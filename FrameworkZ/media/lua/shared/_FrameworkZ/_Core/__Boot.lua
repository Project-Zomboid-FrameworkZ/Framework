local internalObjects = {}
local lockedObjects = {}

local function hashObject(depth, object)
    local actualDepth = depth or 0
    local components = {}

    local function collect(tbl, prefix)
        for k, v in pairs(tbl) do
            local keyPath = prefix .. "." .. tostring(k)

            if type(v) == "function" and not k:match("^_+") then
                table.insert(components, keyPath .. ":" .. tostring(v))
            elseif (actualDepth <= -1 or actualDepth >= 1) and type(v) == "table" and not k:match("^_+") and not v.__skipWrap then
                actualDepth = actualDepth - 1
                collect(v, keyPath)
            end
        end
    end

    collect(object, object.Meta and object.Meta.Name or "object")
    table.sort(components)

    return table.concat(components, "|")
end

local function createSecureFunction(originalFunction, object, originalObject)
    return setmetatable(originalObject or {}, {
        __call = function(tbl, ...)
            local currentHash = hashObject(object.__hashDepth, object)

            if object.__hash ~= currentHash then
                FrameworkZ.Notifications:AddToQueue("Tampering Detected: Object integrity check failed. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)

                error("Tampering Detected: Object integrity check failed. This has been logged.")
                return
            end

            return originalFunction(...)
        end
        --[[__newindex = function(tbl, key, value)
            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Tampering Attempt: Cannot override object after locking. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)
            end

            error("Tampering Attempt: Cannot override object after locking. This has been logged.")
            return
        end,--]]
        --__metatable = false
    })
end

local function wrapFunctionsWithValidation(depth, tbl, object, visited)
    local actualDepth = depth or 0

    visited = visited or {}
    if visited[tbl] then return end
    visited[tbl] = true

    for k, v in pairs(tbl) do
        if type(v) == "function" and not k:match("^_+") then
            tbl[k] = createSecureFunction(v, object)
        elseif (actualDepth <= -1 or actualDepth >= 1) and type(v) == "table" and not k:match("^_+") and not v.__skipWrap then
            wrapFunctionsWithValidation(actualDepth - 1, v, object, visited)
        end
    end

    tbl = createSecureFunction(tbl, object, tbl)

    return tbl
end

-- Proper newObject with metatable
local function newFrameworkZ()
    local object = {
        Meta = {
            Name = "FrameworkZ",
            Author = "N/A",
            Description = "No description set.",
            Version = "1.0.0",
            Compatibility = ""
        },
        __locked = false,
    }

    setmetatable(object, {
        __index = {}
    })

    -- Attach base object logic for module creation
    object.CreateObject = function(self, tbl, name)
        tbl = tbl or {}
        tbl.Meta = {
            Name = name,
            Author = "N/A",
            Description = "No description set.",
            Version = "1.0.0",
            Compatibility = ""
        }
        tbl.__locked = false

        return setmetatable(tbl, {
            __index = self
        })
    end

    return object
end

FrameworkZ = newFrameworkZ()
FrameworkZ.Meta.Author = "RJ_RayJay"
FrameworkZ.Meta.Description = "FrameworkZ Bootstrap"
FrameworkZ.Meta.Version = "1.0.0"

FrameworkZ.Config = {}
FrameworkZ.Config.Options = {
    SkipIntro = true,
    Version = "9.7.3",
    VersionType = "alpha",

    IntroFrameworkImage = "media/textures/fz.png",
    IntroGamemodeImage = "media/textures/hl2rp.png",
    MainMenuImage = "media/textures/citidel.png",

    IntroMusic = "hl2_song25_teleporter_short", -- Approximately 15 seconds long
    MainMenuMusic = "hl2_song19",

    FrameworkTitle = "FrameworkZ",
    GamemodeTitle = "No Gamemode Loaded",
    GamemodeDescription = "The base FrameworkZ foundation.",

    CharacterMinAge = 18, -- Years
    CharacterMaxAge = 100, -- Years
    CharacterMinHeight = 48, -- Inches
    CharacterMaxHeight = 84, -- Inches
    CharacterMinWeight = 80, -- Pounds
    CharacterMaxWeight = 300, -- Pounds

    InitializationDuration = 3, --In seconds. Not recommended to set any lower than 3 second.
    ServerTickInterval = 1, -- In seconds. Increasing this may improve performance at the cost of responsiveness. Default: 1 second.
    TicksUntilServerSave = 180, -- In ticks, by the Server Tick Interval. Default: 1200 (20 minutes).

    PlayerTickInterval = 1, -- In seconds. Increasing this may improve performance at the cost of responsiveness. Default: 1 seconds.
    TicksUntilCharacterSave = 1200, -- In ticks, by the Player Tick Interval. Default: 1200 (10 minutes).
    ShouldNotifyOnCharacterSave = true,
    CharacterLoadDelay = 3, -- In seconds. 3 seconds recommended for smoother transitions. Could be shorter if preferred.

    LimboX = 18539,
    LimboY = 79,
    LimboZ = 0,

    SpawnX = 0,
    SpawnY = 0,
    SpawnZ = 0,

    DefaultMaxCharacters = 3,

    -- Lockpicking
    LockpickChance = 0.5,
    LockpickCooldown = 60,
    LockpickMaxDistance = 2,

    -- Pickpocketing
    PickPocketChance = 0.5,
    PickPocketCooldown = 60,
    PickPocketMaxDistance = 2,

    -- Factions
    Factions = {
        FACTION_CITIZEN = {
            limit = 0
        }
    }
}

