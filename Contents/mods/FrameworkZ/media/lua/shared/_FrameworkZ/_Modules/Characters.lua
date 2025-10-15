--! \page Features
--! \section Characters Characters
--! Characters are the main focus of the game. They are a piece of the player that interacts with the world. Characters can be given a name, description, faction, age, height, eye color, hair color, etc. They can also be given items and equipment.
--! When a player connects to the server, they may create a character and load said character. The character is then saved to the player's data and can be loaded again when the player reconnects. Characters will be saved automatically at predetermined intervals or upon disconnection or when switching characters.
--! Characters are not given items in the traditional sense. Instead, they are given items by a unique ID from an item defined in the framework's (or gamemode's or even plugin's) files. This special item definition is then used to create an item instance that is added to the character's inventory. This allows for items to be created dynamically and given to characters. This allows for the same Project Zomboid item to be reused for different purposes. However characters can still be given items in the traditional sense, all of which will save/restore as needed.

--! \page Global Variables
--! \section characters_variables Characters Variables
--! FrameworkZ.Characters
--! See Characters for the module on characters.
--! FrameworkZ.Characters.List
--! A list of all instanced characters in the game.

local isClient = isClient

FrameworkZ = FrameworkZ or {}

--! \brief Characters module for FrameworkZ. Defines and interacts with CHARACTER object.
--! \module FrameworkZ.Characters
FrameworkZ.Characters = {}

--! \brief Constant for pale skin color.
SKIN_COLOR_PALE = 0
--! \brief Constant for white skin color.
SKIN_COLOR_WHITE = 1
--! \brief Constant for tanned skin color.
SKIN_COLOR_TANNED = 2
--! \brief Constant for brown skin color.
SKIN_COLOR_BROWN = 3
--! \brief Constant for dark brown skin color.
SKIN_COLOR_DARK_BROWN = 4

--! \brief Red component for black hair color.
HAIR_COLOR_BLACK_R = 0
--! \brief Green component for black hair color.
HAIR_COLOR_BLACK_G = 0
--! \brief Blue component for black hair color.
HAIR_COLOR_BLACK_B = 0
--! \brief Red component for blonde hair color.
HAIR_COLOR_BLONDE_R = 0.9
--! \brief Green component for blonde hair color.
HAIR_COLOR_BLONDE_G = 0.9
--! \brief Blue component for blonde hair color.
HAIR_COLOR_BLONDE_B = 0.6
--! \brief Red component for brown hair color.
HAIR_COLOR_BROWN_R = 0.3
--! \brief Green component for brown hair color.
HAIR_COLOR_BROWN_G = 0.2
--! \brief Blue component for brown hair color.
HAIR_COLOR_BROWN_B = 0.2
--! \brief Red component for gray hair color.
HAIR_COLOR_GRAY_R = 0.5
--! \brief Green component for gray hair color.
HAIR_COLOR_GRAY_G = 0.5
--! \brief Blue component for gray hair color.
HAIR_COLOR_GRAY_B = 0.5
--! \brief Red component for red hair color.
HAIR_COLOR_RED_R = 0.9
--! \brief Green component for red hair color.
HAIR_COLOR_RED_G = 0.4
--! \brief Blue component for red hair color.
HAIR_COLOR_RED_B = 0.1
--! \brief Red component for white hair color.
HAIR_COLOR_WHITE_R = 1
--! \brief Green component for white hair color.
HAIR_COLOR_WHITE_G = 1
--! \brief Blue component for white hair color.
HAIR_COLOR_WHITE_B = 1

--! \brief List of all active character instances by username.
FrameworkZ.Characters.List = {}

--! \brief Unique IDs list for characters by UID.
FrameworkZ.Characters.Cache = {}

FrameworkZ.Characters = FrameworkZ.Foundation:NewModule(FrameworkZ.Characters, "Characters")

--! \brief Character class for FrameworkZ.
--! \class CHARACTER
local CHARACTER = {}
CHARACTER.__index = CHARACTER

