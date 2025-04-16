FrameworkZ = FrameworkZ or {}

require "ISUI/ISPanel"

PFW_CreateCharacterAppearance = ISPanel:derive("PFW_CreateCharacterAppearance")

local yOffset = 0

function PFW_CreateCharacterAppearance:initialise()
    ISPanel.initialise(self)

    local isFemale = (self.gender == "Female" and true) or (self.gender == "Male" and false)
    self.survivor = SurvivorFactory:CreateSurvivor(SurvivorType.Neutral, isFemale)
    self.survivor:setFemale(isFemale)
    self.survivor:getHumanVisual():setSkinTextureIndex(self.skinColor)

    local immutableColor = ImmutableColor.new(self.hairColor.r, self.hairColor.g, self.hairColor.b, 1)

    self.survivor:getHumanVisual():setHairColor(immutableColor)
    self.survivor:getHumanVisual():setBeardColor(immutableColor)
    self.survivor:getHumanVisual():setNaturalHairColor(immutableColor)
    self.survivor:getHumanVisual():setNaturalBeardColor(immutableColor)

    self.uiHelper = FrameworkZ.UI

    local title = "Appearance"
    local subtitle = "Customize your character's appearance."
    local factionWidth = 500
    local factionHeight = 300
    local dropdownWidth = self.width * 0.5
    local middleX = self.width / 2
    local quarterX = self.width / 4
    self.factionsClothing = FrameworkZ.Factions:GetFactionByID(self.faction).clothing
    self.initialFaction = nil
    local entryWidth = 200
    local xPadding = self.width * 0.1
    local entryX = xPadding
    local labelX = xPadding - 5

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

    self.characterPreview = PFW_CharacterPreview:new(self.width - 200, yOffset, 200, 400)
    self.characterPreview:initialise()
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)
    self:addChild(self.characterPreview)

    self.hairLabel = ISLabel:new(entryX - 5, yOffset, 25, "Hair:", 1, 1, 1, 1, UIFont.Large, false)
    self.hairLabel:initialise()
    self:addChild(self.hairLabel)

    local hairStyles = getAllHairStyles(isFemale)

    self.hairDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25, self, self.onHairChanged)

    for i = 1, hairStyles:size() do
        local styleId = hairStyles:get(i - 1)
        local hairStyle = isFemale and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
        local label = styleId

        if label == "" then
            label = getText("IGUI_Hair_Bald")
        else
            label = getText("IGUI_Hair_" .. label)
        end

        if not hairStyle:isNoChoose() then
            self.hairDropdown:addOptionWithData(label, hairStyles:get(i - 1))
        end
    end

    self.hairDropdown:initialise()
    self:onHairChanged(self.hairDropdown)
    self:addChild(self.hairDropdown)

    yOffset = yOffset + 30

    self.beardLabel = ISLabel:new(entryX - 5, yOffset, 25, "Beard:", 1, 1, 1, 1, UIFont.Large, false)
    self.beardLabel:initialise()
    self:addChild(self.beardLabel)

    self.beardDropdown = ISComboBox:new(entryX, yOffset, entryWidth, 25, self, self.onBeardChanged)

    if not isFemale then
        local beardStyles = getAllBeardStyles()

        for i = 1, beardStyles:size() do
            local label = beardStyles:get(i - 1)

            if label == "" then
                label = getText("IGUI_Beard_None")
            else
                label = getText("IGUI_Beard_" .. label);
            end

            self.beardDropdown:addOptionWithData(label, beardStyles:get(i - 1))
        end
    end

    if isFemale then
        self.beardDropdown:addOptionWithData("N/A", nil)
    end

    self.beardDropdown:initialise()
    self:onBeardChanged(self.beardDropdown)
    self:addChild(self.beardDropdown)

    yOffset = yOffset + 30

    if self.factionsClothing then
        self.headLabel, self.headDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Head:", "Hat", self.factionsClothing.head)
        self.faceLabel, self.faceDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Face:", "Mask", self.factionsClothing.face)
        self.earsLabel, self.earsDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Ears:", "Ears", self.factionsClothing.ears)
        self.backpackLabel, self.backpackDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Backpack:", "Back", self.factionsClothing.backpack)
        self.glovesLabel, self.glovesDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Gloves:", "Hands", self.factionsClothing.gloves)
        self.undershirtLabel, self.undershirtDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Undershirt:", "Tshirt", self.factionsClothing.undershirt)
        self.overshirtLabel, self.overshirtDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Overshirt:", "Shirt", self.factionsClothing.overshirt)
        self.vestLabel, self.vestDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Vest:", "TorsoExtraVest", self.factionsClothing.vest)
        self.beltLabel, self.beltDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Belt:", "Belt", self.factionsClothing.belt)
        self.pantsLabel, self.pantsDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Pants:", "Pants", self.factionsClothing.pants)
        self.socksLabel, self.socksDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Socks:", "Socks", self.factionsClothing.socks)
        self.shoesLabel, self.shoesDropdown = self:addClothingOption(entryX, yOffset, 25, entryWidth, "Shoes:", "Shoes", self.factionsClothing.shoes)
    end
end

function PFW_CreateCharacterAppearance:addClothingOption(x, y, height, entryWidth, labelText, clothingLocation, clothingTable)
    if not clothingTable then return nil, nil end

    local label = ISLabel:new(x - 5, y, height, labelText, 1, 1, 1, 1, UIFont.Large, false)
    label:initialise()
    self:addChild(label)

    local dropdown = ISComboBox:new(x, y, entryWidth, height,self, self.onClothingChanged)

    if clothingTable then
        for k, v in pairs(clothingTable) do
            dropdown:addOptionWithData(v, {location = clothingLocation, itemID = k})
        end
    end

    dropdown:addOptionWithData("None", {location = clothingLocation, itemID = nil})
    dropdown:initialise()
    self:onClothingChanged(dropdown)
    self:addChild(dropdown)

    if not clothingTable then
        label:setVisible(false)
        dropdown:setVisible(false)

        return label, dropdown
    end
    yOffset = yOffset + 30

    return label, dropdown
