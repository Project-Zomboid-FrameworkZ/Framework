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

--! \brief Default character data template for new character creation.
FrameworkZ.Characters.DefaultCharacterData = {
    -- Meta information
    [FZ_ENUM_CHARACTER_META_ID] = nil,
    [FZ_ENUM_CHARACTER_META_UID] = nil,
    [FZ_ENUM_CHARACTER_META_FIRST_LOAD] = true,
    [FZ_ENUM_CHARACTER_META_RECOGNIZES] = {},
    
    -- Basic info
    [FZ_ENUM_CHARACTER_INFO_NAME] = "",
    [FZ_ENUM_CHARACTER_INFO_DESCRIPTION] = "",
    [FZ_ENUM_CHARACTER_INFO_FACTION] = "",
    [FZ_ENUM_CHARACTER_INFO_AGE] = 25,
    [FZ_ENUM_CHARACTER_INFO_HEIGHT] = "Average",
    [FZ_ENUM_CHARACTER_INFO_WEIGHT] = "Average",
    [FZ_ENUM_CHARACTER_INFO_PHYSIQUE] = "Average",
    
    -- Appearance
    [FZ_ENUM_CHARACTER_INFO_GENDER] = "Male",
    [FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] = SKIN_COLOR_WHITE,
    [FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = "",
    [FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = {r = 0.3, g = 0.2, b = 0.2},
    [FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = "",
    [FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = {r = 0.3, g = 0.2, b = 0.2},
    [FZ_ENUM_CHARACTER_INFO_EYE_COLOR] = {r = 0.2, g = 0.4, b = 0.6},
    
    -- Equipment slots
    [FZ_ENUM_EQUIPMENT_SLOT_HAT] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_MASK] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_EARS] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_BACK] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_HANDS] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_TSHIRT] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_SHIRT] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_TORSO_EXTRA_VEST] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_BELT] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_PANTS] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_SOCKS] = nil,
    [FZ_ENUM_EQUIPMENT_SLOT_SHOES] = nil,
    
    -- Inventory data
    [FZ_ENUM_CHARACTER_INVENTORY_PHYSICAL] = {},
    [FZ_ENUM_CHARACTER_INVENTORY_LOGICAL] = {},
    [FZ_ENUM_CHARACTER_INFO_EQUIPMENT] = {},
    
    -- Position and stats
    [FZ_ENUM_CHARACTER_META_POSITION_X] = nil,
    [FZ_ENUM_CHARACTER_META_POSITION_Y] = nil,
    [FZ_ENUM_CHARACTER_META_POSITION_Z] = nil,
    [FZ_ENUM_CHARACTER_META_POSITION_ANGLE] = nil,
    
    -- Character stats
    [FZ_ENUM_CHARACTER_STAT_HUNGER] = nil,
    [FZ_ENUM_CHARACTER_STAT_THIRST] = nil,
    [FZ_ENUM_CHARACTER_STAT_FATIGUE] = nil,
    [FZ_ENUM_CHARACTER_STAT_STRESS] = nil,
    [FZ_ENUM_CHARACTER_STAT_PAIN] = nil,
    [FZ_ENUM_CHARACTER_STAT_PANIC] = nil,
    [FZ_ENUM_CHARACTER_STAT_BOREDOM] = nil,
    [FZ_ENUM_CHARACTER_STAT_DRUNKENNESS] = nil,
    [FZ_ENUM_CHARACTER_STAT_ENDURANCE] = nil
}

FrameworkZ.Characters = FrameworkZ.Foundation:NewModule(FrameworkZ.Characters, "Characters")

--! \brief Character class for FrameworkZ.
--! \class CHARACTER
local CHARACTER = {}
CHARACTER.__index = CHARACTER

--! \brief Save the character's data from the character object.
--! \param callback \function Optional callback function(success, message) called when save completes.
--! \return \boolean Whether or not the character was successfully saved.
function CHARACTER:Save(callback)
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then 
        if callback then callback(false, "Missing Iso Player.") end
        return false, "Missing Iso Player." 
    end
    local player = FrameworkZ.Players:GetPlayerByID(isoPlayer:getUsername())

    if not player then 
        if callback then callback(false, "Missing player.") end
        return false, "Missing player." 
    end
    FrameworkZ.Players:ResetCharacterSaveInterval()

    -- Sync all current data from isoPlayer before saving
    self:Sync()
    
    -- Get saveable data with filtered properties
    local characterData = self:GetSaveableData()
    if not characterData then 
        if callback then callback(false, "Failed to get saveable data.") end
        return false, "Failed to get saveable data." 
    end
    
    -- Save to database with callback for server confirmation
    FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {isoPlayer:getUsername(), self:GetID()}, characterData, nil, nil, function(success, message)
        print("[FrameworkZ] Character data save " .. (success and "confirmed" or "failed: " .. (message or "Unknown error")))
        if callback then 
            callback(success, message or (success and "Character saved successfully" or "Save failed"))
        end
    end)
    
    -- Return immediately for non-callback callers (legacy support)
    return true, "Character save initiated"

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

    --[[
    local characters = player:GetCharacters()

    FrameworkZ.Utilities:MergeTables(characters[self.ID], characterData)

    FrameworkZ.Foundation:SetData(isoPlayer, "Characters", {isoPlayer:getUsername(), self.ID}, characters[self.ID])

    return true
    --]]
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

