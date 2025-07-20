FrameworkZ.UI.MainMenu = FrameworkZ.UI.MainMenu or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.MainMenu, "MainMenu")

local mainMenuMusicVolume = 1.0
local currentMainMenuSong = nil
local nextLightning = 5

function FrameworkZ.UI.MainMenu:initialise()
    
    -- HL2RP LIGHTNING STUFF
    --[[
    FrameworkZ.Timers:Create("MainMenuTick", 1, 0, function()
        if FrameworkZ.UI.MainMenu.instance then
            if not FrameworkZ.Timers:Exists("NextLightning") then
                FrameworkZ.Timers:Create("NextLightning", nextLightning, 1, function()
                    local mainMenu = FrameworkZ.UI.MainMenu.instance
                    mainMenu.shouldFlashLightning = true
                    mainMenu.hasFlashed1 = false
                    mainMenu.hasFlashed2 = false
                    mainMenu.hasFlashed3 = false
                    nextLightning = ZombRandBetween(10, 60)

                    FrameworkZ.Timers:Simple(2, function()
                        mainMenu.emitter:playSoundImpl("thunder" .. ZombRandBetween(3, 4), nil)
                    end)
                end)
            end
        end
    end)
    --]]

    self.uiHelper = FrameworkZ.UI
    self.emitter = self.playerObject:getEmitter()
	local title = FrameworkZ.Config.Options.GamemodeTitle .. " " .. FrameworkZ.Config.Options.Version .. "-" .. FrameworkZ.Config.Options.VersionType
    local subtitle = FrameworkZ.Config.Options.GamemodeDescription
    local createCharacterLabel = "Create Character"
    local loadCharacterLabel = "Load Character"
    local disconnectLabel = "Disconnect"
    local middleX = self.width / 2 - 200 / 2
    local middleY = self.height / 2 + FrameworkZ.UI.GetHeight(UIFont.Title, title) + FrameworkZ.UI.GetHeight(UIFont.Large, subtitle)

	ISPanel.initialise(self)

    if FrameworkZ.Timers:Exists("FadeOutMainMenuMusic") then
        FrameworkZ.Timers:Remove("FadeOutMainMenuMusic")
    end

    if currentMainMenuSong and self.emitter:isPlaying(currentMainMenuSong) then
        self.emitter:stopSound(currentMainMenuSong)
    end

    mainMenuMusicVolume = 1.0
    currentMainMenuSong = self.emitter:playSoundImpl(FrameworkZ.Config.Options.MainMenuMusic, nil)

    local stepWidth, stepHeight = 500, 600
    local stepX, stepY = self.width / 2 - stepWidth / 2, self.height / 2 - stepHeight / 2
    self.MainMenu = self
    self.createCharacterSteps = FrameworkZ.UserInterfaces:New("VanillaCreateCharacter", self)
    self.createCharacterSteps.onEnterInitialMenu = self.onEnterMainMenu
    self.createCharacterSteps.onExitInitialMenu = self.onExitMainMenu
    self.createCharacterSteps:Initialize()

    if FrameworkZ.UI.MainMenu.customSteps then
        FrameworkZ.UI.MainMenu.customSteps()
    else
        self.createCharacterSteps:RegisterNextStep("MainMenu", "SelectFaction", self, FrameworkZ.UI.CreateCharacterFaction, self.onEnterFactionMenu, self.onExitFactionMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
        self.createCharacterSteps:RegisterNextStep("SelectFaction", "EnterInfo", FrameworkZ.UI.CreateCharacterFaction, FrameworkZ.UI.CreateCharacterInfo, self.onEnterInfoMenu, self.onExitInfoMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
        self.createCharacterSteps:RegisterNextStep("EnterInfo", "CustomizeAppearance", FrameworkZ.UI.CreateCharacterInfo, FrameworkZ.UI.CreateCharacterAppearance, self.onEnterAppearanceMenu, self.onExitAppearanceMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
        self.createCharacterSteps:RegisterNextStep("CustomizeAppearance", "MainMenu", FrameworkZ.UI.CreateCharacterAppearance, self, self.onFinalizeCharacter, nil, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
    end

    self.titleY = self.uiHelper.GetHeight(UIFont.Title, title)

    self.title = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Title, title), self.titleY, 25, title, 1, 1, 1, 1, UIFont.Title, true)
	self:addChild(self.title)

    self.subtitle = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, subtitle), self.titleY + self.uiHelper.GetHeight(UIFont.Large, subtitle), 25, subtitle, 1, 1, 1, 1, UIFont.Large, true)
    self:addChild(self.subtitle)

    self.createCharacterButton = ISButton:new(middleX, middleY - 75, 200, 50, createCharacterLabel, self.createCharacterSteps, self.createCharacterSteps.ShowNextStep)
    self.createCharacterButton.font = UIFont.Large
    self:addChild(self.createCharacterButton)

    self.loadCharacterButton = ISButton:new(middleX, middleY, 200, 50, loadCharacterLabel, self, FrameworkZ.UI.MainMenu.onEnterLoadCharacterMenu)
    self.loadCharacterButton.font = UIFont.Large
    self:addChild(self.loadCharacterButton)

    self.disconnectButton = ISButton:new(middleX, middleY + 75, 200, 50, disconnectLabel, self, FrameworkZ.UI.MainMenu.onDisconnect)
    self.disconnectButton.font = UIFont.Large
    self:addChild(self.disconnectButton)

    self.closeButton = ISButton:new(middleX, middleY + 150, 200, 50, "Close", self, FrameworkZ.UI.MainMenu.onClose)
    self.closeButton.font = UIFont.Large

    if not FrameworkZ.Players:GetLoadedCharacterByID(self.playerObject:getUsername()) then
        self.closeButton:setVisible(false)
    end

    self:addChild(self.closeButton)

    --[[
    self.closeButton = ISButton:new(middleX, middleY + 150, 200, 50, "Close", self, FrameworkZ.UI.MainMenu.onClose)
    self.closeButton.font = UIFont.Large
    self:addChild(self.closeButton)
    --]]
