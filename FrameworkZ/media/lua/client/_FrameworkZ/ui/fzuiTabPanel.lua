local PANEL_X = 0
local PANEL_Y = 0
local PANEL_WIDTH = getCore():getScreenWidth() * 0.2
local PANEL_HEIGHT = getCore():getScreenHeight()
local PANEL_MARGIN_X = 20
local PANEL_MARGIN_Y = 20

FrameworkZ.fzuiTabPanel = ISPanel:derive("fzuiTabPanel")

function FrameworkZ.fzuiTabPanel:initialise()
    local TITLE_TEXT = "Tab Menu"
    local FONT_TITLE = UIFont.Title
    local TITLE_WIDTH = getTextManager():MeasureStringX(FONT_TITLE, TITLE_TEXT)
    local TITLE_HEIGHT = getTextManager():MeasureStringY(FONT_TITLE, TITLE_TEXT)
    local TITLE_PADDING_TOP = 50
    local TITLE_PADDING_BOTTOM = 50
    local BUTTON_PADDING_BOTTOM = 50
    local TITLE_X = (PANEL_WIDTH - TITLE_WIDTH) / 2
    local TITLE_Y = PANEL_MARGIN_Y + TITLE_PADDING_TOP

    ISPanel.initialise(self)

    self.titleLabel = ISLabel:new(TITLE_X, TITLE_Y, TITLE_HEIGHT, TITLE_TEXT, 1, 1, 1, 1, FONT_TITLE, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.closeButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_WIDTH - PANEL_MARGIN_X, PANEL_MARGIN_Y, "X", self, FrameworkZ.fzuiTabPanel.onMenuSelect)
    self.closeButton:setX(PANEL_WIDTH - self.closeButton:getWidth() - PANEL_MARGIN_X)
    self.closeButton.internal = "CLOSE"

    local yOffset = self.titleLabel:getY() + self.titleLabel:getHeight() + TITLE_PADDING_BOTTOM
    self.buttons = {}

    for _, buttonData in ipairs(FrameworkZ.fzuiTabPanel.buttons) do
        local button = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_X + PANEL_MARGIN_X, yOffset, buttonData.text, self, buttonData.callback)
        button.internal = buttonData.internal
        table.insert(self.buttons, button)
        yOffset = yOffset + button:getHeight() + BUTTON_PADDING_BOTTOM
    end

    local textHeight = getTextManager():MeasureStringY(FrameworkZ.UserInterfaces.ButtonTheme.hugeButtonFontSize, "Close")
    self.textCloseButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_X + PANEL_MARGIN_X, PANEL_HEIGHT - textHeight - PANEL_MARGIN_Y, "Close", self, FrameworkZ.fzuiTabPanel.onMenuSelect)
    self.textCloseButton.internal = "CLOSE"

    FrameworkZ.Timers:Create("TabPanelSlideOut", 0, 0, function()
        if self:getX() < 0 then
            self:setX(self:getX() + self:getWidth() * 0.05)
        else
            self:setX(0)
            FrameworkZ.Timers:Remove("TabPanelSlideOut")
        end
    end)
end

function FrameworkZ.fzuiTabPanel:render()
    ISPanel.render(self)
end

function FrameworkZ.fzuiTabPanel:prerender()
    ISPanel.prerender(self)
end

function FrameworkZ.fzuiTabPanel:update()
    ISPanel.update(self)
end

function FrameworkZ.fzuiTabPanel:onClose()
    if FrameworkZ.Timers:Exists("TabPanelSlideOut") then
        FrameworkZ.Timers:Remove("TabPanelSlideOut")
    end

    if FrameworkZ.fzuiTabSession.instance then
        FrameworkZ.fzuiTabSession.instance:onClose()
    end

    FrameworkZ.Timers:Create("TabPanelSlideIn", 0, 0, function()
        if self:getX() > -PANEL_WIDTH then
            self:setX(self:getX() - self:getWidth() * 0.05)
        else
            FrameworkZ.Timers:Remove("TabPanelSlideIn")

            self:setX(-PANEL_WIDTH)
            self:setVisible(false)
            self:removeFromUIManager()
            FrameworkZ.fzuiTabPanel.instance = nil
        end
    end)
end

function FrameworkZ.fzuiTabPanel:onMenuSelect(button, x, y)
    if button.internal == "CLOSE" then
        self:onClose()
    elseif button.internal == "CHARACTERS" then
        self.characterSelect = PFW_MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.isoPlayer)
        self.characterSelect.backgroundImageOpacity = 0.5
        self.characterSelect.backgroundColor = {r=0, g=0, b=0, a=0}
        self.characterSelect:initialise()
        self.characterSelect:addToUIManager()

        self:onClose()
    elseif button.internal == "MY_CHARACTER" then
        print("Opening My Character Menu")
    elseif button.internal == "SESSION" then
        if FrameworkZ.fzuiTabSession.instance then
            FrameworkZ.fzuiTabSession.instance:setVisible(false)
            FrameworkZ.fzuiTabSession.instance:removeFromUIManager()
            FrameworkZ.fzuiTabSession.instance = nil
        else
            local session = FrameworkZ.fzuiTabSession:new(self.isoPlayer)

            if session then
                session:initialise()
                session:addToUIManager()
            end
        end
    elseif button.internal == "DIRECTORY" then
        print("Opening Directory")
    elseif button.internal == "CONFIG" then
        print("Opening Config")
    end
end

FrameworkZ.fzuiTabPanel.buttons = {
    {text = "CHARACTERS", internal = "CHARACTERS", callback = FrameworkZ.fzuiTabPanel.onMenuSelect},
    {text = "MY CHARACTER", internal = "MY_CHARACTER", callback = FrameworkZ.fzuiTabPanel.onMenuSelect},
    {text = "Session", internal = "SESSION", callback = FrameworkZ.fzuiTabPanel.onMenuSelect},
    {text = "Directory", internal = "DIRECTORY", callback = FrameworkZ.fzuiTabPanel.onMenuSelect},
    {text = "Config", internal = "CONFIG", callback = FrameworkZ.fzuiTabPanel.onMenuSelect}
}

function FrameworkZ.fzuiTabPanel:new(isoPlayer)
    local o = ISPanel:new(-PANEL_WIDTH, PANEL_Y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.keepOnScreen = false
    o.moveWithMouse = false
    o.isoPlayer = isoPlayer

    FrameworkZ.fzuiTabPanel.instance = o

    return o
end

return FrameworkZ.fzuiTabPanel
