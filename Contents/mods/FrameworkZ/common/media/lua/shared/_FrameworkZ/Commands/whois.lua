local COMMAND = FrameworkZ.Commands:New("whois")

COMMAND.aliases = {"playerinfo"}
COMMAND.description = "Get information about a player"
COMMAND.usage = "/whois <player>"
COMMAND.permission = "player.info"
COMMAND.minArgs = 1

function COMMAND:CanRun(player, args)
    return FrameworkZ.Roles:HasPermission(player, self.permission)
end

function COMMAND:OnRun(player, args)
    local targetUsername = args[1]
    
    -- Get player info
    local info = "Player: " .. targetUsername
    
    -- Add role info
    if FrameworkZ.Roles then
        local primaryRole = FrameworkZ.Roles:GetPrimaryRole(targetUsername)
        if primaryRole then
            info = info .. "\nRole: " .. primaryRole.name
        end
    end
    
    -- Add faction info if available
    if FrameworkZ.Factions then
        local faction = FrameworkZ.Factions:GetPlayerFaction(targetUsername)
        if faction then
            info = info .. "\nFaction: " .. faction.name
        end
    end
    
    FrameworkZ.Commands:SendMessage(player, info)
    return true
end

FrameworkZ.Commands:Register(COMMAND)
