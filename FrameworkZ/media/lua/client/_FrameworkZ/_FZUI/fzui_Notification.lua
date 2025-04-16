require "ISUI/ISPanel"

PFW_Notification = ISPanel:derive("PFW_Notification")

function PFW_Notification:initialise()
    self.uiHelper = FrameworkZ.UI

	ISPanel.initialise(self)

    self.textLabel = ISLabel:new(self.uiHelper.GetMiddle(self.width, UIFont.Medium, self.text), self:getY() - self:getHeight() / 2 + getTextManager():MeasureStringY(UIFont.Medium, self.text) / 2, self:getHeight(), self.text, 1, 1, 1, 1, UIFont.Medium, true)
    self.textLabel.r = 0
    self.textLabel.g = 0
    self.textLabel.b = 0
    self.textLabel.a = 1
    self.textLabel:initialise()
    self:addChild(self.textLabel)

    self:restartFadeOut()

    FrameworkZ.Timers:Create("NotificationSlide" .. self.ID, 0, 0, function()
        if self.x > self.x2 then
            self:setX(self:getX() - self:getWidth() * 0.05)
        else
            self:setX(self.x2)
            FrameworkZ.Timers:Remove("NotificationSlide" .. self.ID)
        end
    end)
end

function PFW_Notification:restartFadeOut()
    self.isExpiring = false
    self.hasExpired = false
    
    if FrameworkZ.Timers:Exists("NotificationFadeDelay" .. self.ID) then
        FrameworkZ.Timers:Remove("NotificationFadeDelay" .. self.ID)
    end

    FrameworkZ.Timers:Create("NotificationFadeDelay" .. self.ID, self.duration, 1, function()
        self.hasExpired = true
    end)
end

function PFW_Notification:onMouseMove(x, y)
    ISPanel.onMouseMove(self, x, y)

    if not self.hasEntered then
        self.hasEntered = true

        if not self.hasFullyExpired then
            self:restartFadeOut()
            self.backgroundColor.a = math.min(self.originalAlpha - 0.25, 1)
        end
    end
end

function PFW_Notification:onMouseMoveOutside(x, y)
    ISPanel.onMouseMoveOutside(self, x, y)

    if self.hasEntered then
        self.hasEntered = false

        if not self.hasFullyExpired then
            self.backgroundColor.a = self.originalAlpha
        end
    end
end

function PFW_Notification:update()
    ISPanel.update(self)
end

function PFW_Notification:new(type, text, duration, playerObject)
	local padding = 10
    local margin = 10
    local textWidth = getTextManager():MeasureStringX(UIFont.Medium, text)
    local textHeight = getTextManager():MeasureStringY(UIFont.Medium, text)
    local color = FrameworkZ.Notifications.Colors[type]
    local x = getCore():getScreenWidth() - textWidth - padding - margin * 2
    local y = padding
    local width = textWidth + margin * 2
    local height = textHeight + margin * 2

    local o = {}

	o = ISPanel:new(getCore():getScreenWidth(), y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r = color.r, g = color.g, b = color.b, a = color.a}
	o.borderColor = {r=1, g=1, b=1, a=color.a}
	o.moveWithMouse = false
    o.keepOnScreen = false
    o.text = text
    o.duration = duration
	o.playerObject = playerObject
    o.x2 = x
    o.y2 = y
    o.width2 = width
    o.height2 = height
    o.originalAlpha = color.a

	return o
end

return PFW_Notification
