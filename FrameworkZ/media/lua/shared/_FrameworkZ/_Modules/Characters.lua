--! \page features Features
--! \section Characters Characters
--! Characters are the main focus of the game. They are the players that interact with the world. Characters can be given a name, description, faction, age, height, eye color, hair color, etc. They can also be given items and equipment.\n\n
--! When a player connects to the server, they may create a character and load said character. The character is then saved to the player's data and can be loaded again when the player reconnects. Characters will be saved automatically at predetermined intervals or upon disconnection or when switching characters.\n\n
--! Characters are not given items in the traditional sense. Instead, they are given items by a unique ID from an item defined in the framework's (or gamemode's or even plugin's) files. This special item definition is then used to create an item instance that is added to the character's inventory. This allows for items to be created dynamically and given to characters. This allows for the same Project Zomboid item to be reused for different purposes.\n\n

--! \page global_variables Global Variables
--! \section Characters Characters
--! FrameworkZ.Characters\n
--! See Characters for the module on characters.\n\n
--! FrameworkZ.Characters.List\n
--! A list of all instanced characters in the game.

local getTextManager = getTextManager
local isClient = isClient
local sendClientCommand = sendClientCommand

FrameworkZ = FrameworkZ or {}

--! \brief Characters module for FrameworkZ. Defines and interacts with CHARACTER object.
--! \class FrameworkZ.Characters
FrameworkZ.Characters = {}

SKIN_COLOR_PALE = 0
SKIN_COLOR_WHITE = 1
SKIN_COLOR_TANNED = 2
SKIN_COLOR_BROWN = 3
SKIN_COLOR_DARK_BROWN = 4

HAIR_COLOR_BLACK_R = 0
HAIR_COLOR_BLACK_G = 0
HAIR_COLOR_BLACK_B = 0
HAIR_COLOR_BLONDE_R = 0.9
HAIR_COLOR_BLONDE_G = 0.9
HAIR_COLOR_BLONDE_B = 0.6
HAIR_COLOR_BROWN_R = 0.3
HAIR_COLOR_BROWN_G = 0.2
HAIR_COLOR_BROWN_B = 0.2
HAIR_COLOR_GRAY_R = 0.5
HAIR_COLOR_GRAY_G = 0.5
HAIR_COLOR_GRAY_B = 0.5
HAIR_COLOR_RED_R = 0.9
HAIR_COLOR_RED_G = 0.4
HAIR_COLOR_RED_B = 0.1
HAIR_COLOR_WHITE_R = 1
HAIR_COLOR_WHITE_G = 1
HAIR_COLOR_WHITE_B = 1

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_HEAD = "Hat"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_FACE = "Mask"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_EARS = "Ears"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_BACKPACK = "Back"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_GLOVES = "Hands"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_UNDERSHIRT = "Tshirt"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_OVERSHIRT = "Shirt"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_VEST = "TorsoExtraVest"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_BELT = "Belt"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_PANTS = "Pants"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_SOCKS = "Socks"

--! \brief Deprecated. To be removed.
EQUIPMENT_SLOT_SHOES = "Shoes"

FZ_ENUM_CHARACTER_INFO_FACTION = 1
FZ_ENUM_CHARACTER_INFO_GENDER = 2
FZ_ENUM_CHARACTER_INFO_NAME = 2
FZ_ENUM_CHARACTER_INFO_DESCRIPTION = 3
FZ_ENUM_CHARACTER_INFO_AGE = 4
FZ_ENUM_CHARACTER_INFO_HEIGHT = 5
FZ_ENUM_CHARACTER_INFO_WEIGHT = 6
FZ_ENUM_CHARACTER_INFO_PHYSIQUE = 7
FZ_ENUM_CHARACTER_INFO_EYE_COLOR = 8
FZ_ENUM_CHARACTER_INFO_BEARD_COLOR = 9
FZ_ENUM_CHARACTER_INFO_HAIR_COLOR = 10
FZ_ENUM_CHARACTER_INFO_SKIN_COLOR = 11
FZ_ENUM_CHARACTER_INFO_HAIR_STYLE = 12
FZ_ENUM_CHARACTER_INFO_BEARD_STYLE = 13
FZ_ENUM_CHARACTER_SLOT_BANDAGE = 15
FZ_ENUM_CHARACTER_SLOT_WOUND = 16
FZ_ENUM_CHARACTER_SLOT_BELT_EXTRA = 17
FZ_ENUM_CHARACTER_SLOT_BELT = 18
FZ_ENUM_CHARACTER_SLOT_BELLY_BUTTON = 19
FZ_ENUM_CHARACTER_SLOT_MAKEUP_FULL_FACE = 20
FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES = 21
FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES_SHADOW = 22
FZ_ENUM_CHARACTER_SLOT_MAKEUP_LIPS = 23
FZ_ENUM_CHARACTER_SLOT_MASK = 24
FZ_ENUM_CHARACTER_SLOT_MASK_EYES = 25
FZ_ENUM_CHARACTER_SLOT_MASK_FULL = 26
FZ_ENUM_CHARACTER_SLOT_UNDERWEAR = 27
FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_BOTTOM = 28
FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_TOP = 29
FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA1 = 30
FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA2 = 31
FZ_ENUM_CHARACTER_SLOT_HAT = 32
FZ_ENUM_CHARACTER_SLOT_FULL_HAT = 33
FZ_ENUM_CHARACTER_SLOT_EARS = 34
FZ_ENUM_CHARACTER_SLOT_EAR_TOP = 35
FZ_ENUM_CHARACTER_SLOT_NOSE = 36
FZ_ENUM_CHARACTER_SLOT_TORSO1 = 37
FZ_ENUM_CHARACTER_SLOT_TORSO_LEGS1 = 38
FZ_ENUM_CHARACTER_SLOT_TANK_TOP = 39
FZ_ENUM_CHARACTER_SLOT_TSHIRT = 40
FZ_ENUM_CHARACTER_SLOT_SHORT_SLEEVE_SHIRT = 41
FZ_ENUM_CHARACTER_SLOT_LEFT_WRIST = 42
FZ_ENUM_CHARACTER_SLOT_RIGHT_WRIST = 43
FZ_ENUM_CHARACTER_SLOT_SHIRT = 44
FZ_ENUM_CHARACTER_SLOT_NECK = 45
FZ_ENUM_CHARACTER_SLOT_NECKLACE = 46
FZ_ENUM_CHARACTER_SLOT_NECKLACE_LONG = 47
FZ_ENUM_CHARACTER_SLOT_RIGHT_MIDDLE_FINGER = 48
FZ_ENUM_CHARACTER_SLOT_LEFT_MIDDLE_FINGER = 49
FZ_ENUM_CHARACTER_SLOT_LEFT_RING_FINGER = 50
FZ_ENUM_CHARACTER_SLOT_RIGHT_RING_FINGER = 51
FZ_ENUM_CHARACTER_SLOT_HANDS = 52
FZ_ENUM_CHARACTER_SLOT_HANDS_LEFT = 53
FZ_ENUM_CHARACTER_SLOT_HANDS_RIGHT = 54
FZ_ENUM_CHARACTER_SLOT_SOCKS = 55
FZ_ENUM_CHARACTER_SLOT_LEGS1 = 56
FZ_ENUM_CHARACTER_SLOT_PANTS = 57
FZ_ENUM_CHARACTER_SLOT_SKIRT = 58
FZ_ENUM_CHARACTER_SLOT_LEGS5 = 59
FZ_ENUM_CHARACTER_SLOT_DRESS = 60
FZ_ENUM_CHARACTER_SLOT_SWEATER = 61
FZ_ENUM_CHARACTER_SLOT_SWEATER_HAT = 62
FZ_ENUM_CHARACTER_SLOT_JACKET = 63
FZ_ENUM_CHARACTER_SLOT_JACKET_DOWN = 64
FZ_ENUM_CHARACTER_SLOT_JACKET_BULKY = 65
FZ_ENUM_CHARACTER_SLOT_JACKET_HAT = 66
FZ_ENUM_CHARACTER_SLOT_JACKET_HAT_BULKY = 67
FZ_ENUM_CHARACTER_SLOT_JACKET_SUIT = 68
FZ_ENUM_CHARACTER_SLOT_FULL_SUIT = 69
FZ_ENUM_CHARACTER_SLOT_BOILDER_SUIT = 70
FZ_ENUM_CHARACTER_SLOT_FULL_SUIT_HEAD = 71
FZ_ENUM_CHARACTER_SLOT_FULL_TOP = 72
FZ_ENUM_CHARACTER_SLOT_BATH_ROBE = 73
FZ_ENUM_CHARACTER_SLOT_SHOES = 74
FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_FRONT = 75
FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_BACK = 76
FZ_ENUM_CHARACTER_SLOT_AMMO_STRAP = 77
FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA = 78
FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA_VEST = 79
FZ_ENUM_CHARACTER_SLOT_TAIL = 80
FZ_ENUM_CHARACTER_SLOT_BACK = 81
FZ_ENUM_CHARACTER_SLOT_LEFT_EYE = 82
FZ_ENUM_CHARACTER_SLOT_RIGHT_EYE = 83
FZ_ENUM_CHARACTER_SLOT_EYES = 84
FZ_ENUM_CHARACTER_SLOT_SCARF = 85
FZ_ENUM_CHARACTER_SLOT_ZED_DMG = 86

