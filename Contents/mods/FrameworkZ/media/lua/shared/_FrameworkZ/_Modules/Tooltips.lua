-- TODO also display character info variables (approx. age, height, weight, etc.) alongside physical description

local Events = Events
local getAverageFPS = getAverageFPS
local getCell = getCell
local getMouseX = getMouseX
local getMouseY = getMouseY
local getSpecificPlayer = getSpecificPlayer
local getSquare = getSquare
local getTexture = getTexture
local getTextManager = getTextManager
local getTimestampMs = getTimestampMs
local instanceof = instanceof
local isClient = isClient
local IsoDirections = IsoDirections
local isoToScreenX = isoToScreenX
local isoToScreenY = isoToScreenY
local screenToIsoX = screenToIsoX
local screenToIsoY = screenToIsoY

FrameworkZ = FrameworkZ or {}

FrameworkZ.Tooltips = {}

FrameworkZ.Tooltips.HoveredCharacterData = {
    UI = nil,
    Texture = getTexture("media/textures/fz-selector.png"),
    TextureScale = 1.0,
    TextureAlpha = 0.8,
    TextureYOffset = 0.25,
    TooltipShowing = false,
    TooltipPlayer = nil,
    TooltipCharacterName = "",
    TooltipCharacterFaction = "",
    TooltipCharacterDescription = "",
    TooltipCharacterDescriptionLines = {},
    TooltipCharacterNameColor = {r = 1, g = 1, b = 1, a = 1},
    TooltipStickiness = 1.5, -- Multiplier advantage for tracking current tooltip player
    TooltipSwitchThreshold = 0.3, -- Minimum score difference needed to switch to new character
    TooltipRequestSent = false,
    TooltipDataLoaded = false,
    TooltipLastRequestedTarget = nil,
    TypewriterNameProgress = 0,
    TypewriterDescriptionProgress = {},
    TypewriterLastUpdateTime = 0,
    TypewriterStartDelay = 2.5, -- Delay in seconds before typewriter effect starts (increased for more contemplative pacing)
    TypewriterDelayStartTime = 0, -- When the delay period started
    TypewriterBaseSpeed = 8, -- Scaling multiplier for how much the conditions will impact revealing text (increased for slower base speed)
    TypewriterCurrentSpeed = 0.05,
    TypewriterCharactersPerSecond = 6, -- Base line target of characters per second to reveal (decreased for more deliberate pacing)
    -- Cache fields for performance
    _cachedDirectionVectors = {},
    _cachedScreenPositions = {},
    _lastScreenCacheTime = 0,
    _lastTypewriterSpeedTime = 0,
    _lastCacheCleanupTime = 0,
    _cacheInterval = 16, -- Cache for 16ms (~60fps) for more responsive updates
}

FrameworkZ.Tooltips = FrameworkZ.Foundation:NewModule(FrameworkZ.Tooltips, "Tooltips")

-- Get normalized direction vector for a given IsoDirection (with caching)
function FrameworkZ.Tooltips:GetDirectionVector(isoDirection)
    -- Check cache first
    local cached = self.HoveredCharacterData._cachedDirectionVectors[isoDirection]
    if cached then
        return cached.x, cached.y
    end
    
    local dirX, dirY = 0, 0
    
    if isoDirection == IsoDirections.N then
        dirX, dirY = 0, -1      -- North: up
    elseif isoDirection == IsoDirections.NE then
        dirX, dirY = 0.7071, -0.7071      -- Northeast: up-right (pre-normalized)
    elseif isoDirection == IsoDirections.E then
        dirX, dirY = 1, 0       -- East: right
    elseif isoDirection == IsoDirections.SE then
        dirX, dirY = 0.7071, 0.7071       -- Southeast: down-right (pre-normalized)
    elseif isoDirection == IsoDirections.S then
        dirX, dirY = 0, 1       -- South: down
    elseif isoDirection == IsoDirections.SW then
        dirX, dirY = -0.7071, 0.7071      -- Southwest: down-left (pre-normalized)
    elseif isoDirection == IsoDirections.W then
        dirX, dirY = -1, 0      -- West: left
    elseif isoDirection == IsoDirections.NW then
        dirX, dirY = -0.7071, -0.7071     -- Northwest: up-left (pre-normalized)
    else
        return nil, nil -- Unknown direction
    end
    
    -- Cache the result
    self.HoveredCharacterData._cachedDirectionVectors[isoDirection] = {x = dirX, y = dirY}
    
    return dirX, dirY
end

    -- Fast angle calculation using pre-computed lookup
local ANGLE_LOOKUP = {}
for i = 0, 7 do
    local angle = i * math.pi / 4
    ANGLE_LOOKUP[i] = {cos = math.cos(angle), sin = math.sin(angle)}
end

-- Pre-computed angle constants for performance optimization
local ANGLE_CONSTANTS = {
    PI_6 = 0.5236,   -- math.pi / 6 (30 degrees)
    PI_4 = 0.7854,   -- math.pi / 4 (45 degrees)  
    PI_3 = 1.0472,   -- math.pi / 3 (60 degrees)
    PI_2 = 1.5708,   -- math.pi / 2 (90 degrees)
    PI_1_5 = 2.0944  -- math.pi / 1.5 (120 degrees)
}

