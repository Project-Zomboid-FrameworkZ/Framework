FrameworkZ.UI.TabCharacter = FrameworkZ.UI.TabCharacter or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.TabCharacter, "TabCharacter")

local TAB_CHARACTER_WIDTH = getCore():getScreenWidth() * 0.3
local TAB_CHARACTER_HEIGHT = getCore():getScreenHeight()
local TAB_CHARACTER_MARGIN_X = 20
local TAB_CHARACTER_MARGIN_Y = 20
local RELATIONSHIP_TYPES = {"Friend", "Acquaintance", "Rival", "Family", "Neutral"}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function statFraction(value, maxValue)
    if not value then return 0 end
    if not maxValue or maxValue <= 0 then return 0 end
    return clamp(value / maxValue, 0, 1)
end

local function statColor(value, maxValue)
    local fraction = statFraction(value, maxValue)
    if fraction >= 0.7 then
        return {r=0.2, g=0.9, b=0.35, a=1}
    elseif fraction >= 0.35 then
        return {r=0.9, g=0.8, b=0.2, a=1}
    end
    return {r=0.9, g=0.2, b=0.2, a=1}
end

local function safeString(value, fallback)
    if value == nil or value == "" then return fallback end
    return tostring(value)
end

local function countLines(text)
    local count = 1
    for _ in text:gmatch("\n") do
        count = count + 1
    end
    return count
end

