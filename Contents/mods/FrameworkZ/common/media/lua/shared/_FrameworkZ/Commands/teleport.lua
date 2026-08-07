local COMMAND = FrameworkZ.Commands:New("teleport")

COMMAND.aliases = {"tp", "goto"}
COMMAND.description = "Teleport to a player or location"
COMMAND.usage = "/teleport <player|x y z>"
COMMAND.permission = "commands.teleport"
COMMAND.adminOnly = true
COMMAND.serverOnly = true
COMMAND.minArgs = 1

function COMMAND:CanRun(player, args)
    return FrameworkZ.Roles:HasPermission(player, self.permission)
end

function COMMAND:OnRun(player, args)
    if #args == 1 then
        -- Teleport to player
        local targetUsername = args[1]
        local targetPlayer = getPlayerFromUsername(targetUsername)
        
        if not targetPlayer then
            FrameworkZ.Commands:SendMessage(player, "Player not found: " .. targetUsername)
            return false
        end
        
        player:setX(targetPlayer:getX())
        player:setY(targetPlayer:getY())
        player:setZ(targetPlayer:getZ())
        
        FrameworkZ.Commands:SendMessage(player, "Teleported to " .. targetUsername)
    elseif #args >= 3 then
        -- Teleport to coordinates
        local x = tonumber(args[1])
        local y = tonumber(args[2])
        local z = tonumber(args[3]) or 0
        
        if not x or not y then
            FrameworkZ.Commands:SendMessage(player, "Invalid coordinates")
            return false
        end
        
        player:setX(x)
        player:setY(y)
        player:setZ(z)
        
        FrameworkZ.Commands:SendMessage(player, string.format("Teleported to %.2f, %.2f, %.2f", x, y, z))
    else
        FrameworkZ.Commands:SendMessage(player, "Usage: " .. self.usage)
        return false
    end
    
    return true
end

FrameworkZ.Commands:Register(COMMAND)