end

function FrameworkZ.UI.MainMenu:fadeOutMainMenuMusic()
    if self.emitter:isPlaying(currentMainMenuSong) then
        mainMenuMusicVolume = mainMenuMusicVolume - 0.002
        self.emitter:setVolume(currentMainMenuSong, mainMenuMusicVolume)

        if mainMenuMusicVolume <= 0 then
            FrameworkZ.Timers:Remove("FadeOutMainMenuMusic")
            self.emitter:stopSound(currentMainMenuSong)
        end
    end
end

function FrameworkZ.UI.MainMenu:onClose()
    FrameworkZ.Timers:Create("FadeOutMainMenuMusic", 0.01, 0, function()
        self:fadeOutMainMenuMusic()
    end)

    self:setVisible(false)
    self:removeFromUIManager()
end

function FrameworkZ.UI.MainMenu:onEnterMainMenu()
    FrameworkZ.UI.CreateCharacterInfo.instance = nil
    FrameworkZ.UI.CreateCharacterFaction.instance = nil
    FrameworkZ.UI.CreateCharacterAppearance.instance = nil

    self.createCharacterButton:setVisible(true)
    self.loadCharacterButton:setVisible(true)
    self.disconnectButton:setVisible(true)

    if FrameworkZ.Players:GetLoadedCharacterByID(self.playerObject:getUsername()) then
        self.closeButton:setVisible(true)
    end
end

function FrameworkZ.UI.MainMenu:onExitMainMenu()
    local maxCharacters = 1
    local currentCharacters = 0

    if currentCharacters < maxCharacters then
        self.createCharacterButton:setVisible(false)
        self.loadCharacterButton:setVisible(false)
        self.disconnectButton:setVisible(false)

        if FrameworkZ.Players:GetLoadedCharacterByID(self.playerObject:getUsername()) then
            self.closeButton:setVisible(false)
        end

        return true
    else
        return false
    end
end

