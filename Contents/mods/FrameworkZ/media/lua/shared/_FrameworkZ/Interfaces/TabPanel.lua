FrameworkZ.UI.TabPanel = FrameworkZ.UI.TabPanel or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.TabPanel, "TabPanel")

local PANEL_X = 0
local PANEL_Y = 0
local PANEL_WIDTH = getCore():getScreenWidth() * 0.2  -- Increased to accommodate larger Directory panel
local PANEL_HEIGHT = getCore():getScreenHeight()
local PANEL_MARGIN_X = 20
local PANEL_MARGIN_Y = 20
local SLIDE_TIME = 0.25

function FrameworkZ.UI.TabPanel:initialise()
    local TITLE_TEXT = "Tab Menu"
    local FONT_TITLE = UIFont.Title
    local TITLE_WIDTH = getTextManager():MeasureStringX(FONT_TITLE, TITLE_TEXT)
    local TITLE_HEIGHT = getTextManager():MeasureStringY(FONT_TITLE, TITLE_TEXT)
    local TITLE_PADDING_TOP = 50
    local TITLE_PADDING_BOTTOM = 50
    local BUTTON_PADDING_BOTTOM = 30
    local CATEGORY_PADDING_BOTTOM = 15
    local CATEGORY_LABEL_PADDING_BOTTOM = 8
    local SEPARATOR_HEIGHT = 3
    local TITLE_X = (PANEL_WIDTH - TITLE_WIDTH) / 2
    local TITLE_Y = PANEL_MARGIN_Y + TITLE_PADDING_TOP

    ISPanel.initialise(self)

    self.titleLabel = ISLabel:new(TITLE_X, TITLE_Y, TITLE_HEIGHT, TITLE_TEXT, 1, 1, 1, 1, FONT_TITLE, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.closeButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_WIDTH - PANEL_MARGIN_X, PANEL_MARGIN_Y, "X", self, FrameworkZ.UI.TabPanel.onMenuSelect)
    self.closeButton:setX(PANEL_WIDTH - self.closeButton:getWidth() - PANEL_MARGIN_X)
    self.closeButton.internal = "CLOSE"

    local contentPanelYOffset = self.titleLabel:getY() + self.titleLabel:getHeight() + TITLE_PADDING_BOTTOM
    local closeButtonTextHeight = getTextManager():MeasureStringY(FrameworkZ.UserInterfaces.ButtonTheme.hugeButtonFontSize, "Close")
    local contentPanelHeight = PANEL_HEIGHT - contentPanelYOffset - PANEL_MARGIN_Y * 2 - closeButtonTextHeight

    -- Create scrollable content panel
    self.contentPanel = ISPanel:new(0, contentPanelYOffset, PANEL_WIDTH, contentPanelHeight)
    self.contentPanel.backgroundColor = {r=0, g=0, b=0, a=0}

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
    self:addChild(self.contentPanel)

    local mainYOffset = CATEGORY_PADDING_BOTTOM
    self.buttons = {}
    local currentCategory = nil

    -- Group buttons by category
    local categoryGroups = {}
    for _, buttonData in ipairs(FrameworkZ.UI.TabPanel.buttons) do
        if buttonData.category then
            if not categoryGroups[buttonData.category] then
                categoryGroups[buttonData.category] = {}
            end
            table.insert(categoryGroups[buttonData.category], buttonData)
        end
    end

    -- Create buttons and category separators
    local isFirstCategory = true
    for _, category in ipairs({"Character", "Tools", "Settings", "Admin"}) do
        if categoryGroups[category] then
            -- Add separator before category (except for first)
            if not isFirstCategory then
                local separator = ISPanel:new(PANEL_MARGIN_X, mainYOffset, PANEL_WIDTH - (PANEL_MARGIN_X * 2), SEPARATOR_HEIGHT)
                separator.backgroundColor = {r=0.3, g=0.3, b=0.3, a=0.4}
                separator.borderColor = {r=0, g=0, b=0, a=0}
                separator:initialise()
                self.contentPanel:addChild(separator)
                mainYOffset = mainYOffset + SEPARATOR_HEIGHT + CATEGORY_PADDING_BOTTOM
            end

            -- Add category label
            local categoryLabel = ISLabel:new(PANEL_MARGIN_X, mainYOffset, 20, category, 1, 1, 1, 1, UIFont.Small, true)
            categoryLabel:initialise()
            self.contentPanel:addChild(categoryLabel)
            mainYOffset = mainYOffset + 20 + CATEGORY_LABEL_PADDING_BOTTOM

            -- Add buttons for this category
            for _, buttonData in ipairs(categoryGroups[category]) do
                local button = FrameworkZ.UserInterfaces:CreateHugeButton(self.contentPanel, PANEL_MARGIN_X, mainYOffset, buttonData.text, self, buttonData.callback)
                button.internal = buttonData.internal

                table.insert(self.buttons, button)
                mainYOffset = mainYOffset + button:getHeight() + BUTTON_PADDING_BOTTOM
            end

            isFirstCategory = false
        end
    end

    -- Set scroll height and add scrollbars
    self.contentPanel:setScrollHeight(mainYOffset + PANEL_MARGIN_Y)
    self.contentPanel:addScrollBars()
    self.contentPanel:setScrollChildren(true)

    local textHeight = getTextManager():MeasureStringY(FrameworkZ.UserInterfaces.ButtonTheme.hugeButtonFontSize, "Close")
    self.textCloseButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_X + PANEL_MARGIN_X, PANEL_HEIGHT - textHeight - PANEL_MARGIN_Y, "Close", self, FrameworkZ.UI.TabPanel.onMenuSelect)
    self.textCloseButton.internal = "CLOSE"

    self:slideOut()