--! \brief Save the character's data from the character object.
--! \return \boolean Whether or not the character was successfully saved.
function CHARACTER:Save()
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false end
    local player = FrameworkZ.Players:GetPlayerByID(isoPlayer:getUsername())

    if not player then return false end
    FrameworkZ.Players:ResetCharacterSaveInterval()

    -- Use centralized data manager for saving
    local characterData, saveMessage = FrameworkZ.CharacterDataManager:SaveCharacterData(self)
    if characterData then
        print("[FrameworkZ] Character data saved: " .. saveMessage)
        return FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {isoPlayer:getUsername(), self:GetID()}, characterData)
    else
        print("[FrameworkZ] Warning: Failed to save character data: " .. (saveMessage or "Unknown error"))
        return false
    end

    --[[
    modData.status.health = character:getBodyDamage():getOverallBodyHealth()
    modData.status.injuries = character:getBodyDamage():getInjurySeverity()
    modData.status.hyperthermia = character:getBodyDamage():getTemperature()
    modData.status.hypothermia = character:getBodyDamage():getColdStrength()
    modData.status.wetness = character:getBodyDamage():getWetness()
    modData.status.hasCold = character:getBodyDamage():HasACold()
    modData.status.sick = character:getBodyDamage():getSicknessLevel()
    --]]

    --player.Characters[self.id] = characterData

    local characters = player:GetCharacters()

    FrameworkZ.Utilities:MergeTables(characters[self.ID], characterData)

    FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {isoPlayer:getUsername(), self.ID}, characters[self.ID])

    return true
end

--! \brief Destroy a character. This will remove the character from the list of characters and is usually called after a player has disconnected.
function CHARACTER:Destroy()
    --[[
	if isClient() then
        sendClientCommand("FZ_CHAR", "destroy", {self:GetIsoPlayer():getUsername()})
    end
	--]]

    self.IsoPlayer = nil
end

--! \brief Initialize the default items for a character based on their faction. Called when FZ_CHAR mod data is first created.
function CHARACTER:InitializeDefaultItems()
    local faction = FrameworkZ.Factions:GetFactionByID(self.faction)

    if faction then
        for k, v in pairs(faction.defaultItems) do
           self:GiveItems(k, v)
        end
    end
end

--! \brief Get the character's age.
--! \return \integer The character's age.
function CHARACTER:GetAge() return self.Age end
--! \brief Set the character's age.
--! \param age \integer The age to set.
function CHARACTER:SetAge(age) self.Age = age end

--! \brief Get the character's beard color.
--! \return \table The character's beard color as RGB values.
function CHARACTER:GetBeardColor() return self.BeardColor end
--! \brief Set the character's beard color.
--! \param beardColor \table The beard color to set as RGB values.
function CHARACTER:SetBeardColor(beardColor) self.BeardColor = beardColor end

--! \brief Get the character's beard style.
--! \return \string The character's beard style.
function CHARACTER:GetBeardStyle() return self.BeardStyle end
--! \brief Set the character's beard style.
--! \param beardStyle \string The beard style to set.
function CHARACTER:SetBeardStyle(beardStyle) self.BeardStyle = beardStyle end

--! \brief Get the character's description.
--! \return \string The character's description.
function CHARACTER:GetDescription() return self.Description end
--! \brief Set the character's description.
--! \param description \string The description to set.
function CHARACTER:SetDescription(description) self.Description = description end

--! \brief Get the character's eye color.
--! \return \table The character's eye color as RGB values.
function CHARACTER:GetEyeColor() return self.EyeColor end
--! \brief Set the character's eye color.
--! \param eyeColor \table The eye color to set as RGB values.
function CHARACTER:SetEyeColor(eyeColor) self.EyeColor = eyeColor end

