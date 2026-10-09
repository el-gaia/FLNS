local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Library            = Shared.Library
local Options            = Shared.Options
local Toggles            = Shared.Toggles
local Window             = Shared.Window
local Players            = Shared.Players
local UserInputService   = Shared.UserInputService
local RunService         = Shared.RunService
local ReplicatedStorage  = Shared.ReplicatedStorage
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
local Remotes            = Shared.Remotes
local ToFFireRemote      = Shared.ToFFireRemote
local GotBlindedRemote   = Shared.GotBlindedRemote
local fast_tick          = Shared.fast_tick
local _V3_UP_3   = Vector3.new(0, 3, 0)
local _V3_UP_0   = Vector3.new(0, 0, 0)
local _predictScratchRay = RaycastParams.new()
_predictScratchRay.FilterType = Enum.RaycastFilterType.Blacklist
_predictScratchRay.IgnoreWater = true
local _predictScratchFilter = {}
Config.FakeConnection = function(taskTable, name, func)
    local taskArray
    if taskTable == Config.HeartbeatTasks then
        taskArray = Config.HeartbeatTasksArray
    elseif taskTable == Config.RenderSteppedTasks then
        taskArray = Config.RenderSteppedTasksArray
    else
        taskArray = taskTable._array
        if not taskArray then
            taskArray = {}
            taskTable._array = taskArray
        end
    end
    local entry = {    name, func = func }
    taskTable[name] = entry
    taskArray[#taskArray + 1] = entry
    return {
        Disconnect = function()
            if taskTable[name] == entry then
                taskTable[name] = nil
            end
            entry.func = nil
        end
    }
end
Config.Connections.MainLoopManagerHB = RunService.Heartbeat:Connect(function(dt)
    local arr = Config.HeartbeatTasksArray
    local writeIdx = 1
    local i = 1
    while i <= #arr do
        local entry = arr[i]
        if entry and entry.func then
            local ok, err = pcall(entry.func, dt)
            if not ok then warn("[Heartbeat Error] " .. tostring(entry.name) .. ": " .. tostring(err)) end
            arr[writeIdx] = entry
            writeIdx = writeIdx + 1
        end
        i = i + 1
    end
    for j = writeIdx, #arr do arr[j] = nil end
end)
Config.Connections.MainLoopManagerRS = RunService.RenderStepped:Connect(function(dt)
    local arr = Config.RenderSteppedTasksArray
    local writeIdx = 1
    local i = 1
    while i <= #arr do
        local entry = arr[i]
        if entry and entry.func then
            local ok, err = pcall(entry.func, dt)
            if not ok then warn("[RenderStepped Error] " .. tostring(entry.name) .. ": " .. tostring(err)) end
            arr[writeIdx] = entry
            writeIdx = writeIdx + 1
        end
        i = i + 1
    end
    for j = writeIdx, #arr do arr[j] = nil end
end)
local function getProtectedGui()
    local success, hui = pcall(function() return gethui() end)
    if success and hui then return hui end
    return game:GetService("CoreGui")
end
local uis_init = game:GetService("UserInputService")
getgenv().FALLENS_InitMouseB = uis_init.MouseBehavior
getgenv().FALLENS_InitMouseI = uis_init.MouseIconEnabled
local function randomString()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local s = ""
    for _ = 1, math.random(8, 16) do
        local idx = math.random(1, #chars)
        s = s .. string.sub(chars, idx, idx)
    end
    return s
end
Config.Fly.State.velocityHandlerName = randomString()
Config.Fly.State.gyroHandlerName = randomString()
Config._sharedRayParams = RaycastParams.new()
Config._sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude
Config._sharedRayParams.IgnoreWater = true
Config._sharedRayParams.FilterDescendantsInstances = {}
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChildWhichIsA("BasePart")
end
local function formatUsername(player)
    if not player then return "Unknown" end
    return player.DisplayName and player.DisplayName ~= "" and player.DisplayName or player.Name
end
local function getPlayer(query, speaker)
    local matches = {}
    if not query then return matches end
    query = tostring(query):lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= speaker then
            local n = p.Name:lower()
            local d = (p.DisplayName or ""):lower()
            if n == query or d == query or n:find(query, 1, true) or d:find(query, 1, true) then
                table.insert(matches, p)
            end
        end
    end
    return matches
end
local function r15(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.RigType == Enum.HumanoidRigType.R15
end
local function breakVelocity()
    local char = LocalPlayer.Character
    if not char then return end
    local root = getRoot(char)
    if not root then return end
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") then
            child:Destroy()
        end
    end
end
function Fn.safeCall(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Fallens] " .. label .. ": " .. tostring(err)) end
    return ok, err
end
function Fn.notify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title       = tostring(title),
                Description = tostring(desc),
                Time        = duration or 3,
            })
        end
    end)
end
function Fn._destroyConn(label, obj)
    if obj == nil then return end
    local t = typeof(obj)
    if t == "RBXScriptConnection" then
        Fn.safeCall("Unload " .. label, function() obj:Disconnect() end)
    elseif t == "thread" then
        Fn.safeCall("Unload " .. label, function() task.cancel(obj) end)
    elseif type(obj) == "function" then
        Fn.safeCall("Unload " .. label, obj)
    elseif type(obj) == "table" and type(obj.Disconnect) == "function" then
        Fn.safeCall("Unload " .. label, function() obj:Disconnect() end)
    elseif type(obj) == "table" and type(obj.Destroy) == "function" then
        Fn.safeCall("Unload " .. label, function() obj:Destroy() end)
    end
end
function Fn.getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end
function Fn.getLocalTeamName()
    local team = LocalPlayer.Team
    return team and team.Name or "Spectator"
end
function Fn.isSurvivorTeam()
    return Fn.getLocalTeamName() == "Survivors"
end
function Fn.isKillerTeam()
    return Fn.getLocalTeamName() == "Killer"
end
function Fn.isSpectatorTeam()
    return Fn.getLocalTeamName() == "Spectator"
end
function Fn.canUseGunAim()
    return Fn.isSurvivorTeam()
end
function Fn.canUseAttackAim()
    return Fn.isKillerTeam()
end
function Fn.shouldUseAimKeybind()
    return UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
end
function Fn.checkDowned(char)
    if not char then return false end
    return char:GetAttribute("Knocked") == true or char:GetAttribute("isHooked") == true
end
function Fn.isDowned(char)
    if not char then char = LocalPlayer.Character end
    return Fn.checkDowned(char)
