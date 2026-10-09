local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Options            = Shared.Options
local UI                 = Shared.UI
local Players            = Shared.Players
local UserInputService   = Shared.UserInputService
local RunService         = Shared.RunService
local LocalPlayer        = Shared.LocalPlayer
local fast_tick          = Shared.fast_tick
local IsMobile           = Shared.IsMobile
local getRoot            = Shared.getRoot
local formatUsername     = Shared.formatUsername
local getPlayer          = Shared.getPlayer
local r15                = Shared.r15
local breakVelocity      = Shared.breakVelocity
local ASV_Notify         = Shared.ASV_Notify
local _Invisible_GetRemote = Shared._Invisible_GetRemote
function Fn.applySpeedBoost()
    if Config.Connections.SpeedBoost then
        Config.Connections.SpeedBoost:Disconnect()
        Config.Connections.SpeedBoost = nil
    end
    if not Config.Movement.SpeedBoost.Enabled and not Config.Movement.FakePerfectLanding.Enabled then return end
    local cfg = Config.Movement.SpeedBoost
    cfg.HeartbeatRate = 0.15
    cfg.LastApply = 0
    Config.Connections.SpeedBoost = Config.FakeConnection(Config.HeartbeatTasks, "SpeedBoost", function()
        if not Config.Movement.SpeedBoost.Enabled and not Config.Movement.FakePerfectLanding.Enabled then return end
        local now = fast_tick()
        if now - cfg.LastApply < cfg.HeartbeatRate then return end
        cfg.LastApply = now
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local currentSpeed = char:GetAttribute("speedboost") or 1
        if currentSpeed ~= cfg.LastEnforcedSpeed then
            Config.State.GameIntendedSpeed = currentSpeed
        end
        local isApplyingBoost = false
        local totalBoostToAdd = 0
        if Config.Movement.SpeedBoost.Enabled then
            totalBoostToAdd = totalBoostToAdd + (cfg.Multiplier - 1.0)
            isApplyingBoost = true
        end
        if Config.Movement.FakePerfectLanding.Enabled and now < Config.State.TempSpeedBoostEnd then
            totalBoostToAdd = totalBoostToAdd + (Config.Movement.FakePerfectLanding.Value - 1.0)
            isApplyingBoost = true
        end
        if not isApplyingBoost then
            if cfg.LastEnforcedSpeed ~= nil then
                Fn.safeCall("SpeedBoost Cleanup", function()
                    local intended = Config.State.GameIntendedSpeed or 1
                    char:SetAttribute("speedboost", intended)
                    cfg.LastEnforcedSpeed = nil
                end)
            end
            return
        end
        local target = 1.0 + totalBoostToAdd
        target = math.round(target * 100) / 100
        if currentSpeed ~= target then
            Fn.safeCall("SpeedBoost Apply", function()
                char:SetAttribute("speedboost", target)
                cfg.LastEnforcedSpeed = target
            end)
        end
    end)
end
function Fn.disableSpeedBoost()
    if Config.Movement.SpeedBoost.Enabled or Config.Movement.FakePerfectLanding.Enabled then
        Fn.applySpeedBoost()
        return
    end
    if Config.Connections.SpeedBoost then
        Config.Connections.SpeedBoost:Disconnect()
        Config.Connections.SpeedBoost = nil
    end
    local char = LocalPlayer.Character
    if char and Config.Movement.SpeedBoost.LastEnforcedSpeed ~= nil then
        Fn.safeCall("SpeedBoost Disable", function()
            local intended = Config.State.GameIntendedSpeed or 1
            char:SetAttribute("speedboost", intended)
            Config.Movement.SpeedBoost.LastEnforcedSpeed = nil
        end)
    end
end
local _Invisible_ApplyHighlight = function(char)
    if not char or not char.Parent then return nil end
    local existing = char:FindFirstChild("InvHighlight")
    if existing then return existing end
    local h = Instance.new("Highlight")
    h.Name             = "InvHighlight"
    h.FillColor        = Color3.fromRGB(60, 160, 255)
    h.OutlineColor     = Color3.fromRGB(120, 200, 255)
    h.FillTransparency = 0.55
    h.OutlineTransparency = 0
    h.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent           = char
    return h
end
local _Invisible_RemoveHighlight = function(char)
    if not char then return end
    local h = char:FindFirstChild("InvHighlight")
    if h then pcall(function() h:Destroy() end) end
end
local _Invisible_ApplyLocal = function(char)
    _Invisible_ApplyHighlight(char)
end
local _Invisible_RestoreLocal = function(char)
    _Invisible_RemoveHighlight(char)
end
local Fling_PlayerLabels = {}
local function flingBuildPlayerList()
    local labels = {}
    Fling_PlayerLabels = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local label = formatUsername(p)
            if Fling_PlayerLabels[label] then
                label = label .. " (" .. p.Name .. ")"
            end
            Fling_PlayerLabels[label] = p
            table.insert(labels, label)
        end
    end
    table.sort(labels)
    if #labels == 0 then
        table.insert(labels, "(no players)")
    end
    return labels
