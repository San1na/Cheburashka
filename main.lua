--[[
    iOSMenu Library for Roblox
    GitHub raw link placeholder (replace with your own):
    https://raw.githubusercontent.com/USERNAME/REPOSITORY/BRANCH/main.lua
]]

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
    Width = 520,
    Height = 360,
    Draggable = true,
    UseBlur = false,
    CornerRadius = 18,
    AccentColor = Color3.fromRGB(10, 132, 255),
    BackgroundColor = Color3.fromRGB(242, 242, 247),
    SurfaceColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(28, 28, 30),
    SubTextColor = Color3.fromRGB(99, 99, 102),
    BorderColor = Color3.fromRGB(209, 209, 214),
    Font = Enum.Font.Gotham,
    SmallTextSize = 13,
    NormalTextSize = 14,
    TitleTextSize = 22,
    AnimationSpeed = 0.2,
    ItemHeight = 42,
    SafeAreaPadding = 12,
    BackgroundTransparency = 0.08,
    SurfaceTransparency = 0,
}

local function deepCopy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = typeof(v) == "table" and deepCopy(v) or v
    end
    return result
end

local function applyCorner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = instance
    return c
end

local function tween(object, speed, props)
    local tw = TweenService:Create(object, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function createText(parent, text, size, color, font, alignment)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.Font = font
    label.TextSize = size
    label.TextColor3 = color
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function addStroke(parent, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local function addPadding(parent, pad)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, pad)
    p.PaddingBottom = UDim.new(0, pad)
    p.PaddingLeft = UDim.new(0, pad)
    p.PaddingRight = UDim.new(0, pad)
    p.Parent = parent
    return p
end

local function makeButton(parent)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = parent
    return button
end

local function resolveParent(customParent)
    if customParent then
        return customParent
    end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("iOSMenuRoot")
    if existing then
        return existing
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
    for k, v in pairs(config) do
        settings[k] = v
    end

    local self = setmetatable({}, iOSMenu)
    self.Settings = settings
    self.Tabs = {}
    self.Visible = true
    self.CurrentTab = nil
    self.Connections = {}

    local root = resolveParent(settings.Parent)
    local holder = Instance.new("Frame")
    holder.Name = "Window"
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(settings.Width, settings.Height)
    holder.BackgroundColor3 = settings.BackgroundColor
    holder.BackgroundTransparency = settings.BackgroundTransparency
    holder.Parent = root
    applyCorner(holder, settings.CornerRadius)
    addStroke(holder, settings.BorderColor, 0.15)

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.6
    shadow.Size = UDim2.new(1, 70, 1, 70)
    shadow.Position = UDim2.new(0, -35, 0, -35)
    shadow.ZIndex = 0
    shadow.Parent = holder

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.Padding = UDim.new(0, 0)
    mainLayout.Parent = holder

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 72)
    header.BackgroundTransparency = 1
    header.Parent = holder

    local title = createText(header, settings.Name, settings.TitleTextSize, settings.TextColor, settings.Font, Enum.TextXAlignment.Left)
    title.Position = UDim2.fromOffset(18, 13)
    title.Size = UDim2.new(1, -120, 0, 28)

    local subtitle = createText(header, settings.Subtitle, settings.SmallTextSize, settings.SubTextColor, settings.Font, Enum.TextXAlignment.Left)
    subtitle.Position = UDim2.fromOffset(18, 40)
    subtitle.Size = UDim2.new(1, -120, 0, 20)

    local closeBtn = makeButton(header)
    closeBtn.Size = UDim2.fromOffset(36, 24)
    closeBtn.Position = UDim2.new(1, -48, 0, 14)

    local closeDot = Instance.new("Frame")
    closeDot.Size = UDim2.fromOffset(12, 12)
    closeDot.AnchorPoint = Vector2.new(0.5, 0.5)
    closeDot.Position = UDim2.fromScale(0.5, 0.5)
    closeDot.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
    closeDot.Parent = closeBtn
    applyCorner(closeDot, 999)

    local tabsBar = Instance.new("Frame")
    tabsBar.Name = "TabsBar"
    tabsBar.Size = UDim2.new(1, -24, 0, 40)
    tabsBar.Position = UDim2.fromOffset(12, 72)
    tabsBar.BackgroundColor3 = settings.SurfaceColor
    tabsBar.BackgroundTransparency = settings.SurfaceTransparency
    tabsBar.Parent = holder
    applyCorner(tabsBar, math.max(12, settings.CornerRadius - 6))
    addStroke(tabsBar, settings.BorderColor, 0.35)

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.FillDirection = Enum.FillDirection.Horizontal
    tabsLayout.Padding = UDim.new(0, 6)
    tabsLayout.Parent = tabsBar
    addPadding(tabsBar, 6)

    local pages = Instance.new("Frame")
    pages.Name = "Pages"
    pages.BackgroundTransparency = 1
    pages.Position = UDim2.fromOffset(0, 116)
    pages.Size = UDim2.new(1, 0, 1, -116)
    pages.Parent = holder

    self.Root = root
    self.Holder = holder
    self.Header = header
    self.TitleLabel = title
    self.SubtitleLabel = subtitle
    self.TabsBar = tabsBar
    self.Pages = pages

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

    table.insert(self.Connections, closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end))

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == settings.Keybind then
            self:Toggle()
        end
    end))

    return self