-- Utility functions for common operations to reduce code duplication
local Utils = {
    -- Get grid coordinates from player position
    getPlayerGridCoords = function(player)
        return math.floor(player:getX()), math.floor(player:getY()), player:getZ()
    end,
    
    -- Calculate cache key for screen positions
    getScreenPositionCacheKey = function(playerId, x, y, z)
        return playerId .. "_" .. math.floor(x * 10) .. "_" .. math.floor(y * 10) .. "_" .. z
    end,
    
    -- Get adjacent square based on direction
    getAdjacentSquare = function(cell, baseX, baseY, z, dx, dy)
        return cell:getGridSquare(baseX + dx, baseY + dy, z)
    end,
    
    -- Calculate squared distance between two points
    getDistanceSquared = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return dx * dx + dy * dy
    end,
    
    -- Find best candidate from candidates array (optimized loop)
    findBestCandidate = function(candidates)
        local bestCandidate = nil
        local bestScore = 0
        for i = 1, #candidates do
            local candidate = candidates[i]
            if candidate.score > bestScore then
                bestCandidate = candidate.player
                bestScore = candidate.score
            end
        end
        return bestCandidate, bestScore
    end,
    
    -- Check if current player is still valid in candidates list
    checkPlayerValidity = function(candidates, targetPlayer)
        for i = 1, #candidates do
            if candidates[i].player == targetPlayer then
                return true, candidates[i].score
            end
        end
        return false, 0
    end
}

-- Check if a door has a window based on properties or sprite name
function FrameworkZ.Tooltips:DoorHasWindow(door)
    if not door then
        return false
    end
    
    -- Method 1: Check properties for HasWindow or similar
    local properties = door:getProperties()
    if properties then

        -- Check for common property names that might indicate a window using Is() method
        if properties:Is("doorTrans") then
            return true
        end
    end
    
    return false
end

-- Centralized function to check if a wall/door/window combination allows passage
-- This eliminates massive code duplication across directional checks
function FrameworkZ.Tooltips:CheckWallPassage(door, window, wall, restrictive)
    -- Check for door opening first (prioritize openings)
    if door and door:IsOpen() then
        return true -- Open door allows passage
    elseif door and not door:IsOpen() then
        -- Closed door - but check if it has a window we can see through
        if self:DoorHasWindow(door) then
            -- Door has a built-in window - check if there's also a separate window object for curtains
            if window then
                -- Both door with window AND separate window object - check curtain state
                if restrictive then
                    local curtain = window:HasCurtains()
                    if curtain and not curtain:IsOpen() then
                        return false -- Door with window but closed curtains blocks
                    else
                        return true -- Door with window and open/no curtains allows passage
                    end
                else
                    return true -- In permissive mode, door windows don't block regardless of curtains
                end
            else
                -- Door has window but no separate window object (probably no curtains)
                return true -- Door with uncurtained window allows passage
            end
        elseif window then
            -- Closed solid door but separate window - check curtain state  
            if restrictive then
                local curtain = window:HasCurtains()
                if curtain and not curtain:IsOpen() then
                    return false -- Separate window with closed curtains blocks
                else
                    return true -- Separate window with open/no curtains allows passage
                end
            else
                return true -- In permissive mode, windows don't block regardless of curtains
            end
        else
            return false -- Closed solid door without window blocks
        end
    elseif window then
        -- Window without door - check for window opening
        if restrictive then
            local curtain = window:HasCurtains()
            if curtain and not curtain:IsOpen() then
                return false -- Window with closed curtains blocks in restrictive mode
            else
                return true -- Window with open/no curtains allows passage in restrictive mode
            end
        else
            return true -- In permissive mode, windows don't block regardless of curtains
        end
    elseif wall then
        return false -- Wall always blocks
    else
        return true -- No obstruction at all
    end
end

-- Calculate angle between player's facing direction and target position using dot product (optimized)
function FrameworkZ.Tooltips:CalculatePlayerTargetAngle(player, targetX, targetY)
if not player then
    return math.pi -- Return max angle if no player
end

local playerDir = player:getDir()
local playerX = player:getX()
local playerY = player:getY()

-- Get normalized direction vector
local dirX, dirY = self:GetDirectionVector(playerDir)
if not dirX then
    return math.pi -- Unknown direction, return max angle
end

-- Vector from player to target
local toTargetX = targetX - playerX
local toTargetY = targetY - playerY
local toTargetLengthSqr = toTargetX * toTargetX + toTargetY * toTargetY

if toTargetLengthSqr == 0 then
    return 0 -- Same position, no angle
end

-- Normalize target vector using fast inverse square root approximation for better performance
local toTargetLength = math.sqrt(toTargetLengthSqr)
toTargetX = toTargetX / toTargetLength
toTargetY = toTargetY / toTargetLength

-- Calculate dot product to get cosine of angle between vectors
local dotProduct = dirX * toTargetX + dirY * toTargetY

-- Calculate angle from dot product with clamping
local angle = math.acos(math.max(-1, math.min(1, dotProduct)))

return angle
end

-- Check if player is facing towards a target within field of view (optimized)
function FrameworkZ.Tooltips:IsPlayerFacingTarget(player, targetX, targetY, fieldOfViewAngle)
    if not player then
        return false
    end
    
    -- Calculate angle between player facing direction and target
    local angle = self:CalculatePlayerTargetAngle(player, targetX, targetY)
    
    if angle == math.pi then
        return false -- Invalid calculation or unknown direction
    end
    
    -- Check if within field of view using pre-computed constant
    return angle <= (fieldOfViewAngle or ANGLE_CONSTANTS.PI_1_5) -- 120° field of view
end

