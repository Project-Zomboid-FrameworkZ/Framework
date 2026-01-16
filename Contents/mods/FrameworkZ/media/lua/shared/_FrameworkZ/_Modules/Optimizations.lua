FrameworkZ = FrameworkZ or {}

--! \brief Optimizations module for FrameworkZ. Provides various performance enhancements.
--! \module FrameworkZ.Optimizations
FrameworkZ.Optimizations = {}

FrameworkZ.Optimizations = FrameworkZ.Foundation:NewModule(FrameworkZ.Optimizations, "Optimizations")

-- Configuration
FrameworkZ.Optimizations.Config = {
    -- Player synchronization settings
    SyncInterval = 100,              -- Ticks between sync updates (100 ticks = ~1 second)
    PositionSyncThreshold = 2.0,     -- Minimum distance moved before forcing position sync
    
    -- Bandwidth optimization
    EnableDeltaSync = true,          -- Only send changed data
    EnableCompression = true,        -- Compress large data packets
    MaxPacketSize = 1024,            -- Maximum packet size in bytes
    
    -- Performance settings
    EnableBatching = true,           -- Batch multiple updates together
    BatchInterval = 50,              -- Ticks between batch sends
    MaxBatchSize = 10,               -- Maximum updates per batch
    
    -- Desync prevention
    EnableHashValidation = true,     -- Validate data integrity
    ResyncInterval = 6000,           -- Force full resync every 60 seconds
    EnablePrediction = true,         -- Client-side prediction for smoother movement
    PredictionSmoothingFactor = 0.3, -- Interpolation factor for prediction (0-1)
    
    -- Debug settings
    LogSyncErrors = false,
    LogBandwidthUsage = false,
    EnableMetrics = false
}

-- Sync queues and tracking
FrameworkZ.Optimizations.SyncQueue = {}
FrameworkZ.Optimizations.LastSync = {}
FrameworkZ.Optimizations.DirtyFlags = {}
FrameworkZ.Optimizations.Metrics = {
    packetsSent = 0,
    packetsReceived = 0,
    bytesSent = 0,
    bytesReceived = 0,
    syncErrors = 0,
    resyncs = 0
}

-- Player data cache for delta comparison
FrameworkZ.Optimizations.PlayerCache = {}

-- Client prediction cache
FrameworkZ.Optimizations.PredictionCache = {}

-- Module state tracking
FrameworkZ.Optimizations.IsInitialized = false
FrameworkZ.Optimizations.TickHandlers = {}

--! \brief Initialize the optimizations module
function FrameworkZ.Optimizations:Initialize()
    if self.IsInitialized then
        print("[FrameworkZ] Optimizations already initialized")
        return
    end
    
    if isClient() then
        self:InitializeClient()
    end
    
    if isServer() then
        self:InitializeServer()
    end
    
    -- Start sync loop
    self.TickHandlers.OnTick = function()
        self:OnTick()
    end
    Events.OnTick.Add(self.TickHandlers.OnTick)
    
    -- Hook into player events
    self.TickHandlers.OnPlayerUpdate = function(player)
        self:OnPlayerUpdate(player)
    end
    Events.OnPlayerUpdate.Add(self.TickHandlers.OnPlayerUpdate)
    
    self.TickHandlers.OnPlayerMove = function(player)
        self:OnPlayerMove(player)
    end
    Events.OnPlayerMove.Add(self.TickHandlers.OnPlayerMove)
    
    self.IsInitialized = true
    print("[FrameworkZ] Optimizations module initialized")
end

--! \brief Initialize client-side optimizations
function FrameworkZ.Optimizations:InitializeClient()
    -- Set up client prediction
    if self.Config.EnablePrediction then
        self:EnableClientPrediction()
    end
    
    -- Listen for server sync updates
    Events.OnServerCommand.Add(function(module, command, args)
        if module == "FZ_SYNC" then
            self:HandleServerSync(command, args)
        end
    end)
end

--! \brief Initialize server-side optimizations
function FrameworkZ.Optimizations:InitializeServer()
    -- Set up periodic full resyncs
    if self.Config.ResyncInterval > 0 then
        self.lastFullResync = 0
    end
    
    -- Listen for client sync requests
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == "FZ_SYNC" then
            self:HandleClientSync(command, player, args)
        end
    end)
end

--! \brief Main tick update loop
function FrameworkZ.Optimizations:OnTick()
    if not isServer() then return end
    
    local currentTick = getTimestamp()
    
    -- Process batch queue
    if self.Config.EnableBatching and currentTick % self.Config.BatchInterval == 0 then
        self:ProcessBatchQueue()
    end
    
    -- Full resync check
    if self.Config.ResyncInterval > 0 and 
       currentTick - (self.lastFullResync or 0) >= self.Config.ResyncInterval then
        self:PerformFullResync()
        self.lastFullResync = currentTick
    end
    
    -- Update metrics
    if self.Config.EnableMetrics and currentTick % 600 == 0 then
        self:UpdateMetrics()
    end
