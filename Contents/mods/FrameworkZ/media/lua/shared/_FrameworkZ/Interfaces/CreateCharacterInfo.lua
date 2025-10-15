FrameworkZ.UI.CreateCharacterInfo = FrameworkZ.UI.CreateCharacterInfo or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CreateCharacterInfo, "CreateCharacterInfo")

function FrameworkZ.UI.CreateCharacterInfo:initialise()
    -- State and config
    self.warningTurningRed = true
    self.warningStep = 0.02
    self.warningRed = 1
    self.warningGreen = 1
    self.warningBlue = 1
    self.isAbnormal = false
    self.uiHelper = FrameworkZ.UI
    self.nameLimit = 32
    self.recommendedNameLength = 16
    self.descriptionLimit = 256
    self.recommendedDescriptionLength = 100

    local title = "Character Information"
    local subtitle = "Define your character's identity and appearance"

    local yOffset = 15

    -- Title and subtitle
    self.title = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2,
        y = yOffset,
        height = 35,
        text = title,
        font = FZ_FONT_TITLE,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Primary",
        parent = self
    })
    yOffset = yOffset + 50
    self.subtitle = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2,
        y = yOffset,
        height = 25,
        text = subtitle,
        font = FZ_FONT_LARGE,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Subtle",
        parent = self
    })
    yOffset = yOffset + 45

    -- Content panel
    local contentPadding = 25
    local contentWidth = self.width - (contentPadding * 2)
    local contentHeight = self.height - yOffset - 50
    self.contentPanel = FrameworkZ.Interfaces:CreatePanel({
        x = contentPadding, y = yOffset, width = contentWidth, height = contentHeight,
        variant = FrameworkZ.Themes.CardPanelTheme,
        parent = self
    })

    -- Layout metrics
    local columnPadding = 20
    local columnGap = 30
    local leftColumnWidth = (contentWidth - (columnPadding * 2) - columnGap) / 2
    local rightColumnWidth = leftColumnWidth
    local labelX = columnPadding
    local rightLabelX = labelX + leftColumnWidth + columnGap
    local rightEntryX = rightLabelX + 120
    local rightEntryWidth = rightColumnWidth - 120

    -- Section headers
    local sectionY = 15
    self.basicInfoHeader = FrameworkZ.Interfaces:CreateLabel({
        x = labelX, y = sectionY, height = 25,
        text = "▎Basic Information",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self.contentPanel
    })
    self.physicalHeader = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = sectionY, height = 25,
        text = "▎Physical Attributes",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self.contentPanel
    })

    local fieldY = sectionY + 35
    local rightFieldY = fieldY

    -- Gender
    self.genderLabel = FrameworkZ.Interfaces:CreateLabel({
        x = labelX, y = fieldY, height = 25,
        text = "Gender:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    fieldY = fieldY + 25
    self.gender = "Male"
    self.genderDropdown = FrameworkZ.Interfaces:CreateCombo({
        x = labelX, y = fieldY, width = leftColumnWidth, height = 25,
        target = self, onChange = self.onGenderChanged,
        options = { "Male", "Female" },
        parent = self.contentPanel
    })
    fieldY = fieldY + 40

    -- Name
    self.nameLabel = FrameworkZ.Interfaces:CreateLabel({
        x = labelX, y = fieldY, height = 25,
        text = "Name:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    fieldY = fieldY + 25
    self.nameEntry = FrameworkZ.Interfaces:CreateTextEntry({
        x = labelX, y = fieldY, width = leftColumnWidth, height = 25,
        text = "",
        parent = self.contentPanel
    })
    self.nameCounter = FrameworkZ.Interfaces:CreateLabel({
        x = labelX + leftColumnWidth + 5, y = fieldY + 5, height = 15,
        text = tostring(self.nameLimit),
        font = FZ_FONT_SMALL,
        variant = FrameworkZ.Themes.MutedLabelTheme,
        parent = self.contentPanel
    })
    fieldY = fieldY + 40

    -- Description
    self.descriptionLabel = FrameworkZ.Interfaces:CreateLabel({
        x = labelX, y = fieldY, height = 25,
        text = "Description:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    fieldY = fieldY + 25
    local bottomPadding = sectionY + 20  -- Add more padding from bottom edge
    self.descriptionEntry = FrameworkZ.Interfaces:CreateTextEntry({
        x = labelX, y = fieldY, width = leftColumnWidth, height = contentHeight - fieldY - bottomPadding,
        text = "",
        multiple = true, maxLines = 0,
        parent = self.contentPanel
    })
    self.descriptionCounter = FrameworkZ.Interfaces:CreateLabel({
        x = labelX + leftColumnWidth + 5, y = fieldY + self.descriptionEntry:getHeight() - 15, height = 15,
        text = tostring(self.descriptionLimit),
        font = FZ_FONT_SMALL,
        variant = FrameworkZ.Themes.MutedLabelTheme,
        parent = self.contentPanel
    })

    -- Right column: age
    self.ageLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Age: 25",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.ageSlider = FrameworkZ.Interfaces:CreateSlider({
        x = rightLabelX, y = rightFieldY + 25, width = rightColumnWidth, height = 20,
        target = self, onChange = self.onAgeChanged,
        min = FrameworkZ.Config.Options.CharacterMinAge or 18,
        max = FrameworkZ.Config.Options.CharacterMaxAge or 80,
        step = 1, value = 25,
        parent = self.contentPanel
    })
    rightFieldY = rightFieldY + 65

    -- Height
    self.heightLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Height: 5'10\"",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.heightSlider = FrameworkZ.Interfaces:CreateSlider({
        x = rightLabelX, y = rightFieldY + 25, width = rightColumnWidth, height = 20,
        target = self, onChange = self.onHeightChanged,
        min = FrameworkZ.Config.Options.CharacterMinHeight or 48,
        max = FrameworkZ.Config.Options.CharacterMaxHeight or 84,
        step = 1, value = 70,
        parent = self.contentPanel
    })
    rightFieldY = rightFieldY + 65

    -- Weight
    self.weightLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Weight: 150 lb",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.weightSlider = FrameworkZ.Interfaces:CreateSlider({
        x = rightLabelX, y = rightFieldY + 25, width = rightColumnWidth, height = 20,
        target = self, onChange = self.onWeightChanged,
        min = FrameworkZ.Config.Options.CharacterMinWeight or 90,
        max = FrameworkZ.Config.Options.CharacterMaxWeight or 300,
        step = 5, value = 150,
        parent = self.contentPanel
    })
    rightFieldY = rightFieldY + 65

    -- Physique
    self.physiqueLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Physique:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.physiqueDropdown = FrameworkZ.Interfaces:CreateCombo({
        x = rightEntryX, y = rightFieldY, width = rightEntryWidth, height = 25,
        options = { "Skinny", "Slim", "Average", "Muscular", "Overweight", "Obese" },
        parent = self.contentPanel
    })
    if self.physiqueDropdown and self.physiqueDropdown.select then
        self.physiqueDropdown:select("Average")
    end
    rightFieldY = rightFieldY + 50

    -- Appearance header
    self.appearanceHeader = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "▎Appearance",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self.contentPanel
    })
    rightFieldY = rightFieldY + 35

    -- Eye color
    self.eyeColorLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Eye Color:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.eyeColorDropdown = FrameworkZ.Interfaces:CreateCombo({
        x = rightEntryX, y = rightFieldY, width = rightEntryWidth, height = 25,
        options = {
            { text = "Blue", data = { r = 0.2, g = 0.4, b = 0.8 } },
            { text = "Brown", data = { r = 0.4, g = 0.2, b = 0.1 } },
            { text = "Gray", data = { r = 0.5, g = 0.5, b = 0.5 } },
            { text = "Green", data = { r = 0.2, g = 0.6, b = 0.3 } },
            { text = "Hazel", data = { r = 0.4, g = 0.3, b = 0.2 } },
        },
        parent = self.contentPanel
    })
    if self.eyeColorDropdown and self.eyeColorDropdown.select then
        self.eyeColorDropdown:select("Blue")
    end
    rightFieldY = rightFieldY + 35

    -- Hair color
    self.hairColorLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Hair Color:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.hairColorDropdown = FrameworkZ.Interfaces:CreateCombo({
        x = rightEntryX, y = rightFieldY, width = rightEntryWidth, height = 25,
        options = {
            { text = "Black",  data = { r = (HAIR_COLOR_BLACK_R or 0.1), g = (HAIR_COLOR_BLACK_G or 0.1), b = (HAIR_COLOR_BLACK_B or 0.1) } },
            { text = "Blonde", data = { r = (HAIR_COLOR_BLONDE_R or 0.8), g = (HAIR_COLOR_BLONDE_G or 0.7), b = (HAIR_COLOR_BLONDE_B or 0.4) } },
            { text = "Brown",  data = { r = (HAIR_COLOR_BROWN_R or 0.4), g = (HAIR_COLOR_BROWN_G or 0.2), b = (HAIR_COLOR_BROWN_B or 0.1) } },
            { text = "Gray",   data = { r = (HAIR_COLOR_GRAY_R or 0.5), g = (HAIR_COLOR_GRAY_G or 0.5), b = (HAIR_COLOR_GRAY_B or 0.5) } },
            { text = "Red",    data = { r = (HAIR_COLOR_RED_R or 0.7), g = (HAIR_COLOR_RED_G or 0.3), b = (HAIR_COLOR_RED_B or 0.2) } },
            { text = "White",  data = { r = (HAIR_COLOR_WHITE_R or 0.9), g = (HAIR_COLOR_WHITE_G or 0.9), b = (HAIR_COLOR_WHITE_B or 0.9) } },
        },
        parent = self.contentPanel
    })
    if self.hairColorDropdown and self.hairColorDropdown.select then
        self.hairColorDropdown:select("Brown")
    end
    rightFieldY = rightFieldY + 35

    -- Skin color
    self.skinColorLabel = FrameworkZ.Interfaces:CreateLabel({
        x = rightLabelX, y = rightFieldY, height = 25,
        text = "Skin Color:",
        font = FZ_FONT_MEDIUM,
        parent = self.contentPanel
    })
    self.skinColorDropdown = FrameworkZ.Interfaces:CreateCombo({
        x = rightEntryX, y = rightFieldY, width = rightEntryWidth, height = 25,
        options = {
            { text = "Pale",       data = (SKIN_COLOR_PALE or 0) },
            { text = "White",      data = (SKIN_COLOR_WHITE or 1) },
            { text = "Tanned",     data = (SKIN_COLOR_TANNED or 2) },
            { text = "Brown",      data = (SKIN_COLOR_BROWN or 3) },
            { text = "Dark Brown", data = (SKIN_COLOR_DARK_BROWN or 4) },
        },
        parent = self.contentPanel
    })
    if self.skinColorDropdown and self.skinColorDropdown.select then
        self.skinColorDropdown:select("White")
    end
