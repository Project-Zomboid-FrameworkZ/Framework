--! \page globalVars Global Variables
--! \section Players Players
--! ProjectFramework.Players\n
--! See Players for the module on players.\n\n
--! ProjectFramework.Players.List\n
--! A list of all instanced players in the game.

ProjectFramework = ProjectFramework or {}

--! \brief Characters module for ProjectFramework. Defines and interacts with PLAYER object.
--! \class Characters
ProjectFramework.Players = {}
ProjectFramework.Players.__index = ProjectFramework.Characters
ProjectFramework.Players.List = {}
ProjectFramework.Players.Roles = {
    User = "User",
    Operator = "Operator",
    Moderator = "Moderator",
    Admin = "Admin",
    Super_Admin = "Super Admin",
    Owner = "Owner"
}
ProjectFramework.Players = ProjectFramework.Foundation:NewModule(ProjectFramework.Players, "Players")

--! \brief Character class for ProjectFramework.
--! \class CHARACTER
local PLAYER = {}
PLAYER.__index = PLAYER

function PLAYER:Initialize()
    if not self.player then return end
end

function PLAYER:GetWhitelists()
    return self.whitelists
end

function PLAYER:SetWhitelisted(factionID, whitelisted)
    if not factionID then return false end

    self.whitelists[factionID] = whitelisted
end

function PLAYER:IsWhitelisted(factionID)
    if not factionID then return false end

    return self.whitelists[factionID] or false
end

--! \brief Plays a sound for the player that only they can hear.
--! \param soundName \string The name of the sound to play.
--! \return \integer The sound's ID.
function PLAYER:PlayLocalSound(soundName)
    return self.player:getEmitter():playSoundImpl(soundName, nil)
end

--! \brief Stops a sound for the player.
--! \param soundNameOrID \mixed of \string or \integer The name or ID of the sound to stop.
function PLAYER:StopSound(soundNameOrID)
    if type(soundNameOrID) == "number" then
        self.player:getEmitter():stopSound(soundNameOrID)
    elseif type(soundNameOrID) == "string" then
        self.player:getEmitter():stopSoundByName(soundNameOrID)
    end
end

function ProjectFramework.Players:New(username, player)
    if not username or not player then return false end
    
    local object = {
        username = username,
        player = player,
        steamID = player:getSteamID(),
        role = ProjectFramework.Players.Roles.User,
        maxCharacters = ProjectFramework.Config.DefaultMaxCharacters,
        whitelists = {},
        characters = {}
    }

    setmetatable(object, PLAYER)

	return object
end

function ProjectFramework.Players:GetPlayerByID(username)
    if not username then return false end

    local player = ProjectFramework.Players.List[username]

    if player then
        return player
    end

    return false
end

function ProjectFramework.Players:GetCharacterByID(username, characterID)
    if not username or not characterID then return false end

    local player = ProjectFramework.Players:GetPlayerByID(username)

    if player then
        local character = player.characters[characterID]

        if character then
            return character
        end
    end

    return false
end

function ProjectFramework.Players:CreateCharacter(username, characterData)
    
end

function ProjectFramework.Players:LoadCharacter(username, characterID)
    
end

function ProjectFramework.Players:DeleteCharacter(username, characterID)
    
end
