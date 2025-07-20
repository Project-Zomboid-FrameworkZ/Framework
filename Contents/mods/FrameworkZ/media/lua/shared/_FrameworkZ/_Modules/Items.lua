ISEquipWeaponAction = ISEquipWeaponAction
ISTimedActionQueue = ISTimedActionQueue
ISUnequipAction = ISUnequipAction
ISWearClothing = ISWearClothing

FrameworkZ = FrameworkZ or {}

--! \brief Items module for FrameworkZ. Defines and interacts with ITEM \object.
--! \class FrameworkZ.Items
FrameworkZ.Items = {}
FrameworkZ.Items.__index = FrameworkZ.Items

FZ_EQUIP_TYPE_IDEAL = "Ideal"
FZ_EQUIP_TYPE_CLOTHING = "Clothing"
FZ_EQUIP_TYPE_PRIMARY = "Primary"
FZ_EQUIP_TYPE_SECONDARY = "Secondary"
FZ_EQUIP_TYPE_BOTH_HANDS = "BothHands"

FrameworkZ.Items.List = {}
FrameworkZ.Items.Bases = {}
FrameworkZ.Items.Instances = {}

--! \brief An instance map. Contains references to item instances indexed by an item's unique ID and instance ID as a string for optimized lookups. Instance Map is structured as follows: [uniqueID][username][#index] = instance
FrameworkZ.Items.InstanceMap = {}
FrameworkZ.Items = FrameworkZ.Foundation:NewModule(FrameworkZ.Items, "Items")

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

function FrameworkZ.Items:CreateWorldItem(isoPlayer, fullItemID)
    if not isoPlayer then return false, "Missing ISO Player." end
    if not fullItemID then return false, "Missing full item ID." end

    local worldItem = isoPlayer:getInventory():AddItem(InventoryItemFactory.CreateItem(fullItemID))

    return true, "Created world item.", worldItem
end

--! \brief Creates an item instance and links it to a world item.
--! \param uniqueID \string The unique ID of the item to create.
--! \param isoPlayer \object The ISO Player to create the item for.
--! \param callback \function (Optional) A callback function to execute after the item is created but before OnInstanced is called.
--! \return \boolean \string \object \object Success status and message, also the item instance and world item.
function FrameworkZ.Items:CreateItem(uniqueID, isoPlayer, callback)
    if not uniqueID then return false, "Missing item ID." end
    if not isoPlayer then return false, "Missing ISO Player." end

    local item = self:GetItemByUniqueID(uniqueID)

    if not item then return false, "Item not found." end

    local success, message, worldItem = FrameworkZ.Items:CreateWorldItem(isoPlayer, item.itemID)

    if not success or not worldItem then return false, message end

    local instanceID, instance = self:AddInstance(item, isoPlayer, worldItem, callback)

    local instanceData = {
        uniqueID = instance.uniqueID,
        itemID = worldItem:getFullType(),
        instanceID = instanceID,
        owner = isoPlayer:getUsername(),
        name = instance.name or "Unknown",
        description = instance.description or "No description available.",
        category = instance.category or "Uncategorized",
        shouldConsume = instance.shouldConsume or false,
        weight = instance.weight or 1,
        useAction = instance.useAction or nil,
        useTime = instance.useTime or nil,
        customFields = instance.customFields or {}
    }

    FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)

    return instance, "Created " .. instance.uniqueID .. " item.", worldItem
end

function FrameworkZ.Items:AddInstance(item, isoPlayer, worldItem, callback)
    local instanceID = #self.Instances + 1

    item["instanceID"] = instanceID
    item["owner"] = isoPlayer:getUsername()
    item["worldItemID"] = worldItem:getID()
    item["worldItem"] = worldItem
    table.insert(self.Instances, FrameworkZ.Utilities:CopyTable(item))

    local itemInstance = self.Instances[instanceID]

    if not self.InstanceMap[item.uniqueID] then
        self.InstanceMap[item.uniqueID] = {}
    end

    if not self.InstanceMap[item.uniqueID][isoPlayer:getUsername()] then
        self.InstanceMap[item.uniqueID][isoPlayer:getUsername()] = {}
    end

    table.insert(self.InstanceMap[item.uniqueID][isoPlayer:getUsername()], itemInstance)

    if callback then
        callback(isoPlayer, itemInstance, worldItem)
    end

    if itemInstance.OnInstanced then
        itemInstance:OnInstanced(isoPlayer, worldItem)
    end

    return instanceID, itemInstance
end

function FrameworkZ.Items:LinkWorldItemToInstanceData(worldItem, instanceData)
    worldItem:getModData()["FZ_ITM"] = instanceData
    worldItem:setName(instanceData.name)
    worldItem:setActualWeight(instanceData.weight)
end

function FrameworkZ.Items:GetStoredData(worldItem)
    if not worldItem then return false, "Missing world item." end

    local itemData = worldItem:getModData()["FZ_ITM"]

    return itemData or false, "No stored item data found."
end

