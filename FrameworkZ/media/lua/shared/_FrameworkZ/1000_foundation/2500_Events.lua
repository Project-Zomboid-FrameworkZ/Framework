
FrameworkZ = FrameworkZ or {}
local Events = Events
local fzFoundation = FrameworkZ.Foundation

function FrameworkZ.LoadGridsquare(square)
    fzFoundation:ExecuteAllHooks("LoadGridsquare", square)
end
Events.LoadGridsquare.Add(FrameworkZ.LoadGridsquare)
fzFoundation:AddAllHookHandlers("LoadGridsquare")

function FrameworkZ.OnClientCommand(module, command, isoPlayer, args)
    fzFoundation:ExecuteAllHooks("OnClientCommand", module, command, isoPlayer, args)
end
Events.OnClientCommand.Add(FrameworkZ.OnClientCommand)
fzFoundation:AddAllHookHandlers("OnClientCommand")

function FrameworkZ.OnConnected()
    fzFoundation:ExecuteAllHooks("OnConnected")
end
Events.OnConnected.Add(FrameworkZ.OnConnected)
fzFoundation:AddAllHookHandlers("OnConnected")

function FrameworkZ.OnCreatePlayer()
    fzFoundation:ExecuteAllHooks("OnCreatePlayer")
end
Events.OnCreatePlayer.Add(FrameworkZ.OnCreatePlayer)
fzFoundation:AddAllHookHandlers("OnCreatePlayer")

function FrameworkZ.OnDisconnect()
    fzFoundation:ExecuteAllHooks("OnDisconnect")
end
Events.OnDisconnect.Add(FrameworkZ.OnDisconnect)
fzFoundation:AddAllHookHandlers("OnDisconnect")

function FrameworkZ.OnFillInventoryObjectContextMenu(player, context, items)
    fzFoundation:ExecuteAllHooks("OnFillInventoryObjectContextMenu", player, context, items)
end
Events.OnFillInventoryObjectContextMenu.Add(FrameworkZ.OnFillInventoryObjectContextMenu)
fzFoundation:AddAllHookHandlers("OnFillInventoryObjectContextMenu")

function FrameworkZ.OnFillWorldObjectContextMenu(player, context, worldObjects, test)
    fzFoundation:ExecuteAllHooks("OnFillWorldObjectContextMenu", player, context, worldObjects, test)
end
Events.OnFillWorldObjectContextMenu.Add(FrameworkZ.OnFillWorldObjectContextMenu)
fzFoundation:AddAllHookHandlers("OnFillWorldObjectContextMenu")

function FrameworkZ.OnGameStart()
    fzFoundation:ExecuteAllHooks("OnGameStart")
end
Events.OnGameStart.Add(FrameworkZ.OnGameStart)
fzFoundation:AddAllHookHandlers("OnGameStart")

function FrameworkZ.OnInitGlobalModData()
    fzFoundation:ExecuteAllHooks("OnInitGlobalModData")
end
Events.OnInitGlobalModData.Add(FrameworkZ.OnInitGlobalModData)
fzFoundation:AddAllHookHandlers("OnInitGlobalModData")

function FrameworkZ.OnKeyStartPressed(key)
    fzFoundation:ExecuteAllHooks("OnKeyStartPressed", key)
end
Events.OnKeyStartPressed.Add(FrameworkZ.OnKeyStartPressed)
fzFoundation:AddAllHookHandlers("OnKeyStartPressed")

function FrameworkZ.OnMainMenuEnter()
    fzFoundation:ExecuteAllHooks("OnMainMenuEnter")
end
Events.OnMainMenuEnter.Add(FrameworkZ.OnMainMenuEnter)
fzFoundation:AddAllHookHandlers("OnMainMenuEnter")

function FrameworkZ.OnObjectLeftMouseButtonDown(object, x, y)
    fzFoundation:ExecuteAllHooks("OnObjectLeftMouseButtonDown", object, x, y)
end
Events.OnObjectLeftMouseButtonDown.Add(FrameworkZ.OnObjectLeftMouseButtonDown)
fzFoundation:AddAllHookHandlers("OnObjectLeftMouseButtonDown")

function FrameworkZ.OnPlayerDeath(player)
    fzFoundation:ExecuteAllHooks("OnPlayerDeath", player)
end
Events.OnPlayerDeath.Add(FrameworkZ.OnPlayerDeath)
fzFoundation:AddAllHookHandlers("OnPlayerDeath")

function FrameworkZ.OnPreFillInventoryObjectContextMenu(playerID, context, items)
    fzFoundation:ExecuteAllHooks("OnPreFillInventoryObjectContextMenu", playerID, context, items)
end
Events.OnPreFillInventoryObjectContextMenu.Add(FrameworkZ.OnPreFillInventoryObjectContextMenu)
fzFoundation:AddAllHookHandlers("OnPreFillInventoryObjectContextMenu")

function FrameworkZ.OnReceiveGlobalModData(key, data)
    fzFoundation:ExecuteAllHooks("OnReceiveGlobalModData", key, data)
end
Events.OnReceiveGlobalModData.Add(FrameworkZ.OnReceiveGlobalModData)
fzFoundation:AddAllHookHandlers("OnReceiveGlobalModData")
