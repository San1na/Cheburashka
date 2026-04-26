local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/San1na/Cheburashka/refs/heads/main/mainTest2.lua"))()
local ConfigSys = loadstring(game:HttpGet("https://raw.githubusercontent.com/San1na/Cheburashka/refs/heads/main/configSys.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local MathFloor = math.floor
local MathMin = math.min
local MathMax = math.max

local Settings = {
    ESP = {
        Enabled = false,
        Box = true,
        HealthBar = true,
        Name = true,
        Distance = true,
        TeamCheck = false,
        Color = Color3.fromRGB(0, 122, 255),
        TextSize = 13,
    },
    Aimbot = {
        Enabled = false,
        Aiming = false,
        Key = Enum.UserInputType.MouseButton2,
        Smoothness = 0.5,
        FOV = 100,
        ShowFOV = true,
        TargetPart = "Head",
        TeamCheck = false,
        FOVColor = Color3.fromRGB(0, 122, 255),
    },
    UI = {
        MenuKeybind = Enum.KeyCode.RightShift,
    },
}

local function mergeInto(target, source)
    for k, v in pairs(source) do
        if typeof(v) == "table" and typeof(target[k]) == "table" then
            mergeInto(target[k], v)
        else
            target[k] = v
        end
    end
end

local DrawingWrapper = {}
DrawingWrapper.__index = DrawingWrapper

function DrawingWrapper.new(type, properties)
    local self = setmetatable({}, DrawingWrapper)
    self.Instance = Drawing.new(type)

    for k, v in pairs(properties or {}) do
        self.Instance[k] = v
    end

    return self
end

function DrawingWrapper:Update(properties)
    for k, v in pairs(properties) do
        self.Instance[k] = v
    end
end

function DrawingWrapper:Remove()
    if self.Instance then
        self.Instance:Remove()
        self.Instance = nil
    end
end

local ESP = {}
ESP.__index = ESP

function ESP.new(player)
    local self = setmetatable({}, ESP)
    self.Player = player

    self.Drawings = {
        BoxOutline = DrawingWrapper.new("Square", { Color = Color3.new(0, 0, 0), Thickness = 3, Filled = false }),
        Box = DrawingWrapper.new("Square", { Thickness = 1, Filled = false }),
        HealthOutline = DrawingWrapper.new("Square", { Color = Color3.new(0, 0, 0), Thickness = 1, Filled = true }),
        Health = DrawingWrapper.new("Square", { Color = Color3.new(0, 1, 0), Thickness = 1, Filled = true }),
        Name = DrawingWrapper.new("Text", { Center = true, Outline = true, Color = Color3.new(1, 1, 1) }),
        Distance = DrawingWrapper.new("Text", { Center = true, Outline = true, Color = Color3.new(1, 1, 1) }),
    }

    return self
end

function ESP:Validate()
    if not self.Player then
        return false
    end
    if not self.Player.Character then
        return false
    end
    if not self.Player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if not self.Player.Character:FindFirstChild("Humanoid") then
        return false
    end
    if self.Player.Character.Humanoid.Health <= 0 then
        return false
    end
    if Settings.ESP.TeamCheck and self.Player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

function ESP:Update()
    local drawings = self.Drawings

    if not Settings.ESP.Enabled or not self:Validate() then
        for _, drawing in pairs(drawings) do
            drawing:Update({ Visible = false })
        end
        return
    end

    local character = self.Player.Character
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

    if onScreen then
        local rootTop = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.5, 0))
        local rootBottom = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        local height = MathMax(MathFloor(rootBottom.Y - rootTop.Y), 10)
        local width = MathMax(MathFloor(height / 2), 5)

        local boxPosition = Vector2.new(MathFloor(vector.X - width / 2), MathFloor(rootTop.Y))
        local boxSize = Vector2.new(width, height)

        if Settings.ESP.Box then
            drawings.BoxOutline:Update({ Visible = true, Position = boxPosition, Size = boxSize })
            drawings.Box:Update({ Visible = true, Position = boxPosition, Size = boxSize, Color = Settings.ESP.Color })
        else
            drawings.BoxOutline:Update({ Visible = false })
            drawings.Box:Update({ Visible = false })
        end

        if Settings.ESP.HealthBar then
            local healthFactor = MathMax(MathMin(humanoid.Health / humanoid.MaxHealth, 1), 0)
            local healthHeight = MathFloor(height * healthFactor)

            local healthBarPosition = Vector2.new(boxPosition.X - 5, boxPosition.Y)
            local healthBarSize = Vector2.new(3, height)
            local currentHealthPosition = Vector2.new(boxPosition.X - 4, boxPosition.Y + (height - healthHeight))
            local currentHealthSize = Vector2.new(1, healthHeight)

            local r = 255 - MathFloor(healthFactor * 255)
            local g = MathFloor(healthFactor * 255)

            drawings.HealthOutline:Update({ Visible = true, Position = healthBarPosition, Size = healthBarSize })
            drawings.Health:Update({ Visible = true, Position = currentHealthPosition, Size = currentHealthSize, Color = Color3.fromRGB(r, g, 0) })
        else
            drawings.HealthOutline:Update({ Visible = false })
            drawings.Health:Update({ Visible = false })
        end

        if Settings.ESP.Name then
            drawings.Name:Update({
                Visible = true,
                Text = self.Player.Name,
                Position = Vector2.new(vector.X, boxPosition.Y - Settings.ESP.TextSize - 2),
                Size = Settings.ESP.TextSize,
                Color = Settings.ESP.Color,
            })
        else
            drawings.Name:Update({ Visible = false })
        end

        if Settings.ESP.Distance then
            local dist = MathFloor((rootPart.Position - Camera.CFrame.Position).Magnitude)
            drawings.Distance:Update({
                Visible = true,
                Text = tostring(dist) .. "m",
                Position = Vector2.new(vector.X, boxPosition.Y + height + 2),
                Size = Settings.ESP.TextSize,
            })
        else
            drawings.Distance:Update({ Visible = false })
        end
    else
        for _, drawing in pairs(drawings) do
            drawing:Update({ Visible = false })
        end
    end
