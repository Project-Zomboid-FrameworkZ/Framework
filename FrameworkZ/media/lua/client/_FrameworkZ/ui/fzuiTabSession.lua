local PANEL_WIDTH = getCore():getScreenWidth() * 0.25
local PANEL_HEIGHT = getCore():getScreenHeight()
local PANEL_MARGIN_X = 20
local PANEL_MARGIN_Y = 20

FrameworkZ.fzuiTabSession = ISPanel:derive("fzuiTabSession")

function FrameworkZ.fzuiTabSession:initialise()
    local TITLE_TEXT = "Session Characters"
    local FONT_TITLE = UIFont.Title
    local TITLE_WIDTH = getTextManager():MeasureStringX(FONT_TITLE, TITLE_TEXT)
    local TITLE_HEIGHT = getTextManager():MeasureStringY(FONT_TITLE, TITLE_TEXT)
    local TITLE_PADDING_TOP = 50
    local TITLE_PADDING_BOTTOM = 50
    local TITLE_X = (PANEL_WIDTH - TITLE_WIDTH) / 2
    local TITLE_Y = PANEL_MARGIN_Y + TITLE_PADDING_TOP

    ISPanel.initialise(self)
    self.charactersByFaction = {}

    self.titleLabel = ISLabel:new(TITLE_X, TITLE_Y, TITLE_HEIGHT, TITLE_TEXT, 1, 1, 1, 1, FONT_TITLE, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    self.closeButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_WIDTH - PANEL_MARGIN_X, PANEL_MARGIN_Y, "X", self, FrameworkZ.fzuiTabPanel.onMenuSelect)
    self.closeButton:setX(PANEL_WIDTH - self.closeButton:getWidth() - PANEL_MARGIN_X)
    self.closeButton.internal = "CLOSE"

    local yOffset = self.titleLabel:getY() + self.titleLabel:getHeight() + TITLE_PADDING_BOTTOM
    local REFRESH_TEXT_HEIGHT = getTextManager():MeasureStringY(FrameworkZ.UserInterfaces.ButtonTheme.hugeButtonFontSize, "Refresh")
    local SESSION_CHARACTERS_WIDTH = PANEL_WIDTH - PANEL_MARGIN_X * 2
    local SESSION_CHARACTERS_HEIGHT = PANEL_HEIGHT - yOffset - PANEL_MARGIN_Y * 2 - REFRESH_TEXT_HEIGHT

    self.playerListPanel = ISPanel:new(PANEL_MARGIN_X, yOffset, SESSION_CHARACTERS_WIDTH, SESSION_CHARACTERS_HEIGHT)
    self.playerListPanel.backgroundColor = {r=0, g=0, b=0, a=0}

    self.playerListPanel.onMouseWheel = function(self2, del)
        self2:setYScroll(self2:getYScroll() - del * 16)
        return true
    end

    self.playerListPanel.prerender = function(self2)
        self:setStencilRect(self2:getX(), self2:getY(), self2:getWidth(), self2:getHeight())
        ISPanel.prerender(self2)
    end

    self.playerListPanel.render = function(self2)
        ISPanel.render(self2)
        self2:clearStencilRect()
    end

    self.playerListPanel:initialise()
    self.playerListPanel:instantiate()
    self:updatePlayerList()
    self.playerListPanel:setScrollHeight(self.bottomDescription:getBottom() + 50) -- Not the best implementation with self.bottomDescription but it works
    self.playerListPanel:addScrollBars()
    self.playerListPanel:setScrollChildren(true)
    self:addChild(self.playerListPanel)

    self.refreshButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, 0, 0, "Refresh", self, FrameworkZ.fzuiTabPanel.onMenuSelect)
    self.refreshButton:setX(PANEL_WIDTH - self.refreshButton:getWidth() - PANEL_MARGIN_X)
    self.refreshButton:setY(PANEL_HEIGHT - self.refreshButton:getHeight() - PANEL_MARGIN_Y)
    self.refreshButton.internal = "REFRESH"
end

