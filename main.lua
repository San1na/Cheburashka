-- 45
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local iOSMenu = {}
iOSMenu.__index = iOSMenu

iOSMenu.Defaults = {
    Name = "iOS Menu",
    Subtitle = "Library",
    Parent = nil,
    Keybind = Enum.KeyCode.RightShift,
    Width = 560,
    Height = 420,
    Draggable = true,
    UseBlur = false,
    CornerRadius = 22,
    AccentColor = Color3.fromRGB(0, 122, 255),
    BackgroundColor = Color3.fromRGB(242, 242, 247),
    SurfaceColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(28, 28, 30),
    SubTextColor = Color3.fromRGB(99, 99, 102),
    BorderColor = Color3.fromRGB(209, 209, 214),
    Font = Enum.Font.Gotham,
    SmallTextSize = 13,
    NormalTextSize = 14,
    TitleTextSize = 22,
    AnimationSpeed = 0.22,
    ItemHeight = 42,
    SafeAreaPadding = 12,
    BackgroundTransparency = 0.08,
    SurfaceTransparency = 0,
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
        TweenInfo.new(speed, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function tweenDescendants(root, speed, mode)
    if not root then
        return
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UICorner") or obj:IsA("UIListLayout") or obj:IsA("UIPadding") or obj:IsA("UIGradient") then
            continue
        end

        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            tween(obj, speed, { TextTransparency = (mode == "hide") and 1 or 0 })
        end

        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("ScrollingFrame") then
            local target = (mode == "hide") and 1 or (obj:GetAttribute("OrigBG") or 0)
            tween(obj, speed, { BackgroundTransparency = target })
        end

        if obj:IsA("ScrollingFrame") then
            local target = (mode == "hide") and 1 or (obj:GetAttribute("OrigScrollBar") or 0)
            tween(obj, speed, { ScrollBarImageTransparency = target })
        end

        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            tween(obj, speed, { ImageTransparency = (mode == "hide") and 1 or 0 })
        end

        if obj:IsA("UIStroke") then
            local target = (mode == "hide") and 1 or (obj:GetAttribute("OrigStroke") or 0)
            tween(obj, speed, { Transparency = target })
        end
    end
end

local function cacheOriginalTransparency(root)
    if not root then
        return
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("ScrollingFrame") then
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

local function keyToText(keyCode)
    if not keyCode or keyCode == Enum.KeyCode.Unknown then
        return "None"
    end
    return keyCode.Name
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

    button.MouseButton1Down:Connect(function()
        tween(scale, 0.08, { Scale = 0.97 })
    end)
    button.MouseButton1Up:Connect(function()
        tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
    button.MouseLeave:Connect(function()
        tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
end

local function getParent(customParent)
    if customParent then
        return customParent
    end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local root = playerGui:FindFirstChild("iOSMenuRoot")
    if root then
        return root
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "iOSMenuRoot"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = playerGui
    return gui
end

function iOSMenu.new(config)
    config = config or {}
    local settings = deepCopy(iOSMenu.Defaults)
    for key, value in pairs(config) do
        settings[key] = value
    end

    local self = setmetatable({}, iOSMenu)
    self.Settings = settings
    self.Tabs = {}
    self.Visible = true
    self.CurrentTab = nil
    self.Connections = {}
    self._visibilityToken = 0
    self._colorPopups = {}

    local root = getParent(settings.Parent)

    local holder = Instance.new("Frame")
    holder.Name = "Window"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(settings.Width, settings.Height)
    holder.BackgroundColor3 = settings.BackgroundColor
    holder.BackgroundTransparency = settings.BackgroundTransparency
    holder.ClipsDescendants = true
    holder.Parent = root

    local holderScale = Instance.new("UIScale")
    holderScale.Scale = 1
    holderScale.Parent = holder
    makeCorner(holder, settings.CornerRadius)
    makeStroke(holder, settings.BorderColor, 0.12)
    cacheOriginalTransparency(holder)

    local contentGroup = Instance.new("Frame")
    contentGroup.Name = "ContentGroup"
    contentGroup.BackgroundTransparency = 1
    contentGroup.Size = UDim2.fromScale(1, 1)
    contentGroup.Parent = holder

    local contentScale = Instance.new("UIScale")
    contentScale.Scale = 1
    contentScale.Parent = contentGroup

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -24, 0, 70)
    header.Position = UDim2.fromOffset(12, 8)
    header.Parent = contentGroup

    local title = makeLabel(header, settings.Name, settings.TitleTextSize, settings.TextColor, settings.Font, Enum.TextXAlignment.Left)
    title.Size = UDim2.new(1, -8, 0, 30)
    title.Position = UDim2.fromOffset(8, 6)

    local subtitle = makeLabel(header, settings.Subtitle, settings.SmallTextSize, settings.SubTextColor, settings.Font, Enum.TextXAlignment.Left)
    subtitle.Size = UDim2.new(1, -8, 0, 22)
    subtitle.Position = UDim2.fromOffset(8, 34)

    local tabsShell = Instance.new("Frame")
    tabsShell.Name = "TabsShell"
    tabsShell.Size = UDim2.new(1, -24, 0, 40)
    tabsShell.Position = UDim2.fromOffset(12, 82)
    tabsShell.BackgroundColor3 = settings.SurfaceColor
    tabsShell.BackgroundTransparency = settings.SurfaceTransparency
    tabsShell.Parent = contentGroup
    makeCorner(tabsShell, 14)
    makeStroke(tabsShell, settings.BorderColor, 0.35)

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.BackgroundColor3 = settings.AccentColor
    indicator.Size = UDim2.new(0, 0, 1, -8)
    indicator.Position = UDim2.fromOffset(4, 4)
    indicator.Parent = tabsShell
    makeCorner(indicator, 11)

    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Size = UDim2.new(1, -8, 1, -8)
    tabsContainer.Position = UDim2.fromOffset(4, 4)
    tabsContainer.Parent = tabsShell

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, 6)
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.Parent = tabsContainer

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.BackgroundTransparency = 1
    pages.ClipsDescendants = true
    pages.Size = UDim2.new(1, -24, 1, -134)
    pages.Position = UDim2.fromOffset(12, 128)
    pages.Parent = contentGroup

    self.Root = root
    self.Holder = holder
    self.Header = header
    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.TabsShell = tabsShell
    self.TabsContainer = tabsContainer
    self.Indicator = indicator
    self.Pages = pages
    self.HolderScale = holderScale
    self.ContentGroup = contentGroup
    self.ContentScale = contentScale

    local dragStart, startPos
    if settings.Draggable then
        table.insert(self.Connections, header.InputBegan:Connect(function(input)
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
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if self._capturingKeybind then
            return
        end
        if input.KeyCode == self.Settings.Keybind then
            self:Toggle()
        end
    end))

    holder.Size = UDim2.fromOffset(settings.Width * 0.94, settings.Height * 0.94)
    holder.BackgroundTransparency = 1
    tween(holder, settings.AnimationSpeed, {
        Size = UDim2.fromOffset(settings.Width, settings.Height),
        BackgroundTransparency = settings.BackgroundTransparency,
    }, Enum.EasingStyle.Back)
    holderScale.Scale = 0.97
    tween(holderScale, settings.AnimationSpeed, { Scale = 1 }, Enum.EasingStyle.Back)
    contentGroup.Position = UDim2.fromOffset(0, 8)
    contentScale.Scale = 0.985
    tween(contentGroup, settings.AnimationSpeed, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
    tween(contentScale, settings.AnimationSpeed, { Scale = 1 }, Enum.EasingStyle.Quint)

    task.defer(function()
        cacheOriginalTransparency(holder)
    end)

    return self
end

function iOSMenu:SetVisible(state)
    self._visibilityToken = self._visibilityToken + 1
    local token = self._visibilityToken
    self.Visible = state

    if state then
        self.Holder.Visible = true

        self.ContentGroup.Position = UDim2.fromOffset(0, 8)
        self.ContentScale.Scale = 0.985
        self.Holder.Size = UDim2.fromOffset(self.Settings.Width * 0.94, self.Settings.Height * 0.94)
        self.HolderScale.Scale = 0.97
        self.Holder.BackgroundTransparency = 1

        tweenDescendants(self.Holder, 0, "hide")

        tween(self.Holder, self.Settings.AnimationSpeed, {
            Size = UDim2.fromOffset(self.Settings.Width, self.Settings.Height),
            BackgroundTransparency = self.Settings.BackgroundTransparency,
        }, Enum.EasingStyle.Back)

        tween(self.HolderScale, self.Settings.AnimationSpeed, {
            Scale = 1,
        }, Enum.EasingStyle.Back)

        tween(self.ContentGroup, self.Settings.AnimationSpeed, {
            Position = UDim2.fromOffset(0, 0),
        }, Enum.EasingStyle.Quint)

        tween(self.ContentScale, self.Settings.AnimationSpeed, {
            Scale = 1,
        }, Enum.EasingStyle.Quint)

        tweenDescendants(self.Holder, self.Settings.AnimationSpeed, "show")
    else
        local hideDuration = self.Settings.AnimationSpeed * 0.9

        for _, popupRef in ipairs(self._colorPopups) do
            if popupRef and popupRef.CloseInstant then
                popupRef:CloseInstant()
            end
        end

        tweenDescendants(self.Holder, hideDuration, "hide")

        tween(self.Holder, hideDuration, {
            Size = UDim2.fromOffset(self.Settings.Width * 0.94, self.Settings.Height * 0.94),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)

        tween(self.HolderScale, hideDuration, {
            Scale = 0.97,
        }, Enum.EasingStyle.Quad)

        tween(self.ContentGroup, hideDuration, {
            Position = UDim2.fromOffset(0, 8),
        }, Enum.EasingStyle.Quint)

        tween(self.ContentScale, hideDuration, {
            Scale = 0.985,
        }, Enum.EasingStyle.Quint)

        task.delay(hideDuration, function()
            if token ~= self._visibilityToken then
                return
            end
            if self.Holder then
                self.Holder.Visible = false
            end
        end)
    end
end

function iOSMenu:Toggle()
    self:SetVisible(not self.Visible)
end

function iOSMenu:SetTitle(name, subtitle)
    self.TitleLabel.Text = name or self.TitleLabel.Text
    self.SubtitleLabel.Text = subtitle or self.SubtitleLabel.Text
end

function iOSMenu:SetKeybind(keyCode)
    if typeof(keyCode) ~= "EnumItem" or keyCode.EnumType ~= Enum.KeyCode then
        return false
    end
    self.Settings.Keybind = keyCode
    return true
end

function iOSMenu:_refreshTabs()
    local count = #self.Tabs
    if count == 0 then
        self.Indicator.Size = UDim2.new(0, 0, 1, -8)
        return
    end

    local gap = 6
    local totalGap = (count - 1) * gap
    local width = math.floor((self.TabsContainer.AbsoluteSize.X - totalGap) / count)

    for index, tab in ipairs(self.Tabs) do
        tab.Button.Size = UDim2.new(0, width, 1, 0)
        tab.Index = index
    end

    if self.CurrentTab then
        local x = (self.CurrentTab.Index - 1) * (width + gap)
        tween(self.Indicator, 0.2, { Position = UDim2.fromOffset(x + 4, 4), Size = UDim2.new(0, width, 1, -8) }, Enum.EasingStyle.Quint)
    end
end

function iOSMenu:AddTab(tabSettings)
    tabSettings = tabSettings or {}
    local style = self.Settings
    local name = tabSettings.Name or ("Tab " .. tostring(#self.Tabs + 1))

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Size = UDim2.fromScale(1, 1)
    page.Parent = self.Pages
    makePadding(page, style.SafeAreaPadding)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    cacheOriginalTransparency(page)

    local tabButton = makeButton(self.TabsContainer)
    pressAnimation(tabButton)

    local tabText = makeLabel(tabButton, name, style.NormalTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
    tabText.Size = UDim2.fromScale(1, 1)

    local tab = {
        Name = name,
        Button = tabButton,
        Label = tabText,
        Page = page,
        Settings = style,
        Menu = self,
        Index = #self.Tabs + 1,
    }

    function tab:SetActive(state)
        self.Page.Visible = state
        if state then
            self.Page.CanvasPosition = Vector2.new(0, 0)
            self.Page.Position = UDim2.fromOffset(16, 0)
            self.Page.BackgroundTransparency = 1
            tween(self.Page, 0.2, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.999 }, Enum.EasingStyle.Quart)
            tween(self.Label, 0.16, { TextColor3 = Color3.fromRGB(255, 255, 255) })
        else
            tween(self.Label, 0.16, { TextColor3 = self.Settings.SubTextColor })
        end
    end

    function tab:AddSection(sectionSettings)
        sectionSettings = sectionSettings or {}
        local menuRef = self.Menu
        local section = Instance.new("Frame")
        section.BackgroundColor3 = style.SurfaceColor
        section.BackgroundTransparency = style.SurfaceTransparency
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Size = UDim2.new(1, 0, 0, 44)
        section.Parent = page
        makeCorner(section, 14)
        makeStroke(section, style.BorderColor, 0.38)
        makePadding(section, 10)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = section

        local title = makeLabel(section, sectionSettings.Title or "Section", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
        title.Size = UDim2.new(1, 0, 0, 20)

        if sectionSettings.Description then
            local desc = makeLabel(section, sectionSettings.Description, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
            desc.Size = UDim2.new(1, 0, 0, 16)
            desc.TextWrapped = true
            desc.AutomaticSize = Enum.AutomaticSize.Y
        end

        local function makeRow(height)
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
            row.Size = UDim2.new(1, 0, 0, height or style.ItemHeight)
            row.Parent = section
            makeCorner(row, 10)
            makeStroke(row, style.BorderColor, 0.5)
            return row
        end

        local api = {}

        function api:AddButton(data)
            data = data or {}
            local row = makeRow(data.Height)
            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)
            pressAnimation(button)

            local text = makeLabel(row, data.Text or "Button", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -20, 1, 0)
            text.Position = UDim2.fromOffset(12, 0)

            button.MouseButton1Click:Connect(function()
                if data.Callback then
                    data.Callback()
                end
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
            text.Position = UDim2.fromOffset(12, 0)

            local switch = Instance.new("Frame")
            switch.Size = UDim2.fromOffset(44, 24)
            switch.Position = UDim2.new(1, -56, 0.5, -12)
            switch.BackgroundColor3 = state and style.AccentColor or Color3.fromRGB(199, 199, 204)
            switch.Parent = row
            makeCorner(switch, 999)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(20, 20)
            knob.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Parent = switch
            makeCorner(knob, 999)

            local function setState(nextState)
                state = nextState
                tween(switch, 0.16, { BackgroundColor3 = state and style.AccentColor or Color3.fromRGB(199, 199, 204) }, Enum.EasingStyle.Quint)
                tween(knob, 0.16, { Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) }, Enum.EasingStyle.Quint)
                if data.Callback then
                    data.Callback(state)
                end
            end

            button.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            cacheOriginalTransparency(row)
            return {
                Set = setState,
                Get = function()
                    return state
                end,
            }
        end

        function api:AddSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            local step = data.Step or 1
            if step <= 0 then
                step = 1
            end
            local value = math.clamp(data.Default or min, min, max)
            local dragging = false

            local row = makeRow(math.max(58, data.Height or 58))

            local text = makeLabel(row, data.Text or "Slider", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -84, 0, 20)
            text.Position = UDim2.fromOffset(12, 6)

            local valueLabel = makeLabel(row, tostring(value), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Size = UDim2.fromOffset(56, 14)
            valueLabel.Position = UDim2.new(1, -68, 0, 8)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -24, 0, 8)
            bar.Position = UDim2.fromOffset(12, 36)
            bar.BackgroundColor3 = Color3.fromRGB(209, 209, 214)
            bar.Parent = row
            makeCorner(bar, 999)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = style.AccentColor
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = bar
            makeCorner(fill, 999)

            local function render(v)
                local range = math.max(max - min, 1)
                tween(fill, 0.12, { Size = UDim2.new((v - min) / range, 0, 1, 0) }, Enum.EasingStyle.Quint)
                valueLabel.Text = tostring(v)
            end

            local function setValue(raw)
                local rounded = min + math.floor(((raw - min) / step) + 0.5) * step
                value = math.clamp(rounded, min, max)
                render(value)
                if data.Callback then
                    data.Callback(value)
                end
            end

            local input = makeButton(bar)
            input.Size = UDim2.fromScale(1, 1)

            input.MouseButton1Down:Connect(function()
                dragging = true
            end)

            table.insert(menuRef.Connections, UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local alpha = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    setValue(min + (max - min) * alpha)
                end
            end))

            table.insert(menuRef.Connections, UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            render(value)
            cacheOriginalTransparency(row)

            return {
                Set = setValue,
                Get = function()
                    return value
                end,
            }
        end

        function api:AddDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"
            local expanded = false
            local optionRows = {}
            local optionsHeight = 0

            local row = makeRow(data.Height)

            local hit = makeButton(row)
            hit.Size = UDim2.fromScale(1, 1)
            pressAnimation(hit)

            local title = makeLabel(row, data.Text or "Dropdown", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(0.45, 0, 0, style.ItemHeight)
            title.Position = UDim2.fromOffset(12, 0)

            local valueLabel = makeLabel(row, tostring(selected), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Size = UDim2.new(0.45, -12, 0, style.ItemHeight)
            valueLabel.Position = UDim2.new(0.55, 0, 0, 0)

            local popup = Instance.new("Frame")
            popup.Visible = false
            popup.ClipsDescendants = true
            popup.BackgroundColor3 = style.SurfaceColor
            popup.BackgroundTransparency = 1
            popup.Position = UDim2.fromOffset(4, row.AbsoluteSize.Y + 4)
            popup.Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), 0)
            popup.ZIndex = 40
            popup.Parent = row
            makeCorner(popup, 10)
            local popupStroke = makeStroke(popup, style.BorderColor, 1)

            local popupScale = Instance.new("UIScale")
            popupScale.Scale = 0.98
            popupScale.Parent = popup

            local popupPad = Instance.new("UIPadding")
            popupPad.PaddingTop = UDim.new(0, 4)
            popupPad.PaddingBottom = UDim.new(0, 4)
            popupPad.PaddingLeft = UDim.new(0, 4)
            popupPad.PaddingRight = UDim.new(0, 4)
            popupPad.Parent = popup

            local panelLayout = Instance.new("UIListLayout")
            panelLayout.Padding = UDim.new(0, 3)
            panelLayout.Parent = popup

            local function containsPoint(gui, point)
                local pos = gui.AbsolutePosition
                local size = gui.AbsoluteSize
                return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
            end

            local function refreshPopupPlacement()
                popup.Position = UDim2.fromOffset(4, row.AbsoluteSize.Y + 4)
                local width = math.max(row.AbsoluteSize.X - 8, 120)
                popup.Size = UDim2.fromOffset(width, expanded and optionsHeight or 0)
            end

            local function updateStyles()
                for optionName, ref in pairs(optionRows) do
                    local active = (selected == optionName)
                    tween(ref.Marker, 0.12, { BackgroundTransparency = active and 0 or 1 }, Enum.EasingStyle.Quint)
                    tween(ref.Text, 0.12, { TextColor3 = active and style.TextColor or style.SubTextColor }, Enum.EasingStyle.Quint)
                    tween(ref.Button, 0.12, { BackgroundTransparency = active and 0.85 or 1 }, Enum.EasingStyle.Quint)
                end
            end

            local function setExpanded(state)
                expanded = state
                if expanded then
                    popup.Visible = true
                    popupScale.Scale = 0.98
                    popup.BackgroundTransparency = 1
                    popupStroke.Transparency = 1
                    refreshPopupPlacement()
                    tween(popup, 0.16, { Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), optionsHeight), BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
                    tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Quint)
                    tween(popupStroke, 0.16, { Transparency = 0.45 }, Enum.EasingStyle.Quint)
                else
                    tween(popup, 0.14, { Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
                    tween(popupScale, 0.14, { Scale = 0.98 }, Enum.EasingStyle.Quint)
                    tween(popupStroke, 0.14, { Transparency = 1 }, Enum.EasingStyle.Quint)
                    task.delay(0.14, function()
                        if popup and popup.Parent and not expanded then
                            popup.Visible = false
                        end
                    end)
                end
            end

            local function clearOptions()
                for _, ref in pairs(optionRows) do
                    if ref.Button then
                        ref.Button:Destroy()
                    end
                end
                optionRows = {}
                optionsHeight = 0
            end

            local function rebuild(newOptions)
                clearOptions()

                local seen = {}
                for _, option in ipairs(newOptions or {}) do
                    local optionName = tostring(option)
                    if not seen[optionName] then
                        seen[optionName] = true

                        local optionButton = Instance.new("TextButton")
                        optionButton.AutoButtonColor = false
                        optionButton.Text = ""
                        optionButton.BackgroundTransparency = 1
                        optionButton.BackgroundColor3 = Color3.fromRGB(245, 245, 248)
                        optionButton.Size = UDim2.new(1, -6, 0, 28)
                        optionButton.ZIndex = 41
                        optionButton.Parent = popup
                        makeCorner(optionButton, 8)

                        local optionText = makeLabel(optionButton, optionName, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
                        optionText.Size = UDim2.new(1, -28, 1, 0)
                        optionText.Position = UDim2.fromOffset(10, 0)
                        optionText.ZIndex = 42

                        local marker = Instance.new("Frame")
                        marker.Size = UDim2.fromOffset(10, 10)
                        marker.Position = UDim2.new(1, -16, 0.5, -5)
                        marker.BackgroundColor3 = style.AccentColor
                        marker.BackgroundTransparency = 1
                        marker.ZIndex = 42
                        marker.Parent = optionButton
                        makeCorner(marker, 999)

                        optionRows[optionName] = {
                            Button = optionButton,
                            Text = optionText,
                            Marker = marker,
                        }

                        optionButton.MouseButton1Click:Connect(function()
                            selected = optionName
                            valueLabel.Text = optionName
                            updateStyles()
                            setExpanded(false)
                            if data.Callback then
                                data.Callback(optionName)
                            end
                        end)

                        optionsHeight = optionsHeight + 31
                    end
                end

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

            hit.MouseButton1Click:Connect(function()
                setExpanded(not expanded)
            end)

            table.insert(menuRef.Connections, row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                refreshPopupPlacement()
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not expanded then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if not containsPoint(row, input.Position) and not containsPoint(popup, input.Position) then
                    setExpanded(false)
                end
            end))

            rebuild(options)
            cacheOriginalTransparency(row)

            return {
                Set = function(value)
                    local nextValue = tostring(value)
                    if optionRows[nextValue] then
                        selected = nextValue
                        valueLabel.Text = nextValue
                        updateStyles()
                        if data.Callback then
                            data.Callback(nextValue)
                        end
                    end
                end,
                Get = function()
                    return selected
                end,
                SetOptions = function(newOptions)
                    rebuild(newOptions)
                end,
            }
        end

        function api:AddMultiBoolean(data)
            data = data or {}
            local options = data.Options or {}
            local states = {}
            local expanded = false
            local optionRows = {}
            local optionsHeight = 0

            local row = makeRow(data.Height)

            local hit = makeButton(row)
            hit.Size = UDim2.fromScale(1, 1)
            pressAnimation(hit)

            local title = makeLabel(row, data.Text or "MultiBoolean", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(0.45, 0, 0, style.ItemHeight)
            title.Position = UDim2.fromOffset(12, 0)

            local valueLabel = makeLabel(row, "None", style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Size = UDim2.new(0.45, -12, 0, style.ItemHeight)
            valueLabel.Position = UDim2.new(0.55, 0, 0, 0)

            local popup = Instance.new("Frame")
            popup.Visible = false
            popup.ClipsDescendants = true
            popup.BackgroundColor3 = style.SurfaceColor
            popup.BackgroundTransparency = 1
            popup.Position = UDim2.fromOffset(4, row.AbsoluteSize.Y + 4)
            popup.Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), 0)
            popup.ZIndex = 40
            popup.Parent = row
            makeCorner(popup, 10)
            local popupStroke = makeStroke(popup, style.BorderColor, 1)

            local popupScale = Instance.new("UIScale")
            popupScale.Scale = 0.98
            popupScale.Parent = popup

            local popupPad = Instance.new("UIPadding")
            popupPad.PaddingTop = UDim.new(0, 4)
            popupPad.PaddingBottom = UDim.new(0, 4)
            popupPad.PaddingLeft = UDim.new(0, 4)
            popupPad.PaddingRight = UDim.new(0, 4)
            popupPad.Parent = popup

            local panelLayout = Instance.new("UIListLayout")
            panelLayout.Padding = UDim.new(0, 3)
            panelLayout.Parent = popup

            local function containsPoint(gui, point)
                local pos = gui.AbsolutePosition
                local size = gui.AbsoluteSize
                return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
            end

            local function refreshPopupPlacement()
                popup.Position = UDim2.fromOffset(4, row.AbsoluteSize.Y + 4)
                local width = math.max(row.AbsoluteSize.X - 8, 120)
                popup.Size = UDim2.fromOffset(width, expanded and optionsHeight or 0)
            end

            local function updateSummary()
                local count = 0
                for _, enabled in pairs(states) do
                    if enabled then
                        count = count + 1
                    end
                end

                if count == 0 then
                    valueLabel.Text = "None"
                elseif count == 1 then
                    for optionName, enabled in pairs(states) do
                        if enabled then
                            valueLabel.Text = optionName
                            break
                        end
                    end
                else
                    valueLabel.Text = tostring(count) .. " selected"
                end
            end

            local function updateOptionVisual(option)
                local ref = optionRows[option]
                if not ref then
                    return
                end

                local active = states[option] == true
                tween(ref.Knob, 0.12, {
                    Position = active and UDim2.fromOffset(14, 2) or UDim2.fromOffset(2, 2),
                }, Enum.EasingStyle.Quint)
                tween(ref.Switch, 0.12, {
                    BackgroundColor3 = active and style.AccentColor or Color3.fromRGB(207, 207, 214),
                }, Enum.EasingStyle.Quint)
                tween(ref.Text, 0.12, {
                    TextColor3 = active and style.TextColor or style.SubTextColor,
                }, Enum.EasingStyle.Quint)
            end

            local function setExpanded(state)
                expanded = state
                if expanded then
                    popup.Visible = true
                    popupScale.Scale = 0.98
                    popup.BackgroundTransparency = 1
                    popupStroke.Transparency = 1
                    refreshPopupPlacement()
                    tween(popup, 0.16, { Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), optionsHeight), BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
                    tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Quint)
                    tween(popupStroke, 0.16, { Transparency = 0.45 }, Enum.EasingStyle.Quint)
                else
                    tween(popup, 0.14, { Size = UDim2.fromOffset(math.max(row.AbsoluteSize.X - 8, 120), 0), BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
                    tween(popupScale, 0.14, { Scale = 0.98 }, Enum.EasingStyle.Quint)
                    tween(popupStroke, 0.14, { Transparency = 1 }, Enum.EasingStyle.Quint)
                    task.delay(0.14, function()
                        if popup and popup.Parent and not expanded then
                            popup.Visible = false
                        end
                    end)
                end
            end

            local function setOption(option, state, silent)
                option = tostring(option)
                if states[option] == nil then
                    return
                end
                states[option] = state and true or false
                updateOptionVisual(option)
                updateSummary()

                if not silent and data.Callback then
                    data.Callback(option, states[option], states)
                end
            end

            local function clearOptions()
                for _, ref in pairs(optionRows) do
                    if ref.Button then
                        ref.Button:Destroy()
                    end
                end
                optionRows = {}
                states = {}
                optionsHeight = 0
            end

            local function rebuild(newOptions, defaults)
                clearOptions()
                local seen = {}

                for _, option in ipairs(newOptions or {}) do
                    local optionName = tostring(option)
                    if not seen[optionName] then
                        seen[optionName] = true

                        local optionButton = Instance.new("TextButton")
                        optionButton.AutoButtonColor = false
                        optionButton.Text = ""
                        optionButton.BackgroundTransparency = 1
                        optionButton.BackgroundColor3 = Color3.fromRGB(245, 245, 248)
                        optionButton.Size = UDim2.new(1, -6, 0, 28)
                        optionButton.ZIndex = 41
                        optionButton.Parent = popup
                        makeCorner(optionButton, 8)

                        local optionText = makeLabel(optionButton, optionName, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
                        optionText.Size = UDim2.new(1, -42, 1, 0)
                        optionText.Position = UDim2.fromOffset(10, 0)
                        optionText.ZIndex = 42

                        local switch = Instance.new("Frame")
                        switch.Size = UDim2.fromOffset(28, 12)
                        switch.Position = UDim2.new(1, -34, 0.5, -6)
                        switch.BackgroundColor3 = Color3.fromRGB(207, 207, 214)
                        switch.ZIndex = 42
                        switch.Parent = optionButton
                        makeCorner(switch, 999)

                        local knob = Instance.new("Frame")
                        knob.Size = UDim2.fromOffset(8, 8)
                        knob.Position = UDim2.fromOffset(2, 2)
                        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        knob.ZIndex = 43
                        knob.Parent = switch
                        makeCorner(knob, 999)

                        states[optionName] = typeof(defaults) == "table" and defaults[optionName] == true or false
                        optionRows[optionName] = {
                            Button = optionButton,
                            Text = optionText,
                            Switch = switch,
                            Knob = knob,
                        }

                        optionButton.MouseButton1Click:Connect(function()
                            setOption(optionName, not states[optionName], false)
                        end)

                        optionsHeight = optionsHeight + 31
                    end
                end

                refreshPopupPlacement()

                for optionName in pairs(optionRows) do
                    updateOptionVisual(optionName)
                end
                updateSummary()
            end

            hit.MouseButton1Click:Connect(function()
                setExpanded(not expanded)
            end)

            table.insert(menuRef.Connections, row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                refreshPopupPlacement()
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not expanded then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if not containsPoint(row, input.Position) and not containsPoint(popup, input.Position) then
                    setExpanded(false)
                end
            end))

            rebuild(options, data.Default)
            cacheOriginalTransparency(row)

            return {
                Set = function(option, newState, silent)
                    setOption(option, newState, silent)
                end,
                Get = function(option)
                    if option ~= nil then
                        return states[tostring(option)] == true
                    end

                    local out = {}
                    for k, v in pairs(states) do
                        out[k] = v
                    end
                    return out
                end,
                SetOptions = function(newOptions, defaults)
                    rebuild(newOptions, defaults)
                end,
            }
        end

        function api:AddColorPicker(data)
            data = data or {}
            local titleText = data.Text or "Color Picker"
            local currentColor = data.Default or style.AccentColor
            local h, s, v = Color3.toHSV(currentColor)
            local isOpen = false
            local dragMode = nil

            local row = makeRow(data.Height)
            local rowButton = makeButton(row)
            rowButton.Size = UDim2.fromScale(1, 1)
            pressAnimation(rowButton)

            local title = makeLabel(row, titleText, style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(1, -140, 1, 0)
            title.Position = UDim2.fromOffset(12, 0)

            local hexLabel = makeLabel(row, colorToHex(currentColor), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            hexLabel.Size = UDim2.new(0, 78, 1, 0)
            hexLabel.Position = UDim2.new(1, -106, 0, 0)

            local preview = Instance.new("Frame")
            preview.Size = UDim2.fromOffset(18, 18)
            preview.Position = UDim2.new(1, -24, 0.5, -9)
            preview.BackgroundColor3 = currentColor
            preview.Parent = row
            makeCorner(preview, 999)
            makeStroke(preview, Color3.fromRGB(255, 255, 255), 0.35)

            local popup = Instance.new("Frame")
            popup.Name = "ColorPopup"
            popup.Visible = false
            popup.Size = UDim2.fromOffset(220, 166)
            popup.BackgroundColor3 = Color3.fromRGB(246, 246, 248)
            popup.BackgroundTransparency = 1
            popup.ZIndex = 20
            popup.Parent = menuRef.Root
            makeCorner(popup, 12)
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
            makeCorner(sv, 8)

            local whiteLayer = Instance.new("Frame")
            whiteLayer.Size = UDim2.fromScale(1, 1)
            whiteLayer.BackgroundColor3 = Color3.new(1, 1, 1)
            whiteLayer.ZIndex = 22
            whiteLayer.Parent = sv
            makeCorner(whiteLayer, 8)

            local whiteGradient = Instance.new("UIGradient")
            whiteGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
            whiteGradient.Rotation = 0
            whiteGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            whiteGradient.Parent = whiteLayer

            local blackLayer = Instance.new("Frame")
            blackLayer.Size = UDim2.fromScale(1, 1)
            blackLayer.BackgroundColor3 = Color3.new(0, 0, 0)
            blackLayer.ZIndex = 23
            blackLayer.Parent = sv
            makeCorner(blackLayer, 8)

            local blackGradient = Instance.new("UIGradient")
            blackGradient.Rotation = 90
            blackGradient.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0))
            blackGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
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
            makeCorner(hueBar, 8)

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

            local function updateVisuals(emit)
                currentColor = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = currentColor
                hexLabel.Text = colorToHex(currentColor)
                sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                tween(svCursor, 0.08, { Position = UDim2.new(s, 0, 1 - v, 0) }, Enum.EasingStyle.Quint)
                tween(hueCursor, 0.08, { Position = UDim2.new(0.5, 0, h, 0) }, Enum.EasingStyle.Quint)
                if emit and data.Callback then
                    data.Callback(currentColor)
                end
            end

            local popupApi

            local function updatePopupPosition()
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
                updateVisuals(true)
            end

            local function setFromHue(pos)
                h = clamp01((pos.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1))
                updateVisuals(true)
            end

            local function openPopup()
                for _, popupRef in ipairs(menuRef._colorPopups) do
                    if popupRef and popupRef ~= popupApi and popupRef.CloseInstant then
                        popupRef:CloseInstant()
                    end
                end

                updatePopupPosition()
                popup.Visible = true
                popup.BackgroundTransparency = 1
                popupStroke.Transparency = 1
                popupScale.Scale = 0.96

                tweenDescendants(popup, 0, "hide")
                tween(popupScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Back)
                tween(popup, 0.16, { BackgroundTransparency = 0.04 }, Enum.EasingStyle.Quint)
                tween(popupStroke, 0.16, { Transparency = 0.35 }, Enum.EasingStyle.Quint)
                tweenDescendants(popup, 0.16, "show")

                isOpen = true
            end

            local function closePopup()
                if not isOpen then
                    return
                end
                isOpen = false

                tween(popupScale, 0.12, { Scale = 0.96 }, Enum.EasingStyle.Quad)
                tween(popup, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
                tween(popupStroke, 0.12, { Transparency = 1 }, Enum.EasingStyle.Quad)
                tweenDescendants(popup, 0.12, "hide")

                task.delay(0.12, function()
                    if popup and popup.Parent and not isOpen then
                        popup.Visible = false
                    end
                end)
            end

            popupApi = {}
            popupApi.Instance = popup

            function popupApi:CloseInstant()
                isOpen = false
                dragMode = nil
                popup.Visible = false
                popup.BackgroundTransparency = 1
                popupStroke.Transparency = 1
                popupScale.Scale = 0.96
                tweenDescendants(popup, 0, "hide")
            end

            table.insert(menuRef._colorPopups, popupApi)

            rowButton.MouseButton1Click:Connect(function()
                if isOpen then
                    closePopup()
                else
                    openPopup()
                end
            end)

            svHit.MouseButton1Down:Connect(function()
                dragMode = "sv"
                setFromSV(UserInputService:GetMouseLocation())
            end)

            hueHit.MouseButton1Down:Connect(function()
                dragMode = "hue"
                setFromHue(UserInputService:GetMouseLocation())
            end)

            table.insert(menuRef.Connections, UserInputService.InputChanged:Connect(function(input)
                if not dragMode then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if dragMode == "sv" then
                    setFromSV(input.Position)
                else
                    setFromHue(input.Position)
                end
            end))

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if not isOpen then
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                local p = input.Position
                local inPopup = p.X >= popup.AbsolutePosition.X and p.X <= popup.AbsolutePosition.X + popup.AbsoluteSize.X
                    and p.Y >= popup.AbsolutePosition.Y and p.Y <= popup.AbsolutePosition.Y + popup.AbsoluteSize.Y
                local inRow = p.X >= row.AbsolutePosition.X and p.X <= row.AbsolutePosition.X + row.AbsoluteSize.X
                    and p.Y >= row.AbsolutePosition.Y and p.Y <= row.AbsolutePosition.Y + row.AbsoluteSize.Y
                if not inPopup and not inRow then
                    closePopup()
                end
            end))

            table.insert(menuRef.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragMode = nil
                end
            end))

            updateVisuals(false)
            cacheOriginalTransparency(row)
            cacheOriginalTransparency(popup)

            return {
                Set = function(color)
                    local newH, newS, newV = Color3.toHSV(color)
                    h, s, v = newH, newS, newV
                    updateVisuals(true)
                end,
                Get = function()
                    return currentColor
                end,
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
            title.Position = UDim2.fromOffset(12, 0)

            local keyLabel = makeLabel(row, keyToText(currentKey), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            keyLabel.Size = UDim2.new(0, 90, 1, 0)
            keyLabel.Position = UDim2.new(1, -102, 0, 0)

            local function setKey(newKey, trigger)
                if typeof(newKey) ~= "EnumItem" or newKey.EnumType ~= Enum.KeyCode then
                    return
                end
                currentKey = newKey
                keyLabel.Text = keyToText(currentKey)
                if trigger and data.OnChanged then
                    data.OnChanged(currentKey)
                end
            end

            button.MouseButton1Click:Connect(function()
                listening = true
                menuRef._capturingKeybind = true
                keyLabel.Text = "..."
            end)

            table.insert(menuRef.Connections, UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then
                    return
                end

                if listening then
                    listening = false
                    menuRef._capturingKeybind = false
                    if input.KeyCode == Enum.KeyCode.Escape then
                        setKey(Enum.KeyCode.Unknown, true)
                    else
                        setKey(input.KeyCode, true)
                    end
                    return
                end

                if UserInputService:GetFocusedTextBox() then
                    return
                end
                if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
                    if data.Callback then
                        data.Callback(currentKey)
                    end
                end
            end))

            cacheOriginalTransparency(row)
            return {
                Set = function(newKey)
                    setKey(newKey, false)
                end,
                Get = function()
                    return currentKey
                end,
            }
        end

        function api:AddInput(data)
            data = data or {}
            local row = makeRow(data.Height)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -20, 1, 0)
            box.Position = UDim2.fromOffset(10, 0)
            box.BackgroundTransparency = 1
            box.ClearTextOnFocus = false
            box.Text = data.Default or ""
            box.PlaceholderText = data.Placeholder or "Input"
            box.TextColor3 = style.TextColor
            box.PlaceholderColor3 = style.SubTextColor
            box.TextSize = style.NormalTextSize
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Font = style.Font
            box.Parent = row

            box.Focused:Connect(function()
                tween(row, 0.16, { BackgroundColor3 = Color3.fromRGB(241, 246, 255) }, Enum.EasingStyle.Quint)
            end)
            box.FocusLost:Connect(function(enterPressed)
                tween(row, 0.16, { BackgroundColor3 = Color3.fromRGB(248, 248, 250) }, Enum.EasingStyle.Quint)
                if data.Callback then
                    data.Callback(box.Text, enterPressed)
                end
            end)

            cacheOriginalTransparency(row)
            return {
                Set = function(v)
                    box.Text = tostring(v)
                end,
                Get = function()
                    return box.Text
                end,
            }
        end

        function api:AddLabel(text)
            local row = makeRow(32)
            row.BackgroundTransparency = 1
            local label = makeLabel(row, text or "Label", style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
            label.Size = UDim2.new(1, -10, 1, 0)
            label.Position = UDim2.fromOffset(8, 0)
            cacheOriginalTransparency(row)
            return label
        end

        function api:AddDivider()
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.BackgroundColor3 = style.BorderColor
            line.BackgroundTransparency = 0.45
            line.Parent = section
            cacheOriginalTransparency(section)
            return line
        end

        section.Position = UDim2.fromOffset(0, 8)
        section.BackgroundTransparency = 1
        tween(section, 0.22, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = style.SurfaceTransparency }, Enum.EasingStyle.Quart)
        cacheOriginalTransparency(section)

        return api
    end

    tabButton.MouseButton1Click:Connect(function()
        for _, existing in ipairs(self.Tabs) do
            existing:SetActive(false)
        end
        self.CurrentTab = tab
        tab:SetActive(true)
        self:_refreshTabs()
    end)

    table.insert(self.Tabs, tab)
    self:_refreshTabs()

    if #self.Tabs == 1 then
        self.CurrentTab = tab
        tab:SetActive(true)
        self:_refreshTabs()
    end

    if not self._tabsResizeConnection then
        self._tabsResizeConnection = self.TabsContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:_refreshTabs()
        end)
        table.insert(self.Connections, self._tabsResizeConnection)
    end

    return tab
end

function iOSMenu:Destroy()
    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    for _, popupRef in ipairs(self._colorPopups) do
        if popupRef and popupRef.Instance and popupRef.Instance.Parent then
            popupRef.Instance:Destroy()
        end
    end
    if self.Holder then
        self.Holder:Destroy()
    end
end

return iOSMenu