end

function ESP:Destroy()
    for _, drawing in pairs(self.Drawings) do
        drawing:Remove()
    end
end

local ESPManager = {}
ESPManager.__index = ESPManager

function ESPManager.new()
    local self = setmetatable({}, ESPManager)
    self.Cache = {}
    return self
end

function ESPManager:AddPlayer(player)
    if player == LocalPlayer then
        return
    end
    if not self.Cache[player] then
        self.Cache[player] = ESP.new(player)
    end
end

function ESPManager:RemovePlayer(player)
    if self.Cache[player] then
        self.Cache[player]:Destroy()
        self.Cache[player] = nil
    end
end

function ESPManager:Update()
    for _, espInstance in pairs(self.Cache) do
        espInstance:Update()
    end
end

local AimbotSystem = {}
AimbotSystem.__index = AimbotSystem

function AimbotSystem.new()
    local self = setmetatable({}, AimbotSystem)
    self.FOVCircle = DrawingWrapper.new("Circle", {
        Thickness = 1,
        Filled = false,
        Transparency = 1,
        Color = Settings.Aimbot.FOVColor,
    })
    self.CurrentTarget = nil
    return self
end

function AimbotSystem:GetTarget()
    local target = nil
    local shortestDistance = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end
        if Settings.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
            continue
        end

        local character = player.Character
        if not character then
            continue
        end

        local humanoid = character:FindFirstChild("Humanoid")
        local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)

        if not humanoid or humanoid.Health <= 0 or not targetPart then
            continue
        end

        local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then
            continue
        end

        local magnitude = (Vector2.new(vector.X, vector.Y) - mousePos).Magnitude
        if magnitude < shortestDistance then
            target = targetPart
            shortestDistance = magnitude
        end
    end

    return target
end

function AimbotSystem:Update()
    local mousePos = UserInputService:GetMouseLocation()

    if Settings.Aimbot.ShowFOV then
        self.FOVCircle:Update({
            Visible = true,
            Position = mousePos,
            Radius = Settings.Aimbot.FOV,
            Color = Settings.Aimbot.FOVColor,
        })
    else
        self.FOVCircle:Update({ Visible = false })
    end

    if Settings.Aimbot.Enabled and Settings.Aimbot.Aiming then
        self.CurrentTarget = self:GetTarget()
        if self.CurrentTarget then
            local targetPosition = self.CurrentTarget.Position
            local cameraPosition = Camera.CFrame.Position
            local newCFrame = CFrame.new(cameraPosition, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Settings.Aimbot.Smoothness)
        end
    else
        self.CurrentTarget = nil
    end
end

local globalESPManager = ESPManager.new()
local globalAimbotSystem = AimbotSystem.new()

for _, player in pairs(Players:GetPlayers()) do
    globalESPManager:AddPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    globalESPManager:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    globalESPManager:RemovePlayer(player)
end)

RunService.RenderStepped:Connect(function()
    globalESPManager:Update()
    globalAimbotSystem:Update()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Settings.Aimbot.Key then
        Settings.Aimbot.Aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Settings.Aimbot.Key then
        Settings.Aimbot.Aiming = false
    end
end)

