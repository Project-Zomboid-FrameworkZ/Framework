local COMMAND = FrameworkZ.Commands:New("help")

COMMAND.aliases = {"?", "commands"}
COMMAND.description = "Show available commands"
COMMAND.usage = "/help [command]"
COMMAND.permission = "commands.help"

function COMMAND:CanRun(player, args)
    return FrameworkZ.Roles:HasPermission(player, self.permission)
end

function COMMAND:OnRun(player, args)
    local username = player:GetUsername()
    local commandName = args[1]

    if commandName then
        commandName = commandName:lower()
        local command = FrameworkZ.Commands:GetCommand(commandName)

        if not command then
            FrameworkZ.Notifications:AddToQueue("Unknown command: " .. commandName)
            return false
        end

        local helpText = string.format("Command: /%s\nDescription: %s\nUsage: %s",
            command.name,
            command.description,
            command.usage
        )

        if #command.aliases > 0 then
            helpText = helpText .. "\nAliases: " .. table.concat(command.aliases, ", ")
        end

        FrameworkZ.Notifications:AddToQueue(helpText)
    else
        local availableCommands = {}

        for name, command in pairs(self.RegisteredCommands) do
            if command.CanRun then
                if command:CanRun(player, args) then
                    table.insert(availableCommands, "/" .. name)
                end
            else
                table.insert(availableCommands, "/" .. name)
            end
        end

        table.sort(availableCommands)

        local helpText = "Available commands: " .. table.concat(availableCommands, ", ")
        helpText = helpText .. "\nUse /help <command> for more info"

        FrameworkZ.Notifications:AddToQueue(helpText)
    end

    return true
end

FrameworkZ.Commands:Register(COMMAND)