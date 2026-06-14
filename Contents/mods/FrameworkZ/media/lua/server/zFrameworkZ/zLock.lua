if not isServer() then return end

if FrameworkZ.Config.Options.AdvancedConsole then
    local cfg  = FrameworkZ.Config.Options
    local sep1 = "+==============================================================+"
    local sep2 = "+--------------------------------------------------------------+"
    local function row(s)
        -- pad/trim s to exactly 60 chars and wrap in | |
        local padded = s .. string.rep(" ", 60 - #s)
        print("| " .. padded .. " |")
    end

    print(sep1)
    row("")
    row("           F R A M E W O R K Z")
    row("           Advanced Console Mode Active")
    row("")
    print(sep2)
    row("  Gamemode  :  " .. (cfg.GamemodeTitle or "No Gamemode Loaded"))
    row("  Version   :  " .. (cfg.Version or "?") .. "  (" .. (cfg.VersionType or "") .. ")")
    print(sep2)
    row("")
    row("  Console output has been redirected to a log file.")
    row("  Live output will NOT appear in this panel.")
    row("")
    row("  Log file  :  <Zomboid user dir>/Lua/frameworkz.txt")
    row("")
    row("  Commands  :  Type commands directly into this console.")
    row("               They will be intercepted and executed by FZ.")
    row("               Example:  /kick PlayerName Reason")
    row("")
    print(sep1)

    DebugLog.setStdOut(getFileOutput("frameworkz.txt"))
end

FrameworkZ = FrameworkZ:LoadAndLockObject(FrameworkZ)