function FrameworkZ.Config:GetOption(optionName)
    return self.Options[optionName]
end

function FrameworkZ.Config:SetOption(optionName, value)
    self.Options[optionName] = value
end

FrameworkZ.Config = FrameworkZ:CreateObject(FrameworkZ.Config, "Config")

function FrameworkZ:LoadAndLockObject(object)
    --local object = internalObjects[name]

    if not object then
        error("Object is not registered or is already loaded.")
    end

    if not object.Meta or not object.Meta.Name then
        error("Invalid object passed to LockAndLoadObject.")
    end

    if object.__locked then
        error("Object '" .. object.Meta.Name .. "' is already locked.")
    end

    local name = object.Meta.Name
    local depth = name == "FrameworkZ" and 0 or -1

    --[[object = wrapFunctionsWithValidation(depth, object, object)

    if not object then
        error("Failed to wrap functions for object: " .. name)
    end--]]



    local proxy, message = self:LoadObject(object)

    if not proxy then
        error("Failed to load object: " .. message)
    end

    proxy.__hash = hashObject(depth, proxy)
    proxy.__hashDepth = depth
    proxy.__locked = true

    local mt = {
        __index = function(tbl, key)
            local currentHash = hashObject(proxy.__hashDepth, proxy)

            if proxy.__hash ~= currentHash then
                FrameworkZ.Notifications:AddToQueue("Tampering Detected: Object integrity check failed. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)

                error("Tampering Detected: Object integrity check failed. This has been logged.")
                return nil
            end

            return rawget(proxy, key)
        end,
        __newindex = function(tbl, key, value)
            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Tampering Attempt: Cannot override object after locking. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)
            end

            error("Tampering Attempt: Cannot override object after locking. This has been logged.")
        end,
        --[[__call = function(tbl, ...)
            local currentHash = hashObject(proxy.__hashDepth, proxy)

            if proxy.__hash ~= currentHash then
                FrameworkZ.Notifications:AddToQueue("Tampering Detected: Object integrity check failed. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)

                error("Tampering Detected: Object integrity check failed. This has been logged.")
                return print("Denied")
            end

            return tbl(...)
        end,--]]
        __pairs = function() return pairs(proxy) end,
        __ipairs = function() return ipairs(proxy) end,
        __len = function() return #proxy end,
        __metatable = false
    }

    local lockedObject = setmetatable({}, mt)
    lockedObjects[name] = lockedObject
    internalObjects[name] = nil

    return lockedObject
end

function FrameworkZ:LoadObject(object)
    --local object = internalObjects[objectName]

    if object then
        local copy = FrameworkZ.Utilities:CopyTable(object)

        if copy.InitializeObject then
            copy:InitializeObject()
        end

        return copy, "Object '" .. object.Meta.Name .. "' loaded successfully."
    end

    return false, "Object '" .. object.Meta.Name .. "' is not registered or is already loaded."
end

function FrameworkZ:UnloadObject(objectName)
    if not self.__allowUnload then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Warning: Unload attempt blocked for '" .. objectName .. "'. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)
        end

        return false
    end

    internalObjects[objectName] = nil

    return true
end

function FrameworkZ:RegisterObject(object)
    if self.__finalized == true then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Alert: Attempted to register object after finalization. This has been logged.", FrameworkZ.Notifications.Types.Warning, 60)
        end

        error("Security Alert: Attempted to register object after finalization. This has been logged.")
        return
    end

    if not object.Meta or not object.Meta.Name then
        print("Plugin missing metadata or name.")
        return false
    end

    if object.__locked then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Alert: Attempted to re-register locked object '" .. object.Meta.Name .. "'. This has been logged.", FrameworkZ.Notifications.Types.Warning, 60)
        end

        error("Security Alert: Attempted to re-register locked object '" .. object.Meta.Name .. "'. This has been logged.")
        return
    end

    local name = object.Meta.Name

    internalObjects[name] = object

    return object
end

function FrameworkZ:GetObject(objectName)
    return lockedObjects[objectName]
end

function FrameworkZ:InitializeObject()
    if self.__initialized then return end
    self.__initialized = true
    self.Foundation.Initialize(self.Foundation)
    self.__finalized = true
end
