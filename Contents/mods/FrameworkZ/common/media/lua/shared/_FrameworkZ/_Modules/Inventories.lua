--! \page Features
--! \section Inventories Inventories
--! Inventories are used to store items for characters, containers, vehicles, and other entities. Each inventory can hold multiple items, and each item can have its own unique properties and data.
--! Character persistence uses one InventoryData payload. Every live Project Zomboid item is
--! serialized once, with an optional worn-slot or hand-state marker. FrameworkZ logical items
--! are reconstructed as runtime links from each restored item's FZ_ITM ModData.

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

-- sendServerCommand/sendClientCommand round-trip numeric table keys as strings, so a manifest
-- built server-side with itemManifest[1..n] can come back client-side as itemManifest["1".."n"].
-- Re-key it by number so itemManifest[itemIndex] lookups against ipairs(itemsData) still work.
local function normalizeItemManifest(manifest)
    if type(manifest) ~= "table" then return manifest end

    local normalized = {}
    for key, value in pairs(manifest) do
        local numericKey = tonumber(key)
        if numericKey then
            normalized[numericKey] = value
        end
    end

    return normalized
end

local function countInventoryPayload(items)
    local total, frameworkItems = 0, 0

    for _, itemData in ipairs(items or {}) do
        total = total + 1
        local frameworkData = itemData.modData and itemData.modData["FZ_ITM"] or nil
        if type(frameworkData) == "table" and frameworkData.uniqueID then
            frameworkItems = frameworkItems + 1
        end

        local nestedTotal, nestedFrameworkItems = countInventoryPayload(itemData.containerItems)
        total = total + nestedTotal
        frameworkItems = frameworkItems + nestedFrameworkItems
    end

    return total, frameworkItems
end

-- Mirrors Items.lua's GiveItem/CreateWorldItemsBatch pattern: instanceItem() constructs the
-- item object first, then AddItem(object) adds it. AddItem(typeString) directly (letting the
-- inventory construct the item itself) does not register it for replication the same way, which
-- left items unable to be dropped/unequipped -- any server-validated action on them silently failed.
local function createWorldItem(inventory, itemType)
    if not inventory or not itemType or type(instanceItem) ~= "function" then return nil end

    local worldItem = instanceItem(itemType)
    if not worldItem then return nil end

    return inventory:AddItem(worldItem)
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
        local containerModData = containerItems and containerItems.getModData and containerItems:getModData() or nil
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

    local modData = item.getModData and item:getModData() or nil
    local frameworkItemData = modData and modData["FZ_ITM"] or nil
    if type(frameworkItemData) == "table" and frameworkItemData.instanceID ~= nil then
        local liveInstance = FrameworkZ.Items:GetInstance(frameworkItemData.instanceID)
        if type(liveInstance) == "table" then
            modData["FZ_ITM"] = FrameworkZ.Items:BuildInstanceData(liveInstance, item, liveInstance.owner)
        end
    end
    
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

