--! \page Features
--! \section CharacterDataManager Character Data Manager
--! Centralized system for managing all character data from creation to spawning.
--! Consolidates character appearance, inventory, equipment, and state management
--! into a single, coherent system that maintains data integrity throughout
--! the character lifecycle.

FrameworkZ = FrameworkZ or {}

--! \brief Centralized character data manager for FrameworkZ
--! \library FrameworkZ.DataManager
FrameworkZ.CharacterDataManager = {}

-- Data structure templates for consistency
FrameworkZ.CharacterDataManager.Templates = {
    -- Base character data structure
    CharacterData = {
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
        
        -- Equipment slots with comprehensive data
        [FZ_ENUM_CHARACTER_SLOT_HAT] = nil,
        [FZ_ENUM_CHARACTER_SLOT_MASK] = nil,
        [FZ_ENUM_CHARACTER_SLOT_EARS] = nil,
        [FZ_ENUM_CHARACTER_SLOT_BACK] = nil,
        [FZ_ENUM_CHARACTER_SLOT_HANDS] = nil,
        [FZ_ENUM_CHARACTER_SLOT_TSHIRT] = nil,
        [FZ_ENUM_CHARACTER_SLOT_SHIRT] = nil,
        [FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA_VEST] = nil,
        [FZ_ENUM_CHARACTER_SLOT_BELT] = nil,
        [FZ_ENUM_CHARACTER_SLOT_PANTS] = nil,
        [FZ_ENUM_CHARACTER_SLOT_SOCKS] = nil,
        [FZ_ENUM_CHARACTER_SLOT_SHOES] = nil,
        
        -- Inventory data
        INVENTORY_PHYSICAL = {},
        INVENTORY_LOGICAL = {},
        EQUIPPED_ITEMS = {},
        
        -- Position and stats
        POSITION_X = nil,
        POSITION_Y = nil,
        POSITION_Z = nil,
        DIRECTION_ANGLE = nil,
        
        -- Character stats
        STAT_HUNGER = nil,
        STAT_THIRST = nil,
        STAT_FATIGUE = nil,
        STAT_STRESS = nil,
        STAT_PAIN = nil,
        STAT_PANIC = nil,
        STAT_BOREDOM = nil,
        STAT_DRUNKENNESS = nil,
        STAT_ENDURANCE = nil
    },
    
    -- Equipment item data structure with full details
    EquipmentItem = {
        id = "",
        color = nil,
        condition = nil,
        maxCondition = nil,
        modData = {},
        customProperties = {}
    }
}

-- Registry for data validation and transformation
FrameworkZ.CharacterDataManager.Validators = {}
FrameworkZ.CharacterDataManager.Transformers = {}

FrameworkZ.CharacterDataManager = FrameworkZ.Foundation:NewModule(FrameworkZ.CharacterDataManager, "CharacterDataManager")

--! \brief Create a new character data structure from creation UI
--! \param creationData \table Data from character creation interfaces
--! \param player \table (Optional) Player object for UID generation
--! \return \table Complete character data structure
function FrameworkZ.CharacterDataManager:CreateCharacterData(creationData, player)
    if not creationData then
        return nil, "Missing creation data"
    end
    
    -- Start with template
    local characterData = FrameworkZ.Utilities:CopyTable(self.Templates.CharacterData)
    
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
    -- Normalize skin color coming from UI: must be a numeric texture index
    do
        local rawSkin = creationData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
        characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] = (type(rawSkin) == "number") and rawSkin or SKIN_COLOR_WHITE
    end
    characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = creationData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or {r = 0.3, g = 0.2, b = 0.2}
    characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = creationData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] or ""
    characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] or creationData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or {r = 0.3, g = 0.2, b = 0.2}
    characterData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] = creationData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] or {r = 0.2, g = 0.4, b = 0.6}
    
    -- Process equipment data from appearance customization
    if creationData.selectedClothingWithData then
        for slotEnum, equipmentData in pairs(creationData.selectedClothingWithData) do
            if equipmentData and equipmentData.id and equipmentData.id ~= "" and equipmentData.id ~= "None" then
                -- Equipment data already contains all necessary properties (id, color, condition, etc.)
                characterData[slotEnum] = equipmentData
            end
        end
    end
    
    -- Initialize default faction items
    if characterData[FZ_ENUM_CHARACTER_INFO_FACTION] then
        local faction = FrameworkZ.Factions:GetFactionByID(characterData[FZ_ENUM_CHARACTER_INFO_FACTION])
        if faction and faction.items then
            for uniqueID, quantity in pairs(faction.items) do
                self:AddItemToLogicalInventory(characterData, uniqueID, quantity)
            end
        end
    end
    
    -- Generate unique identifiers - use player's UID generation if available
    if player and player.GenerateUID then
        characterData[FZ_ENUM_CHARACTER_META_UID] = player:GenerateUID()
    else
        return false, "Failed to generate unique ID."
    end
    
    return characterData, "Character data created successfully"
end

