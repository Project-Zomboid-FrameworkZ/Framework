FrameworkZ = FrameworkZ or {}

--! \brief Roles module for FrameworkZ. Provides role-based permission system.
--! \module FrameworkZ.Roles
FrameworkZ.Roles = {}

FrameworkZ.Roles = FrameworkZ.Foundation:NewModule(FrameworkZ.Roles, "Roles")

-- Role registry: roleId -> role data
FrameworkZ.Roles.RegisteredRoles = {}
FrameworkZ.Roles.RoleHierarchy    = {}

-- Player role assignments: username -> roleId (exactly one role per player)
FrameworkZ.Roles.PlayerRoles = {}

-- Permission cache for faster lookups
FrameworkZ.Roles.PermissionCache = {}

-- Group registry: groupId -> { id, name, roles = { roleId, ... } }
-- Groups are code-defined collections of roles. Membership is derived from PlayerRoles.
FrameworkZ.Roles.Groups = {}

-- Built-in default role IDs
FrameworkZ.Roles.DEFAULT_ROLES = {
    PLAYER    = "player",
    MODERATOR = "moderator",
    ADMIN     = "admin",
    SUPERADMIN = "superadmin",
}

--[[ ============================================================
     Lifecycle
     ============================================================ ]]--

--! \brief Registers the Roles namespace and seeds roles/data on game init.
function FrameworkZ.Roles:OnInitGlobalModData()
    FrameworkZ.Foundation:RegisterNamespace("Roles")
    self:RegisterDefaultRoles()
    self:LoadCustomRoles()
    if isServer() then
        self:LoadPlayerRoles()
    end
    print("[FrameworkZ] Roles module ready with " .. self:GetRoleCount() .. " roles")
end

--[[ ============================================================
     Role Registration
     ============================================================ ]]--

--! \brief Register the four built-in default roles.
function FrameworkZ.Roles:RegisterDefaultRoles()
    self:RegisterRole({
        id          = self.DEFAULT_ROLES.PLAYER,
        name        = "Player",
        description = "Default player role with basic permissions",
        color       = { r=1.0, g=1.0, b=1.0 },
        permissions = { "chat.send", "chat.receive", "faction.view", "property.view" },
        priority    = 0,
        isDefault   = true,
    })
    self:RegisterRole({
        id          = self.DEFAULT_ROLES.MODERATOR,
        name        = "Moderator",
        description = "Moderator with basic administrative powers",
        color       = { r=0.0, g=0.8, b=1.0 },
        permissions = {
            "chat.*", "faction.*",
            "property.view", "property.manage",
            "player.kick", "player.mute",
            "commands.teleport",
        },
        inherits  = { self.DEFAULT_ROLES.PLAYER },
        priority  = 50,
    })
    self:RegisterRole({
        id          = self.DEFAULT_ROLES.ADMIN,
        name        = "Admin",
        description = "Administrator with full server control",
        color       = { r=1.0, g=0.5, b=0.0 },
        permissions = {
            "chat.*", "faction.*", "property.*",
            "player.*", "commands.*",
            "roles.assign", "roles.remove",
        },
        inherits  = { self.DEFAULT_ROLES.MODERATOR },
        priority  = 100,
    })
    self:RegisterRole({
        id          = self.DEFAULT_ROLES.SUPERADMIN,
        name        = "Super Admin",
        description = "Super Administrator with unrestricted access",
        color       = { r=1.0, g=0.0, b=0.0 },
        permissions = { "*" },
        inherits    = { self.DEFAULT_ROLES.ADMIN },
        priority    = 999,
    })
end

