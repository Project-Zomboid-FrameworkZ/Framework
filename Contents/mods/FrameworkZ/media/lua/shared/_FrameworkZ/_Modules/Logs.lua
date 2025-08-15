local Events = Events
local instanceof = instanceof

--! \brief Logs module for FrameworkZ. Logs player actions, system events, errors, warnings, and informational messages.
--! \module FrameworkZ.Logs
FrameworkZ.Logs = {}
FrameworkZ.Logs.__index = FrameworkZ.Logs
FrameworkZ.Logs.LogEntries = {}
FrameworkZ.Logs.MaxEntries = 1000  -- Maximum number of log entries to load
FrameworkZ.Logs.LogDirectory = "FrameworkZ_Logs/"  -- Directory to store log files

-- Define log types
FrameworkZ.Logs.LogTypes = {
    PLAYER_ACCEPT_TRADE = "Player Accept Trade",
    PLAYER_CANCEL_TRADE = "Player Cancel Trade",
    PLAYER_CREATE_CHARACTER = "Player Create Character",
    PLAYER_DEATH = "Player Death",
    PLAYER_DECLINE_TRADE = "Player Decline Trade",
    PLAYER_ENTER_CAR = "Player Enter Car",
    PLAYER_EXIT_CAR = "Player Exit Car",
    PLAYER_FINALIZE_TRADE = "Player Finalize Trade",
    PLAYER_GIVE_DAMAGE = "Player Give Damage",
    PLAYER_GRAB_ITEM = "Player Grab Item",
    PLAYER_KILL = "Player Kill",
    PLAYER_LOAD_CHARACTER = "Player Load Character",
    PLAYER_PLACE_ITEM = "Player Place Item",
    PLAYER_RECEIVE_ITEM = "Player Receive Item",
    PLAYER_TAKE_DAMAGE = "Player Take Damage",
    ZOMBIE_GIVE_DAMAGE = "Zombie Give Damage",
    ZOMBIE_TAKE_DAMAGE = "Zombie Take Damage",
    SYSTEM_EVENT = "System Event",
    ERROR = "Error",
    WARNING = "Warning",
    INFO = "Info"
}

--! \brief Add a log entry.
--! \param logType \string The type of log (e.g., "PlayerAction", "SystemEvent").
--! \param message \string The log message.
--! \param player \table Optional player table associated with the log.
function FrameworkZ.Logs:AddLog(logType, message, player)
    local logEntry = {
        timestamp = os.time(),
        logType = logType,
        message = message,
        player = player and player:getUsername() or nil
    }
    table.insert(self.LogEntries, logEntry)
    
    -- Save the log entry to a file
    self:SaveLogToFile(logEntry)

    -- Remove oldest entries if we exceed the maximum number of entries
    if #self.LogEntries > self.MaxEntries then
        table.remove(self.LogEntries, 1)
    end

    print(string.format("[%s] %s: %s", os.date("%Y-%m-%d %H:%M:%S", logEntry.timestamp), logType, message))
end

--! \brief Save a log entry to a file.
--! \param logEntry \table The log entry to save.
function FrameworkZ.Logs:SaveLogToFile(logEntry)
    local filename = self.LogDirectory .. (logEntry.player or "system") .. ".log"
    local fileWriter = getFileWriter(filename, true, false)
    if fileWriter then
        fileWriter:write(string.format("[%s] %s: %s\n", os.date("%Y-%m-%d %H:%M:%S", logEntry.timestamp), logEntry.logType, logEntry.message))
        fileWriter:close()
    else
        print("Error opening log file:", filename)
    end
end

--! \brief Retrieve log entries.
--! \param logType \string Optional log type to filter by.
--! \param player \string Optional player username to filter by.
--! \return \table A table of log entries.
function FrameworkZ.Logs:GetLogs(logType, player)
    local filteredLogs = {}
    for _, logEntry in ipairs(self.LogEntries) do
        if (not logType or logEntry.logType == FrameworkZ.Logs.LogTypes[logType]) and (not player or logEntry.player == player) then
            table.insert(filteredLogs, logEntry)
        end
    end
    return filteredLogs
end

--! \brief Load log entries from a file.
--! \param player \string The player username to load logs for.
function FrameworkZ.Logs:LoadLogsFromFile(player)
    local filename = self.LogDirectory .. (player or "system") .. ".log"
    local fileReader = getFileReader(filename, true)
    if fileReader then
        while true do
            local line = fileReader:readLine()
            if not line then break end
            local timestamp, logType, message = line:match("%[(.-)%] (%w+): (.+)")
            if timestamp and logType and message then
                table.insert(self.LogEntries, {
                    timestamp = os.time({year=timestamp:sub(1,4), month=timestamp:sub(6,7), day=timestamp:sub(9,10), hour=timestamp:sub(12,13), min=timestamp:sub(15,16), sec=timestamp:sub(18,19)}),
                    logType = logType,
                    message = message,
                    player = player
                })
            end
        end
        fileReader:close()
    else
        print("Error opening log file:", filename)
    end
