--! \page Features
--! \section Items Items
--! Items are an essential piece of gameplay in both Project Zomboid and FrameworkZ. While items aren't necessarily required to roleplay, they provide important mechanics and interactions that enhance the experience.
--! There are two states an item can be in: Instanced or Non-Instanced. What this means is that a non-instanced item is like a template or blueprint that is used to create actual items in the game world, where they are then considered instanced. In computer terms, imagine that a file is stored on your hard drive (non-instanced), and when you open that file its contents are moved into memory (instanced). A sort of active vs. inactive types of forms.
--! That said, an item can be instantiated (the process of creating an instance from a non-instanced blueprint).
--! Another aspect of items are item bases. A base can be defined and inherited from, allowing for the creation of new item types with shared properties and behaviors. This allows code reuse, a self-explained concept where repitious code is defined at a single source and reused by other different elements.

FrameworkZ = FrameworkZ or {}
FrameworkZ.Items = {}

FZ_EQUIP_TYPE_IDEAL = "Ideal"
FZ_EQUIP_TYPE_CLOTHING = "Clothing"
FZ_EQUIP_TYPE_PRIMARY = "Primary"
FZ_EQUIP_TYPE_SECONDARY = "Secondary"
FZ_EQUIP_TYPE_BOTH_HANDS = "BothHands"

FrameworkZ.Items.List = {}
FrameworkZ.Items.Bases = {}
FrameworkZ.Items.Instances = {}
FrameworkZ.Items.NextInstanceID = 0
FrameworkZ.Items.Subscriptions = {
    consumeOwnedInstances = "FZ_ITEMS.ConsumeOwnedInstances"
}

--! \brief An instance map. Contains references to item instances indexed by an item's unique ID and instance ID as a string for optimized lookups. Instance Map is structured as follows: [uniqueID][username][#index] = instance
FrameworkZ.Items.InstanceMap = {}
FrameworkZ.Items = FrameworkZ.Foundation:NewModule(FrameworkZ.Items, "Items")

local function patchDropWorldItemAction()
    local dropActionClass = rawget(_G, "ISDropWorldItemAction")
    if not dropActionClass or dropActionClass.__fzPatched then
        return
    end

    local originalGetDuration = dropActionClass.getDuration
    local originalNew = dropActionClass.new

    function dropActionClass:getDuration()
        if not self.item or type(self.item) ~= "table" or type(self.item.getActualWeight) ~= "function" then
            return 1
        end

        return originalGetDuration(self)
    end

    function dropActionClass:new(character, item, sq, xoffset, yoffset, zoffset, rotation, isMultiple)
        if not item or type(item) ~= "table" or type(item.getActualWeight) ~= "function" then
            local o = ISBaseTimedAction.new(self, character)
            o.character = character
            o.item = item
            o.sq = sq
            o.xoffset = xoffset
            o.yoffset = yoffset
            o.zoffset = zoffset
            o.rotation = rotation
            o.stopOnWalk = false
            o.stopOnRun = false
            o.maxTime = 1
            o.isMultiple = isMultiple
            return o
        end

        return originalNew(self, character, item, sq, xoffset, yoffset, zoffset, rotation, isMultiple)
    end

    dropActionClass.__fzPatched = true
end

patchDropWorldItemAction()

local ITEM = {}
ITEM.__index = ITEM

ITEM.name = "Unknown"
ITEM.description = "No description available."
ITEM.category = "Uncategorized"
ITEM.equipTime = 50
ITEM.unequipTime = 50
ITEM.useText = "Use"
ITEM.useTime = 1
ITEM.weight = 1
ITEM.shouldConsume = true
ITEM.skin = nil
ITEM.icon = nil
ITEM.texture = nil
ITEM.persistentData = {}

local function copyPersistentValue(value, visited, path)
    local valueType = type(value)

    if valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string" then
        return value
    end

    if valueType ~= "table" then
        return nil, "Unsupported value type '" .. valueType .. "' at " .. path .. "."
    end

    visited = visited or {}
    if visited[value] then
        return nil, "Cyclic table at " .. path .. "."
    end

    visited[value] = true
    local copy = {}

    for key, nestedValue in pairs(value) do
        local keyType = type(key)
        if keyType ~= "string" and keyType ~= "number" then
            visited[value] = nil
            return nil, "Unsupported key type '" .. keyType .. "' at " .. path .. "."
        end

        local nestedCopy, nestedError = copyPersistentValue(nestedValue, visited, path .. "." .. tostring(key))
        if nestedError then
            visited[value] = nil
            return nil, nestedError
        end
        copy[key] = nestedCopy
    end

    visited[value] = nil
    return copy
end

--! \brief Copy and validate data for item persistence.
--! \param value \any A scalar or table containing only string/number keys and serializable values.
--! \return \any A detached copy of the value.
--! \return \string Error message when the value cannot be persisted.
function FrameworkZ.Items:CopyPersistentData(value)
    return copyPersistentValue(value, {}, "persistentData")
end

local function overlayPersistentData(target, source)
    for key, sourceValue in pairs(source or {}) do
        if type(sourceValue) == "table" and type(target[key]) == "table" then
            local success, message = overlayPersistentData(target[key], sourceValue)
            if not success then return false, message end
        else
            local copy, message = FrameworkZ.Items:CopyPersistentData(sourceValue)
            if message then return false, message end
            target[key] = copy
        end
    end

    return true
end

function FrameworkZ.Items:MergePersistentData(defaults, storedData)
    local merged, message = self:CopyPersistentData(defaults or {})
    if message then return nil, message end

    local storedCopy, storedError = self:CopyPersistentData(storedData or {})
    if storedError then return nil, storedError end

    local success, overlayError = overlayPersistentData(merged, storedCopy)
    if not success then return nil, overlayError end
    return merged
end

function ITEM:Initialize()
    return FrameworkZ.Items:Initialize(self)
end

function ITEM:CanContext(isoPlayer, worldItem) return true end
function ITEM:CanDrop(isoPlayer, worldItem) return true end
function ITEM:CanEquip(isoPlayer, worldItem, equipItems, equipType) return true end
function ITEM:CanUse(isoPlayer, worldItem) return true end
function ITEM:OnContext(isoPlayer, worldItem, worldItems, menuManager, itemCount) end
function ITEM:OnEquip(isoPlayer, worldItem, equipItems, equipType)
    if equipType == FZ_EQUIP_TYPE_CLOTHING or worldItem:IsClothing() then
        local primaryItem = isoPlayer:getPrimaryHandItem()
        local secondaryItem = isoPlayer:getSecondaryHandItem()

        if worldItem == primaryItem then
            isoPlayer:setPrimaryHandItem(nil)
        end

        if worldItem == secondaryItem then
            isoPlayer:setSecondaryHandItem(nil)
        end

        ISTimedActionQueue.add(ISWearClothing:new(isoPlayer, worldItem, self.equipTime))
    else
        if equipType == FZ_EQUIP_TYPE_BOTH_HANDS or worldItem:isTwoHandWeapon() then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, self.equipTime, true, true))
        elseif equipType == FZ_EQUIP_TYPE_PRIMARY or not isoPlayer:getPrimaryHandItem() then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, self.equipTime, true, false))
        elseif equipType == FZ_EQUIP_TYPE_SECONDARY or not isoPlayer:getSecondaryHandItem() then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, self.equipTime, false, false))
        end
    end
end
function ITEM:OnInstanced(isoPlayer, worldItem) end
function ITEM:OnRemoved() end
function ITEM:OnUnequip(isoPlayer, worldItem, equipItems, equipType)
    ISTimedActionQueue.add(ISUnequipAction:new(isoPlayer, worldItem, self.unequipTime))
end
function ITEM:OnUse(isoPlayer, worldItem) end

function ITEM:GetName()
    return self.name or "Unnamed Item"
end

--! \brief Get this item's mutable persistent plugin data.
--! \return \table Plain serializable state restored before OnInstanced runs.
function ITEM:GetPersistentData()
    local data = rawget(self, "persistentData")
    if type(data) ~= "table" then
        data = {}
        self.persistentData = data
    end
    return data
