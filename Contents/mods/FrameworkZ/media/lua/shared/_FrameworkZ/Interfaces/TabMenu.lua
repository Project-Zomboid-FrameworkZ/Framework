FrameworkZ.UI.TabMenu = FrameworkZ.Interfaces:New("TabMenu", FrameworkZ.UI)
FrameworkZ.Interfaces:Register(FrameworkZ.UI.TabMenu, "TabMenu")

local getTexture = getTexture

function FrameworkZ.UI.TabMenu:initialise()
    ISPanel.initialise(self)

    local buttonWidth = self.fzIconOff:getWidthOrig()
    local buttonHeight = self.fzIconOff:getHeightOrig()
    
    self.tabButton = FrameworkZ.Interfaces:CreateButton({
        x = 5,
        y = 0,
        width = buttonWidth,
        height = buttonHeight,
        title = "",
        target = self,
        onClick = FrameworkZ.UI.TabMenu.onOptionMouseDown,
        parent = self
    })
    self.tabButton:setImage(self.fzIconOff)
    self.tabButton.internal = "TAB_MENU"
    self.tabButton:setDisplayBackground(false)
    self.tabButton.borderColor = {r=1, g=1, b=1, a=0}
    self.tabButton:ignoreWidthChange()
    self.tabButton:ignoreHeightChange()

    self:setHeight(self.tabButton:getBottom())
end

function FrameworkZ.UI.TabMenu:onOptionMouseDown(button, x, y)
    if button.internal == "TAB_MENU" then
        if FrameworkZ.UI.TabPanel.instance then
            FrameworkZ.UI.TabPanel.instance:close()
        else
            local modal = FrameworkZ.UI.TabPanel:new(self.isoPlayer)
            modal:initialise()
            modal:addToUIManager()
        end
    end
end

function FrameworkZ.UI.TabMenu:close()
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
    local sidebar = ISEquippedItem and ISEquippedItem.instance or nil
    if sidebar and sidebar.getX and sidebar.getY and sidebar.getHeight and sidebar.getWidth then
        local desiredX = sidebar:getX()
        local baseBottom = sidebar:getHeight()
        local sidebarBottom = baseBottom
        local sawOverflowChild = false

        local children = sidebar.getChildren and sidebar:getChildren() or nil
        if children and children.size then
            for i = 0, children:size() - 1 do
                local child = children:get(i)
                if child and child.getY and child.getHeight then
                    local visible = true
                    if child.isVisible then
                        visible = child:isVisible()
                    end

                    if visible then
                        local childBottom = child:getY() + child:getHeight()
                        if childBottom > baseBottom then
                            sawOverflowChild = true
                        end
                        if childBottom > sidebarBottom then
                            sidebarBottom = childBottom
                        end
                    end
                end
            end
        end

        local adminOffset = 0
        local canCheckAdmin = self.isoPlayer and self.isoPlayer.isAccessLevel
        if canCheckAdmin and not self.isoPlayer:isAccessLevel("None") and not sawOverflowChild then
            -- Reserve minimal space only when admin controls are not represented as sidebar children.
            adminOffset = 40
        end

        local desiredY = sidebar:getY() + sidebarBottom + adminOffset + 10
        local desiredW = sidebar:getWidth()

        if self:getX() ~= desiredX then
            self:setX(desiredX)
        end

        if self:getY() ~= desiredY then
            self:setY(desiredY)
        end

        if self:getWidth() ~= desiredW then
            self:setWidth(desiredW)
        end
    end

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
