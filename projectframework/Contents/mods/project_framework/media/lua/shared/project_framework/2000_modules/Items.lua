ProjectFramework = ProjectFramework or {}

ProjectFramework.Items = {}
ProjectFramework.Items.__index = ProjectFramework.Items
ProjectFramework.Items.List = {}
ProjectFramework.Items.Instances = {}
ProjectFramework.Items = ProjectFramework.Foundation:NewModule(ProjectFramework.Items, "Items")

local ITEM = {}
ITEM.__index = ITEM

function ITEM:Initialize()
    return ProjectFramework.Items:Initialize(self, self.id)
end

function ITEM:GetName()
    return self.name or "Unnamed Item"
end

function ProjectFramework.Items:New(id, username)
    local object = {
        id = id or "Base.Plank",
        owner = username or "",
        name = "Unnamed Item",
        description = "No description available."
    }

    setmetatable(object, ITEM)

    return object
end

function ProjectFramework.Items:Initialize(data, name)
    ProjectFramework.Items.List[name] = data

    return name
end

function ProjectFramework.Items:AddInstance(id, worldItem)
    if not ProjectFramework.Items.Instances[id] then
        ProjectFramework.Items.Instances[id] = {}
    end
    
    table.insert(ProjectFramework.Items.Instances[id], worldItem:getModData()["PFW_ITM"])
    
    return #ProjectFramework.Items.Instances[id]
end

function ProjectFramework.Items:RemoveInstance(id, instanceID)
    ProjectFramework.Items.Instances[id][instanceID] = nil
end

function ProjectFramework.Items:GetItemByID(itemID)
    local item = ProjectFramework.Items.List[itemID] or nil
    
    return item
end
