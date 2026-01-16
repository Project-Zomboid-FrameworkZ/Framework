FrameworkZ = FrameworkZ or {}

--! \brief Roles module for FrameworkZ. Provides role-based permission system.
--! \module FrameworkZ.Roles
FrameworkZ.Roles = {}

FrameworkZ.Roles = FrameworkZ.Foundation:NewModule(FrameworkZ.Roles, "Roles")

-- Role registry
FrameworkZ.Roles.RegisteredRoles = {}
FrameworkZ.Roles.RoleHierarchy = {}
FrameworkZ.Roles.PlayerRoles = {} -- username -> {roleId1, roleId2, ...}

-- Permission cache for faster lookups
FrameworkZ.Roles.PermissionCache = {}

-- Built-in default roles
FrameworkZ.Roles.DEFAULT_ROLES = {
    PLAYER = "player",
    MODERATOR = "moderator",
    ADMIN = "admin",
    SUPERADMIN = "superadmin"
}

--! \brief Initialize the Roles module
function FrameworkZ.Roles:Initialize()
    print("[FrameworkZ] Initializing Roles module...")
    
    -- Register default roles
    self:RegisterDefaultRoles()
    
    -- Load custom roles from files
    self:LoadCustomRoles()
    
    -- Load player role assignments
    self:LoadPlayerRoles()
    
    print("[FrameworkZ] Roles module initialized with " .. self:GetRoleCount() .. " roles")
end

--! \brief Register the default built-in roles
function FrameworkZ.Roles:RegisterDefaultRoles()
    -- Player role - basic permissions
    self:RegisterRole({
        id = self.DEFAULT_ROLES.PLAYER,
        name = "Player",
        description = "Default player role with basic permissions",
        color = {r = 1.0, g = 1.0, b = 1.0},
        permissions = {
            "chat.send",
            "chat.receive",
            "faction.view",
            "property.view"
        },
        priority = 0,
        isDefault = true
    })
    
    -- Moderator role
    self:RegisterRole({
        id = self.DEFAULT_ROLES.MODERATOR,
        name = "Moderator",
        description = "Moderator with basic administrative powers",
        color = {r = 0.0, g = 0.8, b = 1.0},
        permissions = {
            "chat.*",
            "faction.*",
            "property.view",
            "property.manage",
            "player.kick",
            "player.mute",
            "commands.teleport"
        },
        inherits = {self.DEFAULT_ROLES.PLAYER},
        priority = 50
    })
    
    -- Admin role
    self:RegisterRole({
        id = self.DEFAULT_ROLES.ADMIN,
        name = "Admin",
        description = "Administrator with full server control",
        color = {r = 1.0, g = 0.5, b = 0.0},
        permissions = {
            "chat.*",
            "faction.*",
            "property.*",
            "player.*",
            "commands.*",
            "roles.assign",
            "roles.remove"
        },
        inherits = {self.DEFAULT_ROLES.MODERATOR},
        priority = 100
    })
    
    -- Super Admin role
    self:RegisterRole({
        id = self.DEFAULT_ROLES.SUPERADMIN,
        name = "Super Admin",
        description = "Super Administrator with unrestricted access",
        color = {r = 1.0, g = 0.0, b = 0.0},
        permissions = {"*"}, -- All permissions
        inherits = {self.DEFAULT_ROLES.ADMIN},
        priority = 999
    })
end

--! \brief Register a new role
--! \param roleData Table containing role definition
--! \return boolean Success status
function FrameworkZ.Roles:RegisterRole(roleData)
    if not roleData or not roleData.id then
        print("[FrameworkZ] Error: Cannot register role without ID")
        return false
    end
    
    -- Validate required fields
    if not roleData.name then
        print("[FrameworkZ] Error: Role " .. roleData.id .. " missing name")
        return false
    end
    
    -- Set defaults
    local role = {
        id = roleData.id,
        name = roleData.name,
        description = roleData.description or "",
        color = roleData.color or {r = 1.0, g = 1.0, b = 1.0},
        permissions = roleData.permissions or {},
        inherits = roleData.inherits or {},
        priority = roleData.priority or 0,
        isDefault = roleData.isDefault or false,
        metadata = roleData.metadata or {}
    }
    
    -- Register the role
    self.RegisteredRoles[role.id] = role
    
    -- Update hierarchy
    self:UpdateRoleHierarchy(role)
    
    -- Clear permission cache since roles changed
    self:ClearPermissionCache()
    
    print("[FrameworkZ] Registered role: " .. role.name .. " (" .. role.id .. ")")
    return true
end

--! \brief Update role hierarchy for inheritance
function FrameworkZ.Roles:UpdateRoleHierarchy(role)
    if not role or not role.id then return end
    
    self.RoleHierarchy[role.id] = {
        priority = role.priority,
        inherits = role.inherits or {}
    }
end

