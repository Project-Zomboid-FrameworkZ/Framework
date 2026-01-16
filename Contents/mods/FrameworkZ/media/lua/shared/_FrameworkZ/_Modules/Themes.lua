FrameworkZ = FrameworkZ or {}

--! \module FrameworkZ.Themes
-- Centralized UI Theme for FrameworkZ
-- Provides: palette, typography, spacing, layout defaults, and helpers to style common IS* widgets
FrameworkZ.Themes = FrameworkZ.Themes or {}
FrameworkZ.Themes.__index = FrameworkZ.Themes
FrameworkZ.Themes = FrameworkZ.Foundation:NewModule(FrameworkZ.Themes, "Themes")

FrameworkZ.Themes.Styles = {
    Colors = {
        Background      = { r = 0.05, g = 0.05, b = 0.05, a = 1.00 },
        Surface         = { r = 0.10, g = 0.10, b = 0.10, a = 0.90 },
        Elevated        = { r = 0.15, g = 0.15, b = 0.15, a = 0.85 },
        Overlay         = { r = 0.10, g = 0.10, b = 0.10, a = 0.75 },
        Transparent     = { r = 0.00, g = 0.00, b = 0.00, a = 0.00 },
        Border          = { r = 0.40, g = 0.40, b = 0.40, a = 0.95 },
        Primary         = { r = 0.94, g = 0.83, b = 0.24, a = 1.00 },
        Secondary       = { r = 0.26, g = 0.20, b = 0.11, a = 1.00 },
        Accent          = { r = 0.40, g = 0.65, b = 0.70, a = 1.00 },
        Success         = { r = 0.26, g = 0.84, b = 0.47, a = 1.00 },
        Warning         = { r = 0.95, g = 0.75, b = 0.30, a = 1.00 },
        Danger          = { r = 0.85, g = 0.25, b = 0.25, a = 1.00 },
        DangerAlt       = { r = 0.75, g = 0.15, b = 0.15, a = 1.00 },
        TextPrimary     = { r = 0.98, g = 0.97, b = 0.92, a = 1.00 },
        TextSecondary   = { r = 0.90, g = 0.88, b = 0.80, a = 1.00 },
        TextMuted       = { r = 0.74, g = 0.72, b = 0.66, a = 1.00 },
        TextDark        = { r = 0.03, g = 0.03, b = 0.03, a = 1.00 },
        TextLight       = { r = 0.90, g = 0.88, b = 0.80, a = 1.00 }
    },
    Typography = {
        Title  = FZ_FONT_TITLE,
        Large  = FZ_FONT_LARGE,
        Medium = FZ_FONT_MEDIUM,
        Small  = FZ_FONT_SMALL,
    }
}

FrameworkZ.Themes.DefaultTheme = {
    Button = {
        Default = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Primary,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Secondary,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextLight,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Danger = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Danger,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.DangerAlt,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextLight,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Success = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Success,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Success,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextDark,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Warning = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Warning,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Warning,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextDark,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Basic = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Transparent,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Transparent,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Transparent,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.Primary,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        }
    },
    ComboBox = {
        Default = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Primary,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextLight,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Danger = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Danger,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Danger,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextDark,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Success = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Success,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Success,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextDark,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        },
        Warning = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Warning,
            HoverColor      = FrameworkZ.Themes.Styles.Colors.Warning,
            HoverTextColor  = FrameworkZ.Themes.Styles.Colors.TextDark,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
        }
    },
    Label = {
        Title = {
            TextColor = FrameworkZ.Themes.Styles.Colors.TextPrimary,
            Font  = FrameworkZ.Themes.Styles.Typography.Title,
        },
        Body = {
            TextColor = FrameworkZ.Themes.Styles.Colors.TextSecondary,
            Font  = FrameworkZ.Themes.Styles.Typography.Medium,
        },
        Caption = {
            TextColor = FrameworkZ.Themes.Styles.Colors.TextMuted,
            Font  = FrameworkZ.Themes.Styles.Typography.Small,
        }
    },
    Panel = {
        Default = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Background,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
        },
        Alt = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
        },
        Card = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Primary,
        },
        Overlay = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Overlay,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
        },
        Outline = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Transparent,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
        },
        Basic = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Transparent,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Transparent,
        }
    },
    Slider = {
        Default = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
        }
    },
    TextEntry = {
        Default = {
            BackgroundColor = FrameworkZ.Themes.Styles.Colors.Surface,
            BorderColor     = FrameworkZ.Themes.Styles.Colors.Border,
            TextColor       = FrameworkZ.Themes.Styles.Colors.TextLight,
            Font            = FrameworkZ.Themes.Styles.Typography.Medium,
        }
    }
}

