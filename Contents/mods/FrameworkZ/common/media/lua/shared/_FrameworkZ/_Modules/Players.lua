--! \page Features
--! \section Players Players
--! Players are the entities that connect to the game server. Each player can have multiple characters and can switch between said characters at any time. Players can also be assigned roles and permissions within the game.
--! Now it's important to distinguish between players characters, imagine the player as the thing controlling the character. The "person" vs the "avatar" where the avatar is the in-game representation of the player and what/whom they're roleplaying as.

--! \page Global Variables
--! \section Players Players
--! FrameworkZ.Players
--! See Players for the module on players.
--! FrameworkZ.Players.List
--! A list of all instanced players in the game.

local getPlayer = getPlayer
local isClient = isClient

FrameworkZ = FrameworkZ or {}

--! \brief Players module for FrameworkZ. Defines and interacts with PLAYER object.
--! \module FrameworkZ.Players
FrameworkZ.Players = {}

--! \brief List of all instanced players in the game.
FrameworkZ.Players.List = {}
FrameworkZ.Players._loadInProgress = {}
FrameworkZ.Players._saveState = {}
FrameworkZ.Players._remoteSaveState = {}
FrameworkZ.Players._disconnectInProgress = FrameworkZ.Players._disconnectInProgress or {}
FrameworkZ.Players._destroyInProgress = FrameworkZ.Players._destroyInProgress or {}

function FrameworkZ.Players:EnsureSaveState(username)
    if not username then return nil end

    self._saveState[username] = self._saveState[username] or {
        player = 0,
        character = 0,
        characterID = nil,
    }

    return self._saveState[username]
end

function FrameworkZ.Players:BeginPlayerSave(username)
    local state = self:EnsureSaveState(username)
    if not state then return 0 end

    state.player = (state.player or 0) + 1
    return state.player
end

function FrameworkZ.Players:BeginCharacterSave(username, characterID)
    local state = self:EnsureSaveState(username)
    if not state then return 0 end

    state.character = (state.character or 0) + 1
    state.characterID = characterID
    return state.character
end

function FrameworkZ.Players:CanWritePlayerSave(username, token)
    local state = self:EnsureSaveState(username)
    return state and token ~= nil and token == state.player
end

function FrameworkZ.Players:CanWriteCharacterSave(username, token, characterID)
    local state = self:EnsureSaveState(username)
    if not state or token == nil then return false end

    if token ~= state.character then
        return false
    end

    if characterID ~= nil and state.characterID ~= nil and state.characterID ~= characterID then
        return false
    end

    return true
end

function FrameworkZ.Players:EnsureRemoteSaveState(username, isoPlayer)
    if not username then return nil end

    local state = self._remoteSaveState[username]
    if not state or state.isoPlayer ~= isoPlayer then
        state = {
            isoPlayer = isoPlayer,
            player = nil,
            character = nil,
            characterID = nil,
        }
        self._remoteSaveState[username] = state
    end

    return state
end

function FrameworkZ.Players:CanAcceptRemotePlayerSave(username, isoPlayer, token)
    local state = self:EnsureRemoteSaveState(username, isoPlayer)
    if not state or token == nil then return false end
    if state.player ~= nil and token <= state.player then return false end

    state.player = token
    return true
end

function FrameworkZ.Players:CanAcceptRemoteCharacterSave(username, isoPlayer, token, characterID)
    local state = self:EnsureRemoteSaveState(username, isoPlayer)
    if not state or token == nil then return false end
    if state.character ~= nil and token <= state.character then return false end

    state.character = token
    state.characterID = characterID
    return true
end

--! \brief Roles for players in FrameworkZ.
FrameworkZ.Players.Roles = {
    User = "User",
    Operator = "Operator",
    Moderator = "Moderator",
    Admin = "Admin",
    Super_Admin = "Super Admin",
    Owner = "Owner"
}
FrameworkZ.Players = FrameworkZ.Foundation:NewModule(FrameworkZ.Players, "Players")

--! \class PLAYER
--! \brief Player class for FrameworkZ.
local PLAYER = {}
PLAYER.__index = PLAYER

--! \brief Initializes the player object.
--! \return \string The username of the player.
function PLAYER:Initialize()
    if not self:GetIsoPlayer() then return false end

    self:InitializeDefaultFactionWhitelists()
end

--! \brief Saves the player's data.
--! \param callback \function? Optional callback(success, message) invoked after server save confirmation.
--! \return \boolean Whether or not the player save was initiated.
--! \todo Test if localized variable (playerData) maintains referential integrity for transmitModData() to work on it.
function PLAYER:Save(callback)
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Missing Iso Player: PLAYER.Save" end
    local saveablePlayerData = self:GetSaveableData() if not saveablePlayerData then return false, "Missing Saveable Player Data." end

    local saveToken = FrameworkZ.Players:BeginPlayerSave(self:GetUsername())
    FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Players.Save", callback, self:GetUsername(), saveablePlayerData, saveToken)

    return true
end

--! \brief Destroys the player object.
--! \return \mixed of \boolean Whether or not the player was successfully destroyed and \string The message on success or failure.
function PLAYER:Destroy(callback)
    if not self:GetIsoPlayer() then 
        if callback then callback(false, "Critical save fail: Iso Player is nil.") end
        return false, "Critical save fail: Iso Player is nil." 
    end

    local username = self:GetUsername()
    local isoPlayer = self:GetIsoPlayer()
    local saveablePlayerData = self:GetSaveableData()
    local playerSaveToken = FrameworkZ.Players:BeginPlayerSave(username)
    local saveableCharacterData = nil
    local loadedCharacter = self:GetCharacter()
    local loadedCharacterID = self:GetLoadedCharacterID()
    local characterSaveToken = FrameworkZ.Players:BeginCharacterSave(username, loadedCharacterID)

    if loadedCharacter then
        if loadedCharacterID ~= nil and loadedCharacter.SetID then
            loadedCharacter:SetID(loadedCharacterID)
        elseif loadedCharacterID == nil and loadedCharacter.GetID then
            loadedCharacterID = loadedCharacter:GetID()
        end

        local okSync, synced, syncMessage = pcall(function()
            return loadedCharacter:Sync()
        end)
        if not okSync or not synced then
            local message = "Character sync during destroy failed: " .. tostring(okSync and syncMessage or synced)
            print("[FrameworkZ] Warning: " .. message)
            if callback then callback(false, message) end
            return false, message
        end
        saveableCharacterData = loadedCharacter:GetSaveableData()

        if type(saveableCharacterData) == "table" and loadedCharacterID ~= nil then
            saveableCharacterData[FZ_ENUM_CHARACTER_META_ID] = loadedCharacterID
        end
    end

    -- Remove auto-save timer when destroying character
    if isClient() and FrameworkZ.Timers:Exists("FZ_CharacterSaveInterval") then
        FrameworkZ.Timers:Remove("FZ_CharacterSaveInterval")
        print("[FrameworkZ] Auto-save timer removed during character destroy")
    end

    -- Save player and character data, then cleanup and call callback
    if FrameworkZ.Players.List[username] or FrameworkZ.Characters.List[username] then
        FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Players.Destroy", function(data, success)
            local message1, message2
            
            if success then
                print("[FrameworkZ] Player and character data saved successfully before destroy")
            else
                print("[FrameworkZ] Warning: Save failed during destroy")
                message1 = "Save failed"
            end

            -- Cleanup lists
            if FrameworkZ.Characters.List[username] then
                FrameworkZ.Characters.List[username] = nil
            end

            if FrameworkZ.Players.List[username] then
                FrameworkZ.Players.List[username] = nil
            end

            -- Call user callback if provided
            if callback then
                callback(success, message1 or message2 or "Player destroyed")
            end
        end, username, saveablePlayerData, saveableCharacterData, loadedCharacterID, playerSaveToken, characterSaveToken)
    else
        -- No data to save, just call callback
        if callback then
            callback(true, "No player or character data to save")
        end
    end
    
    return true, "Player destroy initiated"
end

--! \brief Initialize default faction whitelists for the player based on faction settings.
--! \details Automatically whitelists the player for all factions that have isWhitelistedByDefault set to true.
function PLAYER:InitializeDefaultFactionWhitelists()
    local factions = FrameworkZ.Factions.List

    for k, v in pairs(factions) do
        if v.isWhitelistedByDefault then
            self.Whitelists[v.id] = true
        end
    end
end

--! \brief Restore player data from saved data table.
--! \param data table The saved player data containing MaxCharacters, PreviousCharacter, Whitelists, and CustomData.
--! Role is managed separately by the Roles module; call PLAYER:RestoreRole() for role restoration.
function PLAYER:RestoreData(data)
    self:SetMaxCharacters(data.MaxCharacters)
    self:SetPreviousCharacter(data.PreviousCharacter)
    self:SetWhitelists(data.Whitelists)
    self:SetCustomData(data.CustomData)
    self:RestoreRole()
end