end
local oldNamecall
local _Invisible_GetRemote = function()
    if Config.Invisible.Remote and Config.Invisible.Remote.Parent then
        return Config.Invisible.Remote
    end
    local ok, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5)
                  :WaitForChild("Game", 5)
                  :WaitForChild("UpdateCharacterLook", 5)
    end)
    if ok and remote and remote.Parent then
        Config.Invisible.Remote = remote
        return remote
    end
    return nil
end
local _Invisible_BreakCFrame = function(cf)
    if typeof(cf) ~= "CFrame" then return cf end
    return CFrame.new(0, -1000, 0)
end
local _Invisible_ApplyToArgs = function(args)
    if not args then return args end
    for i = 1, 5 do
        if typeof(args[i]) == "CFrame" then
            args[i] = _Invisible_BreakCFrame(args[i])
        end
    end
    return args
end
local _Korless_BreakCFrame
_Korless_BreakCFrame = function(cf, offset, keepRot)
    if typeof(cf) ~= "CFrame" then return cf end
    if not keepRot then
        return CFrame.new(0, offset, 0)
    end
    return (cf - cf.Position) + Vector3.new(0, offset, 0)
end
local _Korless_ApplyToArgs
_Korless_ApplyToArgs = function(args)
    if not args then return args end
    local cfg = Config.Korless
    if not (cfg.SinkHead or cfg.SinkRightLeg) then
        return args
    end
    local offset   = cfg.Offset or -1000
    local keepRot  = cfg.KeepRotation
    if cfg.SinkHead and typeof(args[1]) == "CFrame" then
        args[1] = _Korless_BreakCFrame(args[1], offset, keepRot)
    end
    if cfg.SinkRightLeg and typeof(args[3]) == "CFrame" then
        args[3] = _Korless_BreakCFrame(args[3], offset, keepRot)
    end
    return args
end
local _Fling_BreakCFrame = function(cf)
    if typeof(cf) ~= "CFrame" then return cf end
    return CFrame.new(0, 1e9, 0)
end
local _Fling_ApplyToArgs = function(args)
    if not args then return args end
    for i = 1, 5 do
        if typeof(args[i]) == "CFrame" then
            args[i] = _Fling_BreakCFrame(args[i])
        end
    end
    return args
end
local _CharLook_EnsureHook = function()
    if Config.Invisible.HookActive then return true end
    if not hookfunction then return false end
    local remote = _Invisible_GetRemote()
    if not remote then return false end
    local ok, original = pcall(function()
        return hookfunction(remote.FireServer, function(...)
            local self = ...
            if not rawequal(self, remote)
                or not (Config.Invisible.Enabled or Config.Fling.Enabled or Config.Korless.Enabled) then
                return Config.Invisible.OriginalFire(...)
            end
            local args = table.pack(...)
            if Config.Fling.Enabled then
                _Fling_ApplyToArgs(args)
            elseif Config.Invisible.Enabled then
                _Invisible_ApplyToArgs(args)
            elseif Config.Korless.Enabled then
                _Korless_ApplyToArgs(args)
            end
            return Config.Invisible.OriginalFire(table.unpack(args, 1, args.n))
        end)
    end)
    if ok then
        Config.Invisible.OriginalFire = original
        Config.Invisible.HookActive = true
        return true
    end
    warn("[Fallens] UpdateCharacterLook hookfunction gagal: " .. tostring(original))
    return false
end
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if checkcaller() then
        return oldNamecall(self, ...)
    end
    local method = getnamecallmethod()
    if method ~= "FireServer" then
        return oldNamecall(self, ...)
    end
    local args = { ... }
    local nargs = select('#', ...)
    if (Config.Invisible.Enabled or Config.Fling.Enabled or Config.Korless.Enabled)
        and typeof(self) == "Instance" and self.Name == "UpdateCharacterLook" then
        if Config.Fling.Enabled then
            _Fling_ApplyToArgs(args)
        elseif Config.Invisible.Enabled then
            _Invisible_ApplyToArgs(args)
        elseif Config.Korless.Enabled then
            _Korless_ApplyToArgs(args)
        end
        return oldNamecall(self, table.unpack(args, 1, nargs))
    end
    local ok, swallow = pcall(function()
        if Config.VeilConfig.Enabled and not Config.VeilState.firing
            and self.Name == "Spearthrow" then
            return true
        end
        if Config.Killer.AntiBlind and self == GotBlindedRemote then
            local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
            if isKiller then
                return true
            end
        end
        if ToFFireRemote and self == ToFFireRemote
            and typeof(args[1]) == "Instance" then
            Config.GunAim._cachedGunPart = args[1]
        end
        if Config.Auto.Bandage and Config.Auto.Bandage.Instant
            and self.Name == "Fire"
            and self.Parent and self.Parent.Name == "Bandage"
            and args[1] == true then
            if Fn.InstantBandageSpam then
                task.spawn(Fn.InstantBandageSpam)
            end
            return true
        end
        return false
    end)
    if not ok then
        warn("[Fallens] __namecall hook error: " .. tostring(swallow))
        return oldNamecall(self, ...)
    end
    if swallow then
        return nil
    end
    if Config.ToFAimV1 and Config.ToFAimV1.Enabled
        and ToFFireRemote and self == ToFFireRemote
        and Config.ToFAimV1.CachedShouldRedirect
        and Config.ToFAimV1.CachedRedirectDir then
        args[2] = Config.ToFAimV1.CachedRedirectDir
        if Config.ToFAimV1.ShowLaser
            and Config.ToFAimV1.CachedOriginPos
            and Config.ToFAimV1.CachedTargetPos then
            pcall(function()
                Fn.ToFV2_UpdateLaser(Config.ToFAimV1.CachedOriginPos, Config.ToFAimV1.CachedTargetPos)
            end)
        end
        return oldNamecall(self, table.unpack(args, 1, 2))
    end
    return oldNamecall(self, ...)
end))
local function hookKillerIfKiller(p, char)
    if not p or not char then return end
    if p == LocalPlayer then return end
    if not p.Team or p.Team.Name ~= "Killer" then return end
    Fn.hookKiller(char)
