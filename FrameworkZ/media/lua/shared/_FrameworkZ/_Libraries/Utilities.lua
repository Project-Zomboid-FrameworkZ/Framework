--! \brief Utility module for FrameworkZ. Contains utility functions and classes.
--! \class FrameworkZ.Utility
FrameworkZ.Utilities = {}
FrameworkZ.Utilities.__index = FrameworkZ.Utilities
FrameworkZ.Utilities = FrameworkZ.Foundation:NewModule(FrameworkZ.Utilities, "Utilities")

--! \brief Copies a table.
--! \param originalTable \table The table to copy.
--! \param tableCopies \table (Internal) The table of copies used internally by the function.
--! \return \table The copied table.
function FrameworkZ.Utilities:CopyTable(originalTable, tableCopies)
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

            setmetatable(copy, self:CopyTable(getmetatable(originalTable), tableCopies))
        end
    else -- number, string, boolean, etc
        copy = originalTable
    end

    return copy
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