--! \brief Load custom roles from role definition files
function FrameworkZ.Roles:LoadCustomRoles()
    -- Custom roles should be defined in separate files that call RegisterRole
    -- This allows mods to add their own roles
    -- Example: media/lua/shared/_FrameworkZ/_Roles/MyCustomRole.lua
    print("[FrameworkZ] Loading custom roles...")
    -- Custom role files are auto-loaded by PZ if in the correct directory
end

--! \brief Load player role assignments from save data
function FrameworkZ.Roles:LoadPlayerRoles()
    if not isServer() then return end
    
    local data = FrameworkZ.Foundation:GetGlobalData("PlayerRoles") or {}
    self.PlayerRoles = data
    
    print("[FrameworkZ] Loaded role assignments for " .. self:CountAssignedPlayers() .. " players")
end

--! \brief Save player role assignments
function FrameworkZ.Roles:SavePlayerRoles()
    if not isServer() then return end
    
    FrameworkZ.Foundation:SetGlobalData("PlayerRoles", self.PlayerRoles)
    FrameworkZ.Foundation:BroadcastGlobalData("PlayerRoles")
end

--! \brief Assign a role to a player
--! \param username Player username
--! \param roleId Role ID to assign
--! \return boolean Success status
function FrameworkZ.Roles:AssignRole(username, roleId)
    if not username or not roleId then return false end
    
    -- Validate role exists
    if not self.RegisteredRoles[roleId] then
        print("[FrameworkZ] Error: Role " .. roleId .. " does not exist")
        return false
    end
    
    -- Initialize player roles if needed
    if not self.PlayerRoles[username] then
        self.PlayerRoles[username] = {}
    end
    
    -- Check if already assigned
    for _, existingRoleId in ipairs(self.PlayerRoles[username]) do
        if existingRoleId == roleId then
            return true -- Already has role
        end
    end
    
    -- Add role
    table.insert(self.PlayerRoles[username], roleId)
    
    -- Clear permission cache for this player
    self.PermissionCache[username] = nil
    
    -- Save changes
    self:SavePlayerRoles()
    
    print("[FrameworkZ] Assigned role " .. roleId .. " to " .. username)
    return true
end

--! \brief Remove a role from a player
--! \param username Player username
--! \param roleId Role ID to remove
--! \return boolean Success status
function FrameworkZ.Roles:RemoveRole(username, roleId)
    if not username or not roleId then return false end
    
    if not self.PlayerRoles[username] then return false end
    
    -- Find and remove role
    for i, existingRoleId in ipairs(self.PlayerRoles[username]) do
        if existingRoleId == roleId then
            table.remove(self.PlayerRoles[username], i)
            
            -- Clear permission cache
            self.PermissionCache[username] = nil
            
            -- Save changes
            self:SavePlayerRoles()
            
            print("[FrameworkZ] Removed role " .. roleId .. " from " .. username)
            return true
        end
    end
    
    return false
end

--! \brief Get all roles assigned to a player
--! \param username Player username
--! \return table Array of role IDs
function FrameworkZ.Roles:GetPlayerRoles(username)
    if not username then return {} end
    
    local roles = self.PlayerRoles[username] or {}
    
    -- Add default player role if no roles assigned
    if #roles == 0 then
        return {self.DEFAULT_ROLES.PLAYER}
    end
    
    return roles
end

--! \brief Get the highest priority role for a player
--! \param username Player username
--! \return table|nil Role data
function FrameworkZ.Roles:GetPrimaryRole(username)
    local roles = self:GetPlayerRoles(username)
    local highestRole = nil
    local highestPriority = -1
    
    for _, roleId in ipairs(roles) do
        local role = self.RegisteredRoles[roleId]
        if role and role.priority > highestPriority then
            highestPriority = role.priority
            highestRole = role
        end
    end
    
    return highestRole or self.RegisteredRoles[self.DEFAULT_ROLES.PLAYER]
end

--! \brief Check if a player has a specific permission
--! \param username Player username (or IsoPlayer object)
--! \param permission Permission string (supports wildcards)
--! \return boolean Has permission
function FrameworkZ.Roles:HasPermission(username, permission)
    -- Handle IsoPlayer object
    if type(username) ~= "string" then
        if username and username.getUsername then
            username = username:getUsername()
        elseif username and username.GetUsername then
            username = username:GetUsername()
        else
            return false
        end
    end
    
    if not username or not permission then return false end
    
    -- Check cache first
    if self.PermissionCache[username] and self.PermissionCache[username][permission] ~= nil then
        return self.PermissionCache[username][permission]
    end
    
    -- Get all permissions for this player
    local allPermissions = self:GetAllPermissions(username)
    
    -- Check for exact match
    if allPermissions[permission] then
        self:CachePermission(username, permission, true)
        return true
    end
    
    -- Check for wildcard match
    for perm, _ in pairs(allPermissions) do
        if self:MatchesWildcard(permission, perm) then
            self:CachePermission(username, permission, true)
            return true
        end
    end
    
    -- Check if player has "*" (all permissions)
    if allPermissions["*"] then
        self:CachePermission(username, permission, true)
        return true
    end
    
    self:CachePermission(username, permission, false)
    return false
end

