--! \page global_variables Global Variables
--! \section Inventories Inventories
--! FrameworkZ.Inventories\n
--! See Inventories for the module on inventories.\n\n
--! FrameworkZ.Inventories.List\n
--! A list of all instanced inventories in the game.\n\n
--! FrameworkZ.Inventories.Types\n
--! The types of inventories that can be created.

FrameworkZ = FrameworkZ or {}

--! \brief The Inventories module for FrameworkZ. Defines and interacts with INVENTORY object.
--! \class FrameworkZ.Inventories
FrameworkZ.Inventories = {}
FrameworkZ.Inventories.__index = FrameworkZ.Inventories
FrameworkZ.Inventories.List = {}
FrameworkZ.Inventories.Types = {
    Character = "Character",
    Container = "Container",
    Vehicle = "Vehicle"
}
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
    return FrameworkZ.Foundation:ProcessSaveableData(self, {}, {})
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

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Inventories)