FZ_SLOT_BANDAGE = "Bandage"
FZ_SLOT_WOUND = "Wound"
FZ_SLOT_BELT_EXTRA = "BeltExtra"
FZ_SLOT_BELT = "Belt"
FZ_SLOT_BELLY_BUTTON = "BellyButton"
FZ_SLOT_MAKEUP_FULL_FACE = "MakeUp_FullFace"
FZ_SLOT_MAKEUP_EYES = "MakeUp_Eyes"
FZ_SLOT_MAKEUP_EYES_SHADOW = "MakeUp_EyesShadow"
FZ_SLOT_MAKEUP_LIPS = "MakeUp_Lips"
FZ_SLOT_MASK = "Mask"
FZ_SLOT_MASK_EYES = "MaskEyes"
FZ_SLOT_MASK_FULL = "MaskFull"
FZ_SLOT_UNDERWEAR = "Underwear"
FZ_SLOT_UNDERWEAR_BOTTOM = "UnderwearBottom"
FZ_SLOT_UNDERWEAR_TOP = "UnderwearTop"
FZ_SLOT_UNDERWEAR_EXTRA1 = "UnderwearExtra1"
FZ_SLOT_UNDERWEAR_EXTRA2 = "UnderwearExtra2"
FZ_SLOT_HAT = "Hat"
FZ_SLOT_FULL_HAT = "FullHat"
FZ_SLOT_EARS = "Ears"
FZ_SLOT_EAR_TOP = "EarTop"
FZ_SLOT_NOSE = "Nose"
FZ_SLOT_TORSO1 = "Torso1"
FZ_SLOT_TORSO_LEGS1 = "Torso1Legs1"
FZ_SLOT_TANK_TOP = "TankTop"
FZ_SLOT_TSHIRT = "Tshirt"
FZ_SLOT_SHORT_SLEEVE_SHIRT = "ShortSleeveShirt"
FZ_SLOT_LEFT_WRIST = "LeftWrist"
FZ_SLOT_RIGHT_WRIST = "RightWrist"
FZ_SLOT_SHIRT = "Shirt"
FZ_SLOT_NECK = "Neck"
FZ_SLOT_NECKLACE = "Necklace"
FZ_SLOT_NECKLACE_LONG = "Necklace_Long"
FZ_SLOT_RIGHT_MIDDLE_FINGER = "Right_MiddleFinger"
FZ_SLOT_LEFT_MIDDLE_FINGER = "Left_MiddleFinger"
FZ_SLOT_LEFT_RING_FINGER = "Left_RingFinger"
FZ_SLOT_RIGHT_RING_FINGER = "Right_RingFinger"
FZ_SLOT_HANDS = "Hands"
FZ_SLOT_HANDS_LEFT = "HandsLeft"
FZ_SLOT_HANDS_RIGHT = "HandsRight"
FZ_SLOT_SOCKS = "Socks"
FZ_SLOT_LEGS1 = "Legs1"
FZ_SLOT_PANTS = "Pants"
FZ_SLOT_SKIRT = "Skirt"
FZ_SLOT_LEGS5 = "Legs5"
FZ_SLOT_DRESS = "Dress"
FZ_SLOT_SWEATER = "Sweater"
FZ_SLOT_SWEATER_HAT = "SweaterHat"
FZ_SLOT_JACKET = "Jacket"
FZ_SLOT_JACKET_DOWN = "Jacket_Down"
FZ_SLOT_JACKET_BULKY = "Jacket_Bulky"
FZ_SLOT_JACKET_HAT = "JacketHat"
FZ_SLOT_JACKET_HAT_BULKY = "JacketHat_Bulky"
FZ_SLOT_JACKET_SUIT = "JacketSuit"
FZ_SLOT_FULL_SUIT = "FullSuit"
FZ_SLOT_BOILDER_SUIT = "Boilersuit"
FZ_SLOT_FULL_SUIT_HEAD = "FullSuitHead"
FZ_SLOT_FULL_TOP = "FullTop"
FZ_SLOT_BATH_ROBE = "BathRobe"
FZ_SLOT_SHOES = "Shoes"
FZ_SLOT_FANNY_PACK_FRONT = "FannyPackFront"
FZ_SLOT_FANNY_PACK_BACK = "FannyPackBack"
FZ_SLOT_AMMO_STRAP = "AmmoStrap"
FZ_SLOT_TORSO_EXTRA = "TorsoExtra"
FZ_SLOT_TORSO_EXTRA_VEST = "TorsoExtraVest"
FZ_SLOT_TAIL = "Tail"
FZ_SLOT_BACK = "Back"
FZ_SLOT_LEFT_EYE = "LeftEye"
FZ_SLOT_RIGHT_EYE = "RightEye"
FZ_SLOT_EYES = "Eyes"
FZ_SLOT_SCARF = "Scarf"
FZ_SLOT_ZED_DMG = "ZedDmg"

