local Events = Events

FrameworkZ = FrameworkZ or {}

function FrameworkZ.OnClientCommand(module, command, isoPlayer, args)
    FrameworkZ.Foundation.ExecuteAllHooks("OnClientCommand", module, command, isoPlayer, args)
end
Events.OnClientCommand.Add(FrameworkZ.OnClientCommand)
FrameworkZ.Foundation:AddAllHookHandlers("OnClientCommand")

function FrameworkZ.OnConnected()
    FrameworkZ.Foundation.ExecuteAllHooks("OnConnected")
end
Events.OnConnected.Add(FrameworkZ.OnConnected)
FrameworkZ.Foundation:AddAllHookHandlers("OnConnected")

function FrameworkZ.OnFillInventoryObjectContextMenu(player, context, items)
    FrameworkZ.Foundation.ExecuteAllHooks("OnFillInventoryObjectContextMenu", player, context, items)
end
Events.OnFillInventoryObjectContextMenu.Add(FrameworkZ.OnFillInventoryObjectContextMenu)
FrameworkZ.Foundation:AddAllHookHandlers("OnFillInventoryObjectContextMenu")

function FrameworkZ.OnInitGlobalModData()
    FrameworkZ.Foundation.ExecuteAllHooks("OnInitGlobalModData")
end
Events.OnInitGlobalModData.Add(FrameworkZ.OnInitGlobalModData)
FrameworkZ.Foundation:AddAllHookHandlers("OnInitGlobalModData")

function FrameworkZ.OnMainMenuEnter()
    FrameworkZ.Foundation.ExecuteAllHooks("OnMainMenuEnter")
end
Events.OnMainMenuEnter.Add(FrameworkZ.OnMainMenuEnter)

function FrameworkZ.OnPlayerDeath(player)
    FrameworkZ.Foundation.ExecuteAllHooks("OnPlayerDeath")
end
Events.OnPlayerDeath.Add(FrameworkZ.OnPlayerDeath)
FrameworkZ.Foundation:AddAllHookHandlers("OnPlayerDeath")

function FrameworkZ.OnGameStart()
    FrameworkZ.Foundation.ExecuteAllHooks("OnGameStart")
end
Events.OnGameStart.Add(FrameworkZ.OnGameStart)
FrameworkZ.Foundation:AddAllHookHandlers("OnGameStart")

function FrameworkZ.LoadGridsquare(square)
    FrameworkZ.Foundation.ExecuteAllHooks("LoadGridsquare")
end
Events.LoadGridsquare.Add(FrameworkZ.Foundation.LoadGridsquare)
FrameworkZ.Foundation:AddAllHookHandlers("LoadGridsquare")

function FrameworkZ.OnDisconnect()
    FrameworkZ.Foundation.ExecuteAllHooks("OnDisconnect")
end
Events.OnDisconnect.Add(FrameworkZ.OnDisconnect)
FrameworkZ.Foundation:AddAllHookHandlers("OnDisconnect")

function FrameworkZ.OnFillWorldObjectContextMenu(player, context, worldObjects, test)
    FrameworkZ.Foundation.ExecuteAllHooks("OnFillWorldObjectContextMenu", player, context, worldObjects, test)
end
Events.OnFillWorldObjectContextMenu.Add(FrameworkZ.OnFillWorldObjectContextMenu)
FrameworkZ.Foundation:AddAllHookHandlers("OnFillWorldObjectContextMenu")

function FrameworkZ.OnPreFillInventoryObjectContextMenu(playerID, context, items)
    FrameworkZ.Foundation.ExecuteAllHooks("OnPreFillInventoryObjectContextMenu", playerID, context, items)
end
Events.OnPreFillInventoryObjectContextMenu.Add(FrameworkZ.OnPreFillInventoryObjectContextMenu)
FrameworkZ.Foundation:AddAllHookHandlers("OnPreFillInventoryObjectContextMenu")

function FrameworkZ.OnReceiveGlobalModData(key, data)
    FrameworkZ.Foundation.ExecuteAllHooks("OnReceiveGlobalModData", key, data)
end
Events.OnReceiveGlobalModData.Add(FrameworkZ.OnReceiveGlobalModData)
FrameworkZ.Foundation:AddAllHookHandlers("OnReceiveGlobalModData")
