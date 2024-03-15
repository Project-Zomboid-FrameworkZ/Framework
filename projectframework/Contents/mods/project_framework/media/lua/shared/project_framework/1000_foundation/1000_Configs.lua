ProjectFramework = ProjectFramework or {}

-- Project HL2RP Configuration Values
ProjectFramework.Config = {

    IntroFrameworkImage = "",
    IntroGamemodeImage = "",
    IntroMusic = "",
    FrameworkTitle = "Project Framework",
    GamemodeTitle = "Half-Life 2 Roleplay",
    GamemodeDescription = "A roleplaying gamemode based on the Half-Life 2 universe.",
    SkipIntro = true,

    DefaultMaxCharacters = 1,

    -- Initialization Duration
    InitializationDuration = 1,

    -- Lockpicking
    LockpickChance = 0.5,
    LockpickCooldown = 60,
    LockpickMaxDistance = 2,
    
    -- Pickpocketing
    PickPocketChance = 0.5,
    PickPocketCooldown = 60,
    PickPocketMaxDistance = 2,

    -- Factions
    Factions = {
        FACTION_CITIZEN = {
            limit = 0
        }
    }
}

