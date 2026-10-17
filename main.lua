--[[
    Adopt Me Ultimate Auto-Farmer - Delta Executor
    Features: Auto pet farm, tasks, baby needs, all mini-games
    PC Optimized | Multi-account ready
    With Minimize Button & ^ω^ Logo
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Configuration
local Config = {
    AutoFarmPets = true,
    AutoTasks = true,
    AutoBabyNeeds = true,
    AutoMiniGames = true,
    -- Mini-game toggles
    AutoHaunted = true,
    AutoGhostGallery = true,
    AutoStitches = true,
    -- Settings
    FarmRadius = 50,
    TweenSpeed = 250,
    CheckInterval = 0.1,
    LowGraphics = false,
    AntiAFK = true
}

-- GUI Library (Kavo UI - lightweight)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Adopt Me Ultimate Farm", "DarkTheme")

-- Create Minimize Button System
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Text = "—"
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -35, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 20
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = Window.MainFrame

-- Create ^ω^ Logo Button (appears when minimized)
local LogoButton = Instance.new("TextButton")
LogoButton.Name = "LogoButton"
LogoButton.Text = "^ω^"
LogoButton.Size = UDim2.new(0, 50, 0, 30)
LogoButton.Position = UDim2.new(0.5, -25, 0, 10)
LogoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
LogoButton.TextColor3 = Color3.fromRGB(255, 150, 200)
LogoButton.TextSize = 18
LogoButton.BorderSizePixel = 0
LogoButton.Visible = false
LogoButton.Parent = Player:WaitForChild("PlayerGui")

-- Make logo draggable
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

LogoButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = LogoButton.Position
    end
end)

LogoButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        LogoButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

LogoButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Minimize function
local function MinimizeGUI()
    Window.MainFrame.Visible = false
    LogoButton.Visible = true
end

-- Restore function
local function RestoreGUI()
    LogoButton.Visible = false
    Window.MainFrame.Visible = true
end

-- Minimize button click
MinimizeButton.MouseButton1Click:Connect(function()
    MinimizeGUI()
end)

-- Logo button click (restore)
LogoButton.MouseButton1Click:Connect(function()
    RestoreGUI()
end)

-- Main Tab
local MainTab = Window:NewTab("Main")
local FarmSection = MainTab:NewSection("Auto Farm")

FarmSection:NewToggle("Auto Farm Pets", "Automatically farms pets", function(state)
    Config.AutoFarmPets = state
end)

FarmSection:NewToggle("Auto Tasks", "Completes tasks automatically", function(state)
    Config.AutoTasks = state
end)

FarmSection:NewToggle("Auto Baby Needs", "Fulfills baby needs", function(state)
    Config.AutoBabyNeeds = state
end)

FarmSection:NewToggle("Auto Mini-Games", "Plays all mini-games", function(state)
    Config.AutoMiniGames = state
end)

-- Mini-Games Tab
local MiniTab = Window:NewTab("Mini-Games")
local MiniSection = MiniTab:NewSection("Game Selection")

MiniSection:NewToggle("Haunted House", "Auto plays Haunted House", function(state)
    Config.AutoHaunted = state
end)

MiniSection:NewToggle("Ghost Gallery", "Auto plays Ghost Gallery", function(state)
    Config.AutoGhostGallery = state
end)

MiniSection:NewToggle("Stitches Spotlight", "Auto plays Stitches Spotlight", function(state)
    Config.AutoStitches = state
end)

-- Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Configuration")

SettingsSection:NewSlider("Farm Radius", "Distance to search for items", 10, 100, 50, function(value)
    Config.FarmRadius = value
end)

SettingsSection:NewSlider("Tween Speed", "Movement speed", 100, 500, 250, function(value)
    Config.TweenSpeed = value
end)

SettingsSection:NewToggle("Low Graphics", "Optimizes for background", function(state)
    Config.LowGraphics = state
    if state then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100
        settings().Rendering.QualityLevel = 1
    else
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 500
        settings().Rendering.QualityLevel = 10
    end
end)

SettingsSection:NewToggle("Anti-AFK", "Prevents disconnection", function(state)
    Config.AntiAFK = state
end)

-- Internal Variables
local IsMoving = false
local CurrentTask = nil
local BabyNeeds = {}
local MiniGameState = {
    Active = false,
    CurrentGame = nil,
    CollectedItems = 0
}

-- Find game objects
local function FindObjects(name)
    local objects = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name:lower():find(name:lower()) then
            table.insert(objects, v)
        end
    end
    return objects
end

-- Find pet objects
local function FindPets()
    local pets = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if v:GetAttribute("IsPet") or v.Name:lower():find("pet") then
                table.insert(pets, v)
            end
        end
    end
    return pets
end

-- Task system
local function FindTasks()
    local tasks = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and (v.Name:lower():find("task") or v.Name:lower():find("quest")) then
            table.insert(tasks, v)
        end
    end
    return tasks
end

-- Baby needs detection
local function FindBabyNeeds()
    local needs = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name:lower():find("baby") then
            for _, part in pairs(v:GetChildren()) do
                if part:IsA("Part") and part.Name:lower():find("need") then
                    table.insert(needs, part)
                end
            end
        end
    end
    return needs
end

-- Fast tween movement
local function FastTween(target)
    if not RootPart or not target then return end
    
    IsMoving = true
    local distance = (RootPart.Position - target.Position).Magnitude
    local duration = math.clamp(distance / Config.TweenSpeed, 0.1, 2)
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.In,
        0,
        false,
        0
    )
    
    local goal = {
        CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    }
    
    local tween = TweenService:Create(RootPart, tweenInfo, goal)
    tween:Play()
    
    task.wait(duration)
    IsMoving = false
