ProjectFramework = ProjectFramework or {}

require "ISUI/ISPanel"

PFW_CharacterPreview = ISPanel:derive("PFW_CharacterPreview")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function PFW_CharacterPreview:initialise()
    ISPanel.initialise(self)

    self.avatarBackgroundTexture = getTexture("media/ui/avatarBackground.png")

	local comboHgt = FONT_HGT_SMALL + 3 * 2

	self.avatarPanel = ISUI3DModel:new(0, 0, self.width, self.height - comboHgt)
	self.avatarPanel.backgroundColor = {r=0, g=0, b=0, a=0.8}
	self.avatarPanel.borderColor = {r=1, g=1, b=1, a=0.2}
	self:addChild(self.avatarPanel)
	self.avatarPanel:setState("idle")
	self.avatarPanel:setDirection(IsoDirections.SW)
	self.avatarPanel:setIsometric(false)
	self.avatarPanel:setDoRandomExtAnimations(true)
    self.avatarPanel:reportEvent("EventWalk")

	self.turnLeftButton = ISButton:new(self.avatarPanel.x, self.avatarPanel:getBottom()-15, 15, 15, "", self, self.onTurnChar)
	self.turnLeftButton.internal = "TURNCHARACTERLEFT"
	self.turnLeftButton:initialise()
	self.turnLeftButton:instantiate()
	self.turnLeftButton:setImage(getTexture("media/ui/ArrowLeft.png"))
	self:addChild(self.turnLeftButton)

	self.turnRightButton = ISButton:new(self.avatarPanel:getRight()-15, self.avatarPanel:getBottom()-15, 15, 15, "", self, self.onTurnChar)
	self.turnRightButton.internal = "TURNCHARACTERRIGHT"
	self.turnRightButton:initialise()
	self.turnRightButton:instantiate()
	self.turnRightButton:setImage(getTexture("media/ui/ArrowRight.png"))
	self:addChild(self.turnRightButton)

	self.animCombo = ISComboBox:new(0, self.avatarPanel:getBottom() + 2, self.width, comboHgt, self, self.onAnimSelected)
	self.animCombo:initialise()
	self:addChild(self.animCombo)
	self.animCombo:addOptionWithData(getText("IGUI_anim_Walk"), "EventWalk")
	self.animCombo:addOptionWithData(getText("IGUI_anim_Idle"), "EventIdle")
	self.animCombo:addOptionWithData(getText("IGUI_anim_Run"), "EventRun")
	self.animCombo.selected = 1
end


function PFW_CharacterPreview:prerender()
    ISPanel.prerender(self)

	self:drawRectBorder(self.avatarPanel.x - 2, self.avatarPanel.y - 2, self.avatarPanel.width + 4, self.avatarPanel.height + 4, 1, 0.3, 0.3, 0.3);
	self:drawTextureScaled(self.avatarBackgroundTexture, self.avatarPanel.x, self.avatarPanel.y, self.avatarPanel.width, self.avatarPanel.height, 1, 1, 1, 1);
end

function PFW_CharacterPreview:onTurnChar(button, x, y)
	local direction = self.avatarPanel:getDirection()
	if button.internal == "TURNCHARACTERLEFT" then
		direction = IsoDirections.RotLeft(direction)
		self.avatarPanel:setDirection(direction)
	elseif button.internal == "TURNCHARACTERRIGHT" then
		direction = IsoDirections.RotRight(direction)
		self.avatarPanel:setDirection(direction)
	end
end

function PFW_CharacterPreview:onAnimSelected(combo)
--	self.avatarPanel:setState(combo:getOptionData(combo.selected))
	self.avatarPanel:reportEvent(combo:getOptionData(combo.selected))
end

function PFW_CharacterPreview:setCharacter(character)
	self.avatarPanel:setCharacter(character)
end

function PFW_CharacterPreview:setSurvivorDesc(survivorDesc)
	self.avatarPanel:setSurvivorDesc(survivorDesc)
end

function PFW_CharacterPreview:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)

	setmetatable(o, self)
	self.__index = self
	o.direction = IsoDirections.E

	return o
end

return PFW_CharacterPreview
