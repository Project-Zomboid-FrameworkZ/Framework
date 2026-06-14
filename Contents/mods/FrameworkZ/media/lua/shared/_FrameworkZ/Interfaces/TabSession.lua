FrameworkZ.UI.TabSession = FrameworkZ.UI.TabSession or {}
FrameworkZ.Interfaces:Register(FrameworkZ.UI.TabSession, "TabSession")

local PANEL_WIDTH = getCore():getScreenWidth() * 0.25
local PANEL_HEIGHT = getCore():getScreenHeight()
local PANEL_MARGIN_X = 20
local PANEL_MARGIN_Y = 20

function FrameworkZ.UI.TabSession:initialise()
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

    self.closeButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, PANEL_WIDTH - PANEL_MARGIN_X, PANEL_MARGIN_Y, "X", self, FrameworkZ.UI.TabPanel.onMenuSelect)
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
    self:addChild(self.playerListPanel)
    self:updatePlayerList()

    self.refreshButton = FrameworkZ.UserInterfaces:CreateHugeButton(self, 0, 0, "Refresh", self, FrameworkZ.UI.TabSession.onClickButton)
    self.refreshButton:setX(PANEL_WIDTH - self.refreshButton:getWidth() - PANEL_MARGIN_X)
    self.refreshButton:setY(PANEL_HEIGHT - self.refreshButton:getHeight() - PANEL_MARGIN_Y)
    self.refreshButton.internal = "REFRESH"

    -- Register panel with TabPanel
    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:registerPanel(self)
    end
end

if isServer() then
    function FrameworkZ.UI.TabSession.OnRequestPlayerList(data)
        local requester = data.isoPlayer if not requester then return end
        local requesterCharacter = FrameworkZ.Players:GetLoadedCharacterByID(requester:getUsername()) if not requesterCharacter then return end
        local characterList = {}
        local players = getOnlinePlayers()

        for i = 0, players:size() - 1 do
            local username = players:get(i):getUsername()
            local character = FrameworkZ.Players:GetLoadedCharacterByID(username)

            if character then
                local isRecognized = requesterCharacter:RecognizesCharacter(character) or requesterCharacter == character

                table.insert(characterList, {
                    name = isRecognized and character:GetName() or "Unknown",
                    description = isRecognized and character:GetDescription() or "Description Hidden",
                    faction = character:GetFaction(),
                    isRecognized = isRecognized,
                    username = username
                })
            end
        end

        return characterList
    end
    FrameworkZ.Foundation:Subscribe("FrameworkZ.UI.TabSession.OnRequestPlayerList", FrameworkZ.UI.TabSession.OnRequestPlayerList)
end

function FrameworkZ.UI.TabSession:updatePlayerList()
    if self.playerListPanel then
        -- Remove any children from previous render pass, including model previews.
        self.playerListPanel:clearChildren()
        self.playerListPanel:setYScroll(0)
        self.playerListPanel:setXScroll(0)
        self.playerListPanel:setScrollHeight(0)
        self.playerListPanel:setScrollChildren(true)
        self.playerListPanel.vscroll = nil
        self.playerListPanel.hscroll = nil
    end

    self.charactersByFaction = {}
    self.playerList = {}

    FrameworkZ.Foundation:SendFire(self.isoPlayer, "FrameworkZ.UI.TabSession.OnRequestPlayerList", function(data, characterList)
        for _, characterData in ipairs(characterList) do
            if not self.charactersByFaction[characterData.faction] then
                self.charactersByFaction[characterData.faction] = {}
            end

            table.insert(self.charactersByFaction[characterData.faction], {
                name = characterData.name,
                description = characterData.description,
                faction = characterData.faction,
                isRecognized = characterData.isRecognized,
                isoPlayer = characterData.isRecognized and getPlayerFromUsername(characterData.username) or nil,
                username = characterData.username
            })
        end

        self:populatePlayerList()
    end)
end

