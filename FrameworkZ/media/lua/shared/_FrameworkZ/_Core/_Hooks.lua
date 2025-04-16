FrameworkZ = FrameworkZ or {}

--! \brief Hooks module for FrameworkZ. Adds functions to be called on certain events.
--! \class FrameworkZ.Hooks
FrameworkZ.Hooks = {}
FrameworkZ.Hooks = FrameworkZ.Foundation:NewModule(FrameworkZ.Hooks, "Hooks")

if isClient() then
    function FrameworkZ.Hooks:PreInitializeClient(isoPlayer)
        local username = isoPlayer:getUsername()

        FrameworkZ.Timers:Simple(0.1, function()
            if not VoiceManager:playerGetMute(username) then
                VoiceManager:playerSetMute(username)
            end
        end)

        isoPlayer:clearWornItems()
		isoPlayer:getInventory():clear()

        local gown = isoPlayer:getInventory():AddItem("Base.HospitalGown")
		isoPlayer:setWornItem(gown:getBodyLocation(), gown)

		local slippers = isoPlayer:getInventory():AddItem("Base.Shoes_Slippers")
		local color = Color.new(1, 1, 1, 1);
		slippers:setColor(color);
		slippers:getVisual():setTint(ImmutableColor.new(color));
		slippers:setCustomColor(true);
		isoPlayer:setWornItem(slippers:getBodyLocation(), slippers)

        isoPlayer:setGodMod(true)
        isoPlayer:setInvincible(true)
        isoPlayer:setHealth(1.0)

        local bodyParts = isoPlayer:getBodyDamage():getBodyParts()
        for i=1, bodyParts:size() do
            local bP = bodyParts:get(i-1)
            bP:RestoreToFullHealth();

            if bP:getStiffness() > 0 then
                bP:setStiffness(0)
                isoPlayer:getFitness():removeStiffnessValue(BodyPartType.ToString(bP:getType()))
            end
        end

        isoPlayer:setInvisible(true)
        isoPlayer:setGhostMode(true)
        isoPlayer:setNoClip(true)

        isoPlayer:setX(FrameworkZ.Config.LimboX)
        isoPlayer:setY(FrameworkZ.Config.LimboY)
        isoPlayer:setZ(FrameworkZ.Config.LimboZ)
        isoPlayer:setLx(FrameworkZ.Config.LimboX)
        isoPlayer:setLy(FrameworkZ.Config.LimboY)
        isoPlayer:setLz(FrameworkZ.Config.LimboZ)

        local ui = PFW_Introduction:new(0, 0, getCore():getScreenWidth(), getCore():getScreenHeight(), getPlayer())
        ui:initialise()
        ui:addToUIManager()
    end
end

if not isClient() then
    function FrameworkZ.Hooks.OnClientCommand(module, command, player, args)
        if module == "FZ_HOOKS" then
            if command == "initialize_client" then
                local onlineID = args.onlineID
                local isoPlayer = getPlayerByOnlineID(onlineID)

                isoPlayer:setGodMod(true)
                isoPlayer:setInvisible(true)
                isoPlayer:setGhostMode(true)
                isoPlayer:setNoClip(true)

                isoPlayer:setX(FrameworkZ.Config.LimboX)
                isoPlayer:setY(FrameworkZ.Config.LimboY)
                isoPlayer:setZ(FrameworkZ.Config.LimboZ)
                isoPlayer:setLx(FrameworkZ.Config.LimboX)
                isoPlayer:setLy(FrameworkZ.Config.LimboY)
                isoPlayer:setLz(FrameworkZ.Config.LimboZ)
            end
        end
    end
    Events.OnClientCommand.Add(FrameworkZ.Hooks.OnClientCommand)
end

FrameworkZ.Foundation:AddAllHookHandlers("PlayerTick")
FrameworkZ.Foundation:RegisterModule(FrameworkZ.Hooks)
FrameworkZ.Foundation:RegisterFramework()