end

function FrameworkZ.UI.CreateCharacterInfo:onGenderChanged(dropdown)
    self.gender = dropdown:getOptionText(dropdown.selected)
end

function FrameworkZ.UI.CreateCharacterInfo:onAgeChanged(newValue, slider)
    -- Update the label with the new age value
    self.ageLabel:setName("Age: " .. newValue)
    
    -- Store the current age
    self.currentAge = newValue
    
    -- Optional: Add age-based visual feedback
    if newValue < 21 then
        self.ageLabel:setColor(0.8, 0.9, 1)  -- Light blue for young
    elseif newValue > 65 then
        self.ageLabel:setColor(0.9, 0.8, 0.6)  -- Light yellow for elderly
    else
        self.ageLabel:setColor(0.9, 0.9, 0.9)  -- Normal white
    end
end

function FrameworkZ.UI.CreateCharacterInfo:onHeightChanged(newValue, slider)
    -- Convert inches to feet and inches for display
    local feet = math.floor(newValue / 12)
    local inches = newValue % 12
    local heightText = feet .. "'" .. inches .. "\""
    
    self.heightLabel:setName("Height: " .. heightText)
    
    -- Store the current height in inches
    self.currentHeight = newValue
    
    -- Optional: Add height-based visual feedback
    if newValue < 60 then
        self.heightLabel:setColor(0.8, 0.8, 1)  -- Light blue for short
    elseif newValue > 78 then
        self.heightLabel:setColor(0.8, 1, 0.8)  -- Light green for tall
    else
        self.heightLabel:setColor(0.9, 0.9, 0.9)  -- Normal white
    end