function CHARACTER:GetFirstLoad() return self[FZ_ENUM_CHARACTER_META_FIRST_LOAD] end
function CHARACTER:SetFirstLoad(firstLoad) self[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = firstLoad end

--! \brief Get the character's gender.
--! \return \string The character's gender.
function CHARACTER:GetGender() return self.Gender end
--! \brief Set the character's gender.
--! \param gender \string The gender to set.
function CHARACTER:SetGender(gender) self.Gender = gender end

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

--! \brief Get the character's name.
--! \return \string The character's name.
function CHARACTER:GetName() return self.Name end
--! \brief Set the character's name.
--! \param name \string The name to set.
function CHARACTER:SetName(name) self.Name = name end

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

--! \brief Get the character's hunger stat.
--! \return \number The character's hunger level.
function CHARACTER:GetHunger()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getHunger() end
    return self.Hunger
end
--! \brief Set the character's hunger stat.
--! \param hunger \number The hunger level to set.
function CHARACTER:SetHunger(hunger)
    self.Hunger = hunger
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setHunger(hunger) end
end

--! \brief Get the character's thirst stat.
--! \return \number The character's thirst level.
function CHARACTER:GetThirst()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getThirst() end
    return self.Thirst
end
--! \brief Set the character's thirst stat.
--! \param thirst \number The thirst level to set.
function CHARACTER:SetThirst(thirst)
    self.Thirst = thirst
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setThirst(thirst) end
end

--! \brief Get the character's fatigue stat.
--! \return \number The character's fatigue level.
function CHARACTER:GetFatigue()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getFatigue() end
    return self.Fatigue
end
--! \brief Set the character's fatigue stat.
--! \param fatigue \number The fatigue level to set.
function CHARACTER:SetFatigue(fatigue)
    self.Fatigue = fatigue
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setFatigue(fatigue) end
end

--! \brief Get the character's stress stat.
--! \return \number The character's stress level.
function CHARACTER:GetStress()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getStress() end
    return self.Stress
end
--! \brief Set the character's stress stat.
--! \param stress \number The stress level to set.
function CHARACTER:SetStress(stress)
    self.Stress = stress
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setStress(stress) end
end

--! \brief Get the character's pain stat.
--! \return \number The character's pain level.
function CHARACTER:GetPain()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getPain() end
    return self.Pain
end
--! \brief Set the character's pain stat.
--! \param pain \number The pain level to set.
function CHARACTER:SetPain(pain)
    self.Pain = pain
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setPain(pain) end
end

--! \brief Get the character's panic stat.
--! \return \number The character's panic level.
function CHARACTER:GetPanic()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getPanic() end
    return self.Panic
end
--! \brief Set the character's panic stat.
--! \param panic \number The panic level to set.
function CHARACTER:SetPanic(panic)
    self.Panic = panic
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setPanic(panic) end
end

--! \brief Get the character's boredom stat.
--! \return \number The character's boredom level.
function CHARACTER:GetBoredom()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getBoredom() end
    return self.Boredom
end
--! \brief Set the character's boredom stat.
--! \param boredom \number The boredom level to set.
function CHARACTER:SetBoredom(boredom)
    self.Boredom = boredom
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setBoredom(boredom) end
end

--! \brief Get the character's drunkenness stat.
--! \return \number The character's drunkenness level.
function CHARACTER:GetDrunkenness()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getDrunkenness() end
    return self.Drunkenness
end
--! \brief Set the character's drunkenness stat.
--! \param drunkenness \number The drunkenness level to set.
function CHARACTER:SetDrunkenness(drunkenness)
    self.Drunkenness = drunkenness
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setDrunkenness(drunkenness) end
end

--! \brief Get the character's endurance stat.
--! \return \number The character's endurance level.
function CHARACTER:GetEndurance()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getStats():getEndurance() end
    return self.Endurance
end
--! \brief Set the character's endurance stat.
--! \param endurance \number The endurance level to set.
function CHARACTER:SetEndurance(endurance)
    self.Endurance = endurance
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getStats():setEndurance(endurance) end
end

--! \brief Get the character's overall body health.
--! \return \number The character's overall body health.
function CHARACTER:GetHealth()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getOverallBodyHealth() end
    return self.Health
end
--! \brief Set the character's overall body health.
--! \param health \number The health level to set.
function CHARACTER:SetHealth(health)
    self.Health = health
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setOverallBodyHealth(health) end
end

--! \brief Get the character's body temperature.
--! \return \number The character's body temperature.
function CHARACTER:GetTemperature()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getTemperature() end
    return self.Temperature
end
--! \brief Set the character's body temperature.
--! \param temperature \number The temperature to set.
function CHARACTER:SetTemperature(temperature)
    self.Temperature = temperature
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setTemperature(temperature) end
end

--! \brief Get the character's wetness level.
--! \return \number The character's wetness level.
function CHARACTER:GetWetness()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getWetness() end
    return self.Wetness
end
--! \brief Set the character's wetness level.
--! \param wetness \number The wetness level to set.
function CHARACTER:SetWetness(wetness)
    self.Wetness = wetness
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setWetness(wetness) end
end

--! \brief Get the character's sickness level.
--! \return \number The character's sickness level.
function CHARACTER:GetSickness()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getFoodSicknessLevel() end
    return self.Sickness
end
--! \brief Set the character's sickness level.
--! \param sickness \number The sickness level to set.
function CHARACTER:SetSickness(sickness)
    self.Sickness = sickness
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setFoodSicknessLevel(sickness) end
end

--! \brief Get the character's cold strength.
--! \return \number The character's cold strength.
function CHARACTER:GetColdStrength()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getColdStrength() end
    return self.ColdStrength
end
--! \brief Set the character's cold strength.
--! \param coldStrength \number The cold strength to set.
function CHARACTER:SetColdStrength(coldStrength)
    self.ColdStrength = coldStrength
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setColdStrength(coldStrength) end
end

--! \brief Get whether the character has a cold.
--! \return \boolean Whether the character has a cold.
function CHARACTER:GetHasCold()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then return isoPlayer:getBodyDamage():getHasACold() end
    return self.HasCold or false
end
--! \brief Set whether the character has a cold.
--! \param hasCold \boolean Whether the character has a cold.
function CHARACTER:SetHasCold(hasCold)
    self.HasCold = hasCold
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then isoPlayer:getBodyDamage():setHasACold(hasCold) end
end

--! \brief Get the character's body part data.
--! \return \table The character's body part data.
function CHARACTER:GetBodyParts() return self.BodyParts end
--! \brief Set the character's body part data.
--! \param bodyParts \table The body part data to set.
function CHARACTER:SetBodyParts(bodyParts) self.BodyParts = bodyParts end

--! \brief Get and sync all character stats from isoPlayer.
--! \return \table The character's stats data.
function CHARACTER:GetStats()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then
        local stats = isoPlayer:getStats()
        self.Hunger = stats:getHunger()
        self.Thirst = stats:getThirst()
        self.Fatigue = stats:getFatigue()
        self.Stress = stats:getStress()
        self.Pain = stats:getPain()
        self.Panic = stats:getPanic()
        self.Boredom = stats:getBoredom()
        self.Drunkenness = stats:getDrunkenness()
        self.Endurance = stats:getEndurance()
    end
    return {
        [FZ_ENUM_CHARACTER_STAT_HUNGER] = self.Hunger,
        [FZ_ENUM_CHARACTER_STAT_THIRST] = self.Thirst,
        [FZ_ENUM_CHARACTER_STAT_FATIGUE] = self.Fatigue,
        [FZ_ENUM_CHARACTER_STAT_STRESS] = self.Stress,
        [FZ_ENUM_CHARACTER_STAT_PAIN] = self.Pain,
        [FZ_ENUM_CHARACTER_STAT_PANIC] = self.Panic,
        [FZ_ENUM_CHARACTER_STAT_BOREDOM] = self.Boredom,
        [FZ_ENUM_CHARACTER_STAT_DRUNKENNESS] = self.Drunkenness,
        [FZ_ENUM_CHARACTER_STAT_ENDURANCE] = self.Endurance
    }
end

--! \brief Get and sync all character health data from isoPlayer.
--! \return \table The character's health data.
function CHARACTER:GetAllHealth()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then
        local bodyDamage = isoPlayer:getBodyDamage()
        
        -- Sync overall health and environmental effects
        self.Health = bodyDamage:getOverallBodyHealth()
        self.Temperature = bodyDamage:getTemperature()
        self.Wetness = bodyDamage:getWetness()
        self.Sickness = bodyDamage:getFoodSicknessLevel()
        self.ColdStrength = bodyDamage:getColdStrength()
        self.HasCold = bodyDamage:isHasACold()
        
        -- Sync body parts data using proper iteration method
        local bodyPartsData = {}
        local bodyParts = bodyDamage:getBodyParts()
        for i = 1, bodyParts:size() do
            local bodyPart = bodyParts:get(i - 1)
            if bodyPart then
                local index = bodyPart:getIndex()
                bodyPartsData[index] = {
                    Health = bodyPart:getHealth(),
                    Bandaged = bodyPart:bandaged(),
                    BandageLife = bodyPart:getBandageLife(),
                    BandageType = bodyPart:getBandageType(),
                    Stitched = bodyPart:stitched(),
                    DeepWounded = bodyPart:deepWounded(),
                    Bitten = bodyPart:bitten(),
                    Scratched = bodyPart:scratched(),
                    Bleeding = bodyPart:bleeding(),
                    IsBurnt = bodyPart:isBurnt(),
                    BurnTime = bodyPart:getBurnTime(),
                    HaveBullet = bodyPart:haveBullet(),
                    IsCut = bodyPart:isCut(),
                    HaveGlass = bodyPart:haveGlass(),
                    BleedingStemmed = bodyPart:IsBleedingStemmed(),
                    Fractured = bodyPart:getFractureTime() > 0,
                    FractureTime = bodyPart:getFractureTime(),
                    Splinted = bodyPart:isSplint(),
                    SplintFactor = bodyPart:getSplintFactor(),
                    StitchTime = bodyPart:getStitchTime(),
                    AlcoholLevel = bodyPart:getAlcoholLevel(),
                    AdditionalPain = bodyPart:getAdditionalPain(false)
                }
            end
        end
        self.BodyParts = bodyPartsData
    end
    
    return {
        [FZ_ENUM_CHARACTER_HEALTH_OVERALL] = self.Health,
        [FZ_ENUM_CHARACTER_HEALTH_TEMPERATURE] = self.Temperature,
        [FZ_ENUM_CHARACTER_HEALTH_WETNESS] = self.Wetness,
        [FZ_ENUM_CHARACTER_HEALTH_SICKNESS] = self.Sickness,
        [FZ_ENUM_CHARACTER_HEALTH_COLD_STRENGTH] = self.ColdStrength,
        [FZ_ENUM_CHARACTER_HEALTH_HAS_COLD] = self.HasCold,
        [FZ_ENUM_CHARACTER_HEALTH_BODY_PARTS] = self.BodyParts
    }
end

--! \brief Get the character's skills/XP data.
--! \return \table The character's skills data.
function CHARACTER:GetSkills()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then
        local skillsData = {}
        local xpSystem = isoPlayer:getXp()
        local perkList = PerkFactory.PerkList
        
        for i = 0, perkList:size() - 1 do
            local perk = perkList:get(i)
            local perkName = tostring(perk)
            local level = isoPlayer:getPerkLevel(perk)
            local experience = xpSystem:getXP(perk)
            local experienceBoost = xpSystem:getPerkBoost(perk)
            
            skillsData[perkName] = {
                skill = perk,
                level = level,
                experience = experience,
                experienceBoost = experienceBoost
            }
        end
        
        self.Skills = skillsData
        return skillsData
    end
    return self.Skills or {}
end
--! \brief Set the character's skills/XP data.
--! \param skills \table The skills data to set.
function CHARACTER:SetSkills(skills) self.Skills = skills end

--! \brief Get the character's traits.
--! \return \table The character's traits.
function CHARACTER:GetTraits()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then
        local traitsData = {}
        local traits = isoPlayer:getTraits()
        for i = 0, traits:size() - 1 do
            table.insert(traitsData, traits:get(i))
        end
        self.Traits = traitsData
        return traitsData
    end
    return self.Traits or {}
end
--! \brief Set the character's traits.
--! \param traits \table The traits to set.
function CHARACTER:SetTraits(traits) self.Traits = traits end

--! \brief Get the character's perks (same as traits in PZ).
--! \return \table The character's perks.
function CHARACTER:GetPerks() return self:GetTraits() end
--! \brief Set the character's perks (same as traits in PZ).
--! \param perks \table The perks to set.
function CHARACTER:SetPerks(perks) self:SetTraits(perks) end

--! \brief Get and sync character equipment from isoPlayer.
--! Only extracts equipment slots (Hat, Shirt, Pants, etc.), not inventory contents.
--! \return \table The character's equipment data by slot.
function CHARACTER:GetEquipment()
    local fullInventoryData, message = FrameworkZ.Inventories:Save(self)
    if fullInventoryData then
        -- Equipment is now stored in Equipment sub-table
        local equipmentData = fullInventoryData.Equipment or {}
        
        -- Store equipment data
        self[FZ_ENUM_CHARACTER_INFO_EQUIPMENT] = equipmentData
        return equipmentData
    else
        print("[FrameworkZ] Warning: Failed to get equipment data: " .. (message or "Unknown error"))
        return self[FZ_ENUM_CHARACTER_INFO_EQUIPMENT] or {}
    end
end

--! \brief Set the character's equipment data.
--! \param equipment \table The equipment data to set.
function CHARACTER:SetEquipment(equipment) 
    self[FZ_ENUM_CHARACTER_INFO_EQUIPMENT] = equipment 
end

--! \brief Get and sync inventory contents from the character's Inventory object.
--! Delegates to the Inventory object's Save() method.
--! \return \table The inventory contents data with INVENTORY_LOGICAL and INVENTORY_PHYSICAL.
function CHARACTER:GetInventoryContents()
    local inventory = self:GetInventory()
    if inventory and inventory.Save then
        return inventory:Save()
    end
    return nil, "No inventory object available"
end


--! \brief Get and sync character position and direction from isoPlayer.
--! \return \table The character's position data.
function CHARACTER:GetPosition()
    local isoPlayer = self:GetIsoPlayer()
    if isoPlayer then
        -- Store using ENUM keys for consistent data format
        self[FZ_ENUM_CHARACTER_META_POSITION_X] = isoPlayer:getX()
        self[FZ_ENUM_CHARACTER_META_POSITION_Y] = isoPlayer:getY()
        self[FZ_ENUM_CHARACTER_META_POSITION_Z] = isoPlayer:getZ()
        self[FZ_ENUM_CHARACTER_META_POSITION_ANGLE] = isoPlayer:getDirectionAngle()
    end
    return {
        [FZ_ENUM_CHARACTER_META_POSITION_X] = self[FZ_ENUM_CHARACTER_META_POSITION_X],
        [FZ_ENUM_CHARACTER_META_POSITION_Y] = self[FZ_ENUM_CHARACTER_META_POSITION_Y],
        [FZ_ENUM_CHARACTER_META_POSITION_Z] = self[FZ_ENUM_CHARACTER_META_POSITION_Z],
        [FZ_ENUM_CHARACTER_META_POSITION_ANGLE] = self[FZ_ENUM_CHARACTER_META_POSITION_ANGLE]
    }
end

--! \brief Sync all character data from isoPlayer to CHARACTER object.
--! \brief Updates stats, health, skills, traits, equipment, inventory, and position from the game state.
function CHARACTER:Sync()
    self:GetStats()
    self:GetAllHealth()
    self:GetSkills()
    self:GetTraits()
    self:GetEquipment()           -- Sync worn items (Hat, Shirt, Pants, etc.)
    self:GetInventoryContents()   -- Sync inventory items (logical + physical)
    self:GetPosition()
end

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

--! \brief Restore this character from persisted data and attach it to the owning player.
--! \param callback \function Callback(characterData|false, message) invoked when restore completes.
--! \return \boolean Success flag.
--! \return \string Status or error message.
function CHARACTER:Restore(callback)
    local username = self:GetPlayer():GetUsername()
    local characterID = self:GetID()
    local player = FrameworkZ.Players:GetPlayerByID(username) if not player then callback(false, "Player not found.") return false, "Player not found." end

    local dataCallback = function(characterData, message)
        if not characterData then
            callback(false, "Failed to get character data: " .. message)

            return false, message
        end

        -- Is this the first load?
        local firstLoad = characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD]

        -- Hook call
        FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterRestore", self, characterData, firstLoad)

        -- Lookup saved position
        local x = not firstLoad and characterData[FZ_ENUM_CHARACTER_META_POSITION_X] or FrameworkZ.Config:GetOption("SpawnX")
        local y = not firstLoad and characterData[FZ_ENUM_CHARACTER_META_POSITION_Y] or FrameworkZ.Config:GetOption("SpawnY")
        local z = not firstLoad and characterData[FZ_ENUM_CHARACTER_META_POSITION_Z] or FrameworkZ.Config:GetOption("SpawnZ")

        -- Restoration processes
        local success, restoreDataMessage = self:RestoreData(characterData) if not success then callback(false, "Failed to restore character data: " .. restoreDataMessage) return false, restoreDataMessage end
        local success2, restoreStatsMessage = self:RestoreStats(characterData) if not success2 then callback(false, "Failed to restore character stats: " .. restoreStatsMessage) return false, restoreStatsMessage end
        local success3, restoreModelMessage = self:RestoreModel(characterData, true) if not success3 then callback(false, "Failed to restore character model: " .. restoreModelMessage) return false, restoreModelMessage end
        local success4, restoreInventoryMessage = self:RestoreInventory(characterData) if not success4 then callback(false, "Failed to restore character inventory: " .. restoreInventoryMessage) return false, restoreInventoryMessage end
        local success5, restoreEquipmentMessage = self:RestoreEquipment(characterData) if not success5 then callback(false, "Failed to restore character equipment: " .. restoreEquipmentMessage) return false, restoreEquipmentMessage end
        local success6, restorePositionMessage = self:RestorePosition(x, y, z, characterData[FZ_ENUM_CHARACTER_META_POSITION_ANGLE]) if not success6 then callback(false, "Failed to restore character position: " .. restorePositionMessage) return false, restorePositionMessage end
        local success7, restoreHealthMessage = self:RestoreHealth(characterData) if not success7 then callback(false, "Failed to restore character health: " .. restoreHealthMessage) return false, restoreHealthMessage end
        local success8, restoreSkillsMessage = self:RestoreSkills(characterData) if not success8 then callback(false, "Failed to restore character skills: " .. restoreSkillsMessage) return false, restoreSkillsMessage end
        local success9, restoreTraitsMessage = self:RestoreTraits(characterData) if not success9 then callback(false, "Failed to restore character traits: " .. restoreTraitsMessage) return false, restoreTraitsMessage end

        -- Temporary hook injection for calling after spawn protection has been removed (since its restorations aren't retained while godmoded/invincible)
        local function temporaryHook(character)
            if character:GetUID() == self:GetUID() then
                character:RestoreStats(characterData)
                character:RestoreHealth(characterData)

                -- Unregister after use to prevent memory leaks
                FrameworkZ.Foundation:UnregisterHandler("OnCharacterSpawned", temporaryHook, nil, nil, HOOK_CATEGORY_MODULE)
            end
        end

        FrameworkZ.Foundation:RegisterHandler("OnCharacterSpawned", temporaryHook, nil, nil, HOOK_CATEGORY_MODULE)

        -- Recognize self
        if not self:RecognizesCharacter(self) then
            local successfullyRecognizes, recognizeMessage = self:AddRecognition(self) if not successfullyRecognizes then callback(false, "Failed to add self to recognition list: " .. recognizeMessage) return false, recognizeMessage end
        end

        -- Set character to player
        player:SetCharacter(self)

        -- Cache character by UID
        if not FrameworkZ.Characters:AddToCache(self:GetUID(), self) then
            FrameworkZ.Characters:RemoveFromList(username)
            callback(false, "Failed to add character to cache.")
            return false, "Failed to add character to cache."
        end

        -- Hook call
        FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterRestored", self, firstLoad)

        -- First load complete, mark first load as false for future loads
        if self:GetFirstLoad() then
            self:SetFirstLoad(false)
        end

        callback(self, "Character restored.")
        return self, "Character restored."
    end

    return player:GetCharacterDataByID(characterID, dataCallback)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterRestore")
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterRestored")

--! \brief Used for restoring character data from a table, typically a table gathered through the FZ Data Storage system.
--! \param characterData \table (Optional) The character data table to restore from.
function CHARACTER:RestoreData(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Iso Player not found." end

    self:SetAge(characterData[FZ_ENUM_CHARACTER_INFO_AGE])
    self:SetBeardColor(characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR])
    self:SetBeardStyle(characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE])
    self:SetDescription(characterData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION])
    self:SetEyeColor(characterData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR])
    self:SetFaction(characterData[FZ_ENUM_CHARACTER_INFO_FACTION])
    self:SetGender(characterData[FZ_ENUM_CHARACTER_INFO_GENDER])
    self:SetHairColor(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR])
    self:SetHairStyle(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE])
    self:SetHeight(characterData[FZ_ENUM_CHARACTER_INFO_HEIGHT])
    self:SetID(characterData[FZ_ENUM_CHARACTER_META_ID])
    self:SetName(characterData[FZ_ENUM_CHARACTER_INFO_NAME])
    self:SetPhysique(characterData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE])
    self:SetRecognizes(characterData[FZ_ENUM_CHARACTER_META_RECOGNIZES] or {})
    self:SetSkinColor(characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR])
    self:SetUID(characterData[FZ_ENUM_CHARACTER_META_UID])
    self:SetWeight(characterData[FZ_ENUM_CHARACTER_INFO_WEIGHT])

    local descriptor = isoPlayer:getDescriptor()
    descriptor:setForename(self:GetName())
    descriptor:setSurname("")

    return true, "Character data restored."