function FrameworkZ.fzuiTabSession:updatePlayerList()
    self.charactersByFaction = {}
    local players = getOnlinePlayers()

    for i = 0, players:size() - 1 do
        local username = players:get(i):getUsername()
        local character = FrameworkZ.Players:GetLoadedCharacterByID(username)

        if character then
            local faction = character:GetFaction() or "Unaffiliated"
            local name, description = self:getCharacterInfo(character)

            if not self.charactersByFaction[faction] then
                self.charactersByFaction[faction] = {}
            end

            table.insert(self.charactersByFaction[faction], {name = name, description = description, username = username})
        end
    end

    self:populatePlayerList()
end

function FrameworkZ.fzuiTabSession:getCharacterInfo(character)
    if self.character:RecognizesCharacter(character) or self.character == character then
        return character:GetName(), character:GetDescription()
    else
        return "Unknown", "Description Hidden"
    end
end

function FrameworkZ.fzuiTabSession:populatePlayerList()
    local FONT_BUTTON = UIFont.Title
    local FONT_FACTION = UIFont.Title
    local FONT_NAME = UIFont.Large
    local FONT_DESCRIPTION = UIFont.Medium

    local xMargin = 10
    local yOffset = 10

    self.playerListPanel:clearChildren()

    for faction, players in pairs(self.charactersByFaction) do
        local factionLabel = ISLabel:new(10, yOffset, 20, faction, 1, 0.84, 0, 1, FONT_FACTION, true)
        factionLabel:initialise()
        self.playerListPanel:addChild(factionLabel)

        yOffset = yOffset + 30

        for _, player in ipairs(players) do
            local nameHeight = getTextManager():MeasureStringY(FONT_NAME, player.name)
            local descriptionHeight = getTextManager():MeasureStringY(FONT_DESCRIPTION, player.description)
            local truncatedDescription = #player.description > 52 and string.sub(player.description, 1, 52) .. "..." or player.description
            local characterButtonWidthHeight = nameHeight + descriptionHeight

            local characterButton = ISButton:new(xMargin, yOffset, characterButtonWidthHeight, characterButtonWidthHeight, "?", self, FrameworkZ.fzuiTabSession.onClickButton)
            characterButton.internal = "INFO" --player.username
            characterButton.font = FONT_BUTTON
            characterButton.tooltip = FrameworkZ.Utilities:WordWrapText("Description: " .. player.description, 32, "\n") .. "\nSteam ID: " .. getSteamIDFromUsername(player.username) .. "\nPing: " .. getPlayerFromUsername(player.username):getPing()
            characterButton:initialise()
            self.playerListPanel:addChild(characterButton)

            local xPadding = characterButton:getWidth() + xMargin * 2

            local characterLabel = ISLabel:new(xPadding, yOffset, nameHeight, player.name, 1, 1, 1, 1, FONT_NAME, true)
            characterLabel:initialise()
            self.playerListPanel:addChild(characterLabel)

            self.bottomDescription = ISLabel:new(xPadding, yOffset + nameHeight, descriptionHeight, truncatedDescription, 0.75, 0.75, 0.75, 1, FONT_DESCRIPTION, true) -- Not the best implementation with self.bottomDescription but it works
            self.bottomDescription:initialise()
            self.playerListPanel:addChild(self.bottomDescription)

            yOffset = yOffset + 45
        end

        yOffset = yOffset + 10
    end
end

function FrameworkZ.fzuiTabSession:onClickButton(button, x, y)
    if button.internal == "INFO" then
        print("Opening Character Info")
    elseif button.internal == "REFRESH" then
        FrameworkZ.fzuiTabSession.instance:updatePlayerList()
    end
end

function FrameworkZ.fzuiTabSession:onClose(button, x, y)
    self:setVisible(false)
    self:removeFromUIManager()
    FrameworkZ.fzuiTabSession.instance = nil
end

function FrameworkZ.fzuiTabSession:render()
    ISPanel.render(self)
end

function FrameworkZ.fzuiTabSession:prerender()
    ISPanel.prerender(self)
end

function FrameworkZ.fzuiTabSession:new(isoPlayer)
    if not FrameworkZ.fzuiTabPanel.instance then return end
    local instance = FrameworkZ.fzuiTabPanel.instance

    local o = ISPanel:new(instance:getX() + instance:getWidth(), instance:getY(), PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.isoPlayer = isoPlayer
    o.character = FrameworkZ.Players:GetLoadedCharacterByID(isoPlayer:getUsername())

    FrameworkZ.fzuiTabSession.instance = o

    return o
end

return FrameworkZ.fzuiTabSession