end

function FrameworkZ.UI.CreateCharacterInfo:onWeightChanged(newValue, slider)
    -- Update the label with the new weight value
    self.weightLabel:setName("Weight: " .. newValue .. " lb")
    
    -- Store the current weight
    self.currentWeight = newValue
    
    -- Optional: Add weight-based visual feedback based on physique
    local selectedPhysique = "Average"
    if self.physiqueDropdown and self.physiqueDropdown.selected > 0 then
        selectedPhysique = self.physiqueDropdown:getOptionText(self.physiqueDropdown.selected)
    end
    
    -- Adjust color based on weight and physique combination
    if (selectedPhysique == "Skinny" and newValue > 140) or (selectedPhysique == "Overweight" and newValue < 160) then
        self.weightLabel:setColor(1, 0.8, 0.6)  -- Light orange for mismatched weight/physique
    else
        self.weightLabel:setColor(0.9, 0.9, 0.9)  -- Normal white
    end
end

function FrameworkZ.UI.CreateCharacterInfo:validateData()
    local errors = {}
    
    -- Validate name
    local name = self.nameEntry and self.nameEntry:getText() or ""
    if not name or string.len(name) == 0 then
        table.insert(errors, "Name is required")
    elseif string.len(name) < 3 then
        table.insert(errors, "Name must be at least 3 characters long")
    elseif string.len(name) > self.nameLimit then
        table.insert(errors, "Name is too long (maximum " .. self.nameLimit .. " characters)")
    end
    
    -- Check for invalid characters in name
    if name:match("[^%w%s%-_'.]") then
        table.insert(errors, "Name contains invalid characters")
    end
    
    -- Validate description
    local description = self.descriptionEntry and self.descriptionEntry:getText() or ""
    if not description or string.len(description) == 0 then
        table.insert(errors, "Description is required")
    elseif string.len(description) < 10 then
        table.insert(errors, "Description must be at least 10 characters long")
    elseif string.len(description) > self.descriptionLimit then
        table.insert(errors, "Description is too long (maximum " .. self.descriptionLimit .. " characters)")
    end
    
    -- Validate age
    local age = self.ageSlider and self.ageSlider.currentValue or 25
    local minAge = FrameworkZ.Config.Options.CharacterMinAge or 18
    local maxAge = FrameworkZ.Config.Options.CharacterMaxAge or 80
    if age < minAge or age > maxAge then
        table.insert(errors, "Age must be between " .. minAge .. " and " .. maxAge)
    end
    
    -- Validate height
    local height = self.heightSlider and self.heightSlider.currentValue or 70
    local minHeight = FrameworkZ.Config.Options.CharacterMinHeight or 48
    local maxHeight = FrameworkZ.Config.Options.CharacterMaxHeight or 84
    if height < minHeight or height > maxHeight then
        table.insert(errors, "Height must be between " .. minHeight .. " and " .. maxHeight .. " inches")
    end
    
    -- Validate weight
    local weight = self.weightSlider and self.weightSlider.currentValue or 150
    local minWeight = FrameworkZ.Config.Options.CharacterMinWeight or 90
    local maxWeight = FrameworkZ.Config.Options.CharacterMaxWeight or 300
    if weight < minWeight or weight > maxWeight then
        table.insert(errors, "Weight must be between " .. minWeight .. " and " .. maxWeight .. " pounds")
    end
    
    -- Validate selections
    if not self.genderDropdown or self.genderDropdown.selected == 0 then
        table.insert(errors, "Gender must be selected")
    end
    
    if not self.physiqueDropdown or self.physiqueDropdown.selected == 0 then
        table.insert(errors, "Physique must be selected")
    end
    
    if not self.eyeColorDropdown or self.eyeColorDropdown.selected == 0 then
        table.insert(errors, "Eye color must be selected")
    end
    
    if not self.hairColorDropdown or self.hairColorDropdown.selected == 0 then
        table.insert(errors, "Hair color must be selected")
    end
    
    if not self.skinColorDropdown or self.skinColorDropdown.selected == 0 then
        table.insert(errors, "Skin color must be selected")
    end
    
    return #errors == 0, errors
