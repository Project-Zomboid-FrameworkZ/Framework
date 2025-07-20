FrameworkZ = FrameworkZ or {}

FrameworkZ.SubClasses = {}
FrameworkZ.SubClasses.__index = FrameworkZ.SubClasses
FrameworkZ.SubClasses.List = {}
FrameworkZ.SubClasses = FrameworkZ.Foundation:NewModule(FrameworkZ.SubClasses, "SubClasses")

local SUBCLASS = {}
SUBCLASS.__index = SUBCLASS

function SUBCLASS:Initialize()
	return FrameworkZ.SubClasses:Initialize(self.name, self)
end

function FrameworkZ.SubClasses:New(name)
    local object = {
        id = name,
        name = name,
        description = "No description available.",
        limit = 0,
        members = {}
    }

    setmetatable(object, SUBCLASS)

	return object
end

function FrameworkZ.SubClasses:Initialize(id, object)
    self.List[id] = object

    return id
end

function FrameworkZ.Factions:GetClassByID(factionID)
    local class = self.List[factionID] or nil
    
    return class
end