--! \brief Restore the player's role from persistent Roles storage.
--! For a returning player this confirms the saved role is still valid and the role
--! definition still exists. For a brand-new player this assigns the default role.
--! \return \string roleId The confirmed or newly-assigned roleId.
--! \return \string message Status message.
function PLAYER:RestoreRole()
    if not FrameworkZ.Roles then
        return false, "Roles module not available."
    end

    local username  = self:GetUsername()
    local currentId = FrameworkZ.Roles.PlayerRoles[username]

    -- Brand-new player — no stored role yet.
    if not currentId then
        local assignedId = FrameworkZ.Roles:EnsurePlayerRole(username)
        print("[FrameworkZ] RestoreRole: assigned default role '" .. tostring(assignedId) .. "' to new player '" .. username .. "'")
        return assignedId, "Default role assigned."
    end

    -- Returning player — validate the stored role still exists (in case roles were removed).
    if not FrameworkZ.Roles.RegisteredRoles[currentId] then
        print("[FrameworkZ] RestoreRole: stored role '" .. currentId .. "' no longer exists for '" .. username .. "'. Reassigning default.")
        FrameworkZ.Roles.PlayerRoles[username] = nil
        local assignedId = FrameworkZ.Roles:EnsurePlayerRole(username)
        return assignedId, "Stored role invalid; default role reassigned."
    end

    print("[FrameworkZ] RestoreRole: confirmed role '" .. currentId .. "' for '" .. username .. "'")
    return currentId, "Role restored."
end

--! \brief Get the player's previous character ID.
--! \return number The ID of the character the player last played.
function PLAYER:GetPreviousCharacter()
    return self.PreviousCharacter
end

--! \brief Set the player's previous character ID.
--! \param previousCharacter number The character ID to set as previous character.
--! \return boolean|nil True if set successfully, false if invalid input.
function PLAYER:SetPreviousCharacter(previousCharacter)
    if not previousCharacter or type(previousCharacter) ~= "number" then
        print("Failed to set Previous Character to: '" .. tostring(previousCharacter) .. "'. Previous Character must be a number.")
        return false
    end

    self.PreviousCharacter = previousCharacter

    return true
end

--! \brief Get the maximum number of characters the player can create.
--! \return number The maximum character limit for this player.
function PLAYER:GetMaxCharacters()
    return self.maxCharacters
end

--! \brief Set the maximum number of characters the player can create.
--! \param maxCharacters number The maximum character limit (must be at least 1).
--! \return boolean|nil True if set successfully, false if invalid input.
function PLAYER:SetMaxCharacters(maxCharacters)
    if not maxCharacters or type(maxCharacters) ~= "number" then
        print("Failed to set Max Characters to: '" .. tostring(maxCharacters) .. "'. Max Characters must be a number.")
        return false
    end

    if maxCharacters < 1 then
        print("Failed to set Max Characters to: '" .. tostring(maxCharacters) .. "'. Max Characters must be at least 1.")
        return false
    end

    self.MaxCharacters = maxCharacters

    return true
end

--! \brief Get the player's custom data table.
--! \return table The custom data table for storing additional player information.
function PLAYER:GetCustomData()
    return self.CustomData
end

--! \brief Set the player's custom data table.
--! \param customData table The custom data table to store.
--! \return boolean|nil True if set successfully, false if invalid input.
function PLAYER:SetCustomData(customData)
    if not customData or type(customData) ~= "table" then
        print("Failed to set Custom Data to: '" .. tostring(customData) .. "'. Custom Data must be a table.")
        return false
    end

    self.CustomData = customData

    return true
end

--! \brief Get the player's currently loaded character.
--! \return CHARACTER|nil The currently loaded character object or nil if no character is loaded.
function PLAYER:GetCharacter()
    return self.LoadedCharacter
end

--! \brief Get the ID of the player's currently loaded character.
--! \details Captured at the moment SetCharacter() was called, independent of the character
--! object's own (mutable) self.ID field. Used as a reliable fallback when saving the currently
--! loaded character before a character switch (see LoadCharacterByID), since self.ID can be
--! nil if the character's data was re-restored with an incomplete payload.
--! \return number|nil The loaded character's ID or nil if no character is loaded.
function PLAYER:GetLoadedCharacterID()
    return self.LoadedCharacterID
end

--! \brief Get the player's Steam ID.
--! \return string The player's Steam ID.
function PLAYER:GetSteamID()
    return self.SteamID
end

--! \brief Set the player's Steam ID.
--! \param steamID string The Steam ID (read-only, cannot be changed after creation).
function PLAYER:SetSteamID(steamID)
    print("Failed to set SteamID to: '" .. tostring(steamID) .. "'. SteamID is read-only and must be set upon object creation.")
end

--! \brief Get the player's current role ID from the Roles module.
--! \return \string roleId (e.g. "player", "admin", "superadmin")
function PLAYER:GetRole()
    return self.Role
end

--! \brief Set the player's role via the Roles module.
--! \param roleId \string The roleId to assign (must be registered in FrameworkZ.Roles).
--! \return \boolean Success
function PLAYER:SetRole(roleId)
    if not roleId then return false end

    self.Role = roleId

    return true
end

--! \brief Set the player's currently loaded character.
--! \param character CHARACTER The character object to set as the loaded character.
function PLAYER:SetCharacter(character)
    self.LoadedCharacter = character
    -- Snapshot the ID at the moment it's known-good (right after a successful Restore()),
    -- decoupled from character.ID so a later, unrelated RestoreData() call on this same
    -- object can't silently erase our ability to know which character is/was loaded.
    self.LoadedCharacterID = character and character.GetID and character:GetID() or nil
end

--! \brief Get all characters owned by this player.
--! \return table Table of character data indexed by character ID.
function PLAYER:GetCharacters()
    return self.Characters
end

--! \brief Set the characters table for this player.
--! \param characters table Table of character data indexed by character ID.
function PLAYER:SetCharacters(characters)
    self.Characters = characters
end

--! \brief Get character data by character ID with optional async callback.
--! \param characterID number The ID of the character to retrieve.
--! \param callback function? Optional callback function(data, message) for async retrieval.
--! \return table|boolean Character data table or false if not found.
--! \return string Message describing success or failure.
function PLAYER:GetCharacterDataByID(characterID, callback)
    if not characterID then 
        if callback then callback(false, "Missing character ID.") end
        return false, "Missing character ID." 
    end

    if isServer() then
        -- On server, try to get updated data from global mod data synchronously
        local globalCharacterData = FrameworkZ.Foundation:GetData(self:GetIsoPlayer(), "Characters", {self:GetUsername(), characterID})
        
        if globalCharacterData then
            -- Update local cache with global data
            self.Characters[characterID] = globalCharacterData
            if callback then callback(globalCharacterData, "Successfully retrieved character data from global storage.") end
            return globalCharacterData, "Successfully retrieved character data from global storage."
        end

        -- Fallback to local data if global data is not available
        local character = self.Characters[characterID]

        if character then
            if callback then callback(character, "Successfully retrieved character data from local cache.") end
            return character, "Successfully retrieved character data from local cache."
        end

        if callback then callback(false, "Character not found.") end
        return false, "Character not found."
    elseif isClient() then
        -- On client, use async GetData with callback
        FrameworkZ.Foundation:GetData(self:GetIsoPlayer(), "Characters", {self:GetUsername(), characterID}, nil, function(isoPlayer, namespace, keys, value)
            if value then
                -- Update local cache with global data
                self.Characters[characterID] = value
                if callback then callback(value, "Successfully retrieved character data from global storage.") end
            else
                -- Fallback to local data if global data is not available
                local character = self.Characters[characterID]
                
                if character then
                    if callback then callback(character, "Successfully retrieved character data from local cache.") end
                else
                    if callback then callback(false, "Character not found.") end
                end
            end
        end)

        -- On client, return local cache immediately for backwards compatibility
        local character = self.Characters[characterID]
        if character then
            return character, "Successfully retrieved character data from local cache."
        end
        return false, "Character not found."
    end
end

--! \brief Get the player's username.
--! \return string The player's username.
function PLAYER:GetUsername()
    return self.Username
end

--! \brief Set the player's username.
--! \param username string The username (read-only, cannot be changed after creation).
function PLAYER:SetUsername(username)
    print("Failed to set Username to: '" .. tostring(username) .. "'. Username is read-only and must be set upon object creation.")
end

--! \brief Get the player's IsoPlayer object.
--! \return IsoPlayer The Project Zomboid IsoPlayer object associated with this player.
function PLAYER:GetIsoPlayer()
    return self.IsoPlayer
end

--! \brief Set the player's IsoPlayer object.
--! \param isoPlayer IsoPlayer The IsoPlayer object (read-only, cannot be changed after creation).
function PLAYER:SetIsoPlayer(isoPlayer)
    print("Failed to set IsoPlayer to: '" .. tostring(isoPlayer) .. "'. IsoPlayer is read-only and must be set upon object creation.")
end

--! \brief Get player data suitable for saving/serialization.
--! \details Filters out non-saveable properties like IsoPlayer, LoadedCharacter, and Characters.
--! \return table Filtered player data table ready for saving.
function PLAYER:GetSaveableData()
    local ignoreList = {
        "IsoPlayer",
        "LoadedCharacter",
        "Characters"
    }

    return FrameworkZ.Foundation:ProcessSaveableData(self, ignoreList)
end

