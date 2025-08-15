FrameworkZ.UI.CharacterView = FrameworkZ.UI.CharacterView or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CharacterView, "CharacterView")

function FrameworkZ.UI.CharacterView:initialise()
    ISPanel.initialise(self)

    local FONT_HEIGHT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local FONT_HEIGHT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
    local FONT_HEIGHT_LARGE = getTextManager():getFontHeight(UIFont.Large)

    if self.characterNameLabel then
        self:removeChild(self.characterNameLabel)
    end

    if self.characterPreview then
        self:removeChild(self.characterPreview)
    end

    if self.descriptionLabels then
        for k, v in pairs(self.descriptionLabels) do
            self:removeChild(v)
        end
    end

    self.descriptionLabels = {}
    self.uiHelper = FrameworkZ.UI
    local descriptionLines = self:getDescriptionLines(self.description)
    local descriptionHeight = FONT_HEIGHT_SMALL * 4
    local isFemale = (self.character[FZ_ENUM_CHARACTER_INFO_GENDER] == "Female" and true) or (self.character[FZ_ENUM_CHARACTER_INFO_GENDER] == "Male" and false)
    local x = self.uiHelper.GetMiddle(self.width, UIFont.Medium, self.name)
    local y = 0

    self.survivor = SurvivorFactory:CreateSurvivor(SurvivorType.Neutral, isFemale)
    self.survivor:setFemale(isFemale)

    self.characterNameLabel = ISLabel:new(x, 0, FONT_HEIGHT_MEDIUM, self.name, 1, 1, 1, 1, UIFont.Medium, true)
    self.characterNameLabel:initialise()
    self:addChild(self.characterNameLabel)

    local previewHeight = self.height - self.characterNameLabel.height - descriptionHeight
    y = y + self.characterNameLabel.height + 4

    self.characterPreview = FrameworkZ.UI.CharacterPreview:new(0, y, self.width, previewHeight, "EventIdle", self.defaultDirection)
    self.characterPreview:initialise()
    self.characterPreview:removeChild(self.characterPreview.animCombo)
    self.characterPreview:setCharacter(self.isoPlayer)
    self.characterPreview:setSurvivorDesc(self.survivor)
    self:updateAppearance()
    self:addChild(self.characterPreview)

    y = y + previewHeight

    for k, v in pairs(descriptionLines) do
        x = self.uiHelper.GetMiddle(self.width, UIFont.Small, v)

        local totalLines = #descriptionLines
        local adjustedK = k - 1
        local alphaStart = 1.0
        local alphaMin = 0.2
        local decayRate = 5
        local alpha

        if totalLines == 1 then
            alpha = alphaStart -- Directly set to alphaStart if there's only one line
        else
            alpha = alphaMin + (alphaStart - alphaMin) * ((1 - adjustedK / (totalLines - 1)) ^ decayRate)
            alpha = math.max(alpha, alphaMin)
        end

        local descriptionLabel = ISLabel:new(x, y, FONT_HEIGHT_SMALL, v, 1, 1, 1, alpha, UIFont.Small, true)
        descriptionLabel:initialise()
        self:addChild(descriptionLabel)

        table.insert(self.descriptionLabels, descriptionLabel)

        if k <= 3 then
            y = y + descriptionLabel.height
        else
            -- For more than 3 lines, the loop breaks after adding "..." to the last displayed line
            break
        end
    end
end

function FrameworkZ.UI.CharacterView:render()
    ISPanel.prerender(self)

    -- Render the character preview and any other UI elements here
end

function FrameworkZ.UI.CharacterView:updateAppearance()
    local survivor = self.survivor
    local character = self.character

    -- Debug: Check if character data exists
    if not character then
        print("[CharacterView] Error: No character data provided")
        return
    end

    print("[CharacterView] updateAppearance called with character data:")
    print("[CharacterView] Character name: " .. tostring(character[FZ_ENUM_CHARACTER_INFO_NAME]))
    print("[CharacterView] Character keys:")
    for key, value in pairs(character) do
        if type(value) == "table" and value.id then
            print("  " .. tostring(key) .. ": equipment item " .. tostring(value.id))
        elseif type(value) == "table" then
            print("  " .. tostring(key) .. ": table")
        else
            print("  " .. tostring(key) .. ": " .. tostring(value))
        end
    end

    -- Use CharacterDataManager to restore appearance
    local newSurvivor, message = FrameworkZ.CharacterDataManager:RestoreSurvivorAppearance(survivor, character)
    if not newSurvivor then
        print("[CharacterView] Warning: Failed to restore survivor appearance: " .. (message or "Unknown error"))
    else
        print("[CharacterView] " .. message)
        self.survivor = newSurvivor
    end

    -- Update the character preview
    self.characterPreview:setSurvivorDesc(newSurvivor)
end

function FrameworkZ.UI.CharacterView:setCharacter(character)
    self.character = character
end

function FrameworkZ.UI.CharacterView:setName(name)
    self.name = name
end

function FrameworkZ.UI.CharacterView:setDescription(description)
    self.description = description
end

function FrameworkZ.UI.CharacterView:reinitialize(character)
    print("[CharacterView] reinitialize called with character:")
    print("[CharacterView] Character name: " .. tostring(character[FZ_ENUM_CHARACTER_INFO_NAME]))
    print("[CharacterView] Character has " .. tostring(#character) .. " indexed entries and equipment data:")
    
    -- Check for equipment data specifically
    local equipmentCount = 0
    for key, value in pairs(character) do
        if type(value) == "table" and value.id then
            equipmentCount = equipmentCount + 1
            print("  Equipment " .. tostring(key) .. ": " .. tostring(value.id))
        end
    end
    print("[CharacterView] Total equipment items found: " .. equipmentCount)
    
    self:setCharacter(character)
    self:setName(character[FZ_ENUM_CHARACTER_INFO_NAME])
    self:setDescription(character[FZ_ENUM_CHARACTER_INFO_DESCRIPTION])

    self:initialise()
end

function FrameworkZ.UI.CharacterView:getDescriptionLines(description)
    local lines = {}
    local line = ""
    local lineLength = 0
    local words = {}

    -- Handle nil or empty description
    if not description or description == "" then
        return {""}
    end

    -- Trim whitespace and check if anything remains
    local trimmedDescription = string.gsub(description, "^%s*(.-)%s*$", "%1")
    if trimmedDescription == "" then
        return {""}
    end

    for word in string.gmatch(trimmedDescription, "%S+") do
        table.insert(words, word)
    end

    if #words == 0 then
        return {""}
    end

    for i = 1, #words do
        local word = words[i]
        local wordLength = string.len(word) + 1

        if lineLength + wordLength <= 30 or lineLength == 0 then
            line = lineLength == 0 and word or line .. " " .. word
            lineLength = lineLength + wordLength
        else
            table.insert(lines, line)
            line = word
            lineLength = wordLength
        end
    end

    if line ~= "" then
        table.insert(lines, line)
    end

    return lines
end

function FrameworkZ.UI.CharacterView:new(x, y, width, height, isoPlayer, character, name, description, defaultDirection)
    local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.isoPlayer = isoPlayer
    o.character = character
    o.name = name
    o.description = description
    o.defaultDirection = defaultDirection
	FrameworkZ.UI.CharacterView.instance = o

	return o
end

return FrameworkZ.UI.CharacterView
