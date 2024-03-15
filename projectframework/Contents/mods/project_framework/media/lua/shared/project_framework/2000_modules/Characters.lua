--! \page globalVars Global Variables
--! \section Characters Characters
--! ProjectFramework.Characters\n
--! See Characters for the module on characters.\n\n
--! ProjectFramework.Characters.List\n
--! A list of all instanced characters in the game.

ProjectFramework = ProjectFramework or {}

--! \brief Characters module for ProjectFramework. Defines and interacts with CHARACTER object.
--! \class Characters
ProjectFramework.Characters = {}
ProjectFramework.Characters.__index = ProjectFramework.Characters
ProjectFramework.Characters.List = {}
ProjectFramework.Characters = ProjectFramework.Foundation:NewModule(ProjectFramework.Characters, "Characters")

--! \brief Character class for ProjectFramework.
--! \class CHARACTER
local CHARACTER = {}
CHARACTER.__index = CHARACTER

--! \brief Initialize a character.
--! \return \string username
function CHARACTER:Initialize()
	if not self.playerObj then return end
    
    local firstConnection = false
    local characterModData = self.playerObj:getModData()["PFW_CHAR"] or nil

    local inventory = ProjectFramework.Inventories:New(self.playerObj:getUsername())
    self.inventoryID = inventory:Initialize()
    self.inventory = inventory

    if not characterModData then
        firstConnection = true

        self.playerObj:getModData()["PFW_CHAR"] = {
            name = self.name or "Unknown",
            description = self.description or "No description available.",
            faction = self.faction or FACTION_CITIZEN,
            age = self.age or 20,
            heightFeet = self.heightFeet or 5,
            heightInches = self.heightInches or 10,
            eyeColor = self.eyeColor or "Brown",
            hairColor = self.hairColor or "Brown",
            physique = self.physique or "Average",
            weight = self.weight or "125",
            inventory = self.inventory.items or {},
            upgrades = {}
        }
        
        if isClient() then
            self.playerObj:transmitModData()
        end
    end

    if firstConnection then
        self:InitializeDefaultItems()
    end

    if isClient() then
        timer:Simple(5, function()
            self:ValidateCharacterData()
            sendClientCommand("PFW_CHARS", "initialize", {self.playerObj:getUsername()})
        end)
    end

    return ProjectFramework.Characters:Initialize(self.username, self)
end

--! \brief Destroy a character. This will remove the character from the list of characters and is usually called after a player has disconnected.
function CHARACTER:Destroy()
    if isClient() then
        sendClientCommand("PFW_CHARS", "destroy", {self.playerObj:getUsername()})
    end
    
    self.playerObj = nil
end

--! \brief Initialize the default items for a character based on their faction. Called when PFW_CHAR mod data is first created.
function CHARACTER:InitializeDefaultItems()
    local faction = ProjectFramework.Factions:GetFactionByID(self.faction)

    if faction then
        for k, v in pairs(faction.defaultItems) do
           self:GiveItems(k, v)
        end
    end
end

--! \brief Validate the character's data.
--! \return \boolean Whether or not any of the character's new data was initialized.
function CHARACTER:ValidateCharacterData()
    local characterModData = self.playerObj:getModData()["PFW_CHAR"]

    if not characterModData then return false end

    local initializedNewData = false

    if not characterModData.name then
        initializedNewData = true
        characterModData.name = self.name or "Unknown"
    end

    if not characterModData.description then
        initializedNewData = true
        characterModData.description = self.description or "No description available."
    end

    if not characterModData.faction then
        initializedNewData = true
        characterModData.faction = self.faction or FACTION_CITIZEN
    end

    if not characterModData.age then
        initializedNewData = true
        characterModData.age = self.age or 20
    end

    if not characterModData.heightFeet then
        initializedNewData = true
        characterModData.heightFeet = self.heightFeet or 5
    end

    if not characterModData.heightInches then
        initializedNewData = true
        characterModData.heightInches = self.heightInches or 10
    end

    if not characterModData.eyeColor then
        initializedNewData = true
        characterModData.eyeColor = self.eyeColor or "Brown"
    end

    if not characterModData.hairColor then
        initializedNewData = true
        characterModData.hairColor = self.hairColor or "Brown"
    end

    if not characterModData.physique then
        initializedNewData = true
        characterModData.physique = self.physique or "Average"
    end

    if not characterModData.weight then
        initializedNewData = true
        characterModData.weight = self.weight or "125"
    end

    if not characterModData.inventory then
        initializedNewData = true
        characterModData.inventory = self.inventory.items or {}
    end

    if not characterModData.upgrades then
        initializedNewData = true
        characterModData.upgrades = {}
    end

    if isClient() then
        self.playerObj:transmitModData()
    end

    self.name = characterModData.name
    self.description = characterModData.description
    self.faction = characterModData.faction
    self.age = characterModData.age
    self.heightFeet = characterModData.heightFeet
    self.heightInches = characterModData.heightInches
    self.eyeColor = characterModData.eyeColor
    self.hairColor = characterModData.hairColor
    self.physique = characterModData.physique
    self.upgrades = characterModData.upgrades

    return initializedNewData