--! \brief Save complete character data including all systems
--! \param character \table The character object
--! \return \table Complete character data for persistence
function FrameworkZ.CharacterDataManager:SaveCharacterData(character)
    if not character then
        return nil, "Missing character parameter"
    end
    
    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return nil, "Character has no IsoPlayer"
    end
    
    -- Create character data with proper FZ_ENUM structure (matching what RestoreData expects)
    local characterData = {}

    -- Pull any previously stored data as a fallback so we don't overwrite user-entered fields
    local prevData = nil
    if character.GetData then
        pcall(function() prevData = character:GetData() end)
    end
    prevData = prevData or character.data or character.CharacterData or {}

    -- Descriptor and visuals (authoritative for some fields)
    local desc = isoPlayer.getDescriptor and isoPlayer:getDescriptor() or nil
    local hv = isoPlayer.getHumanVisual and isoPlayer:getHumanVisual() or nil

    -- Basic character information
    local fallbackName = "Unknown"
    if desc and desc.getForename and desc.getSurname then
        local f, s = desc:getForename() or "", desc:getSurname() or ""
        local full = (f .. " " .. s):gsub("^%s+", ""):gsub("%s+$", "")
        if full ~= "" then fallbackName = full end
    end
    local getOr = function(val, alt)
        if val ~= nil then return val end
        return alt
    end
    characterData[FZ_ENUM_CHARACTER_INFO_NAME] = getOr((character.GetName and character:GetName()) or character.Name, prevData[FZ_ENUM_CHARACTER_INFO_NAME] or fallbackName)
    characterData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION] = getOr((character.GetDescription and character:GetDescription()) or character.Description, prevData[FZ_ENUM_CHARACTER_INFO_DESCRIPTION] or "")
    characterData[FZ_ENUM_CHARACTER_INFO_FACTION] = getOr((character.GetFaction and character:GetFaction()) or character.Faction, prevData[FZ_ENUM_CHARACTER_INFO_FACTION] or "")
    characterData[FZ_ENUM_CHARACTER_INFO_AGE] = getOr((character.GetAge and character:GetAge()) or character.Age, prevData[FZ_ENUM_CHARACTER_INFO_AGE] or 25)
    characterData[FZ_ENUM_CHARACTER_INFO_HEIGHT] = getOr((character.GetHeight and character:GetHeight()) or character.Height, prevData[FZ_ENUM_CHARACTER_INFO_HEIGHT] or -1)
    characterData[FZ_ENUM_CHARACTER_INFO_WEIGHT] = getOr((character.GetWeight and character:GetWeight()) or character.Weight, prevData[FZ_ENUM_CHARACTER_INFO_WEIGHT] or -1)
    characterData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE] = getOr((character.GetPhysique and character:GetPhysique()) or character.Physique, prevData[FZ_ENUM_CHARACTER_INFO_PHYSIQUE] or "")

    -- Gender from IsoPlayer if possible
    local isFemale = (isoPlayer.isFemale and isoPlayer:isFemale()) or (desc and desc.isFemale and desc:isFemale()) or (prevData[FZ_ENUM_CHARACTER_INFO_GENDER] == "Female")
    characterData[FZ_ENUM_CHARACTER_INFO_GENDER] = isFemale and "Female" or "Male"

    -- Eye color: keep previous if we don't have an engine value
    characterData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] = getOr((character.GetEyeColor and character:GetEyeColor()) or character.EyeColor, prevData[FZ_ENUM_CHARACTER_INFO_EYE_COLOR] or {r = 0.2, g = 0.4, b = 0.6})

    -- Appearance data from HumanVisual when available
    if hv and hv.getHairModel then
        characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = hv:getHairModel() or prevData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] or "Bald"
    else
        characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = (character.appearance and character.appearance.hair) or prevData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] or "Bald"
    end
    if hv and hv.getBeardModel then
        local bm = hv:getBeardModel()
        characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = (bm and bm ~= "") and bm or (prevData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] or "None")
    else
        characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = (character.appearance and character.appearance.beard) or prevData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] or "None"
    end

    -- Colors
    do
        -- Hair color
        local hc = nil
        if hv and hv.getNaturalHairColor then hc = hv:getNaturalHairColor() end
        if not hc and hv and hv.getHairColor then hc = hv:getHairColor() end
        if hc and hc.getRedFloat then
            characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = { r = hc:getRedFloat(), g = hc:getGreenFloat(), b = hc:getBlueFloat() }
        else
            characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = (character.appearance and character.appearance.hairColor) or prevData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or {r = 0.5, g = 0.3, b = 0.1}
        end

        -- Beard color mirrors hair if not explicitly set
        local bc = nil
        if hv and hv.getNaturalBeardColor then bc = hv:getNaturalBeardColor() end
        if not bc and hv and hv.getBeardColor then bc = hv:getBeardColor() end
        if bc and bc.getRedFloat then
            characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = { r = bc:getRedFloat(), g = bc:getGreenFloat(), b = bc:getBlueFloat() }
        else
            characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = (character.appearance and character.appearance.beardColor) or prevData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] or characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
        end

        -- Skin color is an index
        local skinIndex = (hv and hv.getSkinTextureIndex and hv:getSkinTextureIndex()) or prevData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] or SKIN_COLOR_WHITE
        if type(skinIndex) ~= "number" then skinIndex = SKIN_COLOR_WHITE end
        characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] = skinIndex
    end
    
    -- Meta data
    characterData[FZ_ENUM_CHARACTER_META_ID] = getOr((character.GetID and character:GetID()) or character.ID or character.id, prevData[FZ_ENUM_CHARACTER_META_ID])
    characterData[FZ_ENUM_CHARACTER_META_UID] = getOr((character.GetUID and character:GetUID()) or character.UID or character.uid, prevData[FZ_ENUM_CHARACTER_META_UID])
    characterData[FZ_ENUM_CHARACTER_META_RECOGNIZES] = getOr((character.GetRecognizes and character:GetRecognizes()) or character.recognizes, prevData[FZ_ENUM_CHARACTER_META_RECOGNIZES] or {})
    characterData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] = getOr(character.firstLoad, prevData[FZ_ENUM_CHARACTER_META_FIRST_LOAD] or false)
    
    -- Save comprehensive inventory and equipment data
    local inventoryData, inventoryMessage = self:SaveInventoryData(character)
    if inventoryData then
        -- Merge inventory data into character data
        for key, value in pairs(inventoryData) do
            characterData[key] = value
        end
        
        -- Also save equipment items in FZ_ENUM format for compatibility
        if inventoryData.EQUIPPED_ITEMS then
            for slotEnum, itemData in pairs(inventoryData.EQUIPPED_ITEMS) do
                characterData[slotEnum] = itemData
            end
        end
    else
        print("[CharacterDataManager] Warning: Failed to save inventory data: " .. (inventoryMessage or "Unknown error"))
    end
    
    -- Save position and direction
    characterData.POSITION_X = isoPlayer:getX()
    characterData.POSITION_Y = isoPlayer:getY()
    characterData.POSITION_Z = isoPlayer:getZ()
    characterData.DIRECTION_ANGLE = isoPlayer:getDirectionAngle()
    
    -- Save character stats
    local stats = isoPlayer:getStats()
    characterData.STAT_HUNGER = stats:getHunger()
    characterData.STAT_THIRST = stats:getThirst()
    characterData.STAT_FATIGUE = stats:getFatigue()
    characterData.STAT_STRESS = stats:getStress()
    characterData.STAT_PAIN = stats:getPain()
    characterData.STAT_PANIC = stats:getPanic()
    characterData.STAT_BOREDOM = stats:getBoredom()
    characterData.STAT_DRUNKENNESS = stats:getDrunkenness()
    characterData.STAT_ENDURANCE = stats:getEndurance()
    
    return characterData, "Character data saved successfully"
