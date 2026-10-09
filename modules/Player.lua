local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Options            = Shared.Options
local Toggles            = Shared.Toggles
local UI                 = Shared.UI
local Players            = Shared.Players
local UserInputService   = Shared.UserInputService
local RunService         = Shared.RunService
local ReplicatedStorage  = Shared.ReplicatedStorage
local VirtualInputManager = Shared.VirtualInputManager
local TweenService       = Shared.TweenService
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
local Remotes            = Shared.Remotes
local AttackEvent        = Shared.AttackEvent
local fast_tick          = Shared.fast_tick
local getProtectedGui    = Shared.getProtectedGui
local matchKey           = Shared.matchKey
local ASV_Notify         = Shared.ASV_Notify
local ASV_InstallModuleHook = Shared.ASV_InstallModuleHook
local ASV_MAX_RETRIES    = Shared.ASV_MAX_RETRIES
local ASV_COLLECTION     = Shared.ASV_COLLECTION
local _V3_UP_0           = Shared._V3_UP_0
local ToFV1_SetSilentAim = Shared.ToFV1_SetSilentAim
function Fn.SetupNoCutsceneHook()
    if Config.NoCutsceneHooked then return end
    Config.NoCutsceneHooked = true
    pcall(function()
        local ok, mt = pcall(function() return getrawmetatable(game) end)
        if ok and mt and setreadonly then
            pcall(function()
                setreadonly(mt, false)
                local oldIndex = mt.__index
                local state = Config._NoCutsceneState
                if not state.fakeBindable then
                    state.fakeBindable = Instance.new("BindableEvent")
                end
                if not state.fakeRemote then
                    state.fakeRemote = Instance.new("RemoteEvent")
                end
                local fakeBindable = state.fakeBindable
                local fakeRemote   = state.fakeRemote
                mt.__index = newcclosure(function(t, k)
                    if k == "OnClientEvent" or k == "Event" then
                        if Config.NoCutscene and not checkcaller() and typeof(t) == "Instance" then
                            local name = t.Name
                            if name == "cutscene" and k == "Event" then
                                local parent = t.Parent
                                if parent and parent.Name == "Game" then
                                    return fakeBindable.Event
                                end
                            elseif (name == "cutsceneEnd" or name == "cutsceneEnd2" or name == "cutsceneEndwithownchar" or name == "endscreencutscene") then
                                local parent = t.Parent
                                if parent and parent.Name == "Game" then
                                    return fakeRemote.OnClientEvent
                                end
                            end
                        end
                    end
                    return oldIndex(t, k)
                end)
                setreadonly(mt, true)
            end)
        end
    end)
end
local function NEX_showInstantResults()
    if not Config.NoCutscene then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = 70
        end
        game:GetService("UserInputService").MouseIconEnabled = true
        pcall(function()
            local SoundService = game:GetService("SoundService")
            local chase = SoundService and SoundService:FindFirstChild("chase")
            if chase then chase.Volume = 0 end
        end)
        LocalPlayer:SetAttribute("isspectating", true)
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local Results   = pg:FindFirstChild("Results")
            local EndScreen = pg:FindFirstChild("EndScreen")
            local Darkness  = pg:FindFirstChild("Darkness")
            if Results then Results.Enabled = true end
            if EndScreen then
                EndScreen.Enabled = true
                local blackout = EndScreen:FindFirstChild("blackout")
                if blackout then blackout.BackgroundTransparency = 1 end
            end
            if Darkness then
                Darkness.Enabled = true
                local frame2 = Darkness:FindFirstChild("Frame2")
                if frame2 then frame2.BackgroundTransparency = 1 end
            end
        end
    end)
end
function Fn.SetupNoCutsceneListeners()
    task.spawn(function()
        local gameFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
        gameFolder = gameFolder and gameFolder:WaitForChild("Game", 10)
        if not gameFolder then return end
        local names = { "endscreencutscene", "cutsceneEnd", "cutsceneEnd2", "cutsceneEndwithownchar" }
        local state = Config._NoCutsceneState
        for _, n in ipairs(names) do
            local event = gameFolder:WaitForChild(n, 10)
            if event and event:IsA("RemoteEvent") then
                local conn = event.OnClientEvent:Connect(NEX_showInstantResults)
                table.insert(state.conns, conn)
            end
        end
    end)
end
function Fn.applyGodMode()
    if not Config.Killer.Mods.GodMode then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.Health < hum.MaxHealth then
        Fn.safeCall("GodMode Health", function() hum.Health = hum.MaxHealth end)
    end
    local s = hum:GetState()
    if s == Enum.HumanoidStateType.Dead
    or s == Enum.HumanoidStateType.FallingDown
    or s == Enum.HumanoidStateType.Ragdoll then
        Fn.safeCall("GodMode State", function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end
end
function Fn.SetupAntiFallDamage()
    Fn.safeCall("AntiFallSetup", function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        if not r then return end
        local m = r:FindFirstChild("Mechanics")
        local fallEvent = m and m:FindFirstChild("Fall")
        if not (fallEvent and fallEvent:IsA("RemoteEvent")) then return end
        local ok, mt = pcall(function() return getrawmetatable(game) end)
        if ok and mt and setreadonly then
            Fn.safeCall("AntiFallHook", function()
                setreadonly(mt, false)
                local old = mt.__namecall
                mt.__namecall = newcclosure(function(self, ...)
                    if not checkcaller() and self == fallEvent then
                        local method = getnamecallmethod()
                        if method == "FireServer" then
                            if Config.Movement.FakePerfectLanding.Enabled then
                                Config.State.TempSpeedBoostEnd = fast_tick() + 3
                            end
                            if Config.Killer.Mods.AntiFall then
                                return nil
                            end
                        end
                    end
                    return old(self, ...)
                end)
                setreadonly(mt, true)
            end)
        end
    end)
end
Fn.SetupAntiFallDamage()
function Fn.scheduleInfiniteLungeScan()
    local S = Config.State
    if S._ilScanning or S.unloaded then return end
    if not (LocalPlayer.Team and LocalPlayer.Team.Name == "Killer") then return end
    local now = fast_tick()
    if now < S._ilScanNext then return end
    S._ilScanNext = now + 5
    local myEpoch = S._ilScanEpoch
    S._ilScanning = true
    task.spawn(function()
        pcall(function()
            local getupvalues = getupvalues or (debug and debug.getupvalues)
            local islclosure  = islclosure or is_l_closure or function(_) return true end
            if not getupvalues then
                if not S._ilFailNotified then
                    S._ilFailNotified = true
                    warn("[InfiniteLunge] Executor tidak mendukung 'getupvalues'. Tidak bisa menerapkan Infinite Max Hold.")
                end
                return
            end
            local scanned = 0
            for _, obj in pairs(getgc(true)) do
                scanned = scanned + 1
                if scanned % 500 == 0 then task.wait() end
                if S.unloaded or not Config.Killer.InfiniteLunge then return end
                if S._ilScanEpoch ~= myEpoch then return end
                if type(obj) == "function" and islclosure(obj) then
                    local success, upvals = pcall(getupvalues, obj)
                    if success and type(upvals) == "table" then
                        for _, upv in ipairs(upvals) do
                            if type(upv) == "table" and rawget(upv, "attack") then
                                local attackConfig = upv.attack
                                if type(attackConfig) == "table" then
                                    local mh = rawget(attackConfig, "maxHold")
                                    if mh ~= nil then
                                        if mh ~= math.huge and S._ilOrigMaxHold == nil then
                                            S._ilOrigMaxHold = mh
                                        end
                                        S._cachedAttackConfig = attackConfig
                                        attackConfig.maxHold = math.huge
                                        S._ilFailNotified = false
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not S._ilFailNotified then
                S._ilFailNotified = true
                warn("[InfiniteLunge] Tabel 'maxHold' tidak ditemukan. Pastikan karakter killer sudah dimuat atau coba lagi.")
            end
        end)
        S._ilScanning = false
    end)
end
function Fn.applyInfiniteLunge()
    if not (LocalPlayer.Team and LocalPlayer.Team.Name == "Killer") then return false end
    local S = Config.State
    local cfg = S._cachedAttackConfig
    if cfg and type(cfg) == "table" and rawget(cfg, "maxHold") ~= nil then
        cfg.maxHold = math.huge
        return true
    end
    if cfg then
        S._cachedAttackConfig = nil
        S._ilOrigMaxHold = nil
    end
    Fn.scheduleInfiniteLungeScan()
    return false
end
function Fn.invalidateInfiniteLungeCache()
    local S = Config.State
    S._ilScanEpoch = S._ilScanEpoch + 1
    local cfg, orig = S._cachedAttackConfig, S._ilOrigMaxHold
    if cfg and type(cfg) == "table" and orig ~= nil and orig ~= math.huge then
        pcall(function() cfg.maxHold = orig end)
    end
    S._cachedAttackConfig = nil
    S._ilOrigMaxHold = nil
    S._ilFailNotified = false
    S._ilScanNext = 0
end
function Fn.stopInfiniteLunge()
    Config.Killer.InfiniteLunge = false
    if Config.Connections.InfiniteLunge then
        Config.Connections.InfiniteLunge:Disconnect()
        Config.Connections.InfiniteLunge = nil
    end
    Fn.invalidateInfiniteLungeCache()
end
function Fn.startInfiniteLunge()
    local S = Config.State
    S._ilFailNotified = false
    S._ilScanNext = 0
    Fn.safeCall("InfiniteLunge Initial Apply", Fn.applyInfiniteLunge)
    if Config.Connections.InfiniteLunge then
        Config.Connections.InfiniteLunge:Disconnect()
        Config.Connections.InfiniteLunge = nil
    end
    local lastApply = 0
    Config.Connections.InfiniteLunge = Config.FakeConnection(Config.HeartbeatTasks, "InfiniteLunge", function()
        if not Config.Killer.InfiniteLunge then return end
        if Config.State.unloaded then return end
        local now = fast_tick()
        local interval = (S._cachedAttackConfig ~= nil) and 0.25 or 1
        if now - lastApply < interval then return end
        lastApply = now
        Fn.safeCall("InfiniteLunge Apply", Fn.applyInfiniteLunge)
    end)
end
function Fn.StartCooldownBypass()
    if not Config.State.CorruptHandlerFunc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" and islclosure(v) then
                local constants = debug.getconstants(v)
                if table.find(constants, "corrupt") and table.find(constants, "Immobile") then
                    Config.State.CorruptHandlerFunc = v
                    break
                end
            end
        end
    end
    if not Config.State.CorruptHandlerFunc then
        warn("corruptHandler function not found in memory.")
        return
    end
    if Config.Connections.CooldownBypass then
        Config.Connections.CooldownBypass:Disconnect()
    end
    Config.Connections.CooldownBypass = Config.FakeConnection(Config.HeartbeatTasks, "CooldownBypass", function()
        if not Config.Killer.BypassCooldown then return end
        local now = fast_tick()
        if now - Config.Timers.lastCooldownBypass < 0.5 then return end
        Config.Timers.lastCooldownBypass = now
        if Config.State.CorruptHandlerFunc then
            local upvalues = debug.getupvalues(Config.State.CorruptHandlerFunc)
            for idx, val in pairs(upvalues) do
                if type(val) == "boolean" then
                    if val == false then
                        debug.setupvalue(Config.State.CorruptHandlerFunc, idx, true)
                    end
                end
            end
        end
    end)
end
function Fn._findHiddenCooldownFuncs()
    local leapFn, m2Fn
    local getupvalues = getupvalues or (debug and debug.getupvalues)
    local islclosure  = islclosure or is_l_closure or function(_) return true end
    if not getupvalues then return nil end
    for _, v in pairs(getgc(true)) do
        if type(v) == "function" and islclosure(v) then
            local ok, info = pcall(debug.getinfo, v)
            if ok and info and info.name then
                if info.name == "tryActivate" then
                    leapFn = leapFn or v
                elseif info.name == "playM2Animation" then
                    m2Fn = m2Fn or v
                end
                if leapFn and m2Fn then break end
            end
        end
    end
    if not leapFn and not m2Fn then return nil end
    return leapFn, m2Fn
end
function Fn.StopNoCooldownHidden()
    Config.Killer.NoCooldownHidden = false
    if Config.Threads.NoCooldownHidden then
        Config.Threads.NoCooldownHidden = nil
    end
end
function Fn.StartNoCooldownHidden()
    local S = Config.State
    if S.unloaded then return end
    if Config.Threads.NoCooldownHidden then return end
    if not (getgc and debug and debug.getupvalues and debug.setupvalue) then
        warn("[NoCooldownHidden] Executor tidak mendukung getgc/debug. Fitur tidak bisa aktif.")
        return
    end
    local leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
    if not leapFn and not m2Fn then
        warn("[NoCooldownHidden] Function tryActivate/playM2Animation belum ditemukan. Aktifkan ulang setelah karakter killer dimuat.")
    else
        print("[NoCooldownHidden] Function ditemukan, bypass aktif.")
    end
    Config.Threads.NoCooldownHidden = task.spawn(function()
        local lastScan = 0
        while task.wait(0.1) do
            if S.unloaded or not Config.Killer.NoCooldownHidden then
                break
            end
            local now = fast_tick()
            if (not leapFn and not m2Fn) and (now - lastScan) >= 2 then
                lastScan = now
                leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
                if leapFn or m2Fn then
                    print("[NoCooldownHidden] Function ditemukan saat rescan, bypass aktif.")
                end
            end
            if leapFn then
                pcall(function()
                    local upvalues = debug.getupvalues(leapFn)
                    for i, value in pairs(upvalues) do
                        if type(value) == "boolean" and value == true then
                            pcall(debug.setupvalue, leapFn, i, false)
                        end
                    end
                end)
            end
            if m2Fn then
                pcall(function()
                    local upvalues = debug.getupvalues(m2Fn)
                    for i, value in pairs(upvalues) do
                        if type(value) == "boolean" and value == true then
                            pcall(debug.setupvalue, m2Fn, i, false)
                        end
                    end
                end)
            end
        end
        Config.Threads.NoCooldownHidden = nil
    end)
end
function Fn._findHiddenM2Func()
    local _leapFn, m2Fn = Fn._findHiddenCooldownFuncs()
    return m2Fn
end
function Fn.isM2AimlockTargetValid(char, root)
    if not char or not char.Parent then return false end
    local cfg = Config.Killer.M2Aimlock
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    if cfg.IgnoreDowned ~= false and Fn.checkDowned(char) then return false end
    if char:GetAttribute("IsCarried") then return false end
    if root and root.Parent then
        local range = cfg.Range or 250
        if (hrp.Position - root.Position).Magnitude > range then return false end
    end
    return true
end
function Fn._m2AimlockApplyTarget(char)
    local cfg = Config.Killer.M2Aimlock
    local partName = cfg.TargetPart or "HumanoidRootPart"
    local part = char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    cfg._targetChar = char
    cfg._targetPart = part
    return true
end
function Fn._destroyM2AimlockGyro()
    local cfg = Config.Killer.M2Aimlock
    if cfg._gyro then
        pcall(function() cfg._gyro:Destroy() end)
        cfg._gyro = nil
    end
end
function Fn._m2AimlockStartLock()
    local cfg = Config.Killer.M2Aimlock
    cfg._active = true
    cfg._releaseAt = fast_tick() + (cfg.LockDuration or 2.5)
    cfg._nextValidateAt = 0
    if cfg.RotateChar then
        Fn._destroyM2AimlockGyro()
        local root = Fn.getRoot()
        if root and root.Parent then
            local gyro = Instance.new("BodyGyro")
            gyro.Name = "FLNS_M2AimlockGyro"
            gyro.MaxTorque = Vector3.new(0, math.huge, 0)
            gyro.P = 90000
            gyro.D = 400
            gyro.CFrame = root.CFrame
            gyro.Parent = root
            cfg._gyro = gyro
        end
    end
end
function Fn._m2AimlockStopLock()
    local cfg = Config.Killer.M2Aimlock
    cfg._active = false
    cfg._targetChar = nil
    cfg._targetPart = nil
    cfg._releaseAt = 0
    cfg._nextValidateAt = 0
    Fn._destroyM2AimlockGyro()
end
function Fn._triggerM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    if not cfg._m2Fn then
        cfg._m2Fn = Fn._findHiddenM2Func()
    end
    if not cfg._m2Fn then
        return
    end
    if cfg._active then
        local newTarget = Fn._getM2AimlockTarget()
        if newTarget then
            Fn._m2AimlockApplyTarget(newTarget)
        elseif cfg._targetChar and not Fn.isM2AimlockTargetValid(cfg._targetChar, Fn.getRoot()) then
            Fn._m2AimlockStopLock()
        end
        return
    end
    local targetChar, dist = Fn._getM2AimlockTarget()
    if not targetChar then
        return
    end
    if not Fn._m2AimlockApplyTarget(targetChar) then return end
    cfg._lastTriggerAt = fast_tick()
    Fn._m2AimlockStartLock()
end
function Fn.StartM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    if Config.Connections.M2AimlockInputBegan and Config.Connections.M2AimlockRender then
        return
    end
    if not cfg._prepareConn then
        local ok, preparem2 = pcall(function()
            return Remotes:WaitForChild("Killers", 3)
                :WaitForChild("Hidden", 3)
                :WaitForChild("preparem2", 3)
        end)
        if ok and preparem2 then
            cfg._prepareConn = preparem2.Event:Connect(function()
                if not cfg.Enabled then return end
                if cfg._active then return end
                Fn.safeCall("M2Aimlock preparem2 fallback", function()
                    Fn._triggerM2Aimlock()
                end)
            end)
        end
    end
    if not Config.Connections.M2AimlockInputBegan then
        Config.Connections.M2AimlockInputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not cfg.Enabled then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            if not Fn.isKillerTeam() then return end
            local now = fast_tick()
            if now - (cfg._lastTriggerAt or 0) < 0.15 then return end
            Fn.safeCall("M2Aimlock Trigger", function()
                Fn._triggerM2Aimlock()
            end)
        end)
    end
    if not Config.Connections.M2AimlockRender then
        Config.Connections.M2AimlockRender = Config.FakeConnection(
            Config.RenderSteppedTasks, "M2AimlockRender", function(dt)
                dt = dt or (1 / 60)
                if not cfg.Enabled then
                    if cfg._active then Fn._m2AimlockStopLock() end
                    return
                end
                if not cfg._active then return end
                local now = fast_tick()
                if now >= cfg._releaseAt then
                    Fn._m2AimlockStopLock()
                    return
                end
                if now >= (cfg._nextValidateAt or 0) then
                    cfg._nextValidateAt = now + 0.1
                    if not Fn.isM2AimlockTargetValid(cfg._targetChar, Fn.getRoot()) then
                        local switched = false
                        if cfg.SwitchOnDowned ~= false then
                            local newTarget = Fn._getM2AimlockTarget()
                            if newTarget then
                                switched = Fn._m2AimlockApplyTarget(newTarget)
                            end
                        end
                        if not switched then
                            Fn._m2AimlockStopLock()
                            return
                        end
                    end
                end
                local cam = workspace.CurrentCamera
                if not cam then return end
                local targetPart = cfg._targetPart
                if not targetPart or not targetPart.Parent then
                    local targetChar = cfg._targetChar
                    if targetChar and targetChar.Parent then
                        local partName = cfg.TargetPart or "HumanoidRootPart"
                        targetPart = targetChar:FindFirstChild(partName)
                                    or targetChar:FindFirstChild("HumanoidRootPart")
                        cfg._targetPart = targetPart
                    end
                end
                if not targetPart then
                    Fn._m2AimlockStopLock()
                    return
                end
                local targetPos = targetPart.Position
                local camPos = cam.CFrame.Position
                local desiredCFrame
                if (targetPos - camPos).Magnitude > 0.01 then
                    desiredCFrame = CFrame.lookAt(camPos, targetPos)
                else
                    desiredCFrame = cam.CFrame
                end
                local rawStrength = cfg.LockStrength or 1
                local alpha = (rawStrength >= 1) and 1
                            or (1 - math.exp(-rawStrength * 15 * dt))
                cam.CFrame = cam.CFrame:Lerp(desiredCFrame, alpha)
                if cfg.RotateChar and cfg._gyro and cfg._gyro.Parent then
                    local root = Fn.getRoot()
                    if root and root.Parent then
                        local hrpPos = root.Position
                        local flatTarget = Vector3.new(targetPos.X, hrpPos.Y, targetPos.Z)
                        local dir = flatTarget - hrpPos
                        if dir.Magnitude > 0.01 then
                            cfg._gyro.CFrame = CFrame.lookAt(hrpPos, hrpPos + dir)
                        end
                    end
                end
            end)
    end
