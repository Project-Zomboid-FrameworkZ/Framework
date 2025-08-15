FrameworkZ = FrameworkZ or {}

--! \module FrameworkZ.Classes
FrameworkZ.Classes = {}
FrameworkZ.Classes.__index = FrameworkZ.Classes
FrameworkZ.Classes.List = {}
FrameworkZ.Classes = FrameworkZ.Foundation:NewModule(FrameworkZ.Classes, "Classes")

local CLASS = {}
CLASS.__index = CLASS

function CLASS:Initialize()
	return FrameworkZ.Classes:Initialize(self.name, self)
end

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

function FrameworkZ.Classes:Initialize(id, object)
    self.List[id] = object

    return id
end

function FrameworkZ.Classes:GetClassByID(factionID)
    local class = self.List[factionID] or nil
    
    return class
end