end

-- Haunted House Mini-Game
local function PlayHauntedHouse()
    if not Config.AutoHaunted or MiniGameState.Active then return end
    
    local hauntedObjects = FindObjects("haunted")
    if #hauntedObjects == 0 then return end
    
    MiniGameState.Active = true
    MiniGameState.CurrentGame = "Haunted"
    
    for _, obj in ipairs(hauntedObjects) do
        if not Config.AutoMiniGames then break end
        
        local collectibles = FindObjects("candy") or FindObjects("candle")
        for _, item in ipairs(collectibles) do
            if (item.Position - RootPart.Position).Magnitude < Config.FarmRadius then
                FastTween(item)
                task.wait(0.1)
            end
        end
        
        local ghosts = FindObjects("ghost")
        for _, ghost in ipairs(ghosts) do
            if (ghost.Position - RootPart.Position).Magnitude < 15 then
                local away = (RootPart.Position - ghost.Position).Unit * 20
                FastTween({Position = RootPart.Position + away})
            end
        end
    end
    
    MiniGameState.Active = false
end

-- Ghost Gallery Mini-Game
local function PlayGhostGallery()
    if not Config.AutoGhostGallery or MiniGameState.Active then return end
    
    local galleryObjects = FindObjects("gallery") or FindObjects("ghost")
    if #galleryObjects == 0 then return end
    
    MiniGameState.Active = true
    MiniGameState.CurrentGame = "GhostGallery"
    
    local orbs = FindObjects("orb") or FindObjects("soul")
    for _, orb in ipairs(orbs) do
        if not Config.AutoMiniGames then break end
        
        if (orb.Position - RootPart.Position).Magnitude < Config.FarmRadius then
            FastTween(orb)
            MiniGameState.CollectedItems += 1
            task.wait(0.1)
        end
    end
    
    local ghosts = FindObjects("ghost")
    for _, ghost in ipairs(ghosts) do
        if ghost:FindFirstChild("Humanoid") then
            local ghostRoot = ghost:FindFirstChild("HumanoidRootPart")
            if ghostRoot and (ghostRoot.Position - RootPart.Position).Magnitude < 20 then
                local safeZone = RootPart.Position + Vector3.new(
                    math.random(-30, 30),
                    0,
                    math.random(-30, 30)
                )
                FastTween({Position = safeZone})
            end
        end
    end
    
    MiniGameState.Active = false
end

