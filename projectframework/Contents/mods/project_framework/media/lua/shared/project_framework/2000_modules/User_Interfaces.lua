if not isClient() then return end

ProjectFramework = ProjectFramework or {}

ProjectFramework.UserInterfaces = {}
ProjectFramework.UserInterfaces.__index = ProjectFramework.UserInterfaces
ProjectFramework.UserInterfaces.List = {}
ProjectFramework.UserInterfaces = ProjectFramework.Foundation:NewModule(ProjectFramework.UserInterfaces, "User Interfaces")

local UI = {}
UI.__index = UI

function UI:Initialize()
    return ProjectFramework.UserInterfaces:Initialize(self.uniqueID, self)
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
        local canGoForward = false
        
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
        local canGoForward = false

        if fromMenu.instance then
            if exitToMenuCallback then
                canGoForward = exitToMenuCallback(self.parent, fromMenu.instance)
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
        end
    end

    self.currentStep = self.currentStep + 1

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
                exitToMenuCallback(self.parent, toMenu)
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

function ProjectFramework.UserInterfaces:New(uniqueID, parent)
    local object = {
        uniqueID = uniqueID,
        parent = parent,
        currentStep = 1,
        steps = {}
    }

    setmetatable(object, UI)

	return object
end

function ProjectFramework.UserInterfaces:Initialize(uniqueID, userInterface)
    self.List[uniqueID] = userInterface
    
    return uniqueID
end