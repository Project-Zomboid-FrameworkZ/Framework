require "ISUI/ISPanel"

PFW_CreateCharacterInfo = ISPanel:derive("PFW_CreateCharacterInfo")

function PFW_CreateCharacterInfo:initialise()
    self.warningTurningRed = true
    self.warningStep = 0.02
    self.warningRed = 1
    self.warningGreen = 1
    self.warningBlue = 1
    self.isAbnormal = false
    self.uiHelper = FrameworkZ.UI
    local emitter = self.playerObject:getEmitter()
	local title = "Information"
    local subtitle = "Enter your character's general info."
    local xPadding = self.width * 0.2
    local entryWidth = self.width * 0.7
    local middleX = self.width / 2 - (xPadding + entryWidth) / 2
    local entryX = middleX + xPadding
    local labelX = middleX + xPadding - 5
    local yOffset = 0

    self.nameLimit = 32
    self.recommendedNameLength = 8
    self.descriptionLimit = 256
    self.recommendedDescriptionLength = 24

    -- 9 fields (1 double height) = 9 * 30 + 75 = 345

	ISPanel.initialise(self)

    yOffset = self.uiHelper.GetHeight(UIFont.Title, title)

    self.title = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Title, title), yOffset, 25, title, 1, 1, 1, 1, UIFont.Title, true)
    self.title:initialise()
	self:addChild(self.title)

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Large, subtitle)

    self.subtitle = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, subtitle), yOffset, 25, subtitle, 1, 1, 1, 1, UIFont.Large, true)
    self.subtitle:initialise()
    self:addChild(self.subtitle)

    yOffset = yOffset + 45

    self.genderLabel = ISLabel:new(labelX, yOffset, 25, "Gender:", 1, 1, 1, 1, UIFont.Large, false)
    self.genderLabel:initialise()
    self:addChild(self.genderLabel)

    self.gender = "Male"
    self.genderDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25, self, self.onGenderChanged)
    self.genderDropdown:addOption("Male")
    self.genderDropdown:addOption("Female")
    self:addChild(self.genderDropdown)

    yOffset = yOffset + 30

    self.nameLabel = ISLabel:new(labelX, yOffset, 25, "Name (32):", 1, 1, 1, 1, UIFont.Large, false)
    self.nameLabel:initialise()
    self:addChild(self.nameLabel)

    self.nameEntry = ISTextEntryBox:new("", entryX, yOffset, entryWidth, 25)
    self.nameEntry.backgroundColor = {r=0, g=0, b=0, a=1.0}
    self.nameEntry.borderColor = {r=1, g=0, b=0, a=1.0}
    self.nameEntry:initialise()
	self.nameEntry:instantiate()
    self:addChild(self.nameEntry)

    yOffset = yOffset + 30

    self.descriptionLabel = ISLabel:new(labelX, yOffset, 25, "Description (256):", 1, 1, 1, 1, UIFont.Large, false)
    self.descriptionLabel:initialise()
    self:addChild(self.descriptionLabel)

    self.descriptionEntry = ISTextEntryBox:new("", entryX, yOffset, entryWidth, 100)
    self.descriptionEntry.backgroundColor = {r=0, g=0, b=0, a=1.0}
    self.descriptionEntry.borderColor = {r=1, g=0, b=0, a=1}
    self.descriptionEntry:initialise()
	self.descriptionEntry:instantiate()
    self.descriptionEntry:setMultipleLine(true)
	self.descriptionEntry:setMaxLines(0)
    self:addChild(self.descriptionEntry)

    yOffset = yOffset + 110

    self.ageLabel = ISLabel:new(labelX, yOffset, 25, "Age (25):", 1, 1, 1, 1, UIFont.Large, false)
    self.ageLabel:initialise()
    self:addChild(self.ageLabel)

    self.ageSlider = ISSliderPanel:new(entryX, yOffset, entryWidth, 25, self, self.onAgeChanged)
    self.ageSlider.currentValue = 25
    self.ageSlider.minValue = FrameworkZ.Config.CharacterMinAge
    self.ageSlider.maxValue = FrameworkZ.Config.CharacterMaxAge
    self.ageSlider.stepValue = 1
    self:addChild(self.ageSlider)

    --[[self.ageDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.ageDropdown:addOption("18")
    self.ageDropdown:addOption("19")
    self.ageDropdown:addOption("20")
    -- Add more age options as needed
    self:addChild(self.ageDropdown)--]]

    yOffset = yOffset + 30

    self.heightLabel = ISLabel:new(labelX, yOffset, 25, "Height (5'10\"):", 1, 1, 1, 1, UIFont.Large, false)
    self.heightLabel:initialise()
    self:addChild(self.heightLabel)

    self.heightSlider = ISSliderPanel:new(entryX, yOffset, entryWidth, 25, self, self.onHeightChanged)
    self.heightSlider.currentValue = 70
    self.heightSlider.minValue = FrameworkZ.Config.CharacterMinHeight
    self.heightSlider.maxValue = FrameworkZ.Config.CharacterMaxHeight
    self.heightSlider.stepValue = 1
    self:addChild(self.heightSlider)

    --[[self.heightFeetDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.heightFeetDropdown:addOption("5")
    self.heightFeetDropdown:addOption("6")
    -- Add more height options as needed
    self:addChild(self.heightFeetDropdown)--]]

    --[[
    yOffset = yOffset + 30

    self.heightInchesLabel = ISLabel:new(labelX, yOffset, 25, "Height (10\"):", 1, 1, 1, 1, UIFont.Large, false)
    self.heightInchesLabel:initialise()
    self:addChild(self.heightInchesLabel)

    self.heightInchesSlider = ISSliderPanel:new(entryX, yOffset, entryWidth, 25, self, self.onHeightInchesChanged)
    self.heightInchesSlider.currentValue = 10
    self.heightInchesSlider.minValue = 0
    self.heightInchesSlider.maxValue = 11
    self.heightInchesSlider.stepValue = 1
    self:addChild(self.heightInchesSlider)
    --]]

    --[[self.heightInchesDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.heightInchesDropdown:addOption("0")
    self.heightInchesDropdown:addOption("1")
    -- Add more height options as needed
    self:addChild(self.heightInchesDropdown)--]]

    yOffset = yOffset + 30

    self.weightLabel = ISLabel:new(labelX, yOffset, 25, "Weight (150 lb):", 1, 1, 1, 1, UIFont.Large, false)
    self.weightLabel:initialise()
    self:addChild(self.weightLabel)

    self.weightSlider = ISSliderPanel:new(entryX, yOffset, entryWidth, 25, self, self.onWeightChanged)
    self.weightSlider.currentValue = 150
    self.weightSlider.minValue = FrameworkZ.Config.CharacterMinWeight
    self.weightSlider.maxValue = FrameworkZ.Config.CharacterMaxWeight
    self.weightSlider.stepValue = 5
    self:addChild(self.weightSlider)

    yOffset = yOffset + 30

    self.physiqueLabel = ISLabel:new(labelX, yOffset, 25, "Physique:", 1, 1, 1, 1, UIFont.Large, false)
    self.physiqueLabel:initialise()
    self:addChild(self.physiqueLabel)

    self.physiqueDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.physiqueDropdown:addOption("Skinny")
    self.physiqueDropdown:addOption("Slim")
    self.physiqueDropdown:addOption("Average")
    self.physiqueDropdown:addOption("Muscular")
    self.physiqueDropdown:addOption("Overweight")
    self.physiqueDropdown:addOption("Obese")
    self.physiqueDropdown:initialise()
    self.physiqueDropdown:select("Average")
    self:addChild(self.physiqueDropdown)

    yOffset = yOffset + 30

    self.eyeColorLabel = ISLabel:new(labelX, yOffset, 25, "Eye Color:", 1, 1, 1, 1, UIFont.Large, false)
    self.eyeColorLabel:initialise()
    self:addChild(self.eyeColorLabel)

    self.eyeColorDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.eyeColorDropdown:addOption("Blue")
    self.eyeColorDropdown:addOption("Brown")
    self.eyeColorDropdown:addOption("Gray")
    self.eyeColorDropdown:addOption("Green")
    self.eyeColorDropdown:addOption("Heterochromatic")
    -- Add more eye color options as needed
    self:addChild(self.eyeColorDropdown)

    yOffset = yOffset + 30

    self.hairColorLabel = ISLabel:new(labelX, yOffset, 25, "Hair Color:", 1, 1, 1, 1, UIFont.Large, false)
    self.hairColorLabel:initialise()
    self:addChild(self.hairColorLabel)

    self.hairColorDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.hairColorDropdown:addOptionWithData("Black", {r = HAIR_COLOR_BLACK_R, g = HAIR_COLOR_BLACK_G, b = HAIR_COLOR_BLACK_B})
    self.hairColorDropdown:addOptionWithData("Blonde", {r = HAIR_COLOR_BLONDE_R, g = HAIR_COLOR_BLONDE_G, b = HAIR_COLOR_BLONDE_B})
    self.hairColorDropdown:addOptionWithData("Brown", {r = HAIR_COLOR_BROWN_R, g = HAIR_COLOR_BROWN_G, b = HAIR_COLOR_BROWN_B})
    self.hairColorDropdown:addOptionWithData("Gray", {r = HAIR_COLOR_GRAY_R, g = HAIR_COLOR_GRAY_G, b = HAIR_COLOR_GRAY_B})
    self.hairColorDropdown:addOptionWithData("Red", {r = HAIR_COLOR_RED_R, g = HAIR_COLOR_RED_G, b = HAIR_COLOR_RED_B})
    self.hairColorDropdown:addOptionWithData("White", {r = HAIR_COLOR_WHITE_R, g = HAIR_COLOR_WHITE_G, b = HAIR_COLOR_WHITE_B})
    self:addChild(self.hairColorDropdown)

    yOffset = yOffset + 30

    self.skinColorLabel = ISLabel:new(labelX, yOffset, 25, "Skin Color:", 1, 1, 1, 1, UIFont.Large, false)
    self.skinColorLabel:initialise()
    self:addChild(self.skinColorLabel)

    self.skinColorDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.skinColorDropdown:addOptionWithData("Pale", SKIN_COLOR_PALE)
    self.skinColorDropdown:addOptionWithData("White", SKIN_COLOR_WHITE)
    self.skinColorDropdown:addOptionWithData("Tanned", SKIN_COLOR_TANNED)
    self.skinColorDropdown:addOptionWithData("Brown", SKIN_COLOR_BROWN)
    self.skinColorDropdown:addOptionWithData("Dark Brown", SKIN_COLOR_DARK_BROWN)
    self:addChild(self.skinColorDropdown)

    yOffset = yOffset + 30

    -- HL2RP abnormal stuff
    --[[
    local warningText1 = "Your character would be considered abnormal."
    local warningText2 = "The Combine will target you."

    self.abnormalLabel1 = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, warningText1), yOffset, 50, warningText1, 1, 1, 1, 1, UIFont.Large, true)
    self.abnormalLabel1:initialise()
    self.abnormalLabel1:setVisible(false)
    self:addChild(self.abnormalLabel1)

    yOffset = yOffset + 30

    self.abnormalLabel2 = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, warningText2), yOffset, 50, warningText2, 1, 1, 1, 1, UIFont.Large, true)
    self.abnormalLabel2:initialise()
    self.abnormalLabel2:setVisible(false)
    self:addChild(self.abnormalLabel2)
    --]]

    --[[self.weightDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25)
    self.weightDropdown:addOption("0")
    self.weightDropdown:addOption("25")
    -- Add more weight options as needed
    self:addChild(self.weightDropdown)--]]
