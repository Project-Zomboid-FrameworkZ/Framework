--! \page global_variables Global Variables
--! \section Players Players
--! FrameworkZ.Players\n
--! See Players for the module on players.\n\n
--! FrameworkZ.Players.List\n
--! A list of all instanced players in the game.

local getPlayer = getPlayer
local isClient = isClient

FrameworkZ = FrameworkZ or {}

--! \brief Players module for FrameworkZ. Defines and interacts with PLAYER object.
--! \class FrameworkZ.Players
FrameworkZ.Players = {}

--! \brief List of all instanced players in the game.
FrameworkZ.Players.List = {}

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
--! \param shouldTransmit \boolean (Optional) Whether or not to transmit the player's data to the server.
--! \return \boolean Whether or not the player was successfully saved.
--! \todo Test if localized variable (playerData) maintains referential integrity for transmitModData() to work on it.
function PLAYER:Save(shouldTransmit)
    if shouldTransmit == nil then shouldTransmit = true end

    if not self:GetIsoPlayer() then return false end

    local playerData = self:GetStoredData()

    if not playerData then return false end

    playerData.role = self.role
    playerData.maxCharacters = self.maxCharacters
    playerData.previousCharacter = self.previousCharacter
    playerData.whitelists = self.whitelists
    playerData.Characters = self.Characters

    if shouldTransmit then
        self:GetIsoPlayer():transmitModData()
    end

    return true
end

--! \brief Destroys the player object.
--! \return \mixed of \boolean Whether or not the player was successfully destroyed and \string The message on success or failure.
function PLAYER:Destroy()
    if not self:GetIsoPlayer() then return false, "Critical save fail: Iso Player is nil." end

    local username = self:GetUsername()
    local success1, success2, message

    if FrameworkZ.Players.List[username] then
        success1, message = FrameworkZ.Players:Save(username)
    end

    if FrameworkZ.Characters.List[username] then
        FrameworkZ.Characters.List[username] = nil
    end

    if FrameworkZ.Players.List[username] then
        FrameworkZ.Players.List[username] = nil
    end

    if success1 and success2 then
        return true, message
    end

    return false, message
end

function PLAYER:InitializeDefaultFactionWhitelists()
    local factions = FrameworkZ.Factions.List

    for k, v in pairs(factions) do
        if v.isWhitelistedByDefault then
            self.whitelists[v.id] = true
        end
    end
end

function PLAYER:RestoreData(data)
    self:SetRole(data.role)
    self:SetMaxCharacters(data.maxCharacters)
    self:SetPreviousCharacter(data.previousCharacter)
    self:SetWhitelists(data.whitelists)
    self:SetCustomData(data.CustomData)
end

function PLAYER:GetRole()
    return self.role
end

function PLAYER:SetRole(role)
    print("Failed to set Role to: '" .. tostring(role) .. "'. Role is read-only and must be set upon object creation.")
end

function PLAYER:GetPreviousCharacter()
    return self.previousCharacter
end

function PLAYER:SetPreviousCharacter(previousCharacter)
    if not previousCharacter or type(previousCharacter) ~= "number" then
        print("Failed to set Previous Character to: '" .. tostring(previousCharacter) .. "'. Previous Character must be a number.")
        return false
    end

    self.previousCharacter = previousCharacter

    return true
end

function PLAYER:GetMaxCharacters()
    return self.maxCharacters
end

function PLAYER:SetMaxCharacters(maxCharacters)
    if not maxCharacters or type(maxCharacters) ~= "number" then
        print("Failed to set Max Characters to: '" .. tostring(maxCharacters) .. "'. Max Characters must be a number.")
        return false
    end

    if maxCharacters < 1 then
        print("Failed to set Max Characters to: '" .. tostring(maxCharacters) .. "'. Max Characters must be at least 1.")
        return false
    end

    self.maxCharacters = maxCharacters

    return true
end

function PLAYER:GetCustomData()
    return self.CustomData