end

--! \brief Restore complete character data during loading/spawning
--! \param character \table The character object
--! \param characterData \table Saved character data
--! \return \boolean Whether restoration was successful
function FrameworkZ.CharacterDataManager:RestoreCharacterData(character, characterData)
    if not character or not characterData then
        return false, "Missing character or characterData parameter"
    end
    
    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return false, "Character has no IsoPlayer"
    end
    
    local messages = {}
    local success = true
    
    -- Clear existing data
    isoPlayer:clearWornItems()
    isoPlayer:getInventory():clear()
    
    -- Restore basic character properties
    character:RestoreData(characterData)
    table.insert(messages, "Basic character data restored")
    
    -- Restore appearance on IsoPlayer
    local appearanceSuccess, appearanceMessage = self:RestoreCharacterAppearance(isoPlayer, characterData)
    if appearanceSuccess then
        table.insert(messages, appearanceMessage)
    else
        success = false
        table.insert(messages, "Appearance restoration failed: " .. (appearanceMessage or "Unknown error"))
    end
    
    -- Restore inventory and equipment
    local inventorySuccess, inventoryMessage = self:RestoreInventoryData(character, characterData)
    if inventorySuccess then
        table.insert(messages, inventoryMessage)
    else
        success = false
        table.insert(messages, "Inventory restoration failed: " .. (inventoryMessage or "Unknown error"))
    end
    
    -- Restore position and direction
    if characterData.POSITION_X and characterData.POSITION_Y and characterData.POSITION_Z then
        isoPlayer:setX(characterData.POSITION_X)
        isoPlayer:setY(characterData.POSITION_Y)
        isoPlayer:setZ(characterData.POSITION_Z)
        table.insert(messages, "Position restored")
    end
    
    if characterData.DIRECTION_ANGLE then
        isoPlayer:setDirectionAngle(characterData.DIRECTION_ANGLE)
    end
    
    -- Restore character stats
    local stats = isoPlayer:getStats()
    if characterData.STAT_HUNGER then stats:setHunger(characterData.STAT_HUNGER) end
    if characterData.STAT_THIRST then stats:setThirst(characterData.STAT_THIRST) end
    if characterData.STAT_FATIGUE then stats:setFatigue(characterData.STAT_FATIGUE) end
    if characterData.STAT_STRESS then stats:setStress(characterData.STAT_STRESS) end
    if characterData.STAT_PAIN then stats:setPain(characterData.STAT_PAIN) end
    if characterData.STAT_PANIC then stats:setPanic(characterData.STAT_PANIC) end
    if characterData.STAT_BOREDOM then stats:setBoredom(characterData.STAT_BOREDOM) end
    if characterData.STAT_DRUNKENNESS then stats:setDrunkenness(characterData.STAT_DRUNKENNESS) end
    if characterData.STAT_ENDURANCE then stats:setEndurance(characterData.STAT_ENDURANCE) end
    table.insert(messages, "Stats restored")
    
    return success, table.concat(messages, "; ")
end

