--! \page Features
--! \section Inventories Inventories
--! Inventories are used to store items for characters, containers, vehicles, and other entities. Each inventory can hold multiple items, and each item can have its own unique properties and data.
--! An inventory object is broken down into two key elements: The logical inventory, and the "physical" inventory. A logical inventory is composed of items that are directly implemented with FrameworkZ. Whereas a physical inventory is composed of regular Project Zomboid items. These two distinctions were made to provide better organization and management of items within the game considering that not all items would be implemented into FrameworkZ.

--! \page Global Variables
--! \section Inventories Inventories
--! FrameworkZ.Inventories
--! See Inventories for the module on inventories.
--! FrameworkZ.Inventories.List
--! A list of all instanced inventories in the game.
--! FrameworkZ.Inventories.Types
--! The types of inventories that can be created.

FrameworkZ = FrameworkZ or {}

--! \brief The Inventories module for FrameworkZ. Defines and interacts with INVENTORY object.
--! \module FrameworkZ.Inventories
FrameworkZ.Inventories = {}
FrameworkZ.Inventories.List = {}
FrameworkZ.Inventories.Types = {
    Character = "Character",
    Container = "Container",
    Vehicle = "Vehicle"
}

local function tableHasEntries(tbl)
    if type(tbl) ~= "table" then return false end

    for _ in pairs(tbl) do
        return true
    end

    return false
end

-- O(1) lookup table for enum to slot name conversion - uses Characters.SlotList for proper PZ compatibility
-- Build SlotLookup using available data without relying on undefined FZ_SLOT_* globals.
-- Priority:
--  1) FrameworkZ.Characters.SlotList if provided elsewhere (full custom mapping)
--  2) Auto-map each enum to its own string value via FrameworkZ.Enumerations.EquipmentSlots
--     (since our enums resolve to Project Zomboid body location strings like "Hat", "Mask", etc.)
do
    local slotLookup = {}
    if FrameworkZ.Characters and FrameworkZ.Characters.SlotList and tableHasEntries(FrameworkZ.Characters.SlotList) then
        slotLookup = FrameworkZ.Characters.SlotList
    elseif FrameworkZ.Enumerations and FrameworkZ.Enumerations.EquipmentSlots then
        for _, slotName in ipairs(FrameworkZ.Enumerations.EquipmentSlots) do
            -- Enum values are strings (e.g., "Hat"); use identity mapping.
            slotLookup[slotName] = slotName
        end
    else
        -- Minimal safe fallback for a few common slots
        local defaults = { "Hat", "Mask", "Neck", "Tshirt", "Shirt", "Pants", "Socks", "Shoes", "Back", "Hands" }
        for _, slotName in ipairs(defaults) do
            slotLookup[slotName] = slotName
        end
    end
    FrameworkZ.Inventories.SlotLookup = slotLookup
end

-- O(1) reverse lookup table for slot name to enum conversion - uses proper FZ_SLOT constants
-- Build reverse lookup from the resolved SlotLookup
do
    local reverse = {}
    for enumKey, slotName in pairs(FrameworkZ.Inventories.SlotLookup) do
        reverse[slotName] = enumKey
    end
    FrameworkZ.Inventories.SlotNameLookup = reverse
end

-- O(1) lookup table for FrameworkZ item type checking - populated at runtime
FrameworkZ.Inventories.FrameworkZItemTypeLookup = {}

-- Initialize the FrameworkZ item lookup table for O(1) checks
local function initializeFrameworkZItemLookup()
    -- Clear existing lookup
    FrameworkZ.Inventories.FrameworkZItemTypeLookup = {}
    
    -- Populate from FrameworkZ.Items.List
    if FrameworkZ.Items and FrameworkZ.Items.List then
        for uniqueID, fzItem in pairs(FrameworkZ.Items.List) do
            if fzItem.itemID then
                FrameworkZ.Inventories.FrameworkZItemTypeLookup[fzItem.itemID] = uniqueID
            end
        end
    end
    
    -- Populate from FrameworkZ.Items.Bases
    if FrameworkZ.Items and FrameworkZ.Items.Bases then
        for uniqueID, fzItem in pairs(FrameworkZ.Items.Bases) do
            if fzItem.itemID then
                FrameworkZ.Inventories.FrameworkZItemTypeLookup[fzItem.itemID] = uniqueID
            end
        end
    end
end

-- Call initialization function when module loads (may be empty if items are registered later by plugins)
initializeFrameworkZItemLookup()

--! \brief Rebuild the FZ item type lookup table from all currently registered items.
--! Call this after all plugins have registered their items, or lazily before any lookup is used.
function FrameworkZ.Inventories:RefreshItemTypeLookup()
    initializeFrameworkZItemLookup()
end

-- Helper function to check if an item type is a FrameworkZ item - O(1) lookup
--! \brief Check if an item type is a FrameworkZ item (O(1) lookup)
--! \param itemType \string The full item type (e.g., "Base.Hat_Beanie")
--! \return \boolean True if it's a FrameworkZ item
function FrameworkZ.Inventories:IsFrameworkZItemType(itemType)
    return self.FrameworkZItemTypeLookup[itemType] ~= nil
end

-- Enhanced Item Data System
-- Comprehensive save/restore functionality for all item properties including:
-- - Basic properties (condition, max condition, weight)
-- - Visual properties (color/tint, blood level, dirt, wetness)
-- - Clothing properties (holes, patches, blood, dirt)
-- - Weapon properties (ammunition, magazine content, individual bullets)
-- - Food properties (freshness, age, frozen state, hunger/boredom values)
-- - Container properties (capacity, contents with recursive item data)
-- - Literature properties (pages, locks, writing)
-- - Mod data persistence
-- - Uses and remaining durability

--! \brief Extract basic item properties (condition, weight, uses)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractBasicProperties(item, itemData)
    if item.getCondition then itemData.condition = item:getCondition() end
    if item.getConditionMax then itemData.maxCondition = item:getConditionMax() end
    if item.getWeight then itemData.weight = item:getWeight() end
    if item.getActualWeight then itemData.actualWeight = item:getActualWeight() end
    if item.getUsedDelta then itemData.usedDelta = item:getUsedDelta() end
    if item.getUses then itemData.uses = item:getUses() end
end

--! \brief Extract color/tint information (prefers visual tint for clothing)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractColorData(item, itemData)
    -- Prefer visual tint for clothing items
    if item.getVisual and type(item.getVisual) == "function" then
        local vis = item:getVisual()
        local clothingItem = item.getClothingItem and item:getClothingItem() or nil

        if vis and vis.getDecal and type(vis.getDecal) == "function" then
            local decal = nil
            if clothingItem then
                local okDecal, resolvedDecal = pcall(function()
                    return vis:getDecal(clothingItem)
                end)
                if okDecal then decal = resolvedDecal end
            else
                local okDecal, resolvedDecal = pcall(function()
                    return vis:getDecal()
                end)
                if okDecal then decal = resolvedDecal end
            end
            if decal ~= nil then
                itemData.decal = (type(decal) == "string") and decal or tostring(decal)
            end
        end

        if vis and vis.getTint then
            local tint = nil
            if clothingItem then
                local okTint, resolvedTint = pcall(function()
                    return vis:getTint(clothingItem)
                end)
                if okTint then tint = resolvedTint end
            else
                local okTint, resolvedTint = pcall(function()
                    return vis:getTint()
                end)
                if okTint then tint = resolvedTint end
            end
            if tint and tint.getRedFloat and tint.getGreenFloat and tint.getBlueFloat then
                local r, g, b = tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat()
                -- Validate color values are numbers
                if type(r) == "number" and type(g) == "number" and type(b) == "number" then
                    itemData.color = {
                        r = r,
                        g = g,
                        b = b,
                        a = 1.0
                    }
                    print("[FrameworkZ] Saved equipment color for " .. (item.getName and item:getName() or "item") .. ": r=" .. r .. ", g=" .. g .. ", b=" .. b)
                    return
                end
            end
        end

        if vis and vis.getTextureChoice and type(vis.getTextureChoice) == "function" then
            local okChoice, choice = pcall(function()
                return vis:getTextureChoice()
            end)
            if okChoice and type(choice) == "number" then
                itemData.textureChoice = math.floor(choice)
            end
        end
    end
    
    -- Fallback to getColor
    if item.getColor then
        local color = item:getColor()
        if color and color.getRedFloat and color.getGreenFloat and color.getBlueFloat then
            local r, g, b = color:getRedFloat(), color:getGreenFloat(), color:getBlueFloat()
            local a = color.getAlphaFloat and color:getAlphaFloat() or 1.0
            -- Validate color values are numbers
            if type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a) == "number" then
                itemData.color = {
                    r = r,
                    g = g,
                    b = b,
                    a = a
                }
            end
        end
    end