function FrameworkZ.UI.TabSession:populatePlayerList()
    --self.playerList = {}

    local FONT_NAME = UIFont.Large
    local FONT_DESCRIPTION = UIFont.Medium

    local xMargin = 10
    local yOffset = 10

    for faction, players in pairs(self.charactersByFaction) do
        self.playerList[faction] = {}
        self.playerList[faction]["factionLabel"] = FrameworkZ.Interfaces:CreateLabel({
            x = 10,
            y = yOffset,
            height = 20,
            text = faction,
            textColor = {r=1, g=0.84, b=0, a=1},
            font = FZ_FONT_LARGE,
            textAlign = "left",
            parent = self.playerListPanel
        })

        yOffset = yOffset + 30

        for _, player in ipairs(players) do
            self.playerList[faction][player.username] = player

            local nameHeight = getTextManager():MeasureStringY(FONT_NAME, player.name)
            local descriptionHeight = getTextManager():MeasureStringY(FONT_DESCRIPTION, player.description)
            local truncatedDescription = #player.description > 52 and string.sub(player.description, 1, 52) .. "..." or player.description
            local characterButtonWidthHeight = nameHeight + descriptionHeight

            -- Get the character to check if recognized
            --local playerCharacter = FrameworkZ.Players:GetLoadedCharacterByID(player.username)
            local isRecognized = player.isRecognized

            -- Create 3D character preview for recognized characters
            if isRecognized then
                self.playerList[faction][player.username]["previewModel"] = ISUI3DModel:new(xMargin, yOffset, characterButtonWidthHeight, characterButtonWidthHeight)
                self.playerList[faction][player.username]["previewModel"]:initialise()
                self.playerList[faction][player.username]["previewModel"]:instantiate()
                self.playerList[faction][player.username]["previewModel"]:setCharacter(player.isoPlayer)
                self.playerList[faction][player.username]["previewModel"]:setState("idle")
                self.playerList[faction][player.username]["previewModel"]:setDirection(IsoDirections.S)
                self.playerList[faction][player.username]["previewModel"]:setIsometric(false)
                self.playerList[faction][player.username]["previewModel"]:setZoom(20)
                self.playerList[faction][player.username]["previewModel"]:setXOffset(0)
                self.playerList[faction][player.username]["previewModel"]:setYOffset(-0.87)
                self.playerListPanel:addChild(self.playerList[faction][player.username]["previewModel"])
            end

            self.playerList[faction][player.username]["characterButton"] = FrameworkZ.Interfaces:CreateButton({
                x = xMargin,
                y = yOffset,
                width = characterButtonWidthHeight,
                height = characterButtonWidthHeight,
                backgroundColor = {r=0, g=0, b=0, a=0},
                hoverColor = {r=1, g=1, b=1, a=0.1},
                title = isRecognized and "" or "?",
                target = self,
                onClick = FrameworkZ.UI.TabSession.onClickButton,
                font = FZ_FONT_TITLE,
                parent = self.playerListPanel
            })
            self.playerList[faction][player.username]["characterButton"].internal = "INFO"
            self.playerList[faction][player.username]["characterButton"].characterUsername = player.username
            self.playerList[faction][player.username]["characterButton"].isRecognized = isRecognized
            local pingText = "Ping: N/A"
            local targetPlayer = getPlayerFromUsername(player.username)
            if targetPlayer then
                pingText = "Ping: " .. targetPlayer:getPing()
            end

            self.playerList[faction][player.username]["characterButton"].tooltip = FrameworkZ.Utilities:WordWrapText("Description: " .. player.description, 32, "\n") .. "\nSteam ID: " .. getSteamIDFromUsername(player.username) .. "\n" .. pingText

            local xPadding = self.playerList[faction][player.username]["characterButton"]:getWidth() + xMargin * 2

            self.playerList[faction][player.username]["characterLabel"] = FrameworkZ.Interfaces:CreateLabel({
                x = xPadding,
                y = yOffset,
                height = nameHeight,
                text = player.name,
                textColor = {r=1, g=1, b=1, a=1},
                font = FZ_FONT_LARGE,
                textAlign = "left",
                parent = self.playerListPanel
            })

            self.playerList[faction][player.username]["bottomDescription"] = FrameworkZ.Interfaces:CreateLabel({
                x = xPadding,
                y = yOffset + nameHeight,
                height = descriptionHeight,
                text = truncatedDescription,
                textColor = {r=0.75, g=0.75, b=0.75, a=1},
                font = FZ_FONT_MEDIUM,
                textAlign = "left",
                parent = self.playerListPanel
            })

            self.bottomDescription = self.playerList[faction][player.username]["bottomDescription"]

            yOffset = yOffset + 45
        end

        yOffset = yOffset + 10
    end

    if self.bottomDescription then
        self.playerListPanel:setScrollHeight(self.bottomDescription:getBottom() + 50) -- Not the best implementation with self.bottomDescription but it works
    end

    self.playerListPanel:addScrollBars()
    self.playerListPanel:setScrollChildren(true)
end

function FrameworkZ.UI.TabSession:onClickButton(button, x, y)
    if button.internal == "INFO" then
        print("Opening Character Info")
    elseif button.internal == "REFRESH" then
        self:updatePlayerList()
    end
end

function FrameworkZ.UI.TabSession:close(button, x, y)
    -- Unregister panel from TabPanel
    if FrameworkZ.UI.TabPanel.instance then
        FrameworkZ.UI.TabPanel.instance:unregisterPanel(self)
    end

    self:setVisible(false)
    self:removeFromUIManager()
    FrameworkZ.UI.TabSession.instance = nil
end

function FrameworkZ.UI.TabSession:render()
    ISPanel.render(self)
end

function FrameworkZ.UI.TabSession:prerender()
    ISPanel.prerender(self)
end

function FrameworkZ.UI.TabSession:new(isoPlayer)
    if not FrameworkZ.UI.TabPanel.instance then return end
    local instance = FrameworkZ.UI.TabPanel.instance

    local o = ISPanel:new(instance:getX() + instance:getWidth(), instance:getY(), PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.15, g=0.15, b=0.15, a=0.9}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.isoPlayer = isoPlayer
    o.character = FrameworkZ.Players:GetLoadedCharacterByID(isoPlayer:getUsername())

    FrameworkZ.UI.TabSession.instance = o

    return o
end

return FrameworkZ.UI.TabSession