--! \brief Get the stored player mod data table.
--! \details WARNING: Internal use only. Direct modification will cause inconsistencies between mod data and the FrameworkZ player object.
--! \return table The raw FZ_PLY mod data table stored on the IsoPlayer.
function PLAYER:GetStoredData()
    return self.IsoPlayer:getModData()["FZ_PLY"]
end

--! \brief Get the player's faction whitelists.
--! \return table Table mapping faction IDs to whitelist status (true/false).
function PLAYER:GetWhitelists()
    return self.Whitelists
end

--! \brief Set the player's faction whitelists table.
--! \param whitelists table Table mapping faction IDs to whitelist status.
--! \return boolean|nil True if set successfully, false if invalid input.
function PLAYER:SetWhitelists(whitelists)
    if not whitelists or type(whitelists) ~= "table" then
        print("Failed to set Whitelists to: '" .. tostring(whitelists) .. "'. Whitelists must be a table.")
        return false
    end

    self.Whitelists = whitelists

    return true
end

--! \brief Set the player's whitelist status for a specific faction.
--! \param factionID string The faction ID to update whitelist status for.
--! \param whitelisted boolean Whether the player is whitelisted for this faction.
--! \return boolean|nil True if set successfully, false if faction ID not provided.
function PLAYER:SetWhitelisted(factionID, whitelisted)
    if not factionID then return false end

    self.Whitelists[factionID] = whitelisted
    self:GetStoredData().Whitelists[factionID] = whitelisted

    return true
end

--! \brief Check if the player is whitelisted for a specific faction.
--! \param factionID string The faction ID to check.
--! \return boolean True if whitelisted, false otherwise.
function PLAYER:IsWhitelisted(factionID)
    if not factionID then return false end
    if FrameworkZ.Factions:GetFactionByID(factionID).requiresWhitelist == false then return true end

    return self.Whitelists[factionID] or false
end

--! \brief Plays a sound for the player that only they can hear.
--! \param soundName \string The name of the sound to play.
--! \return \integer The sound's ID.
function PLAYER:PlayLocalSound(soundName)
    return self:GetIsoPlayer():getEmitter():playSoundImpl(soundName, nil)
end

--! \brief Stops a sound for the player.
--! \param soundNameOrID \mixed of \string or \integer The name or ID of the sound to stop.
function PLAYER:StopSound(soundNameOrID)
    if type(soundNameOrID) == "number" then
        self:GetIsoPlayer():getEmitter():stopSound(soundNameOrID)
    elseif type(soundNameOrID) == "string" then
        self:GetIsoPlayer():getEmitter():stopSoundByName(soundNameOrID)
    end
end

--[[
function PLAYER:ValidatePlayerData()
    local characterModData = self.isoPlayer:getModData()["FZ_PLY"]

    if not characterModData then return false end

    local initializedNewData = false

    if not characterModData.username then
        initializedNewData = true
        characterModData.username = self.username or getPlayer():getUsername()
    end

    if not characterModData.steamID then
        initializedNewData = true
        characterModData.steamID = self.steamID or getPlayer():getSteamID()
    end

    if not characterModData.role then
        initializedNewData = true
        characterModData.role = self.role or FrameworkZ.Players.Roles.User
    end

    if not characterModData.maxCharacters then
        initializedNewData = true
        characterModData.maxCharacters = self.maxCharacters or FrameworkZ.Config.Options.DefaultMaxCharacters
    end

    if not characterModData.previousCharacter then
        initializedNewData = true
        characterModData.previousCharacter = self.previousCharacter or nil
    end

    if not characterModData.whitelists then
        self:InitializeDefaultFactionWhitelists()
        initializedNewData = true
        characterModData.whitelists = self.whitelists
    end

    if not characterModData.Characters then
        initializedNewData = true
        characterModData.Characters = self.Characters or {}
    end

    if isClient() then
        self.isoPlayer:transmitModData()
    end

    self.username = characterModData.username
    self.steamID = characterModData.steamID
    self.role = characterModData.role
    self.maxCharacters = characterModData.maxCharacters
    self.previousCharacter = characterModData.previousCharacter
    self.whitelists = characterModData.whitelists
    self.Characters = characterModData.Characters

    return initializedNewData
end
--]]

--! \brief Create a new PLAYER object.
--! \param isoPlayer IsoPlayer The Project Zomboid IsoPlayer object to create a player for.
--! \return PLAYER|boolean The new PLAYER object or false if isoPlayer is nil.
function FrameworkZ.Players:New(isoPlayer)
    if not isoPlayer then return false end

    local object = {
        IsoPlayer = isoPlayer,
        Username = isoPlayer:getUsername(),
        SteamID = tostring(isoPlayer:getSteamID()),
        Role = FrameworkZ.Roles:GetDefaultRole(),
        LoadedCharacter = nil,
        LoadedCharacterID = nil,
        MaxCharacters = FrameworkZ.Config.Options.DefaultMaxCharacters,
        PreviousCharacter = nil,
        Whitelists = {},
        Characters = {},
        CustomData = {}
    }

    setmetatable(object, PLAYER)

	return object
end

--! \brief Initialize a player and add them to the player list.
--! \param isoPlayer IsoPlayer The Project Zomboid IsoPlayer object to initialize.
--! \return PLAYER|boolean The initialized PLAYER object or false if creation failed.
function FrameworkZ.Players:Initialize(isoPlayer)
    if not isoPlayer then return false end

    local username = isoPlayer:getUsername()
    if not username then return false end

    if self.List[username] then
        print("[FrameworkZ] Skipping duplicate player initialization for: " .. tostring(username))
        return self.List[username]
    end

    local player = FrameworkZ.Players:New(isoPlayer) if not player then return false end
    player:Initialize()

    self.List[username] = player
    self:StartPlayerTick(player)

    return self.List[username]
end

--! \brief Start the player tick system for executing periodic player updates.
--! \param player PLAYER The player object to start ticking for.
--! \details Only runs on client. Creates a timer that executes PlayerTick hooks at configured intervals.
function FrameworkZ.Players:StartPlayerTick(player)
    if not isClient() then return end

    FrameworkZ.Timers:Create("FZ_PLY_TICK", FrameworkZ.Config.Options.PlayerTickInterval, 0, function()
        FrameworkZ.Foundation:ExecuteAllHooks("PlayerTick", player)
    end)
end

--! \brief Get all registered players.
--! \return table Table of all PLAYER objects indexed by username.
function FrameworkZ.Players:GetAllPlayers()
    return self.List
end

--! \brief Gets the player object by their username.
--! \param username \string The username of the player.
--! \return \object|\boolean The player object or false if the player was not found.
function FrameworkZ.Players:GetPlayerByID(username)
    if not username then return false, "Username not set." end
    if not self.List[username] then return false, "Player does not exist." end

    return self.List[username], "Player found."
end

--! \brief Get the loaded character for a specific player.
--! \param username string The username of the player.
--! \return CHARACTER|boolean The loaded CHARACTER object or false if not found or no character loaded.
function FrameworkZ.Players:GetLoadedCharacterByID(username)
    if not username then return false end

    local player = self:GetPlayerByID(username)

    if player then
        return player:GetCharacter() or false
    end

    return false
end

--! \brief Gets saved character data by their ID.
--! \param username \string The username of the player.
--! \param characterID \integer The ID of the character.
--! \param callback \function (Optional) Callback function for async handling.
--! \return \table|\boolean The character data or false if the data failed to be retrieved.
function FrameworkZ.Players:GetCharacterDataByID(username, characterID, callback)
    if not username then 
        if callback then callback(false, "Missing username.") end
        return false, "Missing username." 
    end
    if not characterID then 
        if callback then callback(false, "Missing character ID.") end
        return false, "Missing character ID." 
    end

    local player = FrameworkZ.Players:GetPlayerByID(username) 
    if not player then 
        if callback then callback(false, "Player not found.") end
        return false, "Player not found." 
    end

    return player:GetCharacterDataByID(characterID, callback)
end

--! \brief Get the next available character ID for a player.
--! \param username string The username of the player.
--! \return number|boolean The next character ID or false if max characters reached or player not found.
--! \return string|nil Error message if applicable.
function FrameworkZ.Players:GetNextCharacterID(username)
    if not username then return false end

    local player = self:GetPlayerByID(username)

    if player then
        local nextID = #player.Characters + 1

        if nextID > player:GetMaxCharacters() then
            return false, "Max characters reached."
        end

        return nextID
    end

    return false, "Player not found."
end

--! \brief Create the character auto-save interval timer.
--! \details Creates the FZ_CharacterSaveInterval timer if it doesn't exist. Timer saves the active character at configured intervals.
function FrameworkZ.Players:CreateCharacterSaveInterval()
    if FrameworkZ.Timers:Exists("FZ_CharacterSaveInterval") then
        return -- Timer already exists
    end
    
    if not isClient() then return end
    
    local saveInterval = FrameworkZ.Config.Options.TicksUntilCharacterSave * FrameworkZ.Config.Options.PlayerTickInterval
    
    FrameworkZ.Timers:Create("FZ_CharacterSaveInterval", saveInterval, 0, function()
        local isoPlayer = getPlayer()
        if not isoPlayer then return end
        
        local username = isoPlayer:getUsername()
        local character = FrameworkZ.Characters:GetCharacterByID(username)
        
        if character then
            character:Save(function(success, message)
                if success then
                    if FrameworkZ.Config.Options.ShouldNotifyOnCharacterSave then
                        FrameworkZ.Notifications:AddToQueue("Character auto-saved.", FrameworkZ.Notifications.Types.Success)
                    end
                else
                    print("[FrameworkZ] Auto-save failed: " .. (message or "Unknown error"))
                    FrameworkZ.Notifications:AddToQueue("Auto-save failed: " .. (message or "Unknown error"), FrameworkZ.Notifications.Types.Danger)
                end
            end)
        end
    end)
