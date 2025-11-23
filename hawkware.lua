-- HAWKWARE | FIXED AIMBOT (WITH VISIBLE CHECK) + BOXES NOT FILLED + INTRO ANIMATION

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- INTRO ANIMATION (like Fatality - blur + black HAWKWARE fade in)
local function PlayIntro()
    -- Blur effect
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(blur, tweenInfo, {Size = 24}):Play()

    -- Intro GUI
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "HAWKIntro"
    introGui.Parent = CoreGui
    introGui.IgnoreGuiInset = true

    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundTransparency = 1
    introFrame.Parent = introGui

    local introText = Instance.new("TextLabel")
    introText.Size = UDim2.new(0.5, 0, 0.2, 0)
    introText.Position = UDim2.new(0.25, 0, 0.4, 0)
    introText.BackgroundTransparency = 1
    introText.Text = "H"
    introText.TextColor3 = Color3.fromRGB(0, 0, 0)  -- Black text
    introText.Font = Enum.Font.GothamBlack
    introText.TextSize = 150
    introText.TextTransparency = 1
    introText.Parent = introFrame

    -- Fade in "H"
    TweenService:Create(introText, TweenInfo.new(0.8, Enum.EasingStyle.Quart), {TextTransparency = 0}):Play()
    task.wait(1)

    -- Add rest of "HAWKWARE" (fade in letter by letter for Fatality-like effect)
    local fullText = "HAWKWARE"
    for i = 2, #fullText do
        introText.Text = fullText:sub(1, i)
        task.wait(0.1)
    end

    task.wait(1.5)

    -- Fade out
    TweenService:Create(introText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
    TweenService:Create(blur, TweenInfo.new(0.8), {Size = 0}):Play()
    task.wait(1)

    -- Cleanup
    introGui:Destroy()
    blur:Destroy()
end

PlayIntro()  -- Run intro right after execution

local ESP = {}
local ESPEnabled = false
local BoxesOn = false
local TracersOn = false
local HealthBarOn = false
local AimbotOn = false
local MAX_AIM_DISTANCE = 600

-- YOUR SWASTIKA CROSSHAIR
local Crosshair = {}
for i = 1, 20 do Crosshair[i] = Drawing.new("Line") end
local function DrawYourSwastika()
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local s = 10
    local lines = {
        {Vector2.new(cx - s*1.5, cy - s*2), Vector2.new(cx - s, cy - s*1.5)},
        {Vector2.new(cx - s, cy - s*1.5), Vector2.new(cx - s*2, cy - s)},
        {Vector2.new(cx + s*1.5, cy - s*2), Vector2.new(cx + s, cy - s*1.5)},
        {Vector2.new(cx + s, cy - s*1.5), Vector2.new(cx + s*2, cy - s)},
        {Vector2.new(cx + s*1.5, cy + s*2), Vector2.new(cx + s, cy + s*1.5)},
        {Vector2.new(cx + s, cy + s*1.5), Vector2.new(cx + s*2, cy + s)},
        {Vector2.new(cx - s*1.5, cy + s*2), Vector2.new(cx - s, cy + s*1.5)},
        {Vector2.new(cx - s, cy + s*1.5), Vector2.new(cx - s*2, cy + s)},
        {Vector2.new(cx - s*3, cy), Vector2.new(cx + s*3, cy)},
        {Vector2.new(cx, cy - s*3), Vector2.new(cx, cy + s*3)},
    }
    for i, line in ipairs(lines) do
        local l = Crosshair[i]
        l.Visible = true
        l.Color = Color3.fromRGB(255,0,0)
        l.Thickness = 2.2
        l.From = line[1]
        l.To = line[2]
    end
end
DrawYourSwastika()

-- VISIBLE CHECK
local function IsVisible(target)
    if not target then return false end
    local origin = Camera.CFrame.Position
    local dir = target.Position - origin
    if dir.Magnitude > MAX_AIM_DISTANCE then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character or {}, Camera}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, dir, params)
    return not result or result.Instance:IsDescendantOf(target.Parent)
end

