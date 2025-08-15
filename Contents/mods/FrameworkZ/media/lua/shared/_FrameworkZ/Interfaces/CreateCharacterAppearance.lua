FrameworkZ.UI.CreateCharacterAppearance = FrameworkZ.UI.CreateCharacterAppearance or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CreateCharacterAppearance, "CreateCharacterAppearance")

local yOffset = 0

function FrameworkZ.UI.CreateCharacterAppearance:initialise()
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
    
    -- Initialize storage for selected clothing items
    self.selectedClothing = {}
    self.clothingContainers = {}  -- Store references to grid containers for retrieval

    local title = "Character Appearance"
    local subtitle = "Customize your character's physical appearance and clothing"
    
    -- Layout constants for better organization
    local leftColumnX = 50
    local previewWidth = 200
    local previewPadding = 20
    local rightColumnX = math.max(leftColumnX + 320, self.width - previewWidth - previewPadding)  -- Ensure preview fits within bounds
    local entryWidth = 200
    local colorButtonWidth = 80
    local sectionSpacing = 20
    local itemSpacing = 8
    local groupSpacing = 35
    
    self.factionsClothing = FrameworkZ.Factions:GetFactionByID(self.faction).clothing
    self.initialFaction = nil

    yOffset = 30

    -- Enhanced title styling
    self.title = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Title, title), yOffset, 25, title, 1, 1, 1, 1, UIFont.Title, true)
    self.title:initialise()
	self:addChild(self.title)

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Title, title) + 10

    self.subtitle = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Medium, subtitle), yOffset, 25, subtitle, 0.8, 0.8, 0.8, 1, UIFont.Medium, true)
    self.subtitle:initialise()
    self:addChild(self.subtitle)

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Medium, subtitle) + 30

    -- Reduce padding between customization and preview areas
    rightColumnX = leftColumnX + 420  -- Bring preview closer to customization area
    
    -- Character preview on the right side
    self.characterPreview = FrameworkZ.UI.CharacterPreview:new(rightColumnX, yOffset, previewWidth, 400)
    self.characterPreview:initialise()
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)

    -- Add decorative panel behind character preview
    self.previewPanel = ISPanel:new(rightColumnX - 10, yOffset - 10, previewWidth + 20, 420)
    self.previewPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    self.previewPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
    self.previewPanel:initialise()
    self:addChild(self.previewPanel)
    self:addChild(self.characterPreview) -- Add character preview on top of panel

    -- PHYSICAL FEATURES SECTION
    local physicalY = yOffset
    
    -- Section header
    self.physicalHeader = ISLabel:new(leftColumnX, physicalY, 25, "▎Physical Features", 0.9, 0.7, 0.4, 1, UIFont.Large, true)
    self.physicalHeader:initialise()
    self:addChild(self.physicalHeader)
    
    physicalY = physicalY + groupSpacing

    self.hairLabel = ISLabel:new(leftColumnX, physicalY, 25, "Hair Style:", 1, 1, 1, 1, UIFont.Medium, true)
    self.hairLabel:initialise()
    self:addChild(self.hairLabel)

    local hairStyles = getAllHairStyles(isFemale)
    self.hairDropdown = ISComboBox:new(leftColumnX + 120, physicalY, entryWidth, 25, self, self.onHairChanged)

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

    physicalY = physicalY + 25 + itemSpacing

    self.beardLabel = ISLabel:new(leftColumnX, physicalY, 25, "Facial Hair:", 1, 1, 1, 1, UIFont.Medium, true)
    self.beardLabel:initialise()
    self:addChild(self.beardLabel)

    self.beardDropdown = ISComboBox:new(leftColumnX + 120, physicalY, entryWidth, 25, self, self.onBeardChanged)

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

    physicalY = physicalY + 25 + groupSpacing

    -- CLOTHING SECTION HEADER (Outside scrolling panel)
    self.clothingHeader = ISLabel:new(leftColumnX, physicalY, 25, "▎Clothing & Accessories", 0.9, 0.7, 0.4, 1, UIFont.Large, true)
    self.clothingHeader:initialise()
    self:addChild(self.clothingHeader)
    
    physicalY = physicalY + 35

    -- SCROLLABLE CLOTHING SECTION
    local clothingStartY = physicalY
    
    -- Calculate maximum scrollable height based on layout variables
    local characterPreviewHeight = 400
    local characterPreviewY = yOffset
    local clothingHeaderHeight = 25
    local clothingHeaderSpacing = 35
    local bottomPadding = 20  -- Space at bottom of interface
    
    -- Calculate the bottom boundary of the character preview
    local characterPreviewBottom = characterPreviewY + characterPreviewHeight
    
    -- Calculate available space for scrolling panel
    local availableHeight = characterPreviewBottom - clothingStartY - bottomPadding
    
    -- Ensure we don't exceed the total interface height either
    local maxHeightFromInterface = self.height - clothingStartY - bottomPadding
    
    -- Use the smaller of the two constraints
    local maxScrollableHeight = math.min(availableHeight, maxHeightFromInterface)
    
    -- Ensure minimum height for usability
    local minScrollableHeight = 200
    local scrollableHeight = math.max(minScrollableHeight, maxHeightFromInterface)
    
    local scrollableWidth = 340  -- Match width to Physical Features section (leftColumnX + entryWidth + colorButtonWidth + padding)
    
    -- Create main scrollable panel for all clothing options
    self.clothingScrollPanel = ISPanel:new(leftColumnX - 10, clothingStartY, scrollableWidth, scrollableHeight)
    self.clothingScrollPanel.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.3}  -- Barely visible background
    self.clothingScrollPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=0.5}  -- Subtle border

    -- Add scrolling functionality like TabSession
    self.clothingScrollPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end

    self.clothingScrollPanel.prerender = function(self2)
        self2:setStencilRect(0, 0, self2:getWidth(), self2:getHeight())
        ISPanel.prerender(self2)
    end

    self.clothingScrollPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end

    self.clothingScrollPanel:initialise()
    self.clothingScrollPanel:instantiate()
    self:addChild(self.clothingScrollPanel)

    -- Add internal padding to scrolling panel
    self.scrollYOffset = 15  -- Increased internal padding

    if self.factionsClothing then
        -- Only add clothing options if the category has items available
        if self:hasClothingItems(self.factionsClothing.head) then
            self.headLabel, self.headContainer, self.headColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Head Gear:", FZ_ENUM_EQUIPMENT_SLOT_HAT, self.factionsClothing.head, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.face) then
            self.faceLabel, self.faceContainer, self.faceColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Face/Eyes:", FZ_ENUM_EQUIPMENT_SLOT_EYES, self.factionsClothing.face, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.mask) then
            self.maskLabel, self.maskContainer, self.maskColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Face Mask:", FZ_ENUM_EQUIPMENT_SLOT_MASK, self.factionsClothing.mask, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.ears) then
            self.earsLabel, self.earsContainer, self.earsColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Ear Protection:", FZ_ENUM_EQUIPMENT_SLOT_EARS, self.factionsClothing.ears, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.neck) then
            self.neckLabel, self.neckContainer, self.neckColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Necklace/Scarf:", FZ_ENUM_EQUIPMENT_SLOT_NECKLACE, self.factionsClothing.neck, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.undershirt) then
            self.undershirtLabel, self.undershirtContainer, self.undershirtColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Undershirt:", FZ_ENUM_EQUIPMENT_SLOT_TSHIRT, self.factionsClothing.undershirt, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.overshirt) then
            self.overshirtLabel, self.overshirtContainer, self.overshirtColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Shirt/Jacket:", FZ_ENUM_EQUIPMENT_SLOT_SHIRT, self.factionsClothing.overshirt, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.vest) then
            self.vestLabel, self.vestContainer, self.vestColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Vest/Waistcoat:", FZ_ENUM_EQUIPMENT_SLOT_TORSO_EXTRA_VEST, self.factionsClothing.vest, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.gloves) then
            self.glovesLabel, self.glovesContainer, self.glovesColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Gloves:", FZ_ENUM_EQUIPMENT_SLOT_HANDS, self.factionsClothing.gloves, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.wrist) then
            self.wristLabel, self.wristContainer, self.wristColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Wrist Watch:", FZ_ENUM_EQUIPMENT_SLOT_LEFT_WRIST, self.factionsClothing.wrist, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.belt) then
            self.beltLabel, self.beltContainer, self.beltColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Belt:", FZ_ENUM_EQUIPMENT_SLOT_BELT, self.factionsClothing.belt, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.pants) then
            self.pantsLabel, self.pantsContainer, self.pantsColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Pants/Dress:", FZ_ENUM_EQUIPMENT_SLOT_PANTS, self.factionsClothing.pants, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.socks) then
            self.socksLabel, self.socksContainer, self.socksColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Socks:", FZ_ENUM_EQUIPMENT_SLOT_SOCKS, self.factionsClothing.socks, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.shoes) then
            self.shoesLabel, self.shoesContainer, self.shoesColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Footwear:", FZ_ENUM_EQUIPMENT_SLOT_SHOES, self.factionsClothing.shoes, self.clothingScrollPanel)
        end

        if self:hasClothingItems(self.factionsClothing.backpack) then
            self.backpackLabel, self.backpackContainer, self.backpackColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Backpack:", FZ_ENUM_EQUIPMENT_SLOT_BACK, self.factionsClothing.backpack, self.clothingScrollPanel)
        end
    end

    -- Set up scrolling for the clothing panel with proper bottom padding
    self.clothingScrollPanel:setScrollHeight(self.scrollYOffset + 30)  -- Add bottom padding
    self.clothingScrollPanel:addScrollBars()
    self.clothingScrollPanel:setScrollChildren(true)
