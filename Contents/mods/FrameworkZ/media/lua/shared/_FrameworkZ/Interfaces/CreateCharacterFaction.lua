FrameworkZ.UI.CreateCharacterFaction = FrameworkZ.UI.CreateCharacterFaction or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CreateCharacterFaction, "CreateCharacterFaction")

function FrameworkZ.UI.CreateCharacterFaction:initialise()
    ISPanel.initialise(self)

    self.uiHelper = FrameworkZ.UI
    local title = "Faction"
    local subtitle = "Select a faction for your character."
    local factionWidth = 500
    local factionHeight = 300
    local dropdownWidth = self.width * 0.5
    local middleX = self.width / 2
    local yOffset = 0
    local factionsList = FrameworkZ.Factions.List
    self.initialFaction = nil

    -- Get first available faction:
    for k, v in pairs(factionsList) do
        if not v.requiresWhitelist then
            self.initialFaction = {k = k, v = v}
            break
        end
    end

    self.faction = self.initialFaction and self.initialFaction.k or ""

    yOffset = self.uiHelper.GetHeight(UIFont.Title, title)

    self.title = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Title, title), yOffset, 25, title, 1, 1, 1, 1, UIFont.Title, true)
    self.title:initialise()
	self:addChild(self.title)

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Large, subtitle)

    self.subtitle = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Large, subtitle), yOffset, 25, subtitle, 1, 1, 1, 1, UIFont.Large, true)
    self.subtitle:initialise()
    self:addChild(self.subtitle)

    yOffset = yOffset + 45

    self.factionImage = ISImage:new(self.width / 2 - factionWidth / 2, yOffset, factionWidth, factionHeight, getTexture(self.initialFaction and self.initialFaction.v and self.initialFaction.v.logo or "media/textures/factions/missing-logo.png"))
    self.factionImage.scaledWidth = self.factionImage:getWidth()
    self.factionImage.scaledHeight = self.factionImage:getHeight()
    self.factionImage:initialise()
    self:addChild(self.factionImage)

    yOffset = yOffset + 300

    self.factionDropdown = ISComboBox:new(middleX - factionWidth / 2, yOffset, factionWidth, 25, self, self.onFactionSelected)
    self.factionDropdown:addOptionWithData(self.initialFaction and self.initialFaction.v and self.initialFaction.v.name, self.initialFaction and self.initialFaction.k)

    for k, v in pairs(factionsList) do
        -- if get player get whitelisted factions == true then add option

        if self.initialFaction and v ~= self.initialFaction.v and not v.requiresWhitelist then
            self.factionDropdown:addOptionWithData(v.name, k)
        elseif not self.initialFaction then
            self.factionDropdown:addOptionWithData(v.name, k)
        end
    end
    
    self.factionDropdown:initialise()
    self:addChild(self.factionDropdown)

    yOffset = yOffset + 30

    local factionDescription = self.initialFaction and self.initialFaction.v and ('"' .. self.initialFaction.v.description .. '"') or ""

    self.factionDescription = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Medium, factionDescription), yOffset, 25, factionDescription, 1, 1, 1, 1, UIFont.Medium, true)
    self.factionDescription:initialise()
    self:addChild(self.factionDescription)
end

function FrameworkZ.UI.CreateCharacterFaction:onFactionSelected(dropdown)
    local factionID = dropdown:getOptionData(dropdown.selected)
    local faction = FrameworkZ.Factions:GetFactionByID(factionID)

    if faction then
        self.faction = faction.id
        local factionDescription = ('"' .. faction.description .. '"') or ""
        
        self.factionImage.texture = getTexture(faction.logo)
        self.factionDescription:setName(factionDescription)
        self.factionDescription:setX(self.uiHelper.GetMiddle(self.width, UIFont.Medium, factionDescription))
    end
end

function FrameworkZ.UI.CreateCharacterFaction:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.CreateCharacterFaction:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.CreateCharacterFaction:new(parameters)
	local o = {}

	o = ISPanel:new(parameters.x, parameters.y, parameters.width, parameters.height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.playerObject = parameters.playerObject
    o.faction = ""
	FrameworkZ.UI.CreateCharacterFaction.instance = o

	return o
end

return FrameworkZ.UI.CreateCharacterFaction
