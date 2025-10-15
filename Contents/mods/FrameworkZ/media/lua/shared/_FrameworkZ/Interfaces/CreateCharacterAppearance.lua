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
    self.clothingPanels = {}      -- Store container panels to toggle per-slot controls
    self.clothingColors = {}
    self.colorIndices = {}
    self.textureChoices = {}
    self.textureChoiceMax = {}   -- Fallback max skins per slot when engine doesn’t expose counts
    self.decalValues = {}

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

    -- Enhanced title styling (themed + centered alignment)
    self.title = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = 25,
        text = title,
        font = FZ_FONT_TITLE,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Primary",
        parent = self
    })

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Title, title) + 10

    self.subtitle = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = 25,
        text = subtitle,
        font = FZ_FONT_MEDIUM,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Subtle",
        parent = self
    })

    yOffset = yOffset + self.uiHelper.GetHeight(UIFont.Medium, subtitle) + 30

    -- Reduce padding between customization and preview areas
    rightColumnX = leftColumnX + 420  -- Bring preview closer to customization area
    
    -- Character preview on the right side
    self.characterPreview = FrameworkZ.UI.CharacterPreview:new(rightColumnX, yOffset, previewWidth, 400)
    self.characterPreview:initialise()
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)

    -- Add decorative panel behind character preview
    self.previewPanel = FrameworkZ.Interfaces:CreatePanel({
        x = rightColumnX - 10, y = yOffset - 10, width = previewWidth + 20, height = 420,
        variant = FrameworkZ.Themes.CardPanelTheme,
        parent = self
    })
    self:addChild(self.characterPreview) -- Add character preview on top of panel

    -- PHYSICAL FEATURES SECTION
    local physicalY = yOffset
    
    -- Section header
    self.physicalHeader = FrameworkZ.Interfaces:CreateLabel({
        x = leftColumnX, y = physicalY, height = 25,
        text = "▎Physical Features",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self
    })
    
    physicalY = physicalY + groupSpacing

    self.hairLabel = FrameworkZ.Interfaces:CreateLabel({ x = leftColumnX, y = physicalY, height = 25, text = "Hair Style:", font = FZ_FONT_MEDIUM, parent = self })

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
    self.hairDropdown:instantiate()
    self:onHairChanged(self.hairDropdown)
    self:addChild(self.hairDropdown)

    physicalY = physicalY + 25 + itemSpacing

    self.beardLabel = FrameworkZ.Interfaces:CreateLabel({ x = leftColumnX, y = physicalY, height = 25, text = "Facial Hair:", font = FZ_FONT_MEDIUM, parent = self })

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
    self.beardDropdown:instantiate()
    self:onBeardChanged(self.beardDropdown)
    self:addChild(self.beardDropdown)

    physicalY = physicalY + 25 + groupSpacing

    -- CLOTHING SECTION HEADER (Outside scrolling panel)
    self.clothingHeader = FrameworkZ.Interfaces:CreateLabel({
        x = leftColumnX, y = physicalY, height = 25,
        text = "▎Clothing & Accessories",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self
    })
    
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
    self.clothingScrollPanel = FrameworkZ.Interfaces:CreatePanel({
        x = leftColumnX - 10, y = clothingStartY, width = scrollableWidth, height = scrollableHeight,
        variant = FrameworkZ.Themes.DefaultPanelTheme,
        parent = self
    })

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

    -- Initialize a clothing color picker similar to PZ
    self.colorPicker = ISColorPicker:new(0, 0, {h=1,s=0.6,b=0.9})
    self.colorPicker:initialise()
    self.colorPicker.keepOnScreen = true
    self.colorPicker.pickedTarget = self
    self.colorPicker.resetFocusTo = self.clothingScrollPanel

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

