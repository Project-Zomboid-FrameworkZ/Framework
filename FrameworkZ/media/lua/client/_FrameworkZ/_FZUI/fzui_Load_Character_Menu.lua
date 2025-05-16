PFW_LoadCharacterMenu = ISPanel:derive("PFW_LoadCharacterMenu")

function PFW_LoadCharacterMenu:initialise()
    ISPanel.initialise(self)

    local isoPlayer = self.player.isoPlayer

    self.currentIndex = 1
    self.gender = "Male"
    self.characters = self.player:GetCharacters()

    local transitionButtonHeight = self.height / 2
    local transitionButtonY = self.height / 2 - transitionButtonHeight / 2
    local isFemale = (self.gender == "Female" and true) or (self.gender == "Male" and false)

    local widthLeft = 150
    local heightLeft = 300
    local xLeft = self.width / 8 - widthLeft / 8
    local yLeft = self.height / 2 - heightLeft / 2

    local widthSelected = 200
    local heightSelected = 400
    local xSelected = self.width / 2 - widthSelected / 2
    local ySelected = self.height / 2 - heightSelected / 2

    local widthRight = 150
    local heightRight = 300
    local xRight = self.width - (self.width / 8 + widthLeft)
    local yRight = self.height / 2 - heightLeft / 2

    self.survivor = SurvivorFactory:CreateSurvivor(SurvivorType.Neutral, isFemale)
    self.survivor:setFemale(isFemale)

    self.nextButton = ISButton:new(self.width - 30, transitionButtonY, 30, transitionButtonHeight, ">", self, PFW_LoadCharacterMenu.onNext)
    self.nextButton.font = UIFont.Large
    self.nextButton.internal = "NEXT"
    self.nextButton:initialise()
    self.nextButton:instantiate()
    self:addChild(self.nextButton)

    self.previousButton = ISButton:new(0, transitionButtonY, 30, transitionButtonHeight, "<", self, PFW_LoadCharacterMenu.onPrevious)
    self.previousButton.font = UIFont.Large
    self.previousButton.internal = "PREVIOUS"
    self.previousButton:initialise()
    self.previousButton:instantiate()
    self:addChild(self.previousButton)

    self.leftCharacter = PFW_CharacterView:new(xLeft, yLeft, widthLeft, heightLeft, isoPlayer, self.characters[1], "", "", IsoDirections.SW)
    self.leftCharacter:setVisible(false)
    self.leftCharacter:initialise()
    self:addChild(self.leftCharacter)

    self.selectedCharacter = PFW_CharacterView:new(xSelected, ySelected, widthSelected, heightSelected, isoPlayer, self.characters[1], "", "", IsoDirections.S)
    self.selectedCharacter:setVisible(false)
    self.selectedCharacter:initialise()
    self:addChild(self.selectedCharacter)

    self.rightCharacter = PFW_CharacterView:new(xRight, yRight, widthRight, heightRight, isoPlayer, self.characters[1], "", "", IsoDirections.SE)
    self.rightCharacter:setVisible(false)
    self.rightCharacter:initialise()
    self:addChild(self.rightCharacter)

    if not self.player.previousCharacter then
        if #self.characters == 1 then
            self.selectedCharacter:setCharacter(self.characters[1])
            self.selectedCharacter:reinitialize(self.characters[1])
            self.selectedCharacter:setVisible(true)
        elseif #self.characters >= 2 then
            self.selectedCharacter:setCharacter(self.characters[1])
            self.selectedCharacter:reinitialize(self.characters[1])

            self.rightCharacter:setCharacter(self.characters[2])
            self.rightCharacter:reinitialize(self.characters[2])

            self.selectedCharacter:setVisible(true)
            self.rightCharacter:setVisible(true)
        end
    else
        for i = 1, #self.characters do
            if i == self.player.previousCharacter then
                self.currentIndex = i
                break
            end
        end

        if #self.characters == 1 then
            self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
            self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
            self.selectedCharacter:setVisible(true)
            self.leftCharacter:setVisible(false)
            self.rightCharacter:setVisible(false)
        elseif #self.characters >= 2 then
            if self.currentIndex == 1 then
                self.leftCharacter:setVisible(false)
                self.rightCharacter:setVisible(true)
            elseif self.currentIndex == #self.characters then
                self.leftCharacter:setVisible(true)
                self.rightCharacter:setVisible(false)
            else
                self.leftCharacter:setVisible(true)
                self.rightCharacter:setVisible(true)
            end
        
            self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
            self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
            self.selectedCharacter:setVisible(true)
            
            if self.leftCharacter:isVisible() then
                self.leftCharacter:setCharacter(self.characters[self.currentIndex - 1])
                self.leftCharacter:reinitialize(self.characters[self.currentIndex - 1])
            end
            if self.rightCharacter:isVisible() then
                self.rightCharacter:setCharacter(self.characters[self.currentIndex + 1])
                self.rightCharacter:reinitialize(self.characters[self.currentIndex + 1])
            end
        end
    end

    --[[
    self.characterPreview = PFW_CharacterPreview:new(self.width / 2 - characterPreviewWidth / 2, self.height / 2 - characterPreviewHeight / 2, characterPreviewWidth, characterPreviewHeight, "EventIdle")
    self.characterPreview:initialise()
    self.characterPreview:removeChild(self.characterPreview.animCombo)
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)
    self:addChild(self.characterPreview)
    --]]
end

function PFW_LoadCharacterMenu:onNext()
    self.currentIndex = math.min(self.currentIndex + 1, #self.characters)
    self:updateCharacterPreview()
end

function PFW_LoadCharacterMenu:onPrevious()
    self.currentIndex = math.max(self.currentIndex - 1, 1)
    self:updateCharacterPreview()
end

function PFW_LoadCharacterMenu:updateCharacterPreview()
    self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
    self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
    self.selectedCharacter:setVisible(true)

    if self.currentIndex > 1 then
        self.leftCharacter:setCharacter(self.characters[self.currentIndex - 1])
        self.leftCharacter:reinitialize(self.characters[self.currentIndex - 1])
        self.leftCharacter:setVisible(true)
    else
        self.leftCharacter:setVisible(false)
    end

    if self.currentIndex < #self.characters then
        self.rightCharacter:setCharacter(self.characters[self.currentIndex + 1])
        self.rightCharacter:reinitialize(self.characters[self.currentIndex + 1])
        self.rightCharacter:setVisible(true)
    else
        self.rightCharacter:setVisible(false)
    end
end

function PFW_LoadCharacterMenu:render()
    ISPanel.prerender(self)

    -- Render the character preview and any other UI elements here
end

function PFW_LoadCharacterMenu:new(x, y, width, height, player)
    local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.player = player
	PFW_LoadCharacterMenu.instance = o

	return o
end

return PFW_LoadCharacterMenu