FrameworkZ.Characters.DefaultData = {
    [FZ_ENUM_CHARACTER_INFO_FACTION] = "",
    [FZ_ENUM_CHARACTER_INFO_GENDER] = "",
    [FZ_ENUM_CHARACTER_INFO_NAME] = "",
    [FZ_ENUM_CHARACTER_INFO_DESCRIPTION] = "",
    [FZ_ENUM_CHARACTER_INFO_AGE] = -1,
    [FZ_ENUM_CHARACTER_INFO_HEIGHT] = -1,
    [FZ_ENUM_CHARACTER_INFO_WEIGHT] = -1,
    [FZ_ENUM_CHARACTER_INFO_PHYSIQUE] = "",
    [FZ_ENUM_CHARACTER_INFO_EYE_COLOR] = "",
    [FZ_ENUM_CHARACTER_INFO_BEARD_COLOR] = "",
    [FZ_ENUM_CHARACTER_INFO_HAIR_COLOR] = "",
    [FZ_ENUM_CHARACTER_INFO_SKIN_COLOR] = "",
    [FZ_ENUM_CHARACTER_INFO_HAIR_STYLE] = "",
    [FZ_ENUM_CHARACTER_INFO_BEARD_STYLE] = "",
    [FZ_ENUM_CHARACTER_SLOT_BANDAGE] = {},
    [FZ_ENUM_CHARACTER_SLOT_WOUND] = {},
    [FZ_ENUM_CHARACTER_SLOT_BELT_EXTRA] = {},
    [FZ_ENUM_CHARACTER_SLOT_BELT] = {},
    [FZ_ENUM_CHARACTER_SLOT_BELLY_BUTTON] = {},
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_FULL_FACE] = {},
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES] = {},
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES_SHADOW] = {},
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_LIPS] = {},
    [FZ_ENUM_CHARACTER_SLOT_MASK] = {},
    [FZ_ENUM_CHARACTER_SLOT_MASK_EYES] = {},
    [FZ_ENUM_CHARACTER_SLOT_MASK_FULL] = {},
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR] = {},
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_BOTTOM] = {},
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_TOP] = {},
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA1] = {},
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA2] = {},
    [FZ_ENUM_CHARACTER_SLOT_HAT] = {},
    [FZ_ENUM_CHARACTER_SLOT_FULL_HAT] = {},
    [FZ_ENUM_CHARACTER_SLOT_EARS] = {},
    [FZ_ENUM_CHARACTER_SLOT_EAR_TOP] = {},
    [FZ_ENUM_CHARACTER_SLOT_NOSE] = {},
    [FZ_ENUM_CHARACTER_SLOT_TORSO1] = {},
    [FZ_ENUM_CHARACTER_SLOT_TORSO_LEGS1] = {},
    [FZ_ENUM_CHARACTER_SLOT_TANK_TOP] = {},
    [FZ_ENUM_CHARACTER_SLOT_TSHIRT] = {},
    [FZ_ENUM_CHARACTER_SLOT_SHORT_SLEEVE_SHIRT] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEFT_WRIST] = {},
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_WRIST] = {},
    [FZ_ENUM_CHARACTER_SLOT_SHIRT] = {},
    [FZ_ENUM_CHARACTER_SLOT_NECK] = {},
    [FZ_ENUM_CHARACTER_SLOT_NECKLACE] = {},
    [FZ_ENUM_CHARACTER_SLOT_NECKLACE_LONG] = {},
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_MIDDLE_FINGER] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEFT_MIDDLE_FINGER] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEFT_RING_FINGER] = {},
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_RING_FINGER] = {},
    [FZ_ENUM_CHARACTER_SLOT_HANDS] = {},
    [FZ_ENUM_CHARACTER_SLOT_HANDS_LEFT] = {},
    [FZ_ENUM_CHARACTER_SLOT_HANDS_RIGHT] = {},
    [FZ_ENUM_CHARACTER_SLOT_SOCKS] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEGS1] = {},
    [FZ_ENUM_CHARACTER_SLOT_PANTS] = {},
    [FZ_ENUM_CHARACTER_SLOT_SKIRT] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEGS5] = {},
    [FZ_ENUM_CHARACTER_SLOT_DRESS] = {},
    [FZ_ENUM_CHARACTER_SLOT_SWEATER] = {},
    [FZ_ENUM_CHARACTER_SLOT_SWEATER_HAT] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET_DOWN] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET_BULKY] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET_HAT] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET_HAT_BULKY] = {},
    [FZ_ENUM_CHARACTER_SLOT_JACKET_SUIT] = {},
    [FZ_ENUM_CHARACTER_SLOT_FULL_SUIT] = {},
    [FZ_ENUM_CHARACTER_SLOT_BOILDER_SUIT] = {},
    [FZ_ENUM_CHARACTER_SLOT_FULL_SUIT_HEAD] = {},
    [FZ_ENUM_CHARACTER_SLOT_FULL_TOP] = {},
    [FZ_ENUM_CHARACTER_SLOT_BATH_ROBE] = {},
    [FZ_ENUM_CHARACTER_SLOT_SHOES] = {},
    [FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_FRONT] = {},
    [FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_BACK] = {},
    [FZ_ENUM_CHARACTER_SLOT_AMMO_STRAP] = {},
    [FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA] = {},
    [FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA_VEST] = {},
    [FZ_ENUM_CHARACTER_SLOT_TAIL] = {},
    [FZ_ENUM_CHARACTER_SLOT_BACK] = {},
    [FZ_ENUM_CHARACTER_SLOT_LEFT_EYE] = {},
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_EYE] = {},
    [FZ_ENUM_CHARACTER_SLOT_EYES] = {},
    [FZ_ENUM_CHARACTER_SLOT_SCARF] = {},
    [FZ_ENUM_CHARACTER_SLOT_ZED_DMG] = {}
}