-- Build (if needed) and return a compact inline color palette anchored to the slot's color button
function FrameworkZ.UI.CreateCharacterAppearance:ensureMiniPalette(location)
    self._miniPalettes = self._miniPalettes or {}
    local container = self.clothingPanels and self.clothingPanels[location]
    if not container then return nil end

    -- Check if we already have a valid palette for this location
    if self._miniPalettes[location] and 
       self._miniPalettes[location].parent == self.clothingScrollPanel and
       self._miniPalettes[location].getIsVisible ~= nil then
        return self._miniPalettes[location]
    end

    local colorButton = container.colorButton
    if not colorButton then return nil end

    -- Expanded clothing color palette with much more variety (8 columns for better organization)
    local swatches = {
        -- Row 1: Essential whites and light grays
        {1,1,1},{0.95,0.95,0.95},{0.9,0.9,0.9},{0.85,0.85,0.85},{0.8,0.8,0.8},{0.75,0.75,0.75},{0.7,0.7,0.7},{0.65,0.65,0.65},
        
        -- Row 2: Medium to dark grays and blacks
        {0.6,0.6,0.6},{0.55,0.55,0.55},{0.5,0.5,0.5},{0.45,0.45,0.45},{0.4,0.4,0.4},{0.3,0.3,0.3},{0.2,0.2,0.2},{0,0,0},
        
        -- Row 3: Light browns and tans
        {0.95,0.87,0.75},{0.9,0.8,0.65},{0.87,0.72,0.53},{0.82,0.67,0.48},{0.76,0.6,0.42},{0.7,0.55,0.38},{0.65,0.5,0.35},{0.6,0.45,0.32},
        
        -- Row 4: Medium to dark browns
        {0.55,0.4,0.28},{0.5,0.35,0.25},{0.45,0.32,0.22},{0.4,0.28,0.18},{0.35,0.25,0.18},{0.3,0.22,0.15},{0.25,0.18,0.12},{0.2,0.15,0.1},
        
        -- Row 5: Light reds and pinks
        {1,0.9,0.9},{1,0.8,0.8},{1,0.7,0.7},{0.95,0.6,0.6},{0.9,0.5,0.5},{0.85,0.4,0.4},{0.8,0.3,0.3},{0.75,0.25,0.25},
        
        -- Row 6: Medium to dark reds and burgundy
        {0.9,0.4,0.4},{0.8,0.2,0.2},{0.7,0.1,0.1},{0.6,0,0},{0.5,0,0},{0.45,0,0},{0.4,0,0},{0.3,0,0},
        
        -- Row 7: Light oranges and peaches
        {1,0.9,0.7},{1,0.85,0.6},{1,0.8,0.5},{0.95,0.75,0.45},{0.9,0.7,0.4},{0.85,0.65,0.35},{0.8,0.6,0.3},{0.75,0.55,0.25},
        
        -- Row 8: Medium to dark oranges and rust
        {1,0.75,0.4},{0.9,0.65,0.25},{0.8,0.55,0.15},{0.7,0.45,0.1},{0.6,0.35,0.05},{0.5,0.3,0.05},{0.4,0.25,0.05},{0.3,0.2,0.05},
        
        -- Row 9: Light yellows and creams
        {1,1,0.9},{1,1,0.8},{1,1,0.7},{0.95,0.95,0.6},{0.9,0.9,0.5},{0.85,0.85,0.4},{0.8,0.8,0.3},{0.75,0.75,0.25},
        
        -- Row 10: Medium to dark yellows
        {0.9,0.9,0.2},{0.8,0.8,0.1},{0.7,0.7,0},{0.6,0.6,0},{0.5,0.5,0},{0.4,0.4,0},{0.3,0.3,0},{0.25,0.25,0},
        
        -- Row 11: Light greens and mint
        {0.9,1,0.9},{0.8,0.95,0.8},{0.7,0.9,0.7},{0.6,0.85,0.6},{0.5,0.8,0.5},{0.4,0.75,0.4},{0.3,0.7,0.3},{0.25,0.65,0.25},
        
        -- Row 12: Medium to dark greens
        {0.5,0.75,0.5},{0.4,0.65,0.4},{0.3,0.55,0.3},{0.2,0.45,0.2},{0.15,0.4,0.15},{0.1,0.3,0.1},{0.05,0.25,0.05},{0,0.2,0},
        
        -- Row 13: Light blues and sky colors
        {0.9,0.95,1},{0.8,0.9,1},{0.7,0.85,0.95},{0.6,0.8,0.9},{0.5,0.75,0.95},{0.4,0.7,0.9},{0.3,0.65,0.85},{0.25,0.6,0.8},
        
        -- Row 14: Medium to dark blues
        {0.5,0.75,0.95},{0.4,0.65,0.85},{0.3,0.55,0.75},{0.2,0.4,0.7},{0.15,0.3,0.6},{0.1,0.2,0.5},{0.05,0.15,0.4},{0,0.1,0.3},
        
        -- Row 15: Light purples and lavender
        {0.95,0.9,1},{0.9,0.8,1},{0.85,0.75,0.95},{0.8,0.7,0.9},{0.75,0.65,0.85},{0.7,0.6,0.8},{0.65,0.55,0.75},{0.6,0.5,0.7},
        
        -- Row 16: Medium to dark purples
        {0.85,0.8,1},{0.75,0.65,0.9},{0.65,0.5,0.8},{0.55,0.5,0.85},{0.45,0.4,0.7},{0.35,0.3,0.7},{0.25,0.2,0.6},{0.2,0.15,0.5},
    }

    local cols, cell, gap = 8, 14, 1  -- 8 columns, smaller cells, tighter spacing for expanded palette
    local rows = math.ceil(#swatches / cols)
    local width = cols * cell + (cols - 1) * gap + 4
    local height = rows * cell + (rows - 1) * gap + 4

    local py = colorButton:getY() + colorButton:getHeight() + 4
    local paletteWidth = math.max(width, colorButton:getWidth())
    
    -- Position palette so its right edge aligns with the right edge of the color button
    local px = colorButton:getX() + colorButton:getWidth() - paletteWidth
    
    local palette = ISPanel:new(px, py, paletteWidth, height)
    palette.backgroundColor = { r=0, g=0, b=0, a=0.85 }
    palette.borderColor = { r=0.6, g=0.6, b=0.6, a=0.9 }
    palette:initialise()
    
    -- Add to scroll panel instead of individual container to ensure it appears above combo boxes
    self.clothingScrollPanel:addChild(palette)
    
    -- Adjust position relative to the scroll panel
    local scrollX = container:getX() + colorButton:getX() + colorButton:getWidth() - paletteWidth
    local scrollY = container:getY() + colorButton:getY() + colorButton:getHeight() + 4
    
    palette:setX(scrollX)
    palette:setY(scrollY)

    local x, y = 2, 2
    for i = 1, #swatches do
        local c = swatches[i]
        local b = FrameworkZ.Interfaces:CreateButton({
            x = x,
            y = y,
            width = cell,
            height = cell,
            title = "",
            target = self,
            onClick = self.onMiniPaletteColorClicked,
            backgroundColor = { r=c[1], g=c[2], b=c[3], a=1 },
            borderColor = { r=0.2, g=0.2, b=0.2, a=1 },
            parent = palette
        })
        b.background = true
        b.clothingLocation = location
        b._color = { r=c[1], g=c[2], b=c[3], a=1 }
        b.drawText = nil
        
        -- Disable hover effects and unnecessary updates to prevent animation speed issues
        b.onMouseOver = nil
        b.onMouseOut = nil
        b.doToolTip = false
        
        b:initialise()
        b:instantiate()
        palette:addChild(b)

        x = x + cell + gap
        if (i % cols) == 0 then x = 2; y = y + cell + gap end
    end

    palette:setVisible(false)
    self._miniPalettes[location] = palette
    return palette
end

-- Handle click on a mini-palette swatch
function FrameworkZ.UI.CreateCharacterAppearance:onMiniPaletteColorClicked(button)
    if not button or not button.clothingLocation or not button._color then return end
    local location = button.clothingLocation
    local c = button._color
    self.clothingColors = self.clothingColors or {}
    self.clothingColors[location] = { r=c.r, g=c.g, b=c.b, a=1 }

    -- Update preview swatch
    local panel = self.clothingPanels[location]
    if panel and panel.colorButton and panel.colorButton.colorPreview then
        panel.colorButton.colorPreview.backgroundColor = { r=c.r, g=c.g, b=c.b, a=0.8 }
    end

    -- Apply immediately
    local item = self.survivor and self.survivor:getWornItem(location)
    if item then
        self:applyVisualSelectionsToItem(item, location)
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end

    -- Hide the palette after selection
    if self._miniPalettes and self._miniPalettes[location] then
        self._miniPalettes[location]:setVisible(false)
    end
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

    -- PERFORMANCE OPTIMIZATION: Use single container instead of individual panels per item
    local gridContainer = ISPanel:new(5, 5, gridWidth, gridHeight + 2)  -- Minimal padding around grid
    gridContainer.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.3}
    gridContainer.borderColor = {r=0.4, g=0.4, b=0.4, a=0.5}
    
    -- Store all data for efficient single-render approach
    gridContainer.clothingLocation = clothingLocation
    gridContainer.clothingTable = clothingTable or {}
    gridContainer.itemSize = itemSize
    gridContainer.itemsPerRow = itemsPerRow
    gridContainer.itemPadding = itemPadding
    gridContainer.selectedItemID = nil
    gridContainer.parentWindow = self
    
    -- Recalculate the actual used width and center the grid if there's extra space
    local actualGridWidth = (itemSize * itemsPerRow) + ((itemsPerRow - 1) * itemPadding)
    local startX = math.floor((availableGridWidth - actualGridWidth) / 2) + (gridPadding / 2)
    local startY = 5
    gridContainer.startX = startX
    gridContainer.startY = startY
    
    -- Efficient single render function instead of multiple panels per item
    gridContainer.render = function(self2)
        ISPanel.render(self2)
        
        local currentRow, currentCol = 0, 0
        
        -- Render "None" option first
        local noneX = self2.startX + (currentCol * (self2.itemSize + self2.itemPadding))
        local noneY = self2.startY + (currentRow * (self2.itemSize + self2.itemPadding))
        local noneSelected = (self2.selectedItemID == nil)
        local noneColor = noneSelected and {r=0.3, g=0.5, b=0.3, a=0.8} or {r=0.2, g=0.2, b=0.2, a=0.8}
        
        self2:drawRect(noneX, noneY, self2.itemSize, self2.itemSize, noneColor.a, noneColor.r, noneColor.g, noneColor.b)
        self2:drawRectBorder(noneX, noneY, self2.itemSize, self2.itemSize, 1, 0.4, 0.4, 0.4)
        
        -- Draw "None" text (cached for performance)
        if not self2._noneTextCache then
            local font = UIFont.Small
            local text = "None"
            self2._noneTextCache = {
                text = text,
                font = font,
                width = getTextManager():MeasureStringX(font, text),
                height = getTextManager():MeasureStringY(font, text)
            }
        end
        local cache = self2._noneTextCache
        local textX = noneX + (self2.itemSize - cache.width) / 2
        local textY = noneY + (self2.itemSize - cache.height) / 2
        self2:drawText(cache.text, textX, textY, 0.6, 0.6, 0.6, 1, cache.font)
        
        currentCol = currentCol + 1
        if currentCol >= self2.itemsPerRow then
            currentCol = 0
            currentRow = currentRow + 1
        end
        
        -- Render clothing items efficiently
        for itemID, displayName in pairs(self2.clothingTable) do
            local itemX = self2.startX + (currentCol * (self2.itemSize + self2.itemPadding))
            local itemY = self2.startY + (currentRow * (self2.itemSize + self2.itemPadding))
            local itemSelected = (self2.selectedItemID == itemID)
            local itemColor = itemSelected and {r=0.3, g=0.5, b=0.3, a=0.8} or {r=0.2, g=0.2, b=0.2, a=0.8}
            
            self2:drawRect(itemX, itemY, self2.itemSize, self2.itemSize, itemColor.a, itemColor.r, itemColor.g, itemColor.b)
            self2:drawRectBorder(itemX, itemY, self2.itemSize, self2.itemSize, 1, 0.4, 0.4, 0.4)
            
            -- Try to get and draw texture (cached for performance)
            if not self2._textureCache then self2._textureCache = {} end
            if not self2._textureCache[itemID] then
                local previewItem = InventoryItemFactory.CreateItem(itemID)
                self2._textureCache[itemID] = (previewItem and previewItem.getTexture) and previewItem:getTexture() or false
            end
            
            local texture = self2._textureCache[itemID]
            if texture then
                self2:drawTextureScaled(texture, itemX + 2, itemY + 2, self2.itemSize - 4, self2.itemSize - 4, 1.0, 1, 1, 1)
            else
                -- Draw placeholder "?" for items without textures
                local placeholderX = itemX + (self2.itemSize - 8) / 2
                local placeholderY = itemY + (self2.itemSize - 8) / 2
                self2:drawText("?", placeholderX, placeholderY, 0.7, 0.7, 0.7, 1, UIFont.Small)
            end
            
            currentCol = currentCol + 1
            if currentCol >= self2.itemsPerRow then
                currentCol = 0
                currentRow = currentRow + 1
            end
        end
    end
    
    -- Efficient mouse click detection for grid items
    gridContainer.onMouseUp = function(self2, x, y)
        local gridX = x - self2.startX
        local gridY = y - self2.startY
        
        if gridX >= 0 and gridY >= 0 then
            local colIndex = math.floor(gridX / (self2.itemSize + self2.itemPadding))
            local rowIndex = math.floor(gridY / (self2.itemSize + self2.itemPadding))
            local itemIndex = (rowIndex * self2.itemsPerRow) + colIndex
            
            -- Check if click is within item boundaries
            local itemRelX = gridX - (colIndex * (self2.itemSize + self2.itemPadding))
            local itemRelY = gridY - (rowIndex * (self2.itemSize + self2.itemPadding))
            
            if itemRelX < self2.itemSize and itemRelY < self2.itemSize then
                -- Play clothing selection sound effect
                if getSoundManager then
                    getSoundManager():playUISound("UIActivateButton")
                end
                
                -- First item is "None"
                if itemIndex == 0 then
                    self2.selectedItemID = nil
                    self2.parentWindow:onClothingSelectionChanged({location = self2.clothingLocation, itemID = nil, displayName = "None"})
                else
                    -- Get the actual item ID by counting through the table
                    local counter = 1
                    for itemID, displayName in pairs(self2.clothingTable) do
                        if counter == itemIndex then
                            self2.selectedItemID = itemID
                            self2.parentWindow:onClothingSelectionChanged({location = self2.clothingLocation, itemID = itemID, displayName = displayName})
                            break
                        end
                        counter = counter + 1
                    end
                end
            end
        end
        
        return true
    end
    
    -- Add tooltip support for clothing items
    gridContainer.onMouseMove = function(self2, dx, dy)
        local mouseX = self2:getMouseX()
        local mouseY = self2:getMouseY()
        
        local gridX = mouseX - self2.startX
        local gridY = mouseY - self2.startY
        
        if gridX >= 0 and gridY >= 0 then
            local colIndex = math.floor(gridX / (self2.itemSize + self2.itemPadding))
            local rowIndex = math.floor(gridY / (self2.itemSize + self2.itemPadding))
            local itemIndex = (rowIndex * self2.itemsPerRow) + colIndex
            
            -- Check if mouse is within item boundaries
            local itemRelX = gridX - (colIndex * (self2.itemSize + self2.itemPadding))
            local itemRelY = gridY - (rowIndex * (self2.itemSize + self2.itemPadding))
            
            if itemRelX < self2.itemSize and itemRelY < self2.itemSize then
                local tooltipText = nil
                
                -- First item is "None"
                if itemIndex == 0 then
                    tooltipText = "Remove clothing item"
                else
                    -- Get the actual item display name by counting through the table
                    local counter = 1
                    for itemID, displayName in pairs(self2.clothingTable) do
                        if counter == itemIndex then
                            tooltipText = displayName or itemID
                            break
                        end
                        counter = counter + 1
                    end
                end
                
                if tooltipText and tooltipText ~= self2.currentTooltipText then
                    self2:showTooltip(tooltipText, mouseX, mouseY)
                end
            else
                self2:hideTooltip()
            end
        else
            self2:hideTooltip()
        end
        
        return false
    end
    
    -- Create tooltip UI element with proper positioning and z-order
    gridContainer.showTooltip = function(self2, text, mouseX, mouseY)
        if self2.tooltipUI then
            self2:hideTooltip()
        end
        
        -- Create tooltip UI element
        local font = UIFont.Small
        local fontHgt = getTextManager():getFontHeight(font)
        local width = getTextManager():MeasureStringX(font, text) + 12
        local height = fontHgt + 6
        
        -- Smart positioning based on cursor location
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        local gridCenterY = self2:getAbsoluteY() + (self2:getHeight() / 2)
        
        -- Convert mouse coordinates to absolute screen coordinates
        local absoluteMouseX = self2:getAbsoluteX() + mouseX
        local absoluteMouseY = self2:getAbsoluteY() + mouseY
        
        local x, y
        
        -- Determine if cursor is above or below middle of grid
        if absoluteMouseY < gridCenterY then
            -- Cursor is in upper half - show tooltip below with larger gap
            y = absoluteMouseY + 20  -- Larger gap when below cursor
        else
            -- Cursor is in lower half - show tooltip above with smaller gap
            y = absoluteMouseY - height - 8  -- Smaller gap when above cursor
        end
        
        -- Horizontal positioning with edge detection
        x = absoluteMouseX + 10
        if x + width > screenWidth then
            x = absoluteMouseX - width - 10  -- Show on left side if too close to right edge
        end
        
        -- Final edge bounds checking
        if x < 0 then x = 5 end
        if y < 0 then y = absoluteMouseY + 15 end
        if y + height > screenHeight then y = screenHeight - height - 5 end
        
        -- Create tooltip panel
        self2.tooltipUI = ISPanel:new(x, y, width, height)
        self2.tooltipUI:initialise()
        self2.tooltipUI:instantiate()
        self2.tooltipUI.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.9}
        self2.tooltipUI.borderColor = {r=0.7, g=0.7, b=0.7, a=1.0}
        self2.tooltipUI.tooltipText = text
        self2.tooltipUI.tooltipFont = font
        
        -- Custom render for tooltip content
        self2.tooltipUI.render = function(tooltipSelf)
            ISPanel.render(tooltipSelf)
            tooltipSelf:drawText(tooltipSelf.tooltipText, 6, 3, 1.0, 1.0, 1.0, 1.0, tooltipSelf.tooltipFont)
        end
        
        -- Add to UI manager and set always on top
        self2.tooltipUI:addToUIManager()
        self2.tooltipUI:setAlwaysOnTop(true)
        
        self2.currentTooltipText = text
    end
    
    -- Hide tooltip
    gridContainer.hideTooltip = function(self2)
        if self2.tooltipUI then
            self2.tooltipUI:removeFromUIManager()
            self2.tooltipUI = nil
            self2.currentTooltipText = nil
        end
    end
    
    -- Clean up tooltip when mouse leaves the grid container
    gridContainer.onMouseMoveOutside = function(self2, dx, dy)
        self2:hideTooltip()
        return false
    end
    
    gridContainer:initialise()
    containerPanel:addChild(gridContainer)

    -- Set "None" as initially selected
    gridContainer.selectedItemID = nil
    self.selectedClothing[clothingLocation] = nil

    -- Add color selection panel - positioned to the right side of container - GREEN AREA
    local colorButton = nil
    if clothingTable then
        local colorX = gridWidth + 15  -- Position after grid area with some padding
        colorButton = FrameworkZ.Interfaces:CreateButton({
            x = colorX,
            y = 8,
            width = colorButtonWidth,
            height = 18,
            title = "Change Color",
            target = self,
            onClick = self.onColorButtonClicked,
            font = UIFont.Small,
            parent = containerPanel
        })
        colorButton.clothingLocation = clothingLocation
        colorButton.listContainer = gridContainer
        colorButton.parentWindow = self  -- Store reference to main window

        -- Color preview panel - much smaller
        local colorPreview = ISPanel:new(colorX, 28, colorButtonWidth, 18)  -- Smaller height and tighter spacing
        colorPreview.backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = 0.8}
        colorPreview.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
        colorPreview:initialise()
        containerPanel:addChild(colorPreview)
        
        colorButton.colorPreview = colorPreview

        -- Decal clearing button (moved up since skin controls are removed)
        local decalY = 50  -- Moved up from previous skinY + 22
        local clearDecalBtn = FrameworkZ.Interfaces:CreateButton({
            x = colorX,
            y = decalY,
            width = colorButtonWidth,
            height = 18,
            title = "Clear Decal",
            target = self,
            onClick = self.onClearDecalClicked,
            font = UIFont.Small,
            parent = containerPanel
        })
        clearDecalBtn.clothingLocation = clothingLocation

        -- Decal selection combo (moved up and closer spacing)
        local decalCombo = FrameworkZ.Interfaces:CreateCombo({
            x = colorX,
            y = decalY + 22,
            width = colorButtonWidth,
            height = 18,
            target = self,
            onChange = self.onDecalComboChanged,
            font = UIFont.Small,
            parent = containerPanel
        })
        decalCombo.clothingLocation = clothingLocation

        -- Default state: controls hidden until we know capabilities
        colorButton:setVisible(false)
        colorPreview:setVisible(false)
        clearDecalBtn:setVisible(false)
        decalCombo:setVisible(false)

        -- Initialize defaults (removed texture choice defaults since skin selector is removed)
        self.clothingColors[clothingLocation] = self.clothingColors[clothingLocation] or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
        self.colorIndices[clothingLocation] = self.colorIndices[clothingLocation] or 1
        self.decalValues[clothingLocation] = self.decalValues[clothingLocation] -- may be nil by default

        -- Store for later toggling (removed skin control references)
        containerPanel.clearDecalBtn = clearDecalBtn
        containerPanel.decalCombo = decalCombo
    end

    -- Store references
    containerPanel.listContainer = gridContainer
    containerPanel.colorButton = colorButton
    self.clothingPanels[clothingLocation] = containerPanel
    
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
    
    -- Store selection in the selectedClothing table for character creation
    self.selectedClothing[location] = itemID
    
    -- Always clear the current item first
    self.survivor:setWornItem(location, nil)
    
    -- Reset texture choices for this location to prevent bleeding between items
    self.textureChoices[location] = 0
    
    -- Reset decal choices for this location to prevent bleeding between items
    self.decalValues[location] = nil
    
    -- Reset color choices for this location to prevent bleeding between items
    self.clothingColors[location] = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    -- Only create and set item if itemID is not nil (i.e., not "None" selection)
    if itemID and itemID ~= "" then
        local item = InventoryItemFactory.CreateItem(itemID)
        
        if item then
            self.survivor:setWornItem(location, item)
            
            -- Initialize capabilities and current visual values
            self:refreshSlotCapabilities(location)
            -- Apply user selections (color/tint, decal) - texture choice now properly reset
            self:applyVisualSelectionsToItem(item, location)
        else
            print("Failed to create item: " .. tostring(itemID))
        end
    else
        print("Removed item from " .. location .. " (None selected)")
        -- Clear decal value when removing item
        self.decalValues[location] = nil
        -- Clear color value when removing item
        self.clothingColors[location] = nil
        -- Hide per-slot controls for None
        local panel = self.clothingPanels[location]
        if panel then
            if panel.colorButton then panel.colorButton:setVisible(false) end
            if panel.colorButton and panel.colorButton.colorPreview then panel.colorButton.colorPreview:setVisible(false) end
            if panel.clearDecalBtn then panel.clearDecalBtn:setVisible(false) end
            if panel.decalCombo then panel.decalCombo:setVisible(false) end
        end
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