end

function FrameworkZ.UI.CreateCharacterInfo:getCharacterData()
    local data = {}
    
    -- Basic information
    data.gender = self.genderDropdown and self.genderDropdown:getOptionText(self.genderDropdown.selected) or "Male"
    data.name = self.nameEntry and self.nameEntry:getText() or ""
    data.description = self.descriptionEntry and self.descriptionEntry:getText() or ""
    
    -- Physical attributes
    data.age = self.ageSlider and self.ageSlider.currentValue or 25
    data.height = self.heightSlider and self.heightSlider.currentValue or 70
    data.weight = self.weightSlider and self.weightSlider.currentValue or 150
    data.physique = self.physiqueDropdown and self.physiqueDropdown:getOptionText(self.physiqueDropdown.selected) or "Average"
    
    -- Appearance
    data.eyeColor = self.eyeColorDropdown and self.eyeColorDropdown:getOptionData(self.eyeColorDropdown.selected) or {r = 0.2, g = 0.4, b = 0.8}
    data.hairColor = self.hairColorDropdown and self.hairColorDropdown:getOptionData(self.hairColorDropdown.selected) or {r = 0.4, g = 0.2, b = 0.1}
    data.skinColor = self.skinColorDropdown and self.skinColorDropdown:getOptionData(self.skinColorDropdown.selected) or 1
    
    return data