--! \brief Register a new role.
--! \param roleData \table { id, name, description?, color?, permissions?, inherits?, priority?, isDefault?, metadata? }
--! \return \boolean Success
function FrameworkZ.Roles:RegisterRole(roleData)
    if not roleData or not roleData.id then
        print("[FrameworkZ] Error: Cannot register role without ID")
        return false
    end
    if not roleData.name then
        print("[FrameworkZ] Error: Role " .. roleData.id .. " missing name")
        return false
    end
    local role = {
        id          = roleData.id,
        name        = roleData.name,
        description = roleData.description or "",
        color       = roleData.color or { r=1.0, g=1.0, b=1.0 },
        permissions = roleData.permissions or {},
        inherits    = roleData.inherits or {},
        priority    = roleData.priority or 0,
        isDefault   = roleData.isDefault or false,
        metadata    = roleData.metadata or {},
    }
    self.RegisteredRoles[role.id] = role
    self.RoleHierarchy[role.id]   = { priority = role.priority, inherits = role.inherits }
    self:ClearPermissionCache()
    print("[FrameworkZ] Registered role: " .. role.name .. " (" .. role.id .. ")")
    return true
end

--! \brief Unregister a custom role. Default roles cannot be removed.
--! Any player holding the unregistered role has their assignment cleared.
--! \param roleId \string
--! \return \boolean Success
function FrameworkZ.Roles:UnregisterRole(roleId)
    if not roleId then return false end
    for _, defaultId in pairs(self.DEFAULT_ROLES) do
        if roleId == defaultId then
            print("[FrameworkZ] Cannot unregister default role: " .. roleId)
            return false
        end
    end
    self.RegisteredRoles[roleId] = nil
    self.RoleHierarchy[roleId]   = nil
    for username, assignedId in pairs(self.PlayerRoles) do
        if assignedId == roleId then
            self.PlayerRoles[username] = nil
        end
    end
    self:ClearPermissionCache()
    self:SavePlayerRoles()
    print("[FrameworkZ] Unregistered role: " .. roleId)
    return true
end

--! \brief Hook point for custom role files to self-register.
function FrameworkZ.Roles:LoadCustomRoles()
    print("[FrameworkZ] Loading custom roles...")
    -- Custom role files placed in the correct directory are auto-loaded by PZ.
end

--[[ ============================================================
     Player Role Persistence  (Namespace: "Roles", Key: "PlayerRoles")
     ============================================================ ]]--

--! \brief Load player role assignments from persistent storage.
function FrameworkZ.Roles:LoadPlayerRoles()
    local data = FrameworkZ.Foundation:GetData(nil, "Roles", "PlayerRoles")
    if type(data) == "table" then
        self.PlayerRoles = data
    end
    print("[FrameworkZ] Loaded role assignments for " .. self:CountAssignedPlayers() .. " players")
end

--! \brief Persist player role assignments.
function FrameworkZ.Roles:SavePlayerRoles()
    FrameworkZ.Foundation:SetData(nil, "Roles", "PlayerRoles", self.PlayerRoles, nil, true)
end

--[[ ============================================================
     Player Role Assignment  (one role per player)
     ============================================================ ]]--

--! \brief Return the roleId assigned to a player, or the default player role.
--! \param username \string
--! \return \string roleId
function FrameworkZ.Roles:GetPlayerRole(username)
    if not username then return self.DEFAULT_ROLES.PLAYER end
    return self.PlayerRoles[username] or self.DEFAULT_ROLES.PLAYER
end

--! \brief Assign exactly one role to a player, replacing any previous assignment.
--! \param username \string
--! \param roleId \string
--! \return \boolean Success
function FrameworkZ.Roles:AssignRole(username, roleId)
    if not username or not roleId then return false end
    if not self.RegisteredRoles[roleId] then
        print("[FrameworkZ] Error: Role " .. roleId .. " does not exist")
        return false
    end
    if self.PlayerRoles[username] == roleId then return true end
    self.PlayerRoles[username]       = roleId
    self.PermissionCache[username]   = nil
    self:SavePlayerRoles()
    print("[FrameworkZ] Assigned role " .. roleId .. " to " .. username)
    return true
