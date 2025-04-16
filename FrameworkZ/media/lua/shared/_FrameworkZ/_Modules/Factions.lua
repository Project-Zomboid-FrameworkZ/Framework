--! \page global_variables Global Variables
--! \section Factions Factions
--! FrameworkZ.Factions\n
--! See Factions for the module on factions.\n\n
--! FrameworkZ.Factions.List\n
--! A list of all instanced factions in the game and their online members.

FrameworkZ = FrameworkZ or {}

--! \brief Factions module for FrameworkZ. Defines and interacts with FACTION object.
--! \class FrameworkZ.Factions
FrameworkZ.Factions = {}
FrameworkZ.Factions.__index = FrameworkZ.Factions
FrameworkZ.Factions.List = {}
FrameworkZ.Factions = FrameworkZ.Foundation:NewModule(FrameworkZ.Factions, "Factions")

--! \brief Faction class for FrameworkZ.
--! \class FACTION
local FACTION = {}
FACTION.__index = FACTION

--! \brief Initialize a faction.
--! \return \string faction ID
function FACTION:Initialize()
	return FrameworkZ.Factions:Initialize(self.name, self)
end

--! \brief Create a new faction object.
--! \param name \string Faction name.
--! \return \table The new faction object.
function FrameworkZ.Factions:New(name)
    local object = {
        id = name,
        name = name,
        description = "No description available.",
        limit = 0,
        members = {}
    }

    setmetatable(object, FACTION)

	return object
end

--! \brief Initialize a faction.
--! \param data \table The faction object's data.
--! \param name \string The faction's name (i.e. ID).
--! \return \string The faction ID.
function FrameworkZ.Factions:Initialize(id, object)
    FrameworkZ.Factions.List[id] = object

    return id
end

--! \brief Get a faction by their ID.
--! \param factionID \string The faction's ID
--! \return \table The faction's object.
function FrameworkZ.Factions:GetFactionByID(factionID)
    local faction = FrameworkZ.Factions.List[factionID] or nil
    
    return faction
end

--! \brief Get a faction's name by their ID. Useful for getting a faction's actual name if the initialized faction ID differs from the name field.
--! \param factionID \string The faction's ID.
--! \return \string The faction's name.
function FrameworkZ.Factions:GetFactionNameByID(factionID)
    local faction = FrameworkZ.Factions.List[factionID] or nil
    
    return faction and faction.name
end
