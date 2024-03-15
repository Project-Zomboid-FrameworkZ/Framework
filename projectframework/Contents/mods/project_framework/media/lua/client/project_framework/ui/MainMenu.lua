require "ISUI/ISPanel"

PFW_MainMenu = ISPanel:derive("PFW_MainMenu")

local nextLightning = 5

function PFW_MainMenu:initialise()
    timer:Create("MainMenuTick", 1, 0, function()
        if PFW_MainMenu.instance then
            if not timer:Exists("NextLightning") then
                timer:Create("NextLightning", nextLightning, 1, function()
                    local mainMenu = PFW_MainMenu.instance
                    mainMenu.shouldFlashLightning = true
                    mainMenu.hasFlashed1 = false
                    mainMenu.hasFlashed2 = false
                    mainMenu.hasFlashed3 = false
                    nextLightning = ZombRandBetween(10, 60)
    
                    timer:Simple(2, function()
                        mainMenu.emitter:playSoundImpl("thunder" .. ZombRandBetween(3, 4), nil)
                    end)
                end)
            end
        end
    end)
    
    self.uiHelper = ProjectFramework.UI
    self.emitter = self.playerObject:getEmitter()
	local title = ProjectFramework.Config.GamemodeTitle
    local subtitle = ProjectFramework.Config.GamemodeDescription
    local createCharacterLabel = "Create Character"
    local loadCharacterLabel = "Load Character"
    local disconnectLabel = "Disconnect"
    local middleX = self.width / 2 - 200 / 2
    local middleY = self.height / 2 + ProjectFramework.UI.GetHeight(UIFont.Title, title) + ProjectFramework.UI.GetHeight(UIFont.Large, subtitle)

	ISPanel.initialise(self)
    self.emitter:playSoundImpl("hl2_song19", nil)

    local stepWidth, stepHeight = 500, 500
    local stepX, stepY = self.width / 2 - stepWidth / 2, self.height / 2 - stepHeight / 2
    self.MainMenu = self
    self.createCharacterSteps = ProjectFramework.UserInterfaces:New("VanillaCreateCharacter", self)
    self.createCharacterSteps.onEnterInitialMenu = self.onEnterMainMenu
    self.createCharacterSteps.onExitInitialMenu = self.onExitMainMenu
    self.createCharacterSteps:Initialize()
    self.createCharacterSteps:RegisterNextStep("MainMenu", "SelectFaction", self, PFW_CreateCharacterFaction, self.onEnterFactionMenu, self.onExitFactionMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
    self.createCharacterSteps:RegisterNextStep("SelectFaction", "EnterInfo", PFW_CreateCharacterFaction, PFW_CreateCharacterInfo, self.onEnterInfoMenu, self.onExitInfoMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
    self.createCharacterSteps:RegisterNextStep("EnterInfo", "CustomizeAppearance", PFW_CreateCharacterInfo, PFW_CreateCharacterAppearance, self.onEnterAppearanceMenu, self.onExitAppearanceMenu, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})
    self.createCharacterSteps:RegisterNextStep("CustomizeAppearance", "MainMenu", PFW_CreateCharacterAppearance, self, self.onFinalizeCharacter, nil, {x = stepX, y = stepY, width = stepWidth, height = stepHeight, playerObject = self.playerObject})

    self.titleY = self.uiHelper.GetHeight(UIFont.Title, title)

    self.title = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Title, title), self.titleY, 25, title, 1, 1, 1, 1, UIFont.Title, true)
	self:addChild(self.title)

    self.subtitle = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, subtitle), self.titleY + self.uiHelper.GetHeight(UIFont.Large, subtitle), 25, subtitle, 1, 1, 1, 1, UIFont.Large, true)
    self:addChild(self.subtitle)

    self.createCharacterButton = ISButton:new(middleX, middleY - 75, 200, 50, createCharacterLabel, self.createCharacterSteps, self.createCharacterSteps.ShowNextStep)
    self.createCharacterButton.font = UIFont.Large
    self:addChild(self.createCharacterButton)

    self.loadCharacterButton = ISButton:new(middleX, middleY, 200, 50, loadCharacterLabel, self, PFW_MainMenu.onSelectCharacter)
    self.loadCharacterButton.font = UIFont.Large
    self:addChild(self.loadCharacterButton)

    self.disconnectButton = ISButton:new(middleX, middleY + 75, 200, 50, disconnectLabel, self, PFW_MainMenu.onDisconnect)
    self.disconnectButton.font = UIFont.Large
    self:addChild(self.disconnectButton)

    --[[
    self.closeButton = ISButton:new(middleX, middleY + 150, 200, 50, "Close", self, PFW_MainMenu.onClose)
    self.closeButton.font = UIFont.Large
    self:addChild(self.closeButton)
    --]]