function FrameworkZ.Items:GetItemByUniqueID(uniqueID)
    local item = self.List[uniqueID] or nil

    return item
end

function FrameworkZ.Items:GetInstance(instanceID)
    if not instanceID or instanceID == "" then return false, "Missing instance ID." end

    local instance = self.Instances[instanceID]

    if not instance then return false, "Instance not found." end

    return self.Instances[instanceID]
end

function FrameworkZ.Items:FindFirstInstanceByID(owner, uniqueID)
    if not owner or owner == "" then return false, "Missing owner." end
    if not uniqueID or uniqueID == "" then return false, "Missing unique ID." end

    local instance = self.InstanceMap[uniqueID][owner][1]

    if not instance then return false, "Instance not found." end

    return instance
end

function FrameworkZ.Items:RemoveItemInstanceByUniqueID(owner, uniqueID)
    if not owner or owner == "" then return false, "Missing owner." end
    if not uniqueID or uniqueID == "" then return false, "Missing unique ID." end

    local instance = FrameworkZ.Items:FindFirstInstanceByID(owner, uniqueID)

    if not instance then return false, "Instance not found." end

    return FrameworkZ.Items:RemoveInstance(instance.instanceID)
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

    if instance.owner then
        player.isoPlayer:getInventory():DoRemoveItem(instance.worldItem)
    elseif instance.worldItem:getContainer() then
        instance.worldItem:getContainer():removeItemOnServer(instance.worldItem)
        instance.worldItem:getContainer():DoRemoveItem(instance.worldItem)
    end

    inventory:RemoveItem(instance)

    local instanceMap = self.InstanceMap[instance.uniqueID][instance.owner]

    -- It was a choice to either loop the item instance map on item removal, or loop the item instance list on item lookup. This seemed more efficient because the item
    -- instance list is every single instance across every character, while the instance map is only the instances for a specific item on a specific character.
    for k, v in ipairs(instanceMap) do
        if v.instanceID == instanceID then
            table.remove(self.InstanceMap[instance.uniqueID][instance.owner], k)
            break
        end
    end

    self.Instances[instanceID] = nil

    return true, "Removed item instance #" .. instanceID .. "."
end

-- TODO use multiple items, not just one
function FrameworkZ.Items:OnUseItemCallback(parameters)
    local worldItem, item, playerObject = parameters[1], parameters[2], parameters[3]

    item:OnUse(playerObject, worldItem)
end

function FrameworkZ.Items:OnExamineItemCallback(parameters)
    local worldItem, instance, playerObject = parameters[1], parameters[2], parameters[3]

    playerObject:Say(instance.description)
end

function FrameworkZ.Items:OnEquipItemCallback(parameters)
    local worldItem, selectedWorldItems, instance, isoPlayer, equipType = parameters[1], parameters[2], parameters[3], parameters[4], parameters[5]

    if equipType == FZ_EQUIP_TYPE_IDEAL then
        for _, v in pairs(selectedWorldItems) do
            local itemData = FrameworkZ.Items:GetStoredData(v)
            local selectedInstance = self:GetInstance(itemData and itemData.instanceID or nil)

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

function FrameworkZ.Items:OnUnequipItemCallback(parameters)
    local worldItem, selectedWorldItems, instance, isoPlayer, equipType = parameters[1], parameters[2], parameters[3], parameters[4], parameters[5]

    if equipType == FZ_EQUIP_TYPE_IDEAL then
        for _, v in pairs(selectedWorldItems) do
            if v:isEquipped() then
                local itemData = FrameworkZ.Items:GetStoredData(v)
                local selectedInstance = self:GetInstance(itemData and itemData.instanceID or nil)

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

function FrameworkZ.Items:OnDropItemCallback(parameters)
    local worldItems, player, isoPlayer = ISInventoryPane.getActualItems(parameters[1]), parameters[2], parameters[3]

    for _, worldItem in ipairs(worldItems) do
        if not worldItem:isFavorite() then
            local itemData = FrameworkZ.Items:GetStoredData(worldItem)

            if itemData then
                local instance = self:GetInstance(itemData.instanceID)

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