end

function iOSMenu:SetVisible(state)
    self.Visible = state
    if state then
        self.Holder.Visible = true
        self.Holder.Size = UDim2.fromOffset(self.Settings.Width * 0.92, self.Settings.Height * 0.92)
        self.Holder.BackgroundTransparency = 1
        tween(self.Holder, self.Settings.AnimationSpeed, {
            Size = UDim2.fromOffset(self.Settings.Width, self.Settings.Height),
            BackgroundTransparency = self.Settings.BackgroundTransparency,
        })
    else
        tween(self.Holder, self.Settings.AnimationSpeed, {
            Size = UDim2.fromOffset(self.Settings.Width * 0.92, self.Settings.Height * 0.92),
            BackgroundTransparency = 1,
        })
        task.delay(self.Settings.AnimationSpeed, function()
            self.Holder.Visible = false
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

function iOSMenu:AddTab(tabSettings)
    tabSettings = tabSettings or {}
    local name = tabSettings.Name or ("Tab " .. tostring(#self.Tabs + 1))

    local tabButton = makeButton(self.TabsBar)
    tabButton.Size = UDim2.new(0, tabSettings.Width or 120, 1, 0)

    local tabFill = Instance.new("Frame")
    tabFill.Size = UDim2.new(1, 0, 1, 0)
    tabFill.BackgroundColor3 = self.Settings.SurfaceColor
    tabFill.Parent = tabButton
    applyCorner(tabFill, 10)

    local tabStroke = addStroke(tabFill, self.Settings.BorderColor, 0.35)

    local tabText = createText(tabFill, name, self.Settings.NormalTextSize, self.Settings.SubTextColor, self.Settings.Font, Enum.TextXAlignment.Center)
    tabText.Size = UDim2.new(1, -8, 1, 0)
    tabText.Position = UDim2.fromOffset(4, 0)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 4
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = self.Pages
    addPadding(page, self.Settings.SafeAreaPadding)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page

    local tab = {
        Name = name,
        Settings = self.Settings,
        Button = tabButton,
        Fill = tabFill,
        Stroke = tabStroke,
        Label = tabText,
        Page = page,
        Elements = {},
    }

    function tab:SetActive(state)
        self.Page.Visible = state
        tween(self.Fill, 0.15, { BackgroundColor3 = state and self.Settings.AccentColor or self.Settings.SurfaceColor })
        tween(self.Label, 0.15, { TextColor3 = state and Color3.fromRGB(255, 255, 255) or self.Settings.SubTextColor })
        self.Stroke.Transparency = state and 1 or 0.35
    end

    function tab:AddSection(sectionSettings)
        sectionSettings = sectionSettings or {}
        local style = self.Settings
        local section = Instance.new("Frame")
        section.BackgroundColor3 = style.SurfaceColor
        section.BackgroundTransparency = style.SurfaceTransparency
        section.Size = UDim2.new(1, 0, 0, 44)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Parent = self.Page
        applyCorner(section, math.max(12, style.CornerRadius - 6))
        addStroke(section, style.BorderColor, 0.4)
        addPadding(section, 10)

        local sectionLayout = Instance.new("UIListLayout")
        sectionLayout.Padding = UDim.new(0, 8)
        sectionLayout.Parent = section

        local sectionTitle = createText(section, sectionSettings.Title or "Section", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
        sectionTitle.Size = UDim2.new(1, 0, 0, 20)

        if sectionSettings.Description then
            local desc = createText(section, sectionSettings.Description, style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
            desc.TextWrapped = true
            desc.AutomaticSize = Enum.AutomaticSize.Y
            desc.Size = UDim2.new(1, 0, 0, 16)
        end

        local api = {}

        local function makeRow(height)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, height or style.ItemHeight)
            row.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
            row.Parent = section
            applyCorner(row, 10)
            addStroke(row, style.BorderColor, 0.5)
            return row
        end

        function api:AddButton(data)
            data = data or {}
            local row = makeRow(data.Height)
            local btn = makeButton(row)
            btn.Size = UDim2.fromScale(1, 1)

            local text = createText(row, data.Text or "Button", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Position = UDim2.fromOffset(12, 0)
            text.Size = UDim2.new(1, -24, 1, 0)

            btn.MouseButton1Click:Connect(function()
                if data.Callback then
                    data.Callback()
                end
            end)
            return row
        end

        function api:AddToggle(data)
            data = data or {}
            local state = data.Default or false
            local row = makeRow(data.Height)
            local btn = makeButton(row)
            btn.Size = UDim2.fromScale(1, 1)

            local text = createText(row, data.Text or "Toggle", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Position = UDim2.fromOffset(12, 0)
            text.Size = UDim2.new(1, -76, 1, 0)

            local switch = Instance.new("Frame")
            switch.Size = UDim2.fromOffset(44, 24)
            switch.Position = UDim2.new(1, -56, 0.5, -12)
            switch.BackgroundColor3 = state and style.AccentColor or Color3.fromRGB(199, 199, 204)
            switch.Parent = row
            applyCorner(switch, 999)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(20, 20)
            knob.Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Parent = switch
            applyCorner(knob, 999)

            local function setState(newState)
                state = newState
                tween(switch, 0.12, { BackgroundColor3 = state and style.AccentColor or Color3.fromRGB(199, 199, 204) })
                tween(knob, 0.12, { Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) })
                if data.Callback then
                    data.Callback(state)
                end
            end

            btn.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            return {
                Set = setState,
                Get = function() return state end,
            }
        end

        function api:AddSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            local value = math.clamp(data.Default or min, min, max)
            local step = data.Step or 1
            if step <= 0 then
                step = 1
            end
            local dragging = false

            local row = makeRow(math.max(data.Height or 58, 58))
            local text = createText(row, data.Text or "Slider", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            text.Position = UDim2.fromOffset(12, 6)
            text.Size = UDim2.new(1, -84, 0, 18)

            local valueLabel = createText(row, tostring(value), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Position = UDim2.new(1, -68, 0, 8)
            valueLabel.Size = UDim2.fromOffset(56, 14)

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -24, 0, 8)
            bar.Position = UDim2.fromOffset(12, 36)
            bar.BackgroundColor3 = Color3.fromRGB(209, 209, 214)
            bar.Parent = row
            applyCorner(bar, 999)

            local fill = Instance.new("Frame")
            local range = math.max(max - min, 1)
            fill.Size = UDim2.new((value - min) / range, 0, 1, 0)
            fill.BackgroundColor3 = style.AccentColor
            fill.Parent = bar
            applyCorner(fill, 999)

            local input = makeButton(bar)
            input.Size = UDim2.fromScale(1, 1)

            local function setValue(raw)
                local normalized = min + math.floor(((raw - min) / step) + 0.5) * step
                value = math.clamp(normalized, min, max)
                local range = math.max(max - min, 1)
                fill.Size = UDim2.new((value - min) / range, 0, 1, 0)
                valueLabel.Text = tostring(value)
                if data.Callback then
                    data.Callback(value)
                end
            end

            input.MouseButton1Down:Connect(function()
                dragging = true
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local alpha = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    setValue(min + (max - min) * alpha)
                end
            end)

            return {
                Set = setValue,
                Get = function() return value end,
            }
        end

        function api:AddDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"

            local row = makeRow(data.Height)
            local btn = makeButton(row)
            btn.Size = UDim2.fromScale(1, 1)

            local titleRow = createText(row, data.Text or "Dropdown", style.NormalTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
            titleRow.Position = UDim2.fromOffset(12, 0)
            titleRow.Size = UDim2.new(0.5, 0, 1, 0)

            local valueLabel = createText(row, tostring(selected), style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Right)
            valueLabel.Position = UDim2.new(1, -130, 0, 0)
            valueLabel.Size = UDim2.new(0, 102, 1, 0)

            local menu = Instance.new("Frame")
            menu.Visible = false
            menu.Size = UDim2.new(1, 0, 0, #options * 30 + 8)
            menu.BackgroundColor3 = Color3.fromRGB(245, 245, 247)
            menu.Parent = section
            applyCorner(menu, 10)
            addStroke(menu, style.BorderColor, 0.45)
            addPadding(menu, 4)

            local menuLayout = Instance.new("UIListLayout")
            menuLayout.Padding = UDim.new(0, 4)
            menuLayout.Parent = menu

            for _, option in ipairs(options) do
                local optionBtn = makeButton(menu)
                optionBtn.Size = UDim2.new(1, 0, 0, 26)
                local optionText = createText(optionBtn, tostring(option), style.SmallTextSize, style.TextColor, style.Font, Enum.TextXAlignment.Left)
                optionText.Size = UDim2.new(1, -12, 1, 0)
                optionText.Position = UDim2.fromOffset(6, 0)
                optionBtn.MouseButton1Click:Connect(function()
                    selected = option
                    valueLabel.Text = tostring(option)
                    menu.Visible = false
                    if data.Callback then
                        data.Callback(option)
                    end
                end)
            end

            btn.MouseButton1Click:Connect(function()
                menu.Visible = not menu.Visible
            end)

            return {
                Set = function(v)
                    selected = v
                    valueLabel.Text = tostring(v)
                end,
                Get = function() return selected end,
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
            box.PlaceholderText = data.Placeholder or "Input"
            box.Text = data.Default or ""
            box.TextColor3 = style.TextColor
            box.PlaceholderColor3 = style.SubTextColor
            box.TextSize = style.NormalTextSize
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Font = style.Font
            box.Parent = row

            box.FocusLost:Connect(function(enterPressed)
                if data.Callback then
                    data.Callback(box.Text, enterPressed)
                end
            end)

            return {
                Set = function(v) box.Text = tostring(v) end,
                Get = function() return box.Text end,
            }
        end

        function api:AddLabel(text)
            local row = makeRow(32)
            row.BackgroundTransparency = 1
            local label = createText(row, text or "Label", style.SmallTextSize, style.SubTextColor, style.Font, Enum.TextXAlignment.Left)
            label.Size = UDim2.new(1, -8, 1, 0)
            label.Position = UDim2.fromOffset(8, 0)
            return label
        end

        function api:AddDivider()
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.BackgroundColor3 = style.BorderColor
            line.BackgroundTransparency = 0.5
            line.Parent = section
            return line
        end

        return api
    end

    tabButton.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.Tabs) do
            t:SetActive(false)
        end
        tab:SetActive(true)
        self.CurrentTab = tab
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:SetActive(true)
        self.CurrentTab = tab
    else
        tab:SetActive(false)
    end

    return tab
end

function iOSMenu:Destroy()
    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    if self.Holder then
        self.Holder:Destroy()
    end
end

return iOSMenu