--! \brief Get the character's faction.
--! \return \string The character's faction ID.
function CHARACTER:GetFaction() return self.Faction end
--! \brief Set the character's faction.
--! \param faction \string The faction ID to set.
function CHARACTER:SetFaction(faction) self.Faction = faction end

--! \brief Get the character's hair color.
--! \return \table The character's hair color as RGB values.
function CHARACTER:GetHairColor() return self.HairColor end
--! \brief Set the character's hair color.
--! \param hairColor \table The hair color to set as RGB values.
function CHARACTER:SetHairColor(hairColor) self.HairColor = hairColor end

--! \brief Get the character's hair style.
--! \return \string The character's hair style.
function CHARACTER:GetHairStyle() return self.HairStyle end
--! \brief Set the character's hair style.
--! \param hairStyle \string The hair style to set.
function CHARACTER:SetHairStyle(hairStyle) self.HairStyle = hairStyle end

--! \brief Get the character's height.
--! \return \number The character's height.
function CHARACTER:GetHeight() return self.Height end
--! \brief Set the character's height.
--! \param height \number The height to set.
function CHARACTER:SetHeight(height) self.Height = height end

--! \brief Get the character's ID.
--! \return \integer The character's ID.
function CHARACTER:GetID() return self.ID end
--! \brief Set the character's ID.
--! \param id \integer The ID to set.
function CHARACTER:SetID(id) self.ID = id end

--! \brief Get the character's inventory object.
--! \return \table The character's inventory object.
function CHARACTER:GetInventory() return self.Inventory end
--! \brief Set the character's inventory object.
--! \param inventory \table The inventory object to set.
function CHARACTER:SetInventory(inventory) self.Inventory = inventory end

--! \brief Get the character's inventory ID.
--! \return \integer The character's inventory ID.
function CHARACTER:GetInventoryID() return self.InventoryID end
--! \brief Set the character's inventory ID.
--! \param inventoryID \integer The inventory ID to set.
function CHARACTER:SetInventoryID(inventoryID) self.InventoryID = inventoryID end

--! \brief Get the character's IsoPlayer object.
--! \return \table The character's IsoPlayer object.
function CHARACTER:GetIsoPlayer() return self.IsoPlayer end
--! \brief Set the character's IsoPlayer object (read-only).
--! \param isoPlayer \table The IsoPlayer object (cannot be set after creation).
function CHARACTER:SetIsoPlayer(isoPlayer) print("Failed to set IsoPlayer object to '" .. tostring(isoPlayer) .. "'. IsoPlayer is read-only and must be set upon object creation.") end

--! \brief Get the character's logical inventory data.
--! \return \table The character's logical inventory data.
function CHARACTER:GetLogicalInventory() return self.LogicalInventory end
--! \brief Set the character's logical inventory data.
--! \param logicalInventory \table The logical inventory data to set.
function CHARACTER:SetLogicalInventory(logicalInventory) self.LogicalInventory = logicalInventory end

--! \brief Get the character's name.
--! \return \string The character's name.
function CHARACTER:GetName() return self.Name end
--! \brief Set the character's name.
--! \param name \string The name to set.
function CHARACTER:SetName(name) self.Name = name end

--! \brief Get the character's physical inventory data.
--! \return \table The character's physical inventory data.
function CHARACTER:GetPhysicalInventory() return self.PhysicalInventory end
--! \brief Set the character's physical inventory data.
--! \param physicalInventory \table The physical inventory data to set.
function CHARACTER:SetPhysicalInventory(physicalInventory) self.PhysicalInventory = physicalInventory end

--! \brief Get the character's physique.
--! \return \string The character's physique.
function CHARACTER:GetPhysique() return self.Physique end
--! \brief Set the character's physique.
--! \param physique \string The physique to set.
function CHARACTER:SetPhysique(physique) self.Physique = physique end

--! \brief Get the character's associated player object.
--! \return \table The character's player object.
function CHARACTER:GetPlayer() return self.Player end
--! \brief Set the character's associated player object.
--! \param player \table The player object to set.
function CHARACTER:SetPlayer(player) self.Player = player end

