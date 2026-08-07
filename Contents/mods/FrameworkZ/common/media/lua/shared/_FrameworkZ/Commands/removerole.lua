local COMMAND = FrameworkZ.Commands:New("removerole")

COMMAND.aliases = {"takerole", "delrole"}
COMMAND.description = "Remove a role from a player"
COMMAND.usage = "/removerole <player> <role>"
COMMAND.permission = "roles.remove"
COMMAND.adminOnly = true
COMMAND.minArgs = 2

function COMMAND:CanRun(player, args)
    return FrameworkZ.Roles:HasPermission(player, self.permission)
end

function COMMAND:OnRun(player, args)
    local targetUsername = args[1]
    local roleId = args[2]
    
    if not FrameworkZ.Roles then
        FrameworkZ.Commands:SendMessage(player, "Roles module not available")
        return false
    end
    
    local success = FrameworkZ.Roles:RemoveRole(targetUsername, roleId)
    
    if success then
        FrameworkZ.Commands:SendMessage(player, "Removed role '" .. roleId .. "' from " .. targetUsername)
    else
        FrameworkZ.Commands:SendMessage(player, "Failed to remove role.")
    end
    
    return success
end

FrameworkZ.Commands:Register(COMMAND)