end

--! \brief Extract clothing-specific properties (dirty, wet, bloody, holes, patches)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractClothingProperties(item, itemData)
    if item.isDirty and item:isDirty() then itemData.dirty = true end
    
    if item.isWet and item:isWet() then
        itemData.wet = true
        if item.getWetness then itemData.wetness = item:getWetness() end
    end
    
    if item.isBloody and item:isBloody() then
        itemData.bloody = true
        if item.getBloodLevel then itemData.bloodLevel = item:getBloodLevel() end
    end
    
    -- Only extract holes/patches if clothing is properly initialized
    -- Check getFabricType to ensure internal structures are initialized (matches PZ pattern)
    if item.getFabricType and item:getFabricType() then
        -- Check for holes using covered parts (matches ISInventoryPaneContextMenu pattern)
        if item.getCoveredParts and item.getVisual and item.getHolesNumber then
            local coveredParts = item:getCoveredParts()
            if coveredParts and coveredParts:size() > 0 then
                local visual = item:getVisual()
                if visual and visual.getHole then
                    local hasHoles = false
                    for i = 0, coveredParts:size() - 1 do
                        local part = coveredParts:get(i)
                        local hole = visual:getHole(part)
                        if hole and hole > 0 then
                            hasHoles = true
                            break
                        end
                    end
                    if hasHoles then
                        itemData.holes = item:getHolesNumber()
                    end
                end
            end
        end
        
        -- Check if any patches exist before getting count (matches ISGarmentUI pattern)
        if item.getPatchType and item.getCoveredParts and item.getPatchesNumber then
            local coveredParts = item:getCoveredParts()
            if coveredParts and coveredParts:size() > 0 then
                -- Check if any part actually has a patch
                local hasPatch = false
                for i = 0, coveredParts:size() - 1 do
                    local part = coveredParts:get(i)
                    if item:getPatchType(part) then
                        hasPatch = true
                        break
                    end
                end
                -- Only call getPatchesNumber if we confirmed patches exist
                if hasPatch then
                    itemData.patches = item:getPatchesNumber()
                end
            end
        end
    end
end

--! \brief Extract weapon-specific properties (ammo, magazine, bullets)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractWeaponProperties(item, itemData)
    if not (item:getType():contains("Weapon") or item:getCategory() == "Weapon") then return end
    
    if item.getConditionLowerChance then
        itemData.conditionLowerChance = item:getConditionLowerChance()
    end
    
    if item.getBloodLevel then
        itemData.weaponBloodLevel = item:getBloodLevel()
    end
    
    -- Magazine and ammunition
    if item.getMagazineType then
        local magazineType = item:getMagazineType()
        if magazineType and magazineType ~= "" then
            itemData.magazineType = magazineType
            if item.getCurrentAmmoCount then itemData.ammoCount = item:getCurrentAmmoCount() end
            if item.getMaxAmmo then itemData.maxAmmo = item:getMaxAmmo() end
            if item.getAmmoType then itemData.ammoType = item:getAmmoType() end
            
            -- Individual bullets
            if item.getBullets then
                local bullets = item:getBullets()
                if bullets and bullets:size() > 0 then
                    itemData.bullets = {}
                    for i = 0, bullets:size() - 1 do
                        local bullet = bullets:get(i)
                        if bullet then
                            table.insert(itemData.bullets, {
                                type = bullet:getFullType(),
                                condition = (bullet.getCondition and bullet:getCondition()) or 1.0
                            })
                        end
                    end
                end
            end
        end
    end
end

--! \brief Extract food-specific properties (freshness, age, frozen state)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractFoodProperties(item, itemData)
    if not (item:getType():contains("Food") or item:getCategory() == "Food") then return end
    
    if item.getHungerChange then itemData.hungerChange = item:getHungerChange() end
    if item.getBoredomChange then itemData.boredomChange = item:getBoredomChange() end
    if item.getUnhappyChange then itemData.unhappyChange = item:getUnhappyChange() end
    if item.isFrozen then itemData.frozen = item:isFrozen() end
    if item.getAge then itemData.age = item:getAge() end
    if item.getOffAge then itemData.offAge = item:getOffAge() end
    if item.getOffAgeMax then itemData.offAgeMax = item:getOffAgeMax() end
end

--! \brief Extract container-specific properties (capacity, contents with recursive extraction)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractContainerProperties(item, itemData)
    if not (item:getType():contains("Container") or item:getCategory() == "Container") then return end
    
    if item.getCapacity then itemData.capacity = item:getCapacity() end
    
    if item.getItems then
        local containerItems = item:getItems()
        if containerItems and containerItems:size() > 0 then
            itemData.containerItems = {}
            for i = 0, containerItems:size() - 1 do
                local containerItem = containerItems:get(i)
                if containerItem then
                    -- Recursive extraction
                    table.insert(itemData.containerItems, self:ExtractItemData(containerItem))
                end
            end
        end
        
        -- Save container inventory ModData (e.g., Tetris grid layouts)
        local containerModData = containerItems:getModData()
        if containerModData then
            local hasData = false
            for _ in pairs(containerModData) do hasData = true break end
            if hasData then
                itemData.containerInventoryModData = {}
                for key, value in pairs(containerModData) do
                    itemData.containerInventoryModData[key] = value
                end
            end
        end
    end
end

--! \brief Extract literature-specific properties (pages, locks, writing)
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractLiteratureProperties(item, itemData)
    if not (item:getType():contains("Book") or item:getType():contains("Literature") or item:getCategory() == "Literature") then return end
    
    if item.getNumberOfPages then itemData.numberOfPages = item:getNumberOfPages() end
    if item.getPageToWrite then itemData.pageToWrite = item:getPageToWrite() end
    if item.getLockedBy then itemData.lockedBy = item:getLockedBy() end
end

--! \brief Extract ModData from an item
--! \param item \InventoryItem The item to extract from
--! \param itemData \table The data table to populate
function FrameworkZ.Inventories:ExtractModData(item, itemData)
    local modData = item:getModData()
    if modData then
        local hasData = false
        for _ in pairs(modData) do hasData = true break end
        if hasData then
            itemData.modData = {}
            for key, value in pairs(modData) do
                itemData.modData[key] = value
            end
        end
    end
end

--! \brief Extract comprehensive item data by calling all category-specific extractors
--! \param item \InventoryItem The item to extract data from
--! \return \table Comprehensive item data
function FrameworkZ.Inventories:ExtractItemData(item)
    if not item then return nil end
    
    local itemData = {
        id = item:getFullType(),
        type = item:getType(),
        displayName = item:getDisplayName()
    }
    
    -- Call granular extractors - can be overridden individually
    self:ExtractBasicProperties(item, itemData)
    self:ExtractColorData(item, itemData)
    self:ExtractClothingProperties(item, itemData)
    
    if item:getType() then
        self:ExtractWeaponProperties(item, itemData)
        self:ExtractFoodProperties(item, itemData)
        self:ExtractContainerProperties(item, itemData)
        self:ExtractLiteratureProperties(item, itemData)
    end
    
    self:ExtractModData(item, itemData)
    
    return itemData