end
function Fn.StopM2Aimlock()
    local cfg = Config.Killer.M2Aimlock
    Fn._m2AimlockStopLock()
    cfg._m2Fn = nil
    if cfg._prepareConn then
        pcall(function() cfg._prepareConn:Disconnect() end)
        cfg._prepareConn = nil
    end
    if Config.Connections.M2AimlockInputBegan then
        pcall(function() Config.Connections.M2AimlockInputBegan:Disconnect() end)
        Config.Connections.M2AimlockInputBegan = nil
    end
    if Config.Connections.M2AimlockRender then
        Fn._destroyConn("M2AimlockRender", Config.Connections.M2AimlockRender)
        Config.Connections.M2AimlockRender = nil
    end
end
local function restoreCrouchAttributes()
    local orig = Config.State.AutoCrouchOriginals
    if not orig then return end
    Config.State.AutoCrouchOriginals = nil
    Config.State._autoCrouchSpeedLast = 0
    if not orig.char or not orig.char.Parent then return end
    pcall(function()
        orig.char:SetAttribute("Crouching", orig.Crouching)
        orig.char:SetAttribute("Crouchingserver", orig.CrouchingServer)
        orig.char:SetAttribute("IsRunning", orig.IsRunning)
        if orig.WalkSpeed then
            local hum = orig.char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = orig.WalkSpeed end
        end
    end)
end
local function TriggerCrouchStop()
    if not Config.State.AutoCrouchActive then return end
    restoreCrouchAttributes()
    Config.State.AutoCrouchActive = false
    Config.State.AutoCrouchKiller = nil
end
local function TriggerCrouchStart()
    if Config.State.AutoCrouchActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    Config.State.AutoCrouchActive = true
    local hum = char:FindFirstChildOfClass("Humanoid")
    Config.State.AutoCrouchOriginals = {
        char = char,
        Crouching = char:GetAttribute("Crouching"),
        CrouchingServer = char:GetAttribute("Crouchingserver"),
        IsRunning = char:GetAttribute("IsRunning"),
        WalkSpeed = hum and hum.WalkSpeed or nil,
    }
    pcall(function()
        char:SetAttribute("Crouching", true)
        char:SetAttribute("Crouchingserver", true)
        char:SetAttribute("IsRunning", false)
        if hum then
            hum.WalkSpeed = Config.Auto.AutoCrouch.WalkSpeed or 6
        end
    end)
end
local function hookKillerForAutoCrouch(p, char)
    if not p or not char then return end
    if p == LocalPlayer then return end
    if not p.Team or p.Team.Name ~= "Killer" then return end
    local cache = Config.State._autoCrouchAnims
    if not cache then return end
    if cache[char] then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        task.spawn(function()
            local h = char:WaitForChild("Humanoid", 5)
            if not h or Config.State.unloaded then return end
            if not Config.Auto.AutoCrouch.Enabled then return end
            hookKillerForAutoCrouch(p, char)
        end)
        return
    end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        task.spawn(function()
            local a = hum:WaitForChild("Animator", 5)
            if not a or Config.State.unloaded then return end
            if not Config.Auto.AutoCrouch.Enabled then return end
            hookKillerForAutoCrouch(p, char)
        end)
        return
    end
    local entry = { tracks = {} }
    entry.conn = animator.AnimationPlayed:Connect(function(track)
        local anim = track.Animation
        if not anim then return end
        if not (p.Team and p.Team.Name == "Killer") then return end
        local targetId = Config.Auto.AutoCrouch.AnimId
        if anim.AnimationId ~= targetId then return end
        if not Config.Auto.AutoCrouch.Enabled then return end
        if not Fn.isSurvivorTeam() then return end
        if Fn.isDowned(LocalPlayer.Character) then return end
        local myRoot = Fn.getRoot()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not myRoot or not hrp then return end
        local dist = (hrp.Position - myRoot.Position).Magnitude
        local detectDist = Config.Auto.AutoCrouch.DetectDistance or 15
        if dist > detectDist then return end
        TriggerCrouchStart()
        Config.State.AutoCrouchKiller = p
        if entry.tracks[track] then return end
        local stopConn
        stopConn = track.Stopped:Connect(function()
            if stopConn then
                pcall(function() stopConn:Disconnect() end)
                stopConn = nil
            end
            entry.tracks[track] = nil
            TriggerCrouchStop()
        end)
        entry.tracks[track] = stopConn
    end)
    cache[char] = entry
    entry.ancestryConn = char.AncestryChanged:Connect(function(_, parent)
        if parent then return end
        if Config.State.AutoCrouchKiller == p then
            Fn.safeCall("AutoCrouch Restore", function() TriggerCrouchStop() end)
        end
        if entry.conn then
            pcall(function() entry.conn:Disconnect() end)
            entry.conn = nil
        end
        if entry.ancestryConn then
            pcall(function() entry.ancestryConn:Disconnect() end)
            entry.ancestryConn = nil
        end
        for _, sc in pairs(entry.tracks) do
            pcall(function() sc:Disconnect() end)
        end
        entry.tracks = {}
        cache[char] = nil
    end)
end
function Fn.startAutoCrouch()
    if Config.State._autoCrouchPlayerAddedConn then return end
    Config.State._autoCrouchAnims     = Config.State._autoCrouchAnims     or {}
    Config.State._autoCrouchCharConns = Config.State._autoCrouchCharConns or {}
    for _, p in ipairs(Config.ESPCache.PlayerList) do
        if p ~= LocalPlayer then
            if p.Character then
                hookKillerForAutoCrouch(p, p.Character)
            end
            Config.State._autoCrouchCharConns[p] = p.CharacterAdded:Connect(function(newChar)
                task.spawn(function()
                    local hum = newChar:WaitForChild("Humanoid", 5)
                    if not hum or Config.State.unloaded then return end
                    if not Config.Auto.AutoCrouch.Enabled then return end
                    hookKillerForAutoCrouch(p, newChar)
                end)
            end)
        end
    end
    Config.State._autoCrouchPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        Config.State._autoCrouchCharConns[p] = p.CharacterAdded:Connect(function(newChar)
            task.spawn(function()
                local hum = newChar:WaitForChild("Humanoid", 5)
                if not hum or Config.State.unloaded then return end
                if not Config.Auto.AutoCrouch.Enabled then return end
                hookKillerForAutoCrouch(p, newChar)
            end)
        end)
        if p.Character then
            hookKillerForAutoCrouch(p, p.Character)
        end
    end)
end
function Fn.stopAutoCrouch()
    if not Config.State._autoCrouchPlayerAddedConn
        and not next(Config.State._autoCrouchCharConns or {})
        and not next(Config.State._autoCrouchAnims or {}) then
        TriggerCrouchStop()
        return
    end
    if Config.State._autoCrouchPlayerAddedConn then
        pcall(function() Config.State._autoCrouchPlayerAddedConn:Disconnect() end)
        Config.State._autoCrouchPlayerAddedConn = nil
    end
    for p, conn in pairs(Config.State._autoCrouchCharConns or {}) do
        pcall(function() conn:Disconnect() end)
        Config.State._autoCrouchCharConns[p] = nil
    end
    for char, entry in pairs(Config.State._autoCrouchAnims or {}) do
        if entry.conn then
            pcall(function() entry.conn:Disconnect() end)
        end
        if entry.ancestryConn then
            pcall(function() entry.ancestryConn:Disconnect() end)
        end
        for _, sc in pairs(entry.tracks or {}) do
            pcall(function() sc:Disconnect() end)
        end
        Config.State._autoCrouchAnims[char] = nil
    end
    TriggerCrouchStop()
end
Config.Connections.AutoCrouchSpeedEnforce = Config.FakeConnection(Config.HeartbeatTasks, "AutoCrouchSpeed", function()
    if not Config.State.AutoCrouchActive then return end
    if Config.State.unloaded then return end
    local orig = Config.State.AutoCrouchOriginals
    if not orig then return end
    local now = fast_tick()
    if now - (Config.State._autoCrouchSpeedLast or 0) < 0.1 then return end
    Config.State._autoCrouchSpeedLast = now
    local char = orig.char
    if not char or not char.Parent then return end
    if LocalPlayer.Character ~= char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if orig.WalkSpeed == nil then orig.WalkSpeed = hum.WalkSpeed end
    local target = Config.Auto.AutoCrouch.WalkSpeed or 6
    if hum.WalkSpeed ~= target then
        hum.WalkSpeed = target
    end
end)

local function suppressHealingAnimation()
    if Config.State._selfHealAnimListener then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    Config.State._selfHealAnimListener = animator.AnimationPlayed:Connect(function(activeTrack)
        if activeTrack.Animation and activeTrack.Animation.AnimationId:find("95836365038528") then
            activeTrack:Stop(0)
        end
    end)
end

local function restoreHealingAnimation()
    if Config.State._selfHealAnimListener then
        pcall(function() Config.State._selfHealAnimListener:Disconnect() end)
        Config.State._selfHealAnimListener = nil
    end
end

function Fn.startSelfHeal()
    Config.Auto.SelfHeal.Enabled = true
    suppressHealingAnimation()
    if Config.State._selfHealStarted then return end
    Config.State._selfHealStarted = true

    task.spawn(function()
        while not Config.State.unloaded do
            task.wait(3)
            if Config.Auto.SelfHeal.Enabled and not Config.State.unloaded then
                local team = LocalPlayer.Team
                if team and team.Name ~= "Killer" then
                    local character = LocalPlayer.Character
                    if character then
                        local interactState = character:FindFirstChild("CheckInterractable")
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChildOfClass("Humanoid")

                        local isBusy = false
                        if interactState then
                            if interactState:GetAttribute("isVaulting")
                            or interactState:GetAttribute("isRepairing")
                            or interactState:GetAttribute("isUnhooking")
                            or interactState:GetAttribute("isHealing")
                            or interactState:GetAttribute("isSliding") then
                                isBusy = true
                            end
                        end

                        if not isBusy and rootPart and humanoid and humanoid.Health < humanoid.MaxHealth then
                            pcall(function()
                                local healingFolder = Remotes:FindFirstChild("Healing")
                                if healingFolder and healingFolder:FindFirstChild("HealEvent") then
                                    healingFolder.HealEvent:FireServer(rootPart, true)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)

    Config.State._selfHealCharRemoving = LocalPlayer.CharacterRemoving:Connect(function()
        restoreHealingAnimation()
    end)
    Config.State._selfHealCharAdded = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(5)
        if Config.Auto.SelfHeal.Enabled and not Config.State.unloaded then
            suppressHealingAnimation()
        end
    end)