local window = Library.new({
    Name = "Test",
    Subtitle = "Test",
    Keybind = Settings.UI.MenuKeybind,
    Width = 560,
    Height = 400,
    Draggable = true,
    UseBlur = false,
    CornerRadius = 20,
    AccentColor = Color3.fromRGB(0, 122, 255),
    BackgroundColor = Color3.fromRGB(242, 242, 247),
    SurfaceColor = Color3.fromRGB(255, 255, 255),
    TextColor = Color3.fromRGB(28, 28, 30),
    SubTextColor = Color3.fromRGB(99, 99, 102),
    BorderColor = Color3.fromRGB(199, 199, 204),
    Font = Enum.Font.Gotham,
    SmallTextSize = 13,
    NormalTextSize = 14,
    TitleTextSize = 24,
    AnimationSpeed = 0.2,
    ItemHeight = 42,
    SafeAreaPadding = 12,
    BackgroundTransparency = 0.08,
    SurfaceTransparency = 0,
})

local aimbotTab = window:AddTab({ Name = "Aimbot", Width = 110 })
local visualTab = window:AddTab({ Name = "Visual", Width = 110 })
local miscTab = window:AddTab({ Name = "Misc", Width = 110 })
local cfgTab = window:AddTab({ Name = "Config", Width = 110 })

local refs = {}

local aimbotMain = aimbotTab:AddSection({
    Title = "Aimbot Configuration",
    Description = "Aiming settings.",
})

refs.aimbotEnabled = aimbotMain:AddToggle({
    Text = "Enable Aimbot",
    Default = Settings.Aimbot.Enabled,
    Callback = function(state)
        Settings.Aimbot.Enabled = state
    end,
})

refs.showFOV = aimbotMain:AddToggle({
    Text = "Show FOV",
    Default = Settings.Aimbot.ShowFOV,
    Callback = function(state)
        Settings.Aimbot.ShowFOV = state
    end,
})

refs.fov = aimbotMain:AddSlider({
    Text = "FOV Radius",
    Min = 10,
    Max = 500,
    Step = 5,
    Default = Settings.Aimbot.FOV,
    Callback = function(value)
        Settings.Aimbot.FOV = value
    end,
})

refs.smooth = aimbotMain:AddSlider({
    Text = "Smoothness",
    Min = 0.01,
    Max = 1,
    Step = 0.01,
    Default = Settings.Aimbot.Smoothness,
    Callback = function(value)
        Settings.Aimbot.Smoothness = value
    end,
})

refs.targetPart = aimbotMain:AddDropdown({
    Text = "Target Part",
    Options = { "Head", "HumanoidRootPart", "Torso" },
    Default = Settings.Aimbot.TargetPart,
    Callback = function(value)
        Settings.Aimbot.TargetPart = value
    end,
})

refs.fovColor = aimbotMain:AddColorPicker({
    Text = "FOV Color",
    Default = Settings.Aimbot.FOVColor,
    Callback = function(color)
        Settings.Aimbot.FOVColor = color
    end,
})

local visualMain = visualTab:AddSection({
    Title = "ESP Configuration",
    Description = "Entity visuals.",
})

refs.espEnabled = visualMain:AddToggle({
    Text = "Enable ESP",
    Default = Settings.ESP.Enabled,
    Callback = function(state)
        Settings.ESP.Enabled = state
    end,
})

refs.espBox = visualMain:AddToggle({
    Text = "Draw Boxes",
    Default = Settings.ESP.Box,
    Callback = function(state)
        Settings.ESP.Box = state
    end,
})

refs.espHealth = visualMain:AddToggle({
    Text = "Draw HealthBar",
    Default = Settings.ESP.HealthBar,
    Callback = function(state)
        Settings.ESP.HealthBar = state
    end,
})

refs.espName = visualMain:AddToggle({
    Text = "Draw Names",
    Default = Settings.ESP.Name,
    Callback = function(state)
        Settings.ESP.Name = state
    end,
})

refs.espDistance = visualMain:AddToggle({
    Text = "Draw Distance",
    Default = Settings.ESP.Distance,
    Callback = function(state)
        Settings.ESP.Distance = state
    end,
})

refs.teamCheck = visualMain:AddToggle({
    Text = "Team Check",
    Default = Settings.ESP.TeamCheck,
    Callback = function(state)
        Settings.ESP.TeamCheck = state
        Settings.Aimbot.TeamCheck = state
    end,
})

refs.espColor = visualMain:AddColorPicker({
    Text = "ESP Color",
    Default = Settings.ESP.Color,
    Callback = function(color)
        Settings.ESP.Color = color
    end,
})