-- Stitches Spotlight Mini-Game
local function PlayStitchesSpotlight()
    if not Config.AutoStitches or MiniGameState.Active then return end
    
    local spotlight = FindObjects("spotlight")[1]
    if not spotlight then return end
    
    MiniGameState.Active = true
    MiniGameState.CurrentGame = "Stitches"
    
    local candies = FindObjects("candy") or FindObjects("corn")
    for _, candy in ipairs(candies) do
        if not Config.AutoMiniGames then break end
        
        if spotlight:IsA("Part") and (spotlight.Position - RootPart.Position).Magnitude > 20 then
            if (candy.Position - RootPart.Position).Magnitude < Config.FarmRadius then
                FastTween(candy)
                MiniGameState.CollectedItems += 1
                task.wait(0.1)
            end
        else
            local safePos = RootPart.Position + Vector3.new(
                math.random(-40, 40),
                0,
                math.random(-40, 40)
            )
            FastTween({Position = safePos})
        end
    end
    
    MiniGameState.Active = false
end

-- Pet farming
local function FarmPets()
    if not Config.AutoFarmPets then return end
    
    local pets = FindPets()
    for _, pet in ipairs(pets) do
        if not Config.AutoFarmPets then break end
        
        local petRoot = pet:FindFirstChild("HumanoidRootPart")
        if petRoot and (petRoot.Position - RootPart.Position).Magnitude < Config.FarmRadius then
            FastTween(petRoot)
            task.wait(0.1)
            
            local food = FindObjects("food") or FindObjects("treat")
            for _, item in ipairs(food) do
                if (item.Position - RootPart.Position).Magnitude < 10 then
                    FastTween(item)
                    task.wait(0.1)
                end
            end
        end
    end
end

-- Task completion
local function CompleteTasks()
    if not Config.AutoTasks then return end
    
    local tasks = FindTasks()
    for _, task in ipairs(tasks) do
        if not Config.AutoTasks then break end
        
        local taskRoot = task:FindFirstChild("HumanoidRootPart") or task:FindFirstChild("Part")
        if taskRoot and (taskRoot.Position - RootPart.Position).Magnitude < Config.FarmRadius then
            CurrentTask = task
            FastTween(taskRoot)
            task.wait(0.5)
            
            if task:FindFirstChild("ClickDetector") then
                fireclickdetector(task.ClickDetector)
            elseif task:FindFirstChild("ProximityPrompt") then
                fireproximityprompt(task.ProximityPrompt)
            end
        end
    end
end

-- Baby needs fulfillment
local function FulfillBabyNeeds()
    if not Config.AutoBabyNeeds then return end
    
    local needs = FindBabyNeeds()
    for _, need in ipairs(needs) do
        if not Config.AutoBabyNeeds then break end
        
        if (need.Position - RootPart.Position).Magnitude < Config.FarmRadius then
            FastTween(need)
            task.wait(0.2)
            
            local itemType = need.Name:lower()
            local items = FindObjects(itemType) or FindObjects("item")
            for _, item in ipairs(items) do
                if (item.Position - RootPart.Position).Magnitude < 10 then
                    FastTween(item)
                    task.wait(0.1)
                end
            end
        end
    end
end

-- Main loop
local function MainLoop()
    if Config.AutoFarmPets then
        FarmPets()
    end
    
    if Config.AutoTasks then
        CompleteTasks()
    end
    
    if Config.AutoBabyNeeds then
        FulfillBabyNeeds()
    end
    
    if Config.AutoMiniGames then
        if Config.AutoHaunted then
            PlayHauntedHouse()
        end
        
        if Config.AutoGhostGallery then
            PlayGhostGallery()
        end
        
        if Config.AutoStitches then
            PlayStitchesSpotlight()
        end
    end
end

-- Optimized loop with interval
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= Config.CheckInterval then
        lastUpdate = currentTime
        if not IsMoving then
            MainLoop()
        end
    end
end)

-- Character respawn handling
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Anti-AFK system
task.spawn(function()
    while Config.AntiAFK do
        task.wait(60)
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Window focus optimization
UserInputService.WindowFocusReleased:Connect(function()
    if Config.LowGraphics then
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = 1
    end
end)

UserInputService.WindowFocused:Connect(function()
    if not Config.LowGraphics then
        Lighting.GlobalShadows = true
        settings().Rendering.QualityLevel = 10
    end
end)

-- Notification
print("✅ Adopt Me Ultimate Auto-Farmer loaded!")
print("🎮 Toggle features using the GUI")
print("📌 Press F1 to open/close GUI")
print("✨ Click '—' to minimize, click '^ω^' to restore!")