FrameworkZ.Characters.SlotList = {
    [FZ_ENUM_CHARACTER_SLOT_BANDAGE] = FZ_SLOT_BANDAGE,
    [FZ_ENUM_CHARACTER_SLOT_WOUND] = FZ_SLOT_WOUND,
    [FZ_ENUM_CHARACTER_SLOT_BELT_EXTRA] = FZ_SLOT_BELT_EXTRA,
    [FZ_ENUM_CHARACTER_SLOT_BELT] = FZ_SLOT_BELT,
    [FZ_ENUM_CHARACTER_SLOT_BELLY_BUTTON] = FZ_SLOT_BELLY_BUTTON,
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_FULL_FACE] = FZ_SLOT_MAKEUP_FULL_FACE,
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES] = FZ_SLOT_MAKEUP_EYES,
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_EYES_SHADOW] = FZ_SLOT_MAKEUP_EYES_SHADOW,
    [FZ_ENUM_CHARACTER_SLOT_MAKEUP_LIPS] = FZ_SLOT_MAKEUP_LIPS,
    [FZ_ENUM_CHARACTER_SLOT_MASK] = FZ_SLOT_MASK,
    [FZ_ENUM_CHARACTER_SLOT_MASK_EYES] = FZ_SLOT_MASK_EYES,
    [FZ_ENUM_CHARACTER_SLOT_MASK_FULL] = FZ_SLOT_MASK_FULL,
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR] = FZ_SLOT_UNDERWEAR,
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_BOTTOM] = FZ_SLOT_UNDERWEAR_BOTTOM,
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_TOP] = FZ_SLOT_UNDERWEAR_TOP,
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA1] = FZ_SLOT_UNDERWEAR_EXTRA1,
    [FZ_ENUM_CHARACTER_SLOT_UNDERWEAR_EXTRA2] = FZ_SLOT_UNDERWEAR_EXTRA2,
    [FZ_ENUM_CHARACTER_SLOT_HAT] = FZ_SLOT_HAT,
    [FZ_ENUM_CHARACTER_SLOT_FULL_HAT] = FZ_SLOT_FULL_HAT,
    [FZ_ENUM_CHARACTER_SLOT_EARS] = FZ_SLOT_EARS,
    [FZ_ENUM_CHARACTER_SLOT_EAR_TOP] = FZ_SLOT_EAR_TOP,
    [FZ_ENUM_CHARACTER_SLOT_NOSE] = FZ_SLOT_NOSE,
    [FZ_ENUM_CHARACTER_SLOT_TORSO1] = FZ_SLOT_TORSO1,
    [FZ_ENUM_CHARACTER_SLOT_TORSO_LEGS1] = FZ_SLOT_TORSO_LEGS1,
    [FZ_ENUM_CHARACTER_SLOT_TANK_TOP] = FZ_SLOT_TANK_TOP,
    [FZ_ENUM_CHARACTER_SLOT_TSHIRT] = FZ_SLOT_TSHIRT,
    [FZ_ENUM_CHARACTER_SLOT_SHORT_SLEEVE_SHIRT] = FZ_SLOT_SHORT_SLEEVE_SHIRT,
    [FZ_ENUM_CHARACTER_SLOT_LEFT_WRIST] = FZ_SLOT_LEFT_WRIST,
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_WRIST] = FZ_SLOT_RIGHT_WRIST,
    [FZ_ENUM_CHARACTER_SLOT_SHIRT] = FZ_SLOT_SHIRT,
    [FZ_ENUM_CHARACTER_SLOT_NECK] = FZ_SLOT_NECK,
    [FZ_ENUM_CHARACTER_SLOT_NECKLACE] = FZ_SLOT_NECKLACE,
    [FZ_ENUM_CHARACTER_SLOT_NECKLACE_LONG] = FZ_SLOT_NECKLACE_LONG,
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_MIDDLE_FINGER] = FZ_SLOT_RIGHT_MIDDLE_FINGER,
    [FZ_ENUM_CHARACTER_SLOT_LEFT_MIDDLE_FINGER] = FZ_SLOT_LEFT_MIDDLE_FINGER,
    [FZ_ENUM_CHARACTER_SLOT_LEFT_RING_FINGER] = FZ_SLOT_LEFT_RING_FINGER,
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_RING_FINGER] = FZ_SLOT_RIGHT_RING_FINGER,
    [FZ_ENUM_CHARACTER_SLOT_HANDS] = FZ_SLOT_HANDS,
    [FZ_ENUM_CHARACTER_SLOT_HANDS_LEFT] = FZ_SLOT_HANDS_LEFT,
    [FZ_ENUM_CHARACTER_SLOT_HANDS_RIGHT] = FZ_SLOT_HANDS_RIGHT,
    [FZ_ENUM_CHARACTER_SLOT_SOCKS] = FZ_SLOT_SOCKS,
    [FZ_ENUM_CHARACTER_SLOT_LEGS1] = FZ_SLOT_LEGS1,
    [FZ_ENUM_CHARACTER_SLOT_PANTS] = FZ_SLOT_PANTS,
    [FZ_ENUM_CHARACTER_SLOT_SKIRT] = FZ_SLOT_SKIRT,
    [FZ_ENUM_CHARACTER_SLOT_LEGS5] = FZ_SLOT_LEGS5,
    [FZ_ENUM_CHARACTER_SLOT_DRESS] = FZ_SLOT_DRESS,
    [FZ_ENUM_CHARACTER_SLOT_SWEATER] = FZ_SLOT_SWEATER,
    [FZ_ENUM_CHARACTER_SLOT_SWEATER_HAT] = FZ_SLOT_SWEATER_HAT,
    [FZ_ENUM_CHARACTER_SLOT_JACKET] = FZ_SLOT_JACKET,
    [FZ_ENUM_CHARACTER_SLOT_JACKET_DOWN] = FZ_SLOT_JACKET_DOWN,
    [FZ_ENUM_CHARACTER_SLOT_JACKET_BULKY] = FZ_SLOT_JACKET_BULKY,
    [FZ_ENUM_CHARACTER_SLOT_JACKET_HAT] = FZ_SLOT_JACKET_HAT,
    [FZ_ENUM_CHARACTER_SLOT_JACKET_HAT_BULKY] = FZ_SLOT_JACKET_HAT_BULKY,
    [FZ_ENUM_CHARACTER_SLOT_JACKET_SUIT] = FZ_SLOT_JACKET_SUIT,
    [FZ_ENUM_CHARACTER_SLOT_FULL_SUIT] = FZ_SLOT_FULL_SUIT,
    [FZ_ENUM_CHARACTER_SLOT_BOILDER_SUIT] = FZ_SLOT_BOILDER_SUIT,
    [FZ_ENUM_CHARACTER_SLOT_FULL_SUIT_HEAD] = FZ_SLOT_FULL_SUIT_HEAD,
    [FZ_ENUM_CHARACTER_SLOT_FULL_TOP] = FZ_SLOT_FULL_TOP,
    [FZ_ENUM_CHARACTER_SLOT_BATH_ROBE] = FZ_SLOT_BATH_ROBE,
    [FZ_ENUM_CHARACTER_SLOT_SHOES] = FZ_SLOT_SHOES,
    [FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_FRONT] = FZ_SLOT_FANNY_PACK_FRONT,
    [FZ_ENUM_CHARACTER_SLOT_FANNY_PACK_BACK] = FZ_SLOT_FANNY_PACK_BACK,
    [FZ_ENUM_CHARACTER_SLOT_AMMO_STRAP] = FZ_SLOT_AMMO_STRAP,
    [FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA] = FZ_SLOT_TORSO_EXTRA,
    [FZ_ENUM_CHARACTER_SLOT_TORSO_EXTRA_VEST] = FZ_SLOT_TORSO_EXTRA_VEST,
    [FZ_ENUM_CHARACTER_SLOT_TAIL] = FZ_SLOT_TAIL,
    [FZ_ENUM_CHARACTER_SLOT_BACK] = FZ_SLOT_BACK,
    [FZ_ENUM_CHARACTER_SLOT_LEFT_EYE] = FZ_SLOT_LEFT_EYE,
    [FZ_ENUM_CHARACTER_SLOT_RIGHT_EYE] = FZ_SLOT_RIGHT_EYE,
    [FZ_ENUM_CHARACTER_SLOT_EYES] = FZ_SLOT_EYES,
    [FZ_ENUM_CHARACTER_SLOT_SCARF] = FZ_SLOT_SCARF,
    [FZ_ENUM_CHARACTER_SLOT_ZED_DMG] = FZ_SLOT_ZED_DMG
}

