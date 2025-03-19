

--[[
local sidebar = ISEquippedItem.instance
local a = FrameworkZ.fzTabMenu:new(sidebar:getX(), sidebar:getY() + sidebar:getHeight() + 10, sidebar:getWidth(), 40, getPlayer())
a:initialise()
a:addToUIManager()
--]]

FrameworkZ = FrameworkZ or {}
FrameworkZ.fzTabMenu = ISPanel:derive("fzTabMenu")

local getTextManager = getTextManager
local getTexture = getTexture
local ISButton = ISButton
local ISEquippedItem = ISEquippedItem
local ISPanel = ISPanel

function FrameworkZ.fzTabMenu:initialise()
    ISPanel.initialise(self)

    local buttonWidth = self.fzIconOff:getWidthOrig()
    local buttonHeight = self.fzIconOff:getHeightOrig()
    self.tabButton = ISButton:new(5, 0, buttonWidth, buttonHeight, "", self, FrameworkZ.fzTabMenu.onOptionMouseDown)
    self.tabButton:setImage(self.fzIconOff)
    self.tabButton.internal = "TAB_MENU"
    self.tabButton:initialise()
    self.tabButton:instantiate()
    self.tabButton:setDisplayBackground(false)

    self.tabButton.borderColor = {r=1, g=1, b=1, a=0}
    self.tabButton:ignoreWidthChange()
    self.tabButton:ignoreHeightChange()

    self:addChild(self.tabButton)

    self:setHeight(self.tabButton:getBottom())
    y = self.tabButton:getY() + self.fzIconOff:getHeightOrig() + 10
end

function FrameworkZ.fzTabMenu:onOptionMouseDown(button, x, y)
    if button.internal == "TAB_MENU" then
        if FrameworkZ.fzTabPanel.instance then
            FrameworkZ.fzTabPanel.instance:onClose()
        else
            local modal = FrameworkZ.fzTabPanel:new(self.isoPlayer)
            modal:initialise()
            modal:addToUIManager()
        end
    end
end

function FrameworkZ.fzTabMenu:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function FrameworkZ.fzTabMenu:render()
    ISPanel.render(self)
end

function FrameworkZ.fzTabMenu:prerender()
    ISPanel.prerender(self)

    if self.tabButton then
        if FrameworkZ.fzTabPanel.instance then
            self.tabButton:setImage(self.fzIconOn);
        else
            self.tabButton:setImage(self.fzIconOff);
        end
    end
end

function FrameworkZ.fzTabMenu:update()
    ISPanel.update(self)
end

function FrameworkZ.fzTabMenu:new(x, y, width, height, isoPlayer)
	local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.isoPlayer = isoPlayer
    o.fzIconOn = getTexture("media/textures/fz-on.png")
    o.fzIconOff = getTexture("media/textures/fz-off.png")
	FrameworkZ.fzTabMenu.instance = o

	return o
end

--[[
    Tab Panel
--]]

FrameworkZ.fzTabPanel = ISPanel:derive("fzTabPanel")

-- UI Constants
local buttonFont = UIFont.Title -- Increased to Title size
local TITLE_FONT_SIZE = UIFont.Title
local START_X = 20
local PANEL_WIDTH = 400
local PANEL_HEIGHT = getCore():getScreenHeight()
local BUTTON_PADDING = 50 -- Padding between buttons
local BOTTOM_PADDING = 20 -- Space between bottom and close button

