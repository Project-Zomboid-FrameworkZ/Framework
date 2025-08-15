FrameworkZ.UI.Introduction = FrameworkZ.UI.Introduction or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.Introduction, "Introduction")

-- Music volume settings
local musicVolume = 0.5
local currentIntroSong = nil
local isMuted = false
local originalVolumeBeforeMute = musicVolume

function FrameworkZ.UI.Introduction:createMusicControls()
    -- Music controls panel in bottom-left corner
    local panelWidth = 280
    local panelHeight = 75  -- Increased height to accommodate bottom padding
    local margin = 20
    
    self.musicControlsPanel = ISPanel:new(margin, self.height - panelHeight - margin, panelWidth, panelHeight)
    self.musicControlsPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    self.musicControlsPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    self.musicControlsPanel:initialise()
    self:addChild(self.musicControlsPanel)
    
    local currentY = 5
    
    -- Title
    self.musicTitle = ISLabel:new(10, currentY, 15, "Music Volume", 1, 1, 1, 1, UIFont.Small, true)
    self.musicTitle:initialise()
    self.musicControlsPanel:addChild(self.musicTitle)
    
    currentY = currentY + 20
    
    -- Music Volume Slider
    self.volumeLabel = ISLabel:new(10, currentY, 12, "Volume:", 0.9, 0.9, 0.9, 1, UIFont.Small, true)
    self.volumeLabel:initialise()
    self.musicControlsPanel:addChild(self.volumeLabel)
    
    self.volumeSlider = ISSliderPanel:new(55, currentY, 150, 12, self, self.onVolumeChanged)
	self.volumeSlider.currentValue = musicVolume
    self.volumeSlider.minValue = 0
    self.volumeSlider.maxValue = 1
    self.volumeSlider.stepValue = 0.01
    self.volumeSlider:initialise()
    self.musicControlsPanel:addChild(self.volumeSlider)
    
    -- Volume percentage display
    self.volumePercent = ISLabel:new(210, currentY, 12, tostring(math.floor(musicVolume * 100)) .. "%", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.volumePercent:initialise()
    self.musicControlsPanel:addChild(self.volumePercent)
    
    currentY = currentY + 20  -- Reduced spacing before mute button
    
    -- Mute button
    self.muteButton = ISButton:new(10, currentY, 80, 18, "Mute", self, self.onMuteToggle)
    self.muteButton:initialise()
    self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    self.muteButton.font = UIFont.Small
    self.musicControlsPanel:addChild(self.muteButton)
    
    -- Bottom padding is now included in the panel height (5px bottom margin like top)
end

function FrameworkZ.UI.Introduction:onVolumeChanged(newValue, slider)
    local newVolume = newValue
    musicVolume = newVolume
    
    -- If user adjusts volume while muted, unmute and update original volume
    if isMuted then
        isMuted = false
        originalVolumeBeforeMute = newVolume
        self.muteButton:setTitle("Mute")
        self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    else
        originalVolumeBeforeMute = newVolume
    end
    
    -- Update percentage display
    self.volumePercent:setName(tostring(math.floor(newVolume * 100)) .. "%")
    
    -- Apply volume to currently playing intro music if any
    if currentIntroSong and self.playerObject:getEmitter():isPlaying(currentIntroSong) then
        self.playerObject:getEmitter():setVolume(currentIntroSong, newVolume)
    end
    
    -- If main menu instance exists and has music playing, update its volume too
    if FrameworkZ.UI.MainMenu.instance and FrameworkZ.UI.MainMenu.instance.setMainMenuMusicVolume then
        FrameworkZ.UI.MainMenu.instance:setMainMenuMusicVolume(newVolume)
        -- Also update the original volume for proper unmuting later
        if not isMuted then
            FrameworkZ.UI.MainMenu.instance:setOriginalVolumeForUnmute(newVolume)
        end
    end
end

function FrameworkZ.UI.Introduction:onMuteToggle()
    if self.muteButton:getTitle() == "Mute" then
        -- Store current volume and mute
        originalVolumeBeforeMute = musicVolume
        musicVolume = 0
        isMuted = true
        
        -- Mute intro music
        if currentIntroSong and self.playerObject:getEmitter():isPlaying(currentIntroSong) then
            self.playerObject:getEmitter():setVolume(currentIntroSong, 0)
        end
        -- Mute main menu music if it exists
        if FrameworkZ.UI.MainMenu.instance and FrameworkZ.UI.MainMenu.instance.setMainMenuMusicVolume then
            FrameworkZ.UI.MainMenu.instance:setMainMenuMusicVolume(0)
        end
        
        -- Update UI
        self.volumeSlider.currentValue = 0
        self.volumePercent:setName("0%")
        self.muteButton:setTitle("Unmute")
        self.muteButton.backgroundColor = {r=0.5, g=0.2, b=0.2, a=0.8}
    else
        -- Restore volume and unmute
        musicVolume = originalVolumeBeforeMute
        isMuted = false
        
        -- If we're in the main menu, get the original volume from there
        if FrameworkZ.UI.MainMenu.instance and FrameworkZ.UI.MainMenu.instance.getOriginalVolumeForUnmute then
            local mainMenuOriginal = FrameworkZ.UI.MainMenu.instance:getOriginalVolumeForUnmute()
            if mainMenuOriginal and mainMenuOriginal > 0 then
                musicVolume = mainMenuOriginal
                originalVolumeBeforeMute = mainMenuOriginal
            end
        end
        
        -- Restore intro music volume
        if currentIntroSong and self.playerObject:getEmitter():isPlaying(currentIntroSong) then
            self.playerObject:getEmitter():setVolume(currentIntroSong, musicVolume)
        end
        -- Restore main menu music volume if it exists
        if FrameworkZ.UI.MainMenu.instance and FrameworkZ.UI.MainMenu.instance.setMainMenuMusicVolume then
            FrameworkZ.UI.MainMenu.instance:setMainMenuMusicVolume(musicVolume)
        end
        
        -- Update UI
        self.volumeSlider.currentValue = musicVolume
        self.volumePercent:setName(tostring(math.floor(musicVolume * 100)) .. "%")
        self.muteButton:setTitle("Mute")
        self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    end
end

function FrameworkZ.UI.Introduction:initialise()
    local emitter = self.playerObject:getEmitter()
	self.vignetteTexture = getTexture("media/textures/vignette.png")
	self.cfwTexture = getTexture(FrameworkZ.Config.Options.IntroFrameworkImage)
	self.hl2rpTexture = getTexture(FrameworkZ.Config.Options.IntroGamemodeImage)

	ISPanel.initialise(self)

    self.initializing = ISLabel:new(self.width / 2, (self.height - getTextManager():MeasureStringY(UIFont.Large, "Initializing")) / 2, 25, "Initializing", 1, 1, 1, 1, UIFont.Large, true)
	self.initializing.center = true
	self:addChild(self.initializing)

    -- Add music controls in bottom-left corner during initialization
    self:createMusicControls()

	self.currentTick = 1

	FrameworkZ.Timers:Create("FZ_INITIALIZATION", FrameworkZ.Config.Options.InitializationDuration, 1, function()
		FrameworkZ.Timers:Create("FZ_INIT_TICK", 0.2, 0, function()
			if not FrameworkZ.Foundation.Initialized then
				if self.currentTick == 0 then
					self.initializing:setName("Initializing")
					self.currentTick = 1
				elseif self.currentTick == 1 then
					self.initializing:setName("Initializing.")
					self.currentTick = 2
				elseif self.currentTick == 2 then
					self.initializing:setName("Initializing..")
					self.currentTick = 3
				elseif self.currentTick == 3 then
					self.initializing:setName("Initializing...")
					self.currentTick = 0
				end
			else
				FrameworkZ.Timers:Remove("FZ_INIT_TICK")
				self.initializing:setName("--- Initialized ---")

				FrameworkZ.Timers:Simple(2, function()
					if not FrameworkZ.Config.Options.SkipIntro then
						self:removeChild(self.initializing)
						-- Start intro music with volume control
						if FrameworkZ.Config.Options.IntroMusic then
							currentIntroSong = emitter:playSoundImpl(FrameworkZ.Config.Options.IntroMusic, nil)
							if currentIntroSong then
								emitter:setVolume(currentIntroSong, musicVolume)
							end
						end

						emitter:playSoundImpl("button1", nil)
						self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

						FrameworkZ.Timers:Simple(0.1, function()
							self.backgroundColor = {r=0, g=0, b=0, a=1}

							self.cfw = ISImage:new(self.width / 2 - self.cfwTexture:getWidth() / 2, self.height / 2 - self.cfwTexture:getHeight() / 2, self.cfwTexture:getWidth(), self.cfwTexture:getHeight(), self.cfwTexture)
							self.cfw.backgroundColor = {r=1, g=1, b=1, a=1}
							self.cfw.scaledWidth = self.cfwTexture:getWidth()
							self.cfw.scaledHeight = self.cfwTexture:getHeight()
							self.cfw.shrinking = true
							self.cfw:initialise()
							self:addChild(self.cfw)

							FrameworkZ.Timers:Simple(7, function()
								self:removeChild(self.cfw)
								self.cfw = nil

								emitter:playSoundImpl("lightswitch2", nil)
								self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

								FrameworkZ.Timers:Simple(0.1, function()
									self.backgroundColor = {r=0, g=0, b=0, a=1}

									self.hl2rp = ISImage:new(self.width / 2 - self.hl2rpTexture:getWidth() / 2, self.height / 2 - self.hl2rpTexture:getHeight() / 2, self.hl2rpTexture:getWidth(), self.hl2rpTexture:getHeight(), self.hl2rpTexture)
									self.hl2rp.backgroundColor = {r=1, g=1, b=1, a=1}
									self.hl2rp.scaledWidth = self.hl2rpTexture:getWidth()
									self.hl2rp.scaledHeight = self.hl2rpTexture:getHeight()
									self.hl2rp.shrinking = true
									self.hl2rp:initialise()
									self:addChild(self.hl2rp)

									FrameworkZ.Timers:Simple(7, function()
										self:removeChild(self.hl2rp)
										self.hl2rp = nil

										emitter:playSoundImpl("lightswitch2", nil)
										self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=1}

										FrameworkZ.Timers:Remove("IntroTick")

										FrameworkZ.Timers:Simple(0.1, function()
											self.backgroundColor = {r=0, g=0, b=0, a=1}

											local characterSelect = FrameworkZ.UI.MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.playerObject)
											characterSelect:addChild(FrameworkZ.Foundation.InitializationNotification)
											characterSelect:initialise()
											-- Pass music volume settings to main menu immediately after initialization
											characterSelect:setMainMenuMusicVolume(musicVolume)
											-- If we're muted, pass the original volume for proper unmuting
											if isMuted then
												characterSelect:setOriginalVolumeForUnmute(originalVolumeBeforeMute)
											end
											
											-- Transfer music controls panel to main menu
											if self.musicControlsPanel then
												self:removeChild(self.musicControlsPanel)
												characterSelect:addChild(self.musicControlsPanel)
												-- Update panel position for main menu
												self.musicControlsPanel:setX(20)
												self.musicControlsPanel:setY(characterSelect.height - 95)  -- Adjusted for new height
											end
											
											characterSelect:addToUIManager()

											FrameworkZ.Timers:Simple(1, function()
												self:setVisible(false)
												self:removeFromUIManager()
											end)
										end)
									end)
								end)
							end)
						end)
					else
						FrameworkZ.Timers:Remove("IntroTick")
						local characterSelect = FrameworkZ.UI.MainMenu:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), self.playerObject)
						characterSelect:addChild(FrameworkZ.Foundation.InitializationNotification)
						characterSelect:initialise()
						-- Pass music volume settings to main menu immediately after initialization
						characterSelect:setMainMenuMusicVolume(musicVolume)
						-- If we're muted, pass the original volume for proper unmuting
						if isMuted then
							characterSelect:setOriginalVolumeForUnmute(originalVolumeBeforeMute)
						end
						
						-- Transfer music controls panel to main menu
						if self.musicControlsPanel then
							self:removeChild(self.musicControlsPanel)
							characterSelect:addChild(self.musicControlsPanel)
							-- Update panel position for main menu
							self.musicControlsPanel:setX(20)
							self.musicControlsPanel:setY(characterSelect.height - 95)  -- Adjusted for new height
						end
						
						characterSelect:addToUIManager()

						FrameworkZ.Timers:Simple(1, function()
							self:setVisible(false)
							self:removeFromUIManager()
						end)
					end
				end)
			end
		end)
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

FrameworkZ.Timers:Create("IntroTick", 0.1, 0, function()
	if FrameworkZ.UI.Introduction.instance then
		local instance = FrameworkZ.UI.Introduction.instance

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

function FrameworkZ.UI.Introduction:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.Introduction:new(x, y, width, height, playerObject)
	local o = {}

	o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=1}
	o.borderColor = {r=0, g=0, b=0, a=1}
	o.moveWithMouse = false
	o.playerObject = playerObject
	FrameworkZ.UI.Introduction.instance = o

	return o
end

return FrameworkZ.UI.Introduction