end

--! \brief Get a persistent item value.
--! \param key \string|\number State key.
--! \param default \any Value returned when the key is absent.
function ITEM:GetPersistentValue(key, default)
    local value = self:GetPersistentData()[key]
    if value == nil then return default end
    return value
end

--! \brief Replace all persistent item data with a validated detached copy.
--! \param data \table Plain serializable state.
--! \return \boolean Success flag.
--! \return \string Status message.
function ITEM:SetPersistentData(data)
    local copy, message = FrameworkZ.Items:CopyPersistentData(data or {})
    if message then return false, message end
    self.persistentData = copy
    return self:SyncPersistentData()
end

--! \brief Set and immediately synchronize one persistent item value.
--! \param key \string|\number State key.
--! \param value \any Plain serializable value; nil removes the key.
--! \return \boolean Success flag.
--! \return \string Status message.
function ITEM:SetPersistentValue(key, value)
    if type(key) ~= "string" and type(key) ~= "number" then
        return false, "Persistent item keys must be strings or numbers."
    end

    local copy, message = FrameworkZ.Items:CopyPersistentData(value)
    if message then return false, message end
    self:GetPersistentData()[key] = copy
    return self:SyncPersistentData()
end

--! \brief Synchronize this instance's persistent snapshot to its world item.
--! \return \boolean Success flag.
--! \return \string Status message.
function ITEM:SyncPersistentData()
    if not self.worldItem then return false, "Item has no world item to synchronize." end

    local built, instanceData = pcall(FrameworkZ.Items.BuildInstanceData, FrameworkZ.Items, self, self.worldItem, self.owner)
    if not built then return false, tostring(instanceData) end
    FrameworkZ.Items:LinkWorldItemToInstanceData(self.worldItem, instanceData)
    return true, "Persistent item data synchronized."
end

function ITEM:Remove()
    return FrameworkZ.Items:RemoveInstance(self.instanceID)
end

function FrameworkZ.Items:New(uniqueID, itemID, isBase)
    if not uniqueID then return false, "Missing unique ID." end

    local object = {
        isBase = isBase or false,
        uniqueID = uniqueID,
        itemID = itemID or "Base.Plank",
        owner = nil,
    }

    setmetatable(object, ITEM)

    return object, "Item created."
end

function FrameworkZ.Items:Initialize(data)
    if not data.isBase then
        local base = self.Bases[data.base]

        -- If the base item exists, copy its properties to the new item but skip any overrides implemented by the new item.
        if base then
            for k, v in pairs(base) do
                if data[k] == nil or data[k] == ITEM[k] then
                    data[k] = v
                end
            end
        end

        self.List[data.uniqueID] = data
    else
        self.Bases[data.uniqueID] = data
    end

    return data.uniqueID
end

function FrameworkZ.Items:RestoreCustomFields(itemDefinition, customFieldData)
    local definitionCustomFields = itemDefinition and itemDefinition.customFields
    local snapshotCustomFields = customFieldData

    if type(definitionCustomFields) ~= "table" then
        if type(snapshotCustomFields) == "table" then
            return FrameworkZ.Utilities:CopyTable(snapshotCustomFields)
        end

        return {}
    end

    local restoredCustomFields = {}

    for fieldName, definitionField in pairs(definitionCustomFields) do
        local savedField = snapshotCustomFields and snapshotCustomFields[fieldName] or nil
        local restoredField = definitionField

        if type(definitionField) == "table" then
            restoredField = FrameworkZ.Utilities:CopyTable(definitionField)

            if type(savedField) == "table" then
                if savedField.value ~= nil then
                    restoredField.value = savedField.value
                end

                for savedKey, savedValue in pairs(savedField) do
                    if savedKey ~= "get" and savedKey ~= "set" and savedKey ~= "value" then
                        restoredField[savedKey] = savedValue
                    end
                end
            elseif savedField ~= nil then
                restoredField.value = savedField
            end
        elseif savedField ~= nil then
            restoredField = savedField
        end

        restoredCustomFields[fieldName] = restoredField
    end

    if type(snapshotCustomFields) == "table" then
        for fieldName, savedField in pairs(snapshotCustomFields) do
            if definitionCustomFields[fieldName] == nil then
                restoredCustomFields[fieldName] = savedField
            end
        end
    end

    return restoredCustomFields
end

function FrameworkZ.Items:SnapshotCustomFields(customFields)
    local snapshot = {}

    for fieldName, field in pairs(customFields or {}) do
        if type(field) == "function" then
            -- Runtime behavior comes from the registered item definition.
        elseif type(field) == "table" and (field.value ~= nil or type(field.get) == "function" or type(field.set) == "function") then
            local fieldSnapshot = {}

            if field.value ~= nil then
                local value, message = self:CopyPersistentData(field.value)
                if message then return nil, "Custom field '" .. tostring(fieldName) .. "': " .. message end
                fieldSnapshot.value = value
            end

            for metadataKey, metadataValue in pairs(field) do
                if metadataKey ~= "get" and metadataKey ~= "set" and metadataKey ~= "value" and type(metadataValue) ~= "function" then
                    local value, message = self:CopyPersistentData(metadataValue)
                    if message then return nil, "Custom field '" .. tostring(fieldName) .. "': " .. message end
                    fieldSnapshot[metadataKey] = value
                end
            end

            snapshot[fieldName] = fieldSnapshot
        else
            local value, message = self:CopyPersistentData(field)
            if message then return nil, "Custom field '" .. tostring(fieldName) .. "': " .. message end
            snapshot[fieldName] = value
        end
    end

    return snapshot
end

local function applySnapshotToItemDefinition(itemDefinition, itemSnapshot)
    local rebuiltItem = FrameworkZ.Utilities:CopyTable(itemDefinition)

    if type(itemSnapshot) == "table" then
        for key, value in pairs(itemSnapshot) do
            if key == "customFields" and type(value) == "table" then
                rebuiltItem.customFields = FrameworkZ.Items:RestoreCustomFields(rebuiltItem, value)
            else
                rebuiltItem[key] = value
            end
        end
    end

    setmetatable(rebuiltItem, getmetatable(itemDefinition))

    rebuiltItem.instanceID = nil
    rebuiltItem.owner = nil
    rebuiltItem.worldItem = nil
    rebuiltItem.worldItemID = nil
    rebuiltItem.inventoryIndex = nil

    return rebuiltItem
end

local function getItemDefinitionByItemType(itemType)
    if not itemType then
        return nil
    end

    for _, definition in pairs(FrameworkZ.Items.List or {}) do
        if definition and definition.itemID == itemType then
            return definition
        end
    end

    return nil
end

local function looksLikeIsoPlayer(candidate)
    return candidate
        and type(candidate.getInventory) == "function"
        and type(candidate.getUsername) == "function"
end

local function resolveIsoPlayerFromPayload(data)
    if looksLikeIsoPlayer(data) then
        return data
    end

    if type(data) == "table" then
        local direct = data.isoPlayer or data.player or data.sourcePlayer
        if looksLikeIsoPlayer(direct) then
            return direct
        end

        local playerID = data.playerID
        local getByOnlineID = rawget(_G, "getPlayerByOnlineID")
        if playerID ~= nil and type(getByOnlineID) == "function" then
            local onlinePlayer = getByOnlineID(playerID)
            if looksLikeIsoPlayer(onlinePlayer) then
                return onlinePlayer
            end
        end
    end

    local getLocalPlayer = rawget(_G, "getPlayer")
    if type(getLocalPlayer) == "function" then
        local localPlayer = getLocalPlayer()
        if looksLikeIsoPlayer(localPlayer) then
            return localPlayer
        end
    end

    return nil
end

local function normalizeSkinValue(skin)
    if skin == nil then
        return nil
    end

    if type(skin) == "number" then
        return math.floor(skin)
    end

    if type(skin) == "string" then
        local numeric = tonumber(skin)
        if numeric ~= nil then
            return math.floor(numeric)
        end

        if skin ~= "" then
            return skin
        end
    end

    return nil
end