function FrameworkZ.fzTabPanel:initialise()
    ISPanel.initialise(self)

    -- Start off-screen
    self:setX(-PANEL_WIDTH)
    self:setY(0)
    self:setWidth(PANEL_WIDTH)
    self:setHeight(PANEL_HEIGHT)

    -- Title Bar
    local titleText = "Tab Menu"
    local titleWidth = getTextManager():MeasureStringX(TITLE_FONT_SIZE, titleText)
    local titleX = (self:getWidth() - titleWidth) / 2
    self.titleLabel = ISLabel:new(titleX, 20, 60, titleText, 1, 1, 1, 1, TITLE_FONT_SIZE, true)
    self:addChild(self.titleLabel)

    -- Close Button (Corner X)
    self.closeButton = ISButton:new(self:getWidth() - 30, 10, 20, 20, "X", self, FrameworkZ.fzTabPanel.onMenuSelect)
    self.closeButton.internal = "CLOSE"
    self.closeButton.font = buttonFont
    self.closeButton:setDisplayBackground(false) -- Removed background
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- Hover effect for Close Button
    self.closeButton.oldOnMouseMove = self.closeButton.onMouseMove
    self.closeButton.onMouseMove = function(x, y)
        self.closeButton.oldOnMouseMove(x, y)
        if self.closeButton.mouseOver then
            self.closeButton.textColor = {r=1, g=0.84, b=0, a=1}
        end
    end

    self.closeButton.oldOnMouseMoveOutside = self.closeButton.onMouseMoveOutside
    self.closeButton.onMouseMoveOutside = function(x, y)
        self.closeButton.oldOnMouseMoveOutside(x, y)
        if not self.closeButton.mouseOver then
            self.closeButton.textColor = {r=1, g=1, b=1, a=1}
        end
    end

    local yOffset = 100 + BUTTON_PADDING
    self.buttons = {}

    for _, buttonData in ipairs(FrameworkZ.fzTabPanel.buttons) do
        local textWidth = getTextManager():MeasureStringX(buttonFont, buttonData.text)
        local textHeight = getTextManager():MeasureStringY(buttonFont, buttonData.text)

        local button = ISButton:new(START_X, yOffset, textWidth, textHeight, buttonData.text, buttonData.target, buttonData.callback)
        button.internal = buttonData.internal
        button.font = buttonFont
        button:setDisplayBackground(false) -- Removed background
        button:initialise()

        -- Hover effect for buttons
        button.oldOnMouseMove = button.onMouseMove
        button.onMouseMove = function(x, y)
            button.oldOnMouseMove(x, y)
            if button.mouseOver then
                button.textColor = {r=1, g=0.84, b=0, a=1}
            end
        end

        button.oldOnMouseMoveOutside = button.onMouseMoveOutside
        button.onMouseMoveOutside = function(x, y)
            button.oldOnMouseMoveOutside(x, y)
            if not button.mouseOver then
                button.textColor = {r=1, g=1, b=1, a=1}
            end
        end

        self:addChild(button)
        table.insert(self.buttons, button)

        yOffset = yOffset + textHeight + BUTTON_PADDING
    end

    -- Close Button (Text)
    local textWidth = getTextManager():MeasureStringX(buttonFont, "Close")
    local textHeight = getTextManager():MeasureStringY(buttonFont, "Close")

    self.textCloseButton = ISButton:new(START_X, PANEL_HEIGHT - textHeight - BOTTOM_PADDING, textWidth, textHeight, "Close", self, FrameworkZ.fzTabPanel.onMenuSelect)
    self.textCloseButton.internal = "CLOSE"
    self.textCloseButton.font = buttonFont
    self.textCloseButton:setDisplayBackground(false) -- Removed background
    self.textCloseButton:initialise()

    -- Hover effect for close button
    self.textCloseButton.oldOnMouseMove = self.textCloseButton.onMouseMove
    self.textCloseButton.onMouseMove = function(x, y)
        self.textCloseButton.oldOnMouseMove(x, y)
        if self.textCloseButton.mouseOver then
            self.textCloseButton.textColor = {r=1, g=0.84, b=0, a=1}
        end
    end

    self.textCloseButton.oldOnMouseMoveOutside = self.textCloseButton.onMouseMoveOutside
    self.textCloseButton.onMouseMoveOutside = function(x, y)
        self.textCloseButton.oldOnMouseMoveOutside(x, y)
        if not self.textCloseButton.mouseOver then
            self.textCloseButton.textColor = {r=1, g=1, b=1, a=1}
        end
    end

    self:addChild(self.textCloseButton)

    -- Animate the panel sliding in
    FrameworkZ.Timers:Create("TabPanelSlideOut", 0, 0, function()
        if self:getX() < 0 then
            self:setX(self:getX() + self:getWidth() * 0.05)
        else
            self:setX(0)
            FrameworkZ.Timers:Remove("TabPanelSlideOut")
        end
    end)
end

function FrameworkZ.fzTabPanel:update()
    ISPanel.update(self)
end

function FrameworkZ.fzTabPanel:onClose()
    if FrameworkZ.Timers:Exists("TabPanelSlideOut") then
        FrameworkZ.Timers:Remove("TabPanelSlideOut")
    end

    FrameworkZ.Timers:Create("TabPanelSlideIn", 0, 0, function()
        if self:getX() > -PANEL_WIDTH then
            self:setX(self:getX() - self:getWidth() * 0.05)
        else
            FrameworkZ.Timers:Remove("TabPanelSlideIn")

            self:setX(-PANEL_WIDTH)
            self:setVisible(false)
            self:removeFromUIManager()
            FrameworkZ.fzTabPanel.instance = nil
        end
    end)
end

function FrameworkZ.fzTabPanel:onMenuSelect(button, x, y)
    if button.internal == "CLOSE" then
        self:onClose()
    elseif button.internal == "CHARACTERS" then
        print("Returning to Main Menu")
    elseif button.internal == "MY_CHARACTER" then
        print("Opening My Character Menu")
    elseif button.internal == "SCOREBOARD" then
        print("Opening Player List")
    elseif button.internal == "DIRECTORY" then
        print("Opening Directory")
    elseif button.internal == "CONFIG" then
        print("Opening Config")
    end
end


FrameworkZ.fzTabPanel.buttons = {
    {text = "CHARACTERS", internal = "CHARACTERS", callback = FrameworkZ.fzTabPanel.onMenuSelect, target = FrameworkZ.fzTabPanel.instance},
    {text = "MY CHARACTER", internal = "MY_CHARACTER", callback = FrameworkZ.fzTabPanel.onMenuSelect, target = FrameworkZ.fzTabPanel.instance},
    {text = "Scoreboard", internal = "SCOREBOARD", callback = FrameworkZ.fzTabPanel.onMenuSelect, target = FrameworkZ.fzTabPanel.instance},
    {text = "Directory", internal = "DIRECTORY", callback = FrameworkZ.fzTabPanel.onMenuSelect, target = FrameworkZ.fzTabPanel.instance},
    {text = "Config", internal = "CONFIG", callback = FrameworkZ.fzTabPanel.onMenuSelect, target = FrameworkZ.fzTabPanel.instance},
}

function FrameworkZ.fzTabPanel:new(isoPlayer)
    local o = ISPanel:new(-PANEL_WIDTH, 0, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=1, g=1, b=1, a=0}
    o.keepOnScreen = false
    o.moveWithMouse = false
    o.isoPlayer = isoPlayer

    FrameworkZ.fzTabPanel.instance = o

    return o
end

return FrameworkZ.fzTabPanel
