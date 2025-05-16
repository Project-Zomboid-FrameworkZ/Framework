FrameworkZ = FrameworkZ or {}
FrameworkZ.UI.TabMenu = ISPanel:derive("fzuiTabMenu")

local getTexture = getTexture
local ISButton = ISButton
local ISPanel = ISPanel

function FrameworkZ.UI.TabMenu:initialise()
    ISPanel.initialise(self)

    local buttonWidth = self.fzIconOff:getWidthOrig()
    local buttonHeight = self.fzIconOff:getHeightOrig()
    self.tabButton = ISButton:new(5, 0, buttonWidth, buttonHeight, "", self, FrameworkZ.UI.TabMenu.onOptionMouseDown)
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
end

function FrameworkZ.UI.TabMenu:onOptionMouseDown(button, x, y)
    if button.internal == "TAB_MENU" then
        if FrameworkZ.UI.TabPanel.instance then
            FrameworkZ.UI.TabPanel.instance:onClose()
        else
            local modal = FrameworkZ.UI.TabPanel:new(self.isoPlayer)
            modal:initialise()
            modal:addToUIManager()
        end
    end
end

function FrameworkZ.UI.TabMenu:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function FrameworkZ.UI.TabMenu:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.TabMenu:prerender()
    ISPanel.prerender(self)

    if self.tabButton then
        if FrameworkZ.UI.TabPanel.instance then
            self.tabButton:setImage(self.fzIconOn);
        else
            self.tabButton:setImage(self.fzIconOff);
        end
    end
end

function FrameworkZ.UI.TabMenu:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.TabMenu:new(x, y, width, height, isoPlayer)
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
	FrameworkZ.UI.TabMenu.instance = o

	return o
end

return FrameworkZ.UI.TabMenu
