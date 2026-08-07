--[[
FrameworkZ = FrameworkZ or {}

FrameworkZ.UpgradeSystem = FrameworkZ.UpgradeSystem or {}

function FrameworkZ.UpgradeSystem.registerUpgrade(factionID, upgradeName, upgradeFunction)
    if FrameworkZ.Factions[factionID] then
        FrameworkZ.Factions[factionID].upgrades[upgradeName] = upgradeFunction
    else
        print("Invalid faction: " .. factionID)
    end
end

function FrameworkZ.UpgradeSystem.applyUpgrade(character, faction, upgradeName)
    if FrameworkZ.Factions[faction] and FrameworkZ.Factions[faction].upgrades[upgradeName] then
        FrameworkZ.Factions[faction].upgrades[upgradeName](character)
    else
        print("Invalid faction or upgrade: " .. faction .. ", " .. upgradeName)
    end
end
--]]