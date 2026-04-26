-- 44
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Library = {}
Library.__index = Library

Library.Defaults = {
    Parent = nil,
    Keybind = Enum.KeyCode.RightShift,
    Width = 620,
    Height = 450,
    Draggable = true,
    CornerRadius = 8,
    AccentColor = Color3.fromRGB(0, 122, 255),
    SidebarColor = Color3.fromRGB(20, 20, 22),
    BackgroundColor = Color3.fromRGB(25, 25, 27),
    SurfaceColor = Color3.fromRGB(32, 32, 35),
    ItemColor = Color3.fromRGB(45, 45, 50),
    TextColor = Color3.fromRGB(245, 245, 245),
    SubTextColor = Color3.fromRGB(180, 180, 185),
    BorderColor = Color3.fromRGB(55, 55, 60),
    Font = Enum.Font.Gotham,
    SmallTextSize = 12,
    NormalTextSize = 13,
    TitleTextSize = 18,
    AnimationSpeed = 0.25,
    ItemHeight = 36,
    SafeAreaPadding = 14,
    Resizable = true,
    ResizeHandleSize = 16,
    MinWidth = 420,
    MinHeight = 300,
    MaxWidth = 1200,
    MaxHeight = 900,
}

local function deepCopy(tbl)
    local copy = {}
    for key, value in pairs(tbl) do
        copy[key] = typeof(value) == "table" and deepCopy(value) or value
    end
    return copy
end

local function makeCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function makeStroke(instance, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = instance
    return stroke
end

local function makePadding(instance, amount)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, amount)
    p.PaddingBottom = UDim.new(0, amount)
    p.PaddingLeft = UDim.new(0, amount)
    p.PaddingRight = UDim.new(0, amount)
    p.Parent = instance
    return p
end

local function makeButton(parent)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BackgroundTransparency = 1
    b.Text = ""
    b.Parent = parent
    return b
end

