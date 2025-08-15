local internalObjects = {}

--! \module FrameworkZ.Security
FrameworkZ.Security = {}
FrameworkZ.Security.__index = FrameworkZ.Security
FrameworkZ.Security.__internalObjects = internalObjects
FrameworkZ.Security.RegisteredObjects = {}
FrameworkZ.Security.LoadedObjects = {}
FrameworkZ.Security = FrameworkZ.Foundation:NewModule(FrameworkZ.Security, "Security")

local function createSecureFunction(originalFunction, object)
    return setmetatable({}, {
        __call = function(_, ...)
            if not object.__valid(object) then
                FrameworkZ.Notifications:AddToQueue("Tampering Detected: Object integrity check failed. This has been logged.", FrameworkZ.Notifications.Types.Danger)
                return false
            end
            return originalFunction(...)
        end,
        __metatable = false
    })
end

local function wrapFunctionsWithValidation(tbl, object, visited)
    visited = visited or {}
    if visited[tbl] then return end
    visited[tbl] = true

    for k, v in pairs(tbl) do
        if type(v) == "function" and not k:match("^_") then
            tbl[k] = createSecureFunction(v, object)
        elseif type(v) == "table" and not k:match("^_") and not v.__skipWrap then
            wrapFunctionsWithValidation(v, object, visited)
        end
    end
end

local function hashObject(object)
    local components = {}

    local function collect(tbl, prefix)
        for k, v in pairs(tbl) do
            local keyPath = prefix .. "." .. k
            if type(v) == "function" and not k:match("^_") then
                table.insert(components, keyPath .. ":" .. tostring(v))
            elseif type(v) == "table" and not k:match("^_") and not v.__skipWrap then
                collect(v, keyPath)
            end
        end
    end

    collect(object, object.Meta and object.Meta.Name or "object")
    table.sort(components)

    return table.concat(components, "|")
end

FrameworkZ.Security.BaseObject = {
    __valid = function(object)
        local currentHash = hashObject(object)
        return object.__hash == currentHash
    end,

    __index = function(tbl, key)
        return rawget(FrameworkZ.Security.BaseObject, key)
    end
}

function FrameworkZ.Security:CreateObject(name)
    local object = setmetatable({}, self.BaseObject)

    object.Meta = {
        Author = "N/A",
        Name = name,
        Description = "No description set.",
        Version = "1.0.0",
        Compatibility = ""
    }

    object.__valid = self.BaseObject.__valid
    object.__locked = false

    internalObjects[name] = object

    return object
end

function FrameworkZ.Security:LockAndLoadObject(object)
    if not object or not object.Meta or not object.Meta.Name then
        error("Invalid object passed to LockAndLoadObject.")
    end

    if object.__locked then
        error("Object '" .. object.Meta.Name .. "' is already locked.")
    end

    local name = object.Meta.Name

    wrapFunctionsWithValidation(object, object)
    object.__hash = hashObject(object)
    object.__locked = true

    local proxy = {}
    local mt = {
        __index = object,
        __newindex = function(t, key, value)
            if isClient() then
                FrameworkZ.Notifications:AddToQueue("Tampering Attempt: Cannot override plugin after locking. This has been logged.", FrameworkZ.Notifications.Types.Danger, 60)
            end
        end,
        __pairs = function() return pairs(object) end,
        __ipairs = function() return ipairs(object) end,
        __len = function() return #object end,
        __metatable = false
    }

    local lockedObject = setmetatable(proxy, mt)
    local loadedObject, message = self:LoadLockedObject(name, lockedObject)

    if not loadedObject then
        error("Failed to load locked object: " .. message)
    end

    return loadedObject
end

function FrameworkZ.Security:LoadLockedObject(objectName, lockedObject)
    local object = self.RegisteredObjects[objectName]

    if object and not self.LoadedObjects[objectName] then
        self.RegisteredObjects[objectName] = lockedObject
        internalObjects[objectName] = nil

        if object.Initialize then
            object:Initialize()
        end

        self.LoadedObjects[objectName] = lockedObject

        return self.LoadedObjects[objectName], "Object '" .. objectName .. "' loaded successfully."
    end

    return false, "Object '" .. objectName .. "' is not registered or is already loaded."
end

function FrameworkZ.Security:UnloadObject(objectName)
    if not self.__allowUnload then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Warning: Unload attempt blocked for '" .. objectName .. "'. This has been logged.", FrameworkZ.Notifications.Types.Danger)
        end

        return false
    end

    self.RegisteredObjects[objectName] = nil
    self.LoadedObjects[objectName] = nil
    internalObjects[objectName] = nil

    return true
end

function FrameworkZ.Security:RegisterObject(object)
    if not object.Meta or not object.Meta.Name then
        print("Plugin missing metadata or name.")

        return false
    end

    if object.__locked then
        if isClient() then
            FrameworkZ.Notifications:AddToQueue("Security Alert: Attempted to re-register locked plugin '" .. object.Meta.Name .. "'. This has been logged.", FrameworkZ.Notifications.Types.Warning, 60)
        end

        return false
    end

    local name = object.Meta.Name
    internalObjects[name] = object
end

function FrameworkZ.Security:GetAllObjectss()
    local hasRegisteredObject = false

    for k, v in pairs(self.RegisteredPlugins) do
        if v then
            hasRegisteredObject = true
            break
        end
    end

    return hasRegisteredObject and self.RegisteredObjects or internalObjects
end

function FrameworkZ.Security:GetObject(objectName)
    return self.RegisteredObjects[objectName] or internalObjects[objectName]
end

function FrameworkZ.Security:GetLoadedObject(objectName)
    return self.LoadedObjects[objectName]
end

--FrameworkZ.Foundation:RegisterModule(FrameworkZ.Security)
