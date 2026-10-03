local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Library            = Shared.Library
local UserInputService   = Shared.UserInputService
local Lighting           = Shared.Lighting
local LocalPlayer        = Shared.LocalPlayer
local Remotes            = Shared.Remotes
local AimSystem          = Shared.AimSystem
local ToFV1_State        = Shared.ToFV1_State
local ToFV2_State        = Shared.ToFV2_State
local FLNS_ToFState      = Shared.FLNS_ToFState
local ToFV1_DisconnectInputs = Shared.ToFV1_DisconnectInputs
local ToFV1_StopCache    = Shared.ToFV1_StopCache
local ToFV2_ClearLaser   = Shared.ToFV2_ClearLaser
local _Invisible_RestoreLocal = Shared._Invisible_RestoreLocal
local _animIdCache       = Shared._animIdCache
local WM_Destroy         = Shared.WM_Destroy
function Fn.unloadScript()
    Config.State.unloaded = true
    local _oldNamecall = Fn.GetOldNamecall and Fn.GetOldNamecall()
    if _oldNamecall then
        Fn.safeCall("Unload RestoreNamecall", function()
            hookmetamethod(game, "__namecall", _oldNamecall)
        end)
        if Fn.SetOldNamecall then Fn.SetOldNamecall(nil) end end
    Config.Killer.AntiBlind = false
    Config.Killer.BlockVaults = false
    Config.Killer.KillAll = false
    Config.Killer.Mods.AntiFall = false
    Config.Killer.Mods.GodMode = false
    Config.ToFAimV1.Enabled     = false
    Config.Movement.SpeedBoost.Enabled = false
    Config.Movement.Vault.Enabled = false
    Config.Movement.FakeFastVault.Enabled = false
    Config.Movement.AntiSlowVault.Enabled = false
    Config.Movement.SkillCheckSpeed.Enabled = false
    Config.Auto.Parry = false
    Config.Auto.PalletDrop = false
    Config.Auto.GenBoost.Enabled = false
    Config.Killer.Stalk.Enabled = false
    Config.Killer.BypassCooldown = false
    Config.Killer.NoCooldownHidden = false
    Config.Killer.M2Aimlock.Enabled = false
    Config.Killer.InfiniteLunge = false
    Config.Auto.Flee.Enabled = false
    Config.ESP.Survivor = false; Config.ESP.Killer = false; Config.ESP.Generator = false
    Config.ESP.Pallet = false; Config.ESP.Window = false; Config.ESP.SCP = false
    Config.ESPStatus.Enabled = false
    Config.Auto.ParryVisual.Enabled = false
    Config.VeilConfig.Enabled = false
    Config.GenBypass.Enabled = false
    Config.GenBypass._epoch = Config.GenBypass._epoch + 1
    Config.Auto.AutoCrouch.Enabled = false
    Config.Auto.SelfHeal.Enabled = false
    Config.Auto.Bandage.Auto = false
    Config.PredictMap.Enabled = false
    Config.NoCutscene = false
    Config.Visual.HideSurvivorIcon = false
    Config.Flowstate.Enabled = false
    Config.Invisible.Enabled = false
    Config.Fling.Enabled = false
    Config.Fling.Busy = false
    Config.Fling.Target = nil
    Config.Fling.TargetLabel = ""
    Config.SmoothCam.Enabled = false
    Fn.safeCall("Unload AutoCrouch",      function() Fn.stopAutoCrouch() end)
    Fn.safeCall("Unload SelfHeal",        function() Fn.teardownSelfHeal() end)
    Fn.safeCall("Unload AutoBandage",     function() Fn.stopAutoBandage() end)
    Fn.safeCall("Unload AutoStalk",       function() Fn.stopAutoStalk() end)
    Fn.safeCall("Unload NoCooldownHidden", function() Fn.StopNoCooldownHidden() end)
    Fn.safeCall("Unload M2Aimlock",        function() Fn.StopM2Aimlock() end)
    Fn.safeCall("Unload InfiniteLunge",   function() Fn.stopInfiniteLunge() end)
    Fn.safeCall("Unload GenBoost", function()
        local perksFolder = Remotes:FindFirstChild("Perks")
        local perfRemote = perksFolder and perksFolder:FindFirstChild("perfectionistplanning")
        if perfRemote then perfRemote:FireServer("clearBoost") end
    end)
    Fn.safeCall("Unload SkillCheck", function() Fn.stopSkillCheck() end)
    Fn.safeCall("Unload Flowstate",       function() Fn.stopFlowstate() end)
    Fn.safeCall("Unload ParryResultHook", function() Fn.TeardownParryResultHook() end)
    Fn.safeCall("Unload PredictMap",      function() Fn.StopPredictMap() end)
    Fn.safeCall("Unload HideSurvivorIcon", function() Fn.FLNS_SetHideSurvivorIcon(false) end)
    Fn.safeCall("Unload SmoothCam",      function() Fn.resetSmoothCamera() end)
    Fn.safeCall("Unload Invisible", function()
        local char = LocalPlayer.Character
        if char then
            _Invisible_RestoreLocal(char)
        end
        if Config.Invisible.CharConn then
            pcall(function() Config.Invisible.CharConn:Disconnect() end)
            Config.Invisible.CharConn = nil
        end
        if Config.Invisible.HookActive and Config.Invisible.OriginalFire then
            local remote = Config.Invisible.Remote
            if remote and remote.Parent and hookfunction then
                pcall(function()
                    hookfunction(remote.FireServer, Config.Invisible.OriginalFire)
                end)
            end
        end
        Config.Invisible.HookActive   = false
        Config.Invisible.OriginalFire = nil
        Config.Invisible.Remote       = nil
        Config.Invisible.ShowButton   = false
    end)
    Fn.safeCall("Unload Invisible ToggleIcon", function()
        Fn.removeInvisibleToggleButton()
    end)
    Fn.safeCall("Unload NoCutscene", function()
        if Config._NoCutsceneState then
            for _, c in ipairs(Config._NoCutsceneState.conns or {}) do
                pcall(function() c:Disconnect() end)
            end
            Config._NoCutsceneState.conns = {}
            if Config._NoCutsceneState.fakeBindable then
                pcall(function() Config._NoCutsceneState.fakeBindable:Destroy() end)
                Config._NoCutsceneState.fakeBindable = nil
            end
            if Config._NoCutsceneState.fakeRemote then
                pcall(function() Config._NoCutsceneState.fakeRemote:Destroy() end)
                Config._NoCutsceneState.fakeRemote = nil
            end
        end
        Config.NoCutsceneHooked = false
    end)
    if Config._HideSurvivorIconState and Config._HideSurvivorIconState.PlayerGuiConn then
        pcall(function() Config._HideSurvivorIconState.PlayerGuiConn:Disconnect() end)
        Config._HideSurvivorIconState.PlayerGuiConn = nil
    end
    for key, conn in pairs(Config.Connections) do
        Fn._destroyConn(key, conn)
        Config.Connections[key] = nil
    end
    for key, thr in pairs(Config.Threads) do
        Fn._destroyConn(key, thr)
        Config.Threads[key] = nil
    end
    if Config.State._skillCheckConn then
        Fn._destroyConn("SkillCheckConn", Config.State._skillCheckConn)
        Config.State._skillCheckConn = nil
    end
    if Config.State._parryCharConns then
        for plr, conn in pairs(Config.State._parryCharConns) do
            Fn._destroyConn("ParryCharConn", conn)
            Config.State._parryCharConns[plr] = nil
        end
    end
    if Config.State._parryPlayerAddedConn then
        Fn._destroyConn("ParryPlayerAdded", Config.State._parryPlayerAddedConn)
        Config.State._parryPlayerAddedConn = nil
    end
    for obj, h in pairs(Config.ESPCache.Objects) do
        if h then Fn.safeCall("Unload ESP", function() h:Destroy() end) end
    end
    for char, gui in pairs(Config.ESPCache.Status) do
        if gui then Fn.safeCall("Unload StatusESP", function() gui:Destroy() end) end
    end
    for char, gui in pairs(Config.ESPCache.InfoBillboards) do
        if gui then Fn.safeCall("Unload InfoBillboard", function() gui:Destroy() end) end
    end
    Config.ESPCache.Objects = {}; Config.ESPCache.ObjectVisuals = {}; Config.ESPCache.Status = {}; Config.ESPCache.SCP = {}
    Config.ESPCache.Generators = {}; Config.ESPCache.Windows = {}; Config.ESPCache.Pallets = {}
    Config.ESPCache.ItemImages = {}
    Config.ESPCache.InfoBillboards = {}
    Config.ESPCache.StatusStates = {}
    if Config.State.ParryCircle then Config.State.ParryCircle:Destroy(); Config.State.ParryCircle = nil; Config.State.ParryCircleBeams = nil; Config.State.ParryCircleAtts = nil; Config.State.ParryCircleCache = nil end
    if Config.State.ParryCircleFill then Config.State.ParryCircleFill:Destroy(); Config.State.ParryCircleFill = nil end
    Fn.stopEmote()
    Fn.removeMoonwalkButton()
    Fn.RemoveFakeParryButton()
    Fn.removeEmoteButton()
    Fn.safeCall("Unload ToggleIcons", Fn.unloadToggleIcons)
    Fn.CleanupStunNotification()
    if FLNS_ToFState._clearTask then
        pcall(function() task.cancel(FLNS_ToFState._clearTask) end)
        FLNS_ToFState._clearTask = nil
    end
    if FLNS_ToFState.LaserBeam then
        pcall(function() FLNS_ToFState.LaserBeam:Destroy() end)
        FLNS_ToFState.LaserBeam = nil
    end
    pcall(function()
        if ToFV2_State then
            ToFV2_ClearLaser()
        end
    end)
    pcall(function()
        if ToFV1_State then
            ToFV1_DisconnectInputs()
            ToFV1_StopCache()
        end
        if Config.ToFAimV1 then
            Config.ToFAimV1.BypassRestrictions = false
            Config.ToFAimV1.CachedShouldRedirect = false
            Config.ToFAimV1.CachedRedirectDir   = nil
            Config.ToFAimV1.CachedOriginPos     = nil
            Config.ToFAimV1.CachedTargetPos     = nil
        end
        local char = LocalPlayer.Character
        if char then char:SetAttribute("Aiming", false) end
    end)
    if Config.GenBypass.UI then
        pcall(function() Config.GenBypass.UI:Destroy() end)
        Config.GenBypass.UI = nil
    end
    if Config.VeilDraw.FOVCircle then Config.VeilDraw.FOVCircle.Visible = false end
    if Config.VeilDraw.Highlight then Config.VeilDraw.Highlight.Parent = nil end
    Config.NextKillerDisplay.Enabled = false
    Config.NextKillerDisplay.Label = nil
    Config.KillerPerksDisplay.Enabled = false
    Config.KillerPerksDisplay.Label = nil
    for k in pairs(Config.KillerPerksDisplay.PerkDatabase) do
        Config.KillerPerksDisplay.PerkDatabase[k] = nil
    end
    Fn.safeCall("Unload KillerPerks Watcher", Fn.stopKillerPerksWatcher)
    if Config.State.GunAimBeganConn then Config.State.GunAimBeganConn:Disconnect(); Config.State.GunAimBeganConn = nil end
    if Config.State.GunAimEndedConn then Config.State.GunAimEndedConn:Disconnect(); Config.State.GunAimEndedConn = nil end
    if Config.State.AttackAimBeganConn then Config.State.AttackAimBeganConn:Disconnect(); Config.State.AttackAimBeganConn = nil end
    if Config.State.AttackAimEndedConn then Config.State.AttackAimEndedConn:Disconnect(); Config.State.AttackAimEndedConn = nil end
    Fn.safeCall("Unload RestoreLighting", function()
        Lighting.Brightness     = Config.OriginalLighting.Brightness
        Lighting.ClockTime      = Config.OriginalLighting.ClockTime
        Lighting.Ambient        = Config.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = Config.OriginalLighting.OutdoorAmbient
        Lighting.GlobalShadows  = Config.OriginalLighting.GlobalShadows
    end)
    for obj, state in pairs(Config.DisabledEffects) do
        if obj and obj.Parent then
            Fn.safeCall("Unload RestoreEffects", function() obj.Enabled = state end)
        end
    end
    for k in pairs(Config.DisabledEffects) do Config.DisabledEffects[k] = nil end
    Fn.safeCall("Unload RestoreMovement", function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        if char then
            char:SetAttribute("speedboost", 1)
        end
    end)
    Fn.safeCall("Unload RestoreCamera", function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = Config.CameraZoom.DefaultFOV end
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
    end)
    Fn.safeCall("Unload RestoreQuality", function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    Fn.stopParryHook()
    Fn.disableVault()
    Fn.disableFakeFastVault()
    Fn.disableAntiSlowVault(true)
    Fn.disableSkillCheckSpeed()
    if Config.Noclip.Enabled then
        Fn.safeCall("Unload Noclip", function() Fn.setNoclip(false) end)
    end
    for k in pairs(Config.VaultTracks) do Config.VaultTracks[k] = nil end
    if Config.ESPCache.AncestryConns then
        for obj, conn in pairs(Config.ESPCache.AncestryConns) do
            if typeof(conn) == "RBXScriptConnection" then
                Fn.safeCall("Unload ESP AncestryConn", function() conn:Disconnect() end)
            end
            Config.ESPCache.AncestryConns[obj] = nil
        end
    end
    for k in pairs(Config.LastVisualState) do Config.LastVisualState[k] = nil end
    for k in pairs(Config.LastOptimizationState) do Config.LastOptimizationState[k] = nil end
    Fn.safeCall("Unload RestoreSkies", function()
        for sky, parent in pairs(Config.DisabledSkies) do
            if sky and parent then sky.Parent = parent end
        end
    end)
    for k in pairs(Config.DisabledSkies) do Config.DisabledSkies[k] = nil end
    Fn.safeCall("Unload RestoreClouds", function()
        for clouds, parent in pairs(Config.DisabledClouds) do
            if clouds and parent then clouds.Parent = parent end
        end
    end)
    for k in pairs(Config.DisabledClouds) do Config.DisabledClouds[k] = nil end
    Fn.safeCall("Unload RestoreTextures", function()
        for sa, parent in pairs(Config.DisabledTextures) do
            if sa and parent then sa.Parent = parent end
        end
    end)
    for k in pairs(Config.DisabledTextures) do Config.DisabledTextures[k] = nil end
    Fn.safeCall("Unload Fly", Fn.unloadFly)
    Fn.safeCall("Unload JerkTool", function() Fn.stopJerkTool() end)
    Fn.safeCall("Unload Veil", function()
        if Config.VeilState.cooldownHandle then
            pcall(function() task.cancel(Config.VeilState.cooldownHandle) end)
            Config.VeilState.cooldownHandle = nil
        end
        if Config.VeilDraw.FOVCircle then
            pcall(function() Config.VeilDraw.FOVCircle:Remove() end)
            Config.VeilDraw.FOVCircle = nil
        end
        if Config.VeilDraw.TrajectoryFolder then
            pcall(function() Config.VeilDraw.TrajectoryFolder:Destroy() end)
            Config.VeilDraw.TrajectoryFolder = nil
        end
        Config.VeilDraw.TrajectoryBeams = {}
        Config.VeilDraw.TrajectoryAttachments = {}
        if Config.VeilDraw.HitCircle then
            pcall(function() Config.VeilDraw.HitCircle.Visible = false end)
            pcall(function() Config.VeilDraw.HitCircle:Remove() end)
            Config.VeilDraw.HitCircle = nil
        end
        if Config.VeilDraw.HitMarker then
            pcall(function() Config.VeilDraw.HitMarker:Destroy() end)
            Config.VeilDraw.HitMarker = nil
        end
        if Config.VeilDraw.Highlight then
            pcall(function() Config.VeilDraw.Highlight:Destroy() end)
            Config.VeilDraw.Highlight = nil
        end
        if Config.VeilVelocityCache then
            for k in pairs(Config.VeilVelocityCache) do
                Config.VeilVelocityCache[k] = nil
            end
        end
        if Config.ToFVelocityCache and Config.ToFVelocityCache.Entries then
            for k in pairs(Config.ToFVelocityCache.Entries) do
                Config.ToFVelocityCache.Entries[k] = nil
            end
        end
        Config.VeilState.chargingSpear = false
        Config.VeilState.firing = false
        Config.VeilState.attackCooldown = false
        Config.VeilState.lastTrajectoryHit = nil
    end)
    Fn.safeCall("Unload AimSpear Trajectory", function()
        if not Config.AttackAimTrajectory then return end
        if Config.AttackAimTrajectory.Folder then
            pcall(function() Config.AttackAimTrajectory.Folder:Destroy() end)
            Config.AttackAimTrajectory.Folder = nil
        end
        Config.AttackAimTrajectory.Beams = {}
        Config.AttackAimTrajectory.Attachments = {}
        if Config.AttackAimTrajectory.HitCircle then
            pcall(function() Config.AttackAimTrajectory.HitCircle.Visible = false end)
            pcall(function() Config.AttackAimTrajectory.HitCircle:Remove() end)
            Config.AttackAimTrajectory.HitCircle = nil
        end
        if Config.AttackAimTrajectory.HitMarker then
            pcall(function() Config.AttackAimTrajectory.HitMarker:Destroy() end)
            Config.AttackAimTrajectory.HitMarker = nil
        end
    end)
    Fn.safeCall("Unload AimSystem", function() AimSystem.cleanup() end)
    Fn.safeCall("Unload Watermark", function() WM_Destroy() end)
    Fn.safeCall("Unload MenuToggleButton", function() Fn.removeMenuToggleButton() end)
    Fn.safeCall("Unload RestoreMouse", function()
        local uis_restore = game:GetService("UserInputService")
        local savedB = getgenv().FALLENS_InitMouseB
        local savedI = getgenv().FALLENS_InitMouseI
        if savedB ~= nil then uis_restore.MouseBehavior = savedB end
        if savedI ~= nil then uis_restore.MouseIconEnabled = savedI end
    end)
    Fn.safeCall("Unload Crosshair", function() Fn.clearCrosshair() end)
    if _animIdCache then
        for k in pairs(_animIdCache) do _animIdCache[k] = nil end
    end
    Fn.safeCall("Unload MusicPlayer", Fn.unloadMusicPlayer)
    Fn.safeCall("Unload AvatarChanger", Fn.unloadAvatarChanger)
    Fn.safeCall("Unload parryVisual", function() Fn.parryVisual_reset() end)
    pcall(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end)
    pcall(function() Library:Unload() end)
    getgenv().FALLENS_Loaded = false
    getgenv().FALLENS_Unload = nil
end