end

-- Helper function to check if a clothing category has any items
function FrameworkZ.UI.CreateCharacterAppearance:hasClothingItems(clothingTable)
    if not clothingTable then
        return false
    end
    
    -- Check if the table has any entries
    local hasItems = false
    for _ in pairs(clothingTable) do
        hasItems = true
        break
    end
    
    return hasItems
end

function FrameworkZ.UI.CreateCharacterAppearance:addClothingOption(x, y, height, entryWidth, colorButtonWidth, labelText, clothingLocation, clothingTable, parentContainer)
    if not clothingTable then return nil, nil, nil end

    local label = ISLabel:new(15, self.scrollYOffset, height, labelText, 1, 1, 1, 1, UIFont.Medium, true)  -- Increased left padding
    label:initialise()
    parentContainer:addChild(label)

    self.scrollYOffset = self.scrollYOffset + 25  -- Reduced spacing

    -- Grid configuration - calculate items and layout first
    local itemPadding = 2  -- Reduced padding between items
    local gridPadding = 10 -- Reduced padding within grid container
    local minItemSize = 32  -- Slightly smaller minimum item size
    local maxItemSize = 50  -- Reduced maximum item size
    local preferredColumns = 4  -- Preferred number of columns
    
    -- Calculate item count to determine optimal layout
    local itemCount = 1  -- Start with "None" option
    if clothingTable then
        for _ in pairs(clothingTable) do
            itemCount = itemCount + 1
        end
    end
    
    -- Determine optimal number of columns based on item count and space
    local itemsPerRow = preferredColumns
    if itemCount <= 3 then
        itemsPerRow = itemCount  -- Use fewer columns if we have few items
    elseif itemCount <= 6 then
        itemsPerRow = 3
    else
        itemsPerRow = 4  -- Use 4 columns for many items
    end
    
    -- Calculate item size to fit the available width with proper scaling
    local gridWidth = entryWidth - 10  -- Width for the grid area only
    local availableGridWidth = gridWidth - (gridPadding * 2)  -- Account for container padding
    local totalPaddingWidth = (itemsPerRow - 1) * itemPadding
    local calculatedItemSize = math.floor((availableGridWidth - totalPaddingWidth) / itemsPerRow)
    local itemSize = math.max(minItemSize, math.min(maxItemSize, calculatedItemSize))
    
    -- Create a container panel for the clothing selection
    local baseContainerHeight = 80  -- Much more compact base height
    
    -- Calculate required rows for optimal layout
    local requiredRows = math.ceil(itemCount / itemsPerRow)
    
    -- Calculate dynamic container height based on item size and rows
    local gridHeight = (requiredRows * itemSize) + ((requiredRows - 1) * itemPadding) + 10  -- Minimal padding
    local containerHeight = math.max(baseContainerHeight, gridHeight + 20)  -- Tight container height
    
    local containerWidth = entryWidth + colorButtonWidth + 20  -- Grid area + color area + padding
    local gridWidth = entryWidth - 10  -- Width for the grid area only
    local containerPanel = ISPanel:new(15, self.scrollYOffset, containerWidth, containerHeight)  -- Increased left padding
    containerPanel.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.9}
    containerPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=0.8}
    containerPanel:initialise()
    parentContainer:addChild(containerPanel)

    -- Create grid layout for item selection (left side of container) - RED AREA
    local gridContainer = ISPanel:new(5, 5, gridWidth, gridHeight + 2)  -- Minimal padding around grid
    gridContainer.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.3}
    gridContainer.borderColor = {r=0.4, g=0.4, b=0.4, a=0.5}
    gridContainer:initialise()
    containerPanel:addChild(gridContainer)

    -- Store references for later use
    gridContainer.clothingLocation = clothingLocation
    gridContainer.selectedItem = nil
    gridContainer.selectedButton = nil

    -- Recalculate the actual used width and center the grid if there's extra space
    local actualGridWidth = (itemSize * itemsPerRow) + ((itemsPerRow - 1) * itemPadding)
    local startX = math.floor((availableGridWidth - actualGridWidth) / 2) + (gridPadding / 2)
    local startY = 5
    local currentRow = 0
    local currentCol = 0

    -- Add "None" option first
    local noneX = startX + (currentCol * (itemSize + itemPadding))
    local noneY = startY + (currentRow * (itemSize + itemPadding))
    
    local nonePanel = ISPanel:new(noneX, noneY, itemSize, itemSize)
    nonePanel.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8}
    nonePanel.borderColor = {r=0.3, g=0.5, b=0.3, a=0.8}  -- Selected border
    nonePanel:initialise()
    gridContainer:addChild(nonePanel)

    -- "None" texture placeholder using simple panel
    local noneTexture = ISPanel:new(2, 2, itemSize - 4, itemSize - 4)
    noneTexture.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.5}
    noneTexture.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
    
    -- Simple render for "None" option
    noneTexture.render = function(self2)
        ISPanel.render(self2)
        local font = UIFont.Small
        local text = "None"
        local textWidth = getTextManager():MeasureStringX(font, text)
        local textHeight = getTextManager():MeasureStringY(font, text)
        local textX = self2:getAbsoluteX() + (self2.width - textWidth) / 2
        local textY = self2:getAbsoluteY() + (self2.height - textHeight) / 2
        self2:drawText(text, textX, textY, 0.6, 0.6, 0.6, 1, font)
    end
    
    noneTexture:initialise()
    nonePanel:addChild(noneTexture)

    -- "None" selection button (invisible overlay)
    local noneButton = ISButton:new(0, 0, itemSize, itemSize, "", self, self.onClothingButtonClicked)
    noneButton.backgroundColorMouseOver = {r=0.5, g=0.5, b=0.5, a=0.8}
    noneButton.backgroundColor = {r=0, g=0, b=0, a=0}  -- Transparent
    noneButton.borderColor = {r=0, g=0, b=0, a=0}     -- Transparent
    noneButton.clothingData = {location = clothingLocation, itemID = nil, displayName = "None"}
    noneButton.listContainer = gridContainer
    noneButton.itemPanel = nonePanel
    noneButton.parentWindow = self  -- Store reference to main window
    noneButton:initialise()
    nonePanel:addChild(noneButton)

    -- Set "None" as initially selected
    gridContainer.selectedButton = noneButton
    gridContainer.selectedItem = noneButton.clothingData
    
    -- Initialize the selectedClothing table entry with nil for "None"
    self.selectedClothing[clothingLocation] = nil

    -- Move to next grid position
    currentCol = currentCol + 1
    if currentCol >= itemsPerRow then
        currentCol = 0
        currentRow = currentRow + 1
    end

    -- Add clothing items in grid layout
    if clothingTable then
        for itemID, displayName in pairs(clothingTable) do
            local itemX = startX + (currentCol * (itemSize + itemPadding))
            local itemY = startY + (currentRow * (itemSize + itemPadding))
            
            local itemPanel = ISPanel:new(itemX, itemY, itemSize, itemSize)
            itemPanel.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8}
            itemPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
            itemPanel:initialise()
            gridContainer:addChild(itemPanel)

            -- Item texture preview using ISImage (via item:getTexture())
            local texture = nil
            if itemID and itemID ~= "" then
                local previewItem = nil
                previewItem = InventoryItemFactory.CreateItem(itemID)

                if previewItem and previewItem.getTexture then
                    texture = previewItem:getTexture()
                end
            end
            
            if texture then
                -- Use custom panel with drawTextureScaled for texture display
                local itemTexture = ISPanel:new(2, 2, itemSize - 4, itemSize - 4)
                itemTexture.backgroundColor = {r=0, g=0, b=0, a=0}
                itemTexture.borderColor = {r=0, g=0, b=0, a=0}
                itemTexture.texture = texture
                
                -- Custom render function using drawTextureScaled
                itemTexture.render = function(self2)
                    ISPanel.render(self2)
                    if self2.texture then
                        self2:drawTextureScaled(self2.texture, 0, 0, self2.width, self2.height, 1.0, 1, 1, 1)
                    end
                end
                
                itemTexture:initialise()
                itemPanel:addChild(itemTexture)
            else
                -- Fallback panel with placeholder text if no texture found
                local itemTexture = ISPanel:new(2, 2, itemSize - 4, itemSize - 4)
                itemTexture.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.3}
                itemTexture.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
                
                -- Simple render function for placeholder text
                itemTexture.render = function(self2)
                    ISPanel.render(self2)
                    local font = UIFont.Small
                    local text = "?"
                    local textWidth = getTextManager():MeasureStringX(font, text)
                    local textHeight = getTextManager():MeasureStringY(font, text)
                    local textX = self2:getAbsoluteX() + (self2.width - textWidth) / 2
                    local textY = self2:getAbsoluteY() + (self2.height - textHeight) / 2
                    self2:drawText(text, textX, textY, 0.7, 0.7, 0.7, 1, font)
                end
                
                itemTexture:initialise()
                itemPanel:addChild(itemTexture)
            end

            -- Selection button (invisible overlay)
            local itemButton = ISButton:new(0, 0, itemSize, itemSize, "", self, self.onClothingButtonClicked)
            itemButton.backgroundColorMouseOver = {r=0.5, g=0.5, b=0.5, a=0.8}
            itemButton.backgroundColor = {r=0, g=0, b=0, a=0}  -- Transparent
            itemButton.borderColor = {r=0, g=0, b=0, a=0}     -- Transparent
            itemButton.clothingData = {location = clothingLocation, itemID = itemID, displayName = displayName}
            itemButton.listContainer = gridContainer
            itemButton.itemPanel = itemPanel
            itemButton.parentWindow = self  -- Store reference to main window
            itemButton.tooltip = displayName  -- Show item name on hover
            itemButton:initialise()
            itemPanel:addChild(itemButton)

            -- Move to next grid position
            currentCol = currentCol + 1
            if currentCol >= itemsPerRow then
                currentCol = 0
                currentRow = currentRow + 1
            end
        end
    end

    -- Add color selection panel - positioned to the right side of container - GREEN AREA
    local colorButton = nil
    if clothingTable then
        local colorX = gridWidth + 15  -- Position after grid area with some padding
        colorButton = ISButton:new(colorX, 8, colorButtonWidth, 18, "White", self, self.onColorButtonClicked)  -- Much smaller and higher up
        colorButton.clothingLocation = clothingLocation
        colorButton.listContainer = gridContainer
        colorButton.parentWindow = self  -- Store reference to main window
        colorButton.font = UIFont.Small
        colorButton:initialise()
        containerPanel:addChild(colorButton)

        -- Color preview panel - much smaller
        local colorPreview = ISPanel:new(colorX, 28, colorButtonWidth, 18)  -- Smaller height and tighter spacing
        colorPreview.backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = 0.8}
        colorPreview.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
        colorPreview:initialise()
        containerPanel:addChild(colorPreview)
        
        colorButton.colorPreview = colorPreview

        -- Initialize default color data
        if not self.clothingColors then
            self.clothingColors = {}
        end
        if not self.colorIndices then
            self.colorIndices = {}
        end
        
        -- Set default to first color (White)
        self.clothingColors[clothingLocation] = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
        self.colorIndices[clothingLocation] = 1  -- Start with first color
    end

    -- Store references
    containerPanel.listContainer = gridContainer
    containerPanel.colorButton = colorButton
    
    -- Store the grid container reference for later retrieval of selected items
    self.clothingContainers[clothingLocation] = gridContainer

    if not clothingTable then
        label:setVisible(false)
        containerPanel:setVisible(false)
        return label, containerPanel, colorButton
    end
    
    self.scrollYOffset = self.scrollYOffset + containerHeight + 10  -- Even tighter spacing between containers

    return label, containerPanel, colorButton
