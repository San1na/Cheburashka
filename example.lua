local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/San1na/Cheburashka/refs/heads/main/main.lua"))()

local window = Library.new({
    Name = "Project X",
    Subtitle = "iOS Style Menu",
    Keybind = Enum.KeyCode.RightShift,
    Width = 560,
    Height = 400,
    Draggable = true,
    UseBlur = true,
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

local combatTab = window:AddTab({ Name = "Combat", Width = 130 })
local visualTab = window:AddTab({ Name = "Visual", Width = 130 })
local miscTab = window:AddTab({ Name = "Misc", Width = 130 })

local combatMain = combatTab:AddSection({
    Title = "Combat Settings",
    Description = "Основные настройки боевых механик.",
})

combatMain:AddButton({
    Text = "Force Respawn",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
    end,
})

local autoFarmToggle = combatMain:AddToggle({
    Text = "Auto Farm",
    Default = false,
    Callback = function(state)
        print("Auto Farm:", state)
    end,
})

local reachSlider = combatMain:AddSlider({
    Text = "Reach",
    Min = 1,
    Max = 30,
    Step = 1,
    Default = 8,
    Callback = function(value)
        print("Reach:", value)
    end,
})

combatMain:AddDropdown({
    Text = "Target Part",
    Options = { "Head", "HumanoidRootPart", "Torso" },
    Default = "HumanoidRootPart",
    Callback = function(value)
        print("Target Part:", value)
    end,
})

local visualMain = visualTab:AddSection({
    Title = "Visual Settings",
    Description = "Настройки интерфейса и отображения.",
})

visualMain:AddToggle({
    Text = "ESP Enabled",
    Default = true,
    Callback = function(state)
        print("ESP:", state)
    end,
})

visualMain:AddInput({
    Placeholder = "Введите Hex цвет (пример: #00A2FF)",
    Default = "#007AFF",
    Callback = function(text)
        print("Custom color:", text)
    end,
})

visualMain:AddDivider()
visualMain:AddLabel("Стили можно менять прямо из таблицы настроек window.")

local miscMain = miscTab:AddSection({
    Title = "Misc",
    Description = "Прочие настройки и демонстрация API.",
})

miscMain:AddButton({
    Text = "Print Current Values",
    Callback = function()
        print("AutoFarm:", autoFarmToggle.Get())
        print("Reach:", reachSlider.Get())
    end,
})

miscMain:AddButton({
    Text = "Hide / Show Menu",
    Callback = function()
        window:Toggle()
    end,
})

miscMain:AddButton({
    Text = "Destroy Menu",
    Callback = function()
        window:Destroy()
    end,
})

-- Пример смены заголовка в рантайме:
task.delay(2, function()
    window:SetTitle("Project X", "Ready")
end)
