--! \page globalVars Global Variables
--! \section Inventories Inventories
--! ProjectFramework.Inventories\n
--! See Inventories for the module on inventories.\n\n
--! ProjectFramework.Inventories.List\n
--! A list of all instanced inventories in the game.\n\n
--! ProjectFramework.Inventories.Types\n
--! The types of inventories that can be created.

ProjectFramework = ProjectFramework or {}

--! \brief The Inventories module for ProjectFramework. Defines and interacts with INVENTORY object.
--! \class Inventories
ProjectFramework.Inventories = {}
ProjectFramework.Inventories.__index = ProjectFramework.Inventories
ProjectFramework.Inventories.List = {}
ProjectFramework.Inventories.Types = {
    Character = "Character",
    Container = "Container",
    Vehicle = "Vehicle"
}
ProjectFramework.Inventories = ProjectFramework.Foundation:NewModule(ProjectFramework.Inventories, "Inventories")

--! \brief Inventory class for ProjectFramework.
--! \class INVENTORY
local INVENTORY = {}
INVENTORY.__index = INVENTORY

--! \brief Initialize an inventory.
--! \return \string The inventory's ID.
function INVENTORY:Initialize()
    return ProjectFramework.Inventories:Initialize(self.id, self)
end

--! \brief Add an item to the inventory.
--! \details Note: This does not add a world item, it simply adds it to the inventory's object. Please use CHARACTER::GiveItem(itemID) to add an item to a character's inventory along with the world item.
--! \param item \string The item's ID.
--! \see CHARACTER::GiveItem(itemID)
function INVENTORY:AddItem(item)
    self.items[#self.items + 1] = item
end

--! \brief Add multiple items to the inventory.
--! \details Note: This does not add a world item, it simply adds it to the inventory's object. Please use CHARACTER::GiveItems(itemID) to add an items to a character's inventory along with the world item.
--! \param itemID \string The item's ID.
--! \param quantity \integer The quantity of the item to add.
--! \see CHARACTER::GiveItems(itemID)
function INVENTORY:AddItems(itemID, quantity)
    for i = 1, quantity do
        self:AddItem(itemID)
    end
end

--! \brief Get the inventory's name.
--! \return \string The inventory's name.
function INVENTORY:GetName()
    return self.name or "Someone's Inventory"
end

--! \brief Create a new inventory object.
--! \param username \string The owner's username. Can be nil for no owner.
--! \param type \string The type of inventory. Can be nil, but creates a character inventory type by default. Refer to ProjectFramework.Inventories.Types table for available types.
--! \param id \string The inventory's ID. Can be nil for an auto generated ID (recommended).
--! \return \table The new inventory object.
function ProjectFramework.Inventories:New(username, type, id)
    if not id then
        ProjectFramework.Inventories.List[#ProjectFramework.Inventories.List + 1] = {} -- Reserve space to avoid inconsistencies.
        id = #ProjectFramework.Inventories.List
    end

    local object = {
        id = id,
        owner = username or "",
        type = type or ProjectFramework.Inventories.Types.Character,
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
function ProjectFramework.Inventories:Initialize(id, object)
    ProjectFramework.Inventories.List[id] = object

    return id
end

function ProjectFramework.Inventories:GetInventoryByID(id)
    local inventory = ProjectFramework.Inventories.List[id] or nil
    
    return inventory
end