end

function FrameworkZ.UI.CreateCharacterAppearance:onHairChanged(dropdown)
	local hair = dropdown:getOptionData(dropdown.selected)

	self.hairType = dropdown.selected - 1
	self.survivor:getHumanVisual():setHairModel(hair)
    self.characterPreview:setSurvivorDesc(self.survivor)
end

function FrameworkZ.UI.CreateCharacterAppearance:onBeardChanged(dropdown)
	local beard = dropdown:getOptionData(dropdown.selected)

	self.beardType = dropdown.selected - 1
	self.survivor:getHumanVisual():setBeardModel(beard)
    self.characterPreview:setSurvivorDesc(self.survivor)
end

function FrameworkZ.UI.CreateCharacterAppearance:onClothingButtonClicked(button)
    if not button.clothingData or not button.listContainer then 
        print("ERROR: Missing clothing data or list container")
        return 
    end

    print("Clothing button clicked: " .. button.clothingData.displayName .. " for location: " .. button.clothingData.location)

    -- Clear previous selection highlighting
    if button.listContainer.selectedButton and button.listContainer.selectedButton.itemPanel then
        button.listContainer.selectedButton.itemPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}  -- Default border
    end

    -- Set new selection
    button.listContainer.selectedButton = button
    button.listContainer.selectedItem = button.clothingData
    
    -- Store selection in the selectedClothing table for character creation
    self.selectedClothing[button.clothingData.location] = button.clothingData.itemID
    
    -- Highlight selected item panel
    if button.itemPanel then
        button.itemPanel.borderColor = {r=0.3, g=0.5, b=0.3, a=0.8}  -- Green selected border
    end

    -- Trigger clothing change
    self:onClothingSelectionChanged(button.clothingData)