--! \brief Restore character appearance on IsoPlayer
--! \param isoPlayer \table The IsoPlayer object
--! \param characterData \table Character data containing appearance info
--! \return \boolean Whether restoration was successful
function FrameworkZ.CharacterDataManager:RestoreCharacterAppearance(isoPlayer, characterData)
    if not isoPlayer or not characterData then
        return false, "Missing isoPlayer or characterData"
    end
    
    local humanVisual = isoPlayer:getHumanVisual()
    
    -- Set basic appearance
    local isFemale = (characterData[FZ_ENUM_CHARACTER_INFO_GENDER] == "Female")
    isoPlayer:setFemale(isFemale)
    if isoPlayer.getDescriptor and isoPlayer:getDescriptor() then
        isoPlayer:getDescriptor():setFemale(isFemale)
    end
    
    -- Set skin color
    do
        local rawSkin = characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
        local skinIdx = (type(rawSkin) == "number") and rawSkin or SKIN_COLOR_WHITE
        humanVisual:setSkinTextureIndex(skinIdx)
    end
    
    -- Set hair
    if characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] then
        humanVisual:setHairModel(characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE])
    end
    
    if characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] then
        local hairColor = characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
        local immutableColor = ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1)
        humanVisual:setHairColor(immutableColor)
        humanVisual:setNaturalHairColor(immutableColor)
    end
    
    -- Set beard
    if characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] then
        local beardStyle = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
        if beardStyle == "" or beardStyle == "None" then
            humanVisual:setBeardModel("")
        else
            humanVisual:setBeardModel(beardStyle)
        end
    end
    
    if characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] then
        local beardColor = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]
        local immutableColor = ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1)
        humanVisual:setBeardColor(immutableColor)
        humanVisual:setNaturalBeardColor(immutableColor)
    end
    
    -- Ensure the model updates after visual changes
    if isoPlayer.resetModel then
        isoPlayer:resetModel()
    end

    return true, "Character appearance restored"
end

--! \brief Save comprehensive inventory and equipment data
--! \param character \table The character object
--! \return \table Complete inventory data
function FrameworkZ.CharacterDataManager:SaveInventoryData(character)
    if not character then
        return nil, "Missing character parameter"
    end
    
    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return nil, "Character has no IsoPlayer"
    end
    
    local inventoryData = {}
    
    -- Save physical inventory items with comprehensive data
    local physicalItems = {}
    local inventory = isoPlayer:getInventory():getItems()
    
    for i = 0, inventory:size() - 1 do
        local item = inventory:get(i)
        if item and not item:getModData()["FZ_ITM"] then -- Non-FrameworkZ items
            local itemData = self:ExtractItemData(item)
            if itemData then
                table.insert(physicalItems, itemData)
            end
        end
    end
    inventoryData.INVENTORY_PHYSICAL = physicalItems
    
    -- Save logical inventory (FrameworkZ items)
    local logicalInventoryData = character:GetInventory() and character:GetInventory():GetSaveableData() or {}
    inventoryData.INVENTORY_LOGICAL = logicalInventoryData
    
    -- Save equipped items with full details for all slots
    local equippedItems = {}
    for slotEnum, slotName in pairs(FrameworkZ.Inventories.SlotLookup) do
        if slotName then
            local equippedItem = isoPlayer:getWornItem(slotName)
            if equippedItem then
                local itemData = self:ExtractItemData(equippedItem)
                if itemData then
                    equippedItems[slotEnum] = itemData
                end
            end
        end
    end
    inventoryData.EQUIPPED_ITEMS = equippedItems
    
    return inventoryData, "Inventory data saved successfully"
end