function FrameworkZ.Items:ApplyTextureChoice(worldItem, textureChoice)
    if not worldItem then
        return false
    end

    

    --[[
    local normalizedChoice = nil
    if type(textureChoice) == "number" then
        normalizedChoice = math.floor(textureChoice)
    elseif type(textureChoice) == "string" then
        local numeric = tonumber(textureChoice)
        if numeric ~= nil then
            normalizedChoice = math.floor(numeric)
        end
    end

    if normalizedChoice == nil then
        return false
    end

    local visual = worldItem.getVisual and worldItem:getVisual() or nil
    local applied = false

    if visual and visual.setTextureChoice and type(visual.setTextureChoice) == "function" then
        applied = pcall(function()
            visual:setTextureChoice(normalizedChoice)
        end)
    end

    if type(worldItem.setTextureChoice) == "function" then
        local itemApplied = pcall(function()
            worldItem:setTextureChoice(normalizedChoice)
        end)
        applied = applied or itemApplied
    end
    --]]

    --[[
    if type(worldItem.setIcon) == "function" then
        local iconApplied = pcall(function()
            worldItem:setIcon(normalizedChoice)
        end)

        applied = applied or iconApplied
    end
    --]]

    --[[
    if applied and type(worldItem.synchWithVisual) == "function" then
        pcall(function()
            worldItem:synchWithVisual()
        end)
    end
    --]]

    return true
end

function FrameworkZ.Items:ApplyDeterministicSkin(worldItem, skin)
    if not worldItem then
        return false
    end

    local normalizedSkin = normalizeSkinValue(skin)
    if normalizedSkin == nil or type(worldItem.getVisual) ~= "function" then
        return false
    end

    local visual = worldItem:getVisual()
    if not visual then
        return false
    end

    local applied = false

    if type(normalizedSkin) == "number" then
        applied = self:ApplyTextureChoice(worldItem, normalizedSkin)
        if type(worldItem) == "table" then
            worldItem.textureChoice = normalizedSkin
        end
    elseif type(normalizedSkin) == "string" then
        if type(visual.setClothingItemName) == "function" then
            applied = pcall(function()
                visual:setClothingItemName(normalizedSkin)
            end)
        end

        if not applied and type(visual.setAlternateModelName) == "function" then
            applied = pcall(function()
                visual:setAlternateModelName(normalizedSkin)
            end)
        end
    end

    if applied and type(worldItem.synchWithVisual) == "function" then
        pcall(function()
            worldItem:synchWithVisual()
        end)
    end

    return applied
end

function FrameworkZ.Items:BuildInstanceData(instance, worldItem, owner)
    local persistentData, persistentError = self:CopyPersistentData(instance.persistentData or {})
    if persistentError then error("Invalid persistent item data: " .. persistentError) end

    local customFields, customFieldsError = self:SnapshotCustomFields(instance.customFields)
    if customFieldsError then error("Invalid custom item data: " .. customFieldsError) end

    return {
        uniqueID = instance.uniqueID,
        itemID = worldItem:getFullType(),
        instanceID = instance.instanceID,
        owner = owner,
        name = instance.name or "Unknown",
        description = instance.description or "No description available.",
        category = instance.category or "Uncategorized",
        shouldConsume = instance.shouldConsume or false,
        texture = instance.texture,
        skin = instance.skin,
        textureChoice = instance.textureChoice,
        weight = instance.weight or 1,
        useAction = instance.useAction or nil,
        useTime = instance.useTime or nil,
        persistentData = persistentData,
        customFields = customFields
    }
end

function FrameworkZ.Items:HydrateClientInstanceFromData(isoPlayer, worldItem, instanceData)
    if not isoPlayer or not worldItem or type(instanceData) ~= "table" then
        return false, "Missing hydration inputs."
    end

    local instanceID = instanceData.instanceID
    if instanceID == nil then
        return false, "Missing instance ID in instance data."
    end

    local instance = self.Instances[instanceID]
    if type(instance) ~= "table" then
        local definition = self:GetItemByUniqueID(instanceData.uniqueID)
        if not definition then
            return false, "Item definition not found for hydrated instance."
        end

        instance = FrameworkZ.Utilities:CopyTable(definition)
        setmetatable(instance, getmetatable(definition))
        self.Instances[instanceID] = instance
    end

    self:ApplyStoredInstanceData(instance, instanceData)
    instance.instanceID = instanceID
    instance.owner = instanceData.owner or isoPlayer:getUsername()
    instance.worldItem = worldItem
    instance.worldItemID = worldItem.getID and worldItem:getID() or instance.worldItemID

    --[[
    if instance.skin ~= nil then
        self:ApplyDeterministicSkin(worldItem, instance.skin)
    end

    if instanceData.texture ~= nil then
        self:ApplyTextureChoice(worldItem, instanceData.texture)
    elseif instance.skin ~= nil then
        self:ApplyTextureChoice(worldItem, instance.skin)
    end
    --]]

    if not self.InstanceMap[instance.uniqueID] then
        self.InstanceMap[instance.uniqueID] = {}
    end

    local username = isoPlayer:getUsername()
    if not self.InstanceMap[instance.uniqueID][username] then
        self.InstanceMap[instance.uniqueID][username] = {}
    end

    local instanceList = self.InstanceMap[instance.uniqueID][username]
    local isInMap = false
    for _, existing in ipairs(instanceList) do
        if existing and existing.instanceID == instanceID then
            isInMap = true
            break
        end
    end

    if not isInMap then
        table.insert(instanceList, instance)
    end

    return instance
end

function FrameworkZ.Items:CreateWorldItemsBatch(isoPlayer, requests)
    if not isoPlayer then return false, "Missing Iso Player: FrameworkZ.Items.CreateWorldItemsBatch" end
    if type(requests) ~= "table" then return false, "Missing create requests." end

    local onServer = type(isServer) == "function" and isServer() or false
    local onClient = type(isClient) == "function" and isClient() or false
    if not onServer and not onClient then
        return false, "CreateWorldItemsBatch requires a server or client execution context."
    end

    local manifest = {}
    local instances = {}
    local worldItems = {}

    for _, request in ipairs(requests) do
        local uniqueID = request and request.uniqueID or nil
        local quantity = tonumber(request and request.quantity) or 1
        local requestedItemType = request and request.fullItemID or nil
        if not requestedItemType and request and request.snapshot then
            requestedItemType = request.snapshot.itemID or request.snapshot.fullItemID or nil
        end
        local itemDefinition = uniqueID and self:GetItemByUniqueID(uniqueID) or nil
        if not itemDefinition and requestedItemType then
            itemDefinition = getItemDefinitionByItemType(requestedItemType)
        end

        if itemDefinition and quantity > 0 then
            for _i = 1, quantity do
                local sourceItem = applySnapshotToItemDefinition(itemDefinition, request.snapshot)
                local fullItemID = requestedItemType or sourceItem.itemID or itemDefinition.itemID
                local worldItem = instanceItem(fullItemID)
                local selectedSkin = normalizeSkinValue(request and request.skin ~= nil and request.skin or sourceItem.skin)

                if not worldItem then
                    return false, "Failed to create world item '" .. tostring(fullItemID) .. "'."
                end

                if selectedSkin ~= nil then
                    sourceItem.skin = selectedSkin
                    sourceItem.textureChoice = selectedSkin
                    self:ApplyDeterministicSkin(worldItem, selectedSkin)
                end

                isoPlayer:getInventory():AddItem(worldItem)
                if type(sendAddItemToContainer) == "function" then
                    pcall(function()
                        sendAddItemToContainer(isoPlayer:getInventory(), worldItem)
                    end)
                end

                local instanceID, instance = self:AddInstance(sourceItem, isoPlayer, worldItem)
                instance.instanceID = instanceID

                if instance.OnInstanced then
                    instance:OnInstanced(isoPlayer, worldItem)
                end

                local instanceData = self:BuildInstanceData(instance, worldItem, isoPlayer:getUsername())
                self:LinkWorldItemToInstanceData(worldItem, instanceData)

                table.insert(worldItems, worldItem)
                table.insert(instances, instance)
                table.insert(manifest, {
                    worldItemID = worldItem:getID(),
                    instanceData = instanceData
                })
            end
        end
    end

    return true, "Created " .. tostring(#manifest) .. " world item(s).", manifest, instances, worldItems
end

if isServer() then
    function FrameworkZ.Items.CreateWorldItem(data, fullItemID, quantity, uniqueID)
        local isoPlayer = data.isoPlayer if not isoPlayer then return false, "Missing Iso Player: FrameworkZ.Items.CreateWorldItem" end

        local requests = {
            {
                uniqueID = uniqueID,
                quantity = quantity or 1,
                fullItemID = fullItemID
            }
        }

        local success, message, manifest = FrameworkZ.Items:CreateWorldItemsBatch(isoPlayer, requests)
        if not success then
            return false, message
        end

        return true, message, manifest
    end

    function FrameworkZ.Items.CreateWorldItems(data, requests)
        local isoPlayer = data.isoPlayer if not isoPlayer then return false, "Missing Iso Player: FrameworkZ.Items.CreateWorldItems" end
        return FrameworkZ.Items:CreateWorldItemsBatch(isoPlayer, requests)
    end

    FrameworkZ.Foundation:Subscribe("FrameworkZ.Items.CreateWorldItem", FrameworkZ.Items.CreateWorldItem)
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Items.CreateWorldItems", FrameworkZ.Items.CreateWorldItems)
end

if isServer() then
    function FrameworkZ.Items.OnCreateItem(data, uniqueID, isLogical)
        if not uniqueID then return false, "Missing unique ID." end
        local item = isLogical and FrameworkZ.Items:GetItemByUniqueID(uniqueID) or true if not item then return false, "Item not found." end
        local worldItem = instanceItem(isLogical and item.itemID or uniqueID) if not worldItem then return false, "Failed to create world item '" .. tostring(item.itemID) .. "'." end

        local instanceID, instance = FrameworkZ.Items:AddInstance(isLogical and item or {uniqueID = uniqueID}, data.isoPlayer, worldItem)

        if instance and instance.OnInstanced then
            instance:OnInstanced(data.isoPlayer, worldItem)
        end

        local instanceData = FrameworkZ.Items:BuildInstanceData(instance, worldItem, data.isoPlayer:getUsername())
        FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)

        if worldItem then
            data.isoPlayer:getInventory():AddItem(worldItem)
            sendAddItemToContainer(data.isoPlayer:getInventory(), worldItem)
        end

        return FrameworkZ.Utilities:Serialize(instance)
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Items.OnCreateItem", FrameworkZ.Items.OnCreateItem)
end

