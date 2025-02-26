--! \brief Utility module for FrameworkZ. Contains utility functions and classes.
--! \class FrameworkZ.Utility
FrameworkZ.Utilities = {}
FrameworkZ.Utilities.__index = FrameworkZ.Utilities
FrameworkZ.Utilities = FrameworkZ.Foundation:NewModule(FrameworkZ.Utilities, "Utilities")

--! \brief Copies a table.
--! \param \table originalTable The table to copy.
--! \param \table tableCopies (Internal) The table of copies used internally by the function.
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