end

--! \brief Reset the character auto-save interval timer.
--! \details Restarts the FZ_CharacterSaveInterval timer if it exists.
function FrameworkZ.Players:ResetCharacterSaveInterval()
    if FrameworkZ.Timers:Exists("FZ_CharacterSaveInterval") then
        FrameworkZ.Timers:Start("FZ_CharacterSaveInterval")
    end
end

function PLAYER:GenerateUID()
    local username = self:GetUsername()
    local characters = self:GetCharacters() if not characters then return false end

    function CreateUID()
        local uid = username .. "_" .. FrameworkZ.Utilities:GetRandomNumber(1, 999999, true)

        for k, v in pairs(characters) do
            if v.META_UID == uid then
                return CreateUID()
            end
        end

        return uid
    end

    return CreateUID()
end

function FrameworkZ.Players.OnCreateCharacter(data, username, characterData)
    if not username then return false, "Username is nil." end
    if not characterData then return false, "Character data is nil." end

    -- Get the player object for UID generation
    local player = FrameworkZ.Players:GetPlayerByID(username)
    if not player then return false, "Player not found." end

    -- Canonicalize creation payload server-side so starter items and defaults are applied.
    local processedCharacterData, processMessage = FrameworkZ.Characters:ProcessCreationData(characterData, player)
    if not processedCharacterData then
        return false, "Failed to process character creation data: " .. tostring(processMessage or "Unknown error")
    end

    -- Preserve any additional fields from the creator payload while keeping canonical defaults.
    FrameworkZ.Utilities:MergeTables(processedCharacterData, characterData)

    -- Generate UID if not present
    if not processedCharacterData[FZ_ENUM_CHARACTER_META_UID] then
        processedCharacterData[FZ_ENUM_CHARACTER_META_UID] = player:GenerateUID()
    end

    local characterID = FrameworkZ.Players:CreateCharacter(username, processedCharacterData)
    if not characterID then
        return false, "Failed to create character."
    end
    
    -- Return ID, UID and canonical payload for exact client/server cache parity.
    return characterID, processedCharacterData[FZ_ENUM_CHARACTER_META_UID], processedCharacterData
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.OnCreateCharacter", FrameworkZ.Players.OnCreateCharacter)

function FrameworkZ.Players:CreateCharacter(username, characterData, characterID)
    if not username then return false, "Username is nil" end
    if not characterData then return false, "Character data is nil." end

    local player = self:GetPlayerByID(username)

    if player and player.Characters then
        characterData[FZ_ENUM_CHARACTER_META_ID] = characterID and characterID or #player.Characters + 1
        characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = true

        if not characterID then
            table.insert(player.Characters, characterData)
        else
            player.Characters[characterID] = characterData
        end

        -- Only generate a new UID if one doesn't already exist (first time character creation)
        if not characterData[FZ_ENUM_CHARACTER_META_UID] then
            characterData[FZ_ENUM_CHARACTER_META_UID] = player:GenerateUID()
        end

        FrameworkZ.Foundation:SetData(player:GetIsoPlayer(), "Characters", {username, characterData[FZ_ENUM_CHARACTER_META_ID]}, characterData)

        return characterData[FZ_ENUM_CHARACTER_META_ID]
    end

    return false, "Player not found."
end

--! \brief Saves the player and their currently loaded character.
--! \param username \string The username of the player.
--! \param continueOnFailure \boolean (Optional) Whether or not to continue saving either the player or character if either should fail. Default = false. True not recommended.
--! \return \boolean Whether or not the player was successfully saved.
--! \return \string The failure message if the player or character failed to save.
function FrameworkZ.Players:Save(username, continueOnFailure, callback)
    if continueOnFailure == nil then continueOnFailure = false end

    local player = FrameworkZ.Players:GetPlayerByID(username)

    if not player then return false end

    local saved = false
    local failureMessage = ""
    local character = player.LoadedCharacter
    local characterSaved = false
    
    -- Save player data with callback if provided
    local playerSaved, message = player:Save(callback)
    saved = playerSaved

    if not saved and not continueOnFailure then
        return false, "Failed to save player data: " .. (message or "Unknown error.")
    elseif not saved and continueOnFailure then
        failureMessage = "Failed to save player data."
    end

    if character then
        local hasCharacterSaved, message2 = character:Save()
        characterSaved = hasCharacterSaved
        saved = characterSaved

        if not saved and not continueOnFailure then
            return false, "Failed to save character data: " .. (message2 or "Unknown error.")
        elseif not saved and continueOnFailure then
            failureMessage = (failureMessage == "Failed to save player data." and "Failed to save both player data and character data." or "Player data saved, but failed to save character data. " .. message .. " " .. message2)
        end
    else
        characterSaved = true -- No character loaded, set true to prevent returning false.
    end

    if isClient() then
        player:GetIsoPlayer():transmitModData()
    end

    if playerSaved and characterSaved then
        saved = true
    else
        saved = false
    end

    return saved, failureMessage
end

function FrameworkZ.Players:Destroy(username, callback)
    if not username then
        if callback then callback(false, "Missing username") end
        return false, "Missing username"
    end

    if self._destroyInProgress[username] then
        if callback then callback(true, "Destroy already in progress") end
        return true, "Destroy already in progress"
    end

    self._destroyInProgress[username] = true

    local properlyDestroyed = false
    local message = "Failed to destroy player."
    local player = self:GetPlayerByID(username)

    local finish = function(success, resultMessage)
        self._destroyInProgress[username] = nil
        if callback then callback(success, resultMessage) end
    end

    if player then
        local ok, destroyMessage = player:Destroy(function(success, saveMessage)
            finish(success, saveMessage or destroyMessage)
        end)
        properlyDestroyed = ok
        message = destroyMessage or message
    else
        finish(false, "Player not found")
    end

    return properlyDestroyed, message
end

function FrameworkZ.Players:SaveCharacter(username, character)
    local player = FrameworkZ.Players:GetPlayerByID(username)

    if not player or not character then return false end

    local isoPlayer = player:GetIsoPlayer()

    -- Use centralized inventory system for character saving
    local characterObj = FrameworkZ.Characters:GetCharacterByID(username)
    if not characterObj then
        print("[FrameworkZ] Warning: Could not find character object for inventory saving")
        return false
    end

    local inventoryData, inventoryMessage = FrameworkZ.Inventories:Save(characterObj)
    
    if inventoryData then
        character[FZ_ENUM_CHARACTER_INVENTORY] = inventoryData
        print("[FrameworkZ] Player character inventory saved: " .. inventoryMessage)
    else
        print("[FrameworkZ] Warning: Failed to save player character inventory: " .. (inventoryMessage or "Unknown error"))
        return false
    end

    -- Save character position/direction angle in both legacy and canonical keys so older
    -- saves continue to load while the modern enum-key path stays consistent.
    local x = isoPlayer:getX()
    local y = isoPlayer:getY()
    local z = isoPlayer:getZ()
    local angle = isoPlayer:getDirectionAngle()

    character.POSITION_X = x
    character.POSITION_Y = y
    character.POSITION_Z = z
    character.DIRECTION_ANGLE = angle
    character[FZ_ENUM_CHARACTER_META_POSITION_X] = x
    character[FZ_ENUM_CHARACTER_META_POSITION_Y] = y
    character[FZ_ENUM_CHARACTER_META_POSITION_Z] = z
    character[FZ_ENUM_CHARACTER_META_POSITION_ANGLE] = angle

    local getStats = isoPlayer:getStats()
    character.STAT_HUNGER = getStats:getHunger()
    character.STAT_THIRST = getStats:getThirst()
    character.STAT_FATIGUE = getStats:getFatigue()
    character.STAT_STRESS = getStats:getStress()
    character.STAT_PAIN = getStats:getPain()
    character.STAT_PANIC = getStats:getPanic()
    character.STAT_BOREDOM = getStats:getBoredom()
    --character.STAT_UNHAPPINESS = getStats:getUnhappyness()
    character.STAT_DRUNKENNESS = getStats:getDrunkenness()
    character.STAT_ENDURANCE = getStats:getEndurance()
    --character.STAT_TIREDNESS = getStats:getTiredness()

    --[[
    modData.status.health = character:getBodyDamage():getOverallBodyHealth()
    modData.status.injuries = character:getBodyDamage():getInjurySeverity()
    modData.status.hyperthermia = character:getBodyDamage():getTemperature()
    modData.status.hypothermia = character:getBodyDamage():getColdStrength()
    modData.status.wetness = character:getBodyDamage():getWetness()
    modData.status.hasCold = character:getBodyDamage():HasACold()
    modData.status.sick = character:getBodyDamage():getSicknessLevel()
    --]]

    if isClient() then
        isoPlayer:transmitModData()
    end

    return true
