local COMMAND = FrameworkZ.Commands:New("grantowner")

COMMAND.aliases = {"setowner"}
COMMAND.description = "Assign the Super Admin role to a player by username"
COMMAND.usage = "/grantowner <username>"
COMMAND.allowConsole = true
COMMAND.adminOnly = false
COMMAND.minArgs = 1
COMMAND.maxArgs = 1

function COMMAND:CanRun(player, args)
    -- Console only — no in-game player should be able to grant superadmin
    return player == nil
end

function COMMAND:OnRun(player, args)
    local username = args[1]

    if not FrameworkZ.Roles then
        print("[FZ] grantowner: Roles module not available.")
        return false
    end

    local success = FrameworkZ.Roles:AssignRole(username, FrameworkZ.Roles.DEFAULT_ROLES.SUPERADMIN)

    if success then
        print("[FZ] grantowner: Granted Super Admin to '" .. username .. "'.")
    else
        print("[FZ] grantowner: Failed to grant Super Admin to '" .. username .. "'. Check the username is correct.")
    end

    return success
end

FrameworkZ.Commands:Register(COMMAND)
