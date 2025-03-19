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
FrameworkZ.Players.__index = FrameworkZ.Players

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
    if not self.isoPlayer then return end

    local firstConnection = false
    local characterModData = self.isoPlayer:getModData()["FZ_PLY"] or nil

    if not characterModData then
        firstConnection = true

        self:InitializeDefaultFactionWhitelists()

        self.isoPlayer:getModData()["FZ_PLY"] = {
            username = self.username,
            steamID = self.steamID,
            role = self.role,
            maxCharacters = self.maxCharacters,
            previousCharacter = self.previousCharacter,
            whitelists = self.whitelists,
            characters = self.characters
        }

        if isClient() then
            self.isoPlayer:transmitModData()
        end
    end

    self:ValidatePlayerData()

    --[[if isClient() then
        FrameworkZ.Timers:Simple(5, function()
            sendClientCommand("FZ_PLY", "initialize", {self.isoPlayer:getUsername()})
        end)
    end--]]

    return FrameworkZ.Players:Initialize(self.username, self)
end

--! \brief Saves the player's data.
--! \param shouldTransmit \boolean (Optional) Whether or not to transmit the player's data to the server.
--! \return \boolean Whether or not the player was successfully saved.
--! \todo Test if localized variable (playerData) maintains referential integrity for transmitModData() to work on it.
function PLAYER:Save(shouldTransmit)
    if shouldTransmit == nil then shouldTransmit = true end

    if not self.isoPlayer then return false end

    local playerData = self:GetStoredData()

    if not playerData then return false end

    playerData.role = self.role
    playerData.maxCharacters = self.maxCharacters
    playerData.previousCharacter = self.previousCharacter
    playerData.whitelists = self.whitelists
    playerData.characters = self.characters

    if shouldTransmit then
        self.isoPlayer:transmitModData()
    end

    return true
end

--! \brief Destroys the player object.
--! \return \mixed of \boolean Whether or not the player was successfully destroyed and \string The message on success or failure.
function PLAYER:Destroy()
    if not self.isoPlayer then return false, "Critical save fail: Iso Player is nil." end

    local username = self.isoPlayer:getUsername()
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
        characterModData.maxCharacters = self.maxCharacters or FrameworkZ.Config.DefaultMaxCharacters
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

    if not characterModData.characters then
        initializedNewData = true
        characterModData.characters = self.characters or {}
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
    self.characters = characterModData.characters

    return initializedNewData
end

function PLAYER:GetCharacter()
    return self.loadedCharacter
end

--! \brief Gets the stored player mod data table. Used internally. Do not use this unless you know what you are doing. Updating data on the mod data will cause inconsistencies between the mod data and the FrameworkZ player object.
--! \return \table The stored player mod data table.
function PLAYER:GetStoredData()
    return self.isoPlayer:getModData()["FZ_PLY"]
end

function PLAYER:GetWhitelists()
    return self.whitelists
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
    return self.isoPlayer:getEmitter():playSoundImpl(soundName, nil)
end

--! \brief Stops a sound for the player.
--! \param soundNameOrID \mixed of \string or \integer The name or ID of the sound to stop.
function PLAYER:StopSound(soundNameOrID)
    if type(soundNameOrID) == "number" then
        self.isoPlayer:getEmitter():stopSound(soundNameOrID)
    elseif type(soundNameOrID) == "string" then
        self.isoPlayer:getEmitter():stopSoundByName(soundNameOrID)
    end
end

function FrameworkZ.Players:New(isoPlayer)
    if not isoPlayer then return false end

    local object = {
        username = isoPlayer:getUsername(),
        isoPlayer = isoPlayer,
        steamID = isoPlayer:getSteamID(),
        role = FrameworkZ.Players.Roles.User,
        loadedCharacter = nil,
        maxCharacters = FrameworkZ.Config.DefaultMaxCharacters,
        previousCharacter = nil,
        whitelists = {},
        characters = {}
    }

    setmetatable(object, PLAYER)

	return object
end

function FrameworkZ.Players:Initialize(username, player)
    self.List[username] = player

    return username
end

function FrameworkZ.Players:GetPlayerByID(username)
    if not username then return false end

    local player = self.List[username]

    if player then
        return player
    end

    return false
end

function FrameworkZ.Players:GetCharacterByID(username, characterID)
    if not username or not characterID then return false end

    local player = self:GetPlayerByID(username)

    if player then
        local character = player.characters[characterID]

        if character then
            return character
        end
    end

    return false
end

--! \brief Gets saved character data by their ID.
--! \param username \string The username of the player.
--! \param characterID \integer The ID of the character.
--! \return \table or \boolean The character data or false if the data failed to be retrieved.
function FrameworkZ.Players:GetCharacterDataByID(username, characterID)
    if not username or not characterID then return false end

    local player = FrameworkZ.Players:GetPlayerByID(username)

    if player then
        local character = player.characters[characterID]

        if character then
            return character
        end
    end

    return false