end

function FrameworkZ.Players:SaveCharacterByID(username, characterID)

end

--! \brief Snapshot-save the currently loaded character before switching to another one.
--! \details Uses a direct SetData write to avoid async callback races in load-switch paths.
--! \return \boolean Success flag.
--! \return \string Status message.
function FrameworkZ.Players:SaveLoadedCharacterSnapshot(player, loadedCharacter)
    if not player then return false, "Missing player." end
    if not loadedCharacter then return true, "No loaded character to snapshot-save." end

    local isoPlayer = player:GetIsoPlayer()
    if not isoPlayer then return false, "Missing IsoPlayer." end

    local characterID = loadedCharacter:GetID()
    local saveToken = FrameworkZ.Players:BeginCharacterSave(player:GetUsername(), characterID)

    local synced, syncMessage = loadedCharacter:Sync()
    if not synced then
        return false, syncMessage
    end
    local saveableData = loadedCharacter:GetSaveableData()
    if not saveableData then
        return false, "Failed to gather saveable character data."
    end

    local characterID = loadedCharacter:GetID() or saveableData[FZ_ENUM_CHARACTER_META_ID]
    if not characterID then
        return false, "Failed to resolve loaded character ID for snapshot-save."
    end

    if not FrameworkZ.Players:CanWriteCharacterSave(player:GetUsername(), saveToken, characterID) then
        return false, "Skipped stale character snapshot-save."
    end

    FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {player:GetUsername(), characterID}, saveableData)
    return true, "Loaded character snapshot-saved before switch."
end

function PLAYER:SetModel(characterData)
    if not characterData then return false end
    if not self:GetIsoPlayer() then return false end
    local isoPlayer = self:GetIsoPlayer()

    -- Debug logging
    print("[Players.SetModel] Setting model for character: " .. (characterData[FZ_ENUM_CHARACTER_INFO_NAME] or "Unknown"))
    print("[Players.SetModel] Hair Color: " .. tostring(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]))
    print("[Players.SetModel] Beard Color: " .. tostring(characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]))

    local gender = characterData[FZ_ENUM_CHARACTER_INFO_GENDER]
    local isFemale = gender == "Female" or gender ~= "Male"
    isoPlayer:setFemale(isFemale)
    isoPlayer:getDescriptor():setFemale(isFemale)

    -- Get color data with fallbacks from template
    local template = FrameworkZ.Characters.DefaultCharacterData
    local hairColor = characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or template[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
    local beardColor = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] or template[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]
    
    print("[Players.SetModel] Using Hair Color: " .. tostring(hairColor) .. " (type: " .. type(hairColor) .. ")")
    print("[Players.SetModel] Using Beard Color: " .. tostring(beardColor) .. " (type: " .. type(beardColor) .. ")")
    
    if hairColor and type(hairColor) == "table" then
        print("[Players.SetModel] Hair Color RGB: r=" .. tostring(hairColor.r) .. " g=" .. tostring(hairColor.g) .. " b=" .. tostring(hairColor.b))
    end
    
    if beardColor and type(beardColor) == "table" then
        print("[Players.SetModel] Beard Color RGB: r=" .. tostring(beardColor.r) .. " g=" .. tostring(beardColor.g) .. " b=" .. tostring(beardColor.b))
    end
    
    local visual = isoPlayer:getHumanVisual()
    visual:clear()
    
    -- Apply beard color and style with null checks
    if beardColor and beardColor.r and beardColor.g and beardColor.b then
        visual:setBeardColor(ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1))
        visual:setNaturalBeardColor(ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1))
        print("[Players.SetModel] Applied beard color successfully")
    else
        print("[Players.SetModel] Warning: Invalid beard color data, skipping beard color")
    end
    
    if characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] then
        local beardStyle = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
        if beardStyle == "" or beardStyle == "None" then
            visual:setBeardModel("")
        else
            visual:setBeardModel(beardStyle)
        end
    end
    
    -- Apply hair color and style with null checks
    if hairColor and hairColor.r and hairColor.g and hairColor.b then
        visual:setHairColor(ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1))
        visual:setNaturalHairColor(ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1))
        print("[Players.SetModel] Applied hair color successfully")
    else
        print("[Players.SetModel] Warning: Invalid hair color data, skipping hair color")
    end
    
    if characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] then
        visual:setHairModel(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE])
    end
    
    if characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] then
        visual:setSkinTextureIndex(characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR])
    end

    isoPlayer:resetModel()
end

function PLAYER:LoadCharacter(characterID, callback)
    if not characterID then return false end

    FrameworkZ.Players:LoadCharacterByID(self:GetUsername(), characterID, callback)
end

if isServer() then
    function FrameworkZ.Players.ResetIsoPlayer(username)
        FrameworkZ.Players:ResetIsoPlayer()
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.ResetIsoPlayer", FrameworkZ.Players.ResetIsoPlayer)
end

function FrameworkZ.Players:ResetIsoPlayer(username)
    local player = self:GetPlayerByID(username) if not player then return false, "Player not found." end

    player:ResetIsoPlayer()
end

function PLAYER:ResetIsoPlayer()
    local isoPlayer = self:GetIsoPlayer()

    isoPlayer:clearWornItems()
    isoPlayer:getInventory():clear()
end

function FrameworkZ.Players:LoadCharacterByID(username, characterID, callback)
    local player = self:GetPlayerByID(username) if not player then return false, "Player not found." end
    local isoPlayer = player:GetIsoPlayer() if not isoPlayer then return false, "IsoPlayer not found." end
    local loadedCharacter = player:GetCharacter()

    FrameworkZ.Awaits:Run(function()
        if loadedCharacter then
            local synced, syncMessage = loadedCharacter:Sync()
            if not synced then
                FrameworkZ.Notifications:AddToQueue("Failed to save currently loaded character before switch: " .. tostring(syncMessage), FrameworkZ.Notifications.Types.Danger)
                return
            end

            local loadedCharacterData = loadedCharacter:GetSaveableData()
            local loadedCharacterID = player:GetLoadedCharacterID() or loadedCharacter:GetID() or loadedCharacterData[FZ_ENUM_CHARACTER_META_ID]
            if not loadedCharacterID then
                FrameworkZ.Notifications:AddToQueue("Failed to save currently loaded character before switch: Missing character ID.", FrameworkZ.Notifications.Types.Danger)
                return
            end

            local setResult, setMessage = FrameworkZ.Awaits:SetData(isoPlayer, "Characters", {player:GetUsername(), loadedCharacterID}, loadedCharacterData)

            if setResult == false then
                FrameworkZ.Notifications:AddToQueue("Failed to save currently loaded character before switch: " .. tostring(setMessage or "Unknown error"), FrameworkZ.Notifications.Types.Danger)
                return
            end
        end

        FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterLoad", player)

        isoPlayer:clearWornItems()
        isoPlayer:getInventory():clear()

        local success, message, itemManifest = FrameworkZ.Awaits:SendFire(isoPlayer, "FrameworkZ.Players.LoadCharacter", username, characterID)

        if not success then
            FrameworkZ.Notifications:AddToQueue("Failed to load character: " .. (message or "Unknown error"), FrameworkZ.Notifications.Types.Danger)
            return
        end

        local _, _, _, characterData = FrameworkZ.Awaits:GetData(isoPlayer, "Characters", {username, characterID})

        if type(characterData) ~= "table" then
            FrameworkZ.Notifications:AddToQueue("Failed to initialize character: No character data payload.", FrameworkZ.Notifications.Types.Danger)
            return
        end

        local character, message2 = FrameworkZ.Characters:Initialize(isoPlayer, characterID, characterData, itemManifest)

        if not character then
            FrameworkZ.Notifications:AddToQueue("Failed to initialize character: " .. (message2 or "Unknown error"), FrameworkZ.Notifications.Types.Danger)
            return
        end

        if characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] == true then
            local synced, syncMessage = character:Sync()
            if not synced then
                FrameworkZ.Notifications:AddToQueue("Failed to save first-load inventory: " .. tostring(syncMessage), FrameworkZ.Notifications.Types.Danger)
                return
            end

            character[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = false
            local initializedCharacterData = character:GetSaveableData()
            initializedCharacterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = false

            local saved, saveMessage = FrameworkZ.Awaits:SetData(isoPlayer, "Characters", {username, characterID}, initializedCharacterData)
            if saved == false then
                FrameworkZ.Notifications:AddToQueue("Failed to persist first-load inventory: " .. tostring(saveMessage or "Unknown error"), FrameworkZ.Notifications.Types.Danger)
                return
            end

            player:GetCharacters()[characterID] = initializedCharacterData
            characterData = initializedCharacterData
        end

        if callback then
            callback(character, message2)
        end

        FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterLoaded", character:GetPlayer())

        player:SetPreviousCharacter(characterID)
    end)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterLoad")
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterLoaded")

