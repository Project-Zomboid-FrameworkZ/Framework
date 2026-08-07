---@diagnostic disable: undefined-global
FrameworkZ = FrameworkZ or {}

--! \brief Commands module for FrameworkZ. Provides chat-based command system with permissions.
--! \module FrameworkZ.Commands
FrameworkZ.Commands = {}

FrameworkZ.Commands = FrameworkZ.Foundation:NewModule(FrameworkZ.Commands, "Commands")

-- Command registry
FrameworkZ.Commands.RegisteredCommands = {}
FrameworkZ.Commands.CommandAliases = {}

-- Command prefix (default is /)
FrameworkZ.Commands.PREFIX = "/"

-- Command execution history (for debugging)
FrameworkZ.Commands.ExecutionHistory = {}
FrameworkZ.Commands.MAX_HISTORY = 100

--! \brief Create a new command object
--! \param name Command name
--! \return table Command object
function FrameworkZ.Commands:New(name)
    local command = {
        name = name:lower(),
        aliases = {},
        description = "No description",
        usage = "/" .. name:lower(),
        permission = nil,
        adminOnly = false,
        serverOnly = false,
        clientOnly = false,
        allowConsole = false,
        minArgs = 0,
        maxArgs = nil,
        metadata = {}
    }
    
    return command
end

--! \brief Register a command object
--! \param command Command object (created with New())
--! \return boolean Success status
function FrameworkZ.Commands:Register(command)
    if not command or not command.name then
        print("[FrameworkZ] Error: Cannot register command without name")
        return false
    end
    
    if not command.OnRun or type(command.OnRun) ~= "function" then
        print("[FrameworkZ] Error: Command " .. command.name .. " missing OnRun function")
        return false
    end
    
    local name = command.name:lower()
    
    -- Check if already registered
    if self.RegisteredCommands[name] then
        print("[FrameworkZ] Warning: Overwriting existing command: " .. name)
    end
    
    -- Register command
    self.RegisteredCommands[name] = command
    
    -- Register aliases
    if command.aliases then
        for _, alias in ipairs(command.aliases) do
            alias = alias:lower()
            self.CommandAliases[alias] = name
        end
    end
    
    print("[FrameworkZ] Registered command: /" .. name)
    return true
end

--! \brief Initialize the Commands module
function FrameworkZ.Commands:Initialize()
    print("[FrameworkZ] Initializing Commands module...")
    
    -- Load custom commands (will auto-load from Commands folder)
    self:LoadCustomCommands()
    
    -- Hook into chat system
    self:HookChatSystem()

    if self.RegisteredCommands["giveitem"] then
        print("[FrameworkZ] Command /giveitem is registered")
    else
        print("[FrameworkZ] WARNING: Command /giveitem is not registered at Commands:Initialize time")
    end
    
    print("[FrameworkZ] Commands module initialized with " .. self:GetCommandCount() .. " commands")
end

function FrameworkZ.Commands:InitializeClient(isoPlayer)
    if not isClient() then return end

    if not self._clientBootstrapDone then
        self:LoadCustomCommands()
        self:HookChatSystem()
        self._clientBootstrapDone = true
        print("[FrameworkZ] Commands client bootstrap complete (InitializeClient)")
    end
end

function FrameworkZ.Commands:PostInitializeClient(player)
    if not isClient() then return end
    self:HookChatSystem()
end