function FrameworkZ.UI.MainMenu:showStepControls(menu, backButtonIndex, backButton, backButtonText, forwardButtonIndex, forwardButton, forwardButtonText)
    if not backButton then
        local width = 200
        local height = 50
        local x = menu:getX()
        local y = menu:getY() + menu.height + 25

        self[backButtonIndex] = ISButton:new(x, y, width, height, backButtonText, self.createCharacterSteps, self.createCharacterSteps.ShowPreviousStep)
        self[backButtonIndex].font = UIFont.Large
        self:addChild(self[backButtonIndex])
    else
        backButton:setVisible(true)
    end

    if not forwardButton then
        local width = 200
        local height = 50
        local x = menu:getX() + menu.width - width
        local y = menu:getY() + menu.height + 25

        self[forwardButtonIndex] = ISButton:new(x, y, width, height, forwardButtonText, self.createCharacterSteps, self.createCharacterSteps.ShowNextStep)
        self[forwardButtonIndex].font = UIFont.Large
        self:addChild(self[forwardButtonIndex])
    else
        forwardButton:setVisible(true)
    end
end

function FrameworkZ.UI.MainMenu:hideStepControls(backButton, forwardButton)
    if backButton then
        backButton:setVisible(false)
    end

    if forwardButton then
        forwardButton:setVisible(false)
    end
end

function FrameworkZ.UI.MainMenu:onEnterFactionMenu(menu)
    self:showStepControls(menu, "returnToMainMenu", self.returnToMainMenu, "< Main Menu (Cancel)", "enterInfoForward", self.enterInfoForward, "Info >")
end

function FrameworkZ.UI.MainMenu:onExitFactionMenu(menu)
    self:hideStepControls(self.returnToMainMenu, self.enterInfoForward)

    return true
end

function FrameworkZ.UI.MainMenu:onEnterInfoMenu(menu)
    self:showStepControls(menu, "selectFaction", self.selectFaction, "< Faction", "customizeAppearance", self.customizeAppearance, "Appearance >")
end

function FrameworkZ.UI.MainMenu:onExitInfoMenu(menu, isForward)
    local infoInstance = FrameworkZ.UI.CreateCharacterInfo.instance
    local name = infoInstance.nameEntry:getText()
    local description = infoInstance.descriptionEntry:getText()
    local warningMessage = ""

    if not name or name == "" then
        warningMessage = warningMessage .. "Name must be filled in"
    elseif #name < 8 then
        warningMessage = warningMessage .. (warningMessage == "" and "" or " and ") .. "Name must be at least 8 characters"
    end

    if not description or description == "" then
        warningMessage = warningMessage .. (warningMessage == "" and "" or " and ") .. "Description must be filled in"
    elseif #description < 24 then
        warningMessage = warningMessage .. (warningMessage == "" and "" or " and ") .. "Description must be at least 24 characters"
    end

    if warningMessage ~= "" and isForward then
        FrameworkZ.Notifications:AddToQueue("Cannot proceed: " .. warningMessage, FrameworkZ.Notifications.Types.Warning, nil, self)
        return false
    end

    self:hideStepControls(self.selectFaction, self.customizeAppearance)

    return true
end

function FrameworkZ.UI.MainMenu:onEnterAppearanceMenu(menu)
    menu.faction = FrameworkZ.UI.CreateCharacterFaction.instance.faction
    menu.gender = FrameworkZ.UI.CreateCharacterInfo.instance.gender
    menu.skinColor = FrameworkZ.UI.CreateCharacterInfo.instance.skinColorDropdown:getOptionData(FrameworkZ.UI.CreateCharacterInfo.instance.skinColorDropdown.selected)
    menu.hairColor = FrameworkZ.UI.CreateCharacterInfo.instance.hairColorDropdown:getOptionData(FrameworkZ.UI.CreateCharacterInfo.instance.hairColorDropdown.selected)

    FrameworkZ.UI.CreateCharacterAppearance.instance.skinColor = menu.skinColor
    FrameworkZ.UI.CreateCharacterAppearance.instance.hairColor = menu.hairColor

    FrameworkZ.UI.CreateCharacterAppearance.instance:resetGender(menu.gender)
    FrameworkZ.UI.CreateCharacterAppearance.instance:resetHairColor()
    FrameworkZ.UI.CreateCharacterAppearance.instance:resetHairStyles()
    FrameworkZ.UI.CreateCharacterAppearance.instance:resetBeardStyles()
    FrameworkZ.UI.CreateCharacterAppearance.instance:resetSkinColor()
    FrameworkZ.UI.CreateCharacterAppearance.instance.wasGenderUpdated = false

    self:showStepControls(menu, "enterInfoBack", self.enterInfoBack, "< Info", "finalizeCharacter", self.finalizeCharacter, "Finalize >")