--! \brief Get the character's recognition list.
--! \return \table The character's recognition list.
function CHARACTER:GetRecognizes() return self.Recognizes end
--! \brief Set the character's recognition list.
--! \param recognizes \table The recognition list to set.
function CHARACTER:SetRecognizes(recognizes) self.Recognizes = recognizes end

--! \brief Get the character's skin color.
--! \return \integer The character's skin color constant.
function CHARACTER:GetSkinColor() return self.SkinColor end
--! \brief Set the character's skin color.
--! \param skinColor \integer The skin color constant to set.
function CHARACTER:SetSkinColor(skinColor) self.SkinColor = skinColor end

--! \brief Get the character's unique ID.
--! \return \string The character's unique ID.
function CHARACTER:GetUID() return self.UID end
--! \brief Set the character's unique ID.
--! \param uid \string The unique ID to set.
function CHARACTER:SetUID(uid) self.UID = uid end

--! \brief Get the character's username.
--! \return \string The character's username.
function CHARACTER:GetUsername() return self.Username end
--! \brief Set the character's username (read-only).
--! \param username \string The username (cannot be set after creation).
function CHARACTER:SetUsername(username) print("Failed to set username to: '" .. username .. "'. Username is read-only and must be set upon object creation.") end

--! \brief Get the character's weight.
--! \return \number The character's weight.
function CHARACTER:GetWeight() return self.Weight end
--! \brief Set the character's weight.
--! \param weight \number The weight to set.
function CHARACTER:SetWeight(weight) self.Weight = weight end

--! \brief Get the character's saveable data with filtered properties.
--! \return \table The character's saveable data.
function CHARACTER:GetSaveableData()
    local ignoreList = {
        "IsoPlayer",
        "Player"
    }

    local encodeList = {
        "Inventory"
    }

    return FrameworkZ.Foundation:ProcessSaveableData(self, ignoreList, encodeList)
end

--[[ Note: Setup UID on Player object inside of stored Characters at Character
function CHARACTER:SetUID(uid)
    local player = FrameworkZ.Players:GetPlayerByID(self:GetUsername()) if not player then return false, "Could not find player by ID." end

    self.uid = uid
    player.Characters[self:GetID()].META_UID = uid

    return true
end
--]]

--! \brief Give a character items by the specified amount.
--! \param uniqueID \string The unique ID of the item to give.
--! \param amount \integer The amount of the item to give.
function CHARACTER:GiveItems(uniqueID, amount)
    for i = 1, amount do
        self:GiveItem(uniqueID)
    end
end

--! \brief Take multiple items from a character's inventory by unique ID.
--! \param uniqueID \string The unique ID of the items to take.
--! \param amount \integer The number of items to take.
function CHARACTER:TakeItems(uniqueID, amount)
    for i = 1, amount do
        self:TakeItem(uniqueID)
    end
end

--! \brief Give a character an item.
--! \param uniqueID \string The ID of the item to give.
--! \return \boolean Whether or not the item was successfully given.
function CHARACTER:GiveItem(uniqueID)
    local inventory = self:GetInventory()
    if not inventory then return false, "Failed to find inventory." end
    local instance, message = FrameworkZ.Items:CreateItem(uniqueID, self:GetIsoPlayer())
    if not instance then return false, "Failed to create item: " .. message end

    inventory:AddItem(instance)

    return instance, message
end

--! \brief Take an item from a character's inventory.
--! \param uniqueID \string The unique ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItem(uniqueID)
    local success, message = FrameworkZ.Items:RemoveItemInstanceByUniqueID(self:GetIsoPlayer():getUsername(), uniqueID)

    if success then
        return true, "Successfully took " .. uniqueID .. "."
    end

    return false, message
end

