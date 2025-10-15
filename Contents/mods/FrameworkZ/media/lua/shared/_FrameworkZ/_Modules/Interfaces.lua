--! \page Features
--! \section Interfaces Interfaces
--! This framework provides an interface creation and management system. In other words, User Interfaces (UIs) can be easily created, customized, and managed through a set of predefined functions and classes.
--! One unique method of interface creation and management for FrameworkZ is how new interfaces are defined and then registered. Since Project Zomboid's ISUI features are defined client side and shared Lua files are loaded first, interfaces must be created then registered in shared environments without necessarily being instantiated right away. When a client loads into the game, all interfaces will be initialized at that time.
--! Be sure to have a look at Themes as created interfaces use styling options from that module to provide a consistent and unique look across UI elements.

FrameworkZ = FrameworkZ or {}

--! \module FrameworkZ.Interfaces
FrameworkZ.Interfaces = {}
FrameworkZ.Interfaces.List = {}
FrameworkZ.Interfaces = FrameworkZ.Foundation:NewModule(FrameworkZ.Interfaces, "Interfaces")

function FrameworkZ.Interfaces.Opt(options, key, default)
    if type(options) ~= "table" then return default end
    local v = options[key]
    if v == nil then return default end
    return v
end

function FrameworkZ.Interfaces:CreatePanel(options)
    local x, y = self.Opt(options, "x", 0), self.Opt(options, "y", 0)
    local w, h = self.Opt(options, "width", 100), self.Opt(options, "height", 100)
    local bgColor = self.Opt(options, "backgroundColor", nil)
    local borderColor = self.Opt(options, "borderColor", nil)
    local theme = self.Opt(options, "theme", "Default") -- can be string or full theme table
    local parent = self.Opt(options, "parent", nil)

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()

    FrameworkZ.Themes:ApplyPanelTheme(panel, theme)

    -- Apply any manual overrides
    if bgColor then panel.backgroundColor = bgColor end
    if borderColor then panel.borderColor = borderColor end
    if parent and parent.addChild then parent:addChild(panel) end

    return panel
end

function FrameworkZ.Interfaces:CreateLabel(options)
    -- Extract options
    local x = self.Opt(options, "x", 0)
    local y = self.Opt(options, "y", 0)
    local height = self.Opt(options, "height", 25)
    local text = tostring(self.Opt(options, "text", ""))
    local parent = self.Opt(options, "parent", nil)
    
    -- Theme and alignment options
    local theme = self.Opt(options, "theme", "Default")
    local textAlign = self.Opt(options, "textAlign", nil)
    local textColor = self.Opt(options, "textColor", nil)
    local fontOverride = self.Opt(options, "font", nil)  -- Optional font override

    if textAlign == nil and type(options) == "table" and options.centered ~= nil then
        textAlign = options.centered and FZ_ALIGN_CENTER or FZ_ALIGN_LEFT
    end

    textAlign = textAlign or FZ_ALIGN_LEFT

    -- Create the label with theme's default font first (we'll override later if needed)
    local bLeft = (textAlign == FZ_ALIGN_LEFT)  -- true for left align, false for right/center
    local label = ISLabel:new(x, y, height, text, 1, 1, 1, 1, UIFont.Medium, bLeft)
    label:initialise()

    -- Store alignment data for future text changes
    label._fzTextAlign = textAlign
    label._fzAnchorX = x

    -- Apply theme first (this sets the default font for this theme)
    FrameworkZ.Themes:ApplyLabelTheme(label, theme)

    -- Override font if specified
    if fontOverride and FrameworkZ.Themes and FrameworkZ.Themes.GetFont then
        label.font = FrameworkZ.Themes:GetFont(fontOverride)
    end

    -- Apply alignment directly using proper string measurement
    local textManager = getTextManager and getTextManager()
    if textAlign == FZ_ALIGN_CENTER then
        -- For center alignment, position label so text centers at the X coordinate
        local textWidth = textManager and textManager:MeasureStringX(label.font, text) or 0
        label:setX(x - math.floor(textWidth / 2))
    elseif textAlign == FZ_ALIGN_RIGHT then
        -- For right alignment, position label so text ends at the X coordinate
        local textWidth = textManager and textManager:MeasureStringX(label.font, text) or 0
        label:setX(x - textWidth)
    else
        -- Left alignment - text starts at the X coordinate
        label:setX(x)
    end

    -- Monkey-patch setName to maintain alignment on text changes
    if type(label.setName) == "function" then
        local originalSetName = label.setName
        label.setName = function(lbl, newText)
            originalSetName(lbl, newText)
            -- Reapply alignment after text change using proper string measurement
            local textManager = getTextManager and getTextManager()
            if lbl._fzTextAlign == FZ_ALIGN_CENTER then
                local textWidth = textManager and textManager:MeasureStringX(lbl.font, newText) or 0
                lbl:setX(lbl._fzAnchorX - math.floor(textWidth / 2))
            elseif lbl._fzTextAlign == FZ_ALIGN_RIGHT then
                local textWidth = textManager and textManager:MeasureStringX(lbl.font, newText) or 0
                lbl:setX(lbl._fzAnchorX - textWidth)
            else
                -- Left align: text starts at anchor position
                lbl:setX(lbl._fzAnchorX)
            end
        end
    end
    
    -- Apply color override
    if textColor and label.setColor then 
        label:setColor(textColor.r, textColor.g, textColor.b, textColor.a) 
    end

    -- Add to parent if specified
    if parent and parent.addChild then
        parent:addChild(label)
    end

    return label