--! \brief Restore comprehensive inventory and equipment data
--! \param character \table The character object
--! \param characterData \table Character data containing inventory info
--! \return \boolean Whether restoration was successful
function FrameworkZ.CharacterDataManager:RestoreInventoryData(character, characterData)
    if not character or not characterData then
        return false, "Missing character or characterData parameter"
    end
    
    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return false, "Character has no IsoPlayer"
    end
    
    local messages = {}
    local success = true
    
    -- Build a multiset of items that are planned to be equipped so we can avoid adding
    -- duplicate physical copies of the same clothing back into the inventory.
    local plannedEquipCounts = {}
    local function bumpPlanned(id)
        if not id or id == "" then return end
        plannedEquipCounts[id] = (plannedEquipCounts[id] or 0) + 1
    end

    -- From preferred EQUIPPED_ITEMS save block
    if characterData.EQUIPPED_ITEMS then
        for _, itemData in pairs(characterData.EQUIPPED_ITEMS) do
            bumpPlanned(itemData and itemData.id)
        end
    end

    -- From legacy per-slot saved entries using SlotLookup keys
    if FrameworkZ and FrameworkZ.Inventories and FrameworkZ.Inventories.SlotLookup then
        for slotEnum, _ in pairs(FrameworkZ.Inventories.SlotLookup) do
            local entry = characterData[slotEnum]
            if entry and type(entry) == "table" then
                bumpPlanned(entry.id)
            elseif type(entry) == "string" then
                bumpPlanned(entry)
            end
        end
    end

    -- From creation-time EquipmentSlots keys (names like "Hat", "TShirt", etc.)
    do
        local equipmentSlots = FrameworkZ.Enumerations and FrameworkZ.Enumerations.EquipmentSlots or {}
        for _, slotKey in ipairs(equipmentSlots) do
            local entry = characterData[slotKey]
            if entry and type(entry) == "table" then
                bumpPlanned(entry.id)
            elseif type(entry) == "string" then
                bumpPlanned(entry)
            end
        end
    end

    -- Restore physical inventory, skipping one instance for each planned equipped item
    if characterData.INVENTORY_PHYSICAL then
        local skippedForEquip = 0
        local restoredPhysical = 0
        for _, itemData in pairs(characterData.INVENTORY_PHYSICAL) do
            local id = itemData.id
            local planned = id and plannedEquipCounts[id] or 0
            if planned and planned > 0 then
                -- Skip this copy; it will be recreated and worn from the equipped blocks
                plannedEquipCounts[id] = planned - 1
                skippedForEquip = skippedForEquip + 1
            else
                if id then
                    local restoredItem = isoPlayer:getInventory():AddItem(id)
                    if restoredItem then
                        self:RestoreItemData(restoredItem, itemData)
                        restoredPhysical = restoredPhysical + 1
                    end
                end
            end
        end
        table.insert(messages, string.format("Physical inventory restored (%d items, skipped %d worn-duplicates)", restoredPhysical, skippedForEquip))
    end
    
    -- Restore logical inventory (FrameworkZ items)
    if characterData.INVENTORY_LOGICAL then
    local newInventory = FrameworkZ.Inventories:New(isoPlayer:getUsername())
    local logicalItems = characterData.INVENTORY_LOGICAL and characterData.INVENTORY_LOGICAL.items or characterData.INVENTORY_LOGICAL
    local rebuildSuccess, rebuildMessage, rebuiltInventory = FrameworkZ.Inventories:Rebuild(isoPlayer, newInventory, logicalItems)
        
        if rebuildSuccess and rebuiltInventory then
            character:SetInventory(rebuiltInventory)
            character.InventoryID = rebuiltInventory.id
            rebuiltInventory:Initialize()
            table.insert(messages, "Logical inventory restored")
        else
            success = false
            table.insert(messages, "Failed to rebuild logical inventory: " .. (rebuildMessage or "Unknown error"))
        end
    end
    
    -- Helper: try to reuse an existing physical item of the same full type to avoid duplicates
    local function findInventoryItemByFullType(fullType)
        if not fullType then return nil end
        local items = isoPlayer:getInventory():getItems()
        if not items then return nil end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and it.getFullType and it:getFullType() == fullType then
                return it
            end
        end
        return nil
    end

    -- Restore equipped items (preferred full save path)
    if characterData.EQUIPPED_ITEMS then
        local restoredCount = 0
        for slotEnum, itemData in pairs(characterData.EQUIPPED_ITEMS) do
            local slotName = FrameworkZ.Inventories.SlotLookup[slotEnum]
            if slotName and itemData.id then
                local item = findInventoryItemByFullType(itemData.id)
                if not item then
                    item = InventoryItemFactory.CreateItem(itemData.id)
                    if item then
                        isoPlayer:getInventory():AddItem(item)
                    end
                end
                if item then
                    self:RestoreItemData(item, itemData)
                    isoPlayer:setWornItem(slotName, item)
                    restoredCount = restoredCount + 1
                end
            end
        end
        table.insert(messages, "Equipped items restored (" .. restoredCount .. " items)")
    end
    
    -- Also restore equipment from character data CharacterSlot keys for backward compatibility
    local legacyRestoredCount = 0
    for slotEnum, slotName in pairs(FrameworkZ.Inventories.SlotLookup) do
        if characterData[slotEnum] and characterData[slotEnum].id then
            local itemData = characterData[slotEnum]
            if not isoPlayer:getWornItem(slotName) then -- Don't overwrite if already restored
                local item = findInventoryItemByFullType(itemData.id)
                if not item then
                    item = InventoryItemFactory.CreateItem(itemData.id)
                    if item then
                        isoPlayer:getInventory():AddItem(item)
                    end
                end
                if item then
                    self:RestoreItemData(item, itemData)
                    isoPlayer:setWornItem(slotName, item)
                    legacyRestoredCount = legacyRestoredCount + 1
                end
            end
        end
    end
    if legacyRestoredCount > 0 then
        table.insert(messages, "Legacy equipment restored (" .. legacyRestoredCount .. " items)")
    end

    -- Finally, restore equipment using EquipmentSlots keys (creation-time keys)
    local equipmentSlots = FrameworkZ.Enumerations and FrameworkZ.Enumerations.EquipmentSlots or {}
    local createdRestoredCount = 0
    for _, slotKey in ipairs(equipmentSlots) do
        local entry = characterData[slotKey]
        if entry and entry.id then
            -- Create the item and use its inherent body location when possible
            local item = findInventoryItemByFullType(entry.id)
            if not item then
                item = InventoryItemFactory.CreateItem(entry.id)
                if item then isoPlayer:getInventory():AddItem(item) end
            end
            if item then
                self:RestoreItemData(item, entry)
                local bodyLoc = item.getBodyLocation and item:getBodyLocation() or slotKey
                if not isoPlayer:getWornItem(bodyLoc) then
                    isoPlayer:setWornItem(bodyLoc, item)
                    createdRestoredCount = createdRestoredCount + 1
                end
            end
        end
    end
    if createdRestoredCount > 0 then
        table.insert(messages, "Creation equipment restored (" .. createdRestoredCount .. " items)")
    end

    -- Refresh player model to reflect equipped clothing
    if isoPlayer.resetModel then
        isoPlayer:resetModel()
    end
    
    return success, table.concat(messages, "; ")
end

