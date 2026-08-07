local Events = Events

--! \brief Plugins module for FrameworkZ. Extends the framework with modular plugins.
--! \module FrameworkZ.Plugins
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
    print("[FrameworkZ.Plugins] RegisterPlugin() called for: " .. tostring(name))

    if not self.RegisteredPlugins[name] or overwrite then
        self.RegisteredPlugins[name] = plugin
        FrameworkZ.Foundation:RegisterPluginHandler(self.RegisteredPlugins[name])
        print("[FrameworkZ.Plugins] Plugin registered successfully: " .. tostring(name))
    else
        FrameworkZ.Foundation:UnregisterPluginHandler(self.RegisteredPlugins[name])
        self.RegisteredPlugins[name] = FrameworkZ.Utilities:MergeTables(self.RegisteredPlugins[name], plugin)
        FrameworkZ.Foundation:RegisterPluginHandler(self.RegisteredPlugins[name])
        print("[FrameworkZ.Plugins] Plugin merged with existing: " .. tostring(name))
    end

    --self:LoadPlugin(name)
end

function FrameworkZ.Plugins:GetPlugin(pluginName)
    return self.RegisteredPlugins[pluginName]
end

--! \brief Load a registered plugin.
--! \param pluginName \string The name of the plugin to load.
function FrameworkZ.Plugins:LoadPlugin(pluginName)
    print("[FrameworkZ.Plugins] LoadPlugin() called for: " .. tostring(pluginName))
    local plugin = self.RegisteredPlugins[pluginName]
    if plugin and not self.LoadedPlugins[pluginName] then
        print("[FrameworkZ.Plugins] Plugin found and not already loaded: " .. tostring(pluginName))
        if plugin.Initialize then
            print("[FrameworkZ.Plugins] Calling Initialize() for plugin: " .. tostring(pluginName))
            plugin:Initialize()
        else
            print("[FrameworkZ.Plugins] Plugin has no Initialize method: " .. tostring(pluginName))
        end

        self.LoadedPlugins[pluginName] = plugin
        print("[FrameworkZ.Plugins] Plugin loaded successfully: " .. tostring(pluginName))
        --self:RegisterPluginEventHandlers(plugin)
    else
        if not plugin then
            print("[FrameworkZ.Plugins] Plugin not found in RegisteredPlugins: " .. tostring(pluginName))
        elseif self.LoadedPlugins[pluginName] then
            print("[FrameworkZ.Plugins] Plugin already loaded: " .. tostring(pluginName))
        end
    end
end

--! \brief Load all registered plugins.
function FrameworkZ.Plugins:LoadAllPlugins()
    print("[FrameworkZ.Plugins] LoadAllPlugins() called")
    for pluginName, plugin in pairs(self.RegisteredPlugins) do
        print("[FrameworkZ.Plugins] Processing plugin: " .. tostring(pluginName))
        if not self.LoadedPlugins[pluginName] then
            print("[FrameworkZ.Plugins] Loading plugin: " .. tostring(pluginName))
            self:LoadPlugin(pluginName)
        else
            print("[FrameworkZ.Plugins] Plugin already loaded: " .. tostring(pluginName))
        end
    end
    print("[FrameworkZ.Plugins] LoadAllPlugins() completed")
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

--[[
function FrameworkZ.Plugins:RegisterInterface(interfaceName, interfaceTable)
    if not FrameworkZ.Interfaces.List[interfaceName] then
        FrameworkZ.Interfaces:Register(interfaceName, interfaceTable)
    else
        FrameworkZ.Utilities:MergeTables(FrameworkZ.Interfaces.List[interfaceName], interfaceTable)
    end
end
--]]




















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

--! \brief Initialize the Plugins module - loads all registered plugins.
function FrameworkZ.Plugins:Initialize()
    print("[FrameworkZ.Plugins] Initialize() called")
    
    if self.RegisteredPlugins then
        for pluginName, plugin in pairs(self.RegisteredPlugins) do
            print("[FrameworkZ.Plugins] Found registered plugin: " .. tostring(pluginName))
        end
    end
    
    self:LoadAllPlugins()
    print("[FrameworkZ.Plugins] Initialized and loaded all plugins")
end

--[[
-- Auto-initialize plugins when the module loads
if Events then
    Events.OnGameBoot.Add(function()
        FrameworkZ.Plugins:Initialize()
    end)
else
    -- Fallback if Events is not available yet
    FrameworkZ.Plugins:Initialize()
end
--]]