local function makeLabel(parent, text, size, color, font, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function tween(instance, speed, props, easingStyle, easingDirection)
    local tw = TweenService:Create(
        instance,
        TweenInfo.new(speed, easingStyle or Enum.EasingStyle.Quint, easingDirection or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function tweenDescendants(root, speed, mode)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UICorner") or obj:IsA("UIListLayout") or obj:IsA("UIPadding") or obj:IsA("UIGradient") then
            continue
        end

        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            tween(obj, speed, { TextTransparency = (mode == "hide") and 1 or 0 })
        end

        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("ScrollingFrame") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if mode == "hide" and obj:GetAttribute("OrigBG") == nil then
                obj:SetAttribute("OrigBG", obj.BackgroundTransparency)
            end
            local target = (mode == "hide") and 1 or obj:GetAttribute("OrigBG")
            if target == nil then target = 1 end
            tween(obj, speed, { BackgroundTransparency = target })
        end

        if obj:IsA("ScrollingFrame") then
            if mode == "hide" and obj:GetAttribute("OrigScrollBar") == nil then
                obj:SetAttribute("OrigScrollBar", obj.ScrollBarImageTransparency)
            end
            local target = (mode == "hide") and 1 or obj:GetAttribute("OrigScrollBar")
            if target == nil then target = 0 end
            tween(obj, speed, { ScrollBarImageTransparency = target })
        end

        if obj:IsA("UIStroke") then
            if mode == "hide" and obj:GetAttribute("OrigStroke") == nil then
                obj:SetAttribute("OrigStroke", obj.Transparency)
            end
            local target = (mode == "hide") and 1 or obj:GetAttribute("OrigStroke")
            if target == nil then target = 0 end
            tween(obj, speed, { Transparency = target })
        end
    end
end

local function cacheOriginalTransparency(root)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("ScrollingFrame") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj:SetAttribute("OrigBG", obj.BackgroundTransparency)
        end
        if obj:IsA("ScrollingFrame") then
            obj:SetAttribute("OrigScrollBar", obj.ScrollBarImageTransparency)
        end
        if obj:IsA("UIStroke") then
            obj:SetAttribute("OrigStroke", obj.Transparency)
        end
    end
end

local function clamp01(v)
    return math.clamp(v, 0, 1)
end

local function keyToText(key)
    if not key then return "None" end
    if typeof(key) == "EnumItem" then
        if key.EnumType == Enum.KeyCode then
            if key == Enum.KeyCode.Unknown then return "None" end
            return key.Name
        elseif key.EnumType == Enum.UserInputType then
            if key == Enum.UserInputType.MouseButton1 then return "LMB" end
            if key == Enum.UserInputType.MouseButton2 then return "RMB" end
            if key == Enum.UserInputType.MouseButton3 then return "MMB" end
            return key.Name
        end
    end
    return "None"
end

local function colorToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function pressAnimation(button)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button
    button.MouseButton1Down:Connect(function() tween(scale, 0.08, { Scale = 0.97 }) end)
    button.MouseButton1Up:Connect(function() tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back) end)
    button.MouseLeave:Connect(function() tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back) end)
end

local function getParent(customParent)
    if customParent then return customParent end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local root = playerGui:FindFirstChild("LibraryRoot")
    if root then return root end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LibraryRoot"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = playerGui
    return gui
end

local function isLightColor(c)
    return (c.R * 0.299 + c.G * 0.587 + c.B * 0.114) > 0.7
end

local function toFlag(text)
    local raw = tostring(text or "item")
    raw = raw:gsub("[^%w_]+", "_")
    raw = raw:gsub("^_+", ""):gsub("_+$", "")
    if raw == "" then
        raw = "item"
    end
    return raw
end

local function normalizeOptions(input)
    local out = {}
    local seen = {}

    if typeof(input) ~= "table" then
        return out
    end

    for _, value in ipairs(input) do
        local name = tostring(value)
        if not seen[name] then
            seen[name] = true
            table.insert(out, name)
        end
    end

    for key, value in pairs(input) do
        if typeof(key) ~= "number" then
            local candidate
            if typeof(value) == "boolean" then
                candidate = tostring(key)
            else
                candidate = tostring(value)
            end
            if not seen[candidate] then
                seen[candidate] = true
                table.insert(out, candidate)
            end
        end
    end

    return out
end

function Library.new(config)
    config = config or {}
    local settings = deepCopy(Library.Defaults)
    for key, value in pairs(config) do settings[key] = value end

    if config.ItemColor == nil and isLightColor(settings.BackgroundColor) then
        settings.ItemColor = Color3.fromRGB(230, 230, 236)
    end

    local self = setmetatable({}, Library)
    self.Settings = settings
    self.Tabs = {}
    self.Visible = true
    self.CurrentTab = nil
    self.Connections = {}
    self._visibilityToken = 0
    self._colorPopups = {}
    self._controls = {}
    self._controlOrder = {}
    self._pendingValues = nil
    self._config = {
        System = nil,
        AutoLoad = false,
        AutoLoadName = "autoload",
        AutoSave = false,
        AutoSaveName = "autoload",
    }

    local root = getParent(settings.Parent)

    local holder = Instance.new("Frame")
    holder.Name = "Window"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(settings.Width, settings.Height)
    holder.BackgroundColor3 = settings.BackgroundColor
    holder.ClipsDescendants = true
    holder.Parent = root
    makeCorner(holder, settings.CornerRadius)
    makeStroke(holder, settings.BorderColor, 0)

    local holderScale = Instance.new("UIScale")
    holderScale.Scale = 1
    holderScale.Parent = holder

    local resizeHandle
    if settings.Resizable then
        resizeHandle = Instance.new("Frame")
        resizeHandle.Name = "ResizeHandle"
        resizeHandle.AnchorPoint = Vector2.new(1, 1)
        resizeHandle.Size = UDim2.fromOffset(settings.ResizeHandleSize, settings.ResizeHandleSize)
        resizeHandle.Position = UDim2.new(1, -4, 1, -4)
        resizeHandle.BackgroundColor3 = settings.ItemColor
        resizeHandle.BackgroundTransparency = 1
        resizeHandle.ZIndex = 100
        resizeHandle.Parent = holder
        makeCorner(resizeHandle, 4)
        makeStroke(resizeHandle, settings.BorderColor, 0.6)

        local resizeButton = makeButton(resizeHandle)
        resizeButton.Size = UDim2.fromScale(1, 1)
        resizeButton.ZIndex = 102

        local resizing = false
        local resizeStartPos
        local resizeStartSize
        local resizeStartHolderPos

        table.insert(self.Connections, resizeButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStartPos = input.Position
                resizeStartSize = holder.AbsoluteSize
                resizeStartHolderPos = holder.Position
            end
        end))

        table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

            local delta = input.Position - resizeStartPos
            local newWidth = math.clamp(resizeStartSize.X + delta.X, settings.MinWidth, settings.MaxWidth)
            local newHeight = math.clamp(resizeStartSize.Y + delta.Y, settings.MinHeight, settings.MaxHeight)
            local widthDelta = newWidth - resizeStartSize.X
            local heightDelta = newHeight - resizeStartSize.Y

            holder.Size = UDim2.fromOffset(newWidth, newHeight)
            holder.Position = UDim2.new(
                resizeStartHolderPos.X.Scale,
                resizeStartHolderPos.X.Offset + (widthDelta * 0.5),
                resizeStartHolderPos.Y.Scale,
                resizeStartHolderPos.Y.Offset + (heightDelta * 0.5)
            )
            self.Settings.Width = newWidth
            self.Settings.Height = newHeight
        end))

        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end))
    end

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Parent = holder

    local sidebarLine = Instance.new("Frame")
    sidebarLine.Size = UDim2.new(0, 1, 1, -(settings.CornerRadius * 2))
    sidebarLine.Position = UDim2.new(1, -1, 0, settings.CornerRadius)
    sidebarLine.BackgroundColor3 = settings.BorderColor
    sidebarLine.BorderSizePixel = 0
    sidebarLine.Parent = sidebar

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 70)
    header.Parent = sidebar

    local title = makeLabel(header, settings.Name, settings.TitleTextSize, settings.TextColor, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Position = UDim2.fromOffset(16, 16)

    local subtitle = makeLabel(header, settings.Subtitle, settings.SmallTextSize, settings.SubTextColor, settings.Font, Enum.TextXAlignment.Left)
    subtitle.Size = UDim2.new(1, -24, 0, 14)
    subtitle.Position = UDim2.fromOffset(16, 38)

    local tabsContainer = Instance.new("ScrollingFrame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Size = UDim2.new(1, 0, 1, -70)
    tabsContainer.Position = UDim2.fromOffset(0, 70)
    tabsContainer.ScrollBarThickness = 0
    tabsContainer.CanvasSize = UDim2.fromOffset(0, 0)
    tabsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabsContainer.Parent = sidebar

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Vertical
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.Parent = tabsContainer

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.BackgroundTransparency = 1
    pages.Size = UDim2.new(1, -160, 1, 0)
    pages.Position = UDim2.fromOffset(160, 0)
    pages.ClipsDescendants = true
    pages.Parent = holder

    self.Root = root
    self.Holder = holder
    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.TabsContainer = tabsContainer
    self.Pages = pages
    self.HolderScale = holderScale

    local dragStart, startPos
    if settings.Draggable then
        table.insert(self.Connections, sidebar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = input.Position
                startPos = holder.Position
            end
        end))
        table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
            if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragStart = nil
            end
        end))
    end

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input)
        if UserInputService:GetFocusedTextBox() then return end
        if self._capturingKeybind then return end

        local isKeybindHit = false
        if self.Settings.Keybind.EnumType == Enum.KeyCode and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.Settings.Keybind then
            isKeybindHit = true
        elseif self.Settings.Keybind.EnumType == Enum.UserInputType and input.UserInputType == self.Settings.Keybind then
            isKeybindHit = true
        end

        if isKeybindHit then
            self:Toggle()
        end
    end))

    holder.Size = UDim2.fromOffset(settings.Width * 0.95, settings.Height * 0.95)
    holder.BackgroundTransparency = 1
    tween(holder, settings.AnimationSpeed, { Size = UDim2.fromOffset(settings.Width, settings.Height), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    holderScale.Scale = 0.95
    tween(holderScale, settings.AnimationSpeed, { Scale = 1 }, Enum.EasingStyle.Back)

    task.defer(function() cacheOriginalTransparency(holder) end)

    return self
end

function Library:SetVisible(state)
    self._visibilityToken = self._visibilityToken + 1
    local token = self._visibilityToken
    self.Visible = state

    if state then
        self.Holder.Visible = true
        self.Holder.Size = UDim2.fromOffset(self.Settings.Width * 0.95, self.Settings.Height * 0.95)
        self.HolderScale.Scale = 0.95
        self.Holder.BackgroundTransparency = 1
        tweenDescendants(self.Holder, 0, "hide")
        tween(self.Holder, self.Settings.AnimationSpeed, { Size = UDim2.fromOffset(self.Settings.Width, self.Settings.Height), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
        tween(self.HolderScale, self.Settings.AnimationSpeed, { Scale = 1 }, Enum.EasingStyle.Back)
        tweenDescendants(self.Holder, self.Settings.AnimationSpeed, "show")
    else
        local hideDur = self.Settings.AnimationSpeed * 0.8
        for _, p in ipairs(self._colorPopups) do
            if p and p.CloseInstant then p:CloseInstant() end
        end
        tweenDescendants(self.Holder, hideDur, "hide")
        tween(self.Holder, hideDur, { Size = UDim2.fromOffset(self.Settings.Width * 0.95, self.Settings.Height * 0.95), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
        tween(self.HolderScale, hideDur, { Scale = 0.95 }, Enum.EasingStyle.Quad)
        task.delay(hideDur, function()
            if token ~= self._visibilityToken then return end
            if self.Holder then self.Holder.Visible = false end
        end)
    end
end

function Library:Toggle()
    self:SetVisible(not self.Visible)
end

function Library:SetTitle(name, subtitle)
    self.TitleLabel.Text = name or self.TitleLabel.Text
    self.SubtitleLabel.Text = subtitle or self.SubtitleLabel.Text
end

function Library:SetKeybind(keyCode)
    if typeof(keyCode) ~= "EnumItem" then return false end
    if keyCode.EnumType ~= Enum.KeyCode and keyCode.EnumType ~= Enum.UserInputType then return false end
    self.Settings.Keybind = keyCode
    return true
end

function Library:_registerControl(data)
    if typeof(data) ~= "table" then return nil end
    if typeof(data.Get) ~= "function" or typeof(data.Set) ~= "function" then
        return nil
    end

    local base = toFlag(data.Flag or data.Name or ("control_" .. tostring(#self._controlOrder + 1)))
    local flag = base
    local index = 1
    while self._controls[flag] ~= nil do
        index = index + 1
        flag = base .. "_" .. tostring(index)
    end

    local ref = {
        Flag = flag,
        Type = data.Type or "Unknown",
        Get = data.Get,
        Set = data.Set,
        Serialize = data.Serialize,
        Deserialize = data.Deserialize,
    }

    self._controls[flag] = ref
    table.insert(self._controlOrder, flag)

    if typeof(self._pendingValues) == "table" and self._pendingValues[flag] ~= nil then
        local pending = self._pendingValues[flag]
        if ref.Deserialize then
            pending = ref.Deserialize(pending)
        end
        pcall(function()
            ref.Set(pending, true)
        end)
    end

    return ref
end

function Library:_emitChanged(flag)
    local cfg = self._config
    if not cfg or not cfg.System or not cfg.AutoSave then
        return
    end
    local payload = self:GetValues()
    cfg.System:SaveConfig(cfg.AutoSaveName, payload)
    cfg.System:SetAutoLoad(cfg.AutoSaveName)
end

function Library:GetValues()
    local out = {}
    for _, flag in ipairs(self._controlOrder) do
        local ref = self._controls[flag]
        if ref and ref.Get then
            local ok, value = pcall(ref.Get)
            if ok then
                if ref.Serialize then
                    out[flag] = ref.Serialize(value)
                else
                    out[flag] = value
                end
            end
        end
    end
    return out
end

function Library:ApplyValues(values, silent)
    if typeof(values) ~= "table" then return end
    for flag, raw in pairs(values) do
        local ref = self._controls[flag]
        if ref and ref.Set then
            local value = raw
            if ref.Deserialize then
                value = ref.Deserialize(raw)
            end
            pcall(function()
                ref.Set(value, silent == true)
            end)
        end
    end
end

function Library:SetValue(flag, value, silent)
    local ref = self._controls[flag]
    if not ref then return false end
    pcall(function()
        ref.Set(value, silent == true)
    end)
    return true
end

function Library:GetValue(flag)
    local ref = self._controls[flag]
    if not ref then return nil end
    local ok, value = pcall(ref.Get)
    if ok then return value end
    return nil
end

function Library:BindConfigSystem(configSystem, options)
    if typeof(configSystem) ~= "table" then
        return false, "configSystem is required"
    end

    options = options or {}
    self._config.System = configSystem
    self._config.AutoLoad = options.AutoLoad == true
    self._config.AutoLoadName = options.AutoLoadName or "autoload"
    self._config.AutoSave = options.AutoSave == true
    self._config.AutoSaveName = options.AutoSaveName or self._config.AutoLoadName

    if self._config.AutoLoad then
        local loaded = configSystem:LoadAutoLoad()
        if loaded then
            self._pendingValues = loaded
            self:ApplyValues(loaded, true)
        end
    end

    return true
end

function Library:SaveConfig(configName)
    local system = self._config and self._config.System
    if not system then
        return false, "No config system bound"
    end
    return system:SaveConfig(configName, self:GetValues())
end

function Library:LoadConfig(configName)
    local system = self._config and self._config.System
    if not system then
        return false, "No config system bound"
    end
    local data = system:LoadConfig(configName)
    if typeof(data) ~= "table" then
        return false, "Config not found or invalid"
    end
    self:ApplyValues(data, true)
    return true
end

function Library:SetAutoLoadConfig(configName)
    local system = self._config and self._config.System
    if not system or typeof(system.SetAutoLoad) ~= "function" then
        return false, "No config system bound"
    end
    return system:SetAutoLoad(configName)
end

function Library:LoadAutoConfig()
    local system = self._config and self._config.System
    if not system or typeof(system.LoadAutoLoad) ~= "function" then
        return false, "No config system bound"
    end

    local data = system:LoadAutoLoad()
    if typeof(data) ~= "table" then
        return false, "Autoload config missing"
    end
    self:ApplyValues(data, true)
    return true
end

function Library:AddTab(tabSettings)
    tabSettings = tabSettings or {}
    local style = self.Settings
    local name = tabSettings.Name or ("Tab " .. tostring(#self.Tabs + 1))

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = style.BorderColor
    page.ScrollBarImageTransparency = 0.35
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Position = UDim2.fromOffset(0, style.CornerRadius)
    page.Size = UDim2.new(1, 0, 1, -(style.CornerRadius * 2))
    page.ClipsDescendants = true
    page.Parent = self.Pages
    makePadding(page, style.SafeAreaPadding)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.Parent = page
    cacheOriginalTransparency(page)

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -16, 0, 32)
    tabContainer.Position = UDim2.fromOffset(8, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.TabsContainer
    makeCorner(tabContainer, 6)

    local tabButton = makeButton(tabContainer)
    tabButton.Size = UDim2.fromScale(1, 1)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = style.AccentColor
    indicator.BorderSizePixel = 0
    indicator.Parent = tabContainer
    makeCorner(indicator, 2)

    local tabText = makeLabel(tabContainer, name, style.NormalTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
    tabText.Size = UDim2.new(1, -20, 1, 0)
    tabText.Position = UDim2.fromOffset(14, 0)

    local tab = {
        Name = name,
        Button = tabButton,
        Label = tabText,
        Indicator = indicator,
        Container = tabContainer,
        Page = page,
        Settings = style,
        Menu = self,
        Index = #self.Tabs + 1,
    }

    function tab:SetActive(state)
        self.Page.Visible = state
        if state then
            tween(self.Container, 0.15, { BackgroundTransparency = 0.9, BackgroundColor3 = style.ItemColor })
            tween(self.Indicator, 0.15, { Size = UDim2.new(0, 3, 0, 16) }, Enum.EasingStyle.Back)
            tween(self.Label, 0.15, { TextColor3 = style.TextColor })
        else
            tween(self.Container, 0.15, { BackgroundTransparency = 1 })
            tween(self.Indicator, 0.15, { Size = UDim2.new(0, 3, 0, 0) })
            tween(self.Label, 0.15, { TextColor3 = style.SubTextColor })
        end
    end

    function tab:AddSection(sectionSettings)
        sectionSettings = sectionSettings or {}
        local menuRef = self.Menu
        local section = Instance.new("Frame")
        section.BackgroundColor3 = style.SurfaceColor
        section.BackgroundTransparency = 0
        section.ClipsDescendants = true
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Size = UDim2.new(1, 0, 0, 0)
        section.Parent = page
        makeCorner(section, 6)
        makeStroke(section, style.BorderColor, 0)
        makePadding(section, 10)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = section

        local title = makeLabel(section, sectionSettings.Title or "Section", style.NormalTextSize, style.TextColor, Enum.Font.GothamMedium, Enum.TextXAlignment.Left)
        title.Size = UDim2.new(1, 0, 0, 20)

        if sectionSettings.Description then
            local desc = makeLabel(section, sectionSettings.Description, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
            desc.Size = UDim2.new(1, 0, 0, 16)
            desc.TextWrapped = true
            desc.AutomaticSize = Enum.AutomaticSize.Y
        end

        local function makeRow(height)
            local row = Instance.new("Frame")
            row.BackgroundColor3 = style.ItemColor
            row.Size = UDim2.new(1, 0, 0, height or style.ItemHeight)
            row.Parent = section
            row.BackgroundTransparency = 1
            return row
        end

        local api = {}

        function api:AddButton(data)
            data = data or {}
            local row = makeRow(data.Height)
            row.BackgroundTransparency = 0
            makeCorner(row, 6)
            makeStroke(row, style.BorderColor, 0)

            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)
            pressAnimation(button)

            local text = makeLabel(row, data.Text or "Button", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Center)
            text.Size = UDim2.fromScale(1, 1)

            button.MouseButton1Click:Connect(function()
                if data.Callback then data.Callback() end
            end)
            cacheOriginalTransparency(row)
            return row
        end

        function api:AddToggle(data)
            data = data or {}
            local state = data.Default or false
            local row = makeRow(data.Height)
            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)

            local text = makeLabel(row, data.Text or "Toggle", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -76, 1, 0)

            local toggleBg = Instance.new("Frame")
            toggleBg.Size = UDim2.fromOffset(36, 20)
            toggleBg.Position = UDim2.new(1, -44, 0.5, -10)
            toggleBg.BackgroundColor3 = state and style.AccentColor or style.ItemColor
            toggleBg.Parent = row
            makeCorner(toggleBg, 10)
            makeStroke(toggleBg, style.BorderColor, 0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Parent = toggleBg
            makeCorner(knob, 8)

            local controlRef
            local function setState(nextState, silent)
                state = nextState
                tween(toggleBg, 0.2, { BackgroundColor3 = state and style.AccentColor or style.ItemColor }, Enum.EasingStyle.Quart)
                tween(knob, 0.2, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, Enum.EasingStyle.Quart)
                if data.Callback then data.Callback(state) end
                if not silent then menuRef:_emitChanged(controlRef.Flag) end
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "toggle",
                Type = "Toggle",
                Get = function() return state end,
                Set = function(v, silent) setState(v == true, silent) end,
            })

            button.MouseButton1Click:Connect(function() setState(not state, false) end)
            cacheOriginalTransparency(row)
            return { Set = setState, Get = function() return state end, Flag = controlRef and controlRef.Flag or nil }
        end

        function api:AddSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            local step = data.Step or 1
            if step <= 0 then step = 1 end
            local value = math.clamp(data.Default or min, min, max)
            local dragging = false

            local row = makeRow(math.max(48, data.Height or 48))

            local text = makeLabel(row, data.Text or "Slider", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -60, 0, 20)

            local valueLabel = makeLabel(row, tostring(value), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Size = UDim2.fromOffset(56, 14)
            valueLabel.Position = UDim2.new(1, -56, 0, 3)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 0, 0, 6)
            bar.Position = UDim2.fromOffset(0, 28)
            bar.BackgroundColor3 = style.ItemColor
            bar.Parent = row
            makeCorner(bar, 999)
            makeStroke(bar, style.BorderColor, 0)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = style.AccentColor
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = bar
            makeCorner(fill, 999)

            local function render(v)
                local range = math.max(max - min, 1)
                tween(fill, 0.12, { Size = UDim2.new((v - min) / range, 0, 1, 0) })
                valueLabel.Text = tostring(v)
            end

            local controlRef
            local function setValue(raw, silent)
                local rounded = min + math.floor(((raw - min) / step) + 0.5) * step
                value = math.clamp(rounded, min, max)
                render(value)
                if data.Callback then data.Callback(value) end
                if not silent then menuRef:_emitChanged(controlRef.Flag) end
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "slider",
                Type = "Slider",
                Get = function() return value end,
                Set = function(v, silent)
                    if typeof(v) ~= "number" then return end
                    setValue(v, silent)
                end,
            })

            local input = makeButton(bar)
            input.Size = UDim2.new(1, 0, 1, 10)
            input.Position = UDim2.fromOffset(0, -5)

            input.MouseButton1Down:Connect(function() dragging = true end)
            table.insert(menuRef.Connections, UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local alpha = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    setValue(min + (max - min) * alpha, false)
                end
            end))
            table.insert(menuRef.Connections, UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            render(value)
            cacheOriginalTransparency(row)
            return { Set = setValue, Get = function() return value end, Flag = controlRef and controlRef.Flag or nil }
        end

        function api:AddBoolean(data)
            return api:AddToggle(data)
        end

        function api:AddCheckbox(data)
            return api:AddToggle(data)
        end

        function api:AddDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"
            local expanded = false
            local optionRows = {}
            local optionsHeight = 0
            local rsConnection
            local controlRef

            local row = makeRow(data.Height)
            local title = makeLabel(row, data.Text or "Dropdown", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(0.45, 0, 1, 0)

            local hitBg = Instance.new("Frame")
            hitBg.Size = UDim2.new(0.5, 0, 1, -4)
            hitBg.Position = UDim2.new(0.5, 0, 0, 2)
            hitBg.BackgroundColor3 = style.ItemColor
            hitBg.Parent = row
            makeCorner(hitBg, 4)
            makeStroke(hitBg, style.BorderColor, 0)

            local hit = makeButton(hitBg)
            hit.Size = UDim2.fromScale(1, 1)
            pressAnimation(hit)

            local valueLabel = makeLabel(hitBg, tostring(selected), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
            valueLabel.Size = UDim2.fromScale(1, 1)

            local popup = Instance.new("ScrollingFrame")
            popup.Visible = false
            popup.ClipsDescendants = true
            popup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            popup.BackgroundTransparency = 1
            popup.ZIndex = 200
            popup.BorderSizePixel = 0
            popup.CanvasSize = UDim2.fromOffset(0, 0)
            popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
            popup.ScrollBarImageColor3 = style.BorderColor
            popup.ScrollBarImageTransparency = 0.35
            popup.ScrollBarThickness = 0
            popup.Parent = menuRef.Root
            makeCorner(popup, 6)
            local popupStroke = makeStroke(popup, style.BorderColor, 1)
            popupStroke.ZIndex = 201

            local maxPopupHeight = data.MaxPopupHeight or 220

            local popupPad = Instance.new("UIPadding")
            popupPad.PaddingTop = UDim.new(0, 0)
            popupPad.PaddingBottom = UDim.new(0, 0)
            popupPad.PaddingLeft = UDim.new(0, 0)
            popupPad.PaddingRight = UDim.new(0, 0)
            popupPad.Parent = popup

            local panelLayout = Instance.new("UIListLayout")
            panelLayout.Padding = UDim.new(0, 0)
            panelLayout.Parent = popup

            local popupScale = Instance.new("UIScale")
            popupScale.Scale = 0.96
            popupScale.Parent = popup

            local function getPopupWidth()
                return math.max(hitBg.AbsoluteSize.X, 140)
            end

            local function containsPoint(gui, point)
                local pos = gui.AbsolutePosition
                local size = gui.AbsoluteSize
                return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
            end

            local function refreshPopupPlacement()
                if not hitBg or not hitBg.Parent then return end
                local rootPos = menuRef.Root.AbsolutePosition
                local rootSize = menuRef.Root.AbsoluteSize
                local rowPos = row.AbsolutePosition
                local popupWidth = getPopupWidth()
                local displayHeight = math.min(math.max(optionsHeight, 0), maxPopupHeight)

                local desiredX = rowPos.X - rootPos.X + row.AbsoluteSize.X + 8
                local desiredY = rowPos.Y - rootPos.Y

                local maxX = math.max(8, rootSize.X - popupWidth - 8)
                local maxY = math.max(8, rootSize.Y - math.max(popup.AbsoluteSize.Y, displayHeight) - 8)

                if desiredX > maxX then
                    desiredX = rowPos.X - rootPos.X - popupWidth - 8
                end

                popup.Position = UDim2.fromOffset(
                    math.clamp(desiredX, 8, maxX),
                    math.clamp(desiredY, 8, maxY)
                )

                if not expanded then
                    popup.Size = UDim2.fromOffset(popupWidth, 0)
                end
            end

            local function updateStyles()
                for optionName, ref in pairs(optionRows) do
                    local active = (selected == optionName)
                    ref.Button:SetAttribute("OrigBG", 1)
                    tween(ref.Text, 0.12, { TextColor3 = active and style.AccentColor or style.SubTextColor })
                    tween(ref.Button, 0.12, { BackgroundTransparency = 1 })
                end
            end

            local function setExpanded(state)
                expanded = state
                if expanded then
                    popup.Visible = true
                    refreshPopupPlacement()
                    if not rsConnection then
                        rsConnection = RunService.RenderStepped:Connect(refreshPopupPlacement)
                        table.insert(menuRef.Connections, rsConnection)
                    end
                    local popupWidth = getPopupWidth()
                    local popupHeight = math.min(optionsHeight, maxPopupHeight)
                    popup.ScrollBarThickness = (optionsHeight > maxPopupHeight) and 3 or 0
                    popup.Size = UDim2.fromOffset(popupWidth, math.max(0, popupHeight - 12))
                    popup.BackgroundTransparency = 1
                    popupStroke.Transparency = 1
                    popupScale.Scale = 0.96
                    tweenDescendants(popup, 0, "hide")
                    tween(popup, 0.16, { Size = UDim2.fromOffset(popupWidth, popupHeight) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Back)
                    tween(popup, 0.16, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad)
                    tween(popupStroke, 0.2, { Transparency = 0 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    tweenDescendants(popup, 0.16, "show")
                else
                    if rsConnection then
                        rsConnection:Disconnect()
                        rsConnection = nil
                    end
                    local closeWidth = popup.AbsoluteSize.X
                    local closeHeight = popup.AbsoluteSize.Y
                    tween(popupScale, 0.12, { Scale = 0.96 }, Enum.EasingStyle.Quad)
                    tween(popup, 0.12, { Size = UDim2.fromOffset(closeWidth, math.max(0, closeHeight - 12)) }, Enum.EasingStyle.Quad)
                    tween(popup, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
                    tween(popupStroke, 0.12, { Transparency = 1 }, Enum.EasingStyle.Quad)
                    tweenDescendants(popup, 0.12, "hide")
                    task.delay(0.12, function()
                        if popup and popup.Parent and not expanded then
                            popup.Visible = false
                            popup.Size = UDim2.fromOffset(closeWidth, 0)
                        end
                    end)
                end
            end

            local function clearOptions()
                for _, ref in pairs(optionRows) do
                    if ref.Button then ref.Button:Destroy() end
                end
                optionRows = {}
                optionsHeight = 0
            end

            local function setSelected(nextValue, silent)
                local str = tostring(nextValue)
                if optionRows[str] then
                    selected = str
                    valueLabel.Text = str
                    updateStyles()
                    if data.Callback then data.Callback(str) end
                    if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
                end
            end

            local function rebuild(newOptions)
                clearOptions()
                local optionCount = 0
                local seen = {}
                for _, optionName in ipairs(normalizeOptions(newOptions)) do
                    if not seen[optionName] then
                        seen[optionName] = true
                        optionCount = optionCount + 1

                        local optionButton = Instance.new("TextButton")
                        optionButton.AutoButtonColor = false
                        optionButton.Text = ""
                        optionButton.BackgroundTransparency = 1
                        optionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        optionButton.Size = UDim2.new(1, 0, 0, 26)
                        optionButton.ZIndex = 202
                        optionButton.Parent = popup
                        makeCorner(optionButton, 4)

                        local optionText = makeLabel(optionButton, optionName, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
                        optionText.Size = UDim2.fromScale(1, 1)
                        optionText.ZIndex = 203

                        optionRows[optionName] = { Button = optionButton, Text = optionText }

                        optionButton.MouseButton1Click:Connect(function()
                            setSelected(optionName, false)
                            setExpanded(false)
                        end)
                    end
                end
                optionsHeight = optionCount * 26
                if optionRows[selected] == nil then
                    for optionName in pairs(optionRows) do
                        selected = optionName
                        break
                    end
                    selected = selected or "None"
                end
                valueLabel.Text = tostring(selected)
                refreshPopupPlacement()
                updateStyles()
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "dropdown",
                Type = "Dropdown",
                Get = function() return selected end,
                Set = function(v, silent) setSelected(v, silent) end,
            })

            hit.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

            table.insert(menuRef.Connections, row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if not expanded then refreshPopupPlacement() end
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not expanded then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if not containsPoint(hitBg, input.Position) and not containsPoint(popup, input.Position) then
                    setExpanded(false)
                end
            end))

            rebuild(options)
            cacheOriginalTransparency(popup)
            cacheOriginalTransparency(row)
            return {
                Set = function(a, b, c)
                    local value, silent
                    if typeof(a) == "table" and a.SetOptions ~= nil and a.Get ~= nil then
                        value, silent = b, c
                    else
                        value, silent = a, b
                    end
                    setSelected(value, silent)
                end,
                Get = function()
                    return selected
                end,
                SetOptions = function(a, b)
                    local newOptions
                    if typeof(a) == "table" and a.SetOptions ~= nil and a.Get ~= nil then
                        newOptions = b
                    else
                        newOptions = a
                    end
                    rebuild(newOptions)
                end,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddMultiBoolean(data)
            data = data or {}
            local options = data.Options or {}
            local states = {}
            local expanded = false
            local optionRows = {}
            local optionsHeight = 0
            local rsConnection
            local controlRef

            local row = makeRow(data.Height)
            local title = makeLabel(row, data.Text or "MultiBoolean", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(0.45, 0, 1, 0)

            local hitBg = Instance.new("Frame")
            hitBg.Size = UDim2.new(0.5, 0, 1, -4)
            hitBg.Position = UDim2.new(0.5, 0, 0, 2)
            hitBg.BackgroundColor3 = style.ItemColor
            hitBg.Parent = row
            makeCorner(hitBg, 4)
            makeStroke(hitBg, style.BorderColor, 0)

            local hit = makeButton(hitBg)
            hit.Size = UDim2.fromScale(1, 1)
            pressAnimation(hit)

            local valueLabel = makeLabel(hitBg, "None", style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
            valueLabel.Size = UDim2.fromScale(1, 1)

            local popup = Instance.new("ScrollingFrame")
            popup.Visible = false
            popup.ClipsDescendants = true
            popup.BackgroundColor3 = style.SurfaceColor
            popup.BackgroundTransparency = 1
            popup.ZIndex = 200
            popup.BorderSizePixel = 0
            popup.CanvasSize = UDim2.fromOffset(0, 0)
            popup.AutomaticCanvasSize = Enum.AutomaticSize.Y
            popup.ScrollBarImageColor3 = style.BorderColor
            popup.ScrollBarImageTransparency = 0.35
            popup.ScrollBarThickness = 0
            popup.Parent = menuRef.Root
            makeCorner(popup, 6)
            local popupStroke = makeStroke(popup, style.BorderColor, 1)
            popupStroke.ZIndex = 201

            local maxPopupHeight = data.MaxPopupHeight or 220

            local popupPad = Instance.new("UIPadding")
            popupPad.PaddingTop = UDim.new(0, 4)
            popupPad.PaddingBottom = UDim.new(0, 4)
            popupPad.PaddingLeft = UDim.new(0, 4)
            popupPad.PaddingRight = UDim.new(0, 4)
            popupPad.Parent = popup

            local panelLayout = Instance.new("UIListLayout")
            panelLayout.Padding = UDim.new(0, 0)
            panelLayout.Parent = popup

            local popupScale = Instance.new("UIScale")
            popupScale.Scale = 0.96
            popupScale.Parent = popup

            local function getPopupWidth()
                return math.max(hitBg.AbsoluteSize.X, 180)
            end

            local function containsPoint(gui, point)
                local pos = gui.AbsolutePosition
                local size = gui.AbsoluteSize
                return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
            end

            local function refreshPopupPlacement()
                if not hitBg or not hitBg.Parent then return end
                local rootPos = menuRef.Root.AbsolutePosition
                local rootSize = menuRef.Root.AbsoluteSize
                local rowPos = row.AbsolutePosition
                local popupWidth = getPopupWidth()
                local displayHeight = math.min(math.max(optionsHeight, 0), maxPopupHeight)

                local desiredX = rowPos.X - rootPos.X + row.AbsoluteSize.X + 8
                local desiredY = rowPos.Y - rootPos.Y

                local maxX = math.max(8, rootSize.X - popupWidth - 8)
                local maxY = math.max(8, rootSize.Y - math.max(popup.AbsoluteSize.Y, displayHeight) - 8)

                if desiredX > maxX then
                    desiredX = rowPos.X - rootPos.X - popupWidth - 8
                end

                popup.Position = UDim2.fromOffset(
                    math.clamp(desiredX, 8, maxX),
                    math.clamp(desiredY, 8, maxY)
                )

                if not expanded then
                    popup.Size = UDim2.fromOffset(popupWidth, 0)
                end
            end

            local function updateSummary()
                local count = 0
                for _, enabled in pairs(states) do
                    if enabled then count = count + 1 end
                end
                if count == 0 then
                    valueLabel.Text = "None"
                elseif count == 1 then
                    for opt, enabled in pairs(states) do
                        if enabled then
                            valueLabel.Text = opt
                            break
                        end
                    end
                else
                    valueLabel.Text = tostring(count) .. " selected"
                end
            end

            local function updateOptionVisual(option)
                local ref = optionRows[option]
                if not ref then return end
                local active = states[option] == true
                tween(ref.ToggleBg, 0.15, { BackgroundColor3 = active and style.AccentColor or style.ItemColor }, Enum.EasingStyle.Quad)
                tween(ref.Knob, 0.15, { Position = active and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }, Enum.EasingStyle.Quad)
                tween(ref.Text, 0.12, { TextColor3 = active and style.TextColor or style.SubTextColor })
            end

            local function setExpanded(state)
                expanded = state
                if expanded then
                    popup.Visible = true
                    refreshPopupPlacement()
                    if not rsConnection then
                        rsConnection = RunService.RenderStepped:Connect(refreshPopupPlacement)
                        table.insert(menuRef.Connections, rsConnection)
                    end
                    local popupWidth = getPopupWidth()
                    local popupHeight = math.min(optionsHeight, maxPopupHeight)
                    popup.ScrollBarThickness = (optionsHeight > maxPopupHeight) and 3 or 0
                    popup.Size = UDim2.fromOffset(popupWidth, math.max(0, popupHeight - 12))
                    popup.BackgroundTransparency = 1
                    popupStroke.Transparency = 1
                    popupScale.Scale = 0.96
                    tweenDescendants(popup, 0, "hide")
                    tween(popup, 0.16, { Size = UDim2.fromOffset(popupWidth, popupHeight) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Back)
                    tween(popup, 0.16, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad)
                    tween(popupStroke, 0.2, { Transparency = 0 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    tweenDescendants(popup, 0.16, "show")
                else
                    if rsConnection then
                        rsConnection:Disconnect()
                        rsConnection = nil
                    end
                    local closeWidth = popup.AbsoluteSize.X
                    local closeHeight = popup.AbsoluteSize.Y
                    tween(popupScale, 0.12, { Scale = 0.96 }, Enum.EasingStyle.Quad)
                    tween(popup, 0.12, { Size = UDim2.fromOffset(closeWidth, math.max(0, closeHeight - 12)) }, Enum.EasingStyle.Quad)
                    tween(popup, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
                    tween(popupStroke, 0.12, { Transparency = 1 }, Enum.EasingStyle.Quad)
                    tweenDescendants(popup, 0.12, "hide")
                    task.delay(0.12, function()
                        if popup and popup.Parent and not expanded then
                            popup.Visible = false
                            popup.Size = UDim2.fromOffset(closeWidth, 0)
                        end
                    end)
                end
            end

            local function setOption(option, state, silent)
                option = tostring(option)
                if states[option] == nil then return end
                states[option] = state and true or false
                updateOptionVisual(option)
                updateSummary()
                if data.Callback then data.Callback(option, states[option], states) end
                if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end

            local function getStatesCopy()
                local out = {}
                for k, v in pairs(states) do out[k] = v end
                return out
            end

            local function clearOptions()
                for _, ref in pairs(optionRows) do
                    if ref.Button then ref.Button:Destroy() end
                end
                optionRows = {}
                states = {}
                optionsHeight = 0
            end

            local function setAll(nextStates, silent)
                if typeof(nextStates) ~= "table" then return end
                for optionName in pairs(states) do
                    if nextStates[optionName] ~= nil then
                        states[optionName] = nextStates[optionName] == true
                    end
                end
                for optionName in pairs(optionRows) do
                    updateOptionVisual(optionName)
                end
                updateSummary()
                if data.Callback then data.Callback(nil, nil, getStatesCopy()) end
                if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end

            local function rebuild(newOptions, defaults)
                clearOptions()
                local optionCount = 0
                local seen = {}
                for _, optionName in ipairs(normalizeOptions(newOptions)) do
                    if not seen[optionName] then
                        seen[optionName] = true
                        optionCount = optionCount + 1

                        local optionButton = Instance.new("TextButton")
                        optionButton.AutoButtonColor = false
                        optionButton.Text = ""
                        optionButton.BackgroundTransparency = 1
                        optionButton.BackgroundColor3 = style.ItemColor
                        optionButton.Size = UDim2.new(1, 0, 0, 26)
                        optionButton.ZIndex = 202
                        optionButton.Parent = popup
                        makeCorner(optionButton, 4)

                        local optionText = makeLabel(optionButton, optionName, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
                        optionText.Size = UDim2.new(1, -34, 1, 0)
                        optionText.Position = UDim2.fromOffset(6, 0)
                        optionText.ZIndex = 203

                        local toggleBg = Instance.new("Frame")
                        toggleBg.Size = UDim2.fromOffset(30, 16)
                        toggleBg.Position = UDim2.new(1, -36, 0.5, -8)
                        toggleBg.BackgroundColor3 = style.ItemColor
                        toggleBg.ZIndex = 203
                        toggleBg.Parent = optionButton
                        makeCorner(toggleBg, 8)

                        local knob = Instance.new("Frame")
                        knob.Size = UDim2.fromOffset(12, 12)
                        knob.Position = UDim2.new(0, 2, 0.5, -6)
                        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        knob.ZIndex = 204
                        knob.Parent = toggleBg
                        makeCorner(knob, 6)

                        states[optionName] = typeof(defaults) == "table" and defaults[optionName] == true or false
                        optionRows[optionName] = { Button = optionButton, Text = optionText, ToggleBg = toggleBg, Knob = knob }

                        optionButton.MouseButton1Click:Connect(function()
                            setOption(optionName, not states[optionName], false)
                        end)
                    end
                end
                optionsHeight = (optionCount * 26) + (math.max(optionCount - 1, 0) * 2) + 8
                refreshPopupPlacement()
                for optionName in pairs(optionRows) do updateOptionVisual(optionName) end
                updateSummary()
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "multiboolean",
                Type = "MultiBoolean",
                Get = function() return getStatesCopy() end,
                Set = function(v, silent) setAll(v, silent) end,
            })

            hit.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

            table.insert(menuRef.Connections, row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if not expanded then refreshPopupPlacement() end
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not expanded then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if not containsPoint(hitBg, input.Position) and not containsPoint(popup, input.Position) then
                    setExpanded(false)
                end
            end))

            rebuild(options, data.Default)
            cacheOriginalTransparency(popup)
            cacheOriginalTransparency(row)

            return {
                Set = function(a, b, c, d)
                    local option, newState, silent
                    if typeof(a) == "table" and a.SetOptions ~= nil and a.Get ~= nil then
                        option, newState, silent = b, c, d
                    else
                        option, newState, silent = a, b, c
                    end
                    setOption(option, newState, silent)
                end,
                Get = function(option)
                    if typeof(option) == "table" and option.SetOptions ~= nil and option.Get ~= nil then
                        option = nil
                    end
                    if option ~= nil then return states[tostring(option)] == true end
                    local out = {}
                    for k, v in pairs(states) do out[k] = v end
                    return out
                end,
                SetOptions = function(a, b, c)
                    local newOptions, defaults
                    if typeof(a) == "table" and a.SetOptions ~= nil and a.Get ~= nil then
                        newOptions, defaults = b, c
                    else
                        newOptions, defaults = a, b
                    end
                    rebuild(newOptions, defaults)
                end,
                SetAll = setAll,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddMultiDropdown(data)
            return api:AddMultiBoolean(data)
        end

        function api:AddColorPicker(data)
            data = data or {}
            local titleText = data.Text or "Color Picker"
            local currentColor = data.Default or style.AccentColor
            local h, s, v = Color3.toHSV(currentColor)
            local isOpen = false
            local dragMode = nil
            local rsConnection

            local row = makeRow(data.Height)
            local rowButton = makeButton(row)
            rowButton.Size = UDim2.fromScale(1, 1)
            pressAnimation(rowButton)

            local title = makeLabel(row, titleText, style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(1, -140, 1, 0)

            local hexLabel = makeLabel(row, colorToHex(currentColor), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            hexLabel.Size = UDim2.new(0, 78, 1, 0)
            hexLabel.Position = UDim2.new(1, -106, 0, 0)

            local preview = Instance.new("Frame")
            preview.Size = UDim2.fromOffset(24, 16)
            preview.Position = UDim2.new(1, -24, 0.5, -8)
            preview.BackgroundColor3 = currentColor
            preview.Parent = row
            makeCorner(preview, 4)
            makeStroke(preview, style.BorderColor, 0)

            local popup = Instance.new("Frame")
            popup.Name = "ColorPopup"
            popup.Visible = false
            popup.Size = UDim2.fromOffset(220, 166)
            popup.BackgroundColor3 = style.SurfaceColor
            popup.BackgroundTransparency = 1
            popup.ZIndex = 20
            popup.Parent = menuRef.Root
            makeCorner(popup, 6)
            local popupStroke = makeStroke(popup, style.BorderColor, 1)

            local popupScale = Instance.new("UIScale")
            popupScale.Scale = 0.96
            popupScale.Parent = popup

            local sv = Instance.new("Frame")
            sv.Size = UDim2.new(1, -54, 1, -16)
            sv.Position = UDim2.fromOffset(8, 8)
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            sv.ZIndex = 21
            sv.Parent = popup
            makeCorner(sv, 4)

            local whiteLayer = Instance.new("Frame")
            whiteLayer.Size = UDim2.fromScale(1, 1)
            whiteLayer.BackgroundColor3 = Color3.new(1, 1, 1)
            whiteLayer.ZIndex = 22
            whiteLayer.Parent = sv
            makeCorner(whiteLayer, 4)

            local whiteGradient = Instance.new("UIGradient")
            whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
            whiteGradient.Rotation = 0
            whiteGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
            whiteGradient.Parent = whiteLayer

            local blackLayer = Instance.new("Frame")
            blackLayer.Size = UDim2.fromScale(1, 1)
            blackLayer.BackgroundColor3 = Color3.new(0, 0, 0)
            blackLayer.ZIndex = 23
            blackLayer.Parent = sv
            makeCorner(blackLayer, 4)

            local blackGradient = Instance.new("UIGradient")
            blackGradient.Rotation = 90
            blackGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
            blackGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
            blackGradient.Parent = blackLayer

            local svCursor = Instance.new("Frame")
            svCursor.Size = UDim2.fromOffset(12, 12)
            svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            svCursor.ZIndex = 24
            svCursor.Parent = sv
            makeCorner(svCursor, 999)
            makeStroke(svCursor, Color3.fromRGB(15, 15, 15), 0.35)

            local hueBar = Instance.new("Frame")
            hueBar.Size = UDim2.new(0, 18, 1, -16)
            hueBar.Position = UDim2.new(1, -30, 0, 8)
            hueBar.ZIndex = 21
            hueBar.Parent = popup
            makeCorner(hueBar, 4)

            local hueGradient = Instance.new("UIGradient")
            hueGradient.Rotation = 90
            hueGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
            })
            hueGradient.Parent = hueBar

            local hueCursor = Instance.new("Frame")
            hueCursor.Size = UDim2.new(1, 4, 0, 4)
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueCursor.ZIndex = 24
            hueCursor.Parent = hueBar
            makeCorner(hueCursor, 999)
            makeStroke(hueCursor, Color3.fromRGB(35, 35, 35), 0.35)

            local svHit = makeButton(sv)
            svHit.Size = UDim2.fromScale(1, 1)
            svHit.ZIndex = 25

            local hueHit = makeButton(hueBar)
            hueHit.Size = UDim2.fromScale(1, 1)
            hueHit.ZIndex = 25

            local controlRef
            local function updateVisuals(silent)
                currentColor = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = currentColor
                hexLabel.Text = colorToHex(currentColor)
                sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                tween(svCursor, 0.08, { Position = UDim2.new(s, 0, 1 - v, 0) })
                tween(hueCursor, 0.08, { Position = UDim2.new(0.5, 0, h, 0) })
                if data.Callback then data.Callback(currentColor) end
                if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "colorpicker",
                Type = "ColorPicker",
                Get = function() return currentColor end,
                Set = function(colorValue, silent)
                    if typeof(colorValue) ~= "Color3" then return end
                    local newH, newS, newV = Color3.toHSV(colorValue)
                    h, s, v = newH, newS, newV
                    updateVisuals(silent == true)
                end,
            })

            local popupApi
            local function updatePopupPosition()
                if not row or not row.Parent then return end
                local rootPos = menuRef.Root.AbsolutePosition
                local rootSize = menuRef.Root.AbsoluteSize
                local rowPos = row.AbsolutePosition
                local relativeX = rowPos.X - rootPos.X + row.AbsoluteSize.X + 8
                local relativeY = rowPos.Y - rootPos.Y
                local maxX = math.max(8, rootSize.X - popup.AbsoluteSize.X - 8)
                local maxY = math.max(8, rootSize.Y - popup.AbsoluteSize.Y - 8)
                popup.Position = UDim2.fromOffset(math.clamp(relativeX, 8, maxX), math.clamp(relativeY, 8, maxY))
            end

            local function setFromSV(pos)
                local x = clamp01((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1))
                local y = clamp01((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1))
                s = x
                v = 1 - y
                updateVisuals(false)
            end

            local function setFromHue(pos)
                h = clamp01((pos.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1))
                updateVisuals(false)
            end

            local function openPopup()
                for _, popupRef in ipairs(menuRef._colorPopups) do
                    if popupRef and popupRef ~= popupApi and popupRef.CloseInstant then
                        popupRef:CloseInstant()
                    end
                end
                updatePopupPosition()
                if not rsConnection then
                    rsConnection = RunService.RenderStepped:Connect(updatePopupPosition)
                    table.insert(menuRef.Connections, rsConnection)
                end
                popup.Visible = true
                popup.BackgroundTransparency = 1
                popupStroke.Transparency = 1
                popupScale.Scale = 0.96
                tweenDescendants(popup, 0, "hide")
                tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Back)
                tween(popup, 0.16, { BackgroundTransparency = 0 })
                tween(popupStroke, 0.16, { Transparency = 0 })
                tweenDescendants(popup, 0.16, "show")
                isOpen = true
            end

            local function closePopup()
                if not isOpen then return end
                isOpen = false
                if rsConnection then
                    rsConnection:Disconnect()
                    rsConnection = nil
                end
                tween(popupScale, 0.12, { Scale = 0.96 }, Enum.EasingStyle.Quad)
                tween(popup, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
                tween(popupStroke, 0.12, { Transparency = 1 }, Enum.EasingStyle.Quad)
                tweenDescendants(popup, 0.12, "hide")
                task.delay(0.12, function()
                    if popup and popup.Parent and not isOpen then popup.Visible = false end
                end)
            end

            popupApi = { Instance = popup }
            function popupApi:CloseInstant()
                isOpen = false
                dragMode = nil
                if rsConnection then
                    rsConnection:Disconnect()
                    rsConnection = nil
                end
                popup.Visible = false
                popup.BackgroundTransparency = 1
                popupStroke.Transparency = 1
                popupScale.Scale = 0.96
                tweenDescendants(popup, 0, "hide")
            end
            table.insert(menuRef._colorPopups, popupApi)

            rowButton.MouseButton1Click:Connect(function()
                if isOpen then closePopup() else openPopup() end
            end)

            svHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragMode = "sv"
                    setFromSV(input.Position)
                end
            end)

            hueHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragMode = "hue"
                    setFromHue(input.Position)
                end
            end)

            table.insert(menuRef.Connections, UserInputService.InputChanged:Connect(function(input)
                if not dragMode then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if dragMode == "sv" then setFromSV(input.Position) else setFromHue(input.Position) end
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not isOpen then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local p = input.Position
                local inPopup = p.X >= popup.AbsolutePosition.X and p.X <= popup.AbsolutePosition.X + popup.AbsoluteSize.X and p.Y >= popup.AbsolutePosition.Y and p.Y <= popup.AbsolutePosition.Y + popup.AbsoluteSize.Y
                local inRow = p.X >= row.AbsolutePosition.X and p.X <= row.AbsolutePosition.X + row.AbsoluteSize.X and p.Y >= row.AbsolutePosition.Y and p.Y <= row.AbsolutePosition.Y + row.AbsoluteSize.Y
                if not inPopup and not inRow then closePopup() end
            end))

            table.insert(menuRef.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragMode = nil end
            end))

            updateVisuals(true)
            cacheOriginalTransparency(row)
            cacheOriginalTransparency(popup)
            return {
                Set = function(color)
                    local newH, newS, newV = Color3.toHSV(color)
                    h, s, v = newH, newS, newV
                    updateVisuals(false)
                end,
                Get = function() return currentColor end,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddKeybind(data)
            data = data or {}
            local currentKey = data.Default or Enum.KeyCode.Unknown
            local listening = false

            local row = makeRow(data.Height)
            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)
            pressAnimation(button)

            local title = makeLabel(row, data.Text or "Keybind", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(1, -120, 1, 0)

            local keyBg = Instance.new("Frame")
            keyBg.Size = UDim2.fromOffset(80, 22)
            keyBg.Position = UDim2.new(1, -80, 0.5, -11)
            keyBg.BackgroundColor3 = style.ItemColor
            keyBg.Parent = row
            makeCorner(keyBg, 4)
            makeStroke(keyBg, style.BorderColor, 0)

            local keyLabel = makeLabel(keyBg, keyToText(currentKey), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
            keyLabel.Size = UDim2.fromScale(1, 1)

            local controlRef
            local function setKey(newKey, silent)
                if typeof(newKey) ~= "EnumItem" then return end
                if newKey.EnumType ~= Enum.KeyCode and newKey.EnumType ~= Enum.UserInputType then return end
                currentKey = newKey
                keyLabel.Text = keyToText(currentKey)
                if data.OnChanged then data.OnChanged(currentKey) end
                if data.Callback then data.Callback(currentKey) end
                if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Text,
                Name = data.Text or "keybind",
                Type = "Keybind",
                Get = function() return currentKey end,
                Set = function(v, silent)
                    setKey(v, silent == true)
                end,
            })

            button.MouseButton1Click:Connect(function()
                listening = true
                menuRef._capturingKeybind = true
                keyLabel.Text = "..."
                tween(keyBg, 0.1, { BackgroundColor3 = style.BorderColor })
            end)

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        menuRef._capturingKeybind = false
                        tween(keyBg, 0.1, { BackgroundColor3 = style.ItemColor })
                        if input.KeyCode == Enum.KeyCode.Escape then setKey(Enum.KeyCode.Unknown, false)
                        else setKey(input.KeyCode, false) end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        listening = false
                        menuRef._capturingKeybind = false
                        tween(keyBg, 0.1, { BackgroundColor3 = style.ItemColor })
                        setKey(input.UserInputType, false)
                    end
                    return
                end

                if UserInputService:GetFocusedTextBox() then return end

                if currentKey ~= Enum.KeyCode.Unknown then
                    if input.KeyCode == currentKey or input.UserInputType == currentKey then
                        if data.Callback then data.Callback(currentKey) end
                    end
                end
            end))

            cacheOriginalTransparency(row)
            return {
                Set = function(newKey) setKey(newKey, false) end,
                Get = function() return currentKey end,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddInput(data)
            data = data or {}
            local value = tostring(data.Default or "")
            local row = makeRow(data.Height)
            local boxBg = Instance.new("Frame")
            boxBg.Size = UDim2.new(1, 0, 1, -8)
            boxBg.Position = UDim2.fromOffset(0, 4)
            boxBg.BackgroundColor3 = style.ItemColor
            boxBg.Parent = row
            makeCorner(boxBg, 4)
            makeStroke(boxBg, style.BorderColor, 0)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -16, 1, 0)
            box.Position = UDim2.fromOffset(8, 0)
            box.BackgroundTransparency = 1
            box.ClearTextOnFocus = false
            box.Text = value
            box.PlaceholderText = data.Placeholder or "Input"
            box.TextColor3 = style.TextColor
            box.PlaceholderColor3 = style.SubTextColor
            box.TextSize = style.NormalTextSize
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Font = style.Font
            box.Parent = boxBg

            local controlRef

            box.Focused:Connect(function() tween(boxBg, 0.16, { BackgroundColor3 = style.BorderColor }) end)
            
            local function setText(nextValue, silent)
                value = tostring(nextValue or "")
                box.Text = value
                if data.Callback then data.Callback(value, false) end
                if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end

            box.FocusLost:Connect(function(enterPressed)
                value = box.Text
                tween(boxBg, 0.16, { BackgroundColor3 = style.ItemColor })
                if data.Callback then data.Callback(box.Text, enterPressed) end
                if controlRef then menuRef:_emitChanged(controlRef.Flag) end
            end)

            controlRef = menuRef:_registerControl({
                Flag = data.Flag or data.Placeholder or data.Text,
                Name = data.Placeholder or "input",
                Type = "Input",
                Get = function() return value end,
                Set = function(v, silent) setText(v, silent) end,
            })

            cacheOriginalTransparency(row)
            return {
                Set = function(v, silent) setText(v, silent) end,
                Get = function() return value end,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddTextLabel(data)
            if typeof(data) ~= "table" then
                data = { Text = tostring(data or "Label") }
            end

            local textValue = tostring(data.Text or "Label")
            local row = makeRow(data.Height or 24)
            local label = makeLabel(row, textValue, data.TextSize or style.SmallTextSize, data.TextColor or style.SubTextColor, data.Font or style.Font, data.Align or Enum.TextXAlignment.Left)
            label.Size = UDim2.fromScale(1, 1)

            local controlRef
            if data.Flag then
                local function setText(nextText, silent)
                    textValue = tostring(nextText or "")
                    label.Text = textValue
                    if data.Callback then data.Callback(textValue) end
                    if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
                end

                controlRef = menuRef:_registerControl({
                    Flag = data.Flag,
                    Name = data.Flag,
                    Type = "TextLabel",
                    Get = function() return textValue end,
                    Set = function(v, silent) setText(v, silent) end,
                })
            end

            cacheOriginalTransparency(row)
            return {
                Instance = label,
                Set = function(v, silent)
                    textValue = tostring(v or "")
                    label.Text = textValue
                    if not silent and controlRef then menuRef:_emitChanged(controlRef.Flag) end
                end,
                Get = function() return textValue end,
                Flag = controlRef and controlRef.Flag or nil,
            }
        end

        function api:AddLabel(text)
            return api:AddTextLabel({ Text = text })
        end

        function api:AddDivider()
            local row = makeRow(10)
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = style.BorderColor
            line.BorderSizePixel = 0
            line.Parent = row
            cacheOriginalTransparency(row)
            return line
        end

        section.Position = UDim2.fromOffset(0, 8)
        section.BackgroundTransparency = 1
        tween(section, 0.22, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
        cacheOriginalTransparency(section)

        return api
    end

    tabButton.MouseButton1Click:Connect(function()
        for _, existing in ipairs(self.Tabs) do existing:SetActive(false) end
        self.CurrentTab = tab
        tab:SetActive(true)
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        self.CurrentTab = tab
        tab:SetActive(true)
    end

    return tab
end

function Library:Destroy()
    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then connection:Disconnect() end
    end
    for _, popupRef in ipairs(self._colorPopups) do
        if popupRef and popupRef.Instance and popupRef.Instance.Parent then popupRef.Instance:Destroy() end
    end
    if self.Holder then self.Holder:Destroy() end
end

return Library