end

--! \brief Apply equipment visuals AFTER equipping to prevent randomization override
--! \param item \InventoryItem The equipped item
--! \param itemData \table The item data containing color/decal information
--! \return \boolean True if any visual property was applied
function FrameworkZ.Inventories:ApplyEquipmentColor(item, itemData)
    if not item or not itemData then return false end

    local applied = false
    local visual = item.getVisual and item:getVisual() or nil
    local clothingItem = item.getClothingItem and item:getClothingItem() or nil

    if itemData.textureChoice ~= nil and visual and visual.setTextureChoice and type(visual.setTextureChoice) == "function" then
        local ok = pcall(function()
            visual:setTextureChoice(itemData.textureChoice)
        end)
        if ok then
            if item.synchWithVisual and type(item.synchWithVisual) == "function" then
                pcall(function()
                    item:synchWithVisual()
                end)
            end
            applied = true
        end
    end

    -- Validate color is a proper table with required fields
    if itemData.color and type(itemData.color) == "table" and itemData.color.r and itemData.color.g and itemData.color.b then
        -- Apply color using proper PZ pattern
        if item.setColor and item.setCustomColor then
            local color = Color.new(itemData.color.r, itemData.color.g, itemData.color.b, itemData.color.a or 1.0)
            item:setColor(color)

            if visual and visual.setTint and ImmutableColor and ImmutableColor.new then
                visual:setTint(ImmutableColor.new(color))
            end

            item:setCustomColor(true)
            applied = true
        end
    end

    if itemData.decal ~= nil and visual and visual.setDecal and type(visual.setDecal) == "function" then
        local decalStr = (type(itemData.decal) == "string") and itemData.decal or tostring(itemData.decal)
        if clothingItem and visual.getDecal and type(visual.getDecal) == "function" then
            visual:setDecal(decalStr)
            applied = true
        else
            visual:setDecal(decalStr)
            applied = true
        end
    end

    return applied
end

--! \brief Restore comprehensive item data from saved data
--! \param item \InventoryItem The item to restore to
--! \param itemData \table The saved item data
--! \return \boolean True if restoration was successful
function FrameworkZ.Inventories:RestoreItemData(item, itemData)
    if not item or not itemData then return false end
    
    -- Restore basic properties
    if itemData.condition and item.setCondition then
        item:setCondition(itemData.condition)
    end
    
    if itemData.maxCondition and item.setConditionMax then
        item:setConditionMax(itemData.maxCondition)
    end
    
    -- Restore color/tint
    -- NOTE: For equipped items, color should be applied AFTER setWornItem() to override randomization
    -- This function handles non-equipped items. For equipment, see ApplyEquipmentColor() method.
    if itemData.color and type(itemData.color) == "table" and item.setColor then
        local r, g, b, a = itemData.color.r, itemData.color.g, itemData.color.b, itemData.color.a or 1.0
        -- Validate all color components are numbers before applying
        if type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a) == "number" then
            local color = Color.new(r, g, b, a)
            item:setColor(color)
            if item.getVisual and item.setCustomColor then
                local visual = item:getVisual()
                if visual and visual.setTint and ImmutableColor and ImmutableColor.new then
                    visual:setTint(ImmutableColor.new(color))
                end

                item:setCustomColor(true)
            end
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
    
    if itemData.holes and item.setHolesNumber then
        item:setHolesNumber(itemData.holes)
    end
    
    if itemData.patches and item.setPatchesNumber then
        item:setPatchesNumber(itemData.patches)
    end
    
    -- Restore weapon properties
    if item:getType() and (item:getType():contains("Weapon") or item:getCategory() == "Weapon") then
        if itemData.conditionLowerChance and item.setConditionLowerChance then
            item:setConditionLowerChance(itemData.conditionLowerChance)
        end
        
        if itemData.weaponBloodLevel and item.setBloodLevel then
            item:setBloodLevel(itemData.weaponBloodLevel)
        end
        
        -- Restore magazine and ammunition
        if itemData.magazineType and item.setMagazineType then
            item:setMagazineType(itemData.magazineType)
            
            if itemData.ammoCount and item.setCurrentAmmoCount then
                item:setCurrentAmmoCount(itemData.ammoCount)
            end
            
            if itemData.ammoType and item.setAmmoType then
                item:setAmmoType(itemData.ammoType)
            end
            
            -- Restore individual bullets
            if itemData.bullets and item.getBullets then
                local bullets = item:getBullets()
                if bullets then
                    bullets:clear()
                    for _, bulletData in ipairs(itemData.bullets) do
                        local bullet = item:getInventory():AddItem(bulletData.type)
                        if bullet and bulletData.condition and bullet.setCondition then
                            bullet:setCondition(bulletData.condition)
                        end
                        if bullet then
                            bullets:add(bullet)
                        end
                    end
                end
            end
        end
    end
    
    -- Restore food properties
    if item:getType() and (item:getType():contains("Food") or item:getCategory() == "Food") then
        if itemData.frozen and item.setFrozen then
            item:setFrozen(itemData.frozen)
        end
        
        if itemData.age and item.setAge then
            item:setAge(itemData.age)
        end
        
        if itemData.offAge and item.setOffAge then
            item:setOffAge(itemData.offAge)
        end
        
        if itemData.offAgeMax and item.setOffAgeMax then
            item:setOffAgeMax(itemData.offAgeMax)
        end
    end
    
    -- Restore item's own mod data FIRST (before container contents)
    -- This ensures the container item itself has its ModData set before we manipulate its contents
    if itemData.modData then
        local modData = item:getModData()
        for key, value in pairs(itemData.modData) do
            modData[key] = value
        end
    end
    
    -- Restore container contents
    if item:getType() and (item:getType():contains("Container") or item:getCategory() == "Container") and itemData.containerItems then
        local containerInventory = item:getItems()
        if containerInventory then
            -- CRITICAL: Save the container inventory's ModData BEFORE clearing
            -- This preserves plugin data (like Tetris grid layouts) that might already be set
            local preservedContainerModData = nil
            if itemData.containerInventoryModData then
                preservedContainerModData = itemData.containerInventoryModData
            end
            
            -- Clear the container to remove old items (needed for character swapping)
            containerInventory:clear()
            
            -- Restore the container inventory's ModData IMMEDIATELY after clearing
            -- This must happen before adding items so plugins can track item placement
            if preservedContainerModData then
                local containerModData = containerInventory:getModData()
                for key, value in pairs(preservedContainerModData) do
                    containerModData[key] = value
                end
            end
            
            -- Now restore the items with the grid data intact
            for _, containerItemData in ipairs(itemData.containerItems) do
                local containerItem = containerInventory:AddItem(containerItemData.id)
                if containerItem then
                    self:RestoreItemData(containerItem, containerItemData)
                end
            end
        end
    end
    
    -- Restore literature properties
    if item:getType() and (item:getType():contains("Book") or item:getType():contains("Literature") or item:getCategory() == "Literature") then
        if itemData.pageToWrite and item.setPageToWrite then
            item:setPageToWrite(itemData.pageToWrite)
        end
        
        if itemData.lockedBy and item.setLockedBy then
            item:setLockedBy(itemData.lockedBy)
        end
    end
    
    -- NOTE: Item's ModData already restored earlier (before container contents)
    -- to ensure proper initialization order
    
    -- Restore uses
    if itemData.usedDelta and item.setUsedDelta then
        item:setUsedDelta(itemData.usedDelta)
    end
    
    if itemData.uses and item.setUses then
        item:setUses(itemData.uses)
    end
    
    return true
end

-- Helper function to safely get worn item with error handling
local function resolveBodyLocation(slot)
    if not slot then return nil end
    if type(slot) ~= "string" then return slot end

    if ItemBodyLocation and type(ItemBodyLocation.get) == "function" and ResourceLocation and type(ResourceLocation.of) == "function" then
        local ok, location = pcall(function()
            return ItemBodyLocation.get(ResourceLocation.of(slot))
        end)
        if ok and location then return location end
    end

    if ItemBodyLocation and type(ItemBodyLocation) == "table" then
        local enumLike = slot:gsub("([a-z0-9])([A-Z])", "%1_%2"):upper()
        if ItemBodyLocation[enumLike] then
            return ItemBodyLocation[enumLike]
        end
    end

    return slot