end

--! \brief Search log entries by keyword.
--! \param keyword \string The keyword to search for.
--! \return \table A table of log entries that contain the keyword.
function FrameworkZ.Logs:SearchLogs(keyword)
    local searchResults = {}
    for _, logEntry in ipairs(self.LogEntries) do
        if string.find(logEntry.message, keyword) then
            table.insert(searchResults, logEntry)
        end
    end
    return searchResults
end

--! \brief Display logs in a menu for admins.
function FrameworkZ.Logs:OpenLogMenu()
    -- Placeholder for menu implementation
    print("Opening log menu for admins...")
    -- In a real implementation, you would create a UI menu here
end

-- Example usage of logging player actions
function FrameworkZ.Logs:LogPlayerAction(player, action)
    self:AddLog(self.LogTypes.PLAYER_ACTION, action, player)
end

-- Example usage of logging system events
function FrameworkZ.Logs:LogSystemEvent(message)
    self:AddLog(self.LogTypes.SYSTEM_EVENT, message)
end

-- Example usage of logging errors
function FrameworkZ.Logs:LogError(message)
    self:AddLog(self.LogTypes.ERROR, message)
end

-- Example usage of logging warnings
function FrameworkZ.Logs:LogWarning(message)
    self:AddLog(self.LogTypes.WARNING, message)
end

-- Example usage of logging informational messages
function FrameworkZ.Logs:LogInfo(message)
    self:AddLog(self.LogTypes.INFO, message)
end

--! \brief Log damage dealt to players from players and zombies.
--! \param characterGivingDamage \table The character dealing the damage.
--! \param characterTakingDamage \table The character taking the damage.
--! \param handWeapon \table The weapon used to deal the damage.
--! \param damage \integer The amount of damage dealt.
function FrameworkZ.Logs.OnWeaponHitCharacter(characterGivingDamage, characterTakingDamage, handWeapon, damage)
    if instanceof(characterTakingDamage, "IsoPlayer") then
        if instanceof(characterGivingDamage, "IsoPlayer") then
            local message = string.format("%s hit %s with %s for %d damage (X: %d, Y: %d, Z: %d)", characterGivingDamage:getUsername(), characterTakingDamage:getUsername(), handWeapon:getDisplayName(), damage, characterGivingDamage:getX(), characterGivingDamage:getY(), characterGivingDamage:getZ())
            FrameworkZ.Logs:AddLog(FrameworkZ.Logs.LogTypes.PLAYER_GIVE_DAMAGE, message, characterGivingDamage)

            message = string.format("%s took %d damage from %s using %s (X: %d, Y: %d, Z: %d)", characterTakingDamage:getUsername(), damage, characterGivingDamage:getUsername(), handWeapon:getDisplayName(), characterTakingDamage:getX(), characterTakingDamage:getY(), characterTakingDamage:getZ())
            FrameworkZ.Logs:AddLog(FrameworkZ.Logs.LogTypes.PLAYER_TAKE_DAMAGE, message, characterTakingDamage)
        elseif instanceof(characterGivingDamage, "IsoZombie") then
            local message = string.format("%s took %d damage from a zombie (X: %d, Y: %d, Z: %d)", characterTakingDamage:getUsername(), damage, characterTakingDamage:getX(), characterTakingDamage:getY(), characterTakingDamage:getZ())
            FrameworkZ.Logs:AddLog(FrameworkZ.Logs.LogTypes.ZOMBIE_TAKE_DAMAGE, message, characterTakingDamage)
        end
    elseif instanceof(characterTakingDamage, "IsoZombie") and instanceof(characterGivingDamage, "IsoPlayer") then
        local message = string.format("%s hit a zombie with %s for %d damage (X: %d, Y: %d, Z: %d)", characterGivingDamage:getUsername(), handWeapon:getDisplayName(), damage, characterTakingDamage:getX(), characterTakingDamage:getY(), characterTakingDamage:getZ())
        FrameworkZ.Logs:AddLog(FrameworkZ.Logs.LogTypes.ZOMBIE_GIVE_DAMAGE, message, characterGivingDamage)
    end
end
Events.OnWeaponHitCharacter.Add(FrameworkZ.Logs.OnWeaponHitCharacter)