-- Helper function to resolve font constants from typography tokens
function FrameworkZ.Themes:GetFont(fontToken)
    if UIFont and fontToken and UIFont[fontToken] then
        return UIFont[fontToken]
    end
    -- Fallback to UIFont.Small
    return UIFont.Small
end

-- Clean theme application methods using DefaultTheme structure

-- Apply button theme from DefaultTheme.Button themes
function FrameworkZ.Themes:ApplyButtonTheme(button, theme)
    if not button then return end
    theme = theme or "Default"
    local theme = self.DefaultTheme.Button[theme]
    if not theme then return end
    
    -- Apply colors (create NEW table instances to avoid shared references)
    button.backgroundColor = {r = theme.BackgroundColor.r, g = theme.BackgroundColor.g, b = theme.BackgroundColor.b, a = theme.BackgroundColor.a}
    button.borderColor = {r = theme.BorderColor.r, g = theme.BorderColor.g, b = theme.BorderColor.b, a = theme.BorderColor.a}
    if theme.HoverColor then
        button.backgroundColorMouseOver = {r = theme.HoverColor.r, g = theme.HoverColor.g, b = theme.HoverColor.b, a = theme.HoverColor.a}
    end
    
    -- Apply text color (create NEW table instance)
    if button.setColor and theme.TextColor then
        local c = theme.TextColor
        button.textColor = {r = c.r, g = c.g, b = c.b, a = c.a}
    end
    
    -- Store theme colors as local copies for this specific button instance
    local normalBg = button.backgroundColor
    local normalBorder = button.borderColor
    local normalText = button.textColor
    local hoverBg = button.backgroundColorMouseOver
    local hoverBorder = theme.HoverBorderColor and {r = theme.HoverBorderColor.r, g = theme.HoverBorderColor.g, b = theme.HoverBorderColor.b, a = theme.HoverBorderColor.a} or nil
    local hoverText = theme.HoverTextColor and {r = theme.HoverTextColor.r, g = theme.HoverTextColor.g, b = theme.HoverTextColor.b, a = theme.HoverTextColor.a} or nil
    
    -- Apply hover text color on mouse enter and revert on mouse exit
    button.oldOnMouseMove = button.onMouseMove
    button.onMouseMove = function(self2, dx, dy)
        if button.oldOnMouseMove then
            button.oldOnMouseMove(self2, dx, dy)
        end

        if self2.mouseOver and self2.enable then
            if hoverBorder then self2.borderColor = {r = hoverBorder.r, g = hoverBorder.g, b = hoverBorder.b, a = hoverBorder.a} end
            if hoverBg then self2.backgroundColor = {r = hoverBg.r, g = hoverBg.g, b = hoverBg.b, a = hoverBg.a} end
            if hoverText then self2.textColor = {r = hoverText.r, g = hoverText.g, b = hoverText.b, a = hoverText.a} end
        end
    end

    button.oldOnMouseMoveOutside = button.onMouseMoveOutside
    button.onMouseMoveOutside = function(self2, dx, dy)
        if button.oldOnMouseMoveOutside then
            button.oldOnMouseMoveOutside(self2, dx, dy)
        end

        if not self2.mouseOver and self2.enable then
            if normalBorder then self2.borderColor = {r = normalBorder.r, g = normalBorder.g, b = normalBorder.b, a = normalBorder.a} end
            if normalBg then self2.backgroundColor = {r = normalBg.r, g = normalBg.g, b = normalBg.b, a = normalBg.a} end
            if normalText then self2.textColor = {r = normalText.r, g = normalText.g, b = normalText.b, a = normalText.a} end
        end
    end