end

function Fn.stopSelfHeal()
    Config.Auto.SelfHeal.Enabled = false
    restoreHealingAnimation()
end

function Fn.teardownSelfHeal()
    Fn.stopSelfHeal()
    if Config.State._selfHealCharAdded then
        pcall(function() Config.State._selfHealCharAdded:Disconnect() end)
        Config.State._selfHealCharAdded = nil
    end
    if Config.State._selfHealCharRemoving then
        pcall(function() Config.State._selfHealCharRemoving:Disconnect() end)
        Config.State._selfHealCharRemoving = nil
    end
    Config.State._selfHealStarted = nil
end

function Fn.InstantBandageSpam()
    local B = Config.Auto.Bandage
    if not B or B.Busy then return end
    B.Busy = true
    task.spawn(function()
        pcall(function()
            local bandageRemote = ReplicatedStorage:FindFirstChild("Remotes")
            bandageRemote = bandageRemote and bandageRemote:FindFirstChild("Items")
            bandageRemote = bandageRemote and bandageRemote:FindFirstChild("Bandage")
            bandageRemote = bandageRemote and bandageRemote:FindFirstChild("Fire")
            local character = LocalPlayer.Character
            if bandageRemote and character then
                local bandage = character:FindFirstChild("Bandage")
                if not bandage then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    bandage = backpack and backpack:FindFirstChild("Bandage")
                end
                if bandage then
                    local rightArm = bandage:FindFirstChild("Right Arm")
                    rightArm = rightArm and rightArm:FindFirstChild("Bandage") or bandage
                    for _ = 1, 400 do
                        bandageRemote:FireServer(true, rightArm)
                        bandageRemote:FireServer(false, rightArm)
                    end
                end
            end
        end)
        task.wait(0.1)
        if B then B.Busy = false end
    end)
end

function Fn.startAutoBandage()
    local B = Config.Auto.Bandage
    if not B or B.Heartbeat then return end
    B.Auto = true
    B.Heartbeat = Config.FakeConnection(Config.HeartbeatTasks, "AutoBandage", function()
        if Config.State.unloaded then return end
        if not (Config.Auto.Bandage and Config.Auto.Bandage.Auto) then return end
        local now = fast_tick()
        if now - (B._lastScan or 0) < 0.5 then return end
        B._lastScan = now
        if now - (B.LastTrigger or 0) < (B.Cooldown or 1.5) then return end
        if not Fn.isSurvivorTeam() then return end
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or humanoid.MaxHealth <= 0 then return end
        local threshold = (B.Threshold or 95) / 100
        if humanoid.Health >= humanoid.MaxHealth * threshold then return end
        local bandage = character:FindFirstChild("Bandage")
        if not bandage then
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            bandage = backpack and backpack:FindFirstChild("Bandage")
        end
        if not bandage then return end
        local interactState = character:FindFirstChild("CheckInterractable")
        if interactState then
            if interactState:GetAttribute("isVaulting")
            or interactState:GetAttribute("isRepairing")
            or interactState:GetAttribute("isUnhooking")
            or interactState:GetAttribute("isHealing")
            or interactState:GetAttribute("isSliding") then
                return
            end
        end
        B.LastTrigger = now
        Fn.InstantBandageSpam()
    end)
end

function Fn.stopAutoBandage()
    local B = Config.Auto.Bandage
    if not B then return end
    B.Auto = false
    if B.Heartbeat then
        B.Heartbeat:Disconnect()
        B.Heartbeat = nil
    end
end

function Fn.startFlowstate()
    if Config.Flowstate.WatcherActive then return end
    Config.Flowstate.WatcherActive = true
    task.spawn(function()
        while Config.Flowstate.Enabled do
            local char = LocalPlayer.Character
            if char then
                local current = char:GetAttribute("Flowstate")
                if current ~= true then
                    pcall(function()
                        char:SetAttribute("Flowstate", true)
                    end)
                end
            end
            task.wait(0.1)
        end
        Config.Flowstate.WatcherActive = false
    end)
end
function Fn.pressRightClick()
    local mousePos = UserInputService:GetMouseLocation()
    local x, y = mousePos.X, mousePos.Y
    VirtualInputManager:SendMouseButtonEvent(x, y, 1, true, game, 0)
    task.delay(0.05 + math.random() * 0.05, function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 1, false, game, 0)
    end)
end
function Fn.getGuiByPath(path)
    local current = PlayerGui
    for segment in string.gmatch(path, "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end
function Fn.getGuiByPaths(paths)
    for _, path in ipairs(paths) do
        local node = Fn.getGuiByPath(path)
        if node and node:IsA("GuiObject") then return node end
    end
    return nil
end
function Fn.pressParryButton()
    if UserInputService.TouchEnabled then
        local btn = Fn.getGuiByPath("Survivor-mob.Controls.Gui-mob")
        if btn and btn:IsA("GuiObject") then
            local pos  = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local inset = game:GetService("GuiService"):GetGuiInset()
            local x = pos.X + size.X/2 + inset.X
            local y = pos.Y + size.Y/2 + inset.Y
            VirtualInputManager:SendTouchEvent(Config.TouchID, 0, x, y)
            task.delay(0.01, function()
                VirtualInputManager:SendTouchEvent(Config.TouchID, 2, x, y)
            end)
            return
        end
        Fn.pressRightClick()
    else
        Fn.pressRightClick()
    end
end
function Fn.PlayFakeParry()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    if Config.State.FakeParryTrack then Config.State.FakeParryTrack:Stop(); Config.State.FakeParryTrack = nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = Config.FakeParry.Anims[Config.FakeParry.Animation]
    Config.State.FakeParryTrack = animator:LoadAnimation(anim)
    Config.State.FakeParryTrack.Priority = Enum.AnimationPriority.Action
    Config.State.FakeParryTrack:Play()
end
local _parryVisual = {
    gradients        = {},
    gradientsBoundAt  = 0,
    cooldownToken     = 0,
    parryTrack        = nil,
    parryTrackChar    = nil,
    faceHeartbeatConn = nil,
    actionAppliedFor  = nil,
    COLOR_NORMAL      = Color3.fromRGB(255, 255, 255),
    COLOR_DISABLED    = Color3.fromRGB(77,  77,  77),
}
function Fn.parryVisual_bindGradients(force)
    local now = fast_tick()
    if not force and (_parryVisual.gradientsBoundAt > 0 and now - _parryVisual.gradientsBoundAt < 1.0) then
        return _parryVisual.gradients
    end
    _parryVisual.gradientsBoundAt = now
    local keep = {}
    for _, g in ipairs(_parryVisual.gradients) do
        if g and g.Parent then table.insert(keep, g) end
    end
    _parryVisual.gradients = keep
    local function tryAdd(grad)
        if not grad or not grad:IsA("UIGradient") then return end
        for _, existing in ipairs(_parryVisual.gradients) do
            if existing == grad then return end
        end
        grad.Offset = Vector2.new(0, 0.25)
        table.insert(_parryVisual.gradients, grad)
    end
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        for _, guiName in ipairs({ "Survivor", "Survivor-con" }) do
            local root = pg:FindFirstChild(guiName)
            local bar = root and root:FindFirstChild("Gen")
                and root.Gen:FindFirstChild("ItemFrame")
                and root.Gen.ItemFrame:FindFirstChild("Gui")
                and root.Gen.ItemFrame.Gui:FindFirstChild("Bar")
            if bar then
                local g = bar:FindFirstChildOfClass("UIGradient")
                if g then tryAdd(g) end
            end
        end
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        local mob = pg:FindFirstChild("Survivor-mob")
        local controls = mob and mob:FindFirstChild("Controls")
        if not controls then return end
        for _, child in ipairs(controls:GetChildren()) do
            if child:IsA("ImageButton") and child.Name == "Gui-mob" then
                local bar = child:FindFirstChild("Bar")
                if bar then
                    local g = bar:FindFirstChildOfClass("UIGradient")
                    if g then tryAdd(g) end
                end
            end
        end
    end)
    return _parryVisual.gradients
end
function Fn.parryVisual_setIconsColor(color)
    local grads = Fn.parryVisual_bindGradients()
    for _, g in ipairs(grads) do
        if g and g.Parent and g.Parent.Parent then
            local frame = g.Parent.Parent
            local icon = frame:FindFirstChild("icon")
            if icon then icon.ImageColor3 = color end
            local outer = frame.Parent
            if outer then
                local guiOuter = outer:FindFirstChild("Gui")
                if guiOuter then guiOuter.ImageColor3 = color end
            end
        end
    end
end
function Fn.parryVisual_refresh()
    if not Config.Auto.ParryUICooldown then return end
    local silenced = (Config.State._parrySilenced == true)
    local cooldown = (Config.State.ParryCooldown == true)
    local resolving = Config.State.ParryActive == true
    if silenced or cooldown or resolving then
        Fn.parryVisual_setIconsColor(_parryVisual.COLOR_DISABLED)
    else
        Fn.parryVisual_setIconsColor(_parryVisual.COLOR_NORMAL)
    end
end
function Fn.parryVisual_playCooldownTween(duration)
    if not Config.Auto.ParryUICooldown then return end
    local grads = Fn.parryVisual_bindGradients()
    if #grads == 0 then return end
    local dur = math.max(0.05, tonumber(duration) or 0.5)
    for _, g in ipairs(grads) do
        if g and g.Parent then
            g.Offset = Vector2.new(0, 0.75)
            local tween = TweenService:Create(g,
                TweenInfo.new(dur, Enum.EasingStyle.Linear),
                { Offset = Vector2.new(0, 0.25) })
            tween:Play()
            tween.Completed:Connect(function()
                Fn.parryVisual_refresh()
            end)
        end
    end
end
function Fn.parryVisual_startCooldown(duration)
    if not Config.Auto.ParryUICooldown then return end
    local d = tonumber(duration) or 0
    _parryVisual.cooldownToken = _parryVisual.cooldownToken + 1
    local token = _parryVisual.cooldownToken
    Config.State.ParryActive = false
    Fn.parryVisual_refresh()
    if d > 0 then
        Fn.parryVisual_playCooldownTween(d)
        task.delay(d, function()
            if Config.State.unloaded then return end
            if _parryVisual.cooldownToken == token then
                Fn.parryVisual_refresh()
            end
        end)
    end
end
function Fn.parryVisual_faceLookDirection()
    if not Config.Auto.ParryFaceLock then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local cam  = workspace.CurrentCamera
    if not root or not hum or not cam then return end
    local look = cam.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude <= 1e-4 then return end
    local targetCFrame = CFrame.new(root.Position, root.Position + flat.Unit)
    if _parryVisual.faceHeartbeatConn then
        pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
        _parryVisual.faceHeartbeatConn = nil
    end
    hum.AutoRotate = false
    local tween = TweenService:Create(root,
        TweenInfo.new(0.2, Enum.EasingStyle.Linear),
        { CFrame = targetCFrame })
    tween:Play()
    local lockDur = Config.Auto.ParryLockDuration or 0.8
    tween.Completed:Connect(function()
        if not root or not root.Parent or not hum or not hum.Parent then return end
        local startT = fast_tick()
        _parryVisual.faceHeartbeatConn = RunService.Heartbeat:Connect(function()
            if Config.State.unloaded then
                pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
                _parryVisual.faceHeartbeatConn = nil
                return
            end
            if fast_tick() - startT >= lockDur then
                pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
                _parryVisual.faceHeartbeatConn = nil
                if hum and hum.Parent then hum.AutoRotate = true end
                return
            end
            if root and root.Parent then
                root.CFrame = CFrame.new(root.Position, root.Position + flat.Unit)
            else
                pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
                _parryVisual.faceHeartbeatConn = nil
            end
        end)
    end)
end

function Fn.parryVisual_loadAnim()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return nil end

    local cachedTrack = _parryVisual.parryTrack
    if cachedTrack and _parryVisual.parryTrackChar == char then

        local valid = false
        pcall(function() valid = cachedTrack.IsPlaying ~= nil end)
        if valid then
            return cachedTrack
        end

        _parryVisual.parryTrack = nil
        _parryVisual.parryTrackChar = nil
    end

    if _parryVisual.parryTrack then
        pcall(function() _parryVisual.parryTrack:Stop() end)
        _parryVisual.parryTrack = nil
        _parryVisual.parryTrackChar = nil
    end

    local selectedAnim = Config.Auto.ParryAnim
    if not selectedAnim or selectedAnim == "None" then return nil end

    local anims = Config.Auto.ParryAnims or {}
    local animId = anims[selectedAnim]
    if not animId then return nil end

    if type(animId) == "string" then
        animId = tonumber(animId:match("rbxassetid://(%d+)") or animId:match("(%d+)"))
    end
    if not animId then return nil end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animId)

    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    anim:Destroy() 
    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        _parryVisual.parryTrack     = track
        _parryVisual.parryTrackChar = char  
        return track
    end
    return nil
end
function Fn.parryVisual_playParryAnim()
    local selectedAnim = Config.Auto.ParryAnim
    if not selectedAnim or selectedAnim == "None" then return nil end
    local anims = Config.Auto.ParryAnims or {}
    if not anims[selectedAnim] then return nil end
    local track = Fn.parryVisual_loadAnim()
    if track then
        pcall(function() track:Play() end)
        return track
    end
    return nil
end
function Fn.parryVisual_applyAction()
    if not Config.Auto.ParryApplySlow then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local CollectionService = game:GetService("CollectionService")
    pcall(function() CollectionService:AddTag(root, "doing action") end)
    _parryVisual.actionAppliedFor = root
    pcall(function()
        local slow = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("Mechanics")
            and ReplicatedStorage.Remotes.Mechanics:FindFirstChild("Slow")
        if slow and slow:IsA("BindableEvent") then
            slow:Fire(0, 1, 0)
        elseif slow and slow:IsA("RemoteEvent") then
            slow:FireServer(0, 1, 0)
        end
    end)
end
function Fn.parryVisual_removeAction()
    local root = _parryVisual.actionAppliedFor
    if not root then return end
    _parryVisual.actionAppliedFor = nil
    if not root or not root.Parent then return end
    local CollectionService = game:GetService("CollectionService")
    pcall(function() CollectionService:RemoveTag(root, "doing action") end)
end
function Fn.parryVisual_reset()
    if _parryVisual.faceHeartbeatConn then
        pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
        _parryVisual.faceHeartbeatConn = nil
    end
    if _parryVisual.parryTrack then
        pcall(function() _parryVisual.parryTrack:Stop() end)
        _parryVisual.parryTrack = nil
    end
    _parryVisual.parryTrackChar = nil
    Fn.parryVisual_removeAction()
    _parryVisual.gradients = {}
    _parryVisual.gradientsBoundAt = 0
    _parryVisual.cooldownToken = _parryVisual.cooldownToken + 1
    Fn.parryVisual_resetSilencedHook()