end
local function flingResolveTarget(query)
    if typeof(query) == "Instance" then
        if query.Parent == Players and query ~= LocalPlayer then return query end
        return nil
    end
    if type(query) ~= "string" or query == "" then return nil end
    local direct = Fling_PlayerLabels[query]
    if direct and direct.Parent == Players then return direct end
    local matches = getPlayer(query, LocalPlayer)
    if matches[1] then return matches[1] end
    local byName = Players:FindFirstChild(query)
    if byName and byName ~= LocalPlayer then return byName end
    return nil
end
function Fn.startMoonwalk()
    if Config.Connections.Moonwalk then Config.Connections.Moonwalk:Disconnect(); Config.Connections.Moonwalk = nil end
    local _MW_MOVE_FWD = Vector3.new(0, 0, 1)
    Config.Connections.Moonwalk = Config.FakeConnection(Config.RenderSteppedTasks, "Moonwalk", function()
        if not Config.Moonwalk.Enabled or Config.State.ParryActive or Config.State.AutoCrouchActive or Fn.isDowned() then return end
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not humanoid or not hrp or not cam then return end
        if Config.Moonwalk.UseSlow and humanoid.WalkSpeed ~= Config.Moonwalk.SlowSpeed then
            humanoid.WalkSpeed = Config.Moonwalk.SlowSpeed
        end
        local look = cam.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then
            flatLook = flatLook.Unit
            local baseCF = CFrame.new(hrp.Position, hrp.Position + flatLook)
            local angle  = math.sin(fast_tick() * Config.Moonwalk.SpamSpeed) * Config.Moonwalk.Intensity
            hrp.CFrame   = baseCF * CFrame.Angles(0, math.rad(angle), 0)
            humanoid:Move(_MW_MOVE_FWD, true)
        end
    end)
end
function Fn.createMoonwalkButton()
    if Config.State.MoonwalkButton then Config.State.MoonwalkButton:Destroy() end
    local gui, btn, stroke = Fn.createGameButton({
        Name        = "MoonwalkGui",
        ButtonType  = "ImageButton",
        Size        = UDim2.new(0, 53, 0, 53),
        Position    = UDim2.new(0.67, 0, 0.77, 0),
        Image       = "rbxassetid://131126241643615",
        OnClick = function(stroke)
            Config.Moonwalk.Enabled = not Config.Moonwalk.Enabled
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if Config.Moonwalk.Enabled then
                stroke.Color = Color3.fromRGB(170, 0, 255)
                if not Config.Connections.Moonwalk then Fn.startMoonwalk() end
            else
                stroke.Color = Color3.fromRGB(255, 255, 255)
                if hum then hum.WalkSpeed = 16 end
            end
        end,
    })
    Config.State.MoonwalkButton = gui
end
function Fn.removeMoonwalkButton()
    if Config.State.MoonwalkButton then Config.State.MoonwalkButton:Destroy(); Config.State.MoonwalkButton = nil end
end
function Fn.stopEmote()
    if Config.State.CurrentEmoteTrack then
        Config.State.CurrentEmoteTrack:Stop()
        Config.State.CurrentEmoteTrack:Destroy()
        Config.State.CurrentEmoteTrack = nil
    end
    if Config.State.CurrentEmoteSound then
        Config.State.CurrentEmoteSound:Stop()
        Config.State.CurrentEmoteSound:Destroy()
        Config.State.CurrentEmoteSound = nil
    end
end
function Fn.playEmote(name)
    Fn.stopEmote()
    local data = Config.EmoteData[name]
    if not data then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    if data.anim then
        local anim = Instance.new("Animation")
        anim.AnimationId = data.anim
        Config.State.CurrentEmoteTrack = animator:LoadAnimation(anim)
        Config.State.CurrentEmoteTrack.Priority = Enum.AnimationPriority.Action
        Config.State.CurrentEmoteTrack:Play()
    end
    if data.sound and data.sound ~= "" and data.sound ~= "rbxassetid://0" then
        Config.State.CurrentEmoteSound = Instance.new("Sound")
        Config.State.CurrentEmoteSound.SoundId = data.sound
        Config.State.CurrentEmoteSound.Volume = 1
        Config.State.CurrentEmoteSound.Looped = true
        Config.State.CurrentEmoteSound.Parent = hrp
        Config.State.CurrentEmoteSound:Play()
    end