function FrameworkZ.Items:OnFillInventoryObjectContextMenu(player, context, items)
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
                instance = self:GetInstance(instanceID)

                if instance then
                    local canContext = false
                    local canDrop = false
                    local canUse = false

                    if instance.CanContext then
                        canContext = instance:CanContext(isoPlayer, v)
                    end

                    if canContext then
                        if instance.OnContext then
                            context = instance:OnContext(isoPlayer, v, items, menuManager, uniqueIDCounts[uniqueID])
                        end

                        if instance.CanUse then
                            canUse = instance:CanUse(isoPlayer, v)
                        end

                        if canUse and instance.OnUse then
                            local useText = (instance.useText or "Use") .. " " .. instance.name
                            local useOption = Options.new(useText, self, FrameworkZ.Items.OnUseItemCallback, {v, instance, isoPlayer}, true, true, uniqueIDCounts[uniqueID])
                            menuManager:addAggregatedOption(uniqueID, useOption, interactSubMenu)
                        end

                        local examineText = "Examine " .. instance.name
                        local examineOption = Options.new(examineText, self, FrameworkZ.Items.OnExamineItemCallback, {v, instance, isoPlayer}, false, true, uniqueIDCounts[uniqueID])
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

            local function GenerateEquipSubMenu(optionID, option, optionTarget, equipType)
                local canEquip = false

                if instance and instance.CanEquip then
                    canEquip = instance:CanEquip(isoPlayer, v, items, equipType)
                else
                    canEquip = true
                end

                if canEquip then
                    menuManager:addAggregatedOption(optionID, option, optionTarget)
                end
            end

            local function GenerateUnequipSubMenu(optionID, option, optionTarget)
                menuManager:addAggregatedOption(optionID, option, optionTarget)
            end

            local dynamicEquipSubMenu = itemEquipSubMenus[uniqueID or v:getFullType()] or equipSubMenu

            if not bothHandsAreSelected then
                GenerateEquipSubMenu(
                    "EquipBothHands" .. (uniqueID or v:getFullType()),
                    Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Both Hands)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_BOTH_HANDS}, false, true, 1),
                    dynamicEquipSubMenu,
                    FZ_EQUIP_TYPE_BOTH_HANDS
                )
            end

            if not primaryHandIsSelected then
                GenerateEquipSubMenu(
                    "EquipPrimary" .. (uniqueID or v:getFullType()),
                    Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Primary)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_PRIMARY}, false, true, 1),
                    dynamicEquipSubMenu,
                    FZ_EQUIP_TYPE_PRIMARY
                )
            end

            if not secondaryHandIsSelected then
                GenerateEquipSubMenu(
                    "EquipSecondary" .. (uniqueID or v:getFullType()),
                    Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Secondary)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_SECONDARY}, false, true, 1),
                    dynamicEquipSubMenu,
                    FZ_EQUIP_TYPE_SECONDARY
                )
            end

            if v:IsClothing() then
                if v:isWorn() then
                    GenerateUnequipSubMenu(
                        "UnequipClothing" .. (uniqueID or v:getFullType()),
                        Options.new("Unequip " .. (instance and instance.name or v:getName()) .. " (Clothing)", self, FrameworkZ.Items.OnUnequipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_CLOTHING}, false, true, 1),
                        dynamicEquipSubMenu
                    )
                else
                    GenerateEquipSubMenu(
                        "EquipClothing" .. (uniqueID or v:getFullType()),
                        Options.new("Equip " .. (instance and instance.name or v:getName()) .. " (Clothing)", self, FrameworkZ.Items.OnEquipItemCallback, {v, items, instance, isoPlayer, FZ_EQUIP_TYPE_CLOTHING}, false, true, 1),
                        dynamicEquipSubMenu,
                        FZ_EQUIP_TYPE_CLOTHING
                    )
                end
            end

            local primaryItemData = FrameworkZ.Items:GetStoredData(primaryItem)
            local primaryInstance = self:GetInstance(primaryItemData and primaryItemData.instanceID or nil)
            local secondaryItemData = FrameworkZ.Items:GetStoredData(secondaryItem)
            local secondaryInstance = self:GetInstance(secondaryItemData and secondaryItemData.instanceID or nil)

            if bothHandsAreSelected then
                GenerateUnequipSubMenu(
                    "UnequipBothHands" .. (primaryInstance and primaryInstance.uniqueID or primaryItem:getFullType()),
                    Options.new("Unequip " .. (primaryInstance and primaryInstance.name or primaryItem:getName()) .. " (Both Hands)", self, FrameworkZ.Items.OnUnequipItemCallback, {primaryItem, items, primaryInstance, isoPlayer, FZ_EQUIP_TYPE_BOTH_HANDS}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end

            if primaryHandIsSelected then
                GenerateUnequipSubMenu(
                    "UnequipPrimary" .. (primaryInstance and primaryInstance.uniqueID or primaryItem:getFullType()),
                    Options.new("Unequip " .. (primaryInstance and primaryInstance.name or primaryItem:getName()) .. " (Primary)", self, FrameworkZ.Items.OnUnequipItemCallback, {primaryItem, items, primaryInstance, isoPlayer, FZ_EQUIP_TYPE_PRIMARY}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end

            if secondaryHandIsSelected then
                GenerateUnequipSubMenu(
                    "UnequipSecondary" .. (secondaryInstance and secondaryInstance.uniqueID or secondaryItem:getFullType()),
                    Options.new("Unequip " .. (secondaryInstance and secondaryInstance.name or secondaryItem:getName()) .. " (Secondary)", self, FrameworkZ.Items.OnUnequipItemCallback, {secondaryItem, items, secondaryInstance, isoPlayer, FZ_EQUIP_TYPE_SECONDARY}, false, true, 1),
                    dynamicEquipSubMenu
                )
            end
        end
    end

    menuManager:buildMenu()

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