end
local _parrySilencedHooked = false
function Fn.parryVisual_hookSilenced()
    if _parrySilencedHooked then return end
    _parrySilencedHooked = true
    local CollectionService = game:GetService("CollectionService")

    pcall(function()
        CollectionService:GetInstanceAddedSignal("Silenced"):Connect(function(inst)
            local char = LocalPlayer.Character
            if inst ~= char then return end
            Config.State._parrySilenced = true
            Fn.parryVisual_refresh()

            if _parryVisual.parryTrack then
                pcall(function() _parryVisual.parryTrack:Stop() end)
            end
            Fn.parryVisual_removeAction()

            _parryVisual._doParryToken = (_parryVisual._doParryToken or 0) + 1
            Config.State.ParryActive = false
        end)
    end)

    pcall(function()
        CollectionService:GetInstanceRemovedSignal("Silenced"):Connect(function(inst)
            if inst ~= LocalPlayer.Character then return end
            Config.State._parrySilenced = false
            Fn.parryVisual_refresh()
        end)
    end)
end
function Fn.parryVisual_resetSilencedHook()
    _parrySilencedHooked = false
end
local _parryRemoteCache = nil
local _parryRemoteTriedAt = 0
local function _getParryRemote()
    if _parryRemoteCache and _parryRemoteCache.Parent then
        return _parryRemoteCache
    end
    local now = fast_tick()
    if now - _parryRemoteTriedAt < 0.5 then return nil end
    _parryRemoteTriedAt = now
    local ok, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 2)
            :WaitForChild("Items", 2):WaitForChild("Parrying Dagger", 2)
            :WaitForChild("parry", 2)
    end)
    if ok and remote and remote:IsA("RemoteEvent") then
        _parryRemoteCache = remote
        return remote
    end
    return nil
end
function Fn.canParryLegit()
    local myChar = LocalPlayer.Character
    if not myChar then return false, "no character" end
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false, "no humanoid/root" end
    if not Fn.isSurvivorTeam() or Fn.isDowned() then
        return false, "not survivor / downed"
    end
    local hasDagger = false
    for _, t in ipairs(myChar:GetChildren()) do
        local n = t.Name:lower()
        if n:find("parry", 1, true) or n:find("dagger", 1, true) then
            hasDagger = t:IsDescendantOf(myChar)
            if hasDagger then break end
        end
    end
    if not hasDagger then return false, "dagger not equipped" end
    for _, node in ipairs({ myChar, myChar:FindFirstChild("Parrying Dagger") }) do
        if node and (node:GetAttribute("Silenced") or node:GetAttribute("IsSilenced")) then
            return false, "silenced"
        end
    end
    local now = fast_tick()
    if Config.State.ParryCooldown then
        return false, "cooldown"
    end
    if Config.State.ParryActive then
        return false, "resolving"
    end
    if LocalPlayer:GetAttribute("IsDead") then return false, "dead" end
    if myChar:GetAttribute("IsCarried") then return false, "carried" end
    if myChar:GetAttribute("IsHooked") then return false, "hooked" end
    local CollectionService = game:GetService("CollectionService")
    if CollectionService:HasTag(root, "doing action") then
        return false, "doing action"
    end
    local checkInt = myChar:FindFirstChild("CheckInterractable")
    if checkInt then
        for _, attr in ipairs({
            "isVaulting", "isSliding", "isDroppingPallet",
            "isRepairing", "isHealing", "isUnhooking", "isExiting"
        }) do
            if checkInt:GetAttribute(attr) then
                return false, "busy:" .. attr
            end
        end
    end
    if hum.Health < hum.MaxHealth * 0.5 then
        return false, "low health"
    end
    if now - (Config.State.lastParry or 0) < 0.5 then
        return false, "anti-spam gap"
    end
    return true
end
function Fn.fireParryRemote()
    local remote = _getParryRemote()
    if not remote then return false end
    local ok = pcall(function() remote:FireServer() end)
    return ok
end

function Fn.doParry()
    local now = fast_tick()
    local canFire = Fn.canParryLegit()
    if not canFire then return end

    local delay = Config.Auto.ParryDelay or 0
    Config.State.lastParry      = now
    Config.State.ParryActive   = true

    local token = (_parryVisual._doParryToken or 0) + 1
    _parryVisual._doParryToken = token

    local function doFire()
        if _parryVisual._doParryToken ~= token then return end 
        local fired = false
        local mode  = Config.Auto.ParryMode or "Instant"

        if mode == "Legit" then
            Fn.pressParryButton()
            fired = true
            Config.State.lastParryPressAt = fast_tick()
        else
            if _getParryRemote() then
                fired = Fn.fireParryRemote()
            end
            if not fired then
                Config.State.ParryActive = false
                Fn.parryVisual_refresh()
                return
            end
        end
        Config.State.lastParry = fast_tick()

        if Config.Auto.ParryVisualFX and mode ~= "Legit" then
            Fn.parryVisual_refresh()
            Fn.parryVisual_faceLookDirection()

            local track = Fn.parryVisual_playParryAnim()
            Fn.parryVisual_applyAction()

            local conn
            if track then
                conn = track.Stopped:Connect(function()
                    if _parryVisual._doParryToken ~= token then return end
                    Fn.parryVisual_removeAction()
                    if conn then pcall(function() conn:Disconnect() end); conn = nil end
                end)
            end

            local lockDur = (Config.Auto.ParryLockDuration or 0.8)
            task.delay(lockDur + 0.5, function()
                if _parryVisual._doParryToken ~= token then return end
                if conn then pcall(function() conn:Disconnect() end); conn = nil end
                Fn.parryVisual_removeAction()
            end)
        else

            task.delay(0.25, function()
                if _parryVisual._doParryToken ~= token then return end
                if Config.State.ParryActive then
                    Config.State.ParryActive = false
                    Fn.parryVisual_refresh()
                end
            end)
        end

        if not Config.Connections.ParryResultHook then
            task.delay(0.4, function()
                if _parryVisual._doParryToken ~= token then return end
                Config.State.ParryActive = false
                Fn.parryVisual_refresh()
            end)
        end
    end

    if delay > 0 then
        task.delay(delay, doFire)
    else
        doFire()
    end
end
function Fn.isInParryRange(killerChar)
    local myRoot = Fn.getRoot()
    if not myRoot or not killerChar then return false end
    local enemyRoot = killerChar:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return false end
    return (enemyRoot.Position - myRoot.Position).Magnitude <= Config.Auto.ParryDistance
end
function Fn.SetupParryResultHook()
    if Config.Connections.ParryResultHook then return end
    local ok, parryResult = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5)
            :WaitForChild("Items", 5):WaitForChild("Parrying Dagger", 5)
            :WaitForChild("parryResult", 5)
    end)
    if not ok or not parryResult then
        if not Config.State._parryHookWarned then
            Config.State._parryHookWarned = true
            warn("[FALLENS] parryResult remote not found, dynamic parry cooldown disabled.")
        end
        return
    end
    if Config.Connections.ParryResultHook then return end
    local _mb2DownAt, _mb2DownX, _mb2DownY = 0, 0, 0
    Config.Connections.ParryManualBegin = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            _mb2DownAt = fast_tick()
            local m = UserInputService:GetMouseLocation()
            _mb2DownX, _mb2DownY = m.X, m.Y
        end
    end)
    Config.Connections.ParryManualEnd = UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local dt = fast_tick() - _mb2DownAt
            local m = UserInputService:GetMouseLocation()
            local moved = math.abs(m.X - _mb2DownX) + math.abs(m.Y - _mb2DownY)
            if _mb2DownAt > 0 and dt < 0.3 and moved < 6 then
                Config.State.lastManualParryInputAt = fast_tick()
            end
            _mb2DownAt = 0
        end
    end)
    Config.Connections.ParryResultHook = parryResult.OnClientEvent:Connect(function(success, cooldownArg)
        if type(success) ~= "boolean" then return end

        local cooldownSec
        if type(cooldownArg) == "number" then
            cooldownSec = cooldownArg
        else
            cooldownSec = success and 90 or 60
        end
        cooldownSec = math.clamp(cooldownSec, 0, 120)

        if Config.State.ParryCooldownThread then
            pcall(function() task.cancel(Config.State.ParryCooldownThread) end)
            Config.State.ParryCooldownThread = nil
        end

        if cooldownSec > 0 then
            Config.State.ParryCooldown = true
            Config.State.ParryCooldownThread = task.delay(cooldownSec, function()
                if Config.State.unloaded then return end
                Config.State.ParryCooldown = false
                Config.State.ParryCooldownThread = nil
                Fn.parryVisual_refresh()
            end)
        else
            Config.State.ParryCooldown = false
        end

        Config.State.ParryActive = false

        if Config.Auto.ParryVisualFX and Config.Auto.ParryUICooldown and cooldownSec > 0 then
            Fn.parryVisual_startCooldown(cooldownSec)
        else
            Fn.parryVisual_refresh()
        end
    end)
end
function Fn.TeardownParryResultHook()
    if Config.Connections.ParryResultHook then
        pcall(function() Config.Connections.ParryResultHook:Disconnect() end)
        Config.Connections.ParryResultHook = nil
    end
    if Config.Connections.ParryManualBegin then
        pcall(function() Config.Connections.ParryManualBegin:Disconnect() end)
        Config.Connections.ParryManualBegin = nil
    end
    if Config.Connections.ParryManualEnd then
        pcall(function() Config.Connections.ParryManualEnd:Disconnect() end)
        Config.Connections.ParryManualEnd = nil
    end
    if Config.State.ParryCooldownThread then
        pcall(function() task.cancel(Config.State.ParryCooldownThread) end)
        Config.State.ParryCooldownThread = nil
    end
    Config.State.ParryCooldown = false
    Config.State.lastParryPressAt = 0
    Config.State.lastManualParryInputAt = 0
end
local _parryHookRetryNext = 0
Config.Connections.ParryResultRetry = Config.FakeConnection(Config.HeartbeatTasks, "ParryResultRetry", function()
    if Config.Connections.ParryResultHook or Config.State.unloaded then return end
    local now = fast_tick()
    if now < _parryHookRetryNext then return end
    _parryHookRetryNext = now + 5
    task.spawn(function()
        pcall(function() Fn.SetupParryResultHook() end)
    end)
end)
function Fn.isFacingTarget(targetChar)
    if not Config.Auto.RequireFacing then return true end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myRoot    = myChar:FindFirstChild("HumanoidRootPart")
    local enemyRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not enemyRoot then return false end
    local enemyForward  = enemyRoot.CFrame.LookVector
    local directionToMe = (myRoot.Position - enemyRoot.Position).Unit
    local dot = enemyForward:Dot(directionToMe)
    if Config.Auto.FaceSensitivity <= -1 then return true end
    return dot >= Config.Auto.FaceSensitivity
end
local _animIdCache = {}
function Fn.hookKiller(char)
    if Config.hookedKillers[char] then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    local conn = animator.AnimationPlayed:Connect(function(track)
        if not Config.Auto.Parry then return end
        local anim = track.Animation
        if not anim then return end
        local rawId = anim.AnimationId
        local fullId = _animIdCache[rawId]
        if fullId == nil then
            local id = rawId:match("%d+")
            if id then
                fullId = "rbxassetid://" .. id
                _animIdCache[rawId] = fullId
            else
                fullId = false
                _animIdCache[rawId] = false
            end
        end
        local isAttackAnim = false
        if fullId and Config.KillerAnims[fullId] then
            isAttackAnim = true
        end
        if isAttackAnim then
            if Fn.isInParryRange(char) and Fn.isFacingTarget(char) then
                Fn.doParry()
                return
            end
        end
    end)
    local ancestryConn
    ancestryConn = char.AncestryChanged:Connect(function(_, parent)
        if parent then return end
        pcall(function() if conn then conn:Disconnect() end end)
        pcall(function() if ancestryConn then ancestryConn:Disconnect() end end)
        Config.hookedKillers[char] = nil
    end)
    Config.hookedKillers[char] = { conn = conn, ancestry = ancestryConn }
end
function Fn.stopParryHook()
    if Config.State._parryPlayerAddedConn then
        Fn.safeCall("StopParryHook PlayerAdded", function()
            Config.State._parryPlayerAddedConn:Disconnect()
        end)
        Config.State._parryPlayerAddedConn = nil
    end
    for p, conn in pairs(Config.State._parryCharConns) do
        if conn then
            Fn.safeCall("StopParryHook CharacterAdded", function()
                conn:Disconnect()
            end)
        end
        Config.State._parryCharConns[p] = nil
    end
    for char, entry in pairs(Config.hookedKillers) do
        if type(entry) == "table" then
            if entry.conn then
                Fn.safeCall("StopParryHook AnimationPlayed", function() entry.conn:Disconnect() end)
            end
            if entry.ancestry then
                Fn.safeCall("StopParryHook Ancestry", function() entry.ancestry:Disconnect() end)
            end
        elseif typeof(entry) == "RBXScriptConnection" then
            Fn.safeCall("StopParryHook AnimationPlayed", function() entry:Disconnect() end)
        end
        Config.hookedKillers[char] = nil
    end
end
function Fn.CreateFakeParryButton()
    if Config.State.FakeParryButton then Config.State.FakeParryButton:Destroy() end
    local gui, btn, stroke = Fn.createGameButton({
        Name       = "FakeParryGui",
        ButtonType = "ImageButton",
        Size       = UDim2.new(0, 50, 0, 50),
        Position   = UDim2.new(0.65, 0, 0.60, 0),
        Image      = "rbxassetid://73705354917255",
        OnClick = function()
            if Config.FakeParry.Enabled then Fn.PlayFakeParry() end
        end,
    })
    Config.State.FakeParryButton = gui
end
function Fn.RemoveFakeParryButton()
    if Config.State.FakeParryButton then Config.State.FakeParryButton:Destroy(); Config.State.FakeParryButton = nil end
end
function Fn.pressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end
function Fn.TriggerMobileButton()
    local b = Fn.getGuiByPath(Config.ActionPath)
    if b and b:IsA("GuiObject") then
        local p, s = b.AbsolutePosition, b.AbsoluteSize
        local i = game:GetService("GuiService"):GetGuiInset()
        local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
        Fn.safeCall("MobileAction", function()
            VirtualInputManager:SendTouchEvent(Config.TouchID, 0, cx, cy)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(Config.TouchID, 2, cx, cy)
        end)
    end