end

function PLAYER:SetCustomData(customData)
    if not customData or type(customData) ~= "table" then
        print("Failed to set Custom Data to: '" .. tostring(customData) .. "'. Custom Data must be a table.")
        return false
    end

    self.CustomData = customData

    return true
end

function PLAYER:GetCharacter()
    return self.LoadedCharacter
end

function PLAYER:SetCharacter(character)
    self.LoadedCharacter = character
end

function PLAYER:GetCharacters()
    return self.Characters
end

function PLAYER:SetCharacters(characters)
    self.Characters = characters
end

function PLAYER:GetCharacterDataByID(characterID)
    if not characterID then return false, "Missing character ID." end

    local character = self.Characters[characterID]

    if character then
        return character, "Successfully retrieved character data."
    end

    return false, "Character not found."
end

function PLAYER:GetUsername()
    return self.Username
end

function PLAYER:SetUsername(username)
    print("Failed to set Username to: '" .. tostring(username) .. "'. Username is read-only and must be set upon object creation.")
end

function PLAYER:GetIsoPlayer()
    return self.IsoPlayer
end

function PLAYER:SetIsoPlayer(isoPlayer)
    print("Failed to set IsoPlayer to: '" .. tostring(isoPlayer) .. "'. IsoPlayer is read-only and must be set upon object creation.")
end

function PLAYER:GetSaveableData()
    return FrameworkZ.Foundation:ProcessSaveableData(self, {"IsoPlayer", "Characters", "LoadedCharacter"})
end

--! \brief Gets the stored player mod data table. Used internally. Do not use this unless you know what you are doing. Updating data on the mod data will cause inconsistencies between the mod data and the FrameworkZ player object.
--! \return \table The stored player mod data table.
function PLAYER:GetStoredData()
    return self.IsoPlayer:getModData()["FZ_PLY"]
end

function PLAYER:GetWhitelists()
    return self.whitelists
end

function PLAYER:SetWhitelists(whitelists)
    if not whitelists or type(whitelists) ~= "table" then
        print("Failed to set Whitelists to: '" .. tostring(whitelists) .. "'. Whitelists must be a table.")
        return false
    end

    self.whitelists = whitelists

    return true
end

function PLAYER:SetWhitelisted(factionID, whitelisted)
    if not factionID then return false end

    self.whitelists[factionID] = whitelisted
    self:GetStoredData().whitelists[factionID] = whitelisted

    return true
end

function PLAYER:IsWhitelisted(factionID)
    if not factionID then return false end

    return self.whitelists[factionID] or false
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

function FrameworkZ.Players:New(isoPlayer)
    if not isoPlayer then return false end

    -- TODO Reminder: Update FrameworkZ.Players:OnStorageSet() when updating here.
    local object = {
        IsoPlayer = isoPlayer,
        Username = isoPlayer:getUsername(),
        steamID = isoPlayer:getSteamID(),
        role = FrameworkZ.Players.Roles.User,
        LoadedCharacter = nil,
        maxCharacters = FrameworkZ.Config.Options.DefaultMaxCharacters,
        previousCharacter = nil,
        whitelists = {},
        Characters = {},
        CustomData = {}
    }

    setmetatable(object, PLAYER)

	return object
end

function FrameworkZ.Players:Initialize(isoPlayer)
    local player = FrameworkZ.Players:New(isoPlayer) if not player then return false end
    local username = player:GetUsername()
    player:Initialize()

    self.List[username] = player
    self:StartPlayerTick(isoPlayer)

    return self.List[username]
end

function FrameworkZ.Players:StartPlayerTick(isoPlayer)
    if not isClient() then return end

    -- TODO rename CHAR to PLAYER
    FrameworkZ.Timers:Create("FZ_CHAR_TICK", FrameworkZ.Config.Options.PlayerTickInterval, 0, function()
        FrameworkZ.Foundation:ExecuteAllHooks("PlayerTick", isoPlayer)
    end)
