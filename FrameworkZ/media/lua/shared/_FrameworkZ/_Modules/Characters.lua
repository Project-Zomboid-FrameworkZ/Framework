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

local getCell = getCell
local getMouseX = getMouseX
local getMouseY = getMouseY
local getSquare = getSquare
local getTextManager = getTextManager
local instanceof = instanceof
local isClient = isClient
local isoToScreenX = isoToScreenX
local isoToScreenY = isoToScreenY
local screenToIsoX = screenToIsoX
local screenToIsoY = screenToIsoY

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
FrameworkZ.Characters.Cache = {}

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

--! \brief Save the character's data from the character object.
--! \param shouldTransmit \boolean (Optional) Whether or not to transmit the character's data to the server.
--! \return \boolean Whether or not the character was successfully saved.
function CHARACTER:Save(shouldTransmit)
    if shouldTransmit == nil then shouldTransmit = true end

    local player = FrameworkZ.Players:GetPlayerByID(self:GetIsoPlayer():getUsername())
    local characterData = FrameworkZ.Players:GetCharacterDataByID(self:GetIsoPlayer():getUsername(), self.id)

    if not player or not characterData then return false end
    FrameworkZ.Players:ResetCharacterSaveInterval()

    -- Save "physical" character inventory
    local inventory = self:GetIsoPlayer():getInventory():getItems()
    characterData.INVENTORY_PHYSICAL = {}
    for i = 0, inventory:size() - 1 do
        table.insert(characterData.INVENTORY_PHYSICAL, {id = inventory:get(i):getFullType()})
    end

    -- Save logical character inventory
    characterData.INVENTORY_LOGICAL = self.inventory.items

    -- Save character equipment
    characterData.EQUIPMENT_SLOT_HEAD = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_HEAD) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_HEAD):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_FACE = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_FACE) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_FACE):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_EARS = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_EARS) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_EARS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_BACKPACK = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_BACKPACK) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_BACKPACK):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_GLOVES = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_GLOVES) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_GLOVES):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_UNDERSHIRT = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_UNDERSHIRT) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_UNDERSHIRT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_OVERSHIRT = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_OVERSHIRT) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_OVERSHIRT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_VEST = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_VEST) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_VEST):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_BELT = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_BELT) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_BELT):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_PANTS = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_PANTS) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_PANTS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_SOCKS = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_SOCKS) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_SOCKS):getFullType()} or nil
    characterData.EQUIPMENT_SLOT_SHOES = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_SHOES) and {id = self:GetIsoPlayer():getWornItem(EQUIPMENT_SLOT_SHOES):getFullType()} or nil

    -- Save character position/direction angle
    characterData.POSITION_X = self:GetIsoPlayer():getX()
    characterData.POSITION_Y = self:GetIsoPlayer():getY()
    characterData.POSITION_Z = self:GetIsoPlayer():getZ()
    characterData.DIRECTION_ANGLE = self:GetIsoPlayer():getDirectionAngle()

    local getStats = self:GetIsoPlayer():getStats()
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
        self:GetIsoPlayer():transmitModData()
    end

    return true
end

--! \brief Destroy a character. This will remove the character from the list of characters and is usually called after a player has disconnected.
function CHARACTER:Destroy()
    --[[
	if isClient() then
        sendClientCommand("FZ_CHAR", "destroy", {self:GetIsoPlayer():getUsername()})
    end
	--]]

    self.IsoPlayer = nil
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

function CHARACTER:GetAge() return self.Age end
function CHARACTER:SetAge(age) self.Age = age end

function CHARACTER:GetBeardColor() return self.BeardColor end
function CHARACTER:SetBeardColor(beardColor) self.BeardColor = beardColor end

function CHARACTER:GetBeardStyle() return self.BeardStyle end
function CHARACTER:SetBeardStyle(beardStyle) self.BeardStyle = beardStyle end

function CHARACTER:GetDescription() return self.Description end
function CHARACTER:SetDescription(description) self.Description = description end

function CHARACTER:GetEyeColor() return self.EyeColor end
function CHARACTER:SetEyeColor(eyeColor) self.EyeColor = eyeColor end

function CHARACTER:GetFaction() return self.Faction end
function CHARACTER:SetFaction(faction) self.Faction = faction end

function CHARACTER:GetHairColor() return self.HairColor end
function CHARACTER:SetHairColor(hairColor) self.HairColor = hairColor end

function CHARACTER:GetHairStyle() return self.HairStyle end
function CHARACTER:SetHairStyle(hairStyle) self.HairStyle = hairStyle end

function CHARACTER:GetHeight() return self.Height end
function CHARACTER:SetHeight(height) self.Height = height end

