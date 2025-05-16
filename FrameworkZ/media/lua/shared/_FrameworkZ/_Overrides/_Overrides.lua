FrameworkZ = FrameworkZ or {}
FrameworkZ.Overrides = {}
FrameworkZ.Overrides = FrameworkZ.Foundation:NewModule(FrameworkZ.Overrides, "Overrides")

--[[function FrameworkZ.Overrides:Configure(foundation)
    foundation:RegisterModule(self)
end--]]