-- Detect item visual capabilities for a worn slot and toggle UI controls visibility
function FrameworkZ.UI.CreateCharacterAppearance:refreshSlotCapabilities(location)
    local item = self.survivor and self.survivor:getWornItem(location)
    local panel = self.clothingPanels[location]
    local supportsColor, supportsTint, supportsDecal = false, false, false
    local currentDecal = nil

    if item and item.getVisual and type(item.getVisual) == "function" then
        local vis = item:getVisual()
        supportsTint = (vis and vis.setTint and type(vis.setTint) == "function") and true or false
        supportsDecal = (vis and vis.getDecal and type(vis.getDecal) == "function" and vis.setDecal and type(vis.setDecal) == "function") and true or false
        -- Try reading current values safely
        if supportsDecal and vis.getDecal then
            -- getDecal expects a ClothingItem, not an InventoryItem
            local clothingItem = item.getClothingItem and item:getClothingItem() or nil
            if clothingItem then
                currentDecal = vis:getDecal(clothingItem)
            end
        end
    end
    supportsColor = (item and item.setColor and type(item.setColor) == "function") and true or false

    -- Initialize stored values if not set
    if currentDecal ~= nil then
        self.decalValues[location] = self.decalValues[location] or currentDecal
    end

    -- Toggle UI controls visibility
    if panel then
        -- Only show color controls when the clothing item allows random tint, matching base UI
        local clothingItem = item and item.getClothingItem and item:getClothingItem() or nil
        local allowTint = clothingItem and clothingItem.getAllowRandomTint and clothingItem:getAllowRandomTint() or false
        local showColor = allowTint
        if panel.colorButton then panel.colorButton:setVisible(showColor) end
        if panel.colorButton and panel.colorButton.colorPreview then panel.colorButton.colorPreview:setVisible(showColor) end
        -- Keep an inline palette available but hidden; disable if no tint
        local mini = self:ensureMiniPalette(location)
        if mini then mini:setVisible(false) end
        -- Update color button preview to stored color or current tint
        if showColor and panel.colorButton and panel.colorButton.colorPreview then
            local previewColor = nil
            
            -- First check if we have a stored color for this location
            if self.clothingColors and self.clothingColors[location] then
                previewColor = { 
                    r = self.clothingColors[location].r, 
                    g = self.clothingColors[location].g, 
                    b = self.clothingColors[location].b, 
                    a = 0.8 
                }
            -- Fallback to reading current item tint
            elseif item and item.getVisual and item:getVisual() and item:getVisual().getTint then
                local tint = item:getVisual():getTint(clothingItem)
                if tint then
                    previewColor = { r = tint:getRedFloat(), g = tint:getGreenFloat(), b = tint:getBlueFloat(), a = 0.8 }
                end
            end
            
            if previewColor then
                panel.colorButton.colorPreview.backgroundColor = previewColor
            else
                -- Default to white if no color found
                panel.colorButton.colorPreview.backgroundColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.8 }
            end
        end

        local showDecal = supportsDecal
        if panel.clearDecalBtn then panel.clearDecalBtn:setVisible(showDecal) end
        if panel.decalCombo then
            panel.decalCombo:setVisible(showDecal)
            if showDecal then
                self:populateDecalOptionsForLocation(location)
            end
        end
    end