end
function Fn.createEmoteButton()
    if Config.EmoteButton.GuiInstance then Config.EmoteButton.GuiInstance:Destroy() end
    local gui, btn, stroke = Fn.createGameButton({
        Name       = "EmoteButtonGui",
        ButtonType = "ImageButton",
        Size       = UDim2.new(0, 50, 0, 50),
        Position   = UDim2.new(0.60, 0, 0.75, 0),
        Image      = "rbxassetid://96917710911699",
        OnClick = function(stroke)
            Fn.playEmote(Config.EmoteButton.Selected)
            stroke.Color = Color3.fromRGB(90, 120, 210)
            task.delay(0.3, function() stroke.Color = Color3.fromRGB(255, 255, 255) end)
        end,
    })
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 80, 0, 20)
    label.Position = UDim2.new(0.5, -40, -0.6, 0)
    label.BackgroundTransparency = 1
    label.Text = Config.EmoteButton.Selected
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = btn
    Config.EmoteButton.GuiInstance = gui
    Config.EmoteButton.LabelRef    = label
end
function Fn.removeEmoteButton()
    if Config.EmoteButton.GuiInstance then Config.EmoteButton.GuiInstance:Destroy(); Config.EmoteButton.GuiInstance = nil; Config.EmoteButton.LabelRef = nil end
end
function Fn.disableAntiSlowVault(fullRestore)
    local cfg = Config.Movement.AntiSlowVault
    cfg.Enabled = false
    if Config.Connections.AntiSlowVaultTag then
        Config.Connections.AntiSlowVaultTag:Disconnect()
        Config.Connections.AntiSlowVaultTag = nil
    end
    if fullRestore then
        Fn.safeCall("AntiSlowVault RestoreModule", function()
            if cfg.ControllerRef and cfg.OrigFuncs then
                if cfg.OrigFuncs._isFacingStraightEnough then
                    cfg.ControllerRef._isFacingStraightEnough = cfg.OrigFuncs._isFacingStraightEnough
                end
                if cfg.OrigFuncs._onVaultAnimation then
                    cfg.ControllerRef._onVaultAnimation = cfg.OrigFuncs._onVaultAnimation
                end
            end
        end)
        cfg.ModuleHooked  = false
        cfg.ControllerRef = nil
        cfg.OrigFuncs     = nil
    else
        ASV_Notify("Anti Slow Vault: OFF")
    end
end
function Fn.setNoclip(enabled)
    if Config.Noclip.Connection then
        pcall(function() Config.Noclip.Connection:Disconnect() end)
        Config.Noclip.Connection = nil
    end
    if enabled then
        Config.Noclip.Enabled = true
        task.wait(0.1)
        Config.Noclip.Parts = {}
        Config.Noclip._cachedChar = nil
        Config.Noclip._cachedParts = {}
        local function rebuildCache(char)
            Config.Noclip._cachedChar = char
            Config.Noclip._cachedParts = {}
            if not char then return end
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    table.insert(Config.Noclip._cachedParts, child)
                end
            end
        end
        rebuildCache(LocalPlayer.Character)
        local charConn
        charConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(0.3)
            rebuildCache(newChar)
        end)
        Config.Noclip._charConn = charConn
        Config.Noclip.Connection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            if char ~= Config.Noclip._cachedChar then
                rebuildCache(char)
            end
            local parts = Config.Noclip._cachedParts
            for i = 1, #parts do
                local child = parts[i]
                if child and child.Parent and child.CanCollide == true then
                    local ignore = false
                    if Config.Noclip.IgnoreNames and Config.Noclip.IgnoreNames[child.Name] then
                        ignore = true
                    end
                    if not ignore then
                        child.CanCollide = false
                        Config.Noclip.Parts[child] = true
                    end
                end
            end
        end)
    else
        Config.Noclip.Enabled = false
        task.wait(0.1)
        if Config.Noclip._charConn then
            pcall(function() Config.Noclip._charConn:Disconnect() end)
            Config.Noclip._charConn = nil
        end
        for child, _ in pairs(Config.Noclip.Parts) do
            if typeof(child) == "Instance" and child:IsA("BasePart") and child.Parent then
                child.CanCollide = true
            end
        end
        Config.Noclip.Parts = {}
        Config.Noclip._cachedParts = {}
        Config.Noclip._cachedChar = nil
    end
end
function Fn.setInvisible(enabled)
    if not _Invisible_GetRemote then
        return
    end
    local remote = _Invisible_GetRemote()
    if not remote then
        return
    end
    if enabled then
        Config.Invisible.Enabled = true
        if not Config.Invisible.HookActive then
            Fn._CharLook_EnsureHook()
        end
        local char = LocalPlayer.Character
        if char then
            _Invisible_ApplyLocal(char)
        end
        if not Config.Invisible.CharConn then
            Config.Invisible.CharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                if Config.Invisible.Enabled then
                    _Invisible_ApplyLocal(newChar)
                end
            end)
        end
    else
        Config.Invisible.Enabled = false
        local char = LocalPlayer.Character
        if char then
            _Invisible_RestoreLocal(char)
        end
        if Config.Invisible.CharConn then
            pcall(function() Config.Invisible.CharConn:Disconnect() end)
            Config.Invisible.CharConn = nil
        end
    end
    Fn.updateToggleIconVisual("Invisible")