--! \brief Take an item from a character's inventory by its instance ID. Useful for taking a specific item from a stack.
--! \param instanceID \integer The instance ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItemByInstanceID(instanceID)
    local success, message = FrameworkZ.Items:RemoveInstance(instanceID, self:GetIsoPlayer():getUsername())

    if success then
        return true, "Successfully took item with instance ID " .. instanceID .. "."
    end

    return false, "Failed to find item with instance ID " .. instanceID .. ": " .. message
end

--! \brief Checks if a character is a citizen.
--! \return \boolean Whether or not the character is a citizen.
function CHARACTER:IsCitizen()
    if not self.faction then return false end

    if self.faction == FACTION_CITIZEN then
        return true
    end
    
    return false
end

--! \brief Checks if a character is a combine.
--! \return \boolean Whether or not the character is a combine.
function CHARACTER:IsCombine()
    if not self.faction then return false end

    if self.faction == FACTION_CP then
        return true
    elseif self.faction == FACTION_OTA then
        return true
    elseif self.faction == FACTION_ADMINISTRATOR then
        return true
    end

    return false
end

--! \brief Add a character to the recognition list.
--! \param character \table The character object to add to recognition.
--! \param alias \string (Optional) The alias to recognize the character as.
--! \return \boolean \string Whether the recognition was successfully added and a message.
function CHARACTER:AddRecognition(character, alias)
    if not character then return false, "Character not supplied in parameters." end

    if not self:GetRecognizes()[character:GetUID()] then
        self:GetRecognizes()[character:GetUID()] = alias or character:GetName()
        return true, "Successfully added character to recognition list."
    end

    return false, "Character already exists in recognition list."
end

--! \brief Get how this character recognizes another character.
--! \param character \table The character object to get recognition for.
--! \return \string The name or alias this character recognizes the other as.
function CHARACTER:GetRecognition(character)
    if not character then return false, "Character not supplied in parameters." end

    local recognizes = self:GetRecognizes()

    if recognizes[character:GetUID()] then
        return recognizes[character:GetUID()]
    else
        return "[Unrecognized]"
    end
end

--! \brief Check if this character recognizes another character.
--! \param character \table The character object to check recognition for.
--! \return \boolean Whether this character recognizes the other character.
function CHARACTER:RecognizesCharacter(character)
    if not character then return false, "Character not supplied in parameters." end

    if self:GetRecognizes()[character:GetUID()] then
        return true
    end

    return false
end

--! \brief Used for restoring character data from a table, typically a table gathered through the FZ Data Storage system.
--! \param characterData \table (Optional) The character data table to restore from.
function CHARACTER:RestoreData(characterData)
    local player = self:GetPlayer() if not player then return false, "Player not found." end
    characterData = characterData or player:GetCharacterDataByID(self:GetID()) if not characterData then return false, "Character data not found." end

    self:SetAge(characterData[FZ_ENUM_CHARACTER_INFO_AGE])
    self:SetBeardColor(characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR])
    self:SetBeardStyle(characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE])
    self:SetDescription(characterData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION])
    self:SetEyeColor(characterData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR])
    self:SetFaction(characterData[FZ_ENUM_CHARACTER_INFO_FACTION])
    self:SetHairColor(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR])
    self:SetHairStyle(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE])
    self:SetHeight(characterData[FZ_ENUM_CHARACTER_INFO_HEIGHT])
    self:SetID(characterData[FZ_ENUM_CHARACTER_META_ID])
    self:SetLogicalInventory(characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL])
    self:SetName(characterData[FZ_ENUM_CHARACTER_INFO_NAME])
    self:SetPhysique(characterData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE])
    self:SetPhysicalInventory(characterData[FZ_ENUM_CHARACTER_INVENTORY_PHYSICAL])
    self:SetRecognizes(characterData[FZ_ENUM_CHARACTER_META_RECOGNIZES] or {})
    self:SetSkinColor(characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR])
    self:SetUID(characterData[FZ_ENUM_CHARACTER_META_UID])
    self:SetWeight(characterData[FZ_ENUM_CHARACTER_INFO_WEIGHT])

    local newInventory = FrameworkZ.Inventories:New(self:GetUsername())
    local _success, _message, rebuiltInventory = FrameworkZ.Inventories:Rebuild(self:GetIsoPlayer(), newInventory, self:GetLogicalInventory() or nil)
    self:SetInventory(rebuiltInventory or FrameworkZ.Inventories:New(self:GetUsername()))

    if self:GetInventory() then
        self:SetInventoryID(self:GetInventory().id)
        self:GetInventory():Initialize()
    end

    return true, "Character data restored."
