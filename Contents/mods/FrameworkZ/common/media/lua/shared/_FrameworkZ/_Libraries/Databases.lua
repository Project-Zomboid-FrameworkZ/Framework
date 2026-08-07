--[[
local db, message = FrameworkZ.Databases:Initialize("Players")

if not db then
    print("Failed to create database: " .. message)
    return
end

--local db = FrameworkZ.Databases:GetDatabase("Players")
db:AddSubscriber(FrameworkZ.Players:GetPlayerByID(getPlayer():getUsername()), FrameworkZ.Characters:GetCharacterByID(getPlayer():getUsername()), false)

--local db = FrameworkZ.Databases:GetDatabase("Players")
local field = FrameworkZ.Databases:SetData(db, "PlayerObject", "example_username")

if field then
    field:AddSubscriber(FrameworkZ.Players:GetPlayerByID(getPlayer():getUsername()), FrameworkZ.Characters:GetCharacterByID(getPlayer():getUsername()), false)
end
--]]

local isClient = isClient
local isServer = isServer
local ModData = ModData

FrameworkZ = FrameworkZ or {}

FrameworkZ.Databases = {}
FrameworkZ.Databases = FrameworkZ.Foundation:NewModule(FrameworkZ.Databases, "Databases")

FrameworkZ.Databases.Prefix = "FZ_"
FrameworkZ.Databases.Namespaces = FrameworkZ.Databases.Namespaces or {}
FrameworkZ.Databases.List = {}

--! \class DATABASE
--! \brief Database class for FrameworkZ.
local DATABASE = {}
DATABASE.__index = DATABASE

function DATABASE:Initialize()
    local data = ModData.getOrCreate(FrameworkZ.Databases.Prefix .. self:GetName())

    for k, v in pairs(data) do
        self.Data[k] = v
    end
end

function DATABASE:Broadcast()
    if not isServer() then return end

    for _, subscriber in pairs(self.Subscribers) do
        if subscriber.Player then
            print("Broadcasting database ", self:GetName(), " to ", subscriber.Player:GetUsername())
            FrameworkZ.Foundation:SendFire(subscriber.Player:GetIsoPlayer(), "FrameworkZ.Databases.OnBroadcast", nil, self:GetName(), self:GetData())
        end
    end
end

if isClient() then
    function FrameworkZ.Databases.OnBroadcast(data, dbName, dbData)
        local db = FrameworkZ.Databases:GetDatabase(dbName) if not db then return end

        db:SetData(dbData)
        print("Received broadcast for database ", dbName)
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Databases.OnBroadcast", FrameworkZ.Databases.OnBroadcast)
end

--! \brief Adds a subscriber to the database.
--! \note Character subscriptions will always be removed on character unload. However a player's subscription will persist between loads unless 'temporary' parameter is true.
--! \param player \object The player object subscribing.
--! \param character \object? The character object subscribing.
--! \param temporary \bool Whether the subscription is temporary.
--! \return \bool \string success, message
function DATABASE:AddSubscriber(player, character, temporary)
    if self.Subscribers[player:GetUsername()] then return false, "Player already subscribed" end

    self.Subscribers[player:GetUsername()] = {
        Player = player or false,
        Character = character or false,
        Temporary = temporary or false
    }

    return true
end

function DATABASE:RemoveSubscriber(player, character, sticky)
    if not self.Subscribers[player:GetUsername()] then return false, "Player not subscribed" end

    if not sticky and player then
        self.Subscribers[player:GetUsername()] = nil
    end

    if sticky and character then
        self.Subscribers[player:GetUsername()].Character = nil
    end

    return true
end

function DATABASE:GetData() return self.Data end
function DATABASE:GetField(name) 
    local entry = rawget(self.Data, name)
    return entry and entry.field or nil
end
function DATABASE:GetName() return self.Name end
function DATABASE:GetSubscribers() return self.Subscribers end

function DATABASE:Save()
    local modData = ModData.getOrCreate(FrameworkZ.Databases.Prefix .. self:GetName())
    
    -- Extract just the values for ModData storage
    for k, entry in pairs(self.Data) do
        if type(entry) == "table" and entry.value ~= nil then
            modData[k] = entry.value
        else
            modData[k] = entry
        end
    end
    
    ModData.transmit(FrameworkZ.Databases.Prefix .. self:GetName())
end

function DATABASE:SetData(data) self.Data = data end
function DATABASE:SetField(name, value) self.Fields[name] = value end
function DATABASE:SetName(name) print("[FZ] Warning: Failed to set database name. DB Name must be set on initialization.") end
function DATABASE:SetSubscribers(subscribers) print("[FZ] Warning: Failed to set database subscribers. Use DATABASE:AddSubscriber() or DATABASE:RemoveSubscriber() instead.") end

function FrameworkZ.Databases:GetDatabase(name) return self.List[name] end

function FrameworkZ.Databases:New(name)
    if not name or name == "" then return false, "Invalid name" end
    if self:GetDatabase(name) then return false, "Database already exists" end

    local object = {
        Name = name,
        Subscribers = {},
        Data = {}
    }

    setmetatable(object, DATABASE)

    return object
end

function FrameworkZ.Databases:Initialize(name)
    local database, message = FrameworkZ.Databases:New(name) if not database then return false, "Failed to create database: " .. message end
    database:Initialize()

    self.List[name] = database

    return self.List[name]
end

