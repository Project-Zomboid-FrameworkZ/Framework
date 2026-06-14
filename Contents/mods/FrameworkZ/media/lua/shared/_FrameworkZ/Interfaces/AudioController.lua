FrameworkZ.UI.AudioController = FrameworkZ.Interfaces:New("AudioController", FrameworkZ.UI)
FrameworkZ.UI.AudioController.instances = {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.AudioController, "AudioController")

function FrameworkZ.UI.AudioController:initialise()
    ISPanel.initialise(self)

    -- BG panel
	self.audioControlsPanel = FrameworkZ.Interfaces:CreatePanel({
		x = 0, y = 0, width = self:getWidth(), height = self:getHeight()
	})
    self:addChild(self.audioControlsPanel)

    local currentY = 5

	-- Title
	self.musicTitle = FrameworkZ.Interfaces:CreateLabel({
		x = 10, y = currentY, height = 15,
		text = self.name,
		font = FZ_FONT_SMALL,
		textAlign = FZ_ALIGN_LEFT,
		parent = self.audioControlsPanel
	})

    currentY = currentY + 20

    -- Volume Slider label
	self.volumeLabel = FrameworkZ.Interfaces:CreateLabel({
		x = 10, y = currentY, height = 12,
		text = "Volume:",
		font = FZ_FONT_SMALL,
		textAlign = FZ_ALIGN_LEFT,
		parent = self.audioControlsPanel
	})

    -- Actual Volume Slider
	self.volumeSlider = FrameworkZ.Interfaces:CreateSlider({
		x = 55, y = currentY, width = 150, height = 12,
		target = self, onChange = self.onVolumeChanged,
		min = 0, max = 1, step = 0.01, value = self.Volume,
		parent = self.audioControlsPanel
	})

    -- Volume percentage display
	self.volumePercent = FrameworkZ.Interfaces:CreateLabel({
		x = 210, y = currentY, height = 12,
		text = tostring(math.floor(self.Volume * 100)) .. "%",
		font = FZ_FONT_SMALL,
		parent = self.audioControlsPanel
	})

    currentY = currentY + 20

    -- Mute button
	self.muteButton = FrameworkZ.Interfaces:CreateButton({
		x = 10, y = currentY, width = 80, height = 18,
		title = "Mute",
		target = self, onClick = self.onMuteToggle,
		font = FZ_FONT_SMALL,
		parent = self.audioControlsPanel
	})
end

function FrameworkZ.UI.AudioController:onVolumeChanged(newValue, slider)
    if self:isMuted() then
        self:unmute()
    end

    self:setVolume(newValue)
    self:refreshUI()
end

function FrameworkZ.UI.AudioController:onMuteToggle()
    self:toggleMute()
    self:refreshUI()
end

function FrameworkZ.UI.AudioController:update()
    ISPanel.update(self)
end

function FrameworkZ.UI.AudioController:refreshUI()
    if self:isMuted() then
        self.volumeSlider.currentValue = 0
        self.volumePercent:setName("0%")
        self.muteButton:setTitle("Unmute")
        self.muteButton.backgroundColor = {r=0.5, g=0.2, b=0.2, a=0.8}
    else
        self.volumeSlider.currentValue = self:getVolume()
        self.volumePercent:setName(tostring(math.floor(self:getVolume() * 100)) .. "%")
        self.muteButton:setTitle("Mute")
        self.muteButton.backgroundColor = {r=0.3, g=0.2, b=0.2, a=0.8}
    end
end

function FrameworkZ.UI.AudioController:playTrack(audioName)
    if not audioName then return end
    local emitter = self.playerObject:getEmitter() if not emitter then return end

    -- Cancel track's fade out if it's currently fading
    FrameworkZ.Timers:Remove("FZ_AudioController_FadeOut")

    -- Interrupt current track if it's playing
    if self:isPlaying() then
        emitter:stopSound(self.Audio)
    end

    self.Audio = emitter:playSoundImpl(audioName, self.playerObject)
    emitter:setVolume(self:getAudio(), self:getVolume())
end

function FrameworkZ.UI.AudioController:stopTrack()
    if self:isPlaying() then
        self.playerObject:getEmitter():stopSound(self:getAudio())
        self.Audio = nil
    end
end

function FrameworkZ.UI.AudioController:setVolume(newVolume)
    if not newVolume then return end
    self.Volume = newVolume

    if self:isPlaying() then
        self.playerObject:getEmitter():setVolume(self.Audio, self.Volume)
    end
end

function FrameworkZ.UI.AudioController:mute()
    self.VolumeCache = self:getVolume()
    self.Volume = 0
    self:setVolume(self:getVolume())
    self.Muted = true
end

function FrameworkZ.UI.AudioController:unmute()
    self.Volume = self:getVolumeCache() or 0.5
    self.VolumeCache = nil
    self:setVolume(self:getVolume())
    self.Muted = false
end

function FrameworkZ.UI.AudioController:toggleMute()
    if self:getMuted() then
        self:unmute()
    else
        self:mute()
    end
end

function FrameworkZ.UI.AudioController:isPlaying()
    local audio = self:getAudio() if not audio then return false end

    if audio and self.playerObject:getEmitter():isPlaying(audio) then
        return true
    end

    return false
end

function FrameworkZ.UI.AudioController:isMuted()
    return self:getMuted()
end

function FrameworkZ.UI.AudioController:getAudio() return self.Audio end
function FrameworkZ.UI.AudioController:getMuted() return self.Muted end
function FrameworkZ.UI.AudioController:getVolume() return self.Volume end
function FrameworkZ.UI.AudioController:getVolumeCache() return self.VolumeCache end

function FrameworkZ.UI.AudioController:fadeOut()
    self.VolumeCache = self:getVolumeCache() or self:getVolume()

    FrameworkZ.Timers:Create("FZ_AudioController_FadeOut", 0.01, 0, function()
        if not self:isPlaying() then
            FrameworkZ.Timers:Remove("FZ_AudioController_FadeOut")
            return
        end

        local currentVolume = self:getVolume()
        local newVolume = math.max(0, currentVolume - 0.002)
        self:setVolume(newVolume)

        if newVolume <= 0 then
            self:stopTrack()
            FrameworkZ.Timers:Remove("FZ_AudioController_FadeOut")
        end
    end)
end

function FrameworkZ.UI.AudioController:transfer(panel)
    if not panel then return end

    if self:getParent() then
        self:getParent():removeChild(self)
    end

    panel:addChild(self)

    if not self:isMuted() then
        self:setVolume(self:getVolumeCache() or self:getVolume())
    end
end

function FrameworkZ.UI.AudioController:new(name, x, y, playerObject)
	local o = {}

	o = ISPanel:new(x, y, 280, 75)
	setmetatable(o, self)
	self.__index = self
    o.name = name
	o.backgroundColor = {r=0, g=0, b=0, a=1}
	o.borderColor = {r=0, g=0, b=0, a=1}
	o.moveWithMouse = false
	o.playerObject = playerObject

    o.Audio = nil
    o.Muted = false
    o.Volume = 0.5
    o.VolumeCache = nil

	FrameworkZ.UI.AudioController.instances[name] = o

	return o
end

return FrameworkZ.UI.AudioController