local function applyItemColor(item, colorData)
    if not item or not colorData or type(colorData) ~= "table" then return false end

    local visual = item.getVisual and item:getVisual() or nil
    local clothingItem = item.getClothingItem and item:getClothingItem() or nil
    local r = tonumber(colorData.r)
    local g = tonumber(colorData.g)
    local b = tonumber(colorData.b)
    local a = tonumber(colorData.a) or 1.0

    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return false
    end

    if clothingItem and clothingItem.getAllowRandomTint and clothingItem:getAllowRandomTint() and visual and visual.setTint and ImmutableColor and ImmutableColor.new then
        local immutableColor = ImmutableColor.new(r, g, b, a)
        visual:setTint(immutableColor)
        return true
    end

    if item.setCustomColor then item:setCustomColor(true) end
    if item.setColor and Color and Color.new then
        item:setColor(Color.new(r, g, b, a))
    end

    if visual and visual.setTint and ImmutableColor and ImmutableColor.new then
        visual:setTint(ImmutableColor.new(r, g, b, a))
    end

    return true
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
            applied = true
        end
    end

    -- Validate color is a proper table with required fields
    if itemData.color and type(itemData.color) == "table" and itemData.color.r and itemData.color.g and itemData.color.b then
        if applyItemColor(item, itemData.color) then
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

    if applied and item.synchWithVisual and type(item.synchWithVisual) == "function" then
        pcall(function()
            item:synchWithVisual()
        end)
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
    if itemData.color and type(itemData.color) == "table" then
        applyItemColor(item, itemData.color)
    end

    -- Restore texture choice for items that use IconsForTexture / WorldStaticModelsByIndex
    -- This is especially important for wallets and other non-clothing inventory items.
    if itemData.textureChoice ~= nil then
        local visual = item.getVisual and item:getVisual() or nil
        if visual and visual.setTextureChoice and type(visual.setTextureChoice) == "function" then
            local ok = pcall(function()
                visual:setTextureChoice(itemData.textureChoice)
            end)

            if ok and item.synchWithVisual and type(item.synchWithVisual) == "function" then
                pcall(function()
                    item:synchWithVisual()
                end)
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
                        local bullet = createWorldItem(item:getInventory(), bulletData.type)
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
                local containerItem = createWorldItem(containerInventory, containerItemData.id)
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
        print("[FrameworkZ] DEBUG: resolveBodyLocation('" .. tostring(slot) .. "') via ItemBodyLocation.get failed (ok=" .. tostring(ok) .. ", location=" .. tostring(location) .. ")")
    else
        print("[FrameworkZ] DEBUG: resolveBodyLocation('" .. tostring(slot) .. "') skipped ItemBodyLocation.get: ItemBodyLocation=" .. tostring(ItemBodyLocation) .. ", ResourceLocation=" .. tostring(ResourceLocation))
    end

    if ItemBodyLocation and type(ItemBodyLocation) == "table" then
        local enumLike = slot:gsub("([a-z0-9])([A-Z])", "%1_%2"):upper()
        if ItemBodyLocation[enumLike] then
            return ItemBodyLocation[enumLike]
        end
    end

    print("[FrameworkZ] DEBUG: resolveBodyLocation('" .. tostring(slot) .. "') could not resolve to ItemBodyLocation, falling back to raw string")
    return slot
end

local function safeGetWornItem(isoPlayer, slot)
    if not isoPlayer or not slot then return nil end

    -- NOTE: this build's getWornItem() requires an actual ItemBodyLocation object -- passing a
    -- plain String throws "expected argument of type ItemBodyLocation, got String". Always resolve
    -- first; do not attempt the plain string (see CharacterView.lua for the same requirement).
    local function tryGet(location)
        if not location or not isoPlayer.getWornItem then return nil end
        local ok, value = pcall(function()
            return isoPlayer:getWornItem(location)
        end)
        if ok then return value end
        return nil
    end

    local result = tryGet(resolveBodyLocation(slot))
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

    -- NOTE: pcall only proves setWornItem() didn't throw -- PZ can silently no-op on a
    -- bad/wrong-type location without erroring. Always verify the item actually landed in the
    -- slot via getWornItem(), otherwise callers report "success" while equipping nothing.
    -- Also: this build's setWornItem() requires an actual ItemBodyLocation object, not a String
    -- (see CharacterView.lua) -- resolveBodyLocation() must always be applied before calling.
    local function trySet(location, targetItem)
        if not location or not isoPlayer.setWornItem then return false end
        local ok = pcall(function()
            isoPlayer:setWornItem(location, targetItem)
        end)
        if not ok then return false end

        local ok2, wornNow = pcall(function()
            return isoPlayer:getWornItem(location)
        end)
        return ok2 and wornNow == targetItem
    end

    -- For items with specific body locations, prefer that
    if item.getBodyLocation and item:getBodyLocation() then
        if trySet(resolveBodyLocation(item:getBodyLocation()), item) then
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
        local altSlot = alternativeSlots[slot]
        return trySet(resolveBodyLocation(altSlot), item)
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

    local inventoryData = { items = {} }
    local inventory = isoPlayer:getInventory():getItems()

    local equippedSlots = {}
    for _, slotName in pairs(self.SlotLookup) do
        local wornItem = safeGetWornItem(isoPlayer, slotName)
        if wornItem then equippedSlots[wornItem] = slotName end
    end

    local primaryItem = isoPlayer.getPrimaryHandItem and isoPlayer:getPrimaryHandItem() or nil
    local secondaryItem = isoPlayer.getSecondaryHandItem and isoPlayer:getSecondaryHandItem() or nil

    for i = 0, inventory:size() - 1 do
        local item = inventory:get(i)
        local serialized, itemData = pcall(self.ExtractItemData, self, item)
        if serialized and itemData then
            itemData.equippedSlot = equippedSlots[item]
            if item == primaryItem then itemData.primaryHand = true end
            if item == secondaryItem then itemData.secondaryHand = true end
            table.insert(inventoryData.items, itemData)
        else
            local itemType = item and item.getFullType and item:getFullType() or "<unknown>"
            return nil, "Failed to serialize inventory item '" .. tostring(itemType) .. "': " .. tostring(itemData)
        end
    end

    local total, frameworkItems = countInventoryPayload(inventoryData.items)
    local message = "Saved " .. tostring(total) .. " inventory item(s), including " .. tostring(frameworkItems) .. " FrameworkZ item(s)."
    print("[FrameworkZ] " .. message)
    return inventoryData, message