end

function PFW_CreateCharacterInfo:onGenderChanged(dropdown)
    self.gender = dropdown:getOptionText(dropdown.selected)
end

function PFW_CreateCharacterInfo:onAgeChanged(newValue, slider)
    self.ageLabel:setName("Age (" .. newValue .. "):")

    -- HL2RP abnormal stuff
    --[[
    if newValue < 20 or newValue >= 60 then
        self.isAbnormal = true
        self.abnormalLabel1:setVisible(true)
        self.abnormalLabel2:setVisible(true)
    else
        self.isAbnormal = false
        self.abnormalLabel1:setVisible(false)
        self.abnormalLabel2:setVisible(false)
    end
    --]]
end

function PFW_CreateCharacterInfo:onHeightChanged(newValue, slider)
    local feet = math.floor(newValue / 12)
    local inches = newValue % 12
    
    self.heightLabel:setName("Height (" .. feet .. "' " .. inches .. "\"):")

    -- HL2RP abnormal stuff
    --[[
    if newValue < 60 or newValue > 74 then
        self.isAbnormal = true
        self.abnormalLabel1:setVisible(true)
        self.abnormalLabel2:setVisible(true)
    else
        self.isAbnormal = false
        self.abnormalLabel1:setVisible(false)
        self.abnormalLabel2:setVisible(false)
    end
    --]]