--! \brief Retrieves data from a specified database and keys.
--! \param database \string|\object The name of the database or the specific database object.
--! \param keys \table The keys to traverse in the database.
--! \return \any \string The retrieved data or nil if not found, and a message if applicable.
function FrameworkZ.Databases:GetData(database, keys)
    local db = type(database) == "string" and self:GetDatabase(database) or database
    local data = db and db:GetData() or nil if not data then return nil, nil, "No data in database" end

    if not db then
        return nil, nil, "Database not found"
    end

    local field

    for _, key in ipairs(keys) do
        if data and not data[key] then
            data = data[key].value
            field = data[key].field
        else
            return nil, nil, "Data not found"
        end
    end

    return data, field
end

function FrameworkZ.Databases:SetData(database, keys, value, doNotSave, doNotBroadcast)
    local db = type(database) == "string" and self:GetDatabase(database) or database

    if not db then
        return false, "Database not found"
    end

    -- Handle single key as string by converting to table
    if type(keys) == "string" then
        keys = {keys}
    end

    local data = db:GetData()
    if not data then
        return false, "No data in database"
    end

    local field
    local currentData = data
    local keyCode = ""

    -- Navigate to the target location, creating intermediate tables as needed
    for i, key in ipairs(keys) do
        keyCode = keyCode .. ":" .. tostring(key)

        if i == #keys then
            if not currentData[key] then
                currentData[key] = {
                    field = FrameworkZ.Fields:Initialize(db:GetName(), keyCode),
                    value = {}
                }
            end

            -- This is the final key, set the value using the metamethod
            print("DEBUG: Setting final key:", tostring(key), " = ", tostring(value), " on table:", tostring(currentData))
            currentData[key].value = value
            if currentData[key] and currentData[key].field then
                field = currentData[key].field
                print("DEBUG: Found field:", tostring(field))
            else
                print("DEBUG: No field found in entry")
            end
        else
            if not currentData[key] then
                currentData[key] = {
                    field = FrameworkZ.Fields:Initialize(db:GetName(), keyCode),
                    value = {}
                }
            end
            currentData = currentData[key]
        end
    end

    if not doNotSave and isClient() then
        FrameworkZ.Foundation:SendFire(nil, "FrameworkZ.Databases.OnSetData", nil, db:GetName(), keys, value)
    elseif not doNotSave and isServer() then
        db:Save()
    end

    if not doNotBroadcast then
        db:Broadcast()

        if field then
            field:Broadcast()
        end
    end

    return field or false
end

if isServer() then
    function FrameworkZ.Databases.OnSetData(data, database, keys, value)
        if not FrameworkZ.Databases:SetData(database, keys, value) then
            print("Failed to set data in database: ", database) -- TODO log with module
        end
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Databases.OnSetData", FrameworkZ.Databases.OnSetData)
end

FrameworkZ.Fields = {}
FrameworkZ.Fields = FrameworkZ.Foundation:NewModule(FrameworkZ.Fields, "Fields")

FrameworkZ.Fields.List = {}

--! \class FIELD
--! \brief Database Field class for FrameworkZ.
local FIELD = {}
FIELD.__index = FIELD

function FIELD:GetDatabaseName() return self.DatabaseName end
function FIELD:GetKeys() return self.Keys end
function FIELD:GetTable() return self.Table end
function FIELD:GetValue() return self.Value end

function FIELD:SetDatabaseName(name) self.DatabaseName = name end
function FIELD:SetKeys(keys) self.Keys = keys end
function FIELD:SetTable(tbl) print("[FZ] Warning: Failed to set field table. Table must be set on initialization.") end
function FIELD:SetValue(value)
    self.Value = value
    self:Broadcast()
end

function FIELD:Initialize()
    -- Initialize method for field - can be extended later if needed
    -- For now, just ensure the field is properly set up
    return true
end

function FIELD:Broadcast()
    if not isServer() then return end

    for _, subscriber in pairs(self.Subscribers) do
        if subscriber.Player then
            print("Broadcasting field ", self:GetDatabaseName(), ":", tostring(self:GetKeys()), " to ", subscriber.Player:GetUsername())
            FrameworkZ.Foundation:SendFire(subscriber.Player:GetIsoPlayer(), "FrameworkZ.Fields.OnBroadcast", nil, self:GetDatabaseName(), self:GetKeys(), self:GetValue())
        end
    end
end

if isClient() then
    function FrameworkZ.Fields.OnBroadcast(data, dbName, keys, value)
        local db = FrameworkZ.Databases:GetDatabase(dbName) if not db then return end
        local field

        for i, key in ipairs(keys) do
            if i == #keys then
                db[key].value = value
                field = db[key].field
            else
                db = db[key] or {}
            end
        end

        if field then
            field:SetValue(value)
        end

        print("Received broadcast for field ", dbName, ":", tostring(keys))
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Fields.OnBroadcast", FrameworkZ.Fields.OnBroadcast)
end

function FIELD:AddSubscriber(player, character, temporary)
    if self.Subscribers[player:GetUsername()] then return false, "Player already subscribed" end

    self.Subscribers[player:GetUsername()] = {
        Player = player or false,
        Character = character or false,
        Temporary = temporary or false
    }

    return true
end

function FIELD:RemoveSubscriber(player, character, sticky)
    if not self.Subscribers[player:GetUsername()] then return false, "Player not subscribed" end

    if not sticky and player then
        self.Subscribers[player:GetUsername()] = nil
    end

    if sticky and character then
        self.Subscribers[player:GetUsername()].Character = nil
    end

    return true
end

function FrameworkZ.Fields:New()
    local object = {
        Subscribers = {}
    }

    setmetatable(object, FIELD)

    return object
end

function FrameworkZ.Fields:Initialize(dbName, keyCode)
    local field, message = FrameworkZ.Fields:New() if not field then return false, "Failed to create field: " .. message end
    local id = tostring(dbName) .. tostring(keyCode)
    field:Initialize()

    self.List[id] = field

    return self.List[id]
end

function FrameworkZ.Fields:GetList() return self.List end