end

--! \brief Gets the player object by their username.
--! \param username \string The username of the player.
--! \return \object or \boolean The player object or false if the player was not found.
function FrameworkZ.Players:GetPlayerByID(username)
    if not username then return false, "Username not set." end
    if not self.List[username] then return false, "Player does not exist." end

    return self.List[username]
end

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
--! \return \table or \boolean The character data or false if the data failed to be retrieved.
function FrameworkZ.Players:GetCharacterDataByID(username, characterID)
    if not username then return false, "Missing username." end
    if not characterID then return false, "Missing character ID." end

    local player = FrameworkZ.Players:GetPlayerByID(username) if not player then return false, "Player not found." end

    return player:GetCharacterDataByID(characterID)
end

function FrameworkZ.Players:GetNextCharacterID(username)
    if not username then return false end

    local player = self:GetPlayerByID(username)

    if player then
        local nextID = #player.Characters + 1

        if nextID > player.maxCharacters then
            return false, "Max characters reached."
        end

        return nextID
    end

    return false, "Player not found."
end

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

    return FrameworkZ.Players:CreateCharacter(username, characterData)
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.OnCreateCharacter", FrameworkZ.Players.OnCreateCharacter)

function FrameworkZ.Players:CreateCharacter(username, characterData, characterID)
    if not username then return false, "Username is nil" end
    if not characterData then return false, "Character data is nil." end

    local player = self:GetPlayerByID(username)

    if player and player.Characters then
        if isClient() then
            FrameworkZ.Players:ResetCharacterSaveInterval()
        end

        characterData.META_ID = characterID and characterID or #player.Characters + 1
        characterData.META_FIRST_LOAD = true

        if not characterID then
            table.insert(player.Characters, characterData)
        else
            player.Characters[characterID] = characterData
        end

        characterData.META_UID = player:GenerateUID()

        return characterData.META_ID
    end

    return false, "Player not found."
end

--! \brief Saves the player and their currently loaded character.
--! \param username \string The username of the player.
--! \param continueOnFailure \boolean (Optional) Whether or not to continue saving either the player or character if either should fail. Default = false. True not recommended.
--! \return \boolean Whether or not the player was successfully saved.
--! \return \string The failure message if the player or character failed to save.
function FrameworkZ.Players:Save(username, continueOnFailure)
    if continueOnFailure == nil then continueOnFailure = false end

    local player = FrameworkZ.Players:GetPlayerByID(username)

    if not player then return false end

    local saved = false
    local failureMessage = ""
    local character = player.LoadedCharacter
    local characterSaved = false
    local playerSaved = player:Save(false)
    saved = playerSaved

    if not saved and not continueOnFailure then
        return false, "Failed to save player data."
    elseif not saved and continueOnFailure then
        failureMessage = "Failed to save player data."
    end

    if character then
        characterSaved = character:Save(false)
        saved = characterSaved

        if not saved and not continueOnFailure then
            return false, "Failed to save character data."
        elseif not saved and continueOnFailure then
            failureMessage = failureMessage == "Failed to save player data." and "Failed to save both player data and character data." or "Player data saved, but failed to save character data."
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

function FrameworkZ.Players:Destroy(username)
    local properlyDestroyed = false
    local message = "Failed to destroy player."
    local player = self:GetPlayerByID(username)

    if player then
        properlyDestroyed, message = player:Destroy()
    end

    return properlyDestroyed, message
end