--! \brief Extract comprehensive item data for saving
--! \param item \table The inventory item
--! \return \table Item data with all properties
function FrameworkZ.CharacterDataManager:ExtractItemData(item)
    if not item then return nil end
    
    local itemData = {
        -- Use full type so we can recreate the exact item later (Module.ItemName)
        id = (item.getFullType and item:getFullType()) or item:getType(),
        name = item:getName(),
        condition = item:getCondition(),
        maxCondition = item:getConditionMax()
    }
    
    -- Visual properties (prefer clothing visual tint if present)
    local colorExtracted = false
    if item.getVisual and type(item.getVisual) == "function" then
        local vis = item:getVisual()
        if vis and vis.getTint then
            local tint = vis:getTint()
            if tint then
                itemData.color = { r = tint:getRedFloat(), g = tint:getGreenFloat(), b = tint:getBlueFloat() }
                colorExtracted = true
            end
        end
    end
    if not colorExtracted and item.getColor then
        local color = item:getColor()
        if color then
            itemData.color = { r = color:getRedFloat(), g = color:getGreenFloat(), b = color:getBlueFloat() }
        end
    end
    
    -- Clothing properties
    if item.isDirty and item:isDirty() then
        itemData.dirty = true
    end
    
    if item.isWet and item:isWet() then
        itemData.wet = true
        if item.getWetness then
            itemData.wetness = item:getWetness()
        end
    end
    
    if item.isBloody and item:isBloody() then
        itemData.bloody = true
        if item.getBloodLevel then
            itemData.bloodLevel = item:getBloodLevel()
        end
    end
    
    -- Weapon properties
    if item.getCurrentAmmoCount then
        itemData.currentAmmoCount = item:getCurrentAmmoCount()
    end
    
    if item.getMaxAmmo then
        itemData.maxAmmo = item:getMaxAmmo()
    end
    
    -- Food properties
    if item.isFrozen then
        itemData.frozen = item:isFrozen()
    end
    
    if item.getAge then
        itemData.age = item:getAge()
    end
    
    -- Container contents
    if item.getItems then
        local containerItems = item:getItems()
        if containerItems and containerItems:size() > 0 then
            itemData.containerItems = {}
            for i = 0, containerItems:size() - 1 do
                local containerItem = containerItems:get(i)
                if containerItem then
                    table.insert(itemData.containerItems, self:ExtractItemData(containerItem))
                end
            end
        end
    end
    
    -- Mod data
    local modData = item:getModData()
    if modData then
        local hasEntries = false
        for _ in pairs(modData) do
            hasEntries = true
            break
        end
        if hasEntries then
            itemData.modData = {}
            for key, value in pairs(modData) do
                itemData.modData[key] = value
            end
        end
    end
    
    -- Uses and durability
    if item.getUsedDelta then
        itemData.usedDelta = item:getUsedDelta()
    end
    
    if item.getUses then
        itemData.uses = item:getUses()
    end
    
    return itemData
end

--! \brief Restore comprehensive item data
--! \param item \table The inventory item
--! \param itemData \table Item data to restore
--! \return \boolean Whether restoration was successful
function FrameworkZ.CharacterDataManager:RestoreItemData(item, itemData)
    if not item or not itemData then return false end
    
    -- Restore basic properties
    if itemData.condition and item.setCondition then
        item:setCondition(itemData.condition)
    end
    
    if itemData.maxCondition and item.setConditionMax then
        item:setConditionMax(itemData.maxCondition)
    end
    
    -- Restore visual properties
    if itemData.color then
        local r = itemData.color.r or 1.0
        local g = itemData.color.g or 1.0
        local b = itemData.color.b or 1.0
        -- Prefer clothing visual tint path
        if item.getVisual and type(item.getVisual) == "function" then
            local vis = item:getVisual()
            if vis and vis.setTint then
                local immutableColor = ImmutableColor.new(r, g, b, 1)
                vis:setTint(immutableColor)
            end
        end
        -- Enable and set custom color when supported
        if item.setCustomColor then
            item:setCustomColor(true)
        end
        if item.setColor then
            local ColorObj = Color and Color.new or nil
            if ColorObj then
                item:setColor(ColorObj(r, g, b, 1))
            elseif item.setColorRed and item.setColorGreen and item.setColorBlue then
                item:setColorRed(r)
                item:setColorGreen(g)
                item:setColorBlue(b)
            end
        elseif item.setColorRed and item.setColorGreen and item.setColorBlue then
            item:setColorRed(r)
            item:setColorGreen(g)
            item:setColorBlue(b)
        end
    end
    
    -- Restore clothing properties
    if itemData.dirty and item.setDirty then
        item:setDirty(true)
    end
    
    if itemData.wet and item.setWet then
        item:setWet(true)
        if itemData.wetness and item.setWetness then
            item:setWetness(itemData.wetness)
        end
    end
    
    if itemData.bloody and item.setBloody then
        item:setBloody(true)
        if itemData.bloodLevel and item.setBloodLevel then
            item:setBloodLevel(itemData.bloodLevel)
        end
    end
    
    -- Restore weapon properties
    if itemData.currentAmmoCount and item.setCurrentAmmoCount then
        item:setCurrentAmmoCount(itemData.currentAmmoCount)
    end
    
    -- Restore food properties
    if itemData.frozen and item.setFrozen then
        item:setFrozen(itemData.frozen)
    end
    
    if itemData.age and item.setAge then
        item:setAge(itemData.age)
    end
    
    -- Restore container contents
    if itemData.containerItems and item.getItems then
        local containerInventory = item:getItems()
        if containerInventory then
            containerInventory:clear()
            for _, containerItemData in ipairs(itemData.containerItems) do
                local containerItem = containerInventory:AddItem(containerItemData.id)
                if containerItem then
                    self:RestoreItemData(containerItem, containerItemData)
                end
            end
        end
    end
    
    -- Restore mod data
    if itemData.modData then
        local modData = item:getModData()
        for key, value in pairs(itemData.modData) do
            modData[key] = value
        end
    end
    
    -- Restore uses and durability
    if itemData.usedDelta and item.setUsedDelta then
        item:setUsedDelta(itemData.usedDelta)
    end
    
    if itemData.uses and item.setUses then
        item:setUses(itemData.uses)
    end
    
    return true
