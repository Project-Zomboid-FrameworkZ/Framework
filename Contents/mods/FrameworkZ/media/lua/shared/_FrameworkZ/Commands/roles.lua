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
        -- Show roles for specific player
        local targetUsername = args[1]
        local roles = FrameworkZ.Roles:GetPlayerRoles(targetUsername)
        
        if #roles == 0 then
            FrameworkZ.Commands:SendMessage(player, targetUsername .. " has no assigned roles")
        else
            local roleNames = {}
            for _, roleId in ipairs(roles) do
                local roleName = FrameworkZ.Roles:GetFormattedRoleName(roleId)
                table.insert(roleNames, roleName)
            end
            
            FrameworkZ.Commands:SendMessage(player, targetUsername .. " roles: " .. table.concat(roleNames, ", "))
        end
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