end

--! \brief Handle player update events
function FrameworkZ.Optimizations:OnPlayerUpdate(player)
    if not isServer() then return end
    if not player then return end
    
    local username = player:getUsername()
    if not username then return end
    
    -- Mark player data as dirty for next sync
    self.DirtyFlags[username] = self.DirtyFlags[username] or {}
    self.DirtyFlags[username].stats = true
end

--! \brief Handle player movement events
function FrameworkZ.Optimizations:OnPlayerMove(player)
    if not isServer() then return end
    if not player then return end
    
    local username = player:getUsername()
    if not username then return end
    
    -- Check if movement threshold exceeded
    local lastPos = self.LastSync[username] and self.LastSync[username].position
    if lastPos then
        local dx = player:getX() - lastPos.x
        local dy = player:getY() - lastPos.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance >= self.Config.PositionSyncThreshold then
            self:QueuePositionSync(player)
        end
    else
        -- First movement, queue sync
        self:QueuePositionSync(player)
    end
end

--! \brief Queue a position sync for a player
function FrameworkZ.Optimizations:QueuePositionSync(player)
    if not player then return end
    
    local username = player:getUsername()
    local data = {
        type = "position",
        username = username,
        x = player:getX(),
        y = player:getY(),
        z = player:getZ(),
        direction = player:getDirectionAngle(),
        timestamp = getTimestamp()
    }
    
    if self.Config.EnableBatching then
        table.insert(self.SyncQueue, data)
    else
        self:SendSyncUpdate(data)
    end
    
    -- Update last sync cache
    self.LastSync[username] = self.LastSync[username] or {}
    self.LastSync[username].position = {x = data.x, y = data.y, z = data.z}
    self.LastSync[username].timestamp = data.timestamp
end