if isServer() then
    function FrameworkZ.Players.LoadCharacter(data, username, characterID)
        if not username then return false, "Missing username." end
        if not characterID then return false, "Missing character ID." end

        local characterData = FrameworkZ.Foundation:GetData(data.isoPlayer, "Characters", {username, characterID})
        if not characterData then return false, "Character data not found." end
        local character, message, itemManifest = FrameworkZ.Characters:Initialize(data.isoPlayer, characterID, characterData)
        if not character then return false, message end

        --[[
        if character and character.DispatchFirstLoadHooks then
            character:DispatchFirstLoadHooks()
        end
        --]]

        return true, message, itemManifest
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.LoadCharacter", FrameworkZ.Players.LoadCharacter)
end

--[[
function FrameworkZ.Players:OnLoadCharacter(username, characterID, callback, options)
    local player, message = FrameworkZ.Players:GetPlayerByID(username) if not player then return false, message end
    if type(callback) ~= "function" then
        callback = nil
    end
    local authoritative = options and options.authoritative or false

    if authoritative and isServer() then
        local character, message3 = FrameworkZ.Characters:Initialize(player:GetIsoPlayer(), characterID, callback)
        if not character then
            if callback then callback(false, message3) end
            return false, message3
        end

        return character, "Character authoritatively loaded on server."
    end

    -- Stop the auto-save timer to prevent race conditions during character switching
    if isClient() and FrameworkZ.Timers:Exists("FZ_CharacterSaveInterval") then
        FrameworkZ.Timers:Remove("FZ_CharacterSaveInterval")
    end

    local function initializeCharacterAfterSave()
        local characterInitializedCallback = function(character, message2)
            if callback then
                callback(character, message2)
            end
        end

        local character, message3 = FrameworkZ.Characters:Initialize(player:GetIsoPlayer(), characterID, characterInitializedCallback)
        if not character then
            if callback then callback(false, message3) end
            return false, message3
        end

        -- Create and start the character save interval timer for the newly loaded character
        if isClient() then
            FrameworkZ.Players:CreateCharacterSaveInterval()
            FrameworkZ.Players:ResetCharacterSaveInterval()
        end

        -- TODO run first load hook FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterFirstLoad", character)
        return character, "Character preemptively loaded successfully."
    end

    -- Save current character before switching and wait for confirmation to avoid stale reload data.
    local currentCharacter = player:GetCharacter()
    if currentCharacter then
        local didContinueLoad = false
        local continueLoad = function(reason)
            if didContinueLoad then return end
            didContinueLoad = true

            if reason then
                print("[FrameworkZ] Continuing character load after save phase via: " .. tostring(reason))
            end

            initializeCharacterAfterSave()
        end

        local saveStarted, saveMessage = currentCharacter:Save(function(success, callbackMessage)
            if not success then
                print("[FrameworkZ] Warning: Character save failed before load switch: " .. tostring(callbackMessage or "Unknown error"))
            end

            continueLoad("save_callback")
        end)

        if not saveStarted then
            print("[FrameworkZ] Warning: Character save did not start before load switch: " .. tostring(saveMessage or "Unknown error"))
            continueLoad("save_start_failed")
            return true, "Character save failed to start; continuing load."
        end

        local timeoutSeconds = (FrameworkZ.Config and FrameworkZ.Config.Options and FrameworkZ.Config.Options.CharacterLoadDelay and FrameworkZ.Config.Options.CharacterLoadDelay > 0)
            and (FrameworkZ.Config.Options.CharacterLoadDelay + 2)
            or 5

        FrameworkZ.Timers:Simple(timeoutSeconds, function()
            if didContinueLoad then return end

            print("[FrameworkZ] Warning: Character save callback timeout before load switch after " .. tostring(timeoutSeconds) .. "s.")
            continueLoad("save_timeout")
        end)

        return true, "Character save requested before load switch."
    end

    return initializeCharacterAfterSave()
end
--]]

function FrameworkZ.Players:OnPreLoadCharacter(isoPlayer, player, character, characterData)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPreLoad", isoPlayer, player, character, characterData)

    -- Inventory and worn-item state are rebuilt by the restore pipeline itself.
    -- Clearing them here can discard the target character's saved snapshot before it is restored.
    player:SetModel(characterData)

    -- Apply damage/wounds/moodles
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterPreLoad")

--[[
function FrameworkZ.Players:OnPostLoadCharacter(isoPlayer, player, character, characterData)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostLoad", isoPlayer, player, character, characterData)

    if isClient() then
        FrameworkZ.Notifications:AddToQueue("Please wait a few seconds for the map to load.", FrameworkZ.Notifications.Types.Warning)
    end

    FrameworkZ.Timers:Simple(2, function()
        if characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] == true then
            local options = FrameworkZ.Config.Options

            isoPlayer:setX(options.SpawnX)
            isoPlayer:setY(options.SpawnY)
            isoPlayer:setZ(options.SpawnZ)
            isoPlayer:setLx(options.SpawnX)
            isoPlayer:setLy(options.SpawnY)
            isoPlayer:setLz(options.SpawnZ)

            characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = false
        else
            FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostliminaryLoad", character)

            isoPlayer:setX(characterData.POSITION_X)
            isoPlayer:setY(characterData.POSITION_Y)
            isoPlayer:setZ(characterData.POSITION_Z)
            isoPlayer:setLx(characterData.POSITION_X)
            isoPlayer:setLy(characterData.POSITION_Y)
            isoPlayer:setLz(characterData.POSITION_Z)
            isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
        end

        isoPlayer:setInvisible(false)
        isoPlayer:setGhostMode(false)
        isoPlayer:setNoClip(false)

        if VoiceManager:playerGetMute(player:GetUsername()) then
            VoiceManager:playerSetMute(player:GetUsername())
        end

        if isClient() and FrameworkZ.UI.MainMenu.instance then
            FrameworkZ.UI.MainMenu.instance:onClose()
        end

        FrameworkZ.Timers:Simple(3, function()
            isoPlayer:setGodMod(false)
            isoPlayer:setInvincible(false)

            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Spawn protection has now been removed.", FrameworkZ.Notifications.Types.Warning)
            end

            FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterFinishedLoading", player, character, characterData)
        end)
    end)
end
--]]

--[[
    Steps:
        1. Load equipment/items
        2. Teleport
        3. Ungod
        4. Apply damage/wounds/moodles (if applicable)
        5. Make visible
        6. Unmute
        7. Save
        8. Post load
        9. Return true
--]]
--[[
function FrameworkZ.Players:LoadCharacter(username, characterData, survivorDescriptor, loadCharacterStartTime)
    local player = FrameworkZ.Players:GetPlayerByID(username)
    if not player or not characterData then return false end
    local isoPlayer = player.isoPlayer

    FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Characters.PostLoad", function(data, _success, _character)
        local character = FrameworkZ.Characters.PostLoad({isoPlayer = isoPlayer}, characterData)

        if not character then
            FrameworkZ.Notifications:AddToQueue("Failed to load character: Not found.", FrameworkZ.Notifications.Types.Danger, nil, FrameworkZ.UI.MainMenu.instance)
            return
        end

        character:OnPostLoad(characterData.META_FIRST_LOAD)

        isoPlayer:clearWornItems()
        isoPlayer:getInventory():clear()

        for k, v in pairs(characterData) do
            if string.match(k, "EQUIPMENT_SLOT_") then
                if v and v.id then
                    local item = isoPlayer:getInventory():AddItem(v.id)
                    isoPlayer:setWornItem(item:getBodyLocation(), item)
                end
            end
        end

        local isFemale = survivorDescriptor:isFemale()
        isoPlayer:setFemale(isFemale)
        isoPlayer:getDescriptor():setFemale(isFemale)
        isoPlayer:getHumanVisual():clear()
        isoPlayer:getHumanVisual():copyFrom(survivorDescriptor:getHumanVisual())
        isoPlayer:resetModel()

        isoPlayer:setGodMod(false)
        isoPlayer:setInvincible(false)

        -- Apply damage/wounds/moodles

        isoPlayer:setInvisible(false)
        isoPlayer:setGhostMode(false)
        isoPlayer:setNoClip(false)

        if VoiceManager:playerGetMute(username) then
            VoiceManager:playerSetMute(username)
        end

        FrameworkZ.Foundation.LoadingNotifications = {} -- TODO store loading notifications and parent them, then remove from parent after main menu is finally closed.

        FrameworkZ.Notifications:AddToQueue("Please wait a few seconds for the map to load.", FrameworkZ.Notifications.Types.Warning)

        FrameworkZ.Timers:Simple(1, function()
            if characterData.META_FIRST_LOAD == true then
                isoPlayer:setX(FrameworkZ.Config.Options.SpawnX)
                isoPlayer:setY(FrameworkZ.Config.Options.SpawnY)
                isoPlayer:setZ(FrameworkZ.Config.Options.SpawnZ)
                isoPlayer:setLx(FrameworkZ.Config.Options.SpawnX)
                isoPlayer:setLy(FrameworkZ.Config.Options.SpawnY)
                isoPlayer:setLz(FrameworkZ.Config.Options.SpawnZ)
            else
                isoPlayer:setX(characterData.POSITION_X)
                isoPlayer:setY(characterData.POSITION_Y)
                isoPlayer:setZ(characterData.POSITION_Z)
                isoPlayer:setLx(characterData.POSITION_X)
                isoPlayer:setLy(characterData.POSITION_Y)
                isoPlayer:setLz(characterData.POSITION_Z)
                isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
            end

            if not self:SaveCharacter(username, characterData) then
                FrameworkZ.Notifications:AddToQueue("Failed to load character: Not saved.", FrameworkZ.Notifications.Types.Danger, nil, FrameworkZ.UI.MainMenu.instance)

                FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Foundation.TeleportToLimbo", function(success)
                    if success then
                        FrameworkZ.Foundation.TeleportToLimbo({isoPlayer = isoPlayer})
                    end
                end)
            else
                FrameworkZ.UI.MainMenu.instance:onClose()
                FrameworkZ.Notifications:AddToQueue("Loaded character in " .. tostring(string.format(" %.2f", (getTimestampMs() - loadCharacterStartTime) / 1000)) .. " seconds.", FrameworkZ.Notifications.Types.Success)

                if characterData.META_FIRST_LOAD then
                    characterData.META_FIRST_LOAD = false
                end
            end
        end)
    end, characterData)
