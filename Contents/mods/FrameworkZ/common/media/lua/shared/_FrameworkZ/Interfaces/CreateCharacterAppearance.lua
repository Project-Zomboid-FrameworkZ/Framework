FrameworkZ.UI.CreateCharacterAppearance = FrameworkZ.UI.CreateCharacterAppearance or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CreateCharacterAppearance, "CreateCharacterAppearance")

local yOffset = 0

local function resolveBodyLocation(location)
    if not location then return nil end
    if type(location) ~= "string" then return location end

    if ItemBodyLocation and type(ItemBodyLocation.get) == "function" and ResourceLocation and type(ResourceLocation.of) == "function" then
        local ok, resolved = pcall(function()
            return ItemBodyLocation.get(ResourceLocation.of(location))
        end)
        if ok and resolved then
            return resolved
        end
    end

    return location
end

local function resolveItemTexture(itemID)
    if not itemID then return false end

    -- Prefer runtime item texture resolution; this follows game-side icon mappings in B42.
    if type(instanceItem) == "function" then
        local okItem, item = pcall(function()
            return instanceItem(itemID)
        end)
        if okItem and item and item.getTexture then
            local okTex, texture = pcall(function()
                return item:getTexture()
            end)
            if okTex and texture then
                return texture
            end
        end
    end

    -- Fallback for script-defined icons and legacy paths.
    local scriptItem = ScriptManager and ScriptManager.instance and ScriptManager.instance.FindItem and ScriptManager.instance:FindItem(itemID) or nil
    if scriptItem and scriptItem.getIcon then
        local icon = scriptItem:getIcon()
        if icon and icon ~= "" and icon ~= "None" then
            return getTexture("Item_" .. icon)
                or getTexture("media/textures/Item_" .. icon)
                or getTexture("media/textures/Item_" .. icon .. ".png")
                or false
        end
    end

    return false
end

local function getTextureDimensions(texture)
    if not texture then return nil, nil end

    local width, height = nil, nil
    local okW, valueW = pcall(function()
        return texture:getWidthOrig()
    end)
    if okW and valueW and valueW > 0 then
        width = valueW
    else
        okW, valueW = pcall(function()
            return texture:getWidth()
        end)
        if okW and valueW and valueW > 0 then
            width = valueW
        end
    end

    local okH, valueH = pcall(function()
        return texture:getHeightOrig()
    end)
    if okH and valueH and valueH > 0 then
        height = valueH
    else
        okH, valueH = pcall(function()
            return texture:getHeight()
        end)
        if okH and valueH and valueH > 0 then
            height = valueH
        end
    end

    return width, height
end

local function copyColorTable(color)
    if not color then return nil end
    return {
        r = color.r or 1.0,
        g = color.g or 1.0,
        b = color.b or 1.0,
        a = color.a or 1.0,
    }
end

local function extractItemVisualState(item)
    if not item then return nil end

    local state = {
        color = nil,
        decal = nil,
        textureChoice = nil,
    }

    local vis = item.getVisual and item:getVisual() or nil
    local clothingItem = item.getClothingItem and item:getClothingItem() or nil

    if vis and vis.getTint and type(vis.getTint) == "function" then
        local tint = nil
        if clothingItem then
            local okTint, resolvedTint = pcall(function()
                return vis:getTint(clothingItem)
            end)
            if okTint then
                tint = resolvedTint
            end
        else
            local okTint, resolvedTint = pcall(function()
                return vis:getTint()
            end)
            if okTint then
                tint = resolvedTint
            end
        end
        if tint and tint.getRedFloat and tint.getGreenFloat and tint.getBlueFloat then
            state.color = {
                r = tint:getRedFloat(),
                g = tint:getGreenFloat(),
                b = tint:getBlueFloat(),
                a = 1.0,
            }
        end
    end

    if not state.color and item.getColor and type(item.getColor) == "function" then
        local c = item:getColor()
        if c and c.getRedFloat and c.getGreenFloat and c.getBlueFloat then
            state.color = {
                r = c:getRedFloat(),
                g = c:getGreenFloat(),
                b = c:getBlueFloat(),
                a = (c.getAlphaFloat and c:getAlphaFloat()) or 1.0,
            }
        end
    end

    if vis and vis.getDecal and type(vis.getDecal) == "function" then
        local decal = nil
        if clothingItem then
            local okDecal, resolvedDecal = pcall(function()
                return vis:getDecal(clothingItem)
            end)
            if okDecal then
                decal = resolvedDecal
            end
        else
            local okDecal, resolvedDecal = pcall(function()
                return vis:getDecal()
            end)
            if okDecal then
                decal = resolvedDecal
            end
        end
        if decal ~= nil then
            state.decal = (type(decal) == "string") and decal or tostring(decal)
        end
    end

    if vis and vis.getTextureChoice and type(vis.getTextureChoice) == "function" then
        local okChoice, value = pcall(function()
            return vis:getTextureChoice()
        end)
        if okChoice and type(value) == "number" then
            state.textureChoice = math.floor(value)
        end
    end

    return state
end

local function getItemTextureSignature(item)
    if not item then return nil end

    local okName, textureName = pcall(function()
        return item.getTextureName and item:getTextureName() or nil
    end)
    if okName and textureName and textureName ~= "" then
        return tostring(textureName)
    end

    local okTex, texture = pcall(function()
        return item.getTexture and item:getTexture() or nil
    end)
    if okTex and texture then
        return tostring(texture)
    end

    return nil
end

local function safeSetTextureChoice(item, choice)
    if not item or type(choice) ~= "number" then return false end
    local vis = item.getVisual and item:getVisual() or nil
    if not vis or not vis.setTextureChoice or type(vis.setTextureChoice) ~= "function" then return false end

    local ok = pcall(function()
        vis:setTextureChoice(choice)
    end)
    if ok and item.synchWithVisual and type(item.synchWithVisual) == "function" then
        pcall(function()
            item:synchWithVisual()
        end)
    end
    return ok
end

local function safeGetTextureChoice(item)
    if not item then return nil end
    local vis = item.getVisual and item:getVisual() or nil
    if not vis or not vis.getTextureChoice or type(vis.getTextureChoice) ~= "function" then return nil end

    local ok, choice = pcall(function()
        return vis:getTextureChoice()
    end)
    if ok and type(choice) == "number" then
        return math.floor(choice)
    end
    return nil
end