end

--! \brief Set the age of the character.
--! \param age \integer The age of the character.
function CHARACTER:SetAge(age)
    self.age = age
    self.playerObj:getModData()["PFW_CHAR"].age = age
    self.playerObj:transmitModData()

    if isClient() then
        sendClientCommand("PFW_CHARS", "update", {self.playerObj:getUsername(), "age", age})
    end
end

--! \brief Set the description of the character.
--! \param description \string The description of the character's appearance.
function CHARACTER:SetDescription(description)
    self.description = description
    self.playerObj:getModData()["PFW_CHAR"].description = description
    self.playerObj:transmitModData()
    
    if isClient() then
        sendClientCommand("PFW_CHARS", "update", {self.playerObj:getUsername(), "description", description})
    end
end

--! \brief Set the faction of the character.
--! \param faction \string The ID of the faction to set on the character.
function CHARACTER:SetFaction(faction)
    self.faction = faction
    self.playerObj:getModData()["PFW_CHAR"].faction = faction
    self.playerObj:transmitModData()
    
    if isClient() then
        sendClientCommand("PFW_CHARS", "update", {self.playerObj:getUsername(), "faction", faction})
    end
end

--! \brief Set the name of the character.
--! \param name \string The new name for the character.
function CHARACTER:SetName(name)
    self.name = name
    self.playerObj:getModData()["PFW_CHAR"].name = name
    self.playerObj:transmitModData()
    
    if isClient() then
        sendClientCommand("PFW_CHARS", "update", {self.playerObj:getUsername(), "name", name})
    end
end

--! \brief Get the character's inventory.
--! \return \table The character's inventory object.
function CHARACTER:GetInventory()
    return ProjectFramework.Inventories:GetInventoryByID(self.inventoryID)
end

--! \brief Give a character items by the specified amount.
--! \param itemID \string The ID of the item to give.
--! \param amount \integer The amount of the item to give.
function CHARACTER:GiveItems(itemID, amount)
    for i = 1, amount do
        self:GiveItem(itemID)
    end
end

--! \brief Give a character an item.
--! \param itemID \string The ID of the item to give.
--! \return \boolean Whether or not the item was successfully given.
function CHARACTER:GiveItem(itemID)
    local inventory = self:GetInventory()
    local item = ProjectFramework.Items:GetItemByID(itemID)

    if inventory and item then
        local worldItem = self.playerObj:getInventory():AddItem(InventoryItemFactory.CreateItem(item.id))
        local instanceID = ProjectFramework.Items:AddInstance(item.id, worldItem)
        local itemData = {
            id = item.id,
            instanceID = instanceID,
            owner = self.playerObj:getUsername(),
            name = item.name or "Unknown",
            description = item.description or "No description available.",
            category = item.category or "Uncategorized",
            shouldConsume = item.shouldConsume or nil,
            useAction = item.useAction or nil,
            useTime = item.useTime or nil
        }

        worldItem:getModData()["ProjectFramework_Item"] = itemData
        inventory:AddItem(itemData)

        if isClient() then
            --worldItem:transmitModData() -- Only transmit when item is on ground?
        end

        return true
    end

    return false
end

--! \brief Take an item from a character's inventory.
--! \param itemID \string The ID of the item to take.
--! \return \boolean Whether or not the item was successfully taken.
function CHARACTER:TakeItem(itemID)
    local item = ProjectFramework.Items:GetItemByID(itemID)

    if item then
        local inventory = self.playerObj:getInventory()
        local worldItem = inventory:getFirstTypeRecurse(item.id)
        local instanceID = worldItem:getModData()["ProjectFramework_Item"].instanceID

        ProjectFramework.Items:RemoveInstance(item.id, instanceID)
        inventory:DoRemoveItem(worldItem)

        return true
    end

    return false
