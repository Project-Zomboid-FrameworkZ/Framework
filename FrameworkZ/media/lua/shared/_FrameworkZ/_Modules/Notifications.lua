if not isClient() then return end

FrameworkZ = FrameworkZ or {}

--! \brief Notifications module for FrameworkZ. Queues and sends notifications.
--! \class FrameworkZ.Notifications
FrameworkZ.Notifications = {}
FrameworkZ.Notifications.__index = FrameworkZ.Notifications
FrameworkZ.Notifications.Queue = {}
FrameworkZ.Notifications.List = {}
FrameworkZ.Notifications.Types = {
    Default = "Default",
    Info = "Info",
    Success = "Success",
    Warning = "Warning",
    Danger = "Danger"
}
FrameworkZ.Notifications.Colors = {
    Default = {r = 1, g = 1, b = 1, a = 1},
    Info = {r = 0.051, g = 0.792, b = 0.941, a = 1},
    Success = {r = 0.098, g = 0.529, b = 0.329, a = 1},
    Warning = {r = 1, g = 0.757, b = 0.027, a = 1},
    Danger = {r = 0.863, g = 0.208, b = 0.271, a = 1}
}
FrameworkZ.Notifications = FrameworkZ.Foundation:NewModule(FrameworkZ.Notifications, "Notifications")

function FrameworkZ.Notifications:ProcessQueue(isProcessingContinued)
    if not (isProcessingContinued or not self.isProcessing) and not (#self.Queue > 0 or #self.List > 0) then return false end

    if isProcessingContinued or not self.isProcessing then
        if #self.Queue > 0 then
            self.isProcessing = true
            local queuedNotification = self.Queue[1]

            queuedNotification:initialise()

            if queuedNotification.parentUI then
                queuedNotification.parentUI:addChild(queuedNotification)
            else
                queuedNotification:addToUIManager()
            end

            local player = FrameworkZ.Players:GetPlayerByID(getPlayer():getUsername())
            if player then player:PlayLocalSound("pfw_lightswitch2") end

            table.remove(self.Queue, 1)
            table.insert(self.List, 1, queuedNotification)

            if #self.List > 1 then
                for i = 2, #self.List, 1 do
                    local position = i - 1
                    local topNotification = self.List[1]
                    local notification = self.List[i]
                    notification:setY(topNotification:getY() + notification:getHeight() * position + 10 * position)
                end
            end

            FrameworkZ.Timers:Simple(1, function()
                self.isProcessing = self:ProcessQueue(true)
            end)

            return true
        elseif #self.List > 0 then
            self.isProcessing = true
            local processingID = nil

            for i = 1, #self.List, 1 do
                local notification = self.List[i]
                local expired = notification.hasExpired

                if expired then
                    notification.isExpiring = true
                    processingID = i
                    break
                end
            end

            if not processingID then return false end

            local processingNotification = self.List[processingID]

            FrameworkZ.Timers:Create("NotificationFadeOut", 0, 0, function()
                if processingNotification.isExpiring and processingNotification.textLabel.a > 0 then
                    processingNotification.backgroundColor.a = processingNotification.backgroundColor.a - processingNotification.originalAlpha * 0.01
                    processingNotification.borderColor.a = processingNotification.borderColor.a - processingNotification.originalAlpha * 0.01
                    processingNotification.textLabel.a = processingNotification.textLabel.a - 1 * 0.01
                elseif processingNotification.isExpiring and FrameworkZ.Timers:Exists("NotificationFadeOut") then
                    FrameworkZ.Timers:Remove("NotificationFadeOut")
                    processingNotification.hasFullyExpired = true
                    processingNotification.backgroundColor.a = 0
                    processingNotification.borderColor.a = 0
                    processingNotification.textLabel.a = 0

                    FrameworkZ.Timers:Simple(0.5, function()
                        for i = processingID, #self.List, 1 do
                            local notification = self.List[i]

                            if not notification.isExpiring then
                                notification:setY(notification:getY() - (processingNotification:getHeight() + 10))
                            end
                        end

                        processingNotification:removeFromUIManager()
                        table.remove(self.List, processingID)

                        FrameworkZ.Timers:Simple(1, function()
                            self.isProcessing = self:ProcessQueue(true)
                        end)
                    end)
                elseif not processingNotification.hasFullyExpired and not processingNotification.isExpiring then
                    FrameworkZ.Timers:Remove("NotificationFadeOut")
                    processingNotification.backgroundColor.a = math.min(processingNotification.originalAlpha + 0.25, 1)
                    processingNotification.borderColor.a = processingNotification.originalAlpha
                    processingNotification.textLabel.a = 1

                    FrameworkZ.Timers:Simple(1, function()
                        self.isProcessing = self:ProcessQueue(true)
                    end)
                end
            end)

            return true
        end
    end
end

--! \brief Adds a notification to the queue.
--! \param message \string The message to display.
--! \param notificationType \string The type of notification to display. See notification types.
--! \param duration \integer The duration the notification should be displayed for.
--! \param ui \object The UI object that would cover where notifications display. Useful if you want to display notifications over top of a specific UI object.
--! \return \object The notification UI object.
function FrameworkZ.Notifications:AddToQueue(message, notificationType, duration, ui)
    if not message then return end

    local notification = PFW_Notification:new(notificationType or FrameworkZ.Notifications.Types.Default, message, duration or 10, getPlayer())

    if ui then
        notification.parentUI = ui
    end

    table.insert(self.Queue, notification)

    return notification
end

--[[
function FrameworkZ.Notifications:OnGameStart()
    FrameworkZ.Timers:Create("NotificationTick", 0.5, 0, function()
        if not self.isProcessing then
            self.isProcessing = self:ProcessQueue(false)
        end
    end)
end
--]]

function FrameworkZ.Notifications:PlayerTick(isoPlayer)
    if not self.isProcessing then
        self.isProcessing = self:ProcessQueue(false)
    end
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Notifications)
