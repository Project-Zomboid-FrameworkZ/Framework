MenuManager = {}
MenuManager.__index = MenuManager

function MenuManager.new(context)
    local self = setmetatable({}, MenuManager)
    self.context = context
    self.contextMenuBuilder = ContextMenuBuilder.new(self, context)
    self.subMenuBuilders = {}
    return self
end

function MenuManager:addOption(option, target)
    target = target or self.contextMenuBuilder
    target:addOption(option.text, option.target, option.callback, option.callbackParameters, option.addOnTop)
end

function MenuManager:addSubMenu(name, addOnTop, options)
    -- Create a submenu and its builder
    local menuOption, subMenuBuilder = self.contextMenuBuilder:addSubMenu(name, addOnTop, options)

    -- Store the submenu builder for later use
    table.insert(self.subMenuBuilders, subMenuBuilder)

    return subMenuBuilder
end

function MenuManager:addAggregatedOption(unqiueID, option, target)
    target = target or self.contextMenuBuilder
    target:addAggregatedOptionWithCallback(unqiueID, option.target, option.text, option.callback, option.callbackParameters, option.addOnTop, option.useMultiple, option.count)
end

function MenuManager:buildMenu()
    local function buildSubMenu(subMenuBuilder)
        for _, subMenu in ipairs(subMenuBuilder.subMenus) do
            buildSubMenu(subMenu)
        end

        subMenuBuilder:buildAggregatedOptions()
    end

    -- Build aggregated options for the main context menu
    self.contextMenuBuilder:buildAggregatedOptions()

    -- Build aggregated options for submenus
    for _, subMenuBuilder in ipairs(self.subMenuBuilders) do
        buildSubMenu(subMenuBuilder)
    end
end

function MenuManager:getContext()
    return self.context
end

function MenuManager:getSubMenu(subMenuName)
    for _, subMenuBuilder in ipairs(self.subMenuBuilders) do
        if subMenuBuilder.name and subMenuBuilder.name == subMenuName then
            return subMenuBuilder
        end
    end

    return nil
end

-- Options class
Options = {}
Options.__index = Options

function Options.new(text, target, callback, callbackParameters, addOnTop, useMultiple, count)
    local self = setmetatable({}, Options)

    self.text = text
    self.target = target
    self.callback = callback
    self.callbackParameters = callbackParameters or {}
    self.addOnTop = addOnTop or false
    self.useMultiple = useMultiple or false
    self.count = count or 1

    return self
end

-- getters for Options class
function Options:getText() return self.text end
function Options:getTarget() return self.target end
function Options:getCallback() return self.callback end
function Options:getCallbackParameters() return self.callbackParameters end
function Options:getAddOnTop() return self.addOnTop end
function Options:getUseMultiple() return self.useMultiple end
function Options:getCount() return self.count end

-- setters for Options class
function Options:setText(text) self.text = text end
function Options:setTarget(target) self.target = target end
function Options:setCallback(callback) self.callback = callback end
function Options:setCallbackParameters(callbackParameters) self.callbackParameters = callbackParameters end
function Options:setAddOnTop(addOnTop) self.addOnTop = addOnTop end
function Options:setUseMultiple(useMultiple) self.useMultiple = useMultiple end
function Options:setCount(count) self.count = count end

-- AggregatedOptions class
AggregatedOptions = {}
AggregatedOptions.__index = AggregatedOptions

function AggregatedOptions.new(uniqueID)
    local self = setmetatable({}, AggregatedOptions)
    self.uniqueID = uniqueID
    self.options = {}
    return self
end

-- getters for AggregatedOptions class
function AggregatedOptions:getUniqueID() return self.uniqueID end
function AggregatedOptions:getOptions() return self.options end

function AggregatedOptions:addOption(option)
    table.insert(self.options, option)
end

-- ContextMenuBuilder class
ContextMenuBuilder = {}
ContextMenuBuilder.__index = ContextMenuBuilder

function ContextMenuBuilder.new(menuManager, context)
    local self = setmetatable({}, ContextMenuBuilder)
    self.menuManager = menuManager
    self.context = context
    self.addedOptions = {}
    self.aggregatedOptions = {}
    self.subMenus = {}
    return self
end

function ContextMenuBuilder:getContext()
    return self.context
end

function ContextMenuBuilder:getOptions()
    return self.addedOptions
end

function ContextMenuBuilder:getAggregatedOptions()
    return self.aggregatedOptions
end

function ContextMenuBuilder:getMenuManager()
    return self.menuManager
end

function ContextMenuBuilder:addOption(name, target, callback, parameters, addOnTop)
    local option
    if addOnTop then
        option = self.context:addOptionOnTop(name, target, callback, parameters)
    else
        option = self.context:addOption(name, target, callback, parameters)
    end

    -- Track added options for debugging
    table.insert(self.addedOptions, option)
    return option
end

function ContextMenuBuilder:addSubMenu(name, addOnTop, options)
    -- Create a new context for the submenu
    local subMenu = ISContextMenu:getNew(self.context)
    local subMenuBuilder = ContextMenuBuilder.new(self.menuManager, subMenu) -- Pass menuManager properly
    subMenuBuilder["name"] = name

    -- Add predefined options to the submenu
    if options then
        for _, option in ipairs(options) do
            subMenuBuilder:addOption(option.text, option.target, option.callback, option.callbackParameters, option.addOnTop)
        end
    end

    -- Create a new menu option that leads to the submenu
    local menuOption
    if addOnTop then
        menuOption = self.context:addOptionOnTop(name)
    else
        menuOption = self.context:addOption(name)
    end

    -- Add the submenu to the parent context
    self.context:addSubMenu(menuOption, subMenu)
    table.insert(self.subMenus, subMenuBuilder)

    return menuOption, subMenuBuilder
end

function ContextMenuBuilder:addAggregatedOption(aggregatedOption)
    local uniqueID = aggregatedOption:getUniqueID()

    if not self.aggregatedOptions[uniqueID] then
        self.aggregatedOptions[uniqueID] = aggregatedOption
    end
end

function ContextMenuBuilder:addAggregatedOptionWithCallback(uniqueID, target, text, callback, params, addOnTop, useMultiple, count)
    local option = Options.new(text, target, callback, params, addOnTop, useMultiple, count)
    local aggregatedOption = AggregatedOptions.new(uniqueID)

    aggregatedOption:addOption(option)
    self:addAggregatedOption(aggregatedOption)
end

function ContextMenuBuilder:buildAggregatedOptions()
    local previousUniqueID = nil

    if self.aggregatedOptions then
        for _, aggregatedOption in pairs(self.aggregatedOptions) do
            local uniqueID = aggregatedOption:getUniqueID()

            if uniqueID ~= previousUniqueID then
                for _, option in ipairs(aggregatedOption:getOptions()) do
                    local optionText = option:getText()

                    if option:getUseMultiple() and option:getCount() > 1 then
                        optionText = optionText .. " (x" .. option:getCount() .. ")"
                    end

                    local callback = function(target, parameters)
                        option:getCallback()(target, parameters)
                    end

                    if option:getAddOnTop() then
                        self:addOption(optionText, option:getTarget(), callback, option:getCallbackParameters(), true)
                    else
                        self:addOption(optionText, option:getTarget(), callback, option:getCallbackParameters(), false)
                    end
                end
            end

            previousUniqueID = uniqueID
        end
    end

    self.aggregatedOptions = {}
end
