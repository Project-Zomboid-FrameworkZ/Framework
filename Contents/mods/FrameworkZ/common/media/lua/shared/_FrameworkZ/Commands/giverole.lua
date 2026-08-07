local COMMAND = FrameworkZ.Commands:New("giverole")

COMMAND.aliases = {"assignrole", "addrole"}
COMMAND.description = "Assign a role to a player"
COMMAND.usage = "/giverole <player> <role>"
COMMAND.permission = "roles.assign"
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
    
    local success = FrameworkZ.Roles:AssignRole(targetUsername, roleId)
    
    if success then
        FrameworkZ.Commands:SendMessage(player, "Assigned role '" .. roleId .. "' to " .. targetUsername)
    else
        FrameworkZ.Commands:SendMessage(player, "Failed to assign role. Check if role exists.")
    end
    
    return success
end

FrameworkZ.Commands:Register(COMMAND)