-- Check for obstructions in a square based on movement direction (centralized function)
function FrameworkZ.Tooltips:CheckSquareObstructions(square, stepX, stepY, isTargetSquare, restrictive)
    if not square then
        return false -- No square means no obstruction
    end
    
    local hasOpening = true -- Start by assuming there's an opening, then check if blocked
    local cell = getCell()
    
    -- Project Zomboid wall system:
    -- getWall(true) = North walls, getWall(false) = West walls
    -- South walls are on the square to the south (Y+1), East walls are on the square to the east (X+1)
    
    -- Check for north-side obstructions when moving south (stepY > 0)
    if stepY > 0 then
        local northDoor = square:getDoor(true)
        local northWindow = square:getWindow(true)
        local northWall = square:getWall(true)
        hasOpening = self:CheckWallPassage(northDoor, northWindow, northWall, restrictive)
    end
    
    -- Check for west-side obstructions when moving east (stepX > 0)
    if stepX > 0 and hasOpening then
        local westDoor = square:getDoor(false)
        local westWindow = square:getWindow(false)
        local westWall = square:getWall(false)
        hasOpening = self:CheckWallPassage(westDoor, westWindow, westWall, restrictive)
    end
    
    -- Check for south-side obstructions when moving north (stepY < 0)
    -- South walls are stored as north walls of the square below
    if stepY < 0 and hasOpening then
        local southSquare = cell:getGridSquare(square:getX(), square:getY() + 1, square:getZ())
        if southSquare then
            local southDoor = southSquare:getDoor(true)
            local southWindow = southSquare:getWindow(true)
            local southWall = southSquare:getWall(true)
            hasOpening = self:CheckWallPassage(southDoor, southWindow, southWall, restrictive)
        end
    end
    
    -- Check for east-side obstructions when moving west (stepX < 0)
    -- East walls are stored as west walls of the square to the right
    if stepX < 0 and hasOpening then
        local eastSquare = cell:getGridSquare(square:getX() + 1, square:getY(), square:getZ())
        if eastSquare then
            local eastDoor = eastSquare:getDoor(false)
            local eastWindow = eastSquare:getWindow(false)
            local eastWall = eastSquare:getWall(false)
            hasOpening = self:CheckWallPassage(eastDoor, eastWindow, eastWall, restrictive)
        end
    end
    
    return not hasOpening -- Return true if blocked (no opening found)
end

-- Check for valid openings between adjacent players (centralized function)
-- Check for valid openings between adjacent players (optimized with centralized logic)
function FrameworkZ.Tooltips:CheckAdjacentOpening(localSquare, targetSquare, dx, dy, restrictive)
    local cell = getCell()
    
    if dx == 1 and dy == 0 then
        -- Moving east: check west walls between squares
        -- Check west wall of target square
        if targetSquare then
            local door = targetSquare:getDoor(false)
            local window = targetSquare:getWindow(false)
            local wall = targetSquare:getWall(false)
            
            if self:CheckWallPassage(door, window, wall, restrictive) then
                return true
            end
        end
        
        -- Also check east wall of local square (west wall of square to the right)
        if localSquare then
            local localX, localY = localSquare:getX(), localSquare:getY()
            local eastSquare = cell:getGridSquare(localX + 1, localY, localSquare:getZ())
            if eastSquare then
                local door = eastSquare:getDoor(false)
                local window = eastSquare:getWindow(false)
                local wall = eastSquare:getWall(false)
                
                return self:CheckWallPassage(door, window, wall, restrictive)
            end
        end
        
    elseif dx == -1 and dy == 0 then
        -- Moving west: check west wall of local square
        if localSquare then
            local door = localSquare:getDoor(false)
            local window = localSquare:getWindow(false)
            local wall = localSquare:getWall(false)
            
            return self:CheckWallPassage(door, window, wall, restrictive)
        end
        
    elseif dx == 0 and dy == 1 then
        -- Moving south: check north walls between squares
        -- Check north wall of target square
        if targetSquare then
            local door = targetSquare:getDoor(true)
            local window = targetSquare:getWindow(true)
            local wall = targetSquare:getWall(true)
            
            if self:CheckWallPassage(door, window, wall, restrictive) then
                return true
            end
        end
        
        -- Also check south wall of local square (north wall of square below)
        if localSquare then
            local localX, localY = localSquare:getX(), localSquare:getY()
            local southSquare = cell:getGridSquare(localX, localY + 1, localSquare:getZ())
            if southSquare then
                local door = southSquare:getDoor(true)
                local window = southSquare:getWindow(true)
                local wall = southSquare:getWall(true)
                
                return self:CheckWallPassage(door, window, wall, restrictive)
            end
        end
        
    elseif dx == 0 and dy == -1 then
        -- Moving north: check north wall of local square
        if localSquare then
            local door = localSquare:getDoor(true)
            local window = localSquare:getWindow(true)
            local wall = localSquare:getWall(true)
            
            return self:CheckWallPassage(door, window, wall, restrictive)
        end
    end
    
    return false
end

-- split a long description string into ~30-char lines
function FrameworkZ.Tooltips:GetDescriptionLines(desc)
    local lines, line, len = {}, "", 0
    for word in string.gmatch(desc, "%S+") do
        local wlen = #word
        if len + wlen + 1 <= 30 then
            if len > 0 then
                line = line .. " "
                len = len + 1
            end
            line = line .. word
            len  = len + wlen
        else
            table.insert(lines, line)
            line, len = word, wlen
        end
    end
    table.insert(lines, line)
    return lines
end

