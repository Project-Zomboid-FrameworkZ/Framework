FrameworkZ.UI.CreateCharacterFaction = FrameworkZ.UI.CreateCharacterFaction or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CreateCharacterFaction, "CreateCharacterFaction")

-- Helper function to get faction status and color
function FrameworkZ.UI.CreateCharacterFaction:getFactionStatus(factionData)
    if not factionData.requiresWhitelist then
        return "Open Access", {r=0.3, g=0.8, b=0.3, a=1}  -- Green
    else
        -- Check if player is whitelisted for this faction
        local player = FrameworkZ.Players:GetPlayerByID(self.playerObject:getUsername())
        local isPlayerWhitelisted = false
        
        if player then
            isPlayerWhitelisted = player:IsWhitelisted(factionData.id)
        end
        
        if isPlayerWhitelisted then
            return "Whitelisted", {r=0.9, g=0.9, b=0.3, a=1}  -- Yellow
        else
            return "Restricted", {r=0.9, g=0.3, b=0.3, a=1}  -- Red
        end
    end
end

function FrameworkZ.UI.CreateCharacterFaction:initialise()
    ISPanel.initialise(self)

    self.uiHelper = FrameworkZ.UI
    local title = "FACTION SELECTION"
    local subtitle = "Choose your allegiance and shape your destiny"
    
    -- Modern full-screen layout utilizing entire usable space
    local marginX = 40
    local marginY = 30
    local headerHeight = 120
    
    local usableWidth = self.width - (marginX * 2)
    local usableHeight = self.height - (marginY * 2) - headerHeight
    
    local yOffset = marginY
    local factionsList = FrameworkZ.Factions.List
    self.initialFaction = nil

    -- Get first available faction
    for k, v in pairs(factionsList) do
        if not v.requiresWhitelist then
            self.initialFaction = {k = k, v = v}
            break
        end
    end

    self.faction = self.initialFaction and self.initialFaction.k or ""

    -- Create a background overlay panel using theme
    self.backgroundOverlay = FrameworkZ.Interfaces:CreatePanel({
        x = 0, y = 0, width = self.width, height = self.height,
        theme = "Overlay",
        parent = self
    })

    -- Modern header with enhanced typography
    self.title = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = 40,
        text = title,
        font = "Title",
        textAlign = FZ_ALIGN_CENTER,
        theme = "Title",
        parent = self
    })

    yOffset = yOffset + 50

    self.subtitle = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = 30,
        text = subtitle,
        font = "Large",
        textAlign = FZ_ALIGN_CENTER,
        theme = "Caption",
        parent = self
    })

    yOffset = yOffset + 70

    -- Main content area with modern card-based layout
    local cardGap = 30
    local cardsPerRow = 2  -- Reduced to 2 for better image display
    local cardsPadding = 15  -- Consistent padding on all sides
    local scrollBarWidth = 20  -- Account for scrollbar space
    
    -- Calculate card width based on available space with proper padding
    local availableCardWidth = usableWidth - scrollBarWidth - (cardsPadding * 2)
    local cardWidth = (availableCardWidth - (cardGap * (cardsPerRow - 1))) / cardsPerRow
    local cardHeight = 240  -- Much shorter cards to save space for description
    
    -- Faction cards container with scrolling support - reduced height significantly
    local contentAreaHeight = usableHeight - 180  -- Leave much more space for description (was 80)
    
    -- Visual border panel (renders border but no stencil)
    self.factionCardsPanel = FrameworkZ.Interfaces:CreatePanel({
        x = marginX, y = yOffset, width = usableWidth, height = contentAreaHeight,
        theme = "Default",
        parent = self
    })

    -- Inner content panel (invisible, handles stenciling and content)
    local borderWidth = 2  -- Account for panel border thickness
    self.factionCardsContentPanel = FrameworkZ.Interfaces:CreatePanel({
        x = borderWidth,
        y = borderWidth,
        width = usableWidth - (borderWidth * 2),
        height = contentAreaHeight - (borderWidth * 2),
        backgroundColor = {r=0, g=0, b=0, a=0},  -- Transparent background
        borderColor = {r=0, g=0, b=0, a=0},     -- No border
        parent = self.factionCardsPanel
    })

    -- Add scrolling capability to the outer panel
    self.factionCardsContentPanel.onMouseWheel = function(panel, del)
        if panel.vscroll then
            panel:setYScroll(panel:getYScroll() - (del * 40))

            return true
        end

        return false
    end

    -- Apply stencil clipping to the outer panel to maintain fixed clipping area
    self.factionCardsContentPanel.prerender = function(panel)
        -- Clip content to the outer panel bounds (fixed clipping area regardless of scroll)
        panel:setStencilRect(borderWidth, borderWidth, panel:getWidth() - (borderWidth * 2), panel:getHeight() - (borderWidth * 2))
        if ISPanel and ISPanel.prerender then ISPanel.prerender(panel) end
    end

    self.factionCardsContentPanel.render = function(panel)
        if ISPanel and ISPanel.render then ISPanel.render(panel) end
        panel:clearStencilRect()
    end

    -- Create faction cards in a grid layout
    self.factionCards = {}
    local availableFactions = {}

    -- Collect available factions
    for k, v in pairs(factionsList) do
        if not v.requiresWhitelist then
            table.insert(availableFactions, {id = k, data = v})
        end
    end

    -- Calculate grid layout with proper bounds checking
    local totalCards = #availableFactions
    local rows = math.ceil(totalCards / cardsPerRow)
    local totalContentHeight = rows * cardHeight + (rows - 1) * cardGap + cardsPadding * 2 + 20  -- Include top/bottom padding
    
    -- Set up scrolling if content exceeds visible area
    if totalContentHeight > contentAreaHeight then
        self.factionCardsContentPanel:setScrollHeight(totalContentHeight)
        self.factionCardsContentPanel:addScrollBars()
        self.factionCardsContentPanel:setScrollChildren(true)
    end

    -- Generate faction cards
    -- Use consistent padding values defined above
    local availableCardWidthForLayout = usableWidth - (cardsPadding * 2)
    
    -- Recalculate cards per row to ensure they fit with padding (defensive check)
    local effectiveCardsPerRow = math.floor((availableCardWidthForLayout + cardGap) / (cardWidth + cardGap))
    cardsPerRow = math.max(1, effectiveCardsPerRow)  -- Ensure at least 1 card per row
    
    for i, faction in ipairs(availableFactions) do
        local row = math.floor((i - 1) / cardsPerRow)
        local col = (i - 1) % cardsPerRow
        
        local cardX = cardsPadding + col * (cardWidth + cardGap)
        local cardY = row * (cardHeight + cardGap) + 20
        
        -- Ensure card doesn't exceed panel boundaries
        if cardX + cardWidth <= usableWidth - cardsPadding then
            self:createFactionCard(cardX, cardY, cardWidth, cardHeight, faction.id, faction.data)
        end
    end

    -- Selected faction details panel at bottom
    local detailsPanelY = yOffset + contentAreaHeight + 10
    local detailsPanelHeight = 160  -- Much larger description area

    self.selectedFactionPanel = FrameworkZ.Interfaces:CreatePanel({
        x = marginX,
        y = detailsPanelY,
        width = usableWidth,
        height = detailsPanelHeight,
        theme = "Default",
        parent = self
    })

    -- Selected faction info layout
    local detailsPadding = 20

    -- Status positioned at top-right of the panel
    local statusText, statusColor = "Status: Unknown", {r=0.5, g=0.5, b=0.5, a=1}
    if self.initialFaction and self.initialFaction.v then
        local status, color = self:getFactionStatus(self.initialFaction.v)
        statusText = "Status: " .. status
        statusColor = color
    end
    
    self.selectedFactionStatus = FrameworkZ.Interfaces:CreateLabel({
        x = 0, y = 15, height = 25, text = statusText,
        font = "Medium",
        theme = "Caption",
        textColor = statusColor,
        parent = self.selectedFactionPanel
    })
    -- Position it at the right edge of the panel
    self.selectedFactionStatus:setX(usableWidth - self.selectedFactionStatus:getWidth() - detailsPadding)
    --self.selectedFactionPanel:addChild(self.selectedFactionStatus)
    
    -- Faction name on the left
    self.selectedFactionName = FrameworkZ.Interfaces:CreateLabel({
        x = detailsPadding, y = 15, height = 35,
        text = (self.initialFaction and self.initialFaction.v and self.initialFaction.v.name) or "No Faction Selected",
        font = FZ_FONT_LARGE,
        theme = "Primary",
        parent = self.selectedFactionPanel
    })
    
    -- Description closer to name and using full width
    local maxDescWidth = math.floor((usableWidth - detailsPadding * 2) / 8)  -- Use full width minus padding
    local wrappedDesc = self.initialFaction and self.initialFaction.v and self.initialFaction.v.description and 
        FrameworkZ.Utilities:WordWrapText(self.initialFaction.v.description, maxDescWidth, "\n") or "Select a faction to view details."
    
    self.selectedFactionDesc = FrameworkZ.Interfaces:CreateLabel({
        x = detailsPadding, y = 45, height = 90,
        text = '"' .. wrappedDesc .. '"',
        font = FZ_FONT_MEDIUM,
        theme = "Body",
        parent = self.selectedFactionPanel
    })