end
local function handleSkillCheckPrompt(prompt)
    local check = prompt:WaitForChild("Check", 5)
    if not check then
        local t0 = fast_tick()
        while not check and prompt.Parent and fast_tick() - t0 < 5 do
            task.wait(0.1)
            check = prompt:FindFirstChild("Check")
        end
        if not check then return end
    end
    local function onVisibilityChanged()
        if check.Visible and check.Parent and Config.Auto.SkillCheck then
            if Config.Connections.SkillHeartbeat and Config.State._skillHeartbeatCheck ~= check then
                Config.Connections.SkillHeartbeat:Disconnect()
                Config.Connections.SkillHeartbeat = nil
            end
            if not Config.Connections.SkillHeartbeat then
                Config.State._skillHeartbeatCheck = check
                Config.State._skillHeartbeatLine = check:FindFirstChild("Line")
                Config.State._skillHeartbeatGoal = check:FindFirstChild("Goal")
                Config.Connections.SkillHeartbeat = Config.FakeConnection(Config.RenderSteppedTasks, "SkillHeartbeat", function()
                    if Config.State.busy or not Config.Auto.SkillCheck then return end
                    if not check.Parent then
                        if Config.Connections.SkillHeartbeat then
                            Config.Connections.SkillHeartbeat:Disconnect()
                            Config.Connections.SkillHeartbeat = nil
                        end
                        Config.State._skillHeartbeatLine = nil
                        Config.State._skillHeartbeatGoal = nil
                        return
                    end
                    if not check.Visible then return end
                    local line = Config.State._skillHeartbeatLine
                    local goal = Config.State._skillHeartbeatGoal
                    if not (line and line.Parent) then
                        line = check:FindFirstChild("Line")
                        Config.State._skillHeartbeatLine = line
                    end
                    if not (goal and goal.Parent) then
                        goal = check:FindFirstChild("Goal")
                        Config.State._skillHeartbeatGoal = goal
                    end
                    if not line or not goal then return end
                    if Config.Auto.SkillCheckMode == "Instant" then
                        line.Rotation = goal.Rotation + 109
                        Config.State.busy = true
                        task.spawn(function()
                            if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                            task.wait(0.2)
                            Config.State.busy = false
                        end)
                    elseif Config.Auto.SkillCheckMode == "normal" then
                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
                        local startRange = (gr + 117) % 360
                        local endRange   = (gr + 130) % 360
                        local success = (startRange > endRange and (lr >= startRange or lr <= endRange))
                                     or (lr >= startRange and lr <= endRange)
                        if success then
                            Config.State.busy = true
                            task.spawn(function()
                                if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                                task.wait(0.05)
                                Config.State.busy = false
                            end)
                        end
                    else
                        local lr = line.Rotation % 360
                        local gr = goal.Rotation % 360
                        local startRange = (gr + 102) % 360
                        local endRange   = (gr + 116) % 360
                        local success = (startRange > endRange and (lr >= startRange or lr <= endRange))
                                     or (lr >= startRange and lr <= endRange)
                        if success then
                            Config.State.busy = true
                            task.spawn(function()
                                if UserInputService.TouchEnabled then Fn.TriggerMobileButton() else Fn.pressSpace() end
                                task.wait(0.05)
                                Config.State.busy = false
                            end)
                        end
                    end
                end)
            end
        else
            if Config.Connections.SkillHeartbeat then
                Config.Connections.SkillHeartbeat:Disconnect()
                Config.Connections.SkillHeartbeat = nil
            end
        end
    end
    check:GetPropertyChangedSignal("Visible"):Connect(onVisibilityChanged)
    onVisibilityChanged()
end
function Fn.startSkillCheck()
    if Config.State._skillCheckConn then return end
    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if prompt then task.spawn(handleSkillCheckPrompt, prompt) end
    Config.State._skillCheckConn = PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "SkillCheckPromptGui" then
            task.spawn(handleSkillCheckPrompt, child)
        end
    end)
end
function Fn.stopSkillCheck()
    Config.Auto.SkillCheck = false
    if Config.Connections.SkillHeartbeat then
        Config.Connections.SkillHeartbeat:Disconnect()
        Config.Connections.SkillHeartbeat = nil
    end
    Config.State._skillHeartbeatCheck = nil
    if Config.State._skillCheckConn then
        Fn._destroyConn("SkillCheckConn", Config.State._skillCheckConn)
        Config.State._skillCheckConn = nil
    end
end
local STALK_KILLER_IDS = {
    ["Stalker"] = true,
}
function Fn.getStalkRemote()
    local S = Config.Killer.Stalk
    local now = fast_tick()
    if S._remote and S._remote.Parent and (now - S._remoteAt) < 5 then
        return S._remote
    end
    S._remoteAt = now
    local killers = Remotes:FindFirstChild("Killers", true)
    local stalker = killers and killers:FindFirstChild("Stalker", true)
    local evt     = stalker and stalker:FindFirstChild("StartStalking")
    S._remote = (evt and evt:IsA("RemoteEvent")) and evt or nil
    return S._remote
end
function Fn.isStalkCapable()
    if not Fn.isKillerTeam() then return false end
    local S = Config.Killer.Stalk
    local now = fast_tick()
    if (now - S._killerAt) >= 3 then
        S._killerAt = now
        local name = Fn.GetKillerName(LocalPlayer, LocalPlayer.Character)
        S._killerOk = (name ~= nil and STALK_KILLER_IDS[name] == true)
    end
    return S._killerOk
end
function Fn.isStalkTargetValid(plr, root)
    if plr == nil or plr.Parent == nil then return false end
    if plr == LocalPlayer then return false end
    if not (plr.Team and plr.Team.Name == "Survivors") then return false end
    local char = plr.Character
    if not char or not char.Parent then return false end
    if Fn.checkDowned(char) then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= Config.Killer.Stalk.MinHealth then return false end
    if not root then return false end
    if (hrp.Position - root.Position).Magnitude > Config.Killer.Stalk.StalkRange then return false end
    if Config.Killer.Stalk.RequireLineOfSight and not Fn.isVisible(hrp) then return false end
    return true
end
function Fn.startAutoStalk()
    if Config.Connections.Stalk then return end
    local S = Config.Killer.Stalk
    S.Target, S._remote, S._remoteAt, S._killerAt = nil, nil, 0, 0
    Config.Connections.Stalk = Config.FakeConnection(Config.HeartbeatTasks, "Stalk", function()
        if not S.Enabled then return end
        if not Fn.isStalkCapable() then
            if S.Target then S.Target = nil end
            return
        end
        local now = fast_tick()
        if now - Config.State.LastStalkFire < S.Cooldown then return end
        local root = Fn.getRoot()
        if not root then return end
        if not Fn.isStalkTargetValid(S.Target, root) then
            S.Target = Fn.getClosestSurvivorForStalk()
        end
        local target = S.Target
        if not target then return end
        local stalkEvent = Fn.getStalkRemote()
        if not stalkEvent then return end
        local ok = Fn.safeCall("AutoStalk", function()
            stalkEvent:FireServer(target)
        end)
        if ok then
            Config.State.LastStalkFire = now
        else
            Config.State.LastStalkFire = now - S.Cooldown + 0.5
            if not stalkEvent.Parent then S._remote = nil end
        end
    end)
end
function Fn.stopAutoStalk()
    if Config.Connections.Stalk then
        Config.Connections.Stalk:Disconnect()
        Config.Connections.Stalk = nil
    end
    Config.Killer.Stalk.Target = nil
end
Config.Threads.Flee = task.spawn(function()
    while not Config.State.unloaded do
        task.wait(0.2)
        if not Config.Auto.Flee.Enabled then continue end
        local root = Fn.getRoot()
        if not root then continue end
        local killerRoot, distance = Fn.GetNearestKiller()
        if killerRoot and distance <= Config.Auto.Flee.DetectDistance
        and fast_tick() - Config.State.LastFlee > Config.Auto.Flee.Cooldown then
            local point = Fn.GetFarthestGeneratorPoint(killerRoot)
            if point then
                Config.State.LastFlee = fast_tick()
                root.CFrame = point.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end)
function Fn.teleportToFinishLine()
    local root = Fn.getRoot()
    if not root then return end
    local found = Config.State._finishLineCache
    if not found or not found.Parent then
        Config.State._finishLineCache = nil
        found = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if string.lower(obj.Name) == "fininshline" and obj:IsA("BasePart") then
                found = obj
                Config.State._finishLineCache = obj
                break
            end
        end
    end
    if not found then warn("fininshline not found"); return end
    root.CFrame = found.CFrame + Vector3.new(0, 5, 0)
end
function Fn.UpdateThirdPerson()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    local shouldBeActive = Config.Killer.ThirdPerson and isKiller
    if shouldBeActive then
        if not Config.Killer.ThirdPersonWasActive then
            Config.Killer.OriginalCameraType = cam.CameraType
        end
        if cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
        end
        local char = LocalPlayer.Character
        local hum = Config.Killer._cachedHum
        if not (hum and hum.Parent and hum.Parent == char) then
            hum = char and char:FindFirstChildOfClass("Humanoid")
            Config.Killer._cachedHum = hum
        end
        if hum and hum.CameraOffset ~= Config.Killer._ThirdPersonOffset then
            hum.CameraOffset = Config.Killer._ThirdPersonOffset
        end
        Config.Killer.ThirdPersonWasActive = true
    elseif Config.Killer.ThirdPersonWasActive then
        if Config.Killer.OriginalCameraType then
            cam.CameraType = Config.Killer.OriginalCameraType
            Config.Killer.OriginalCameraType = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.CameraOffset ~= _V3_UP_0 then
            hum.CameraOffset = _V3_UP_0
        end
        Config.Killer._cachedHum = nil
        Config.Killer.ThirdPersonWasActive = false
    end
end
function Fn.updateParryCircle()
    local root = Fn.getRoot()
    if not Config.Auto.ParryVisual.Enabled
    or not Config.Auto.Parry
    or not root then
        if Config.State.ParryCircle then
            Config.State.ParryCircle:Destroy()
            Config.State.ParryCircle = nil
            Config.State.ParryCircleBeams = nil
            Config.State.ParryCircleAtts  = nil
            Config.State.ParryCircleCache = nil
        end
        if Config.State.ParryCircleFill then
            Config.State.ParryCircleFill:Destroy()
            Config.State.ParryCircleFill = nil
        end
        return
    end
    if Options and Options.ParryRangeStrokeColor and type(Options.ParryRangeStrokeColor.Transparency) == "number" then
        Config.Auto.ParryVisual.StrokeTransparency = Options.ParryRangeStrokeColor.Transparency
    end
    if Options and Options.ParryRangeColor and type(Options.ParryRangeColor.Transparency) == "number" then
        Config.Auto.ParryVisual.Transparency = Options.ParryRangeColor.Transparency
    end
    local vis          = Config.Auto.ParryVisual
    local radius       = Config.Auto.ParryDistance
    local thickness    = math.max(0.05, vis.StrokeThickness or 0.35)
    local strokeColor  = vis.StrokeColor or Color3.fromRGB(51, 124, 255)
    local strokeTransp = math.clamp(vis.StrokeTransparency or 0.1, 0, 1)
    local segments     = math.max(8, math.floor(vis.StrokeSegments or 72))
    local lightEmiss   = math.clamp(vis.StrokeLightEmission or 1, 0, 1)
    local lightInfl    = math.clamp(vis.StrokeLightInfluence or 0, 0, 1)
    local yOffset      = root.Size.Y / 2 + 1.5
    local ringCFrame   = CFrame.new(root.Position - Vector3.new(0, yOffset, 0))
    if not Config.State.ParryCircleFill then
        local fill = Instance.new("Part")
        fill.Shape       = Enum.PartType.Cylinder
        fill.Anchored    = true
        fill.CanCollide  = false
        fill.CanQuery    = false
        fill.CanTouch    = false
        fill.Material    = Enum.Material.Neon
        fill.Name        = "ParryRangeCircleFill"
        fill.Parent      = workspace
        Config.State.ParryCircleFill = fill
    end
    local size = Config.Auto.ParryDistance * 2
    Config.State.ParryCircleFill.Size        = Vector3.new(0.2, size, size)
    Config.State.ParryCircleFill.CFrame      = ringCFrame * CFrame.Angles(0, 0, math.rad(90))
    Config.State.ParryCircleFill.Color        = Config.Auto.ParryVisual.Color
    Config.State.ParryCircleFill.Transparency = Config.Auto.ParryVisual.Transparency
    if not Config.State.ParryCircle then
        local holder = Instance.new("Part")
        holder.Anchored       = true
        holder.CanCollide     = false
        holder.CanQuery       = false
        holder.CanTouch       = false
        holder.Transparency   = 1
        holder.Size           = Vector3.new(0.2, 0.2, 0.2)
        holder.Material       = Enum.Material.Plastic
        holder.Name           = "ParryRangeCircle"
        holder.Parent         = workspace
        local beams = table.create(segments)
        local atts  = table.create(segments)
        for i = 1, segments do
            local ang = math.rad((i - 1) * (360 / segments))
            local att = Instance.new("Attachment")
            att.Name     = "RingAtt" .. i
            att.Position = Vector3.new(math.cos(ang) * radius, 0, math.sin(ang) * radius)
            att.Parent   = holder
            atts[i] = att
        end
        local cs  = ColorSequence.new(strokeColor)
        local ns  = NumberSequence.new(strokeTransp)
        for i = 1, segments do
            local nextI = (i % segments) + 1
            local beam = Instance.new("Beam")
            beam.Name              = "RingBeam" .. i
            beam.Attachment0       = atts[i]
            beam.Attachment1       = atts[nextI]
            beam.FaceCamera        = false
            beam.Width0            = thickness
            beam.Width1            = thickness
            beam.Color             = cs
            beam.Transparency      = ns
            beam.LightEmission     = lightEmiss
            beam.LightInfluence    = lightInfl
            beam.Parent            = holder
            beams[i] = beam
        end
        Config.State.ParryCircle      = holder
        Config.State.ParryCircleBeams = beams
        Config.State.ParryCircleAtts  = atts
        Config.State.ParryCircleCache = {
            color = strokeColor, transp = strokeTransp, thickness = thickness,
            lightEmiss = lightEmiss, lightInfl = lightInfl, radius = radius,
            segments = segments,
        }
    end
    Config.State.ParryCircle.CFrame = ringCFrame
    local cache = Config.State.ParryCircleCache
    if cache then
        if cache.color ~= strokeColor
        or cache.transp ~= strokeTransp
        or cache.thickness ~= thickness
        or cache.lightEmiss ~= lightEmiss
        or cache.lightInfl ~= lightInfl then
            local cs = ColorSequence.new(strokeColor)
            local ns = NumberSequence.new(strokeTransp)
            local beams = Config.State.ParryCircleBeams
            for i = 1, #beams do
                local b = beams[i]
                b.Color         = cs
                b.Transparency  = ns
                b.Width0        = thickness
                b.Width1        = thickness
                b.LightEmission = lightEmiss
                b.LightInfluence= lightInfl
            end
            cache.color      = strokeColor
            cache.transp     = strokeTransp
            cache.thickness  = thickness
            cache.lightEmiss = lightEmiss
            cache.lightInfl  = lightInfl
        end
        if cache.radius ~= radius or cache.segments ~= segments then
            local atts = Config.State.ParryCircleAtts
            for i = 1, #atts do
                local ang = math.rad((i - 1) * (360 / segments))
                atts[i].Position = Vector3.new(math.cos(ang) * radius, 0, math.sin(ang) * radius)
            end
            cache.radius   = radius
            cache.segments = segments
        end
    end
end
Config.Connections.CharacterInit = LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    if Config.Connections.CharWalkingConn then
        Fn._destroyConn("CharWalking", Config.Connections.CharWalkingConn)
        Config.Connections.CharWalkingConn = nil
    end
    Config.Connections.CharWalkingConn = hum.Walking:Connect(function(speed)
        if speed > 1 then Fn.stopEmote() end
    end)
    task.delay(0.5, function()
        if Config.State.ParryCircle then Config.State.ParryCircle:Destroy(); Config.State.ParryCircle = nil; Config.State.ParryCircleBeams = nil; Config.State.ParryCircleAtts = nil; Config.State.ParryCircleCache = nil end
        if Config.State.ParryCircleFill then Config.State.ParryCircleFill:Destroy(); Config.State.ParryCircleFill = nil end
        if Config.State.ParryCooldownThread then
            pcall(function() task.cancel(Config.State.ParryCooldownThread) end)
            Config.State.ParryCooldownThread = nil
        end
        Config.State.ParryCooldown = false
        Config.State.lastParry    = 0
        Config.State.lastParryPressAt = 0
        Config.State.lastManualParryInputAt = 0
        Fn.parryVisual_reset()
        Fn.applyMaxZoom()
        Fn.applyOptimization(true)
        if Config.Movement.Vault.Enabled then Fn.applyVault() end
        if Config.Movement.FakeFastVault.Enabled then Fn.applyFakeFastVault() end
        if Config.Movement.AntiSlowVault.Enabled then Fn.applyAntiSlowVault() end
        if Config.Movement.SkillCheckSpeed.Enabled then Fn.applySkillCheckSpeed() end
    end)
    task.delay(0.8, function()
        Fn.applySpeedBoost()
    end)
    task.delay(1, function()
        Config.GunAim.Target = nil
        Config.GunAim.Holding = false
        Config.AttackAim.Holding = false
        Fn.applyCameraFOV()
        if Config.Moonwalk.ShowButton then Fn.createMoonwalkButton() end
        if Config.GunAim.ShowTargetIcon then Fn.createGunAimTargetIcon() end
        if Config.ToFAimV1.ShowTargetIcon then Fn.createToFAimV1TargetIcon() end
        if Config.FakeParry.Enabled and UserInputService.TouchEnabled then Fn.CreateFakeParryButton() end
        if Config.EmoteButton.Show then Fn.createEmoteButton() end
        if Config.GenBypass.Enabled and UserInputService.TouchEnabled then
            GB_CreateButton()
            GB_UpdateButton()
        end
        Fn.reapplyAllEnabled()
    end)