end

--! \brief Restore logical/physical inventory (not worn equipment) from saved character data.
--! \param characterData \table Character data payload containing INVENTORY_LOGICAL and INVENTORY_PHYSICAL.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreInventory(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end

    -- Build inventory data with only logical and physical inventory
    local inventoryData = {
        INVENTORY_LOGICAL = characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL],
        INVENTORY_PHYSICAL = characterData[FZ_ENUM_CHARACTER_INVENTORY_PHYSICAL]
    }
    
    -- Use FrameworkZ.Inventories:Restore for inventory restoration (NOT equipment)
    local success, message = FrameworkZ.Inventories:Restore(self, inventoryData)
    
    if not success then
        print("[FrameworkZ] Warning: Inventories.Restore failed: " .. (message or "Unknown error") .. ". Using fallback.")
        
        -- Fallback: legacy rebuild approach for logical inventory
        local logicalData = characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL]
        if logicalData then
            local newInventory = FrameworkZ.Inventories:New(self:GetUsername())
            local _success, _message, rebuiltInventory = FrameworkZ.Inventories:Rebuild(self:GetIsoPlayer(), newInventory, logicalData)
            self:SetInventory(rebuiltInventory or FrameworkZ.Inventories:New(self:GetUsername()))

            if self:GetInventory() then
                self:SetInventoryID(self:GetInventory().id)
                self:GetInventory():Initialize()
            end
        end
    end

    return true, "Character inventory restored."