end

function FrameworkZ.UI.CreateCharacterAppearance:onClothingChanged(dropdown)
    -- Keep this for backward compatibility with hair/beard dropdowns
    if not dropdown then return end

    local dropdownData = dropdown:getOptionData(dropdown.selected)
    if dropdownData then
        self:onClothingSelectionChanged(dropdownData)
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:onClothingSelectionChanged(itemData)
    if not itemData then return end

    local location = itemData.location
    local itemID = itemData.itemID
    
    -- Always clear the current item first
    self.survivor:setWornItem(location, nil)

    -- Only create and set item if itemID is not nil (i.e., not "None" selection)
    if itemID and itemID ~= "" then
        local item = InventoryItemFactory.CreateItem(itemID)
        
        if item then
            self.survivor:setWornItem(location, item)
            
            -- Apply color if available - check if item supports coloring
            if self.clothingColors and self.clothingColors[location] then
                local color = self.clothingColors[location]
                print("Applying color to " .. location .. ": r=" .. color.r .. ", g=" .. color.g .. ", b=" .. color.b)
                
                -- Apply tint to the item's visual - this is the correct method for clothing colors
                if item.getVisual and type(item.getVisual) == "function" then
                    -- Enable custom coloring and set both color methods
                    if item.setCustomColor then
                        item:setCustomColor(true)
                    end
                    
                    -- Use Color.new for setColor
                    if item.setColor then
                        local colorObj = Color.new(color.r, color.g, color.b, color.a)
                        item:setColor(colorObj)
                    end
                    
                    -- Use ImmutableColor.new for tint
                    if item:getVisual().setTint then
                        local immutableColor = ImmutableColor.new(color.r, color.g, color.b, color.a)
                        item:getVisual():setTint(immutableColor)
                    end
                    
                    print("Successfully applied custom color and tint to item")
                else
                    print("Item does not support getVisual method")
                end
            else
                print("No color data found for " .. location)
            end
        else
            print("Failed to create item: " .. tostring(itemID))
        end
    else
        print("Removed item from " .. location .. " (None selected)")
    end

    -- Always update the character preview - try multiple refresh methods
    if self.characterPreview then
        self.characterPreview:setSurvivorDesc(self.survivor)
        -- Force a visual refresh
        --if self.characterPreview.setCharacter then
        --    self.characterPreview:setCharacter(self.survivor)
        --end
        -- Additional refresh attempt
        --if self.characterPreview.refresh then
        --    self.characterPreview:refresh()
        --end
        print("Character preview updated")
    else
        print("ERROR: Character preview not found")
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:onColorButtonClicked(button)
    if not button.clothingLocation then return end
    
    -- Create an enhanced color cycling system with visual feedback
    local predefinedColors = {
        {r = 1.0, g = 1.0, b = 1.0, name = "White"},
        {r = 0.1, g = 0.1, b = 0.1, name = "Black"},
        {r = 0.4, g = 0.4, b = 0.4, name = "Charcoal"},
        {r = 0.7, g = 0.7, b = 0.7, name = "Light Gray"},
        {r = 0.2, g = 0.3, b = 0.5, name = "Navy Blue"},
        {r = 0.1, g = 0.2, b = 0.1, name = "Forest Green"},
        {r = 0.4, g = 0.2, b = 0.1, name = "Brown"},
        {r = 0.5, g = 0.3, b = 0.2, name = "Tan"},
        {r = 0.3, g = 0.1, b = 0.1, name = "Maroon"},
        {r = 0.8, g = 0.7, b = 0.6, name = "Beige"},
        {r = 0.2, g = 0.2, b = 0.3, name = "Dark Blue"},
        {r = 0.3, g = 0.2, b = 0.4, name = "Dark Purple"}
    }

    -- Ensure clothingColors table exists
    if not self.clothingColors then
        self.clothingColors = {}
    end

    -- Initialize color index if not exists
    if not self.colorIndices then
        self.colorIndices = {}
    end

    -- Simple index-based cycling instead of color matching
    local currentIndex = self.colorIndices[button.clothingLocation] or 1
    
    -- Cycle to next color
    currentIndex = (currentIndex % #predefinedColors) + 1
    local newColor = predefinedColors[currentIndex]
    
    -- Store the new index and color
    self.colorIndices[button.clothingLocation] = currentIndex
    self.clothingColors[button.clothingLocation] = {r = newColor.r, g = newColor.g, b = newColor.b, a = 1.0}
    
    -- Update button and preview appearance
    button:setTitle(newColor.name)
    if button.colorPreview then
        button.colorPreview.backgroundColor = {r = newColor.r, g = newColor.g, b = newColor.b, a = 0.8}
    end

    -- Debug: Print color values to help diagnose issues
    print("Color Button Clicked - " .. button.clothingLocation .. ": " .. newColor.name)
    print("RGB Values: r=" .. newColor.r .. ", g=" .. newColor.g .. ", b=" .. newColor.b)

    -- Refresh the clothing item with new color if something is selected
    if button.listContainer and button.listContainer.selectedItem then
        self:onClothingSelectionChanged(button.listContainer.selectedItem)
    else
        -- No item selected, just store the color for later use
        print("Color changed but no item selected - color will be applied when item is selected")
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:getClothingColors()
    return self.clothingColors or {}
end

function FrameworkZ.UI.CreateCharacterAppearance:getSelectedClothing()
    -- Return clothing items with full data (id, color, condition, etc.)
    local clothingWithData = {}
    
    print("[getSelectedClothing] Getting selected clothing with full data...")
    print("[getSelectedClothing] self.selectedClothing = " .. tostring(self.selectedClothing))
    
    if self.selectedClothing then
        print("[getSelectedClothing] Found selectedClothing table with " .. tostring(#self.selectedClothing) .. " items")
        for location, itemID in pairs(self.selectedClothing) do
            print("[getSelectedClothing] Checking location: " .. tostring(location) .. " itemID: " .. tostring(itemID))
            if itemID and itemID ~= "" and itemID ~= "None" then
                local equipmentData = {
                    id = itemID,
                    name = nil, -- Will be filled when item is created
                    color = nil,
                    condition = 1.0,
                    maxCondition = 1.0,
                    modData = {},
                    customProperties = {},
                    dirty = false,
                    wet = false,
                    bloody = false,
                    wetness = 0,
                    bloodLevel = 0
                }
                
                -- Apply color if available
                if self.clothingColors and self.clothingColors[location] then
                    equipmentData.color = {
                        r = self.clothingColors[location].r or 1.0,
                        g = self.clothingColors[location].g or 1.0,
                        b = self.clothingColors[location].b or 1.0,
                        a = self.clothingColors[location].a or 1.0
                    }
                    print("[getSelectedClothing] Applied color to " .. location .. ": r=" .. equipmentData.color.r .. " g=" .. equipmentData.color.g .. " b=" .. equipmentData.color.b)
                end
                
                clothingWithData[location] = equipmentData
                print("[getSelectedClothing] Added clothing item: " .. location .. " = " .. tostring(itemID))
            end
        end
    else
        print("[getSelectedClothing] selectedClothing table is nil!")
    end
    
    -- Count clothing items properly (associative array)
    local clothingCount = 0
    for k, v in pairs(clothingWithData) do
        clothingCount = clothingCount + 1
    end
    print("[getSelectedClothing] Final clothingWithData contains items for " .. tostring(clothingCount) .. " slots")
    return clothingWithData
end

function FrameworkZ.UI.CreateCharacterAppearance:resetGender(newGender)
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

function FrameworkZ.UI.CreateCharacterAppearance:resetHairColor()
    if self.survivor then
        local immutableColor = ImmutableColor.new(self.hairColor.r, self.hairColor.g, self.hairColor.b, 1)

        self.survivor:getHumanVisual():setHairColor(immutableColor)
        self.survivor:getHumanVisual():setBeardColor(immutableColor)
        self.survivor:getHumanVisual():setNaturalHairColor(immutableColor)
        self.survivor:getHumanVisual():setNaturalBeardColor(immutableColor)

        self.characterPreview:setSurvivorDesc(self.survivor)
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:resetHairStyles()
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

function FrameworkZ.UI.CreateCharacterAppearance:resetBeardStyles()
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

function FrameworkZ.UI.CreateCharacterAppearance:resetSkinColor()
    if self.survivor then
        self.survivor:getHumanVisual():setSkinTextureIndex(self.skinColor)
        self.characterPreview:setSurvivorDesc(self.survivor)
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.CreateCharacterAppearance:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.CreateCharacterAppearance:new(parameters)
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
	FrameworkZ.UI.CreateCharacterAppearance.instance = o

	return o
end

return FrameworkZ.UI.CreateCharacterAppearance