end

function PFW_CreateCharacterAppearance:onHairChanged(dropdown)
	local hair = dropdown:getOptionData(dropdown.selected)

	self.hairType = dropdown.selected - 1
	self.survivor:getHumanVisual():setHairModel(hair)
    self.characterPreview:setSurvivorDesc(self.survivor)
end

function PFW_CreateCharacterAppearance:onBeardChanged(dropdown)
	local beard = dropdown:getOptionData(dropdown.selected)

	self.beardType = dropdown.selected - 1
	self.survivor:getHumanVisual():setBeardModel(beard)
    self.characterPreview:setSurvivorDesc(self.survivor)
end

function PFW_CreateCharacterAppearance:onClothingChanged(dropdown)
    if not dropdown then return end

    local dropdownData = dropdown:getOptionData(dropdown.selected)
    local itemID = dropdownData.itemID
    local location = dropdownData.location
    local item = InventoryItemFactory.CreateItem(itemID)

    self.survivor:setWornItem(location, nil)

    if item then
        self.survivor:setWornItem(location, item)
    end

    self.characterPreview:setSurvivorDesc(self.survivor)
end

function PFW_CreateCharacterAppearance:resetGender(newGender)
    if self.survivor and self.gender ~= newGender then
        self.gender = newGender

        local isFemale = (self.gender == "Female" and true) or (self.gender == "Male" and false)
        self.survivor = SurvivorFactory:CreateSurvivor(SurvivorType.Neutral, isFemale)
        self.survivor:setFemale(isFemale)
        self:onClothingChanged(self.headDropdown)
        self:onClothingChanged(self.undershirtDropdown)
        self:onClothingChanged(self.overshirtDropdown)
        self:onClothingChanged(self.pantsDropdown)
        self:onClothingChanged(self.socksDropdown)
        self:onClothingChanged(self.shoesDropdown)
        self.characterPreview:setSurvivorDesc(self.survivor)

        self:onHairChanged(self.hairDropdown)

        self.wasGenderUpdated = true
    end
end

function PFW_CreateCharacterAppearance:resetHairColor()
    if self.survivor then
        local immutableColor = ImmutableColor.new(self.hairColor.r, self.hairColor.g, self.hairColor.b, 1)

        self.survivor:getHumanVisual():setHairColor(immutableColor)
        self.survivor:getHumanVisual():setBeardColor(immutableColor)
        self.survivor:getHumanVisual():setNaturalHairColor(immutableColor)
        self.survivor:getHumanVisual():setNaturalBeardColor(immutableColor)

        self.characterPreview:setSurvivorDesc(self.survivor)
    end
end

function PFW_CreateCharacterAppearance:resetHairStyles()
    if self.survivor then
        local hairStyles = getAllHairStyles(self.survivor:isFemale())

        self.hairDropdown:clear()

        for i = 1, hairStyles:size() do
            local styleId = hairStyles:get(i - 1)
            local hairStyle = self.survivor:isFemale() and getHairStylesInstance():FindFemaleStyle(styleId) or getHairStylesInstance():FindMaleStyle(styleId)
            local label = styleId

            if label == "" then
                label = getText("IGUI_Hair_Bald")
            else
                label = getText("IGUI_Hair_" .. label)
            end

            if not hairStyle:isNoChoose() then
                self.hairDropdown:addOptionWithData(label, hairStyles:get(i - 1))
            end
        end

        if self.wasGenderUpdated then
            self.hairDropdown:select("Bald")
        end

        self:onHairChanged(self.hairDropdown)
    end
end

function PFW_CreateCharacterAppearance:resetBeardStyles()
    if self.survivor then
        local isFemale = (self.gender == "Female" and true) or (self.gender == "Male" and false)

        if not isFemale then
            local beardStyles = getAllBeardStyles()

            self.beardDropdown:clear()

            for i = 1, beardStyles:size() do
                local label = beardStyles:get(i - 1)

                if label == "" then
                    label = getText("IGUI_Beard_None")
                else
                    label = getText("IGUI_Beard_" .. label)
                end

                self.beardDropdown:addOptionWithData(label, beardStyles:get(i - 1))
            end

            self:onBeardChanged(self.beardDropdown)
        else
            self.beardDropdown:clear()
            self.beardDropdown:addOptionWithData("N/A", nil)
            self.beardDropdown:select("N/A")

            self:onBeardChanged(self.beardDropdown)
        end
    end
end

function PFW_CreateCharacterAppearance:resetSkinColor()
    if self.survivor then
        self.survivor:getHumanVisual():setSkinTextureIndex(self.skinColor)
        self.characterPreview:setSurvivorDesc(self.survivor)
    end
end

function PFW_CreateCharacterAppearance:render()
    ISPanel.render(self)
end

function PFW_CreateCharacterAppearance:update()
    ISPanel.update(self)
end

function PFW_CreateCharacterAppearance:new(parameters)
	local o = {}

	o = ISPanel:new(parameters.x, parameters.y, parameters.width, parameters.height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.playerObject = parameters.playerObject
    o.faction = parameters.faction
    o.gender = parameters.gender
    o.skinColor = parameters.skinColor
    o.hairColor = parameters.hairColor
	PFW_CreateCharacterAppearance.instance = o

	return o
end

return PFW_CreateCharacterAppearance