end

--! \brief Restore worn equipment from saved character data.
--! \param characterData \table Character data payload containing equipment info.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreEquipment(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end

    local equipmentData = characterData[FZ_ENUM_CHARACTER_INFO_EQUIPMENT]
    
    if not equipmentData then
        return true, "No equipment data to restore."
    end
    
    self:SetEquipment(equipmentData)
    
    -- Build inventoryData structure that Inventories:RestoreEquipment expects
    local inventoryData = {
        Equipment = equipmentData
    }
    
    -- Delegate actual equipment restoration to Inventories module
    local success, message = FrameworkZ.Inventories:RestoreEquipment(self, inventoryData)
    
    if success then
        return true, "Equipment restored successfully."
    else
        return false, "Equipment restoration failed: " .. (message or "Unknown error")
    end
end

--! \brief Restore visual model (gender, skin, hair, beard) from saved character data.
--! \param characterData \table Character data payload used to rebuild visuals.
--! \param reset \boolean? Whether to call isoPlayer:resetModel() after applying visuals.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreModel(characterData, reset)
    if not characterData then return false, "Character data not supplied in parameters." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Iso Player not found." end

    -- Clear model first
    isoPlayer:clearWornItems()
    isoPlayer:getInventory():clear()

    -- Set gender
    local humanVisual = isoPlayer:getHumanVisual()
    local isFemale = (self:GetGender() == "Female")
    isoPlayer:setFemale(isFemale)
    isoPlayer:getDescriptor():setFemale(isFemale)

    -- Set skin color
    local rawSkin = characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
    local skinIdx = (type(rawSkin) == "number") and rawSkin or SKIN_COLOR_WHITE
    humanVisual:setSkinTextureIndex(skinIdx)
    
    -- Set hair
    humanVisual:setHairModel(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE])

    -- Set hair color
    local hairColor = characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
    local immutableColor = ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1)
    humanVisual:setHairColor(immutableColor)
    humanVisual:setNaturalHairColor(immutableColor)

    -- Set beard
    local beardStyle = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
    if beardStyle == "" or beardStyle == "None" or not beardStyle then
        humanVisual:setBeardModel("")
    else
        humanVisual:setBeardModel(beardStyle)
        
        -- Only set beard color if there's actually a beard
        local beardColor = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]
        if beardColor then
            local beardImmutableColor = ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1)
            humanVisual:setBeardColor(beardImmutableColor)
            humanVisual:setNaturalBeardColor(beardImmutableColor)
        end
    end

    -- Reset model to apply changes
    if reset then isoPlayer:resetModel() end

    return true, "Character model restored."
