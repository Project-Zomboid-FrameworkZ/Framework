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
    local isFemale = (self.character.INFO_GENDER == "Female" and true) or (self.character.INFO_GENDER == "Male" and false)
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
    --self.characterPreview:setSurvivorDesc(self.survivor)
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

    for k, v in ipairs (FrameworkZ.Characters.EquipmentSlots) do
        survivor:setWornItem(v, nil)
    end

    local headItem = character.EQUIPMENT_SLOT_HEAD and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_HEAD.id) or nil
    local faceItem = character.EQUIPMENT_SLOT_FACE and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_FACE.id) or nil
    local earsItem = character.EQUIPMENT_SLOT_EARS and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_EARS.id) or nil
    local backpackItem = character.EQUIPMENT_SLOT_BACKPACK and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_BACKPACK.id) or nil
    local glovesItem = character.EQUIPMENT_SLOT_GLOVES and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_GLOVES.id) or nil
    local undershirtItem = character.EQUIPMENT_SLOT_UNDERSHIRT and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_UNDERSHIRT.id) or nil
    local overshirtItem = character.EQUIPMENT_SLOT_OVERSHIRT and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_OVERSHIRT.id) or nil
    local vestItem = character.EQUIPMENT_SLOT_VEST and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_VEST.id) or nil
    local beltItem = character.EQUIPMENT_SLOT_BELT and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_BELT.id) or nil
    local pantsItem = character.EQUIPMENT_SLOT_PANTS and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_PANTS.id) or nil
    local socksItem = character.EQUIPMENT_SLOT_SOCKS and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_SOCKS.id) or nil
    local shoesItem = character.EQUIPMENT_SLOT_SHOES and InventoryItemFactory.CreateItem(character.EQUIPMENT_SLOT_SHOES.id) or nil

    survivor:getHumanVisual():setSkinTextureIndex(character.INFO_SKIN_COLOR)
    survivor:getHumanVisual():setHairModel(character.INFO_HAIR_STYLE)
    survivor:getHumanVisual():setBeardModel(character.INFO_BEARD_STYLE)

    local immutableColor = ImmutableColor.new(character.INFO_HAIR_COLOR.r, character.INFO_HAIR_COLOR.g, character.INFO_HAIR_COLOR.b, 1)

    survivor:getHumanVisual():setHairColor(immutableColor)
    survivor:getHumanVisual():setBeardColor(immutableColor)
    survivor:getHumanVisual():setNaturalHairColor(immutableColor)
    survivor:getHumanVisual():setNaturalBeardColor(immutableColor)

    if headItem then survivor:setWornItem(EQUIPMENT_SLOT_HEAD, headItem) end
    if faceItem then survivor:setWornItem(EQUIPMENT_SLOT_FACE, faceItem) end
    if earsItem then survivor:setWornItem(EQUIPMENT_SLOT_EARS, earsItem) end
    if backpackItem then survivor:setWornItem(EQUIPMENT_SLOT_BACKPACK, backpackItem) end
    if glovesItem then survivor:setWornItem(EQUIPMENT_SLOT_GLOVES, glovesItem) end
    if undershirtItem then survivor:setWornItem(EQUIPMENT_SLOT_UNDERSHIRT, undershirtItem) end
    if overshirtItem then survivor:setWornItem(EQUIPMENT_SLOT_OVERSHIRT, overshirtItem) end
    if vestItem then survivor:setWornItem(EQUIPMENT_SLOT_VEST, vestItem) end
    if beltItem then survivor:setWornItem(EQUIPMENT_SLOT_BELT, beltItem) end
    if pantsItem then survivor:setWornItem(EQUIPMENT_SLOT_PANTS, pantsItem) end
    if socksItem then survivor:setWornItem(EQUIPMENT_SLOT_SOCKS, socksItem) end
    if shoesItem then survivor:setWornItem(EQUIPMENT_SLOT_SHOES, shoesItem) end

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
    self:setCharacter(character)
    self:setName(character.INFO_NAME)
    self:setDescription(character.INFO_DESCRIPTION)
    self:initialise()
end

function FrameworkZ.UI.CharacterView:getDescriptionLines(description)
    local lines = {}
    local line = ""
    local lineLength = 0
    local words = {}

    for word in string.gmatch(description, "%S+") do
        table.insert(words, word)
    end

    if #words == 0 then
        return {description}
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
