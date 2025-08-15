--[[ Documentation



██████   ██████   ██████ ██    ██ ███    ███ ███████ ███    ██ ████████  █████  ████████ ██  ██████  ███    ██ 
██   ██ ██    ██ ██      ██    ██ ████  ████ ██      ████   ██    ██    ██   ██    ██    ██ ██    ██ ████   ██ 
██   ██ ██    ██ ██      ██    ██ ██ ████ ██ █████   ██ ██  ██    ██    ███████    ██    ██ ██    ██ ██ ██  ██ 
██   ██ ██    ██ ██      ██    ██ ██  ██  ██ ██      ██  ██ ██    ██    ██   ██    ██    ██ ██    ██ ██  ██ ██ 
██████   ██████   ██████  ██████  ██      ██ ███████ ██   ████    ██    ██   ██    ██    ██  ██████  ██   ████ 



--]]

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

--! \page Global Variables
--! \section FrameworkZ FrameworkZ
--! FrameworkZ
--! The global table that contains all of the framework.
--! [table]: /variable_types.html#table "table"

--! \page Variable Types
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

--[[ Setup



███████ ███████ ████████ ██    ██ ██████  
██      ██         ██    ██    ██ ██   ██ 
███████ █████      ██    ██    ██ ██████  
     ██ ██         ██    ██    ██ ██      
███████ ███████    ██     ██████  ██      



--]]

--! \brief Local reference to the global Events table for performance optimization.
local Events = Events

--! \brief Local reference to the global getPlayer function for performance optimization.
local getPlayer = getPlayer

--! \brief Local reference to the global isClient function for performance optimization.
local isClient = isClient

--! \brief Local reference to the global isServer function for performance optimization.
local isServer = isServer

--! \brief Local reference to the global ModData table for performance optimization.
local ModData = ModData

--! \brief Local reference to the global unpack function for performance optimization.
local unpack = unpack

FrameworkZ = FrameworkZ or {}

--! \brief Contains all of the User Interfaces for FrameworkZ.
FrameworkZ.UI = FrameworkZ.UI or {}

--! \brief Foundational systems for FrameworkZ.
--! \core FrameworkZ.Foundation
FrameworkZ.Foundation = {}
--FrameworkZ.Foundation.__index = FrameworkZ.Foundation

--! \brief Contains all event handling functions for the Foundation system.
FrameworkZ.Foundation.Events = {}

--! \brief Version information for the Foundation system.
FrameworkZ.Foundation.version = "1.0.0"

--! \brief Contains modules for FrameworkZ. Extends the framework with additional functionality.
FrameworkZ.Foundation.Modules = FrameworkZ.Foundation.Modules or {}

--! \brief Create a new instance of the FrameworkZ framework.
--! \return \table The new instance of the FrameworkZ framework.
function FrameworkZ.Foundation.New()
    return FrameworkZ:CreateObject(FrameworkZ.Foundation, "Foundation")
end

--! \brief Create a new module for the FrameworkZ framework.
--! \param moduleObject \object The object to use as the module.
--! \param moduleName \string The name of the module.
--! \return \object The new module.
function FrameworkZ.Foundation:NewModule(moduleObject, moduleName)
    local object = FrameworkZ:CreateObject(moduleObject, moduleName)

    self.Modules[moduleName] = object

	return object
end

--! \brief Get a module by name.
--! \param moduleName \string The name of the module.
--! \return \object The module object or \false if the module was not found.
function FrameworkZ.Foundation:GetModule(moduleName)
    if not moduleName or moduleName == "" then return false, "No module name supplied." end
    if not self.Modules[moduleName] then return false, "Module not found." end

    return self.Modules[moduleName]
end

--! \brief Get a module's meta object stored on a module. Not every module will have a meta object. This is a very specific use case and is used for getting instantiable objects such as PLAYER objects or CHARACTER objects.
--! \param moduleName \string The name of the module.
--! \return \object The meta object stored on the module or false if nothing was found.
function FrameworkZ.Foundation:GetModuleMetaObject(moduleName)
    local module, message = self:GetModule(moduleName)
    if not module then return false, message end
    if not module.MetaObject then return false, "Module does not have a meta object." end

    return module.MetaObject
end

--! \brief Register FrameworkZ. This is called after framework definition.
function FrameworkZ.Foundation:RegisterFramework()
	FrameworkZ.Foundation:RegisterFrameworkHandler()
    FrameworkZ:RegisterObject(self)
end

--! \brief Register a module for FrameworkZ. This is called after module definition.
--! \param module \object The module to register.
function FrameworkZ.Foundation:RegisterModule(module)
	FrameworkZ.Foundation:RegisterModuleHandler(module)
    FrameworkZ:RegisterObject(module)
end

--! \brief Get the version of FrameworkZ Foundation.
--! \return \string The version of the FrameworkZ Foundation.
function FrameworkZ.Foundation:GetVersion()
    return self.version
end

--! \field Foundation \object The foundational systems for FrameworkZ.
FrameworkZ.Foundation = FrameworkZ.Foundation.New()

--[[ Networking



███    ██ ███████ ████████ ██     ██  ██████  ██████  ██   ██ ██ ███    ██  ██████  
████   ██ ██         ██    ██     ██ ██    ██ ██   ██ ██  ██  ██ ████   ██ ██       
██ ██  ██ █████      ██    ██  █  ██ ██    ██ ██████  █████   ██ ██ ██  ██ ██   ███ 
██  ██ ██ ██         ██    ██ ███ ██ ██    ██ ██   ██ ██  ██  ██ ██  ██ ██ ██    ██ 
██   ████ ███████    ██     ███ ███   ██████  ██   ██ ██   ██ ██ ██   ████  ██████  



--]]

--! \brief The name of the networking module for commands in OnClientCommand and OnServerCommand. Not to be confused with a FrameworkZ module.
FrameworkZ.Foundation.NetworksName = "FZ_NETWORKS"

--! \brief Pending confirmations for network requests. This is used to track requests that are waiting for a response.
FrameworkZ.Foundation.PendingConfirmations = {}

--! \brief Subscribers for the network system. This is used to track subscribers for channels.
FrameworkZ.Foundation.Subscribers = {}

--! \brief Meta data for the subscribers. This is used to track when a channel was created and when it was last fired.
FrameworkZ.Foundation.SubscribersMeta = {}

--! \brief Generate a time-based unique request ID for network requests.
--! \return \string A unique request ID based on the current timestamp and a random number.
local function generateRequestID()
    return tostring(getTimestamp()) .. "-" .. tostring(ZombRand(100000, 999999))
end

--! \brief Convert a path to a string. This is used to convert a table path to a string path.
--! \param path \string or \table The path to convert. If a string is supplied, it will be returned as is. If a table is supplied, it will be concatenated with dots.
--! \return \string The string representation of the path.
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
        createdAt = getTimestamp(),
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
--! \param idOrCallback \string or \function The ID of the function callback being added, or the callback function itself. If a string is supplied, it will be used as the ID for the callback.
--! \param maybeCallback \function The callback function to call when the key changes. This is optional if the first argument is a function.
--! \return \function The callback function that was added. This can be used to unsubscribe later.
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

    local channel = self:GetChannel(key)

    if not channel[id] then
        channel[id] = {}
    end

    table.insert(channel[id], callback)

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
    local channel = self:GetChannel(key)
    local subscribers = {}

    for k, v in pairs(channel) do
        for k2, v2 in ipairs(v) do
            table.insert(subscribers, v2)
        end
    end

    return subscribers
end

--! \brief Check if a subscription exists for a key. This will return true if the subscription exists, false otherwise.
--! \param key \string The key to check for. Use a \table to check for nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param id \string The ID of the function callback being checked.
--! \return \boolean True if the subscription exists, false otherwise.
function FrameworkZ.Foundation:HasSubscription(key, id)
    local channel = self:GetChannel(key)

    return channel and channel[id] ~= nil
