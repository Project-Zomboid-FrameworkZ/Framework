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
FrameworkZ.Inventories.__index = FrameworkZ.Inventories
FrameworkZ.Inventories.List = {}
FrameworkZ.Inventories.Types = {
    Character = "Character",
    Container = "Container",
    Vehicle = "Vehicle"
}

-- O(1) lookup table for enum to slot name conversion - uses Characters.SlotList for proper PZ compatibility
-- Build SlotLookup using available data without relying on undefined FZ_SLOT_* globals.
-- Priority:
--  1) FrameworkZ.Characters.SlotList if provided elsewhere (full custom mapping)
--  2) Auto-map each enum to its own string value via FrameworkZ.Enumerations.EquipmentSlots
--     (since our enums resolve to Project Zomboid body location strings like "Hat", "Mask", etc.)
do
    local slotLookup = {}
    if FrameworkZ.Characters and FrameworkZ.Characters.SlotList and next(FrameworkZ.Characters.SlotList) then
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

-- Call initialization function when module loads
initializeFrameworkZItemLookup()

-- Helper function to check if an item type is a FrameworkZ item - O(1) lookup
local function isFrameworkZItemType(itemType)
    return FrameworkZ.Inventories.FrameworkZItemTypeLookup[itemType] ~= nil
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

-- Helper function to extract comprehensive item data including condition, color, magazine content, etc.
local function extractItemData(item)
    if not item then return nil end
    
    local itemData = {
        id = item:getFullType(),
        type = item:getType(),
        displayName = item:getDisplayName()
    }
    
    -- Basic item properties
    if item.getCondition then
        itemData.condition = item:getCondition()
    end
    
    if item.getConditionMax then
        itemData.maxCondition = item:getConditionMax()
    end
    
    -- Color/Tint information
    if item.getColor then
        local color = item:getColor()
        if color then
            itemData.color = {
                r = color:getRedFloat(),
                g = color:getGreenFloat(), 
                b = color:getBlueFloat(),
                a = color:getAlphaFloat()
            }
        end
    end
    
    -- Clothing specific properties
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
    
    if item.getHolesNumber then
        itemData.holes = item:getHolesNumber()
    end
    
    if item.getPatchesNumber then
        itemData.patches = item:getPatchesNumber()
    end
    
    -- Weapon specific properties
    if item:getType() and (item:getType():contains("Weapon") or item:getCategory() == "Weapon") then
        if item.getConditionLowerChance then
            itemData.conditionLowerChance = item:getConditionLowerChance()
        end
        
        if item.getBloodLevel then
            itemData.weaponBloodLevel = item:getBloodLevel()
        end
        
        -- Magazine and ammunition for firearms
        if item.getMagazineType then
            local magazineType = item:getMagazineType()
            if magazineType and magazineType ~= "" then
                itemData.magazineType = magazineType
                
                if item.getCurrentAmmoCount then
                    itemData.ammoCount = item:getCurrentAmmoCount()
                end
                
                if item.getMaxAmmo then
                    itemData.maxAmmo = item:getMaxAmmo()
                end
                
                if item.getAmmoType then
                    itemData.ammoType = item:getAmmoType()
                end
                
                -- Save individual bullets if it's a magazine
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
    
    -- Food specific properties
    if item:getType() and (item:getType():contains("Food") or item:getCategory() == "Food") then
        if item.getHungerChange then
            itemData.hungerChange = item:getHungerChange()
        end
        
        if item.getBoredomChange then
            itemData.boredomChange = item:getBoredomChange()
        end
        
        if item.getUnhappyChange then
            itemData.unhappyChange = item:getUnhappyChange()
        end
        
        if item.isFrozen then
            itemData.frozen = item:isFrozen()
        end
        
        if item.getAge then
            itemData.age = item:getAge()
        end
        
        if item.getOffAge then
            itemData.offAge = item:getOffAge()
        end
        
        if item.getOffAgeMax then
            itemData.offAgeMax = item:getOffAgeMax()
        end
    end
    
    -- Container specific properties
    if item:getType() and (item:getType():contains("Container") or item:getCategory() == "Container") then
        if item.getCapacity then
            itemData.capacity = item:getCapacity()
        end
        
        if item.getItems then
            local containerItems = item:getItems()
            if containerItems and containerItems:size() > 0 then
                itemData.containerItems = {}
                for i = 0, containerItems:size() - 1 do
                    local containerItem = containerItems:get(i)
                    if containerItem then
                        -- Recursively save container contents
                        table.insert(itemData.containerItems, extractItemData(containerItem))
                    end
                end
            end
        end
    end
    
    -- Literature/Book specific properties
    if item:getType() and (item:getType():contains("Book") or item:getType():contains("Literature") or item:getCategory() == "Literature") then
        if item.getNumberOfPages then
            itemData.numberOfPages = item:getNumberOfPages()
        end
        
        if item.getPageToWrite then
            itemData.pageToWrite = item:getPageToWrite()
        end
        
        if item.getLockedBy then
            itemData.lockedBy = item:getLockedBy()
        end
    end
    
    -- Save mod data
    local modData = item:getModData()
    if modData and next(modData) then
        itemData.modData = {}
        for key, value in pairs(modData) do
            itemData.modData[key] = value
        end
    end
    
    -- Save uses/remaining uses
    if item.getUsedDelta then
        itemData.usedDelta = item:getUsedDelta()
    end
    
    if item.getUses then
        itemData.uses = item:getUses()
    end
    
    -- Custom properties that might be set
    if item.getWeight then
        itemData.weight = item:getWeight()
    end
    
    if item.getActualWeight then
        itemData.actualWeight = item:getActualWeight()
    end
    
    return itemData