end

function PFW_CreateCharacterInfo:onWeightChanged(newValue, slider)
    self.weightLabel:setName("Weight (" .. newValue .. " lb):")

    -- HL2RP abnormal stuff
    --[[
    if newValue < 125 or newValue > 175 then
        self.isAbnormal = true
        self.abnormalLabel1:setVisible(true)
        self.abnormalLabel2:setVisible(true)
    else
        self.isAbnormal = false
        self.abnormalLabel1:setVisible(false)
        self.abnormalLabel2:setVisible(false)
    end
    --]]
end

function PFW_CreateCharacterInfo:prerender()
    ISPanel.prerender(self)
end

function PFW_CreateCharacterInfo:update()
    ISPanel.update(self)

    -- HL2RP abnormal stuff
    --[[
    if self.abnormalLabel1 and self.abnormalLabel2 and self.abnormalLabel1:getIsVisible() == true and self.abnormalLabel2:getIsVisible() == true then
        if self.warningTurningRed == true then
            if self.warningGreen > 0 or self.warningBlue > 0 then
                self.warningGreen = self.warningGreen - self.warningStep
                self.warningBlue = self.warningBlue - self.warningStep
            else
                self.warningTurningRed = false
            end
        else
            if self.warningGreen < 1 or self.warningBlue < 1 then
                self.warningGreen = self.warningGreen + self.warningStep
                self.warningBlue = self.warningBlue + self.warningStep
            else
                self.warningTurningRed = true
            end
        end

        self.abnormalLabel1:setColor(self.warningRed, self.warningGreen, self.warningBlue)
        self.abnormalLabel2:setColor(self.warningRed, self.warningGreen, self.warningBlue)
    end
    --]]

    if self.nameLabel and self.nameEntry then
        local usedCharacters = string.len(self.nameEntry:getText())
        local remainingCharacters = self.nameLimit - usedCharacters

        if remainingCharacters < 0 then
            self.nameEntry:setText(string.sub(self.nameEntry:getText(), 1, self.nameLimit))
            remainingCharacters = 0
        end

        local red, green
        if usedCharacters >= self.nameLimit then
            red = 1
            green = 1
        else
            if usedCharacters <= self.recommendedNameLength then
                local ratio = usedCharacters / self.recommendedNameLength
                red = 1 - ratio
                green = ratio
            else
                local ratio = (usedCharacters - self.recommendedNameLength) / (self.nameLimit - self.recommendedNameLength)
                red = math.max(0, math.min(1, ratio * 0.5))
                green = math.max(0, math.min(1, 1 - ratio * 0.5))
            end
        end

        self.nameLabel:setName("Name (" .. remainingCharacters .. "):")
        self.nameEntry.borderColor = {r=red, g=green, b=0, a=0.7}
    end

    if self.descriptionLabel and self.descriptionEntry then
        local usedCharacters = string.len(self.descriptionEntry:getText())
        local remainingCharacters = self.descriptionLimit - usedCharacters

        if remainingCharacters < 0 then
            self.descriptionEntry:setText(string.sub(self.descriptionEntry:getText(), 1, self.descriptionLimit))
            remainingCharacters = 0
        end

        local red, green
        if usedCharacters >= self.descriptionLimit then
            red = 1
            green = 1
        else
            if usedCharacters <= self.recommendedDescriptionLength then
                local ratio = usedCharacters / self.recommendedDescriptionLength
                red = 1 - ratio
                green = ratio
            else
                local ratio = (usedCharacters - self.recommendedDescriptionLength) / (self.descriptionLimit - self.recommendedDescriptionLength)
                red = math.max(0, math.min(1, ratio * 0.5))
                green = math.max(0, math.min(1, 1 - ratio * 0.5))
            end
        end

        self.descriptionLabel:setName("Description (" .. remainingCharacters .. "):")
        self.descriptionEntry.borderColor = {r=red, g=green, b=0, a=0.7}
    end
end

function PFW_CreateCharacterInfo:new(parameters)
	local o = {}

	o = ISPanel:new(parameters.x, parameters.y, parameters.width, parameters.height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.playerObject = parameters.playerObject
	PFW_CreateCharacterInfo.instance = o

	return o
end

return PFW_CreateCharacterInfo