end

--! \brief Fires a callback for a key. This will call the callback for the key with the value supplied.
--! \param key \string The key to fire the callback for. Use a \table to fire the callback for nested values. \see FrameworkZ.Foundation::Subscribe for an example on how to supply a table as a key.
--! \param data \table The standard data to pass to the callback. Generally contains diagnostic information.
--! \param arguments \table The values to pass to the callback. This can be any type of values stored in the table.
--! \return \table A table of return values from the callbacks. The keys are the IDs of the callbacks and the values are the return values from the callbacks.
function FrameworkZ.Foundation:Fire(key, data, arguments)
    if not self:HasChannel(key) then
        print("[FZ] Warning: Received fire event for unknown ID: ", key)
    end

    local returnValues = {}
    local subscribers = self:GetSubscribers(key)

    if subscribers then
        local results

        for id, callback in ipairs(subscribers) do
            results = FrameworkZ.Utilities:Pack(callback(data, FrameworkZ.Utilities:Unpack(arguments)))

            returnValues[id] = results
        end

        local meta = self:GetChannelMeta(key)

        if meta then
            meta.lastFiredAt = getTimestamp()
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

    sendClientCommand(self.NetworksName, "GetData", {
        key = key,
        broadcast = broadcast,
        callbackID = callbackID,
        requestID = requestID,
        args = FrameworkZ.Utilities:Pack(...)
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

    sendClientCommand(self.NetworksName, "SetData", {
        key = key,
        value = value,
        broadcast = broadcast,
        callbackID = callbackID,
        requestID = requestID
    })

    return requestID
end

--! \brief Sends a fire event to the server or client. This is used to send events to subscribers.
--! \param isoPlayer \object The player sending the fire event. If nil, the event will be fired but no confirmation will be sent back (send and forget).
--! \param subscriptionID \string The ID of the subscription to fire. This is the key used to subscribe to the event. It's recommended to use a string matching your function's callback name in a unique way when adding a subscription.
--! \param callback \function The callback to call when the server confirms the fire event. This is optional and can be nil if you don't need confirmation.
--! \param ... \multiple Additional arguments of any amount to pass to the subscription. These can be any type of values except functions as they do not get networked.
--! \return \string The request ID for the fire event. This can be used to track the request and get confirmation later.
function FrameworkZ.Foundation:SendFire(isoPlayer, subscriptionID, callback, ...)
    local playerID = isoPlayer and isoPlayer:getOnlineID() or nil
    local requestID = generateRequestID()

    if callback then
        self.PendingConfirmations[requestID] = {
            playerID = playerID,
            callback = callback,
            subID = subscriptionID,
            sentAt = getTimestamp()
        }
    end

    if isClient() then
        local payload = {
            requestID = requestID,
            subID = subscriptionID,
            args = FrameworkZ.Utilities:Pack(...),
            clientSentAt = getTimestamp()
        }

        sendClientCommand(isoPlayer, self.NetworksName, "SendFire", payload)
    elseif isServer() then
        local payload = {
            playerID = playerID,
            requestID = requestID,
            subID = subscriptionID,
            args = FrameworkZ.Utilities:Pack(...),
            serverSentAt = getTimestamp()
        }

        sendServerCommand(isoPlayer, self.NetworksName, "SendFire", payload)
    end

    return requestID
end

--! \brief Get a nested value from a table using a path. This is used to get values from nested tables.
--! \param root \table The root table to get the value from.
--! \param path \table The path to the value. This is a table of keys to traverse the nested tables.
--! \return \mixed The value at the end of the path, or nil if the path does not exist.
--! \note Example path argument: {"key", "subkey"} == root["key"]["subkey"]
function FrameworkZ.Foundation:GetNestedValue(root, path)
    local current = root

    for _, key in ipairs(path) do
        if type(current) ~= "table" then return nil end
        current = current[key]
    end

    return current
end

--! \brief Set a nested value in a table using a path. This is used to set values in nested tables.
--! \param root \table The root table to set the value in.
--! \param path \table The path to the value. This is a table of keys to traverse the nested tables.
--! \param value \mixed The value to set at the end of the path.
--! \return \mixed The value that was set at the end of the path.
--! \note Example path argument: {"key", "subkey"} == root["key"]["subkey"] = value
function FrameworkZ.Foundation:SetNestedValue(root, path, value)
    local current = root

    for i = 1, #path - 1 do
        local key = path[i]
        current[key] = current[key] or {}
        current = current[key]
    end

    current[path[#path]] = value

    return current[path[#path]]
end

if isServer() then

    --! \brief Handles incoming commands from the client on the server.
    --! \param module \string The name of the module that sent the command. This should match the NetworksName defined in FrameworkZ.Foundation.NetworksName.
    --! \param command \string The command that was sent by the client.
    --! \param isoPlayer \object The player that sent the command. This is the player object that sent the command.
    --! \param arguments \table The arguments that were sent with the command. This contains the data needed to process the command.
    --! \note This function is called on the server when a client sends a command to the server. It processes the command and sends a response back to the client using the networking system.
    function FrameworkZ.Foundation:OnClientCommand(module, command, isoPlayer, arguments)
        if module ~= self.NetworksName then return end

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
                sendServerCommand(isoPlayer, self.NetworksName, "ReturnData", {
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
                    sendServerCommand(onlineUsers:get(i), self.NetworksName, "ReturnData", {
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
                sendServerCommand(isoPlayer, self.NetworksName, "FailedSet", {
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
                sendServerCommand(isoPlayer, self.NetworksName, "ConfirmSet", {
                    key = key,
                    value = newValue,
                    broadcast = false,
                    requestID = arguments.requestID
                })
            else
                local onlineUsers = getOnlinePlayers()

                for i = 0, onlineUsers:size() - 1 do
                    sendServerCommand(onlineUsers:get(i), self.NetworksName, "ConfirmSet", {
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

            sendServerCommand(isoPlayer, self.NetworksName, "ConfirmFire", {
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

                    callback(data, FrameworkZ.Utilities:Unpack(returnArgs))
                end

                self.PendingConfirmations[arguments.requestID] = nil
            end
        end
    end
end

if isClient() then
    
    --! \brief Handles incoming commands from the server on the client.
    --! \param module \string The name of the module that sent the command. This should match the NetworksName defined in FrameworkZ.Foundation.NetworksName.
    --! \param command \string The command that was sent by the server.
    --! \param arguments \table The arguments that were sent with the command. This contains the data needed to process the command.
    --! \note This function is called on the client when the server sends a command to the client. It processes the command and sends a response back to the server using the networking system.
    function FrameworkZ.Foundation:OnServerCommand(module, command, arguments)
        if module ~= self.NetworksName then return end

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

            sendClientCommand(isoPlayer, self.NetworksName, "ConfirmFire", {
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

                    callback(data, FrameworkZ.Utilities:Unpack(returnArgs))
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

--! \brief Cleans up pending confirmations that have not been confirmed within a timeout period.
--! \param timeout \number The timeout in seconds to clean up pending confirmations. Default: 300 seconds (5 minutes).
function FrameworkZ.Foundation:CleanupConfirmations(timeout)
    local now = getTimestamp()

    for id, entry in pairs(self.PendingConfirmations) do
        if now - entry.sentAt > timeout then
            self.PendingConfirmations[id] = nil
            print(("[FZ] Cleaned up stale confirmation: %s"):format(tostring(id)))
        end
    end
end

--! TODO move to shared timer hook
function FrameworkZ.Foundation:EveryDays()
    self:CleanupConfirmations(60 * 5) -- 5 minutes
end

--[[ Hook System



██   ██  ██████   ██████  ██   ██     ███████ ██    ██ ███████ ████████ ███████ ███    ███ 
██   ██ ██    ██ ██    ██ ██  ██      ██       ██  ██  ██         ██    ██      ████  ████ 
███████ ██    ██ ██    ██ █████       ███████   ████   ███████    ██    █████   ██ ████ ██ 
██   ██ ██    ██ ██    ██ ██  ██           ██    ██         ██    ██    ██      ██  ██  ██ 
██   ██  ██████   ██████  ██   ██     ███████    ██    ███████    ██    ███████ ██      ██ 



--]]

--! \brief Categories for framework hooks. HOOK_CATEGORY_FRAMEWORK = "framework"
HOOK_CATEGORY_FRAMEWORK = "framework"

--! \brief Categories for module hooks. HOOK_CATEGORY_MODULE = "module"
HOOK_CATEGORY_MODULE = "module"

--! \brief Categories for gamemode hooks. HOOK_CATEGORY_GAMEMODE = "gamemode"
HOOK_CATEGORY_GAMEMODE = "gamemode"

--! \brief Categories for plugin hooks. HOOK_CATEGORY_PLUGIN = "plugin"
HOOK_CATEGORY_PLUGIN = "plugin"

--! \brief Categories for generic hooks. HOOK_CATEGORY_GENERIC = "generic"
HOOK_CATEGORY_GENERIC = "generic"

--! \brief Collection of hook handlers organized by category. Each category contains hooks that can be registered.
FrameworkZ.Foundation.HookHandlers = {
    framework = {},
    module = {},
    gamemode = {},
    plugin = {},
    generic = {}
}

--! \brief Collection of registered hook functions organized by category and hook name.
FrameworkZ.Foundation.RegisteredHooks = {
    framework = {},
    module = {},
    gamemode = {},
    plugin = {},
    generic = {}
}

--! \brief Add a new hook handler to the list.
--! \param hookName \string The name of the hook handler to add.
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
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
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
function FrameworkZ.Foundation:RemoveHookHandler(hookName, category)
    category = category or HOOK_CATEGORY_GENERIC
    self.HookHandlers[category][hookName] = nil
end

--! \brief Register hook handlers for the framework.
function FrameworkZ.Foundation:RegisterFrameworkHandler()
    self:RegisterHandlers(self, HOOK_CATEGORY_FRAMEWORK)
end

--! \brief Unregister hook handlers for the framework.
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
--! \param gamemode \table The gamemode table containing the functions.
function FrameworkZ.Foundation:RegisterGamemodeHandler(gamemode)
    self:RegisterHandlers(gamemode, HOOK_CATEGORY_GAMEMODE)
end

--! \brief Unregister hook handlers for the gamemode.
--! \param gamemode \table The gamemode table containing the functions.
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

--! \brief Register generic hook handlers that don't belong to a specific object.
function FrameworkZ.Foundation:RegisterGenericHandler()
    self:RegisterHandlers(nil, HOOK_CATEGORY_GENERIC)
end

--! \brief Unregister generic hook handlers that don't belong to a specific object.
function FrameworkZ.Foundation:UnregisterGenericHandler()
    self:UnregisterHandlers(nil, HOOK_CATEGORY_GENERIC)
end

--! \brief Register handlers for a specific category.
--! \param objectOrHandlers \table The object containing the functions, or nil for generic handlers.
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
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
--! \param objectOrHandlers \table The object containing the functions, or nil for generic handlers.
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
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
--! \param object \table? The object containing the function.
--! \param functionName \string? The name of the function to call.
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
function FrameworkZ.Foundation:RegisterHandler(hookName, handler, object, functionName, category)
    category = category or HOOK_CATEGORY_GENERIC
    self.RegisteredHooks[category][hookName] = self.RegisteredHooks[category][hookName] or {}
    --object.__skipWrap = true

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
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
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
--! \param category \string The category of the hook (framework, module, plugin, generic). Defaults to HOOK_CATEGORY_GENERIC if not specified.
--! \param ... \multiple Additional arguments to pass to the hook functions.
function FrameworkZ.Foundation:ExecuteHook(hookName, category, ...)
    category = category or HOOK_CATEGORY_GENERIC
    local args = FrameworkZ.Utilities:Pack(...)

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
                        func(FrameworkZ.Utilities:Unpack(args))
                    else
                        if args[1] ~= object then
                            func(object, FrameworkZ.Utilities:Unpack(args))
                        else
                            func(FrameworkZ.Utilities:Unpack(args))
                        end
                    end
                else
                    func(FrameworkZ.Utilities:Unpack(args))
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

--[[ Hooks



██   ██  ██████   ██████  ██   ██ ███████ 
██   ██ ██    ██ ██    ██ ██  ██  ██      
███████ ██    ██ ██    ██ █████   ███████ 
██   ██ ██    ██ ██    ██ ██  ██       ██ 
██   ██  ██████   ██████  ██   ██ ███████ 



--]]

--! \brief Daily timer event that executes once per in-game day.
function FrameworkZ.Foundation.Events:EveryDays()
    self:ExecuteAllHooks("EveryDays")
end
FrameworkZ.Foundation:AddAllHookHandlers("EveryDays")

--! \brief The LoadGridSquare event is not defined for hook usage because of performance reasons.

--! \brief Handles client commands received on the server.
--! \param module \string The module name that sent the command.
--! \param command \string The command that was sent.
--! \param isoPlayer \object The player object that sent the command.
--! \param arguments \table The arguments that were sent with the command.
function FrameworkZ.Foundation.Events:OnClientCommand(module, command, isoPlayer, arguments)
    self:ExecuteAllHooks("OnClientCommand", module, command, isoPlayer, arguments)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnClientCommand")

--! \brief Called when a player connects to the server.
function FrameworkZ.Foundation.Events:OnConnected()
    self:ExecuteAllHooks("OnConnected")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnConnected")

--! \brief Called when a new player character is created.
function FrameworkZ.Foundation.Events:OnCreatePlayer()
    self:ExecuteAllHooks("OnCreatePlayer")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCreatePlayer")

--! \brief Called when a player disconnects from the server.
function FrameworkZ.Foundation.Events:OnDisconnect()
    self:ExecuteAllHooks("OnDisconnect")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnDisconnect")

--! \brief Called when filling an inventory object's context menu.
--! \param player \object The player object.
--! \param context \object The context menu object.
--! \param items \table The items being examined.
function FrameworkZ.Foundation.Events:OnFillInventoryObjectContextMenu(player, context, items)
    self:ExecuteAllHooks("OnFillInventoryObjectContextMenu", player, context, items)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnFillInventoryObjectContextMenu")

--! \brief Called when filling a world object's context menu.
--! \param playerNumber \integer The player number.
--! \param context \object The context menu object.
--! \param worldObjects \table The world objects being examined.
--! \param test \boolean Test parameter.
function FrameworkZ.Foundation.Events:OnFillWorldObjectContextMenu(playerNumber, context, worldObjects, test)
    self:ExecuteAllHooks("OnFillWorldObjectContextMenu", playerNumber, context, worldObjects, test)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnFillWorldObjectContextMenu")

--! \brief Called when the game starts.
function FrameworkZ.Foundation.Events:OnGameStart()
    self:ExecuteAllHooks("OnGameStart")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnGameStart")

--! \brief Called when global mod data is initialized.
--! \param isNewGame \boolean Whether this is a new game or loading an existing one.
function FrameworkZ.Foundation.Events:OnInitGlobalModData(isNewGame)
    self:ExecuteAllHooks("OnInitGlobalModData", isNewGame)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnInitGlobalModData")

--! \brief Called when a key starts being pressed.
--! \param key \integer The key code that was pressed.
function FrameworkZ.Foundation.Events:OnKeyStartPressed(key)
    self:ExecuteAllHooks("OnKeyStartPressed", key)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnKeyStartPressed")

--! \brief Called when entering the main menu.
function FrameworkZ.Foundation.Events:OnMainMenuEnter()
    self:ExecuteAllHooks("OnMainMenuEnter")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnMainMenuEnter")

--! \brief Called when the left mouse button is pressed down on an object.
--! \param object \object The object that was clicked.
--! \param x \integer The X coordinate of the click.
--! \param y \integer The Y coordinate of the click.
function FrameworkZ.Foundation.Events:OnObjectLeftMouseButtonDown(object, x, y)
    self:ExecuteAllHooks("OnObjectLeftMouseButtonDown", object, x, y)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnObjectLeftMouseButtonDown")

--! \brief Called when a player dies.
--! \param player \object The player object that died.
function FrameworkZ.Foundation.Events:OnPlayerDeath(player)
    self:ExecuteAllHooks("OnPlayerDeath", player)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnPlayerDeath")

--! \brief Called before filling an inventory object's context menu.
--! \param playerID \integer The player ID.
--! \param context \object The context menu object.
--! \param items \table The items being examined.
function FrameworkZ.Foundation.Events:OnPreFillInventoryObjectContextMenu(playerID, context, items)
    self:ExecuteAllHooks("OnPreFillInventoryObjectContextMenu", playerID, context, items)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnPreFillInventoryObjectContextMenu")

--! \brief Called when global mod data is received.
--! \param key \string The key of the data received.
--! \param data \mixed The data that was received.
function FrameworkZ.Foundation.Events:OnReceiveGlobalModData(key, data)
    self:ExecuteAllHooks("OnReceiveGlobalModData", key, data)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnReceiveGlobalModData")

--! \brief Called when the Lua state is reset.
--! \param reason \string The reason for the reset.
function FrameworkZ.Foundation.Events:OnResetLua(reason)
    self:ExecuteAllHooks("OnResetLua", reason)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnResetLua")

--! \brief Handles server commands received on the client.
--! \param module \string The module name that sent the command.
--! \param command \string The command that was sent.
--! \param arguments \table The arguments that were sent with the command.
function FrameworkZ.Foundation.Events:OnServerCommand(module, command, arguments)
    self:ExecuteAllHooks("OnServerCommand", module, command, arguments)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnServerCommand")

--! \brief Called when the server starts.
function FrameworkZ.Foundation.Events:OnServerStarted()
    self:ExecuteAllHooks("OnServerStarted")
end
FrameworkZ.Foundation:AddAllHookHandlers("OnServerStarted")

--! \brief The OnTick event is not defined for hook usage because of performance reasons.

--[[ Hook Callbacks



██   ██  ██████   ██████  ██   ██      ██████  █████  ██      ██      ██████   █████   ██████ ██   ██ ███████ 
██   ██ ██    ██ ██    ██ ██  ██      ██      ██   ██ ██      ██      ██   ██ ██   ██ ██      ██  ██  ██      
███████ ██    ██ ██    ██ █████       ██      ███████ ██      ██      ██████  ███████ ██      █████   ███████ 
██   ██ ██    ██ ██    ██ ██  ██      ██      ██   ██ ██      ██      ██   ██ ██   ██ ██      ██  ██       ██ 
██   ██  ██████   ██████  ██   ██      ██████ ██   ██ ███████ ███████ ██████  ██   ██  ██████ ██   ██ ███████ 



--]]

--! \brief Local variable to store the initialization start time.
local startTime

--! \brief Local counter for server save ticks.
local serverSaveTick = 0

--! \brief Server tick handler that manages periodic data saving.
function FrameworkZ.Foundation:ServerTick()
    if serverSaveTick >= FrameworkZ.Config.Options.TicksUntilServerSave then
        self:SaveData()
        print("[FZ] Server data saved...")

        serverSaveTick = 0
    else
        serverSaveTick = serverSaveTick + 1
    end
end

--! \brief Starts the server tick system that manages timers and periodic operations.
function FrameworkZ.Foundation:StartServerTick()
    if not isServer() then return end

    local loops = 0

    FrameworkZ.Timers:Create("FZ_SERVER_TICK", FrameworkZ.Config.Options.ServerTickInterval, 0, function()
        self:ExecuteAllHooks("ServerTick")
    end)

    FrameworkZ.Timers:Create("FZ_SERVER_TIMER", 1, 0, function()
        self:ExecuteAllHooks("ServerTimer", loops)

        loops = loops + 1
    end)
end
FrameworkZ.Foundation:AddAllHookHandlers("ServerTick")
FrameworkZ.Foundation:AddAllHookHandlers("ServerTimer")

--! \brief Callback for when the server starts. Initializes server-side tick systems.
function FrameworkZ.Foundation:OnServerStarted()
    if isServer() then
        self:StartServerTick()
    end
end

--! \brief Called when the game starts. Executes the OnGameStart function for all modules.
function FrameworkZ.Foundation:OnGameStart()
    if isClient() then
        self.Initialized = false

        local isoPlayer = getPlayer()
        startTime = getTimestampMs()

        self:ExecuteFrameworkHooks("PreInitializeClient", isoPlayer)
    end
end

--! \brief Pre-initialization phase for client setup. Sets up the UI and executes module hooks.
--! \param isoPlayer \object The player object being initialized.
function FrameworkZ.Foundation:PreInitializeClient(isoPlayer)
    FrameworkZ.Interfaces:Initialize()

    local sidebar = ISEquippedItem.instance
    self.fzuiTabMenu = FrameworkZ.UI.TabMenu:new(sidebar:getX(), sidebar:getY() + sidebar:getHeight() + 10, sidebar:getWidth(), 40, getPlayer())
    self.fzuiTabMenu:initialise()
    self.fzuiTabMenu:addToUIManager()

    local ui = FrameworkZ.UI.Introduction:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), getPlayer())
    ui:initialise()
    ui:addToUIManager()

    self:ExecuteModuleHooks("PreInitializeClient", isoPlayer)
    self:ExecuteGamemodeHooks("PreInitializeClient",isoPlayer)
    self:ExecutePluginHooks("PreInitializeClient", isoPlayer)

    self:ExecuteFrameworkHooks("InitializeClient", isoPlayer)
end
FrameworkZ.Foundation:AddAllHookHandlers("PreInitializeClient")

--! \brief Main client initialization function. Sets up player state and communicates with the server.
--! \param isoPlayer \object The player object being initialized.
function FrameworkZ.Foundation:InitializeClient(isoPlayer)
    FrameworkZ.Timers:Simple(FrameworkZ.Config.Options.InitializationDuration, function()
        self:SendFire(isoPlayer, "FrameworkZ.Foundation.OnInitializePlayer", function(data, serverSideInitialized, playerData, charactersData)
            if serverSideInitialized then
                local username = isoPlayer:getUsername()

                if not VoiceManager:playerGetMute(username) then
                    VoiceManager:playerSetMute(username)
                end

                isoPlayer:clearWornItems()
                isoPlayer:getInventory():clear()

                local gown = isoPlayer:getInventory():AddItem("Base.HospitalGown")
                isoPlayer:setWornItem(gown:getBodyLocation(), gown)

                local slippers = isoPlayer:getInventory():AddItem("Base.Shoes_Slippers")
                local color = Color.new(1, 1, 1, 1);
                slippers:setColor(color);
                slippers:getVisual():setTint(ImmutableColor.new(color));
                slippers:setCustomColor(true);
                isoPlayer:setWornItem(slippers:getBodyLocation(), slippers)

                isoPlayer:setGodMod(true)
                isoPlayer:setInvincible(true)
                isoPlayer:setHealth(1.0)

                local bodyParts = isoPlayer:getBodyDamage():getBodyParts()
                for i=1, bodyParts:size() do
                    local bP = bodyParts:get(i-1)
                    bP:RestoreToFullHealth();

                    if bP:getStiffness() > 0 then
                        bP:setStiffness(0)
                        isoPlayer:getFitness():removeStiffnessValue(BodyPartType.ToString(bP:getType()))
                    end
                end

                isoPlayer:setInvisible(true)
                isoPlayer:setGhostMode(true)
                isoPlayer:setNoClip(true)

                isoPlayer:setX(FrameworkZ.Config.Options.LimboX)
                isoPlayer:setY(FrameworkZ.Config.Options.LimboY)
                isoPlayer:setZ(FrameworkZ.Config.Options.LimboZ)
                isoPlayer:setLx(FrameworkZ.Config.Options.LimboX)
                isoPlayer:setLy(FrameworkZ.Config.Options.LimboY)
                isoPlayer:setLz(FrameworkZ.Config.Options.LimboZ)

                self:InitializePlayer(isoPlayer, playerData, charactersData)
            end
        end)
    end)
end
FrameworkZ.Foundation:AddAllHookHandlers("InitializeClient")

--! \brief Server-side handler for player initialization requests.
--! \param data \table The data containing the isoPlayer object.
--! \return \multiple Returns the result of InitializePlayer function.
if isServer() then
    function FrameworkZ.Foundation.OnInitializePlayer(data)
        return FrameworkZ.Foundation:InitializePlayer(data.isoPlayer)
    end
end

--! \brief Restores player data from storage or creates new data if none exists.
--! \param isoPlayer \object The player's ISO object.
--! \param player \object The framework player object.
--! \param username \string The player's username.
--! \param playerData \table (Optional) Existing player data on client-side.
--! \param charactersData \table (Optional) Existing character data on client-side.
--! \return \table, \table The player data and character data, or false if new.
function FrameworkZ.Foundation:RestorePlayer(isoPlayer, player, username, playerData, charactersData)
    if not player then return end
    if isClient() and (not playerData or not charactersData) then return end

    if isServer() then
        playerData = self:GetData(isoPlayer, "Players", username)
        charactersData = self:GetData(isoPlayer, "Characters", username)
    end

    if playerData then
        player:RestoreData(playerData)

        if charactersData then
            player:SetCharacters(charactersData)

            return playerData, charactersData
        elseif isServer() then
            local characters = player:GetCharacters()
            self:SetData(isoPlayer, "Characters", username, characters)
        end

        return playerData, false
    elseif isServer() then
        local saveableData = player:GetSaveableData()
        local characters = player:GetCharacters()

        self:SetData(isoPlayer, "Players", username, saveableData)
        self:SetData(isoPlayer, "Characters", username, characters)
    end

    return false, false
end

--! \brief Initializes a player with framework data and sets up their initial state.
--! \param isoPlayer \object The player's ISO object.
--! \param playerData \table (Optional) Existing player data for restoration.
--! \param charactersData \table (Optional) Existing character data for restoration.
--! \return \boolean, \table, \table Returns success status, player data, and character data.
function FrameworkZ.Foundation:InitializePlayer(isoPlayer, playerData, charactersData)
    if not isoPlayer then return false, nil, nil end

    local player = FrameworkZ.Players:Initialize(isoPlayer) if not player then return false end
    local username = player:GetUsername()
    local options = FrameworkZ.Config.Options
    local x, y, z = options.LimboX, options.LimboY, options.LimboZ

    isoPlayer:setX(x)
    isoPlayer:setY(y)
    isoPlayer:setZ(z)
    isoPlayer:setLx(x)
    isoPlayer:setLy(y)
    isoPlayer:setLz(z)

    if isServer() then
        playerData, charactersData = self:RestorePlayer(isoPlayer, player, username)
    elseif isClient() then
        playerData, charactersData = self:RestorePlayer(isoPlayer, player, username, playerData, charactersData)
    end

    if playerData then
        print("[FZ] Restored player for '" .. username .. "'.")
    else
        print("[FZ] Created new player for '" .. username .. "'.")
    end

    if charactersData then
        local charactersRestored = ""

        for k, character in pairs(charactersData) do
            charactersRestored = "#" .. k .. " " .. charactersRestored .. character[FZ_ENUM_CHARACTER_INFO_NAME] .. ", "
        end

        charactersRestored = string.sub(charactersRestored, 1, -3) -- Remove the last comma and space

        print("[FZ] Restored characters for '" .. username .. "': " .. (charactersRestored == "" and "[N/A]" or charactersRestored))
    else
        print("[FZ] Created new characters field for '" .. username .. "'.")
    end

    self:ExecuteModuleHooks("InitializeClient", isoPlayer)
    self:ExecuteGamemodeHooks("InitializeClient", isoPlayer)
    self:ExecutePluginHooks("InitializeClient", isoPlayer)

    self:ExecuteFrameworkHooks("PostInitializeClient", player)

    return true, playerData, charactersData
end

--! \brief Post-initialization phase that completes the client setup and shows success notification.
--! \param player \object The framework player object that has been initialized.
function FrameworkZ.Foundation:PostInitializeClient(player)
    self:ExecuteModuleHooks("PostInitializeClient", player)
    self:ExecuteGamemodeHooks("PostInitializeClient", player)
    self:ExecutePluginHooks("PostInitializeClient", player)

    if isClient() then
        FrameworkZ.Foundation.InitializationNotification = FrameworkZ.Notifications:AddToQueue("Initialized in " .. tostring(string.format(" %.2f", (getTimestampMs() - startTime - FrameworkZ.Config:GetOption("InitializationDuration") * 1000) / 1000)) .. " seconds.", FrameworkZ.Notifications.Types.Success, nil, FrameworkZ.UI.Introduction.instance)
    end

    self.Initialized = true
end
FrameworkZ.Foundation:AddAllHookHandlers("PostInitializeClient")

--! \brief Network callback function for teleporting a player to the limbo area.
--! \param data \table The data containing the isoPlayer object.
--! \return \boolean Returns true if successful, false otherwise.
function FrameworkZ.Foundation.OnTeleportToLimbo(data)
    local isoPlayer = data.isoPlayer

    if not isoPlayer then print("[FZ] ERROR: Failed to teleport player to limbo, isoPlayer is nil.") return false end
    if not FrameworkZ.Foundation:TeleportToLimbo(isoPlayer) then print("[FZ] ERROR: Failed to teleport player to limbo.") return false end

    return true
end

--! \brief Teleports a player to the configured limbo location.
--! \param isoPlayer \object The player object to teleport.
--! \return \boolean Returns true if successful, false if the player object is invalid.
function FrameworkZ.Foundation:TeleportToLimbo(isoPlayer)
    if not isoPlayer then return false end

    local x, y, z = FrameworkZ.Config:GetOption("LimboX"), FrameworkZ.Config:GetOption("LimboY"), FrameworkZ.Config:GetOption("LimboZ")

    isoPlayer:setX(x)
    isoPlayer:setY(y)
    isoPlayer:setZ(z)
    isoPlayer:setLx(x)
    isoPlayer:setLy(y)
    isoPlayer:setLz(z)

    return true
end

--! \brief Hook handler registration for PlayerTick events.
FrameworkZ.Foundation:AddAllHookHandlers("PlayerTick")


--[[ Data Storage



██████   █████  ████████  █████      ███████ ████████  ██████  ██████   █████   ██████  ███████ 
██   ██ ██   ██    ██    ██   ██     ██         ██    ██    ██ ██   ██ ██   ██ ██       ██      
██   ██ ███████    ██    ███████     ███████    ██    ██    ██ ██████  ███████ ██   ███ █████   
██   ██ ██   ██    ██    ██   ██          ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██      
██████  ██   ██    ██    ██   ██     ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████ 



--]]

--! \brief STORAGE BACKEND - The base name used for storage operations.
FrameworkZ.Foundation.StorageName = "FZ_STORAGE"

--! \brief Collection of registered namespaces for data storage.
FrameworkZ.Foundation.Namespaces = FrameworkZ.Foundation.Namespaces or {}

--! \brief Queues for batching synchronization operations.
FrameworkZ.Foundation.SyncQueues = FrameworkZ.Foundation.SyncQueues or {}

--! \brief Registers a storage namespace, e.g., "Players"
--! \param name \string The name of the namespace to register.
--! \note This must be used in the shared scope within an OnInitGlobalModData function.
function FrameworkZ.Foundation:RegisterNamespace(name)
    if isServer() then
        self.Namespaces[name] = ModData.getOrCreate(self.StorageName .. "_" .. name)
    end

    if isClient() then
        self.Namespaces[name] = self.Namespaces[name] or {}
    end
end

--! \brief Gets data from local storage using namespace and keys.
--! \param namespace \string The namespace to retrieve data from.
--! \param keys \string or \table The key(s) to retrieve. If table, performs nested lookup.
--! \return \mixed The retrieved data, or an error code if not found.
function FrameworkZ.Foundation:GetLocalData(namespace, keys)
    local ns = self:GetNamespace(namespace)

    if ns then
        if not keys then
            return ns or "FZ ERROR CODE: 1"
        elseif type(keys) == "string" then
            return ns[keys] or "FZ ERROR CODE: 1"
        elseif type(keys) == "table" then
            return self:GetNestedValue(ns, keys) or "FZ ERROR CODE: 1"
        end
    end

    print("[FZ] WARNING: Failed to get value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")

    return "FZ ERROR CODE: 1"
end

--! \brief Sets data in local storage using namespace and keys.
--! \param namespace \string The namespace to store data in.
--! \param keys \string or \table The key(s) to set. If table, performs nested assignment.
--! \param value \mixed The value to store.
--! \return \boolean Returns true if successful, false otherwise.
function FrameworkZ.Foundation:SetLocalData(namespace, keys, value)
    local ns = self:GetNamespace(namespace)

    if ns then
        if not keys then
            self.Namespaces[namespace] = value
        elseif type(keys) == "string" then
            self.Namespaces[namespace][keys] = value
        elseif type(keys) == "table" then
            value = self:SetNestedValue(ns, keys, value)
        end

        return true
    end

    print("[FZ] ERROR: Failed to set value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")

    return false
end

--! \brief Client-side callback for saving data.
--! \param data \table The data containing the isoPlayer object.
if isClient() then

    function FrameworkZ.Foundation.OnSaveData(data)
        FrameworkZ.Foundation:SaveData(data.isoPlayer)
    end

    --! \brief Client-side callback for saving a specific namespace.
    --! \param data \table The data containing the isoPlayer and namespace.
    function FrameworkZ.Foundation.OnSaveNamespace(data)
        FrameworkZ.Foundation:SaveNamespace(data.isoPlayer, data.namespace)
    end

--! \brief Server-side callback for saving data.
--! \param data \table The data containing the isoPlayer object.
elseif isServer() then

    function FrameworkZ.Foundation.OnSaveData(data)
        FrameworkZ.Foundation:SaveData(data.isoPlayer)
    end

    --! \brief Server-side callback for saving a specific namespace.
    --! \param data \table The data containing the isoPlayer object.
    --! \param namespace \string The namespace to save.
    function FrameworkZ.Foundation.OnSaveNamespace(data, namespace)
        FrameworkZ.Foundation:SaveNamespace(data.isoPlayer, namespace)
    end
end

--! \brief Network callback for getting data from storage.
--! \param data \table The request data.
--! \param namespace \string The namespace to retrieve from.
--! \param keys \string or \table The key(s) to retrieve.
--! \param subscriptionID \string (Optional) Subscription ID for callback.
--! \return \mixed The retrieved value.
function FrameworkZ.Foundation.OnGetData(data, namespace, keys, subscriptionID)
    if isServer() then
        local value = FrameworkZ.Foundation:GetLocalData(namespace, keys)

        if value ~= "FZ ERROR CODE: 1" and subscriptionID then
            FrameworkZ.Foundation:Fire(subscriptionID, data, FrameworkZ.Utilities:Pack(namespace, keys, value))
        end

        return value
    end
end

--! \brief Network callback for setting data in storage.
--! \param data \table The request data.
--! \param namespace \string The namespace to store in.
--! \param keys \string or \table The key(s) to set.
--! \param value \mixed The value to store.
--! \param subscriptionID \string (Optional) Subscription ID for callback.
--! \param broadcast \boolean Whether to broadcast the change.
--! \return \boolean Success status.
function FrameworkZ.Foundation.OnSetData(data, namespace, keys, value, subscriptionID, broadcast)
    if isServer() then
        if not FrameworkZ.Foundation:SetLocalData(namespace, keys, value) then
            return false
        end

        if subscriptionID then
            FrameworkZ.Foundation:Fire(subscriptionID, data, FrameworkZ.Utilities:Pack(namespace, keys, value))
        end

        -- Broadcast is handled here because the value should be managed before broadcasting [instead of in FrameworkZ.Foundation:Set()].
        if broadcast then
            FrameworkZ.Foundation:Broadcast(namespace, keys, value)
        end

        return true
    end
end

--! \brief Hook handlers for storage get and set operations.
FrameworkZ.Foundation:AddAllHookHandlers("OnStorageGet")
FrameworkZ.Foundation:AddAllHookHandlers("OnStorageSet")

--! \brief Gets a value from a namespace by key(s).
--! \param isoPlayer \object (Optional) The player to get the value for. This is only used on the client to send a request to the server.
--! \param namespace \string The namespace to get the value from.
--! \param keys \string or \table The key(s) to get the value for. Supplying a table will do a lookup through all keys and get value at the last index.
--! \param subscriptionID \string (Optional) A unique identifier for the subscription to be fired server-side after the value has been retrieved.
--! \param callback \function (Optional) A callback function to call after the value is retrieved. This is only used on the client to handle the response from the server.
--! \return \any (except \function) The value for the key in the namespace, or false if the namespace or key does not exist. Server-side only.
--! \note If called on the client, the value may only be accessed in the callback immediately, or later after data has synchronized.
function FrameworkZ.Foundation:GetData(isoPlayer, namespace, keys, subscriptionID, callback)
    if isClient() then
        self:SendFire(isoPlayer, "FrameworkZ.Foundation.OnGetData", function(data, value)
            if value == "FZ ERROR CODE: 1" then
                print("[FZ] WARNING: Failed to get server-side value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")
                return
            end

            self:SetLocalData(namespace, keys, value)

            if callback then
                callback(isoPlayer, namespace, keys, value)
            end
        end, namespace, keys, subscriptionID)
    elseif isServer() then
        local value = self:GetLocalData(namespace, keys)

        if value == "FZ ERROR CODE: 1" then
            print("[FZ] WARNING: Failed to get server-side value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")
            return false
        end

        if callback then
            callback(isoPlayer, namespace, keys, value)
        end

        return value
    end
end

--! \brief Sets a value in a namespace and (optionally) broadcasts to all clients.
--! \param isoPlayer \object (Optional when called server-side only) The player to set the value for. This is only used on the client to send a request to the server.
--! \param namespace \string The namespace to set the value in.
--! \param keys \string or \table The key(s) to set the value for. Supplying a table will do a lookup through all keys and set value at the last index.
--! \param value \any (except \function) The value to set.
--! \param subscriptionID \string (Optional) A unique identifier for the subscription to be fired server-side after the value has been set.
--! \param broadcast \boolean (Optional) Whether or not to broadcast the value to all clients.
--! \param callback \function (Optional) A callback function to call after the value is set. This is only used on the client to handle the response from the server.
--! \return \boolean Whether or not the value was set successfully. Server-side only.
--! \note If called on the client, the value may only be accessed in the callback immediately, or later after data has synchronized.
function FrameworkZ.Foundation:SetData(isoPlayer, namespace, keys, value, subscriptionID, broadcast, callback)
    if isClient() then
        self:SendFire(isoPlayer, "FrameworkZ.Foundation.OnSetData", function(data, success)
            if not success then
                print("[FZ] ERROR: Failed to set server-side value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")
                return
            end

            self:SetLocalData(namespace, keys, value)

            if callback then
                callback(isoPlayer, namespace, keys, value)
            end
        end, namespace, keys, value, subscriptionID, broadcast)
    elseif isServer() then
        local success = self:SetLocalData(namespace, keys, value)

        if not success then
            print("[FZ] ERROR: Failed to set server-side value for namespace '" .. (namespace and tostring(namespace) or "null") .. "' and key(s) '" .. FrameworkZ.Utilities:DumpTable(keys) .. "'")
            return false
        end

        if callback then
            callback(isoPlayer, namespace, keys, value)
        end

        return success
    end
end

--! \brief Restores data from storage for client-server synchronization.
--! \param isoPlayer \object The player object.
--! \param command \string The command identifier.
--! \param namespace \string The namespace to restore from.
--! \param keys \string or \table The key(s) to restore.
--! \param callback \function Callback function to handle the restored data.
--! \return \boolean Returns true if successful on server, varies on client.
function FrameworkZ.Foundation:RestoreData(isoPlayer, command, namespace, keys, callback)
    if isServer() then
        local stored = self:GetLocalData(namespace, keys)

        if stored and type(stored) == "table" then
            --[[for k, v in pairs(stored) do
                object[k] = v
            end--]]

            if callback then
                callback(true, stored)
            end

            return true
        end

        if callback then
            callback(false)
        end

        return false
    elseif isClient() then
        local handlerName = "RestoreData_" .. tostring(namespace) .. "_" .. tostring(command)

        local function tempHook(_isoPlayer, _command, _namespace, _keys, value)
            if _namespace == namespace and _command == command then
                if value then
                    if callback then callback(true, value) end
                else
                    if callback then callback(false) end
                end

                -- Unregister this handler after first use
                FrameworkZ.Foundation:UnregisterHandler("OnStorageGet", tempHook, nil, handlerName, HOOK_CATEGORY_FRAMEWORK)
            end
        end

        FrameworkZ.Foundation:RegisterHandler("OnStorageGet", tempHook, nil, handlerName, HOOK_CATEGORY_FRAMEWORK)
        self:GetData(isoPlayer, command, namespace, keys)
    end
end

--! \brief Saves all namespace data to persistent storage.
--! \param isoPlayer \object (Optional) The player object. Used on client to send request to server.
function FrameworkZ.Foundation:SaveData(isoPlayer)
    if isClient() then
        self:SendFire(isoPlayer, "FrameworkZ.Foundation.OnSaveData", nil)
    elseif isServer() then
        for namespace, data in pairs(self.Namespaces) do
            ModData.add(self.StorageName .. "_" .. namespace, data)
        end
    end
end

--! \brief Saves a specific namespace to persistent storage.
--! \param isoPlayer \object (Optional) The player object. Used on client to send request to server.
--! \param namespace \string The namespace to save.
function FrameworkZ.Foundation:SaveNamespace(isoPlayer, namespace)
    if isClient() then
        self:SendFire(isoPlayer, "FrameworkZ.Foundation.OnSaveNamespace", nil, namespace)
    elseif isServer() then
        local data = self.Namespaces[namespace]

        if data then
            ModData.add(self.StorageName .. "_" .. namespace, data)
        end
    end
end

--! \brief Removes a key from a namespace and broadcasts removal.
--! \param namespace \string The namespace to remove from.
--! \param key \string The key to remove.
function FrameworkZ.Foundation:RemoveData(namespace, key)
    if isServer() then
        local ns = self.Namespaces[namespace]
        if ns then
            ns[key] = nil
            self:Broadcast(namespace, key, true)
        end
    end
end

--! \brief Retrieves the entire namespace table.
--! \param namespace \string The namespace to retrieve.
--! \return \table The namespace table or nil if not found.
function FrameworkZ.Foundation:GetNamespace(namespace)
    return self.Namespaces[namespace]
end

--! \brief Sends a specific key to a specific player.
--! \param isoPlayer \object The player to send the data to.
--! \param namespace \string The namespace containing the data.
--! \param key \string The key to send.
function FrameworkZ.Foundation:SyncToPlayer(isoPlayer, namespace, key)
    self:SendFire(isoPlayer, "FrameworkZ.Storage.OnSync", function(data, success)
        if success and data and data.namespace and data.key and data.value then
            self.Namespaces[data.namespace] = self.Namespaces[data.namespace] or {}
            self.Namespaces[data.namespace][data.key] = data.value
        end
    end, {
        namespace = namespace,
        key = key,
        isoPlayer = isoPlayer
    })
end

--! \brief Broadcasts updated or removed data to all clients.
--! \param namespace \string The namespace containing the data.
--! \param key \string The key being broadcast.
--! \param remove \boolean Whether this is a removal operation.
function FrameworkZ.Foundation:Broadcast(namespace, key, remove)
    local value = self:Get(namespace, key)

    self:SendFire(nil, remove and "FrameworkZ.Storage.OnRemove" or "FrameworkZ.Storage.OnSyncBroadcast", {
        namespace = namespace,
        key = key,
        value = value
    })
end

--! \brief Server-side response to client sync request.
--! \param data \table The sync request data containing namespace and key.
--! \return \table Returns a table with namespace, key, and value if successful.
function FrameworkZ.Foundation.OnSync(data)
    local namespace, key = data.namespace, data.key
    if not namespace or not key then return false end
    local value = FrameworkZ.Foundation:Get(namespace, key)
    if not value then return false end
    return { namespace = namespace, key = key, value = value }
end
--FrameworkZ.Foundation:Subscribe("FrameworkZ.Storage.OnSync", FrameworkZ.Foundation.OnSync)

--! \brief Client receives sync data from broadcast.
--! \param data \table The broadcast data containing namespace, key, and value.
function FrameworkZ.Foundation.OnSyncBroadcast(data)
    if not data.namespace or not data.key then return end
    FrameworkZ.Foundation.Namespaces[data.namespace] = FrameworkZ.Foundation.Namespaces[data.namespace] or {}
    FrameworkZ.Foundation.Namespaces[data.namespace][data.key] = data.value
end
--FrameworkZ.Foundation:Subscribe("FrameworkZ.Storage.OnSyncBroadcast", FrameworkZ.Foundation.OnSyncBroadcast)

--! \brief Client receives key removal broadcast.
--! \param data \table The removal data containing namespace and key.
function FrameworkZ.Foundation.OnRemoveData(data)
    if not data.namespace or not data.key then return end
    local ns = FrameworkZ.Foundation.Namespaces[data.namespace]
    if ns then ns[data.key] = nil end
end
--FrameworkZ.Foundation:Subscribe("FrameworkZ.Storage.OnRemoveData", FrameworkZ.Foundation.OnRemove)

--! \brief Queue a key in a namespace for batch synchronization.
--! \param isoPlayer \object The player to queue sync for.
--! \param namespace \string The namespace containing the data.
--! \param key \string The key to sync.
function FrameworkZ.Foundation:QueueBatchSync(isoPlayer, namespace, key)
    if not isoPlayer then return end
    local username = isoPlayer:getUsername()
    self.SyncQueues[username] = self.SyncQueues[username] or {}
    table.insert(self.SyncQueues[username], { namespace = namespace, key = key })
end

--! \brief Clear the sync queue for a player.
--! \param isoPlayer \object The player whose queue to clear.
function FrameworkZ.Foundation:ClearBatchSyncQueue(isoPlayer)
    if isoPlayer and isoPlayer:getUsername() then
        self.SyncQueues[isoPlayer:getUsername()] = nil
    end
end

--! \brief Begin processing the queued keys for a player with a timer-based batch system.
--! \param isoPlayer \object The player to sync data for.
--! \param interval \number (Optional) The interval between sync operations. Default: 0.1 seconds.
--! \param onComplete \function (Optional) Callback to call when sync is complete.
function FrameworkZ.Foundation:StartBatchSync(isoPlayer, interval, onComplete)
    if not isoPlayer then return end
    local username = isoPlayer:getUsername()
    local queue = self.SyncQueues[username]
    if not queue or #queue == 0 then return end

    local tickRate = interval or 0.1
    local timerName = "BatchSync_" .. username

    local index = 1
    local total = #queue
    local calledPre = {}
    local calledPost = {}
    local namespaceCounts = {}
    local namespaceProgress = {}

    for _, item in ipairs(queue) do
        local ns = item.namespace
        namespaceCounts[ns] = (namespaceCounts[ns] or 0) + 1
    end

    self:ExecuteAllHooks("PreBatchSync", isoPlayer, nil, nil)
    FrameworkZ.Timers:Remove(timerName)

    FrameworkZ.Timers:Create(timerName, tickRate, total, function()
        local item = queue[index]
        if item then
            local ns, key = item.namespace, item.key

            if not calledPre[ns] then
                self:ExecuteAllHooks("PreBatchSync", isoPlayer, ns, nil)
                calledPre[ns] = true
            end

            self:ExecuteAllHooks("OnBatchSync", isoPlayer, ns, key)
            self:SyncToPlayer(isoPlayer, ns, key)

            namespaceProgress[ns] = (namespaceProgress[ns] or 0) + 1

            if namespaceProgress[ns] == namespaceCounts[ns] then
                self:ExecuteAllHooks("PostBatchSync", isoPlayer, ns, key)
                calledPost[ns] = true
            end
        end

        index = index + 1

        if index > total then
            if type(onComplete) == "function" then
                onComplete(isoPlayer)
            end

            self:ExecuteAllHooks("PostBatchSync", isoPlayer, nil, nil)
        end
    end)

    self.SyncQueues[username] = nil
end

--! \brief Processes an object to extract saveable data, filtering out functions and handling nested objects.
--! \param object \table The object to process for saving.
--! \param ignoreList \table List of keys to ignore during processing.
--! \param encodeList \table List of keys that should be encoded using their GetSaveableData method.
--! \return \table The processed saveable data.
function FrameworkZ.Foundation:ProcessSaveableData(object, ignoreList, encodeList)
    local saveableData = {}

    for k, v in pairs(object) do
        if FrameworkZ.Utilities:TableContainsValue(ignoreList, k) then
            -- skip ignored keys
        elseif type(v) == "function" then
            -- skip functions
        elseif type(v) == "table" then
            if FrameworkZ.Utilities:TableContainsValue(encodeList, k) and v.GetSaveableData then
                saveableData[k] = v:GetSaveableData()

                if not saveableData[k] then
                    print("[FZ] Failed to save '" .. tostring(v) .. "' at '" .. tostring(k) .. "'. OBJECT:GetSaveableData() is not implemented.")
                end
            else
                -- Recursively process plain tables
                saveableData[k] = self:ProcessSaveableData(v, ignoreList, encodeList)
            end
        else
            saveableData[k] = v
        end
    end

    return saveableData
end

--[[ Finalization



███████ ██ ███    ██  █████  ██      ██ ███████  █████  ████████ ██  ██████  ███    ██ 
██      ██ ████   ██ ██   ██ ██      ██    ███  ██   ██    ██    ██ ██    ██ ████   ██ 
█████   ██ ██ ██  ██ ███████ ██      ██   ███   ███████    ██    ██ ██    ██ ██ ██  ██ 
██      ██ ██  ██ ██ ██   ██ ██      ██  ███    ██   ██    ██    ██ ██    ██ ██  ██ ██ 
██      ██ ██   ████ ██   ██ ███████ ██ ███████ ██   ██    ██    ██  ██████  ██   ████ 



-]]

--! \brief Initializes the FrameworkZ Foundation system by setting up event handlers and registering them with the Project Zomboid event system.
--! \note The LoadGridSquare event is not added to the hook system for performance reasons, as it is called very frequently.
--! \note This function wraps the Project Zomboid Events system to integrate with the FrameworkZ hook system, allowing all foundation events to be processed through the hook mechanism.
function FrameworkZ.Foundation:Initialize()
    local events = {}

    for k, v in pairs(Events) do
        if v and v.Add then
            local oldEventAdd = v.Add

            if not events[k] then
                events[k] = {}
            end

            events[k].Add = function(func)
                local function wrappedFunc(...)
                    func(self, ...)
                end

                oldEventAdd(wrappedFunc)
            end
        end
    end

    events.EveryDays.Add(self.Events.EveryDays)
    events.OnClientCommand.Add(self.Events.OnClientCommand)
    events.OnConnected.Add(self.Events.OnConnected)
    events.OnCreatePlayer.Add(self.Events.OnCreatePlayer)
    events.OnDisconnect.Add(self.Events.OnDisconnect)
    events.OnFillInventoryObjectContextMenu.Add(self.Events.OnFillInventoryObjectContextMenu)
    events.OnFillWorldObjectContextMenu.Add(self.Events.OnFillWorldObjectContextMenu)
    events.OnGameStart.Add(self.Events.OnGameStart)
    events.OnInitGlobalModData.Add(self.Events.OnInitGlobalModData)
    events.OnKeyStartPressed.Add(self.Events.OnKeyStartPressed)
    events.OnMainMenuEnter.Add(self.Events.OnMainMenuEnter)
    events.OnObjectLeftMouseButtonDown.Add(self.Events.OnObjectLeftMouseButtonDown)
    events.OnPlayerDeath.Add(self.Events.OnPlayerDeath)
    events.OnPreFillInventoryObjectContextMenu.Add(self.Events.OnPreFillInventoryObjectContextMenu)
    events.OnReceiveGlobalModData.Add(self.Events.OnReceiveGlobalModData)
    events.OnServerCommand.Add(self.Events.OnServerCommand)
    events.OnServerStarted.Add(self.Events.OnServerStarted)

    if isServer() then
        --self:Subscribe("FrameworkZ.Foundation.OnInitializeClient", self.OnInitializeClient)
        self:Subscribe("FrameworkZ.Foundation.OnGetData", self.OnGetData)
        self:Subscribe("FrameworkZ.Foundation.OnInitializePlayer", self.OnInitializePlayer)
        self:Subscribe("FrameworkZ.Foundation.OnSetData", self.OnSetData)
        self:Subscribe("FrameworkZ.Foundation.OnSaveData", self.OnSaveData)
        self:Subscribe("FrameworkZ.Foundation.OnSaveNamespace", self.OnSaveNamespace)
        self:Subscribe("FrameworkZ.Foundation.OnTeleportToLimbo", self.OnTeleportToLimbo)
    end
end

FrameworkZ.Foundation:RegisterFramework()