end

-- Create individual faction card
function FrameworkZ.UI.CreateCharacterFaction:createFactionCard(x, y, width, height, factionId, factionData)
    -- Card background with hover effects - use inner content panel
    local card = FrameworkZ.Interfaces:CreatePanel({ x = x, y = y, width = width, height = height, theme = "Alt", parent = self.factionCardsContentPanel })
    if not card then return end
    card.factionId = factionId
    card.factionData = factionData
    card.isSelected = (factionId == self.faction)
    
    -- Update selection visual state
    if card.isSelected then
        card.backgroundColor = FrameworkZ.Themes.Styles.Colors.Secondary
        card.borderColor = FrameworkZ.Themes.Styles.Colors.Primary
    end
    
    --card:initialise()
    --self.factionCardsPanel:addChild(card)
    
    -- Faction image with proper scaling for 1792x1024 textures - adjusted for shorter cards
    local imageWidth = width * 0.85  -- Slightly smaller to fit in shorter cards
    local imageHeight = imageWidth * (1024 / 1792)  -- Maintain 16:9 aspect ratio
    local imageX = (width - imageWidth) / 2  -- Center horizontally
    local imageY = 15  -- Less padding from top for shorter cards
    
    -- Create image panel using FrameworkZ.Interfaces
    local factionImage = FrameworkZ.Interfaces:CreatePanel({
        x = imageX,
        y = imageY,
        width = imageWidth,
        height = imageHeight,
        parent = card
    })
    
    -- Set the texture after creation
    if factionImage and getTexture then
        local texture = getTexture(factionData.logo or "media/textures/factions/missing-logo.png")
        if texture then
            factionImage.background = true
            factionImage.texture = texture
            factionImage.scaledWidth = imageWidth
            factionImage.scaledHeight = imageHeight
            
            -- Override render to draw the texture
            factionImage.render = function(self)
                if self.texture then
                    self:drawTextureScaled(self.texture, 0, 0, self.scaledWidth, self.scaledHeight, 1, 1, 1, 1)
                end
            end
        end
    end
    
    -- Faction name
    local nameY = imageY + imageHeight + 10  -- Reduced spacing
    local factionName = FrameworkZ.Interfaces:CreateLabel({
        x = width / 2, y = nameY, height = 25, text = factionData.name or "Unknown Faction",
        font = FZ_FONT_MEDIUM,
        textAlign = FZ_ALIGN_CENTER,
        parent = card
    })
    
    -- Status indicator
    local statusY = nameY + 25  -- Reduced spacing for shorter cards
    local statusText, statusColor = self:getFactionStatus(factionData)
    
    local statusLabel = FrameworkZ.Interfaces:CreateLabel({
        x = width / 2, y = statusY, height = 20, text = statusText:upper(),
        font = FZ_FONT_SMALL,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Default",
        textColor = statusColor,
        parent = card
    })
    
    -- Create invisible clickable overlay panel that covers the entire card
    local clickOverlay = FrameworkZ.Interfaces:CreatePanel({
        x = 0,
        y = 0,
        width = width,
        height = height,
        backgroundColor = {r=0, g=0, b=0, a=0},  -- Completely transparent
        borderColor = {r=0, g=0, b=0, a=0},  -- No border
        parent = card
    })
    
    if clickOverlay then
        clickOverlay.factionId = factionId
        clickOverlay.factionData = factionData
    end
    
    -- Move all click handlers to the overlay panel
    if clickOverlay then
        clickOverlay.onMouseUp = function(overlayPanel, x, y)
            if overlayPanel.factionId then
                self:selectFaction(overlayPanel.factionId, overlayPanel.factionData)
            end
        end
    
    -- Hover effects on the overlay affect the parent card
        clickOverlay.onMouseEnter = function(overlayPanel)
            if not card.isSelected then
                card.backgroundColor = FrameworkZ.Themes.Styles.Colors.Secondary
                card.borderColor = FrameworkZ.Themes.Styles.Colors.Border
            end
        end
        
        clickOverlay.onMouseExit = function(overlayPanel)
            if not card.isSelected then
                card.backgroundColor = FrameworkZ.Themes.Styles.Colors.Surface
                card.borderColor = FrameworkZ.Themes.Styles.Colors.Border
            end
        end
    end
    
    table.insert(self.factionCards, card)