--! \brief Creates an item instance and links it to a world item.
--! \param uniqueID \string The unique ID of the item to create.
--! \param isoPlayer \object The ISO Player to create the item for.
--! \param uniqueID \string The unique ID of the logical item of item ID of the basic Project Zomboid item.
--! \param isLogical \boolean Whether or not the item is a logical item (i.e. based in FrameworkZ).
--! \return \boolean|/object \string The object for the created instance, or false and a message if it failed to create the item.
function FrameworkZ.Items:CreateItem(isoPlayer, uniqueID, isLogical)
    return FrameworkZ.Awaits:Run(function()
        if not uniqueID then return false, "Missing unique ID." end
        local item = isLogical and FrameworkZ.Items:GetItemByUniqueID(uniqueID) or true if not item then return false, "Item not found." end
        local instance, message = FrameworkZ.Awaits:SendFire(isoPlayer, "FrameworkZ.Items.OnCreateItem", uniqueID, isLogical) if not instance then return false, "Failed to create server side item: " .. message end

        local sourceInstance = instance and type(instance) == "table" and instance or {}
        if isLogical and item and type(item) == "table" then
            sourceInstance = FrameworkZ.Utilities:MergeTables(sourceInstance, item)
        end

        local worldItem = isoPlayer:getInventory():getItemById(instance.worldItemID)
        local canonicalInstance = FrameworkZ.Items:RegisterInstance(sourceInstance.instanceID, sourceInstance, isoPlayer, worldItem)
        local liveInstance = FrameworkZ.Items:GetInstance(sourceInstance.instanceID) or canonicalInstance

        if liveInstance and type(liveInstance) == "table" and liveInstance.OnInstanced then
            liveInstance:OnInstanced(isoPlayer, worldItem)
        end

        local instanceData = FrameworkZ.Items:BuildInstanceData(liveInstance or sourceInstance, worldItem, isoPlayer:getUsername())
        FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)

        if liveInstance and type(liveInstance) == "table" then
            liveInstance.worldItem = worldItem
            liveInstance.worldItemID = worldItem and worldItem.getID and worldItem:getID() or liveInstance.worldItemID
        end

        return liveInstance or sourceInstance
    end)
end

function FrameworkZ.Items:AddInstance(item, isoPlayer, worldItem)
    self.NextInstanceID = self.NextInstanceID + 1
    local instanceID = self.NextInstanceID
    local itemInstance = FrameworkZ.Items:RegisterInstance(instanceID, item, isoPlayer, worldItem)

    return instanceID, itemInstance
end

function FrameworkZ.Items:RegisterInstance(instanceID, item, isoPlayer, worldItem)
    local numericInstanceID = tonumber(instanceID)
    if numericInstanceID and numericInstanceID > self.NextInstanceID then
        self.NextInstanceID = numericInstanceID
    end

    local itemInstance = FrameworkZ.Utilities:CopyTable(item)
    local persistentData, persistentError = self:CopyPersistentData(item.persistentData or {})
    if persistentError then error("Invalid persistent item data: " .. persistentError) end

    itemInstance["instanceID"] = instanceID
    itemInstance["owner"] = isoPlayer:getUsername()
    itemInstance["worldItemID"] = worldItem:getID()
    itemInstance["worldItem"] = worldItem
    itemInstance["texture"] = item.texture or nil
    itemInstance["persistentData"] = persistentData
    self.Instances[instanceID] = itemInstance

    if not self.InstanceMap[item.uniqueID] then
        self.InstanceMap[item.uniqueID] = {}
    end

    if not self.InstanceMap[item.uniqueID][isoPlayer:getUsername()] then
        self.InstanceMap[item.uniqueID][isoPlayer:getUsername()] = {}
    end

    table.insert(self.InstanceMap[item.uniqueID][isoPlayer:getUsername()], itemInstance)

    return itemInstance
end

function FrameworkZ.Items:ClearOwnerInstances(owner)
    if not owner then return end

    for instanceID, instance in pairs(self.Instances) do
        if type(instance) == "table" and instance.owner == owner then
            self.Instances[instanceID] = nil
        end
    end

    for _, ownerMap in pairs(self.InstanceMap) do
        ownerMap[owner] = nil
    end
end

function FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)
    worldItem:getModData()["FZ_ITM"] = instanceData
    worldItem:setName(instanceData.name)
    worldItem:setActualWeight(instanceData.weight)

    if instanceData.texture then
        worldItem:setTexture(getTexture(instanceData.texture))
    end

    if isServer() and type(sendItemStats) == "function" then
        pcall(function()
            sendItemStats(worldItem)
        end)
    end
end

function FrameworkZ.Items:GetStoredData(worldItem)
    if not worldItem then return false, "Missing world item." end

    local itemData = worldItem:getModData()["FZ_ITM"]

    return itemData or false, "No stored item data found."
end

function FrameworkZ.Items:ApplyStoredInstanceData(instance, itemData)
    if type(instance) ~= "table" or type(itemData) ~= "table" then return instance end

    local storedFields = {
        "name",
        "description",
        "category",
        "shouldConsume",
        "texture",
        "skin",
        "textureChoice",
        "weight",
        "useAction",
        "useTime"
    }

    for _, fieldName in ipairs(storedFields) do
        if itemData[fieldName] ~= nil then
            instance[fieldName] = itemData[fieldName]
        end
    end

    local persistentData, persistentError = self:MergePersistentData(instance.persistentData or {}, itemData.persistentData or {})
    if persistentError then error("Invalid stored persistent item data: " .. persistentError) end
    instance.persistentData = persistentData
    instance.customFields = self:RestoreCustomFields(instance, itemData.customFields or instance.customFields or {})
    return instance
