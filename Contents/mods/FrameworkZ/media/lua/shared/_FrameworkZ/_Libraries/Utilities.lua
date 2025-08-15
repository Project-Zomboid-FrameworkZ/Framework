local IsoFlagType = IsoFlagType
local select = select
local unpack = unpack

--! \brief Utility module for FrameworkZ. Contains utility functions and classes.
--! \library FrameworkZ.Utilities
FrameworkZ.Utilities = {}
FrameworkZ.Utilities.__index = FrameworkZ.Utilities
FrameworkZ.Utilities = FrameworkZ.Foundation:NewModule(FrameworkZ.Utilities, "Utilities")

function FrameworkZ.Utilities:Pack(...)
    return {n = select("#", ...), ...}
end

function FrameworkZ.Utilities:Unpack(t)
    return unpack(t, 1, t.n)
end

--! \brief Copies a table.
--! \param originalTable \table The table to copy.
--! \param tableCopies \table (Internal) The table of copies used internally by the function.
--! \return \table The copied table.
function FrameworkZ.Utilities:CopyTable(originalTable, tableCopies, shouldCopyMetatable)
    tableCopies = tableCopies or {}

    local originalType = type(originalTable)
    local copy

    if originalType == "table" then
        if tableCopies[originalTable] then
            copy = tableCopies[originalTable]
        else
            copy = {}
            tableCopies[originalTable] = copy

            for originalKey, originalValue in pairs(originalTable) do
                copy[self:CopyTable(originalKey, tableCopies)] = self:CopyTable(originalValue, tableCopies)
            end

            local mt = getmetatable(originalTable)

            if mt and type(mt) == "table" then
                setmetatable(copy, self:CopyTable(mt, tableCopies))
            end
        end
    else -- number, string, boolean, etc
        copy = originalTable
    end

    return copy
end

function FrameworkZ.Utilities:MergeTables(t1, t2, visited)
    visited = visited or {}
    if visited[t1] and visited[t2] then
        return t1
    end
    visited[t1] = true
    visited[t2] = true

    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            self:MergeTables(t1[k], v, visited)
        else
            t1[k] = v
        end
    end

    -- Handle metatable merging (improved logic)
    local mt1 = getmetatable(t1)
    local mt2 = getmetatable(t2)

    if mt1 and mt2 then
        if type(mt1) == "table" and type(mt2) == "table" then
            -- Merge both metatables into a new table to preserve both chains
            local mergedMeta = {}
            self:MergeTables(mergedMeta, mt1, visited)
            self:MergeTables(mergedMeta, mt2, visited)
            setmetatable(t1, mergedMeta)
        else
            -- If either metatable isn't a table, prefer t2's metatable
            setmetatable(t1, mt2)
        end
    elseif mt2 then
        setmetatable(t1, mt2)
    elseif mt1 then
        setmetatable(t1, mt1)
    end

    return t1
end

function FrameworkZ.Utilities:DumpTable(tbl)
    if type(tbl) == 'table' then
        local s = '{ '
        for k,v in pairs(tbl) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. self:DumpTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(tbl)
    end
end

function FrameworkZ.Utilities:PrintTable(tbl)
    print(self:DumpTable(tbl))
end

function FrameworkZ.Utilities:TableIsEmpty(t)
    if type(t) ~= "table" then
        return false
    end

    local isEmpty = true

    for _, _ in pairs(t) do
        isEmpty = false
        break
    end

    return isEmpty
end

function FrameworkZ.Utilities:TableContainsKey(t, key)
    if t then
        for k, _ in pairs(t) do
            if k == key then
                return true
            end
        end
    end

    return false
end

function FrameworkZ.Utilities:TableContainsValue(t, value)
    if t then
        for _, v in pairs(t) do
            if v == value then
                return true
            end
        end
    end

    return false
end

function FrameworkZ.Utilities:RemoveContextDuplicates(worldObjects)
    local newObjects = {}

    for _, v1 in ipairs(worldObjects) do
        local isInList = false

        for _2, v2 in ipairs(newObjects) do
            if v2 == v1 then
                isInList = true
                break
            end
        end

        if not isInList then
            table.insert(newObjects, v1)
        end
    end

    return newObjects
end

function FrameworkZ.Utilities:__GenOrderedIndex( t )
    local orderedIndex = {}

    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end

    table.sort(orderedIndex)

    return orderedIndex
end

function FrameworkZ.Utilities:OrderedNext(t, state)
    local key = nil

    if state == nil then
        t.__orderedIndex = self:__GenOrderedIndex(t)
        key = t.__orderedIndex[1]
    else
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    t.__orderedIndex = nil

    return
end

function FrameworkZ.Utilities:OrderedPairs(t)
    return self.OrderedNext, t, nil
end

