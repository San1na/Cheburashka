local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Library = {}
Library.__index = Library

Library.Defaults = {
    Name = "Universal Menu",
    Subtitle = "Interface",
    Parent = nil,
    Keybind = Enum.KeyCode.RightShift,
    Width = 640,
    Height = 460,
    Draggable = true,
    CornerRadius = 6,
    AccentColor = Color3.fromRGB(100, 110, 255),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    SidebarColor = Color3.fromRGB(25, 25, 25),
    SurfaceColor = Color3.fromRGB(32, 32, 32),
    TextColor = Color3.fromRGB(240, 240, 240),
    SubTextColor = Color3.fromRGB(140, 140, 140),
    BorderColor = Color3.fromRGB(45, 45, 45),
    Font = Enum.Font.Gotham,
    SmallTextSize = 12,
    NormalTextSize = 13,
    TitleTextSize = 18,
    AnimationSpeed = 0.2,
    ItemHeight = 32,
    SafeAreaPadding = 10
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

local function cacheOriginalTransparency(root)
    if not root then return end
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

local function tweenDescendants(root, speed, mode)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UICorner") or obj:IsA("UIListLayout") or obj:IsA("UIPadding") or obj:IsA("UIGradient") then continue end

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

local function clamp01(v)
    return math.clamp(v, 0, 1)
end

local function keyToText(keyCode)
    if not keyCode or keyCode == Enum.KeyCode.Unknown then return "None" end
    return keyCode.Name
end

local function colorToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function getParent(customParent)
    if customParent then return customParent end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local root = playerGui:FindFirstChild("UniversalMenuRoot")
    if root then return root end
    local gui = Instance.new("ScreenGui")
    gui.Name = "UniversalMenuRoot"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = playerGui
    return gui
end

function Library.new(config)
    config = config or {}
    local settings = deepCopy(Library.Defaults)
    for key, value in pairs(config) do settings[key] = value end

    local self = setmetatable({}, Library)
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
    holder.ClipsDescendants = true
    holder.Parent = root

    local holderScale = Instance.new("UIScale")
    holderScale.Scale = 1
    holderScale.Parent = holder
    makeCorner(holder, settings.CornerRadius)
    makeStroke(holder, settings.BorderColor, 0)
    cacheOriginalTransparency(holder)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundColor3 = settings.SidebarColor
    sidebar.BorderSizePixel = 0
    sidebar.Parent = holder

    local sidebarLine = Instance.new("Frame")
    sidebarLine.Size = UDim2.new(0, 1, 1, 0)
    sidebarLine.Position = UDim2.new(1, -1, 0, 0)
    sidebarLine.BackgroundColor3 = settings.BorderColor
    sidebarLine.BorderSizePixel = 0
    sidebarLine.Parent = sidebar

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Parent = sidebar

    local title = makeLabel(header, settings.Name, settings.TitleTextSize, settings.TextColor, settings.Font, Enum.TextXAlignment.Left)
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Position = UDim2.fromOffset(16, 14)
    title.Font = Enum.Font.GothamBold

    local subtitle = makeLabel(header, settings.Subtitle, settings.SmallTextSize, settings.SubTextColor, settings.Font, Enum.TextXAlignment.Left)
    subtitle.Size = UDim2.new(1, -24, 0, 14)
    subtitle.Position = UDim2.fromOffset(16, 36)

    local tabsContainer = Instance.new("ScrollingFrame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Size = UDim2.new(1, 0, 1, -70)
    tabsContainer.Position = UDim2.fromOffset(0, 70)
    tabsContainer.ScrollBarThickness = 0
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
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if UserInputService:GetFocusedTextBox() then return end
        if self._capturingKeybind then return end
        if input.KeyCode == self.Settings.Keybind then
            self:Toggle()
        end
    end))

    holder.Size = UDim2.fromOffset(settings.Width * 0.95, settings.Height * 0.95)
    holder.BackgroundTransparency = 1
    tween(holder, settings.AnimationSpeed, {
        Size = UDim2.fromOffset(settings.Width, settings.Height),
        BackgroundTransparency = 0,
    }, Enum.EasingStyle.Back)
    holderScale.Scale = 0.95
    tween(holderScale, settings.AnimationSpeed, { Scale = 1 }, Enum.EasingStyle.Back)

    task.defer(function()
        cacheOriginalTransparency(holder)
    end)

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

        tween(self.Holder, self.Settings.AnimationSpeed, {
            Size = UDim2.fromOffset(self.Settings.Width, self.Settings.Height),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Back)

        tween(self.HolderScale, self.Settings.AnimationSpeed, {
            Scale = 1,
        }, Enum.EasingStyle.Back)

        tweenDescendants(self.Holder, self.Settings.AnimationSpeed, "show")
    else
        local hideDuration = self.Settings.AnimationSpeed * 0.8
        for _, popupRef in ipairs(self._colorPopups) do
            if popupRef and popupRef.CloseInstant then
                popupRef:CloseInstant()
            end
        end

        tweenDescendants(self.Holder, hideDuration, "hide")
        tween(self.Holder, hideDuration, {
            Size = UDim2.fromOffset(self.Settings.Width * 0.95, self.Settings.Height * 0.95),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
        tween(self.HolderScale, hideDuration, {
            Scale = 0.95,
        }, Enum.EasingStyle.Quad)

        task.delay(hideDuration, function()
            if token ~= self._visibilityToken then return end
            if self.Holder then self.Holder.Visible = false end
        end)
    end
end

function Library:Toggle()
    self:SetVisible(not self.Visible)
end

function Library:AddTab(tabSettings)
    tabSettings = tabSettings or {}
    local style = self.Settings
    local name = tabSettings.Name or "Tab"

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
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

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -16, 0, 30)
    tabContainer.Position = UDim2.fromOffset(8, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.TabsContainer
    makeCorner(tabContainer, 4)

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
            tween(self.Container, 0.15, { BackgroundTransparency = 0.9 })
            tween(self.Indicator, 0.15, { Size = UDim2.new(0, 3, 0, 16) }, Enum.EasingStyle.Back)
            tween(self.Label, 0.15, { TextColor3 = self.Settings.TextColor })
        else
            tween(self.Container, 0.15, { BackgroundTransparency = 1 })
            tween(self.Indicator, 0.15, { Size = UDim2.new(0, 3, 0, 0) })
            tween(self.Label, 0.15, { TextColor3 = self.Settings.SubTextColor })
        end
    end

    function tab:AddSection(sectionSettings)
        sectionSettings = sectionSettings or {}
        local menuRef = self.Menu
        
        local section = Instance.new("Frame")
        section.BackgroundColor3 = style.SurfaceColor
        section.BackgroundTransparency = 0
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Size = UDim2.new(1, 0, 0, 0)
        section.Parent = page
        makeCorner(section, 4)
        makeStroke(section, style.BorderColor, 0)
        makePadding(section, 8)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = section

        local title = makeLabel(section, sectionSettings.Title or "Section", style.NormalTextSize, style.TextColor, Enum.Font.GothamMedium, Enum.TextXAlignment.Left)
        title.Size = UDim2.new(1, 0, 0, 16)

        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, 0, 0, 1)
        divider.BackgroundColor3 = style.BorderColor
        divider.BorderSizePixel = 0
        divider.Parent = section

        local function makeRow(height)
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, height or style.ItemHeight)
            row.Parent = section
            return row
        end

        local api = {}

        function api:AddToggle(data)
            data = data or {}
            local state = data.Default or false
            local row = makeRow(data.Height)
            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)

            local text = makeLabel(row, data.Text or "Toggle", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -30, 1, 0)

            local box = Instance.new("Frame")
            box.Size = UDim2.fromOffset(16, 16)
            box.Position = UDim2.new(1, -16, 0.5, -8)
            box.BackgroundColor3 = state and style.AccentColor or style.BackgroundColor
            box.Parent = row
            makeCorner(box, 3)
            local boxStroke = makeStroke(box, style.BorderColor, 0)

            local check = Instance.new("Frame")
            check.Size = UDim2.fromOffset(8, 8)
            check.Position = UDim2.fromOffset(4, 4)
            check.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            check.BackgroundTransparency = state and 0 or 1
            check.Parent = box
            makeCorner(check, 2)

            local function setState(nextState)
                state = nextState
                tween(box, 0.15, { BackgroundColor3 = state and style.AccentColor or style.BackgroundColor })
                tween(check, 0.15, { BackgroundTransparency = state and 0 or 1 })
                if state then tween(boxStroke, 0.15, { Transparency = 1 }) else tween(boxStroke, 0.15, { Transparency = 0 }) end
                if data.Callback then data.Callback(state) end
            end

            button.MouseButton1Click:Connect(function() setState(not state) end)
            cacheOriginalTransparency(row)
            return { Set = setState, Get = function() return state end }
        end

        function api:AddSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            local step = data.Step or 1
            local value = math.clamp(data.Default or min, min, max)
            local dragging = false

            local row = makeRow(36)

            local text = makeLabel(row, data.Text or "Slider", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Size = UDim2.new(1, -40, 0, 16)

            local valueLabel = makeLabel(row, tostring(value), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Size = UDim2.new(0, 40, 0, 16)
            valueLabel.Position = UDim2.new(1, -40, 0, 0)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 0, 0, 4)
            bar.Position = UDim2.fromOffset(0, 24)
            bar.BackgroundColor3 = style.BackgroundColor
            bar.Parent = row
            makeCorner(bar, 2)
            makeStroke(bar, style.BorderColor, 0)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = style.AccentColor
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.Parent = bar
            makeCorner(fill, 2)

            local function render(v)
                local range = math.max(max - min, 1)
                tween(fill, 0.1, { Size = UDim2.new((v - min) / range, 0, 1, 0) })
                valueLabel.Text = tostring(v)
            end

            local function setValue(raw)
                local rounded = min + math.floor(((raw - min) / step) + 0.5) * step
                value = math.clamp(rounded, min, max)
                render(value)
                if data.Callback then data.Callback(value) end
            end

            local input = makeButton(bar)
            input.Size = UDim2.new(1, 0, 1, 10)
            input.Position = UDim2.fromOffset(0, -5)

            input.MouseButton1Down:Connect(function() dragging = true end)
            table.insert(menuRef.Connections, UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local alpha = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    setValue(min + (max - min) * alpha)
                end
            end))
            table.insert(menuRef.Connections, UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end))

            render(value)
            cacheOriginalTransparency(row)
            return { Set = setValue, Get = function() return value end }
        end

        function api:AddButton(data)
            data = data or {}
            local row = makeRow(data.Height)
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.fromScale(1, 1)
            btnFrame.BackgroundColor3 = style.BackgroundColor
            btnFrame.Parent = row
            makeCorner(btnFrame, 4)
            makeStroke(btnFrame, style.BorderColor, 0)

            local button = makeButton(btnFrame)
            button.Size = UDim2.fromScale(1, 1)

            local text = makeLabel(btnFrame, data.Text or "Button", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Center)
            text.Size = UDim2.fromScale(1, 1)

            button.MouseButton1Down:Connect(function() tween(btnFrame, 0.1, { BackgroundColor3 = style.BorderColor }) end)
            button.MouseButton1Up:Connect(function() tween(btnFrame, 0.1, { BackgroundColor3 = style.BackgroundColor }) end)
            button.MouseLeave:Connect(function() tween(btnFrame, 0.1, { BackgroundColor3 = style.BackgroundColor }) end)
            button.MouseButton1Click:Connect(function() if data.Callback then data.Callback() end end)

            cacheOriginalTransparency(row)
            return row
        end

        function api:AddDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"
            local expanded = false

            local row = makeRow(data.Height)
            local title = makeLabel(row, data.Text or "Dropdown", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            title.Size = UDim2.new(0.5, 0, 1, 0)

            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(0.5, 0, 1, -4)
            dropFrame.Position = UDim2.new(0.5, 0, 0, 2)
            dropFrame.BackgroundColor3 = style.BackgroundColor
            dropFrame.Parent = row
            makeCorner(dropFrame, 4)
            makeStroke(dropFrame, style.BorderColor, 0)

            local hit = makeButton(dropFrame)
            hit.Size = UDim2.fromScale(1, 1)

            local valueLabel = makeLabel(dropFrame, tostring(selected), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Center)
            valueLabel.Size = UDim2.fromScale(1, 1)

            hit.MouseButton1Click:Connect(function()
                if data.Callback then data.Callback(selected) end
            end)

            cacheOriginalTransparency(row)
            return {
                Set = function(v) selected = tostring(v); valueLabel.Text = selected end,
                Get = function() return selected end
            }
        end

        section.Position = UDim2.fromOffset(0, 5)
        section.BackgroundTransparency = 1
        tween(section, 0.2, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0 })
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

return Library