end

-- Helper function to restore comprehensive item data
local function restoreItemData(item, itemData)
    if not item or not itemData then return false end
    
    -- Restore basic properties
    if itemData.condition and item.setCondition then
        item:setCondition(itemData.condition)
    end
    
    if itemData.maxCondition and item.setConditionMax then
        item:setConditionMax(itemData.maxCondition)
    end
    
    -- Restore color/tint
    if itemData.color and item.setColor then
        -- Create color using ColorInfo or direct color values
        if item.setColorRed and item.setColorGreen and item.setColorBlue then
            item:setColorRed(itemData.color.r)
            item:setColorGreen(itemData.color.g) 
            item:setColorBlue(itemData.color.b)
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
    
    -- Restore container contents
    if item:getType() and (item:getType():contains("Container") or item:getCategory() == "Container") and itemData.containerItems then
        local containerInventory = item:getItems()
        if containerInventory then
            containerInventory:clear()
            for _, containerItemData in ipairs(itemData.containerItems) do
                local containerItem = containerInventory:AddItem(containerItemData.id)
                if containerItem then
                    restoreItemData(containerItem, containerItemData)
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
    
    -- Restore mod data
    if itemData.modData then
        local modData = item:getModData()
        for key, value in pairs(itemData.modData) do
            modData[key] = value
        end
    end
    
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
local function safeGetWornItem(isoPlayer, slot)
    if not isoPlayer or not slot then return nil end
    
    -- Handle special cases and common slot variations
    local actualSlot = slot
    
    -- Try different slot name variations if needed
    local success, result = pcall(function()
        return isoPlayer:getWornItem(actualSlot)
    end)
    
    if success then
        return result
    else
        -- Try alternative slot names for compatibility
        local alternativeSlots = {
            ["TorsoExtraVest"] = "TorsoExtra",
            ["TorsoExtra"] = "TorsoExtraVest"
        }
        
        if alternativeSlots[slot] then
            local altSuccess, altResult = pcall(function()
                return isoPlayer:getWornItem(alternativeSlots[slot])
            end)
            if altSuccess then
                return altResult
            end
        end
        
        return nil
    end
end

-- Helper function to safely set worn item with error handling
local function safeSetWornItem(isoPlayer, slot, item)
    if not isoPlayer or not slot or not item then return false end
    
    local success, result = pcall(function()
        -- For items with specific body locations, use that
        if item:getBodyLocation() then
            isoPlayer:setWornItem(item:getBodyLocation(), item)
        else
            -- Otherwise use the slot name
            isoPlayer:setWornItem(slot, item)
        end
        return true
    end)
    
    if success then
        return result
    else
        -- Try alternative slot names for compatibility
        local alternativeSlots = {
            ["TorsoExtraVest"] = "TorsoExtra",
            ["TorsoExtra"] = "TorsoExtraVest"
        }
        
        if alternativeSlots[slot] then
            local altSuccess, altResult = pcall(function()
                isoPlayer:setWornItem(alternativeSlots[slot], item)
                return true
            end)
            if altSuccess then
                return altResult
            end
        end
        
        return false
    end
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