end)
function Fn.applyVault()
    if Config.Connections.Vault then
        Config.Connections.Vault:Disconnect()
        Config.Connections.Vault = nil
    end
    if not Config.Movement.Vault.Enabled then return end
    local cfg = Config.Movement.Vault
    cfg.HeartbeatRate = 0.15
    cfg.LastApply = 0
    Config.Connections.Vault = Config.FakeConnection(Config.HeartbeatTasks, "Vault", function()
        if not cfg.Enabled then return end
        local now = fast_tick()
        if now - cfg.LastApply < cfg.HeartbeatRate then return end
        cfg.LastApply = now
        local char = LocalPlayer.Character
        if not char or not char.Parent then return end
        local target      = cfg.Speed
        local hasVaultSpeed = char:GetAttribute("vaultspeed") ~= nil
        local hasSwift      = char:GetAttribute("swift") ~= nil
        Fn.safeCall("VaultSpeed Apply", function()
            if hasSwift and not hasVaultSpeed then
                if char:GetAttribute("swift") ~= target then char:SetAttribute("swift", target) end
            elseif hasVaultSpeed and not hasSwift then
                if char:GetAttribute("vaultspeed") ~= target then char:SetAttribute("vaultspeed", target) end
            else
                if char:GetAttribute("vaultspeed") ~= target then char:SetAttribute("vaultspeed", target) end
                if char:GetAttribute("swift") ~= target then char:SetAttribute("swift", target) end
            end
        end)
    end)
end
function Fn.disableVault()
    if Config.Connections.Vault then
        Config.Connections.Vault:Disconnect()
        Config.Connections.Vault = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("VaultSpeed Disable", function()
            if char:GetAttribute("vaultspeed") ~= nil then
                char:SetAttribute("vaultspeed", 1)
            end
            if char:GetAttribute("swift") ~= nil then
                char:SetAttribute("swift", 1)
            end
        end)
    end
end
function Fn.applyFakeFastVault()
    if Config.Connections.FakeFastVaultChar then
        Config.Connections.FakeFastVaultChar:Disconnect()
        Config.Connections.FakeFastVaultChar = nil
    end
    if Config.Connections.FakeFastVault then
        Config.Connections.FakeFastVault:Disconnect()
        Config.Connections.FakeFastVault = nil
    end
    if not Config.Movement.FakeFastVault.Enabled then return end
    local WALK_ID   = Config.FakeFastVault.WALK_VAULT_ID
    local RUN_ID    = Config.FakeFastVault.RUN_VAULT_ID
    local SPEED     = Config.FakeFastVault.SPEED
    local RESET_DLY = Config.FakeFastVault.ResetDelay or 2
    local function normalizeAnimId(rawId)
        if type(rawId) ~= "string" then return nil end
        if rawId:sub(1, 13) == "rbxassetid://" then return rawId end
        local id = rawId:match("%d+")
        if id then return "rbxassetid://" .. id end
        return rawId
    end
    local function swapToRunningVault(animator, char, track)
        Fn.safeCall("FakeFastVault Swap", function()
            if char and char.Parent and char:GetAttribute("vaultspeed") ~= SPEED then
                char:SetAttribute("vaultspeed", SPEED)
            end
            pcall(function() track:Stop(0) end)
            local runAnim = Instance.new("Animation")
            runAnim.AnimationId = RUN_ID
            local runTrack = animator:LoadAnimation(runAnim)
            runTrack:Play()
            task.delay(RESET_DLY, function()
                if char and char.Parent
                   and Config.Movement.FakeFastVault.Enabled
                   and char:GetAttribute("vaultspeed") == SPEED then
                    char:SetAttribute("vaultspeed", 1)
                end
            end)
        end)
    end
    local function hookAnimator(animator, char)
        if not animator or not char or not char.Parent then return end
        if Config.Connections.FakeFastVault then
            Config.Connections.FakeFastVault:Disconnect()
        end
        Config.Connections.FakeFastVault = animator.AnimationPlayed:Connect(function(track)
            if not Config.Movement.FakeFastVault.Enabled then return end
            local anim = track and track.Animation
            if not anim then return end
            local fullId = normalizeAnimId(anim.AnimationId)
            if fullId ~= WALK_ID then return end
            swapToRunningVault(animator, char, track)
        end)
    end
    local function hookCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            task.spawn(function()
                local h = char:WaitForChild("Humanoid", 5)
                if h then hookCharacter(char) end
            end)
            return
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            task.spawn(function()
                local h = char:WaitForChild("Humanoid", 5)
                if h then
                    local an = h:FindFirstChildOfClass("Animator")
                    if an then hookAnimator(an, char) end
                end
            end)
            return
        end
        hookAnimator(animator, char)
    end
    local char = LocalPlayer.Character
    if char then hookCharacter(char) end
    Config.Connections.FakeFastVaultChar = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        hookCharacter(newChar)
    end)
end
function Fn.disableFakeFastVault()
    if Config.Connections.FakeFastVault then
        Config.Connections.FakeFastVault:Disconnect()
        Config.Connections.FakeFastVault = nil
    end
    if Config.Connections.FakeFastVaultChar then
        Config.Connections.FakeFastVaultChar:Disconnect()
        Config.Connections.FakeFastVaultChar = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("FakeFastVault Reset", function()
            if char:GetAttribute("vaultspeed") == Config.FakeFastVault.SPEED then
                char:SetAttribute("vaultspeed", 1)
            end
        end)
    end
end
function Fn.applyAntiSlowVault()
    local cfg = Config.Movement.AntiSlowVault
    Fn.safeCall("AntiSlowVault TagClean", function()
        if Config.Connections.AntiSlowVaultTag then
            Config.Connections.AntiSlowVaultTag:Disconnect()
            Config.Connections.AntiSlowVaultTag = nil
        end
        for _, v in ipairs(ASV_COLLECTION:GetTagged("SlowVault")) do
            pcall(function() ASV_COLLECTION:RemoveTag(v, "SlowVault") end)
        end
        Config.Connections.AntiSlowVaultTag = ASV_COLLECTION:GetInstanceAddedSignal("SlowVault"):Connect(function(instance)
            pcall(function()
                if Config.Movement.AntiSlowVault.Enabled then
                    ASV_COLLECTION:RemoveTag(instance, "SlowVault")
                end
            end)
        end)
    end)
    task.spawn(function()
        if ASV_InstallModuleHook() then return end
        local attempts = 0
        while Config.Movement.AntiSlowVault.Enabled
              and not Config.Movement.AntiSlowVault.ModuleHooked
              and attempts < ASV_MAX_RETRIES do
            attempts = attempts + 1
            task.wait(1)
            if ASV_InstallModuleHook() then break end
        end
        if Config.Movement.AntiSlowVault.Enabled and not Config.Movement.AntiSlowVault.ModuleHooked then
            warn("[Anti Slow Vault] Gagal load SurvivorAnimationsController setelah " .. ASV_MAX_RETRIES .. " percobaan")
        end
    end)
    ASV_Notify("Anti Slow Vault: ON")
end
function Fn.applySkillCheckSpeed()
    if Config.Connections.SkillCheckSpeed then
        Config.Connections.SkillCheckSpeed:Disconnect()
        Config.Connections.SkillCheckSpeed = nil
    end
    if not Config.Movement.SkillCheckSpeed.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local function updateSkillCheck()
        if not Config.Movement.SkillCheckSpeed.Enabled then return end
        local target = Config.Movement.SkillCheckSpeed.Speed
        if char:GetAttribute("skillcheckspeed") ~= target then
            Fn.safeCall("SkillCheckSpeed Apply", function()
                char:SetAttribute("skillcheckspeed", target)
            end)
        end
    end
    updateSkillCheck()
    Config.Connections.SkillCheckSpeed = char:GetAttributeChangedSignal("skillcheckspeed"):Connect(updateSkillCheck)
end
function Fn.disableSkillCheckSpeed()
    if Config.Connections.SkillCheckSpeed then
        Config.Connections.SkillCheckSpeed:Disconnect()
        Config.Connections.SkillCheckSpeed = nil
    end
    local char = LocalPlayer.Character
    if char then
        Fn.safeCall("SkillCheckSpeed Disable", function()
            char:SetAttribute("skillcheckspeed", 1)
        end)
    end
end
function Fn.HandleAutoPallet()
    if not Config.Auto.PalletDrop then return end
    local plr = Players.LocalPlayer
    if not (plr.Team and plr.Team.Name == "Survivors") then return end
    local now = fast_tick()
    if now - Config.Timers.lastPalletScan < 0.2 then return end
    Config.Timers.lastPalletScan = now
    if now - Config.Timers.lastPalletDrop < 2.5 then return end
    local root = Fn.getRoot()
    if not root then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local killerRoot, killerDist = Fn.GetNearestKiller()
    if not killerRoot or killerDist > Config.Auto.PalletDropDist then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local palletFold = remotes and remotes:FindFirstChild("Pallet")
    local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
    if not dropEvent then return end
    local bestPallet = nil
    local bestDist = 8
    local function findPalletPointSlide(model)
        local slide = model:FindFirstChild("PalletPointSlide")
        if slide then return slide end
        for _, child in ipairs(model:GetDescendants()) do
            if child.Name == "PalletPointSlide" then return child end
        end
        return model:FindFirstChild("PalletPoint")
    end
    for pal, _ in pairs(Config.ESPCache.Pallets) do
        if not pal or Config.State.UsedPallets[pal] then continue end
        local refPart = pal:FindFirstChild("PalletPoint") or pal:FindFirstChild("PalletPointSlide")
        if not refPart then continue end
        local ok, pos = pcall(function() return refPart.Position end)
        if not ok or not pos then continue end
        local d = (root.Position - pos).Magnitude
        if d < bestDist then
            bestDist = d
            bestPallet = pal
        end
    end
    if bestPallet then
        local fireTarget = findPalletPointSlide(bestPallet)
        if fireTarget then
            Fn.safeCall("AutoPallet", function() dropEvent:FireServer(fireTarget) end)
            Config.State.UsedPallets[bestPallet] = true
            Config.Timers.lastPalletDrop = now
        end
    end
end
do
local CollectionService = game:GetService("CollectionService")
local function gbResolvePerfRemote()
    local perksFolder = Remotes:FindFirstChild("Perks")
    return perksFolder and perksFolder:FindFirstChild("perfectionistplanning")
end
local function gbResolveRepairAnimRemote()
    local generatorFolder = Remotes:FindFirstChild("Generator")
    return generatorFolder and generatorFolder:FindFirstChild("RepairAnim")
end
local gbListenerAttached = false
local function gbAttachListener()
    if gbListenerAttached or Config.State.unloaded then return end
    local RepairAnimRemote = gbResolveRepairAnimRemote()
    if not RepairAnimRemote then return end
    gbListenerAttached = true
    Config.Connections.GenBoostListener = RepairAnimRemote.OnClientEvent:Connect(function(plr, isRepairing, targetPart)
        if not Config.Auto.GenBoost.Enabled then return end
        if typeof(plr) == "Instance" and plr:IsA("Player") and plr ~= LocalPlayer then return end
        if isRepairing and targetPart and targetPart.Parent then
            local PerfPlanningRemote = gbResolvePerfRemote()
            if not PerfPlanningRemote then return end
            Fn.safeCall("GenBoost Apply", function()
                PerfPlanningRemote:FireServer("applyBoost", "fast")
            end)
            if fast_tick() > Config.Auto.GenBoost.LastBroadcast then
                Config.Auto.GenBoost.LastBroadcast = fast_tick() + 55
                local allGens = {}
                for _, gen in ipairs(CollectionService:GetTagged("Generator")) do
                    if gen:IsDescendantOf(workspace) then
                        local genModel = (gen:IsA("Model") and gen) or gen.Parent
                        table.insert(allGens, genModel)
                    end
                end
                Fn.safeCall("GenBoost Broadcast", function()
                    PerfPlanningRemote:FireServer("broadcast", allGens)
                end)
            end
        else
            local PerfPlanningRemote = gbResolvePerfRemote()
            if PerfPlanningRemote then
                Fn.safeCall("GenBoost Clear", function()
                    PerfPlanningRemote:FireServer("clearBoost")
                end)
            end
        end
    end)
end
gbAttachListener()
local gbRetryNext = 0
Config.Connections.GenBoostRetry = Config.FakeConnection(Config.HeartbeatTasks, "GenBoostRetry", function()
    if gbListenerAttached or Config.State.unloaded then return end
    local now = fast_tick()
    if now < gbRetryNext then return end
    gbRetryNext = now + 5
    gbAttachListener()
end)
Config.Connections.CharacterRemove = LocalPlayer.CharacterRemoving:Connect(function()
    Fn.safeCall("AutoCrouch Reset", function() TriggerCrouchStop() end)
    if Config.Connections.CharWalkingConn then
        Fn._destroyConn("CharWalking", Config.Connections.CharWalkingConn)
        Config.Connections.CharWalkingConn = nil
    end
    if Config.Auto.GenBoost.Enabled then
        local PerfPlanningRemote = gbResolvePerfRemote()
        if PerfPlanningRemote then
            Fn.safeCall("GenBoost Clear", function() PerfPlanningRemote:FireServer("clearBoost") end)
        end
    end
end)
end
Config.Connections.MainHeartbeat = Config.FakeConnection(Config.HeartbeatTasks, "MainHeartbeat", function()
    local now = fast_tick()
    Fn.HandleAutoPallet()
    if now - Config.Timers.lastVaultBlock >= 1.5 then
        Config.Timers.lastVaultBlock = now
        Fn.HandleBlockVaults()
    end
    if now - Config.Timers.lastGodMode >= 0.1 then
        Config.Timers.lastGodMode = now
        Fn.applyGodMode()
    end
    if now - Config.Timers.lastKillerUpdate >= 0.05 then
        Config.Timers.lastKillerUpdate = now
        if Config.Killer.KillAll then
            local root = Fn.getRoot()
            if root then
                local needRetarget = false
                if not Config.State.KillerTarget then
                    needRetarget = true
                else
                    local targetPlayer = Players:GetPlayerFromCharacter(Config.State.KillerTarget)
                    if not (targetPlayer and targetPlayer.Team and targetPlayer.Team.Name == "Survivors") then
                        needRetarget = true
                    elseif Fn.checkDowned(Config.State.KillerTarget) then
                        needRetarget = true
                    end
                end
                if needRetarget then
                    Config.State.KillerTarget = Fn.GetNearestAliveSurvivor()
                end
                local target = Config.State.KillerTarget
                if target and not Fn.checkDowned(target) then
                    local targetHRP = target:FindFirstChild("HumanoidRootPart")
                    local targetHum = target:FindFirstChildOfClass("Humanoid")
                    if targetHRP and targetHum and targetHum.Health > 0 then
                        local velocity = targetHRP.AssemblyLinearVelocity
                        local predict  = velocity * 0.15
                        local targetPos = targetHRP.Position + predict
                        local behind    = targetHRP.CFrame.LookVector * -3
                        root.CFrame = CFrame.new(targetPos + behind, targetPos)
                        Fn.safeCall("KillAll Attack", function() AttackEvent:FireServer(false) end)
                    end
                end
            end
        end
    end
    if now - Config.Timers.lastAttrEnforce >= 0.5 then
        Config.Timers.lastAttrEnforce = now
        Fn.enforceAttributes()
    end
    if now - Config.Timers.lastStunCheck >= 0.2 then
        Config.Timers.lastStunCheck = now
        Fn.UpdateStunNotification()
    end
    if now - Config.Timers.lastSmoothCam >= 0.5 then
        Config.Timers.lastSmoothCam = now
        Fn.safeCall("SmoothCam", Fn.enforceSmoothCamera)
    end
end)
function Fn.enforceAttributes()
    local char = LocalPlayer.Character
    if not char then return end
    if Config.Killer.BreakSpeedEnabled then
        if char:GetAttribute("breakspeed") ~= Config.Killer.BreakSpeed then
            char:SetAttribute("breakspeed", Config.Killer.BreakSpeed)
        end
    else
        if char:GetAttribute("breakspeed") ~= nil then
            char:SetAttribute("breakspeed", nil)
        end
    end
