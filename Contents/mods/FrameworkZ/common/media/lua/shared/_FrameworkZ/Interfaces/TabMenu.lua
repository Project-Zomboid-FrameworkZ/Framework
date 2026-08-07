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
    if sidebar and sidebar.getX and sidebar.getY and sidebar.getWidth then
        -- Don't trust sidebar:getHeight() here. Vanilla's shrinkWrap() (ISEquippedItem:initialise(),
        -- media/lua/client/ISUI/ISEquippedItem.lua) sizes the sidebar to the bottom of every ISButton
        -- child it ever CREATED, regardless of visibility - and the safety/client/admin/war-manager
        -- buttons are created unconditionally whenever isClient() is true, with only their *visibility*
        -- toggled later (in prerender(), based on access level). So getHeight() permanently reserves
        -- space for those buttons even when they're hidden (e.g. a non-admin player), leaving a big gap
        -- of empty space below the last actually-visible icon. Instead, scan the sidebar's children
        -- every frame and use the bottom-most edge among only the currently VISIBLE ones - this is
        -- self-correcting regardless of admin status, vanilla version, or other mods adding children.
        --
        -- NOTE: vanilla ISUIElement:getChildren() (media/lua/client/ISUI/ISUIElement.lua) returns
        -- self.children, a plain Lua table KEYED BY ELEMENT ID (self.children[otherElement.ID] = ...),
        -- not a Java-list-style object - it has no :size()/:get(i) methods, so it must be walked with
        -- pairs(). getChildrenInOrder() returns self.childrenInOrder, a real sequential array (built
        -- via table.insert) that also preserves add-order, so it's preferred when available.
        local relativeBottom = 0
        local children = (sidebar.getChildrenInOrder and sidebar:getChildrenInOrder())
            or (sidebar.getChildren and sidebar:getChildren())
            or nil
        if children then
            for _, child in pairs(children) do
                if child and child.getY and child.getHeight then
                    local visible = true
                    if child.isVisible then
                        visible = child:isVisible()
                    end

                    if visible then
                        local childBottom = child:getY() + child:getHeight()
                        if childBottom > relativeBottom then
                            relativeBottom = childBottom
                        end
                    end
                end
            end
        elseif sidebar.getHeight then
            relativeBottom = sidebar:getHeight()
        end

        local desiredX = sidebar:getX()
        local desiredY = sidebar:getY() + relativeBottom + 10
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