end

--! \brief Add item to logical inventory during character creation
--! \param characterData \table Character data structure
--! \param uniqueID \string FrameworkZ item unique ID
--! \param quantity \integer Quantity to add
function FrameworkZ.CharacterDataManager:AddItemToLogicalInventory(characterData, uniqueID, quantity)
    if not characterData.INVENTORY_LOGICAL then
        characterData.INVENTORY_LOGICAL = {}
    end
    
    if not characterData.INVENTORY_LOGICAL.items then
        characterData.INVENTORY_LOGICAL.items = {}
    end
    
    -- Add or increment item quantity
    if characterData.INVENTORY_LOGICAL.items[uniqueID] then
        characterData.INVENTORY_LOGICAL.items[uniqueID] = characterData.INVENTORY_LOGICAL.items[uniqueID] + quantity
    else
        characterData.INVENTORY_LOGICAL.items[uniqueID] = quantity
    end
end

--! \brief Generate unique identifier
--! \return \string Unique ID
function FrameworkZ.CharacterDataManager:GenerateUID()
    return CreateUID()
end

--! \brief Deep copy a table
--! \param original \table Table to copy
--! \return \table Deep copy of the table
function FrameworkZ.CharacterDataManager:DeepCopy(original)
    if type(original) ~= 'table' then
        return original
    end
    
    -- Use FrameworkZ utility for table copying with deep copy and metatable support
    return FrameworkZ.Utilities:CopyTable(original, {}, true)
end

--! \brief Validate character data structure
--! \param characterData \table Character data to validate
--! \return \boolean Whether data is valid
function FrameworkZ.CharacterDataManager:ValidateCharacterData(characterData)
    if not characterData then return false, "Character data is nil" end
    
    -- Check required fields
    local requiredFields = {
        FZ_ENUM_CHARACTER_INFO_NAME,
        FZ_ENUM_CHARACTER_INFO_FACTION,
        FZ_ENUM_CHARACTER_INFO_GENDER
    }
    
    for _, field in ipairs(requiredFields) do
        if not characterData[field] then
            return false, "Missing required field: " .. tostring(field)
        end
    end
    
    return true, "Character data is valid"
end