--! \brief Get all permissions for a player (including inherited)
--! \param username Player username
--! \return table Map of permission -> true
function FrameworkZ.Roles:GetAllPermissions(username)
    local allPermissions = {}
    local processedRoles = {} -- Prevent circular inheritance
    
    local function addRolePermissions(roleId)
        if processedRoles[roleId] then return end
        processedRoles[roleId] = true
        
        local role = self.RegisteredRoles[roleId]
        if not role then return end
        
        -- Add this role's permissions
        for _, perm in ipairs(role.permissions) do
            allPermissions[perm] = true
        end
        
        -- Add inherited permissions
        if role.inherits then
            for _, inheritedRoleId in ipairs(role.inherits) do
                addRolePermissions(inheritedRoleId)
            end
        end
    end
    
    -- Process all player roles
    local roles = self:GetPlayerRoles(username)
    for _, roleId in ipairs(roles) do
        addRolePermissions(roleId)
    end
    
    return allPermissions
end

--! \brief Check if a permission matches a wildcard pattern
--! \param permission Permission to check
--! \param pattern Pattern with wildcards (e.g., "chat.*")
--! \return boolean Matches
function FrameworkZ.Roles:MatchesWildcard(permission, pattern)
    -- Convert wildcard pattern to Lua pattern
    local luaPattern = "^" .. pattern:gsub("%.", "%%."):gsub("%*", ".*") .. "$"
    return permission:match(luaPattern) ~= nil
end

--! \brief Cache a permission check result
function FrameworkZ.Roles:CachePermission(username, permission, result)
    if not self.PermissionCache[username] then
        self.PermissionCache[username] = {}
    end
    self.PermissionCache[username][permission] = result
end

--! \brief Clear permission cache
function FrameworkZ.Roles:ClearPermissionCache(username)
    if username then
        self.PermissionCache[username] = nil
    else
        self.PermissionCache = {}
    end
end

--! \brief Get a role by ID
--! \param roleId Role ID
--! \return table|nil Role data
function FrameworkZ.Roles:GetRole(roleId)
    return self.RegisteredRoles[roleId]
end

--! \brief Get all registered roles
--! \return table Map of roleId -> role data
function FrameworkZ.Roles:GetAllRoles()
    return self.RegisteredRoles
end

--! \brief Get count of registered roles
--! \return number Count
function FrameworkZ.Roles:GetRoleCount()
    local count = 0
    for _ in pairs(self.RegisteredRoles) do
        count = count + 1
    end
    return count
end

--! \brief Count players with role assignments
--! \return number Count
function FrameworkZ.Roles:CountAssignedPlayers()
    local count = 0
    for _ in pairs(self.PlayerRoles) do
        count = count + 1
    end
    return count
end

--! \brief Get all players with a specific role
--! \param roleId Role ID
--! \return table Array of usernames
function FrameworkZ.Roles:GetPlayersWithRole(roleId)
    local players = {}
    
    for username, roles in pairs(self.PlayerRoles) do
        for _, playerRoleId in ipairs(roles) do
            if playerRoleId == roleId then
                table.insert(players, username)
                break
            end
        end
    end
    
    return players
end

--! \brief Check if a player has a specific role
--! \param username Player username
--! \param roleId Role ID
--! \return boolean Has role
function FrameworkZ.Roles:HasRole(username, roleId)
    local roles = self:GetPlayerRoles(username)
    
    for _, playerRoleId in ipairs(roles) do
        if playerRoleId == roleId then
            return true
        end
    end
    
    return false
end

--! \brief Get formatted role name with color for display
--! \param roleId Role ID
--! \return string Formatted name
function FrameworkZ.Roles:GetFormattedRoleName(roleId)
    local role = self.RegisteredRoles[roleId]
    if not role then return roleId end
    
    -- Return just the name for now (could add color codes later)
    return role.name
end

--! \brief Get role color
--! \param roleId Role ID
--! \return table {r, g, b} or nil
function FrameworkZ.Roles:GetRoleColor(roleId)
    local role = self.RegisteredRoles[roleId]
    return role and role.color or nil
end

--! \brief Unregister a role
--! \param roleId Role ID
--! \return boolean Success
function FrameworkZ.Roles:UnregisterRole(roleId)
    if not roleId then return false end
    
    -- Don't allow removing default roles
    for _, defaultRoleId in pairs(self.DEFAULT_ROLES) do
        if roleId == defaultRoleId then
            print("[FrameworkZ] Cannot unregister default role: " .. roleId)
            return false
        end
    end
    
    -- Remove from registry
    self.RegisteredRoles[roleId] = nil
    self.RoleHierarchy[roleId] = nil
    
    -- Remove from all players
    for username, roles in pairs(self.PlayerRoles) do
        for i = #roles, 1, -1 do
            if roles[i] == roleId then
                table.remove(roles, i)
            end
        end
    end
    
    -- Clear caches
    self:ClearPermissionCache()
    self:SavePlayerRoles()
    
    print("[FrameworkZ] Unregistered role: " .. roleId)
    return true
end