end

function FrameworkZ.Players:ResetCharacterSaveInterval()
    if FrameworkZ.Timers:Exists("FZ_CharacterSaveInterval") then
        FrameworkZ.Timers:Start("FZ_CharacterSaveInterval")
    end
end

function FrameworkZ.Players:CreateCharacter(username, data)
    if not username or not data then return false end

    local player = self:GetPlayerByID(username)

    if player and player.characters then
        FrameworkZ.Players:ResetCharacterSaveInterval()

        data.META_ID = #player.characters + 1
        data.META_FIRST_LOAD = true

        table.insert(player.characters, data)
        player:GetStoredData().characters = player.characters

        if isClient() then
            player.isoPlayer:transmitModData()
        end

        return true, #player.characters
    end

    return false
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
    local character = player.loadedCharacter
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
        player.isoPlayer:transmitModData()
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

    local isoPlayer = player.isoPlayer

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
function FrameworkZ.Players:LoadCharacter(username, characterData, survivorDescriptor)
    local player = FrameworkZ.Players:GetPlayerByID(username)

    if not player or not characterData then return false end

    local isoPlayer = player.isoPlayer

    if characterData.META_FIRST_LOAD == true then
        isoPlayer:setX(FrameworkZ.Config.SpawnX)
        isoPlayer:setY(FrameworkZ.Config.SpawnY)
        isoPlayer:setZ(FrameworkZ.Config.SpawnZ)
        isoPlayer:setLx(FrameworkZ.Config.SpawnX)
        isoPlayer:setLy(FrameworkZ.Config.SpawnY)
        isoPlayer:setLz(FrameworkZ.Config.SpawnZ)
    else
        isoPlayer:setX(characterData.POSITION_X)
        isoPlayer:setY(characterData.POSITION_Y)
        isoPlayer:setZ(characterData.POSITION_Z)
        isoPlayer:setLx(characterData.POSITION_X)
        isoPlayer:setLy(characterData.POSITION_Y)
        isoPlayer:setLz(characterData.POSITION_Z)
        isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
    end

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

    local postLoadSuccessful, character = FrameworkZ.Characters:PostLoad(isoPlayer, characterData)

    if not postLoadSuccessful or not character then return false end

    player.loadedCharacter = character
    character:OnPostLoad(characterData.META_FIRST_LOAD)

    if characterData.META_FIRST_LOAD then
        characterData.META_FIRST_LOAD = false
    end

    if not self:SaveCharacter(username, characterData) then return false end

    return true
end

function FrameworkZ.Players:LoadCharacterByID(username, characterID)

end

function FrameworkZ.Players:DeleteCharacter(username, character)

end

function FrameworkZ.Players:DeleteCharacterByID(username, characterID)

end

function FrameworkZ.Players:InitializeClient(isoPlayer)
    local player = FrameworkZ.Players:New(isoPlayer)

    if player then
        player:Initialize()
    end
end

if not isClient() then
    function FrameworkZ.Players.OnClientCommand(module, command, isoPlayer, args)
        if module == "FZ_PLY" then
            if command == "initialize" then
                local player = FrameworkZ.Players:New(isoPlayer)

                if player then
                    player:Initialize()
                end
            elseif command == "remove_limbo_protection" then
                isoPlayer:setGodMod(false)
                isoPlayer:setInvincible(false)
                isoPlayer:setInvisible(false)
                isoPlayer:setGhostMode(false)
                isoPlayer:setNoClip(false)
                sendPlayerExtraInfo(isoPlayer)
            elseif command == "on_first_load" then
                isoPlayer:setX(FrameworkZ.Config.SpawnX)
                isoPlayer:setY(FrameworkZ.Config.SpawnY)
                isoPlayer:setZ(FrameworkZ.Config.SpawnZ)
                isoPlayer:setLx(FrameworkZ.Config.SpawnX)
                isoPlayer:setLy(FrameworkZ.Config.SpawnY)
                isoPlayer:setLz(FrameworkZ.Config.SpawnZ)
            elseif command == "destroy" then
                local username = args[1]
                local player = FrameworkZ.Players:GetPlayerByID(username)

                if player then
                    player:Destroy()
                end

                FrameworkZ.Characters.List[username] = nil
            elseif command == "update" then
                local username = args[1]
                local field = args[2]
                local newData = args[3]

                FrameworkZ.Players.List[username][field] = newData
            end
        end
    end
    Events.OnClientCommand.Add(FrameworkZ.Players.OnClientCommand)
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Players)