-- calculate character selection score for weighted tracking (optimized)
function FrameworkZ.Tooltips:CalculateCharacterScore(localPlayer, targetPlayer, mouseX, mouseY)
    if not localPlayer or not targetPlayer then
        return 0
    end

    -- Get screen position of target player with optimized caching
    local targetId = targetPlayer:getPlayerNum()
    local currentTime = getTimestampMs()
    local px, py, pz = targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ()
    local cacheKey = Utils.getScreenPositionCacheKey(targetId, px, py, pz)
    
    local sx, sy
    if self.HoveredCharacterData._lastScreenCacheTime + self.HoveredCharacterData._cacheInterval > currentTime and
        self.HoveredCharacterData._cachedScreenPositions[cacheKey] then
        local cached = self.HoveredCharacterData._cachedScreenPositions[cacheKey]
        sx, sy = cached.x, cached.y
    else
        sx = isoToScreenX(targetId, px, py, pz)
        sy = isoToScreenY(targetId, px, py, pz)
        
        -- Cache the result with shorter lifetime for moving targets
        self.HoveredCharacterData._cachedScreenPositions[cacheKey] = {x = sx, y = sy}
        self.HoveredCharacterData._lastScreenCacheTime = currentTime
    end

    -- Distance from mouse cursor to character on screen (closer = higher score)
    local screenDx = sx - mouseX
    local screenDy = sy - mouseY
    local screenDistanceSqr = screenDx * screenDx + screenDy * screenDy
    local screenScore = math.max(0, 100 - math.sqrt(screenDistanceSqr) * 0.5)

    -- World distance factor (closer = higher score) using utility function
    local worldDistanceSqr = Utils.getDistanceSquared(px, py, localPlayer:getX(), localPlayer:getY())
    local worldScore = math.max(0, 50 - math.sqrt(worldDistanceSqr) * 10)

    -- Line of sight bonus (visible = higher score) - use centralized function
    local hasLineOfSight = self:HasLineOfSight(localPlayer, targetPlayer)
    local losScore = hasLineOfSight and 25 or 0

    -- Apply stickiness bonus if this is the currently tracked player
    local stickinessBonus = 0
    if self.HoveredCharacterData.TooltipPlayer == targetPlayer then
        stickinessBonus = (screenScore + worldScore + losScore) * (self.HoveredCharacterData.TooltipStickiness - 1.0)
    end

    return screenScore + worldScore + losScore + stickinessBonus
end

-- check line of sight between two players (optimized but more permissive)
-- Centralized line of sight calculation with configurable strictness
function FrameworkZ.Tooltips:CalculateLineOfSight(localPlayer, targetPlayer, restrictive, adjacentRange)
    if not localPlayer or not targetPlayer then
        return false
    end

    -- Check if both players are on the same Z level
    if localPlayer:getZ() ~= targetPlayer:getZ() then
        return false
    end

    -- Get starting and ending grid coordinates using utility function
    local x1, y1, z = Utils.getPlayerGridCoords(localPlayer)
    local x2, y2 = Utils.getPlayerGridCoords(targetPlayer)

    -- If players are close, handle adjacent checking
    local distanceSqr = Utils.getDistanceSquared(x1, y1, x2, y2)
    
    if distanceSqr <= (adjacentRange or 1) then
        -- Within adjacent range - use different logic
        if distanceSqr <= 1 and restrictive then
            -- Adjacent players with restrictive checking
            local cell = getCell()
            local localSquare = cell:getGridSquare(x1, y1, z)
            local targetSquare = cell:getGridSquare(x2, y2, z)
            
            -- Use centralized function to check for valid openings
            local dx = x2 - x1
            local dy = y2 - y1
            local hasOpening = self:CheckAdjacentOpening(localSquare, targetSquare, dx, dy, restrictive)
            
            return hasOpening
        else
            -- Close range, permissive or within range - assume line of sight
            return true
        end
    end

    -- Use Bresenham-like algorithm for longer distances
    local dx = x2 - x1
    local dy = y2 - y1
    local absDx = math.abs(dx)
    local absDy = math.abs(dy)
    local stepX = x1 < x2 and 1 or -1
    local stepY = y1 < y2 and 1 or -1
    local err = absDx - absDy
    
    local cell = getCell()
    local checkX = x1
    local checkY = y1
    
    while true do
        -- Check current square for obstructions using centralized function
        local checkSquare = cell:getGridSquare(checkX, checkY, z)
        local isTargetSquare = (checkX == x2 and checkY == y2)
        
        if self:CheckSquareObstructions(checkSquare, stepX, stepY, isTargetSquare, restrictive) then
            return false -- Blocked by obstruction
        end
        
        -- Check if we've reached the target
        if checkX == x2 and checkY == y2 then
            break
        end
        
        -- Move to next square using Bresenham algorithm
        local err2 = 2 * err
        if err2 > -absDy then
            err = err - absDy
            checkX = checkX + stepX
        end
        if err2 < absDx then
            err = err + absDx
            checkY = checkY + stepY
        end
    end

    return true
end

-- Strict line of sight check for tooltip visibility
function FrameworkZ.Tooltips:HasLineOfSight(localPlayer, targetPlayer)
    return self:CalculateLineOfSight(localPlayer, targetPlayer, true, 1)
end

-- More permissive line of sight check specifically for typewriter speed calculation
function FrameworkZ.Tooltips:HasLineOfSightForTypewriter(localPlayer, targetPlayer)
    return self:CalculateLineOfSight(localPlayer, targetPlayer, false, 9) -- Within 3 tiles, very generous
end