end

function FrameworkZ.Interfaces:CreateButton(options)
    local x, y = self.Opt(options, "x", 0), self.Opt(options, "y", 0)
    local w, h = self.Opt(options, "width", 100), self.Opt(options, "height", 25)
    local title = tostring(self.Opt(options, "title", "Button"))
    local target = self.Opt(options, "target", nil)
    local onClick = self.Opt(options, "onClick", nil)
    local theme = self.Opt(options, "theme", "Default")
    local parent = self.Opt(options, "parent", nil)

    local btn = ISButton:new(x, y, w, h, title, target, onClick)
    btn:initialise()

    -- Apply theme first (this sets the default font for this theme)
    FrameworkZ.Themes:ApplyButtonTheme(btn, theme)

    -- Apply manual overrides only if specified
    local fontOverride = self.Opt(options, "font", nil)
    local bgColor = self.Opt(options, "backgroundColor", nil)
    local borderColor = self.Opt(options, "borderColor", nil)
    local textColor = self.Opt(options, "textColor", nil)
    local hoverColor = self.Opt(options, "hoverColor", nil)

    if fontOverride and FrameworkZ.Themes and FrameworkZ.Themes.GetFont then
        btn.font = FrameworkZ.Themes:GetFont(fontOverride)
    end

    if bgColor then btn.backgroundColor = bgColor end
    if borderColor then btn.borderColor = borderColor end
    if hoverColor then btn.backgroundColorMouseOver = hoverColor end
    if textColor and btn.setColor then
        btn:setColor(textColor.r, textColor.g, textColor.b, textColor.a)
    end

    if parent and parent.addChild then parent:addChild(btn) end

    return btn
end

function FrameworkZ.Interfaces:CreateSlider(options)
    local x, y = self.Opt(options, "x", 0), self.Opt(options, "y", 0)
    local w, h = self.Opt(options, "width", 100), self.Opt(options, "height", 20)
    local target = self.Opt(options, "target", nil)
    local onChange = self.Opt(options, "onChange", nil)
    local theme = self.Opt(options, "theme", "Default")
    local parent = self.Opt(options, "parent", nil)

    local slider = ISSliderPanel:new(x, y, w, h, target, onChange)
    slider.minValue = self.Opt(options, "min", slider.minValue or 0)
    slider.maxValue = self.Opt(options, "max", slider.maxValue or 1)
    slider.stepValue = self.Opt(options, "step", slider.stepValue or 0.01)
    slider.currentValue = self.Opt(options, "value", slider.currentValue or slider.minValue)
    slider:initialise()

    FrameworkZ.Themes:ApplySliderTheme(slider, theme)

    -- Apply manual overrides
    local bgColor = self.Opt(options, "backgroundColor", nil)
    local borderColor = self.Opt(options, "borderColor", nil)
    if bgColor then slider.backgroundColor = bgColor end
    if borderColor then slider.borderColor = borderColor end

    if parent and parent.addChild then parent:addChild(slider) end

    return slider
end