end
function Fn._flingSequence(target, opts)
    opts = opts or {}
    local char = LocalPlayer.Character
    local root = char and getRoot(char)
    if not root then
        return false
    end
    local originalCFrame = root.CFrame
    Fn._CharLook_EnsureHook()
    local attempts    = math.max(1, tonumber(Config.Fling.Attempts) or 3)
    local pulseTime   = math.max(0.05, tonumber(Config.Fling.PulseTime) or 0.3)
    local successDist = math.max(1, tonumber(Config.Fling.SuccessDist) or 8)
    local success = false
    for attempt = 1, attempts do
        if Config.State.unloaded then break end
        local tChar = target.Character
        local tRoot = tChar and getRoot(tChar)
        if not tRoot then break end
        local targetStart = tRoot.Position
        local spin = 0
        Config.Fling.Enabled = true
        local deadline = fast_tick() + pulseTime
        while fast_tick() < deadline and not Config.State.unloaded do
            local tr = target.Character and getRoot(target.Character)
            if not tr then break end
            local myRoot = getRoot(LocalPlayer.Character)
            if not myRoot then break end
            spin = spin + 0.9
            myRoot.CFrame = tr.CFrame * CFrame.Angles(0, spin, 0)
            task.wait()
        end
        Config.Fling.Enabled = false
        task.wait(0.08)
        local tCharAfter = target.Character
        local tRootAfter = tCharAfter and getRoot(tCharAfter)
        if not tRootAfter then
            success = true
        else
            local moved = (tRootAfter.Position - targetStart).Magnitude
            local vel  = tRootAfter.AssemblyLinearVelocity.Magnitude
            local hum  = tCharAfter:FindFirstChildOfClass("Humanoid")
            if moved >= successDist or vel >= 75 or (hum and hum.Health <= 0) then
                success = true
            end
        end
        if success then break end
    end
    local finalRoot = getRoot(LocalPlayer.Character)
    if finalRoot then
        finalRoot.CFrame = originalCFrame
        finalRoot.AssemblyLinearVelocity = Vector3.zero
        finalRoot.AssemblyAngularVelocity = Vector3.zero
        breakVelocity()
    end
    Config.Fling.Enabled = false
    return success
end
function Fn.flingPlayer(target)
    if Config.Fling.Busy then
        return
    end
    local resolved = flingResolveTarget(target)
    if not resolved then
        return
    end
    local tChar = resolved.Character
    if not (tChar and getRoot(tChar)) then
        return
    end
    Config.Fling.Busy = true
    task.spawn(function()
        Fn._flingSequence(resolved)
        Config.Fling.Busy = false
    end)
end
function Fn.flingSelected()
    local label = Config.Fling.TargetLabel
    if not label or label == "" then
        return
    end
    Fn.flingPlayer(label)