end

function FrameworkZ.UI.TabPanel:slideOut()
    if not self:isVisible() then
        self:setX(-PANEL_WIDTH)
        self:setVisible(true)
    end

    FrameworkZ.Timers:Remove("TabPanelSlideOut")

    FrameworkZ.Timers:Create("TabPanelSlideOut", 0, 0, function()
        local fps = getAverageFPS() or 60
        local dt = 1 / fps
        local speed = PANEL_WIDTH / SLIDE_TIME
        local dx = speed * dt

        local newX = math.min(self:getX() + dx, 0)
        self:setX(newX)

        if newX >= 0 then
            FrameworkZ.Timers:Remove("TabPanelSlideOut")
        end
    end)
end

function FrameworkZ.UI.TabPanel:slideIn()
    FrameworkZ.Timers:Remove("TabPanelSlideIn")

    FrameworkZ.Timers:Create("TabPanelSlideIn", 0, 0, function()
        local fps = getAverageFPS() or 60
        local dt = 1 / fps
        local speed = PANEL_WIDTH / SLIDE_TIME
        local dx = speed * dt

        local newX = math.max(self:getX() - dx, -PANEL_WIDTH)
        self:setX(newX)

        if newX <= -PANEL_WIDTH then
            FrameworkZ.Timers:Remove("TabPanelSlideIn")
            self:setVisible(false)
            self:removeFromUIManager()
            FrameworkZ.UI.TabPanel.instance = nil
        end
    end)
end

function FrameworkZ.UI.TabPanel:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.TabPanel:prerender()
    ISPanel.prerender(self)
end

function FrameworkZ.UI.TabPanel:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.TabPanel:registerPanel(panel)
    if not self.openPanels then
        self.openPanels = {}
    end
    table.insert(self.openPanels, panel)
end

function FrameworkZ.UI.TabPanel:unregisterPanel(panel)
    if self.openPanels then
        for i, p in ipairs(self.openPanels) do
            if p == panel then
                table.remove(self.openPanels, i)
                break
            end
        end
    end
end

function FrameworkZ.UI.TabPanel:close()
    FrameworkZ.Timers:Remove("TabPanelSlideOut")

    -- Close all registered panels
    if self.openPanels then
        for _, panel in ipairs(self.openPanels) do
            if panel and panel.close then
                panel:close()
            end
        end
        self.openPanels = {}
    end

    self:slideIn()