FrameworkZ.Characters.List = {}

--! \brief Unique IDs list for characters.
FrameworkZ.Characters.UIDs = {}

--! \brief Deprecated. To be removed.
FrameworkZ.Characters.EquipmentSlots = {
    EQUIPMENT_SLOT_HEAD,
    EQUIPMENT_SLOT_FACE,
    EQUIPMENT_SLOT_EARS,
    EQUIPMENT_SLOT_BACKPACK,
    EQUIPMENT_SLOT_GLOVES,
    EQUIPMENT_SLOT_UNDERSHIRT,
    EQUIPMENT_SLOT_OVERSHIRT,
    EQUIPMENT_SLOT_VEST,
    EQUIPMENT_SLOT_BELT,
    EQUIPMENT_SLOT_PANTS,
    EQUIPMENT_SLOT_SOCKS,
    EQUIPMENT_SLOT_SHOES
}
FrameworkZ.Characters = FrameworkZ.Foundation:NewModule(FrameworkZ.Characters, "Characters")

--! \brief Character class for FrameworkZ.
--! \class CHARACTER
local CHARACTER = {}
CHARACTER.__index = CHARACTER

--! \brief Initialize a character.
--! \return \string username
function CHARACTER:Initialize()
	if not self.isoPlayer then return end

    local firstConnection = false
    local characterModData = self.isoPlayer:getModData()["FZ_CHAR"] or nil

    if not self.inventory then
        local inventory = FrameworkZ.Inventories:New(self.isoPlayer:getUsername())
        self.inventoryID = inventory:Initialize()
        self.inventory = inventory
    end

    if not characterModData then
        firstConnection = true

        self.isoPlayer:getModData()["FZ_CHAR"] = {
            id = self.id or -1,
            name = self.name or "Unknown",
            description = self.description or "No description available.",
            faction = self.faction or FACTION_CITIZEN,
            age = self.age or 20,
            height = self.height or 70,
            eyeColor = self.eyeColor or "Brown",
            hairColor = self.hairColor or "Brown",
            skinColor = self.skinColor or "White",
            physique = self.physique or "Average",
            weight = self.weight or "125",
            inventory = self.inventory or {},
            recognizes = self.recognizes or {},
            upgrades = {}
        }

        if isClient() then
            self.isoPlayer:transmitModData()
        end
    end

    if firstConnection then
        self:InitializeDefaultItems()
    end

    --self:ValidateCharacterData()

    --[[
	if isClient() then
        FrameworkZ.Timers:Simple(5, function()
            sendClientCommand("FZ_CHAR", "initialize", {self.isoPlayer:getUsername()})
        end)
    end
	--]]

    return FrameworkZ.Characters:Initialize(self.username, self)
end

--! \brief Save the character's data from the character object.
--! \param shouldTransmit \boolean (Optional) Whether or not to transmit the character's data to the server.
--! \return \boolean Whether or not the character was successfully saved.
function CHARACTER:Save(shouldTransmit)
    if shouldTransmit == nil then shouldTransmit = true end

    local player = FrameworkZ.Players:GetPlayerByID(self.isoPlayer:getUsername())
    local characterData = FrameworkZ.Players:GetCharacterDataByID(self.isoPlayer:getUsername(), self.id)

    if not player or not characterData then return false end
    FrameworkZ.Players:ResetCharacterSaveInterval()

    -- Save "physical" character inventory
    local inventory = self.isoPlayer:getInventory():getItems()
    characterData.INVENTORY_PHYSICAL = {}
    for i = 0, inventory:size() - 1 do
        table.insert(characterData.INVENTORY_PHYSICAL, {id = inventory:get(i):getFullType()})
    end

    -- Save logical character inventory
    characterData.INVENTORY_LOGICAL = self.inventory.items

    -- Save character equipment
    characterData.EQUIPMENT_SLOT_HEAD = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_HEAD) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_HEAD):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_FACE = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_FACE) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_FACE):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_EARS = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_EARS) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_EARS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_BACKPACK = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_BACKPACK) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_BACKPACK):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_GLOVES = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_GLOVES) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_GLOVES):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_UNDERSHIRT = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_UNDERSHIRT) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_UNDERSHIRT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_OVERSHIRT = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_OVERSHIRT) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_OVERSHIRT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_VEST = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_VEST) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_VEST):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_BELT = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_BELT) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_BELT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_PANTS = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_PANTS) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_PANTS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_SOCKS = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_SOCKS) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_SOCKS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_SHOES = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_SHOES) and {id = self.isoPlayer:getWornItem(EQUIPMENT_SLOT_SHOES):getFullType()} or nil

    -- Save character position/direction angle
    characterData.POSITION_X = self.isoPlayer:getX()
    characterData.POSITION_Y = self.isoPlayer:getY()
    characterData.POSITION_Z = self.isoPlayer:getZ()
    characterData.DIRECTION_ANGLE = self.isoPlayer:getDirectionAngle()

    local getStats = self.isoPlayer:getStats()
    characterData.STAT_HUNGER = getStats:getHunger()
    characterData.STAT_THIRST = getStats:getThirst()
    characterData.STAT_FATIGUE = getStats:getFatigue()
    characterData.STAT_STRESS = getStats:getStress()
    characterData.STAT_PAIN = getStats:getPain()
    characterData.STAT_PANIC = getStats:getPanic()
    characterData.STAT_BOREDOM = getStats:getBoredom()
    --characterData.STAT_UNHAPPINESS = getStats:getUnhappyness()
    characterData.STAT_DRUNKENNESS = getStats:getDrunkenness()
    characterData.STAT_ENDURANCE = getStats:getEndurance()
    --characterData.STAT_TIREDNESS = getStats:getTiredness()

    --[[
    modData.status.health = character:getBodyDamage():getOverallBodyHealth()
    modData.status.injuries = character:getBodyDamage():getInjurySeverity()
    modData.status.hyperthermia = character:getBodyDamage():getTemperature()
    modData.status.hypothermia = character:getBodyDamage():getColdStrength()
    modData.status.wetness = character:getBodyDamage():getWetness()
    modData.status.hasCold = character:getBodyDamage():HasACold()
    modData.status.sick = character:getBodyDamage():getSicknessLevel()
    --]]

    player.Characters[self.id] = characterData

    if isClient() and shouldTransmit == true then
        self.isoPlayer:transmitModData()
    end

    return true