function FrameworkZ.UI.TabCharacter:initialise()
    ISPanel.initialise(self)

    self.contentPanel = ISPanel:new(0, 0, self:getWidth(), self:getHeight())
    self.contentPanel.backgroundColor = {r=0, g=0, b=0, a=0}
    self.contentPanel.borderColor = {r=0, g=0, b=0, a=0}
    self.contentPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end
    self.contentPanel.prerender = function(self2)
        self:setStencilRect(self2:getX(), self2:getY(), self2:getWidth(), self2:getHeight())
        ISPanel.prerender(self2)
    end
    self.contentPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end
    self.contentPanel:initialise()
    self.contentPanel:instantiate()
    self:addChild(self.contentPanel)

    local username = self.isoPlayer and self.isoPlayer:getUsername() or nil
    if self.character == nil and username and FrameworkZ.Players and FrameworkZ.Players.GetLoadedCharacterByID then
        self.character = FrameworkZ.Players:GetLoadedCharacterByID(username)
    end
    self.characterName = self.character and (self.character:GetName() or "Unknown") or "Unknown"
    self.characterDescription = self.character and (self.character:GetDescription() or "") or ""
    self.relationshipSelection = nil

    local titleText = "My Character"
    local fontTitle = UIFont.Title
    local titleWidth = getTextManager():MeasureStringX(fontTitle, titleText)
    local titleHeight = getTextManager():MeasureStringY(fontTitle, titleText)
    local titlePaddingTop = 50
    local titlePaddingBottom = 25
    local titleX = (self:getWidth() - titleWidth) / 2
    local titleY = TAB_CHARACTER_MARGIN_Y + titlePaddingTop

    self.titleLabel = ISLabel:new(titleX, titleY, titleHeight, titleText, 1, 1, 1, 1, fontTitle, true)
    self.titleLabel:initialise()
    self.contentPanel:addChild(self.titleLabel)

    self.closeButton = FrameworkZ.UserInterfaces:CreateHugeButton(self.contentPanel, self:getWidth() - TAB_CHARACTER_MARGIN_X, TAB_CHARACTER_MARGIN_Y, "X", self, FrameworkZ.UI.TabPanel.onMenuSelect)
    self.closeButton:setX(self:getWidth() - self.closeButton:getWidth() - TAB_CHARACTER_MARGIN_X)
    self.closeButton.internal = "CLOSE"

    local contentTop = self.titleLabel:getBottom() + titlePaddingBottom
    local previewHeight = math.max(220, self:getHeight() * 0.32)
    local infoWidth = self:getWidth() - TAB_CHARACTER_MARGIN_X * 2
    local infoX = TAB_CHARACTER_MARGIN_X
    local nextY = contentTop
    local fontHeightSmall = getTextManager():getFontHeight(UIFont.Small)
    local fontHeightMedium = getTextManager():getFontHeight(UIFont.Medium)

    self.characterView = FrameworkZ.UI.CharacterView:new(
        infoX,
        nextY,
        infoWidth,
        previewHeight,
        self.isoPlayer,
        self.character,
        self.characterName,
        self.characterDescription,
        IsoDirections.S
    )
    self.characterView:initialise()
    self.contentPanel:addChild(self.characterView)

    if self.character then
        self.characterView:setCharacter(self.character)
        self.characterView:setName(self.characterName)
        self.characterView:setDescription(self.characterDescription)
        self.characterView:reinitialize(self.character)
    end

    nextY = self.characterView:getBottom() + 10

    local factionText = "Faction: " .. safeString(self.character and self.character:GetFaction() or "Unknown", "Unknown")
    local ageText = "Age: " .. safeString(self.character and self.character:GetAge() or "Unknown", "Unknown")
    local weightText = "Weight: " .. safeString(self.character and self.character:GetWeight() or "Unknown", "Unknown")
    local physiqueText = "Physique: " .. safeString(self.character and self.character:GetPhysique() or "Unknown", "Unknown")
    local aliasText = "Alias: " .. safeString(self.characterName, "Unknown")
    local professionText = "Profession: " .. self:getProfessionText()

    local summaryText = factionText .. "\n" .. ageText .. "\n" .. weightText .. "\n" .. physiqueText .. "\n" .. aliasText .. "\n" .. professionText
    self.summaryLabel = ISLabel:new(infoX, nextY, fontHeightSmall * countLines(summaryText), summaryText, 1, 1, 1, 1, UIFont.Small, true)
    self.summaryLabel:initialise()
    self.contentPanel:addChild(self.summaryLabel)
    nextY = self.summaryLabel:getBottom() + 12

    local statsData = {
        {label = "Health", value = self:getStatValue("Health"), max = 100},
        {label = "Hunger", value = self:getStatValue("Hunger"), max = 100},
        {label = "Stamina", value = self:getStatValue("Stamina"), max = 100},
        {label = "Fatigue", value = self:getStatValue("Fatigue"), max = 100},
        {label = "Stress", value = self:getStatValue("Stress"), max = 100},
        {label = "Pain", value = self:getStatValue("Pain"), max = 100}
    }

    local BAR_ROW_HEIGHT = 26
    local BAR_LABEL_HEIGHT = 14
    local BAR_HEIGHT = 8

    self.statBarPanels = {}
    for _, stat in ipairs(statsData) do
        local row = ISPanel:new(infoX, nextY, infoWidth, BAR_ROW_HEIGHT)
        row.backgroundColor = {r=0, g=0, b=0, a=0}
        row.borderColor = {r=0, g=0, b=0, a=0}
        row.stat = stat
        row.render = function(self2)
            ISPanel.render(self2)

            local color = statColor(self2.stat.value, self2.stat.max)
            local barY = BAR_LABEL_HEIGHT
            self2:drawRect(0, barY, self2:getWidth(), BAR_HEIGHT, 0.35, 0.2, 0.2, 0.2)
            self2:drawProgressBar(0, barY, self2:getWidth(), BAR_HEIGHT, statFraction(self2.stat.value, self2.stat.max), color)

            local labelText = self2.stat.label .. ": " .. tostring(math.floor(self2.stat.value or 0)) .. "/" .. tostring(self2.stat.max or 100)
            self2:drawText(labelText, 0, 0, 1, 1, 1, 1, UIFont.Small)
        end
        row:initialise()
        self.contentPanel:addChild(row)
        table.insert(self.statBarPanels, row)
        nextY = row:getBottom() + 2
    end
    nextY = nextY + 14

    self.descriptionLabel = ISLabel:new(infoX, nextY, fontHeightMedium, "Description", 1, 1, 1, 1, UIFont.Medium, true)
    self.descriptionLabel:initialise()
    self.contentPanel:addChild(self.descriptionLabel)
    nextY = self.descriptionLabel:getBottom() + 6

    self.descriptionEntry = FrameworkZ.Interfaces:CreateTextEntry({
        x = infoX,
        y = nextY,
        width = infoWidth,
        height = 70,
        text = self.characterDescription,
        parent = self.contentPanel,
        multipleLines = true,
        theme = "Default"
    })
    self.descriptionEntry:setMaxLines(4)
    nextY = self.descriptionEntry:getBottom() + 8

    self.saveDescriptionButton = FrameworkZ.Interfaces:CreateButton({
        x = infoX + infoWidth - 150,
        y = nextY,
        width = 150,
        height = 25,
        title = "Save Description",
        target = self,
        onClick = FrameworkZ.UI.TabCharacter.onSaveDescription,
        parent = self.contentPanel,
        theme = "Basic",
        font = FZ_FONT_MEDIUM
    })
    self.saveDescriptionButton.internal = "SAVE_DESCRIPTION"
    nextY = self.saveDescriptionButton:getBottom() + 16

    local traitsText = "Traits: " .. self:getTraitsText()
    self.traitsLabel = ISLabel:new(infoX, nextY, fontHeightSmall * countLines(traitsText), traitsText, 1, 1, 1, 1, UIFont.Small, true)
    self.traitsLabel:initialise()
    self.contentPanel:addChild(self.traitsLabel)
    nextY = self.traitsLabel:getBottom() + 14

    self.relationshipLabel = ISLabel:new(infoX, nextY, fontHeightMedium, "Known Characters", 1, 1, 1, 1, UIFont.Medium, true)
    self.relationshipLabel:initialise()
    self.contentPanel:addChild(self.relationshipLabel)
    nextY = self.relationshipLabel:getBottom() + 6

    local relationshipOptions = self:getRelationshipOptions()
    self.relationshipTargetCombo = FrameworkZ.Interfaces:CreateCombo({
        x = infoX,
        y = nextY,
        width = 150,
        height = 25,
        options = relationshipOptions,
        parent = self.contentPanel,
        target = self,
        onChange = FrameworkZ.UI.TabCharacter.onRelationshipSelectionChanged,
        theme = "Default"
    })

    self.relationshipTypeCombo = FrameworkZ.Interfaces:CreateCombo({
        x = infoX + 160,
        y = nextY,
        width = 120,
        height = 25,
        options = RELATIONSHIP_TYPES,
        parent = self.contentPanel,
        target = self,
        theme = "Default"
    })
    self.relationshipTypeCombo.selected = 1

    self.relationshipApplyButton = FrameworkZ.Interfaces:CreateButton({
        x = infoX + 290,
        y = nextY,
        width = 100,
        height = 25,
        title = "Apply",
        target = self,
        onClick = FrameworkZ.UI.TabCharacter.onApplyRelationship,
        parent = self.contentPanel,
        theme = "Basic",
        font = FZ_FONT_MEDIUM
    })
    self.relationshipApplyButton.internal = "APPLY_RELATIONSHIP"
    nextY = self.relationshipApplyButton:getBottom() + 10

    self.relationshipListLabel = ISLabel:new(infoX, nextY, fontHeightSmall * countLines(self:buildRelationshipSummary()), self:buildRelationshipSummary(), 1, 1, 1, 1, UIFont.Small, true)
    self.relationshipListLabel:initialise()
    self.contentPanel:addChild(self.relationshipListLabel)

    self.contentPanel:setScrollHeight(nextY + self.relationshipListLabel:getHeight() + 30)
    self.contentPanel:addScrollBars()
    self.contentPanel:setScrollChildren(true)

    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:registerPanel(self)
    end