end

local function safeGetWornItem(isoPlayer, slot)
    if not isoPlayer or not slot then return nil end
    
    -- Handle special cases and common slot variations
    local actualSlot = slot
    
    -- Try different slot name variations if needed
    local function tryGet(location)
        if not isoPlayer.getWornItem then return nil end
        local ok, value = pcall(function()
            return isoPlayer:getWornItem(location)
        end)
        if ok then return value end
        return nil
    end

    local result = tryGet(resolveBodyLocation(actualSlot))
    if result then return result end
    -- Try alternative slot names for compatibility
    local alternativeSlots = {
        ["TorsoExtraVest"] = "TorsoExtra",
        ["TorsoExtra"] = "TorsoExtraVest"
    }
    if alternativeSlots[slot] then
        return tryGet(resolveBodyLocation(alternativeSlots[slot]))
    end
    return nil
end

-- Helper function to safely set worn item with error handling
local function safeSetWornItem(isoPlayer, slot, item)
    if not isoPlayer or not slot or not item then return false end

    local function trySet(location, targetItem)
        if not isoPlayer.setWornItem then return false end
        local ok = pcall(function()
            isoPlayer:setWornItem(location, targetItem)
        end)
        return ok
    end
    
    -- For items with specific body locations, prefer that
    if item.getBodyLocation and item:getBodyLocation() then
        if trySet(item:getBodyLocation(), item) then
            return true
        end
    end

    if trySet(resolveBodyLocation(slot), item) then
        return true
    end

    -- Try alternative slot names for compatibility
    local alternativeSlots = {
        ["TorsoExtraVest"] = "TorsoExtra",
        ["TorsoExtra"] = "TorsoExtraVest"
    }
    if alternativeSlots[slot] then
        return trySet(resolveBodyLocation(alternativeSlots[slot]), item)
    end

    return false
end
FrameworkZ.Inventories = FrameworkZ.Foundation:NewModule(FrameworkZ.Inventories, "Inventories")

--! \brief Inventory class for FrameworkZ.
--! \class INVENTORY
local INVENTORY = {}
INVENTORY.__index = INVENTORY

--! \brief Initialize an inventory.
--! \return \string The inventory's ID.
function INVENTORY:Initialize()
    return FrameworkZ.Inventories:Initialize(self.id, self)
end

--! \brief Add an item to the inventory.
--! \details Note: This does not add a world item, it simply adds it to the inventory's object. Please use CHARACTER::GiveItem(uniqueID) to add an item to a character's inventory along with the world item.
--! \param item \string The item's ID.
--! \see CHARACTER::GiveItem(uniqueID)
function INVENTORY:AddItem(item)
    local inventoryIndex = #self.items + 1

    item["inventoryIndex"] = inventoryIndex
    self.items[inventoryIndex] = item
end

--! \brief Remove an item from the inventory.
--! \param item \table The item object to remove.
--! \return \boolean \string True if successful and a message.
function INVENTORY:RemoveItem(item)
    if not item then return false, "No item provided." end
    if not item.inventoryIndex then return false, "Item does not have an inventory index." end

    self.items[item.inventoryIndex] = nil

    return true, "Item  removed from inventory #" .. self.id
end

--! \brief Add multiple items to the inventory.
--! \details Note: This does not add a world item, it simply adds it to the inventory's object. Please use CHARACTER::GiveItems(uniqueID) to add an items to a character's inventory along with the world item.
--! \param uniqueID \string The item's ID.
--! \param quantity \integer The quantity of the item to add.
--! \see CHARACTER::GiveItems(uniqueID)
function INVENTORY:AddItems(uniqueID, quantity)
    for i = 1, quantity do
        self:AddItem(uniqueID)
    end
end

--! \brief Get all items in the inventory.
--! \return \table The items table.
function INVENTORY:GetItems()
    return self.items
end

--! \brief Get an item by its unique ID.
--! \param uniqueID \string The item's unique ID.
--! \return \table|\boolean The item object or false if not found.
--! \return \string Error message if not found.
function INVENTORY:GetItemByUniqueID(uniqueID)
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    for _key, item in pairs(self:GetItems()) do
        if item.uniqueID == uniqueID then
            return item
        end
    end

    return false, "No item found with unique ID: " .. uniqueID
end

--! \brief Get the count of items with a specific unique ID.
--! \param uniqueID \string The item's unique ID.
--! \return \integer The count of matching items.
function INVENTORY:GetItemCountByID(uniqueID)
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    local count = 0

    for _key, item in pairs(self:GetItems()) do
        if item.uniqueID == uniqueID then
            count = count + 1
        end
    end

    return count
end

--! \brief Get the inventory's name.
--! \return \string The inventory's name.
function INVENTORY:GetName()
    return self.name or "Someone's Inventory"
end

--! \brief Get filtered saveable data for the inventory.
--! \return \table The processed saveable data.
function INVENTORY:GetSaveableData()
    return FrameworkZ.Foundation:ProcessSaveableData(self)
end

--! \brief Save the inventory to character data
--! \return \table The complete inventory data including equipment
function INVENTORY:Save()
    -- This function is designed to work with character inventories
    -- For other inventory types, override this method as needed
    if self.type ~= FrameworkZ.Inventories.Types.Character then
        return nil, "Save method only supported for character inventories"
    end
    
    -- Get the character that owns this inventory
    local character = FrameworkZ.Characters:GetCharacterByID(self.owner)
    if not character then
        return nil, "Could not find character for inventory owner: " .. tostring(self.owner)
    end
    
    -- Delegate to the centralized save function
    return FrameworkZ.Inventories:Save(character)
end

