if isClient() then return end

FrameworkZ = FrameworkZ or {}

--! \brief Loaders module for FrameworkZ. Loads server side files on a dedicated server.
--! \module FrameworkZ.Loaders
FrameworkZ.Loaders = {}
FrameworkZ.Loaders.List = {}
FrameworkZ.Loaders.Separator = getFileSeparator()

function FrameworkZ.Loaders:AddFile(file)
    self.List[file] = file
end

function FrameworkZ.Loaders:LoadFile(file)
    local reader = getFileReader(file, false)

    if not reader then
        print("[FZ] ERROR: Could not open server file: " .. file)
        return false, "Failed to load file: Could not open " .. file
    end

    local lines = {}

    while true do
        local line = reader:readLine()
        if line == nil then break end
        table.insert(lines, line)
    end

    reader:close()

    local source = table.concat(lines, "\n")
    local fn, err = loadstring(source, "@" .. file)

    if not fn then
        print("[FZ] ERROR compiling " .. file .. ": " .. tostring(err))
        return false, "Failed to load file: Could not compile " .. file .. " " .. tostring(err)
    end

    local context = "running " .. file

    if type(fn) ~= "function" then
        print("[FZ] ERROR " .. tostring(context) .. ": expected function, got " .. tostring(type(fn)))
        return false, "Failed to load file: " .. tostring(context) .. ": expected function, got " .. tostring(type(fn))
    end

    local ok, result = pcall(fn)

    if not ok then
        local resultText = tostring(result)

        if resultText:find("%[FZ%] ERROR", 1, true) then
            print(resultText)
        else
            print("[FZ] ERROR " .. tostring(context) .. ": " .. tostring(err))
        end

        return false, "Failed to load file: " .. tostring(context) .. ": " .. tostring(err)
    end

    return true, "File loaded successfully."
end

function FrameworkZ.Loaders:LoadAllFiles()
    for _, v in pairs(self.List) do
        self:LoadFIle(v)
    end
end

FrameworkZ.Foundation:RegisterModule(FrameworkZ.Loaders)
