FrameworkZ = FrameworkZ or {}
FrameworkZ.Overrides = FrameworkZ.Foundation:GetModule("Overrides")

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
FrameworkZ.Overrides.MainScreen_onConfirmQuitToDesktop = MainScreen.onConfirmQuitToDesktop

-- Prevent double-disconnect/quit sequences from racing (e.g., repeated clicks)
local isDisconnectInProgress = false

function FrameworkZ.Overrides.onMenuItemMouseDownMainMenu(item, x, y)
    local isoPlayer = getPlayer()

    if isDisconnectInProgress then
        print("[FZ] Disconnect already in progress; ignoring duplicate request")
        return
    end

    -- Handle EXIT (ESC menu) - save before quitting
    if item.internal == "EXIT" then
        if not isoPlayer then
            print("[FZ] No IsoPlayer found; falling back to vanilla exit")
            return FrameworkZ.Overrides.MainScreen_onMenuItemMouseDownMainMenu(item, x, y)
        end

        print("[FZ] Starting disconnect sequence...")
        isDisconnectInProgress = true
        
        -- Destroy saves data and waits for server confirmation via callback
        FrameworkZ.Players:Destroy(isoPlayer:getUsername(), function(success, message)
            if success then
                print("[FZ] Player data saved and destroyed successfully: " .. (message or ""))
            else
                print("[FZ] Warning during destroy: " .. (message or "Unknown error"))
            end
            
            -- After save is confirmed, teleport to limbo and disconnect
            FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Foundation.OnTeleportToLimbo", function(data, limboSuccess)
                if limboSuccess then
                    FrameworkZ.Foundation:TeleportToLimbo(isoPlayer)
                    print("[FZ] Player teleported to limbo. Disconnecting now...")
                else
                    print("[FZ] Warning: Failed to teleport player to limbo. Disconnecting anyways...")
                end

                FrameworkZ.Overrides.MainScreen_onMenuItemMouseDownMainMenu(item, x, y)
                isDisconnectInProgress = false
            end)
        end)
    else
        -- For QUIT_TO_DESKTOP and other items, let vanilla handle it (shows confirmation first)
        FrameworkZ.Overrides.MainScreen_onMenuItemMouseDownMainMenu(item, x, y)
    end
end

-- Override the confirmation handler to save AFTER user confirms
function FrameworkZ.Overrides.onConfirmQuitToDesktop(target, button)
    if isDisconnectInProgress then
        print("[FZ] Quit already in progress; ignoring duplicate request")
        return
    end

    if button.internal == "NO" then
        target.quitToDesktopDialog:destroy()
        target.quitToDesktopDialog = nil
        return
    end
    
    local isoPlayer = getPlayer()
    if not isoPlayer then
        print("[FZ] No IsoPlayer found; falling back to vanilla quit to desktop")
        return FrameworkZ.Overrides.MainScreen_onConfirmQuitToDesktop(target, button)
    end

    isDisconnectInProgress = true
    print("[FZ] User confirmed quit to desktop. Starting save sequence...")
    
    -- Save and destroy player data before quitting
    FrameworkZ.Players:Destroy(isoPlayer:getUsername(), function(success, message)
        if success then
            print("[FZ] Player data saved and destroyed successfully: " .. (message or ""))
        else
            print("[FZ] Warning during destroy: " .. (message or "Unknown error"))
        end
        
        -- After save is confirmed, teleport to limbo and quit
        FrameworkZ.Foundation:SendFire(isoPlayer, "FrameworkZ.Foundation.OnTeleportToLimbo", function(data, limboSuccess)
            if limboSuccess then
                FrameworkZ.Foundation:TeleportToLimbo(isoPlayer)
                print("[FZ] Player teleported to limbo. Quitting to desktop...")
            else
                print("[FZ] Warning: Failed to teleport player to limbo. Quitting anyway...")
            end

            -- Call the original confirmation handler to actually quit
            FrameworkZ.Overrides.MainScreen_onConfirmQuitToDesktop(target, button)
            isDisconnectInProgress = false
        end)
    end)
