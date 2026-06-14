if not isServer() then return end
if not FrameworkZ.Config.Options.AdvancedConsole then return end

local STDOUT_FILE   = "frameworkz.txt"
local STDIN_PATTERN = 'command entered via server console %(System%.in%):%s*"(.-)"'

local stdoutFileLineCount = 0

local function pollCommandFile()
    local totalLines = 0
    local newLines   = {}

    -- Keep FileStdout active during the read so PZ's "command entered via
    -- server console" echo still lands in frameworkz.txt for detection.
    -- pcall guards against any stream errors without crashing the poller.
    pcall(function()
        local input = getFileInput(STDOUT_FILE)
        if not input then return end
        while true do
            local line = input:readLine()
            if line == nil then break end
            totalLines = totalLines + 1
            if totalLines > stdoutFileLineCount then
                table.insert(newLines, line)
            end
        end
        input:close()
    end)

    if #newLines > 0 then
        stdoutFileLineCount = totalLines

        for _, rawLine in ipairs(newLines) do
            local ln = rawLine:gsub("%z", ""):match("^%s*(.-)%s*$") or ""
            if ln ~= "" then
                local cmd = ln:match(STDIN_PATTERN)
                if cmd and cmd ~= "" then
                    local display = (cmd:sub(1,1) == "/" and cmd or ("/" .. cmd))
                    print("[FZ] COMMAND INTERCEPTED: " .. display)
                    local result = FrameworkZ.Commands:ProcessConsoleCommand(cmd)
                    print("[FZ] COMMAND DONE: " .. display .. " => " .. (result and "success" or "failure"))
                end
            end
        end
    end
end

FrameworkZ.Timers:Create("ConsolePoller", 1, 0, pollCommandFile)
