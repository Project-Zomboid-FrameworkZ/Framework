-- Refactor entities with a cache of tiles for the index and then the entity? Or pop up option for selecting entity on object spawned? Cache would still be needed.
-- It might be better to extend an entity by tile, but still use the cache.

--! \page global_variables Global Variables
--! \section Entities Entities
--! FrameworkZ.Entities\n
--! See Entities for the module on entities.\n\n
--! FrameworkZ.Entities.List\n
--! A list of all non-instanced entities in the game.

FrameworkZ = FrameworkZ or {}

--! \brief Entities module for FrameworkZ. Defines and interacts with ENTITY object.
--! \class FrameworkZ.Entities
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

function FrameworkZ.Entities:GetData(worldObject, index)
    if worldObject then
        local entityPersistData = worldObject:getModData()["PFW_ENT"]
        
        if entityPersistData and entityPersistData[index] then
            return entityPersistData[index]
        end
    end
    
    return nil
end

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

function FrameworkZ.Entities.OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
	local playerObj = getSpecificPlayer(player)
	
    local interact = context:addOptionOnTop("Interact")
    local interactContext = ISContextMenu:getNew(context)
    context:addSubMenu(interact, interactContext)

    for k, v in pairs(worldObjects) do
        if v:getModData()["PFW_ENT"] then
            local entityID = v:getModData()["PFW_ENT"].id
            local entity = FrameworkZ.Entities:GetEntityByID(entityID)

            if entity then
                local canContext = false

                entity:ValidateEntityData(v)

                if entity.CanContext then
                    canContext = entity:CanContext(playerObj, v)
                end

                if canContext then
                    if entity.OnContext then
                        context = entity:OnContext(playerObj, v, interactContext)
                    elseif entity.OnUse then
                        interactContext:addOptionOnTop("Use " .. entity.name, entity, entity.OnUse, playerObj, v)
                    end
                end

                interactContext:addOption("Examine " .. entity.name, entity, function(entity, playerObj) playerObj:Say(entity.description) end, playerObj)
            else
                interactContext:addOption("Malformed Entity")
            end
        end
    end

    if interactContext:isEmpty() then
        interactContext:addOption("No Interactions Available")
    end
end

function FrameworkZ.Entities.OnGameStart()
    Events.OnPreFillWorldObjectContextMenu.Add(FrameworkZ.Entities.OnPreFillWorldObjectContextMenu)
end

function FrameworkZ.Entities:LoadGridsquare(square)
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
end
