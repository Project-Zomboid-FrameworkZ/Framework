--! \mainpage Main Page
--! Created By RJ_RayJay
--! \section Introduction
--! FrameworkZ is a roleplay framework for the game Project Zomboid. This framework is designed to be a base for roleplay servers, providing a variety of features and systems to help server owners create a unique and enjoyable roleplay experience for their players.
--! \section Features
--! FrameworkZ includes a variety of features and systems to help server owners create a unique and enjoyable roleplay experience for their players. Some of the features and systems include:
--! - Characters
--! - Factions
--! - Entities
--! - Items
--! - Inventories
--! - Modules
--! - Plugins
--! - Hooks
--! - Notifications
--! - ...and more!
--! \section Installation
--! To install the FrameworkZ framework, simply download the latest release from the Steam Workshop and add the Workshop ID/Mod ID into your Project Zomboid server's config file. After installing, you can start your server and the framework will be ready to use. Typically you would also install a gamemode alongside the framework for additional functionality. Refer to your gamemode of choice for additional installation instructions.
--! \section Usage
--! The FrameworkZ framework is designed to be easy to use and extend. The framework is built using Lua, a lightweight, multi-paradigm programming language designed primarily for embedded use in applications. The framework is designed to be modular, allowing server owners to easily add, remove, and modify features and systems to suit their needs. The framework also includes extensive documentation to help server owners understand how to use and extend the framework.
--! \section Contributing
--! The FrameworkZ framework is an open-source project and we welcome contributions from the community. If you would like to contribute to the framework, you can do so by forking the GitHub repository, making your changes, and submitting a pull request. We also welcome bug reports, feature requests, and feedback from the community. If you have any questions or need help with the framework, you can join the FrameworkZ Discord server and ask for assistance in the #support channel.
--! \section License
--! The FrameworkZ framework is licensed under the MIT License, a permissive open-source license that allows you to use, modify, and distribute the framework for free. You can find the full text of the MIT License in the LICENSE file included with the framework. We chose the MIT License because we believe in the power of open-source software and want to encourage collaboration and innovation in the Project Zomboid community.
--! \section Support
--! If you need help with the FrameworkZ framework, you can join the FrameworkZ Discord server and ask for assistance in the #support channel. We have a friendly and knowledgeable community that is always willing to help with any questions or issues you may have. We also have a variety of resources available to help you get started with the framework, including documentation, tutorials, and example code.
--! \section Conclusion
--! The FrameworkZ framework is a powerful and flexible tool for creating roleplay servers in Project Zomboid. Whether you are a server owner looking to create a unique roleplay experience for your players or a developer looking to contribute to an open-source project, the FrameworkZ framework has something for everyone. We hope you enjoy using the framework and look forward to seeing the amazing roleplay experiences you create with it.
--! \section Links
--! - Steam Workshop: Coming Soon(tm)
--! - GitHub Repository: https://github.com/Project-Zomboid-FrameworkZ/Framework
--! - Bug Reports: https://github.com/Project-Zomboid-FrameworkZ/Framework/issues
--! - Discord Server: https://discord.gg/PgNTyva3xk
--! - Documentation: https://frameworkz.projectzomboid.life/documentation/

--! \page global_variables Global Variables
--! \section FrameworkZ FrameworkZ
--! FrameworkZ
--! The global table that contains all of the framework.
--! [table]: /variable_types.html#table "table"
--! \page variable_types Variable Types
--! \section string string
--! A string is a sequence of characters. Strings are used to represent text and are enclosed in double quotes or single quotes.
--! \section boolean boolean
--! A boolean is a value that can be either true or false. Booleans are used to represent logical values.
--! \section integer integer
--! A integer is a numerical value without any decimal points.
--! \section float float
--! A float is a numerical value with decimal points.
--! \section table table
--! A table is a collection of key-value pairs. It is the only data structure available in Lua that allows you to store data with arbitrary keys and values. Tables are used to represent arrays, sets, records, and other data structures.
--! \section function function
--! A function is a block of code that can be called and executed. Functions are used to encapsulate and reuse code.
--! \section nil nil
--! Nil is a special value that represents the absence of a value. Nil is used to indicate that a variable has no value.
--! \section any any
--! Any is a placeholder that represents any type of value. It is used to indicate that a variable can hold any type of value.
--! \section mixed mixed
--! Mixed is a placeholder that represents a combination of different types of values. It is used to indicate that a variable can hold a variety of different types of values.
--! \section multiple multiple
--! Multiple is a placeholder that represents a list of values. It is used to indicate that a function can accept multiple arguments.
--! \section class class
--! Class is a placeholder that represents a class of objects by a table set to a metatable.
--! \section object object
--! Object is a placeholder that represents an instance of a class.

local Events = Events
local getPlayer = getPlayer
local isClient = isClient
local unpack = unpack

--! \brief FrameworkZ global table.
--! \class FrameworkZ
FrameworkZ = FrameworkZ or {}

--! \brief Foundation for FrameworkZ.
--! \class FrameworkZ.Foundation
FrameworkZ.Foundation = {}