end

function FrameworkZ.Items:BuildTransientInstanceFromStoredData(itemData, worldItem)
    if not itemData or not itemData.uniqueID then return false, "Missing stored item data." end

    local definition = self:GetItemByUniqueID(itemData.uniqueID)
    if not definition then return false, "Item definition not found." end

    local transient = FrameworkZ.Utilities:CopyTable(definition)
    setmetatable(transient, getmetatable(definition))
    self:ApplyStoredInstanceData(transient, itemData)

    transient.instanceID = itemData.instanceID
    transient.owner = itemData.owner
    transient.worldItem = worldItem
    transient.worldItemID = worldItem and worldItem.getID and worldItem:getID() or nil

    return transient
end

function FrameworkZ.Items:ResolveUsableInstance(worldItem, itemData)
    if not itemData then return false, "Missing stored item data." end

    local liveInstance = self:GetInstance(itemData.instanceID)
    if liveInstance then
        return liveInstance
    end

    return self:BuildTransientInstanceFromStoredData(itemData, worldItem)
end

function FrameworkZ.Items:ResolveUsableInstanceForCallback(worldItem, fallbackInstance)
    if fallbackInstance and type(fallbackInstance) == "table" and fallbackInstance.OnUse then
        return fallbackInstance
    end

    if not worldItem then return false, "Missing world item." end

    local itemData = self:GetStoredData(worldItem)
    local resolved = self:ResolveUsableInstance(worldItem, itemData)
    if resolved then
        return resolved
    end

    local fullType = worldItem.getFullType and worldItem:getFullType() or nil
    if not fullType then
        return false, "Missing world item full type."
    end

    for uniqueID, definition in pairs(self.List or {}) do
        if definition and definition.itemID == fullType then
            local transient = FrameworkZ.Utilities:CopyTable(definition)
            setmetatable(transient, getmetatable(definition))
            transient.uniqueID = transient.uniqueID or uniqueID
            transient.worldItem = worldItem
            transient.worldItemID = worldItem.getID and worldItem:getID() or nil
            return transient
        end
    end

    return false, "No FrameworkZ item definition matched world item type."
end

function FrameworkZ.Items:GetItemByUniqueID(uniqueID)
    local item = self.List[uniqueID] or nil

    return item
end

function FrameworkZ.Items:GetInstance(instanceID)
    if not instanceID or instanceID == "" then return false, "Missing instance ID." end

    local instance = self.Instances[instanceID]

    if type(instance) == "table" then
        local hasEntries = false
        for _ in pairs(instance) do
            hasEntries = true
            break
        end

        if not hasEntries then
            instance = nil
        end
    end

    if not instance then return false, "Instance not found." end

    return instance
end

function FrameworkZ.Items:FindFirstInstanceByID(owner, uniqueID)
    if not owner or owner == "" then return false, "Missing owner." end
    if not uniqueID or uniqueID == "" then return false, "Missing unique ID." end

    local byUnique = self.InstanceMap[uniqueID]
    local byOwner = byUnique and byUnique[owner] or nil
    local instance = byOwner and byOwner[1] or nil

    if not instance then return false, "Instance not found." end

    return instance
end

function FrameworkZ.Items:RemoveItemInstanceByUniqueID(owner, uniqueID)
    if not owner or owner == "" then return false, "Missing owner." end
    if not uniqueID or uniqueID == "" then return false, "Missing unique ID." end

    local instance = FrameworkZ.Items:FindFirstInstanceByID(owner, uniqueID)

    if not instance then return false, "Instance not found." end

    return FrameworkZ.Items:RemoveInstance(instance.instanceID, owner)
end

--! \brief Removes an item instance from the game world and the item instance list.
--! \param instanceID \integer The instance ID of the item to remove.
--! \param username \object (Optional) The player's username whose inventory the item should be removed from.
--! \return \boolean \string Success status and message.
function FrameworkZ.Items:RemoveInstance(instanceID, username)
    if not instanceID or instanceID == "" then return false, "Missing instance ID." end
    local instance = self:GetInstance(instanceID)
    if not instance then return false, "Instance not found." end
    local player = FrameworkZ.Players:GetPlayerByID(username or instance.owner)
    if not player then return false, "Player not found." end
    local inventory = player:GetCharacter():GetInventory()
    if not inventory then return false, "Inventory not found." end

    if instance.OnRemoved then
        instance:OnRemoved()
    end

    local isoPlayer = player:GetIsoPlayer()
    if not isoPlayer then return false, "ISO player not found." end

    local worldItem = instance.worldItem
    if not worldItem then
        local pendingContainers = {}
        local inventoryContainer = isoPlayer.getInventory and isoPlayer:getInventory() or nil
        if inventoryContainer then
            table.insert(pendingContainers, inventoryContainer)
        end

        while not worldItem and #pendingContainers > 0 do
            local container = table.remove(pendingContainers)
            if container and container.getItems then
                local items = container:getItems()
                if items then
                    for i = 0, items:size() - 1 do
                        local candidate = items:get(i)
                        if candidate and candidate.getModData then
                            local itemData = candidate:getModData()["FZ_ITM"]
                            if itemData and itemData.instanceID == instance.instanceID then
                                worldItem = candidate
                                break
                            end

                            if candidate.getCategory and candidate:getCategory() == "Container" and candidate.getItemContainer then
                                local nested = candidate:getItemContainer()
                                if nested then
                                    table.insert(pendingContainers, nested)
                                end
                            end
                        end
                    end
                end
            end
        end

        if worldItem then
            instance.worldItem = worldItem
            instance.worldItemID = worldItem.getID and worldItem:getID() or instance.worldItemID
        end
    end

    if worldItem then
        local removedPhysical = false
        local playerInventory = isoPlayer.getInventory and isoPlayer:getInventory() or nil

        if isoPlayer.removeFromHands then
            isoPlayer:removeFromHands(worldItem)
        end

        local container = worldItem.getContainer and worldItem:getContainer() or nil
        if container then
            if container ~= playerInventory and container.removeItemOnServer then
                container:removeItemOnServer(worldItem)
            end

            if container.Remove then
                container:Remove(worldItem)
                removedPhysical = true
            elseif container.DoRemoveItem then
                container:DoRemoveItem(worldItem)
                removedPhysical = true
            end

            if removedPhysical and type(sendRemoveItemFromContainer) == "function" then
                pcall(function()
                    sendRemoveItemFromContainer(container, worldItem)
                end)
            end
        elseif playerInventory then
            if playerInventory.Remove then
                playerInventory:Remove(worldItem)
                removedPhysical = true
            elseif playerInventory.DoRemoveItem then
                playerInventory:DoRemoveItem(worldItem)
                removedPhysical = true
            end

            if removedPhysical and type(sendRemoveItemFromContainer) == "function" then
                pcall(function()
                    sendRemoveItemFromContainer(playerInventory, worldItem)
                end)
            end
        end

        if not removedPhysical then
            return false, "Failed to remove physical world item for instance #" .. tostring(instanceID) .. "."
        end
    end

    inventory:RemoveItem(instance)

    local uniqueMap = self.InstanceMap[instance.uniqueID]
    local instanceMap = uniqueMap and uniqueMap[instance.owner] or nil

    -- It was a choice to either loop the item instance map on item removal, or loop the item instance list on item lookup. This seemed more efficient because the item
    -- instance list is every single instance across every character, while the instance map is only the instances for a specific item on a specific character.
    if instanceMap then
        for k, v in ipairs(instanceMap) do
            if v.instanceID == instanceID then
                self.InstanceMap[instance.uniqueID][instance.owner][k] = nil
                break
            end
        end
    end

    self.Instances[instanceID] = nil

    return true, "Removed item instance #" .. tostring(instanceID) .. "."
end