end
function Fn.flingNearest()
    if Config.Fling.Busy then
        return
    end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and getRoot(myChar)
    if not myRoot then
        return
    end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pRoot = p.Character and getRoot(p.Character)
            if pRoot then
                local d = (pRoot.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    best, bestDist = p, d
                end
            end
        end
    end
    if not best then
        return
    end
    Fn.flingPlayer(best)
end
function Fn.flingAll()
    if Config.Fling.Busy then
        return
    end
    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(targets, p)
        end
    end
    if #targets == 0 then
        return
    end
    Config.Fling.Busy = true
    task.spawn(function()
        local okCount, failCount, skipped = 0, 0, 0
        for i, p in ipairs(targets) do
            if Config.State.unloaded then break end
            if p.Parent ~= Players or not (p.Character and getRoot(p.Character)) then
                skipped = skipped + 1
            else
                local ok = Fn._flingSequence(p, { silent = true })
                if ok then okCount = okCount + 1 else failCount = failCount + 1 end
                task.wait(math.max(0, tonumber(Config.Fling.Cooldown) or 0.3))
            end
        end
        Config.Fling.Busy = false
    end)
end
function Fn.refreshFlingTargets()
    if Config.State.unloaded then return end
    pcall(function()
        local dropdown = Options.FlingTarget
        if not dropdown then return end
        local labels = flingBuildPlayerList()
        dropdown:SetValues(labels)
        local current = Config.Fling.TargetLabel
        if current and Fling_PlayerLabels[current] then
            pcall(function() dropdown:SetValue(current) end)
            Config.Fling.Target = Fling_PlayerLabels[current]
        else
            local v = dropdown.Value
            if v and Fling_PlayerLabels[v] then
                Config.Fling.TargetLabel = v
                Config.Fling.Target = Fling_PlayerLabels[v]
            else
                Config.Fling.TargetLabel = ""
                Config.Fling.Target = nil
            end
        end
    end)
end
function Fn.giveJerkTool(speaker)
    speaker = speaker or LocalPlayer
    local char = speaker.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local backpack = speaker:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end
    Config.JerkTool._generation = (Config.JerkTool._generation or 0) + 1
    local myGen = Config.JerkTool._generation
    Config.JerkTool.Active = true
    if Config.JerkTool._charAddedConn then
        pcall(function() Config.JerkTool._charAddedConn:Disconnect() end)
        Config.JerkTool._charAddedConn = nil
    end
    local function cleanupExistingJerkTools(spk)
        local bp = spk:FindFirstChildWhichIsA("Backpack")
        local ch = spk.Character
        for _, cont in ipairs({bp, ch}) do
            if cont then
                for _, item in ipairs(cont:GetChildren()) do
                    if item:IsA("Tool") and (item.Name == "Jerk" or item.Name == "Jerk Off") then
                        pcall(function() item:Destroy() end)
                    end
                end
            end
        end
    end
    cleanupExistingJerkTools(speaker)
    local tool = Instance.new("Tool")
    tool.Name = "Jerk"
    tool.RequiresHandle = false
    tool.Parent = backpack
    local jorkin = false
    local track = nil
    local function stopTomfoolery()
        jorkin = false
        if track then
            pcall(function() track:Stop() end)
            track = nil
        end
    end
    tool.Equipped:Connect(function() jorkin = true end)
    tool.Unequipped:Connect(stopTomfoolery)
    humanoid.Died:Connect(stopTomfoolery)
    Config.JerkTool._charAddedConn = speaker.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if Config.JerkTool.Active and myGen == Config.JerkTool._generation then
            Fn.giveJerkTool(speaker)
        end
    end)
    Config.Threads.JerkToolLoop = task.spawn(function()
        while task.wait() do
            if not Config.JerkTool.Active or myGen ~= Config.JerkTool._generation then
                break
            end
            if not jorkin then continue end
            local ok, err = pcall(function()
                local isR15 = r15(speaker)
                if not isR15 and not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://72042024"
                    track = humanoid:LoadAnimation(anim)
                elseif isR15 and not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://698251653"
                    track = humanoid:LoadAnimation(anim)
                end
                if track then
                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                end
            end)
            if not ok then
                warn("[Fallens] JerkTool anim error: " .. tostring(err))
                track = nil
                task.wait(0.3)
            end
            local isR15Now = r15(speaker)
            local threshold = isR15Now and 0.7 or 0.65
            while track and track.TimePosition < threshold do
                if not Config.JerkTool.Active or myGen ~= Config.JerkTool._generation then
                    pcall(function() track:Stop() end)
                    return
                end
                task.wait(0.1)
            end
            if track then
                pcall(function() track:Stop() end)
                track = nil
            end
        end
    end)
end
function Fn.stopJerkTool()
    Config.JerkTool._generation = (Config.JerkTool._generation or 0) + 1
    Config.JerkTool.Active = false
    if Config.JerkTool._charAddedConn then
        pcall(function() Config.JerkTool._charAddedConn:Disconnect() end)
        Config.JerkTool._charAddedConn = nil
    end
    if Config.Threads.JerkToolLoop then
        Fn._destroyConn("JerkToolLoop", Config.Threads.JerkToolLoop)
        Config.Threads.JerkToolLoop = nil
    end
    local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    local char = LocalPlayer.Character
    for _, cont in ipairs({backpack, char}) do
        if cont then
            for _, item in ipairs(cont:GetChildren()) do
                if item:IsA("Tool") and (item.Name == "Jerk" or item.Name == "Jerk Off") then
                    pcall(function() item:Destroy() end)
                end
            end
        end
    end
end
do
    local SpeedBoostToggle = UI.MovementBox:AddToggle("SpeedBoostToggle", { Text = "Speed Boost",
        Default = false,
        Callback = function(v)
            Config.Movement.SpeedBoost.Enabled = v
            if v then
                Fn.applySpeedBoost()
            else
                Fn.disableSpeedBoost()
            end
            Fn.updateToggleIconVisual("SpeedBoost")
        end }):AddKeyPicker("SpeedBoostToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.MovementBox:AddSlider("SpeedBoostMultiplier", { Text = "Boost Multiplier",
    Default = 1.1, Min = 1.0, Max = 3.0, Rounding = 2,
    Callback = function(v)
        Config.Movement.SpeedBoost.Multiplier = v
        if Config.Movement.SpeedBoost.Enabled then
            Fn.applySpeedBoost()
        end
    end })
UI.MovementBox:AddToggle("MoonwalkButton", { Text = "MoonwalkButton", Default = false,
    Callback = function(v)
        Config.Moonwalk.ShowButton = v
        if v then Fn.createMoonwalkButton() else Fn.removeMoonwalkButton() end
    end }):AddKeyPicker("MoonwalkButton_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.MovementBox:AddLabel("Moonwalk (pc)"):AddKeyPicker("MoonwalkKey", { Mode = "Toggle", Callback = function(state)
        local isActive = (state == true)
        Config.Moonwalk.Enabled = isActive
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if isActive then
            Fn.startMoonwalk()
        else
            if Config.Connections.Moonwalk then Config.Connections.Moonwalk:Disconnect(); Config.Connections.Moonwalk = nil end
            if hum then hum.WalkSpeed = 16 end
        end
    end })