--FrameworkZ.Foundation.__index = FrameworkZ.Foundation

--! \brief Modules for FrameworkZ. Extends the framework with additional functionality.
--! \class FrameworkZ.Modules
FrameworkZ.Modules = {}

--! \brief Create a new instance of the FrameworkZ Framework.
--! \return \table The new instance of the FrameworkZ Framework.
function FrameworkZ.Foundation.New()
    local object = {
        version = FrameworkZ.Config.Version
    }
    object.__index = FrameworkZ.Foundation

    setmetatable(object, FrameworkZ.Foundation)

	return object
end

--! \brief Create a new module for the FrameworkZ Framework.
--! \param MODULE_TABLE \table The table to use as the module.
--! \param moduleName \string The name of the module.
--! \return \table The new module.
function FrameworkZ.Foundation:NewModule(moduleObject, moduleName)
	if (not FrameworkZ.Modules[moduleName]) then
		local object = {}
		moduleObject.__index = moduleObject
		setmetatable(object, moduleObject)
		FrameworkZ.Modules[moduleName] = object
		--FrameworkZ.Foundation:RegisterModuleHandler(object)
	end

	return FrameworkZ.Modules[moduleName]
end

function FrameworkZ.Foundation:GetModule(moduleName)
    if not moduleName or moduleName == "" then return false, "No module name supplied." end
    if not FrameworkZ.Modules[moduleName] then return false, "Module not found." end

    return FrameworkZ.Modules[moduleName]
end

--! \brief Get the meta object stored on a module. Not every module will have a meta object. This is a very specific use case and is used for getting instantiable objects such as PLAYER objects or CHARACTER objects.
--! \param moduleName \string The name of the module.
--! \return \table The meta object stored on the module or \nil if nothing was found.
function FrameworkZ.Foundation:GetModuleMetaObject(moduleName)
    local module, message = self:GetModule(moduleName)
    if not module then return false, message end
    if not module.Meta then return false, "Module does not have a meta object." end

    return module.Meta
end

function FrameworkZ.Foundation:RegisterFramework()
	FrameworkZ.Foundation:RegisterFrameworkHandler()
end

function FrameworkZ.Foundation:RegisterModule(module)
	FrameworkZ.Foundation:RegisterModuleHandler(module)
end

--! \brief Get the version of the FrameworkZ Framework.
--! \return \string The version of the FrameworkZ Framework.
function FrameworkZ.Foundation:GetVersion()
    return self.version
end

FrameworkZ.Foundation = FrameworkZ.Foundation.New()

--[[
    FRAMEWORKZ
    NETWORKS SYSTEM
--]]
NETWORKS_MODULE_ID = "fzNetworks"
FrameworkZ.Foundation.PendingConfirmations = {}
FrameworkZ.Foundation.Subscribers = {}
FrameworkZ.Foundation.SubscribersMeta = {}

--! \brief Generate a time-based unique request ID for network requests.
local function generateRequestID()
    return tostring(os.time()) .. "-" .. tostring(ZombRand(100000, 999999))
end

function FrameworkZ.Foundation:PathToString(path)
    if type(path) == "string" then
        return path
    end

    return table.concat(path, ".")
end

--! \brief Add a new channel to the network system. Channels are used to subscribe to; changes in values, or fire events.
--! \param key \string or \table The key to use for the channel. Use a table to create nested channels. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
function FrameworkZ.Foundation:AddChannel(key)
    local stringKey = self:PathToString(key)

    self.Subscribers[stringKey] = {}
    self.SubscribersMeta[stringKey] = {
        originalKey = key,
        createdAt = os.time(),
        lastFiredAt = nil
    }
end

--! \brief Remove a channel from the network system. This will remove all subscribers and meta data for the channel.
--! \param key \string or \table The key to use for the channel. Use a table to create nested channels. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
function FrameworkZ.Foundation:RemoveChannel(key)
    local stringKey = self:PathToString(key)

    self.Subscribers[stringKey] = nil
    self.SubscribersMeta[stringKey] = nil
end

--! \brief Get the channel for a key. This will return the channel data for the key.
--! \param key \string or \table The key to use for the channel. Use a table to create nested channels. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \return \table The channel data for the key.
function FrameworkZ.Foundation:GetChannel(key)
    local stringKey = self:PathToString(key)

    return self.Subscribers[stringKey]
end

--! \brief Get the meta data for a channel. This will return the meta data for the key.
--! \param key \string or \table The key to use for the channel. Use a table to create nested channels. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \return \table The meta data for the key.
function FrameworkZ.Foundation:GetChannelMeta(key)
    local stringKey = self:PathToString(key)

    return self.SubscribersMeta[stringKey]
end

--! \brief Check if a channel exists for a key. This will return true if the channel exists, false otherwise.
--! \param key \string or \table The key to use for the channel. Use a table to create nested channels. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \return \boolean True if the channel exists, false otherwise.
function FrameworkZ.Foundation:HasChannel(key)
    local stringKey = self:PathToString(key)

    return self.Subscribers[stringKey] ~= nil