-- calculate typewriter speed based on distance, line of sight, and facing direction (slowed and more variable for immersive roleplay)
function FrameworkZ.Tooltips:CalculateTypewriterSpeed(localPlayer, targetPlayer)
    if not localPlayer or not targetPlayer then
        return self.HoveredCharacterData.TypewriterBaseSpeed * 2.5 -- Conservative fallback for measured pacing
    end

    -- Use utility function for distance calculation
    local distanceSqr = Utils.getDistanceSquared(localPlayer:getX(), localPlayer:getY(), targetPlayer:getX(), targetPlayer:getY())

    -- Start with slower, more contemplative base speed
    local finalSpeed = self.HoveredCharacterData.TypewriterBaseSpeed * 1.0

    -- Distance factor (much more variable and generally slower)
    local distanceMultiplier = 1.0
    if distanceSqr < 1.0 then -- < 1 tile - intimate range
        distanceMultiplier = 0.7 -- Still fairly quick for close interaction, but not instant
    elseif distanceSqr < 4.0 then -- < 2 tiles - conversation range  
        distanceMultiplier = 1.0 -- Normal speed for conversation distance
    elseif distanceSqr < 9.0 then -- < 3 tiles - observation range
        distanceMultiplier = 1.4 -- Slower for distant observation
    elseif distanceSqr < 16.0 then -- < 4 tiles - recognition range
        distanceMultiplier = 1.8 -- Much slower for distant recognition
    else
        distanceMultiplier = 2.5 -- Very slow for far targets
    end
    finalSpeed = finalSpeed * distanceMultiplier

    -- Line of sight check (significant impact for realism)
    local hasLineOfSight = self:HasLineOfSightForTypewriter(localPlayer, targetPlayer)
    if not hasLineOfSight then
        finalSpeed = finalSpeed * 3.5 -- Much slower without clear line of sight
    else
        finalSpeed = finalSpeed * 1.0 -- Normal speed with clear line of sight
    end

    -- Local player facing direction check (significant variability for immersion)
    local localAngleDiff = self:CalculatePlayerTargetAngle(localPlayer, targetPlayer:getX(), targetPlayer:getY())

    -- Local player facing factor (more dramatic differences for engagement)
    if localAngleDiff < ANGLE_CONSTANTS.PI_6 then
        finalSpeed = finalSpeed * 0.6 -- Faster when staring directly, but not instant
    elseif localAngleDiff < ANGLE_CONSTANTS.PI_4 then
        finalSpeed = finalSpeed * 0.8 -- Moderately fast when looking at target
    elseif localAngleDiff < ANGLE_CONSTANTS.PI_3 then
        finalSpeed = finalSpeed * 1.0 -- Normal speed when generally facing
    elseif localAngleDiff < ANGLE_CONSTANTS.PI_2 then
        finalSpeed = finalSpeed * 1.3 -- Slower when partially facing
    else
        finalSpeed = finalSpeed * 2.2 -- Much slower when not facing
    end

    -- Target player facing direction check (moderate but noticeable effect)
    local targetAngleDiff = self:CalculatePlayerTargetAngle(targetPlayer, localPlayer:getX(), localPlayer:getY())

    -- Target facing factor (creates natural interaction rhythms)
    if targetAngleDiff < ANGLE_CONSTANTS.PI_6 then
        finalSpeed = finalSpeed * 0.7 -- Faster when target stares back (mutual attention)
    elseif targetAngleDiff < ANGLE_CONSTANTS.PI_4 then
        finalSpeed = finalSpeed * 0.9 -- Slightly faster when target looks back
    elseif targetAngleDiff < ANGLE_CONSTANTS.PI_3 then
        finalSpeed = finalSpeed * 1.1 -- Slightly slower when target is somewhat attentive
    elseif targetAngleDiff < ANGLE_CONSTANTS.PI_2 then
        finalSpeed = finalSpeed * 1.3 -- Slower when target is partially facing
    else
        finalSpeed = finalSpeed * 1.7 -- Much slower when target isn't paying attention
    end

    -- Mutual attention bonus (rewarding but not overpowering)
    if localAngleDiff < ANGLE_CONSTANTS.PI_4 and targetAngleDiff < ANGLE_CONSTANTS.PI_4 then
        finalSpeed = finalSpeed * 0.5 -- Good bonus for mutual eye contact/attention
    elseif localAngleDiff < ANGLE_CONSTANTS.PI_3 and targetAngleDiff < ANGLE_CONSTANTS.PI_3 then
        finalSpeed = finalSpeed * 0.7 -- Moderate bonus for good mutual attention
    elseif localAngleDiff < ANGLE_CONSTANTS.PI_2 and targetAngleDiff < ANGLE_CONSTANTS.PI_2 then
        finalSpeed = finalSpeed * 0.9 -- Small bonus for casual mutual awareness
    end

    return finalSpeed
end

-- update typewriter progress (optimized)
function FrameworkZ.Tooltips:UpdateTypewriterProgress()
    local currentTime = getTimestampMs()

    -- Check if we're still in the delay period
    if (currentTime - self.HoveredCharacterData.TypewriterDelayStartTime) < (self.HoveredCharacterData.TypewriterStartDelay * 1000) then
        return -- Don't start typewriter effect yet
    end

    -- If this is the first update after delay, reset the timer
    if self.HoveredCharacterData.TypewriterLastUpdateTime <= self.HoveredCharacterData.TypewriterDelayStartTime then
        self.HoveredCharacterData.TypewriterLastUpdateTime = currentTime
        return -- Skip this frame to avoid large deltaTime
    end

    local deltaTime = (currentTime - self.HoveredCharacterData.TypewriterLastUpdateTime) * 0.001  -- convert to seconds

    -- Recalculate speed less frequently for better performance
    local mp = getSpecificPlayer(0)
    if mp and self.HoveredCharacterData.TooltipPlayer then
        -- Only recalculate every few frames (more responsive: 100ms instead of 200ms)
        if currentTime - self.HoveredCharacterData._lastTypewriterSpeedTime > 100 then -- Every 100ms for more dynamic updates
            self.HoveredCharacterData.TypewriterCurrentSpeed = FrameworkZ.Tooltips:CalculateTypewriterSpeed(mp, self.HoveredCharacterData.TooltipPlayer)
            self.HoveredCharacterData._lastTypewriterSpeedTime = currentTime
        end
    end

    -- Get current FPS and normalize speed
    local avgFPS = math.max(1, getAverageFPS())  -- prevent division by zero
    local fpsNormalizer = 60 / avgFPS

    -- Calculate frame-rate independent character reveal speed
    local baseCharsPerSecond = self.HoveredCharacterData.TypewriterCharactersPerSecond
    local adjustedCharsPerSecond = baseCharsPerSecond / (self.HoveredCharacterData.TypewriterCurrentSpeed / self.HoveredCharacterData.TypewriterBaseSpeed)
    local charactersToReveal = deltaTime * adjustedCharsPerSecond * fpsNormalizer

    if charactersToReveal >= 1.0 then
        local charsToAdd = math.floor(charactersToReveal)

        -- Update description progress first (observing appearance)
        local allDescriptionComplete = true
        local descLines = self.HoveredCharacterData.TooltipCharacterDescriptionLines
        for i = 1, #descLines do
            if charsToAdd <= 0 then break end

            local line = descLines[i]
            local lineLen = #line
            
            if not self.HoveredCharacterData.TypewriterDescriptionProgress[i] then
                self.HoveredCharacterData.TypewriterDescriptionProgress[i] = 0
            end

            -- Only start revealing description lines in order
            if i == 1 or (self.HoveredCharacterData.TypewriterDescriptionProgress[i-1] or 0) >= #descLines[i-1] then
                local currentProgress = self.HoveredCharacterData.TypewriterDescriptionProgress[i]
                if currentProgress < lineLen then
                    local lineCharsToAdd = math.min(charsToAdd, lineLen - currentProgress)
                    self.HoveredCharacterData.TypewriterDescriptionProgress[i] = currentProgress + lineCharsToAdd
                    charsToAdd = charsToAdd - lineCharsToAdd
                    allDescriptionComplete = false
                end
            else
                allDescriptionComplete = false
            end
        end

        -- Check if all description lines are complete
        if allDescriptionComplete then
            for i = 1, #descLines do
                local progress = self.HoveredCharacterData.TypewriterDescriptionProgress[i] or 0
                if progress < #descLines[i] then
                    allDescriptionComplete = false
                    break
                end
            end
        end

        -- Update name progress (only after description is complete)
        if allDescriptionComplete and charsToAdd > 0 then
            local nameLen = #self.HoveredCharacterData.TooltipCharacterName
            if self.HoveredCharacterData.TypewriterNameProgress < nameLen then
                local nameCharsToAdd = math.min(charsToAdd, nameLen - self.HoveredCharacterData.TypewriterNameProgress)
                self.HoveredCharacterData.TypewriterNameProgress = self.HoveredCharacterData.TypewriterNameProgress + nameCharsToAdd
            end
        end

        self.HoveredCharacterData.TypewriterLastUpdateTime = currentTime
    end