end
--]]

--[[
function FrameworkZ.Players.OnLoadCharacter(data, characterID)
    return true
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.OnLoadCharacter", FrameworkZ.Players.OnLoadCharacter)
--]]

function FrameworkZ.Players:DeleteCharacter(username, character)

end

function FrameworkZ.Players:DeleteCharacterByID(username, characterID)

end

function FrameworkZ.Players:BeginDisconnectSave(username)
    if not username then return false end
    if self._disconnectInProgress[username] then
        return false
    end

    self._disconnectInProgress[username] = true
    return true
end

function FrameworkZ.Players:EndDisconnectSave(username)
    if not username then return end
    self._disconnectInProgress[username] = nil
end

--[[
function FrameworkZ.Players:OnDisconnect()
    local usernames = {}

    local isoPlayer = getPlayer()
    if isoPlayer and isoPlayer.getUsername then
        table.insert(usernames, isoPlayer:getUsername())
    end

    -- Fallback: drain any tracked players to avoid missing a save when IsoPlayer is nil
    for username, _ in pairs(self.List) do
        table.insert(usernames, username)
    end

    local processed = {}

    for _, username in ipairs(usernames) do
        if username and not processed[username] then
            processed[username] = true

            if self:BeginDisconnectSave(username) then
                self:Destroy(username, function(success, message)
                    self:EndDisconnectSave(username)
                    if success then
                        print("[FrameworkZ] Player destroyed on disconnect: " .. username)
                    else
                        print("[FrameworkZ] Warning during disconnect destroy: " .. (message or "Unknown error"))
                    end
                end)
            else
                print("[FrameworkZ] Skipping duplicate disconnect save for: " .. tostring(username))
            end
        end
    end
end
--]]

function FrameworkZ.Players:OnInitGlobalModData(isNewGame)
    FrameworkZ.Foundation:RegisterNamespace("Players")
end

function FrameworkZ.Players:OnStorageSet(isoPlayer, command, namespace, keys, value)
    if namespace == "Players" then
        if command == "Initialize" then
            local username = keys
            local data = value
            local player = self:GetPlayerByID(username) if not player then return end

            if data then
                for k, v in pairs(data) do
                    if data[k] and player[k] then
                        player[k] = data[k] -- Restore saved data on default fields
                    elseif data[k] and not player[k] then
                        player[k] = data[k] -- Restore saved custom data
                    end
                end

                for k, v in pairs(player) do
                    if player[k] and not data[k] then
                        data[k] = player[k] -- Add new data fields from default fields (probably from an update)
                    end
                end

                --FrameworkZ.Foundation:GetData(isoPlayer, "Initialize", "Characters", username)
            end
        end
    end
end

function FrameworkZ.Players:OnFillWorldObjectContextMenu(playerNumber, context, worldObjects, test)
    if true then return end -- Disable our custom context menu for now.

    worldObjects = FrameworkZ.Utilities:RemoveContextDuplicates(worldObjects)

    --context:clear()

    local isoPlayer = getSpecificPlayer(playerNumber)
    local inventory = isoPlayer:getInventory()

    local menuManager = MenuManager.new(context)
    local interactSubMenu = menuManager:addSubMenu("Interact") -- FZ specific interactions
    local inspectSubMenu = menuManager:addSubMenu("Inspect") -- FZ flavour text
    local manageSubMenu = menuManager:addSubMenu("Manage") -- Pickup, dissassemble, grab
    local adminSubMenu = menuManager:addSubMenu("(ADMIN)") -- Admin/debug stuff

    for _, v in pairs(worldObjects) do
        if instanceof(v, "IsoDoor") or (instanceof(v, "IsoThumpable") and v:isDoor()) then
            local lockUnlockOption
            local closeOpenOption
            local keyID

            if instanceof(v, "IsoDoor") and v:checkKeyId() ~= -1 then
                keyID = v:checkKeyId()
            else
                keyID = nil
            end

            if instanceof(v, "IsoThumpable") and  v:getKeyId() ~= -1 then
                keyID = v:getKeyId();
            end

            if keyID and inventory:haveThisKeyId(keyID) or FrameworkZ.Utilities:IsTrulyInterior(isoPlayer:getSquare()) then
                if not v:isLockedByKey() then
                    lockUnlockOption = menuManager:addOption(Options.new("Lock Door", self, function(target, parameters)
                        ISWorldObjectContextMenu.onLockDoor(worldObjects, playerNumber, v)
                    end), interactSubMenu)
                else
                    lockUnlockOption = menuManager:addOption(Options.new("Unlock Door", self, function(target, parameters)
                        ISWorldObjectContextMenu.onUnLockDoor(worldObjects, playerNumber, v)
                    end), interactSubMenu)
                end
            end

            if not v:isBarricaded() then
                if v:IsOpen() then
                    closeOpenOption = menuManager:addOption(Options.new("Close Door", self, function(target, parameters)
                        ISWorldObjectContextMenu.onOpenCloseDoor(worldObjects, v, playerNumber)
                    end), interactSubMenu)
                else
                    closeOpenOption = menuManager:addOption(Options.new("Open Door", self, function(target, parameters)
                        ISWorldObjectContextMenu.onOpenCloseDoor(worldObjects, v, playerNumber)
                    end), interactSubMenu)
                end
            end

            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("The door is " .. (v:IsOpen() and "open" or "closed") .. " and " .. (v:isLockedByKey() and "locked" or "unlocked") .. ".")
            tooltip:setTexture(v:getTextureName())
            tooltip.description = "Open/Close Door:\n" .. getText("Tooltip_OpenClose", getKeyName(getCore():getKey("Interact")))
            closeOpenOption.toolTip = tooltip

            if lockUnlockOption then
                lockUnlockOption.toolTip = tooltip
            end
        elseif instanceof(v, "IsoWindow") then
            local climbThroughOption
            local lockUnlockOption
            local closeOpenOption
            local keyID

            if v:getKeyId() ~= -1 then
                keyID = v:checkKeyId()
            else
                keyID = nil
            end

            if v:canClimbThrough(isoPlayer) then
                climbThroughOption = menuManager:addOption(Options.new("Climb Through Window", self, function(target, parameters)
                    ISWorldObjectContextMenu.onClimbThroughWindow(worldObjects, v, playerNumber)
                end), interactSubMenu)
            end

            if keyID and inventory:haveThisKeyId(keyID) or FrameworkZ.Utilities:IsTrulyInterior(isoPlayer:getSquare()) then
                if not v:isLocked() then
                    local lockWindow = function()
                        if luautils.walkAdjWindowOrDoor(isoPlayer, v:getSquare(), v) then
                            ISTimedActionQueue.add(ISLockUnlockWindow:new(isoPlayer, v, true));
                        end
                    end

                    lockUnlockOption = menuManager:addOption(Options.new("Lock Window", self, function(target, parameters)
                        lockWindow()
                    end), interactSubMenu)
                else
                    local unlockWindow = function()
                        if luautils.walkAdjWindowOrDoor(isoPlayer, v:getSquare(), v) then
                            ISTimedActionQueue.add(ISLockUnlockWindow:new(isoPlayer, v, false));
                        end
                    end

                    lockUnlockOption = menuManager:addOption(Options.new("Unlock Window", self, function(target, parameters)
                        unlockWindow()
                    end), interactSubMenu)
                end
            end

            if not v:isBarricaded() then
                if v:IsOpen() then
                    closeOpenOption = menuManager:addOption(Options.new("Close Window", self, function(target, parameters)
                        ISWorldObjectContextMenu.onOpenCloseWindow(worldObjects, v, playerNumber)
                    end), interactSubMenu)
                else
                    closeOpenOption = menuManager:addOption(Options.new("Open Window", self, function(target, parameters)
                        ISWorldObjectContextMenu.onOpenCloseWindow(worldObjects, v, playerNumber)
                    end), interactSubMenu)
                end
            end

            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("The window" .. (v:isSmashed() and " (smashed) " or " ") .. "is " .. (v:IsOpen() and "open" or "closed") .. " and " .. (v:isLocked() and "locked" or "unlocked") .. ".")
            tooltip:setTexture(v:getTextureName())
            tooltip.description = "Open/Close Window:\n" .. getText("Tooltip_TapKey", getKeyName(getCore():getKey("Interact"))) .. "\n" ..
                "Climb Through Window:\n" .. getText("Tooltip_Climb", getKeyName(getCore():getKey("Interact")))
            closeOpenOption.toolTip = tooltip

            if climbThroughOption then
                climbThroughOption.toolTip = tooltip
            end

            if lockUnlockOption then
                lockUnlockOption.toolTip = tooltip
            end
        end
    end

    menuManager:buildMenu()

    if interactSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Interactions Available"), interactSubMenu)
    end

    if inspectSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Inspections Available"), inspectSubMenu)
    end

    if manageSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Management Options Available"), manageSubMenu)
    end

    if adminSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Admin Actions Available"), adminSubMenu)
    end