--! \brief Create a new inventory object.
--! \param username \string The owner's username. Can be nil for no owner.
--! \param type \string The type of inventory. Can be nil, but creates a character inventory type by default. Refer to FrameworkZ.Inventories.Types table for available types.
--! \param id \string The inventory's ID. Can be nil for an auto generated ID (recommended).
--! \return \table The new inventory object.
function FrameworkZ.Inventories:New(username, type, id)
    if not id then
        FrameworkZ.Inventories.List[#FrameworkZ.Inventories.List + 1] = {} -- Reserve space to avoid inconsistencies.
        id = #FrameworkZ.Inventories.List
    end

    local object = {
        id = id,
        owner = username or "",
        type = type or FrameworkZ.Inventories.Types.Character,
        name = "Someone's Inventory",
        description = "No description available.",
        items = {}
    }

    setmetatable(object, INVENTORY)

    return object
end

--! \brief Initialize an inventory.
--! \param id \table The inventory's id.
--! \param object \table The inventory's object.
--! \return \integer The inventory's ID.
function FrameworkZ.Inventories:Initialize(id, object)
    FrameworkZ.Inventories.List[id] = object

    return id
end

--! \brief Get an inventory by its ID.
--! \param id \integer The inventory's ID.
--! \return \table|\boolean The inventory object or false if not found.
--! \return \string Error message if not found.
function FrameworkZ.Inventories:GetInventoryByID(id)
    if not id then return false, "No inventory ID provided." end

    local inventory = self.List[id] or nil

    if not inventory then return false, "No inventory found with ID: " .. id end

    return inventory
end

--! \brief Get an item by its unique ID from a specific inventory.
--! \param inventoryID \integer The inventory's ID to search in.
--! \param uniqueID \string The item's unique ID.
--! \return \table|\boolean The item object or false if not found.
--! \return \string Error message if not found.
function FrameworkZ.Inventories:GetItemByUniqueID(inventoryID, uniqueID)
    if not inventoryID then return false, "No inventory ID provided." end
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    local inventoryOrSuccess, inventoryMessage = self:GetInventoryByID(inventoryID)

    if not inventoryOrSuccess then return inventoryOrSuccess, inventoryMessage end

    local itemOrSuccess, itemMessage = inventoryOrSuccess:GetItemByUniqueID(uniqueID)

    return itemOrSuccess, itemMessage
end

--! \brief Get the count of items with a specific unique ID in an inventory.
--! \param inventoryID \integer The inventory's ID to search in.
--! \param uniqueID \string The item's unique ID.
--! \return \integer|\boolean The count or false if inventory not found.
--! \return \string Error message if failed.
function FrameworkZ.Inventories:GetItemCountByID(inventoryID, uniqueID)
    if not inventoryID then return false, "No inventory ID provided." end
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    local inventoryOrSuccess, inventoryMessage = self:GetInventoryByID(inventoryID)

    if not inventoryOrSuccess then return inventoryOrSuccess, inventoryMessage end

    local countOrSuccess, countMessage = inventoryOrSuccess:GetItemCountByID(uniqueID)

    return countOrSuccess, countMessage
end

--! \brief Recursively traverses the inventory table for missing data while referencing the item definitions to rebuild the inventory.
--! \param inventory \table The inventory to rebuild.
--! \return \table The rebuilt inventory.
function FrameworkZ.Inventories:Rebuild(isoPlayer, inventory, items)
    if not isoPlayer then return false, "No ISO Player to add items to." end
    if not inventory then return false, "No inventory to rebuild." end
    if not items or type(items) ~= "table" then return false, "Logical inventory payload is invalid." end

    local logicalItems = items.items
    if type(logicalItems) ~= "table" then return false, "Logical inventory payload is missing items table." end
    if #logicalItems == 0 then
        return true, "No logical items to rebuild.", inventory
    end

    local rebuildRequests = {}

    for _, itemSnapshot in ipairs(logicalItems) do
        local uniqueID = itemSnapshot and itemSnapshot.uniqueID or nil
        if uniqueID and FrameworkZ.Items:GetItemByUniqueID(uniqueID) then
            table.insert(rebuildRequests, {
                uniqueID = uniqueID,
                quantity = 1,
                snapshot = itemSnapshot
            })
        end
    end

    if #rebuildRequests == 0 then
        return true, "No valid logical items to rebuild.", inventory
    end

    local success, message, manifest, instances, _worldItems = FrameworkZ.Items:CreateWorldItemsBatch(isoPlayer, rebuildRequests)
    if not success then
        return false, message
    end

    local rebuildCount = 0

    if type(manifest) == "table" then
        for _, itemManifest in ipairs(manifest) do
            local worldItemID = itemManifest and itemManifest.worldItemID or nil
            local instanceData = itemManifest and itemManifest.instanceData or nil
            local worldItem = worldItemID and isoPlayer:getInventory():getItemById(worldItemID) or nil

            if worldItem and type(instanceData) == "table" then
                FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)
                local itemInstance = FrameworkZ.Items:HydrateClientInstanceFromData(isoPlayer, worldItem, instanceData)

                if type(itemInstance) == "table" then
                    inventory:AddItem(itemInstance)
                    rebuildCount = rebuildCount + 1
                end
            end
        end
    elseif type(instances) == "table" then
        -- Fallback for direct server-side call path where instances are already returned.
        for _, itemInstance in ipairs(instances) do
            if type(itemInstance) == "table" then
                inventory:AddItem(itemInstance)
                rebuildCount = rebuildCount + 1
            end
        end
    end

    return true, "Inventory rebuilt with " .. tostring(rebuildCount) .. " logical items.", inventory
end

--! \brief Save character inventory and equipment data
--! \param character \table The character object with inventory
--! \return \table The complete inventory data including equipment
function FrameworkZ.Inventories:Save(character)
    if not character then 
        return nil, "Missing character parameter"
    end

    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return nil, "Character has no IsoPlayer"
    end

    -- Ensure FZ world items are linked to live logical instances before building
    -- logical/physical save payloads; otherwise reconnects can degrade to physical-only.
    self:RepairFrameworkZInventoryIntegrity(character)

    local inventoryData = {}
    
    -- Save logical inventory in canonical shape
    local logicalInventoryData = { items = {}, equippedItems = {} }
    local logicalInstanceIDs = {}
    local logicalInventory = character:GetInventory()

    if logicalInventory and logicalInventory.GetItems then
        for _, logicalItem in pairs(logicalInventory:GetItems()) do
            if type(logicalItem) == "table" then
                local saveableItemData = FrameworkZ.Foundation:ProcessSaveableData(logicalItem)
                if saveableItemData and saveableItemData.uniqueID then
                    table.insert(logicalInventoryData.items, saveableItemData)

                    if saveableItemData.instanceID ~= nil then
                        logicalInstanceIDs[tostring(saveableItemData.instanceID)] = true
                    end
                end
            end
        end
    end

    -- Save physical inventory (with comprehensive item data).
    -- FZ_ITM items are usually represented by logical inventory snapshots.
    -- If logical tracking is missing, keep a physical fallback copy to prevent loss on reconnect.
    local physicalItems = {}
    local inventory = isoPlayer:getInventory():getItems()
    for i = 0, inventory:size() - 1 do
        local item = inventory:get(i)
        local fzData = item:getModData()["FZ_ITM"]
        local includePhysical = false

        if not fzData then
            includePhysical = true
        else
            local logicalKey = fzData.instanceID and tostring(fzData.instanceID) or nil
            includePhysical = logicalKey == nil or not logicalInstanceIDs[logicalKey]
        end

        if includePhysical then
            local itemData = self:ExtractItemData(item)
            if itemData then
                table.insert(physicalItems, itemData)
            end
        end
    end
    inventoryData.INVENTORY_PHYSICAL = physicalItems
    
    -- Capture equipped FrameworkZ items using SlotLookup
    local equippedFrameworkZItems = {}
    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            local equippedItem = safeGetWornItem(isoPlayer, slotName)
            if equippedItem and equippedItem:getModData()["FZ_ITM"] then
                local fzItemData = equippedItem:getModData()["FZ_ITM"]
                if fzItemData and fzItemData.instanceID then
                    equippedFrameworkZItems[fzItemData.instanceID] = {
                        slot = slotName,
                        slotName = slotName,
                        slotEnum = slotEnum
                    }
                    print("[FrameworkZ] Found equipped FrameworkZ item '" .. (fzItemData.name or "Unknown") .. "' in slot " .. slotName .. " (enum: " .. slotEnum .. ")")
                end
            end
        end
    end
    
    -- Add equipped state to logical inventory data
    logicalInventoryData.equippedItems = equippedFrameworkZItems
    inventoryData.INVENTORY_LOGICAL = logicalInventoryData

    -- Save physical equipment (with comprehensive item data) using SlotLookup and O(1) lookup
    local function saveEquipmentSlot(slotName, slotEnum)
        local equippedItem = safeGetWornItem(isoPlayer, slotName)
        if equippedItem then
            local itemType = equippedItem:getFullType()
            
            -- O(1) check if item is FrameworkZ type
            if self:IsFrameworkZItemType(itemType) then
                print("[FrameworkZ] Skipping FrameworkZ item in equipment slot " .. slotName .. " (enum: " .. slotEnum .. "). Logical inventory handles this.")
                return nil
            else
                -- Use enhanced item data extraction for equipment
                return self:ExtractItemData(equippedItem)
            end
        end
        return nil
    end

    -- Store equipment in Equipment sub-table for consistency
    local equipmentData = {}
    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            -- Use enum as primary key for consistency with character creation
            equipmentData[slotEnum] = saveEquipmentSlot(slotName, slotEnum)
        end
    end
    inventoryData.Equipment = equipmentData

    return inventoryData, "Character inventory data saved successfully"
end