end

--! \brief Destroy a character. This will remove the character from the list of characters and is usually called after a player has disconnected.
function CHARACTER:Destroy()
    --[[
	if isClient() then
        sendClientCommand("FZ_CHAR", "destroy", {self.isoPlayer:getUsername()})
    end
	--]]
    
    self.isoPlayer = nil
end

--! \brief Initialize the default items for a character based on their faction. Called when FZ_CHAR mod data is first created.
function CHARACTER:InitializeDefaultItems()
    local faction = FrameworkZ.Factions:GetFactionByID(self.faction)

    if faction then
        for k, v in pairs(faction.defaultItems) do
           self:GiveItems(k, v)
        end
    end
end

--! \brief Validate the character's data.
--! \return \boolean Whether or not any of the character's new data was initialized.
function CHARACTER:ValidateCharacterData()
    local characterModData = self.isoPlayer:getModData()["FZ_CHAR"]

    if not characterModData then return false end

    local initializedNewData = false

    if not characterModData.name then
        initializedNewData = true
        characterModData.name = self.name or "Unknown"
    end

    if not characterModData.description then
        initializedNewData = true
        characterModData.description = self.description or "No description available."
    end

    if not characterModData.faction then
        initializedNewData = true
        characterModData.faction = self.faction or FACTION_CITIZEN
    end

    if not characterModData.age then
        initializedNewData = true
        characterModData.age = self.age or 20
    end

    if not characterModData.heightFeet then
        initializedNewData = true
        characterModData.heightFeet = self.heightFeet or 5
    end

    if not characterModData.heightInches then
        initializedNewData = true
        characterModData.heightInches = self.heightInches or 10
    end

    if not characterModData.eyeColor then
        initializedNewData = true
        characterModData.eyeColor = self.eyeColor or "Brown"
    end

    if not characterModData.hairColor then
        initializedNewData = true
        characterModData.hairColor = self.hairColor or "Brown"
    end

    if not characterModData.physique then
        initializedNewData = true
        characterModData.physique = self.physique or "Average"
    end

    if not characterModData.weight then
        initializedNewData = true
        characterModData.weight = self.weight or "125"
    end

    if not characterModData.inventory then
        initializedNewData = true
        characterModData.inventory = self.inventory or {}
    end

    if not characterModData.upgrades then
        initializedNewData = true
        characterModData.upgrades = {}
    end

    if not characterModData.recognizes then
        initializedNewData = true
        characterModData.recognizes = {}
    end

    if isClient() then
        self.isoPlayer:transmitModData()
    end

    self.name = characterModData.name
    self.description = characterModData.description
    self.faction = characterModData.faction
    self.age = characterModData.age
    self.heightFeet = characterModData.heightFeet
    self.heightInches = characterModData.heightInches
    self.eyeColor = characterModData.eyeColor
    self.hairColor = characterModData.hairColor
    self.physique = characterModData.physique
    self.upgrades = characterModData.upgrades
    self.recognizes = characterModData.recognizes

    return initializedNewData
end

function CHARACTER:GetFaction()
    return self.faction
end

function CHARACTER:GetIsoPlayer()
    return self.isoPlayer
end

function CHARACTER:GetSaveableData()
    return FrameworkZ.Foundation:ProcessSaveableData(self, {"isoPlayer"}, {"inventory"})
end

--! \brief Set the age of the character.
--! \param age \integer The age of the character.
function CHARACTER:SetAge(age)
    self.age = age
    self.isoPlayer:getModData()["FZ_CHAR"].age = age
    self.isoPlayer:transmitModData()

    --[[if isClient() then
        sendClientCommand("FZ_CHAR", "update", {self.isoPlayer:getUsername(), "age", age})
    end--]]
end

--! \brief Set the faction of the character.
--! \param faction \string The ID of the faction to set on the character.
function CHARACTER:SetFaction(faction)
    self.faction = faction
    self.isoPlayer:getModData()["FZ_CHAR"].faction = faction
    self.isoPlayer:transmitModData()
    
    --[[
	if isClient() then
        sendClientCommand("FZ_CHAR", "update", {self.isoPlayer:getUsername(), "faction", faction})
    end
	--]]
end

function CHARACTER:GetName()
    return self.name
end

--! \brief Set the name of the character.
--! \param name \string The new name for the character.
function CHARACTER:SetName(name)
    self.name = name
    self.isoPlayer:getModData()["FZ_CHAR"].name = name
    self.isoPlayer:transmitModData()
    
	--[[
    if isClient() then
        sendClientCommand("FZ_CHAR", "update", {self.isoPlayer:getUsername(), "name", name})
    end
	--]]
end

function CHARACTER:GetDescription()
    return self.description
end

--! \brief Set the description of the character.
--! \param description \string The description of the character's appearance.
function CHARACTER:SetDescription(description)
    self.description = description
    self.isoPlayer:getModData()["FZ_CHAR"].description = description
    self.isoPlayer:transmitModData()

    --[[
	if isClient() then
        sendClientCommand("FZ_CHAR", "update", {self.isoPlayer:getUsername(), "description", description})
    end
	--]]
end

function CHARACTER:GetID()
    return self.id
end

function CHARACTER:GetUID()
    return self.uid
end

--! \brief Get the character's inventory object.
--! \return \table The character's inventory object.
function CHARACTER:GetInventory()
    return FrameworkZ.Inventories:GetInventoryByID(self.inventoryID)
end

--! \brief Give a character items by the specified amount.
--! \param itemID \string The ID of the item to give.
--! \param amount \integer The amount of the item to give.
function CHARACTER:GiveItems(uniqueID, amount)
    for i = 1, amount do
        self:GiveItem(uniqueID)
    end
end

function CHARACTER:TakeItems(uniqueID, amount)
    for i = 1, amount do
        self:TakeItem(uniqueID)
    end
end