end

function FrameworkZ.UI.CreateCharacterInfo:prerender()
    ISPanel.prerender(self)
end

function FrameworkZ.UI.CreateCharacterInfo:update()
    ISPanel.update(self)
    
    -- Enhanced name character counter with color coding
    if self.nameLabel and self.nameEntry and self.nameCounter then
        local usedCharacters = string.len(self.nameEntry:getText())
        local remainingCharacters = self.nameLimit - usedCharacters

        if remainingCharacters < 0 then
            self.nameEntry:setText(string.sub(self.nameEntry:getText(), 1, self.nameLimit))
            remainingCharacters = 0
        end

        self.nameCounter:setName(tostring(remainingCharacters))
        
        -- Enhanced color coding for character limits
        if remainingCharacters == 0 then
            self.nameCounter:setColor(1, 0.2, 0.2)  -- Red when at limit
            self.nameEntry.borderColor = {r=1, g=0.2, b=0.2, a=1.0}
        elseif remainingCharacters < 8 then
            self.nameCounter:setColor(1, 0.8, 0)  -- Orange when close to limit
            self.nameEntry.borderColor = {r=1, g=0.8, b=0, a=1.0}
        else
            self.nameCounter:setColor(0.4, 0.8, 0.4)  -- Green when plenty of space
            self.nameEntry.borderColor = {r=0.4, g=0.6, b=0.4, a=1.0}
        end
    end

    -- Enhanced description character counter with color coding
    if self.descriptionLabel and self.descriptionEntry and self.descriptionCounter then
        local usedCharacters = string.len(self.descriptionEntry:getText())
        local remainingCharacters = self.descriptionLimit - usedCharacters

        if remainingCharacters < 0 then
            self.descriptionEntry:setText(string.sub(self.descriptionEntry:getText(), 1, self.descriptionLimit))
            remainingCharacters = 0
        end

        self.descriptionCounter:setName(tostring(remainingCharacters))
        
        -- Enhanced color coding for character limits
        if remainingCharacters == 0 then
            self.descriptionCounter:setColor(1, 0.2, 0.2)  -- Red when at limit
            self.descriptionEntry.borderColor = {r=1, g=0.2, b=0.2, a=1.0}
        elseif remainingCharacters < 20 then
            self.descriptionCounter:setColor(1, 0.8, 0)  -- Orange when close to limit
            self.descriptionEntry.borderColor = {r=1, g=0.8, b=0, a=1.0}
        else
            self.descriptionCounter:setColor(0.4, 0.8, 0.4)  -- Green when plenty of space
            self.descriptionEntry.borderColor = {r=0.4, g=0.6, b=0.4, a=1.0}
        end
    end
end

function FrameworkZ.UI.CreateCharacterInfo:new(parameters)
	local o = {}

	o = ISPanel:new(parameters.x, parameters.y, parameters.width, parameters.height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.playerObject = parameters.playerObject
	FrameworkZ.UI.CreateCharacterInfo.instance = o

	return o
end

return FrameworkZ.UI.CreateCharacterInfo