function FrameworkZ.Items:ConsumeOwnedInstances(isoPlayer, instanceIDs, count, requirements)
    if not isoPlayer then return false, "Missing Iso player: FrameworkZ.Items.ConsumeOwnedInstances", 0 end
    if type(instanceIDs) ~= "table" then return false, "Missing instance ID list.", 0 end

    count = tonumber(count) or 1
    if count < 1 then return false, "Invalid consume count.", 0 end

    local username = isoPlayer:getUsername()
    local character = FrameworkZ.Characters:GetCharacterByID(username)
    if not character then return false, "Character not found.", 0 end

    local candidateInstanceIDs = {}
    local seen = {}

    for _, instanceID in ipairs(instanceIDs) do
        if instanceID ~= nil then
            local key = instanceID
            if not seen[key] then
                seen[key] = true

                local instance = self:GetInstance(instanceID)
                if instance and (not instance.owner or instance.owner == username) then
                    local matches = true

                    if type(requirements) == "table" then
                        if requirements.uniqueID and instance.uniqueID ~= requirements.uniqueID then
                            matches = false
                        end

                        if matches and requirements.base and instance.base ~= requirements.base then
                            matches = false
                        end

                        if matches and requirements.currencyType and instance.currencyType ~= requirements.currencyType then
                            matches = false
                        end

                        if matches and requirements.amount ~= nil and tonumber(instance.amount) ~= tonumber(requirements.amount) then
                            matches = false
                        end
                    end

                    if matches then
                        table.insert(candidateInstanceIDs, instanceID)
                    end
                end
            end
        end
    end

    if #candidateInstanceIDs < count then
        return false, "Not enough valid item instances.", 0
    end

    local consumed = 0
    for i = 1, #candidateInstanceIDs do
        if consumed >= count then break end

        local ok = character:TakeItemByInstanceID(candidateInstanceIDs[i])
        if ok then
            consumed = consumed + 1
        end
    end

    if consumed < count then
        return false, "Failed to consume required item instances.", consumed
    end

    return true, "Consumed item instances.", consumed
end

function FrameworkZ.Items:RequestConsumeOwnedInstances(isoPlayer, instanceIDs, count, requirements, callback)
    if not FrameworkZ.Foundation or type(FrameworkZ.Foundation.SendFire) ~= "function" or not isoPlayer then
        return self:ConsumeOwnedInstances(isoPlayer, instanceIDs, count, requirements)
    end

    FrameworkZ.Foundation:SendFire(isoPlayer, self.Subscriptions.consumeOwnedInstances, function(_, success, message, consumed)
        if callback then
            callback(success, message, consumed)
        end
    end, {
        instanceIDs = instanceIDs,
        count = count,
        requirements = requirements
    })

    return true, "Consumption request sent."
end

if not FrameworkZ.Items._networkSubscriptionsRegistered
    and FrameworkZ.Foundation
    and type(FrameworkZ.Foundation.Subscribe) == "function" then
    FrameworkZ.Foundation:Subscribe(FrameworkZ.Items.Subscriptions.consumeOwnedInstances, function(data, args)
        return FrameworkZ.Items:ConsumeOwnedInstances(
            data and data.isoPlayer or nil,
            args and args.instanceIDs or nil,
            args and args.count or 1,
            args and args.requirements or nil
        )
    end)

    FrameworkZ.Items._networkSubscriptionsRegistered = true
end

-- TODO use multiple items, not just one
function FrameworkZ.Items:OnUseItemCallback(parameters, ...)
    local callbackParameters = type(parameters) == "table" and parameters or {parameters, ...}
    local worldItem, item, playerObject = callbackParameters[1], callbackParameters[2], callbackParameters[3]

    if not (playerObject and type(playerObject) ~= "number") then
        local playerIndex = callbackParameters and callbackParameters[4] or nil
        playerObject = nil

        if type(playerIndex) == "number" and type(getSpecificPlayer) == "function" then
            playerObject = getSpecificPlayer(playerIndex)
        end

        if not playerObject and type(getSpecificPlayer) == "function" then
            playerObject = getSpecificPlayer(0)
        end

        if not playerObject and type(getPlayer) == "function" then
            playerObject = getPlayer(0) or getPlayer()
        end
    end

    item = FrameworkZ.Items:ResolveUsableInstanceForCallback(worldItem, item)

    local playerType = type(playerObject)
    if not playerObject or (playerType ~= "table" and playerType ~= "userdata") then
        return false, "Unable to resolve player for item use callback."
    end

    if not item or type(item) ~= "table" or not item.OnUse then
        local fullType = worldItem and worldItem.getFullType and worldItem:getFullType() or "unknown"
        local itemData = worldItem and FrameworkZ.Items:GetStoredData(worldItem) or nil
        local uniqueID = itemData and itemData.uniqueID or "none"

        if playerObject and playerObject.Say then
            playerObject:Say("Unable to use item: " .. tostring(fullType) .. " [" .. tostring(uniqueID) .. "]")
        end

        return false, "Unable to resolve item use callback."
    end

    item:OnUse(playerObject, worldItem)

    return true, "Item use callback executed."
end

function FrameworkZ.Items:OnExamineItemCallback(parameters, ...)
    local callbackParameters = type(parameters) == "table" and parameters or {parameters, ...}
    local worldItem, instance, playerObject = callbackParameters[1], callbackParameters[2], callbackParameters[3]

    if not (playerObject and type(playerObject) ~= "number") then
        local playerIndex = callbackParameters and callbackParameters[4] or nil
        playerObject = nil

        if type(playerIndex) == "number" and type(getSpecificPlayer) == "function" then
            playerObject = getSpecificPlayer(playerIndex)
        end

        if not playerObject and type(getSpecificPlayer) == "function" then
            playerObject = getSpecificPlayer(0)
        end

        if not playerObject and type(getPlayer) == "function" then
            playerObject = getPlayer(0) or getPlayer()
        end
    end

    if (not instance or type(instance) ~= "table") and worldItem then
        local itemData = FrameworkZ.Items:GetStoredData(worldItem)
        instance = FrameworkZ.Items:ResolveUsableInstance(worldItem, itemData)
    end

    if not instance or type(instance) ~= "table" then
        if playerObject and playerObject.Say then
            playerObject:Say("No item data available.")
        end

        return false, "Unable to resolve item examine callback."
    end

    local playerType = type(playerObject)
    if not playerObject or (playerType ~= "table" and playerType ~= "userdata") or not playerObject.Say then
        return false, "Unable to resolve player for item examine callback."
    end

    playerObject:Say(instance.description)

    return true, "Item examine callback executed."
end

function FrameworkZ.Items:OnEquipItemCallback(parameters, ...)
    local callbackParameters = type(parameters) == "table" and parameters or {parameters, ...}
    local worldItem, selectedWorldItems, instance, isoPlayer, equipType = callbackParameters[1], callbackParameters[2], callbackParameters[3], callbackParameters[4], callbackParameters[5]

    if equipType == FZ_EQUIP_TYPE_IDEAL then
        for _, v in pairs(selectedWorldItems) do
            local itemData = FrameworkZ.Items:GetStoredData(v)
            local selectedInstance = self:ResolveUsableInstance(v, itemData)

            if selectedInstance then
                selectedInstance:OnEquip(isoPlayer, v, selectedWorldItems, equipType)
            else
                if v:IsClothing() then
                    local primaryItem = isoPlayer:getPrimaryHandItem()
                    local secondaryItem = isoPlayer:getSecondaryHandItem()

                    if v == primaryItem then
                        isoPlayer:setPrimaryHandItem(nil)
                    end

                    if v == secondaryItem then
                        isoPlayer:setSecondaryHandItem(nil)
                    end

                    ISTimedActionQueue.add(ISWearClothing:new(isoPlayer, v, 50))
                else
                    if v:isTwoHandWeapon() then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, v, 50, true, true))
                    elseif not isoPlayer:getPrimaryHandItem() then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, v, 50, true, false))
                    elseif not isoPlayer:getSecondayrHandItem() then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, v, 50, false, false))
                    end
                end
            end
        end
    elseif instance then
        instance:OnEquip(isoPlayer, worldItem, selectedWorldItems, equipType)
    elseif equipType == FZ_EQUIP_TYPE_BOTH_HANDS then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, 50, true, true))
    elseif equipType == FZ_EQUIP_TYPE_PRIMARY then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, 50, true, false))
    elseif equipType == FZ_EQUIP_TYPE_SECONDARY then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(isoPlayer, worldItem, 50, false, false))
    elseif equipType == FZ_EQUIP_TYPE_CLOTHING then
        local primaryItem = isoPlayer:getPrimaryHandItem()
        local secondaryItem = isoPlayer:getSecondaryHandItem()

        if worldItem == primaryItem then
            isoPlayer:setPrimaryHandItem(nil)
        end

        if worldItem == secondaryItem then
            isoPlayer:setSecondaryHandItem(nil)
        end

        ISTimedActionQueue.add(ISWearClothing:new(isoPlayer, worldItem, 50))
    end