end

-- reset typewriter state for new character (optimized)
function FrameworkZ.Tooltips:ResetTypewriterState()
    self.HoveredCharacterData.TypewriterNameProgress = 0
    self.HoveredCharacterData.TypewriterDescriptionProgress = {}
    self.HoveredCharacterData.TypewriterDelayStartTime = getTimestampMs()  -- Start the delay timer
    self.HoveredCharacterData.TypewriterLastUpdateTime = getTimestampMs()
    -- Clear caches when resetting state
    self.HoveredCharacterData._cachedScreenPositions = {}
    self.HoveredCharacterData._lastScreenCacheTime = 0
    self.HoveredCharacterData._lastTypewriterSpeedTime = 0
end

-- draw the selector + text each UI frame (optimized)
function FrameworkZ.Tooltips.DrawTooltip()
    local tooltipData = FrameworkZ.Tooltips.HoveredCharacterData

    if not tooltipData.TooltipPlayer or not tooltipData.UI then return end

    -- Always recalculate screen position for smooth tracking of moving characters
    local player = tooltipData.TooltipPlayer
    local pidx = player:getPlayerNum()
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local sx = isoToScreenX(pidx, px, py, pz)
    local sy = isoToScreenY(pidx, px, py, pz)

    -- Always draw selector ring immediately
    local texture = tooltipData.Texture
    local w, h = texture:getWidth(), texture:getHeight()
    local scale = tooltipData.TextureScale
    local sw, sh = w * scale, h * scale
    tooltipData.UI:drawTextureScaled(
        texture,
        sx - sw * 0.5,
        sy - sh * 0.5 + (h * scale * tooltipData.TextureYOffset),
        sw, sh,
        tooltipData.TextureAlpha
    )

    -- Check if delay period has passed before showing text
    local currentTime = getTimestampMs()
    if (currentTime - tooltipData.TypewriterDelayStartTime) < (tooltipData.TypewriterStartDelay * 1000) then
        return -- Don't show text yet, only selector
    end

    -- update typewriter progress (only after delay)
    FrameworkZ.Tooltips:UpdateTypewriterProgress()

    -- draw name + description with typewriter effect
    local tm = getTextManager()
    local font = UIFont.Dialogue
    local lineH = tm:getFontFromEnum(font):getLineHeight()
    local ty = sy + (sh * 0.5) + 6

    -- name at top (with typewriter effect) - recognition after observation
    local nameColor = tooltipData.TooltipCharacterNameColor
    local visibleName = string.sub(tooltipData.TooltipCharacterName, 1, tooltipData.TypewriterNameProgress)
    tm:DrawStringCentre(font, sx, ty, visibleName, nameColor.r, nameColor.g, nameColor.b, nameColor.a)
    ty = ty + lineH

    -- description below name (with typewriter effect) - observing appearance
    local descLines = tooltipData.TooltipCharacterDescriptionLines
    for i = 1, #descLines do
        local line = descLines[i]
        local visibleChars = tooltipData.TypewriterDescriptionProgress[i] or 0
        local visibleLine = string.sub(line, 1, visibleChars)
        tm:DrawStringCentre(font, sx, ty, visibleLine, 1, 1, 1, 1)
        ty = ty + lineH
    end
end

-- enable / disable the UI callback
function FrameworkZ.Tooltips:EnableTooltip()
    if not self.HoveredCharacterData.TooltipShowing then
        self.HoveredCharacterData.UI = ISUIElement:new(0, 0, 0, 0)
        self.HoveredCharacterData.UI:initialise()
        self.HoveredCharacterData.UI:addToUIManager()
        self.HoveredCharacterData.TooltipShowing = true
        Events.OnPreUIDraw.Add(FrameworkZ.Tooltips.DrawTooltip)
    end
end