end
function Fn.onTeamTransition()
    local team = Fn.getLocalTeamName()
    if team == "Survivors" then
        Config.State._espCleanedForSpectator = false
        Fn.safeCall("KillerPerks Watcher Start (team)", Fn.startKillerPerksWatcher)
        task.delay(5, function()
            if Config.State.unloaded then return end
            if Fn.isSurvivorTeam() then
                Fn.startParryHook()
                if Config.Auto.AutoCrouch.Enabled then
                    Fn.startAutoCrouch()
                end
                Fn.safeCall("KillerPerks Watcher Re-arm", Fn.startKillerPerksWatcher)
            end
        end)
    else
        Config.GenBypass._epoch = Config.GenBypass._epoch + 1
        if team == "Killer" then
            Fn.safeCall("Window Rescan", function() Fn.rescanWindows() end)
            Config.State._vaultFireOK = nil
        end
        if team ~= "Killer" then
            Config.Killer.Stalk.Target = nil
            Fn.safeCall("InfiniteLunge Invalidate", function() Fn.invalidateInfiniteLungeCache() end)
        end
        Fn.safeCall("KillerPerks Watcher Stop (team)", Fn.stopKillerPerksWatcher)
        if Config.KillerPerksDisplay.Label then
            Fn.safeCall("KillerPerks Label Reset (team)", function()
                Config.KillerPerksDisplay.Label:SetText("Killer Perks: -")
            end)
        end
        Fn.stopParryHook()
        Fn.stopAutoCrouch()
        if team == "Spectator" and not Config.State._espCleanedForSpectator then
            Fn.safeCall("Spectator ESP Cleanup", function()
                for obj, h in pairs(Config.ESPCache.Objects) do
                    if h then h:Destroy() end
                end
                for char, gui in pairs(Config.ESPCache.Status) do
                    if gui then gui:Destroy() end
                end
                for char, gui in pairs(Config.ESPCache.InfoBillboards) do
                    if gui then gui:Destroy() end
                end
                Config.ESPCache.Objects    = {}
                Config.ESPCache.Status     = {}
                Config.ESPCache.SCP        = {}
                Config.ESPCache.Generators = {}
                Config.ESPCache.Windows    = {}
                Config.ESPCache.Pallets    = {}
                Config.ESPCache.InfoBillboards = {}
                for obj, conn in pairs(Config.ESPCache.AncestryConns) do
                    if typeof(conn) == "RBXScriptConnection" then
                        Fn.safeCall("Spectator Cleanup AncestryConn", function() conn:Disconnect() end)
                    end
                    Config.ESPCache.AncestryConns[obj] = nil
                end
                Config.ESPCache.StatusStates = {}
            end)
            Config.State._espCleanedForSpectator = true
        end
    end
end
local visibilityCache = {}
setmetatable(visibilityCache, { __mode = "k" })
function Fn.clearVisibilityCache()
    local now = fast_tick()
    for part, data in pairs(visibilityCache) do
        if not part or not part.Parent or now - data.time > 2 then
            visibilityCache[part] = nil
        end
    end
end
function Fn.isVisible(part)
    local now = fast_tick()
    if visibilityCache[part] and now - visibilityCache[part].time < 0.5 then
        return visibilityCache[part].visible
    end
    local cam = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local targetPos = part.Position
    local direction = targetPos - origin
    local ignoreList = {LocalPlayer.Character}
    local isVisible = false
    local rayParams = Config._sharedRayParams
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    for i = 1, 3 do
        rayParams.FilterDescendantsInstances = ignoreList
        local result = workspace:Raycast(origin, direction, rayParams)
        if not result then
            isVisible = true
            break
        elseif result.Instance:IsDescendantOf(part.Parent) then
            isVisible = true
            break
        elseif (result.Position - targetPos).Magnitude <= 5 then
            isVisible = true
            break
        elseif result.Instance.Transparency >= 0.8 or not result.Instance.CanCollide then
            table.insert(ignoreList, result.Instance)
        else
            break
        end
    end
    visibilityCache[part] = {time = now, visible = isVisible}
    return isVisible
end
local _lastVisCacheClean = 0
Config.FakeConnection(Config.HeartbeatTasks, "VisibilityCacheCleanup", function()
    local now = fast_tick()
    if now - _lastVisCacheClean < 2 then return end
    _lastVisCacheClean = now
    Fn.clearVisibilityCache()
end)
local function IsValidSticky(part)
    if not (part and part.Parent and part.Parent:FindFirstChild("Humanoid") and part.Parent.Humanoid.Health > 0) then
        return false
    end
    return not Fn.checkDowned(part.Parent)
end
local function matchKey(inputEnum, configVal)
    if typeof(configVal) == "EnumItem" then
        return inputEnum == configVal
    elseif type(configVal) == "string" then
        return inputEnum.Name == configVal
    end
    return false
end
Config.Connections.AimKeyBegan = UserInputService.InputBegan:Connect(function(input, gp)
    if gp and UserInputService:GetFocusedTextBox() then return end
    if Fn.shouldUseAimKeybind() and input.UserInputType == Enum.UserInputType.Keyboard then
        if matchKey(input.KeyCode, Config.GunAim.Keybind) and Fn.canUseGunAim() then
            Config.GunAim.Holding = true
        elseif matchKey(input.KeyCode, Config.AttackAim.Keybind) and Fn.canUseAttackAim() then
            Config.AttackAim.Holding = true
        end
    end
end)
Config.Connections.AimKeyEnded = UserInputService.InputEnded:Connect(function(input)
    if Fn.shouldUseAimKeybind() and input.UserInputType == Enum.UserInputType.Keyboard then
        if matchKey(input.KeyCode, Config.GunAim.Keybind) then
            Config.GunAim.Holding = false
        end
        if matchKey(input.KeyCode, Config.AttackAim.Keybind) then
            Config.AttackAim.Holding = false
        end
    end
end)
Config.Connections.FakeParryKey = UserInputService.InputBegan:Connect(function(input, gp)
    if gp and UserInputService:GetFocusedTextBox() then return end
    if Config.FakeParry.Enabled and matchKey(input.KeyCode, Config.FakeParry.Keybind) then
        Fn.PlayFakeParry()
    end
end)
local function rebindAimButton(btn, cfg, state, keys)
    if state[keys.began] then state[keys.began]:Disconnect() end
    if state[keys.ended] then state[keys.ended]:Disconnect() end
    state[keys.began] = btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then cfg.Holding = true end
    end)
    state[keys.ended] = btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then cfg.Holding = false end
    end)
    state[keys.current] = btn
