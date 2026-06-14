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
    
    print("[FrameworkZ] Commands module initialized with " .. self:GetCommandCount() .. " commands")
end

--! \brief Load custom commands from command definition files
function FrameworkZ.Commands:LoadCustomCommands()
    -- Custom commands are auto-loaded from:
    -- media/lua/shared/_FrameworkZ/Commands/*.lua
    print("[FrameworkZ] Loading custom commands...")
end

--! \brief Hook into the chat system to intercept commands
function FrameworkZ.Commands:HookChatSystem()
    -- This would hook into PZ's chat events
    -- For now, commands should be called via ProcessCommand
    Events.OnChatWindowInit.Add(function()
        print("[FrameworkZ] Chat system hooked for commands")
    end)
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
    if not message:sub(1, #self.PREFIX) == self.PREFIX then
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
    
    if FrameworkZ.Notifications then
        FrameworkZ.Notifications:Send(player, {
            message = message,
            category = "Command",
            duration = 5000
        })
    else
        -- Fallback to chat message
        player:Say(message)
    end
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

