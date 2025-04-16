FrameworkZ = FrameworkZ or {}
FrameworkZ.Overrides = FrameworkZ.Foundation:GetModule("Overrides")

require "ISUI/ISToolTipInv"
require "OptionScreens/ConnectToServer"
require "OptionScreens/MainScreen"

function FrameworkZ.Overrides.onChatWindowInit()
    ISChat.instance:setVisible(false)
end
Events.OnChatWindowInit.Add(FrameworkZ.Overrides.onChatWindowInit)

ConnectToServer.OnConnected = function(self)
    if not SystemDisabler.getAllowDebugConnections() and getDebug() and not isAdmin() and not isCoopHost() and not SystemDisabler.getOverrideServerConnectDebugCheck() then
        forceDisconnect()
        return
    end
    connectionManagerLog("connect-state-finish", "lua-connected");
    self.connecting = false
    self:setVisible(false)
    if not checkSavePlayerExists() then
        if not getWorld():getMap() then
            getWorld():setMap("Muldraugh, KY")
        end

        if MainScreen.instance.createWorld then
            createWorld(getWorld():getWorld())
        end

        GameWindow.doRenderEvent(false)
        forceChangeState(LoadingQueueState.new())
    else
        GameWindow.doRenderEvent(false)
        forceChangeState(LoadingQueueState.new())
    end
end

FrameworkZ.Overrides.MainScreen_onMenuItemMouseDownMainMenu = MainScreen.onMenuItemMouseDownMainMenu
MainScreen.onMenuItemMouseDownMainMenu = function(item, x, y)
    if item.internal == "EXIT" then
        FrameworkZ.Players:Destroy(getPlayer():getUsername())
    end

    if item.internal == "QUIT_TO_DESKTOP" then
        FrameworkZ.Players:Destroy(getPlayer():getUsername())
    end

    FrameworkZ.Overrides.MainScreen_onMenuItemMouseDownMainMenu(item, x, y)
end

FrameworkZ.Overrides.ISToolTipInv_render = ISToolTipInv.render

function FrameworkZ.Overrides.WordWrapText(text)
    local maxLineLength = 28
    local lines = {}
    local line = ""
    local lineLength = 0
    local words = {}

    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    for i = 1, #words do
        local word = words[i]
        local wordLength = string.len(word)

        if lineLength + wordLength <= maxLineLength then
            line = line .. " " .. word
            lineLength = lineLength + wordLength
        else
            table.insert(lines, line)
            line = word
            lineLength = wordLength
        end
    end

    table.insert(lines, line)

    return lines
end