end

function FrameworkZ.UI.TabCharacter:getProfessionText()
    if not self.character then return "Unknown" end

    local isoPlayer = self.character.GetIsoPlayer and self.character:GetIsoPlayer() or nil
    if not isoPlayer or not isoPlayer.getDescriptor then return "Unknown" end

    local descriptor = isoPlayer:getDescriptor()
    if descriptor and descriptor.getProfession then
        local profession = descriptor:getProfession()
        if profession and profession ~= "" then
            return tostring(profession)
        end
    end

    return "Unknown"
end

function FrameworkZ.UI.TabCharacter:getTraitsText()
    if not self.character then return "None" end
    local traits = self.character:GetTraits() or {}
    if #traits == 0 then return "None" end
    return table.concat(traits, ", ")
end

function FrameworkZ.UI.TabCharacter:getRelationshipOptions()
    local options = {"No known characters"}
    if not self.character then return options end

    local recognized = self.character:GetRecognizes() or {}
    local names = {}
    for uid, label in pairs(recognized) do
        local name = tostring(label)
        if name and name ~= "" then
            table.insert(names, name)
        end
    end

    if #names == 0 then return options end
    table.sort(names)
    return names
end

function FrameworkZ.UI.TabCharacter:buildRelationshipSummary()
    if not self.character then return "Relationships: None" end

    local recognized = self.character:GetRecognizes() or {}
    local entries = {}
    for uid, label in pairs(recognized) do
        local cleaned = tostring(label)
        if cleaned and cleaned ~= "" then
            table.insert(entries, "- " .. cleaned)
        end
    end

    if #entries == 0 then
        return "Relationships: None"
    end

    table.sort(entries)
    return "Relationships:\n" .. table.concat(entries, "\n")