--! \brief Restore character appearance to a SurvivorDesc object (for UI previews)
--! \param survivor \table The SurvivorDesc object
--! \param characterData \table The character data containing appearance info
--! \return \bool Success status
--! \return \string Message
function FrameworkZ.CharacterDataManager:RestoreSurvivorAppearance(survivor, characterData)
    if not survivor or not characterData then
        return false, "Missing survivor or characterData"
    end

    print("[RestoreSurvivorAppearance] Starting character restoration...")
    
    -- Debug: Print all character data keys
    print("[RestoreSurvivorAppearance] Character data keys:")
    for key, value in pairs(characterData) do
        if type(value) == "table" and value.id then
            print("  " .. tostring(key) .. ": equipment item " .. tostring(value.id))
        else
            print("  " .. tostring(key) .. ": " .. tostring(value))
        end
    end

    -- Clear all worn items first
    if FrameworkZ.Enumerations and FrameworkZ.Enumerations.EquipmentSlots then
        for k, v in ipairs(FrameworkZ.Enumerations.EquipmentSlots) do
            survivor:setWornItem(v, nil)
        end
    end

    local humanVisual = survivor:getHumanVisual()
    local template = self.Templates.CharacterData

    -- Set basic appearance
    local gender = characterData[FZ_ENUM_CHARACTER_INFO_GENDER] or template[FZ_ENUM_CHARACTER_INFO_GENDER]
    local isFemale = (gender == "Female")
    survivor:setFemale(isFemale)
    print("[RestoreSurvivorAppearance] Set gender: " .. tostring(gender) .. " (isFemale: " .. tostring(isFemale) .. ")")

    -- Set skin color
    do
        local rawSkin = characterData[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
        local skinColor = (type(rawSkin) == "number") and rawSkin or template[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
        if type(skinColor) ~= "number" then skinColor = SKIN_COLOR_WHITE end
        humanVisual:setSkinTextureIndex(skinColor)
        print("[RestoreSurvivorAppearance] Set skin color index: " .. tostring(skinColor))
    end

    -- Set hair
    local hairStyle = characterData[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] or template[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE]
    if hairStyle and hairStyle ~= "" then
        humanVisual:setHairModel(hairStyle)
        print("[RestoreSurvivorAppearance] Set hair style: " .. tostring(hairStyle))
    end

    local hairColor = characterData[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] or template[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
    if hairColor then
        local immutableColor = ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1)
        humanVisual:setHairColor(immutableColor)
        humanVisual:setNaturalHairColor(immutableColor)
        print("[RestoreSurvivorAppearance] Set hair color: r=" .. hairColor.r .. " g=" .. hairColor.g .. " b=" .. hairColor.b)
    end

    -- Set beard
    local beardStyle = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] or template[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
    if beardStyle and beardStyle ~= "" and beardStyle ~= "None" then
        humanVisual:setBeardModel(beardStyle)
        print("[RestoreSurvivorAppearance] Set beard style: " .. tostring(beardStyle))
    end

    local beardColor = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] or template[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]
    if beardColor then
        local immutableColor = ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1)
        humanVisual:setBeardColor(immutableColor)
        humanVisual:setNaturalBeardColor(immutableColor)
        print("[RestoreSurvivorAppearance] Set beard color: r=" .. beardColor.r .. " g=" .. beardColor.g .. " b=" .. beardColor.b)
    end

    -- Restore equipment - check multiple possible slot enumerations
    local equipmentSlots = FrameworkZ.Enumerations.EquipmentSlots or {}
    if not equipmentSlots or #equipmentSlots == 0 then
        -- Try alternative slot references
        equipmentSlots = {
            "Hat", "Mask", "Neck", "Shirt", "TShirt", "Sweater", "Jacket", "Hands",
            "Pants", "Skirt", "Socks", "Shoes", "Belt", "Back", "Weapon"
        }
    end
    
    print("[RestoreSurvivorAppearance] Checking equipment slots...")
    print("[RestoreSurvivorAppearance] Available equipment slots: " .. table.concat(equipmentSlots, ", "))
    
    -- Also check what keys actually exist in character data that might be equipment
    print("[RestoreSurvivorAppearance] Scanning character data for potential equipment keys:")
    for key, value in pairs(characterData) do
        if type(value) == "table" and value.id then
            print("  Found equipment-like entry: " .. tostring(key) .. " = " .. tostring(value.id))
        end
    end
    
    local restoredItems = 0
    
    -- Common aliasing between selection keys and survivor slots (defensive)
    local slotAliases = {
        Tshirt = {"Tshirt", "TShirt", "Undershirt"},
        Shirt = {"Shirt", "Overshirt", "Jacket", "FullTop"},
        Pants = {"Pants", "Dress", "Skirt"},
        Hat = {"Hat", "FullHat"},
        Mask = {"Mask", "MaskFull", "MaskEyes"},
        Neck = {"Neck", "Necklace", "Necklace_Long", "Scarf"},
        Hands = {"Hands", "HandsLeft", "HandsRight", "LeftWrist", "RightWrist"},
        Shoes = {"Shoes"},
        Socks = {"Socks"},
        Back = {"Back"}
    }

    local function findEntryForSlot(data, slot)
        -- exact key first
        if data[slot] then return slot, data[slot] end
        -- try aliases if known
        local aliases = slotAliases[slot]
        if aliases then
            for _, alt in ipairs(aliases) do
                if data[alt] then return alt, data[alt] end
            end
        end
        return nil, nil
    end

    for _, slotName in ipairs(equipmentSlots) do
        local actualKey, equipmentEntry = findEntryForSlot(characterData, slotName)
        if equipmentEntry then
            local itemID = nil
            local itemColor = nil
            local itemCondition = nil
            
            -- Handle both new format (table with id, color, etc.) and legacy format (simple itemID string)
            if type(equipmentEntry) == "table" then
                -- New format: equipment entry contains full data
                itemID = equipmentEntry.id
                itemColor = equipmentEntry.color
                itemCondition = equipmentEntry.condition
            else
                -- Legacy format: equipment entry is just the itemID
                itemID = equipmentEntry
            end
            
            if itemID and itemID ~= "" and itemID ~= "None" then
                print("[RestoreSurvivorAppearance] Restoring item for slot " .. slotName .. " (key: " .. tostring(actualKey or slotName) .. "): " .. itemID)
                -- Create the item
                local item = InventoryItemFactory.CreateItem(itemID)
                if item then
                    -- Apply color if available
                    if itemColor then
                        local r = itemColor.r or 1.0
                        local g = itemColor.g or 1.0
                        local b = itemColor.b or 1.0
                        local applied = false
                        -- Prefer visual tint for clothing
                        if item.getVisual and type(item.getVisual) == "function" then
                            local vis = item:getVisual()
                            if vis and vis.setTint then
                                vis:setTint(ImmutableColor.new(r, g, b, 1))
                                applied = true
                                print("[RestoreSurvivorAppearance] Applied visual tint to " .. itemID)
                            end
                        end
                        -- Also set custom color if supported
                        if item.setCustomColor then
                            item:setCustomColor(true)
                        end
                        if item.setColor then
                            if Color and Color.new then
                                item:setColor(Color.new(r, g, b, 1))
                                applied = true
                                print("[RestoreSurvivorAppearance] Applied Color to " .. itemID)
                            end
                        end
                        if not applied and item.setColorRed and item.setColorGreen and item.setColorBlue then
                            item:setColorRed(r)
                            item:setColorGreen(g)
                            item:setColorBlue(b)
                            print("[RestoreSurvivorAppearance] Applied RGB color to " .. itemID)
                        end
                    end
                    
                    -- Apply condition if available
                    if itemCondition and item.setCondition then
                        item:setCondition(itemCondition)
                    end

                    -- Add the item to the survivor's worn items
                    survivor:setWornItem(slotName, item)
                    restoredItems = restoredItems + 1
                    print("[RestoreSurvivorAppearance] Successfully equipped " .. itemID .. " to " .. slotName)
                else
                    print("[RestoreSurvivorAppearance] Failed to create item: " .. itemID)
                end
            end
        end
    end
    
    print("[RestoreSurvivorAppearance] Restored " .. restoredItems .. " equipment items")

    -- If beard is intentionally None, ensure it's cleared
    local beardStyleFinal = characterData[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
    if not beardStyleFinal or beardStyleFinal == "" or beardStyleFinal == "None" then
        humanVisual:setBeardModel("")
    end

    return survivor, "Survivor appearance and equipment restored"
end

-- Register the module
FrameworkZ.Foundation:RegisterModule(FrameworkZ.CharacterDataManager)

return FrameworkZ.CharacterDataManager
