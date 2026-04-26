-- 44
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

local function serialize(value, visited)
    visited = visited or {}
    local t = typeof(value)

    if t == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    end

    if t == "EnumItem" then
        return {
            __type = "EnumItem",
            enumType = tostring(value.EnumType):gsub("^Enum%.", ""),
            name = value.Name,
        }
    end

    if t == "table" then
        if visited[value] then
            return nil
        end
        visited[value] = true

        local out = {}
        for k, v in pairs(value) do
            out[k] = serialize(v, visited)
        end

        visited[value] = nil
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
    self.MetaFileName = options.MetaFileName or "_meta"
    self.AutoLoadKey = options.AutoLoadKey or "autoload"
    self.LastUsedKey = options.LastUsedKey or "last_used"

    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        warn("[ConfigSys] " .. err)
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

function ConfigSys:_metaPath()
    return string.format("%s/%s%s", self.FolderName, self.MetaFileName, self.FileExtension)
end

function ConfigSys:_readJson(path)
    if not hasFS() or not isfile(path) then
        return nil
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok then
        return decoded
    end
    return nil
end

function ConfigSys:_writeJson(path, data)
    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        return false, err
    end

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not success then
        return false, "JSON encode failed"
    end

    local writeOk, writeErr = pcall(function()
        writefile(path, encoded)
    end)
    if not writeOk then
        return false, tostring(writeErr)
    end
    return true
end

function ConfigSys:_readManifest()
    local decoded = self:_readJson(self:_manifestPath())
    if typeof(decoded) ~= "table" then
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
    return self:_writeJson(self:_manifestPath(), list)
end

function ConfigSys:_readMeta()
    local decoded = self:_readJson(self:_metaPath())
    if typeof(decoded) ~= "table" then
        return {}
    end
    return decoded
end

function ConfigSys:_writeMeta(meta)
    return self:_writeJson(self:_metaPath(), meta)
end

function ConfigSys:SetMeta(key, value)
    local meta = self:_readMeta()
    meta[tostring(key)] = value
    return self:_writeMeta(meta)
end

function ConfigSys:GetMeta(key, defaultValue)
    local meta = self:_readMeta()
    local found = meta[tostring(key)]
    if found == nil then
        return defaultValue
    end
    return found
end

function ConfigSys:SaveConfig(configName, data)
    local ok, err = ensureFolder(self.FolderName)
    if not ok then
        return false, err
    end

    local path, safeName = self:_buildPath(configName)
    local payload = serialize(data)
    local success, writeErr = self:_writeJson(path, payload)
    if not success then
        return false, writeErr
    end

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
    end
    table.sort(manifest)
    self:_writeManifest(manifest)

    self:SetLastUsedConfig(safeName)
    return true, path
end

function ConfigSys:LoadConfig(configName)
    if not hasFS() then
        return nil, "Executor filesystem is not available"
    end

    local path, safeName = self:_buildPath(configName)
    if not isfile(path) then
        return nil, "Config not found: " .. path
    end

    local decoded = self:_readJson(path)
    if decoded == nil then
        return nil, "Invalid JSON in config"
    end

    self:SetLastUsedConfig(safeName)
    return deserialize(decoded), path
end

function ConfigSys:DeleteConfig(configName)
    if typeof(delfile) ~= "function" then
        return false, "delfile is not supported by this executor"
    end

    local path, safeName = self:_buildPath(configName)
    if not isfile(path) then
        return false, "Config not found"
    end

    delfile(path)

    local manifest = self:_readManifest()
    local nextManifest = {}
    for _, name in ipairs(manifest) do
        if name ~= safeName then
            table.insert(nextManifest, name)
        end
    end
    self:_writeManifest(nextManifest)

    local autoLoad = self:GetAutoLoadName(nil)
    if autoLoad == safeName then
        self:ClearAutoLoad()
    end

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

    local function collectName(rawName)
        local cfgName = sanitizeName(rawName)
        if cfgName ~= "" and cfgName ~= "_manifest" and cfgName ~= self.MetaFileName and not seen[cfgName] then
            seen[cfgName] = true
            table.insert(out, cfgName)
        end
    end

    local function collectFromFileList(files)
        if typeof(files) ~= "table" then
            return
        end

        for _, filePath in ipairs(files) do
            local fileName = filePath:match("[^/\\]+$") or filePath
            if fileName:sub(-#self.FileExtension) == self.FileExtension then
                local cfgName = fileName:sub(1, #fileName - #self.FileExtension)
                collectName(cfgName)
            end
        end
    end

    if typeof(listfiles) == "function" then
        local tried = {
            self.FolderName,
            self.FolderName .. "/",
            "./" .. self.FolderName,
            "./" .. self.FolderName .. "/",
        }

        for _, path in ipairs(tried) do
            local ok, files = pcall(function()
                return listfiles(path)
            end)
            if ok then
                collectFromFileList(files)
            end
        end

        local okRoot, rootFiles = pcall(function()
            return listfiles("")
        end)
        if okRoot and typeof(rootFiles) == "table" then
            local needleA = self.FolderName .. "/"
            local needleB = self.FolderName .. "\\"
            local filtered = {}
            for _, filePath in ipairs(rootFiles) do
                local normalized = tostring(filePath)
                if normalized:find(needleA, 1, true) or normalized:find(needleB, 1, true) then
                    table.insert(filtered, normalized)
                end
            end
            collectFromFileList(filtered)
        end
    end

    local autoName = self:GetAutoLoadName(nil)
    if autoName then
        local path = self:_buildPath(autoName)
        if hasFS() and isfile(path) then
            collectName(autoName)
        end
    end

    local lastUsed = self:GetLastUsedConfig(nil)
    if lastUsed then
        local path = self:_buildPath(lastUsed)
        if hasFS() and isfile(path) then
            collectName(lastUsed)
        end
    end

    table.sort(out)
    self:_writeManifest(out)
    return out
end

function ConfigSys:GetConfigNames()
    return self:ListConfigs()
end

function ConfigSys:SetAutoLoad(configName)
    return self:SetMeta(self.AutoLoadKey, sanitizeName(configName))
end

function ConfigSys:GetAutoLoadName(defaultValue)
    return self:GetMeta(self.AutoLoadKey, defaultValue)
end

function ConfigSys:ClearAutoLoad()
    return self:SetMeta(self.AutoLoadKey, nil)
end

function ConfigSys:LoadAutoLoad()
    local auto = self:GetAutoLoadName(nil)
    if not auto then
        return nil, "Autoload is not set"
    end
    return self:LoadConfig(auto)
end

function ConfigSys:SetLastUsedConfig(configName)
    return self:SetMeta(self.LastUsedKey, sanitizeName(configName))
end

function ConfigSys:GetLastUsedConfig(defaultValue)
    return self:GetMeta(self.LastUsedKey, defaultValue)
end

return ConfigSys