end

--! \brief Initialize a character.
--! \return \boolean \string Whether initialization was successful and a message.
function CHARACTER:Initialize()
	if not self:GetIsoPlayer() then return false, "IsoPlayer not set." end

    --self:GetInventory():Initialize()
    local successfullyRestored, restoreMessage = self:RestoreData() if not successfullyRestored then return false, "Failed to restore character data: " .. restoreMessage end

    if not self:RecognizesCharacter(self) then
        local successfullyRecognizes, recognizeMessage = self:AddRecognition(self) if not successfullyRecognizes then return false, "Failed to add self to recognition list: " .. recognizeMessage end
    end

    return true, "Character initialized."
end

--! \brief Create a new character object.
--! \param isoPlayer \table The IsoPlayer object associated with this character.
--! \param id \integer The character's ID from the player stored data.
--! \return \object|\boolean The new character object or false if the process failed to create a new character object.
--! \return \string An error message if the process failed.
function FrameworkZ.Characters:New(isoPlayer, id)
    if not isoPlayer then return false, "IsoPlayer is invalid." end

    local username = isoPlayer:getUsername()
    local object = {
        ID = id or -1,
        Player = FrameworkZ.Players:GetPlayerByID(username),
        IsoPlayer = isoPlayer,
        Username = username,
        Inventory = FrameworkZ.Inventories:New(username),
        CustomData = {},
        Recognizes = {}
    }

    if object.ID <= -1 then return false, "New character ID is invalid." end
    if not object.Player then return false, "Player not found." end
    if not object.Inventory then return false, "Inventory not found." end
    if object.Player and not object.Player:GetCharacterDataByID(object.ID) then return false, "Player character data not found." end

    setmetatable(object, CHARACTER)

	return object
end

--! \brief Initialize a character and add it to the system.
--! \param isoPlayer \table The IsoPlayer object associated with this character.
--! \param id \integer The character's ID from the player stored data.
--! \return \table \string The initialized character object or false and an error message.
function FrameworkZ.Characters:Initialize(isoPlayer, id)
    local character, message = FrameworkZ.Characters:New(isoPlayer, id) if not character then return false, "Could not create new character object, " .. message end
    local username = character:GetUsername()
    local success, message2 = character:Initialize() if not success then return false, "Failed to initialize character object: " .. message2 end

    if not self:AddToList(username, character) then
        return false, "Failed to add character to list."
    end

    if not self:AddToCache(character:GetUID(), character) then
        self:RemoveFromList(username)
        return false, "Failed to add character to cache."
    end

    return character
end

--! \brief Add a character to the active character list.
--! \param username \string The player's username.
--! \param character \table The character object to add.
--! \return \table \boolean The added character object or false if failed.
function FrameworkZ.Characters:AddToList(username, character)
    if not username or not character then return false end

    self.List[username] = character
    return self.List[username]
end

--! \brief Remove a character from the active character list.
--! \param username \string The player's username.
--! \return \boolean Whether the character was successfully removed.
function FrameworkZ.Characters:RemoveFromList(username)
    if not username then return false end

    self.List[username] = nil
    return true
end