function FrameworkZ.Players:SaveCharacter(username, character)
    local player = FrameworkZ.Players:GetPlayerByID(username)

    if not player or not character then return false end

    local isoPlayer = player:GetIsoPlayer()

    character.INVENTORY_PHYSICAL = {}
    local inventory = isoPlayer:getInventory():getItems()
    for i = 0, inventory:size() - 1 do
        table.insert(character.INVENTORY_PHYSICAL, {id = inventory:get(i):getFullType()})
    end

    character.INVENTORY_LOGICAL = FrameworkZ.Characters:GetCharacterInventoryByID(username).items

    character.EQUIPMENT_SLOT_HEAD = isoPlayer:getWornItem(EQUIPMENT_SLOT_HEAD) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_HEAD):getFullType()} or nil
    character.EQUIPMENT_SLOT_FACE = isoPlayer:getWornItem(EQUIPMENT_SLOT_FACE) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_FACE):getFullType()} or nil
    character.EQUIPMENT_SLOT_EARS = isoPlayer:getWornItem(EQUIPMENT_SLOT_EARS) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_EARS):getFullType()} or nil
    character.EQUIPMENT_SLOT_BACKPACK = isoPlayer:getWornItem(EQUIPMENT_SLOT_BACKPACK) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_BACKPACK):getFullType()} or nil
    character.EQUIPMENT_SLOT_GLOVES = isoPlayer:getWornItem(EQUIPMENT_SLOT_GLOVES) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_GLOVES):getFullType()} or nil
    character.EQUIPMENT_SLOT_UNDERSHIRT = isoPlayer:getWornItem(EQUIPMENT_SLOT_UNDERSHIRT) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_UNDERSHIRT):getFullType()} or nil
    character.EQUIPMENT_SLOT_OVERSHIRT = isoPlayer:getWornItem(EQUIPMENT_SLOT_OVERSHIRT) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_OVERSHIRT):getFullType()} or nil
    character.EQUIPMENT_SLOT_VEST = isoPlayer:getWornItem(EQUIPMENT_SLOT_VEST) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_VEST):getFullType()} or nil
    character.EQUIPMENT_SLOT_BELT = isoPlayer:getWornItem(EQUIPMENT_SLOT_BELT) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_BELT):getFullType()} or nil
    character.EQUIPMENT_SLOT_PANTS = isoPlayer:getWornItem(EQUIPMENT_SLOT_PANTS) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_PANTS):getFullType()} or nil
    character.EQUIPMENT_SLOT_SOCKS = isoPlayer:getWornItem(EQUIPMENT_SLOT_SOCKS) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_SOCKS):getFullType()} or nil
    character.EQUIPMENT_SLOT_SHOES = isoPlayer:getWornItem(EQUIPMENT_SLOT_SHOES) and {id = isoPlayer:getWornItem(EQUIPMENT_SLOT_SHOES):getFullType()} or nil

    -- Save character position/direction angle
    character.POSITION_X = isoPlayer:getX()
    character.POSITION_Y = isoPlayer:getY()
    character.POSITION_Z = isoPlayer:getZ()
    character.DIRECTION_ANGLE = isoPlayer:getDirectionAngle()

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

function PLAYER:SetModel(characterData)
    if not characterData then return false end
    if not self:GetIsoPlayer() then return false end
    local isoPlayer = self:GetIsoPlayer()

    local isFemale = characterData.INFO_GENDER == "Female" or not characterData.INFO_GENDER == "Male"
    isoPlayer:setFemale(isFemale)
    isoPlayer:getDescriptor():setFemale(isFemale)

    local hairColor = characterData.INFO_HAIR_COLOR
    local beardColor = characterData.INFO_BEARD_COLOR
    local visual = isoPlayer:getHumanVisual()
    visual:clear()
    visual:setBeardColor(ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1))
    visual:setBeardModel(characterData.INFO_BEARD_STYLE)
    visual:setHairColor(ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1))
    visual:setHairModel(characterData.INFO_HAIR_STYLE)
    visual:setNaturalBeardColor(ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1))
    visual:setNaturalHairColor(ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1))
    visual:setSkinTextureIndex(characterData.INFO_SKIN_COLOR)

    isoPlayer:resetModel()
end

function PLAYER:LoadCharacter(characterID)
    if not characterID then return false end

    FrameworkZ.Players:OnLoadCharacter(self:GetUsername(), characterID)