end
local GB_DONE_CHECKS = {
}
local function gbIsGenDone(genModel)
    for _, c in ipairs(GB_DONE_CHECKS) do
        local v = genModel:GetAttribute(c.name)
        if v ~= nil and v == c.doneValue then return true end
    end
    return false
end
function GB_GetAllGenerators()
    local now = fast_tick()
    if now - Config.GenBypass.CacheTimer < 5 then return Config.GenBypass.Cache end
    Config.GenBypass.Cache = {}
    Config.GenBypass.CacheTimer = now
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return Config.GenBypass.Cache end
    pcall(function()
        for _, v in pairs(mapFolder:GetDescendants()) do
            if not v:IsA("Model") then continue end
            if v.Name ~= "Generator" then continue end
            local isReal = v:GetAttribute("RepairProgress") ~= nil
                or v:GetAttribute("kickcount") ~= nil
                or v:GetAttribute("ProgressRepair") ~= nil
            if isReal and not gbIsGenDone(v) then table.insert(Config.GenBypass.Cache, v) end
        end
    end)
    return Config.GenBypass.Cache
end
function GB_GetPoints(genModel)
    local points = {}
    pcall(function()
        for _, obj in pairs(genModel:GetChildren()) do
            if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                table.insert(points, obj)
            end
        end
    end)
    return points
end
function GB_WaitRepairing(point, timeout)
    local start = fast_tick()
    while fast_tick() - start < (timeout or 1) do
        if point:GetAttribute("IsRepairing") == true then return true end
        task.wait(0.05)
    end
    return false
end
function GB_DoRepair(targetPoint)
    if Config.GenBypass._running then return end
    local genModel = targetPoint.Parent
    if Config.GenBypass.Processed[genModel] then return end
    Config.GenBypass.Processed[genModel] = true
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then Config.GenBypass.Processed[genModel] = nil return end
    local RepairEvent = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("Generator")
        and ReplicatedStorage.Remotes.Generator:FindFirstChild("RepairEvent")
    local originalCFrame = hrp.CFrame
    Config.GenBypass._running = true
    local myEpoch = Config.GenBypass._epoch
    local ok, err = pcall(function()
        for _, point in pairs(GB_GetPoints(genModel)) do
            if Config.GenBypass._epoch ~= myEpoch or Config.State.unloaded
                or not Config.GenBypass.Enabled then
                break
            end
            if point ~= targetPoint and point.Parent then
                hrp.Anchored = true
                hrp.CFrame = point.CFrame
                task.wait(0.15)
                pcall(function() if RepairEvent then RepairEvent:FireServer(point, true) end end)
                if not GB_WaitRepairing(point, 0.8) then
                    pcall(function() if RepairEvent then RepairEvent:FireServer(point, false) end end)
                    task.wait(0.1)
                    hrp.CFrame = point.CFrame
                    task.wait(0.15)
                    pcall(function() if RepairEvent then RepairEvent:FireServer(point, true) end end)
                    GB_WaitRepairing(point, 0.5)
                end
                hrp.Anchored = false
                task.wait(0.05)
            end
        end
    end)
    if not ok then
        warn("[GenBypass] GB_DoRepair error: " .. tostring(err))
    end
    pcall(function()
        if hrp and hrp.Parent then
            hrp.Anchored = false
            hrp.CFrame = originalCFrame
        end
    end)
    Config.GenBypass._running = false
    task.wait(0.1)
    pcall(function() if RepairEvent then RepairEvent:FireServer(targetPoint, false) end end)
end
function GB_GetNearestPoint()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local bestPoint, bestDist = nil, math.huge
    for _, gen in pairs(GB_GetAllGenerators()) do
        for _, point in pairs(GB_GetPoints(gen)) do
            local d = (hrp.Position - point.Position).Magnitude
            if d < bestDist then bestDist = d; bestPoint = point end
        end
    end
    return bestPoint, bestDist
end
function GB_IsPromptVisible()
    local ok, frame = pcall(function()
        return LocalPlayer.PlayerGui.pcprompts.Frame.GeneratorRepair
    end)
    return ok and frame and frame.Visible
end
function GB_UpdateButton()
    if not Config.GenBypass.UI or not Config.GenBypass.UI.Parent then
        if Config.GenBypass.Enabled and UserInputService.TouchEnabled then
            GB_CreateButton()
        else
            return
        end
    end
    if Config.GenBypass.Button and Config.GenBypass.Button.Parent then
        Config.GenBypass.Button.Visible = Config.GenBypass.Enabled and UserInputService.TouchEnabled
    end
end
function GB_CreateButton()
    if Config.GenBypass.UI then
        pcall(function() Config.GenBypass.UI:Destroy() end)
        Config.GenBypass.UI = nil
    end
    Config.GenBypass.UI = Instance.new("ScreenGui")
    Config.GenBypass.UI.Name = "BypassGenUI"
    Config.GenBypass.UI.ResetOnSpawn = false
    Config.GenBypass.UI.IgnoreGuiInset = true
    Config.GenBypass.UI.Parent = getProtectedGui()
    Config.GenBypass.Button = Instance.new("ImageButton")
    Config.GenBypass.Button.Size = UDim2.new(0, 53, 0, 53)
    Config.GenBypass.Button.Position = UDim2.new(0.88, 0, 0.55, 0)
    Config.GenBypass.Button.AnchorPoint = Vector2.new(0.5, 0.5)
    Config.GenBypass.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Config.GenBypass.Button.BackgroundTransparency = 0.9
    Config.GenBypass.Button.Image = ""
    Config.GenBypass.Button.ImageTransparency = 0.1
    Config.GenBypass.Button.Visible = false
    Config.GenBypass.Button.Parent = Config.GenBypass.UI
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = Config.GenBypass.Button
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1.2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Parent = Config.GenBypass.Button
    Config.GenBypass.Button.MouseButton1Click:Connect(function()
        if not Config.GenBypass.Enabled then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if bestPoint and bestDist <= 8 then GB_DoRepair(bestPoint) end
    end)
end
Config.Connections.GenBypassKey = UserInputService.InputBegan:Connect(function(input, gp)
    if gp and UserInputService:GetFocusedTextBox() then return end
    if UserInputService.TouchEnabled then return end
    if matchKey(input.KeyCode, Config.GenBypass.HotkeyCode) and Config.GenBypass.Enabled then
        if not GB_IsPromptVisible() then return end
        local bestPoint, bestDist = GB_GetNearestPoint()
        if not bestPoint or bestDist > 8 then return end
        if Config.GenBypass.Processed[bestPoint.Parent] then return end
        GB_DoRepair(bestPoint)
    end
end)
Config.Threads.GenBypassLoop = task.spawn(function()
    while not Config.State.unloaded do
        task.wait(2)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for genModel in pairs(Config.GenBypass.Processed) do
                if not genModel or not genModel.Parent then
                    Config.GenBypass.Processed[genModel] = nil
                    continue
                end
                local nearAny = false
                for _, point in pairs(GB_GetPoints(genModel)) do
                    if point.Parent and (hrp.Position - point.Position).Magnitude <= 10 then
                        nearAny = true; break
                    end
                end
                if not nearAny then Config.GenBypass.Processed[genModel] = nil end
            end
        end
    end
end)
function setGenBypass(v)
    Config.GenBypass.Enabled = v
    if not v then
        Config.GenBypass._epoch = Config.GenBypass._epoch + 1
    end
    if v and UserInputService.TouchEnabled then
        GB_CreateButton()
    elseif Config.GenBypass.UI and (not v or not UserInputService.TouchEnabled) then
        if Config.GenBypass.UI then
            pcall(function() Config.GenBypass.UI:Destroy() end)
            Config.GenBypass.UI = nil
        end
    end
    GB_UpdateButton()
end
function Fn.reapplyAllEnabled()
    for k in pairs(Config.LastVisualState) do Config.LastVisualState[k] = nil end
    for k in pairs(Config.LastOptimizationState) do Config.LastOptimizationState[k] = nil end
    for k in pairs(Config.DisabledEffects) do Config.DisabledEffects[k] = nil end
    for sky, parent in pairs(Config.DisabledSkies) do
        if sky and parent then pcall(function() sky.Parent = parent end) end
    end
    for k in pairs(Config.DisabledSkies) do Config.DisabledSkies[k] = nil end
    for clouds, parent in pairs(Config.DisabledClouds) do
        if clouds and parent then pcall(function() clouds.Parent = parent end) end
    end
    for k in pairs(Config.DisabledClouds) do Config.DisabledClouds[k] = nil end
    for sa, parent in pairs(Config.DisabledTextures) do
        if sa and parent then pcall(function() sa.Parent = parent end) end
    end
    for k in pairs(Config.DisabledTextures) do Config.DisabledTextures[k] = nil end
    Fn.applyVisual(true)
    Fn.applyOptimization(true)
    Fn.applyCleanTexture(true)
    Fn.applyNoScreenEffects()
    Fn.applyMaxZoom()
    Fn.applyCameraFOV()
    if Config.Movement.SpeedBoost.Enabled then Fn.applySpeedBoost() end
    if Config.Movement.Vault.Enabled then Fn.applyVault() end
    if Config.Movement.FakeFastVault.Enabled then Fn.applyFakeFastVault() end
    if Config.Movement.AntiSlowVault.Enabled then Fn.applyAntiSlowVault() end
    if Config.Movement.SkillCheckSpeed.Enabled then Fn.applySkillCheckSpeed() end
    if Config.GunAim.Enabled then Fn.startGunAim() end
    if Config.AttackAim.Enabled then Fn.startAttackAim() end
    if Config.Auto.SkillCheck then Fn.startSkillCheck() end
    if Config.Killer.Stalk.Enabled then Fn.startAutoStalk() end
    if Config.Killer.BypassCooldown then Fn.StartCooldownBypass() end
    if Config.Killer.NoCooldownHidden then
        Fn.safeCall("NoCooldownHidden Init", function() Fn.StartNoCooldownHidden() end)
    end
    if Config.Killer.M2Aimlock.Enabled then
        Fn.safeCall("M2Aimlock Init", function() Fn.StartM2Aimlock() end)
    end
    if Config.Killer.InfiniteLunge then
        Fn.safeCall("InfiniteLunge Invalidate", function() Fn.invalidateInfiniteLungeCache() end)
        Fn.startInfiniteLunge()
    end
    if Config.Moonwalk.ShowButton then Fn.createMoonwalkButton() end
    if Config.FakeParry.Enabled and UserInputService.TouchEnabled then Fn.CreateFakeParryButton() end
    if Config.ToFAimV1.Enabled then
        pcall(function() ToFV1_SetSilentAim(true) end)
    end
    if Config.EmoteButton.Show then Fn.createEmoteButton() end
    if Config.GenBypass.Enabled and UserInputService.TouchEnabled then
        GB_CreateButton()
        GB_UpdateButton()
    end
    if Config.Auto.AutoCrouch.Enabled then Fn.startAutoCrouch() end
    if Config.PredictMap.Enabled then Fn.StartPredictMap() end
    if Config.Visual.HideSurvivorIcon then Fn.FLNS_SetHideSurvivorIcon(true) end
    if Config.Invisible.Enabled then Fn.setInvisible(true) end
    if Config.Invisible.ShowButton then Fn.createInvisibleToggleButton() end
end
UI.AbilityTab:AddToggle("Skill", { Text = "Auto Skill Check", Default = false,
    Callback = function(v)
        Config.Auto.SkillCheck = v
        if v then
            Fn.safeCall("SkillCheck Start", function() Fn.startSkillCheck() end)
        else
            Fn.safeCall("SkillCheck Stop", function() Fn.stopSkillCheck() end)
        end
    end }):AddKeyPicker("Skill_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddDropdown("SkillCheckModeDropdown", { Values = {"perfect", "normal", "Instant"},
    Default = 1,
    Multi = false,
    Text = "Skill Check Mode",
    Callback = function(v)
        Config.Auto.SkillCheckMode = v
    end })
UI.AbilityTab:AddToggle("SkillCheckSpeedToggle", { Text = "Slow Skill Check", Default = false,
    Callback = function(v)
        Config.Movement.SkillCheckSpeed.Enabled = v
        if v then
            Fn.applySkillCheckSpeed()
        else
            Fn.disableSkillCheckSpeed()
        end
    end }):AddKeyPicker("SkillCheckSpeedToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("SkillCheckSpeedValue", { Text = "Skill Check Speed Value", Default = 1, Min = 1, Max = 3, Rounding = 2,
    Callback = function(v) Config.Movement.SkillCheckSpeed.Speed = v end })