end

function FrameworkZ.Items:OnUnequipItemCallback(parameters, ...)
    local callbackParameters = type(parameters) == "table" and parameters or {parameters, ...}
    local worldItem, selectedWorldItems, instance, isoPlayer, equipType = callbackParameters[1], callbackParameters[2], callbackParameters[3], callbackParameters[4], callbackParameters[5]

    if equipType == FZ_EQUIP_TYPE_IDEAL then
        for _, v in pairs(selectedWorldItems) do
            if v:isEquipped() then
                local itemData = FrameworkZ.Items:GetStoredData(v)
                local selectedInstance = self:ResolveUsableInstance(v, itemData)

                if selectedInstance then
                    selectedInstance:OnUnequip(isoPlayer, v, selectedWorldItems, equipType)
                else
                    ISTimedActionQueue.add(ISUnequipAction:new(isoPlayer, v, 50))
                end
            end
        end
    elseif instance then
        instance:OnUnequip(isoPlayer, worldItem, selectedWorldItems, equipType)
    elseif worldItem:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(isoPlayer, worldItem, 50))
    end
end

function FrameworkZ.Items:OnDropItemCallback(parameters, ...)
    local callbackParameters = type(parameters) == "table" and parameters or {parameters, ...}
    local extraArgs = { ... }

    local rawItems = nil
    local player = nil
    local isoPlayer = nil

    local looksLikeDropTuple = type(callbackParameters) == "table"
        and callbackParameters[1] ~= nil
        and callbackParameters[2] ~= nil
        and callbackParameters[3] ~= nil
        and type(callbackParameters[2]) == "number"

    if looksLikeDropTuple then
        rawItems = callbackParameters[1]
        player = callbackParameters[2]
        isoPlayer = callbackParameters[3]
    else
        rawItems = parameters
        player = extraArgs[1]
        isoPlayer = extraArgs[2]
    end

    -- Callback parameters can arrive as either {items, player, isoPlayer}
    -- or direct varargs. Guard getActualItems to prevent hard errors.
    if rawItems == nil then
        rawItems = callbackParameters[1]
    end

    local worldItems = {}
    if ISInventoryPane and ISInventoryPane.getActualItems then
        local ok, resolvedItems = pcall(ISInventoryPane.getActualItems, rawItems)
        if ok and type(resolvedItems) == "table" then
            worldItems = resolvedItems
        end
    end

    if #worldItems == 0 then
        if type(rawItems) == "userdata" then
            worldItems = { rawItems }
        elseif type(rawItems) == "table" then
            for _, value in pairs(rawItems) do
                if value and (type(value) == "userdata" or type(value) == "table") then
                    table.insert(worldItems, value)
                end
            end
        end
    end

    if (not isoPlayer or (type(isoPlayer) ~= "table" and type(isoPlayer) ~= "userdata")) and type(getSpecificPlayer) == "function" then
        if type(player) == "number" then
            isoPlayer = getSpecificPlayer(player)
        else
            isoPlayer = getSpecificPlayer(0)
        end
    end

    for _, worldItem in ipairs(worldItems) do
        if worldItem and worldItem.isFavorite and not worldItem:isFavorite() then
            local itemData = FrameworkZ.Items:GetStoredData(worldItem)

            if itemData then
                local instance = self:ResolveUsableInstance(worldItem, itemData)

                if instance then
                    local canDrop = false

                    if instance.CanDrop then
                        canDrop = instance:CanDrop(isoPlayer, worldItem)
                    end

                    if canDrop then
                        if instance.OnDrop then
                            instance:OnDrop(isoPlayer, worldItem)
                        end

                        ISInventoryPaneContextMenu.dropItem(worldItem, player)
                    end
                end
            else
                ISInventoryPaneContextMenu.dropItem(worldItem, player)
            end
        end
    end
end

function FrameworkZ.Items:OnPreFillInventoryObjectContextMenu(player, context, items)
    if not context then return end

    context._fzItemsMenuPhase = "prefill"
    context._fzItemsMenuBuilt = false
    context._fzItemsFallbackName = "Fallback"
end