end

--! \brief Take an item from a character's inventory by its instance ID. Useful for taking a specific item from a stack.
--! \param itemID \string The ID of the item to take.
--! \param instanceID \integer The instance ID of the item to take.
--! \return \boolean Whether or not the item was successfully taken.
function CHARACTER:TakeItemByInstanceID(itemID, instanceID)
    local item = ProjectFramework.Items:GetItemByID(itemID)

    if item then
        local inventory = self.playerObj:getInventory()
        local worldItem = inventory:getFirstTypeRecurse(item.id) -- Search whole inventory for matching item instance ID or make an inventory module for more efficiency?

        ProjectFramework.Items:RemoveInstance(item.id, instanceID)
        inventory:DoRemoveItem(worldItem)

        return true
    end

    return false
end

--! \brief Checks if a character is a citizen.
--! \return \boolean Whether or not the character is a citizen.
function CHARACTER:IsCitizen()
    if not self.faction then return false end

    if self.faction == FACTION_CITIZEN then
        return true
    end
    
    return false
end

--! \brief Checks if a character is a combine.
--! \return \boolean Whether or not the character is a combine.
function CHARACTER:IsCombine()
    if not self.faction then return false end

    if self.faction == FACTION_CP then
        return true
    elseif self.faction == FACTION_OTA then
        return true
    elseif self.faction == FACTION_ADMINISTRATOR then
        return true
    end
    
    return false
end

--! \brief Create a new character object.
--! \param username \string The player's username as their ID.
--! \return \table The new character object.
function ProjectFramework.Characters:New(username)
    local object = {
        username = username
    }

    setmetatable(object, CHARACTER)

	return object
end

--! \brief Initialize a character.
--! \param username \string The player's username.
--! \param character \table The character's object data.
--! \return \string The username added to the list of characters.
function ProjectFramework.Characters:Initialize(username, character)
    self.List[username] = character

    return username
end

--! \brief Get a character by their ID (i.e. username).
--! \param username \string The player's username to get their character object with.
--! \return \table The character object from the list of characters.
function ProjectFramework.Characters:GetCharacterByID(username)
    local character = self.List[username] or nil
    
    return character
end

