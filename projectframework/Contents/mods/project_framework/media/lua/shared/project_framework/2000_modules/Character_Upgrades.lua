--[[
ProjectFramework = ProjectFramework or {}

ProjectFramework.UpgradeSystem = ProjectFramework.UpgradeSystem or {}

function ProjectFramework.UpgradeSystem.registerUpgrade(factionID, upgradeName, upgradeFunction)
    if ProjectFramework.Factions[factionID] then
        ProjectFramework.Factions[factionID].upgrades[upgradeName] = upgradeFunction
    else
        print("Invalid faction: " .. factionID)
    end
end

function ProjectFramework.UpgradeSystem.applyUpgrade(character, faction, upgradeName)
    if ProjectFramework.Factions[faction] and ProjectFramework.Factions[faction].upgrades[upgradeName] then
        ProjectFramework.Factions[faction].upgrades[upgradeName](character)
    else
        print("Invalid faction or upgrade: " .. faction .. ", " .. upgradeName)
    end
end
--]]