function FrameworkZ.Tooltips:DisableTooltip()
    if self.HoveredCharacterData.TooltipShowing then
        Events.OnPreUIDraw.Remove(FrameworkZ.Tooltips.DrawTooltip)
        self.HoveredCharacterData.TooltipShowing = false
        self.HoveredCharacterData.TooltipPlayer = nil
        self.HoveredCharacterData.UI = nil
        -- Reset character data state when disabling tooltip
        self.HoveredCharacterData.TooltipDataLoaded = false
        self.HoveredCharacterData.TooltipRequestSent = false
        self.HoveredCharacterData.TooltipLastRequestedTarget = nil
        FrameworkZ.Tooltips:ResetTypewriterState()
    end
end

-- Cache cleanup function to prevent memory leaks
function FrameworkZ.Tooltips:CleanupCaches()
    local currentTime = getTimestampMs()
    
    -- Clean up screen position cache if it's getting too old (every 10 seconds)
    if currentTime - self.HoveredCharacterData._lastCacheCleanupTime > 10000 then
        self.HoveredCharacterData._cachedScreenPositions = {}
        self.HoveredCharacterData._lastCacheCleanupTime = currentTime
    end
    
    -- Limit cache size to prevent memory bloat (increased from 50 to 100)
    local cacheCount = 0
    for _ in pairs(self.HoveredCharacterData._cachedScreenPositions) do
        cacheCount = cacheCount + 1
    end
    
    if cacheCount > 100 then -- Limit to 100 cached positions
        -- Clear oldest entries by recreating cache (simple but effective)
        local newCache = {}
        local count = 0
        for key, value in pairs(self.HoveredCharacterData._cachedScreenPositions) do
            if count < 50 then -- Keep newest 50
                newCache[key] = value
                count = count + 1
            else
                break
            end
        end
        self.HoveredCharacterData._cachedScreenPositions = newCache
    end
end