--! \brief Restore character inventory and equipment data
--! \param character \table The character object
--! \param inventoryData \table The saved inventory data
--! \return \boolean Whether restoration was successful
function FrameworkZ.Inventories:Restore(character, inventoryData)
    if not character then
        return false, "Missing character parameter"
    end
    
    if not inventoryData then
        return false, "Missing inventory data"
    end

    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return false, "Character has no IsoPlayer"
    end

    local onServer = type(isServer) == "function" and isServer() or false

    local success = true
    local messages = {}

    if onServer then
        -- Server path: authoritative. Clear was done at restore boundary; add physical and rebuild logical.
        if inventoryData.INVENTORY_PHYSICAL then
            for _, itemData in pairs(inventoryData.INVENTORY_PHYSICAL) do
                if itemData.id then
                    local restoredItem = isoPlayer:getInventory():AddItem(itemData.id)
                    if restoredItem then
                        self:RestoreItemData(restoredItem, itemData)
                    end
                end
            end
            table.insert(messages, "Physical inventory restored")
        end

        if inventoryData.INVENTORY_LOGICAL then
            local newInventory = FrameworkZ.Inventories:New(isoPlayer:getUsername())
            local rebuildSuccess, rebuildMessage, rebuiltInventory = self:Rebuild(isoPlayer, newInventory, inventoryData.INVENTORY_LOGICAL)

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

        -- Run integrity repair immediately on server since all items are present.
        local repairedCount, repairedMessage = self:RepairFrameworkZInventoryIntegrity(character)
        if repairedCount and repairedCount > 0 then
            table.insert(messages, "Repaired " .. tostring(repairedCount) .. " link(s)")
            print("[FrameworkZ] " .. tostring(repairedMessage))
        end

        -- Notify the owning client that inventory is fully built so it can run its own repair
        -- once PZ has replicated the physical items.  sendClientCommand is server-only.
        if type(sendClientCommand) == "function" then
            sendClientCommand(isoPlayer, "FZ", "InventoryRestored", {uid = character:GetUID()})
        end
    else
        -- Client path: rebuild the saved logical inventory from the character snapshot so
        -- reconnects restore FrameworkZ items even before server-authoritative world sync.
        local existingInventory = character.GetInventory and character:GetInventory() or nil
        if not existingInventory or type(existingInventory.AddItem) ~= "function" then
            existingInventory = FrameworkZ.Inventories:New(isoPlayer:getUsername())
            character:SetInventory(existingInventory)
            character.InventoryID = existingInventory.id
            existingInventory:Initialize()
        end

        if inventoryData.INVENTORY_LOGICAL then
            local rebuildSuccess, rebuildMessage, rebuiltInventory = self:Rebuild(isoPlayer, existingInventory, inventoryData.INVENTORY_LOGICAL)
            if rebuildSuccess and rebuiltInventory then
                character:SetInventory(rebuiltInventory)
                character.InventoryID = rebuiltInventory.id
                rebuiltInventory:Initialize()
                table.insert(messages, "Logical inventory rebuilt from saved data")
            else
                table.insert(messages, "Logical inventory rebuild from saved data failed: " .. tostring(rebuildMessage or "Unknown error"))
            end
        end

        -- Run repair immediately to link any physical items that may already be present.
        local immediateRepaired, immediateMsg = self:RepairFrameworkZInventoryIntegrity(character)
        if immediateRepaired and immediateRepaired > 0 then
            table.insert(messages, "Immediate client repair: linked " .. tostring(immediateRepaired) .. " item(s)")
        end

        if not inventoryData.INVENTORY_LOGICAL then
            table.insert(messages, "No logical inventory payload available for client rebuild")
        end
    end

    return success, table.concat(messages, "; ")
end

function FrameworkZ.Inventories:RepairFrameworkZInventoryIntegrity(character)
    if not character then
        return 0, "Skipped integrity repair: missing character."
    end

    local isoPlayer = character.GetIsoPlayer and character:GetIsoPlayer() or nil
    if not isoPlayer or not isoPlayer.getInventory then
        return 0, "Skipped integrity repair: missing player inventory."
    end

    local inventoryObj = character.GetInventory and character:GetInventory() or nil
    if not inventoryObj or type(inventoryObj.AddItem) ~= "function" then
        inventoryObj = FrameworkZ.Inventories:New(isoPlayer:getUsername())
        if character.SetInventory then
            character:SetInventory(inventoryObj)
        end
        if character.SetInventoryID then
            character:SetInventoryID(inventoryObj.id)
        else
            character.InventoryID = inventoryObj.id
        end
        inventoryObj:Initialize()
    end

    local repaired = 0
    local items = isoPlayer:getInventory():getItems()
    if not items then
        return repaired, "No physical inventory found for integrity repair."
    end

    local function inventoryAlreadyHasInstance(targetInventory, instanceID)
        if not targetInventory or not instanceID then
            return false
        end

        local logicalItems = targetInventory.GetItems and targetInventory:GetItems() or nil
        if type(logicalItems) ~= "table" then
            return false
        end

        for _, logicalItem in pairs(logicalItems) do
            if type(logicalItem) == "table" and logicalItem.instanceID == instanceID then
                return true
            end

            local logicalModData = logicalItem and logicalItem.getModData and logicalItem:getModData() or nil
            local logicalFZData = logicalModData and logicalModData["FZ_ITM"] or nil
            if type(logicalFZData) == "table" and logicalFZData.instanceID == instanceID then
                return true
            end
        end

        return false
    end

    -- Refresh type lookup every time: plugin items are registered after module load,
    -- so the lookup built at startup may be empty or stale. Cost is just one table pass.
    initializeFrameworkZItemLookup()

    for i = 0, items:size() - 1 do
        local worldItem = items:get(i)
        if worldItem and worldItem.getFullType and worldItem.getModData then
            local fullType = worldItem:getFullType()
            local modData = worldItem:getModData()
            local linkedData = modData and modData["FZ_ITM"] or nil

            -- Prefer uniqueID from existing FZ_ITM mod data (always present on server-replicated FZ items).
            -- Fall back to the type lookup for items that are FZ-type but not yet tagged (world pickups).
            local uniqueID = (type(linkedData) == "table" and linkedData.uniqueID) or self.FrameworkZItemTypeLookup[fullType]

            if uniqueID then
                local hasValidLink = false

                if type(linkedData) == "table" and linkedData.instanceID ~= nil then
                    local liveInstance = FrameworkZ.Items:GetInstance(linkedData.instanceID)
                    hasValidLink = tableHasEntries(liveInstance)
                end

                if not hasValidLink then
                    local definition = FrameworkZ.Items:GetItemByUniqueID(uniqueID)
                    if definition then
                        local instanceID, itemInstance = FrameworkZ.Items:AddInstance(definition, isoPlayer, worldItem)
                        if itemInstance and instanceID then
                            if type(linkedData) == "table" then
                                itemInstance.customFields = linkedData.customFields or itemInstance.customFields
                                itemInstance.name = linkedData.name or itemInstance.name
                                itemInstance.description = linkedData.description or itemInstance.description
                                itemInstance.category = linkedData.category or itemInstance.category
                                if linkedData.weight ~= nil then
                                    itemInstance.weight = linkedData.weight
                                end
                            end

                            -- Run base-inherited OnInstanced if not yet initialized.
                            -- Denomination items store a placeholder name in their definition;
                            -- OnInstanced (copied from the base) computes the real display name.
                            -- The definition always has wasInitialized=false so this is safe to call.
                            if itemInstance.OnInstanced and not itemInstance.wasInitialized then
                                itemInstance:OnInstanced(isoPlayer, worldItem)
                            end

                            local instanceData = {
                                uniqueID = itemInstance.uniqueID,
                                itemID = worldItem:getFullType(),
                                instanceID = instanceID,
                                owner = isoPlayer:getUsername(),
                                name = itemInstance.name or "Unknown",
                                description = itemInstance.description or "No description available.",
                                category = itemInstance.category or "Uncategorized",
                                shouldConsume = itemInstance.shouldConsume or false,
                                weight = itemInstance.weight or 1,
                                useAction = itemInstance.useAction or nil,
                                useTime = itemInstance.useTime or nil,
                                customFields = itemInstance.customFields or {}
                            }

                            FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)

                            if not inventoryAlreadyHasInstance(inventoryObj, instanceID) then
                                inventoryObj:AddItem(itemInstance)
                                repaired = repaired + 1
                            end
                        end
                    end
                end
            end
        end
    end

    if repaired > 0 then
        return repaired, "Repaired " .. tostring(repaired) .. " FrameworkZ item(s) with missing or stale FZ_ITM links."
    end

    return 0, "No FrameworkZ item integrity repairs were needed."
