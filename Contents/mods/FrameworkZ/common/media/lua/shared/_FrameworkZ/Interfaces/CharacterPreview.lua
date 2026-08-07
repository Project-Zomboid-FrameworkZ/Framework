FrameworkZ.UI.CharacterPreview = FrameworkZ.UI.CharacterPreview or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.CharacterPreview, "CharacterPreview")

local function mapEventToState(eventName)
	if eventName == "EventWalk" then return "walk" end
	if eventName == "EventRun" then return "run" end
	if eventName == "EventIdle" then return "idle" end
	return nil
end

function FrameworkZ.UI.CharacterPreview:applyCurrentAnimation()
	if not self.avatarPanel then return end
	local eventName = self.currentAnimationEvent or "EventWalk"
	self.avatarPanel:reportEvent(eventName)

	local mappedState = mapEventToState(eventName)
	if mappedState and self.avatarPanel.setState then
		self.avatarPanel:setState(mappedState)
	end
end

function FrameworkZ.UI.CharacterPreview:initialise()
    ISPanel.initialise(self)

    self.avatarBackgroundTexture = getTexture("media/ui/avatarBackground.png")

	local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
	local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
	local comboHgt = FONT_HGT_SMALL + 3 * 2

	self.avatarPanel = ISUI3DModel:new(0, 0, self.width, self.height - comboHgt)
	self.avatarPanel.backgroundColor = {r=0, g=0, b=0, a=0.8}
	self.avatarPanel.borderColor = {r=1, g=1, b=1, a=0.2}
	self:addChild(self.avatarPanel)
	self.avatarPanel:setState("idle")
	self.avatarPanel:setDirection(self.direction)
	self.avatarPanel:setIsometric(false)
	self.avatarPanel:setDoRandomExtAnimations(true)
	self.currentAnimationEvent = self.defaultAnimation and self.defaultAnimation or "EventWalk"
	self.pendingAnimReapplyFrames = 0
	self:applyCurrentAnimation()

	self.turnLeftButton = FrameworkZ.Interfaces:CreateButton({
		x = self.avatarPanel.x,
		y = self.avatarPanel:getBottom()-15,
		width = 15,
		height = 15,
		title = "",
		target = self,
		onClick = self.onTurnChar,
		parent = self
	})
	self.turnLeftButton.internal = "TURNCHARACTERLEFT"
	self.turnLeftButton:setImage(getTexture("media/ui/ArrowLeft.png"))

	self.turnRightButton = FrameworkZ.Interfaces:CreateButton({
		x = self.avatarPanel:getRight()-15,
		y = self.avatarPanel:getBottom()-15,
		width = 15,
		height = 15,
		title = "",
		target = self,
		onClick = self.onTurnChar,
		parent = self
	})
	self.turnRightButton.internal = "TURNCHARACTERRIGHT"
	self.turnRightButton:setImage(getTexture("media/ui/ArrowRight.png"))

	self.animCombo = FrameworkZ.Interfaces:CreateCombo({
		x = 0,
		y = self.avatarPanel:getBottom() + 2,
		width = self.width,
		height = comboHgt,
		target = self,
		onChange = self.onAnimSelected,
		options = {
			{text = getText("IGUI_anim_Walk"), data = "EventWalk"},
			{text = getText("IGUI_anim_Idle"), data = "EventIdle"},
			{text = getText("IGUI_anim_Run"), data = "EventRun"}
		},
		parent = self
	})
	self.animCombo.selected = 1
end

function FrameworkZ.UI.CharacterPreview:prerender()
    ISPanel.prerender(self)

	self:drawRectBorder(self.avatarPanel.x - 2, self.avatarPanel.y - 2, self.avatarPanel.width + 4, self.avatarPanel.height + 4, 1, 0.3, 0.3, 0.3);
	self:drawTextureScaled(self.avatarBackgroundTexture, self.avatarPanel.x, self.avatarPanel.y, self.avatarPanel.width, self.avatarPanel.height, 1, 1, 1, 1);
end

function FrameworkZ.UI.CharacterPreview:onTurnChar(button, x, y)
	local direction = self.avatarPanel:getDirection()
	if button.internal == "TURNCHARACTERLEFT" then
		direction = IsoDirections.RotLeft(direction)
		self.avatarPanel:setDirection(direction)
	elseif button.internal == "TURNCHARACTERRIGHT" then
		direction = IsoDirections.RotRight(direction)
		self.avatarPanel:setDirection(direction)
	end
end

function FrameworkZ.UI.CharacterPreview:onAnimSelected(combo)
--	self.avatarPanel:setState(combo:getOptionData(combo.selected))
	self.currentAnimationEvent = combo:getOptionData(combo.selected) or "EventWalk"
	self.pendingAnimReapplyFrames = 2
	self:applyCurrentAnimation()
end

function FrameworkZ.UI.CharacterPreview:setCharacter(character)
	self.avatarPanel:setCharacter(character)
	self.pendingAnimReapplyFrames = 3
	self:applyCurrentAnimation()
end

function FrameworkZ.UI.CharacterPreview:setSurvivorDesc(survivorDesc)
	self.avatarPanel:setSurvivorDesc(survivorDesc)
	self.pendingAnimReapplyFrames = 3
	self:applyCurrentAnimation()
end

function FrameworkZ.UI.CharacterPreview:update()
	ISPanel.update(self)

	if self.pendingAnimReapplyFrames and self.pendingAnimReapplyFrames > 0 then
		self:applyCurrentAnimation()
		self.pendingAnimReapplyFrames = self.pendingAnimReapplyFrames - 1
	end
end

function FrameworkZ.UI.CharacterPreview:new(x, y, width, height, defaultAnimation, defaultDirection)
	local o = ISPanel:new(x, y, width, height)

	setmetatable(o, self)
	self.__index = self

	-- The panel is bigger than it appears when the animation selection dropdown is removed. Maybe there's a better way to handle that?
	o.backgroundColor = {r=0, g=0, b=0, a=0}
	o.borderColor = {r=0, g=0, b=0, a=0}
	o.direction = defaultDirection and defaultDirection or IsoDirections.SW
	o.defaultAnimation = defaultAnimation

	return o
end

return FrameworkZ.UI.CharacterPreview