--! \brief Give a character an item.
--! \param uniqueID \string The ID of the item to give.
--! \return \boolean Whether or not the item was successfully given.
function CHARACTER:GiveItem(uniqueID)
    local inventory = self:GetInventory()
    if not inventory then return false, "Failed to find inventory." end
    local instance, message = FrameworkZ.Items:CreateItem(uniqueID, self.isoPlayer)
    if not instance then return false, "Failed to create item: " .. message end

    inventory:AddItem(instance)

    return instance, message
end

--! \brief Take an item from a character's inventory.
--! \param uniqueID \string The unique ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItem(uniqueID)
    local success, message = FrameworkZ.Items:RemoveItemInstanceByUniqueID(self.isoPlayer:getUsername(), uniqueID)

    if success then
        return true, "Successfully took " .. uniqueID .. "."
    end

    return false, message
end

--! \brief Take an item from a character's inventory by its instance ID. Useful for taking a specific item from a stack.
--! \param instanceID \integer The instance ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItemByInstanceID(instanceID)
    local success, message = FrameworkZ.Items:RemoveInstance(instanceID, self.isoPlayer:getUsername())

    if success then
        return true, "Successfully took item with instance ID " .. instanceID .. "."
    end

    return false, "Failed to find item with instance ID " .. instanceID .. ": " .. message
end

--! \brief Checks if a character is a citizen.
--! \return \boolean Whether or not the character is a citizen.
function CHARACTER:IsCitizen()
    if not self.faction then return false end

    if self.faction == FACTION_CITIZEN then
        return true
    end
    
    return false
end

--! \brief Checks if a character is a combine.
--! \return \boolean Whether or not the character is a combine.
function CHARACTER:IsCombine()
    if not self.faction then return false end

    if self.faction == FACTION_CP then
        return true
    elseif self.faction == FACTION_OTA then
        return true
    elseif self.faction == FACTION_ADMINISTRATOR then
        return true
    end

    return false
end

function CHARACTER:RecognizesCharacter(character)
    if not character then return false, "Character not supplied in parameters." end

    if self.recognizes[character.username] then
        return true
    end

    return false
end

--! \brief Create a new character object.
--! \param username \string The player's username as their ID.
--! \param id \integer The character's ID from the player stored data.
--! \param data \table (Optional) The character's data stored on the object.
--! \return \table The new character object.
function FrameworkZ.Characters:New(username, id, data)
    if not username then return false end

    local object

    if not data then
        object = {
            username = username,
            id = id or -1
        }
    else
        object = data
        object.username = username
        object.id = id or -1
    end

    setmetatable(object, CHARACTER)

	return object
end

--! \brief Initialize a character.
--! \param username \string The player's username.
--! \param character \table The character's object data.
--! \return \string The username added to the list of characters.
function FrameworkZ.Characters:Initialize(username, character)
    self.List[username] = character

    return username
end

--! \brief Gets the user's loaded character by their ID.
--! \param username \string The player's username to get their character object with.
--! \return \table The character object from the list of characters.
function FrameworkZ.Characters:GetCharacterByID(username)
    local character = self.List[username] or nil

    return character
end

function FrameworkZ.Characters:GetCharacterInventoryByID(username)
    local character = self:GetCharacterByID(username)

    if character then
        return character:GetInventory()
    end

    return nil
end

--! \brief Saves the user's currently loaded character.
--! \param username \string The player's username to get their loaded character from.
--! \return \boolean Whether or not the character was successfully saved.
function FrameworkZ.Characters:Save(username)
    if not username then return false end

    local character = self:GetCharacterByID(username)

    if character then
        return character:Save()
    end

    return false
end

function CHARACTER:OnPreLoad()
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPreLoad", self)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterPreLoad")

function CHARACTER:OnLoad()
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterLoad", self)
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterLoad")

function CHARACTER:OnPostLoad(firstLoad)
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostLoad", self, firstLoad)

    if firstLoad then
        FrameworkZ.Characters:SetupUID(self:GetIsoPlayer(), self.id)
    end
end
FrameworkZ.Foundation:AddAllHookHandlers("OnCharacterPostLoad")

function FrameworkZ.Characters.PostLoad(data, characterData)
    return FrameworkZ.Characters:OnPostLoad(data.isoPlayer, characterData)
end
FrameworkZ.Foundation:Subscribe("FrameworkZ.Characters.PostLoad", FrameworkZ.Characters.PostLoad)

--! \brief Initializes a player's character after loading.
--! \return \boolean Whether or not the post load was successful.
function FrameworkZ.Characters:OnPostLoad(isoPlayer, characterData)
    local username = isoPlayer:getUsername()
    local player = FrameworkZ.Players:GetPlayerByID(username)
    local character = FrameworkZ.Characters:New(username, characterData.META_ID)

    if not player or not character then return false end

    character:OnPreLoad()

    character.isoPlayer = isoPlayer
    character.name = characterData.INFO_NAME
    character.description = characterData.INFO_DESCRIPTION
    character.faction = characterData.INFO_FACTION
    character.age = characterData.INFO_AGE
    character.heightInches = characterData.INFO_HEIGHT
    character.eyeColor = characterData.INFO_EYE_COLOR
    character.hairColor = characterData.INFO_HAIR_STYLE
    character.skinColor = characterData.INFO_SKIN_COLOR
    character.physique = characterData.INFO_PHYSIQUE
    character.weight = characterData.INFO_WEIGHT
    character.recognizes = {}

    local newInventory = FrameworkZ.Inventories:New(username)
    local _success, _message, rebuiltInventory = FrameworkZ.Inventories:Rebuild(isoPlayer, newInventory, characterData.INVENTORY_LOGICAL or nil)
    character.inventory = rebuiltInventory or nil

    if character.inventory then
        character.inventoryID = character.inventory.id
        character.inventory:Initialize()
    end

    character:Initialize()
    character:OnLoad()

    player.loadedCharacter = character

    return character
end

if isServer() then
    function FrameworkZ.Characters.GenerateUID(data, characterID)
        local username = data.isoPlayer:getUsername()
        local player = FrameworkZ.Players:GetPlayerByID(username)
        local character = player and player:GetCharacter()
        local characterData = player and player:GetCharacterByID(characterID)

        if player and character and characterData and character.id == characterData.META_ID then
            FrameworkZ.Characters.UIDs[username] = FrameworkZ.Characters.UIDs[username] or {}

            local uid = username .. "_" .. FrameworkZ.Utilities:GetRandomNumber(1, 999999, true)

            while FrameworkZ.Characters.UIDs[username][uid] do
                uid = username .. "_" ..  FrameworkZ.Utilities:GetRandomNumber(1, 999999, true)
            end

            character.uid = uid
            player.Characters[character.id].META_UID = uid

            FrameworkZ.Characters.UIDs[username][uid] = true
            ModData.add("FZ_CHAR_UIDS", FrameworkZ.Characters.UIDs)

            return characterData.META_ID, uid
        end

        return false
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.Characters.GenerateUID", FrameworkZ.Characters.GenerateUID)
end

