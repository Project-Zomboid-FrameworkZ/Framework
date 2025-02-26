FrameworkZ = FrameworkZ or {}

-- FrameworkZ Configuration Values
FrameworkZ.Config = {
    SkipIntro = true,
    Version = "5.6.3",
    VersionType = "alpha",

    IntroFrameworkImage = "media/textures/fz.png",
    IntroGamemodeImage = "media/textures/hl2rp.png",
    MainMenuImage = "media/textures/citidel.png",

    IntroMusic = "hl2_song25_teleporter_short", -- Approximately 15 seconds long
    MainMenuMusic = "hl2_song19",

    FrameworkTitle = "FrameworkZ",
    GamemodeTitle = "No Gamemode Loaded",
    GamemodeDescription = "The base FrameworkZ foundation.",

    CharacterMinAge = 18, -- Years
    CharacterMaxAge = 100, -- Years
    CharacterMinHeight = 48, -- Inches
    CharacterMaxHeight = 84, -- Inches
    CharacterMinWeight = 80, -- Pounds
    CharacterMaxWeight = 300, -- Pounds

    CharacterSaveInterval = 600,
    ShouldNotifyOnCharacterSave = true,

    LimboX = 18539,
    LimboY = 79,
    LimboZ = 0,

    SpawnX = 0,
    SpawnY = 0,
    SpawnZ = 0,

    DefaultMaxCharacters = 1,

    -- Initialization Duration
    InitializationDuration = 5,

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

