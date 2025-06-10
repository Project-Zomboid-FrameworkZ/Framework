local Events = Events

--! \brief Plugins module for FrameworkZ. Extends the framework with modular plugins.
--! \class FrameworkZ.Plugins
FrameworkZ.Plugins = {}
FrameworkZ.Plugins.__index = FrameworkZ.Plugins
FrameworkZ.Plugins.RegisteredPlugins = {}
FrameworkZ.Plugins.Commands = {}
FrameworkZ.Plugins.LoadedPlugins = {}
FrameworkZ.Plugins.EventHandlers = {}
FrameworkZ.Plugins = FrameworkZ.Foundation:NewModule(FrameworkZ.Plugins, "Plugins")

-- Define the base plugin metatable
FrameworkZ.Plugins.BasePlugin = {}
FrameworkZ.Plugins.BasePlugin.__index = FrameworkZ.Plugins.BasePlugin

-- Function to initialize a new plugin
function FrameworkZ.Plugins:CreatePlugin(name)
    local plugin = setmetatable({}, self.BasePlugin)
    plugin.Meta = {
        Author = "N/A",
        Name = name,
        Description = "No description set.",
        Version = "1.0.0",
        Compatibility = ""
    }

    return plugin
end

-- TODO add to FrameworkZ.Utilities library?
local function mergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            mergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end

    return t1
end

--! \brief Register a plugin.
--! \param pluginName \string The name of the plugin.
--! \param pluginTable \table The table containing the plugin's functions and data.
--! \param metadata \table Optional metadata for the plugin.
function FrameworkZ.Plugins:RegisterPlugin(plugin, overwrite)
    local name = plugin.Meta.Name

    if not self.RegisteredPlugins[name] or overwrite then
        self.RegisteredPlugins[name] = plugin
        FrameworkZ.Foundation:RegisterPluginHandler(self.RegisteredPlugins[name])
    else
        FrameworkZ.Foundation:UnregisterPluginHandler(self.RegisteredPlugins[name])
        self.RegisteredPlugins[name] = mergeTables(self.RegisteredPlugins[name], plugin)
        FrameworkZ.Foundation:RegisterPluginHandler(self.RegisteredPlugins[name])
    end

    self:LoadPlugin(name)
end

function FrameworkZ.Plugins:GetPlugin(pluginName)
    return self.RegisteredPlugins[pluginName]
end

--! \brief Load a registered plugin.
--! \param pluginName \string The name of the plugin to load.
function FrameworkZ.Plugins:LoadPlugin(pluginName)
    local plugin = self.RegisteredPlugins[pluginName]
    if plugin and not self.LoadedPlugins[pluginName] then
        if plugin.Initialize then
            plugin:Initialize()
        end

        self.LoadedPlugins[pluginName] = plugin
        --self:RegisterPluginEventHandlers(plugin)
    end
end

--! \brief Unload a loaded plugin.
--! \param pluginName \string The name of the plugin to unload.
function FrameworkZ.Plugins:UnloadPlugin(pluginName)
    local plugin = self.LoadedPlugins[pluginName]
    if plugin then
        self:UnregisterPluginEventHandlers(plugin)

        if plugin.Cleanup then
            plugin:Cleanup()
        end

        self.LoadedPlugins[pluginName] = nil
    end
end

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

--[[
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