end

function PFW_MainMenu:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function PFW_MainMenu:onEnterMainMenu()
    self.createCharacterButton:setVisible(true)
    self.loadCharacterButton:setVisible(true)
    self.disconnectButton:setVisible(true)
end

function PFW_MainMenu:onExitMainMenu()
    local maxCharacters = 1
    local currentCharacters = 0

    if currentCharacters < maxCharacters then
        self.createCharacterButton:setVisible(false)
        self.loadCharacterButton:setVisible(false)
        self.disconnectButton:setVisible(false)

        return true
    else
        return false
    end
end

function PFW_MainMenu:showStepControls(menu, backButtonIndex, backButton, backButtonText, forwardButtonIndex, forwardButton, forwardButtonText)
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

function PFW_MainMenu:hideStepControls(backButton, forwardButton)
    if backButton then
        backButton:setVisible(false)
    end

    if forwardButton then
        forwardButton:setVisible(false)
    end
end

function PFW_MainMenu:onEnterFactionMenu(menu)
    self:showStepControls(menu, "returnToMainMenu", self.returnToMainMenu, "< Main Menu", "enterInfoForward", self.enterInfoForward, "Info >")
end

function PFW_MainMenu:onExitFactionMenu(menu)
    self:hideStepControls(self.returnToMainMenu, self.enterInfoForward)
end

function PFW_MainMenu:onEnterInfoMenu(menu)
    self:showStepControls(menu, "selectFaction", self.selectFaction, "< Faction", "customizeAppearance", self.customizeAppearance, "Appearance >")
end

function PFW_MainMenu:onExitInfoMenu(menu)
    self:hideStepControls(self.selectFaction, self.customizeAppearance)
end

function PFW_MainMenu:onEnterAppearanceMenu(menu)
    menu.faction = PFW_CreateCharacterFaction.instance.faction
    menu.gender = PFW_CreateCharacterInfo.instance.gender
    self:showStepControls(menu, "enterInfoBack", self.enterInfoBack, "< Info", "finalizeCharacter", self.finalizeCharacter, "Finalize >")
end

function PFW_MainMenu:onExitAppearanceMenu(menu)
    self:hideStepControls(self.enterInfoBack, self.finalizeCharacter)
end

function PFW_MainMenu:onFinalizeCharacter(menu)
    self:hideStepControls(self.enterInfoBack, self.finalizeCharacter)
end

function PFW_MainMenu:onSelectCharacter()
    self:hideMainMenuControls()
end

function PFW_MainMenu:onDisconnect()
    self:setVisible(false)
    self:removeFromUIManager()
	getCore():exitToMenu()
end

function PFW_MainMenu:prerender()
    ISPanel.prerender(self)

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
        
        timer:Simple(0.05, function()
            self.hasFlashed1 = true

            timer:Simple(0.05, function()
                self.hasFlashed2 = true
                
                timer:Simple(0.05, function()
                    self.hasFlashed3 = true
                    self.shouldFlashLightning = false
                end)
            end)
        end)
    end

    self:drawTextureScaled(getTexture("media/textures/citidel.png"), 0, 0, self.width, self.height, opacity, 1, 1, 1)
end

function PFW_MainMenu:update()
    ISPanel.update(self)
end

function PFW_MainMenu:new(x, y, width, height, playerObject)
	local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=1}
	o.borderColor = {r=0, g=0, b=0, a=1}
	o.moveWithMouse = false
	o.playerObject = playerObject
	PFW_MainMenu.instance = o

	return o
end

return PFW_MainMenu