end

--! \brief Restore world position and facing direction.
--! \param x \number X coordinate.
--! \param y \number Y coordinate.
--! \param z \number Z level.
--! \param angles \number? Facing direction angle.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestorePosition(x, y, z, angles)
    if not x or not y or not z then return false, "Invalid position coordinates." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "IsoPlayer not found." end

    isoPlayer:setX(x)
    isoPlayer:setY(y)
    isoPlayer:setZ(z)
    isoPlayer:setLx(x)
    isoPlayer:setLy(y)
    isoPlayer:setLz(z)

    if angles then
        isoPlayer:setDirectionAngle(angles)
    end

    return true, "Position restored."
end

--! \brief Restore high-level moodle/stat values (hunger, thirst, fatigue, etc.).
--! \param characterData \table Character data payload containing STAT_* fields.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreStats(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end

    if characterData[FZ_ENUM_CHARACTER_STAT_BOREDOM] then self:SetBoredom(characterData[FZ_ENUM_CHARACTER_STAT_BOREDOM]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_DRUNKENNESS] then self:SetDrunkenness(characterData[FZ_ENUM_CHARACTER_STAT_DRUNKENNESS]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_ENDURANCE] then self:SetEndurance(characterData[FZ_ENUM_CHARACTER_STAT_ENDURANCE]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_FATIGUE] then self:SetFatigue(characterData[FZ_ENUM_CHARACTER_STAT_FATIGUE]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_HUNGER] then self:SetHunger(characterData[FZ_ENUM_CHARACTER_STAT_HUNGER]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_PAIN] then self:SetPain(characterData[FZ_ENUM_CHARACTER_STAT_PAIN]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_PANIC] then self:SetPanic(characterData[FZ_ENUM_CHARACTER_STAT_PANIC]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_STRESS] then self:SetStress(characterData[FZ_ENUM_CHARACTER_STAT_STRESS]) end
    if characterData[FZ_ENUM_CHARACTER_STAT_THIRST] then self:SetThirst(characterData[FZ_ENUM_CHARACTER_STAT_THIRST]) end

    return true, "Character stats restored."
end

--! \brief Restore health values, environmental effects, and body part states.
--! \param characterData \table Character data payload containing health fields/body part data.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreHealth(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Iso Player not found." end
    local bodyDamage = isoPlayer:getBodyDamage() if not bodyDamage then return false, "Body damage not found." end

    -- Restore overall health
    if characterData[FZ_ENUM_CHARACTER_HEALTH_OVERALL] then
        self:SetHealth(characterData[FZ_ENUM_CHARACTER_HEALTH_OVERALL])
    end

    -- Restore environmental/status effects
    if characterData[FZ_ENUM_CHARACTER_HEALTH_TEMPERATURE] then self:SetTemperature(characterData[FZ_ENUM_CHARACTER_HEALTH_TEMPERATURE]) end
    if characterData[FZ_ENUM_CHARACTER_HEALTH_WETNESS] then self:SetWetness(characterData[FZ_ENUM_CHARACTER_HEALTH_WETNESS]) end
    if characterData[FZ_ENUM_CHARACTER_HEALTH_SICKNESS] then self:SetSickness(characterData[FZ_ENUM_CHARACTER_HEALTH_SICKNESS]) end
    if characterData[FZ_ENUM_CHARACTER_HEALTH_COLD_STRENGTH] then self:SetColdStrength(characterData[FZ_ENUM_CHARACTER_HEALTH_COLD_STRENGTH]) end
    if characterData[FZ_ENUM_CHARACTER_HEALTH_HAS_COLD] ~= nil then self:SetHasCold(characterData[FZ_ENUM_CHARACTER_HEALTH_HAS_COLD]) end

    -- Restore body parts data (injuries, bandages, etc.)
    local bodyPartsData = characterData[FZ_ENUM_CHARACTER_HEALTH_BODY_PARTS]
    if bodyPartsData then
        self:SetBodyParts(bodyPartsData)
        
        -- Iterate through each body part and restore its state
        for bodyPartType, partData in pairs(bodyPartsData) do
            local bodyPart = bodyDamage:getBodyPart(BodyPartType[bodyPartType])
            if bodyPart then
                -- Restore health
                if partData.Health then bodyPart:SetHealth(partData.Health) end
                
                -- Restore scratched state
                if partData.Scratched ~= nil then bodyPart:setScratched(partData.Scratched, false) end
                
                -- Restore deep wounded state
                if partData.DeepWounded ~= nil then bodyPart:setDeepWounded(partData.DeepWounded) end
                
                -- Restore stitched state
                if partData.Stitched ~= nil then bodyPart:setStitched(partData.Stitched) end
                
                -- Restore bitten state
                if partData.Bitten ~= nil then bodyPart:SetBitten(partData.Bitten) end
                
                -- Restore bleeding state
                if partData.Bleeding ~= nil then bodyPart:setBleeding(partData.Bleeding) end
                
                -- Restore burnt state (setBurnTime handles burn state automatically)
                if partData.BurnTime then bodyPart:setBurnTime(partData.BurnTime) end
                
                -- Restore bullet/cut/glass state
                if partData.HaveBullet ~= nil then bodyPart:setHaveBullet(partData.HaveBullet, 0) end
                if partData.IsCut ~= nil then bodyPart:setCut(partData.IsCut) end
                if partData.HaveGlass ~= nil then bodyPart:setHaveGlass(partData.HaveGlass) end
                
                -- Restore bleeding stemmed state
                if partData.BleedingStemmed ~= nil then bodyPart:SetBleedingStemmed(partData.BleedingStemmed) end
                
                -- Restore fracture state
                if partData.FractureTime then bodyPart:setFractureTime(partData.FractureTime) end
                
                -- Restore stitch/alcohol/splint state
                if partData.StitchTime then bodyPart:setStitchTime(partData.StitchTime) end
                if partData.AlcoholLevel then bodyPart:setAlcoholLevel(partData.AlcoholLevel) end
                if partData.SplintFactor then bodyPart:setSplintFactor(partData.SplintFactor) end
                if partData.Splinted and partData.SplintItem then bodyPart:setSplintItem(partData.SplintItem) end
                
                -- Restore bandage state (should be last to preserve bandage on injuries)
                if partData.Bandaged ~= nil then 
                    bodyPart:setBandaged(partData.Bandaged, partData.BandageLife or 0, false, partData.BandageType or nil) 
                end
                
                -- Restore additional pain
                if partData.AdditionalPain then bodyPart:setAdditionalPain(partData.AdditionalPain) end
            end
        end
    end

    return true, "Character health restored."
end

--! \brief Restore skills/XP levels from saved data.
--! \param characterData \table Character data payload containing XP/skills table.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreSkills(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Iso Player not found." end
    local skillsData = characterData[FZ_ENUM_CHARACTER_XP_SKILLS] if not skillsData then return true, "No skills data to restore." end

    self:SetSkills(skillsData)

    local xpSystem = isoPlayer:getXp()

    -- Restore each skill's level and XP using the fzRespawn pattern
    for perkName, xpData in pairs(skillsData) do
        if type(xpData) == "table" and Perks[perkName] then
            local perk = Perks[perkName]
            local experience = tonumber(xpData.xp) or 0

            -- Reset skill to 0 first
            xpSystem:setXPToLevel(perk, 0)
            isoPlayer:setPerkLevelDebug(perk, 0)

            -- Add all XP at once (this will naturally level up the character)
            -- Last parameter true = add silently without notifications
            if experience > 0 then
                xpSystem:AddXP(perk, experience, false, false, true)
            end
        end
    end

    return true, "Character skills restored."
end

--! \brief Restore trait list to the IsoPlayer and character object.
--! \param characterData \table Character data payload containing trait array.
--! \return \boolean Success flag.
--! \return \string Descriptive message.
function CHARACTER:RestoreTraits(characterData)
    if not characterData then return false, "Character data not supplied in parameters." end
    local isoPlayer = self:GetIsoPlayer() if not isoPlayer then return false, "Iso Player not found." end
    local traitsData = characterData[FZ_ENUM_CHARACTER_TRAITS] if not traitsData then return true, "No traits data to restore." end
    
    self:SetTraits(traitsData)
    
    -- Clear all existing traits first
    local existingTraits = isoPlayer:getTraits()
    existingTraits:clear()
    
    -- Restore each trait
    for _, traitName in ipairs(traitsData) do
        existingTraits:add(traitName)
    end
    
    return true, "Character traits restored."
end

--! \brief Initialize a character.
--! \return \boolean \string Whether initialization was successful and a message.
function CHARACTER:Initialize(callback)
	if not self:GetIsoPlayer() then return false, "IsoPlayer not set." end

    local success, message = self:Restore(callback) if not success then return false, "Failed to restore character: " .. message end

    return true, "Character initialized started."
end

--! \brief Process character creation data from UI into complete character data structure.
--! \param creationData \table Data from character creation interfaces.
--! \param player \object PLAYER object for UID generation.
--! \return \table|\boolean Complete character data structure or false if processing failed.
--! \return \string Error message if processing failed.
function FrameworkZ.Characters:ProcessCreationData(creationData, player)
    if not creationData then
        return nil, "Missing creation data"
    end
    
    -- Start with template
    local characterData = FrameworkZ.Utilities:CopyTable(self.DefaultCharacterData)
    
    -- Fill in basic information
    characterData[FZ_ENUM_CHARACTER_INFO_NAME] = creationData[FZ_ENUM_CHARACTER_INFO_NAME] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION] = creationData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_FACTION] = creationData[FZ_ENUM_CHARACTER_INFO_FACTION] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_AGE] = creationData[FZ_ENUM_CHARACTER_INFO_AGE] or 25
    characterData[FZ_ENUM_CHARACTER_INFO_HEIGHT] = creationData[FZ_ENUM_CHARACTER_INFO_HEIGHT] or "Average"
    characterData[FZ_ENUM_CHARACTER_INFO_WEIGHT] = creationData[FZ_ENUM_CHARACTER_INFO_WEIGHT] or "Average"
    characterData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE] = creationData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE] or "Average"
    
    -- Fill in appearance data
    characterData[FZ_ENUM_CHARACTER_INFO_GENDER] = creationData[FZ_ENUM_CHARACTER_INFO_GENDER] or "Male"
    -- Normalize skin color: must be a numeric texture index
    local rawSkin = creationData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
    characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] = (type(rawSkin) == "number") and rawSkin or SKIN_COLOR_WHITE
    characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = creationData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or {r = 0.3, g = 0.2, b = 0.2}
    characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = creationData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] or creationData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or {r = 0.3, g = 0.2, b = 0.2}
    characterData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] or {r = 0.2, g = 0.4, b = 0.6}
    
    -- Process equipment data from appearance customization
    characterData[FZ_ENUM_CHARACTER_INFO_EQUIPMENT] = creationData[FZ_ENUM_CHARACTER_INFO_EQUIPMENT] or {}
    
    -- Initialize default faction items
    if characterData[FZ_ENUM_CHARACTER_INFO_FACTION] then
        local faction = FrameworkZ.Factions:GetFactionByID(characterData[FZ_ENUM_CHARACTER_INFO_FACTION])
        if faction and faction.items then
            for uniqueID, quantity in pairs(faction.items) do
                -- Add to logical inventory
                if not characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL] then
                    characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL] = {}
                end
                characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL][uniqueID] = (characterData[FZ_ENUM_CHARACTER_INVENTORY_LOGICAL][uniqueID] or 0) + quantity
            end
        end
    end
    
    -- Generate unique identifiers - use player's UID generation if available
    if player and player.GenerateUID then
        characterData[FZ_ENUM_CHARACTER_META_UID] = player:GenerateUID()
    else
        return false, "Failed to generate unique ID."
    end
    
    return characterData
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
function FrameworkZ.Characters:Initialize(isoPlayer, id, callback)
    local character, message = FrameworkZ.Characters:New(isoPlayer, id) if not character then return false, "Could not create new character object, " .. message end
    local characterInstance = self:AddToList(character:GetUsername(), character) if not characterInstance then return false, "Failed to add character to list." end
    local success, message2 = characterInstance:Initialize(callback) if not success then return false, "Failed to initialize character object: " .. message2 end

    return characterInstance, "Character preemptively initialized and added to system."
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
    local message = "Character found in active list."

    if not character then message = "Character not found in active list." end

    return character, message
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
        local ok, message = character:Save()
        -- Additionally ensure the characters map is updated in storage to avoid stale cache overwriting on reconnect
        local player = FrameworkZ.Players:GetPlayerByID(username)
        if ok and player then
            local isoPlayer = player:GetIsoPlayer()
            local charactersMap = player:GetCharacters() or {}
            local entry = charactersMap[character:GetID()] or {}
            -- Get saved data directly from character (already synced by Save())
            local savedData = character:GetSaveableData()
            if savedData then
                FrameworkZ.Utilities:MergeTables(entry, savedData)
                charactersMap[character:GetID()] = entry
                FrameworkZ.Foundation:SetData(isoPlayer, "Characters", username, charactersMap)
            end
        end
        return ok, message
    end

    return false, "Character not found."
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
    --[[
    local restoreSuccess, restoreMessage = FrameworkZ.Inventories:Restore(character, characterData)
    if restoreSuccess then
        print("[FrameworkZ] Character inventory restored: " .. restoreMessage)
    else
        print("[FrameworkZ] Warning: Character inventory restoration issues: " .. (restoreMessage or "Unknown error"))
    end
    --]]

    -- Restore character position and direction
    --[[
    if characterData.POSITION_X and characterData.POSITION_Y and characterData.POSITION_Z then
        isoPlayer:setX(characterData.POSITION_X)
        isoPlayer:setY(characterData.POSITION_Y)
        isoPlayer:setZ(characterData.POSITION_Z)
        print("[FrameworkZ] Character position restored")
    end

    if characterData.DIRECTION_ANGLE then
        isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
    end
    --]]

    --[[ Restore character stats - Now handled by RestoreStats function in Restore()
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
    --]]

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
        if currentSaveTick >= FrameworkZ.Config:GetOption("TicksUntilCharacterSave") then
            local success, message = FrameworkZ.Players:Save(player:GetUsername())

            if success then
                if FrameworkZ.Config:GetOption("ShouldNotifyOnCharacterSave") then
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
