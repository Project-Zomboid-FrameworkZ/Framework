MenuManager = {}
MenuManager.__index = MenuManager

--! \brief Create a menu manager wrapper around a context menu.
--! \param context \table The ISContextMenu instance.
--! \return \table MenuManager instance.
function MenuManager.new(context)
    local self = setmetatable({}, MenuManager)
    self.context = context
    self.contextMenuBuilder = ContextMenuBuilder.new(self, context)
    self.subMenuBuilders = {}
    return self
end

--! \brief Add a simple option to the context menu or target builder.
--! \param option \table Option table with text/target/callback parameters.
--! \param target \table Optional ContextMenuBuilder target; defaults to root builder.
--! \return \table The created menu option.
function MenuManager:addOption(option, target)
    target = target or self.contextMenuBuilder
    return target:addOption(option.text, option.target, option.callback, option.callbackParameters, option.addOnTop)
end

--! \brief Create and return a submenu builder.
--! \param name \string Submenu display name.
--! \param addOnTop \boolean Whether to add the submenu on top.
--! \param options \table Optional predefined options list.
--! \return \table Submenu builder instance.
function MenuManager:addSubMenu(name, addOnTop, options)
    -- Create a submenu and its builder
    local menuOption, subMenuBuilder = self.contextMenuBuilder:addSubMenu(name, addOnTop, options)

    -- Store the submenu builder for later use
    table.insert(self.subMenuBuilders, subMenuBuilder)

    return subMenuBuilder
end

--! \brief Add an aggregated option bucket keyed by unique ID.
--! \param unqiueID \string Aggregation key.
--! \param option \table Option definition.
--! \param target \table Optional target builder.
function MenuManager:addAggregatedOption(unqiueID, option, target)
    target = target or self.contextMenuBuilder
    target:addAggregatedOptionWithCallback(unqiueID, option.target, option.text, option.callback, option.callbackParameters, option.addOnTop, option.useMultiple, option.count)
end

--! \brief Snapshot all options currently in a context menu into a plain list.
--! Call this BEFORE clearing the context. Returns a list of raw option tables.
--! \param context \table ISContextMenu to snapshot.
--! \return \table Array of option tables.
function MenuManager.snapshotOptions(context)
    local snapshot = {}
    if context and context.options then
        for _, opt in ipairs(context.options) do
            -- Copy option state but keep original submenu references.
            local optCopy = {}
            for key, value in pairs(opt) do
                if key == "subOption" then
                    optCopy[key] = value
                else
                    optCopy[key] = FrameworkZ.Utilities:CopyTable(value)
                end
            end

            table.insert(snapshot, optCopy)
        end
    end
    return snapshot
end

--! \brief Re-add a list of snapshotted options into a new named submenu appended to the root context.
--! Preserves callbacks, params, and nested submenus. Call this AFTER buildMenu().
--! \param optionList \table List returned by snapshotOptions.
--! \param subMenuName \string Display name for the submenu.
function MenuManager:migrateOptionsToSubMenu(optionList, subMenuName)
    if not optionList or #optionList == 0 then return end

    local subMenu = self.context:getNew(self.context)
    local subMenuOption = self.context:addOption(subMenuName)
    self.context:addSubMenu(subMenuOption, subMenu)

    local function getOptionText(opt)
        return opt.name or opt.text or opt.title or opt.displayText
    end

    local function getOptionCallback(opt)
        return opt.onmousedown or opt.onSelect or opt.callback or opt.onClick
    end

    local function getOptionParams(opt)
        return opt.param or opt.params or opt.callbackParameters or opt.parameters or {}
    end

    local function isReservedFrameworkZBucket(optionText)
        if not optionText then return false end

        return optionText == "Interact"
            or optionText == "Inspect"
            or optionText == "Equip"
            or optionText == "Manage"
            or optionText == subMenuName
    end

    local function copyOptionState(sourceOption, targetOption)
        for key, value in pairs(sourceOption) do
            if key ~= "subOption" and key ~= "name" and key ~= "text" and key ~= "title" and key ~= "displayText"
                and key ~= "target" and key ~= "callback" and key ~= "callbackParameters" and key ~= "param"
                and key ~= "params" and key ~= "parameters" and key ~= "onmousedown" and key ~= "onSelect"
                and key ~= "onClick" then
                targetOption[key] = value
            end
        end
    end

    local function migrateOptionList(sourceOptions, destinationMenu, visitedSubMenus)
        visitedSubMenus = visitedSubMenus or {}

        for _, sourceOption in ipairs(sourceOptions) do
            local optionText = getOptionText(sourceOption)
            local optionCallback = getOptionCallback(sourceOption)

            -- Preserve any real option we captured, even if it uses a different
            -- field shape than the FrameworkZ builders.
            if optionText and optionText ~= "" and not isReservedFrameworkZBucket(optionText) then
                local newOpt = destinationMenu:addOption(optionText, sourceOption.target, optionCallback, getOptionParams(sourceOption))
                copyOptionState(sourceOption, newOpt)

                local nestedSubMenu = sourceOption.subOption
                if nestedSubMenu then
                    local resolvedSubMenu = nestedSubMenu

                    if type(nestedSubMenu) ~= "table" and destinationMenu.getSubMenu then
                        resolvedSubMenu = destinationMenu:getSubMenu(nestedSubMenu)
                    end

                    if type(resolvedSubMenu) == "table" and resolvedSubMenu.options
                        and resolvedSubMenu ~= destinationMenu and resolvedSubMenu ~= subMenu and resolvedSubMenu ~= self.context
                        and not visitedSubMenus[resolvedSubMenu] then

                        visitedSubMenus[resolvedSubMenu] = true

                        local clonedSubMenu = destinationMenu:getNew(destinationMenu)
                        destinationMenu:addSubMenu(newOpt, clonedSubMenu)
                        migrateOptionList(resolvedSubMenu.options, clonedSubMenu, visitedSubMenus)

                        visitedSubMenus[resolvedSubMenu] = nil
                    end
                end
            end
        end
    end

    migrateOptionList(optionList, subMenu)
