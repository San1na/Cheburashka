local HttpService = game:GetService("HttpService")

local ConfigSys = {}
ConfigSys.__index = ConfigSys

local function hasFS()
    return typeof(isfolder) == "function"
        and typeof(makefolder) == "function"
        and typeof(isfile) == "function"
        and typeof(writefile) == "function"
        and typeof(readfile) == "function"
end

local function ensureFolder(folder)
    if not hasFS() then
        return false, "Executor filesystem is not available"
    end

    if not isfolder(folder) then
        makefolder(folder)
    end

    return true
end

local function sanitizeName(name)
    local clean = tostring(name or "default")
    clean = clean:gsub("[^%w_%-%s]", "_")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then
        clean = "default"
    end
    return clean
end

local function serialize(value)
    local t = typeof(value)

    if t == "Color3" then
        return {
            __type = "Color3",
            r = value.R,
            g = value.G,
            b = value.B,
        }
    end

    if t == "EnumItem" then
        return {
            __type = "EnumItem",
            enumType = tostring(value.EnumType):gsub("^Enum%.", ""),
            name = value.Name,
        }
    end

    if t == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = serialize(v)
        end
        return out
    end

    if t == "string" or t == "number" or t == "boolean" or t == "nil" then
        return value
    end

    return nil
end

local function deserialize(value)
    if typeof(value) ~= "table" then
        return value
    end

    if value.__type == "Color3" then
        return Color3.new(value.r, value.g, value.b)
    end

    if value.__type == "EnumItem" then
        local enumType = Enum[value.enumType]
        if enumType then
            return enumType[value.name]
        end
        return nil
    end

    local out = {}
    for k, v in pairs(value) do
        out[k] = deserialize(v)
    end
    return out
end

function ConfigSys.new(options)
    options = options or {}

    local self = setmetatable({}, ConfigSys)
    self.FolderName = sanitizeName(options.FolderName or "iOSMenuConfigs")
    self.FileExtension = options.FileExtension or ".json"

    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        warn("[configSys] " .. err)
    end

    return self
end

function ConfigSys:SetFolder(folderName)
    self.FolderName = sanitizeName(folderName)
    return ensureFolder(self.FolderName)
end

function ConfigSys:GetFolder()
    return self.FolderName
end

function ConfigSys:_buildPath(configName)
    local safe = sanitizeName(configName)
    return string.format("%s/%s%s", self.FolderName, safe, self.FileExtension), safe
end

function ConfigSys:SaveConfig(configName, data)
    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        return false, err
    end

    local path = self:_buildPath(configName)
    local payload = serialize(data)
    local encoded = HttpService:JSONEncode(payload)
    writefile(path, encoded)
    return true, path
end

function ConfigSys:LoadConfig(configName)
    if not hasFS() then
        return nil, "Executor filesystem is not available"
    end

    local path = self:_buildPath(configName)
    if not isfile(path) then
        return nil, "Config not found: " .. path
    end

    local raw = readfile(path)
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not ok then
        return nil, "Invalid JSON in config"
    end

    return deserialize(decoded), path
end

function ConfigSys:DeleteConfig(configName)
    if typeof(delfile) ~= "function" then
        return false, "delfile is not supported by this executor"
    end

    local path = self:_buildPath(configName)
    if not isfile(path) then
        return false, "Config not found"
    end

    delfile(path)
    return true, path
end

function ConfigSys:ListConfigs()
    if typeof(listfiles) ~= "function" then
        return {}
    end

    local ok, files = pcall(function()
        return listfiles(self.FolderName)
    end)
    if not ok then
        return {}
    end

    local out = {}
    for _, filePath in ipairs(files) do
        local fileName = filePath:match("[^/\\]+$") or filePath
        if fileName:sub(-#self.FileExtension) == self.FileExtension then
            table.insert(out, fileName:sub(1, #fileName - #self.FileExtension))
        end
    end
    table.sort(out)
    return out
end

return ConfigSys