UI.MovementBox:AddSlider("MoonwalkSpamSpeed", { Text = "Spam Speed", Default = Config.Moonwalk.SpamSpeed, Min = 1, Max = 50, Rounding = 0,
    Callback = function(v) Config.Moonwalk.SpamSpeed = v end })
UI.MovementBox:AddSlider("MoonwalkIntensity", { Text = "Intensity", Default = Config.Moonwalk.Intensity, Min = 1, Max = 50, Rounding = 1,
    Callback = function(v) Config.Moonwalk.Intensity = v end })
UI.MovementBox:AddDivider()
do
    local toggle = UI.MovementBox:AddToggle("NoclipToggle", { Text = "Noclip",
        Default = false,
        Callback = function(v)
            Fn.setNoclip(v)
            Fn.updateToggleIconVisual("Noclip")
        end }):AddKeyPicker("NoclipToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
do
    local toggle = UI.MovementBox:AddToggle("FlyEnabled", { Text = "Fly",
        Default = false,
        Callback = function(v)
            Fn.setFly(v)
            Fn.updateToggleIconVisual("Fly")
        end }):AddKeyPicker("FlyEnabled_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.MovementBox:AddSlider("FlySpeed", { Text = "Fly Speed",
    Default = 1, Min = 1, Max = 500, Rounding = 0,
    Callback = function(v) Fn.setFlySpeed(v) end })
UI.CrosshairBox:AddToggle("CrosshairEnabled", { Text = "Enable Crosshair", Default = false,
    Callback = function(v) Config.Crosshair.Enabled = v end }):AddKeyPicker("CrosshairEnabled_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("CrosshairColor", { Default = Color3.fromRGB(255,255,255), Title = "Crosshair Color", Transparency = 0,
    Callback = function(color) Config.Crosshair.Color = color end })
UI.CrosshairBox:AddDropdown("Style", { Values = {"Plus", "Dot", "Circle"}, Default = 1, Multi = false, Text = "Style",
    Callback = function(v) Config.Crosshair.Style = v end })
UI.CrosshairBox:AddSlider("CrosshairSize", { Text = "Size", Default = 8, Min = 1, Max = 100, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.Size = v end })
UI.CrosshairBox:AddSlider("CrosshairThickness", { Text = "Thickness", Default = 2, Min = 1, Max = 10, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.Thickness = v end })
UI.CrosshairBox:AddSlider("CrosshairPosX", { Text = "Offset X", Default = 0, Min = -500, Max = 500, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.OffsetX = v end })
UI.CrosshairBox:AddSlider("CrosshairPosY", { Text = "Offset Y", Default = 0, Min = -500, Max = 500, Rounding = 1, Compact = false,
    Callback = function(v) Config.Crosshair.OffsetY = v end })
UI.EmoteBox:AddDropdown("SelectEmote", { Values = Config.EmoteButton.List, Default = 1, Multi = false, Text = "Select Emote",
    Callback = function(v)
        Config.EmoteButton.Selected = v
        if Config.EmoteButton.LabelRef then Config.EmoteButton.LabelRef.Text = v end
    end })
UI.EmoteBox:AddButton({ Text = "Play Emote", Func = function() Fn.playEmote(Config.EmoteButton.Selected) end })
UI.EmoteBox:AddButton({ Text = "Stop Emote", Func = function() Fn.stopEmote() end })
UI.EmoteBox:AddToggle("ShowEmoteButton", { Text = "Show Emote Button", Default = false,
    Callback = function(v)
        Config.EmoteButton.Show = v
        if v then Fn.createEmoteButton() else Fn.removeEmoteButton() end
    end }):AddKeyPicker("ShowEmoteButton_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.FunBox:AddButton({ Text = "Give Jerk Tool", Func = function() Fn.giveJerkTool(LocalPlayer) end })
UI.FunBox:AddButton({ Text = "Remove Jerk Tool", Func = function() Fn.stopJerkTool() end })
UI.FunBox:AddDivider()
do
    local toggle = UI.FunBox:AddToggle("InvisibleToggle", {
        Text = "Invisible",
        Default = false,
        Callback = function(v)
            Fn.setInvisible(v)
            Fn.updateToggleIconVisual("Invisible")
        end
    }):AddKeyPicker("InvisibleToggle_Keybind", {
        Default = "None",
        Mode = "Toggle",
        SyncToggleState = true
    })
end
UI.FlingBox:AddDropdown("FlingTarget", {
    Text = "Target Player",
    Values = flingBuildPlayerList(),
    Default = nil,
    Multi = false,
    Searchable = true,
    Callback = function(v)
        Config.Fling.TargetLabel = v or ""
        Config.Fling.Target = (v and Fling_PlayerLabels[v]) or nil
    end
})
UI.FlingBox:AddButton({ Text = "Fling Selected Target", Func = function()
    Fn.flingSelected()
end })
UI.FlingBox:AddButton({ Text = "Fling Nearest Player", Func = function()
    Fn.flingNearest()
end })
UI.FlingBox:AddButton({ Text = "Fling All Players", Func = function()
    Fn.flingAll()
end })
UI.FlingBox:AddDivider()
UI.FlingBox:AddSlider("FlingPulseTime", { Text = "Fling Duration (s)",
    Default = 0.3, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) Config.Fling.PulseTime = v end })
