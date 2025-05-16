local Events = Events
local internalPlugins = {}

--! \brief Plugins module for FrameworkZ. Extends the framework with modular plugins.
--! \class FrameworkZ.Plugins
FrameworkZ.Plugins = {}
FrameworkZ.Plugins.__index = FrameworkZ.Plugins
FrameworkZ.Plugins.__internalPlugins = internalPlugins
FrameworkZ.Plugins.RegisteredPlugins = {}
FrameworkZ.Plugins.Commands = {}
FrameworkZ.Plugins.LoadedPlugins = {}
FrameworkZ.Plugins.EventHandlers = {}
FrameworkZ.Plugins = FrameworkZ.Foundation:NewModule(FrameworkZ.Plugins, "Plugins")

FrameworkZ.Plugins.BasePlugin = {
    __valid = function(object)
        local currentHash = FrameworkZ.Security:HashPlugin(object)
        return object.__hash == currentHash
    end,

    __index = function(tbl, key)
        return rawget(FrameworkZ.Plugins.BasePlugin, key)
    end
}

function FrameworkZ.Plugins:CreatePlugin(name)
    local plugin = setmetatable({}, self.BasePlugin)

    plugin.Meta = {
        Author = "N/A",
        Name = name,
        Description = "No description set.",
        Version = "1.0.0",
        Compatibility = ""
    }

    plugin.__valid = self.BasePlugin.__valid
    plugin.__locked = false

    internalPlugins[name] = plugin

    return plugin
end

local function createSecureFunction(originalFunction, plugin)
    return setmetatable({}, {
        __call = function(_, ...)
            if not plugin.__valid(plugin) then
                FrameworkZ.Notifications:AddToQueue("Tampering Detected: Plugin integrity check failed. This has been logged.", FrameworkZ.Notifications.Types.Danger)
                return false
            end
            return originalFunction(...)
        end,
        __metatable = false
    })
end

local function wrapFunctionsWithValidation(tbl, plugin, visited)
    visited = visited or {}
    if visited[tbl] then return end
    visited[tbl] = true

    for k, v in pairs(tbl) do
        if type(v) == "function" and not k:match("^_") then
            tbl[k] = createSecureFunction(v, plugin)

        elseif type(v) == "table" and not k:match("^_") and not v.__skipWrap then
            wrapFunctionsWithValidation(v, plugin, visited)
        end
    end
end

function FrameworkZ.Plugins:RegisterPlugin(plugin)
    if not plugin.Meta or not plugin.Meta.Name then
        print("Plugin missing metadata or name.")

        return false
    end

    if plugin.__locked then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Alert: Attempted to re-register locked plugin '" .. plugin.Meta.Name .. "'. This has been logged.", FrameworkZ.Notifications.Types.Warning, 60)
        end

        return false
    end

    local name = plugin.Meta.Name
    internalPlugins[name] = plugin
end

function FrameworkZ.Plugins:LockAndLoadPlugin(plugin)
    if not plugin or not plugin.Meta or not plugin.Meta.Name then
        error("Invalid plugin passed to LockAndLoadPlugin.")
    end

    if plugin.__locked then
        error("Plugin '" .. plugin.Meta.Name .. "' is already locked.")
    end

    local name = plugin.Meta.Name

    wrapFunctionsWithValidation(plugin, plugin)
    plugin.__hash = FrameworkZ.Security:HashPlugin(plugin)
    plugin.__locked = true

    local proxy = {}
    local mt = {
        __index = plugin,
        __newindex = function(t, key, value)
            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Tampering Attempt: Cannot override plugin after locking. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)
            end
        end,
        __pairs = function() return pairs(plugin) end,
        __ipairs = function() return ipairs(plugin) end,
        __len = function() return #plugin end,
        __metatable = false
    }

    local lockedPlugin = setmetatable(proxy, mt)

    self.RegisteredPlugins[name] = lockedPlugin
    internalPlugins[name] = nil

    if not self.LoadedPlugins[name] then
        if plugin.Initialize then
            plugin:Initialize()
        end

        self.LoadedPlugins[name] = lockedPlugin
    end

    return lockedPlugin
end

function FrameworkZ.Plugins:GetAllPlugins()
    local hasRegisteredPlugin = false

    for k, v in pairs(self.RegisteredPlugins) do
        if v then
            hasRegisteredPlugin = true
            break
        end
    end

    return hasRegisteredPlugin and self.RegisteredPlugins or internalPlugins
end

function FrameworkZ.Plugins:GetPlugin(pluginName)
    return self.RegisteredPlugins[pluginName] or internalPlugins[pluginName]
end

function FrameworkZ.Plugins:GetLoadedPlugin(pluginName)
    return self.LoadedPlugins[pluginName]
end

function FrameworkZ.Plugins:LoadPlugin(pluginName)
    local plugin = self.RegisteredPlugins[pluginName]

    if plugin and not self.LoadedPlugins[pluginName] then
        if plugin.Initialize then
            plugin:Initialize()
        end

        self.LoadedPlugins[pluginName] = plugin

        return plugin
    end
end

function FrameworkZ.Plugins:UnloadPlugin(pluginName)
    if not self._allowUnload then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Warning: Unload attempt blocked for '" .. pluginName .. "'. This has been logged.", FrameworkZ.Notifications.Types.Danger)
        end

        return false
    end

    self.RegisteredPlugins[pluginName] = nil
    self.LoadedPlugins[pluginName] = nil
    internalPlugins[pluginName] = nil

    return true
end