end

--! \brief Log all channels and their subscribers to the console. This is useful for debugging and understanding the network system.
function FrameworkZ.Foundation:LogChannels()
    print("=== FrameworkZ.Networks Channels ===")

    for key, subs in pairs(self.Subscribers) do
        local meta = self.SubscribersMeta[key]
        local createdString = meta and os.date("%X", meta.createdAt) or "?"
        local firedString = meta and meta.lastFiredAt and os.date("%X", meta.lastFiredAt) or "never"

        print("Channel:", key, "(created at " .. createdString .. ", last fired at " .. firedString .. ")")

        for id, _ in pairs(subs) do
            print("  ->", id)
        end
    end
end

--! \brief Subscribes to a key to listen for changes with the first three arguments supplied, or can be used for sending/receiving fire events with the first two arguments supplied.
--! \param key \string The key to subscribe to. Use a \table to subscribe to nested values. \note Example key argument as a table: {"key", "subkey"} == _G["key"]["subkey"] or _G.key.subkey on lookup when subscribing.
--! \param id \mixed The \string ID of the function callback being added for key changes, or a \function callback for the client-server/server-client fire events.
--! \param callback \function (Optional) The callback to call when the key changes.
--! \return \function The callback that was added to the channel. Useful if an inline callback was supplied for the idOrCallback parameter when setting up a fire event.
function FrameworkZ.Foundation:Subscribe(key, idOrCallback, maybeCallback)
    local id, callback

    if type(idOrCallback) == "function" then
        id = "__default"
        callback = idOrCallback
    else
        id = idOrCallback
        callback = maybeCallback
    end

    if not self:HasChannel(key) then
        self:AddChannel(key)
    end

    self:GetChannel(key)[id] = callback

    return callback
end

--! \brief Unsubscribes from a key. This will remove the callback from the channel.
--! \param key \string The key to unsubscribe from. Use a \table to unsubscribe from nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param id \sting The ID of the function callback being removed. Default for fire events: "__default"
function FrameworkZ.Foundation:Unsubscribe(key, id)
    local subscribers = self:GetSubscribers(key)
    if not subscribers then return false end

    subscribers[id] = nil
end

--! \brief Get the subscribers for a key. This will return the subscribers for the key.
--! \param key \string The key to get the subscribers for. Use a \table to get the subscribers for nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \return \table The subscribers for the key.
function FrameworkZ.Foundation:GetSubscribers(key)
    return self:GetChannel(key)
end

--! \brief Check if a subscription exists for a key. This will return true if the subscription exists, false otherwise.
--! \param key \string The key to check for. Use a \table to check for nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param id \string The ID of the function callback being checked.
function FrameworkZ.Foundation:HasSubscription(key, id)
    local channel = self:GetChannel(key)

    return channel and channel[id] ~= nil
end

--! \brief Fires a callback for a key. This will call the callback for the key with the value supplied.
--! \param key \string The key to fire the callback for. Use a \table to fire the callback for nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param data \table The standard data to pass to the callback. Generally contains diagnostic information.
--! \param arguments \table The values to pass to the callback. This can be any type of values stored in the table.
function FrameworkZ.Foundation:Fire(key, data, arguments)
    if not self:HasChannel(key) then
        print("[FZ] Warning: Received fire event for unknown ID: ", key)
    end

    local returnValues = {}
    local callbacks = self:GetSubscribers(key)

    if callbacks then
        local results

        for id, callback in pairs(callbacks) do
            results = {callback(data, unpack(arguments))}

            returnValues[id] = results
        end

        local meta = self:GetChannelMeta(key)

        if meta then
            meta.lastFiredAt = os.time()
        end
    end

    return returnValues
end

--! \brief Subscribes and fires callback immediately if the value is already set. Useful for UIs.
--! \param key \string or \table The key to watch. Use a table to watch nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param id \string The ID of the function callback being added.
--! \param callback \function The callback to call when the key changes.
function FrameworkZ.Foundation:Watch(key, id, callback)
    self:Subscribe(key, id, callback)

    local value = self:GetNestedValue(_G, type(key) == "string" and {key} or key)

    if value ~= nil then
        callback(key, value)
    end
end

--! \brief Sends a get request to the server.
--! \param key \mixed The key to get. Does not support getting functions.
--! \param callback \function The callback to call on the client when the server returns the value.
--! \param callbackID \string The key to use for the callback on the server after getting the value.
--! \param broadcast \boolean Whether to broadcast the get callback to all clients.
function FrameworkZ.Foundation:SendGet(key, callback, callbackID, broadcast, ...)
    if type(key) == "string" then
        key = {key}
    end

    local requestID = generateRequestID()

    if callback then
        self.PendingConfirmations[requestID] = {callback = callback}
    end

    sendClientCommand(NETWORKS_MODULE_ID, "GetData", {
        key = key,
        broadcast = broadcast,
        callbackID = callbackID,
        requestID = requestID,
        args = {...}
    })

    return requestID
end