function FrameworkZ.Items:OnFillInventoryObjectContextMenu(player, context, items)
    if not context or context._fzItemsMenuBuilt then return end

    context._fzItemsMenuPhase = "filling"

    local vanillaOptions = MenuManager.snapshotOptions(context)
    context:clear()

    local isoPlayer = getSpecificPlayer(player)
    local menuManager = MenuManager.new(context)
    local interactSubMenu = menuManager:addSubMenu("Interact")
    local inspectSubMenu = menuManager:addSubMenu("Inspect")
    local equipSubMenu = menuManager:addSubMenu("Equip")
    local manageSubMenu = menuManager:addSubMenu("Manage")

    items = ISInventoryPane.getActualItems(items)

    local uniqueIDCounts = {}
    for k, v in pairs(items) do
        if instanceof(v, "InventoryItem") then
            local itemData = FrameworkZ.Items:GetStoredData(v)

            if itemData then
                local uniqueID = itemData.uniqueID
                uniqueIDCounts[uniqueID] = (uniqueIDCounts[uniqueID] or 0) + 1
            else
                local uniqueID = v:getFullType()
                uniqueIDCounts[uniqueID] = (uniqueIDCounts[uniqueID] or 0) + 1
            end
        end
    end

    local uidLength = 0

    for _, _ in pairs(uniqueIDCounts) do
        uidLength = uidLength + 1
    end

    local itemEquipSubMenus = {}

    for k, v in pairs(items) do
        if instanceof(v, "InventoryItem") then

            local itemData = FrameworkZ.Items:GetStoredData(v)
            local uniqueID = nil
            local instanceID = nil
            local instance = nil

            local multipleTypesSelected = uidLength > 1
            local primaryItem = isoPlayer:getPrimaryHandItem()
            local secondaryItem = isoPlayer:getSecondaryHandItem()
            local bothHandsAreSelected = false
            local primaryHandIsSelected = false
            local secondaryHandIsSelected = false
            local canEquipPrimary = false
            local canEquipSecondary = false
            local canEquipBothHands = false

            if itemData then
                uniqueID = itemData.uniqueID
                instanceID = itemData.instanceID
                instance = self:ResolveUsableInstance(v, itemData)

                if instance then
                    local canContext = false
                    local canDrop = false
                    local canUse = false

                    if instance.CanContext then
                        canContext = instance:CanContext(isoPlayer, v)
                    end

                    if canContext then
                        if instance.OnContext then
                            local returnedContext = instance:OnContext(isoPlayer, v, items, menuManager, uniqueIDCounts[uniqueID])
                            if returnedContext and (type(returnedContext) == "table" or type(returnedContext) == "userdata") then
                                context = returnedContext
                            end
                        end

                        if instance.CanUse then
                            canUse = instance:CanUse(isoPlayer, v)
                        end

                        if canUse and instance.OnUse then
                            local useText = (instance.useText or "Use") .. " " .. instance.name
                            local useOption = Options.new(useText, self, FrameworkZ.Items.OnUseItemCallback, {v, instance, isoPlayer, player}, true, true, uniqueIDCounts[uniqueID])
                            menuManager:addAggregatedOption(uniqueID, useOption, interactSubMenu)
                        end

                        local examineText = "Examine " .. instance.name
                        local examineOption = Options.new(examineText, self, FrameworkZ.Items.OnExamineItemCallback, {v, instance, isoPlayer, player}, false, true, uniqueIDCounts[uniqueID])
                        menuManager:addAggregatedOption("Examine" .. uniqueID, examineOption, inspectSubMenu)

                        if instance.CanDrop then
                            canDrop = instance:CanDrop(isoPlayer, v)
                        end

                        if canDrop then
                            local dropText = multipleTypesSelected and "Drop Selected Items" or "Drop " .. instance.name
                            local dropOption = Options.new(dropText, self, FrameworkZ.Items.OnDropItemCallback, {items, player, isoPlayer}, false, true, multipleTypesSelected and 1 or uniqueIDCounts[uniqueID])
                            menuManager:addAggregatedOption(multipleTypesSelected and "DropSelectedItems" or uniqueID, dropOption, manageSubMenu)
                        end
                    end
                else
                    local option = Options.new()
                    option:setText("Malformed Item")
                    menuManager:addOption(option, interactSubMenu)
                end
            else
                local dropText = multipleTypesSelected and "Drop Selected Items" or "Drop " .. v:getName()
                local dropOption = Options.new(dropText, self, FrameworkZ.Items.OnDropItemCallback, {items, player, isoPlayer}, false, true, multipleTypesSelected and 1 or uniqueIDCounts[v:getFullType()])
                menuManager:addAggregatedOption(multipleTypesSelected and "DropSelectedItems" or v:getFullType(), dropOption, manageSubMenu)
            end

            if primaryItem and secondaryItem and v == primaryItem and v == secondaryItem then
                bothHandsAreSelected = v == primaryItem and v == secondaryItem
            elseif not bothHandsAreSelected then
                primaryHandIsSelected = primaryItem and v == primaryItem
                secondaryHandIsSelected = secondaryItem and v == secondaryItem
            end

            if multipleTypesSelected then
                local unequipText = multipleTypesSelected and "Unequip Selected Items" or nil
                local unequipOption = Options.new(unequipText, self, FrameworkZ.Items.OnUnequipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_IDEAL}, true, true, 1)
                menuManager:addAggregatedOption(multipleTypesSelected and "UnequipSelectedItems", unequipOption, equipSubMenu)

                local equipText = multipleTypesSelected and "Equip Selected Items" or nil
                local equipOption = Options.new(equipText, self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_IDEAL}, true, true, 1)
                menuManager:addAggregatedOption(multipleTypesSelected and "EquipSelectedItems", equipOption, equipSubMenu)

                if not itemEquipSubMenus[uniqueID or v:getFullType()] then
                    local option, subMenu = menuManager:getSubMenu("Equip"):addSubMenu(v:getName())
                    itemEquipSubMenus[uniqueID or v:getFullType()] = subMenu
                end
            end

            local dynamicEquipSubMenu = itemEquipSubMenus[uniqueID or v:getFullType()] or equipSubMenu

            if not bothHandsAreSelected then
                local canEquipBothHands = not instance or not instance.CanEquip or instance:CanEquip(isoPlayer, v, items, FZ_EQUIP_TYPE_BOTH_HANDS)
                if canEquipBothHands then
                    menuManager:addAggregatedOption(
                        "EquipBothHands" .. (uniqueID or v:getFullType()),
                        Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Both Hands)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_BOTH_HANDS}, false, true, 1),
                        dynamicEquipSubMenu
                    )
                end
            end

            if not primaryHandIsSelected then
                local canEquipPrimary = not instance or not instance.CanEquip or instance:CanEquip(isoPlayer, v, items, FZ_EQUIP_TYPE_PRIMARY)
                if canEquipPrimary then
                    menuManager:addAggregatedOption(
                        "EquipPrimary" .. (uniqueID or v:getFullType()),
                        Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Primary)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_PRIMARY}, false, true, 1),
                        dynamicEquipSubMenu
                    )
                end
            end

            if not secondaryHandIsSelected then
                local canEquipSecondary = not instance or not instance.CanEquip or instance:CanEquip(isoPlayer, v, items, FZ_EQUIP_TYPE_SECONDARY)
                if canEquipSecondary then
                    menuManager:addAggregatedOption(
                        "EquipSecondary" .. (uniqueID or v:getFullType()),
                        Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Secondary)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_SECONDARY}, false, true, 1),
                        dynamicEquipSubMenu
                    )
                end
            end

            if v:IsClothing() then
                if v:isWorn() then
                    menuManager:addAggregatedOption(
                        "UnequipClothing" .. (uniqueID or v:getFullType()),
                        Options.new("Unequip " .. (instance and instance.name or v:getName()) .. " (Clothing)", self, FrameworkZ.Items.OnUnequipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_CLOTHING}, false, true, 1),
                        dynamicEquipSubMenu
                    )
                else
                    local canEquipClothing = not instance or not instance.CanEquip or instance:CanEquip(isoPlayer, v, items, FZ_EQUIP_TYPE_CLOTHING)
                    if canEquipClothing then
                        menuManager:addAggregatedOption(
                            "EquipClothing" .. (uniqueID or v:getFullType()),
                            Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Clothing)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_CLOTHING}, false, true, 1),
                            dynamicEquipSubMenu
                        )
                    end
                end
            end

            local primaryItemData = FrameworkZ.Items:GetStoredData(primaryItem)
            local primaryInstance = self:ResolveUsableInstance(primaryItem, primaryItemData)
            local secondaryItemData = FrameworkZ.Items:GetStoredData(secondaryItem)
            local secondaryInstance = self:ResolveUsableInstance(secondaryItem, secondaryItemData)

            if bothHandsAreSelected then
                menuManager:addAggregatedOption(
                    "UnequipBothHands" .. (primaryInstance and primaryInstance.uniqueID or primaryItem:getFullType()),
                    Options.new("Unequip " .. (primaryInstance and primaryInstance.name or primaryItem:getName()) .. " (Both Hands)", self, FrameworkZ.Items.OnUnequipItemCallback, {primaryItem, items, primaryInstance, isoPlayer, FZ_EQUIP_TYPE_BOTH_HANDS}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end

            if primaryHandIsSelected then
                menuManager:addAggregatedOption(
                    "UnequipPrimary" .. (primaryInstance and primaryInstance.uniqueID or primaryItem:getFullType()),
                    Options.new("Unequip " .. (primaryInstance and primaryInstance.name or primaryItem:getName()) .. " (Primary)", self, FrameworkZ.Items.OnUnequipItemCallback, {primaryItem, items, primaryInstance, isoPlayer, FZ_EQUIP_TYPE_PRIMARY}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end

            if secondaryHandIsSelected then
                menuManager:addAggregatedOption(
                    "UnequipSecondary" .. (secondaryInstance and secondaryInstance.uniqueID or secondaryItem:getFullType()),
                    Options.new("Unequip " .. (secondaryInstance and secondaryInstance.name or secondaryItem:getName()) .. " (Secondary)", self, FrameworkZ.Items.OnUnequipItemCallback, {secondaryItem, items, secondaryInstance, isoPlayer, FZ_EQUIP_TYPE_SECONDARY}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end
        end
    end

    menuManager:buildMenu()
    menuManager:migrateOptionsToSubMenu(vanillaOptions, "Fallback")

    context._fzItemsMenuBuilt = true
    context._fzItemsMenuPhase = "done"

    if interactSubMenu:getContext():isEmpty() then
        local option = Options.new()
        option:setText("No Interactions Available")
        menuManager:addOption(option, interactSubMenu)
    end

    if inspectSubMenu:getContext():isEmpty() then
        local option = Options.new()
        option:setText("No Inspections Available")
        menuManager:addOption(option, inspectSubMenu)
    end

    if equipSubMenu:getContext():isEmpty() then
        local option = Options.new()
        option:setText("No Equipments Available")
        menuManager:addOption(option, equipSubMenu)
    end

    if manageSubMenu:getContext():isEmpty() then
        local option = Options.new()
        option:setText("No Management Options Available")
        menuManager:addOption(option, manageSubMenu)
    end
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Items)