end

-- Handle faction selection
function FrameworkZ.UI.CreateCharacterFaction:selectFaction(factionId, factionData)
    -- Update internal state
    self.faction = factionId
    
    -- Update visual selection state for all cards
    for _, card in ipairs(self.factionCards) do
        card.isSelected = (card.factionId == factionId)
        if card.isSelected then
            card.backgroundColor = FrameworkZ.Themes.Styles.Colors.Secondary
            card.borderColor = FrameworkZ.Themes.Styles.Colors.Primary
        else
            card.backgroundColor = FrameworkZ.Themes.Styles.Colors.Surface
            card.borderColor = FrameworkZ.Themes.Styles.Colors.Border
        end
    end
    
    -- Update details panel
    self.selectedFactionName:setName(factionData.name or "Unknown Faction")
    
    -- Word wrap the description to use full width
    local panelWidth = self.selectedFactionPanel:getWidth()
    local detailsPadding = 20
    local maxDescWidth = math.floor((panelWidth - detailsPadding * 2) / 8)  -- Use full width
    local description = factionData.description or "No description available."
    local wrappedDesc = FrameworkZ.Utilities:WordWrapText(description, maxDescWidth, "\n")
    self.selectedFactionDesc:setName('"' .. wrappedDesc .. '"')
    
    -- Update status text and reposition it dynamically at top-right
    local status, statusColor = self:getFactionStatus(factionData)
    local statusText = "Status: " .. status
    self.selectedFactionStatus:setName(statusText)
    -- Reposition to top-right after text changes
    self.selectedFactionStatus:setX(panelWidth - self.selectedFactionStatus:getWidth() - detailsPadding)
    
    self.selectedFactionStatus:setColor(statusColor.r, statusColor.g, statusColor.b, statusColor.a)
end

function FrameworkZ.UI.CreateCharacterFaction:onFactionSelected(dropdown)
    -- Legacy compatibility - this method might still be called by old code
    local factionID = dropdown:getOptionData(dropdown.selected)
    local faction = FrameworkZ.Factions:GetFactionByID(factionID)
    if faction then
        self:selectFaction(faction.id, faction)
    end
end

function FrameworkZ.UI.CreateCharacterFaction:render()
    if ISPanel and ISPanel.render then ISPanel.render(self) end
end

function FrameworkZ.UI.CreateCharacterFaction:update()
    if ISPanel and ISPanel.update then ISPanel.update(self) end
end

function FrameworkZ.UI.CreateCharacterFaction:new(parameters)
	local o = {}

    o = ISPanel and ISPanel:new(parameters.x, parameters.y, parameters.width, parameters.height) or {}
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