if isClient() then


    local showingTooltip = false
    local previousMouseX = 0
    local previousMouseY = 0
    local tooltipX = 0
    local tooltipY = 0
    local tooltipPlayer = nil
    local tooltip = {name = "", description = {}}

    function ProjectFramework.Characters:GetDescriptionLines(description)
        local lines = {}
        local line = ""
        local lineLength = 0
        local words = {}

        for word in string.gmatch(description, "%S+") do
            table.insert(words, word)
        end

        for i = 1, #words do
            local word = words[i]
            local wordLength = string.len(word)

            if lineLength + wordLength <= 30 then
                line = line .. " " .. word
                lineLength = lineLength + wordLength
            else
                table.insert(lines, line)
                line = word
                lineLength = wordLength
            end
        end

        table.insert(lines, line)

        return lines
    end

    function ProjectFramework.Characters.OnPreUIDraw()
        if tooltip then
            local y = tooltipY + getTextManager():getFontFromEnum(UIFont.Dialogue):getLineHeight()
            
            getTextManager():DrawStringCentre(UIFont.Dialogue, tooltipX, y, tooltip.name, 0.6, 0.5, 0.4, 0.75)

            for k, v in pairs(tooltip.description) do
                y = y + getTextManager():getFontFromEnum(UIFont.Dialogue):getLineHeight()
                getTextManager():DrawStringCentre(UIFont.Dialogue, tooltipX, y, v, 1, 1, 1, 0.75)
            end
        end
    end

    function ProjectFramework.Characters:CreateCharacterTick(player, tickTime)
        timer:Create("CharacterTick", tickTime, 0, function()
            local x = getMouseX()
            local y = getMouseY()

            if x ~= previousMouseX or y ~= previousMouseY then
                Events.OnPreUIDraw.Remove(ProjectFramework.Characters.OnPreUIDraw)
                
                showingTooltip = false
                tooltipPlayer = nil
                previousMouseX = x
                previousMouseY = y
            elseif showingTooltip == false then
                showingTooltip = true
                local player = getPlayer()

                if player then
                    local playerIndex = player:getPlayerNum()
                    local worldX = screenToIsoX(playerIndex, x, y, 0)
                    local worldY = screenToIsoY(playerIndex, x, y, 0)
                    local worldZ = player:getZ()
                    local square = getSquare(worldX, worldY, worldZ)

                    if square then
                        local playerOnSquare = square:getPlayer()

                        if playerOnSquare then
                            local playerOnSquareIndex = playerOnSquare:getPlayerNum()
                            tooltipX = isoToScreenX(playerOnSquareIndex, worldX, worldY, worldZ)
                            tooltipY = isoToScreenY(playerOnSquareIndex, worldX, worldY, worldZ)

                            tooltipPlayer = playerOnSquare
                            local character = ProjectFramework.Characters:GetCharacterByID(playerOnSquare:getUsername())
                            tooltip.name = character and character.name or "Invalid Character"
                            tooltip.description = ProjectFramework.Characters:GetDescriptionLines(character and character.description or "Invalid Description")


                            if tooltip then
                                Events.OnPreUIDraw.Add(ProjectFramework.Characters.OnPreUIDraw)
                            end
                        end
                    end
                end
            elseif showingTooltip == true then
                local player = getPlayer()

                if player then
                    local playerIndex = player:getPlayerNum()
                    local worldX = screenToIsoX(playerIndex, x, y, 0)
                    local worldY = screenToIsoY(playerIndex, x, y, 0)
                    local worldZ = player:getZ()
                    local square = getSquare(worldX, worldY, worldZ)

                    if square then
                        local playerOnSquare = square:getPlayer()

                        if playerOnSquare ~= tooltipPlayer then
                            Events.OnPreUIDraw.Remove(ProjectFramework.Characters.OnPreUIDraw)
                            showingTooltip = false
                            tooltipPlayer = nil
                        end
                    end
                end
            end
        end)
    end

    --! \brief Initializes a player's character after joining. Called by OnGameStart event hook.
    --! \return \string The username of the new character's player.
    function ProjectFramework.Characters:OnGameStart()
        local cell = getWorld():getCell()
        local x = cell:getMaxX()
        local y = cell:getMaxY()
        local z = 0
        local player = getPlayer()
        player:setInvincible(true)
        player:setInvisible(true)
        player:setGhostMode(true)
        player:setNoClip(true)
        player:setX(x)
        player:setY(y)
        player:setZ(z)
	    player:setLx(x)
	    player:setLy(y)
	    player:setLz(z)

        ProjectFramework.Characters:CreateCharacterTick(player, 1)

        local ui = PFW_Introduction:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), getPlayer())
        ui:initialise()
        ui:addToUIManager()

        timer:Simple(ProjectFramework.Config.InitializationDuration, function()
            local character = ProjectFramework.Characters:New(player:getUsername())

            character.playerObj = player
            
            return character:Initialize()
        end)
    end

    --! \brief Destroys a character and removes them from the character list after disconnecting. Called by OnDisconnect event hook.
    function ProjectFramework.Characters:OnDisconnect()
        print("OnDisconnect")
        
        local player = getPlayer()
        local username = player:getUsername()
        local character = ProjectFramework.Characters:GetCharacterByID(username)
        
        if character then
            character:Destroy()
            print("Character destroyed")
        end

        self.List[username] = nil
    end
end

if not isClient() then

    --! \brief Initialize a character called by OnServerStarted event hook.
    --! \param module \string
    --! \param command \string
    --! \param player \table Player object.
    --! \param args \string
    function ProjectFramework.Characters.OnClientCommand(module, command, player, args)
        if module == "PFW_CHARS" then
            if command == "initialize" then
                local username = args[1]
                local character = ProjectFramework.Characters:New(username)

                character.playerObj = player
                character:Initialize()
            elseif command == "destroy" then
                local username = args[1]
                local character = ProjectFramework.Characters:GetCharacterByID(username)

                if character then
                    character:Destroy()
                end

                ProjectFramework.Characters.List[username] = nil
            elseif command == "update" then
                local username = args[1]
                local field = args[2]
                local newData = args[3]

                ProjectFramework.Characters.List[username][field] = newData
            end
        end
    end
    Events.OnClientCommand.Add(ProjectFramework.Characters.OnClientCommand)
end