end

--! \brief Restore character inventory and equipment data
--! \param character \table The character object
--! \param inventoryData \table The saved inventory data
--! \param itemManifest \table Optional server-created item IDs to bind on the client
--! \return \boolean Whether restoration was successful
function FrameworkZ.Inventories:Restore(character, inventoryData, itemManifest)
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

    local itemsData = inventoryData.items
    if type(itemsData) ~= "table" then
        return false, "Inventory payload is missing its items list."
    end

    pcall(function()
        if isoPlayer and isoPlayer.clearWornItems then
            isoPlayer:clearWornItems()
        end
    end)

    local useSynchronizedItems = type(itemManifest) == "table"
    if useSynchronizedItems then
        itemManifest = normalizeItemManifest(itemManifest)
    else
        pcall(function()
            local inventory = isoPlayer and isoPlayer.getInventory and isoPlayer:getInventory()
            if inventory and inventory.clear then
                inventory:clear()
            end
        end)
    end

    local runtimeInventory = FrameworkZ.Inventories:New(isoPlayer:getUsername())
    character:SetInventory(runtimeInventory)
    character:SetInventoryID(runtimeInventory.id)
    runtimeInventory:Initialize()

    -- The server is the sole authority for creating character equipment. The client only ever
    -- binds to items the server already created and networked -- it never fabricates its own,
    -- because a client-created item has no server-assigned ID and can never be validated for
    -- equip/unequip/drop, leaving a permanent duplicate "ghost" item behind.
    local isAuthoritative = type(isServer) == "function" and isServer()

    local resolvedItems = {}
    local pendingLookups = {}
    local claimedItemIDs = {}

    for itemIndex, itemData in ipairs(itemsData) do
        local manifestEntry = useSynchronizedItems and itemManifest[itemIndex] or nil

        if manifestEntry and manifestEntry.worldItemID then
            local found = isoPlayer:getInventory():getItemById(manifestEntry.worldItemID)
            if found then
                claimedItemIDs[found:getID()] = true
                resolvedItems[itemIndex] = found
            else
                pendingLookups[itemIndex] = manifestEntry.worldItemID
            end
        elseif isAuthoritative and itemData.id then
            local created = createWorldItem(isoPlayer:getInventory(), itemData.id)
            if created then
                claimedItemIDs[created:getID()] = true
                resolvedItems[itemIndex] = created
            end
        end
    end

    -- Batch-wait once for every still-pending item instead of racing each one against its own
    -- short timeout. The engine's own container sync for a brand-new character's starting items
    -- lags behind spawn/teleport until network interest catches up with the new position -- it's
    -- slow, not instantaneous, so give it a real window. Client-only: the server always resolves
    -- (or creates) its own items directly above and never has a manifest to wait on, and WaitUntil
    -- itself requires a running Awaits coroutine, which this server-side RPC handler is not.
    if tableHasEntries(pendingLookups) and type(isClient) == "function" and isClient() then
        FrameworkZ.Awaits:WaitUntil(function()
            local stillPending = false
            for itemIndex, worldItemID in pairs(pendingLookups) do
                local found = isoPlayer:getInventory():getItemById(worldItemID)
                if found then
                    claimedItemIDs[found:getID()] = true
                    resolvedItems[itemIndex] = found
                    pendingLookups[itemIndex] = nil
                else
                    stillPending = true
                end
            end
            return not stillPending
        end, 300)
    end

    -- Fallback: a worldItemID may not survive identically to the client (e.g. reassigned on
    -- sync). Claim the first as-yet-unclaimed item of the same type before giving up -- this
    -- still only binds to a real, server-created item, it never fabricates one.
    for itemIndex, worldItemID in pairs(pendingLookups) do
        local itemData = itemsData[itemIndex]
        local liveItems = isoPlayer:getInventory():getItems()
        for i = 0, liveItems:size() - 1 do
            local candidate = liveItems:get(i)
            if candidate:getFullType() == itemData.id and not claimedItemIDs[candidate:getID()] then
                claimedItemIDs[candidate:getID()] = true
                resolvedItems[itemIndex] = candidate
                pendingLookups[itemIndex] = nil
                break
            end
        end
    end

    local restoredItems = {}
    local restoredManifest = {}
    local restored, failed, pending = 0, 0, 0

    for itemIndex, itemData in ipairs(itemsData) do
        local restoredItem = resolvedItems[itemIndex]

        if restoredItem then
            self:RestoreItemData(restoredItem, itemData)
            -- Indexed by itemIndex (not appended) so a failure anywhere doesn't shift every
            -- later entry out of alignment with itemsData when this manifest is replayed.
            table.insert(restoredItems, { item = restoredItem, data = itemData })
            restoredManifest[itemIndex] = {
                id = itemData.id,
                worldItemID = restoredItem:getID()
            }
            restored = restored + 1
        elseif pendingLookups[itemIndex] then
            -- The server already confirmed this item exists (and it stays in restoredManifest
            -- for the next restore attempt); the client just hasn't seen the engine's own sync
            -- for it yet. That's a timing issue, not a data problem, so don't fail the whole
            -- character load over it -- and don't fabricate a duplicate to paper over it either.
            pending = pending + 1
            restoredManifest[itemIndex] = useSynchronizedItems and itemManifest[itemIndex] or nil
            print("[FrameworkZ] Notice: Saved item #" .. tostring(itemIndex) .. " ('" .. tostring(itemData.id) .. "') confirmed by the server but not yet visible locally; it will appear once the engine's item sync catches up.")
        else
            failed = failed + 1

            if useSynchronizedItems then
                print("[FrameworkZ] Warning: Could not bind saved item #" .. tostring(itemIndex) .. " ('" .. tostring(itemData.id) .. "') to a manifest entry.")
            end
        end
    end

    local equipped, equipmentFailed = 0, 0
    for _, entry in ipairs(restoredItems) do
        if entry.data.equippedSlot then
            if safeSetWornItem(isoPlayer, entry.data.equippedSlot, entry.item) then
                equipped = equipped + 1
                self:ApplyEquipmentColor(entry.item, entry.data)
            else
                equipmentFailed = equipmentFailed + 1
                print("[FrameworkZ] Warning: Failed to equip '" .. tostring(entry.data.id) .. "' in slot '" .. tostring(entry.data.equippedSlot) .. "'.")
            end
        end
        if entry.data.primaryHand then isoPlayer:setPrimaryHandItem(entry.item) end
        if entry.data.secondaryHand then isoPlayer:setSecondaryHandItem(entry.item) end
    end

    if equipped > 0 and isoPlayer.resetModel then
        isoPlayer:resetModel()
    end

    local logicalRestored, logicalFailed = self:RebuildFrameworkZRuntimeIndex(character)
    local synchronized, synchronizationFailed = 0, 0
    if isAuthoritative then
        -- The very first sync right after spawn/teleport is often dropped because the client's
        -- network interest hasn't caught up with the new position yet -- resend a few times over
        -- the next couple of seconds instead of trusting a single fire-and-forget attempt.
        local function resendAll()
            for _, entry in ipairs(restoredItems) do
                if type(sendAddItemToContainer) == "function" then
                    pcall(function()
                        sendAddItemToContainer(isoPlayer:getInventory(), entry.item)
                    end)
                end
            end
        end

        local sentFirstRound = pcall(resendAll)
        synchronized = sentFirstRound and #restoredItems or 0
        synchronizationFailed = sentFirstRound and 0 or #restoredItems

        local resendRoundsRemaining = 6
        local ticksPerRound = 10
        local ticksUntilNextRound = ticksPerRound
        local resendCallback

        resendCallback = function()
            ticksUntilNextRound = ticksUntilNextRound - 1

            if ticksUntilNextRound <= 0 then
                resendRoundsRemaining = resendRoundsRemaining - 1
                pcall(resendAll)
                ticksUntilNextRound = ticksPerRound

                if resendRoundsRemaining <= 0 then
                    Events.OnTick.Remove(resendCallback)
                end
            end
        end

        Events.OnTick.Add(resendCallback)
    end

    local expectedTotal, expectedFrameworkItems = countInventoryPayload(itemsData)
    local message = "Restored " .. tostring(restored) .. " top-level item(s) from " .. tostring(expectedTotal) .. " total saved item(s), " .. tostring(failed) .. " failed, " .. tostring(pending) .. " pending sync; equipped " .. tostring(equipped) .. " item(s), " .. tostring(equipmentFailed) .. " failed; indexed " .. tostring(logicalRestored) .. " of " .. tostring(expectedFrameworkItems) .. " FrameworkZ item(s), " .. tostring(logicalFailed) .. " failed."
    if isAuthoritative then
        message = message .. " Synchronized " .. tostring(synchronized) .. " item(s), " .. tostring(synchronizationFailed) .. " failed."
    end
    print("[FrameworkZ] " .. message)
    return failed == 0 and logicalFailed == 0 and logicalRestored == expectedFrameworkItems and synchronizationFailed == 0, message, restoredManifest