local function tryResolveTextureChoiceCount(source)
    if not source then return nil end

    local methodNames = {
        "getTextureChoicesCount",
        "getTextureChoiceCount",
        "getTextureChoices",
        "getBaseTextures",
        "getTextures",
    }

    for _, methodName in ipairs(methodNames) do
        local fn = source[methodName]
        if type(fn) == "function" then
            local ok, value = pcall(function()
                return fn(source)
            end)
            if ok and value ~= nil then
                if type(value) == "number" then
                    local count = math.floor(value)
                    if count > 1 then
                        return count
                    end
                elseif type(value) == "table" then
                    local count = #value
                    if count > 1 then
                        return count
                    end
                elseif type(value) == "userdata" then
                    if value.size and type(value.size) == "function" then
                        local okSize, sizeValue = pcall(function()
                            return value:size()
                        end)
                        if okSize and type(sizeValue) == "number" and sizeValue > 1 then
                            return math.floor(sizeValue)
                        end
                    end
                    if value.getLength and type(value.getLength) == "function" then
                        local okLen, lenValue = pcall(function()
                            return value:getLength()
                        end)
                        if okLen and type(lenValue) == "number" and lenValue > 1 then
                            return math.floor(lenValue)
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function getTextureStyleOptions(item)
    if not item then return {} end
    local vis = item.getVisual and item:getVisual() or nil
    if not vis or not vis.setTextureChoice or type(vis.setTextureChoice) ~= "function" then return {} end

    local originalChoice = safeGetTextureChoice(item) or 0
    local options = {}

    local clothingItem = item.getClothingItem and item:getClothingItem() or nil
    local explicitCount = tryResolveTextureChoiceCount(clothingItem) or tryResolveTextureChoiceCount(vis)

    if type(explicitCount) == "number" and explicitCount > 1 then
        local maxChoice = math.min(15, explicitCount - 1)
        for choice = 0, maxChoice do
            if safeSetTextureChoice(item, choice) then
                table.insert(options, {
                    id = "texture:" .. tostring(choice),
                    name = "Skin: " .. tostring(#options + 1),
                    kind = "texture",
                    textureChoice = choice,
                })
            end
        end
    end

    safeSetTextureChoice(item, originalChoice)

    -- If only one effective texture exists, there is nothing to customize.
    if #options <= 1 then
        return {}
    end

    return options
end

local function normalizeVariantFamily(itemID)
    if type(itemID) ~= "string" then return nil end

    local moduleName, scriptName = itemID:match("^([^%.]+)%.(.+)$")
    if not moduleName or not scriptName then
        return itemID
    end

    local base = scriptName

    -- Strip chained suffixes (e.g. _DECAL_TINT, DECALTINT, _decal_tint, _TEXTURE_TINT) until stable.
    local changed = true
    while changed do
        changed = false
        local nextBase = base

        -- Support both underscore and non-underscore conventions.
        nextBase = nextBase:gsub("_TINT$", "")
        nextBase = nextBase:gsub("TINT$", "")
        nextBase = nextBase:gsub("_Tint$", "")
        nextBase = nextBase:gsub("Tint$", "")
        nextBase = nextBase:gsub("_tint$", "")
        nextBase = nextBase:gsub("tint$", "")

        nextBase = nextBase:gsub("_HUE$", "")
        nextBase = nextBase:gsub("HUE$", "")
        nextBase = nextBase:gsub("_Hue$", "")
        nextBase = nextBase:gsub("Hue$", "")
        nextBase = nextBase:gsub("_hue$", "")
        nextBase = nextBase:gsub("hue$", "")

        nextBase = nextBase:gsub("_TEXTURE$", "")
        nextBase = nextBase:gsub("TEXTURE$", "")
        nextBase = nextBase:gsub("_Texture$", "")
        nextBase = nextBase:gsub("Texture$", "")
        nextBase = nextBase:gsub("_texture$", "")
        nextBase = nextBase:gsub("texture$", "")

        nextBase = nextBase:gsub("_DECAL$", "")
        nextBase = nextBase:gsub("DECAL$", "")
        nextBase = nextBase:gsub("_Decal$", "")
        nextBase = nextBase:gsub("Decal$", "")
        nextBase = nextBase:gsub("_decal$", "")
        nextBase = nextBase:gsub("decal$", "")

        nextBase = nextBase:gsub("_Random$", "")
        nextBase = nextBase:gsub("Random$", "")
        nextBase = nextBase:gsub("_RANDOM$", "")
        nextBase = nextBase:gsub("RANDOM$", "")
        nextBase = nextBase:gsub("_random$", "")
        nextBase = nextBase:gsub("random$", "")

        if nextBase ~= base then
            base = nextBase
            changed = true
        end
    end

    local colorSuffixes = {
        "Blue", "Green", "Red", "Black", "White", "Grey", "Gray", "Pink", "Teal",
        "Brown", "Yellow", "Orange", "Purple", "Gold", "Silver", "Navy", "NavyBlue",
        "Light", "Dark", "KY",
    }
    for _, suffix in ipairs(colorSuffixes) do
        base = base:gsub(suffix .. "$", "")
    end

    -- Normalize leftover separators so mixed conventions still group together.
    base = base:gsub("[_%- ]+$", "")
    base = base:gsub("[_%- ]+", "_")

    if base == "" then
        base = scriptName
    end

    return moduleName .. "." .. base
end

local function getRelatedStyleOptions(clothingTable, currentItemID)
    if not clothingTable or not currentItemID then return {} end
    local familyKey = normalizeVariantFamily(currentItemID)
    if not familyKey then return {} end

    local options = {}
    for itemID, displayName in pairs(clothingTable) do
        if normalizeVariantFamily(itemID) == familyKey then
            table.insert(options, {
                id = itemID,
                name = displayName or itemID,
            })
        end
    end

    table.sort(options, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)

    return options
end

local function getCombinedStyleOptions(item, clothingTable, currentItemID)
    local options = {}

    for _, option in ipairs(getRelatedStyleOptions(clothingTable, currentItemID)) do
        table.insert(options, {
            id = "item:" .. tostring(option.id),
            name = "Variant: " .. tostring(option.name),
            kind = "item",
            itemID = option.id,
        })
    end

    return options
end

local function getItemCustomizationProfile(item, itemID, clothingTable)
    local profile = {
        allowTint = false,
        canTint = false,
        canColor = false,
        canDecal = false,
        styleOptions = {},
        colorMode = "none",
    }

    if item then
        local vis = item.getVisual and item:getVisual() or nil
        local clothingItem = item.getClothingItem and item:getClothingItem() or nil

        profile.allowTint = clothingItem and clothingItem.getAllowRandomTint and clothingItem:getAllowRandomTint() or false
        profile.canTint = profile.allowTint and vis and vis.setTint and type(vis.setTint) == "function" and true or false
        profile.canColor = item.setColor and type(item.setColor) == "function" and true or false
        profile.canDecal = (vis and vis.getDecal and type(vis.getDecal) == "function" and vis.setDecal and type(vis.setDecal) == "function" and clothingItem ~= nil) and true or false
    end

    if clothingTable and itemID then
        profile.styleOptions = getCombinedStyleOptions(item, clothingTable, itemID)
    end

    if profile.canTint then
        profile.colorMode = "tint"
    elseif profile.canColor then
        profile.colorMode = "color"
    end

    return profile
end

function FrameworkZ.UI.CreateCharacterAppearance:initialise()
    ISPanel.initialise(self)

    local isFemale = (self.gender == "Female" and true) or (self.gender == "Male" and false)
    self.survivor = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, isFemale)
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
    self.itemVisualState = {}

    self.backgroundOverlay = FrameworkZ.Interfaces:CreatePanel({
        x = 0, y = 0, width = self.width, height = self.height,
        theme = "Overlay",
        parent = self
    })

    local title = "Character Appearance"
    local subtitle = "Customize your character's physical appearance and clothing"
    local titleHeight = self.uiHelper.GetHeight(UIFont.Title, title)
    local subtitleHeight = self.uiHelper.GetHeight(UIFont.Small, subtitle)
    
    -- Layout constants for better organization
    local leftColumnX = 50
    local previewWidth = 165
    local previewHeight = 340
    local previewPadding = 20
    local rightColumnX = self.width - previewWidth - previewPadding  -- Ensure preview fits within bounds
    local entryWidth = 220
    local colorButtonWidth = 80
    local sectionSpacing = 20
    local itemSpacing = 8
    local groupSpacing = 35
    
    self.factionsClothing = FrameworkZ.Factions:GetFactionByID(self.faction).clothing
    self.initialFaction = nil

    yOffset = 30

    -- Enhanced title styling (themed + centered alignment)
    self.title = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = titleHeight,
        text = title,
        font = FZ_FONT_TITLE,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Primary",
        parent = self
    })

    yOffset = yOffset + titleHeight + 10

    self.subtitle = FrameworkZ.Interfaces:CreateLabel({
        x = self.width / 2, y = yOffset, height = subtitleHeight,
        text = subtitle,
        font = FZ_FONT_LARGE,
        textAlign = FZ_ALIGN_CENTER,
        theme = "Caption",
        parent = self
    })

    yOffset = yOffset + subtitleHeight + 30

    -- Keep preview anchored to the right; left side can use extra width for item selection.
    rightColumnX = self.width - previewWidth - previewPadding
    
    -- Character preview on the right side
    self.characterPreview = FrameworkZ.UI.CharacterPreview:new(rightColumnX, yOffset, previewWidth, previewHeight)
    self.characterPreview:initialise()
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)

    -- Add decorative panel behind character preview
    self.previewPanel = FrameworkZ.Interfaces:CreatePanel({
        x = rightColumnX - 10, y = yOffset - 10, width = previewWidth + 20, height = previewHeight + 20,
        variant = FrameworkZ.Themes.CardPanelTheme,
        parent = self
    })
    self:addChild(self.characterPreview) -- Add character preview on top of panel

    -- Selected item customization inspector (uses the open area below preview)
    local inspectorY = yOffset + previewHeight + 28
    local inspectorHeight = math.max(120, self.height - inspectorY - 30)
    local inspectorBottomY = inspectorY + inspectorHeight
    self.customizationInspector = FrameworkZ.Interfaces:CreatePanel({
        x = rightColumnX - 10,
        y = inspectorY,
        width = previewWidth + 20,
        height = inspectorHeight,
        variant = FrameworkZ.Themes.CardPanelTheme,
        parent = self
    })

    self.customizationInspectorTitle = FrameworkZ.Interfaces:CreateLabel({
        x = 10,
        y = 8,
        height = 18,
        text = "Selected Item",
        font = FZ_FONT_MEDIUM,
        parent = self.customizationInspector
    })

    self.customizationInspectorSlot = FrameworkZ.Interfaces:CreateLabel({
        x = 10,
        y = 28,
        height = 16,
        text = "Slot: -",
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.customizationInspectorItem = FrameworkZ.Interfaces:CreateLabel({
        x = 10,
        y = 44,
        height = 16,
        text = "Item: None",
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    local inspectorControlWidth = math.max(120, (previewWidth + 20) - 20)
    local inspectorColorButtonWidth = math.max(86, inspectorControlWidth - 30)

    self.inspectorColorButton = FrameworkZ.Interfaces:CreateButton({
        x = 10,
        y = 58,
        width = inspectorColorButtonWidth,
        height = 18,
        title = "Change Color",
        target = self,
        onClick = self.onColorButtonClicked,
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.inspectorColorPreview = ISPanel:new(10 + inspectorColorButtonWidth + 6, 58, 24, 18)
    self.inspectorColorPreview.backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = 0.8}
    self.inspectorColorPreview.borderColor = {r=0.4, g=0.4, b=0.4, a=0.8}
    self.inspectorColorPreview:initialise()
    self.customizationInspector:addChild(self.inspectorColorPreview)

    local inspectorDecalComboWidth = math.max(80, inspectorControlWidth - 86)
    local inspectorClearDecalButtonWidth = inspectorControlWidth - inspectorDecalComboWidth - 6

    self.inspectorDecalCombo = FrameworkZ.Interfaces:CreateCombo({
        x = 10,
        y = 130,
        width = inspectorControlWidth,
        height = 18,
        target = self,
        onChange = self.onDecalComboChanged,
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.inspectorClearDecalBtn = FrameworkZ.Interfaces:CreateButton({
        x = 10,
        y = 154,
        width = inspectorControlWidth,
        height = 18,
        title = "Clear Decal",
        target = self,
        onClick = self.onClearDecalClicked,
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.inspectorSkinCombo = FrameworkZ.Interfaces:CreateCombo({
        x = 10,
        y = 82,
        width = inspectorControlWidth,
        height = 18,
        target = self,
        onChange = self.onSkinComboChanged,
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.inspectorStyleCombo = FrameworkZ.Interfaces:CreateCombo({
        x = 10,
        y = 106,
        width = inspectorControlWidth,
        height = 18,
        target = self,
        onChange = self.onStyleComboChanged,
        font = UIFont.Small,
        parent = self.customizationInspector
    })

    self.customizationInspector:setVisible(false)

    -- PHYSICAL FEATURES SECTION
    local physicalY = yOffset
    
    -- Section header
    self.physicalHeader = FrameworkZ.Interfaces:CreateLabel({
        x = leftColumnX, y = physicalY, height = 25,
        text = "Physical Features",
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
        text = "Clothing & Accessories",
        font = FZ_FONT_LARGE,
        variant = FrameworkZ.Themes.PrimaryLabelTheme,
        parent = self
    })
    
    physicalY = physicalY + 35

    -- SCROLLABLE CLOTHING SECTION
    local clothingStartY = physicalY
    
    -- Square up the clothing list bottom with the selected-item inspector.
    local minScrollableHeight = 260
    local scrollableHeight = math.max(minScrollableHeight, inspectorBottomY - clothingStartY)
    
    local scrollableWidth = 340  -- Match width to Physical Features section (leftColumnX + entryWidth + colorButtonWidth + padding)
    
    -- Create main scrollable panel for all clothing options
    self.clothingScrollPanel = FrameworkZ.Interfaces:CreatePanel({
        x = leftColumnX - 10, y = clothingStartY, width = scrollableWidth, height = scrollableHeight,
        variant = FrameworkZ.Themes.DefaultPanelTheme,
        parent = self
    })

    local clothingBorderWidth = 2
    self.clothingScrollContentPanel = FrameworkZ.Interfaces:CreatePanel({
        x = clothingBorderWidth,
        y = clothingBorderWidth,
        width = scrollableWidth - (clothingBorderWidth * 2),
        height = scrollableHeight - (clothingBorderWidth * 2),
        backgroundColor = {r=0, g=0, b=0, a=0},
        borderColor = {r=0, g=0, b=0, a=0},
        parent = self.clothingScrollPanel
    })

    -- Add scrolling functionality like TabSession
    self.clothingScrollContentPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end

    self.clothingScrollContentPanel.prerender = function(self2)
        self2:setStencilRect(clothingBorderWidth, clothingBorderWidth, self2:getWidth() - (clothingBorderWidth * 2), self2:getHeight() - (clothingBorderWidth * 2))
        ISPanel.prerender(self2)
    end

    self.clothingScrollContentPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end

    self.clothingScrollPanel:initialise()
    self.clothingScrollPanel:instantiate()
    self.clothingScrollContentPanel:initialise()
    self.clothingScrollContentPanel:instantiate()
    self.clothingScrollPanel:addChild(self.clothingScrollContentPanel)
    self:addChild(self.clothingScrollPanel)

    -- Initialize a clothing color picker similar to PZ
    self.colorPicker = ISColorPicker:new(0, 0, {h=1,s=0.6,b=0.9})
    self.colorPicker:initialise()
    self.colorPicker.keepOnScreen = true
    self.colorPicker.pickedTarget = self
    self.colorPicker.resetFocusTo = self.clothingScrollContentPanel

    -- Add internal padding to scrolling panel
    self.scrollYOffset = 15  -- Increased internal padding

    if self.factionsClothing then
        -- Only add clothing options if the category has items available
        if self:hasClothingItems(self.factionsClothing.head) then
            self.headLabel, self.headContainer, self.headColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Head Gear:", FZ_ENUM_EQUIPMENT_SLOT_HAT, self.factionsClothing.head, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.face) then
            self.faceLabel, self.faceContainer, self.faceColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Face/Eyes:", FZ_ENUM_EQUIPMENT_SLOT_EYES, self.factionsClothing.face, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.mask) then
            self.maskLabel, self.maskContainer, self.maskColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Face Mask:", FZ_ENUM_EQUIPMENT_SLOT_MASK, self.factionsClothing.mask, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.ears) then
            self.earsLabel, self.earsContainer, self.earsColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Ear Protection:", FZ_ENUM_EQUIPMENT_SLOT_EARS, self.factionsClothing.ears, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.neck) then
            self.neckLabel, self.neckContainer, self.neckColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Necklace/Scarf:", FZ_ENUM_EQUIPMENT_SLOT_NECKLACE, self.factionsClothing.neck, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.undershirt) then
            self.undershirtLabel, self.undershirtContainer, self.undershirtColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Undershirt:", FZ_ENUM_EQUIPMENT_SLOT_TSHIRT, self.factionsClothing.undershirt, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.overshirt) then
            self.overshirtLabel, self.overshirtContainer, self.overshirtColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Shirt/Jacket:", FZ_ENUM_EQUIPMENT_SLOT_SHIRT, self.factionsClothing.overshirt, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.vest) then
            self.vestLabel, self.vestContainer, self.vestColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Vest/Waistcoat:", FZ_ENUM_EQUIPMENT_SLOT_TORSO_EXTRA_VEST, self.factionsClothing.vest, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.gloves) then
            self.glovesLabel, self.glovesContainer, self.glovesColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Gloves:", FZ_ENUM_EQUIPMENT_SLOT_HANDS, self.factionsClothing.gloves, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.wrist) then
            self.wristLabel, self.wristContainer, self.wristColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Wrist Watch:", FZ_ENUM_EQUIPMENT_SLOT_LEFT_WRIST, self.factionsClothing.wrist, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.belt) then
            self.beltLabel, self.beltContainer, self.beltColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Belt:", FZ_ENUM_EQUIPMENT_SLOT_BELT, self.factionsClothing.belt, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.pants) then
            self.pantsLabel, self.pantsContainer, self.pantsColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Pants/Dress:", FZ_ENUM_EQUIPMENT_SLOT_PANTS, self.factionsClothing.pants, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.socks) then
            self.socksLabel, self.socksContainer, self.socksColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Socks:", FZ_ENUM_EQUIPMENT_SLOT_SOCKS, self.factionsClothing.socks, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.shoes) then
            self.shoesLabel, self.shoesContainer, self.shoesColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Footwear:", FZ_ENUM_EQUIPMENT_SLOT_SHOES, self.factionsClothing.shoes, self.clothingScrollContentPanel)
        end

        if self:hasClothingItems(self.factionsClothing.backpack) then
            self.backpackLabel, self.backpackContainer, self.backpackColorButton = self:addClothingOption(10, self.scrollYOffset, 25, entryWidth, colorButtonWidth, "Backpack:", FZ_ENUM_EQUIPMENT_SLOT_BACK, self.factionsClothing.backpack, self.clothingScrollContentPanel)
        end
    end

    -- Set up scrolling for the clothing panel with proper bottom padding
    self.clothingScrollContentPanel:setScrollHeight(self.scrollYOffset + 24)  -- Add bottom padding
    self.clothingScrollContentPanel:addScrollBars()
    self.clothingScrollContentPanel:setScrollChildren(true)
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
    local baseContainerHeight = 112  -- Extra height for style/variant controls
    
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
                self2._textureCache[itemID] = resolveItemTexture(itemID)
            end
            
            local texture = self2._textureCache[itemID]
            if texture then
                local targetSize = self2.itemSize - 4
                local drawX = itemX + 2
                local drawY = itemY + 2
                local drawW = targetSize
                local drawH = targetSize

                local texW, texH = getTextureDimensions(texture)
                if texW and texH and texW > 0 and texH > 0 then
                    local scale = math.min(targetSize / texW, targetSize / texH)
                    drawW = math.max(1, math.floor(texW * scale + 0.5))
                    drawH = math.max(1, math.floor(texH * scale + 0.5))
                    drawX = itemX + 2 + math.floor((targetSize - drawW) / 2)
                    drawY = itemY + 2 + math.floor((targetSize - drawH) / 2)
                end

                self2:drawTextureScaled(texture, drawX, drawY, drawW, drawH, 1.0, 1, 1, 1)
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

        -- Variant/style selector for related item IDs in the same family (e.g., BaseballCap*).
        local styleCombo = FrameworkZ.Interfaces:CreateCombo({
            x = colorX,
            y = decalY + 44,
            width = colorButtonWidth,
            height = 18,
            target = self,
            onChange = self.onStyleComboChanged,
            font = UIFont.Small,
            parent = containerPanel
        })
        styleCombo.clothingLocation = clothingLocation

        -- Default state: controls hidden until we know capabilities
        colorButton:setVisible(false)
        colorPreview:setVisible(false)
        clearDecalBtn:setVisible(false)
        decalCombo:setVisible(false)
        styleCombo:setVisible(false)

        -- Initialize defaults (removed texture choice defaults since skin selector is removed)
        self.clothingColors[clothingLocation] = self.clothingColors[clothingLocation] or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
        self.colorIndices[clothingLocation] = self.colorIndices[clothingLocation] or 1
        self.decalValues[clothingLocation] = self.decalValues[clothingLocation] -- may be nil by default

        -- Store for later toggling (removed skin control references)
        containerPanel.clearDecalBtn = clearDecalBtn
        containerPanel.decalCombo = decalCombo
        containerPanel.styleCombo = styleCombo
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
    local resolvedLocation = resolveBodyLocation(location)
    local previousItemID = self.selectedClothing[location]
    local currentWornItem = self.survivor and self.survivor:getWornItem(resolvedLocation)

    -- Reselecting the same item should preserve current visuals and avoid rerolling random defaults.
    if previousItemID == itemID and currentWornItem then
        self:refreshSlotCapabilities(location)
        if self.characterPreview then
            self.characterPreview:setSurvivorDesc(self.survivor)
        end
        return
    end

    -- Capture visual state for the previously selected item in this slot.
    if previousItemID and previousItemID ~= "" and currentWornItem then
        self.itemVisualState[location] = self.itemVisualState[location] or {}
        local previousState = extractItemVisualState(currentWornItem)
        if previousState then
            self.itemVisualState[location][previousItemID] = {
                color = copyColorTable(previousState.color),
                decal = previousState.decal,
                textureChoice = previousState.textureChoice,
            }
        end
    end
    
    -- Store selection in the selectedClothing table for character creation
    self.selectedClothing[location] = itemID
    
    -- Always clear the current item first (B42: setWornItem requires ItemBodyLocation object)
    self.survivor:setWornItem(resolvedLocation, nil)
    
    -- Reset texture choices for this location to prevent bleeding between items
    self.textureChoices[location] = 0

    -- Initialize slot-level values from per-item cache when available.
    self.clothingColors[location] = nil
    self.decalValues[location] = nil
    local cachedState = self.itemVisualState[location] and itemID and self.itemVisualState[location][itemID] or nil
    if cachedState then
        self.clothingColors[location] = copyColorTable(cachedState.color)
        self.decalValues[location] = cachedState.decal
    end

    -- Only create and set item if itemID is not nil (i.e., not "None" selection)
    if itemID and itemID ~= "" then
        local item = instanceItem(itemID) -- B42: InventoryItemFactory removed; use instanceItem
        
        if item then
            local resolvedLocation = resolveBodyLocation(location)
            self.survivor:setWornItem(resolvedLocation, item)

            -- First-time selection of an item: capture current defaults so they can be restored later.
            if not cachedState and itemID then
                self.itemVisualState[location] = self.itemVisualState[location] or {}
                local initialState = extractItemVisualState(item)
                if initialState then
                    self.itemVisualState[location][itemID] = {
                        color = copyColorTable(initialState.color),
                        decal = initialState.decal,
                        textureChoice = initialState.textureChoice,
                    }
                    if not self.clothingColors[location] then
                        self.clothingColors[location] = copyColorTable(initialState.color)
                    end
                    if self.decalValues[location] == nil then
                        self.decalValues[location] = initialState.decal
                    end
                end
            end

            if cachedState and type(cachedState.textureChoice) == "number" then
                safeSetTextureChoice(item, cachedState.textureChoice)
            end
            
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
            if panel.styleCombo then panel.styleCombo:setVisible(false) end
        end
        self:updateCustomizationInspector(nil)
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
    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
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
        local clothingItem = item and item.getClothingItem and item:getClothingItem() or nil
        local currentItemID = self.selectedClothing and self.selectedClothing[location]
        local clothingTable = panel.listContainer and panel.listContainer.clothingTable or nil
        local profile = getItemCustomizationProfile(item, currentItemID, clothingTable)

        local showColor = profile.colorMode ~= "none"
        if panel.colorButton then panel.colorButton:setVisible(false) end
        if panel.colorButton and panel.colorButton.colorPreview then panel.colorButton.colorPreview:setVisible(false) end

        if panel.colorButton then
            if profile.colorMode == "tint" then
                panel.colorButton:setTitle("Change Tint")
            else
                panel.colorButton:setTitle("Change Color")
            end
        end
        
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

        local showDecal = profile.canDecal
        if panel.clearDecalBtn then panel.clearDecalBtn:setVisible(false) end
        if panel.decalCombo then
            panel.decalCombo:setVisible(false)
            if showDecal then
                self:populateDecalOptionsForLocation(location)
            end
            -- Legacy per-slot controls remain hidden; inspector owns customization UI.
            panel.decalCombo:setVisible(false)
        end

        if panel.styleCombo then
            panel.styleCombo:setVisible(false)
            self:populateStyleOptionsForLocation(location)
            panel.styleCombo:setVisible(false)
        end

        self:updateCustomizationInspector(location, profile)
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:updateCustomizationInspector(location, profile)
    if not self.customizationInspector then return end

    if not location or not self.selectedClothing or not self.selectedClothing[location] then
        self.customizationInspector:setVisible(false)
        return
    end

    local itemID = self.selectedClothing[location]
    if not itemID or itemID == "" then
        self.customizationInspector:setVisible(false)
        return
    end

    local panel = self.clothingPanels[location]
    local displayName = (panel and panel.listContainer and panel.listContainer.clothingTable and panel.listContainer.clothingTable[itemID]) or itemID

    self.customizationInspector:setVisible(true)
    self.activeCustomizationLocation = location

    if self.customizationInspectorSlot then
        self.customizationInspectorSlot.name = "Slot: " .. tostring(location)
    end
    if self.customizationInspectorItem then
        self.customizationInspectorItem.name = "Item: " .. tostring(displayName)
    end

    local currentProfile = profile
    if not currentProfile then
        local resolvedLocation = resolveBodyLocation(location)
        local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
        local clothingTable = panel and panel.listContainer and panel.listContainer.clothingTable or nil
        currentProfile = getItemCustomizationProfile(item, itemID, clothingTable)
    end

    if self.inspectorColorButton then
        self.inspectorColorButton.clothingLocation = location
        self.inspectorColorButton:setVisible(currentProfile and currentProfile.colorMode ~= "none")
        if currentProfile and currentProfile.colorMode == "tint" then
            self.inspectorColorButton:setTitle("Change Tint")
        else
            self.inspectorColorButton:setTitle("Change Color")
        end
    end

    if self.inspectorColorPreview then
        local showColorPreview = currentProfile and currentProfile.colorMode ~= "none"
        self.inspectorColorPreview:setVisible(showColorPreview)
        if showColorPreview then
            local slotColor = self.clothingColors and self.clothingColors[location]
            if slotColor then
                self.inspectorColorPreview.backgroundColor = {
                    r = slotColor.r or 1.0,
                    g = slotColor.g or 1.0,
                    b = slotColor.b or 1.0,
                    a = 0.8,
                }
            else
                self.inspectorColorPreview.backgroundColor = {r = 1.0, g = 1.0, b = 1.0, a = 0.8}
            end
        end
    end

    if self.inspectorClearDecalBtn then
        self.inspectorClearDecalBtn.clothingLocation = location
        self.inspectorClearDecalBtn:setVisible(currentProfile and currentProfile.canDecal and self.inspectorDecalCombo and self.inspectorDecalCombo:isVisible())
    end

    if self.inspectorDecalCombo and panel and panel.decalCombo then
        self.inspectorDecalCombo.clothingLocation = location
        self.inspectorDecalCombo.options = {}
        if currentProfile and currentProfile.canDecal and panel.decalCombo.options and #panel.decalCombo.options > 0 then
            self._suppressDecalComboChange = true
            for i = 1, #panel.decalCombo.options do
                local opt = panel.decalCombo.options[i]
                local txt = opt and opt.text or tostring(i)
                self.inspectorDecalCombo:addOptionWithData("Decal: " .. txt, panel.decalCombo:getOptionData(i))
            end
            self.inspectorDecalCombo.selected = panel.decalCombo.selected
            self.inspectorDecalCombo:setVisible(true)
            if self.inspectorClearDecalBtn then self.inspectorClearDecalBtn:setVisible(true) end
            self._suppressDecalComboChange = false
        else
            self.inspectorDecalCombo:setVisible(false)
            if self.inspectorClearDecalBtn then self.inspectorClearDecalBtn:setVisible(false) end
        end
    end

    if self.inspectorSkinCombo then
        self.inspectorSkinCombo.clothingLocation = location
        self.inspectorSkinCombo.options = {}

        local resolvedLocation = resolveBodyLocation(location)
        local wornItem = self.survivor and self.survivor:getWornItem(resolvedLocation)
        local skinOptions = getTextureStyleOptions(wornItem)
        if skinOptions and #skinOptions > 1 then
            self._suppressSkinComboChange = true
            for _, option in ipairs(skinOptions) do
                self.inspectorSkinCombo:addOptionWithData(option.name, option)
            end

            local currentItemID = self.selectedClothing and self.selectedClothing[location]
            local cachedTextureChoice = self.itemVisualState
                and self.itemVisualState[location]
                and currentItemID
                and self.itemVisualState[location][currentItemID]
                and self.itemVisualState[location][currentItemID].textureChoice

            local selectedIndex = 1
            if type(cachedTextureChoice) == "number" then
                for i, option in ipairs(skinOptions) do
                    if option.textureChoice == cachedTextureChoice then
                        selectedIndex = i
                        break
                    end
                end
            end

            self.inspectorSkinCombo.selected = selectedIndex
            self.inspectorSkinCombo:setVisible(true)
            self._suppressSkinComboChange = false
        else
            self.inspectorSkinCombo:setVisible(false)
        end
    end

    if self.inspectorStyleCombo and panel and panel.styleCombo then
        self.inspectorStyleCombo.clothingLocation = location
        self.inspectorStyleCombo.options = {}
        if panel.styleCombo.options and #panel.styleCombo.options > 1 then
            self._suppressStyleComboChange = true
            for i = 1, #panel.styleCombo.options do
                local opt = panel.styleCombo.options[i]
                local txt = opt and opt.text or tostring(i)
                self.inspectorStyleCombo:addOptionWithData(txt, panel.styleCombo:getOptionData(i))
            end
            self.inspectorStyleCombo.selected = panel.styleCombo.selected
            self.inspectorStyleCombo:setVisible(true)
            self._suppressStyleComboChange = false
        else
            self.inspectorStyleCombo:setVisible(false)
        end
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:onSkinComboChanged(combo)
    if self._suppressSkinComboChange then return end
    if not combo or not combo.clothingLocation then return end

    local location = combo.clothingLocation
    local selection = combo:getOptionData(combo.selected)
    if not selection or type(selection) ~= "table" or selection.kind ~= "texture" then return end

    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
    if not item or type(selection.textureChoice) ~= "number" then return end

    if safeSetTextureChoice(item, selection.textureChoice) then
        local currentItemID = self.selectedClothing and self.selectedClothing[location]
        if currentItemID then
            self.itemVisualState[location] = self.itemVisualState[location] or {}
            self.itemVisualState[location][currentItemID] = self.itemVisualState[location][currentItemID] or {}
            self.itemVisualState[location][currentItemID].textureChoice = selection.textureChoice
        end

        self:applyVisualSelectionsToItem(item, location)
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
        self:refreshSlotCapabilities(location)
    end
end

function FrameworkZ.UI.CreateCharacterAppearance:populateStyleOptionsForLocation(location)
    local panel = self.clothingPanels[location]
    if not panel or not panel.styleCombo or not panel.listContainer then return end

    local combo = panel.styleCombo
    combo.options = {}

    local currentItemID = self.selectedClothing and self.selectedClothing[location]
    if not currentItemID or currentItemID == "" then
        combo:setVisible(false)
        return
    end

    local probeItem = nil
    if type(instanceItem) == "function" and currentItemID then
        local okProbe, tempItem = pcall(function()
            return instanceItem(currentItemID)
        end)
        if okProbe and tempItem then
            probeItem = tempItem
        end
    end
    if not probeItem then
        local resolvedLocation = resolveBodyLocation(location)
        probeItem = self.survivor and self.survivor:getWornItem(resolvedLocation)
    end

    local options = getCombinedStyleOptions(probeItem, panel.listContainer.clothingTable, currentItemID)
    if #options <= 1 then
        combo:setVisible(false)
        return
    end

    self._suppressStyleComboChange = true
    for _, option in ipairs(options) do
        combo:addOptionWithData(option.name, option)
    end

    local selectedIndex = 1
    local cachedTextureChoice = self.itemVisualState
        and self.itemVisualState[location]
        and self.itemVisualState[location][currentItemID]
        and self.itemVisualState[location][currentItemID].textureChoice

    for i, option in ipairs(options) do
        if option.kind == "item" and option.itemID == currentItemID then
            selectedIndex = i
            break
        end
        if option.kind == "texture" and cachedTextureChoice ~= nil and option.textureChoice == cachedTextureChoice then
            selectedIndex = i
        end
    end

    combo.selected = selectedIndex
    combo:setVisible(true)
    self._suppressStyleComboChange = false
end

function FrameworkZ.UI.CreateCharacterAppearance:onStyleComboChanged(combo)
    if self._suppressStyleComboChange then return end
    if not combo or not combo.clothingLocation then return end

    local location = combo.clothingLocation
    local panel = self.clothingPanels[location]
    if panel and panel.styleCombo and combo ~= panel.styleCombo then
        panel.styleCombo.selected = combo.selected
    end

    local selection = combo:getOptionData(combo.selected)
    if not selection then return end

    local currentItemID = self.selectedClothing and self.selectedClothing[location]

    if type(selection) == "table" and selection.kind == "texture" then
        local resolvedLocation = resolveBodyLocation(location)
        local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
        if item and type(selection.textureChoice) == "number" then
            if safeSetTextureChoice(item, selection.textureChoice) and currentItemID then
                self.itemVisualState[location] = self.itemVisualState[location] or {}
                self.itemVisualState[location][currentItemID] = self.itemVisualState[location][currentItemID] or {}
                self.itemVisualState[location][currentItemID].textureChoice = selection.textureChoice
                self:applyVisualSelectionsToItem(item, location)
                if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
            end
        end
        self:refreshSlotCapabilities(location)
        return
    end

    local selectedItemID = nil
    if type(selection) == "table" and selection.kind == "item" then
        selectedItemID = selection.itemID
    elseif type(selection) == "string" then
        selectedItemID = selection
    end

    if not selectedItemID or selectedItemID == "" then return end
    if currentItemID == selectedItemID then return end

    local displayName = (panel and panel.listContainer and panel.listContainer.clothingTable and panel.listContainer.clothingTable[selectedItemID]) or selectedItemID
    self:onClothingSelectionChanged({ location = location, itemID = selectedItemID, displayName = displayName })
end

-- Apply color/tint and decal choices from UI state to a specific item
function FrameworkZ.UI.CreateCharacterAppearance:applyVisualSelectionsToItem(item, location)
    if not item then return end
    local vis = (item.getVisual and item:getVisual()) or nil

    local itemID = self.selectedClothing and self.selectedClothing[location]
    local textureChoice = self.itemVisualState
        and self.itemVisualState[location]
        and itemID
        and self.itemVisualState[location][itemID]
        and self.itemVisualState[location][itemID].textureChoice
    if type(textureChoice) == "number" then
        safeSetTextureChoice(item, textureChoice)
    end

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

    -- Decal: only apply when an explicit value exists.
    local decal = self.decalValues and self.decalValues[location]
    if decal ~= nil and vis and vis.setDecal and type(vis.setDecal) == "function" then
        local decalStr = (type(decal) == "string") and decal or tostring(decal)
        vis:setDecal(decalStr)
    end
end

-- Populate decal combo options for a worn slot's current item
function FrameworkZ.UI.CreateCharacterAppearance:populateDecalOptionsForLocation(location)
    local panel = self.clothingPanels[location]
    if not panel or not panel.decalCombo then return end
    local combo = panel.decalCombo
    combo.options = {}

    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
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

    -- Select current decal value if any (prefer stored state, fallback to live visual).
    local current = self.decalValues and self.decalValues[location] or nil
    if current == nil then
        local clothingItem = item.getClothingItem and item:getClothingItem() or nil
        if clothingItem and item:getVisual() and item:getVisual().getDecal then
            local okDecal, resolvedDecal = pcall(function()
                return item:getVisual():getDecal(clothingItem)
            end)
            if okDecal then
                current = resolvedDecal
            end
        end
    end

    local matched = false
    if current and current ~= "" then
        for i = 1, #combo.options do
            local optionData = combo:getOptionData(i)
            if optionData == current then
                combo.selected = i
                matched = true
                break
            end
        end
    end

    if not matched then
        combo:select(noneLabel)
    end
end

-- Handler when a user selects a decal from the combo
function FrameworkZ.UI.CreateCharacterAppearance:onDecalComboChanged(combo)
    if self._suppressDecalComboChange then return end
    local location = combo and combo.clothingLocation
    if not location then return end

    local panel = self.clothingPanels[location]
    if panel and panel.decalCombo and combo ~= panel.decalCombo then
        panel.decalCombo.selected = combo.selected
    end
    
    local decalName = combo:getOptionData(combo.selected)
    -- Persist selection ("" means clear)
    self.decalValues[location] = decalName or ""
    local currentItemID = self.selectedClothing and self.selectedClothing[location]
    if currentItemID then
        self.itemVisualState[location] = self.itemVisualState[location] or {}
        self.itemVisualState[location][currentItemID] = self.itemVisualState[location][currentItemID] or {}
        self.itemVisualState[location][currentItemID].decal = self.decalValues[location]
    end
    -- Apply immediately to worn item
    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
    if item and item.getVisual and item:getVisual() and item:getVisual().setDecal then
        item:getVisual():setDecal(self.decalValues[location])
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
    self:refreshSlotCapabilities(location)
end

-- Handler for Clear Decal button
function FrameworkZ.UI.CreateCharacterAppearance:onClearDecalClicked(button)
    local location = button and button.clothingLocation
    if not location then return end
    self.decalValues[location] = ""
    local currentItemID = self.selectedClothing and self.selectedClothing[location]
    if currentItemID then
        self.itemVisualState[location] = self.itemVisualState[location] or {}
        self.itemVisualState[location][currentItemID] = self.itemVisualState[location][currentItemID] or {}
        self.itemVisualState[location][currentItemID].decal = ""
    end
    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
    if item and item.getVisual and item:getVisual() and item:getVisual().setDecal then
        item:getVisual():setDecal("")
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
    -- Update decal combo selection back to (None)
    local panel = self.clothingPanels[location]
    if panel and panel.decalCombo then
        panel.decalCombo:select("(None)")
    end
    self:refreshSlotCapabilities(location)
end

function FrameworkZ.UI.CreateCharacterAppearance:onColorButtonClicked(button)
    if not button.clothingLocation then return end
    local location = button.clothingLocation
    
    -- Get current color for this clothing slot
    local currentColor = self.clothingColors[location] or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
    
    -- Calculate position relative to the button
    local btnAbsX = button:getAbsoluteX()
    local btnAbsY = button:getAbsoluteY()
    
    -- Create ISColorPicker with clothing-appropriate color palette
    local picker = ISColorPicker:new(btnAbsX, btnAbsY + button:getHeight())
    picker:initialise()
    
    -- Custom clothing color palette - more muted, realistic tones
    local clothingColors = {
        -- Row 1: Whites and light grays
        {r=1.0, g=1.0, b=1.0}, {r=0.95, g=0.95, b=0.95}, {r=0.9, g=0.9, b=0.9}, {r=0.85, g=0.85, b=0.85}, 
        {r=0.8, g=0.8, b=0.8}, {r=0.75, g=0.75, b=0.75}, {r=0.7, g=0.7, b=0.7}, {r=0.65, g=0.65, b=0.65},
        {r=0.6, g=0.6, b=0.6}, {r=0.55, g=0.55, b=0.55}, {r=0.5, g=0.5, b=0.5}, {r=0.45, g=0.45, b=0.45},
        {r=0.4, g=0.4, b=0.4}, {r=0.35, g=0.35, b=0.35}, {r=0.3, g=0.3, b=0.3}, {r=0.25, g=0.25, b=0.25},
        {r=0.2, g=0.2, b=0.2}, {r=0.1, g=0.1, b=0.1},
        
        -- Row 2: Beiges, tans, and khakis
        {r=0.96, g=0.96, b=0.86}, {r=0.96, g=0.87, b=0.7}, {r=0.93, g=0.84, b=0.66}, {r=0.89, g=0.78, b=0.59},
        {r=0.85, g=0.75, b=0.56}, {r=0.82, g=0.71, b=0.55}, {r=0.76, g=0.7, b=0.5}, {r=0.74, g=0.65, b=0.47},
        {r=0.71, g=0.62, b=0.45}, {r=0.68, g=0.57, b=0.42}, {r=0.64, g=0.54, b=0.39}, {r=0.6, g=0.5, b=0.36},
        
        -- Row 3: Browns and earth tones
        {r=0.55, g=0.45, b=0.35}, {r=0.52, g=0.42, b=0.32}, {r=0.48, g=0.38, b=0.28}, {r=0.45, g=0.35, b=0.25},
        {r=0.42, g=0.32, b=0.22}, {r=0.38, g=0.28, b=0.19}, {r=0.35, g=0.25, b=0.17}, {r=0.32, g=0.23, b=0.15},
        {r=0.28, g=0.2, b=0.13}, {r=0.25, g=0.18, b=0.12}, {r=0.22, g=0.15, b=0.1}, {r=0.18, g=0.12, b=0.08},
        
        -- Row 4: Denim blues and navy
        {r=0.6, g=0.7, b=0.8}, {r=0.52, g=0.62, b=0.74}, {r=0.45, g=0.55, b=0.68}, {r=0.38, g=0.48, b=0.62},
        {r=0.32, g=0.42, b=0.56}, {r=0.28, g=0.38, b=0.52}, {r=0.24, g=0.34, b=0.48}, {r=0.2, g=0.3, b=0.44},
        {r=0.17, g=0.27, b=0.4}, {r=0.14, g=0.24, b=0.36}, {r=0.12, g=0.2, b=0.32}, {r=0.1, g=0.17, b=0.28},
        
        -- Row 5: Olive greens and military tones
        {r=0.5, g=0.55, b=0.45}, {r=0.46, g=0.51, b=0.41}, {r=0.42, g=0.47, b=0.37}, {r=0.38, g=0.43, b=0.33},
        {r=0.35, g=0.4, b=0.3}, {r=0.32, g=0.37, b=0.27}, {r=0.29, g=0.34, b=0.24}, {r=0.26, g=0.31, b=0.21},
        {r=0.23, g=0.28, b=0.19}, {r=0.2, g=0.25, b=0.17}, {r=0.18, g=0.22, b=0.15}, {r=0.15, g=0.19, b=0.13},
        
        -- Row 6: Burgundy and wine reds
        {r=0.6, g=0.3, b=0.3}, {r=0.55, g=0.25, b=0.25}, {r=0.5, g=0.22, b=0.22}, {r=0.45, g=0.19, b=0.19},
        {r=0.42, g=0.17, b=0.17}, {r=0.38, g=0.15, b=0.15}, {r=0.35, g=0.13, b=0.13}, {r=0.32, g=0.11, b=0.11},
        {r=0.28, g=0.09, b=0.09}, {r=0.25, g=0.08, b=0.08}, {r=0.22, g=0.07, b=0.07}, {r=0.18, g=0.05, b=0.05},
        
        -- Row 7: Forest and dark greens
        {r=0.3, g=0.45, b=0.35}, {r=0.28, g=0.42, b=0.32}, {r=0.25, g=0.38, b=0.28}, {r=0.22, g=0.35, b=0.25},
        {r=0.2, g=0.32, b=0.23}, {r=0.18, g=0.29, b=0.21}, {r=0.16, g=0.26, b=0.19}, {r=0.14, g=0.23, b=0.17},
        {r=0.12, g=0.2, b=0.15}, {r=0.1, g=0.18, b=0.13}, {r=0.08, g=0.15, b=0.11}, {r=0.06, g=0.12, b=0.09},
        
        -- Row 8: Charcoal and slate grays
        {r=0.45, g=0.5, b=0.52}, {r=0.42, g=0.46, b=0.48}, {r=0.38, g=0.42, b=0.44}, {r=0.35, g=0.38, b=0.4},
        {r=0.32, g=0.35, b=0.37}, {r=0.28, g=0.31, b=0.33}, {r=0.25, g=0.28, b=0.3}, {r=0.22, g=0.25, b=0.27},
        {r=0.19, g=0.22, b=0.24}, {r=0.16, g=0.19, b=0.21}, {r=0.14, g=0.16, b=0.18}, {r=0.11, g=0.13, b=0.15},
        
        -- Row 9: Muted oranges and rusts
        {r=0.65, g=0.45, b=0.3}, {r=0.6, g=0.42, b=0.28}, {r=0.55, g=0.38, b=0.25}, {r=0.5, g=0.35, b=0.22},
        {r=0.46, g=0.32, b=0.2}, {r=0.42, g=0.29, b=0.18}, {r=0.38, g=0.26, b=0.16}, {r=0.34, g=0.23, b=0.14},
        {r=0.3, g=0.2, b=0.12}, {r=0.27, g=0.18, b=0.11}, {r=0.24, g=0.16, b=0.09}, {r=0.2, g=0.13, b=0.08},
        
        -- Row 10: Muted purples and plums
        {r=0.45, g=0.35, b=0.45}, {r=0.42, g=0.32, b=0.42}, {r=0.38, g=0.28, b=0.38}, {r=0.35, g=0.25, b=0.35},
        {r=0.32, g=0.22, b=0.32}, {r=0.28, g=0.19, b=0.28}, {r=0.25, g=0.17, b=0.25}, {r=0.22, g=0.15, b=0.22},
        {r=0.19, g=0.13, b=0.19}, {r=0.16, g=0.11, b=0.16}, {r=0.14, g=0.09, b=0.14}, {r=0.11, g=0.07, b=0.11},
    }
    
    picker:setColors(clothingColors, 18, 10)
    picker.pickedTarget = self
    picker.pickedFunc = FrameworkZ.UI.CreateCharacterAppearance.onClothingColorPicked
    picker.pickedArgs = {location}
    
    -- Set initial color to match current selection
    local initialColor = Color.new(currentColor.r, currentColor.g, currentColor.b, 1.0)
    picker:setInitialColor(initialColor)
    
    picker:addToUIManager()
    picker:bringToTop()
end

-- Called by ISColorPicker when a clothing color is picked
-- Signature: function(target, color, mouseUp, arg1, arg2, arg3, arg4)
function FrameworkZ.UI.CreateCharacterAppearance:onClothingColorPicked(colorInfo, mouseUp, location)
    if not location or not colorInfo then return end
    self.clothingColors = self.clothingColors or {}
    self.clothingColors[location] = { r = colorInfo.r, g = colorInfo.g, b = colorInfo.b, a = 1.0 }
    local currentItemID = self.selectedClothing and self.selectedClothing[location]
    if currentItemID then
        self.itemVisualState[location] = self.itemVisualState[location] or {}
        self.itemVisualState[location][currentItemID] = self.itemVisualState[location][currentItemID] or {}
        self.itemVisualState[location][currentItemID].color = copyColorTable(self.clothingColors[location])
    end
    
    -- Update preview on the button
    local panel = self.clothingPanels[location]
    if panel and panel.colorButton and panel.colorButton.colorPreview then
        panel.colorButton.colorPreview.backgroundColor = { r = colorInfo.r, g = colorInfo.g, b = colorInfo.b, a = 0.8 }
    end
    
    -- Apply to currently worn item immediately
    local resolvedLocation = resolveBodyLocation(location)
    local item = self.survivor and self.survivor:getWornItem(resolvedLocation)
    if item then
        self:applyVisualSelectionsToItem(item, location)
        if self.characterPreview then self.characterPreview:setSurvivorDesc(self.survivor) end
    end
    self:refreshSlotCapabilities(location)
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

                -- Keep a copy of current visual state for this selected item.
                if self.itemVisualState and self.itemVisualState[location] and self.itemVisualState[location][itemID] then
                    local state = self.itemVisualState[location][itemID]
                    if state.color and not equipmentData.color then
                        equipmentData.color = copyColorTable(state.color)
                    end
                    if equipmentData.decal == nil and state.decal ~= nil then
                        equipmentData.decal = state.decal
                    end
                    if state.textureChoice ~= nil then
                        equipmentData.textureChoice = state.textureChoice
                    end
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
        self.survivor = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, isFemale)
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


