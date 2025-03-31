if not isClient() then return end

FrameworkZ = FrameworkZ or {}

--! \brief User Interfaces module. This module is used to create user interfaces for the game.
--! \class FrameworkZ.UserInterfaces
FrameworkZ.UserInterfaces = {}
FrameworkZ.UserInterfaces.__index = FrameworkZ.UserInterfaces
FrameworkZ.UserInterfaces.List = {}
FrameworkZ.UserInterfaces.ButtonTheme = {
    massiveButtonFontSize = UIFont.Massive,
    hugeButtonFontSize = UIFont.Title,
    largeButtonFontSize = UIFont.Large,
    mediumButtonFontSize = UIFont.Medium,
    smallButtonFontSize = UIFont.Small,
    buttonBackground = false,
    buttonBackgroundColor = {r=0.1, g=0.1, b=0.1, a=1},
    buttonBorder = false,
    buttonBorderColor = {r=1, g=1, b=1, a=1},
    buttonTextColor = {r=1, g=1, b=1, a=1},
    buttonHoverBackground = false,
    buttonHoverBackgroundColor = {r=0.1, g=0.1, b=0.1, a=1},
    buttonHoverBorder = false,
    buttonHoverBorderColor = {r=1, g=1, b=1, a=1},
    buttonHoverTextColor = {r=1, g=0.84, b=0, a=1},
}
FrameworkZ.UserInterfaces = FrameworkZ.Foundation:NewModule(FrameworkZ.UserInterfaces, "UserInterfaces")

local UI = {}
UI.__index = UI

function UI:Initialize()
    return FrameworkZ.UserInterfaces:Initialize(self.uniqueID, self)
end

function UI:RegisterNextStep(fromMenuName, toMenuName, fromMenu, toMenu, enterToMenuCallback, exitToMenuCallback, toMenuParameters)
    local step = {
        fromMenuName = fromMenuName,
        toMenuName = toMenuName,
        fromMenu = fromMenu,
        toMenu = toMenu,
        enterToMenuCallback = enterToMenuCallback,
        exitToMenuCallback = exitToMenuCallback,
        toMenuParameters = toMenuParameters
    }

    table.insert(self.steps, step)

    return step
end

function UI:ShowNextStep()
    if self.currentStep >= #self.steps then
        local currentStepInfo = self.steps[self.currentStep]
        local fromMenu = currentStepInfo.fromMenu
        local enterToMenuCallback = currentStepInfo.enterToMenuCallback

        if fromMenu.instance then
            enterToMenuCallback(self.parent, fromMenu.instance)
            fromMenu.instance:setVisible(false)
        end

        self.onEnterInitialMenu(self.parent)
        self.currentStep = 1

        return
    end

    -- Moving to current step's to menu
    if self.currentStep == 1 then
        local canGoForward = true

        if self.onExitInitialMenu then
            canGoForward = self.onExitInitialMenu(self.parent)
        end

        if canGoForward then
            local currentStepInfo = self.steps[self.currentStep]
            local toMenu = currentStepInfo.toMenu
            local enterToMenuCallback = currentStepInfo.enterToMenuCallback
            local toMenuParameters = currentStepInfo.toMenuParameters

            if toMenu.instance then
                if enterToMenuCallback then
                    enterToMenuCallback(self.parent, toMenu.instance)
                end

                toMenu.instance:setVisible(true)
            else
                local toMenuName = currentStepInfo.toMenuName
                self.parent[toMenuName] = toMenu:new(toMenuParameters)

                if enterToMenuCallback then
                    enterToMenuCallback(self.parent, self.parent[toMenuName])
                end

                self.parent[toMenuName]:initialise()
                self.parent:addChild(self.parent[toMenuName])
            end

            self.currentStep = self.currentStep + 1
        end

    -- Move to next step's to menu
    else
        local previousStepInfo = self.steps[self.currentStep - 1]
        local currentStepInfo = self.steps[self.currentStep]
        local fromMenu = currentStepInfo.fromMenu
        local toMenu = currentStepInfo.toMenu
        local enterToMenuCallback = currentStepInfo.enterToMenuCallback
        local exitToMenuCallback = previousStepInfo.exitToMenuCallback
        local toMenuParameters = currentStepInfo.toMenuParameters
        local canGoForward = true

        if fromMenu.instance then
            if exitToMenuCallback then
                canGoForward = exitToMenuCallback(self.parent, fromMenu.instance, true)
            end

            if canGoForward then
                fromMenu.instance:setVisible(false)
            end
        end

        if canGoForward then
            if toMenu.instance then
                if enterToMenuCallback then
                    enterToMenuCallback(self.parent, toMenu)
                end

                toMenu.instance:setVisible(true)
            else
                local toMenuName = currentStepInfo.toMenuName
                self.parent[toMenuName] = toMenu:new(toMenuParameters)

                if enterToMenuCallback then
                    enterToMenuCallback(self.parent, self.parent[toMenuName])
                end

                self.parent[toMenuName]:initialise()
                self.parent:addChild(self.parent[toMenuName])
            end

            self.currentStep = self.currentStep + 1
        end
    end

    return true
