require "ISUI/ISPanel"

PFW_Introduction = ISPanel:derive("PFW_Introduction")

function PFW_Introduction:initialise()
    local emitter = self.playerObject:getEmitter()
	self.vignetteTexture = getTexture("media/textures/vignette.png")
	self.cfwTexture = getTexture("media/textures/cfw.png")
	self.hl2rpTexture = getTexture("media/textures/hl2rp.png")

	ISPanel.initialise(self)

    self.initializing = ISLabel:new((self.width - getTextManager():MeasureStringX(UIFont.Large, "Initializing...")) / 2, (self.height - getTextManager():MeasureStringY(UIFont.Large, "Initializing...")) / 2, 25, "Initializing...", 1, 1, 1, 1, UIFont.Large, true)
	self:addChild(self.initializing)

	timer:Simple(ProjectFramework.Config.InitializationDuration, function()
    	
		if not ProjectFramework.Config.SkipIntro then
			self:removeChild(self.initializing)
			emitter:playSoundImpl("hl2_song25_teleporter_short", nil)

			emitter:playSoundImpl("button1", nil)
			self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

			timer:Simple(0.1, function()
				self.backgroundColor = {r=0, g=0, b=0, a=1}

				self.cfw = ISImage:new(self.width / 2 - self.cfwTexture:getWidth() / 2, self.height / 2 - self.cfwTexture:getHeight() / 2, self.cfwTexture:getWidth(), self.cfwTexture:getHeight(), self.cfwTexture)
				self.cfw.backgroundColor = {r=1, g=1, b=1, a=1}
				self.cfw.scaledWidth = self.cfwTexture:getWidth()
				self.cfw.scaledHeight = self.cfwTexture:getHeight()
				self.cfw.shrinking = true
				self.cfw:initialise()
				self:addChild(self.cfw)

				timer:Simple(7, function()
					self:removeChild(self.cfw)
					self.cfw = nil

					emitter:playSoundImpl("lightswitch2", nil)
					self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

					timer:Simple(0.1, function()
						self.backgroundColor = {r=0, g=0, b=0, a=1}

						self.hl2rp = ISImage:new(self.width / 2 - self.hl2rpTexture:getWidth() / 2, self.height / 2 - self.hl2rpTexture:getHeight() / 2, self.hl2rpTexture:getWidth(), self.hl2rpTexture:getHeight(), self.hl2rpTexture)
						self.hl2rp.backgroundColor = {r=1, g=1, b=1, a=1}
						self.hl2rp.scaledWidth = self.hl2rpTexture:getWidth()
						self.hl2rp.scaledHeight = self.hl2rpTexture:getHeight()
						self.hl2rp.shrinking = true
						self.hl2rp:initialise()
						self:addChild(self.hl2rp)

						timer:Simple(7, function()
							self:removeChild(self.hl2rp)
							self.hl2rp = nil

							emitter:playSoundImpl("lightswitch2", nil)
							self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

							timer:Remove("IntroTick")

							timer:Simple(0.1, function()
								self.backgroundColor = {r=0, g=0, b=0, a=1}

								local characterSelect = PFW_MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.playerObject)
								characterSelect:initialise()
								characterSelect:addToUIManager()

								timer:Simple(1, function()
									self:setVisible(false)
									self:removeFromUIManager()
								end)
							end)
						end)
					end)
				end)
			end)
		else
			timer:Remove("IntroTick")
			local characterSelect = PFW_MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.playerObject)
			characterSelect:initialise()
			characterSelect:addToUIManager()

			timer:Simple(1, function()
				self:setVisible(false)
				self:removeFromUIManager()
			end)
		end
	end)
end

local function calculateWidthHeight(originalAspectRatio, width, height, changeValue)
    -- Scenario 1: Increase width by 1 and adjust height
    local newWidth1 = width + changeValue
    local newHeight1 = math.floor((newWidth1 / originalAspectRatio) + 0.5)
    
    -- Scenario 2: Increase height by 1 and adjust width
    local newHeight2 = height + changeValue
    local newWidth2 = math.floor((newHeight2 * originalAspectRatio) + 0.5)
    
    -- Calculate the aspect ratio difference for both scenarios
    local difference1 = math.abs((newWidth1 / newHeight1) - originalAspectRatio)
    local difference2 = math.abs((newWidth2 / newHeight2) - originalAspectRatio)
    
    -- Choose the scenario with the smallest difference
    if difference1 < difference2 then
        return newWidth1, newHeight1
    else
        return newWidth2, newHeight2
	end
end

timer:Create("IntroTick", 0.1, 0, function()
	if PFW_Introduction.instance then
		local instance = PFW_Introduction.instance

		if instance.cfw then
			if instance.cfw.shrinking == true and instance.cfw.scaledWidth / instance.cfw:getWidth() >= 0.95 then
				local width, height = calculateWidthHeight(instance.cfw.width / instance.cfw.height, instance.cfw.scaledWidth, instance.cfw.scaledHeight, -1)
				
				instance.cfw.scaledWidth = width
				instance.cfw.scaledHeight = height
			elseif instance.cfw.shrinking == true then
				instance.cfw.shrinking = false
			end
	
			if instance.cfw.shrinking == false and instance.cfw.scaledWidth / instance.cfw:getWidth() <= 1 then
				local width, height = calculateWidthHeight(instance.cfw.width / instance.cfw.height, instance.cfw.scaledWidth, instance.cfw.scaledHeight, 1)
				
				instance.cfw.scaledWidth = width
				instance.cfw.scaledHeight = height
			elseif instance.cfw.shrinking == false then
				instance.cfw.shrinking = true
			end

			instance.cfw:setX(instance.width / 2 - instance.cfw.scaledWidth / 2)
			instance.cfw:setY(instance.height / 2 - instance.cfw.scaledHeight / 2)
		end
	
		if instance.hl2rp then
			if instance.hl2rp.shrinking == true and instance.hl2rp.scaledWidth / instance.hl2rp:getWidth() >= 0.95 then
				local width, height = calculateWidthHeight(instance.hl2rp.width / instance.hl2rp.height, instance.hl2rp.scaledWidth, instance.hl2rp.scaledHeight, -1)

				instance.hl2rp.scaledWidth = width
				instance.hl2rp.scaledHeight = height
			elseif instance.hl2rp.shrinking == true then
				instance.hl2rp.shrinking = false
			end
	
			if instance.hl2rp.shrinking == false and instance.hl2rp.scaledWidth / instance.hl2rp:getWidth() <= 1 then
				local width, height = calculateWidthHeight(instance.hl2rp.width / instance.hl2rp.height, instance.hl2rp.scaledWidth, instance.hl2rp.scaledHeight, 1)
				
				instance.hl2rp.scaledWidth = width
				instance.hl2rp.scaledHeight = height
			elseif instance.hl2rp.shrinking == false then
				instance.hl2rp.shrinking = true
			end

			instance.hl2rp:setX(instance.width / 2 - instance.hl2rp.scaledWidth / 2)
			instance.hl2rp:setY(instance.height / 2 - instance.hl2rp.scaledHeight / 2)
		end
	end
end)

function PFW_Introduction:update()
    ISPanel.update(self)
end

function PFW_Introduction:new(x, y, width, height, playerObject)
	local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=1}
	o.borderColor = {r=0, g=0, b=0, a=1}
	o.moveWithMouse = false
	o.playerObject = playerObject
	PFW_Introduction.instance = o

	return o
end

return PFW_Introduction
