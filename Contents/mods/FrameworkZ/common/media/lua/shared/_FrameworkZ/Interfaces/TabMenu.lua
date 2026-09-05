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

    -- Start hidden: this panel is added to the UI manager during PreInitializeClient, well before
    -- Introduction/character creation/load screens finish, so it would otherwise flash on top of
    -- them for a frame before :update() gets a chance to hide it.
    self:setVisible(false)
end

function FrameworkZ.UI.TabMenu:onOptionMouseDown(button, x, y)
    if button.internal == "TAB_MENU" then
        local instance = FrameworkZ.UI.TabPanel.instance

        -- Guard against a stale instance reference (e.g. detached/removed from the UI
        -- manager some other way without going through :close()) so the menu can never
        -- get permanently stuck unable to reopen.
        if instance and (not instance:isVisible() or not instance:isReallyVisible()) then
            FrameworkZ.UI.TabPanel.instance = nil
            instance = nil
        end

        if instance then
            instance:close()
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
    -- Hide until a character is actually loaded - covers Introduction, character creation, and
    -- the load-character screen uniformly (unlike checking individual menu instances, which stay
    -- set/stale after closing and don't reliably reflect "no character loaded yet").
    -- NOTE: Once a character is loaded, do NOT hide this just because MainMenu is open (e.g. when
    -- MainMenu is reopened transparently from the Tab Panel's "Characters" button to switch
    -- characters) - MainMenu can be fully transparent there, so the icon abruptly vanishing is
    -- jarring/noticeable. Keep it visible and let bringToTop below (which already only acts while
    -- TabPanel itself isn't open) handle z-order against it.
    -- NOTE: GetLoadedCharacterByID returns `false` (not nil) when there's no character, and
    -- `false ~= nil` is true in Lua - so this must check truthiness, not compare against nil.
    -- Also guard against early startup when the Players module may not have initialized yet.
    local isoPlayer = getPlayer and getPlayer() or nil
    local hasLoadedCharacter = false

    if isoPlayer and FrameworkZ.Players and FrameworkZ.Players.GetLoadedCharacterByID then
        hasLoadedCharacter = FrameworkZ.Players:GetLoadedCharacterByID(isoPlayer:getUsername())
    end

    if not hasLoadedCharacter then
        if self:isVisible() then
            self:setVisible(false)
        end

        ISPanel.update(self)
        return
    elseif not self:isVisible() then
        self:setVisible(true)
    end

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

        -- Clamp so extra sidebar buttons (e.g. admin/safety/war-manager becoming visible)
        -- can never push the button below the visible screen, making it unclickable.
        local maxY = getCore():getScreenHeight() - self:getHeight()
        if desiredY > maxY then
            desiredY = maxY
        end

        -- Use an epsilon instead of exact equality: sidebar:getX/Y/Width can jitter by sub-pixel
        -- floating-point amounts every frame, and re-setting position/size that often can leave
        -- the panel's hit-box momentarily out of sync with the coordinates a click was captured
        -- against, making the button appear visible but not register clicks.
        local EPSILON = 0.5

        if math.abs(self:getX() - desiredX) > EPSILON then
            self:setX(desiredX)
        end

        if math.abs(self:getY() - desiredY) > EPSILON then
            self:setY(desiredY)
        end

        if math.abs(self:getWidth() - desiredW) > EPSILON then
            self:setWidth(desiredW)
        end
    end

    -- Vanilla panels (e.g. the admin panel) can get added/re-added to the UI manager above us
    -- after we've already been added once, silently stealing clicks over our region even while
    -- we still render fine visually. Re-assert top z-order every frame so nothing can outrank us -
    -- but only while our own TabPanel modal isn't open (otherwise we'd punch through on top of it),
    -- and only while MainMenu isn't visible (e.g. the transparent reopen from the Tab Panel's
    -- "Characters" button to switch characters) - we still want the icon visible there, just not
    -- fighting MainMenu for z-order.
    local mainMenu = FrameworkZ.UI.MainMenu and FrameworkZ.UI.MainMenu.instance
    local mainMenuVisible = mainMenu ~= nil and mainMenu.isVisible and mainMenu:isVisible()

    if self.bringToTop and not FrameworkZ.UI.TabPanel.instance and not mainMenuVisible then
        self:bringToTop()
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
