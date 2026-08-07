local COMMAND = FrameworkZ.Commands:New("roles")

COMMAND.aliases = {"listroles"}
COMMAND.description = "List all available roles"
COMMAND.usage = "/roles [player]"
COMMAND.permission = "roles.view"

function COMMAND:CanRun(player, args)
    return FrameworkZ.Roles:HasPermission(player, self.permission)
end

function COMMAND:OnRun(player, args)
    if not FrameworkZ.Roles then
        FrameworkZ.Commands:SendMessage(player, "Roles module not available")
        return false
    end
    
    if #args > 0 then
        -- Show role for specific player
        local targetUsername = args[1]
        local roleId = FrameworkZ.Roles:GetPlayerRole(targetUsername)
        local roleName = FrameworkZ.Roles:GetFormattedRoleName(roleId)

        FrameworkZ.Commands:SendMessage(player, targetUsername .. " role: " .. roleName .. " (" .. tostring(roleId) .. ")")
    else
        -- Show all available roles
        local allRoles = FrameworkZ.Roles:GetAllRoles()
        local roleList = {}
        
        for roleId, role in pairs(allRoles) do
            table.insert(roleList, role.name .. " (" .. roleId .. ")")
        end
        
        table.sort(roleList)
        
        FrameworkZ.Commands:SendMessage(player, "Available roles: " .. table.concat(roleList, ", "))
    end
    
    return true
end

FrameworkZ.Commands:Register(COMMAND)