end

function FrameworkZ.Players:LoadCharacterByID(username, characterID)
    local clientLoadCharacter = function(_data, success, message)
        if not success then
            FrameworkZ.Notifications:AddToQueue("Failed to load character: " .. message, FrameworkZ.Notifications.Types.Danger, nil, PFW_MainMenu.instance)
            return
        end

        self:OnLoadCharacter(username, characterID)
    end

    FrameworkZ.Foundation:SendFire(FrameworkZ.Players:GetPlayerByID(username):GetIsoPlayer(), "FrameworkZ.Players.LoadCharacter", clientLoadCharacter, username, characterID)
end

if isServer() then
    function FrameworkZ.Players.LoadCharacter(_data, username, characterID)
        return FrameworkZ.Players:OnLoadCharacter(username, characterID)
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Players.LoadCharacter", FrameworkZ.Players.LoadCharacter)
end

function FrameworkZ.Players:OnLoadCharacter(username, characterID)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterLoaded", username, characterID)

    local player, message = FrameworkZ.Players:GetPlayerByID(username) if not player then return false, message end
    local character, message2 = FrameworkZ.Characters:Initialize(player:GetIsoPlayer(), characterID) if not character then return false, message2 end
    local characterData, message3 = player:GetCharacterDataByID(characterID) if not characterData then return false, message3 end
    local isoPlayer = player:GetIsoPlayer()

    player:SetCharacter(character)

    FrameworkZ.Players:OnPreLoadCharacter(isoPlayer, player, character, characterData)
    FrameworkZ.Players:OnPostLoadCharacter(isoPlayer, player, character, characterData)

    return true, "Successfully loaded character."
end

function FrameworkZ.Players:OnPreLoadCharacter(isoPlayer, player, character, characterData)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPreLoad", isoPlayer, player, character, characterData)

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

    player:SetModel(characterData)

    -- Apply damage/wounds/moodles
end

function FrameworkZ.Players:OnPostLoadCharacter(isoPlayer, player, character, characterData)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostLoad", isoPlayer, player, character, characterData)

    if isClient() then
        FrameworkZ.Notifications:AddToQueue("Please wait a few seconds for the map to load.", FrameworkZ.Notifications.Types.Warning)
    end

    FrameworkZ.Timers:Simple(2, function()
        if characterData.META_FIRST_LOAD == true then
            local options = FrameworkZ.Config.Options

            isoPlayer:setX(options.SpawnX)
            isoPlayer:setY(options.SpawnY)
            isoPlayer:setZ(options.SpawnZ)
            isoPlayer:setLx(options.SpawnX)
            isoPlayer:setLy(options.SpawnY)
            isoPlayer:setLz(options.SpawnZ)
        else
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

        if isClient() and PFW_MainMenu.instance then
            PFW_MainMenu.instance:onClose()
        end

        FrameworkZ.Timers:Simple(3, function()
            isoPlayer:setGodMod(false)
            isoPlayer:setInvincible(false)

            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Spawn protection has now been removed.", FrameworkZ.Notifications.Types.Warning)
            end

            FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterFinishedLoading", isoPlayer, player, character, characterData)
        end)
    end)
end

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
            FrameworkZ.Notifications:AddToQueue("Failed to load character: Not found.", FrameworkZ.Notifications.Types.Danger, nil, PFW_MainMenu.instance)
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
                FrameworkZ.Notifications:AddToQueue("Failed to load character: Not saved.", FrameworkZ.Notifications.Types.Danger, nil, PFW_MainMenu.instance)

                FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Foundation.TeleportToLimbo", function(success)
                    if success then
                        FrameworkZ.Foundation.TeleportToLimbo({isoPlayer = isoPlayer})
                    end
                end)
            else
                PFW_MainMenu.instance:onClose()
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
    worldObjects = FrameworkZ.Utilities:RemoveContextDuplicates(worldObjects)

    context:clear()

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

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Players)