end

--! \brief Restore all equipment (both physical and logical) for a character
--! \param character \table The character object
--! \param inventoryData \table The complete inventory data containing equipment info
--! \return \boolean Whether restoration was successful
function FrameworkZ.Inventories:RestoreEquipment(character, inventoryData)
    if not character then
        return false, "Missing character parameter"
    end

    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return false, "Character has no IsoPlayer"
    end

    if not inventoryData then
        return false, "Missing inventory data"
    end

    local restoredPhysical = 0
    local restoredLogical = 0
    local failedCount = 0

    -- Get equipment from Equipment sub-table
    local equipmentTable = inventoryData.Equipment or {}

    -- Clear stale currently-worn items before restoring saved equipment.
    -- This strips temporary limbo outfit pieces and removes mismatched items from slots
    -- that are about to be restored with different saved equipment.
    local function getSavedEquipmentForLocation(locationName)
        if not locationName then return nil end

        local key = tostring(locationName)
        local slotEnum = self.SlotNameLookup[key] or key

        local slotData = equipmentTable[slotEnum]
        if slotData and slotData.id then
            return slotData
        end

        local legacyKey = "EQUIPMENT_SLOT_" .. string.upper(key:gsub("([A-Z])", "_%1"):gsub("^_", ""))
        local legacyData = inventoryData[legacyKey] or inventoryData[key]
        if legacyData and legacyData.id then
            return legacyData
        end

        return nil
    end

    local wornItems = isoPlayer:getWornItems()
    if wornItems and wornItems.size and wornItems.get then
        local staleWornEntries = {}

        for i = 0, wornItems:size() - 1 do
            local wornEntry = wornItems:get(i)
            local wornItem = wornEntry and wornEntry.getItem and wornEntry:getItem() or nil

            if wornItem then
                local locationName = wornItem.getBodyLocation and wornItem:getBodyLocation() or nil
                local savedSlotData = getSavedEquipmentForLocation(locationName)
                local shouldClear = false

                if not savedSlotData then
                    shouldClear = true
                elseif wornItem.getFullType and savedSlotData.id and wornItem:getFullType() ~= savedSlotData.id then
                    shouldClear = true
                end

                if shouldClear then
                    table.insert(staleWornEntries, {
                        location = locationName,
                        item = wornItem,
                    })
                end
            end
        end

        for _, staleEntry in ipairs(staleWornEntries) do
            if staleEntry.location then
                pcall(function()
                    isoPlayer:setWornItem(resolveBodyLocation(staleEntry.location), nil)
                end)
            end

            local inventory = isoPlayer:getInventory()
            if inventory and staleEntry.item then
                pcall(function()
                    inventory:Remove(staleEntry.item)
                end)
            end
        end
    end

    -- First, restore physical equipment (non-FrameworkZ items) using SlotLookup
    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            -- Get equipment from Equipment sub-table using enum key
            local equipmentData = equipmentTable[slotEnum]
            
            if equipmentData and equipmentData.id then
                -- O(1) check if this equipment item is a FrameworkZ item
                if not self:IsFrameworkZItemType(equipmentData.id) then
                    local inventory = isoPlayer:getInventory()
                    local items = inventory:getItems()
                    local foundItem = nil
                    
                    -- Look for this item type in the player's inventory (should already be there from physical inventory restoration)
                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        if item:getFullType() == equipmentData.id and not item:getModData()["FZ_ITM"] then
                            foundItem = item
                            break
                        end
                    end
                    
                    -- If not found in inventory, create the item (this handles default clothing that might not have been saved)
                    if not foundItem then
                        foundItem = inventory:AddItem(equipmentData.id)
                        if foundItem then
                            print("[FrameworkZ] Created missing physical item '" .. equipmentData.id .. "' for equipment restoration")
                        end
                    end
                    
                    -- If found or created, restore properties and equip it
                    if foundItem then
                        -- Restore all item data EXCEPT color (which must be applied after equipping)
                        local colorBackup = equipmentData.color
                        equipmentData.color = nil
                        self:RestoreItemData(foundItem, equipmentData)
                        equipmentData.color = colorBackup
                        
                        -- Equip the item
                        if safeSetWornItem(isoPlayer, slotName, foundItem) then
                            -- Apply color AFTER equipping to override randomization from setWornItem
                            if self:ApplyEquipmentColor(foundItem, equipmentData) then
                                print("[FrameworkZ] Applied color to '" .. equipmentData.id .. "': r=" .. (equipmentData.color and equipmentData.color.r or "nil"))
                            else
                                print("[FrameworkZ] Warning: Failed to apply color to '" .. equipmentData.id .. "'")
                            end
                            restoredPhysical = restoredPhysical + 1
                            print("[FrameworkZ] Equipped physical item '" .. equipmentData.id .. "' to slot " .. slotName .. " (enum: " .. slotEnum .. ") with detailed properties")
                        else
                            failedCount = failedCount + 1
                            print("[FrameworkZ] Warning: Failed to equip physical item '" .. equipmentData.id .. "' to slot " .. slotName)
                        end
                    else
                        failedCount = failedCount + 1
                        print("[FrameworkZ] Warning: Could not create or find physical item '" .. equipmentData.id .. "' for slot " .. slotName)
                    end
                end
            end
        end
    end

    -- Then, restore logical equipment (FrameworkZ items) using SlotLookup
    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            -- Try enum key first (from character creation), then legacy string key for backward compatibility
            local equipmentData = inventoryData[slotEnum] or inventoryData["EQUIPMENT_SLOT_" .. string.upper(slotName:gsub("([A-Z])", "_%1"):gsub("^_", ""))]
            
            if equipmentData and equipmentData.id then
                -- O(1) check if this equipment item is a FrameworkZ item
                local fzItemUniqueID = self:IsFrameworkZItemType(equipmentData.id)
                
                -- Only restore FrameworkZ equipment here
                if fzItemUniqueID then
                    -- Find the instance from logical inventory data
                    local instanceID = nil
                    local logicalInventoryData = inventoryData.INVENTORY_LOGICAL
                    if logicalInventoryData and logicalInventoryData.equippedItems then
                        for instID, equipInfo in pairs(logicalInventoryData.equippedItems) do
                            if equipInfo.slot == slotName then
                                instanceID = instID
                                break
                            end
                        end
                    end
                    
                    if instanceID then
                        local fzItem = FrameworkZ.Items:GetInstance(instanceID)
                        if fzItem then
                            -- Create a world item for this FrameworkZ item
                            local worldItem = isoPlayer:getInventory():AddItem(fzItem.itemID)
                            if worldItem then
                                -- Link the world item to the FrameworkZ instance data
                                FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, fzItem)
                                
                                -- Equip the item to its saved slot
                                local equipSuccess = false
                                if worldItem:IsClothing() then
                                    equipSuccess = safeSetWornItem(isoPlayer, slotName, worldItem)
                                elseif worldItem:getCategory() == "Weapon" then
                                    if slotName == "TwoHands" or worldItem:isTwoHandWeapon() then
                                        isoPlayer:setPrimaryHandItem(worldItem)
                                        isoPlayer:setSecondaryHandItem(worldItem)
                                        equipSuccess = true
                                    elseif slotName == "Primary" then
                                        isoPlayer:setPrimaryHandItem(worldItem)
                                        equipSuccess = true
                                    elseif slotName == "Secondary" then
                                        isoPlayer:setSecondaryHandItem(worldItem)
                                        equipSuccess = true
                                    end
                                else
                                    -- Try as regular equipment for other item types
                                    equipSuccess = safeSetWornItem(isoPlayer, slotName, worldItem)
                                end
                                
                                if equipSuccess then
                                    restoredLogical = restoredLogical + 1
                                    print("[FrameworkZ] Restored equipped FrameworkZ item '" .. (fzItem.name or fzItem.uniqueID) .. "' to slot " .. slotName .. " (enum: " .. slotEnum .. ")")
                                else
                                    failedCount = failedCount + 1
                                    print("[FrameworkZ] Warning: Failed to equip FrameworkZ item '" .. (fzItem.name or fzItem.uniqueID) .. "' to slot " .. slotName)
                                end
                            else
                                failedCount = failedCount + 1
                                print("[FrameworkZ] Warning: Failed to create world item for FrameworkZ item instance " .. instanceID)
                            end
                        else
                            failedCount = failedCount + 1
                            print("[FrameworkZ] Warning: Could not find FrameworkZ item instance " .. instanceID .. " for equipment restoration")
                        end
                    else
                        print("[FrameworkZ] Warning: Found FrameworkZ item '" .. fzItemUniqueID .. "' in saved equipment slot " .. slotName .. " but no instance data found. Skipping restoration.")
                    end
                end
            end
        end
    end

    local message = string.format("Restored %d physical and %d logical equipment items", restoredPhysical, restoredLogical)
    if failedCount > 0 then
        message = message .. string.format(" (%d failed)", failedCount)
    end

    -- Apply colors to all inventory items (equipment and inventory) for consistency and future-proofing
    local colorsApplied = 0
    
    -- Apply colors directly from the inventoryData that was passed in (already has the correct structure)
    if inventoryData then
        -- Get equipment from Equipment sub-table
        local equipmentTable = inventoryData.Equipment or {}
        
        -- Apply colors to equipped items using resolved SlotLookup mapping
        for slotEnum, slotName in pairs(self.SlotLookup) do
            -- Get equipment data from Equipment sub-table
            local slotData = equipmentTable[slotEnum]
            if slotName and slotData and slotData.color then
                print("[FrameworkZ] Re-applying color from inventoryData for slot " .. slotName .. ": r=" .. slotData.color.r)
                local wornItem = safeGetWornItem(isoPlayer, slotName)
                if wornItem and wornItem.getVisual and type(wornItem.getVisual) == "function" then
                    if wornItem.setCustomColor then wornItem:setCustomColor(true) end
                    if Color and Color.new and wornItem.setColor then
                        wornItem:setColor(Color.new(slotData.color.r, slotData.color.g, slotData.color.b, slotData.color.a or 1))
                    end
                    local vis = wornItem:getVisual()
                    if vis and vis.setTint and ImmutableColor and ImmutableColor.new then
                        vis:setTint(ImmutableColor.new(slotData.color.r, slotData.color.g, slotData.color.b, slotData.color.a or 1))
                    end
                    colorsApplied = colorsApplied + 1
                    print("[FrameworkZ] Applied equipment color to " .. tostring(slotName) .. " slot")
                end
            end
        end
        
        -- Apply colors to all inventory items (future-proofing for when inventory items have colors)
        local inventory = isoPlayer:getInventory():getItems()
        for i = 0, inventory:size() - 1 do
            local item = inventory:get(i)
            if item and item.getVisual and type(item.getVisual) == "function" then
                -- For now, inventory items might not have specific color data stored,
                -- but this structure allows for easy expansion when that feature is added
                local itemType = item:getFullType()
                
                -- Check if this item has stored color data (could be expanded in the future)
                -- For now, we'll skip non-equipped items unless they have specific color data
                -- This is prepared for future expansion of the color system
                
                -- Example structure for future inventory item colors:
                -- if characterData.INVENTORY_ITEM_COLORS and characterData.INVENTORY_ITEM_COLORS[itemType] then
                --     local colorData = characterData.INVENTORY_ITEM_COLORS[itemType]
                --     item:setCustomColor(true)
                --     local colorObj = Color.new(colorData.r, colorData.g, colorData.b, colorData.a)
                --     item:setColor(colorObj)
                --     local immutableColor = ImmutableColor.new(colorData.r, colorData.g, colorData.b, colorData.a)
                --     item:getVisual():setTint(immutableColor)
                --     colorsApplied = colorsApplied + 1
                --     print("[FrameworkZ] Applied inventory item color to " .. itemType)
                -- end
            end
        end
        
        if colorsApplied > 0 then
            message = message .. string.format(" (applied %d item colors)", colorsApplied)
            print("[FrameworkZ] Applied colors to " .. colorsApplied .. " items total")
        end
    end

    return failedCount == 0, message