end

function FrameworkZ.UI.MainMenu:onExitAppearanceMenu(menu)
    self:hideStepControls(self.enterInfoBack, self.finalizeCharacter)

    return true
end

function FrameworkZ.UI.MainMenu:onFinalizeCharacter(menu)
    self:hideStepControls(self.enterInfoBack, self.finalizeCharacter)

    local infoInstance = FrameworkZ.UI.CreateCharacterInfo.instance
    local factionInstance = FrameworkZ.UI.CreateCharacterFaction.instance
    local appearanceInstance = FrameworkZ.UI.CreateCharacterAppearance.instance

    local faction = factionInstance.faction
    local gender = infoInstance.genderDropdown:getSelectedText()
    local name = infoInstance.nameEntry:getText()
    local description = infoInstance.descriptionEntry:getText()
    local age = infoInstance.ageSlider:getCurrentValue()
    local height = infoInstance.heightSlider:getCurrentValue()
    local weight = infoInstance.weightSlider:getCurrentValue()
    local physique = infoInstance.physiqueDropdown:getSelectedText()
    local eyeColor = infoInstance.eyeColorDropdown:getSelectedText()
    local hairColor = infoInstance.hairColorDropdown and infoInstance.hairColorDropdown:getOptionData(infoInstance.hairColorDropdown.selected) or nil
    local skinColor = infoInstance.skinColorDropdown and infoInstance.skinColorDropdown:getOptionData(infoInstance.skinColorDropdown.selected) or nil

    local hair = appearanceInstance.hairDropdown and appearanceInstance.hairDropdown:getOptionData(appearanceInstance.hairDropdown.selected) or nil
    local beard = appearanceInstance.beardDropdown and appearanceInstance.beardDropdown:getOptionData(appearanceInstance.beardDropdown.selected) or nil
    local head = appearanceInstance.headDropdown and appearanceInstance.headDropdown:getOptionData(appearanceInstance.headDropdown.selected).itemID or nil
    local face = appearanceInstance.faceDropdown and appearanceInstance.faceDropdown:getOptionData(appearanceInstance.faceDropdown.selected).itemID or nil
    local ears = appearanceInstance.earsDropdown and appearanceInstance.earsDropdown:getOptionData(appearanceInstance.earsDropdown.selected).itemID or nil
    local backpack = appearanceInstance.backpackDropdown and appearanceInstance.backpackDropdown:getOptionData(appearanceInstance.backpackDropdown.selected).itemID or nil
    local rightHand = nil
    local rightHandAccessory = nil
    local leftHand = nil
    local leftHandAccessory = nil
    local gloves = appearanceInstance.glovesDropdown and appearanceInstance.glovesDropdown:getOptionData(appearanceInstance.glovesDropdown.selected).itemID or nil
    local undershirt = appearanceInstance.undershirtDropdown and appearanceInstance.undershirtDropdown:getOptionData(appearanceInstance.undershirtDropdown.selected).itemID or nil
    local overshirt = appearanceInstance.overshirtDropdown and appearanceInstance.overshirtDropdown:getOptionData(appearanceInstance.overshirtDropdown.selected).itemID or nil
    local vest = appearanceInstance.vestDropdown and appearanceInstance.vestDropdown:getOptionData(appearanceInstance.vestDropdown.selected).itemID or nil
    local belt = appearanceInstance.beltDropdown and appearanceInstance.beltDropdown:getOptionData(appearanceInstance.beltDropdown.selected).itemID or nil
    local pants = appearanceInstance.pantsDropdown and appearanceInstance.pantsDropdown:getOptionData(appearanceInstance.pantsDropdown.selected).itemID or nil
    local socks = appearanceInstance.socksDropdown and appearanceInstance.socksDropdown:getOptionData(appearanceInstance.socksDropdown.selected).itemID or nil
    local shoes = appearanceInstance.shoesDropdown and appearanceInstance.shoesDropdown:getOptionData(appearanceInstance.shoesDropdown.selected).itemID or nil

    local characterData = {
        INFO_FACTION = faction,
        INFO_GENDER = gender,
        INFO_NAME = name,
        INFO_DESCRIPTION = description,
        INFO_AGE = age,
        INFO_HEIGHT = height,
        INFO_WEIGHT = weight,
        INFO_PHYSIQUE = physique,
        INFO_EYE_COLOR = eyeColor,
        INFO_BEARD_COLOR = hairColor,
        INFO_HAIR_COLOR = hairColor,
        INFO_SKIN_COLOR = skinColor,
        INFO_HAIR_STYLE = hair,
        INFO_BEARD_STYLE = beard,
        EQUIPMENT_SLOT_HEAD = {id = head},
        EQUIPMENT_SLOT_FACE = {id = face},
        EQUIPMENT_SLOT_EARS = {id = ears},
        EQUIPMENT_SLOT_BACKPACK = {id = backpack},
        EQUIPMENT_SLOT_GLOVES = {id = gloves},
        EQUIPMENT_SLOT_UNDERSHIRT = {id = undershirt},
        EQUIPMENT_SLOT_OVERSHIRT = {id = overshirt},
        EQUIPMENT_SLOT_VEST = {id = vest},
        EQUIPMENT_SLOT_BELT = {id = belt},
        EQUIPMENT_SLOT_PANTS = {id = pants},
        EQUIPMENT_SLOT_SOCKS = {id = socks},
        EQUIPMENT_SLOT_SHOES = {id = shoes}
    }

    FrameworkZ.Foundation:SendFire(self.playerObject, "FrameworkZ.Players.OnCreateCharacter", function(data, serverCharacterID, serverMessage)
        if serverCharacterID then
            local clientCharacterID, clientMessage = FrameworkZ.Players:CreateCharacter(self.playerObject:getUsername(), characterData, serverCharacterID)

            if clientCharacterID and clientCharacterID == serverCharacterID then
                FrameworkZ.Notifications:AddToQueue("Successfully created character #" .. clientCharacterID .. ": " .. characterData.INFO_NAME, FrameworkZ.Notifications.Types.Success, nil, self)
            elseif clientCharacterID ~= serverCharacterID then
                FrameworkZ.Notifications:AddToQueue("Failed to create character client-side: Character ID mistmatch.", FrameworkZ.Notifications.Types.Warning, nil, self)
            else
                FrameworkZ.Notifications:AddToQueue("Failed to create character client-side: " .. clientMessage, FrameworkZ.Notifications.Types.Warning, nil, self)
            end
        else
            FrameworkZ.Notifications:AddToQueue("Failed to create character server-side: " .. serverMessage, FrameworkZ.Notifications.Types.Warning, nil, self)
            return false
        end
    end, self.playerObject:getUsername(), characterData)

    return true
