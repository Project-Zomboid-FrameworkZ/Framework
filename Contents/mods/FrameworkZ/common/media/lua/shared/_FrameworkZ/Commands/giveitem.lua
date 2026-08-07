---@diagnostic disable: undefined-global
local function canIssueFromIsoPlayer(isoPlayer)
    if not isoPlayer then return false end

    local level = isoPlayer:getAccessLevel()
    return level == "admin" or level == "moderator"
end

local function resolvePlayerByCharacterName(characterName)
    if not characterName or characterName == "" then
        return false, "Missing character name."
    end

    local needle = string.lower(characterName)
    local matches = {}

    for username, character in pairs(FrameworkZ.Characters.List or {}) do
        if character and character.GetName then
            local currentName = character:GetName()
            if type(currentName) == "string" and string.lower(currentName) == needle then
                table.insert(matches, {username = username, name = currentName})
            end
        end
    end

    if #matches == 0 then
        return false, "Character not found (must be loaded/online): " .. tostring(characterName)
    end

    if #matches > 1 then
        return false, "Multiple loaded characters match that name. Use a more unique name."
    end

    local hit = matches[1]
    local player, msg = FrameworkZ.Players:GetPlayerByID(hit.username)
    if not player then
        return false, "Player lookup failed for character owner: " .. tostring(msg or hit.username)
    end

    return player, hit.name
end

local function issueFZItem(issuerIsoPlayer, targetCharacterName, itemUniqueID, amount)
    if not isServer() then return false, "Must run on server." end

    if issuerIsoPlayer and not canIssueFromIsoPlayer(issuerIsoPlayer) then
        return false, "You do not have permission to issue FZ items."
    end

    if not targetCharacterName or targetCharacterName == "" then
        return false, "Missing target character name."
    end

    if not itemUniqueID or itemUniqueID == "" then
        return false, "Missing FZ unique item ID."
    end

    amount = tonumber(amount) or 1
    amount = math.floor(amount)

    if amount < 1 then
        return false, "Amount must be at least 1."
    end

    local targetPlayer, targetMsg = resolvePlayerByCharacterName(targetCharacterName)
    if not targetPlayer then
        return false, tostring(targetMsg)
    end

    local targetIsoPlayer = targetPlayer:GetIsoPlayer()
    if not targetIsoPlayer then
        return false, "Target player has no active IsoPlayer."
    end

    local targetCharacter = targetPlayer:GetCharacter() or FrameworkZ.Characters:GetCharacterByID(targetPlayer:GetUsername())
    if not targetCharacter then
        return false, "Target player's character is not loaded."
    end

    local itemDef = FrameworkZ.Items:GetItemByUniqueID(itemUniqueID)
    if not itemDef then
        return false, "Unknown FZ item unique ID: " .. tostring(itemUniqueID)
    end

    local granted = 0
    local lastError = nil

    for i = 1, amount do
        local didGrant = false
        local callbackMessage = nil

        targetCharacter:GiveItem(itemUniqueID, 1, function(instances, message)
            callbackMessage = message
            if type(instances) == "table" and #instances > 0 then
                didGrant = true
            end
        end)

        if didGrant then
            granted = granted + 1
        else
            lastError = callbackMessage or "Failed to give item instance."
            break
        end
    end

    if granted <= 0 then
        return false, "No items granted. " .. tostring(lastError or "Unknown error.")
    end

    if granted < amount then
        return true, "Partially granted " .. tostring(granted) .. "/" .. tostring(amount) .. " of '" .. tostring(itemUniqueID) .. "'. Last error: " .. tostring(lastError)
    end

    return true, "Granted " .. tostring(granted) .. "x '" .. tostring(itemUniqueID) .. "' to " .. tostring(targetMsg or targetCharacterName) .. "."
end

local function onIssueFZItem(data, targetCharacterName, itemUniqueID, amount)
    local issuer = data and data.isoPlayer or nil
    return issueFZItem(issuer, targetCharacterName, itemUniqueID, amount)
end

FrameworkZ.Foundation:Subscribe("COMMANDS.OnIssueFZItem", onIssueFZItem)

local COMMAND = FrameworkZ.Commands:New("giveitem")

COMMAND.description = "Give an FZ item by unique ID to a target player."
COMMAND.usage = "/giveitem <character name> <itemUniqueID> [amount]"
COMMAND.adminOnly = true
COMMAND.allowConsole = true
COMMAND.minArgs = 2
COMMAND.maxArgs = 3

function COMMAND:CanRun(player, args)
    if not player then return true end

    local level = player:getAccessLevel()
    return level == "admin" or level == "moderator"
end

function COMMAND:OnRun(player, args)
    local targetCharacterName = args[1]
    local itemUniqueID = args[2]
    local amount = tonumber(args[3] or 1) or 1
    local character = FrameworkZ.Characters:FindCharacterByName(targetCharacterName) if not character then return false, "Character not found: " .. tostring(targetCharacterName) end
    
    local resultsCallback = function(success, message)
        if success then
            FrameworkZ.Commands:SendMessage(player, "Granted " .. tostring(amount) .. "x '" .. tostring(itemUniqueID) .. "' to " .. tostring(character:GetName()) .. ".")
        else
            FrameworkZ.Commands:SendMessage(player, "Failed to grant item: " .. tostring(message))
        end
    end

    character:GiveItems(itemUniqueID, amount, resultsCallback)
end

FrameworkZ.Commands:Register(COMMAND)
