FrameworkZ = FrameworkZ or {}

--! \module FrameworkZ.Classes
FrameworkZ.Classes = {}
FrameworkZ.Classes.__index = FrameworkZ.Classes
FrameworkZ.Classes.List = {}
FrameworkZ.Classes = FrameworkZ.Foundation:NewModule(FrameworkZ.Classes, "Classes")

--! \brief Class definition for FrameworkZ class records.
--! \class CLASS
local CLASS = {}
CLASS.__index = CLASS

--! \brief Register this CLASS instance with the module list.
--! \return \string Class ID.
function CLASS:Initialize()
	return FrameworkZ.Classes:Initialize(self.name, self)
end

--! \brief Create a new class object definition.
--! \param name \string Class ID/name.
--! \return \table The CLASS instance.
function FrameworkZ.Classes:New(name)
    local object = {
        id = name,
        name = name,
        description = "No description available.",
        limit = 0,
        members = {}
    }

    setmetatable(object, CLASS)

	return object
end

--! \brief Register a CLASS object into the module list.
--! \param id \string Class ID.
--! \param object \table CLASS instance to register.
--! \return \string Registered class ID.
function FrameworkZ.Classes:Initialize(id, object)
    self.List[id] = object

    return id
end

--! \brief Lookup a CLASS by ID.
--! \param factionID \string The class ID to fetch.
--! \return \table|nil The CLASS object or nil if missing.
function FrameworkZ.Classes:GetClassByID(factionID)
    local class = self.List[factionID] or nil
    
    return class
end