-- BEST TARGET
local function GetBestTarget()
    local closest = nil
    local best = math.huge
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 and IsVisible(head) then
                local scr, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local dist = (Vector2.new(scr.X, scr.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < best then best = dist; closest = head end
                end
            end
        end
    end
    return closest
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
    if AimbotOn then
        local target = GetBestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)  -- No smoothness
        end
    end

    if ESPEnabled then
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChild("Humanoid")
                if head and hrp and hum and hum.Health > 0 then
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        if not ESP[plr] then
                            ESP[plr] = {
                                Box = Drawing.new("Square"),
                                Tracer = Drawing.new("Line"),
                                Name = Drawing.new("Text"),
                                HealthBG = Drawing.new("Square"),
                                HealthFG = Drawing.new("Square")
                            }
                            ESP[plr].Box.Thickness = 2
                            ESP[plr].Box.Color = Color3.fromRGB(255,0,0)
                            ESP[plr].Box.Filled = false

                            ESP[plr].Tracer.Thickness = 1
                            ESP[plr].Tracer.Color = Color3.fromRGB(255,0,0)

                            ESP[plr].Name.Size = 16
                            ESP[plr].Name.Color = Color3.fromRGB(255,0,0)
                            ESP[plr].Name.Outline = true

                            ESP[plr].HealthBG.Color = Color3.new(0,0,0)
                            ESP[plr].HealthBG.Filled = true

                            ESP[plr].HealthFG.Color = Color3.fromRGB(0,255,0)
                            ESP[plr].HealthFG.Filled = true
                        end

                        ESP[plr].Name.Text = plr.DisplayName
                        ESP[plr].Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                        ESP[plr].Name.Visible = true

                        local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0))
                        local bot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,4,0))
                        local h = math.abs(top.Y - bot.Y)
                        local w = h * 0.5

                        if BoxesOn then
                            ESP[plr].Box.Size = Vector2.new(w, h)
                            ESP[plr].Box.Position = Vector2.new(top.X - w/2, top.Y)
                            ESP[plr].Box.Visible = true
                        else
                            ESP[plr].Box.Visible = false
                        end

                        if HealthBarOn then
                            local health = hum.Health / hum.MaxHealth
                            local barH = h * health
                            ESP[plr].HealthBG.Size = Vector2.new(6, h)
                            ESP[plr].HealthBG.Position = Vector2.new(top.X - w/2 - 10, top.Y)
                            ESP[plr].HealthBG.Visible = true
                            ESP[plr].HealthFG.Size = Vector2.new(6, barH)
                            ESP[plr].HealthFG.Position = Vector2.new(top.X - w/2 - 10, top.Y + (h - barH))
                            ESP[plr].HealthFG.Visible = true
                        else
                            ESP[plr].HealthBG.Visible = false
                            ESP[plr].HealthFG.Visible = false
                        end

                        if TracersOn then
                            ESP[plr].Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            ESP[plr].Tracer.To = Vector2.new(headPos.X, headPos.Y)
                            ESP[plr].Tracer.Visible = true
                        else
                            ESP[plr].Tracer.Visible = false
                        end
                    else
                        if ESP[plr] then
                            for _, v in pairs(ESP[plr]) do v.Visible = false end
                        end
                    end
                end
            else
                if ESP[plr] then
                    for _, v in pairs(ESP[plr]) do v:Remove() end
                    ESP[plr] = nil
                end
            end
        end
    end
end)

-- GUI (PURPLE THEME)
local sg = Instance.new("ScreenGui", CoreGui)
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0,300,0,330)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundColor3 = Color3.fromRGB(128,0,128)  -- Purple
frame.Active = true; frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.BackgroundColor3 = Color3.fromRGB(128,0,128)  -- Purple
title.Text = "HAWKWARE"
title.TextColor3 = Color3.new(0,0,0)  -- Black text
title.Font = Enum.Font.GothamBold
title.TextSize = 22

local function btn(name, y, callback)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.9,0,0,45)
    b.Position = UDim2.new(0.05,0,0,y)
    b.BackgroundColor3 = Color3.fromRGB(128,0,128)  -- Purple
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = name..": OFF"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 18
    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        b.Text = name..(on and ": ON" or ": OFF")
        callback(on)
    end)
end

btn("ESP Master", 50, function(v) ESPEnabled = v end)
btn("Health Bars", 100, function(v) HealthBarOn = v end)
btn("Boxes", 150, function(v) BoxesOn = v end)
btn("Tracers", 200, function(v) TracersOn = v end)
btn("Aimbot", 250, function(v) AimbotOn = v end)

local dc = Instance.new("TextLabel", frame)
dc.Size = UDim2.new(1,0,0,30)
dc.Position = UDim2.new(0,0,1,-35)
dc.BackgroundTransparency = 1
dc.Text = "discord: Warshipsink411."
dc.TextColor3 = Color3.fromRGB(100,200,255)
dc.Font = Enum.Font.GothamBold
dc.TextSize = 20

local hide = Instance.new("TextButton", sg)
hide.Size = UDim2.new(0,80,0,40)
hide.Position = UDim2.new(0,10,0,10)
hide.BackgroundColor3 = Color3.fromRGB(128,0,128)  -- Purple
hide.Text = "HIDE"
hide.Active = true
hide.Draggable = true
local hidden = false
hide.MouseButton1Click:Connect(function()
    hidden = not hidden
    frame.Visible = not hidden
    hide.Text = hidden and "SHOW" or "HIDE"
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(plr)
    if ESP[plr] then
        for _, v in pairs(ESP[plr]) do pcall(v.Remove, v) end
        ESP[plr] = nil
    end
end)

print("HAWKWARE LOADED - With Fatality-like Intro Animation")