end

function FrameworkZ.UI.TabCharacter:getStatValue(statName)
    if not self.character then return 0 end
    local isoPlayer = self.character:GetIsoPlayer() or self.isoPlayer
    if not isoPlayer then return 0 end

    if statName == "Health" then
        return isoPlayer:getBodyDamage() and isoPlayer:getBodyDamage():getOverallBodyHealth() or 100
    elseif statName == "Hunger" then
        local nutrition = isoPlayer.getNutrition and isoPlayer:getNutrition() or nil
        if nutrition and nutrition.getHunger then return nutrition:getHunger() end
        return 100
    elseif statName == "Stamina" then
        local stats = isoPlayer.getStats and isoPlayer:getStats() or nil
        if stats and stats.getEndurance then return stats:getEndurance() end
        return 100
    elseif statName == "Fatigue" then
        local stats = isoPlayer.getStats and isoPlayer:getStats() or nil
        if stats and stats.getFatigue then return stats:getFatigue() end
        return 0
    elseif statName == "Stress" then
        local stats = isoPlayer.getStats and isoPlayer:getStats() or nil
        if stats and stats.getStress then return stats:getStress() end
        return 0
    elseif statName == "Pain" then
        local stats = isoPlayer.getStats and isoPlayer:getStats() or nil
        if stats and stats.getPain then return stats:getPain() end
        return 0
    end

    return 0
end

function FrameworkZ.UI.TabCharacter:onSaveDescription(button, x, y)
    if not self.character or not self.descriptionEntry then return end
    local text = self.descriptionEntry:getText() or ""
    self.character:SetDescription(text)
    self.characterDescription = text
    self.characterView:setDescription(text)
    self.characterView:reinitialize(self.character)
end

function FrameworkZ.UI.TabCharacter:onRelationshipSelectionChanged(combo)
    if not combo then return end
    local selectedValue = combo.options and combo.options[combo.selected]
    if selectedValue and selectedValue ~= "No known characters" then
        self.relationshipSelection = selectedValue
    else
        self.relationshipSelection = nil
    end
end

function FrameworkZ.UI.TabCharacter:onApplyRelationship(button, x, y)
    if not self.character or not self.relationshipTargetCombo or not self.relationshipTypeCombo then return end
    local targetName = self.relationshipTargetCombo.options and self.relationshipTargetCombo.options[self.relationshipTargetCombo.selected]
    local label = self.relationshipTypeCombo.options and self.relationshipTypeCombo.options[self.relationshipTypeCombo.selected]

    if not targetName or targetName == "No known characters" or not label then return end

    local recognized = self.character:GetRecognizes() or {}
    for uid, existing in pairs(recognized) do
        if tostring(existing) == targetName then
            recognized[uid] = label
            self.relationshipListLabel:setName("Relationships:\n- " .. label)
            self.relationshipListLabel.name = self:buildRelationshipSummary()
            self.relationshipListLabel:setText(self:buildRelationshipSummary())
            return
        end
    end
end

function FrameworkZ.UI.TabCharacter:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.TabCharacter:close()
    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:unregisterPanel(self)
    end

    self:setVisible(false)
    self:removeFromUIManager()
    FrameworkZ.UI.TabCharacter.instance = nil
end

function FrameworkZ.UI.TabCharacter:new(isoPlayer)
    if not FrameworkZ.UI.TabPanel.instance then return end
    local instance = FrameworkZ.UI.TabPanel.instance

    local o = ISPanel:new(instance:getX() + instance:getWidth(), instance:getY(), TAB_CHARACTER_WIDTH, TAB_CHARACTER_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.isoPlayer = isoPlayer
    o.character = FrameworkZ.Players:GetLoadedCharacterByID(isoPlayer:getUsername())
    o.characterName = o.character and o.character:GetName() or "Unknown"
    o.characterDescription = o.character and o.character:GetDescription() or ""

    FrameworkZ.UI.TabCharacter.instance = o

    return o
end

return FrameworkZ.UI.TabCharacter
