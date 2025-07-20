FrameworkZ = FrameworkZ or {}

FrameworkZ.Interfaces = {}
FrameworkZ.Interfaces.List = {}
FrameworkZ.Interfaces.__index = FrameworkZ.Interfaces
FrameworkZ.Interfaces = FrameworkZ.Foundation:NewModule(FrameworkZ.Interfaces, "Interfaces")

function FrameworkZ.Interfaces:New(uniqueID)
    if not uniqueID or uniqueID == "" then return false end

    local object = {
        uniqueID = uniqueID,
    }

    setmetatable(object, {})

	return object
end

function FrameworkZ.Interfaces:Register(tbl, index)
    self.List[index] = tbl
end

function FrameworkZ.Interfaces:GetUI(index)
    return self.List[index]
end

function FrameworkZ.Interfaces:Initialize()
    for k, v in pairs(self.List) do
        FrameworkZ.UI[k] = FrameworkZ.Utilities:MergeTables(FrameworkZ.UI[k], ISPanel:derive(k))
    end
end