function FrameworkZ.Overrides.DoTooltip(objTooltip, item, panel)
    local itemData = item:getModData()["FZ_ITM"]

    objTooltip:render()

    local textureWidth, textureHeight = 64, 64
    local font = objTooltip:getFont()
    local lineSpace = objTooltip:getLineSpacing()
    local yOffset = 5

    if itemData then
        local itemName = itemData.name
        local itemDescription = itemData.description

        objTooltip:DrawText(font, itemName, 5.0, yOffset, 1.0, 1.0, 0.8, 1.0)
        objTooltip:adjustWidth(5, itemName)
        yOffset = yOffset + lineSpace + 5

        local yTextureOffset = textureHeight + 10
        objTooltip:DrawTextureScaled(item:getTexture(), panel:getWidth() - textureWidth - 15, 5, textureWidth, textureHeight, 0.75)

        local description = FrameworkZ.Overrides.WordWrapText(itemDescription)

        for k, v in pairs(description) do
            objTooltip:DrawText(font, v, 5, yOffset, 1, 1, 0.8, 1)
            objTooltip:adjustWidth(5, v)
            yOffset = yOffset + lineSpace + 2.5
        end

        if yTextureOffset > yOffset then
            yOffset = yTextureOffset
        end

        panel:drawRect(0, yOffset, panel:getWidth(), 1, panel.borderColor.a, panel.borderColor.r, panel.borderColor.g, panel.borderColor.b)

        yOffset = yOffset + 2.5
    else
        objTooltip:DrawText(font, item:getDisplayName(), 5.0, yOffset, 1.0, 1.0, 0.8, 1.0)
        objTooltip:adjustWidth(5, item:getDisplayName())
        yOffset = yOffset + lineSpace + 5

        local yTextureOffset = textureHeight + 10
        objTooltip:DrawTextureScaled(item:getTexture(), panel:getWidth() - textureWidth - 15, 5, textureWidth, textureHeight, 0.75)

        --[[
        local description = FrameworkZ.Overrides.WordWrapText(item:getDescription())

        for k, v in pairs(description) do
            objTooltip:DrawText(font, v, 5, yOffset, 1, 1, 0.8, 1)
            objTooltip:adjustWidth(5, v)
            yOffset = yOffset + lineSpace + 2.5
        end
        --]]

        if yTextureOffset > yOffset then
            yOffset = yTextureOffset
        end

        panel:drawRect(0, yOffset, panel:getWidth(), 1, panel.borderColor.a, panel.borderColor.r, panel.borderColor.g, panel.borderColor.b)

        yOffset = yOffset + 2.5
    end

    local layoutTooltip = objTooltip:beginLayout()
    layoutTooltip:setMinLabelWidth(128)
    local layout = nil

    if itemData then
        local itemInstance = FrameworkZ.Items:GetInstance(itemData.instanceID)
        local itemCustomFields = itemData.customFields

        for k, v in pairs(itemCustomFields) do
            layout = layoutTooltip:addItem()
            layout:setLabel(k .. ":", 1, 1, 0.8, 1)

            if type(v) == "boolean" then
                if v then
                    layout:setValue("Yes", 1, 1, 1, 1)
                else
                    layout:setValue("No", 1, 1, 1, 1)
                end
            else
                if v.get then
                    local values = v.get(itemInstance)

                    if type(values) == "table" then
                        local displayString = ""

                        for _, v2 in pairs(values) do
                            displayString = displayString .. tostring(v2) .. "\n"
                        end

                        layout:setValue(displayString, 1, 1, 1, 1)
                    else
                        layout:setValue(tostring(v.get(itemInstance)), 1, 1, 1, 1)
                    end
                else
                    layout:setValue(v, 1, 1, 1, 1)
                end
            end
        end
    end

    local weightEquipped = item:getCleanString(item:getEquippedWeight())
    local weightUnequipped = item:getUnequippedWeight()
    layout = layoutTooltip:addItem()
    layout:setLabel("Weight (Unequipped):", 1, 1, 0.8, 1)

    if weightUnequipped > 0 and weightUnequipped < 0.01 then
        weightUnequipped = "<0.01"
    else
        weightUnequipped = item:getCleanString(weightUnequipped)
    end

    if not item:isEquipped() then
        layout:setValue("*" .. tostring(weightUnequipped) .. "*", 1, 1, 1, 1)
    else
        layout:setValue(tostring(weightUnequipped), 1, 1, 1, 1)
    end

    layout = layoutTooltip:addItem()
    layout:setLabel("Weight (Equipped):", 1, 1, 0.8, 1)

    if item:isEquipped() then
        layout:setValue("*" .. tostring(weightEquipped) .. "*", 1, 1, 1, 1)
    else
        layout:setValue(tostring(weightEquipped), 1, 1, 1, 1)
    end

    --[[
    if not item:IsWeapon() and not item:IsClothing() and not item:IsDrainable() and not string.match(item:getFullType(), "Walkie") then
        local unequippedWeight = item:getUnequippedWeight()

        if unequippedWeight > 0 and unequippedWeight < 0.01 then
            unequippedWeight = 0.01
        end

        layout:setValueRightNoPlus(unequippedWeight)
    elseif item:isEquipped() then
        local equippedWeight = item:getCleanString(item:getEquippedWeight())

        layout:setValue(equippedWeight .. "    (" .. item:getCleanString(item:getUnequippedWeight()) .. " " .. getText("Tooltip_item_Unequipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    elseif item:getAttachedSlot() > -1 then
        local hotbarEquippedWeight = item:getCleanString(item:getHotbarEquippedWeight())

        layout:setValue(hotbarEquippedWeight .. "    (" .. item:getCleanString(item:getUnequippedWeight()) .. " " .. getText("Tooltip_item_Unequipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    else
        local unequippedWeight = item:getCleanString(item:getUnequippedWeight())

        layout:setValue(unequippedWeight .. "    (" .. item:getCleanString(item:getEquippedWeight()) .. " " .. getText("Tooltip_item_Equipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    end
    --]]

    if item:getTooltip() ~= nil then
        layout = layoutTooltip:addItem()
        layout:setLabel(getText(item:getTooltip()), 1, 1, 0.8, 1)
    end

    yOffset = layoutTooltip:render(5, yOffset, objTooltip)
    objTooltip:endLayout(layoutTooltip)
    yOffset = yOffset + 5
    objTooltip:setHeight(yOffset)

    if objTooltip:getWidth() < 256 then
        objTooltip:setWidth(256)
    end
end

ISToolTipInv.render = function(self)
    local mx = getMouseX() + 24
    local my = getMouseY() + 24

    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    self.tooltip:setX(mx + 11);
    self.tooltip:setY(my);

    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)

    if self.item ~= nil and self.tooltip ~= nil then
        FrameworkZ.Overrides.DoTooltip(self.tooltip, self.item, self);
    else
        self.item:DoTooltip(self.tooltip);
    end

    self.tooltip:setMeasureOnly(false)

    -- clampy x, y

    local myCore = getCore();
    local maxX = myCore:getScreenWidth();
    local maxY = myCore:getScreenHeight();

    local tw = self.tooltip:getWidth();
    local th = self.tooltip:getHeight();

    self.tooltip:setX(math.max(0, math.min(mx + 11, maxX - tw - 1)));

    if not self.followMouse and self.anchorBottomLeft then
        self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)));
    else
        self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)));
    end

    self:setX(self.tooltip:getX() - 11);
    self:setY(self.tooltip:getY());
    self:setWidth(tw + 11);
    self:setHeight(th);

    if self.followMouse then
        self:adjustPositionToAvoidOverlap({
            x = mx - 24 * 2,
            y = my - 24 * 2,
            width = 24 * 2,
            height = 24 * 2
        })
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if self.item ~= nil and self.tooltip ~= nil then
        FrameworkZ.Overrides.DoTooltip(self.tooltip, self.item, self);
    else
        self.item:DoTooltip(self.tooltip);
    end
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Overrides)
