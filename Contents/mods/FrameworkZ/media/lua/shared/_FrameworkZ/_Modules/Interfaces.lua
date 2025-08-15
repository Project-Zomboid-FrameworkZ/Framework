FrameworkZ = FrameworkZ or {}

--! \module FrameworkZ.Interfaces
FrameworkZ.Interfaces = {}
FrameworkZ.Interfaces.List = {}
FrameworkZ.Interfaces.__index = FrameworkZ.Interfaces
FrameworkZ.Interfaces = FrameworkZ.Foundation:NewModule(FrameworkZ.Interfaces, "Interfaces")

function FrameworkZ.Interfaces:New(uniqueID, parentTable)
    local object = {
        UniqueID = uniqueID or "DefaultInterface",
        Parent = parentTable or nil
    }

    setmetatable(object, {})

    return object
end

function FrameworkZ.Interfaces:Register(tbl, index)
    if self.List[index] then
        print("[FZ] Interface '" .. index .. "' is already registered. Use 'FrameworkZ.Interfaces:GetInterface(index)' to modify an already existing interface. Re-registration has been aborted.")
        return {}
    end

    self.List[index] = tbl

    return self.List[index]
end

function FrameworkZ.Interfaces:GetInterface(index)
    return self.List[index]
end

function FrameworkZ.Interfaces:Initialize()
    if not ISPanel or not ISPanel.derive then return end

    for k, v in pairs(self.List) do
        local derived = ISPanel:derive(k)
        FrameworkZ.Utilities:MergeTables(v, derived)
        setmetatable(v, getmetatable(derived))
        self.List[k] = v
    end
end