end

--! \brief Rebuild the derived FrameworkZ runtime index from restored world items.
--! \details InventoryData remains the only persisted source of truth. Runtime instance IDs are
--! recreated on every restore and are never read from the save as authoritative identifiers.
function FrameworkZ.Inventories:RebuildFrameworkZRuntimeIndex(character)
    if not character then
        return 0, 1
    end

    local isoPlayer = character.GetIsoPlayer and character:GetIsoPlayer() or nil
    if not isoPlayer or not isoPlayer.getInventory then
        return 0, 1
    end

    local inventoryObj = character.GetInventory and character:GetInventory() or nil
    if not inventoryObj or type(inventoryObj.AddItem) ~= "function" then
        return 0, 1
    end

    local rootInventory = isoPlayer:getInventory()
    local rootItems = rootInventory and rootInventory:getItems() or nil
    if not rootItems then
        return 0, 1
    end

    local username = isoPlayer:getUsername()
    FrameworkZ.Items:ClearOwnerInstances(username)

    local worldItems = {}
    local pendingContainers = { rootInventory }
    local visitedContainers = {}
    while #pendingContainers > 0 do
        local container = table.remove(pendingContainers)
        if container and not visitedContainers[container] then
            visitedContainers[container] = true
            local containerItems = container.getItems and container:getItems() or nil
            if containerItems then
                for i = 0, containerItems:size() - 1 do
                    local worldItem = containerItems:get(i)
                    if worldItem then
                        table.insert(worldItems, worldItem)
                        local nestedContainer = worldItem.getItemContainer and worldItem:getItemContainer() or nil
                        if not nestedContainer and worldItem.getItems then
                            nestedContainer = worldItem:getItems()
                        end
                        if nestedContainer then table.insert(pendingContainers, nestedContainer) end
                    end
                end
            end
        end
    end

    local indexed, failed = 0, 0
    for _, worldItem in ipairs(worldItems) do
        local modData = worldItem.getModData and worldItem:getModData() or nil
        local storedData = modData and modData["FZ_ITM"] or nil
        if type(storedData) == "table" and storedData.uniqueID then
            local runtimeItem = FrameworkZ.Items:BuildTransientInstanceFromStoredData(storedData, worldItem)
            if type(runtimeItem) == "table" then
                local instanceID, instance = FrameworkZ.Items:AddInstance(runtimeItem, isoPlayer, worldItem)
                if instance and instanceID then
                    local initialized, initializeError = pcall(instance.OnInstanced, instance, isoPlayer, worldItem)
                    if initialized then
                        -- OnInstanced rebuilds runtime-only state, but persisted identity and
                        -- custom values remain authoritative across reconnects and transfers.
                        FrameworkZ.Items:ApplyStoredInstanceData(instance, storedData)
                        local instanceData = FrameworkZ.Items:BuildInstanceData(instance, worldItem, username)
                        FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)
                        inventoryObj:AddItem(instance)
                        indexed = indexed + 1
                    else
                        failed = failed + 1
                        print("[FrameworkZ] Failed to initialize restored item '" .. tostring(instance.uniqueID) .. "': " .. tostring(initializeError))
                    end
                else
                    failed = failed + 1
                end
            else
                failed = failed + 1
            end
        end
    end

    return indexed, failed
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Inventories)
