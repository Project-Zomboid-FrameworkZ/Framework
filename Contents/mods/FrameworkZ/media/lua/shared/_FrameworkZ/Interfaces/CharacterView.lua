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

    if not character then
        print("[CharacterView] Error: No character data provided")
        return
    end

    -- Set basic appearance
    local isFemale = (character[FZ_ENUM_CHARACTER_INFO_GENDER] == "Female")
    survivor:setFemale(isFemale)
    
    local humanVisual = survivor:getHumanVisual()
    
    -- Set skin color
    local skinColor = character[FZ_ENUM_CHARACTER_INFO_SKIN_COLOR]
    if type(skinColor) == "number" then
        humanVisual:setSkinTextureIndex(skinColor)
    else
        humanVisual:setSkinTextureIndex(SKIN_COLOR_WHITE)
    end
    
    -- Set hair
    local hairStyle = character[FZ_ENUM_CHARACTER_INFO_HAIR_STYLE]
    if hairStyle and hairStyle ~= "" then
        humanVisual:setHairModel(hairStyle)
    end
    
    local hairColor = character[FZ_ENUM_CHARACTER_INFO_HAIR_COLOR]
    if hairColor then
        local immutableColor = ImmutableColor.new(hairColor.r, hairColor.g, hairColor.b, 1)
        humanVisual:setHairColor(immutableColor)
        humanVisual:setNaturalHairColor(immutableColor)
    end
    
    -- Set beard
    local beardStyle = character[FZ_ENUM_CHARACTER_INFO_BEARD_STYLE]
    if beardStyle and beardStyle ~= "" and beardStyle ~= "None" then
        humanVisual:setBeardModel(beardStyle)
        
        -- Only set beard color if there's actually a beard
        local beardColor = character[FZ_ENUM_CHARACTER_INFO_BEARD_COLOR]
        if beardColor then
            local immutableColor = ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b, 1)
            humanVisual:setBeardColor(immutableColor)
            humanVisual:setNaturalBeardColor(immutableColor)
        end
    else
        humanVisual:setBeardModel("")
    end
    
    -- Clear existing worn items
    local equipmentSlots = FrameworkZ.Enumerations and FrameworkZ.Enumerations.EquipmentSlots or {}
    for _, slot in ipairs(equipmentSlots) do
        survivor:setWornItem(slot, nil)
    end
    
    -- Restore equipment from Equipment table
    local equipment = character[FZ_ENUM_CHARACTER_INFO_EQUIPMENT]
    if equipment then
        for slot, itemData in pairs(equipment) do
            local itemType, itemColor, itemCondition
            
            -- Handle both new format (table) and legacy format (string)
            if type(itemData) == "table" then
                itemType = itemData.id
                itemColor = itemData.color
                itemCondition = itemData.condition
            else
                itemType = itemData
            end
            
            if itemType and itemType ~= "" and itemType ~= "None" then
                local item = InventoryItemFactory.CreateItem(itemType)
                if item then
                    -- Apply condition before equipping
                    if itemCondition and item.setCondition then
                        item:setCondition(itemCondition)
                    end
                    
                    -- Equip item first
                    survivor:setWornItem(slot, item)
                    
                    -- Apply color after equipping using Inventories method (handles edge cases)
                    FrameworkZ.Inventories:ApplyEquipmentColor(item, itemData)
                end
            end
        end
    end
    
    -- Update the character preview
    self.characterPreview:setSurvivorDesc(survivor)
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
    -- Light-weight reinit: reuse existing preview/survivor; update fields and appearance without rebuilding UI
    self:setCharacter(character)
    self:setName(character[FZ_ENUM_CHARACTER_INFO_NAME])
    self:setDescription(character[FZ_ENUM_CHARACTER_INFO_DESCRIPTION])
    if self.characterNameLabel then
        -- Recenter the name each time, since text width can change per character
        local nameX = self.uiHelper.GetMiddle(self.width, UIFont.Medium, self.name)
        self.characterNameLabel:setX(nameX)
        self.characterNameLabel.name = self.name
    end
    -- Update description lines minimally: remove old labels and recreate
    if self.descriptionLabels then
        for _, lbl in pairs(self.descriptionLabels) do self:removeChild(lbl) end
        self.descriptionLabels = {}
    end
    local descriptionLines = self:getDescriptionLines(self.description)
    -- Position description directly under the preview panel
    local y = (self.characterPreview and (self.characterPreview.y + self.characterPreview.height))
              or (self.characterNameLabel and (self.characterNameLabel.y + self.characterNameLabel.height + 4))
              or 0
    local FONT_HEIGHT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    for k, v in ipairs(descriptionLines) do
        local x = self.uiHelper.GetMiddle(self.width, UIFont.Small, v)
        local descriptionLabel = ISLabel:new(x, y, FONT_HEIGHT_SMALL, v, 1, 1, 1, 0.9, UIFont.Small, true)
        descriptionLabel:initialise()
        self:addChild(descriptionLabel)
        table.insert(self.descriptionLabels, descriptionLabel)
        if k <= 3 then y = y + descriptionLabel.height else break end
    end
    -- Apply appearance
    self:updateAppearance()
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