end

--! \brief Restore equipped FrameworkZ items (logical items) - DEPRECATED: Use RestoreEquipment instead
--! \param character \table The character object  
--! \param logicalInventoryData \table The logical inventory data containing equipped items
--! \return \boolean Whether restoration was successful
function FrameworkZ.Inventories:RestoreLogicalItems(character, logicalInventoryData)
    if not character then
        return false, "Missing character parameter"
    end

    local isoPlayer = character:GetIsoPlayer()
    if not isoPlayer then
        return false, "Character has no IsoPlayer"
    end

    -- Extract equipped items from logical inventory data
    local equippedItems = nil
    if logicalInventoryData and logicalInventoryData.equippedItems then
        equippedItems = logicalInventoryData.equippedItems
    end

    if not equippedItems then 
        return true, "No equipped FrameworkZ items to restore" 
    end

    local restoredCount = 0
    local failedCount = 0

    for instanceID, equipmentInfo in pairs(equippedItems) do
        local fzItem = FrameworkZ.Items:GetInstance(instanceID)
        if fzItem then
            -- Create a world item for this FrameworkZ item
            local worldItem = isoPlayer:getInventory():AddItem(fzItem.itemID)
            if worldItem then
                -- Link the world item to the FrameworkZ instance data
                FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, fzItem)
                
                -- Equip the item to its saved slot
                local equipSuccess = false
                if worldItem:IsClothing() then
                    equipSuccess = safeSetWornItem(isoPlayer, equipmentInfo.slot, worldItem)
                elseif worldItem:getCategory() == "Weapon" then
                    if equipmentInfo.slot == "TwoHands" or worldItem:isTwoHandWeapon() then
                        isoPlayer:setPrimaryHandItem(worldItem)
                        isoPlayer:setSecondaryHandItem(worldItem)
                        equipSuccess = true
                    elseif equipmentInfo.slot == "Primary" then
                        isoPlayer:setPrimaryHandItem(worldItem)
                        equipSuccess = true
                    elseif equipmentInfo.slot == "Secondary" then
                        isoPlayer:setSecondaryHandItem(worldItem)
                        equipSuccess = true
                    end
                end
                
                if equipSuccess then
                    restoredCount = restoredCount + 1
                    print("[FrameworkZ] Restored equipped FrameworkZ item '" .. (fzItem.name or fzItem.uniqueID) .. "' to slot " .. equipmentInfo.slotName)
                else
                    failedCount = failedCount + 1
                    print("[FrameworkZ] Warning: Failed to equip FrameworkZ item '" .. (fzItem.name or fzItem.uniqueID) .. "' to slot " .. equipmentInfo.slotName)
                end
            else
                failedCount = failedCount + 1
                print("[FrameworkZ] Warning: Failed to create world item for FrameworkZ item instance " .. instanceID)
            end
        else
            failedCount = failedCount + 1
            print("[FrameworkZ] Warning: Could not find FrameworkZ item instance " .. instanceID .. " for equipment restoration")
        end
    end

    local message = string.format("Restored %d equipped FrameworkZ items", restoredCount)
    if failedCount > 0 then
        message = message .. string.format(" (%d failed)", failedCount)
    end

    return failedCount == 0, message
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Inventories)
