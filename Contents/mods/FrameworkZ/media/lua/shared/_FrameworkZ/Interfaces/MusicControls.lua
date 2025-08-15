FrameworkZ.UI.MusicControls = FrameworkZ.UI.MusicControls or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.MusicControls, "MusicControls")

-- Global music volume settings
local introMusicVolume = 0.8
local mainMenuMusicVolume = 0.6
local currentIntroSong = nil
local currentMainMenuSong = nil

function FrameworkZ.UI.MusicControls:initialise()
    ISPanel.initialise(self)

    self.uiHelper = FrameworkZ.UI
    self.emitter = getPlayer():getEmitter()
    
    -- Interface dimensions and positioning
    local panelWidth = 300
    local panelHeight = 120
    local margin = 20
    
    -- Position at bottom-left corner
    self:setX(margin)
    self:setY(getCore():getScreenHeight() - panelHeight - margin)
    self:setWidth(panelWidth)
    self:setHeight(panelHeight)
    
    -- Semi-transparent background
    self.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    self.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    
    local currentY = 10
    
    -- Title
    self.titleLabel = ISLabel:new(10, currentY, 20, "Music Controls", 1, 1, 1, 1, UIFont.Medium, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)
    
    currentY = currentY + 25
    
    -- Intro Music Volume Slider
    self.introVolumeLabel = ISLabel:new(10, currentY, 15, "Intro Volume:", 0.9, 0.9, 0.9, 1, UIFont.Small, true)
    self.introVolumeLabel:initialise()
    self:addChild(self.introVolumeLabel)
    
    self.introVolumeSlider = ISSliderPanel:new(120, currentY, 150, 15, self, self.onIntroVolumeChanged)
    self.introVolumeSlider:initialise()
    self.introVolumeSlider:setValues(0, 1, introMusicVolume, 0.01)
    self:addChild(self.introVolumeSlider)
    
    -- Volume percentage display
    self.introVolumePercent = ISLabel:new(275, currentY, 15, math.floor(introMusicVolume * 100) .. "%", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.introVolumePercent:initialise()
    self:addChild(self.introVolumePercent)
    
    currentY = currentY + 25
    
    -- Main Menu Music Volume Slider
    self.menuVolumeLabel = ISLabel:new(10, currentY, 15, "Menu Volume:", 0.9, 0.9, 0.9, 1, UIFont.Small, true)
    self.menuVolumeLabel:initialise()
    self:addChild(self.menuVolumeLabel)
    
    self.menuVolumeSlider = ISSliderPanel:new(120, currentY, 150, 15, self, self.onMenuVolumeChanged)
    self.menuVolumeSlider:initialise()
    self.menuVolumeSlider:setValues(0, 1, mainMenuMusicVolume, 0.01)
    self:addChild(self.menuVolumeSlider)
    
    -- Volume percentage display
    self.menuVolumePercent = ISLabel:new(275, currentY, 15, math.floor(mainMenuMusicVolume * 100) .. "%", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self.menuVolumePercent:initialise()
    self:addChild(self.menuVolumePercent)
    
    currentY = currentY + 25
    
    -- Control buttons row
    local buttonWidth = 80
    local buttonSpacing = 10
    
    -- Mute/Unmute button
    self.muteButton = ISButton:new(10, currentY, buttonWidth, 20, "Mute All", self, self.onMuteToggle)
    self.muteButton:initialise()
    self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    self:addChild(self.muteButton)
    
    -- Test intro music button
    self.testIntroButton = ISButton:new(10 + buttonWidth + buttonSpacing, currentY, buttonWidth, 20, "Test Intro", self, self.onTestIntro)
    self.testIntroButton:initialise()
    self.testIntroButton.backgroundColor = {r=0.2, g=0.3, b=0.2, a=0.8}
    self:addChild(self.testIntroButton)
    
    -- Close button
    self.closeButton = ISButton:new(10 + (buttonWidth + buttonSpacing) * 2, currentY, buttonWidth, 20, "Close", self, self.onClose)
    self.closeButton:initialise()
    self.closeButton.backgroundColor = {r=0.2, g=0.2, b=0.3, a=0.8}
    self:addChild(self.closeButton)
    
    -- Store instance reference
    FrameworkZ.UI.MusicControls.instance = self
    
    -- Set up fade-in animation
    self:setVisible(true)
    self.fadeAlpha = 0
    self.isFadingIn = true
end

function FrameworkZ.UI.MusicControls:onIntroVolumeChanged()
    local newVolume = self.introVolumeSlider:getCurrentValue()
    introMusicVolume = newVolume
    
    -- Update percentage display
    self.introVolumePercent:setName(math.floor(newVolume * 100) .. "%")
    
    -- Apply volume to currently playing intro music if any
    if currentIntroSong and self.emitter:isPlaying(currentIntroSong) then
        self.emitter:setVolume(currentIntroSong, newVolume)
    end
    
    print("Intro music volume set to: " .. math.floor(newVolume * 100) .. "%")
end

function FrameworkZ.UI.MusicControls:onMenuVolumeChanged()
    local newVolume = self.menuVolumeSlider:getCurrentValue()
    mainMenuMusicVolume = newVolume
    
    -- Update percentage display
    self.menuVolumePercent:setName(math.floor(newVolume * 100) .. "%")
    
    -- Apply volume to currently playing main menu music if any
    if currentMainMenuSong and self.emitter:isPlaying(currentMainMenuSong) then
        self.emitter:setVolume(currentMainMenuSong, newVolume)
    end
    
    -- Also update the main menu's music volume if it exists
    if FrameworkZ.UI.MainMenu and FrameworkZ.UI.MainMenu.instance then
        FrameworkZ.UI.MainMenu.instance:updateMusicVolume(newVolume)
    end
    
    print("Main menu music volume set to: " .. math.floor(newVolume * 100) .. "%")
end

function FrameworkZ.UI.MusicControls:onMuteToggle()
    if self.muteButton:getTitle() == "Mute All" then
        -- Mute all music
        if currentIntroSong and self.emitter:isPlaying(currentIntroSong) then
            self.emitter:setVolume(currentIntroSong, 0)
        end
        if currentMainMenuSong and self.emitter:isPlaying(currentMainMenuSong) then
            self.emitter:setVolume(currentMainMenuSong, 0)
        end
        self.muteButton:setTitle("Unmute All")
        self.muteButton.backgroundColor = {r=0.5, g=0.2, b=0.2, a=0.8}
    else
        -- Restore volumes
        if currentIntroSong and self.emitter:isPlaying(currentIntroSong) then
            self.emitter:setVolume(currentIntroSong, introMusicVolume)
        end
        if currentMainMenuSong and self.emitter:isPlaying(currentMainMenuSong) then
            self.emitter:setVolume(currentMainMenuSong, mainMenuMusicVolume)
        end
        self.muteButton:setTitle("Mute All")
        self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    end
end

function FrameworkZ.UI.MusicControls:onTestIntro()
    -- Stop any currently playing intro music
    if currentIntroSong and self.emitter:isPlaying(currentIntroSong) then
        self.emitter:stopSound(currentIntroSong)
    end
    
    -- Play intro music at current volume setting
    if FrameworkZ.Config.Options.IntroMusic then
        currentIntroSong = self.emitter:playSoundImpl(FrameworkZ.Config.Options.IntroMusic, nil)
        if currentIntroSong then
            self.emitter:setVolume(currentIntroSong, introMusicVolume)
            print("Testing intro music at " .. math.floor(introMusicVolume * 100) .. "% volume")
        end
    else
        print("No intro music configured")
    end
end

function FrameworkZ.UI.MusicControls:onClose()
    -- Fade out and close
    self.isFadingIn = false
    self.isFadingOut = true
end

function FrameworkZ.UI.MusicControls:update()
    ISPanel.update(self)
    
    -- Handle fade animations
    if self.isFadingIn then
        self.fadeAlpha = self.fadeAlpha + 0.05
        if self.fadeAlpha >= 1.0 then
            self.fadeAlpha = 1.0
            self.isFadingIn = false
        end
    elseif self.isFadingOut then
        self.fadeAlpha = self.fadeAlpha - 0.05
        if self.fadeAlpha <= 0.0 then
            self.fadeAlpha = 0.0
            self.isFadingOut = false
            self:setVisible(false)
            FrameworkZ.UI.MusicControls.instance = nil
        end
    end
end

function FrameworkZ.UI.MusicControls:render()
    -- Apply fade alpha to background
    if self.fadeAlpha and self.fadeAlpha < 1.0 then
        local originalAlpha = self.backgroundColor.a
        self.backgroundColor.a = originalAlpha * self.fadeAlpha
        ISPanel.render(self)
        self.backgroundColor.a = originalAlpha
    else
        ISPanel.render(self)
    end
end

-- Static functions for external control
function FrameworkZ.UI.MusicControls:SetIntroMusicVolume(volume)
    introMusicVolume = math.max(0, math.min(1, volume))
    if FrameworkZ.UI.MusicControls.instance then
        FrameworkZ.UI.MusicControls.instance.introVolumeSlider:setCurrentValue(introMusicVolume)
        FrameworkZ.UI.MusicControls.instance.introVolumePercent:setName(math.floor(introMusicVolume * 100) .. "%")
    end
end

function FrameworkZ.UI.MusicControls:SetMainMenuMusicVolume(volume)
    mainMenuMusicVolume = math.max(0, math.min(1, volume))
    if FrameworkZ.UI.MusicControls.instance then
        FrameworkZ.UI.MusicControls.instance.menuVolumeSlider:setCurrentValue(mainMenuMusicVolume)
        FrameworkZ.UI.MusicControls.instance.menuVolumePercent:setName(math.floor(mainMenuMusicVolume * 100) .. "%")
    end
end

function FrameworkZ.UI.MusicControls:GetIntroMusicVolume()
    return introMusicVolume
end

function FrameworkZ.UI.MusicControls:GetMainMenuMusicVolume()
    return mainMenuMusicVolume
end

function FrameworkZ.UI.MusicControls:SetCurrentIntroSong(song)
    currentIntroSong = song
end

function FrameworkZ.UI.MusicControls:SetCurrentMainMenuSong(song)
    currentMainMenuSong = song
end

function FrameworkZ.UI.MusicControls:new(parameters)
    local o = {}
    o = ISPanel:new(0, 0, 300, 120)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    o.moveWithMouse = true
    
    return o
end

return FrameworkZ.UI.MusicControls