end

-- Apply color/tint and decal choices from UI state to a specific item
function FrameworkZ.UI.CreateCharacterAppearance:applyVisualSelectionsToItem(item, location)
    if not item then return end
    local vis = (item.getVisual and item:getVisual()) or nil
    -- Color/Tint
    local color = self.clothingColors and self.clothingColors[location]
    if color then
        local clothingItem = item.getClothingItem and item:getClothingItem() or nil
        if clothingItem and clothingItem.getAllowRandomTint and clothingItem:getAllowRandomTint() and vis and vis.setTint then
            -- setTint expects an ImmutableColor
            local ic = ImmutableColor and ImmutableColor.new and ImmutableColor.new(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
            if ic then
                vis:setTint(ic)
            end
        else
            if item.setCustomColor then item:setCustomColor(true) end
            if item.setColor and Color and Color.new then
                item:setColor(Color.new(color.r or 1, color.g or 1, color.b or 1, color.a or 1))
            end
        end
    end

    -- Decal
    local decal = self.decalValues and self.decalValues[location]
    if vis and vis.setDecal and type(vis.setDecal) == "function" then
        local decalStr = ""
        if decal ~= nil then
            decalStr = (type(decal) == "string") and decal or tostring(decal)
        end
        vis:setDecal(decalStr)
    end
end

-- Populate decal combo options for a worn slot's current item
function FrameworkZ.UI.CreateCharacterAppearance:populateDecalOptionsForLocation(location)
    local panel = self.clothingPanels[location]
    if not panel or not panel.decalCombo then return end
    local combo = panel.decalCombo
    combo.options = {}

    local item = self.survivor and self.survivor:getWornItem(location)
    if not item or not (item.getVisual and item:getVisual()) then
        combo:setVisible(false)
        return
    end

    -- Try to get available decal names provided by the game for this item
    local itemsList = nil
    if type(getAllDecalNamesForItem) == "function" then
        itemsList = getAllDecalNamesForItem(item)
    end

    -- Always insert a None/clear option at top
    local noneLabel = "(None)"
    combo:addOptionWithData(noneLabel, "")

    if itemsList and itemsList.size and itemsList:size() > 0 then
        for i = 1, itemsList:size() do
            local name = itemsList:get(i-1)
            combo:addOptionWithData(name, name)
        end
        combo:setVisible(true)
    else
        -- If there are no decals for this item, hide the selector
        combo:setVisible(false)
        return
    end

    -- Select current decal value if any
    local clothingItem = item.getClothingItem and item:getClothingItem() or nil
    local current = nil
    if clothingItem and item:getVisual() and item:getVisual().getDecal then
        current = item:getVisual():getDecal(clothingItem)
    end
    if current and current ~= "" then
        combo:select(current)
    else
        combo:select(noneLabel)
    end
end

-- Handler when a user selects a decal from the combo
function FrameworkZ.UI.CreateCharacterAppearance:onDecalComboChanged(combo)
    local location = combo and combo.clothingLocation
    if not location then return end
    
    -- Hide any open mini palettes to prevent overlay conflicts
    self:hideAllMiniPalettes()
    
    local decalName = combo:getOptionData(combo.selected)
    -- Persist selection ("" means clear)
    self.decalValues[location] = decalName or ""
    -- Apply immediately to worn item
    local item = self.survivor and self.survivor:getWornItem(location)
    if item and item.getVisual and item:getVisual() and item:getVisual().setDecal then
        item:getVisual():setDecal(self.decalValues[location])
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
end

-- Handler for Clear Decal button
function FrameworkZ.UI.CreateCharacterAppearance:onClearDecalClicked(button)
    local location = button and button.clothingLocation
    if not location then return end
    self.decalValues[location] = ""
    local item = self.survivor and self.survivor:getWornItem(location)
    if item and item.getVisual and item:getVisual() and item:getVisual().setDecal then
        item:getVisual():setDecal("")
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
    -- Update decal combo selection back to (None)
    local panel = self.clothingPanels[location]
    if panel and panel.decalCombo then
        panel.decalCombo:select("(None)")
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:onColorButtonClicked(button)
    if not button.clothingLocation then return end
    local location = button.clothingLocation
    -- Toggle the inline mini palette instead of spawning the large color picker
    local palette = self:ensureMiniPalette(location)
    if palette then
        local isCurrentlyVisible = palette:getIsVisible()
        
        if isCurrentlyVisible then
            -- If this palette is open, just close it
            palette:setVisible(false)
        else
            -- If this palette is closed, hide others first then open this one
            self:hideAllMiniPalettes()
            palette:setVisible(true)
        end
    end
end

-- Helper method to hide all mini palettes
function FrameworkZ.UI.CreateCharacterAppearance:hideAllMiniPalettes()
    if self._miniPalettes then
        for loc, palette in pairs(self._miniPalettes) do
            if palette and palette.setVisible then
                palette:setVisible(false)
            end
        end
    end
end

-- Called by ISColorPicker when a clothing color is picked
function FrameworkZ.UI.CreateCharacterAppearance:onClothingColorPicked(colorInfo, location)
    if not location or not colorInfo then return end
    self.clothingColors = self.clothingColors or {}
    self.clothingColors[location] = { r = colorInfo:getR(), g = colorInfo:getG(), b = colorInfo:getB(), a = 1.0 }
    -- Update preview on the button
    local panel = self.clothingPanels[location]
    if panel and panel.colorButton and panel.colorButton.colorPreview then
        panel.colorButton.colorPreview.backgroundColor = { r = self.clothingColors[location].r, g = self.clothingColors[location].g, b = self.clothingColors[location].b, a = 0.8 }
    end
    -- Apply to currently worn item immediately
    local item = self.survivor and self.survivor:getWornItem(location)
    if item then
        self:applyVisualSelectionsToItem(item, location)
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
    -- Hide mini palette if open
    if self._miniPalettes and self._miniPalettes[location] then
        self._miniPalettes[location]:setVisible(false)
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

                -- Include decal if chosen
                if self.decalValues and self.decalValues[location] ~= nil then
                    equipmentData.decal = self.decalValues[location]
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

--[[
function FrameworkZ.UI.CreateCharacterAppearance:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.CreateCharacterAppearance:update()
    ISPanel.update(self)
end
--]]

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