--[[
--! \brief Register event handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Plugins:RegisterPluginEventHandlers(plugin)
    for _, eventName in ipairs(self.EventHandlers) do
        if plugin[eventName] then
            FrameworkZ.Hooks:RegisterHandler(eventName, plugin[eventName], plugin, eventName)
        end
    end
end

--! \brief Unregister event handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Plugins:UnregisterPluginEventHandlers(plugin)
    for _, eventName in ipairs(self.EventHandlers) do
        if plugin[eventName] then
            FrameworkZ.Hooks:UnregisterHandler(eventName, plugin[eventName], plugin, eventName)
        end
    end
end

--! \brief Add a new event handler to the list.
--! \param eventName \string The name of the event handler to add.
function FrameworkZ.Plugins:AddEventHandler(eventName)
    table.insert(self.EventHandlers, eventName)
end

--! \brief Remove an event handler from the list.
--! \param eventName \string The name of the event handler to remove.
function FrameworkZ.Plugins:RemoveEventHandler(eventName)
    for i, handler in ipairs(self.EventHandlers) do
        if handler == eventName then
            table.remove(self.EventHandlers, i)
            break
        end
    end
end

--! \brief Unregister a specific hook for a plugin.
--! \param pluginName \string The name of the plugin.
--! \param hookName \string The name of the hook to unregister.
function FrameworkZ.Plugins:UnregisterPluginHook(pluginName, hookName)
    local plugin = self.LoadedPlugins[pluginName]
    if plugin and plugin[hookName] then
        FrameworkZ.Hooks:UnregisterHandler(hookName, plugin[hookName], plugin, hookName)
        plugin[hookName] = nil
    end
end

--! \brief Execute a hook for all loaded plugins.
--! \param hookName \string The name of the hook to execute.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Plugins:ExecutePluginHook(hookName, ...)
    for pluginName, plugin in pairs(self.LoadedPlugins) do
        if plugin[hookName] then
            local handlers = FrameworkZ.Hooks.RegisteredHooks[hookName]

            if handlers then
                for _, handler in ipairs(handlers) do
                    if handler.object and handler.functionName then
                        handler.handler(...)
                    else
                        plugin[hookName](...)
                    end
                end
            end
        end
    end
end

--! \brief Log a message for debugging purposes.
--! \param message \string The message to log.
function FrameworkZ.Plugins:Log(message)
    print("[FrameworkZ.Plugins] " .. message)
end

--! \brief Register a custom command for a plugin.
--! \param commandName \string The name of the command.
--! \param callback \function The function to call when the command is executed.
function FrameworkZ.Plugins:RegisterCommand(commandName, callback)
    if not self.Commands then
        self.Commands = {}
    end
    self.Commands[commandName] = callback
end

--! \brief Execute a custom command.
--! \param commandName \string The name of the command.
--! \param ... \vararg Additional arguments to pass to the command function.
function FrameworkZ.Plugins:ExecuteCommand(commandName, ...)
    local command = self.Commands and self.Commands[commandName]
    if command then
        command(...)
    else
        print("Command not found:", commandName)
    end
end

function FrameworkZ.Plugins.EveryOneMinute()
    FrameworkZ.Plugins:ExecutePluginHook("EveryOneMinute")
end
Events.EveryOneMinute.Add(FrameworkZ.Plugins.EveryOneMinute)
FrameworkZ.Plugins:AddEventHandler("EveryOneMinute")

function FrameworkZ.Plugins.EveryTenMinutes()
    FrameworkZ.Plugins:ExecutePluginHook("EveryTenMinutes")
end
Events.EveryTenMinutes.Add(FrameworkZ.Plugins.EveryTenMinutes)
FrameworkZ.Plugins:AddEventHandler("EveryTenMinutes")

function FrameworkZ.Plugins.EveryHours()
    FrameworkZ.Plugins:ExecutePluginHook("EveryHours")
end
Events.EveryHours.Add(FrameworkZ.Plugins.EveryHours)
FrameworkZ.Plugins:AddEventHandler("EveryHours")

function FrameworkZ.Plugins.EveryDays()
    FrameworkZ.Plugins:ExecutePluginHook("EveryDays")
end
Events.EveryDays.Add(FrameworkZ.Plugins.EveryDays)
FrameworkZ.Plugins:AddEventHandler("EveryDays")

function FrameworkZ.Plugins.OnAcceptedTrade(accepted)
	FrameworkZ.Plugins:ExecutePluginHook("OnAcceptedTrade", accepted)
end
Events.AcceptedTrade.Add(FrameworkZ.Plugins.OnAcceptedTrade)
FrameworkZ.Plugins:AddEventHandler("OnAcceptedTrade")

function FrameworkZ.Plugins.LoadGridsquare(square)
    FrameworkZ.Plugins:ExecutePluginHook("OnLoadGridsquare", square)
end
Events.LoadGridsquare.Add(FrameworkZ.Plugins.LoadGridsquare)
FrameworkZ.Plugins:AddEventHandler("OnLoadGridsquare")

function FrameworkZ.Plugins.OnPlayerDeath(player)
    FrameworkZ.Plugins:ExecutePluginHook("OnPlayerDeath", player)
end
Events.OnPlayerDeath.Add(FrameworkZ.Plugins.OnPlayerDeath)
FrameworkZ.Plugins:AddEventHandler("OnPlayerDeath")

function FrameworkZ.Plugins.OnRequestTrade(player)
    FrameworkZ.Plugins:ExecutePluginHook("OnRequestTrade", player)
end
Events.RequestTrade.Add(FrameworkZ.Plugins.OnRequestTrade)
FrameworkZ.Plugins:AddEventHandler("OnRequestTrade")
--]]
