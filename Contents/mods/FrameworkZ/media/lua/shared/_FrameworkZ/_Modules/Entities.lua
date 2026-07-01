-- Refactor entities with a cache of tiles for the index and then the entity? Or pop up option for selecting entity on object spawned? Cache would still be needed.
-- It might be better to extend an entity by tile, but still use the cache.

--! \page Global Variables
--! \section Entities Entities
--! FrameworkZ.Entities
--! See Entities for the module on entities.
--! FrameworkZ.Entities.List
--! A list of all non-instanced entities in the game.

FrameworkZ = FrameworkZ or {}

--! \brief Entities module for FrameworkZ. Defines and interacts with ENTITY object.
--! \module FrameworkZ.Entities
FrameworkZ.Entities = {}
FrameworkZ.Entities.__index = FrameworkZ.Entities
FrameworkZ.Entities.List = {}
FrameworkZ.Entities = FrameworkZ.Foundation:NewModule(FrameworkZ.Entities, "Entities")

--! \brief Entity class for FrameworkZ.
--! \class ENTITY
local ENTITY = {}
ENTITY.__index = ENTITY

--! \brief Initialize an entity.
--! \return \string The entity's ID.
function ENTITY:Initialize()
    --if not self.worldObj then return end

    --local entityModData = self.worldObj:getModData()["ProjectFramework_Entity"] or nil
    
    return FrameworkZ.Entities:Initialize(self, self.name)
end

--! \brief Validate the entity's data.
--! \return \boolean Whether or not any of the entity's new data was initialized.
function ENTITY:ValidateEntityData(worldObject)
    local entityModData = worldObject:getModData()["PFW_ENT"]

    if not entityModData then return false end

    local initializedNewData = false
    
    if not entityModData.persistData then
        initializedNewData = true
        entityModData.persistData = self.persistData or {}
    else
        for k, v in pairs(self.persistData) do
            if not entityModData.persistData[k] then
                initializedNewData = true
                entityModData.persistData[k] = v
            end
        end
    end

    worldObject:transmitModData()

    return initializedNewData
end

--! \brief Create a new entity object.
--! \param name \string The entity's name (i.e. ID).
--! \param square \table The square the entity is on.
--! \return \table The entity's object table.
function FrameworkZ.Entities:New(name)
    local object = {
        name = name,
        description = "No description available."
    }

    setmetatable(object, ENTITY)

    return object
end

--! \brief Initialize an entity.
--! \param data \table The entity's object data
--! \param name \string The entity's name (i.e. ID)
--! \return \string Entity ID
function FrameworkZ.Entities:Initialize(data, name)
    FrameworkZ.Entities.List[name] = data

    return name
end

--! \brief Get an entity by their ID.
--! \param entityID \string The entity's ID.
--! \return \table Entity Object
function FrameworkZ.Entities:GetEntityByID(entityID)
    local entity = FrameworkZ.Entities.List[entityID] or nil
   
    return entity
end

--! \brief Get persisted entity data value by key from a world object.
--! \param worldObject \table The world object containing entity mod data.
--! \param index \string The persistData key to retrieve.
--! \return \mixed The stored value or nil if missing.
function FrameworkZ.Entities:GetData(worldObject, index)
    if worldObject then
        local entityPersistData = worldObject:getModData()["PFW_ENT"]
        
        if entityPersistData and entityPersistData[index] then
            return entityPersistData[index]
        end
    end
    
    return nil
end

--! \brief Update a persisted entity data value and transmit the change.
--! \param worldObject \table The world object containing entity mod data.
--! \param index \string The persistData key to update.
--! \param value \mixed The value to set.
--! \return \boolean Whether the data was updated.
function FrameworkZ.Entities:SetData(worldObject, index, value)
    if worldObject and index and value then
        local entityPersistData = worldObject:getModData()["PFW_ENT"]
        
        if entityPersistData and entityPersistData.persistData and entityPersistData.persistData[index] then
            entityPersistData.persistData[index] = value
            worldObject:transmitModData()
            return true
        end
    end
    
    return false
end

--! \brief Checks if an object is an entity (needs optimization from cached entities).
--! \param object \table The object to check.
--! \return \boolean Whether or not the object is an entity and its entity ID if it is an entity.
--! \return \integer The entity ID if the object is an entity.
function FrameworkZ.Entities:IsEntity(object)
    for id, entity in pairs(FrameworkZ.Entities.List) do
        for k, tile in pairs(entity.tiles) do
            if tile == object:getSprite():getName() then
                return true, id
            end
        end
    end

    return false, nil
end

--! \brief Play a world sound at an entity's square.
--! \param worldObject \table The world object to use as the source.
--! \param sound \string The sound cue name.
--! \return \boolean Whether the sound was queued.
function FrameworkZ.Entities:EmitSound(worldObject, sound)
    if worldObject and sound then
        getSoundManager():PlayWorldSound(sound, worldObject:getSquare(), 0, 8, 1, false)

        return true
    end

    return false
end

--! \brief Called when an object is added to the world. Adds the entity to the object's mod data.
--! \param object \table The object that was added to the world.
function FrameworkZ.Entities.OnObjectAdded(object)
    local isEntity, entityID = FrameworkZ.Entities:IsEntity(object)
    
    if isEntity then
        local entity = FrameworkZ.Entities:GetEntityByID(entityID)
        local coordinates = {x = object:getX(), y = object:getY(), z = object:getZ()}
        
        if entity then
            entity:Initialize()
            object:getModData()["PFW_ENT"] = {
                id = entityID,
                data = entity.persistData or {},
                coordinates = coordinates or {}
            }
            object:transmitModData()

            if entity.OnSpawn then
                entity:OnSpawn(getPlayer(), object)
            end
        end
    end