function FrameworkZ.Interfaces:CreateCombo(options)
    local x, y = self.Opt(options, "x", 0), self.Opt(options, "y", 0)
    local w, h = self.Opt(options, "width", 100), self.Opt(options, "height", 25)
    local target = self.Opt(options, "target", nil)
    local onChange = self.Opt(options, "onChange", nil)
    local options_data = self.Opt(options, "options", nil)
    local theme = self.Opt(options, "theme", "Default")
    local parent = self.Opt(options, "parent", nil)

    local combo = ISComboBox:new(x, y, w, h, target, onChange)
    combo:initialise()
    combo:instantiate()

    if type(options_data) == "table" then
        for _, v in ipairs(options_data) do
            if type(v) == "table" then
                local text = v.text or tostring(v[1] or "")
                combo:addOptionWithData(text, v.data)
            else
                combo:addOption(tostring(v))
            end
        end
    end

    FrameworkZ.Themes:ApplyComboBoxTheme(combo, theme)

    -- Apply manual overrides
    local bgColor = self.Opt(options, "backgroundColor", nil)
    local borderColor = self.Opt(options, "borderColor", nil)
    local textColor = self.Opt(options, "textColor", nil)
    local fontToken = self.Opt(options, "font", nil)

    if bgColor then combo.backgroundColor = bgColor end
    if borderColor then combo.borderColor = borderColor end
    if textColor and combo.setColor then combo:setColor(textColor.r, textColor.g, textColor.b, textColor.a) end
    if fontToken then combo.font = FrameworkZ.Themes:GetFont(fontToken) end

    if parent and parent.addChild then parent:addChild(combo) end

    return combo
end

function FrameworkZ.Interfaces:CreateComboBox(options)
    return self:CreateCombo(options)
end

function FrameworkZ.Interfaces:CreateTextEntry(options)
    local x, y = self.Opt(options, "x", 0), self.Opt(options, "y", 0)
    local w, h = self.Opt(options, "width", 100), self.Opt(options, "height", 25)
    local text = tostring(self.Opt(options, "text", ""))
    local theme = self.Opt(options, "theme", "Default")
    local parent = self.Opt(options, "parent", nil)
    local multiple = self.Opt(options, "multipleLines", false)
    local maxLines = self.Opt(options, "maxLines", multiple and 0 or 1)

    local entry = ISTextEntryBox:new(text, x, y, w, h)
    entry:initialise()
    entry:instantiate()

    if multiple and entry.setMultipleLine then
        entry:setMultipleLine(true)
        if entry.setMaxLines then entry:setMaxLines(maxLines) end
        entry.hasVScrollBar = true
    end

    FrameworkZ.Themes:ApplyTextEntryTheme(entry, theme)

    -- Apply manual overrides
    local bgColor = self.Opt(options, "backgroundColor", nil)
    local borderColor = self.Opt(options, "borderColor", nil)
    local textColor = self.Opt(options, "textColor", nil)
    local fontToken = self.Opt(options, "font", nil)

    if bgColor then entry.backgroundColor = bgColor end
    if borderColor then entry.borderColor = borderColor end
    if textColor and entry.setColor then entry:setColor(textColor.r, textColor.g, textColor.b, textColor.a) end
    if fontToken then entry.font = FrameworkZ.Themes:GetFont(fontToken) end

    if parent and parent.addChild then parent:addChild(entry) end

    return entry
end

function FrameworkZ.Interfaces:CreateTextBox(options)
    return self:CreateTextEntry(options)
end

function FrameworkZ.Interfaces:Create(kind, options)
    if not kind then return nil end
    if kind == "Panel" then return self:CreatePanel(options) end
    if kind == "Label" then return self:CreateLabel(options) end
    if kind == "Button" then return self:CreateButton(options) end
    if kind == "Slider" then return self:CreateSlider(options) end
    if kind == "Combo" or kind == "ComboBox" then return self:CreateCombo(options) end
    if kind == "TextEntry" or kind == "TextBox" or kind == "TextEntryBox" then return self:CreateTextEntry(options) end
    print("[FZ][Interfaces] Unknown factory kind: " .. tostring(kind))
    return nil
end

function FrameworkZ.Interfaces:New(uniqueID, parentTable)
    local object = {
        UniqueID = uniqueID or "DefaultInterface",
        Parent = parentTable or nil
    }

    setmetatable(object, {})

    return object
end

function FrameworkZ.Interfaces:Register(tbl, index)
    if self.List[index] then
        print("[FZ] Interface '" .. index .. "' is already registered. Use 'FrameworkZ.Interfaces:GetInterface(index)' to modify an already existing interface. Re-registration has been aborted.")
        return {}
    end

    self.List[index] = tbl

    return self.List[index]
end

function FrameworkZ.Interfaces:GetInterface(index)
    return self.List[index]
end

function FrameworkZ.Interfaces:Initialize()
    local uiPanel = ISPanel
    if not uiPanel or not uiPanel.derive then return end

    for k, v in pairs(self.List) do
        local derived = uiPanel:derive(k)
        FrameworkZ.Utilities:MergeTables(v, derived)
        setmetatable(v, getmetatable(derived))
        self.List[k] = v
    end
end