UI.FlingBox:AddSlider("FlingAttempts", { Text = "Retry Attempts",
    Default = 3, Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) Config.Fling.Attempts = v end })
UI.FlingBox:AddSlider("FlingSuccessDist", { Text = "Success Distance (studs)",
    Default = 8, Min = 3, Max = 50, Rounding = 0,
    Callback = function(v) Config.Fling.SuccessDist = v end })
Config.Connections.FlingPlayerAdded = Players.PlayerAdded:Connect(function()
    task.defer(function() Fn.refreshFlingTargets() end)
end)
Config.Connections.FlingPlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    if Config.Fling.Target == p then
        Config.Fling.Target = nil
        Config.Fling.TargetLabel = ""
    end
    task.defer(function() Fn.refreshFlingTargets() end)
end)
task.delay(1, function() Fn.refreshFlingTargets() end)
do
    local State    = Config.Fly.State
    local notifyFn = Fn.notify

    local function sFLY(vfly)
        local plr = LocalPlayer
        local char = plr.Character or plr.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
            humanoid = char:FindFirstChildOfClass("Humanoid")
        end
        if State.flyKeyDown or State.flyKeyUp then
            if State.flyKeyDown then State.flyKeyDown:Disconnect() State.flyKeyDown = nil end
            if State.flyKeyUp   then State.flyKeyUp:Disconnect()   State.flyKeyUp   = nil end
        end
        local T = getRoot(char)
        local CONTROL  = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local SPEED = 0
        local function FLY()
            State.FLYING = true
            local BG = Instance.new('BodyGyro')
            local BV = Instance.new('BodyVelocity')
            BG.P = 9e4
            BG.Parent = T
            BV.Parent = T
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.CFrame = T.CFrame
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            task.spawn(function()
                repeat task.wait()
                    local camera = workspace.CurrentCamera
                    if not vfly and humanoid then
                        humanoid.PlatformStand = true
                    end
                    if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                        SPEED = 50
                    elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                        SPEED = 0
                    end
                    if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                        BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                    elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                        BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    else
                        BV.Velocity = Vector3.new(0, 0, 0)
                    end
                    BG.CFrame = camera.CFrame
                until not State.FLYING
                CONTROL  = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()
                if humanoid then humanoid.PlatformStand = false end
            end)
        end
        local iySpeed  = State.iyflyspeed
        local vehSpeed = State.vehicleflyspeed
        State.flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then
                CONTROL.F =  (vfly and vehSpeed or iySpeed)
            elseif input.KeyCode == Enum.KeyCode.S then
                CONTROL.B = -(vfly and vehSpeed or iySpeed)
            elseif input.KeyCode == Enum.KeyCode.A then
                CONTROL.L = -(vfly and vehSpeed or iySpeed)
            elseif input.KeyCode == Enum.KeyCode.D then
                CONTROL.R =  (vfly and vehSpeed or iySpeed)
            elseif input.KeyCode == Enum.KeyCode.E and State.QEfly then
                CONTROL.Q =  (vfly and vehSpeed or iySpeed) * 2
            elseif input.KeyCode == Enum.KeyCode.Q and State.QEfly then
                CONTROL.E = -(vfly and vehSpeed or iySpeed) * 2
            end
            pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
        end)
        State.flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
            if processed then return end
            if     input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
            elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
            elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
            elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
            elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
            elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
            end
        end)
        FLY()
    end

    local function NOFLY()
        State.FLYING = false
        if State.flyKeyDown then State.flyKeyDown:Disconnect() State.flyKeyDown = nil end
        if State.flyKeyUp   then State.flyKeyUp:Disconnect()   State.flyKeyUp   = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
            LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    end

    local function unmobilefly(speaker)
        pcall(function()
            State.FLYING = false
            local root = getRoot(speaker.Character)
            if root then
                local v = root:FindFirstChild(State.velocityHandlerName)
                local g = root:FindFirstChild(State.gyroHandlerName)
                if v then v:Destroy() end
                if g then g:Destroy() end
            end
            local hum = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.PlatformStand = false end
            State._cachedMobileHum = nil
            State._cachedMobileBV  = nil
            State._cachedMobileBG  = nil
            if State.mfly1 then State.mfly1:Disconnect() State.mfly1 = nil end
            if State.mfly2 then State.mfly2:Disconnect() State.mfly2 = nil end
        end)
    end

    local function mobilefly(speaker, vfly)
        unmobilefly(speaker)
        State.FLYING = true
        local root = getRoot(speaker.Character)
        local camera = workspace.CurrentCamera
        local v3none = Vector3.new()
        local v3zero = Vector3.new(0, 0, 0)
        local v3inf  = Vector3.new(9e9, 9e9, 9e9)
        local controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        local bv = Instance.new("BodyVelocity")
        bv.Name = State.velocityHandlerName
        bv.Parent = root
        bv.MaxForce = v3zero
        bv.Velocity = v3zero
        local bg = Instance.new("BodyGyro")
        bg.Name = State.gyroHandlerName
        bg.Parent = root
        bg.MaxTorque = v3inf
        bg.P = 1000
        bg.D = 50
        State._cachedMobileHum = nil
        State._cachedMobileBV  = bv
        State._cachedMobileBG  = bg
        State.mfly1 = speaker.CharacterAdded:Connect(function()
            local newRoot = getRoot(speaker.Character)
            if not newRoot then return end
            local nbv = Instance.new("BodyVelocity")
            nbv.Name = State.velocityHandlerName
            nbv.Parent = newRoot
            nbv.MaxForce = v3zero
            nbv.Velocity = v3zero
            local nbg = Instance.new("BodyGyro")
            nbg.Name = State.gyroHandlerName
            nbg.Parent = newRoot
            nbg.MaxTorque = v3inf
            nbg.P = 1000
            nbg.D = 50
            State._cachedMobileHum = nil
            State._cachedMobileBV  = nbv
            State._cachedMobileBG  = nbg
        end)
        State.mfly2 = RunService.RenderStepped:Connect(function()
            root = getRoot(speaker.Character)
            camera = workspace.CurrentCamera
            local hum           = State._cachedMobileHum
            local VelocityHandler = State._cachedMobileBV
            local GyroHandler     = State._cachedMobileBG
            if not (hum and hum.Parent) then
                hum = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
                State._cachedMobileHum = hum
            end
            if not (VelocityHandler and VelocityHandler.Parent) then
                VelocityHandler = root and root:FindFirstChild(State.velocityHandlerName)
                State._cachedMobileBV = VelocityHandler
            end
            if not (GyroHandler and GyroHandler.Parent) then
                GyroHandler = root and root:FindFirstChild(State.gyroHandlerName)
                State._cachedMobileBG = GyroHandler
            end
            if speaker.Character and hum and root and VelocityHandler and GyroHandler then
                if VelocityHandler.MaxForce ~= v3inf then VelocityHandler.MaxForce = v3inf end
                if GyroHandler.MaxTorque ~= v3inf  then GyroHandler.MaxTorque = v3inf end
                if not vfly and not hum.PlatformStand then hum.PlatformStand = true end
                GyroHandler.CFrame = camera.CoordinateFrame
                VelocityHandler.Velocity = v3none
                local direction = controlModule:GetMoveVector()
                local speedFactor = (vfly and State.vehicleflyspeed or State.iyflyspeed) * 50
                if direction.X ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * speedFactor)
                end
                if direction.Z ~= 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * speedFactor)
                end
            end
        end)
    end

    function Fn.setFly(enabled)
        Config.Fly.Enabled = enabled
        if enabled then
            if IsMobile then
                mobilefly(LocalPlayer, Config.Fly.VehicleFly)
            else
                sFLY(Config.Fly.VehicleFly)
            end
            if notifyFn then notifyFn("Fly", "Fly enabled", 2) end
        else
            if IsMobile then
                unmobilefly(LocalPlayer)
            else
                NOFLY()
            end
            if notifyFn then notifyFn("Fly", "Fly disabled", 2) end
        end
    end

    function Fn.setFlySpeed(value)
        State.iyflyspeed = tonumber(value) or 50
        Config.Fly.Speed = State.iyflyspeed
    end

    function Fn.setQEFly(enabled)
        State.QEfly     = enabled
        Config.Fly.QEFly = enabled
    end

    function Fn.unloadFly()
        State.FLYING = false
        if State.flyKeyDown then State.flyKeyDown:Disconnect() State.flyKeyDown = nil end
        if State.flyKeyUp   then State.flyKeyUp:Disconnect()   State.flyKeyUp   = nil end
        if State.mfly1      then State.mfly1:Disconnect()      State.mfly1      = nil end
        if State.mfly2      then State.mfly2:Disconnect()      State.mfly2      = nil end
        State._cachedMobileHum = nil
        State._cachedMobileBV  = nil
        State._cachedMobileBG  = nil
    end
end
Shared._Invisible_RestoreLocal = _Invisible_RestoreLocal