--! \brief Load custom commands from command definition files
function FrameworkZ.Commands:LoadCustomCommands()
    print("[FrameworkZ] Loading custom commands...")

    local requiredModules = {
        {command = "help", module = "_FrameworkZ/Commands/help"},
        {command = "roles", module = "_FrameworkZ/Commands/roles"},
        {command = "giverole", module = "_FrameworkZ/Commands/giverole"},
        {command = "removerole", module = "_FrameworkZ/Commands/removerole"},
        {command = "grantowner", module = "_FrameworkZ/Commands/grantowner"},
        {command = "teleport", module = "_FrameworkZ/Commands/teleport"},
        {command = "whois", module = "_FrameworkZ/Commands/whois"},
        {command = "giveitem", module = "_FrameworkZ/Commands/giveitem"}
    }

    for _, entry in ipairs(requiredModules) do
        if not self.RegisteredCommands[entry.command] then
            local ok, err = pcall(require, entry.module)
            if not ok then
                print("[FrameworkZ] WARNING: Failed to load command module '" .. tostring(entry.module) .. "': " .. tostring(err))
            end
        end
    end
end

--! \brief Hook into the chat system to intercept commands
function FrameworkZ.Commands:HookChatSystem()
    if self._chatHooksRegistered then return end
    self._chatHooksRegistered = true

    local function _pack(...)
        return { n = select('#', ...), ... }
    end

    local function extractMessage(selfObj, packedArgs)
        if packedArgs then
            for i = 2, packedArgs.n do
                local v = packedArgs[i]
                if type(v) == "string" and v ~= "" then
                    return v
                end
            end
        end

        if selfObj and selfObj.getText then
            return selfObj:getText()
        end

        if selfObj and selfObj.textEntry and selfObj.textEntry.getText then
            return selfObj.textEntry:getText()
        end

        if ISChat and ISChat.instance and ISChat.instance.textEntry and ISChat.instance.textEntry.getText then
            return ISChat.instance.textEntry:getText()
        end

        return nil
    end

    local function shouldHandle(message)
        if type(message) ~= "string" then return false end
        return message:sub(1, #FrameworkZ.Commands.PREFIX) == FrameworkZ.Commands.PREFIX
    end

    local function resolveFrameworkZCommandName(message)
        if type(message) ~= "string" then return nil end
        if message:sub(1, #FrameworkZ.Commands.PREFIX) ~= FrameworkZ.Commands.PREFIX then return nil end

        local commandText = message:sub(#FrameworkZ.Commands.PREFIX + 1)
        local parts = FrameworkZ.Commands:ParseCommandString(commandText)
        if not parts or #parts == 0 then return nil end

        local commandName = tostring(parts[1] or ""):lower()
        if commandName == "" then return nil end

        if FrameworkZ.Commands.CommandAliases[commandName] then
            commandName = FrameworkZ.Commands.CommandAliases[commandName]
        end

        if FrameworkZ.Commands.RegisteredCommands[commandName] then
            return commandName
        end

        return nil
    end

    local function interceptMessage(message, selfObj)
        if not shouldHandle(message) then return false end

        local commandName = resolveFrameworkZCommandName(message)
        if not commandName then
            -- Not a FrameworkZ command; allow vanilla Project Zomboid routing.
            return false
        end

        local isoPlayer = getPlayer and getPlayer() or nil
        if not isoPlayer then return false end

        print("[FrameworkZ] Intercepted chat command: " .. tostring(message))
        FrameworkZ.Commands:ProcessCommand(isoPlayer, message)

        if selfObj and selfObj.clear then
            selfObj:clear()
        elseif selfObj and selfObj.setText then
            selfObj:setText("")
        elseif ISChat and ISChat.instance and ISChat.instance.textEntry and ISChat.instance.textEntry.setText then
            ISChat.instance.textEntry:setText("")
        end

        return true
    end

    local function wrapMethod(targetTable, key)
        if type(targetTable) ~= "table" then return false end
        local original = targetTable[key]
        if type(original) ~= "function" then return false end

        local marker = "__fzCommandsWrapped_" .. tostring(key)
        if targetTable[marker] and targetTable[key] == targetTable[marker] then
            return false
        end

        local wrapped = function(...)
            local args = _pack(...)
            local selfObj = args[1]
            local message = extractMessage(selfObj, args)

            if interceptMessage(message, selfObj) then
                return
            end

            return original(...)
        end

        targetTable[key] = wrapped
        targetTable[marker] = wrapped
        return true
    end

    local function wrapChatEntrySubmit()
        if not ISChat or not ISChat.instance or not ISChat.instance.textEntry then return false end

        local entry = ISChat.instance.textEntry
        local original = entry.onCommandEntered
        if type(original) ~= "function" then return false end

        local marker = "__fzCommandsWrapped_onCommandEntered"
        if entry[marker] and entry.onCommandEntered == entry[marker] then
            return false
        end

        local wrapped = function(...)
            local args = _pack(...)
            local selfObj = args[1]
            local message = extractMessage(ISChat and ISChat.instance or selfObj, args)

            if interceptMessage(message, selfObj) then
                return
            end

            return original(...)
        end

        entry.onCommandEntered = wrapped
        entry[marker] = wrapped
        return true
    end

    local function wrapChatEntryOtherKey()
        if not ISChat or not ISChat.instance or not ISChat.instance.textEntry then return false end

        local entry = ISChat.instance.textEntry
        local original = entry.onOtherKey
        if type(original) ~= "function" then return false end

        local marker = "__fzCommandsWrapped_onOtherKey"
        if entry[marker] and entry.onOtherKey == entry[marker] then
            return false
        end

        local wrapped = function(...)
            local args = _pack(...)
            local selfObj = args[1]
            local key = args[2]

            if tonumber(key) ~= 28 then
                return original(...)
            end

            local message = extractMessage(ISChat and ISChat.instance or selfObj, args)
            if interceptMessage(message, selfObj) then
                return
            end

            return original(...)
        end

        entry.onOtherKey = wrapped
        entry[marker] = wrapped
        return true
    end

    local function installChatInterceptor()
        if not isClient() then return false end
        if type(ISChat) ~= "table" then return false end

        local patched = false

        patched = wrapMethod(ISChat, "onCommandEntered") or patched
        patched = wrapMethod(ISChat, "processCommand") or patched
        patched = wrapMethod(ISChat, "sendMessage") or patched
        patched = wrapMethod(ISChat, "sendMessageToCurrentTab") or patched
        patched = wrapMethod(ISChat, "sendMessageToTab") or patched

        patched = wrapChatEntrySubmit() or patched
        patched = wrapChatEntryOtherKey() or patched

        return patched
    end

    local function installGeneralMessageInterceptor()
        if not isClient() then return false end
        if type(processGeneralMessage) ~= "function" then return false end

        local current = processGeneralMessage
        if FrameworkZ.Commands._wrappedProcessGeneralMessage == current then
            return false
        end

        local original = current
        local wrapped = function(message)
            if interceptMessage(message, nil) then
                return
            end

            return original(message)
        end

        FrameworkZ.Commands._wrappedProcessGeneralMessage = wrapped
        processGeneralMessage = wrapped

        return true
    end

    local function installSendCommandInterceptor()
        if not isClient() then return false end
        if type(SendCommandToServer) ~= "function" then return false end

        local current = SendCommandToServer
        if FrameworkZ.Commands._wrappedSendCommandToServer == current then
            return false
        end

        local original = current
        local wrapped = function(command)
            if interceptMessage(command, nil) then
                return
            end

            return original(command)
        end

        FrameworkZ.Commands._wrappedSendCommandToServer = wrapped
        SendCommandToServer = wrapped
        return true
    end

    local function tryInstall()
        local installed = installChatInterceptor()
        installed = installGeneralMessageInterceptor() or installed
        installed = installSendCommandInterceptor() or installed
        if installed then
            print("[FrameworkZ] Installed command chat interceptor")
        end
    end

    Events.OnChatWindowInit.Add(tryInstall)
    Events.OnGameStart.Add(tryInstall)

    local retries = 0
    Events.OnTick.Add(function()
        if retries > 900 then return end
        retries = retries + 1

        if retries % 30 == 0 then
            tryInstall()
        end
    end)

    print("[FrameworkZ] Chat system hook registered for commands")
end

--! \brief Process a console input string as a command (no prefix required)
--! \param message Console input text
--! \return boolean True if message was a command and was handled
function FrameworkZ.Commands:ProcessConsoleCommand(message)
    if not message then return false end

    -- Strip a leading slash so both "kick Bob" and "/kick Bob" work from file input
    if message:sub(1, 1) == "/" then
        message = message:sub(2)
    end

    local parts = self:ParseCommandString(message)
    if #parts == 0 then return false end

    local commandName = parts[1]:lower()
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end

    return self:ExecuteCommand(nil, commandName, args)
end

--! \brief Process a chat message as a potential command
--! \param player IsoPlayer who sent the message
--! \param message Chat message text
--! \return boolean True if message was a command and was handled
function FrameworkZ.Commands:ProcessCommand(player, message)
    if not player or not message then return false end
    
    -- Check if message starts with command prefix
    if message:sub(1, #self.PREFIX) ~= self.PREFIX then
        return false
    end
    
    -- Remove prefix and parse
    local commandText = message:sub(#self.PREFIX + 1)
    local parts = self:ParseCommandString(commandText)
    
    if #parts == 0 then return false end
    
    local commandName = parts[1]:lower()
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    -- Execute command
    return self:ExecuteCommand(player, commandName, args)
end

--! \brief Parse a command string into parts
--! \param commandText Command text (without prefix)
--! \return table Array of command parts
function FrameworkZ.Commands:ParseCommandString(commandText)
    local parts = {}
    local inQuote = false
    local current = ""
    
    for i = 1, #commandText do
        local char = commandText:sub(i, i)
        
        if char == '"' then
            inQuote = not inQuote
        elseif char == " " and not inQuote then
            if #current > 0 then
                table.insert(parts, current)
                current = ""
            end
        else
            current = current .. char
        end
    end
    
    -- Add final part
    if #current > 0 then
        table.insert(parts, current)
    end
    
    return parts
end

--! \brief Execute a command
--! \param player IsoPlayer executing the command
--! \param commandName Command name or alias
--! \param args Array of arguments
--! \return boolean Success status
function FrameworkZ.Commands:ExecuteCommand(player, commandName, args)
    if not commandName then return false end
    local isConsole = (player == nil)
    
    commandName = commandName:lower()
    args = args or {}
    
    -- Resolve alias
    if self.CommandAliases[commandName] then
        commandName = self.CommandAliases[commandName]
    end
    
    -- Get command
    local command = self.RegisteredCommands[commandName]
    if not command then
        self:SendMessage(player, "Unknown command: " .. commandName)
        return false
    end
    
    -- Console-only or console-allowed check
    if isConsole and not command.allowConsole then
        print("[FZ] Command /" .. commandName .. " does not allow console execution.")
        return false
    end

    -- Check if player can run command
    if not isConsole then
        if command.CanRun then
            if not command:CanRun(player, args) then
                self:SendMessage(player, "You don't have permission to use this command.")
                return false
            end
        else
            -- Fallback permission check
            if not self:CanExecuteCommand(player, command) then
                self:SendMessage(player, "You don't have permission to use this command.")
                return false
            end
        end
    end
    
    -- Check argument count
    if command.minArgs and #args < command.minArgs then
        self:SendMessage(player, "Not enough arguments. Usage: " .. command.usage)
        return false
    end
    
    if command.maxArgs and #args > command.maxArgs then
        self:SendMessage(player, "Too many arguments. Usage: " .. command.usage)
        return false
    end
    
    -- Check server/client only
    if command.serverOnly and not isServer() then
        self:SendMessage(player, "This command can only be used on the server.")
        return false
    end
    
    if command.clientOnly and isConsole then
        self:SendMessage(player, "This command can only be used by clients.")
        return false
    end

    local success, result = pcall(command.OnRun, command, player, args)
    
    if not success then
        print("[FZ] Error executing command " .. commandName .. ": " .. tostring(result))
        self:SendMessage(player, "Error executing command. Check server logs.")
        return false
    end
    
    -- Log execution
    self:LogCommandExecution(player, commandName, args, success)
    
    return true
end

--! \brief Check if a player can execute a command (fallback method)
--! \param player IsoPlayer
--! \param command Command object
--! \return boolean Can execute
function FrameworkZ.Commands:CanExecuteCommand(player, command)
    if not player or not command then return false end
    
    local username = player:getUsername()
    
    -- Check admin-only
    if command.adminOnly and not player:isAdmin() then
        return false
    end
    
    -- Check permission
    if command.permission then
        if not FrameworkZ.Roles then
            -- Fallback if Roles module not available
            return player:isAdmin()
        end
        
        return FrameworkZ.Roles:HasPermission(username, command.permission)
    end
    
    return true
end

--! \brief Send a message to a player
--! \param player IsoPlayer
--! \param message Message text
function FrameworkZ.Commands:SendMessage(player, message)
    if not player then
        print("[FZ] " .. tostring(message))
        return
    end

    local text = tostring(message or "")

    if isClient() and FrameworkZ.Notifications and type(FrameworkZ.Notifications.AddToQueue) == "function" then
        local notificationType = FrameworkZ.Notifications.Types and FrameworkZ.Notifications.Types.Info or nil
        FrameworkZ.Notifications:AddToQueue(text, notificationType, 5)
        return
    end

    if type(player.Say) == "function" then
        player:Say(text)
        return
    end

    print("[FZ] " .. text)
end

--! \brief Log command execution
function FrameworkZ.Commands:LogCommandExecution(player, commandName, args, success)
    local entry = {
        timestamp = os.time(),
        username = player and player:getUsername() or "Console",
        command = commandName,
        args = args,
        success = success
    }
    
    table.insert(self.ExecutionHistory, entry)
    
    -- Trim history if too long
    if #self.ExecutionHistory > self.MAX_HISTORY then
        table.remove(self.ExecutionHistory, 1)
    end
    
    -- Console log
    print(string.format("[FZ] %s executed: /%s %s (success: %s)",
        entry.username,
        commandName,
        table.concat(args, " "),
        tostring(success)
    ))
end

--! \brief Get command by name
--! \param commandName Command name
--! \return table|nil Command object
function FrameworkZ.Commands:GetCommand(commandName)
    if not commandName then return nil end
    
    commandName = commandName:lower()
    
    -- Check alias
    if self.CommandAliases[commandName] then
        commandName = self.CommandAliases[commandName]
    end
    
    return self.RegisteredCommands[commandName]
end

--! \brief Get all registered commands
--! \return table Map of commandName -> command object
function FrameworkZ.Commands:GetAllCommands()
    return self.RegisteredCommands
end

--! \brief Get count of registered commands
--! \return number Count
function FrameworkZ.Commands:GetCommandCount()
    local count = 0
    for _ in pairs(self.RegisteredCommands) do
        count = count + 1
    end
    return count
end

--! \brief Unregister a command
--! \param commandName Command name
--! \return boolean Success
function FrameworkZ.Commands:UnregisterCommand(commandName)
    if not commandName then return false end
    
    commandName = commandName:lower()
    
    local command = self.RegisteredCommands[commandName]
    if not command then return false end
    
    -- Remove aliases
    if command.aliases then
        for _, alias in ipairs(command.aliases) do
            self.CommandAliases[alias:lower()] = nil
        end
    end
    
    -- Remove command
    self.RegisteredCommands[commandName] = nil
    
    print("[FZ] Unregistered command: /" .. commandName)
    return true
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Commands)

if isClient() then
    FrameworkZ.Commands:HookChatSystem()
end