function CHARACTER:GetID() return self.ID end
function CHARACTER:SetID(id) self.ID = id end

function CHARACTER:GetInventory() return self.Inventory end
function CHARACTER:SetInventory(inventory) self.Inventory = inventory end

function CHARACTER:GetIsoPlayer() return self.IsoPlayer end
function CHARACTER:SetIsoPlayer(isoPlayer) print("Failed to set IsoPlayer object to '" .. tostring(isoPlayer) .. "'. IsoPlayer is read-only and must be set upon object creation.") end

function CHARACTER:GetLogicalInventory() return self.LogicalInventory end
function CHARACTER:SetLogicalInventory(logicalInventory) self.LogicalInventory = logicalInventory end

function CHARACTER:GetName() return self.Name end
function CHARACTER:SetName(name) self.Name = name end

function CHARACTER:GetPhysicalInventory() return self.PhysicalInventory end
function CHARACTER:SetPhysicalInventory(physicalInventory) self.PhysicalInventory = physicalInventory end

function CHARACTER:GetPhysique() return self.Physique end
function CHARACTER:SetPhysique(physique) self.Physique = physique end

function CHARACTER:GetPlayer() return self.Player end
function CHARACTER:SetPlayer(player) self.Player = player end

function CHARACTER:GetRecognizes() return self.Recognizes end
function CHARACTER:SetRecognizes(recognizes) self.Recognizes = recognizes end

function CHARACTER:GetSkinColor() return self.SkinColor end
function CHARACTER:SetSkinColor(skinColor) self.SkinColor = skinColor end

function CHARACTER:GetUID() return self.UID end
function CHARACTER:SetUID(uid) self.UID = uid end

function CHARACTER:GetUsername() return self.Username end
function CHARACTER:SetUsername(username) print("Failed to set username to: '" .. username .. "'. Username is read-only and must be set upon object creation.") end

function CHARACTER:GetWeight() return self.Weight end
function CHARACTER:SetWeight(weight) self.Weight = weight end

function CHARACTER:GetSaveableData()
    return FrameworkZ.Foundation:ProcessSaveableData(self, {"isoPlayer"}, {"inventory"})
end

--[[ Note: Setup UID on Player object inside of stored Characters at Character
function CHARACTER:SetUID(uid)
    local player = FrameworkZ.Players:GetPlayerByID(self:GetUsername()) if not player then return false, "Could not find player by ID." end

    self.uid = uid
    player.Characters[self:GetID()].META_UID = uid

    return true
end
--]]

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
    local instance, message = FrameworkZ.Items:CreateItem(uniqueID, self:GetIsoPlayer())
    if not instance then return false, "Failed to create item: " .. message end

    inventory:AddItem(instance)

    return instance, message
end

--! \brief Take an item from a character's inventory.
--! \param uniqueID \string The unique ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItem(uniqueID)
    local success, message = FrameworkZ.Items:RemoveItemInstanceByUniqueID(self:GetIsoPlayer():getUsername(), uniqueID)

    if success then
        return true, "Successfully took " .. uniqueID .. "."
    end

    return false, message
end

--! \brief Take an item from a character's inventory by its instance ID. Useful for taking a specific item from a stack.
--! \param instanceID \integer The instance ID of the item to take.
--! \return \boolean \string Whether or not the item was successfully taken and the success or failure message.
function CHARACTER:TakeItemByInstanceID(instanceID)
    local success, message = FrameworkZ.Items:RemoveInstance(instanceID, self:GetIsoPlayer():getUsername())

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

function CHARACTER:AddRecognition(character, alias)
    if not character then return false, "Character not supplied in parameters." end

    if not self:GetRecognizes()[character:GetUID()] then
        self:GetRecognizes()[character:GetUID()] = alias or character:GetName()
        return true, "Successfully added character to recognition list."
    end

    return false, "Character already exists in recognition list."
end

function CHARACTER:GetRecognition(character)
    if not character then return false, "Character not supplied in parameters." end

    local recognizes = self:GetRecognizes()

    if recognizes[character:GetUID()] then
        return recognizes[character:GetUID()]
    else
        return "[Unrecognized]"
    end
end

function CHARACTER:RecognizesCharacter(character)
    if not character then return false, "Character not supplied in parameters." end

    if self:GetRecognizes()[character:GetUID()] then
        return true
    end

    return false
end