end

-- Apply panel theme from DefaultTheme.Panel themes
function FrameworkZ.Themes:ApplyPanelTheme(panel, themeName)
    if not panel then return end
    themeName = themeName or "Default"
    local theme = self.DefaultTheme.Panel[themeName]
    if not theme then return end

    panel.backgroundColor = theme.BackgroundColor
    panel.borderColor = theme.BorderColor
end

-- Apply label theme from DefaultTheme.Label themes
function FrameworkZ.Themes:ApplyLabelTheme(label, theme)
    if not label then return end
    theme = theme or "Body"
    local theme = self.DefaultTheme.Label[theme]
    if not theme then return end

    -- Apply color
    if label.setColor and theme.TextColor then
        local c = theme.TextColor
        label.r = c.r
        label.g = c.g
        label.b = c.b
        label.a = c.a
    end

    -- Apply font
    if theme.Font then
        label.font = self:GetFont(theme.Font)
    end
end

-- Apply combo box theme from DefaultTheme.ComboBox themes
function FrameworkZ.Themes:ApplyComboBoxTheme(combo, theme)
    if not combo then return end
    theme = theme or "Default"
    local theme = self.DefaultTheme.ComboBox[theme]
    if not theme then return end
    
    combo.backgroundColor = theme.BackgroundColor
    combo.borderColor = theme.BorderColor
    
    -- Apply text color
    if combo.setColor and theme.TextColor then
        local c = theme.TextColor
        combo:setColor(c.r, c.g, c.b, c.a)
    end
    
    -- Apply hover colors
    if theme.HoverColor then
        combo.backgroundColorMouseOver = theme.HoverColor
    end
    if theme.HoverTextColor then
        combo.textColorMouseOver = theme.HoverTextColor
    end
end

-- Apply text entry theme from DefaultTheme.TextEntry themes
function FrameworkZ.Themes:ApplyTextEntryTheme(textEntry, theme)
    if not textEntry then return end
    theme = theme or "Default"
    local theme = self.DefaultTheme.TextEntry[theme]
    if not theme then return end
    
    textEntry.backgroundColor = theme.BackgroundColor
    textEntry.borderColor = theme.BorderColor
    
    -- Apply text color
    if textEntry.setColor and theme.TextColor then
        local c = theme.TextColor
        textEntry:setColor(c.r, c.g, c.b, c.a)
    end
    
    -- Apply font
    if theme.Font then
        textEntry.font = self:GetFont(theme.Font)
    end
end

-- Apply slider theme from DefaultTheme.Slider themes
function FrameworkZ.Themes:ApplySliderTheme(slider, theme)
    if not slider then return end
    theme = theme or "Default"
    local theme = self.DefaultTheme.Slider[theme]
    if not theme then return end
    
    slider.backgroundColor = theme.BackgroundColor
    slider.borderColor = theme.BorderColor
end

-- Generic theme application method - detects element type and applies appropriate theme
function FrameworkZ.Themes:ApplyTheme(element, elementType, theme)
    if not element or not elementType then return end
    
    if elementType == "Button" then
        self:ApplyButtonTheme(element, theme)
    elseif elementType == "Panel" then
        self:ApplyPanelTheme(element, theme)
    elseif elementType == "Label" then
        self:ApplyLabelTheme(element, theme)
    elseif elementType == "ComboBox" then
        self:ApplyComboBoxTheme(element, theme)
    elseif elementType == "TextEntry" then
        self:ApplyTextEntryTheme(element, theme)
    elseif elementType == "Slider" then
        self:ApplySliderTheme(element, theme)
    end
end