end
function Fn.createGameButton(config)
    config = config or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = config.Name or "GameButtonGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = config.IgnoreGuiInset == true
    gui.Parent = getProtectedGui()
    local btnType = config.ButtonType or "ImageButton"
    local btn = Instance.new(btnType)
    btn.Size = config.Size or UDim2.new(0, 50, 0, 50)
    btn.Position = config.Position or UDim2.new(0.65, 0, 0.6, 0)
    btn.AnchorPoint = config.AnchorPoint or Vector2.new(0, 0)
    btn.BackgroundColor3 = config.BackgroundColor3 or Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = config.BackgroundTransparency == nil
        and 0.9 or config.BackgroundTransparency
    if btnType == "ImageButton" then
        btn.Image = config.Image or ""
        btn.ImageTransparency = config.ImageTransparency == nil
            and 0.1 or config.ImageTransparency
    else
        btn.Text = config.Text or ""
        btn.TextColor3 = config.TextColor3 or Color3.fromRGB(255, 255, 255)
        btn.Font = config.Font or Enum.Font.GothamBold
        btn.TextSize = config.TextSize or 11
    end
    btn.Visible = config.Visible ~= false
    btn.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = config.CornerRadius or UDim.new(1, 0)
    corner.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1.2
    stroke.Color = config.StrokeColor or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = config.StrokeTransparency == nil
        and 0.8 or config.StrokeTransparency
    stroke.Parent = btn
    if config.OnClick then
        btn.MouseButton1Click:Connect(function() config.OnClick(stroke) end)
    end
    return gui, btn, stroke
end
local ASV_COLLECTION  = game:GetService("CollectionService")
local ASV_MAX_RETRIES = 10
local function ASV_Notify(msg)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title       = "Anti Slow Vault",
                Description = tostring(msg),
                Time        = 3,
            })
        end
    end)
end
local function ASV_InstallModuleHook()
    local cfg = Config.Movement.AntiSlowVault
    if cfg.ModuleHooked and cfg.ControllerRef then return true end
    local ok, result = pcall(function()
        local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
        if not Modules then return nil end
        local Survivors = Modules:WaitForChild("Survivors", 5)
        if not Survivors then return nil end
        local Controller = Survivors:WaitForChild("SurvivorAnimationsController", 5)
        if not Controller then return nil end
        return require(Controller)
    end)
    if not ok or not result or type(result) ~= "table" then
        return false
    end
    if cfg.ModuleHooked and cfg.ControllerRef == result then
        return true
    end
    cfg.ControllerRef = result
    cfg.OrigFuncs = {
        _isFacingStraightEnough = result._isFacingStraightEnough,
        _onVaultAnimation       = result._onVaultAnimation,
    }
    local orig_isFacingStraightEnough = cfg.OrigFuncs._isFacingStraightEnough
    local orig_onVaultAnimation       = cfg.OrigFuncs._onVaultAnimation

    result._isFacingStraightEnough = function(self, part1, part2, maxAngle)
        if Config.Movement.AntiSlowVault.Enabled then
            pcall(function() self.characterspeed = 20 end)
            return true, 0
        end
        if orig_isFacingStraightEnough then
            return orig_isFacingStraightEnough(self, part1, part2, maxAngle)
        end
        return true, 0
    end

    result._onVaultAnimation = function(self, vaultPoint, isSprinting)
        if Config.Movement.AntiSlowVault.Enabled then
            if orig_onVaultAnimation then
                return orig_onVaultAnimation(self, vaultPoint, true)
            end
            return
        end
        if orig_onVaultAnimation then
            return orig_onVaultAnimation(self, vaultPoint, isSprinting)
        end
    end

    cfg.ModuleHooked = true
    print("[Anti Slow Vault] Module hook installed")
    return true
end
Config.Connections.TeamChanged = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    Fn.setAimHoldingFromTeam(false)
    Fn.onTeamTransition()