--! \brief Sends a set request to the server.
--! \param key \string or \table The key to set. Use a table to set nested values. \note Example key argument as a table: {"key", "subkey"} == _G["key"]["subkey"] or _G.key.subkey on lookup when setting.
--! \param value \mixed The value to set. Does not support functions.
--! \param callback \function The callback to call on the client when the server confirms the set.
--! \param callbackID \string The key to use for the callback on the server after setting the value.
--! \param broadcast \boolean Whether to broadcast the set callback to all clients.
function FrameworkZ.Foundation:SendSet(key, value, callback, callbackID, broadcast)
    if type(key) == "string" then
        key = {key}
    end

    local requestID = generateRequestID()

    if callback then
        self.PendingConfirmations[requestID] = {key = key, newValue = value, callback = callback}
    end

    sendClientCommand(NETWORKS_MODULE_ID, "SetData", {
        key = key,
        value = value,
        broadcast = broadcast,
        callbackID = callbackID,
        requestID = requestID
    })

    return requestID
end

function FrameworkZ.Foundation:SendFire(isoPlayer, subscriptionID, callback, ...)
    local playerID = isoPlayer and isoPlayer:getOnlineID() or nil
    local requestID = generateRequestID()

    if callback then
        self.PendingConfirmations[requestID] = {
            playerID = playerID,
            callback = callback,
            subID = subscriptionID,
            sentAt = os.time()
        }
    end

    if isClient() then
        local payload = {
            requestID = requestID,
            subID = subscriptionID,
            args = {...},
            clientSentAt = os.time()
        }

        sendClientCommand(isoPlayer, NETWORKS_MODULE_ID, "SendFire", payload)
    elseif isServer() then
        local payload = {
            playerID = playerID,
            requestID = requestID,
            subID = subscriptionID,
            args = {...},
            serverSentAt = os.time()
        }

        sendServerCommand(isoPlayer, NETWORKS_MODULE_ID, "SendFire", payload)
    end

    return requestID
end


function FrameworkZ.Foundation:GetNestedValue(root, path)
    local current = root

    for _, key in ipairs(path) do
        if type(current) ~= "table" then return nil end
        current = current[key]
    end

    return current
end