--! \brief Word wraps text to a specified length.
--! \param text \string The text to word wrap.
--! \param maxLength \int The maximum length of a line (default: 28).
--! \param eolDelimiter \string (Optional) The end of line delimiter. Returns a \table of lines if not supplied.
--! \return \mixed The word wrapped text as a \string or a \table of lines of text if no eolDelimiter was supplied as an argument.
function FrameworkZ.Utilities:WordWrapText(text, maxLength, eolDelimiter)
    local maxLineLength = maxLength or 28
    local lines = {}
    local line = ""
    local lineLength = 0
    local words = {}

    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    for i = 1, #words do
        local word = words[i]
        local wordLength = string.len(word)

        if lineLength + wordLength <= maxLineLength then
            line = line .. " " .. word
            lineLength = lineLength + wordLength
        else
            table.insert(lines, line)
            line = word
            lineLength = wordLength
        end
    end

    table.insert(lines, line)

    if eolDelimiter then
        local delimitedText = ""

        for i = 1, #lines do
            delimitedText = delimitedText .. lines[i] .. (i ~= #lines and eolDelimiter or "")
        end

        return delimitedText
    end

    return lines
end

function FrameworkZ.Utilities:GetRandomNumber(min, max, keepLeadingZeros)
    if min > max then
        min, max = max, min
    end

    local maxDigits = math.max(#tostring(min), #tostring(max))

    return keepLeadingZeros and string.format("%0" .. maxDigits .. "d", ZombRandBetween(min, max)) or ZombRandBetween(min, max)
end

FrameworkZ.Utilities.Directions = {
    { dx =  1, dy =  0, wallFlag = IsoFlagType.collideW, doorFlag = IsoFlagType.doorW, windowFlag = IsoFlagType.windowW },
    { dx = -1, dy =  0, wallFlag = IsoFlagType.collideW, doorFlag = IsoFlagType.doorW, windowFlag = IsoFlagType.windowW },
    { dx =  0, dy =  1, wallFlag = IsoFlagType.collideN, doorFlag = IsoFlagType.doorN, windowFlag = IsoFlagType.windowN },
    { dx =  0, dy = -1, wallFlag = IsoFlagType.collideN, doorFlag = IsoFlagType.doorN, windowFlag = IsoFlagType.windowN },
}

function FrameworkZ.Utilities:IsExterior(square)
    return not square or square:getRoom() == nil
end

function FrameworkZ.Utilities:IsTrulyInterior(square)
    if not square then return false end
    local room = square:getRoom()
    if not room then return false end

    local seen = {}
    local queue = { square }
    seen[square] = true

    while #queue > 0 do
        local currentSquare = table.remove(queue, 1)

        for _, dir in ipairs(self.Directions) do
            local nx, ny, nz = currentSquare:getX() + dir.dx, currentSquare:getY() + dir.dy, currentSquare:getZ()
            local nextSquare = getCell():getGridSquare(nx, ny, nz)

            if nextSquare and not seen[nextSquare] then
                local blocked = nextSquare:Is(dir.wallFlag) or nextSquare:Is(dir.doorFlag) or nextSquare:Is(dir.windowFlag)

                if not blocked then
                    if not nextSquare:getRoom() then
                        return false
                    end

                    if nextSquare:getRoom() == room then
                        seen[nextSquare] = true
                        table.insert(queue, nextSquare)
                    end
                end
            end
        end
    end

    return true
end

function FrameworkZ.Utilities:IsSemiExterior(square)
    if not square or not square:getRoom() then return false end
    return not FrameworkZ.Utilities:IsTrulyInterior(square)
end

function FrameworkZ.Utilities:GetPrettyDuration(timeInSeconds)
    local seconds = math.floor(tonumber(timeInSeconds) or 0)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local parts = {}

    if days > 0 then
        table.insert(parts, days .. (days == 1 and " day" or " days"))
        if hours > 0 then
            table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
        end
    elseif hours > 0 then
        table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
        if minutes > 0 then
            table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
        end
    elseif minutes > 0 then
        table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
        if seconds > 0 then
            table.insert(parts, seconds .. (seconds == 1 and " second" or " seconds"))
        end
    else
        table.insert(parts, seconds .. (seconds == 1 and " second" or " seconds"))
    end

    return table.concat(parts, " and ")
end

--! \brief Trims a string to a maximum length, optionally adding ellipsis.
--! \param str \string The string to trim.
--! \param maxLength \int The maximum allowed length.
--! \param addEllipsis \boolean (Optional) If true, appends "..." if trimmed.
--! \return \string The trimmed string.
function FrameworkZ.Utilities:TrimString(str, maxLength, addEllipsis)
    if type(str) ~= "string" or type(maxLength) ~= "number" then
        return str
    end

    if #str <= maxLength then
        return str
    end

    if addEllipsis then
        local ellipsis = "..."
        if maxLength > #ellipsis then
            local trimmed = string.sub(str, 1, maxLength - #ellipsis)
            trimmed = trimmed:match("^(.-)%s*$")
            return trimmed .. ellipsis
        else
            return string.sub(str, 1, maxLength)
        end
    else
        return string.sub(str, 1, maxLength)
    end
end