--! \brief Add a character to the UID cache.
--! \param uid \string The character's unique ID.
--! \param character \table The character object to add.
--! \return \table \boolean The added character object or false if failed.
function FrameworkZ.Characters:AddToCache(uid, character)
    if not uid or not character then return false end

    self.Cache[uid] = character
    return self.Cache[uid]
end

--! \brief Remove a character from the UID cache.
--! \param uid \string The character's unique ID.
--! \return \boolean Whether the character was successfully removed.
function FrameworkZ.Characters:RemoveFromCache(uid)
    if not uid then return false end

    self.Cache[uid] = nil
    return true
end

--! \brief Gets the user's loaded character by their ID.
--! \param username \string The player's username to get their character object with.
--! \return \table The character object from the list of characters.
function FrameworkZ.Characters:GetCharacterByID(username)
    local character = self.List[username] or nil

    return character
end

--! \brief Gets a character by their unique ID.
--! \param uid \string The character's unique ID.
--! \return \table The character object from the cache or nil if not found.
function FrameworkZ.Characters:GetCharacterByUID(uid)
    local character = self.Cache[uid] or nil

    return character
end

--! \brief Gets a character's inventory by their username.
--! \param username \string The player's username.
--! \return \table The character's inventory object or nil if not found.
function FrameworkZ.Characters:GetCharacterInventoryByID(username)
    local character = self:GetCharacterByID(username)

    if character then
        return character:GetInventory()
    end

    return nil
end

--! \brief Saves the user's currently loaded character.
--! \param username \string The player's username to get their loaded character from.
--! \return \boolean Whether or not the character was successfully saved.
function FrameworkZ.Characters:Save(username)
    if not username then return false end

    local character = self:GetCharacterByID(username)

    if character then
        local ok = character:Save()
        -- Additionally ensure the characters map is updated in storage to avoid stale cache overwriting on reconnect
        local player = FrameworkZ.Players:GetPlayerByID(username)
        if ok and player then
            local isoPlayer = player:GetIsoPlayer()
            local charactersMap = player:GetCharacters() or {}
            local entry = charactersMap[character:GetID()] or {}
            local savedData, _ = FrameworkZ.CharacterDataManager:SaveCharacterData(character)
            if savedData then
                FrameworkZ.Utilities:MergeTables(entry, savedData)
                charactersMap[character:GetID()] = entry
                FrameworkZ.Foundation:SetData(isoPlayer, "Characters", username, charactersMap)
            end
        end
        return ok
    end

    return false
end

--! \brief Character pre-load hook. Called before character loading begins.
function CHARACTER:OnPreLoad()
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPreLoad", self)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterPreLoad")

--! \brief Character load hook. Called during character loading.
function CHARACTER:OnLoad()
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterLoad", self)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterLoad")

--! \brief Character post-load hook. Called after character loading is complete.
--! \param firstLoad \boolean Whether this is the first time loading this character.
function CHARACTER:OnPostLoad(firstLoad)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostLoad", self, firstLoad) -- Does not actually call anymore
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterPostLoad")

--! \brief Post-load callback function for character initialization.
--! \param data \table The data containing the IsoPlayer object.
--! \param characterData \table The character's stored data.
--! \return \table The initialized character object.
function FrameworkZ.Characters.PostLoad(data, characterData)
    return FrameworkZ.Characters:OnPostLoad(data.isoPlayer, characterData)
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Characters.PostLoad", FrameworkZ.Characters.PostLoad)