--! \brief Process the batch queue
function FrameworkZ.Optimizations:ProcessBatchQueue()
    if #self.SyncQueue == 0 then return end
    
    local batch = {}
    local batchSize = math.min(#self.SyncQueue, self.Config.MaxBatchSize)
    
    for i = 1, batchSize do
        table.insert(batch, table.remove(self.SyncQueue, 1))
    end
    
    -- Send batched updates
    if #batch > 0 then
        self:SendBatchUpdate(batch)
    end
end

--! \brief Send a batched update to clients
function FrameworkZ.Optimizations:SendBatchUpdate(batch)
    if not isServer() then return end
    if not batch or #batch == 0 then return end
    
    -- Compress if enabled
    local data = batch
    if self.Config.EnableCompression then
        data = self:CompressData(batch)
    end
    
    -- Send to all clients
    sendServerCommand("FZ_SYNC", "batch", data)
    
    -- Update metrics
    if self.Config.EnableMetrics then
        self.Metrics.packetsSent = self.Metrics.packetsSent + 1
        self.Metrics.bytesSent = self.Metrics.bytesSent + self:EstimateDataSize(data)
    end
end

--! \brief Send a single sync update
function FrameworkZ.Optimizations:SendSyncUpdate(data)
    if not isServer() then return end
    if not data then return end
    
    sendServerCommand("FZ_SYNC", data.type, data)
    
    -- Update metrics
    if self.Config.EnableMetrics then
        self.Metrics.packetsSent = self.Metrics.packetsSent + 1
        self.Metrics.bytesSent = self.Metrics.bytesSent + self:EstimateDataSize(data)
    end
end

--! \brief Handle sync updates from server (client-side)
function FrameworkZ.Optimizations:HandleServerSync(command, args)
    if not isClient() then return end
    
    if command == "batch" then
        -- Process batch of updates
        for _, update in ipairs(args) do
            self:ApplySyncUpdate(update)
        end
    else
        -- Single update
        self:ApplySyncUpdate(args)
    end
    
    -- Update metrics
    if self.Config.EnableMetrics then
        self.Metrics.packetsReceived = self.Metrics.packetsReceived + 1
        self.Metrics.bytesReceived = self.Metrics.bytesReceived + self:EstimateDataSize(args)
    end
end

--! \brief Apply a sync update (client-side)
function FrameworkZ.Optimizations:ApplySyncUpdate(update)
    if not update or not update.type then return end
    
    if update.type == "position" then
        self:ApplyPositionUpdate(update)
    elseif update.type == "stats" then
        self:ApplyStatsUpdate(update)
    elseif update.type == "fullsync" then
        self:ApplyFullSync(update)
    end
end

--! \brief Apply position update (client-side)
function FrameworkZ.Optimizations:ApplyPositionUpdate(update)
    local player = getPlayerFromUsername(update.username)
    if not player then return end
    
    -- Validate position to prevent desync
    if self.Config.EnableHashValidation then
        local currentPos = {x = player:getX(), y = player:getY(), z = player:getZ()}
        local distance = self:CalculateDistance(currentPos, update)
        
        -- If position difference is too large, it might be a desync
        if distance > 50 then
            if self.Config.LogSyncErrors then
                print("[FrameworkZ] Large position desync detected for " .. update.username)
            end
            self.Metrics.syncErrors = self.Metrics.syncErrors + 1
            -- Request full resync
            self:RequestFullResync(update.username)
            return
        end
    end
    
    -- Apply position with interpolation for smooth movement
    if self.Config.EnablePrediction then
        self:InterpolatePosition(player, update)
    else
        player:setX(update.x)
        player:setY(update.y)
        player:setZ(update.z)
        player:setDirectionAngle(update.direction)
    end
end

--! \brief Apply stats update (client-side)
function FrameworkZ.Optimizations:ApplyStatsUpdate(update)
    local player = getPlayerFromUsername(update.username)
    if not player or not update.stats then return end
    
    -- Apply stats changes
    if update.stats.health then
        player:setHealth(update.stats.health)
    end
    if update.stats.hunger and player:getNutrition() then
        player:getNutrition():setHunger(update.stats.hunger)
    end
    if update.stats.thirst and player:getNutrition() then
        player:getNutrition():setThirst(update.stats.thirst)
    end
    if update.stats.fatigue then
        player:setFatigue(update.stats.fatigue)
    end
end

--! \brief Apply full sync update (client-side)
function FrameworkZ.Optimizations:ApplyFullSync(update)
    -- Apply position
    if update.position then
        self:ApplyPositionUpdate({
            username = update.username,
            x = update.position.x,
            y = update.position.y,
            z = update.position.z,
            direction = update.position.direction,
            timestamp = update.timestamp,
            type = "position"
        })
    end
    
    -- Apply stats
    if update.stats then
        self:ApplyStatsUpdate({
            username = update.username,
            stats = update.stats,
            timestamp = update.timestamp,
            type = "stats"
        })
    end
end

--! \brief Perform a full resync of all players
function FrameworkZ.Optimizations:PerformFullResync()
    if not isServer() then return end
    
    local players = getOnlinePlayers()
    if not players then return end
    
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            self:SendFullPlayerSync(player)
        end
    end
    
    if self.Config.EnableMetrics then
        self.Metrics.resyncs = self.Metrics.resyncs + 1
    end
end

--! \brief Send full player sync data
function FrameworkZ.Optimizations:SendFullPlayerSync(player)
    if not player then return end
    
    local username = player:getUsername()
    local data = {
        type = "fullsync",
        username = username,
        position = {
            x = player:getX(),
            y = player:getY(),
            z = player:getZ(),
            direction = player:getDirectionAngle()
        },
        stats = {
            health = player:getHealth(),
            hunger = player:getNutrition():getHunger(),
            thirst = player:getNutrition():getThirst(),
            fatigue = player:getFatigue()
        },
        timestamp = getTimestamp()
    }
    
    sendServerCommand("FZ_SYNC", "fullsync", data)
end

--! \brief Request a full resync from server (client-side)
function FrameworkZ.Optimizations:RequestFullResync(username)
    if not isClient() then return end
    
    sendClientCommand("FZ_SYNC", "request_resync", {username = username})
end

--! \brief Handle client sync requests (server-side)
function FrameworkZ.Optimizations:HandleClientSync(command, player, args)
    if not isServer() then return end
    
    if command == "request_resync" then
        -- Client requested full resync
        local targetPlayer = getPlayerFromUsername(args.username)
        if targetPlayer then
            self:SendFullPlayerSync(targetPlayer)
        end
    end
end

--! \brief Enable client-side prediction
function FrameworkZ.Optimizations:EnableClientPrediction()
    -- Client prediction helps smooth out movement between server updates
    -- Initialize prediction cache for all players
    print("[FrameworkZ] Client-side prediction enabled")
end

--! \brief Interpolate position for smooth movement
function FrameworkZ.Optimizations:InterpolatePosition(player, update)
    if not player then return end
    
    local username = update.username
    local currentX = player:getX()
    local currentY = player:getY()
    local currentZ = player:getZ()
    
    -- Get smoothing factor
    local smoothing = self.Config.PredictionSmoothingFactor
    
    -- Calculate interpolated position
    local newX = currentX + (update.x - currentX) * smoothing
    local newY = currentY + (update.y - currentY) * smoothing
    local newZ = currentZ + (update.z - currentZ) * smoothing
    
    -- Apply interpolated position
    player:setX(newX)
    player:setY(newY)
    player:setZ(newZ)
    player:setDirectionAngle(update.direction)
    
    -- Cache predicted position for validation
    self.PredictionCache[username] = {
        x = newX,
        y = newY,
        z = newZ,
        targetX = update.x,
        targetY = update.y,
        targetZ = update.z,
        timestamp = getTimestamp()
    }
end

--! \brief Calculate distance between two positions
function FrameworkZ.Optimizations:CalculateDistance(pos1, pos2)
    local dx = (pos1.x or 0) - (pos2.x or 0)
    local dy = (pos1.y or 0) - (pos2.y or 0)
    local dz = (pos1.z or 0) - (pos2.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--! \brief Compress data for transmission
function FrameworkZ.Optimizations:CompressData(data)
    if not self.Config.EnableCompression then
        return data
    end
    
    -- Recursively remove nil values and compact tables
    local function compress(t)
        if type(t) ~= "table" then
            return t
        end
        
        local compressed = {}
        for k, v in pairs(t) do
            if v ~= nil then
                if type(v) == "table" then
                    compressed[k] = compress(v)
                else
                    compressed[k] = v
                end
            end
        end
        return compressed
    end
    
    local compressed = compress(data)
    
    -- Round float values to reduce precision (saves bytes)
    local function roundFloats(t)
        if type(t) ~= "table" then
            if type(t) == "number" then
                return math.floor(t * 100 + 0.5) / 100  -- Round to 2 decimal places
            end
            return t
        end
        
        for k, v in pairs(t) do
            t[k] = roundFloats(v)
        end
        return t
    end
    
    return roundFloats(compressed)
end

--! \brief Estimate size of data in bytes
function FrameworkZ.Optimizations:EstimateDataSize(data)
    -- Rough estimate based on string representation
    local str = tostring(data)
    return #str
end

--! \brief Update and log metrics
function FrameworkZ.Optimizations:UpdateMetrics()
    if not self.Config.EnableMetrics then return end
    
    if self.Config.LogBandwidthUsage then
        print(string.format("[FrameworkZ Metrics] Packets: %d sent, %d received | Bytes: %d sent, %d received | Errors: %d | Resyncs: %d",
            self.Metrics.packetsSent,
            self.Metrics.packetsReceived,
            self.Metrics.bytesSent,
            self.Metrics.bytesReceived,
            self.Metrics.syncErrors,
            self.Metrics.resyncs
        ))
    end
end

--! \brief Get current metrics
function FrameworkZ.Optimizations:GetMetrics()
    return self.Metrics
end

--! \brief Reset metrics
function FrameworkZ.Optimizations:ResetMetrics()
    self.Metrics = {
        packetsSent = 0,
        packetsReceived = 0,
        bytesSent = 0,
        bytesReceived = 0,
        syncErrors = 0,
        resyncs = 0
    }
end

--! \brief Clean up old cache entries
function FrameworkZ.Optimizations:CleanupCache()
    local currentTime = getTimestamp()
    local timeout = 3600 -- 1 hour
    
    local cleanedCount = 0
    
    -- Clean player cache
    for username, cache in pairs(self.PlayerCache) do
        if cache.lastUpdate and currentTime - cache.lastUpdate > timeout then
            self.PlayerCache[username] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Clean last sync data
    for username, sync in pairs(self.LastSync) do
        if sync.timestamp and currentTime - sync.timestamp > timeout then
            self.LastSync[username] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Clean prediction cache
    for username, pred in pairs(self.PredictionCache) do
        if pred.timestamp and currentTime - pred.timestamp > timeout then
            self.PredictionCache[username] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print(string.format("[FrameworkZ] Cleaned %d stale cache entries", cleanedCount))
    end
end

--! \brief Update cache timestamp
function FrameworkZ.Optimizations:UpdateCacheTimestamp(username)
    local currentTime = getTimestamp()
    
    if self.PlayerCache[username] then
        self.PlayerCache[username].lastUpdate = currentTime
    end
end

--! \brief Shutdown the optimizations module
function FrameworkZ.Optimizations:Shutdown()
    if not self.IsInitialized then
        return
    end
    
    -- Remove event handlers
    if self.TickHandlers.OnTick then
        Events.OnTick.Remove(self.TickHandlers.OnTick)
    end
    if self.TickHandlers.OnPlayerUpdate then
        Events.OnPlayerUpdate.Remove(self.TickHandlers.OnPlayerUpdate)
    end
    if self.TickHandlers.OnPlayerMove then
        Events.OnPlayerMove.Remove(self.TickHandlers.OnPlayerMove)
    end
    
    -- Clear caches
    self.SyncQueue = {}
    self.LastSync = {}
    self.DirtyFlags = {}
    self.PlayerCache = {}
    self.PredictionCache = {}
    
    self.IsInitialized = false
    print("[FrameworkZ] Optimizations module shutdown")
end

-- Cleanup task
Events.EveryHours.Add(function()
    FrameworkZ.Optimizations:CleanupCache()
end)