function CHARACTER:RestoreData()
    local player = self:GetPlayer() if not player then return false, "Player not found." end
    local characterData = player:GetCharacterDataByID(self:GetID()) if not characterData then return false, "Character data not found." end

    self:SetAge(characterData.INFO_AGE)
    self:SetBeardColor(characterData.INFO_BEARD_COLOR)
    self:SetBeardStyle(characterData.INFO_BEARD_STYLE)
    self:SetDescription(characterData.INFO_DESCRIPTION)
    self:SetEyeColor(characterData.INFO_EYE_COLOR)
    self:SetFaction(characterData.INFO_FACTION)
    self:SetHairColor(characterData.INFO_HAIR_COLOR)
    self:SetHairStyle(characterData.INFO_HAIR_STYLE)
    self:SetHeight(characterData.INFO_HEIGHT)
    self:SetID(characterData.META_ID)
    self:SetLogicalInventory(characterData.INVENTORY_LOGICAL)
    self:SetName(characterData.INFO_NAME)
    self:SetPhysique(characterData.INFO_PHYSIQUE)
    self:SetPhysicalInventory(characterData.INVENTORY_PHYSICAL)
    self:SetRecognizes(characterData.META_RECOGNIZES or {})
    self:SetSkinColor(characterData.INFO_SKIN_COLOR)
    self:SetUID(characterData.META_UID)
    self:SetWeight(characterData.INFO_WEIGHT)

    return true, "Character data restored."
end

--! \brief Initialize a character.
--! \return \string username
function CHARACTER:Initialize()
	if not self:GetIsoPlayer() then return false, "IsoPlayer not set." end

    --self:GetInventory():Initialize()
    local successfullyRestored, restoreMessage = self:RestoreData() if not successfullyRestored then return false, "Failed to restore character data: " .. restoreMessage end

    if not self:RecognizesCharacter(self) then
        local successfullyRecognizes, recognizeMessage = self:AddRecognition(self) if not successfullyRecognizes then return false, "Failed to add self to recognition list: " .. recognizeMessage end
    end

    return true, "Character initialized."
end

--! \brief Create a new character object.
--! \param username \string The player's username as their ID.
--! \param id \integer The character's ID from the player stored data.
--! \param data \table (Optional) The character's data stored on the object.
--! \return \table The new character object.
function FrameworkZ.Characters:New(isoPlayer, id)
    if not isoPlayer then return false, "IsoPlayer is invalid." end

    local username = isoPlayer:getUsername()
    local object = {
        ID = id or -1,
        Player = FrameworkZ.Players:GetPlayerByID(username),
        IsoPlayer = isoPlayer,
        Username = username,
        Inventory = FrameworkZ.Inventories:New(username),
        CustomData = {},
        Recognizes = {}
    }

    if object.ID <= -1 then return false, "New character ID is invalid." end
    if not object.Player then return false, "Player not found." end
    if not object.Inventory then return false, "Inventory not found." end
    if object.Player and not object.Player:GetCharacterDataByID(object.ID) then return false, "Player character data not found." end

    setmetatable(object, CHARACTER)

	return object
end

--! \brief Initialize a character.
--! \param username \string The player's username.
--! \param character \table The character's object data.
--! \return \string The username added to the list of characters.
function FrameworkZ.Characters:Initialize(isoPlayer, id)
    local character, message = FrameworkZ.Characters:New(isoPlayer, id) if not character then return false, "Could not create new character object, " .. message end
    local username = character:GetUsername()
    local success, message2 = character:Initialize() if not success then return false, "Failed to initialize character object: " .. message2 end

    if not self:AddToList(username, character) then
        return false, "Failed to add character to list."
    end

    if not self:AddToCache(character:GetUID(), character) then
        self:RemoveFromList(username)
        return false, "Failed to add character to cache."
    end

    return character
end

function FrameworkZ.Characters:AddToList(username, character)
    if not username or not character then return false end

    self.List[username] = character
    return self.List[username]
end

function FrameworkZ.Characters:RemoveFromList(username)
    if not username then return false end

    self.List[username] = nil
    return true
end

function FrameworkZ.Characters:AddToCache(uid, character)
    if not uid or not character then return false end

    self.Cache[uid] = character
    return self.Cache[uid]
end

function FrameworkZ.Characters:RemoveFromCache(uid)
    if not uid then return false end

    self.Cache[uid] = nil
    return true
end

--! \brief Gets the user's loaded character by their ID.
--! \param username \string The player's username to get their character object with.
--! \return \table The character object from the list of characters.
function FrameworkZ.Characters:GetCharacterByID(username)
    local character = self.List[username] or nil

    return character
end