end)
do
    local UIS         = UserInputService
    local notify      = Fn.notify
    local safeCall    = Fn.safeCall

    local function NextStackPosition()
        local cfg   = Config.ToggleIcons
        local size  = cfg.IconSize
        local gap   = cfg.Gap
        local idx   = cfg._stackCount
        cfg._stackCount = idx + 1
        local xOff = -cfg.AnchorXOffset - size
        local yOff = cfg.AnchorYOffset + idx * (size + gap)
        return UDim2.new(1, xOff, 0, yOff)
    end

    local function EnsureGui()
        local cfg = Config.ToggleIcons
        if cfg._gui and cfg._gui.Parent then return cfg._gui end
        local SG = Instance.new("ScreenGui")
        SG.Name = "FLNS_ToggleIcons"
        SG.ResetOnSpawn = false
        SG.IgnoreGuiInset = true
        SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        pcall(function() SG.Parent = getProtectedGui() end)
        if not SG.Parent then SG.Parent = PlayerGui end
        cfg._gui = SG
        Config.State.ToggleIconsGui = SG
        if not cfg._uisConn then
            cfg._uisConn = UIS.InputChanged:Connect(function(input, gp)
                if not cfg._activeDrag then return end
                if not cfg.Draggable then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                local data = cfg._icons[cfg._activeDrag]
                if not data or not data.root then return end
                local delta = input.Position - cfg._dragStart
                data.root.Position = UDim2.new(
                    cfg._dragStartPos.X.Scale, cfg._dragStartPos.X.Offset + delta.X,
                    cfg._dragStartPos.Y.Scale, cfg._dragStartPos.Y.Offset + delta.Y
                )
            end)
        end
        if not cfg._uisEndConn then
            cfg._uisEndConn = UIS.InputEnded:Connect(function(input, gp)
                if not cfg._activeDrag then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    local key = cfg._activeDrag
                    local data = cfg._icons[key]
                    if data and data.root then
                        cfg.Positions[key] = data.root.Position
                    end
                    cfg._activeDrag = nil
                    cfg._dragStart = nil
                    cfg._dragStartPos = nil
                end
            end)
        end
        return SG
    end

    local function RestackDefaults()
        local cfg = Config.ToggleIcons
        cfg._stackCount = 0
        local needSlot = {}
        for key, data in pairs(cfg._icons) do
            if not cfg.Positions[key] then
                table.insert(needSlot, { key = key, data = data })
            end
        end
        table.sort(needSlot, function(a, b)
            local sa = a.data.SortIndex or 0
            local sb = b.data.SortIndex or 0
            if sa ~= sb then return sa < sb end
            return a.key < b.key
        end)
        for _, entry in ipairs(needSlot) do
            local pos = NextStackPosition()
            if entry.data.root then
                entry.data.root.Position = pos
            end
        end
    end

    function Fn.updateToggleIconVisual(key)
        local cfg = Config.ToggleIcons
        local data = cfg._icons[key]
        if not data or not data.root then return end
        local isOn = false
        if type(data.GetState) == "function" then
            local ok, val = pcall(data.GetState)
            if ok then isOn = val and true or false end
        end
        local onColor  = data.ColorOn or Color3.fromRGB(80, 255, 120)
        local offColor = data.ColorOff or Color3.fromRGB(255, 255, 255)
        if data.stroke then
            data.stroke.Color = isOn and onColor or offColor
            data.stroke.Transparency = isOn and 0.1 or 0.6
        end
        if data.label then
            data.label.TextColor3 = isOn and onColor or Color3.fromRGB(235, 235, 240)
        end
        if data.root then
            data.root.BackgroundTransparency = isOn and 0.05 or 0.25
        end
    end

    function Fn.createToggleIcon(options)
        options = options or {}
        local key = options.Key
        if not key then return end
        local cfg = Config.ToggleIcons
        if cfg._icons[key] then
            safeCall("ToggleIcon:RemoveExisting:"..key, function()
                local data = cfg._icons[key]
                if data.root then data.root:Destroy() end
                for _, c in ipairs(data.conns or {}) do
                    pcall(function() c:Disconnect() end)
                end
            end)
            cfg._icons[key] = nil
        end
        local SG = EnsureGui()
        local iconSize = cfg.IconSize
        local bgColor  = Color3.fromRGB(20, 22, 27)
        local cornerRadius = UDim.new(0, math.floor(iconSize * 0.28))
        local IconRoot = Instance.new("Frame")
        IconRoot.Name = randomString()
        IconRoot.Parent = SG
        IconRoot.AnchorPoint = Vector2.new(1, 0)
        IconRoot.BackgroundColor3 = bgColor
        IconRoot.BackgroundTransparency = 0.25
        IconRoot.BorderSizePixel = 0
        IconRoot.Size = UDim2.fromOffset(iconSize, iconSize)
        IconRoot.ZIndex = 20
        IconRoot.ClipsDescendants = false
        local UICornerIcon = Instance.new("UICorner")
        UICornerIcon.CornerRadius = cornerRadius
        UICornerIcon.Parent = IconRoot
        local UIStrokeIcon = Instance.new("UIStroke")
        UIStrokeIcon.Color = options.ColorOff or Color3.fromRGB(255, 255, 255)
        UIStrokeIcon.Thickness = 1.5
        UIStrokeIcon.Transparency = 0.6
        UIStrokeIcon.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStrokeIcon.Parent = IconRoot
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Name = randomString()
        IconLabel.Parent = IconRoot
        IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        IconLabel.BackgroundTransparency = 1
        IconLabel.BorderSizePixel = 0
        IconLabel.Position = UDim2.fromScale(0.5, 0.5)
        IconLabel.Size = UDim2.fromScale(0.85, 0.85)
        IconLabel.ZIndex = 21
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.Text = options.Text or key:sub(1, 4):upper()
        IconLabel.TextScaled = true
        IconLabel.TextWrapped = true
        IconLabel.TextTransparency = 0
        IconLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Name = "ClickBtn"
        ClickBtn.Size = UDim2.fromScale(1, 1)
        ClickBtn.BackgroundTransparency = 1
        ClickBtn.Text = ""
        ClickBtn.ZIndex = 22
        ClickBtn.Parent = IconRoot
        local data = {
            root    = IconRoot,
            stroke  = UIStrokeIcon,
            label   = IconLabel,
            btn     = ClickBtn,
            conns   = {},
            GetState = options.GetState,
            ColorOn  = options.ColorOn,
            ColorOff = options.ColorOff,
            SortIndex = options.SortIndex or 0,
        }
        cfg._icons[key] = data
        local clickConn
        clickConn = ClickBtn.MouseButton1Click:Connect(function()
            local current = false
            if type(data.GetState) == "function" then
                local ok, val = pcall(data.GetState)
                if ok then current = val and true or false end
            end
            local newVal = not current
            if type(options.OnToggle) == "function" then
                safeCall("ToggleIcon:OnClick:"..key, function() options.OnToggle(newVal) end)
            end
            task.defer(function()
                Fn.updateToggleIconVisual(key)
            end)
        end)
        table.insert(data.conns, clickConn)
        local pressConn
        pressConn = ClickBtn.InputBegan:Connect(function(input)
            if not cfg.Draggable then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                cfg._activeDrag   = key
                cfg._dragStart    = input.Position
                cfg._dragStartPos = IconRoot.Position
            end
        end)
        table.insert(data.conns, pressConn)
        local releaseConn
        releaseConn = ClickBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if cfg._activeDrag == key then
                    local data2 = cfg._icons[key]
                    if data2 and data2.root then
                        cfg.Positions[key] = data2.root.Position
                    end
                    cfg._activeDrag = nil
                    cfg._dragStart = nil
                    cfg._dragStartPos = nil
                end
            end
        end)
        table.insert(data.conns, releaseConn)
        if cfg.Positions[key] then
            IconRoot.Position = cfg.Positions[key]
        else
            IconRoot.Position = UDim2.new(1, -cfg.AnchorXOffset - iconSize, 0, cfg.AnchorYOffset)
        end
        RestackDefaults()
        Fn.updateToggleIconVisual(key)
        return data
    end

    function Fn.removeToggleIcon(key)
        local cfg = Config.ToggleIcons
        local data = cfg._icons[key]
        if not data then return end
        if cfg._activeDrag == key then
            cfg._activeDrag = nil
            cfg._dragStart = nil
            cfg._dragStartPos = nil
        end
        safeCall("ToggleIcon:Remove:"..key, function()
            if data.root then data.root:Destroy() end
            for _, c in ipairs(data.conns or {}) do
                pcall(function() c:Disconnect() end)
            end
        end)
        cfg._icons[key] = nil
        RestackDefaults()
        local empty = true
        for _ in pairs(cfg._icons) do empty = false; break end
        if empty then
            if cfg._uisConn then
                pcall(function() cfg._uisConn:Disconnect() end)
                cfg._uisConn = nil
            end
            if cfg._uisEndConn then
                pcall(function() cfg._uisEndConn:Disconnect() end)
                cfg._uisEndConn = nil
            end
            if cfg._gui then
                pcall(function() cfg._gui:Destroy() end)
                cfg._gui = nil
            end
            Config.State.ToggleIconsGui = nil
            cfg._stackCount = 0
        end
    end

    function Fn.setToggleIconsDraggable(enabled)
        Config.ToggleIcons.Draggable = enabled and true or false
    end

    function Fn.createTargetIcon(opts)
        opts = opts or {}
        local key = opts.Key
        if not key then return end
        local cfg = Config.ToggleIcons
        if cfg._icons[key] then
            safeCall("TargetIcon:RemoveExisting:"..key, function()
                local data = cfg._icons[key]
                if data.root then data.root:Destroy() end
                for _, c in ipairs(data.conns or {}) do
                    pcall(function() c:Disconnect() end)
                end
            end)
            cfg._icons[key] = nil
        end
        local SG = EnsureGui()
        local iconSize = cfg.IconSize
        local bgColor  = Color3.fromRGB(20, 22, 27)
        local cornerRadius = UDim.new(0, math.floor(iconSize * 0.28))
        local IconRoot = Instance.new("Frame")
        IconRoot.Name = randomString()
        IconRoot.Parent = SG
        IconRoot.AnchorPoint = Vector2.new(1, 0)
        IconRoot.BackgroundColor3 = bgColor
        IconRoot.BackgroundTransparency = 0.20
        IconRoot.BorderSizePixel = 0
        IconRoot.Size = UDim2.fromOffset(iconSize, iconSize)
        IconRoot.ZIndex = 20
        IconRoot.ClipsDescendants = false
        local UICornerIcon = Instance.new("UICorner")
        UICornerIcon.CornerRadius = cornerRadius
        UICornerIcon.Parent = IconRoot
        local UIStrokeIcon = Instance.new("UIStroke")
        UIStrokeIcon.Color = Color3.fromRGB(255, 255, 255)
        UIStrokeIcon.Thickness = 1.5
        UIStrokeIcon.Transparency = 0.4
        UIStrokeIcon.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStrokeIcon.Parent = IconRoot
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Name = randomString()
        IconLabel.Parent = IconRoot
        IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        IconLabel.BackgroundTransparency = 1
        IconLabel.BorderSizePixel = 0
        IconLabel.Position = UDim2.fromScale(0.5, 0.5)
        IconLabel.Size = UDim2.fromScale(0.85, 0.85)
        IconLabel.ZIndex = 21
        IconLabel.Font = Enum.Font.GothamBold
        IconLabel.Text = "?"
        IconLabel.TextScaled = true
        IconLabel.TextWrapped = true
        IconLabel.TextTransparency = 0
        IconLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
        local ClickBtn = Instance.new("TextButton")
        ClickBtn.Name = "ClickBtn"
        ClickBtn.Size = UDim2.fromScale(1, 1)
        ClickBtn.BackgroundTransparency = 1
        ClickBtn.Text = ""
        ClickBtn.ZIndex = 22
        ClickBtn.Parent = IconRoot
        local data = {
            root    = IconRoot,
            stroke  = UIStrokeIcon,
            label   = IconLabel,
            btn     = ClickBtn,
            conns   = {},
            GetMode = opts.GetMode,
            SetMode = opts.SetMode,
            SortIndex = opts.SortIndex or 100,
        }
        cfg._icons[key] = data
        local clickConn
        clickConn = ClickBtn.MouseButton1Click:Connect(function()
            if type(data.SetMode) ~= "function" then return end
            local shared = Config.TargetIconShared
            local current = "?"
            if type(data.GetMode) == "function" then
                local ok, cur = pcall(data.GetMode); if ok then current = cur end
            end
            local idx = 1
            for i, v in ipairs(shared.ModeList) do
                if v == current then idx = i; break end
            end
            local nextIdx = (idx % #shared.ModeList) + 1
            local nextMode = shared.ModeList[nextIdx]
            safeCall("TargetIcon:Cycle:"..key, function()
                data.SetMode(nextMode)
            end)
            task.defer(function()
                Fn.updateTargetIconVisual(key)
            end)
        end)
        table.insert(data.conns, clickConn)
        local pressConn
        pressConn = ClickBtn.InputBegan:Connect(function(input)
            if not cfg.Draggable then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                cfg._activeDrag = key
                cfg._dragStart = input.Position
                cfg._dragStartPos = IconRoot.Position
            end
        end)
        table.insert(data.conns, pressConn)
        local releaseConn
        releaseConn = ClickBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if cfg._activeDrag == key then
                    local data2 = cfg._icons[key]
                    if data2 and data2.root then
                        cfg.Positions[key] = data2.root.Position
                    end
                    cfg._activeDrag = nil
                    cfg._dragStart = nil
                    cfg._dragStartPos = nil
                end
            end
        end)
        table.insert(data.conns, releaseConn)
        if cfg.Positions[key] then
            IconRoot.Position = cfg.Positions[key]
        else
            IconRoot.Position = UDim2.new(1, -cfg.AnchorXOffset - iconSize, 0, cfg.AnchorYOffset)
        end
        RestackDefaults()
        Fn.updateTargetIconVisual(key)
        return data
    end

    function Fn.updateTargetIconVisual(key)
        local cfg = Config.ToggleIcons
        local data = cfg._icons[key]
        if not data or not data.root then return end
        if type(data.GetMode) ~= "function" then return end
        local shared = Config.TargetIconShared
        local mode = "?"
        local ok, m = pcall(data.GetMode); if ok then mode = m end
        local label = shared.Labels[mode] or (mode and mode:sub(1, 1)) or "?"
        local color = shared.Colors[mode] or Color3.fromRGB(255, 255, 255)
        if data.label then
            data.label.Text = label
            data.label.TextColor3 = color
        end
        if data.stroke then
            data.stroke.Color = color
            data.stroke.Transparency = 0.2
        end
        if data.root then
            data.root.BackgroundTransparency = 0.15
        end
    end

    function Fn.createGunAimTargetIcon()
        return Fn.createTargetIcon({
            Key = "GunAimTargetIcon",
            SortIndex = 100,
            GetMode = function() return Config.GunAim.TargetMode end,
            SetMode = function(mode)
                Config.GunAim.TargetMode = mode
                pcall(function()
                    if Library and Library.SetDropdownValue then
                        Options.GunAimTarget:SetValue(mode)
                    end
                end)
            end,
        })
    end

    function Fn.createToFAimV1TargetIcon()
        return Fn.createTargetIcon({
            Key = "ToFAimV1TargetIcon",
            SortIndex = 102,
            GetMode = function()
                local m = Config.ToFAimV1.TargetMode
                return m == "Survivors" and "Survivor" or m
            end,
            SetMode = function(mode)
                local tofMode = mode == "Survivor" and "Survivors" or mode
                Config.ToFAimV1.TargetMode = tofMode
                Config.ToFAimV2.TargetMode = tofMode
                local iconMode = tofMode == "Survivors" and "Survivor" or tofMode
                Config.GunAim.TargetMode = iconMode
                if Fn.ToFV2_RefreshTargetButtons then Fn.ToFV2_RefreshTargetButtons() end
                pcall(function()
                    if Options and Options.ToFAimV1Target then
                        Options.ToFAimV1Target:SetValue(tofMode)
                    end
                end)
            end,
        })
    end

    function Fn.CycleToFTargetModeSync()
        local shared = Config.TargetIconShared
        local current = Config.ToFAimV1.TargetMode or "Killer"
        local idx = 1
        for i, v in ipairs(shared.ModeList) do
            local cur = current
            if cur == "Survivors" then cur = "Survivor" end
            if v == cur then idx = i; break end
        end
        local nextIdx = (idx % #shared.ModeList) + 1
        local nextMode = shared.ModeList[nextIdx]
        local tofMode = nextMode == "Survivor" and "Survivors" or nextMode
        Config.ToFAimV1.TargetMode = tofMode
        Config.ToFAimV2.TargetMode = tofMode
        local iconMode = tofMode == "Survivors" and "Survivor" or tofMode
        Config.GunAim.TargetMode = iconMode
        if Fn.ToFV2_RefreshTargetButtons then Fn.ToFV2_RefreshTargetButtons() end
        pcall(function()
            if Options and Options.ToFAimV1Target then
                Options.ToFAimV1Target:SetValue(tofMode)
            end
        end)
        Fn.updateTargetIconVisual("ToFAimV1TargetIcon")
        Fn.updateTargetIconVisual("GunAimTargetIcon")
        if notify then notify("ToF Target Sync", "Target: " .. tofMode, 1.5) end
    end

    function Fn.SetupToFTargetCycleKeybind(keybindValue)
        if Config.State.ToFTargetCycleKeybindConn then
            pcall(function() Config.State.ToFTargetCycleKeybindConn:Disconnect() end)
            Config.State.ToFTargetCycleKeybindConn = nil
        end
        if not keybindValue or keybindValue == "None" then
            return
        end
        local keyCode = keybindValue
        if type(keyCode) == "string" then
            keyCode = Enum.KeyCode[keyCode]
        end
        if not keyCode then return end
        Config.State.ToFTargetCycleKeybindConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == keyCode then
                safeCall("ToF Target Cycle Keybind", function()
                    Fn.CycleToFTargetModeSync()
                end)
            end
        end)
    end

    function Fn.createFlowstateToggleButton()
        Fn.createToggleIcon({
            Key       = "Flowstate",
            Text      = "FLOW",
            ColorOn   = Color3.fromRGB(255, 180, 60),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 1,
            GetState  = function() return Config.Flowstate.Enabled end,
            OnToggle  = function(v)
                Config.Flowstate.Enabled = v
                if v then Fn.startFlowstate() else Fn.stopFlowstate() end
                pcall(function() Toggles.FlowstateToggle:SetValue(v) end)
                if notify then notify("Flowstate", v and "Enabled" or "Disabled", 2) end
            end,
        })
        Config.State.FlowstateToggleButton = Config.ToggleIcons._icons.Flowstate and Config.ToggleIcons._icons.Flowstate.root or nil
    end
    function Fn.removeFlowstateToggleButton()
        Fn.removeToggleIcon("Flowstate")
        Config.State.FlowstateToggleButton = nil
    end

    function Fn.createSpeedBoostToggleButton()
        Fn.createToggleIcon({
            Key       = "SpeedBoost",
            Text      = "SPD",
            ColorOn   = Color3.fromRGB(80, 220, 255),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 2,
            GetState  = function() return Config.Movement.SpeedBoost.Enabled end,
            OnToggle  = function(v)
                Config.Movement.SpeedBoost.Enabled = v
                if v then Fn.applySpeedBoost() else Fn.disableSpeedBoost() end
                pcall(function() Toggles.SpeedBoostToggle:SetValue(v) end)
                if notify then notify("Speed Boost", v and "Enabled" or "Disabled", 2) end
            end,
        })
        Config.State.SpeedBoostToggleButton = Config.ToggleIcons._icons.SpeedBoost and Config.ToggleIcons._icons.SpeedBoost.root or nil
    end
    function Fn.removeSpeedBoostToggleButton()
        Fn.removeToggleIcon("SpeedBoost")
        Config.State.SpeedBoostToggleButton = nil
    end

    function Fn.createNoclipToggleButton()
        Fn.createToggleIcon({
            Key       = "Noclip",
            Text      = "CLIP",
            ColorOn   = Color3.fromRGB(255, 80, 120),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 3,
            GetState  = function() return Config.Noclip.Enabled end,
            OnToggle  = function(v)
                Fn.setNoclip(v)
                pcall(function() Toggles.NoclipToggle:SetValue(v) end)
            end,
        })
        Config.State.NoclipToggleButton = Config.ToggleIcons._icons.Noclip and Config.ToggleIcons._icons.Noclip.root or nil
    end
    function Fn.removeNoclipToggleButton()
        Fn.removeToggleIcon("Noclip")
        Config.State.NoclipToggleButton = nil
    end

    function Fn.createInvisibleToggleButton()
        Fn.createToggleIcon({
            Key       = "Invisible",
            Text      = "INVIS",
            ColorOn   = Color3.fromRGB(80, 180, 255),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 8,
            GetState  = function() return Config.Invisible.Enabled end,
            OnToggle  = function(v)
                local ok = pcall(function() Toggles.InvisibleToggle:SetValue(v) end)
                if not ok then Fn.setInvisible(v) end
            end,
        })
        Config.State.InvisibleToggleButton = Config.ToggleIcons._icons.Invisible and Config.ToggleIcons._icons.Invisible.root or nil
    end
    function Fn.removeInvisibleToggleButton()
        Fn.removeToggleIcon("Invisible")
        Config.State.InvisibleToggleButton = nil
    end

    function Fn.createFlyToggleButton()
        Fn.createToggleIcon({
            Key       = "Fly",
            Text      = "FLY",
            ColorOn   = Color3.fromRGB(120, 255, 120),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 4,
            GetState  = function() return Config.Fly.Enabled end,
            OnToggle  = function(v)
                Fn.setFly(v)
                pcall(function() Toggles.FlyEnabled:SetValue(v) end)
            end,
        })
        Config.State.FlyToggleButton = Config.ToggleIcons._icons.Fly and Config.ToggleIcons._icons.Fly.root or nil
    end
    function Fn.removeFlyToggleButton()
        Fn.removeToggleIcon("Fly")
        Config.State.FlyToggleButton = nil
    end

    function Fn.createFleeToggleButton()
        Fn.createToggleIcon({
            Key       = "Flee",
            Text      = "FLEE",
            ColorOn   = Color3.fromRGB(255, 120, 80),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 5,
            GetState  = function() return Config.Auto.Flee.Enabled end,
            OnToggle  = function(v)
                Config.Auto.Flee.Enabled = v
                pcall(function() Toggles.AutoFleeKiller:SetValue(v) end)
                if notify then notify("Auto Flee Killer", v and "Enabled" or "Disabled", 2) end
            end,
        })
        Config.State.FleeToggleButton = Config.ToggleIcons._icons.Flee and Config.ToggleIcons._icons.Flee.root or nil
    end
    function Fn.removeFleeToggleButton()
        Fn.removeToggleIcon("Flee")
        Config.State.FleeToggleButton = nil
    end

    function Fn.createAutoParryToggleButton()
        Fn.createToggleIcon({
            Key       = "AutoParry",
            Text      = "PARRY",
            ColorOn   = Color3.fromRGB(255, 215, 80),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 6,
            GetState  = function() return Config.Auto.Parry end,
            OnToggle  = function(v)
                Config.Auto.Parry = v
                if not v then
                    if Config.State.ParryCircle then
                        Config.State.ParryCircle:Destroy()
                        Config.State.ParryCircle = nil
                    end
                    Config.Auto.ParryVisual.Enabled = false
                    pcall(function() Toggles.ShowParryRange:SetValue(false) end)
                end
                pcall(function() Toggles.AutoParry:SetValue(v) end)
                if notify then notify("Auto Parry", v and "Enabled" or "Disabled", 2) end
            end,
        })
        Config.State.AutoParryToggleButton = Config.ToggleIcons._icons.AutoParry and Config.ToggleIcons._icons.AutoParry.root or nil
    end
    function Fn.removeAutoParryToggleButton()
        Fn.removeToggleIcon("AutoParry")
        Config.State.AutoParryToggleButton = nil
    end

    function Fn.createAutoBandageToggleButton()
        Fn.createToggleIcon({
            Key       = "AutoBandage",
            Text      = "BAND",
            ColorOn   = Color3.fromRGB(110, 255, 150),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 8,
            GetState  = function() return Config.Auto.Bandage and Config.Auto.Bandage.Auto or false end,
            OnToggle  = function(v)
                if v then Fn.startAutoBandage() else Fn.stopAutoBandage() end
                pcall(function() Toggles.AutoBandage:SetValue(v) end)
                if notify then notify("Auto Bandage", v and "Enabled" or "Disabled", 2) end
            end,
        })
        Config.State.AutoBandageToggleButton = Config.ToggleIcons._icons.AutoBandage and Config.ToggleIcons._icons.AutoBandage.root or nil
    end
    function Fn.removeAutoBandageToggleButton()
        Fn.removeToggleIcon("AutoBandage")
        Config.State.AutoBandageToggleButton = nil
    end

    function Fn.createInstantEscapeToggleButton()
        Fn.createToggleIcon({
            Key       = "InstantEscape",
            Text      = "ESC",
            ColorOn   = Color3.fromRGB(120, 255, 180),
            ColorOff  = Color3.fromRGB(255, 255, 255),
            SortIndex = 7,
            GetState  = function() return false end,
            OnToggle  = function(_v)
                task.defer(function() Fn.updateToggleIconVisual("InstantEscape") end)
                safeCall("InstantEscape Icon", function()
                    Fn.teleportToFinishLine()
                    if notify then notify("Instant Escape", "Teleported to finish line", 2) end
                end)
            end,
        })
        Config.State.InstantEscapeToggleButton = Config.ToggleIcons._icons.InstantEscape and Config.ToggleIcons._icons.InstantEscape.root or nil
    end
    function Fn.removeInstantEscapeToggleButton()
        Fn.removeToggleIcon("InstantEscape")
        Config.State.InstantEscapeToggleButton = nil
    end

    function Fn.unloadToggleIcons()
        pcall(function() Fn.removeFlowstateToggleButton() end)
        pcall(function() Fn.removeSpeedBoostToggleButton() end)
        pcall(function() Fn.removeNoclipToggleButton() end)
        pcall(function() Fn.removeFlyToggleButton() end)
        pcall(function() Fn.removeFleeToggleButton() end)
        pcall(function() Fn.removeAutoParryToggleButton() end)
        pcall(function() Fn.removeAutoBandageToggleButton() end)
        pcall(function() Fn.removeInstantEscapeToggleButton() end)
        pcall(function() Fn.removeToggleIcon("GunAimTargetIcon") end)
        pcall(function() Fn.removeToggleIcon("ToFAimV1TargetIcon") end)

        if Config.State and Config.State.ToFTargetCycleKeybindConn then
            pcall(function() Config.State.ToFTargetCycleKeybindConn:Disconnect() end)
            Config.State.ToFTargetCycleKeybindConn = nil
        end

        local cfg = Config.ToggleIcons
        if cfg then
            if cfg._uisConn then
                pcall(function() cfg._uisConn:Disconnect() end)
                cfg._uisConn = nil
            end
            if cfg._uisEndConn then
                pcall(function() cfg._uisEndConn:Disconnect() end)
                cfg._uisEndConn = nil
            end
            if cfg._gui then
                pcall(function() cfg._gui:Destroy() end)
                cfg._gui = nil
            end
            if type(cfg._icons) == "table" then
                for k in pairs(cfg._icons) do cfg._icons[k] = nil end
            end
            if type(cfg.Positions) == "table" then
                for k in pairs(cfg.Positions) do cfg.Positions[k] = nil end
            end
            cfg._stackCount   = 0
            cfg._activeDrag   = nil
            cfg._dragStart    = nil
            cfg._dragStartPos = nil
        end
        if Config.State then
            Config.State.ToggleIconsGui = nil
        end
    end
end
Shared.randomString          = randomString
Shared.getRoot               = getRoot
Shared.formatUsername        = formatUsername
Shared.getPlayer             = getPlayer
Shared.r15                   = r15
Shared.breakVelocity         = breakVelocity
Shared.getProtectedGui       = getProtectedGui
Shared.matchKey              = matchKey
Shared.rebindAimButton       = rebindAimButton
Shared.IsValidSticky         = IsValidSticky
Shared.ASV_Notify            = ASV_Notify
Shared.ASV_InstallModuleHook = ASV_InstallModuleHook
Shared.ASV_MAX_RETRIES       = ASV_MAX_RETRIES
Shared.ASV_COLLECTION        = ASV_COLLECTION
Shared.hookKillerIfKiller    = hookKillerIfKiller
Shared._V3_UP_3              = _V3_UP_3
Shared._V3_UP_0              = _V3_UP_0
Shared._predictScratchRay    = _predictScratchRay
Shared._predictScratchFilter = _predictScratchFilter
Shared._Invisible_GetRemote  = _Invisible_GetRemote
Fn._CharLook_EnsureHook      = _CharLook_EnsureHook
Fn.GetOldNamecall            = function() return oldNamecall end
Fn.SetOldNamecall            = function(v) oldNamecall = v end