end

function FrameworkZ.UI.TabPanel:onMenuSelect(button, x, y)
    if button.internal == "CLOSE" then
        self:close()
    elseif button.internal == "CHARACTERS" then
        self.characterSelect = FrameworkZ.UI.MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.isoPlayer)
        self.characterSelect.backgroundImageOpacity = 0.5
        self.characterSelect.backgroundColor = {r=0, g=0, b=0, a=0}
        self.characterSelect:initialise()
        self.characterSelect:addToUIManager()

        self:close()
    elseif button.internal == "MY_CHARACTER" then
        print("Opening My Character Menu")
    elseif button.internal == "SESSION" then
        if FrameworkZ.UI.TabSession.instance then
            FrameworkZ.UI.TabSession.instance:close()
        elseif FrameworkZ.UI.TabMenu.instance then
            if FrameworkZ.UI.TabPanel.instance.currentPanel then
                FrameworkZ.UI.TabPanel.instance.currentPanel:close()
            end

            local session = FrameworkZ.UI.TabSession:new(self.isoPlayer)

            if session then
                session:initialise()
                session:addToUIManager()

                FrameworkZ.UI.TabPanel.instance.currentPanel = session
            end
        end
    elseif button.internal == "DIRECTORY" then
        if FrameworkZ.UI.TabPanel.instance and FrameworkZ.UI.TabPanel.instance.currentPanel then
            FrameworkZ.UI.TabPanel.instance.currentPanel:close()
            FrameworkZ.UI.TabPanel.instance.currentPanel = nil
        end

        if FrameworkZ.UI.TabDirectory.instance then
            FrameworkZ.UI.TabDirectory.instance:close()
            FrameworkZ.UI.TabPanel.instance.currentPanel = nil
        else
            local directory = FrameworkZ.UI.TabDirectory:new(self.isoPlayer)
            if directory then
                directory:initialise()
                directory:addToUIManager()
                FrameworkZ.UI.TabDirectory.instance = directory
                FrameworkZ.UI.TabPanel.instance.currentPanel = directory
            end
        end
    elseif button.internal == "CONFIG" then
        print("Opening Config")
    end
end

FrameworkZ.UI.TabPanel.buttons = {
    -- Character Management
    {category = "Character", text = "Characters", internal = "CHARACTERS", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Character", text = "My Character", internal = "MY_CHARACTER", callback = FrameworkZ.UI.TabPanel.onMenuSelect},

    -- Tools & Services
    {category = "Tools", text = "Session", internal = "SESSION", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Tools", text = "Directory", internal = "DIRECTORY", callback = FrameworkZ.UI.TabPanel.onMenuSelect},

    -- Settings
    {category = "Settings", text = "Config", internal = "CONFIG", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Settings", text = "Info", internal = "INFO", callback = FrameworkZ.UI.TabPanel.onMenuSelect},

    -- Admin
    {category = "Admin", text = "Server Settings", internal = "SERVER_SETTINGS", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Admin", text = "Roles", internal = "ROLES", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Admin", text = "Logs", internal = "LOGS", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Admin", text = "Players", internal = "PLAYERS", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Admin", text = "Whitelist", internal = "WHITELIST", callback = FrameworkZ.UI.TabPanel.onMenuSelect},
    {category = "Admin", text = "Announcements", internal = "ANNOUNCEMENTS", callback = FrameworkZ.UI.TabPanel.onMenuSelect}
}

function FrameworkZ.UI.TabPanel:new(isoPlayer)
    local o = ISPanel:new(-PANEL_WIDTH, PANEL_Y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.keepOnScreen = false
    o.moveWithMouse = false
    o.isoPlayer = isoPlayer
    o.openPanels = {}

    FrameworkZ.UI.TabPanel.instance = o

    return o
end

return FrameworkZ.UI.TabPanel