end

function FrameworkZ.Overrides:OnGameStart()
    MainScreen.onMenuItemMouseDownMainMenu = FrameworkZ.Overrides.onMenuItemMouseDownMainMenu
    MainScreen.onConfirmQuitToDesktop = FrameworkZ.Overrides.onConfirmQuitToDesktop

    LoadMainScreenPanelInt(true)
end
Events.OnGameStart.Remove(LoadMainScreenPanelIngame)
--Events.OnGameStart.Add(FrameworkZ.Overrides.OnGameStart)

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

function FrameworkZ.Overrides.GetTooltipTextureDrawSize(item, maxTextureSize)
    local drawWidth, drawHeight = 64, 64
    local texture = item and item:getTexture() or nil

    if not texture then
        return drawWidth, drawHeight
    end

    local sourceWidth, sourceHeight = nil, nil

    if texture.getWidthOrig and texture.getHeightOrig then
        sourceWidth = texture:getWidthOrig()
        sourceHeight = texture:getHeightOrig()
    elseif texture.getWidth and texture.getHeight then
        sourceWidth = texture:getWidth()
        sourceHeight = texture:getHeight()
    end

    if not sourceWidth or not sourceHeight or sourceWidth <= 0 or sourceHeight <= 0 then
        return drawWidth, drawHeight
    end

    local scale = math.min(maxTextureSize / sourceWidth, maxTextureSize / sourceHeight)
    drawWidth = math.max(1, math.floor((sourceWidth * scale) + 0.5))
    drawHeight = math.max(1, math.floor((sourceHeight * scale) + 0.5))

    return drawWidth, drawHeight
end

function FrameworkZ.Overrides.DoTooltip(objTooltip, item, panel)
    local itemData = item:getModData()["FZ_ITM"]

    objTooltip:render()

    local textureTop = 5
    local textureMaxSize = 72
    local textureWidth, textureHeight = FrameworkZ.Overrides.GetTooltipTextureDrawSize(item, textureMaxSize)
    local textureX = panel:getWidth() - textureWidth - 15
    local textureMinTooltipWidth = textureWidth + 190
    local font = objTooltip:getFont()
    local lineSpace = objTooltip:getLineSpacing()
    local yOffset = 5

    if itemData then
        local itemName = itemData.name
        local itemDescription = itemData.description

        objTooltip:DrawText(font, itemName, 5.0, yOffset, 1.0, 1.0, 0.8, 1.0)
        objTooltip:adjustWidth(5, itemName)
        yOffset = yOffset + lineSpace + 5

        local yTextureOffset = textureTop + textureHeight + 5
        
        -- Get item color and apply to texture using utility function
        local r, g, b, a = FrameworkZ.Utilities:GetItemColor(item)
        objTooltip:DrawTextureScaledColor(item:getTexture(), textureX, textureTop, textureWidth, textureHeight, r, g, b, 0.75)

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

        local yTextureOffset = textureTop + textureHeight + 5
        
        -- Get item color and apply to texture using utility function
        local r, g, b, a = FrameworkZ.Utilities:GetItemColor(item)
        objTooltip:DrawTextureScaledColor(item:getTexture(), textureX, textureTop, textureWidth, textureHeight, r, g, b, 0.75)

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

    local minTooltipWidth = math.max(256, textureMinTooltipWidth)
    if objTooltip:getWidth() < minTooltipWidth then
        objTooltip:setWidth(minTooltipWidth)
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

FrameworkZ.UI.RespawnMenu = FrameworkZ.Interfaces:New("RespawnMenu", FrameworkZ.UI)
FrameworkZ.Interfaces:Register(FrameworkZ.UI.RespawnMenu, "RespawnMenu")