function INVENTORY:GetItems()
    return self.items
end

function INVENTORY:GetItemByUniqueID(uniqueID)
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    for _key, item in pairs(self:GetItems()) do
        if item.uniqueID == uniqueID then
            return item
        end
    end

    return false, "No item found with unique ID: " .. uniqueID
end

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

function FrameworkZ.Inventories:GetInventoryByID(id)
    if not id then return false, "No inventory ID provided." end

    local inventory = self.List[id] or nil

    if not inventory then return false, "No inventory found with ID: " .. id end

    return inventory
end

function FrameworkZ.Inventories:GetItemByUniqueID(inventoryID, uniqueID)
    if not inventoryID then return false, "No inventory ID provided." end
    if not uniqueID or uniqueID == "" then return false, "No unique ID provided." end

    local inventoryOrSuccess, inventoryMessage = self:GetInventoryByID(inventoryID)

    if not inventoryOrSuccess then return inventoryOrSuccess, inventoryMessage end

    local itemOrSuccess, itemMessage = inventoryOrSuccess:GetItemByUniqueID(uniqueID)

    return itemOrSuccess, itemMessage
end

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
    if not items then return false, "No items to add to inventory." end

    -- Recursive function to rebuild fields and inherit methods
    local function rebuildAndInherit(item, definition)
        -- Ensure item inherits methods and properties from the definition
        setmetatable(item, { __index = definition })

        -- Recursively rebuild all fields
        for key, value in pairs(definition) do
            if type(value) == "table" then
                -- Ensure item[key] exists and is a table, then recurse
                if item[key] == nil then
                    item[key] = {}
                end

                rebuildAndInherit(item[key], value)
            elseif type(value) == "function" then
                -- Ensure functions are inherited and retain their object context
                item[key] = value
            elseif item[key] == nil then
                -- Copy over non-function and non-table fields if missing
                item[key] = value
            end
        end
    end

    -- Rebuild an individual item
    local function rebuildItem(item)
        if type(item) ~= "table" then return end -- Ensure item is a table

        -- Fetch the item definition
        local itemDefinition = FrameworkZ.Items:GetItemByUniqueID(item.uniqueID)
        if not itemDefinition then return end -- Exit if no definition is found

        -- Rebuild fields and inherit methods
        rebuildAndInherit(item, itemDefinition)

        -- Create and link the world item
        local success, message, worldItem = FrameworkZ.Items:CreateWorldItem(isoPlayer, item.itemID)
        if success and worldItem then
            local instanceID, itemInstance = FrameworkZ.Items:AddInstance(item, isoPlayer, worldItem)

            -- Define instance data
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

            -- Link the world item to the instance data
            FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)

            -- Add the item instance to the inventory
            inventory:AddItem(itemInstance)

            -- Call OnInstance if it exists
            if item.OnInstance then
                item:OnInstance(isoPlayer, inventory, worldItem)
            end
        end
    end

    -- Iterate through and rebuild each item
    for _, item in pairs(items) do
        rebuildItem(item)
    end

    return true, "Inventory rebuilt.", inventory
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

    local inventoryData = {}
    
    -- Save physical inventory (with comprehensive item data)
    local physicalItems = {}
    local inventory = isoPlayer:getInventory():getItems()
    for i = 0, inventory:size() - 1 do
        local item = inventory:get(i)
        if not item:getModData()["FZ_ITM"] then
            -- Use enhanced item data extraction
            local itemData = extractItemData(item)
            if itemData then
                table.insert(physicalItems, itemData)
            end
        end
    end
    inventoryData.INVENTORY_PHYSICAL = physicalItems

    -- Save logical inventory with equipped state information
    local logicalInventoryData = character:GetInventory() and character:GetInventory():GetSaveableData() or {}
    
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
    if logicalInventoryData then
        logicalInventoryData.equippedItems = equippedFrameworkZItems
    end
    inventoryData.INVENTORY_LOGICAL = logicalInventoryData

    -- Save physical equipment (with comprehensive item data) using SlotLookup and O(1) lookup
    local function saveEquipmentSlot(slotName, slotEnum)
        local equippedItem = safeGetWornItem(isoPlayer, slotName)
        if equippedItem then
            local itemType = equippedItem:getFullType()
            
            -- O(1) check if item is FrameworkZ type
            if isFrameworkZItemType(itemType) then
                print("[FrameworkZ] Skipping FrameworkZ item in equipment slot " .. slotName .. " (enum: " .. slotEnum .. "). Logical inventory handles this.")
                return nil
            else
                -- Use enhanced item data extraction for equipment
                return extractItemData(equippedItem)
            end
        end
        return nil
    end

    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            -- Use enum as primary key for consistency with character creation
            inventoryData[slotEnum] = saveEquipmentSlot(slotName, slotEnum)
        end
    end

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

    local success = true
    local messages = {}

    -- Restore physical inventory with comprehensive item data
    if inventoryData.INVENTORY_PHYSICAL then
        for _, itemData in pairs(inventoryData.INVENTORY_PHYSICAL) do
            if itemData.id then
                local restoredItem = isoPlayer:getInventory():AddItem(itemData.id)
                if restoredItem then
                    -- Restore all the detailed item properties
                    restoreItemData(restoredItem, itemData)
                end
            end
        end
        table.insert(messages, "Physical inventory restored with detailed properties")
    end

    -- Restore logical inventory
    if inventoryData.INVENTORY_LOGICAL then
        local newInventory = FrameworkZ.Inventories:New(isoPlayer:getUsername())
        local rebuildSuccess, rebuildMessage, rebuiltInventory = self:Rebuild(isoPlayer, newInventory, inventoryData.INVENTORY_LOGICAL or nil)
        
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

    -- Restore all equipment (both physical and logical) using unified method
    local equipSuccess, equipMessage = self:RestoreEquipment(character, inventoryData)
    if equipSuccess then
        table.insert(messages, equipMessage)
    else
        table.insert(messages, "Warning: " .. equipMessage)
    end
    
    return success, table.concat(messages, "; ")
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

    -- First, restore physical equipment (non-FrameworkZ items) using SlotLookup
    for slotEnum, slotName in pairs(self.SlotLookup) do
        if slotName then
            -- Try enum key first (from character creation), then legacy string key for backward compatibility
            local equipmentData = inventoryData[slotEnum] or inventoryData["EQUIPMENT_SLOT_" .. string.upper(slotName:gsub("([A-Z])", "_%1"):gsub("^_", ""))]
            
            if equipmentData and equipmentData.id then
                -- O(1) check if this equipment item is a FrameworkZ item
                if not isFrameworkZItemType(equipmentData.id) then
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
                            -- Restore comprehensive item data for newly created equipment
                            restoreItemData(foundItem, equipmentData)
                            print("[FrameworkZ] Created missing physical item '" .. equipmentData.id .. "' for equipment restoration with detailed properties")
                        end
                    end
                    
                    -- If found or created, equip it
                    if foundItem then
                        if safeSetWornItem(isoPlayer, slotName, foundItem) then
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
                local fzItemUniqueID = isFrameworkZItemType(equipmentData.id)
                
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
    
    -- Get character data from the character object to access color information
    local player = character:GetPlayer()
    local characterData = nil
    if player then
        characterData = player:GetCharacterDataByID(character:GetID())
    end
    
    if characterData then
        -- Apply colors to equipped items using resolved SlotLookup mapping
        for slotEnum, slotName in pairs(self.SlotLookup) do
            local slotData = characterData[slotEnum]
            if slotName and slotData and slotData.color then
                local wornItem = isoPlayer:getWornItem(slotName)
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
    else
        print("[FrameworkZ] Warning: Could not retrieve character data for color application")
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
                    isoPlayer:setWornItem(equipmentInfo.slot, worldItem)
                    equipSuccess = true
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