end

function FrameworkZ.UI.MainMenu:onEnterLoadCharacterMenu()
    local player = FrameworkZ.Players:GetPlayerByID(self.playerObject:getUsername())

    if not player then
        FrameworkZ.Notifications:AddToQueue("Failed to load characters.", FrameworkZ.Notifications.Types.Danger, nil, self)

        return false
    elseif #player:GetCharacters() <= 0 then
        FrameworkZ.Notifications:AddToQueue("No characters found.", FrameworkZ.Notifications.Types.Warning, nil, self)

        return false
    end

    self:onExitMainMenu()

    if not self.loadCharacterMenu then
        local width = 800
        local height = 600
        local x = self.width / 2 - width / 2
        local y = self.height / 2 - height / 2

        self.loadCharacterMenu = FrameworkZ.UI.LoadCharacterMenu:new(x, y, width, height, player)
        self.loadCharacterMenu:initialise()
        self:addChild(self.loadCharacterMenu)
    else
        self.loadCharacterMenu:setVisible(true)
        self.loadCharacterMenu:updateCharacterPreview()
    end

    if not self.loadCharacterBackButton then
        local widthReturn = 200
        local heightReturn = 50
        local xReturn = self.loadCharacterMenu:getX()
        local yReturn = self.loadCharacterMenu:getY() + self.loadCharacterMenu.height + 25

        self.loadCharacterBackButton = ISButton:new(xReturn, yReturn, widthReturn, heightReturn, "< Main Menu", self, self.onEnterMainMenuFromLoadCharacterMenu)
        self.loadCharacterBackButton.font = UIFont.Large
        self:addChild(self.loadCharacterBackButton)
    else
        self.loadCharacterBackButton:setVisible(true)
    end

    if not self.loadCharacterForwardButton then
        local widthLoad = 200
        local heightLoad = 50
        local xLoad = self.loadCharacterMenu:getX() + self.loadCharacterMenu.width - widthLoad
        local yLoad = self.loadCharacterMenu:getY() + self.loadCharacterMenu.height + 25

        self.loadCharacterForwardButton = ISButton:new(xLoad, yLoad, widthLoad, heightLoad, "Load Character >", self, self.onLoadCharacter)
        self.loadCharacterForwardButton.font = UIFont.Large
        self:addChild(self.loadCharacterForwardButton)
    else
        self.loadCharacterForwardButton:setVisible(true)
    end
    --self.loadCharacterMenu:addToUIManager()