function FrameworkZ.Foundation:SetNestedValue(root, path, value)
    local current = root

    for i = 1, #path - 1 do
        local key = path[i]
        current[key] = current[key] or {}
        current = current[key]
    end

    current[path[#path]] = value
end

if isServer() then

    --! \brief Handles incoming commands from the client on the server.
    function FrameworkZ.Foundation:OnClientCommand(module, command, isoPlayer, arguments)
        if module ~= NETWORKS_MODULE_ID then return end

        if command == "GetData" then
            local key = arguments.key
            local value = self:GetNestedValue(_G, key)
            local returnValues = {}

            if arguments.callbackID then
                local callbacks = self:GetSubscribers(arguments.callbackID)

                if callbacks then
                    for id, callback in pairs(callbacks) do
                        local returnValue = callback(isoPlayer, key, value, nil, arguments.args)

                        if returnValue then
                            if not returnValues[id] then returnValues[id] = {} end
                            returnValues[id] = returnValue
                        end
                    end
                end
            end

            if not arguments.broadcast then
                sendServerCommand(isoPlayer, NETWORKS_MODULE_ID, "ReturnData", {
                    key = key,
                    value = value,
                    broadcast = false,
                    requestID = arguments.requestID,
                    returnValues = returnValues,
                    args = arguments.args
                })
            else
                local onlineUsers = getOnlinePlayers()

                for i = 0, onlineUsers:size() - 1 do
                    sendServerCommand(onlineUsers:get(i), NETWORKS_MODULE_ID, "ReturnData", {
                        key = key,
                        value = value,
                        broadcast = true,
                        requestID = arguments.requestID,
                        returnValues = returnValues,
                        args = arguments.args
                    })
                end
            end
        elseif command == "SetData" then
            local key = arguments.key
            local value = arguments.value

            self:SetNestedValue(_G, key, value)

            local newValue = self:GetNestedValue(_G, key)

            if value ~= newValue then
                sendServerCommand(isoPlayer, NETWORKS_MODULE_ID, "FailedSet", {
                    key = key,
                    value = newValue,
                    broadcast = false,
                    requestID = arguments.requestID
                })

                return
            end

            if arguments.callbackID then
                local callbacks = self:GetSubscribers(arguments.callbackID)

                if callbacks then
                    for _, callback in pairs(callbacks) do
                        callback(key, value)
                    end
                end
            end

            if not arguments.broadcast then
                sendServerCommand(isoPlayer, NETWORKS_MODULE_ID, "ConfirmSet", {
                    key = key,
                    value = newValue,
                    broadcast = false,
                    requestID = arguments.requestID
                })
            else
                local onlineUsers = getOnlinePlayers()

                for i = 0, onlineUsers:size() - 1 do
                    sendServerCommand(onlineUsers:get(i), NETWORKS_MODULE_ID, "ConfirmSet", {
                        key = key,
                        value = newValue,
                        broadcast = true,
                        requestID = arguments.requestID
                    })
                end
            end
        elseif command == "SendFire" then
            local subID = arguments.subID
            local meta = self:GetChannelMeta(subID) or {}
            local data = {
                isoPlayer = isoPlayer,
                clientSentAt = arguments.clientSentAt,
                subID = subID,
                subCreatedAt = meta.createdAt,
                subLastFiredAt = meta.lastFiredAt
            }

            local returnValues = self:Fire(subID, data, arguments.args)

            sendServerCommand(isoPlayer, NETWORKS_MODULE_ID, "ConfirmFire", {
                requestID = arguments.requestID,
                subID = subID,
                meta = meta,
                returnValues = returnValues
            })
        elseif command == "ConfirmFire" then
            local confirmation = self.PendingConfirmations[arguments.requestID]

            if confirmation then
                local meta = arguments.meta or {}
                local callback = confirmation.callback
                local returnValues = arguments.returnValues or {}

                for _, returnArgs in pairs(returnValues) do
                    local data = {
                        subscriptionID = confirmation.subID,
                        isoPlayer = isoPlayer,
                        sentAt = confirmation.sentAt,
                        createdAt = meta.createdAt,
                        lastFiredAt = meta.lastFiredAt,
                    }

                    callback(data, unpack(returnArgs))
                end

                self.PendingConfirmations[arguments.requestID] = nil
            end
        end
    end
end

if isClient() then
    --! \brief Handles incoming commands from the server on the client.
    function FrameworkZ.Foundation:OnServerCommand(module, command, arguments)
        if module ~= NETWORKS_MODULE_ID then return end

        if command == "ConfirmSet" then
            local requestID = arguments.requestID
            local confirmation = self.PendingConfirmations[requestID]

            if confirmation then
                if arguments.value == confirmation.newValue then
                    local callback = confirmation.callback

                    if callback then
                        callback(arguments.key, arguments.value)
                    end
                end

                self.PendingConfirmations[requestID] = nil
            end

            if arguments.broadcast then
                local key = arguments.key
                local callbacks = self:GetSubscribers(key)

                if callbacks then
                    for _, callback in pairs(callbacks) do
                        callback(key, arguments.value)
                    end
                end
            end
        elseif command == "ReturnData" then
            local isoPlayer = getPlayer()
            local requestID = arguments.requestID
            local confirmation = self.PendingConfirmations[requestID]

            if confirmation then
                local callback = confirmation.callback

                if callback then
                    callback(isoPlayer, arguments.key, arguments.value, arguments.returnValues, arguments.args)
                end

                self.PendingConfirmations[requestID] = nil
            end

            if arguments.broadcast then
                local key = arguments.key
                local callbacks = self:GetSubscribers(key)

                if callbacks then
                    for _, callback in pairs(callbacks) do
                        callback(isoPlayer, key, arguments.value, arguments.returnValues, arguments.args)
                    end
                end
            end
        elseif command == "SendFire" then
            local subID = arguments.subID
            local isoPlayer = getSpecificPlayer(arguments.playerID)
            local meta = self:GetChannelMeta(subID) or {}
            local data = {
                isoPlayer = isoPlayer,
                serverSentAt = arguments.serverSentAt,
                subID = subID,
                subCreatedAt = meta.createdAt,
                subLastFiredAt = meta.lastFiredAt
            }

            local returnValues = self:Fire(subID, data, arguments.args)

            sendClientCommand(isoPlayer, NETWORKS_MODULE_ID, "ConfirmFire", {
                requestID = arguments.requestID,
                subID = subID,
                meta = meta,
                returnValues = returnValues
            })
        elseif command == "ConfirmFire" then
            local confirmation = self.PendingConfirmations[arguments.requestID]

            if confirmation then
                local meta = arguments.meta or {}
                local callback = confirmation.callback
                local returnValues = arguments.returnValues or {}

                for _, returnArgs in pairs(returnValues) do
                    local data = {
                        subscriptionID = confirmation.subID,
                        isoPlayer = getSpecificPlayer(confirmation.playerID),
                        sentAt = confirmation.sentAt,
                        createdAt = meta.createdAt,
                        lastFiredAt = meta.lastFiredAt,
                    }

                    callback(data, unpack(returnArgs))
                end

                self.PendingConfirmations[arguments.requestID] = nil
            end
        elseif command == "FailedSet" then
            local requestID = arguments.requestID
            local confirmation = self.PendingConfirmations[requestID]

            if confirmation then
                self.PendingConfirmations[requestID] = nil
                print("[FZ] Failed to set value for key: " .. table.concat(arguments.key, ".") .. " | Setting to '" .. confirmation.newValue .. "' but got '" .. arguments.value .. "' server-side. Maybe key doesn't exist on the server?")
            end
        end
    end
end

function FrameworkZ.Foundation:CleanupConfirmations(timeout)
    local now = os.time()

    for id, entry in pairs(self.PendingConfirmations) do
        if now - entry.sentAt > timeout then
            self.PendingConfirmations[id] = nil
            print(("[FZ] Cleaned up stale confirmation: %s"):format(tostring(id)))
        end
    end
end

function FrameworkZ.Foundation:EveryDays()
    self:CleanupConfirmations(60 * 5) -- 5 minutes
end

--[[
    FRAMEWORKZ
    HOOKS SYSTEM
--]]

HOOK_CATEGORY_FRAMEWORK = "framework"
HOOK_CATEGORY_MODULE = "module"
HOOK_CATEGORY_GAMEMODE = "gamemode"
HOOK_CATEGORY_PLUGIN = "plugin"
HOOK_CATEGORY_GENERIC = "generic"

FrameworkZ.Foundation.HookHandlers = {
    framework = {},
    module = {},
    gamemode = {},
    plugin = {},
    generic = {}
}

FrameworkZ.Foundation.RegisteredHooks = {
    framework = {},
    module = {},
    gamemode = {},
    plugin = {},
    generic = {}
}

--! \brief Add a new hook handler to the list.
--! \param hookName \string The name of the hook handler to add.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:AddHookHandler(hookName, category)
    category = category or HOOK_CATEGORY_GENERIC
    self.HookHandlers[category][hookName] = true
end

--! \brief Add a new hook handler to the list for all categories.
--! \param hookName \string The name of the hook handler to add.
function FrameworkZ.Foundation:AddAllHookHandlers(hookName)
    self:AddHookHandler(hookName, HOOK_CATEGORY_FRAMEWORK)
    self:AddHookHandler(hookName, HOOK_CATEGORY_MODULE)
    self:AddHookHandler(hookName, HOOK_CATEGORY_GAMEMODE)
    self:AddHookHandler(hookName, HOOK_CATEGORY_PLUGIN)
    self:AddHookHandler(hookName, HOOK_CATEGORY_GENERIC)
end

--! \brief Remove a hook handler from the list.
--! \param hookName \string The name of the hook handler to remove.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:RemoveHookHandler(hookName, category)
    category = category or HOOK_CATEGORY_GENERIC
    self.HookHandlers[category][hookName] = nil
end

--! \brief Register hook handlers for the framework.
--! \param framework \table The framework table containing the functions.
function FrameworkZ.Foundation:RegisterFrameworkHandler()
    self:RegisterHandlers(self, HOOK_CATEGORY_FRAMEWORK)
end

--! \brief Unregister hook handlers for the framework.
--! \param framework \table The framework table containing the functions.
function FrameworkZ.Foundation:UnregisterFrameworkHandler()
    self:UnregisterHandlers(self, HOOK_CATEGORY_FRAMEWORK)
end

--! \brief Register hook handlers for a module.
--! \param module \table The module table containing the functions.
function FrameworkZ.Foundation:RegisterModuleHandler(module)
    self:RegisterHandlers(module, HOOK_CATEGORY_MODULE)
end

--! \brief Unregister hook handlers for a module.
--! \param module \table The module table containing the functions.
function FrameworkZ.Foundation:UnregisterModuleHandler(module)
    self:UnregisterHandlers(module, HOOK_CATEGORY_MODULE)
end

--! \brief Register hook handlers for the gamemode.
--! \param module \table The module table containing the functions.
function FrameworkZ.Foundation:RegisterGamemodeHandler(gamemode)
    self:RegisterHandlers(gamemode, HOOK_CATEGORY_GAMEMODE)
end

--! \brief Unregister hook handlers for the gamemode.
--! \param module \table The module table containing the functions.
function FrameworkZ.Foundation:UnregisterGamemodeHandler(gamemode)
    self:UnregisterHandlers(gamemode, HOOK_CATEGORY_GAMEMODE)
end

--! \brief Register hook handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Foundation:RegisterPluginHandler(plugin)
    self:RegisterHandlers(plugin, HOOK_CATEGORY_PLUGIN)
end

--! \brief Unregister hook handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Foundation:UnregisterPluginHandler(plugin)
    self:UnregisterHandlers(plugin, HOOK_CATEGORY_PLUGIN)
end

--! \brief Register hook handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Foundation:RegisterGenericHandler()
    self:RegisterHandlers(nil, HOOK_CATEGORY_GENERIC)
end

--! \brief Unregister hook handlers for a plugin.
--! \param plugin \table The plugin table containing the functions.
function FrameworkZ.Foundation:UnregisterGenericHandler()
    self:UnregisterHandlers(nil, HOOK_CATEGORY_GENERIC)
end

--! \brief Register handlers for a specific category.
--! \param object \table The object containing the functions.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:RegisterHandlers(objectOrHandlers, category)
    category = category or HOOK_CATEGORY_GENERIC
    if not self.HookHandlers[category] then
        error("Invalid category: " .. tostring(category))
    end

    -- Iterate over the hook names using pairs since HookHandlers is now a dictionary
    for hookName, _ in pairs(self.HookHandlers[category]) do
        if objectOrHandlers and type(objectOrHandlers) == "table" then
            -- Check if the object/table has a function for the hookName
            local handlerFunction = objectOrHandlers[hookName]
            if handlerFunction and type(handlerFunction) == "function" then
                self:RegisterHandler(hookName, handlerFunction, objectOrHandlers, hookName, category)
            end
        else
            -- objectOrHandlers is nil or not a table
            -- Try to get the function from the global environment
            local handler = _G[hookName]
            if handler and type(handler) == "function" then
                self:RegisterHandler(hookName, handler, nil, nil, category)
            end
        end
    end
end

--! \brief Unregister handlers for a specific category.
--! \param object \table The object containing the functions.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:UnregisterHandlers(objectOrHandlers, category)
    category = category or HOOK_CATEGORY_GENERIC
    if not self.HookHandlers[category] then
        error("Invalid category: " .. tostring(category))
    end

    for hookName, _ in pairs(self.HookHandlers[category]) do
        if objectOrHandlers and type(objectOrHandlers) == "table" then
            local handlerFunction = objectOrHandlers[hookName]
            if handlerFunction and type(handlerFunction) == "function" then
                self:UnregisterHandler(hookName, handlerFunction, objectOrHandlers, hookName, category)
            end
        else
            local handler = _G[hookName]
            if handler and type(handler) == "function" then
                self:UnregisterHandler(hookName, handler, nil, nil, category)
            end
        end
    end
end

--! \brief Register a handler for a hook.
--! \param hookName \string The name of the hook.
--! \param handler \function The function to call when the hook is executed.
--! \param object \table (Optional) The object containing the function.
--! \param functionName \string (Optional) The name of the function to call.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:RegisterHandler(hookName, handler, object, functionName, category)
    category = category or HOOK_CATEGORY_GENERIC
    self.RegisteredHooks[category][hookName] = self.RegisteredHooks[category][hookName] or {}

    if object and functionName then
        table.insert(self.RegisteredHooks[category][hookName], {
            handler = function(...)
                object[functionName](...)
            end,
            object = object,
            functionName = functionName
        })
    else
        table.insert(self.RegisteredHooks[category][hookName], {
            handler = handler,
            object = object
        })
    end
end

--! \brief Unregister a handler from a hook.
--! \param hookName \string The name of the hook.
--! \param handler \function The function to unregister.
--! \param object \table (Optional) The object containing the function.
--! \param functionName \string (Optional) The name of the function to unregister.
--! \param category \string The category of the hook (framework, module, plugin, generic).
function FrameworkZ.Foundation:UnregisterHandler(hookName, handler, object, functionName, category)
    category = category or HOOK_CATEGORY_GENERIC
    local hooks = self.RegisteredHooks[category] and self.RegisteredHooks[category][hookName]
    if hooks then
        for i = #hooks, 1, -1 do
            if object and functionName then
                if hooks[i].object == object and hooks[i].functionName == functionName then
                    table.remove(hooks, i)
                end
            else
                if hooks[i] == handler then
                    table.remove(hooks, i)
                end
            end
        end
    end
end

--! \brief Execute a given hook by its hook name for its given category.
--! \note When a function is defined and registered as a hook, sometimes it's as an object. However in the definition it could be as some.func() or some:func() (notice the period and colon between the examples). If the function is defined as some:func() then the object is passed as the first argument. If the function is defined as some.func() then the object is not passed as the first argument, in which case we would also need to define some.func_PassOverHookableObject function which must return \boolean true. This tells the hook system to not supply the object as the first argument if the function is apart of an object in the first place. Generic function hooks do not store an object and so do not have to worry about defining that additional property on its own function.
--! \param hookName \string The name of the hook.
--! \param category \string The category of the hook (framework, module, plugin, generic).
--! \param ... \multiple Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteHook(hookName, category, ...)
    category = category or HOOK_CATEGORY_GENERIC
    local args = {...}

    local hooks = self.RegisteredHooks[category] and self.RegisteredHooks[category][hookName]
    if hooks then
        for _, hook in ipairs(hooks) do
            local func = hook.handler
            local object = hook.object
            local functionName = hook.functionName

            if func then
                if object and functionName then
                    local shouldPassOverHookableObject = rawget(object, functionName .. "_PassOverHookableObject")

                    if shouldPassOverHookableObject then
                        func(unpack(args))
                    else
                        if args[1] ~= object then
                            func(object, unpack(args))
                        else
                            func(unpack(args))
                        end
                    end
                else
                    func(unpack(args))
                end
            end
        end
    end
end

--! \brief Execute all of the hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteAllHooks(hookName, ...)
    for category, hooks in pairs(self.RegisteredHooks) do
        self:ExecuteHook(hookName, category, ...)
    end
end

--! \brief Execute the framework hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteFrameworkHooks(hookName, ...)
    self:ExecuteHook(hookName, HOOK_CATEGORY_FRAMEWORK, ...)
end

--! \brief Execute module hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteModuleHooks(hookName, ...)
    self:ExecuteHook(hookName, HOOK_CATEGORY_MODULE, ...)
end

--! \brief Execute the gamemode hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteGamemodeHooks(hookName, ...)
    self:ExecuteHook(hookName, HOOK_CATEGORY_GAMEMODE, ...)
end

--! \brief Execute plugin hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecutePluginHooks(hookName, ...)
    self:ExecuteHook(hookName, HOOK_CATEGORY_PLUGIN, ...)
end

--! \brief Execute generic hooks.
--! \param hookName \string The name of the hook.
--! \param ... \vararg Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteGenericHooks(hookName, ...)
    self:ExecuteHook(hookName, HOOK_CATEGORY_GENERIC, ...)
end

--[[
	FRAMEWORKZ
	HOOKS ADDITIONS
--]]

if isServer() then
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Foundation.GetServerTime", function(data)
        return getTimestampMs()
    end)
end

local startTime

--! \brief Called when the game starts. Executes the OnGameStart function for all modules.
function FrameworkZ.Foundation:OnGameStart()
    local isoPlayer = getPlayer()
    startTime = getTimestampMs()

    self:ExecuteFrameworkHooks("PreInitializeClient", isoPlayer)
end

function FrameworkZ.Foundation:PreInitializeClient(isoPlayer)
    if isClient() then
        FrameworkZ.Players:StartPlayerTick(isoPlayer)
        
        local sidebar = ISEquippedItem.instance
        FrameworkZ.Foundation.fzuiTabMenu = FrameworkZ.fzuiTabMenu:new(sidebar:getX(), sidebar:getY() + sidebar:getHeight() + 10, sidebar:getWidth(), 40, getPlayer())
        FrameworkZ.Foundation.fzuiTabMenu:initialise()
        FrameworkZ.Foundation.fzuiTabMenu:addToUIManager()
    end

    self:ExecuteModuleHooks("PreInitializeClient", isoPlayer)
    self:ExecuteGamemodeHooks("PreInitializeClient",isoPlayer)
    self:ExecutePluginHooks("PreInitializeClient", isoPlayer)

    self:ExecuteFrameworkHooks("InitializeClient", isoPlayer)
end
FrameworkZ.Foundation:AddAllHookHandlers("PreInitializeClient")

function FrameworkZ.Foundation:InitializeClient(isoPlayer)
    if isClient() then
        FrameworkZ.Timers:Simple(FrameworkZ.Config.InitializationDuration, function()
            --FrameworkZ.Foundation:SendFire(isoPlayer, FrameworkZ.Foundation.OnInitializeClient, "FrameworkZ.Foundation.OnInitializeClient", false)

            FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Foundation.OnInitializeClient", FrameworkZ.Foundation.OnInitializeClient)
        end)
    end
end
FrameworkZ.Foundation:AddAllHookHandlers("InitializeClient")

function FrameworkZ.Foundation.OnInitializeClient(data)
    if not data.isoPlayer then return false end

    local isoPlayer = data.isoPlayer
    local player = FrameworkZ.Players:New(isoPlayer)

    if player then
        player:Initialize()
    end

    FrameworkZ.Foundation:ExecuteModuleHooks("InitializeClient", isoPlayer)
    FrameworkZ.Foundation:ExecuteGamemodeHooks("InitializeClient", isoPlayer)
    FrameworkZ.Foundation:ExecutePluginHooks("InitializeClient",isoPlayer)

    FrameworkZ.Foundation:ExecuteFrameworkHooks("PostInitializeClient", isoPlayer)
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Foundation.OnInitializeClient", FrameworkZ.Foundation.OnInitializeClient)

function FrameworkZ.Foundation:PostInitializeClient(isoPlayer)
    self:ExecuteModuleHooks("PostInitializeClient", isoPlayer)
    self:ExecuteGamemodeHooks("PostInitializeClient", isoPlayer)
    self:ExecutePluginHooks("PostInitializeClient", isoPlayer)

    if isClient() then
        FrameworkZ.Foundation.InitializationNotification = FrameworkZ.Notifications:AddToQueue("Initialized in " .. tostring(string.format(" %.2f", (getTimestampMs() - startTime) / 1000)) .. " seconds.", FrameworkZ.Notifications.Types.Success, nil, PFW_Introduction.instance)
    end
end
FrameworkZ.Foundation:AddAllHookHandlers("PostInitializeClient")

function FrameworkZ.Foundation:OnMainMenuEnter()
    self:ExecuteFrameworkHooks("OnOpenEscapeMenu", getPlayer())
end

function FrameworkZ.Foundation:OnOpenEscapeMenu()
    self:ExecuteModuleHooks("OnOpenEscapeMenu", getPlayer())
    self:ExecuteGamemodeHooks("OnOpenEscapeMenu", getPlayer())
    self:ExecutePluginHooks("OnOpenEscapeMenu", getPlayer())
end
FrameworkZ.Foundation:AddAllHookHandlers("OnOpenEscapeMenu")

if not isClient() then

	--! \brief Called when the server starts. Executes the OnServerStarted function for all modules.
	function FrameworkZ.Foundation.OnServerStarted()
		for k, v in pairs(FrameworkZ.Modules) do
			if v.OnServerStarted then
				v.OnServerStarted(v)
			end
		end
	end
	Events.OnServerStarted.Add(FrameworkZ.Foundation.OnServerStarted)

end