function FrameworkZ.UI.RespawnMenu:new(deathScreenUI)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local panelW = 320
    local respawns = FrameworkZ.Config:GetOption("Respawns")
    local buttonHgt = 36
    local buttonGap = 10
    local titleH = 50
    local panelH = titleH + (#respawns * (buttonHgt + buttonGap)) + 20
    local x = (screenW - panelW) / 2
    local y = (screenH - panelH) / 2

    local o = ISPanel.new(self, x, y, panelW, panelH)
    o.deathScreenUI = deathScreenUI
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    return o
end

function FrameworkZ.UI.RespawnMenu:createChildren()
    local respawns = FrameworkZ.Config:GetOption("Respawns") if type(respawns) ~= "table" then respawns = {} end
    local buttonWid = self:getWidth() - 40
    local buttonHgt = 36
    local buttonGap = 10
    local titleH = 50
    local x = 20
    local y = titleH

    for _, location in ipairs(respawns) do
        local btn = ISButton:new(x, y, buttonWid, buttonHgt, location.name, self, FrameworkZ.UI.RespawnMenu.onSelectLocation)
        btn.location = location
        self:addChild(btn)
        y = y + buttonHgt + buttonGap
    end
end

function FrameworkZ.UI.RespawnMenu:render()
    ISPanel.render(self)
    self:drawText("Select Respawn Location", 20, 15, 1, 1, 0.8, 1, UIFont.Medium)
end

function FrameworkZ.UI.RespawnMenu.onSelectLocation(modal, button)
    local location = button.location
    modal:removeFromUIManager()
    FrameworkZ.Overrides.OnTrueRespawn(modal.deathScreenUI, location)
end

function FrameworkZ.UI.RespawnMenu.open(deathScreenUI)
    local respawns = FrameworkZ.Config:GetOption("Respawns")
    if #respawns == 1 then
        FrameworkZ.Overrides.OnTrueRespawn(deathScreenUI, respawns[1])
        return
    end
    local modal = FrameworkZ.UI.RespawnMenu:new(deathScreenUI)
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
end

function FrameworkZ.Overrides.OnTrueRespawn(deathScreenUI, selectedLocation)
    if MainScreen.instance:isReallyVisible() then return end

    -- Snapshot visual appearance, profession, skills and traits from the living player BEFORE respawn
    local isoPlayer = getPlayer()
    if isoPlayer then
        local humanVisual = isoPlayer:getHumanVisual()
        local desc = isoPlayer:getDescriptor()
        FrameworkZ.Overrides._respawnSnapshot = {
            isFemale         = desc:isFemale(),
            profession       = desc:getProfession(),
            hairModel        = humanVisual:getHairModel(),
            hairColor        = humanVisual:getHairColor(),
            bodyHairIndex    = humanVisual:getBodyHairIndex(),
            beardModel       = humanVisual:getBeardModel(),
            beardColor       = humanVisual:getBeardColor(),
            --skinTexture      = humanVisual:getSkinTextureName(),
            skinTextureIndex = humanVisual:getSkinTextureIndex(),
            skinColor        = humanVisual:getSkinColor(),
        }

        -- Snapshot body part wound states and all modifiable stats before the player is destroyed
        local _stats = isoPlayer:getStats()
        local _bd    = isoPlayer:getBodyDamage()
        FrameworkZ.Overrides._respawnSnapshot.statsSnap = {
            stress      = _stats:getStress(),
            panic       = _stats:getPanic(),
            boredom     = _stats:getBoredom(),
            drunkenness = _stats:getDrunkenness(),
            endurance   = _stats:getEndurance(),
        }
        FrameworkZ.Overrides._respawnSnapshot.bodyDamageSnap = {
            unhappiness  = _bd:getUnhappynessLevel(),
            foodSickness = _bd:getFoodSicknessLevel(),
            wetness      = _bd:getWetness(),
            temperature  = _bd:getTemperature(),
        }
        local _bParts = _bd:getBodyParts()
        local _bodyPartsSnap = {}
        for i = 1, _bParts:size() do
            local bP = _bParts:get(i - 1)
            _bodyPartsSnap[i] = {
                stiffness    = bP:getStiffness(),
                alcoholLevel = bP:getAlcoholLevel(),
                scratch      = bP:scratched(),
                deepWounded  = bP:deepWounded(),
                bitten       = bP:bitten(),
                haveBullet   = bP:haveBullet(),
                haveGlass    = bP:haveGlass(),
                isCut        = bP:isCut(),
                stitched     = bP:stitched(),
                bleeding     = bP:bleeding(),
            }
        end
        FrameworkZ.Overrides._respawnSnapshot.bodyParts = _bodyPartsSnap

        -- Pull skills, traits and full saveable data from the FrameworkZ character object
        local fzCharacter = FrameworkZ.Characters:GetCharacterByID(isoPlayer:getUsername())
        if fzCharacter then
            fzCharacter:Sync()  -- flush live isoPlayer state into the character object
            FrameworkZ.Overrides._respawnSnapshot.characterID   = fzCharacter:GetID()
            FrameworkZ.Overrides._respawnSnapshot.saveableData  = fzCharacter:GetSaveableData()
            FrameworkZ.Overrides._respawnSnapshot.skills        = fzCharacter.Skills
            FrameworkZ.Overrides._respawnSnapshot.traits        = fzCharacter.Traits
        end

        Events.OnCreatePlayer.Add(FrameworkZ.Overrides.OnRespawnCreatePlayer)
    end

	deathScreenUI:setVisible(false)
	CoopCharacterCreation.setVisibleAllUI(false)

	if UIManager.getSpeedControls() and not IsoPlayer.allPlayersDead() then
		setShowPausedMessage(false)
		UIManager.getSpeedControls():SetCurrentGameSpeed(0)
	end

    local respawnLocation = selectedLocation or FrameworkZ.Config:GetOption("Respawns")[1]
    local x = respawnLocation.x
    local y = respawnLocation.y
    local z = respawnLocation.z
    local cellX = math.floor(x / 300)
    local cellY = math.floor(y / 300)
    local relativeX = x % 300
    local relativeY = y % 300

    getWorld():setLuaSpawnCellX(cellX)
    getWorld():setLuaSpawnCellY(cellY)
    getWorld():setLuaPosX(relativeX)
    getWorld():setLuaPosY(relativeY)
    getWorld():setLuaPosZ(z)

    local snap = FrameworkZ.Overrides._respawnSnapshot
    local descriptor = SurvivorFactory.CreateSurvivor()
    if snap then
        descriptor:setFemale(snap.isFemale)
        descriptor:setProfession(snap.profession)
        local humanVisual = descriptor:getHumanVisual()
        humanVisual:setHairModel(snap.hairModel)
        humanVisual:setHairColor(snap.hairColor)
        humanVisual:setBodyHairIndex(snap.bodyHairIndex)
        humanVisual:setBeardModel(snap.beardModel)
        humanVisual:setBeardColor(snap.beardColor)
        if snap.skinTexture and snap.skinTexture ~= "" then humanVisual:setSkinTextureName(snap.skinTexture) end
        humanVisual:setSkinTextureIndex(snap.skinTextureIndex)
        humanVisual:setSkinColor(snap.skinColor)
    end
	getWorld():setLuaPlayerDesc(descriptor)

    if UIManager.getSpeedControls() and not IsoPlayer.allPlayersDead() then
		setShowPausedMessage(true)
		UIManager.getSpeedControls():SetCurrentGameSpeed(1)
	end

	if ISPostDeathUI.instance[deathScreenUI.playerIndex] then
		ISPostDeathUI.instance[deathScreenUI.playerIndex]:removeFromUIManager()
		ISPostDeathUI.instance[deathScreenUI.playerIndex] = nil
	end

	setPlayerMouse(nil)
	CoopCharacterCreation.setVisibleAllUI(true)
end

-- Called once by Events.OnCreatePlayer after a respawn to restore progression.
function FrameworkZ.Overrides.OnRespawnCreatePlayer(num, player)
    if player ~= getPlayer() then return end
    Events.OnCreatePlayer.Remove(FrameworkZ.Overrides.OnRespawnCreatePlayer)

    local snap = FrameworkZ.Overrides._respawnSnapshot
    if not snap then return end
    FrameworkZ.Overrides._respawnSnapshot = nil

    -- Re-apply profession XP map
    if snap.profession then
        player:getDescriptor():setProfession(snap.profession)
        player:getDescriptor():getXPBoostMap():clear()
    end

    -- Restore traits
    if snap.traits then
        local existingTraits = player:getTraits()
        existingTraits:clear()
        for _, traitName in ipairs(snap.traits) do
            existingTraits:add(traitName)
        end
    end

    -- Restore skills / XP levels
    if snap.skills then
        local xpSystem = player:getXp()
        for _, xpData in pairs(snap.skills) do
            if type(xpData) == "table" and xpData.skill then
                local perk = xpData.skill
                local experience      = tonumber(xpData.experience)      or 0
                local experienceBoost = tonumber(xpData.experienceBoost) or 0
                xpSystem:setXPToLevel(perk, 0)
                player:setPerkLevelDebug(perk, 0)
                if experience > 0 then
                    xpSystem:AddXP(perk, experience, false, false, true)
                end
                if experienceBoost > 0 then
                    xpSystem:setPerkBoost(perk, experienceBoost)
                end
            end
        end
    end

    -- Hospital treatment: dress in gown + slippers, heal all wounds, reset all stats.
    player:clearWornItems()
    player:getInventory():clear()

    local gown = player:getInventory():AddItem("Base.HospitalGown")
    player:setWornItem(gown:getBodyLocation(), gown)

    local slippers = player:getInventory():AddItem("Base.Shoes_Slippers")
    local whiteColor = Color.new(1, 1, 1, 1)
    slippers:setColor(whiteColor)
    slippers:getVisual():setTint(ImmutableColor.new(whiteColor))
    slippers:setCustomColor(true)
    player:setWornItem(slippers:getBodyLocation(), slippers)

    -- Restore body part stiffness; apply bandages only to pre-death wounds (bullet wounds left for a doctor).
    player:setHealth(1.0)
    local bodyParts = player:getBodyDamage():getBodyParts()
    for i = 1, bodyParts:size() do
        local bP = bodyParts:get(i - 1)
        local bPSnap = snap.bodyParts and snap.bodyParts[i]
        -- Restore stiffness carried over from before death
        if bPSnap and bPSnap.stiffness and bPSnap.stiffness > 0 then
            bP:setStiffness(bPSnap.stiffness)
        end
        -- Restore alcohol disinfection level on wounds
        if bPSnap and bPSnap.alcoholLevel and bPSnap.alcoholLevel > 0 then
            bP:setAlcoholLevel(bPSnap.alcoholLevel)
        end
        -- Bandage parts that had wounds: scratch, cut, deep wound, bite, glass, or active bleeding.
        -- Bullet wounds are intentionally left unbandaged so a doctor can remove the bullet first.
        local hadWound = bPSnap and (bPSnap.scratch or bPSnap.deepWounded or bPSnap.bitten or
                                     bPSnap.haveGlass or bPSnap.isCut or bPSnap.bleeding)
        if hadWound then
            bP:setBandaged(true, 5, false, "Base.Bandage")
        end
    end

    -- Restore pre-death stats from snapshot; pain is the sole exception - always reset to safe baseline.
    local stats = player:getStats()
    local ss = snap.statsSnap
    stats:setStress(ss and ss.stress or 0)
    stats:setPanic(ss and ss.panic or 0)
    stats:setBoredom(ss and ss.boredom or 0)
    stats:setDrunkenness(ss and ss.drunkenness or 0)
    stats:setEndurance(ss and ss.endurance or 1.0)
    stats:setPain(0) -- always reset: high pain causes instant death

    local bodyDamage = player:getBodyDamage()
    local bds = snap.bodyDamageSnap
    bodyDamage:setUnhappynessLevel(bds and bds.unhappiness or 0)
    bodyDamage:setFoodSicknessLevel(bds and bds.foodSickness or 0)
    bodyDamage:setWetness(bds and bds.wetness or 0)
    bodyDamage:setTemperature(bds and bds.temperature or 37.0)

    -- Re-register the player and character into FrameworkZ lists so that
    -- the normal disconnect flow (Players:Destroy → callback) works correctly.
    if snap.characterID then
        local fzPlayer = FrameworkZ.Players:Initialize(player)
        if fzPlayer then
            local username = player:getUsername()

            -- Rebuild a character object from the snapshotted saveable data so that
            -- RP fields (name, faction, description, etc.) survive a disconnect.
            local charObject = setmetatable({
                ID        = snap.characterID,
                Player    = fzPlayer,
                IsoPlayer = player,
                Username  = username,
                Inventory = FrameworkZ.Inventories:New(username),
                CustomData = {},
                Recognizes = {},
            }, FrameworkZ.Characters.MetaObject)

            if snap.saveableData then
                for k, v in pairs(snap.saveableData) do
                    if charObject[k] == nil then charObject[k] = v end
                end
                fzPlayer.Characters = { [snap.characterID] = snap.saveableData }
            end

            FrameworkZ.Characters:AddToList(username, charObject)
            fzPlayer:SetCharacter(charObject)
            FrameworkZ.Players:CreateCharacterSaveInterval()
            FrameworkZ.Players:ResetCharacterSaveInterval()
            print("[FZ] Player and character re-registered into FrameworkZ lists after respawn.")
        end
    end
end

ISPostDeathUI.createChildren = function(self)
	local buttonWid = 250
	local buttonHgt = 40
	local buttonGapY = 12
	local buttonX = 0
	local buttonY = 0
	local totalHgt = (buttonHgt * 2) + (buttonGapY * 1)

	self:setWidth(buttonWid)
	self:setHeight(totalHgt)

	self:setX(self.screenX + (self.screenWidth - buttonWid) / 2)
	self:setY(self.screenHeight - 40 - totalHgt)

    --[[
	local button = ISButton:new(buttonX - 50, buttonY - (buttonHgt + buttonGapY), buttonWid + 100, buttonHgt, "Don't exit without respawning!")
	self:configButton(button)
	self:addChild(button)
    --]]

    local buttonExit = ISButton:new(buttonX, buttonY + 999999, buttonWid, buttonHgt, "", self, FrameworkZ.UI.RespawnMenu.open)
	self:configButton(buttonExit)
	self:addChild(buttonExit)
	self.buttonExit = buttonExit

	local respawns = FrameworkZ.Config:GetOption("Respawns")
	local respawnLabel = (#respawns == 1) and ("Respawn at " .. respawns[1].name) or "Select Respawn Location"
	local buttonRespawn = ISButton:new(buttonX, buttonY, buttonWid, buttonHgt, respawnLabel, self, FrameworkZ.UI.RespawnMenu.open)
	self:configButton(buttonRespawn)
	self:addChild(buttonRespawn)
	self.buttonRespawn = buttonRespawn

	buttonY = buttonY + buttonHgt + buttonGapY

	local buttonRevive = ISButton:new(buttonX, buttonY, buttonWid, buttonHgt, "Accept Revive", self, FrameworkZ.UI.RespawnMenu.revive)
	self:configButton(buttonRevive)
    buttonRevive:setEnable(false)
	self:addChild(buttonRevive)
	self.buttonRevive = buttonRevive

    --[[
	button = ISButton:new(buttonX, buttonY + 99999, buttonWid, buttonHgt, getText("IGUI_PostDeath_Respawn"), self, self.onRespawn)
	self:configButton(button)
	self:addChild(button)
	self.buttonRespawn = button
	buttonY = buttonY + buttonHgt + buttonGapY
    --]]

	local buttonQuit = ISButton:new(buttonX, buttonY + 999999, buttonWid, buttonHgt, getText("IGUI_PostDeath_Quit"), self, self.onQuitToDesktop)
	self:configButton(buttonQuit)
	self:addChild(buttonQuit)
	self.buttonQuit = buttonQuit
end

Events.OnKeyPressed.Remove(ToggleEscapeMenu)
FrameworkZ.Overrides.ToggleEscapeMenu_old = ToggleEscapeMenu

function FrameworkZ.Overrides.ToggleEscapeMenu(key)
	local mainMenuKey = getCore():getKey("Main Menu")

    if ((key == mainMenuKey) or (mainMenuKey == 0 and key == Keyboard.KEY_ESCAPE)) and FrameworkZ.UI.MainMenu.instance then
        return
    end

    FrameworkZ.Overrides.ToggleEscapeMenu_old(key)
end
Events.OnKeyPressed.Add(FrameworkZ.Overrides.ToggleEscapeMenu)

-- Global monkey-patch for ISComboBoxPopup to support dropdown theme colors
-- This ensures all combo boxes render dropdown items with proper theme styling
local _originalISComboBoxPopupDoDrawItem = ISComboBoxPopup.doDrawItem
function ISComboBoxPopup:doDrawItem(y, item, alt)
    if self.parentCombo:hasFilterText() then
        if not item.text:lower():contains(self.parentCombo:getFilterText():lower()) then
            return y
        end
    end
    if item.height == 0 then
        item.height = self.itemheight
    end
    local highlight = (self:isMouseOver() and not self:isMouseOverScrollBar()) and self.mouseoverselected or self.selected
    if self.parentCombo.joypadFocused then
        highlight = self.selected
    end
    if highlight == item.index then
        -- Use dropdown theme's hover color if available
        local selectColor = nil
        if self.parentCombo._comboDropdownTheme and self.parentCombo._comboDropdownTheme.OptionHoverColor then
            selectColor = self.parentCombo._comboDropdownTheme.OptionHoverColor
        else
            selectColor = self.parentCombo.backgroundColorMouseOver
        end
        self:drawRect(0, (y), self:getWidth(), item.height-1, selectColor.a, selectColor.r, selectColor.g, selectColor.b)

        if self:isMouseOver() and not self:isMouseOverScrollBar() then
            local textWid = getTextManager():MeasureStringX(self.font, item.text)
            local scrollBarWid = self:isVScrollBarVisible() and 13 or 0
            if 10 + textWid > self.width - scrollBarWid then
                self.tooWide = item
                self.tooWideY = y
            end
        end
        -- Use dropdown theme's hover text color if available
        local textColor = nil
        if self.parentCombo._comboDropdownTheme and self.parentCombo._comboDropdownTheme.OptionHoverTextColor then
            textColor = self.parentCombo._comboDropdownTheme.OptionHoverTextColor
        else
            textColor = self.parentCombo.textColor
        end
        local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
        self:drawText(item.text, 10, y + itemPadY, textColor.r, textColor.g, textColor.b, textColor.a, self.font)
    else
        local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2
        self:drawText(item.text, 10, y + itemPadY, self.parentCombo.textColor.r, self.parentCombo.textColor.g, self.parentCombo.textColor.b, self.parentCombo.textColor.a, self.font)
    end
    y = y + item.height
    return y
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Overrides)