end

-- Server-side subscription handlers for save operations
FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.Save", function(data, username, saveablePlayerData, saveToken)
    if isServer() then
        if not FrameworkZ.Players:CanAcceptRemotePlayerSave(username, data.isoPlayer, saveToken) then
            print("[FrameworkZ] Skipping stale player save for: " .. tostring(username) .. " (token=" .. tostring(saveToken) .. ")")
            return true, "Skipped stale player save"
        end

        -- Save player data to storage
        FrameworkZ.Foundation:SetLocalData("Players", username, saveablePlayerData)
        print("[FrameworkZ] Player data saved for: " .. username)
        return true
    end
end)

FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.Destroy", function(data, username, clientPlayerData, clientCharacterData, clientCharacterID, clientPlayerSaveToken, clientCharacterSaveToken)
    if isServer() then
        -- Save both player and character data before destroying
        local player = FrameworkZ.Players:GetPlayerByID(username)

        -- IMPORTANT: Only use player:GetCharacter() (the character THIS player's connection
        -- actually has loaded/restored this session). Do NOT use
        -- FrameworkZ.Characters:GetCharacterByID(username): that global cache can still
        -- reference a character that was created but never actually loaded into the game, or a
        -- stale entry left over from an earlier connection this server session. Calling :Sync()
        -- on such a character reads whatever is CURRENTLY worn on the live IsoPlayer (e.g. the
        -- limbo Hospital Gown/Slippers from FrameworkZ.Foundation:InitializeClient) and
        -- permanently bakes that into the character's saved Equipment data, corrupting it even
        -- though the character was never really dressed/restored. See frameworkz-migration-notes.md.
        local character = player and player:GetCharacter()

        -- IsoPlayer can be nil during late disconnect teardown.
        -- Foundation:SetData on server does not require a live player reference.
        local isoPlayer = player and player:GetIsoPlayer() or nil
        local finalPlayerData = player and player:GetSaveableData() or clientPlayerData
        local finalCharacterData = nil
        local requestedCharacterID = clientCharacterID
        local clientX, clientY, clientZ, clientAngle = nil, nil, nil, nil
        local fallbackX, fallbackY, fallbackZ, fallbackAngle = nil, nil, nil, nil

        if type(clientCharacterData) == "table" then
            clientX = clientCharacterData[FZ_ENUM_CHARACTER_META_POSITION_X]
            clientY = clientCharacterData[FZ_ENUM_CHARACTER_META_POSITION_Y]
            clientZ = clientCharacterData[FZ_ENUM_CHARACTER_META_POSITION_Z]
            clientAngle = clientCharacterData[FZ_ENUM_CHARACTER_META_POSITION_ANGLE]
        end

        if isoPlayer then
            fallbackX = isoPlayer:getX()
            fallbackY = isoPlayer:getY()
            fallbackZ = isoPlayer:getZ()
            fallbackAngle = isoPlayer:getDirectionAngle()
        end

        if not FrameworkZ.Players:CanAcceptRemotePlayerSave(username, data.isoPlayer, clientPlayerSaveToken) then
            print("[FrameworkZ] Skipping stale disconnect player save for: " .. tostring(username) .. " (token=" .. tostring(clientPlayerSaveToken) .. ")")
            return true, "Skipped stale disconnect player save"
        end

        if character then
            -- Always prefer the live server character state when it is available.
            if requestedCharacterID ~= nil and character.SetID then
                character:SetID(requestedCharacterID)
            end
            local synced, syncMessage = character:Sync()
            if synced then
                finalCharacterData = character:GetSaveableData()
            else
                finalCharacterData = clientCharacterData
                print("[FrameworkZ] Warning: Server disconnect snapshot failed; preserving validated client snapshot: " .. tostring(syncMessage))
            end
        else
            finalCharacterData = clientCharacterData
        end

        if type(finalCharacterData) ~= "table" and type(clientCharacterData) == "table" then
            finalCharacterData = clientCharacterData
        end

        -- The client captures its transform immediately before this request. Prefer that snapshot
        -- because the server's replicated IsoPlayer transform can lag during disconnect teardown.
        if type(finalCharacterData) == "table" then
            local finalX = clientX ~= nil and clientX or fallbackX
            local finalY = clientY ~= nil and clientY or fallbackY
            local finalZ = clientZ ~= nil and clientZ or fallbackZ
            local finalAngle = clientAngle ~= nil and clientAngle or fallbackAngle

            if finalX ~= nil then
                finalCharacterData[FZ_ENUM_CHARACTER_META_POSITION_X] = finalX
                finalCharacterData.POSITION_X = finalX
            end
            if finalY ~= nil then
                finalCharacterData[FZ_ENUM_CHARACTER_META_POSITION_Y] = finalY
                finalCharacterData.POSITION_Y = finalY
            end
            if finalZ ~= nil then
                finalCharacterData[FZ_ENUM_CHARACTER_META_POSITION_Z] = finalZ
                finalCharacterData.POSITION_Z = finalZ
            end
            if finalAngle ~= nil then
                finalCharacterData[FZ_ENUM_CHARACTER_META_POSITION_ANGLE] = finalAngle
                finalCharacterData.DIRECTION_ANGLE = finalAngle
            end

            print("[FrameworkZ] Disconnect transform handoff: x=" .. tostring(finalX) .. ", y=" .. tostring(finalY) .. ", z=" .. tostring(finalZ) .. ", angle=" .. tostring(finalAngle))
        end

        -- The client snapshot was produced immediately before this request from the inventory
        -- the player can actually see. Server item replication can lag behind disconnect, so a
        -- server resnapshot must not replace this canonical inventory with a partial list.
        local clientInventoryData = type(clientCharacterData) == "table" and clientCharacterData[FZ_ENUM_CHARACTER_INVENTORY] or nil
        if type(finalCharacterData) == "table" and type(clientInventoryData) == "table" and type(clientInventoryData.items) == "table" then
            local serverInventoryData = finalCharacterData[FZ_ENUM_CHARACTER_INVENTORY]
            local serverItemCount = type(serverInventoryData) == "table" and type(serverInventoryData.items) == "table" and #serverInventoryData.items or 0
            local clientItemCount = #clientInventoryData.items
            finalCharacterData[FZ_ENUM_CHARACTER_INVENTORY] = clientInventoryData
            print("[FrameworkZ] Disconnect inventory handoff: preserving client snapshot (client=" .. tostring(clientItemCount) .. ", server=" .. tostring(serverItemCount) .. ").")
        end

        if type(finalCharacterData) == "table" and requestedCharacterID ~= nil then
            finalCharacterData[FZ_ENUM_CHARACTER_META_ID] = requestedCharacterID
        end

        if not FrameworkZ.Players:CanAcceptRemoteCharacterSave(username, data.isoPlayer, clientCharacterSaveToken, requestedCharacterID) then
            print("[FrameworkZ] Skipping stale disconnect character save for: " .. tostring(username) .. " (token=" .. tostring(clientCharacterSaveToken) .. ", characterID=" .. tostring(requestedCharacterID) .. ")")
            return true, "Skipped stale disconnect character save"
        end

        local inventoryCount = 0
        if type(finalCharacterData) == "table" then
            local inventoryData = finalCharacterData[FZ_ENUM_CHARACTER_INVENTORY]
            local inventoryItems = inventoryData and inventoryData.items
            if type(inventoryItems) == "table" then inventoryCount = #inventoryItems end
        end

        if finalPlayerData then
            FrameworkZ.Foundation:SetData(isoPlayer, "Players", username, finalPlayerData)
            print("[FrameworkZ] Player data saved during destroy for: " .. username)
        end

        if finalCharacterData then
            local characterID = requestedCharacterID or finalCharacterData[FZ_ENUM_CHARACTER_META_ID] or (character and character:GetID()) or (player and player:GetLoadedCharacterID())

            if characterID then
                if type(finalCharacterData) == "table" then
                    finalCharacterData[FZ_ENUM_CHARACTER_META_ID] = characterID
                end
                FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {username, characterID}, finalCharacterData)
                print("[FrameworkZ] Character data saved during destroy for: " .. username .. " (items=" .. tostring(inventoryCount) .. ")")
            else
                print("[FrameworkZ] Warning: Missing character ID during destroy save for: " .. username)
            end
        end

        return true
    end
end)

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Players)
