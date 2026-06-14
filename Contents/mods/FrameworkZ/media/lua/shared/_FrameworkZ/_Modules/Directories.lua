FrameworkZ.Directories = FrameworkZ.Directories or {}
FrameworkZ.Directories.__index = FrameworkZ.Directories
FrameworkZ.Directories = FrameworkZ.Foundation:NewModule(FrameworkZ.Directories, "Directories")

function FrameworkZ.Directories:PostInitializeClient()
    self:InitializeDirectoryStructure()
end

function FrameworkZ.Directories:InitializeDirectoryStructure()
    local TabDir = FrameworkZ.UI.TabDirectory
    
    -- Create FrameworkZ folder
    TabDir:AddFolder({}, "FrameworkZ")
    
    -- Add FrameworkZ/Info
    TabDir:AddFile(
        {"FrameworkZ"},
        "Info",
        {
            {type = "header", text = "FrameworkZ"},
            {type = "spacing", height = 10},
            {type = "subheader", text = "About"},
            {type = "text", text = "FrameworkZ is a comprehensive roleplay-centric Lua framework for Project Zomboid modifications."},
            {type = "subheader", text = "Version"},
            {type = "code", text = "Number: " .. FrameworkZ.Config:GetOption("Version")},
            {type = "code", text = "Type: " .. FrameworkZ.Config:GetOption("VersionType")},
        }
    )
    
    -- Add FrameworkZ/Plugins
    local pluginsFile = {
        {type = "header", text = "Installed Plugins"},
        {type = "spacing", height = 10},
        {type = "text", text = "The following plugins are currently registered in this FrameworkZ installation:"},
        {type = "spacing", height = 10},
    }

    local pluginList = self:GeneratePluginList()
    for _, item in ipairs(pluginList) do
        table.insert(pluginsFile, item)
    end

    table.insert(pluginsFile, {type = "spacing", height = 15})
    table.insert(pluginsFile, {type = "header", text = "Plugin Information Format"})
    table.insert(pluginsFile, {type = "code", text = "<Plugin Name>"})
    table.insert(pluginsFile, {type = "code", text = "<Plugin Description: What the plugin does>"})
    table.insert(pluginsFile, {type = "code", text = "| Author: <Creator name>"})
    table.insert(pluginsFile, {type = "code", text = "| Version: <Plugin version number>"})
    table.insert(pluginsFile, {type = "code", text = "| Compatibility: <FrameworkZ version number>"})

    TabDir:AddFile(
        {"FrameworkZ"},
        "Plugins",
        pluginsFile
    )
    
    -- Add FrameworkZ/Commands (placeholder for now)
    TabDir:AddFile(
        {"FrameworkZ"},
        "Commands",
        {
            {type = "header", text = "Framework Commands"},
            {type = "spacing", height = 10},
            {type = "subheader", text = "Command Syntax"},
            {type = "text", text = "/commandName <paramName: type> [optional: type]"},
            {type = "spacing", height = 15},
            {type = "subheader", text = "Type Reference"},
            {type = "code", text = "string - Text input"},
            {type = "code", text = "number - Integer or decimal"},
            {type = "code", text = "bool - true/false"},
            {type = "code", text = "player - Online player username"},
            {type = "code", text = "character - Saved character name"},
            {type = "spacing", height = 15},
            {type = "bold", text = "[Commands list placeholder - plugins populate this at runtime]"},
        }
    )
    
    -- Create Gamemode folder
    TabDir:AddFolder({}, "Gamemode")
    
    -- Add Gamemode/Guides (placeholder)
    TabDir:AddFile(
        {"Gamemode"},
        "Guides",
        {
            {type = "header", text = "Gamemode Guides"},
            {type = "spacing", height = 10},
            {type = "subheader", text = "Available Guides"},
            {type = "text", text = "Guides provide gameplay instructions, rules, and tutorials for the active gamemode."},
            {type = "spacing", height = 15},
            {type = "bold", text = "[Guides are populated by the active gamemode plugin]"},
            {type = "spacing", height = 10},
            {type = "italic", text = "Load a gamemode plugin to see available guides."},
        }
    )
end

function FrameworkZ.Directories:GeneratePluginList()
    local list = {}

    if not FrameworkZ.Plugins or not FrameworkZ.Plugins.RegisteredPlugins then
        return {
            {type = "italic", text = "[Plugin system not initialized]"}
        }
    end

    local names = {}
    for name, _ in pairs(FrameworkZ.Plugins.RegisteredPlugins) do
        table.insert(names, name)
    end

    table.sort(names)

    if #names == 0 then
        return {
            {type = "italic", text = "[No plugins registered]"}
        }
    end

    for _, name in ipairs(names) do
        local plugin = FrameworkZ.Plugins.RegisteredPlugins[name]
        local meta = plugin and plugin.Meta or {}

        local displayName = FrameworkZ.Utilities:StringIsEmpty(meta.Name) and "Unknown" or meta.Name
        local author = FrameworkZ.Utilities:StringIsEmpty(meta.Author) and "N/A" or meta.Author
        local version = FrameworkZ.Utilities:StringIsEmpty(meta.Version) and "N/A" or meta.Version
        local description = FrameworkZ.Utilities:StringIsEmpty(meta.Description) and "[No Description]" or meta.Description
        local compatibility = FrameworkZ.Utilities:StringIsEmpty(meta.Compatibility) and "N/A" or meta.Compatibility

        table.insert(list, {type = "subheader", text = displayName})
        if description ~= "" then
            table.insert(list, {type = "italic", text = description})
        end
        table.insert(list, {type = "code", text = "| Author: " .. author})
        table.insert(list, {type = "code", text = "| Version: " .. version})
        table.insert(list, {type = "code", text = "| Compatibility: " .. compatibility})
        table.insert(list, {type = "spacing", height = 6})
    end

    if #list > 0 and list[#list].type == "spacing" then
        table.remove(list, #list)
    end

    return list
end
