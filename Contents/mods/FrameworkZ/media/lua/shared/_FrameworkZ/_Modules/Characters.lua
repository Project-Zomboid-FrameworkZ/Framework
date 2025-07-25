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

local isClient = isClient

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
    local currentSaveTick = 0

    function FrameworkZ.Characters:PlayerTick(player)
        if currentSaveTick >= FrameworkZ.Config.Options.TicksUntilCharacterSave then
            local success, message = FrameworkZ.Players:Save(player:GetIsoPlayer():getUsername())

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