local miscMain = miscTab:AddSection({
    Title = "Miscellaneous",
    Description = "Utility tools.",
})

local cfgWatcherActive = true

refs.menuKeybind = miscMain:AddKeybind({
    Text = "Toggle Menu Key",
    Default = Settings.UI.MenuKeybind,
    OnChanged = function(newKey)
        Settings.UI.MenuKeybind = newKey
        window:SetKeybind(newKey)
    end,
})

miscMain:AddButton({
    Text = "Hide / Show Menu",
    Callback = function()
        window:Toggle()
    end,
})

miscMain:AddButton({
    Text = "Unload All",
    Callback = function()
        cfgWatcherActive = false
        for _, espInstance in pairs(globalESPManager.Cache) do
            espInstance:Destroy()
        end
        globalAimbotSystem.FOVCircle:Remove()
        window:Destroy()
    end,
})

local configSystem = ConfigSys.new({
    FolderName = "example",
})

local currentConfigName = "default"
local cfgMain = cfgTab:AddSection({
    Title = "Config System",
    Description = "Save and load settings into executor workspace/example.",
})

local statusLabel = cfgMain:AddLabel("Selected: default")
cfgMain:AddLabel("Folder: example")
local availableCfgLabel = cfgMain:AddLabel("Available: (empty)")

cfgMain:AddLabel("Config Name")
cfgMain:AddInput({
    Default = currentConfigName,
    Placeholder = "example: legit",
    Callback = function(text)
        if text and text ~= "" then
            currentConfigName = text
            statusLabel.Text = "Selected: " .. currentConfigName
        end
    end,
})

local function rebuildConfigSelector()
    local list = configSystem:ListConfigs()
    local hasConfigs = #list > 0

    if not hasConfigs then
        availableCfgLabel.Text = "Available: (empty)"
        statusLabel.Text = "No saved configs in /example"
    else
        availableCfgLabel.Text = "Available: " .. table.concat(list, ", ")
        statusLabel.Text = string.format("Selected: %s (%d)", currentConfigName, #list)
    end
end

local function syncUIFromSettings()
    refs.aimbotEnabled:Set(Settings.Aimbot.Enabled)
    refs.showFOV:Set(Settings.Aimbot.ShowFOV)
    refs.fov:Set(Settings.Aimbot.FOV)
    refs.smooth:Set(Settings.Aimbot.Smoothness)
    refs.targetPart:Set(Settings.Aimbot.TargetPart)
    refs.fovColor:Set(Settings.Aimbot.FOVColor)

    refs.espEnabled:Set(Settings.ESP.Enabled)
    refs.espBox:Set(Settings.ESP.Box)
    refs.espHealth:Set(Settings.ESP.HealthBar)
    refs.espName:Set(Settings.ESP.Name)
    refs.espDistance:Set(Settings.ESP.Distance)
    refs.teamCheck:Set(Settings.ESP.TeamCheck)
    refs.espColor:Set(Settings.ESP.Color)

    refs.menuKeybind:Set(Settings.UI.MenuKeybind)
    window:SetKeybind(Settings.UI.MenuKeybind)
end

cfgMain:AddButton({
    Text = "Save Config",
    Callback = function()
        local ok, info = configSystem:SaveConfig(currentConfigName, Settings)
        if ok then
            rebuildConfigSelector()
            statusLabel.Text = "Saved: " .. tostring(info)
        else
            statusLabel.Text = "Save failed: " .. tostring(info)
        end
    end,
})

cfgMain:AddButton({
    Text = "Load Config",
    Callback = function()
        local data, info = configSystem:LoadConfig(currentConfigName)
        if data then
            mergeInto(Settings, data)
            syncUIFromSettings()
            statusLabel.Text = "Loaded: " .. tostring(info)
        else
            statusLabel.Text = "Load failed: " .. tostring(info)
        end
    end,
})

cfgMain:AddButton({
    Text = "Delete Config",
    Callback = function()
        local ok, info = configSystem:DeleteConfig(currentConfigName)
        if ok then
            rebuildConfigSelector()
            statusLabel.Text = "Deleted: " .. tostring(info)
        else
            statusLabel.Text = "Delete failed: " .. tostring(info)
        end
    end,
})

rebuildConfigSelector()

task.spawn(function()
    local lastSnapshot = ""
    while cfgWatcherActive do
        local list = configSystem:ListConfigs()
        table.sort(list)
        local snapshot = table.concat(list, "|")
        if snapshot ~= lastSnapshot then
            lastSnapshot = snapshot
            rebuildConfigSelector()
        end
        task.wait(1.5)
    end
end)