end

--! \brief Build all aggregated options for root and nested submenus.
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

--! \brief Get the root ISContextMenu.
function MenuManager:getContext()
    return self.context
end

--! \brief Lookup a submenu builder by name.
--! \param subMenuName \string Name of submenu to find.
--! \return \table|nil Submenu builder or nil.
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

--! \brief Construct a menu option descriptor.
--! \param text \string Display text.
--! \param target \table Callback target/self.
--! \param callback \function Function to execute.
--! \param callbackParameters \table Optional parameters table.
--! \param addOnTop \boolean Whether to insert at top of menu.
--! \param useMultiple \boolean Whether to show count badge.
--! \param count \integer Count for multiple selection.
--! \return \table Options instance.
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

--! \brief Construct a container for grouped options.
--! \param uniqueID \string Aggregation key.
--! \return \table AggregatedOptions instance.
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

local function normalizeCallbackParams(parameters)
    if parameters == nil then
        return {}
    end

    if type(parameters) ~= "table" then
        return { parameters }
    end

    return parameters
end

--! \brief Builder that wraps an ISContextMenu for option aggregation.
--! \param menuManager \table Owning MenuManager.
--! \param context \table ISContextMenu being built.
--! \return \table ContextMenuBuilder instance.
function ContextMenuBuilder.new(menuManager, context)
    local self = setmetatable({}, ContextMenuBuilder)
    self.menuManager = menuManager
    self.context = context
    self.addedOptions = {}
    self.aggregatedOptions = {}
    self.subMenus = {}
    return self
end

--! \brief Get the underlying ISContextMenu.
function ContextMenuBuilder:getContext()
    return self.context
end

--! \brief Return the options added through this builder.
function ContextMenuBuilder:getOptions()
    return self.addedOptions
end

--! \brief Return the aggregated options table.
function ContextMenuBuilder:getAggregatedOptions()
    return self.aggregatedOptions
end

--! \brief Get owning MenuManager.
function ContextMenuBuilder:getMenuManager()
    return self.menuManager
end

--! \brief Add a basic option to the context menu.
--! \param name \string Display text.
--! \param target \table Callback target/self.
--! \param callback \function Callback.
--! \param parameters \table Optional parameters.
--! \param addOnTop \boolean Whether to add on top of menu.
--! \return \table The created option.
function ContextMenuBuilder:addOption(name, target, callback, parameters, addOnTop)
    local params = normalizeCallbackParams(parameters)
    local option
    if addOnTop then
        option = self.context:addOptionOnTop(name, target, callback, FrameworkZ.Utilities:Unpack(params))
    else
        option = self.context:addOption(name, target, callback, FrameworkZ.Utilities:Unpack(params))
    end

    -- Track added options for debugging
    table.insert(self.addedOptions, option)
    return option
end

--! \brief Add a submenu entry and return its builder.
--! \param name \string Submenu label.
--! \param addOnTop \boolean Whether to add on top of menu.
--! \param options \table Optional predefined option list.
--! \return \table The created menu option and submenu builder.
function ContextMenuBuilder:addSubMenu(name, addOnTop, options)
    -- Create a new context for the submenu
    local subMenu = self.context:getNew(self.context)
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

--! \brief Register an AggregatedOptions container for later building.
--! \param aggregatedOption \table AggregatedOptions instance.
function ContextMenuBuilder:addAggregatedOption(aggregatedOption)
    local uniqueID = aggregatedOption:getUniqueID()

    if not self.aggregatedOptions[uniqueID] then
        self.aggregatedOptions[uniqueID] = aggregatedOption
    end
end

--! \brief Convenience to add an aggregated option by ID.
--! \param uniqueID \string Aggregation key.
--! \param target \table Callback target/self.
--! \param text \string Display text.
--! \param callback \function Callback to invoke.
--! \param params \table Optional parameters.
--! \param addOnTop \boolean Whether to add on top of menu.
--! \param useMultiple \boolean Whether to append count indicator.
--! \param count \integer Count value.
function ContextMenuBuilder:addAggregatedOptionWithCallback(uniqueID, target, text, callback, params, addOnTop, useMultiple, count)
    local option = Options.new(text, target, callback, params, addOnTop, useMultiple, count)
    local aggregatedOption = AggregatedOptions.new(uniqueID)

    aggregatedOption:addOption(option)
    self:addAggregatedOption(aggregatedOption)
end

--! \brief Build and add all aggregated options to the context menu, then clear the queue.
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

                    local callback = function(target, ...)
                        option:getCallback()(target, ...)
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