UI.AbilityTab:AddToggle("GenBoostToggle", { Text = "Bypass PerksPerfectionist",
    Default = false,
    Callback = function(Value)
        Config.Auto.GenBoost.Enabled = Value
        if not Value then
            local perksFolder = Remotes:FindFirstChild("Perks")
            local perfRemote = perksFolder and perksFolder:FindFirstChild("perfectionistplanning")
            if perfRemote then
                Fn.safeCall("GenBoost Clear", function() perfRemote:FireServer("clearBoost") end)
            end
        end
    end }):AddKeyPicker("GenBoostToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("GenBypassToggle", { Text = "GenBoost (MultiRepair)", Default = false,
    Callback = function(v) Fn.safeCall("GenBypass Set", function() setGenBypass(v) end) end }):AddKeyPicker("GenBypassToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("StunNotificationToggle", { Text = "Stun Notification",
    Default = false,
    Callback = function(v)
        Config.StunNotification.Enabled = v
        if not v then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
    end }):AddKeyPicker("StunNotificationToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("AutoPalletDrop", { Text = "Auto Drop Pallet", Default = false,
    Callback = function(v) Config.Auto.PalletDrop = v end }):AddKeyPicker("AutoPalletDrop_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
do
    local toggle = UI.AbilityTab:AddToggle("AutoFleeKiller", { Text = "Auto Flee Killer",
        Default = false,
        Callback = function(v) Config.Auto.Flee.Enabled = v end }):AddKeyPicker("AutoFleeKiller_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.AbilityTab:AddToggle("AntiFallDamage", { Text = "Anti Fall Damage",
    Default = false,
    Callback = function(Value)
        Config.Killer.Mods.AntiFall = Value
    end }):AddKeyPicker("AntiFallDamage_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("GodMode", { Text = "Anti KnockDown", Default = false,
    Callback = function(v) Config.Killer.Mods.GodMode = v end }):AddKeyPicker("GodMode_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("AutoCrouchToggle", { Text = "Auto Crouch", Default = false,
    Callback = function(v)
        Config.Auto.AutoCrouch.Enabled = v
        if v then Fn.startAutoCrouch() else Fn.stopAutoCrouch() end
    end }):AddKeyPicker("AutoCrouchToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("AutoCrouchDist", {
    Text = "Detect Distance",
    Default = Config.Auto.AutoCrouch.DetectDistance,
    Min = 5, Max = 80, Rounding = 0,
    Callback = function(v) Config.Auto.AutoCrouch.DetectDistance = v end
})
UI.AbilityTab:AddSlider("AutoCrouchSpeed", {
    Text = "Crouch WalkSpeed",
    Default = Config.Auto.AutoCrouch.WalkSpeed,
    Min = 2, Max = 16, Rounding = 0,
    Callback = function(v) Config.Auto.AutoCrouch.WalkSpeed = v end
})
UI.AbilityTab:AddToggle("SelfHealToggle", { Text = "Self Heal (Auto)",
    Default = false,
    Callback = function(v)
        if v then Fn.startSelfHeal() else Fn.stopSelfHeal() end
    end }):AddKeyPicker("SelfHealToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("AutoBandage", { Text = "Auto Bandage",
    Default = false,
    Callback = function(v)
        Config.Auto.Bandage.Auto = v
        if v then Fn.startAutoBandage() else Fn.stopAutoBandage() end
        Fn.updateToggleIconVisual("AutoBandage")
    end }):AddKeyPicker("AutoBandage_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("BandageInstant", { Text = "Instant Bandage (Hook)",
    Default = true,
    Callback = function(v)
        Config.Auto.Bandage.Instant = v
    end })
UI.AbilityTab:AddSlider("BandageThreshold", {
    Text = "Bandage HP Threshold (%)",
    Default = 95,
    Min = 1, Max = 99, Rounding = 0,
    Callback = function(v) Config.Auto.Bandage.Threshold = v end
})
UI.AbilityTab:AddSlider("BandageCooldown", {
    Text = "Bandage Cooldown (s)",
    Default = 1.5,
    Min = 0.5, Max = 10, Rounding = 1,
    Callback = function(v) Config.Auto.Bandage.Cooldown = v end
})
do
    local toggle = UI.AbilityTab:AddToggle("FlowstateToggle", { Text = "Flowstate",
        Default = false,
        Callback = function(v)
            Config.Flowstate.Enabled = v
            if v then Fn.startFlowstate() else Fn.stopFlowstate() end
            Fn.updateToggleIconVisual("Flowstate")
        end }):AddKeyPicker("FlowstateToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.AbilityTab:AddToggle("FakePerfectLandingToggle", { Text = "Fake Perfect Landing",
    Default = false,
    Callback = function(v)
        Config.Movement.FakePerfectLanding.Enabled = v
        if v then Fn.applySpeedBoost() else Fn.disableSpeedBoost() end
    end }):AddKeyPicker("FakePerfectLandingToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("FakePerfectLandingSlider", { Text = "Landing Boost Value",
    Default = 1.40, Min = 1.0, Max = 5.0, Rounding = 2,
    Callback = function(v)
        Config.Movement.FakePerfectLanding.Value = v
    end })
UI.AbilityTab:AddToggle("FastVault", { Text = "Vault Speed", Default = false,
    Callback = function(v)
        Config.Movement.Vault.Enabled = v
        if v then
            Fn.applyVault()
        else
            Fn.disableVault()
        end
    end }):AddKeyPicker("FastVault_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddSlider("VaultSpeed", { Text = "Vault Speed", Default = 1, Min = 1, Max = 3, Rounding = 2,
    Callback = function(v) Config.Movement.Vault.Speed = v end })
UI.AbilityTab:AddToggle("FakeFastVault", { Text = "Fake Fast Vault", Default = false,
    Callback = function(v)
        Config.Movement.FakeFastVault.Enabled = v
        if v then
            Fn.applyFakeFastVault()
        else
            Fn.disableFakeFastVault()
        end
    end }):AddKeyPicker("FakeFastVault_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddToggle("AntiSlowVault", { Text = "Anti Slow Vault", Default = false,
    Callback = function(v)
        Config.Movement.AntiSlowVault.Enabled = v
        if v then
            Fn.applyAntiSlowVault()
        else
            Fn.disableAntiSlowVault()
        end
    end }):AddKeyPicker("AntiSlowVault_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AbilityTab:AddDivider()
UI.AbilityTab:AddButton({ Text = "Instant Escape", Func = function() Fn.teleportToFinishLine() end })
UI.KillerTab:AddToggle("BlockAllVaults", { Text = "Block All Vaults",
    Default = false,
    Callback = function(v)
        Config.Killer.BlockVaults = v
        if not v and Config.State._vaultFireOK then
            Config.State._vaultFireOK = nil
        end
    end }):AddKeyPicker("BlockAllVaults_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("AntiBlindToggle", { Text = "Anti Blind (Flashlight)",
    Default = false,
    Callback = function(v)
        Config.Killer.AntiBlind = v
    end }):AddKeyPicker("AntiBlindToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("AutoStalk", { Text = "Auto Stalk (myers)", Default = false,
    Callback = function(v)
        Config.Killer.Stalk.Enabled = v
        if v then Fn.startAutoStalk() else Fn.stopAutoStalk() end
    end }):AddKeyPicker("AutoStalk_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("BypassCooldown", { Text = "NoCooldown(Abyss)",
    Default = false,
    Callback = function(state)
        Config.Killer.BypassCooldown = state
        if state then
            Fn.StartCooldownBypass()
        end
    end }):AddKeyPicker("BypassCooldown_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("NoCooldownHidden", { Text = "No Cooldown Hidden",
    Default = false,
    Callback = function(state)
        Config.Killer.NoCooldownHidden = state
        if state then
            Fn.safeCall("NoCooldownHidden Start", function() Fn.StartNoCooldownHidden() end)
        else
            Fn.StopNoCooldownHidden()
        end
    end }):AddKeyPicker("NoCooldownHidden_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
do
    UI.KillerTab:AddToggle("M2Aimlock", { Text = "Aimlock M2 Hidden",
        Default = false,
        Callback = function(state)
            Config.Killer.M2Aimlock.Enabled = state
            if state then
                Fn.safeCall("M2Aimlock Start", function() Fn.StartM2Aimlock() end)
            else
                Fn.StopM2Aimlock()
            end
        end }):AddKeyPicker("M2Aimlock_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
end
UI.KillerTab:AddToggle("InfiniteLungeToggle", { Text = "Infinite Lunge Attack", Default = false,
    Callback = function(v)
        Config.Killer.InfiniteLunge = v
        if v then
            Fn.safeCall("InfiniteLunge Start", function() Fn.startInfiniteLunge() end)
        else
            Fn.safeCall("InfiniteLunge Stop", function() Fn.stopInfiniteLunge() end)
        end
    end }):AddKeyPicker("InfiniteLungeToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("KillAll", { Text = "Auto Kill All", Default = false,
    Callback = function(v) Config.Killer.KillAll = v end }):AddKeyPicker("KillAll_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddToggle("BreakSpeedToggle", { Text = "Enable Break Speed",
    Default = false,
    Callback = function(v)
        Config.Killer.BreakSpeedEnabled = v
    end }):AddKeyPicker("BreakSpeedToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.KillerTab:AddSlider("BreakSpeedSlider", { Text = "Break Pallet & Gen Speed",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 2,
    Callback = function(v)
        Config.Killer.BreakSpeed = v
    end })
UI.KillerTab:AddDivider()
UI.KillerTab:AddDropdown("MaskedPowerSelect", { Text = "Select Power", Values = Config.Masked.Powers, Default = 1, Multi = false,
    Callback = function(val) Config.Masked.CurrentPower = val end })
UI.KillerTab:AddButton({ Text = "Activate Power", Func = function()
    local Event = ReplicatedStorage:FindFirstChild("Remotes", true)
        and ReplicatedStorage.Remotes:FindFirstChild("Killers", true)
        and ReplicatedStorage.Remotes.Killers:FindFirstChild("Masked", true)
        and ReplicatedStorage.Remotes.Killers.Masked:FindFirstChild("Activatepower")
    if Event then Event:FireServer(Config.Masked.CurrentPower) end
end })
UI.KillerTab:AddButton({ Text = "Deactivate Power", Func = function()
    Fn.safeCall("Deactivate Power", function()
        Remotes.Masked:WaitForChild("PowerEvent"):FireServer(false, "Cancel")
    end)
end })
do
    local toggle = UI.ParryBox:AddToggle("AutoParry", { Text = "Auto Parry",
        Default = false,
        Callback = function(v)
            Config.Auto.Parry = v
            if not v then
                if Config.State.ParryCooldownThread then
                    pcall(function() task.cancel(Config.State.ParryCooldownThread) end)
                    Config.State.ParryCooldownThread = nil
                end
                Config.State.ParryCooldown = false
                Config.State.ParryActive = false
                Fn.parryVisual_refresh()
                if Config.State.ParryCircle then
                    Config.State.ParryCircle:Destroy()
                    Config.State.ParryCircle = nil
                    Config.State.ParryCircleBeams = nil
                    Config.State.ParryCircleAtts  = nil
                    Config.State.ParryCircleCache = nil
                end
                if Config.State.ParryCircleFill then
                    Config.State.ParryCircleFill:Destroy()
                    Config.State.ParryCircleFill = nil
                end
                Config.Auto.ParryVisual.Enabled = false
                pcall(function() Toggles.ShowParryRange:SetValue(false) end)
            end
        end }):AddKeyPicker("AutoParry_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("ParryRangeColor", { Default = Color3.fromRGB(255,80,80), Transparency = 0.9, Title = "Parry Range Color",
        Callback = function(color)
            Config.Auto.ParryVisual.Color = color
            if Config.State.ParryCircleFill then Config.State.ParryCircleFill.Color = color end
        end }):AddColorPicker("ParryRangeStrokeColor", { Default = Color3.fromRGB(51, 124, 255), Transparency = 0.1, Title = "Parry Range Stroke / Outline",
        Callback = function(color, transparency)
            Config.Auto.ParryVisual.StrokeColor = color
            if transparency ~= nil then
                Config.Auto.ParryVisual.StrokeTransparency = transparency
            end
        end })
end
UI.ParryBox:AddDropdown("ParryMode", { Text = "Parry Mode", Values = {"Instant", "Legit"}, Default = 1,
    Callback = function(v)
        Config.Auto.ParryMode = v
    end })
UI.ParryBox:AddToggle("ShowParryRange", { Text = "Show Parry Range", Default = false,
    Callback = function(v)
        if not Config.Auto.Parry then
            Config.Auto.ParryVisual.Enabled = false
            if Config.State.ParryCircle then
                Config.State.ParryCircle:Destroy()
                Config.State.ParryCircle = nil
                Config.State.ParryCircleBeams = nil
                Config.State.ParryCircleAtts  = nil
                Config.State.ParryCircleCache = nil
            end
            if Config.State.ParryCircleFill then
                Config.State.ParryCircleFill:Destroy()
                Config.State.ParryCircleFill = nil
            end
            if v then
                pcall(function() Toggles.ShowParryRange:SetValue(false) end)
            end
            return
        end
        Config.Auto.ParryVisual.Enabled = v
        if not v and Config.State.ParryCircle then
            Config.State.ParryCircle:Destroy()
            Config.State.ParryCircle = nil
            Config.State.ParryCircleBeams = nil
            Config.State.ParryCircleAtts  = nil
            Config.State.ParryCircleCache = nil
        end
        if not v and Config.State.ParryCircleFill then
            Config.State.ParryCircleFill:Destroy()
            Config.State.ParryCircleFill = nil
        end
    end }):AddKeyPicker("ShowParryRange_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ParryBox:AddSlider("ParryDistance", { Text = "Distance", Default = 15, Min = 5, Max = 30, Rounding = 0,
    Callback = function(v) Config.Auto.ParryDistance = v end })
UI.ParryBox:AddSlider("ParryDelaySlider", { Text = "Parry Delay(ms)", Default = 0, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) Config.Auto.ParryDelay = v / 1000 end })
UI.ParryBox:AddDropdown("ParryAnim", {
    Text = "Parry Animation",
    Values = {"NoSkin","Enten","Stopwatch","Fih","BloodShield"},
    Default = 2,
    Callback = function(v)
        Config.Auto.ParryAnim = v

        _parryVisual._doParryToken = (_parryVisual._doParryToken or 0) + 1

        if _parryVisual.parryTrack then
            pcall(function() _parryVisual.parryTrack:Stop() end)
            _parryVisual.parryTrack = nil
        end
        _parryVisual.parryTrackChar = nil

        Config.State.ParryActive = false
        if Config.State.ParryCooldownThread then
            pcall(function() task.cancel(Config.State.ParryCooldownThread) end)
            Config.State.ParryCooldownThread = nil
        end
        Config.State.ParryCooldown = false
        Config.State.lastParry = 0

        if _parryVisual.actionAppliedFor and _parryVisual.actionAppliedFor.Parent then
            pcall(function()
                game:GetService("CollectionService"):RemoveTag(
                    _parryVisual.actionAppliedFor, "doing action")
            end)
        end
        _parryVisual.actionAppliedFor = nil

        if _parryVisual.faceHeartbeatConn then
            pcall(function() _parryVisual.faceHeartbeatConn:Disconnect() end)
            _parryVisual.faceHeartbeatConn = nil
            local hum = LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end

        Fn.parryVisual_refresh()
    end
})
UI.ParryBox:AddSlider("FaceSensitivity", { Text = "Face Sensitivity Killer", Default = 0.7, Min = -1, Max = 1, Rounding = 2,
    Callback = function(v) Config.Auto.FaceSensitivity = v end })
do
    local toggle = UI.ParryBox:AddToggle("FakeParry", { Text = "Enable Fake Parry", Default = false,
        Callback = function(v)
            Config.FakeParry.Enabled = v
            if UserInputService.TouchEnabled then
                if v then Fn.CreateFakeParryButton() else Fn.RemoveFakeParryButton() end
            end
        end })
                UI.ParryBox:AddLabel("Fake Parry Key"):AddKeyPicker("FakeParryKeybind", { Mode = "Toggle", ChangedCallback = function(New) Config.FakeParry.Keybind = New end })
end
UI.ParryBox:AddDropdown("FakeParryAnim", { Text = "Animation", Values = {"Enten","Stopwatch","Fih","BloodShield"}, Default = 1,
    Callback = function(v) Config.FakeParry.Animation = v end })

Shared._animIdCache = _animIdCache