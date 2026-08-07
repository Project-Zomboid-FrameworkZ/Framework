FrameworkZ.UI.TabDirectory = FrameworkZ.UI.TabDirectory or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.TabDirectory, "TabDirectory")

local PANEL_WIDTH = getCore():getScreenWidth() * 0.3  -- 30% width positioned after TabPanel
local PANEL_HEIGHT = getCore():getScreenHeight()
local PANEL_MARGIN_X = 20
local PANEL_MARGIN_Y = 20
local SIDEBAR_WIDTH = 140

-- Directory data structure stored at class level (populated by Directories module)
FrameworkZ.UI.TabDirectory.filesystem = {}
FrameworkZ.UI.TabDirectory.currentPath = {}  -- Breadcrumb navigation
FrameworkZ.UI.TabDirectory.selectedFile = nil

local DIR_HUGE_TEXT_COLOR = {r=1, g=1, b=1, a=1}
local DIR_HUGE_HOVER_COLOR = {r=1, g=0.84, b=0, a=1}

function FrameworkZ.UI.TabDirectory:new(isoPlayer)
    -- Calculate position: 20% of screen (after TabPanel which is 0-20%)
    local tabPanelWidth = getCore():getScreenWidth() * 0.2
    local tabPanelX = 0
    if FrameworkZ.UI.TabPanel and FrameworkZ.UI.TabPanel.instance then
        if FrameworkZ.UI.TabPanel.instance.getWidth then
            tabPanelWidth = FrameworkZ.UI.TabPanel.instance:getWidth()
        end
        if FrameworkZ.UI.TabPanel.instance.getX then
            tabPanelX = FrameworkZ.UI.TabPanel.instance:getX()
        end
    end
    local panelWidth = getCore():getScreenWidth() * 0.3
    local o = ISPanel:new(tabPanelX + tabPanelWidth, 0, panelWidth, getCore():getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.keepOnScreen = false
    o.moveWithMouse = false
    o.isoPlayer = isoPlayer
    
    return o
end

function FrameworkZ.UI.TabDirectory:createHugeButton(parent, x, y, text, onClick)
    local width = getTextManager():MeasureStringX(UIFont.Title, text)
    local height = getTextManager():MeasureStringY(UIFont.Title, text)

    local button = ISButton:new(x, y, width, height, text, self, onClick)
    button.font = UIFont.Title
    button.textColor = DIR_HUGE_TEXT_COLOR
    button:setDisplayBackground(false)

    button.oldOnMouseMove = button.onMouseMove
    button.onMouseMove = function(bx, by)
        if button.oldOnMouseMove then
            button.oldOnMouseMove(bx, by)
        end
        if button.mouseOver then
            button.textColor = DIR_HUGE_HOVER_COLOR
        end
    end

    button.oldOnMouseMoveOutside = button.onMouseMoveOutside
    button.onMouseMoveOutside = function(bx, by)
        if button.oldOnMouseMoveOutside then
            button.oldOnMouseMoveOutside(bx, by)
        end
        if not button.mouseOver then
            button.textColor = DIR_HUGE_TEXT_COLOR
        end
    end

    button:initialise()
    if parent and parent.addChild then
        parent:addChild(button)
    end

    return button
end

function FrameworkZ.UI.TabDirectory:initialise()
    local TITLE_TEXT = "Directory"
    local FONT_TITLE = UIFont.Title
    local TITLE_WIDTH = getTextManager():MeasureStringX(FONT_TITLE, TITLE_TEXT)
    local TITLE_HEIGHT = getTextManager():MeasureStringY(FONT_TITLE, TITLE_TEXT)
    local TITLE_PADDING_TOP = 50
    local TITLE_PADDING_BOTTOM = 30
    local TITLE_X = (self:getWidth() - TITLE_WIDTH) / 2
    local TITLE_Y = PANEL_MARGIN_Y + TITLE_PADDING_TOP

    ISPanel.initialise(self)

    self.titleLabel = ISLabel:new(TITLE_X, TITLE_Y, TITLE_HEIGHT, TITLE_TEXT, 1, 1, 1, 1, FONT_TITLE, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.closeButton = self:createHugeButton(self, self:getWidth() - PANEL_MARGIN_X, PANEL_MARGIN_Y, "X", FrameworkZ.UI.TabPanel.onMenuSelect)
    if self.closeButton then
        self.closeButton:setX(self:getWidth() - self.closeButton:getWidth() - PANEL_MARGIN_X)
        self.closeButton.internal = "CLOSE"
    end

    local yOffset = self.titleLabel:getY() + self.titleLabel:getHeight() + TITLE_PADDING_BOTTOM
    local closeButtonTextHeight = getTextManager():MeasureStringY(UIFont.Title, "Close")
    
    -- Split view: sidebar (folders) and content area (files/document)
    local availableHeight = self:getHeight() - yOffset - PANEL_MARGIN_Y * 2 - closeButtonTextHeight
    
    -- Calculate sidebar and content widths dynamically
    local usableWidth = self:getWidth() - (PANEL_MARGIN_X * 2)
    local sidebarWidth = math.floor(usableWidth * 0.4)  -- 40% sidebar
    local contentWidth = usableWidth - sidebarWidth - 10  -- 60% content with 10px gap
    
    -- Sidebar for folder navigation
    self.sidebarPanel = ISPanel:new(PANEL_MARGIN_X, yOffset, sidebarWidth, availableHeight)
    self.sidebarPanel.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.8}
    self.sidebarPanel.borderColor = {r=0.4, g=0.4, b=0.4, a=0.5}

    self.sidebarPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end

    self.sidebarPanel.prerender = function(self2)
        self:setStencilRect(self2:getX(), self2:getY(), self2:getWidth(), self2:getHeight())
        ISPanel.prerender(self2)
    end

    self.sidebarPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end

    self.sidebarPanel:initialise()
    self.sidebarPanel:instantiate()
    self.sidebarPanel:addScrollBars()
    self.sidebarPanel:setScrollChildren(true)
    self:addChild(self.sidebarPanel)

    -- Content area for displaying files and document content
    local contentX = PANEL_MARGIN_X + sidebarWidth + 10
    
    self.contentPanel = ISPanel:new(contentX, yOffset, contentWidth, availableHeight)
    self.contentPanel.backgroundColor = {r=0, g=0, b=0, a=0}

    self.contentPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end

    self.contentPanel.prerender = function(self2)
        self:setStencilRect(self2:getX(), self2:getY(), self2:getWidth(), self2:getHeight())
        ISPanel.prerender(self2)
    end

    self.contentPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end

    self.contentPanel:initialise()
    self.contentPanel:instantiate()
    self.contentPanel:addScrollBars()
    self.contentPanel:setScrollChildren(true)
    self:addChild(self.contentPanel)

    -- Close button at bottom
    self.closeButton2 = self:createHugeButton(self, 0, 0, "Close", FrameworkZ.UI.TabPanel.onMenuSelect)
    if self.closeButton2 then
        self.closeButton2:setX(self:getWidth() - self.closeButton2:getWidth() - PANEL_MARGIN_X)
        self.closeButton2:setY(self:getHeight() - self.closeButton2:getHeight() - PANEL_MARGIN_Y)
        self.closeButton2.internal = "CLOSE"
    end

    -- Populate sidebar and initial content
    self:populateSidebar()
    
    -- Ensure filesystem has content - if empty, populate now
    local filesystemEmpty = true
    for _ in pairs(FrameworkZ.UI.TabDirectory.filesystem) do
        filesystemEmpty = false
        break
    end
    if filesystemEmpty then
        -- Filesystem is empty, try to populate it manually
        if FrameworkZ.Directories and FrameworkZ.Directories.InitializeDirectoryStructure then
            FrameworkZ.Directories:InitializeDirectoryStructure()
            self:populateSidebar()
        end
    end
    
    -- Default content area
    self:showEmptyContent()

    -- Register panel with TabPanel
    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:registerPanel(self)
    end
end

function FrameworkZ.UI.TabDirectory:populateSidebar()
    self.sidebarPanel:clearChildren()

    local yOffset = 8
    local filesystem = FrameworkZ.UI.TabDirectory.filesystem

    -- Root label inside sidebar
    local rootLabel = ISLabel:new(6, yOffset, 20, "Root", 1, 1, 1, 1, UIFont.Small, true)
    rootLabel:initialise()
    self.sidebarPanel:addChild(rootLabel)
    yOffset = yOffset + 22
    
    -- Debug: check if filesystem has content
    local folderCount = 0
    for name, contents in pairs(filesystem) do
        if type(contents) == "table" and contents._isFolder then
            folderCount = folderCount + 1
        end
    end

    -- Render folder structure
    self:renderFolderTree(self.sidebarPanel, filesystem, yOffset)
end

function FrameworkZ.UI.TabDirectory:refreshSidebar()
    self:populateSidebar()
end

function FrameworkZ.UI.TabDirectory:renderFolderTree(parent, folderTable, yOffset, indent)
    indent = indent or 0
    local rowHeight = 20
    local toggleSize = 16
    local indentWidth = 14
    local rowPaddingX = 6

    for name, contents in pairs(folderTable) do
        if type(contents) == "table" and contents._isFolder then
            local baseX = indent * indentWidth
            local toggleText = contents._expanded and "-" or "+"

            local rowPanel = ISPanel:new(rowPaddingX, yOffset, parent:getWidth() - (rowPaddingX * 2), rowHeight)
            rowPanel:initialise()
            rowPanel.backgroundColor = {r=0, g=0, b=0, a=0}
            rowPanel.borderColor = {r=0, g=0, b=0, a=0}
            rowPanel._hovered = false
            rowPanel.onMouseDown = function()
                self:openFolder(name, contents)
            end
            rowPanel.onMouseMove = function(self2)
                self2._hovered = true
                return true
            end
            rowPanel.onMouseMoveOutside = function(self2)
                self2._hovered = false
                return true
            end
            rowPanel.render = function(self2)
                ISPanel.render(self2)
                if self2._hovered then
                    self2:drawRect(0, 0, self2:getWidth(), self2:getHeight(), 0.18, 0.2, 0.2, 0.2)
                end
                local boxX = baseX
                self2:drawRect(boxX, 1, toggleSize, toggleSize, 0.7, 0.08, 0.08, 0.08)
                self2:drawRectBorder(boxX, 1, toggleSize, toggleSize, 0.8, 0.6, 0.6, 0.6)

                local tm = getTextManager()
                local signW = tm:MeasureStringX(UIFont.Small, toggleText)
                local signX = boxX + math.floor((toggleSize - signW) / 2)
                self2:drawText(toggleText, signX, 1, 1, 1, 1, 1, UIFont.Small)

                local nameX = boxX + toggleSize + 6
                self2:drawText(name, nameX, 1, 1, 1, 1, 1, UIFont.Small)
            end
            parent:addChild(rowPanel)

            yOffset = yOffset + rowHeight + 4

            if contents._expanded then
                for childName, childContents in pairs(contents) do
                    if childName ~= "_isFolder" and childName ~= "_expanded" and childName ~= "_metadata" then
                        if type(childContents) == "table" and childContents._isFolder then
                            yOffset = self:renderFolderTree(parent, {[childName] = childContents}, yOffset, indent + 1)
                        elseif type(childContents) == "table" and childContents._isFile then
                            local fileIndent = (indent + 1) * indentWidth
                            local fileRow = ISPanel:new(rowPaddingX, yOffset, parent:getWidth() - (rowPaddingX * 2), rowHeight)
                            fileRow:initialise()
                            fileRow.backgroundColor = {r=0, g=0, b=0, a=0}
                            fileRow.borderColor = {r=0, g=0, b=0, a=0}
                            fileRow._hovered = false
                            fileRow.onMouseDown = function()
                                self:openFile(childName, childContents)
                            end
                            fileRow.onMouseMove = function(self2)
                                self2._hovered = true
                                return true
                            end
                            fileRow.onMouseMoveOutside = function(self2)
                                self2._hovered = false
                                return true
                            end
                            fileRow.render = function(self2)
                                ISPanel.render(self2)
                                if self2._hovered then
                                    self2:drawRect(0, 0, self2:getWidth(), self2:getHeight(), 0.14, 0.2, 0.2, 0.2)
                                end
                                local textX = fileIndent + toggleSize + 6
                                self2:drawText("- " .. childName, textX, 1, 0.9, 0.9, 0.9, 1, UIFont.Small)
                            end
                            parent:addChild(fileRow)
                            yOffset = yOffset + rowHeight + 2
                        end
                    end
                end
            end
        end
    end

    parent:setScrollHeight(yOffset + 30)
    return yOffset
end

function FrameworkZ.UI.TabDirectory:openFolder(folderName, folderContents)
    -- Toggle folder expansion
    folderContents._expanded = not folderContents._expanded
    self:populateSidebar()
end

function FrameworkZ.UI.TabDirectory:showEmptyContent()
    self.contentPanel:clearChildren()

    local label = ISLabel:new(10, 10, 20, "Select a file from the left to view its contents.", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    label:initialise()
    self.contentPanel:addChild(label)

    self.contentPanel:setScrollHeight(40)
    self.contentPanel:addScrollBars()
    self.contentPanel:setScrollChildren(true)
end

function FrameworkZ.UI.TabDirectory:normalizeBulletText(text)
    if type(text) ~= "string" then
        return text
    end
    return text:gsub("^%s*•%s*", "- ")
end

function FrameworkZ.UI.TabDirectory:getContentWrapWidth(panel)
    local scrollbarPadding = 18
    local horizontalPadding = 20
    return panel:getWidth() - horizontalPadding - scrollbarPadding
end

function FrameworkZ.UI.TabDirectory:wrapText(text, font, maxWidth)
    local lines = {}
    if not text or text == "" then
        table.insert(lines, "")
        return lines
    end

    local tm = getTextManager()
    for paragraph in string.gmatch(text, "[^\n]+") do
        local words = {}
        for word in string.gmatch(paragraph, "%S+") do
            table.insert(words, word)
        end

        local current = ""
        for i = 1, #words do
            local word = words[i]
            local test = current == "" and word or (current .. " " .. word)
            local width = tm:MeasureStringX(font, test)

            if width <= maxWidth then
                current = test
            else
                if current ~= "" then
                    table.insert(lines, current)
                    current = ""
                end

                if tm:MeasureStringX(font, word) <= maxWidth then
                    current = word
                else
                    local chunk = ""
                    for ch in word:gmatch(".") do
                        local testChunk = chunk .. ch
                        if tm:MeasureStringX(font, testChunk) > maxWidth then
                            if chunk ~= "" then
                                table.insert(lines, chunk)
                            end
                            chunk = ch
                        else
                            chunk = testChunk
                        end
                    end
                    if chunk ~= "" then
                        current = chunk
                    end
                end
            end
        end

        if current ~= "" then
            table.insert(lines, current)
        end
    end

    return lines
end

function FrameworkZ.UI.TabDirectory:displayFolderContents(folderName, folderContents)
    -- Clear content panel
    self.contentPanel:clearChildren()

    local yOffset = 10
    
    -- Folder title
    local folderTitle = ISLabel:new(10, yOffset, 30, "Folder: " .. folderName, 1, 1, 1, 1, UIFont.Large, true)
    folderTitle:initialise()
    self.contentPanel:addChild(folderTitle)
    yOffset = yOffset + 40

    -- List files and subfolders
    for name, contents in pairs(folderContents) do
        if name ~= "_isFolder" and name ~= "_expanded" and name ~= "_metadata" then
            if type(contents) == "table" and contents._isFolder then
                -- Subfolder
                local subfolderButton = FrameworkZ.Interfaces:CreateButton({
                    x = 10,
                    y = yOffset,
                    width = 200,
                    height = 25,
                    title = "📁 " .. name .. "/",
                    target = self,
                    onClick = function()
                        self:openFolder(name, contents)
                    end,
                    parent = self.contentPanel
                })
                yOffset = yOffset + 30
            else
                -- File
                local fileButton = FrameworkZ.Interfaces:CreateButton({
                    x = 10,
                    y = yOffset,
                    width = 200,
                    height = 25,
                    title = "📄 " .. name,
                    target = self,
                    onClick = function()
                        self:openFile(name, contents)
                    end,
                    parent = self.contentPanel
                })
                yOffset = yOffset + 30
            end
        end
    end

    self.contentPanel:setScrollHeight(yOffset + 50)
end

function FrameworkZ.UI.TabDirectory:openFile(fileName, fileContent)
    -- Clear content panel
    self.contentPanel:clearChildren()

    local yOffset = 10

    -- File title
    local fileTitle = ISLabel:new(10, yOffset, 30, "File: " .. fileName, 0.94, 0.83, 0.24, 1, UIFont.Large, true)
    fileTitle:initialise()
    self.contentPanel:addChild(fileTitle)
    yOffset = yOffset + 40

    -- Render formatted content
    if type(fileContent) == "table" and fileContent._isFile then
        yOffset = self:renderFormattedContent(self.contentPanel, fileContent.content or {}, yOffset)
    else
        -- Plain text fallback
        local wrapWidth = self:getContentWrapWidth(self.contentPanel)
        local lineHeight = getTextManager():MeasureStringY(UIFont.Small, "A")
        local text = self:normalizeBulletText(tostring(fileContent))
        local lines = self:wrapText(text, UIFont.Small, wrapWidth)
        for _, line in ipairs(lines) do
            local textLabel = ISLabel:new(10, yOffset, lineHeight, line, 1, 1, 1, 1, UIFont.Small, true)
            textLabel:initialise()
            self.contentPanel:addChild(textLabel)
            yOffset = yOffset + lineHeight + 2
        end
    end

    self.contentPanel:setScrollHeight(yOffset + 50)
    self.contentPanel:addScrollBars()
    self.contentPanel:setScrollChildren(true)
end

function FrameworkZ.UI.TabDirectory:renderFormattedContent(parent, contentTable, yOffset)
    local baseLineHeight = getTextManager():MeasureStringY(UIFont.Small, "A")
    local maxWidth = self:getContentWrapWidth(parent)

    for _, element in ipairs(contentTable) do
        if type(element) == "table" then
            local elementType = element.type or "text"
            local text = self:normalizeBulletText(element.text or "")
            local color = element.color or {r=1, g=1, b=1, a=1}
            local font = element.font or UIFont.Small
            local lineHeight = baseLineHeight

            if elementType == "header" then
                font = UIFont.Large
                color = {r=0.94, g=0.83, b=0.24, a=1}
                lineHeight = getTextManager():MeasureStringY(font, "A")
            elseif elementType == "subheader" then
                font = UIFont.Medium
                color = {r=0.90, g=0.88, b=0.80, a=1}
                lineHeight = getTextManager():MeasureStringY(font, "A")
            elseif elementType == "bold" then
                color = {r=1, g=1, b=1, a=1}
                font = UIFont.Medium
                lineHeight = getTextManager():MeasureStringY(font, "A")
            elseif elementType == "italic" then
                -- Italics handled as style note
                color = {r=0.90, g=0.88, b=0.80, a=1}
            elseif elementType == "code" then
                color = {r=0.26, g=0.84, b=0.47, a=1}
                font = UIFont.Small
                lineHeight = baseLineHeight
            end

            -- Only render label if not a spacing element
            if elementType ~= "spacing" then
                local lines = self:wrapText(text, font, maxWidth)
                for _, line in ipairs(lines) do
                    local label = ISLabel:new(10, yOffset, lineHeight, line, color.r, color.g, color.b, color.a, font, true)
                    label:initialise()
                    parent:addChild(label)
                    yOffset = yOffset + lineHeight + 2
                end
            else
                -- Spacing element just adds vertical gap
                yOffset = yOffset + (element.height or 10)
            end
        else
            -- Plain text
            local text = self:normalizeBulletText(tostring(element))
            local lines = self:wrapText(text, UIFont.Small, maxWidth)
            for _, line in ipairs(lines) do
                local label = ISLabel:new(10, yOffset, baseLineHeight, line, 1, 1, 1, 1, UIFont.Small, true)
                label:initialise()
                parent:addChild(label)
                yOffset = yOffset + baseLineHeight + 2
            end
        end
    end

    return yOffset
end

-- Public API for adding files and folders

function FrameworkZ.UI.TabDirectory:AddFolder(path, folderName)
    local targetFolder = FrameworkZ.UI.TabDirectory:navigateToPath(path)
    if targetFolder then
        targetFolder[folderName] = {_isFolder = true, _expanded = false}
    else
        -- If path doesn't exist, create at root
        FrameworkZ.UI.TabDirectory.filesystem[folderName] = {_isFolder = true, _expanded = false}
    end
end

function FrameworkZ.UI.TabDirectory:AddFile(path, fileName, contentTable)
    local targetFolder = FrameworkZ.UI.TabDirectory:navigateToPath(path)
    if targetFolder then
        targetFolder[fileName] = {_isFile = true, content = contentTable}
    end
end

function FrameworkZ.UI.TabDirectory:navigateToPath(path)
    local current = FrameworkZ.UI.TabDirectory.filesystem
    if type(path) == "string" then
        path = {path}
    end
    for _, segment in ipairs(path) do
        if current[segment] then
            current = current[segment]
        else
            return nil
        end
    end
    return current
end

function FrameworkZ.UI.TabDirectory:close()
    -- Unregister from TabPanel
    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:unregisterPanel(self)
    end
    self:setVisible(false)
    self:removeFromUIManager()
    -- Clear instance reference so it can be recreated
    FrameworkZ.UI.TabDirectory.instance = nil
end

function FrameworkZ.UI.TabDirectory:onRender()
    ISPanel.onRender(self)
end

return FrameworkZ.UI.TabDirectory