-- Main tick function (heavily optimized)
function FrameworkZ.Tooltips.OnTick()
    -- Cleanup caches periodically
    FrameworkZ.Tooltips:CleanupCaches()
    
    local mp = getPlayer()
    if not mp then
        FrameworkZ.Tooltips:DisableTooltip()
        return
    end

    local mx, my = getMouseX(), getMouseY()
    local pidx = mp:getPlayerNum()
    local wx = screenToIsoX(pidx, mx, my, 0)
    local wy = screenToIsoY(pidx, mx, my, 0)
    local wz = mp:getZ()
    local sq = getSquare(wx, wy, wz)

    if not sq then
        FrameworkZ.Tooltips:DisableTooltip()
        return
    end

    -- scan a 3×3 grid for all IsoPlayers and score them (optimized)
    local candidates = {}
    local cell = getCell()  -- Cache cell reference
    local sqX, sqY = sq:getX(), sq:getY()
    
    for ix = sqX - 1, sqX + 1 do
        for iy = sqY - 1, sqY + 1 do
            local sq2 = cell:getGridSquare(ix, iy, wz)
            if sq2 then
                local movingObjects = sq2:getMovingObjects()
                local objCount = movingObjects:size()
                for i = 0, objCount - 1 do
                    local o = movingObjects:get(i)
                    if instanceof(o, "IsoPlayer") then -- TODO uncomment when finalized: and o ~= mp
                        local score = FrameworkZ.Tooltips:CalculateCharacterScore(mp, o, mx, my)
                        if score > 0 then -- Only add candidates with positive scores
                            candidates[#candidates + 1] = {player = o, score = score}
                        end
                    end
                end
            end
        end
    end

    -- Find the best candidate using utility function
    local bestCandidate, bestScore = Utils.findBestCandidate(candidates)

    -- Determine if we should switch to a new character
    local shouldSwitch = false
    local currentPlayerStillValid = false
    local currentScore = 0
    local tooltipData = FrameworkZ.Tooltips.HoveredCharacterData

    -- Check if current player is still in candidates list using utility function
    if tooltipData.TooltipPlayer then
        currentPlayerStillValid, currentScore = Utils.checkPlayerValidity(candidates, tooltipData.TooltipPlayer)
    end

    if not tooltipData.TooltipPlayer then
        -- No current player, switch to any valid candidate
        shouldSwitch = bestCandidate ~= nil
    elseif not bestCandidate then
        -- No candidates found, disable tooltip
        shouldSwitch = true
        bestCandidate = nil
    elseif not currentPlayerStillValid then
        -- Current player is no longer valid, switch to best candidate
        shouldSwitch = true
    else
        -- Check if the best candidate is different and significantly better
        if bestCandidate ~= tooltipData.TooltipPlayer then
            -- Only switch if the new candidate is significantly better
            local scoreDifference = (bestScore - currentScore) / math.max(bestScore, 1)
            shouldSwitch = scoreDifference > tooltipData.TooltipSwitchThreshold
        end
    end

    if shouldSwitch then
        if bestCandidate then
            -- Check line of sight before showing tooltip - if no line of sight, don't show tooltip at all
            if not FrameworkZ.Tooltips:HasLineOfSight(mp, bestCandidate) then
                FrameworkZ.Tooltips:DisableTooltip()
                return
            end

            -- Check if player is facing the target - if not, don't show tooltip at all
            if not FrameworkZ.Tooltips:IsPlayerFacingTarget(mp, bestCandidate:getX(), bestCandidate:getY(), ANGLE_CONSTANTS.PI_1_5) then
                FrameworkZ.Tooltips:DisableTooltip()
                return
            end

            -- Update to new character
            if bestCandidate ~= tooltipData.TooltipPlayer then
                tooltipData.TooltipPlayer = bestCandidate

                -- Reset character data state only if switching to a new character
                local targetUsername = bestCandidate:getUsername()
                if tooltipData.TooltipLastRequestedTarget ~= targetUsername then
                    tooltipData.TooltipDataLoaded = false
                    tooltipData.TooltipRequestSent = false
                    tooltipData.TooltipLastRequestedTarget = targetUsername
                end

                -- Show loading state immediately
                tooltipData.TooltipCharacterName = "[Loading...]"
                tooltipData.TooltipCharacterNameColor = {r = 0.7, g = 0.7, b = 0.7, a = 1}
                tooltipData.TooltipCharacterDescriptionLines = {}

                -- Request character data from server - only send if we haven't already sent for this specific player
                if not tooltipData.TooltipRequestSent then
                    FrameworkZ.Foundation:SendFire(mp, "FrameworkZ.Tooltips.RequestCharacterData", function(data, responseData)
                        -- Handle response from server
                        FrameworkZ.Tooltips:OnReceiveCharacterData(responseData)
                    end, mp:getUsername(), targetUsername)
                    tooltipData.TooltipRequestSent = true
                elseif tooltipData.TooltipDataLoaded then
                    -- If data is already loaded, show it immediately
                    local character = FrameworkZ.Characters:GetCharacterByID(mp:getUsername())
                    if not character then return end
                    local targetCharacter = FrameworkZ.Characters:GetCharacterByID(targetUsername)
                    if not targetCharacter then return end

                    tooltipData.TooltipCharacterName = character:GetRecognition(targetCharacter)
                    tooltipData.TooltipCharacterNameColor = FrameworkZ.Factions:GetFactionByID(tooltipData.TooltipCharacterFaction):GetColor() or {r = 1, g = 1, b = 1, a = 1}
                    tooltipData.TooltipCharacterDescriptionLines = FrameworkZ.Tooltips:GetDescriptionLines(tooltipData.TooltipCharacterDescription)

                    FrameworkZ.Tooltips:ResetTypewriterState()
                end

                -- Calculate initial typewriter speed and reset state
                tooltipData.TypewriterCurrentSpeed = FrameworkZ.Tooltips:CalculateTypewriterSpeed(mp, bestCandidate)
                FrameworkZ.Tooltips:ResetTypewriterState()
            end
            FrameworkZ.Tooltips:EnableTooltip()
        else
            -- No valid candidate, disable tooltip
            tooltipData.TooltipPlayer = nil
            FrameworkZ.Tooltips:DisableTooltip()
        end
    elseif tooltipData.TooltipPlayer and currentPlayerStillValid then
        -- Check line of sight for current player before keeping tooltip
        if not FrameworkZ.Tooltips:HasLineOfSight(mp, tooltipData.TooltipPlayer) then
            -- Lost line of sight, disable tooltip
            FrameworkZ.Tooltips:DisableTooltip()
            return
        end
        
        -- Also check if still facing the current target
        if not FrameworkZ.Tooltips:IsPlayerFacingTarget(mp, tooltipData.TooltipPlayer:getX(), tooltipData.TooltipPlayer:getY(), ANGLE_CONSTANTS.PI_1_5) then
            FrameworkZ.Tooltips:DisableTooltip()
            return
        end
        
        -- Keep showing tooltip for current player
        FrameworkZ.Tooltips:EnableTooltip()
    else
        -- No valid player to show
        FrameworkZ.Tooltips:DisableTooltip()
    end
end
Events.OnTick.Add(FrameworkZ.Tooltips.OnTick)

function FrameworkZ.Tooltips:OnReceiveCharacterData(responseData)
    if not responseData then
        return
    end

    -- Only process if this response is for our current tooltip target
    if self.HoveredCharacterData.TooltipPlayer and self.HoveredCharacterData.TooltipPlayer:getUsername() == responseData.targetUsername then
        -- Store the character data
        self.HoveredCharacterData.TooltipDataLoaded = true

        -- Update tooltip data with recognition logic
        self.HoveredCharacterData.TooltipCharacterName = responseData.targetData.name or "[Unknown]"

        -- Get faction color
        local targetFaction = responseData.targetData.faction
        self.HoveredCharacterData.TooltipCharacterNameColor = targetFaction and FrameworkZ.Factions:GetFactionByID(targetFaction):GetColor() or {r = 1, g = 1, b = 1, a = 1}

        -- Get description
        local descStr = responseData.targetData.description or ""
        self.HoveredCharacterData.TooltipCharacterDescriptionLines = FrameworkZ.Tooltips:GetDescriptionLines(descStr)

        -- Reset typewriter state with new data
        FrameworkZ.Tooltips:ResetTypewriterState()
    end
end

if isServer() then
    function FrameworkZ.Tooltips.RequestCharacterData(data, localUsername, targetUsername, requestingPlayer)
        -- Get both characters from server-side data
        local localCharacter = FrameworkZ.Characters:GetCharacterByID(localUsername)
        local targetCharacter = FrameworkZ.Characters:GetCharacterByID(targetUsername)

        if localCharacter and targetCharacter then
            local responseData = {
                localUsername = localUsername,
                targetUsername = targetUsername,
                localRecognizes = localCharacter:GetRecognition(targetCharacter) or "[Unknown]",
                targetData = {
                    name = localCharacter:GetRecognition(targetCharacter) or "[Unknown]",
                    description = targetCharacter:GetDescription() or "[No Description]",
                    faction = targetCharacter:GetFaction() or "[No Faction]",
                    uid = targetCharacter:GetUID() or "[No UID]"
                }
            }

            -- Return response data to client via callback
            return responseData
        end

        -- Return empty response if something went wrong
        return {
            localUsername = localUsername or "unknown",
            targetUsername = targetUsername or "unknown",
            localRecognizes = {},
            targetData = {
                name = "[Error]",
                description = "[Error retrieving data]",
                faction = nil,
                uid = nil
            }
        }
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Tooltips.RequestCharacterData", FrameworkZ.Tooltips.RequestCharacterData)
end