function FrameworkZ.Characters:GetCharacterByUID(uid)
    local character = self.Cache[uid] or nil

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
    FrameworkZ.Foundation:ExecuteAllHooks("OnCharacterPostLoad", self, firstLoad) -- Does not actually call anymore
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

    character.IsoPlayer = isoPlayer
    character.Name = characterData.INFO_NAME
    character.Description = characterData.INFO_DESCRIPTION
    character.Faction = characterData.INFO_FACTION
    character.Age = characterData.INFO_AGE
    character.HeightInches = characterData.INFO_HEIGHT
    character.EyeColor = characterData.INFO_EYE_COLOR
    character.HairColor = characterData.INFO_HAIR_STYLE
    character.SkinColor = characterData.INFO_SKIN_COLOR
    character.Physique = characterData.INFO_PHYSIQUE
    character.Weight = characterData.INFO_WEIGHT
    character.Recognizes = {}

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
    self.Cache[characterData.META_UID] = character
    character:SetUID(characterData.META_UID)

    return character
end

if isClient() then

    -- UI object
    local ui

    -- cache selector texture
    local selectorTex = getTexture("media/textures/fz-selector.png")
    local texScale   = 1.0
    local texAlpha   = 0.8
    local texYOffset = 0.25   -- fraction of height to lower it under the feet

    -- tooltip state
    local showingTooltip = false
    local tooltipPlayer  = nil
    local tooltipData    = { name = "", description = {}, nameColor = {r = 1, g = 1, b = 1, a = 1} }

    -- tracking state for sticky character selection
    local trackingData = {
        currentPlayer = nil,
        stickiness = 1.5,  -- Multiplier advantage for currently tracked player
        switchThreshold = 0.3  -- Minimum score difference needed to switch to new character
    }

    -- typewriter effect state
    local typewriterData = {
        nameProgress = 0,
        descProgress = {},
        lastUpdateTime = 0,
        startDelay = 2.0,  -- Delay in seconds before typewriter effect starts
        delayStartTime = 0,  -- When the delay period started
        baseSpeed = 5,  -- Scaling multiplier for how fast (lower = faster) the conditions will affect revealing text (impact)
        currentSpeed = 0.05, -- Calculated in real time, initial value shouldn't matter
        charactersPerSecond = 10  -- Base line target of characters per second to reveal affected by baseSpeed
    }

    -- split a long description string into ~30-char lines
    function FrameworkZ.Characters:GetDescriptionLines(desc)
        local lines, line, len = {}, "", 0
        for word in string.gmatch(desc, "%S+") do
            local wlen = #word
            if len + wlen + 1 <= 30 then
                if len > 0 then
                    line = line .. " "
                    len = len + 1
                end
                line = line .. word
                len  = len + wlen
            else
                table.insert(lines, line)
                line, len = word, wlen
            end
        end
        table.insert(lines, line)
        return lines
    end

    -- calculate character selection score for weighted tracking
    local function calculateCharacterScore(localPlayer, targetPlayer, mouseX, mouseY)
        if not localPlayer or not targetPlayer then
            return 0
        end

        -- Get screen position of target player
        local pidx = targetPlayer:getPlayerNum()
        local px, py, pz = targetPlayer:getX(), targetPlayer:getY(), targetPlayer:getZ()
        local sx = isoToScreenX(pidx, px, py, pz)
        local sy = isoToScreenY(pidx, px, py, pz)

        -- Distance from mouse cursor to character on screen (closer = higher score)
        local screenDistance = math.sqrt((sx - mouseX)^2 + (sy - mouseY)^2)
        local screenScore = math.max(0, 100 - screenDistance / 2)  -- Diminishes over distance

        -- World distance factor (closer = higher score)
        local dx = targetPlayer:getX() - localPlayer:getX()
        local dy = targetPlayer:getY() - localPlayer:getY()
        local worldDistance = math.sqrt(dx * dx + dy * dy)
        local worldScore = math.max(0, 50 - worldDistance * 10)  -- Diminishes over distance

        -- Line of sight bonus (visible = higher score)
        local hasLineOfSight = true
        local steps = math.max(1, math.floor(worldDistance))
        for i = 1, steps do
            local checkX = localPlayer:getX() + (dx * i / steps)
            local checkY = localPlayer:getY() + (dy * i / steps)
            local checkSquare = getSquare(checkX, checkY, localPlayer:getZ())
            if checkSquare then
                local hasBlockingWall = checkSquare:getWall(true) or checkSquare:getWall(false)
                local door1 = checkSquare:getDoor(true)
                local door2 = checkSquare:getDoor(false)
                local hasBlockingDoor = (door1 and not door1:IsOpen()) or (door2 and not door2:IsOpen())
                local window1 = checkSquare:getWindowFrame(true)
                local window2 = checkSquare:getWindowFrame(false)
                local hasBlockingWindow = (window1 and not window1:isSmashed() and not window1:IsOpen()) or 
                                         (window2 and not window2:isSmashed() and not window2:IsOpen())
                local hasFloorAbove = checkSquare:hasFloor(true) or checkSquare:hasFloor(false)

                if hasBlockingWall or hasBlockingDoor or hasBlockingWindow or hasFloorAbove then
                    hasLineOfSight = false
                    break
                end
            end
        end
        
        local losScore = hasLineOfSight and 25 or 5

        -- Apply stickiness bonus if this is the currently tracked player
        local stickinessBonus = 0
        if trackingData.currentPlayer == targetPlayer then
            stickinessBonus = (screenScore + worldScore + losScore) * (trackingData.stickiness - 1.0)
        end

        return screenScore + worldScore + losScore + stickinessBonus
    end

    -- calculate typewriter speed based on distance, line of sight, and facing direction
    local function calculateTypewriterSpeed(localPlayer, targetPlayer)
        if not localPlayer or not targetPlayer then
            return typewriterData.baseSpeed * 4 -- slowest if we can't calculate
        end

        local dx = targetPlayer:getX() - localPlayer:getX()
        local dy = targetPlayer:getY() - localPlayer:getY()
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Base speed multiplier from distance (closer = faster)
        local distanceMultiplier = math.max(0.3, math.min(2.0, 3.0 / (distance + 1)))

        -- Line of sight check (improved - checks for actual blocking obstacles)
        local hasLineOfSight = true
        local steps = math.max(1, math.floor(distance))
        for i = 1, steps do
            local checkX = localPlayer:getX() + (dx * i / steps)
            local checkY = localPlayer:getY() + (dy * i / steps)
            local checkSquare = getSquare(checkX, checkY, localPlayer:getZ())
            if checkSquare then
                -- Check for solid walls (not doors or windows)
                local hasBlockingWall = checkSquare:getWall(true) or checkSquare:getWall(false)
                
                -- Check for closed doors (open doors don't block sight)
                local door1 = checkSquare:getDoor(true)
                local door2 = checkSquare:getDoor(false)
                local hasBlockingDoor = (door1 and not door1:IsOpen()) or (door2 and not door2:IsOpen())
                
                -- Check for window frames with glass (open or broken windows don't block sight)
                local window1 = checkSquare:getWindowFrame(true)
                local window2 = checkSquare:getWindowFrame(false)
                local hasBlockingWindow = (window1 and not window1:isSmashed() and not window1:IsOpen()) or 
                                         (window2 and not window2:isSmashed() and not window2:IsOpen())
                
                -- Check for floor above that would block view from below
                local hasFloorAbove = checkSquare:hasFloor(true) or checkSquare:hasFloor(false)

                if hasBlockingWall or hasBlockingDoor or hasBlockingWindow or hasFloorAbove then
                    hasLineOfSight = false
                    break
                end
            end
        end

        -- Line of sight multiplier
        local losMultiplier = hasLineOfSight and 1.0 or 0.4

        -- Facing direction check
        local localDir = localPlayer:getDirectionAngle()
        local angleToTarget = math.atan2(dy, dx)
        local angleDiff = math.abs(localDir - angleToTarget)
        if angleDiff > math.pi then
            angleDiff = 2 * math.pi - angleDiff
        end

        -- Facing multiplier (looking at target = faster)
        local facingMultiplier = math.max(0.5, 1.0 - (angleDiff / math.pi) * 0.7)

        -- Return speed multiplier (higher = faster typewriter effect)
        return typewriterData.baseSpeed / (distanceMultiplier * losMultiplier * facingMultiplier)
    end

    -- update typewriter progress
    local function updateTypewriterProgress()
        local currentTime = getTimestampMs()
        
        -- Check if we're still in the delay period
        if (currentTime - typewriterData.delayStartTime) / 1000.0 < typewriterData.startDelay then
            return -- Don't start typewriter effect yet
        end
        
        -- If this is the first update after delay, reset the timer
        if typewriterData.lastUpdateTime <= typewriterData.delayStartTime then
            typewriterData.lastUpdateTime = currentTime
            return -- Skip this frame to avoid large deltaTime
        end
        
        local deltaTime = (currentTime - typewriterData.lastUpdateTime) / 1000.0  -- convert to seconds

        -- Recalculate speed continuously based on current conditions
        local mp = getSpecificPlayer(0)
        if mp and tooltipPlayer then
            typewriterData.currentSpeed = calculateTypewriterSpeed(mp, tooltipPlayer)
        end

        -- Get current FPS and normalize speed
        local avgFPS = math.max(1, getAverageFPS())  -- prevent division by zero
        local targetFPS = 60
        local fpsNormalizer = targetFPS / avgFPS

        -- Calculate frame-rate independent character reveal speed
        local baseCharsPerSecond = typewriterData.charactersPerSecond
        local adjustedCharsPerSecond = baseCharsPerSecond / (typewriterData.currentSpeed / typewriterData.baseSpeed)
        local charactersToReveal = deltaTime * adjustedCharsPerSecond * fpsNormalizer

        if charactersToReveal >= 1.0 then
            local charsToAdd = math.floor(charactersToReveal)

            -- Update description progress first (observing appearance)
            local allDescriptionComplete = true
            for i, line in ipairs(tooltipData.description) do
                if charsToAdd <= 0 then break end

                if not typewriterData.descProgress[i] then
                    typewriterData.descProgress[i] = 0
                end

                -- Only start revealing description lines in order
                if i == 1 or typewriterData.descProgress[i-1] >= string.len(tooltipData.description[i-1]) then
                    if typewriterData.descProgress[i] < string.len(line) then
                        local lineCharsToAdd = math.min(charsToAdd, string.len(line) - typewriterData.descProgress[i])
                        typewriterData.descProgress[i] = typewriterData.descProgress[i] + lineCharsToAdd
                        charsToAdd = charsToAdd - lineCharsToAdd
                        allDescriptionComplete = false
                    end
                else
                    allDescriptionComplete = false
                end
            end

            -- Check if all description lines are complete
            for i, line in ipairs(tooltipData.description) do
                if not typewriterData.descProgress[i] then
                    typewriterData.descProgress[i] = 0
                end
                if typewriterData.descProgress[i] < string.len(line) then
                    allDescriptionComplete = false
                    break
                end
            end

            -- Update name progress (only after description is complete)
            if allDescriptionComplete and charsToAdd > 0 then
                if typewriterData.nameProgress < string.len(tooltipData.name) then
                    local nameCharsToAdd = math.min(charsToAdd, string.len(tooltipData.name) - typewriterData.nameProgress)
                    typewriterData.nameProgress = typewriterData.nameProgress + nameCharsToAdd
                    charsToAdd = charsToAdd - nameCharsToAdd
                end
            end

            typewriterData.lastUpdateTime = currentTime
        end
    end

    -- reset typewriter state for new character
    local function resetTypewriterState()
        typewriterData.nameProgress = 0
        typewriterData.descProgress = {}
        typewriterData.delayStartTime = getTimestampMs()  -- Start the delay timer
        typewriterData.lastUpdateTime = getTimestampMs()
    end

    -- draw the selector + text each UI frame
    local function drawTooltip()
        if not tooltipPlayer then return end

        -- recompute screen pos
        local pidx = tooltipPlayer:getPlayerNum()
        local px, py, pz = tooltipPlayer:getX(), tooltipPlayer:getY(), tooltipPlayer:getZ()
        local sx = isoToScreenX(pidx, px, py, pz)
        local sy = isoToScreenY(pidx, px, py, pz)

        -- Always draw selector ring immediately
        local w, h = selectorTex:getWidth(), selectorTex:getHeight()
        local sw, sh = w * texScale, h * texScale
        ui:drawTextureScaled(
            selectorTex,
            sx - sw/2,
            sy - sh/2 + (h * texScale * texYOffset),
            sw, sh,
            texAlpha
        )

        -- Check if delay period has passed before showing text
        local currentTime = getTimestampMs()
        if (currentTime - typewriterData.delayStartTime) / 1000.0 < typewriterData.startDelay then
            return -- Don't show text yet, only selector
        end

        -- update typewriter progress (only after delay)
        updateTypewriterProgress()

        -- draw name + description with typewriter effect
        local tm    = getTextManager()
        local font  = UIFont.Dialogue
        local lineH = tm:getFontFromEnum(font):getLineHeight()
        local ty    = sy + (sh/2) + 6

        -- name at top (with typewriter effect) - recognition after observation
        local nameColor = tooltipData.nameColor or {r = 1, g = 1, b = 1, a = 1}
        local visibleName = string.sub(tooltipData.name, 1, typewriterData.nameProgress)
        tm:DrawStringCentre(font, sx, ty, visibleName, nameColor.r, nameColor.g, nameColor.b, nameColor.a)
        ty = ty + lineH

        -- description below name (with typewriter effect) - observing appearance
        for i, line in ipairs(tooltipData.description) do
            if not typewriterData.descProgress[i] then
                typewriterData.descProgress[i] = 0
            end
            local visibleChars = typewriterData.descProgress[i]
            local visibleLine = string.sub(line, 1, visibleChars)
            tm:DrawStringCentre(font, sx, ty, visibleLine, 1, 1, 1, 1)
            ty = ty + lineH
        end
    end

    -- enable / disable the UI callback
    local function enableTooltip()
        if not showingTooltip then
            ui = ISUIElement:new(0, 0, 0, 0)
            ui:initialise()
            ui:addToUIManager()
            showingTooltip = true
            Events.OnPreUIDraw.Add(drawTooltip)
        end
    end
    local function disableTooltip()
        if showingTooltip then
            Events.OnPreUIDraw.Remove(drawTooltip)
            showingTooltip = false
            tooltipPlayer = nil
            ui = nil
            trackingData.currentPlayer = nil  -- Reset tracking when disabling tooltip
            resetTypewriterState()
        end
    end

    -- every tick, check if the mouse is over an IsoPlayer
    Events.OnTick.Add(function()
        local mp = getSpecificPlayer(0)
        if not mp then
            disableTooltip()
            return
        end

        local mx, my = getMouseX(), getMouseY()
        local pidx    = mp:getPlayerNum()
        local wx      = screenToIsoX(pidx, mx, my, 0)
        local wy      = screenToIsoY(pidx, mx, my, 0)
        local wz      = mp:getZ()
        local sq      = getSquare(wx, wy, wz)
        if not sq then
            disableTooltip()
            return
        end

        -- scan a 3×3 grid for all IsoPlayers and score them
        local candidates = {}
        for ix = sq:getX()-1, sq:getX()+1 do
            for iy = sq:getY()-1, sq:getY()+1 do
                local sq2 = getCell():getGridSquare(ix, iy, wz)
                if sq2 then
                    for i = 0, sq2:getMovingObjects():size()-1 do
                        local o = sq2:getMovingObjects():get(i)
                        if instanceof(o, "IsoPlayer") --[[and o ~= mp--]] then -- TODO uncomment when finalized
                            local score = calculateCharacterScore(mp, o, mx, my)
                            table.insert(candidates, {player = o, score = score})
                        end
                    end
                end
            end
        end

        -- Find the best candidate
        local bestCandidate = nil
        local bestScore = 0
        for _, candidate in ipairs(candidates) do
            if candidate.score > bestScore then
                bestCandidate = candidate.player
                bestScore = candidate.score
            end
        end

        -- Determine if we should switch to a new character
        local shouldSwitch = false
        local currentPlayerStillValid = false
        
        -- Check if current player is still in candidates list
        if trackingData.currentPlayer then
            for _, candidate in ipairs(candidates) do
                if candidate.player == trackingData.currentPlayer then
                    currentPlayerStillValid = true
                    break
                end
            end
        end
        
        if not trackingData.currentPlayer then
            -- No current player, switch to any valid candidate
            shouldSwitch = bestCandidate ~= nil
        elseif not bestCandidate then
            -- No candidates found, disable tooltip
            shouldSwitch = true
            bestCandidate = nil
        elseif not currentPlayerStillValid then
            -- Current player is no longer valid, switch to best candidate
            shouldSwitch = true
        else
            -- Check if the best candidate is different and significantly better
            if bestCandidate ~= trackingData.currentPlayer then
                local currentScore = 0
                for _, candidate in ipairs(candidates) do
                    if candidate.player == trackingData.currentPlayer then
                        currentScore = candidate.score
                        break
                    end
                end
                
                -- Only switch if the new candidate is significantly better
                local scoreDifference = (bestScore - currentScore) / math.max(bestScore, 1)
                shouldSwitch = scoreDifference > trackingData.switchThreshold
            end
        end

        if shouldSwitch then
            if bestCandidate then
                -- Update to new character
                trackingData.currentPlayer = bestCandidate
                if bestCandidate ~= tooltipPlayer then
                    local localChar  = FrameworkZ.Characters:GetCharacterByID(mp:getUsername()) 
                    if not localChar then return end
                    local targetChar = FrameworkZ.Characters:GetCharacterByID(bestCandidate:getUsername()) 
                    if not targetChar then return end
                    
                    tooltipPlayer = bestCandidate
                    tooltipData.name        = targetChar and localChar:GetRecognition(targetChar) or "[Unknown]"
                    tooltipData.nameColor   = targetChar and FrameworkZ.Factions:GetFactionByID(targetChar:GetFaction()):GetColor() or {r = 1, g = 1, b = 1, a = 1}
                    local descStr           = targetChar and targetChar:GetDescription() or ""
                    tooltipData.description = FrameworkZ.Characters:GetDescriptionLines(descStr)

                    -- Calculate initial typewriter speed and reset state
                    typewriterData.currentSpeed = calculateTypewriterSpeed(mp, bestCandidate)
                    resetTypewriterState()
                end
                enableTooltip()
            else
                -- No valid candidate, disable tooltip
                trackingData.currentPlayer = nil
                disableTooltip()
            end
        elseif trackingData.currentPlayer and currentPlayerStillValid then
            -- Keep showing tooltip for current player even if not switching
            enableTooltip()
        else
            -- No valid player to show
            disableTooltip()
        end
    end)

    local currentSaveTick = 0

    function FrameworkZ.Characters:PlayerTick(player)
        --[[if not player:GetIsoPlayer() then return end
        if not player:GetCharacter() then return end
        local isoPlayer = player:GetIsoPlayer()
        local character = player:GetCharacter()
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

            local playerIndex = isoPlayer:getPlayerNum()
            local worldX = screenToIsoX(playerIndex, x, y, 0)
            local worldY = screenToIsoY(playerIndex, x, y, 0)
            local worldZ = isoPlayer:getZ()
            local square = getSquare(worldX, worldY, worldZ)

            if square then
                local playerOnSquareOrNearby

                for x2=square:getX()-1,square:getX()+1 do
                    for y2=square:getY()-1,square:getY()+1 do
                        local sq = getCell():getGridSquare(x2,y2,square:getZ());
                        if sq then
                            for i=0,sq:getMovingObjects():size()-1 do
                                local o = sq:getMovingObjects():get(i)
                                if instanceof(o, "IsoPlayer") and (o ~= isoPlayer) then
                                    playerOnSquareOrNearby = o
                                    break
                                end
                            end
                        end
                    end

                    if playerOnSquareOrNearby then
                        break
                    end
                end

                if playerOnSquareOrNearby then
                    local playerOnSquareIndex = playerOnSquareOrNearby:getPlayerNum()
                    tooltipX = isoToScreenX(playerOnSquareIndex, worldX, worldY, worldZ)
                    tooltipY = isoToScreenY(playerOnSquareIndex, worldX, worldY, worldZ)

                    tooltipPlayer = playerOnSquareOrNearby
                    local characterOnSquareOrNearby = FrameworkZ.Characters:GetCharacterByID(playerOnSquareOrNearby:getUsername())
                    tooltip.name = characterOnSquareOrNearby and character:GetRecognition(characterOnSquareOrNearby) or "[Invalid Name]"
                    tooltip.description = FrameworkZ.Characters:GetDescriptionLines(characterOnSquareOrNearby and characterOnSquareOrNearby:GetDescription() or "[Invalid Description]")

                    if tooltip then
                        Events.OnPreUIDraw.Add(FrameworkZ.Characters.OnPreUIDraw)
                    end

                    local characterOnSquareOrNearby = FrameworkZ.Characters:GetCharacterByID(playerOnSquareOrNearby:getUsername())
                    tooltipPlayer = playerOnSquareOrNearby
                    tooltipData.name        = characterOnSquareOrNearby and character:GetRecognition(characterOnSquareOrNearby) or "[Invalid Name]"
                    tooltipData.description = FrameworkZ.Characters:GetDescriptionLines(characterOnSquareOrNearby and characterOnSquareOrNearby:GetDescription() or "[Invalid Description]")

                    enableTooltip()
                end
            end
        elseif showingTooltip == true then
            local playerIndex = isoPlayer:getPlayerNum()
            local worldX = screenToIsoX(playerIndex, x, y, 0)
            local worldY = screenToIsoY(playerIndex, x, y, 0)
            local worldZ = isoPlayer:getZ()
            local square = getSquare(worldX, worldY, worldZ)

            if square then
                local playerOnSquareOrNearby = square:getPlayer()

                for x2=square:getX()-1,square:getX()+1 do
                    for y2=square:getY()-1,square:getY()+1 do
                        local sq = getCell():getGridSquare(x2,y2,square:getZ());
                        if sq then
                            for i=0,sq:getMovingObjects():size()-1 do
                                local o = sq:getMovingObjects():get(i)
                                if instanceof(o, "IsoPlayer") and (o ~= isoPlayer) then
                                    playerOnSquareOrNearby = o
                                    break
                                end
                            end
                        end
                    end

                    if playerOnSquareOrNearby then
                        break
                    end
                end

                if playerOnSquareOrNearby ~= tooltipPlayer then
                    disableTooltip()
                end
            end
        end
        --]]

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

function FrameworkZ.Characters:OnStorageSet(isoPlayer, command, namespace, keys, value)
    if namespace == "Characters" then
        if command == "Initialize" then
            local username = keys
            local data = value
            local player = FrameworkZ.Players:GetPlayerByID(username) if not player then return end

            if data then
                player:SetCharacters(data)
            end
        end
    end
end

function FrameworkZ.Characters:OnInitGlobalModData()
    FrameworkZ.Foundation:RegisterNamespace("Characters")
end

FrameworkZ.Characters.MetaObject = CHARACTER

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Characters)