--! \brief Initializes a player's character after loading.
--! \param isoPlayer \table The IsoPlayer object.
--! \param characterData \table The character's stored data.
--! \return \table The initialized character object.
function FrameworkZ.Characters:OnPostLoad(isoPlayer, characterData)
    local username = isoPlayer:getUsername()
    local player = FrameworkZ.Players:GetPlayerByID(username)
    local character = FrameworkZ.Characters:New(username, characterData.META_ID)

    if not player or not character then return false end

    character:OnPreLoad()

    character.IsoPlayer = isoPlayer
    character:RestoreData(characterData)

    -- Use centralized inventory system for restoration
    local restoreSuccess, restoreMessage = FrameworkZ.Inventories:Restore(character, characterData)
    if restoreSuccess then
        print("[FrameworkZ] Character inventory restored: " .. restoreMessage)
    else
        print("[FrameworkZ] Warning: Character inventory restoration issues: " .. (restoreMessage or "Unknown error"))
    end

    -- Restore character position and direction
    if characterData.POSITION_X and characterData.POSITION_Y and characterData.POSITION_Z then
        isoPlayer:setX(characterData.POSITION_X)
        isoPlayer:setY(characterData.POSITION_Y)
        isoPlayer:setZ(characterData.POSITION_Z)
        print("[FrameworkZ] Character position restored")
    end

    if characterData.DIRECTION_ANGLE then
        isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
    end

    -- Restore character stats
    local getStats = isoPlayer:getStats()
    if characterData.STAT_HUNGER then getStats:setHunger(characterData.STAT_HUNGER) end
    if characterData.STAT_THIRST then getStats:setThirst(characterData.STAT_THIRST) end
    if characterData.STAT_FATIGUE then getStats:setFatigue(characterData.STAT_FATIGUE) end
    if characterData.STAT_STRESS then getStats:setStress(characterData.STAT_STRESS) end
    if characterData.STAT_PAIN then getStats:setPain(characterData.STAT_PAIN) end
    if characterData.STAT_PANIC then getStats:setPanic(characterData.STAT_PANIC) end
    if characterData.STAT_BOREDOM then getStats:setBoredom(characterData.STAT_BOREDOM) end
    if characterData.STAT_DRUNKENNESS then getStats:setDrunkenness(characterData.STAT_DRUNKENNESS) end
    if characterData.STAT_ENDURANCE then getStats:setEndurance(characterData.STAT_ENDURANCE) end
    print("[FrameworkZ] Character stats restored")

    character:Initialize()
    character:OnLoad()

    player:SetCharacter(character)
    self.Cache[characterData[FZ_ENUM_CHARACTER_META_UID]] = character
    character:SetUID(characterData[FZ_ENUM_CHARACTER_META_UID])

    return character
end

if isClient() then
    local currentSaveTick = 0

    --! \brief Player tick function for handling character auto-save on client.
    --! \param player \table The player object to process.
    function FrameworkZ.Characters:PlayerTick(player)
        if currentSaveTick >= FrameworkZ.Config.Options.TicksUntilCharacterSave then
            local success, message = FrameworkZ.Players:Save(player:GetUsername())

            if success then
                if FrameworkZ.Config.Options.ShouldNotifyOnCharacterSave then
                    FrameworkZ.Notifications:AddToQueue("Saved player and character data.", FrameworkZ.Notifications.Types.Success)
                end
            else
                FrameworkZ.Notifications:AddToQueue(message, FrameworkZ.Notifications.Types.Danger)
            end

            currentSaveTick = 0
        end

        currentSaveTick = currentSaveTick + 1
    end
end

--! \brief Storage set event handler for character data.
--! \param isoPlayer \table The IsoPlayer object.
--! \param command \string The command type.
--! \param namespace \string The data namespace.
--! \param keys \string The data keys.
--! \param value \table The data value.
function FrameworkZ.Characters:OnStorageSet(isoPlayer, command, namespace, keys, value)
    if namespace == "Characters" then
        if command == "Initialize" then
            local username = keys
            local data = value
            local player = FrameworkZ.Players:GetPlayerByID(username) if not player then return end

            if data then
                player:SetCharacters(data)
            end
        end
    end
end

--! \brief Initialize global mod data for the Characters module.
function FrameworkZ.Characters:OnInitGlobalModData()
    FrameworkZ.Foundation:RegisterNamespace("Characters")
end

--! \brief Reference to the CHARACTER metatable for external access.
FrameworkZ.Characters.MetaObject = CHARACTER

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Characters)