end

--! \brief Remove the role assignment from a player.
--! If roleId is supplied the removal only proceeds when the player currently holds that exact role.
--! \param username \string
--! \param roleId \string? Optional guard — only remove if this is their current role.
--! \return \boolean Success
function FrameworkZ.Roles:RemoveRole(username, roleId)
    if not username then return false end
    if not self.PlayerRoles[username] then return false end
    if roleId and self.PlayerRoles[username] ~= roleId then return false end
    self.PlayerRoles[username]     = nil
    self.PermissionCache[username] = nil
    self:SavePlayerRoles()
    print("[FrameworkZ] Removed role from " .. username)
    return true
end

--! \brief Check whether a player is assigned a specific role.
--! \param username \string
--! \param roleId \string
--! \return \boolean
function FrameworkZ.Roles:HasRole(username, roleId)
    return self:GetPlayerRole(username) == roleId
end

--! \brief Return the full role data table for a player's assigned role.
--! \param username \string
--! \return \table role data
function FrameworkZ.Roles:GetPrimaryRole(username)
    return self.RegisteredRoles[self:GetPlayerRole(username)]
        or self.RegisteredRoles[self.DEFAULT_ROLES.PLAYER]
end

--! \brief Number of players with an explicit role assignment.
--! \return \integer
function FrameworkZ.Roles:CountAssignedPlayers()
    local n = 0
    for _ in pairs(self.PlayerRoles) do n = n + 1 end
    return n
end

--[[ ============================================================
     Permissions
     ============================================================ ]]--

--! \brief Collect all permissions for a player by walking role inheritance.
--! \param username \string
--! \return \table Map of permission string -> true
function FrameworkZ.Roles:GetAllPermissions(username)
    local perms   = {}
    local visited = {}
    local function collect(roleId)
        if visited[roleId] then return end
        visited[roleId] = true
        local role = self.RegisteredRoles[roleId]
        if not role then return end
        for _, p in ipairs(role.permissions) do perms[p] = true end
        for _, inherited in ipairs(role.inherits) do collect(inherited) end
    end
    collect(self:GetPlayerRole(username))
    return perms
end

--! \brief Check whether a player has a given permission (wildcard-aware).
--! \param username \string or IsoPlayer
--! \param permission \string
--! \return \boolean
function FrameworkZ.Roles:HasPermission(username, permission)
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
    local cache = self.PermissionCache[username]
    if cache and cache[permission] ~= nil then return cache[permission] end
    local perms  = self:GetAllPermissions(username)
    local result = perms["*"] == true
    if not result then result = perms[permission] == true end
    if not result then
        for p in pairs(perms) do
            if self:MatchesWildcard(permission, p) then result = true; break end
        end
    end
    self:CachePermission(username, permission, result)
    return result
end

--! \brief Test whether a permission string matches a wildcard pattern (e.g. "chat.*").
function FrameworkZ.Roles:MatchesWildcard(permission, pattern)
    local lp = "^" .. pattern:gsub("%.", "%%."):gsub("%*", ".*") .. "$"
    return permission:match(lp) ~= nil
end

--! \brief Store a permission-check result in the per-player cache.
function FrameworkZ.Roles:CachePermission(username, permission, result)
    if not self.PermissionCache[username] then self.PermissionCache[username] = {} end
    self.PermissionCache[username][permission] = result
end

--! \brief Invalidate permission cache for one player, or for all players when username is nil.
function FrameworkZ.Roles:ClearPermissionCache(username)
    if username then
        self.PermissionCache[username] = nil
    else
        self.PermissionCache = {}
    end
end

--[[ ============================================================
     Groups
     Groups are code-defined collections of roles. They are never
     persisted — membership is always derived live from PlayerRoles.
     ============================================================ ]]--