end

function FrameworkZ.UI.MainMenu:onEnterMainMenuFromLoadCharacterMenu()
    self.loadCharacterBackButton:setVisible(false)
    self.loadCharacterForwardButton:setVisible(false)
    self.loadCharacterMenu:setVisible(false)

    self:onEnterMainMenu()
end

function FrameworkZ.UI.MainMenu:onLoadCharacter()
    local characterID = self.loadCharacterMenu.currentIndex
    FrameworkZ.Players:LoadCharacterByID(self.playerObject:getUsername(), characterID)





    --[[
    local loadCharacterStartTime = getTimestampMs()
    local characterID = self.loadCharacterMenu.currentIndex
    local character = FrameworkZ.Players:GetCharacterByID(self.playerObject:getUsername(), characterID)

    if character then
        FrameworkZ.Players:LoadCharacter(self.playerObject:getUsername(), character, self.loadCharacterMenu.selectedCharacter.survivor, loadCharacterStartTime)
    else
        FrameworkZ.Notifications:AddToQueue("No character selected.", FrameworkZ.Notifications.Types.Warning, nil, self)
    end
    --]]
end

function FrameworkZ.UI.MainMenu:onDisconnect()
    self:setVisible(false)
    self:removeFromUIManager()
	getCore():exitToMenu()
end

function FrameworkZ.UI.MainMenu:prerender()
    ISPanel.prerender(self)

    -- HL2RP LIGHTNING STUFF
    --[[
    local opacity = 0.25
    
    if self.shouldFlashLightning then
        opacity = 0.5
        
        if not self.hasFlashed1 then
            self:drawTextureScaled(getTexture("media/textures/lightning_1.png"), 0, 0, self.width, self.height, opacity, 1, 1, 1)
        elseif not self.hasFlashed2 then
            self:drawTextureScaled(getTexture("media/textures/lightning_2.png"), 0, 0, self.width, self.height, opacity, 1, 1, 1)
        elseif not self.hasFlashed3 then
            self:drawTextureScaled(getTexture("media/textures/lightning_1.png"), 0, 0, self.width, self.height, opacity, 1, 1, 1)
        end
        
        FrameworkZ.Timers:Simple(0.05, function()
            self.hasFlashed1 = true

            FrameworkZ.Timers:Simple(0.05, function()
                self.hasFlashed2 = true
                
                FrameworkZ.Timers:Simple(0.05, function()
                    self.hasFlashed3 = true
                    self.shouldFlashLightning = false
                end)
            end)
        end)
    end
    --]]

    self:drawTextureScaled(getTexture(FrameworkZ.Config:GetOption("MainMenuImage")), 0, 0, self.width, self.height, self.backgroundImageOpacity, 1, 1, 1)
end

function FrameworkZ.UI.MainMenu:update()
    ISPanel.update(self)

    if not self.emitter:isPlaying(currentMainMenuSong) then
        currentMainMenuSong = self.emitter:playSoundImpl(FrameworkZ.Config:GetOption("MainMenuMusic"), nil)
    end
end

function FrameworkZ.UI.MainMenu:new(x, y, width, height, playerObject)
	local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
    self.backgroundImageOpacity = 1
	o.backgroundColor = {r=0, g=0, b=0, a=1}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.playerObject = playerObject
	FrameworkZ.UI.MainMenu.instance = o

	return o
end

return FrameworkZ.UI.MainMenu