end
Events.OnObjectAdded.Add(FrameworkZ.Entities.OnObjectAdded)

--! \brief Invoked before an entity world object is removed.
--! \param object \table The object being removed.
function FrameworkZ.Entities.OnObjectAboutToBeRemoved(object)
	local isEntity, entityID = FrameworkZ.Entities:IsEntity(object)
    
    if isEntity then
        local entity = FrameworkZ.Entities:GetEntityByID(entityID)

        if entity and entity.OnRemove then
            entity:OnRemove(getPlayer(), object)
        end
    end
end
Events.OnObjectAboutToBeRemoved.Add(FrameworkZ.Entities.OnObjectAboutToBeRemoved)

--! \brief Build interaction submenu entries for entity objects on right-click.
--! \param player \integer The local player index.
--! \param context \table The context menu being built.
--! \param worldObjects \table The world objects under the cursor.
--! \param test \boolean Test flag from PZ hook.
function FrameworkZ.Entities:OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
    if type(context) ~= "table" or type(context.clear) ~= "function" then return end

    context._fzEntitiesMenuPhase = "prefill"
    context._fzEntitiesMenuBuilt = false
    context._fzEntitiesFallbackName = "Fallback"
end

--! \brief Build entity options after vanilla options are collected and migrate leftovers to fallback.
--! \param player \integer The local player index.
--! \param context \table The context menu being built.
--! \param worldObjects \table The world objects under the cursor.
--! \param test \boolean Test flag from PZ hook.
function FrameworkZ.Entities:OnFillWorldObjectContextMenu(player, context, worldObjects, test)
    if type(context) ~= "table" or type(context.clear) ~= "function" then return end
    if context._fzEntitiesMenuBuilt then return end
    if type(worldObjects) ~= "table" then worldObjects = {} end

    context._fzEntitiesMenuPhase = "filling"

    local vanillaOptions = MenuManager.snapshotOptions(context)
    context:clear()

    local playerObj = getSpecificPlayer(player)
    local menuManager = MenuManager.new(context)
    local interactSubMenu = menuManager:addSubMenu("Interact")
    local inspectSubMenu = menuManager:addSubMenu("Inspect")

    for _, worldObject in ipairs(worldObjects) do
        local entityData = nil
        if worldObject and type(worldObject) == "table" and worldObject.getModData then
            local modData = worldObject:getModData()
            entityData = modData and modData["PFW_ENT"]
        end

        if entityData then
            local entity = FrameworkZ.Entities:GetEntityByID(entityData.id)

            if entity then
                entity:ValidateEntityData(worldObject)

                local canContext = true
                if entity.CanContext then
                    canContext = entity:CanContext(playerObj, worldObject)
                end

                if canContext then
                    if entity.OnContext then
                        entity:OnContext(playerObj, worldObject, interactSubMenu:getContext())
                    elseif entity.OnUse then
                        menuManager:addOption(Options.new("Use " .. entity.name, entity, entity.OnUse, {playerObj, worldObject}, true), interactSubMenu)
                    end
                end

                local inspectOption = Options.new(
                    "Examine " .. entity.name,
                    entity,
                    function(targetEntity, callbackPlayer)
                        callbackPlayer:Say(targetEntity.description)
                    end,
                    {playerObj}
                )
                menuManager:addOption(inspectOption, inspectSubMenu)
            else
                menuManager:addOption(Options.new("Malformed Entity"), interactSubMenu)
            end
        end
    end

    menuManager:buildMenu()

    -- Separate vanilla world actions from other options
    local actionsOptions = {}
    local otherOptions = {}
    
    local vanillaActionNames = {
        ["Walk to"] = true,
        ["Sit on ground"] = true,
        ["Investigate This Area"] = true,
        ["Disassemble"] = true
    }

    local function getOptionText(opt)
        return opt.name or opt.text or opt.title or opt.displayText
    end
    
    for _, opt in ipairs(vanillaOptions) do
        local optText = getOptionText(opt)
        if optText and vanillaActionNames[optText] then
            table.insert(actionsOptions, opt)
        else
            table.insert(otherOptions, opt)
        end
    end
    
    -- Migrate actions and fallback using MenuManager (which skips empty buckets)
    menuManager:migrateOptionsToSubMenu(actionsOptions, "Actions")
    menuManager:migrateOptionsToSubMenu(otherOptions, context._fzEntitiesFallbackName or "Fallback")

    context._fzEntitiesMenuBuilt = true
    context._fzEntitiesMenuPhase = "done"

    if interactSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Interactions Available"), interactSubMenu)
    end

    if inspectSubMenu:getContext():isEmpty() then
        menuManager:addOption(Options.new("No Inspections Available"), inspectSubMenu)
    end
end

--! \brief Register entity context menu hook once the game starts.
function FrameworkZ.Entities.OnGameStart()
    Events.OnPreFillWorldObjectContextMenu.Add(function(player, context, worldObjects, test)
        FrameworkZ.Entities:OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
    end)
    Events.OnFillWorldObjectContextMenu.Add(function(player, context, worldObjects, test)
        FrameworkZ.Entities:OnFillWorldObjectContextMenu(player, context, worldObjects, test)
    end)
end

--! \brief Placeholder for loading entity data on chunk load.
--! \param square \table The gridsquare being loaded.
function FrameworkZ.Entities:LoadGridsquare(square)
    --[[
	for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i)

        if object and object:getModData()["PFW_ENT"] then
            local entityID = object:getModData()["PFW_ENT"].id
            local entity = FrameworkZ.Entities:GetEntityByID(entityID)

            if entity and not entity.isInitialized then
                entity:OnInitialize(object)
                entity.isInitialized = true
            end
        end
    end
	--]]
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Entities)
