FrameworkZ.UI.LoadCharacterMenu = FrameworkZ.UI.LoadCharacterMenu or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.LoadCharacterMenu, "LoadCharacterMenu")

function FrameworkZ.UI.LoadCharacterMenu:initialise()
    ISPanel.initialise(self)

    local isoPlayer = self.player.isoPlayer

    self.currentIndex = 1
    
    -- Build initial character arrays
    self:refreshCharacterList(false)

    print("[LoadCharacterMenu] Found characters: " .. tostring(#self.characters))
    for i,id in ipairs(self.characterIDs) do
        print("  ["..i.."] id="..tostring(id))
    end

    local transitionButtonHeight = self.height / 2
    local transitionButtonY = self.height / 2 - transitionButtonHeight / 2

    local widthLeft = 150
    local heightLeft = 300
    local xLeft = self.width / 8 - widthLeft / 8
    local yLeft = self.height / 2 - heightLeft / 2

    local widthSelected = 200
    local heightSelected = 400
    local xSelected = self.width / 2 - widthSelected / 2
    local ySelected = self.height / 2 - heightSelected / 2

    local widthRight = 150
    local heightRight = 300
    local xRight = self.width - (self.width / 8 + widthLeft)
    local yRight = self.height / 2 - heightLeft / 2

    -- Create a default survivor - gender will be updated when character is set
    self.survivor = SurvivorFactory:CreateSurvivor(SurvivorType.Neutral, false)

    self.nextButton = FrameworkZ.Interfaces:CreateButton({
        x = self.width - 30,
        y = transitionButtonY,
        width = 30,
        height = transitionButtonHeight,
        title = ">",
        target = self,
        onClick = FrameworkZ.UI.LoadCharacterMenu.onNext,
        font = FZ_FONT_LARGE,
        parent = self
    })
    self.nextButton.internal = "NEXT"

    self.previousButton = FrameworkZ.Interfaces:CreateButton({
        x = 0,
        y = transitionButtonY,
        width = 30,
        height = transitionButtonHeight,
        title = "<",
        target = self,
        onClick = FrameworkZ.UI.LoadCharacterMenu.onPrevious,
        font = FZ_FONT_LARGE,
        parent = self
    })
    self.previousButton.internal = "PREVIOUS"

    self.leftCharacter = FrameworkZ.UI.CharacterView:new(xLeft, yLeft, widthLeft, heightLeft, isoPlayer, self.characters[1], "", "", IsoDirections.SW)
    self.leftCharacter:setVisible(false)
    self.leftCharacter:initialise()
    self:addChild(self.leftCharacter)

    self.selectedCharacter = FrameworkZ.UI.CharacterView:new(xSelected, ySelected, widthSelected, heightSelected, isoPlayer, self.characters[1], "", "", IsoDirections.S)
    self.selectedCharacter:setVisible(false)
    self.selectedCharacter:initialise()
    self:addChild(self.selectedCharacter)

    self.rightCharacter = FrameworkZ.UI.CharacterView:new(xRight, yRight, widthRight, heightRight, isoPlayer, self.characters[1], "", "", IsoDirections.SE)
    self.rightCharacter:setVisible(false)
    self.rightCharacter:initialise()
    self:addChild(self.rightCharacter)

    local prevSel = self.player.previousCharacter
    -- Map previous selection: it may be an ID or an index
    if not prevSel then
        if #self.characters == 1 then
            self.selectedCharacter:setCharacter(self.characters[1])
            self.selectedCharacter:reinitialize(self.characters[1])
            self.selectedCharacter:setVisible(true)
        elseif #self.characters >= 2 then
            self.selectedCharacter:setCharacter(self.characters[1])
            self.selectedCharacter:reinitialize(self.characters[1])

            self.rightCharacter:setCharacter(self.characters[2])
            self.rightCharacter:reinitialize(self.characters[2])

            self.selectedCharacter:setVisible(true)
            self.rightCharacter:setVisible(true)
        end
    else
        -- Try to find by ID first
        local foundIndex = nil
        for i, id in ipairs(self.characterIDs) do
            if tostring(id) == tostring(prevSel) then foundIndex = i; break end
        end
        -- Fallback: if prevSel is a number inside range, treat as index
        if not foundIndex and type(prevSel) == "number" and prevSel >= 1 and prevSel <= #self.characters then
            foundIndex = prevSel
        end
        if foundIndex then self.currentIndex = foundIndex end

        if #self.characters == 1 then
            self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
            self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
            self.selectedCharacter:setVisible(true)
            self.leftCharacter:setVisible(false)
            self.rightCharacter:setVisible(false)
        elseif #self.characters >= 2 then
            if self.currentIndex == 1 then
                self.leftCharacter:setVisible(false)
                self.rightCharacter:setVisible(true)
            elseif self.currentIndex == #self.characters then
                self.leftCharacter:setVisible(true)
                self.rightCharacter:setVisible(false)
            else
                self.leftCharacter:setVisible(true)
                self.rightCharacter:setVisible(true)
            end
        
            self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
            self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
            self.selectedCharacter:setVisible(true)
            
            if self.leftCharacter:isVisible() then
                self.leftCharacter:setCharacter(self.characters[self.currentIndex - 1])
                self.leftCharacter:reinitialize(self.characters[self.currentIndex - 1])
            end
            if self.rightCharacter:isVisible() then
                self.rightCharacter:setCharacter(self.characters[self.currentIndex + 1])
                self.rightCharacter:reinitialize(self.characters[self.currentIndex + 1])
            end
        end
    end

    --[[
    self.characterPreview = FrameworkZ.UI.CharacterPreview:new(self.width / 2 - characterPreviewWidth / 2, self.height / 2 - characterPreviewHeight / 2, characterPreviewWidth, characterPreviewHeight, "EventIdle")
    self.characterPreview:initialise()
    self.characterPreview:removeChild(self.characterPreview.animCombo)
    self.characterPreview:setCharacter(getPlayer())
    self.characterPreview:setSurvivorDesc(self.survivor)
    self:addChild(self.characterPreview)
    --]]
end

-- Rebuild character arrays from the player object; optionally keep current selection by ID
function FrameworkZ.UI.LoadCharacterMenu:refreshCharacterList(keepSelection)
    if not self.player or not self.player.GetCharacters then return end
    local allCharacters = self.player:GetCharacters() or {}

    local prevSelectedID = keepSelection and (self.characterIDs and self.characterIDs[self.currentIndex]) or nil

    self.characters = {}
    self.characterIDs = {}
    local ids = {}
    for id, _ in pairs(allCharacters) do table.insert(ids, id) end
    table.sort(ids, function(a,b)
        local na, nb = tonumber(a), tonumber(b)
        if na and nb then return na < nb end
        if na and not nb then return true end
        if nb and not na then return false end
        return tostring(a) < tostring(b)
    end)
    for _, id in ipairs(ids) do
        table.insert(self.characterIDs, id)
        table.insert(self.characters, allCharacters[id])
    end

    -- Track count/signature to detect changes during prerender
    self._lastCharCount = #self.characters
    self._lastCharSig = table.concat(self.characterIDs, "|")

    -- Preserve selection if requested
    if keepSelection and prevSelectedID then
        local foundIndex
        for i, id in ipairs(self.characterIDs) do
            if tostring(id) == tostring(prevSelectedID) then foundIndex = i; break end
        end
        if foundIndex then self.currentIndex = foundIndex end
    end
end

-- Detect character list changes while menu is open and refresh previews
function FrameworkZ.UI.LoadCharacterMenu:prerender()
    ISPanel.prerender(self)
    if not self.player or not self.player.GetCharacters then return end
    local chars = self.player:GetCharacters() or {}
    local count = 0; for _ in pairs(chars) do count = count + 1 end
    if (self._lastCharCount ~= count) then
        local oldSelectedID = self.characterIDs and self.characterIDs[self.currentIndex]
        self:refreshCharacterList(true)
        -- After refresh, update visible previews
        if #self.characters >= 1 then
            self.selectedCharacter:setCharacter(self.characters[self.currentIndex])
            self.selectedCharacter:reinitialize(self.characters[self.currentIndex])
            self.selectedCharacter:setVisible(true)
        end
        if self.currentIndex > 1 and self.characters[self.currentIndex - 1] then
            self.leftCharacter:setCharacter(self.characters[self.currentIndex - 1])
            self.leftCharacter:reinitialize(self.characters[self.currentIndex - 1])
            self.leftCharacter:setVisible(true)
        else
            self.leftCharacter:setVisible(false)
        end
        if self.currentIndex < #self.characters and self.characters[self.currentIndex + 1] then
            self.rightCharacter:setCharacter(self.characters[self.currentIndex + 1])
            self.rightCharacter:reinitialize(self.characters[self.currentIndex + 1])
            self.rightCharacter:setVisible(true)
        else
            self.rightCharacter:setVisible(false)
        end
    end
end

function FrameworkZ.UI.LoadCharacterMenu:onNext()
    if #self.characters < 2 then return end
    self.currentIndex = math.min(self.currentIndex + 1, #self.characters)
    self:updateCharacterPreview()
end

function FrameworkZ.UI.LoadCharacterMenu:onPrevious()
    if #self.characters < 2 then return end
    self.currentIndex = math.max(self.currentIndex - 1, 1)
    self:updateCharacterPreview()
end

function FrameworkZ.UI.LoadCharacterMenu:updateCharacterPreview()
    if #self.characters == 0 then
        self.selectedCharacter:setVisible(false)
        self.leftCharacter:setVisible(false)
        self.rightCharacter:setVisible(false)
        return
    end

    local current = self.characters[self.currentIndex] or self.characters[1]
    self.currentIndex = self.currentIndex or 1
    self.selectedCharacter:setCharacter(current)
    self.selectedCharacter:reinitialize(current)
    self.selectedCharacter:setVisible(true)

    if self.currentIndex > 1 then
        local leftChar = self.characters[self.currentIndex - 1]
        if leftChar then
            self.leftCharacter:setCharacter(leftChar)
            self.leftCharacter:reinitialize(leftChar)
        end
        self.leftCharacter:setVisible(true)
    else
        self.leftCharacter:setVisible(false)
    end

    if self.currentIndex < #self.characters then
        local rightChar = self.characters[self.currentIndex + 1]
        if rightChar then
            self.rightCharacter:setCharacter(rightChar)
            self.rightCharacter:reinitialize(rightChar)
        end
        self.rightCharacter:setVisible(true)
    else
        self.rightCharacter:setVisible(false)
    end
end

function FrameworkZ.UI.LoadCharacterMenu:render()
    ISPanel.prerender(self)

    -- Render the character preview and any other UI elements here
end

function FrameworkZ.UI.LoadCharacterMenu:new(x, y, width, height, player)
    local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.moveWithMouse = false
	o.player = player
	FrameworkZ.UI.LoadCharacterMenu.instance = o

	return o
end

return FrameworkZ.UI.LoadCharacterMenu

