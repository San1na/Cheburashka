-- 22
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

function ConfigSys:_manifestPath()
    return string.format("%s/_manifest%s", self.FolderName, self.FileExtension)
end

function ConfigSys:_readManifest()
    if not hasFS() then
        return {}
    end

    local path = self:_manifestPath()
    if not isfile(path) then
        return {}
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or typeof(decoded) ~= "table" then
        return {}
    end

    local out = {}
    local seen = {}
    for _, name in ipairs(decoded) do
        local clean = sanitizeName(name)
        if clean ~= "" and not seen[clean] then
            seen[clean] = true
            table.insert(out, clean)
        end
    end

    table.sort(out)
    return out
end

function ConfigSys:_writeManifest(list)
    local ok = ensureFolder(self.FolderName)
    if not ok then
        return false
    end

    local path = self:_manifestPath()
    writefile(path, HttpService:JSONEncode(list))
    return true
end

function ConfigSys:SaveConfig(configName, data)
    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        return false, err
    end

    local path, safeName = self:_buildPath(configName)
    local payload = serialize(data)
    local encoded = HttpService:JSONEncode(payload)
    writefile(path, encoded)

    local manifest = self:_readManifest()
    local exists = false
    for _, name in ipairs(manifest) do
        if name == safeName then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(manifest, safeName)
        table.sort(manifest)
        self:_writeManifest(manifest)
    end

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

    local _, safeName = self:_buildPath(configName)
    local manifest = self:_readManifest()
    local nextManifest = {}
    for _, name in ipairs(manifest) do
        if name ~= safeName then
            table.insert(nextManifest, name)
        end
    end
    self:_writeManifest(nextManifest)

    return true, path
end

function ConfigSys:ListConfigs()
    local seen = {}
    local out = {}

    for _, name in ipairs(self:_readManifest()) do
        if not seen[name] then
            seen[name] = true
            table.insert(out, name)
        end
    end

    if typeof(listfiles) == "function" then
        local ok, files = pcall(function()
            return listfiles(self.FolderName)
        end)

        if ok and typeof(files) == "table" then
            for _, filePath in ipairs(files) do
                local fileName = filePath:match("[^/\\]+$") or filePath
                if fileName:sub(-#self.FileExtension) == self.FileExtension then
                    local cfgName = fileName:sub(1, #fileName - #self.FileExtension)
                    if cfgName ~= "_manifest" and not seen[cfgName] then
                        seen[cfgName] = true
                        table.insert(out, cfgName)
                    end
                end
            end
        end
    end

    table.sort(out)

    -- Keep manifest synced so ListConfigs still works even if listfiles is blocked.
    self:_writeManifest(out)

    return out
end

return ConfigSys