--! \brief Register a group.
--! \param groupData \table { id \string, name \string, roles \table }
--! \return \boolean Success
function FrameworkZ.Roles:RegisterGroup(groupData)
    if not groupData or not groupData.id or not groupData.name then
        print("[FrameworkZ] Error: Cannot register group without id and name")
        return false
    end
    self.Groups[groupData.id] = {
        id    = groupData.id,
        name  = groupData.name,
        roles = groupData.roles or {},
    }
    print("[FrameworkZ] Registered group: " .. groupData.name .. " (" .. groupData.id .. ")")
    return true
end

--! \brief Return the group definition for a given id, or nil.
--! \param groupId \string
--! \return \table|nil
function FrameworkZ.Roles:GetGroup(groupId)
    return self.Groups[groupId]
end

--! \brief Return all registered group definitions.
--! \return \table
function FrameworkZ.Roles:GetAllGroups()
    return self.Groups
end

--! \brief Derive live membership for every role in a group from the current PlayerRoles table.
--! \param groupId \string
--! \return \table|nil { roleId -> { username, ... } }, or nil if the group does not exist.
function FrameworkZ.Roles:GetGroupMembership(groupId)
    local group = self.Groups[groupId]
    if not group then return nil end
    local membership = {}
    for _, roleId in ipairs(group.roles) do
        membership[roleId] = {}
    end
    for username, roleId in pairs(self.PlayerRoles) do
        if membership[roleId] then
            table.insert(membership[roleId], username)
        end
    end
    return membership
end

--! \brief Return all players currently assigned to a specific role.
--! \param roleId \string
--! \return \table Array of username strings
function FrameworkZ.Roles:GetPlayersWithRole(roleId)
    local players = {}
    for username, assignedId in pairs(self.PlayerRoles) do
        if assignedId == roleId then
            table.insert(players, username)
        end
    end
    return players
end

--[[ ============================================================
     Role Info Helpers
     ============================================================ ]]--

--! \brief Return the role data table for a given roleId.
function FrameworkZ.Roles:GetRole(roleId)
    return self.RegisteredRoles[roleId]
end

--! \brief Return the full RegisteredRoles table.
function FrameworkZ.Roles:GetAllRoles()
    return self.RegisteredRoles
end

--! \brief Return the number of registered roles.
function FrameworkZ.Roles:GetRoleCount()
    local n = 0
    for _ in pairs(self.RegisteredRoles) do n = n + 1 end
    return n
end

--! \brief Return the role marked as default (isDefault = true).
--! When more than one default is registered the one with the highest priority wins.
--! Falls back to DEFAULT_ROLES.PLAYER if nothing is found.
--! \return \table Role data table
function FrameworkZ.Roles:GetDefaultRole()
    local best = nil
    for _, role in pairs(self.RegisteredRoles) do
        if role.isDefault then
            if not best or role.priority > best.priority then
                best = role
            end
        end
    end
    return best or self.RegisteredRoles[self.DEFAULT_ROLES.PLAYER]
end

--! \brief Ensure a player has a role. If none is recorded, assign the default role.
--! Safe to call for both brand-new players and returning players.
--! \param username \string
--! \return \string The player's roleId (existing or newly assigned default)
function FrameworkZ.Roles:EnsurePlayerRole(username)
    if not username then return false end
    if self.PlayerRoles[username] then return self.PlayerRoles[username] end
    local defaultRole = self:GetDefaultRole()
    if not defaultRole then return false end
    self:AssignRole(username, defaultRole.id)
    return defaultRole.id
end

--! \brief Return the display name for a roleId, falling back to the raw id.
function FrameworkZ.Roles:GetFormattedRoleName(roleId)
    local role = self.RegisteredRoles[roleId]
    return role and role.name or roleId
end

--! \brief Return the { r, g, b } color table for a roleId, or nil.
function FrameworkZ.Roles:GetRoleColor(roleId)
    local role = self.RegisteredRoles[roleId]
    return role and role.color or nil
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Roles)