function FrameworkZ.Characters:OnInitGlobalModData()
    self.UIDs = ModData.getOrCreate("FZ_CHAR_UIDS")
end

function FrameworkZ.Characters:SetupUID(isoPlayer, characterID)
    if not isoPlayer then return false end
    local username = isoPlayer:getUsername()

    FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Characters.GenerateUID", function(data, checkedCharacterID, uid)
        local player = FrameworkZ.Players:GetPlayerByID(username)
        local character = player and player:GetCharacter()

        if player and character and character.id == checkedCharacterID then
            FrameworkZ.Characters.UIDs[username] = FrameworkZ.Characters.UIDs[username] or {}

            character.uid = uid
            player.Characters[character.id].META_UID = uid
            FrameworkZ.Characters.UIDs[username][uid] = true

            FrameworkZ.Notifications:AddToQueue("Character UID has been set to: " .. uid, FrameworkZ.Notifications.Types.Info)
        else
            FrameworkZ.Notifications:AddToQueue("Failed to setup character UID. Player switched character or potential issues(!).", FrameworkZ.Notifications.Types.Warning)
        end
    end, characterID)
end

if isClient() then

    local showingTooltip = false
    local previousMouseX = 0
    local previousMouseY = 0
    local tooltipX = 0
    local tooltipY = 0
    local tooltipPlayer = nil
    local tooltip = {name = "", description = {}}

    function FrameworkZ.Characters:GetDescriptionLines(description)
        local lines = {}
        local line = ""
        local lineLength = 0
        local words = {}

        for word in string.gmatch(description, "%S+") do
            table.insert(words, word)
        end

        for i = 1, #words do
            local word = words[i]
            local wordLength = string.len(word)

            if lineLength + wordLength <= 30 then
                line = line .. " " .. word
                lineLength = lineLength + wordLength
            else
                table.insert(lines, line)
                line = word
                lineLength = wordLength
            end
        end

        table.insert(lines, line)

        return lines
    end

    function FrameworkZ.Characters.OnPreUIDraw()
        if tooltip then
            local y = tooltipY + getTextManager():getFontFromEnum(UIFont.Dialogue):getLineHeight()
            
            getTextManager():DrawStringCentre(UIFont.Dialogue, tooltipX, y, tooltip.name, 0.6, 0.5, 0.4, 0.75)

            for k, v in pairs(tooltip.description) do
                y = y + getTextManager():getFontFromEnum(UIFont.Dialogue):getLineHeight()
                getTextManager():DrawStringCentre(UIFont.Dialogue, tooltipX, y, v, 1, 1, 1, 0.75)
            end
        end
    end

    local currentSaveTick = 0

    function FrameworkZ.Characters:PlayerTick(isoPlayer)
        local x = getMouseX()
        local y = getMouseY()

        if x ~= previousMouseX or y ~= previousMouseY then
            Events.OnPreUIDraw.Remove(FrameworkZ.Characters.OnPreUIDraw)

            showingTooltip = false
            tooltipPlayer = nil
            previousMouseX = x
            previousMouseY = y
        elseif showingTooltip == false then
            showingTooltip = true

            if isoPlayer then
                local playerIndex = isoPlayer:getPlayerNum()
                local worldX = screenToIsoX(playerIndex, x, y, 0)
                local worldY = screenToIsoY(playerIndex, x, y, 0)
                local worldZ = isoPlayer:getZ()
                local square = getSquare(worldX, worldY, worldZ)

                if square then
                    local playerOnSquare = square:getPlayer()

                    if playerOnSquare then
                        local playerOnSquareIndex = playerOnSquare:getPlayerNum()
                        tooltipX = isoToScreenX(playerOnSquareIndex, worldX, worldY, worldZ)
                        tooltipY = isoToScreenY(playerOnSquareIndex, worldX, worldY, worldZ)

                        tooltipPlayer = playerOnSquare
                        local character = FrameworkZ.Characters:GetCharacterByID(playerOnSquare:getUsername())
                        tooltip.name = character and character.name or "Invalid Character"
                        tooltip.description = FrameworkZ.Characters:GetDescriptionLines(character and character.description or "Invalid Description")


                        if tooltip then
                            Events.OnPreUIDraw.Add(FrameworkZ.Characters.OnPreUIDraw)
                        end
                    end
                end
            end
        elseif showingTooltip == true then
            if isoPlayer then
                local playerIndex = isoPlayer:getPlayerNum()
                local worldX = screenToIsoX(playerIndex, x, y, 0)
                local worldY = screenToIsoY(playerIndex, x, y, 0)
                local worldZ = isoPlayer:getZ()
                local square = getSquare(worldX, worldY, worldZ)

                if square then
                    local playerOnSquare = square:getPlayer()

                    if playerOnSquare ~= tooltipPlayer then
                        Events.OnPreUIDraw.Remove(FrameworkZ.Characters.OnPreUIDraw)
                        showingTooltip = false
                        tooltipPlayer = nil
                    end
                end
            end
        end

        if currentSaveTick >= FrameworkZ.Config.Options.TicksUntilCharacterSave then
            local success, message = FrameworkZ.Players:Save(isoPlayer:getUsername())

            if success then
                if FrameworkZ.Config.Options.ShouldNotifyOnCharacterSave then
                    FrameworkZ.Notifications:AddToQueue("Saved player and character data.", FrameworkZ.Notifications.Types.Success)
                end
            else
                FrameworkZ.Notifications:AddToQueue(message, FrameworkZ.Notifications.Types.Danger)
            end

            currentSaveTick = 0
        end

        currentSaveTick = currentSaveTick + 1
    end
end

if isServer() then

    --! \brief Initialize a character called by OnServerStarted event hook.
    --! \param module \string
    --! \param command \string
    --! \param player \table Player object.
    --! \param args \string
    --[[function FrameworkZ.Characters.OnClientCommand(module, command, player, args)
        if module == "FZ_CHAR" then
            if command == "initialize" then
                local username = args[1]
                local character = FrameworkZ.Characters:New(username)

                character.isoPlayer = player
                character:Initialize()
            elseif command == "destroy" then
                local username = args[1]
                local character = FrameworkZ.Characters:GetCharacterByID(username)

                if character then
                    character:Destroy()
                end

                FrameworkZ.Characters.List[username] = nil
            elseif command == "update" then
                local username = args[1]
                local field = args[2]
                local newData = args[3]

                FrameworkZ.Characters.List[username][field] = newData
            end
        end
    end
    Events.OnClientCommand.Add(FrameworkZ.Characters.OnClientCommand)--]]
end

FrameworkZ.Characters.MetaObject = CHARACTER

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Characters)