end

function UI:ShowPreviousStep()
    if self.currentStep <= 1 then
        return false
    end

    -- Moving from initial menu
    if self.currentStep == 2 then
        local previousStepInfo = self.steps[self.currentStep - 1]
        local toMenu = previousStepInfo.toMenu
        local exitToMenuCallback = previousStepInfo.exitToMenuCallback

        if toMenu.instance then
            if exitToMenuCallback then
                exitToMenuCallback(self.parent, toMenu, false)
            end

            toMenu.instance:setVisible(false)
        end

        if self.onEnterInitialMenu then
            self.onEnterInitialMenu(self.parent)
        end

    -- Move to previous step's menu
    else
        local currentStepInfo = self.steps[self.currentStep]
        local previousStepInfo = self.steps[self.currentStep - 1]
        local fromMenu = currentStepInfo.fromMenu
        local toMenu = previousStepInfo.fromMenu
        local enterToMenuCallback = self.steps[self.currentStep - 2].enterToMenuCallback
        local exitFromMenuCallback = previousStepInfo.exitToMenuCallback

        if fromMenu and fromMenu.instance then
            if exitFromMenuCallback then
                exitFromMenuCallback(self.parent, fromMenu)
            end

            fromMenu.instance:setVisible(false)
        end

        if toMenu and toMenu.instance then
            if enterToMenuCallback then
                enterToMenuCallback(self.parent, toMenu)
            end

            toMenu.instance:setVisible(true)
        end
    end

    self.currentStep = self.currentStep - 1

    return true
end

function FrameworkZ.UserInterfaces:New(uniqueID, parent)
    local object = {
        uniqueID = uniqueID,
        parent = parent,
        currentStep = 1,
        steps = {}
    }

    setmetatable(object, UI)

	return object
end

function FrameworkZ.UserInterfaces:Initialize(uniqueID, userInterface)
    self.List[uniqueID] = userInterface

    return uniqueID
end

function FrameworkZ.UserInterfaces:AddButtonEffects(button)
    local theme = self.ButtonTheme

    if not theme.buttonBackground then
        button:setDisplayBackground(false)
    else
        button.backgroundColor = theme.buttonBackgroundColor
    end

    button.oldOnMouseMove = button.onMouseMove
    button.onMouseMove = function(x, y)
        button.oldOnMouseMove(x, y)

        if button.mouseOver then
            button.textColor = theme.buttonHoverTextColor

            if theme.buttonHoverBackground then
                button.backgroundColor = theme.buttonHoverBackgroundColor
            end

            if theme.buttonHoverBorder then
                button.borderColor = theme.buttonHoverBorderColor
            end
        end
    end

    button.oldOnMouseMoveOutside = button.onMouseMoveOutside
    button.onMouseMoveOutside = function(x, y)
        button.oldOnMouseMoveOutside(x, y)

        if not button.mouseOver then
            button.textColor = theme.buttonTextColor
        end

        if theme.buttonBackground then
            button.backgroundColor = theme.buttonBackgroundColor
        end

        if theme.buttonBorder then
            button.borderColor = theme.buttonBorderColor
        end
    end
end

function FrameworkZ.UserInterfaces:CreateHugeButton(parent, x, y, text, target, onClick)
    local theme = self.ButtonTheme
    local width = getTextManager():MeasureStringX(theme.hugeButtonFontSize, text)
    local height = getTextManager():MeasureStringY(theme.hugeButtonFontSize, text)

    local button = ISButton:new(x, y, width, height, text, target, onClick)
    button.font = theme.hugeButtonFontSize
    self:AddButtonEffects(button)
    button:initialise()
    parent:addChild(button)

    return button
end
