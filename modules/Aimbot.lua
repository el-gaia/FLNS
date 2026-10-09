local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Options            = Shared.Options
local UI                 = Shared.UI
local Players            = Shared.Players
local UserInputService   = Shared.UserInputService
local RunService         = Shared.RunService
local ReplicatedStorage  = Shared.ReplicatedStorage
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
local Remotes            = Shared.Remotes
local ToFFireRemote      = Shared.ToFFireRemote
local fast_tick          = Shared.fast_tick
local rebindAimButton    = Shared.rebindAimButton
local IsValidSticky      = Shared.IsValidSticky
local _V3_UP_3           = Shared._V3_UP_3
local _V3_UP_0           = Shared._V3_UP_0
local _predictScratchRay = Shared._predictScratchRay
local _predictScratchFilter = Shared._predictScratchFilter

local FLNS_ToFState = {
    LaserBeam   = nil,
    _clearTask  = nil,
}

local _vdFovOk, _vdFovCircle = pcall(function()
    return Drawing and Drawing.new and Drawing.new("Circle")
end)
Config.VeilDraw = {
    FOVCircle = _vdFovOk and _vdFovCircle or nil,
    Highlight = Instance.new("Highlight")
}
if Config.VeilDraw.FOVCircle then
    Config.VeilDraw.FOVCircle.Color     = Color3.fromRGB(255, 255, 255)
    Config.VeilDraw.FOVCircle.Thickness = 1.5
    Config.VeilDraw.FOVCircle.Filled    = false
    Config.VeilDraw.FOVCircle.Visible   = false
end
Config.VeilDraw.Highlight.Name                = "VD_VeilTarget"
Config.VeilDraw.Highlight.FillColor           = Color3.fromRGB(255, 0, 0)
Config.VeilDraw.Highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
Config.VeilDraw.Highlight.FillTransparency    = 0.5
Config.VeilDraw.Highlight.OutlineTransparency = 0

Config.VeilDraw.TrajectoryBeams       = {}
Config.VeilDraw.TrajectoryAttachments = {}
Config.VeilDraw.TrajectoryFolder      = nil
Config.VeilDraw.HitCircle = nil
Config.VeilDraw.HitMarker  = nil
function Veil_EnsureTrajectoryFolder()
    local existing = Config.VeilDraw.TrajectoryFolder
    if existing and existing.Parent then
        return existing
    end
    pcall(function()
        local _old = workspace.Terrain:FindFirstChild("VeilTrajectory")
            or workspace:FindFirstChild("VeilTrajectory")
        if _old then _old:Destroy() end
    end)
    local folder = Instance.new("Folder")
    folder.Name = "VeilTrajectory"
    local _parented = pcall(function()
        folder.Parent = workspace.Terrain
    end)
    if not _parented then
        folder.Parent = workspace
    end
    local atts, beams = {}, {}
    for _ai = 1, 16 do
        local att = Instance.new("Attachment")
        att.Name = "Att_" .. _ai
        att.Parent = folder
        atts[_ai] = att
    end
    for _bi = 1, 15 do
        local beam = Instance.new("Beam")
        beam.Attachment0 = atts[_bi]
        beam.Attachment1 = atts[_bi + 1]
        beam.Width0 = 0.12
        beam.Width1 = 0.12
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255))
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Texture = "rbxassetid://4740112440"
        beam.TextureSpeed = 2
        beam.Enabled = false
        beam.Parent = folder
        beams[_bi] = beam
    end
    Config.VeilDraw.TrajectoryAttachments = atts
    Config.VeilDraw.TrajectoryBeams = beams
    Config.VeilDraw.TrajectoryFolder = folder
    return folder
end
do
    local _cok, _circle = pcall(function() return Drawing and Drawing.new("Circle") end)
    if _cok and _circle then
        _circle.Radius     = 10
        _circle.Thickness  = 2
        _circle.Filled     = false
        _circle.Color      = Color3.fromRGB(0, 255, 120)
        _circle.Visible    = false
        Config.VeilDraw.HitCircle = _circle
    else
        local marker = Instance.new("Part")
        marker.Name = "VeilHitMarker"
        marker.Shape = Enum.PartType.Ball
        marker.Material = Enum.Material.Neon
        marker.Color = Color3.fromRGB(0, 255, 120)
        marker.Size = Vector3.new(0.8, 0.8, 0.8)
        marker.Transparency = 0.3
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanQuery = false
        marker.CanTouch = false
        marker.CastShadow = false
        marker.Parent = nil
        Config.VeilDraw.HitMarker = marker
    end
    pcall(Veil_EnsureTrajectoryFolder)
end

Config.AttackAimTrajectory = {
    Folder       = nil,
    Beams        = {},
    Attachments  = {},
    HitCircle    = nil,
    HitMarker    = nil,
}
function AimSpear_EnsureTrajectoryFolder()
    local existing = Config.AttackAimTrajectory.Folder
    if existing and existing.Parent then
        return existing
    end
    pcall(function()
        local _old = workspace.Terrain:FindFirstChild("AimSpearTrajectory")
            or workspace:FindFirstChild("AimSpearTrajectory")
        if _old then _old:Destroy() end
    end)
    local folder = Instance.new("Folder")
    folder.Name = "AimSpearTrajectory"
    local _parented = pcall(function()
        folder.Parent = workspace.Terrain
    end)
    if not _parented then
        folder.Parent = workspace
    end
    local atts, beams = {}, {}
    for _ai = 1, 16 do
        local att = Instance.new("Attachment")
        att.Name = "Att_" .. _ai
        att.Parent = folder
        atts[_ai] = att
    end
    for _bi = 1, 15 do
        local beam = Instance.new("Beam")
        beam.Attachment0 = atts[_bi]
        beam.Attachment1 = atts[_bi + 1]
        beam.Width0 = 0.12
        beam.Width1 = 0.12
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(0, 220, 255))
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.Texture = "rbxassetid://4740112440"
        beam.TextureSpeed = 2
        beam.Enabled = false
        beam.Parent = folder
        beams[_bi] = beam
    end
    Config.AttackAimTrajectory.Attachments = atts
    Config.AttackAimTrajectory.Beams = beams
    Config.AttackAimTrajectory.Folder = folder
    return folder
end
do
    local _aok, _acircle = pcall(function() return Drawing and Drawing.new("Circle") end)
    if _aok and _acircle then
        _acircle.Radius     = 10
        _acircle.Thickness  = 2
        _acircle.Filled     = false
        _acircle.Color      = Color3.fromRGB(0, 255, 120)
        _acircle.Visible    = false
        Config.AttackAimTrajectory.HitCircle = _acircle
    else
        local marker = Instance.new("Part")
        marker.Name = "AimSpearHitMarker"
        marker.Shape = Enum.PartType.Ball
        marker.Material = Enum.Material.Neon
        marker.Color = Color3.fromRGB(0, 255, 120)
        marker.Size = Vector3.new(0.8, 0.8, 0.8)
        marker.Transparency = 0.3
        marker.Anchored = true
        marker.CanCollide = false
        marker.CanQuery = false
        marker.CanTouch = false
        marker.CastShadow = false
        marker.Parent = nil
        Config.AttackAimTrajectory.HitMarker = marker
    end
    pcall(AimSpear_EnsureTrajectoryFolder)
end

local AimSystem = {}
AimSystem.modes = {
    { Name = "ToFV1",     config = function() return Config.ToFAimV1     end, kind = "SilentAim" },
    { Name = "Veil",      config = function() return Config.VeilConfig   end, kind = "SpearSilent" },
    { Name = "GunAim",    config = function() return Config.GunAim       end, kind = "CameraLock" },
    { Name = "AttackAim", config = function() return Config.AttackAim    end, kind = "AttackLock" },
}
AimSystem._sharedLaser = nil
AimSystem._sharedLaserTask = nil
function AimSystem.getActiveMode()
    for i = 1, #AimSystem.modes do
        local entry = AimSystem.modes[i]
        local cfg = entry.config()
        if cfg and cfg.Enabled == true then
            return entry
        end
    end
    return nil
end
function AimSystem.isLaserInUse()
    local mode = AimSystem.getActiveMode()
    if not mode then return false end
    local cfg = mode.config()
    if cfg.ShowLaser == true then return true end
    if cfg.ShowFOV == true and mode.Name == "Veil" then return true end
    return false
end
function AimSystem.coordinateLaser(showFn, gunPos, targetPos)
    pcall(function()
        if AimSystem._sharedLaserTask then
            pcall(function() task.cancel(AimSystem._sharedLaserTask) end)
            AimSystem._sharedLaserTask = nil
        end
        if showFn then showFn(gunPos, targetPos) end
    end)
end
function AimSystem.cleanup()
    pcall(function()
        Config.ToFAimV1.Enabled = false
        Config.GunAim.Enabled = false
        Config.AttackAim.Enabled = false
        Config.VeilConfig.Enabled = false
        Config.GunAim.Holding = false
        Config.GunAim.Target = nil
        Config.AttackAim.Holding = false
        Config.VeilState.chargingSpear = false
        Config.VeilState.firing = false
        Config.VeilState.attackCooldown = false
        if Config.VeilState.cooldownHandle then
            pcall(function() task.cancel(Config.VeilState.cooldownHandle) end)
            Config.VeilState.cooldownHandle = nil
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
        if FLNS_ToFState and FLNS_ToFState._clearTask then
            pcall(function() task.cancel(FLNS_ToFState._clearTask) end)
            FLNS_ToFState._clearTask = nil
        end
        if FLNS_ToFState and FLNS_ToFState.LaserBeam then
            pcall(function() FLNS_ToFState.LaserBeam:Destroy() end)
            FLNS_ToFState.LaserBeam = nil
        end
        if Config.VeilDraw and Config.VeilDraw.FOVCircle then
            pcall(function() Config.VeilDraw.FOVCircle.Visible = false end)
        end
        if Config.VeilDraw and Config.VeilDraw.Highlight then
            pcall(function() Config.VeilDraw.Highlight.Parent = nil end)
        end
        if AimSystem._sharedLaserTask then
            pcall(function() task.cancel(AimSystem._sharedLaserTask) end)
            AimSystem._sharedLaserTask = nil
        end
        AimSystem._sharedLaser = nil
        if Veil_SpearHookTask then
            pcall(function() task.cancel(Veil_SpearHookTask) end)
            Veil_SpearHookTask = nil
        end
        if Config.VeilCooldownSamples then
            for i = 1, #Config.VeilCooldownSamples do Config.VeilCooldownSamples[i] = nil end
        end
        Config.VeilLastFireTime = 0
        Config.VeilState.realSpearCooldown = nil
        Config.VeilState.oldMakeMoveCooldown = nil
        if Config.VeilState.oldSpearFireServer and Config.VeilState.spearRemote then
            pcall(function()
                if restorefunction then
                    restorefunction(Config.VeilState.oldSpearFireServer)
                elseif hookfunction then
                    hookfunction(Config.VeilState.spearRemote.FireServer, Config.VeilState.oldSpearFireServer)
                end
            end)
        end
        Config.VeilState.oldSpearFireServer = nil
        Config.VeilState.spearRemote        = nil
    end)
end
getgenv().AimSystem = AimSystem

function Fn.setAimHoldingFromTeam(state)
    if Fn.canUseGunAim() then
        Config.GunAim.Holding = state
        Config.AttackAim.Holding = false
    elseif Fn.canUseAttackAim() then
        Config.AttackAim.Holding = state
        Config.GunAim.Holding = false
    else
        Config.GunAim.Holding = false
        Config.AttackAim.Holding = false
        Config.GunAim.Target = nil
    end
end

local function FLNS_ToFUpdateLaser(originPos, targetPos)
    if not FLNS_ToFState.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name = "ToFLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CanQuery = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 50, 50)
        laser.Parent = workspace
        FLNS_ToFState.LaserBeam = laser
    end
    local dist = (targetPos - originPos).Magnitude
    if dist < 0.01 then dist = 0.01 end
    FLNS_ToFState.LaserBeam.Size = Vector3.new(0.08, 0.08, dist)
    FLNS_ToFState.LaserBeam.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
    FLNS_ToFState.LaserBeam.Transparency = 0
end
local function FLNS_ToFClearLaser()
    if FLNS_ToFState.LaserBeam then
        pcall(function() FLNS_ToFState.LaserBeam:Destroy() end)
        FLNS_ToFState.LaserBeam = nil
    end
end
local function ToF_GetRealVelocity(part, smoothingOverride)
    if not part then return Vector3.zero end
    local currentPos = part.Position
    local currentTime = fast_tick()
    local entries = Config.ToFVelocityCache.Entries
    local entry = entries[part]
    if not entry then
        entry = { samples = {}, writeIdx = 1, count = 0, smoothedVel = Vector3.zero }
        entries[part] = entry
    end
    local samples = entry.samples
    local writeIdx = entry.writeIdx
    local sample = samples[writeIdx]
    if not sample then
        sample = {}
        samples[writeIdx] = sample
    end
    sample.t = currentTime
    sample.pos = currentPos
    entry.writeIdx = (writeIdx % 128) + 1
    entry.count = math.min(entry.count + 1, 128)
    if entry.count < 2 then
        return entry.smoothedVel
    end
    local targetTime = currentTime - Config.ToFVelocityCache.WindowSec
    local maxAge = Config.ToFVelocityCache.MaxSampleAge
    local bestSample = nil
    local bestDiff = math.huge
    for i = 1, entry.count do
        local s = samples[i]
        local age = currentTime - s.t
        if age > 0 and age <= maxAge then
            local diff = math.abs(s.t - targetTime)
            if diff < bestDiff then
                bestDiff = diff
                bestSample = s
            end
        end
    end
    if not bestSample then return entry.smoothedVel end
    local dt = currentTime - bestSample.t
    if dt < 0.01 then
        return entry.smoothedVel
    end
    local rawVelocity = (currentPos - bestSample.pos) / dt
    if rawVelocity.Magnitude > Config.ToFVelocityCache.MaxSaneVelocity then
        return entry.smoothedVel
    end
    local alpha = smoothingOverride or Config.ToFVelocityCache.Smoothing or 0.35
    if alpha < 0 then alpha = 0 elseif alpha > 1 then alpha = 1 end
    entry.smoothedVel = entry.smoothedVel:Lerp(rawVelocity, alpha)
    return entry.smoothedVel
end
local function ToF_ClearVelocityCache(part)
    if part then
        Config.ToFVelocityCache.Entries[part] = nil
    else
        for k in pairs(Config.ToFVelocityCache.Entries) do
            Config.ToFVelocityCache.Entries[k] = nil
        end
    end
end
local ToFV2_State = {
    Connection   = nil,
    LaserBeam    = nil,
    TargetGui    = nil,
    InputBegan   = nil,
    InputEnded   = nil,
    TouchInput   = nil,
    IsAiming     = false,
    SavedUIPos   = UDim2.new(0.5, -120, 0, 110),
    SCPCache     = {},
    SCPCacheTimer= 0,
}
local function ToFV2_GetEvent()
    if ToFFireRemote then return ToFFireRemote end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local items   = remotes and remotes:FindFirstChild("Items")
    local tof     = items and items:FindFirstChild("Twist of Fate")
    local fire    = tof and tof:FindFirstChild("Fire")
    if fire and fire:IsA("RemoteEvent") then return fire end
    return nil
end
local function ToFV2_GetGunObject()
    local char = LocalPlayer.Character
    if not char then return nil end
    local baseToF = char:FindFirstChild("Twist of Fate", true)
    if not baseToF then return nil end
    local rightArm = baseToF:FindFirstChild("Right Arm")
    if rightArm then
        local gunPart = rightArm:FindFirstChild("gun")
        if gunPart then return gunPart end
        local emperorGun = rightArm:FindFirstChild("EmperorGun")
        if emperorGun then return emperorGun end
    end
    return baseToF
end
local function ToFV2_GetSCPs()
    if fast_tick() - ToFV2_State.SCPCacheTimer < 0.5 then
        return ToFV2_State.SCPCache
    end
    local newTargets = {}
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        for _, container in pairs(mapFolder:GetDescendants()) do
            if container:IsA("Model") then
                local attributes = container:GetAttributes()
                if container:GetAttribute("CorpseCreated0492") or next(attributes) ~= nil then
                    local root = container:FindFirstChild("HumanoidRootPart")
                    if root then table.insert(newTargets, root) end
                end
            end
        end
    end
    ToFV2_State.SCPCache = newTargets
    ToFV2_State.SCPCacheTimer = fast_tick()
    return ToFV2_State.SCPCache
end
local function ToF_PredictTarget(originPos, gunObj, bulletSpeed, aimConfig, torso, targetCharacter, laserBeam)
    local targetPos = torso.Position
    local rootPart = targetCharacter and (targetCharacter:FindFirstChild("HumanoidRootPart") or torso)
    local hum = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    local isFalling = hum and (hum:GetState() == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air)
    local targetVel = _V3_UP_0
    if rootPart then
        local smoothing = aimConfig.VelSmoothing or Config.ToFVelocityCache.Smoothing
        local realVel = ToF_GetRealVelocity(rootPart, smoothing)
        if isFalling then
            targetVel = realVel
        else
            targetVel = Vector3.new(realVel.X, 0, realVel.Z)
        end
    end
    local directionRaw = targetPos - originPos
    local distance = directionRaw.Magnitude
    if distance < 0.1 then return nil, nil, nil, nil end
    if distance < 5 then return directionRaw.Unit, gunObj, originPos, targetPos end
    local travelTime   = distance / bulletSpeed
    local predictedPos = targetPos
    local leadMult = aimConfig.PredictStrength or 1.0
    for _ = 1, 2 do
        if isFalling then
            local gravityDrop = 0.5 * workspace.Gravity * (travelTime * travelTime)
            predictedPos = targetPos + (targetVel * travelTime * leadMult) - Vector3.new(0, gravityDrop, 0)
        else
            predictedPos = targetPos + (targetVel * travelTime * leadMult)
        end
        local newDist = (predictedPos - originPos).Magnitude
        travelTime    = newDist / bulletSpeed
    end
    if isFalling then
        _predictScratchFilter[1] = targetCharacter
        _predictScratchFilter[2] = LocalPlayer.Character
        if laserBeam then
            _predictScratchFilter[3] = laserBeam
        else
            _predictScratchFilter[3] = nil
        end
        _predictScratchRay.FilterDescendantsInstances = _predictScratchFilter
        local feetPos = targetPos - _V3_UP_3
        local predictedFeet = predictedPos - _V3_UP_3
        local floorHit = workspace:Raycast(feetPos, predictedFeet - feetPos, _predictScratchRay)
        if floorHit then
            predictedPos = floorHit.Position + _V3_UP_3
        end
    end
    local finalDirection = predictedPos - originPos
    if finalDirection.Magnitude < 0.1 then return nil, nil, nil, nil end
    return finalDirection.Unit, gunObj, originPos, predictedPos
end
local function ToFV2_UpdateLaser(originPos, targetPos)
    if not ToFV2_State.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name        = "ToFV2Laser"
        laser.Anchored    = true
        laser.CanCollide  = false
        laser.CanTouch    = false
        laser.CanQuery    = false
        laser.CastShadow  = false
        laser.Material    = Enum.Material.Neon
        laser.Color       = Color3.fromRGB(255, 50, 50)
        laser.Parent      = workspace
        ToFV2_State.LaserBeam = laser
    end
    local dist = (targetPos - originPos).Magnitude
    if dist < 0.01 then dist = 0.01 end
    ToFV2_State.LaserBeam.Size    = Vector3.new(0.08, 0.08, dist)
    ToFV2_State.LaserBeam.CFrame  = CFrame.new((originPos + targetPos) / 2, targetPos)
    ToFV2_State.LaserBeam.Transparency = 0
end
local function ToFV2_ClearLaser()
    if ToFV2_State.LaserBeam then
        pcall(function() ToFV2_State.LaserBeam:Destroy() end)
        ToFV2_State.LaserBeam = nil
    end
end
local function ToFV2_GetMobileShootButton()
    local playerGui   = LocalPlayer:FindFirstChild("PlayerGui")
    local survivorMob = playerGui and playerGui:FindFirstChild("Survivor-mob")
    local controls    = survivorMob and survivorMob:FindFirstChild("Controls")
    local guiMob      = controls and controls:FindFirstChild("Gui-mob")
    if not guiMob then return nil end
    local directNames = { "attack", "Attack", "shoot", "Shoot", "fire", "Fire" }
    for _, name in ipairs(directNames) do
        local btn = guiMob:FindFirstChild(name, true)
        if btn and btn:IsA("GuiObject") then return btn end
    end
    for _, obj in ipairs(guiMob:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible then return obj end
    end
    return guiMob:IsA("GuiObject") and guiMob or nil
end
local function ToFV2_IsTouchOnShootButton(input)
    local shootButton = ToFV2_GetMobileShootButton()
    if not (shootButton and shootButton.Visible) then return false end
    local pos     = input.Position
    local absPos  = shootButton.AbsolutePosition
    local absSize = shootButton.AbsoluteSize
    return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
       and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
end
local function ToFV2_RefreshTargetButtons()
end
getgenv().ToFV2_ClearLaser      = ToFV2_ClearLaser
local ToFV1_State = {
    InputBegan    = nil,
    InputEnded    = nil,
    TouchInput    = nil,
    CacheConn     = nil,
    IsAiming      = false,
    SCPCache      = {},
    SCPCacheTimer = 0,
    BypassInputBegan = nil,
    BypassInputEnded = nil,
    BypassTouchInput = nil,
    BypassFiring    = false,
    BypassLastShot  = 0,
}
local function ToFV1_GetGunObject()
    return ToFV2_GetGunObject()
end
local function ToFV1_GetSCPs()
    return ToFV2_GetSCPs()
end
local function ToFV1_GetTargetPosition()
    local gunObj = ToFV1_GetGunObject()
    local char   = LocalPlayer.Character
    if not (gunObj and char) then return nil, nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil, nil end
    local myPos = hrp.Position
    local originPos
    if char:GetAttribute("IsCarried") then
        originPos = hrp.Position + (hrp.CFrame.LookVector * 2)
    else
        pcall(function()
            originPos = gunObj:IsA("BasePart") and gunObj.Position
                or (gunObj:FindFirstChildOfClass("BasePart") and gunObj:FindFirstChildOfClass("BasePart").Position)
        end)
        originPos = originPos or Vector3.new(myPos.X, myPos.Y + 1.5, myPos.Z)
    end
    local bulletSpeed = Config.ToFAimV1.BulletSpeed or 400
    local aimConfig = Config.ToFAimV1
    local laserBeam = ToFV2_State and ToFV2_State.LaserBeam or nil
    local function predictTarget(torso, targetCharacter)
        return ToF_PredictTarget(originPos, gunObj, bulletSpeed, aimConfig, torso, targetCharacter, laserBeam)
    end
    local targetMode = Config.ToFAimV1.TargetMode or "Killer"
    local aimPartName = Config.ToFAimV1.AimPart or "HumanoidRootPart"
    if targetMode == "Killer" then
        local closestTorso, closestChar, shortestDist = nil, nil, math.huge
        for _, player in ipairs(Config.ESPCache.PlayerList) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Killer" and player.Character then
                local torso = player.Character:FindFirstChild(aimPartName)
                    or player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local isDowned = Fn.checkDowned(player.Character)
                if torso and hum and hum.Health > 0 and not isDowned then
                    local dist = (myPos - torso.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestTorso = torso
                        closestChar  = player.Character
                    end
                end
            end
        end
        if not closestTorso then return nil, nil, nil, nil end
        return predictTarget(closestTorso, closestChar)
    elseif targetMode == "Survivors" then
        local bestTorso, bestChar, bestDot = nil, nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector
        for _, player in ipairs(Config.ESPCache.PlayerList) do
            if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
                local torso = player.Character:FindFirstChild(aimPartName)
                    or player.Character:FindFirstChild("Torso")
                    or player.Character:FindFirstChild("UpperTorso")
                    or player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local isDowned = Fn.checkDowned(player.Character)
                if torso and hum and hum.Health > 0 and not isDowned then
                    local dirToTarget = torso.Position - cam.CFrame.Position
                    if dirToTarget.Magnitude > 0.1 then
                        local dot = camLook:Dot(dirToTarget.Unit)
                        if dot > 0.5 and dot > bestDot then
                            bestDot   = dot
                            bestTorso = torso
                            bestChar  = player.Character
                        end
                    end
                end
            end
        end
        if not bestTorso then return nil, nil, nil, nil end
        return predictTarget(bestTorso, bestChar)
    elseif targetMode == "SCP" then
        local bestPart, bestDot = nil, -math.huge
        local cam = workspace.CurrentCamera
        local camLook = cam.CFrame.LookVector
        for _, root in ipairs(ToFV1_GetSCPs()) do
            if root and root.Parent then
                local dirToTarget = root.Position - cam.CFrame.Position
                if dirToTarget.Magnitude > 0.1 then
                    local dot = camLook:Dot(dirToTarget.Unit)
                    if dot > 0.5 and dot > bestDot then
                        bestDot  = dot
                        bestPart = root
                    end
                end
            end
        end
        if not bestPart then return nil, nil, nil, nil end
        return predictTarget(bestPart, bestPart.Parent)
    end
    return nil, nil, nil, nil
end
local function ToFV1_UpdateCache()
    if not Config.ToFAimV1.Enabled then
        Config.ToFAimV1.CachedShouldRedirect = false
        Config.ToFAimV1.CachedRedirectDir   = nil
        Config.ToFAimV1.CachedOriginPos     = nil
        Config.ToFAimV1.CachedTargetPos     = nil
        return
    end
    local direction, gunObj, originPos, targetPos = ToFV1_GetTargetPosition()
    if direction and originPos and targetPos then
        Config.ToFAimV1.CachedShouldRedirect = true
        Config.ToFAimV1.CachedRedirectDir   = direction
        Config.ToFAimV1.CachedOriginPos     = originPos
        Config.ToFAimV1.CachedTargetPos     = targetPos
        if Config.ToFAimV1.ShowLaser and ToFV1_State.IsAiming then
            pcall(function() ToFV2_UpdateLaser(originPos, targetPos) end)
        elseif Config.ToFAimV1.ShowLaser and ToFV2_State.LaserBeam then
            ToFV2_State.LaserBeam.Transparency = 1
        end
    else
        Config.ToFAimV1.CachedShouldRedirect = false
        Config.ToFAimV1.CachedRedirectDir   = nil
        Config.ToFAimV1.CachedOriginPos     = nil
        Config.ToFAimV1.CachedTargetPos     = nil
        if Config.ToFAimV1.ShowLaser and ToFV2_State.LaserBeam then
            ToFV2_State.LaserBeam.Transparency = 1
        end
    end
end
local function ToFV1_StartCache()
    if ToFV1_State.CacheConn then return end
    local _acc = 0
    ToFV1_State.CacheConn = RunService.Heartbeat:Connect(function(dt)
        if not Config.ToFAimV1.Enabled then
            if ToFV1_State._wasEnabled then
                ToFV1_UpdateCache()
                ToFV1_State._wasEnabled = false
            end
            return
        end
        ToFV1_State._wasEnabled = true
        _acc = _acc + dt
        if _acc < 1/30 then return end
        _acc = 0
        ToFV1_UpdateCache()
    end)
end
local function ToFV1_StopCache()
    if ToFV1_State.CacheConn then
        pcall(function() ToFV1_State.CacheConn:Disconnect() end)
        ToFV1_State.CacheConn = nil
    end
    Config.ToFAimV1.CachedShouldRedirect = false
    Config.ToFAimV1.CachedRedirectDir   = nil
    Config.ToFAimV1.CachedOriginPos     = nil
    Config.ToFAimV1.CachedTargetPos     = nil
    ToFV2_ClearLaser()
end
local function ToFV1_IsTouchOnShootButton(input)
    return ToFV2_IsTouchOnShootButton(input)
end
local function ToFV1_IsRestricted()
    local char = LocalPlayer.Character
    if not char then return true end
    if LocalPlayer:GetAttribute("IsDead") then return true end
    if char:GetAttribute("IsCarried") then return true end
    if char:GetAttribute("IsHooked") then return true end
    if char:GetAttribute("Knocked") then return true end
    return false
end
local function ToFV1_DoBypassShoot()
    if not Config.ToFAimV1.Enabled then return end
    if not Config.ToFAimV1.BypassRestrictions then return end
    if not ToFV1_IsRestricted() then return end
    local gunObj = ToFV1_GetGunObject()
    if not gunObj then return end
    local direction = Config.ToFAimV1.CachedRedirectDir
    local originPos = Config.ToFAimV1.CachedOriginPos
    local targetPos = Config.ToFAimV1.CachedTargetPos
    if not (direction and originPos and targetPos) then
        local freshDir, freshGun, freshOrigin, freshTarget = ToFV1_GetTargetPosition()
        if not (freshDir and freshOrigin and freshTarget) then return end
        direction, gunObj, originPos, targetPos = freshDir, freshGun, freshOrigin, freshTarget
    end
    local tofEvent = ToFV2_GetEvent()
    if not tofEvent then return end
    pcall(function()
        tofEvent:FireServer(gunObj, direction)
    end)
    if Config.ToFAimV1.ShowLaser then
        pcall(function() ToFV2_UpdateLaser(originPos, targetPos) end)
    end
end
local function ToFV1_EnsureBypassInputs()
    if not Config.ToFAimV1.BypassRestrictions then return end
    if not ToFV1_State.BypassInputBegan then
        ToFV1_State.BypassInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not Config.ToFAimV1.Enabled then return end
            if not Config.ToFAimV1.BypassRestrictions then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or (input.UserInputType == Enum.UserInputType.Touch and ToFV1_IsTouchOnShootButton(input)) then
                if input.UserInputType == Enum.UserInputType.Touch then
                    ToFV1_State.BypassTouchInput = input
                end
                ToFV1_DoBypassShoot()
            end
        end)
    end
    if not ToFV1_State.BypassInputEnded then
        ToFV1_State.BypassInputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and input == ToFV1_State.BypassTouchInput then
                ToFV1_State.BypassTouchInput = nil
            end
        end)
    end
end
local function ToFV1_DisconnectBypassInputs()
    if ToFV1_State.BypassInputBegan then pcall(function() ToFV1_State.BypassInputBegan:Disconnect() end) end
    if ToFV1_State.BypassInputEnded then pcall(function() ToFV1_State.BypassInputEnded:Disconnect() end) end
    ToFV1_State.BypassInputBegan = nil
    ToFV1_State.BypassInputEnded = nil
    ToFV1_State.BypassTouchInput = nil
end
local function ToFV1_EnsureInputs()
    if not ToFV1_State.InputBegan then
        ToFV1_State.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not Config.ToFAimV1.Enabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2
            or (input.UserInputType == Enum.UserInputType.Touch and ToFV1_IsTouchOnShootButton(input)) then
                ToFV1_State.IsAiming = true
                if input.UserInputType == Enum.UserInputType.Touch then
                    ToFV1_State.TouchInput = input
                end
                local char = LocalPlayer.Character
                if char then char:SetAttribute("Aiming", true) end
            end
        end)
    end
    if not ToFV1_State.InputEnded then
        ToFV1_State.InputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2
            or (input.UserInputType == Enum.UserInputType.Touch and input == ToFV1_State.TouchInput) then
                ToFV1_State.IsAiming = false
                if input == ToFV1_State.TouchInput then ToFV1_State.TouchInput = nil end
                local char = LocalPlayer.Character
                if char then char:SetAttribute("Aiming", false) end
                if Config.ToFAimV1.ShowLaser
                   and ToFV2_State.LaserBeam then
                    ToFV2_State.LaserBeam.Transparency = 1
                end
            end
        end)
    end
end
local function ToFV1_DisconnectInputs()
    if ToFV1_State.InputBegan then pcall(function() ToFV1_State.InputBegan:Disconnect() end) end
    if ToFV1_State.InputEnded then pcall(function() ToFV1_State.InputEnded:Disconnect() end) end
    ToFV1_State.InputBegan = nil
    ToFV1_State.InputEnded = nil
    ToFV1_State.TouchInput = nil
    ToFV1_State.IsAiming = false
    ToFV1_DisconnectBypassInputs()
end
local ToFV1_SetSilentAim
ToFV1_SetSilentAim = function(enabled)
    Config.ToFAimV1.Enabled = enabled and true or false
    ToFV1_EnsureInputs()
    ToFV1_EnsureBypassInputs()
    if Config.ToFAimV1.Enabled then
        ToFV1_StartCache()
    else
        ToFV1_StopCache()
        local char = LocalPlayer.Character
        if char then char:SetAttribute("Aiming", false) end
    end
end
local function ToFV1_SetBypassRestrictions(enabled)
    Config.ToFAimV1.BypassRestrictions = enabled and true or false
    if Config.ToFAimV1.BypassRestrictions then
        ToFV1_EnsureBypassInputs()
    else
        ToFV1_DisconnectBypassInputs()
    end
end
local function ToFV1_SetTargetMode(modeName)
    if modeName ~= "Killer" and modeName ~= "Survivors" and modeName ~= "SCP" then return end
    Config.ToFAimV1.TargetMode = modeName
end
getgenv().ToFV1_SetSilentAim        = ToFV1_SetSilentAim
getgenv().ToFV1_SetTargetMode    = ToFV1_SetTargetMode
getgenv().ToFV1_SetBypassRestrictions = ToFV1_SetBypassRestrictions
getgenv().ToFV1_UpdateCache      = ToFV1_UpdateCache
getgenv().ToFV1_GetState         = function() return ToFV1_State end
ToFV1_EnsureInputs()

local Veil_SpearHookTask = nil
local function Veil_InitSpearFireServerHook()
    if Config.VeilState.oldSpearFireServer then return true end
    if not hookfunction then return false end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return false end
    local killers = remotes:FindFirstChild("Killers")
    if not killers then return false end
    local veil = killers:FindFirstChild("Veil")
    if not veil then return false end
    local spear = veil:FindFirstChild("Spearthrow")
    if not spear then return false end
    Config.VeilState.spearRemote = spear
    local ok = pcall(function()
        Config.VeilState.oldSpearFireServer = hookfunction(spear.FireServer, function(...)
            local self = ...
            if rawequal(self, spear)
               and Config.VeilConfig and Config.VeilConfig.Enabled
               and Config.VeilState and not Config.VeilState.firing then
                return nil
            end
            return Config.VeilState.oldSpearFireServer(...)
        end)
    end)
    return ok and Config.VeilState.oldSpearFireServer ~= nil
end
Veil_SpearHookTask = task.spawn(function()
    if Veil_InitSpearFireServerHook() then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        remotes = ReplicatedStorage:WaitForChild("Remotes", 8)
    end
    if not remotes then return end
    local killers = remotes:FindFirstChild("Killers") or remotes:WaitForChild("Killers", 5)
    if not killers then return end
    local veil = killers:FindFirstChild("Veil") or killers:WaitForChild("Veil", 5)
    if not veil then return end
    local spear = veil:FindFirstChild("Spearthrow") or veil:WaitForChild("Spearthrow", 5)
    if not spear then return end
    Veil_InitSpearFireServerHook()
end)
Config.VeilCooldownSamples = {}
Config.VeilLastFireTime = 0
function Fn.Veil_RecordCooldownSample(fireTime, resetTime)
    local delta = resetTime - fireTime
    if delta <= 0 or delta > 10 then return end
    local samples = Config.VeilCooldownSamples
    samples[#samples + 1] = delta
    if #samples > 3 then
        table.remove(samples, 1)
    end
    local sum = 0
    for i = 1, #samples do sum = sum + samples[i] end
    Config.VeilState.realSpearCooldown = sum / #samples
end
function Fn.Veil_GetEffectiveCooldown()
    return Config.VeilState.realSpearCooldown or 1.2
end

function Fn.getClosestGunTarget()
    return Fn.getClosestTarget(Config.GunAim.TargetMode, Config.GunAim.AimPart, Config.GunAim.FOV, Config.GunAim.VisibilityCheck)
end
function Fn.getClosestAttackTarget()
    return Fn.getClosestTarget("Survivor", Config.AttackAim.AimPart, Config.AttackAim.FOV, Config.AttackAim.VisibilityCheck)
end
function Fn.SpearAimbotCalcEx(targetPart)
    local root = Fn.getRoot()
    if not root then return nil end
    if not targetPart then return nil end
    local myChar    = LocalPlayer.Character
    local startPos  = root.Position + Vector3.new(0, 2, 0)
    local targetPos = targetPart.Position
    local spearSpeed, gravity, aimPos, travelTime
    if Config.AttackAim.Spear.SmartPredict then
        spearSpeed, gravity = Veil_GetSmartParams(myChar)
        local targetPlayer = Players:GetPlayerFromCharacter(targetPart.Parent)
        local velocity
        if targetPlayer then
            velocity = Veil_GetRealVelocity(targetPart, targetPlayer.Name)
        else
            velocity = targetPart.AssemblyLinearVelocity
        end
        if velocity.Magnitude <= 1.5 then velocity = Vector3.zero end
        aimPos, travelTime = Veil_SolveProjectile(startPos, targetPos, velocity, spearSpeed, gravity, 3)
    else
        spearSpeed = math.max(Config.AttackAim.Spear.Speed or 100, 20)
        travelTime = (targetPos - startPos).Magnitude / spearSpeed
        if Config.AttackAim.Predict then
            local rawVel = targetPart.AssemblyLinearVelocity
            if rawVel.Magnitude > 1.5 then
                targetPos = targetPos + (rawVel * travelTime)
                travelTime = (targetPos - startPos).Magnitude / spearSpeed
            end
        end
        gravity = Config.AttackAim.Spear.Gravity or 50
        local drop = 0.5 * gravity * travelTime * travelTime
        aimPos = targetPos + Vector3.new(0, drop, 0)
    end
    return {
        aimPos      = aimPos,
        startPos    = startPos,
        spearSpeed  = spearSpeed,
        gravity     = gravity,
        travelTime  = travelTime,
        targetPart  = targetPart,
    }
end
function Fn.SpearAimbotCalc(targetPart)
    local res = Fn.SpearAimbotCalcEx(targetPart)
    if not res then return nil end
    return res.aimPos
end
function Fn.getClosestSpearTarget()
    return Fn.getClosestTarget("Survivor", Config.AttackAim.Spear.AimPart, Config.AttackAim.Spear.FOV, false)
end
function Fn.getClosestAttackTargetOmni()
    local root = Fn.getRoot()
    if not root then return nil end
    local cfg = Config.AttackAim
    local range = cfg.Range or 250
    local aimPart = cfg.AimPart or "HumanoidRootPart"
    local closest, shortest = nil, range
    local playerList = Config.ESPCache.PlayerList
    for i = 1, #playerList do
        local p = playerList[i]
        if p ~= LocalPlayer and p.Character and p.Team and p.Team.Name == "Survivors" then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(aimPart)
                          or p.Character:FindFirstChild("HumanoidRootPart")
            if hum and part and hum.Health > 0
               and not Fn.checkDowned(p.Character)
               and not p.Character:GetAttribute("IsCarried") then
                if not cfg.VisibilityCheck or Fn.isVisible(part) then
                    local d = (part.Position - root.Position).Magnitude
                    if d < shortest then
                        shortest = d; closest = part
                    end
                end
            end
        end
    end
    return closest
end
function Fn.getClosestSpearTargetOmni()
    local root = Fn.getRoot()
    if not root then return nil end
    local cfg = Config.AttackAim
    local range = cfg.Range or 250
    local aimPart = cfg.Spear.AimPart or "HumanoidRootPart"
    local closest, shortest = nil, range
    local playerList = Config.ESPCache.PlayerList
    for i = 1, #playerList do
        local p = playerList[i]
        if p ~= LocalPlayer and p.Character and p.Team and p.Team.Name == "Survivors" then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(aimPart)
                          or p.Character:FindFirstChild("HumanoidRootPart")
            if hum and part and hum.Health > 0
               and not Fn.checkDowned(p.Character)
               and not p.Character:GetAttribute("IsCarried") then
                local d = (part.Position - root.Position).Magnitude
                if d < shortest then
                    shortest = d; closest = part
                end
            end
        end
    end
    return closest
end
function Fn.startGunAim()
    if Config.Connections.GunAim then return end
    Config.Connections.GunAim = Config.FakeConnection(Config.RenderSteppedTasks, "GunAim", function(dt)
        dt = dt or (1 / 60)
        if not Config.GunAim.Enabled then
            Config.GunAim.Target = nil
            FLNS_ToFClearLaser()
            return
        end
        if not Fn.canUseGunAim() then
            Config.GunAim.Target = nil
            Config.GunAim.Holding = false
            FLNS_ToFClearLaser()
            return
        end
        if not Config.GunAim.Holding then
            Config.GunAim.Target = nil
            FLNS_ToFClearLaser()
            return
        end
        if Config.GunAim.ShowButton and Config.State.GunAimTargetButton then
            local btn = Config.State.GunAimTargetButton:FindFirstChild("TargetButton")
            if btn then
                local color = Config.GunAim.Colors[Config.GunAim.TargetMode] or Color3.fromRGB(255, 255, 255)
                btn.Text = "Target: " .. Config.GunAim.TargetMode
                btn.TextColor3 = color
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = color end
            end
        end
        local cam    = workspace.CurrentCamera
        local target = Fn.getClosestGunTarget()
        if not target then
            Config.GunAim.Target = nil
            FLNS_ToFClearLaser()
            return
        end
        Config.GunAim.Target = target
        local pos = target.Position
        if Config.GunAim.Predict then
            local targetChar = target.Parent
            local rootPart   = (targetChar and targetChar:FindFirstChild("HumanoidRootPart")) or target
            local hum        = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
            local isFalling  = hum and (hum:GetState() == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air)
            local smoothing  = Config.GunAim.VelSmoothing or Config.ToFVelocityCache.Smoothing
            local realVel    = ToF_GetRealVelocity(rootPart, smoothing)
            local targetVel  = isFalling and realVel or Vector3.new(realVel.X, 0, realVel.Z)
            local dist       = (target.Position - cam.CFrame.Position).Magnitude
            local bulletSpd  = math.max(Config.GunAim.BulletSpeed or 200, 50)
            local travelTime = dist / bulletSpd
            local leadMult   = Config.GunAim.PredictStrength or 1.0
            local predictedPos = pos
            for _ = 1, 2 do
                if isFalling then
                    local gravityDrop = 0.5 * workspace.Gravity * (travelTime * travelTime)
                    predictedPos = pos + (targetVel * travelTime * leadMult) - Vector3.new(0, gravityDrop, 0)
                else
                    predictedPos = pos + (targetVel * travelTime * leadMult)
                end
                local newDist = (predictedPos - cam.CFrame.Position).Magnitude
                travelTime    = newDist / bulletSpd
            end
            if isFalling and targetChar then
                _predictScratchFilter[1] = targetChar
                _predictScratchFilter[2] = LocalPlayer.Character
                if FLNS_ToFState and FLNS_ToFState.LaserBeam then
                    _predictScratchFilter[3] = FLNS_ToFState.LaserBeam
                else
                    _predictScratchFilter[3] = nil
                end
                _predictScratchRay.FilterDescendantsInstances = _predictScratchFilter
                local feetPos      = pos - _V3_UP_3
                local predictedFeet = predictedPos - _V3_UP_3
                local floorHit = workspace:Raycast(feetPos, predictedFeet - feetPos, _predictScratchRay)
                if floorHit then
                    predictedPos = floorHit.Position + _V3_UP_3
                end
            end
            pos = predictedPos
        end
        local rawStrength = Config.GunAim.Strength or 1
        local lerpAlpha = (rawStrength >= 1) and 1 or (1 - math.exp(-rawStrength * 15 * dt))
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, pos), lerpAlpha)
        if Config.GunAim.ShowLaser then
            local gunPos
            if Config.GunAim._cachedGunPart and Config.GunAim._cachedGunPart.Parent then
                Fn.safeCall("GunAim Laser GunPos", function()
                    gunPos = Config.GunAim._cachedGunPart.Position
                end)
            end
            if not gunPos and cam then
                gunPos = cam.CFrame.Position + (cam.CFrame.LookVector * 2)
            end
            if gunPos then
                Fn.safeCall("GunAim Laser Show", function()
                    FLNS_ToFUpdateLaser(gunPos, pos)
                end)
                if FLNS_ToFState._clearTask then
                    pcall(function() task.cancel(FLNS_ToFState._clearTask) end)
                    FLNS_ToFState._clearTask = nil
                end
            end
        else
            FLNS_ToFClearLaser()
        end
    end)
end
local AttackAim_StickyTarget = nil
local AttackAim_Highlight = Instance.new("Highlight")
AttackAim_Highlight.Name = "AttackAim_StickyHighlight"
AttackAim_Highlight.FillColor = Color3.fromRGB(255, 0, 0)
AttackAim_Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
AttackAim_Highlight.FillTransparency = 0.5
AttackAim_Highlight.OutlineTransparency = 0
AttackAim_Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

function Fn.startAttackAim()
    if Config.Connections.AttackAim then return end
    Config.Connections.AttackAim = Config.FakeConnection(Config.RenderSteppedTasks, "AttackAim", function(dt)
        dt = dt or (1 / 60)
        if not Config.AttackAim.Enabled or not Fn.canUseAttackAim() or not Config.AttackAim.Holding then
            if not Fn.canUseAttackAim() then Config.AttackAim.Holding = false end
            AttackAim_StickyTarget = nil
            AttackAim_Highlight.Parent = nil
            AimSpear_HideTrajectory()
            return
        end
        local _now = fast_tick()
        if _now - (Config.AttackAim._lastUpdate or 0) < 1/60 then return end
        Config.AttackAim._lastUpdate = _now
        local cam = workspace.CurrentCamera
        if not cam then return end
        local rawStrength = math.clamp(Config.AttackAim.Strength or 1, 0.05, 1)
        local lerpAlpha = (rawStrength >= 1) and 1 or (1 - math.exp(-rawStrength * 15 * dt))
        if Config.State.AttackAimMode == "Spear" then
            if not IsValidSticky(AttackAim_StickyTarget) then
                if Config.AttackAim.LockBehindChar then
                    AttackAim_StickyTarget = Fn.getClosestSpearTargetOmni()
                else
                    AttackAim_StickyTarget = Fn.getClosestSpearTarget()
                end
            end
            local target = AttackAim_StickyTarget
            if not target then
                AttackAim_Highlight.Parent = nil
                AimSpear_HideTrajectory()
                return
            end
            AttackAim_Highlight.Parent = Config.AttackAim.UseHighlight and target.Parent or nil
            local aimRes = Fn.SpearAimbotCalcEx(target)
            if not aimRes then
                AimSpear_HideTrajectory()
                return
            end
            local aimPos = aimRes.aimPos
            local goalCF = CFrame.new(cam.CFrame.Position, aimPos)
            cam.CFrame = cam.CFrame:Lerp(goalCF, lerpAlpha)
            if Config.AttackAim.Spear.ShowTrajectory then
                AimSpear_DrawTrajectory({
                    startPos     = aimRes.startPos,
                    aimDir       = (aimPos - aimRes.startPos).Unit,
                    spearSpeed   = aimRes.spearSpeed,
                    gravity      = aimRes.gravity,
                    travelTime   = aimRes.travelTime,
                    predictedPos = aimPos,
                    targetPart   = target,
                })
            else
                AimSpear_HideTrajectory()
            end
        else
            if not IsValidSticky(AttackAim_StickyTarget) then
                if Config.AttackAim.LockBehindChar then
                    AttackAim_StickyTarget = Fn.getClosestAttackTargetOmni()
                else
                    AttackAim_StickyTarget = Fn.getClosestAttackTarget()
                end
            end
            local target = AttackAim_StickyTarget
            if not target then
                AttackAim_Highlight.Parent = nil
                AimSpear_HideTrajectory()
                return
            end
            AttackAim_Highlight.Parent = Config.AttackAim.UseHighlight and target.Parent or nil
            local pos = target.Position
            if Config.AttackAim.Predict then
                pos = pos + (target.AssemblyLinearVelocity * Config.AttackAim.PredictStrength)
            end
            local goalCF = CFrame.new(cam.CFrame.Position, pos)
            cam.CFrame = cam.CFrame:Lerp(goalCF, lerpAlpha)
            AimSpear_HideTrajectory()
        end
    end)
end

Config.Threads.AimButtonRebind = task.spawn(function()
    while not Config.State.unloaded do
        task.wait(1)
        local gunBtn = Fn.getGuiByPath("Survivor-mob.Controls.Gui-mob")
        if not gunBtn then
            Config.State.CurrentGunButton = nil
        elseif gunBtn ~= Config.State.CurrentGunButton then
            rebindAimButton(gunBtn, Config.GunAim, Config.State, {
                current = "CurrentGunButton",
                began   = "GunAimBeganConn",
                ended   = "GunAimEndedConn",
            })
        end
        local atkBtn = Fn.getGuiByPaths(Config.AttackPaths)
        if atkBtn and atkBtn ~= Config.State.CurrentAttackButton then
            rebindAimButton(atkBtn, Config.AttackAim, Config.State, {
                current = "CurrentAttackButton",
                began   = "AttackAimBeganConn",
                ended   = "AttackAimEndedConn",
            })
        end
    end
end)

function Fn.clearCrosshair()
    for _, v in pairs(Config.CrosshairDrawings) do if v.Remove then v:Remove() end end
    for k in pairs(Config.CrosshairDrawings) do Config.CrosshairDrawings[k] = nil end
end
function Fn.drawCrosshair()
    if not Config.Crosshair.Enabled then
        for _, v in pairs(Config.CrosshairDrawings) do if v then v.Visible = false end end
        return
    end
    if not (Drawing and Drawing.new) then return end
    if Config.State.LastCrosshairStyle ~= Config.Crosshair.Style then
        Fn.clearCrosshair(); Config.State.created = false
        Config.State.LastCrosshairStyle = Config.Crosshair.Style
    end
    local cam = workspace.CurrentCamera
    local center = Vector2.new(
        cam.ViewportSize.X / 2 + Config.Crosshair.OffsetX,
        cam.ViewportSize.Y / 2 + Config.Crosshair.OffsetY
    )
    if not Config.State.created then
        Config.State.created = true
        if Config.Crosshair.Style == "Plus" then
            for i = 1, 4 do
                local line = Drawing.new("Line"); line.Visible = true; line.Transparency = 1; line.ZIndex = 999
                table.insert(Config.CrosshairDrawings, line)
            end
        elseif Config.Crosshair.Style == "Dot" then
            local dot = Drawing.new("Circle"); dot.Filled = true; dot.Visible = true; dot.Transparency = 1; dot.ZIndex = 999
            table.insert(Config.CrosshairDrawings, dot)
        elseif Config.Crosshair.Style == "Circle" then
            local circle = Drawing.new("Circle"); circle.Filled = false; circle.Visible = true; circle.Transparency = 1; circle.ZIndex = 999
            table.insert(Config.CrosshairDrawings, circle)
        end
    end
    for _, v in pairs(Config.CrosshairDrawings) do
        if v then
            v.Visible = true
            v.Transparency = 1
            v.ZIndex = 999
        end
    end
    if Config.Crosshair.Style == "Plus" then
        for _, line in pairs(Config.CrosshairDrawings) do line.Color = Config.Crosshair.Color; line.Thickness = Config.Crosshair.Thickness end
        Config.CrosshairDrawings[1].From = center + Vector2.new(-Config.Crosshair.Size, 0); Config.CrosshairDrawings[1].To = center + Vector2.new(-2, 0)
        Config.CrosshairDrawings[2].From = center + Vector2.new(Config.Crosshair.Size, 0); Config.CrosshairDrawings[2].To = center + Vector2.new(2, 0)
        Config.CrosshairDrawings[3].From = center + Vector2.new(0, -Config.Crosshair.Size); Config.CrosshairDrawings[3].To = center + Vector2.new(0, -2)
        Config.CrosshairDrawings[4].From = center + Vector2.new(0, Config.Crosshair.Size); Config.CrosshairDrawings[4].To = center + Vector2.new(0, 2)
    elseif Config.Crosshair.Style == "Dot" then
        local dot = Config.CrosshairDrawings[1]
        dot.Position = center; dot.Radius = Config.Crosshair.Size / 2; dot.Color = Config.Crosshair.Color
    elseif Config.Crosshair.Style == "Circle" then
        local circle = Config.CrosshairDrawings[1]
        circle.Position = center; circle.Radius = Config.Crosshair.Size
        circle.Color = Config.Crosshair.Color; circle.Thickness = Config.Crosshair.Thickness
    end
end

function Veil_ClearVelocityCache(playerName)
    if playerName then
        Config.VeilVelocityCache[playerName] = nil
    else
        for k in pairs(Config.VeilVelocityCache) do
            Config.VeilVelocityCache[k] = nil
        end
    end
end
function Veil_GetRealVelocity(part, playerName)
    if not part then return Vector3.zero end
    local currentPos = part.Position
    local currentTime = fast_tick()
    local cache = Config.VeilVelocityCache[playerName]
    if not cache then
        Config.VeilVelocityCache[playerName] = {
            lastPos = currentPos,
            lastTime = currentTime,
            velocity = Vector3.zero,
        }
        return Vector3.zero
    end
    local dt = currentTime - cache.lastTime
    if dt > 0.01 then
        local rawVelocity = (currentPos - cache.lastPos) / dt
        if rawVelocity.Magnitude < 80 then
            cache.velocity = cache.velocity:Lerp(rawVelocity, 0.35)
            cache.lastPos = currentPos
        else
            cache.velocity = Vector3.zero
            cache.lastPos = currentPos
        end
        cache.lastTime = currentTime
    end
    return cache.velocity
end
local function Veil_HookSurvivorChar(player)
    if player == LocalPlayer then return end
    pcall(function()
        player.CharacterAdded:Connect(function()
            Veil_ClearVelocityCache(player.Name)
        end)
    end)
end
Config.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    Config.VeilVelocityCache[p.Name] = nil
    local entries = Config.ToFVelocityCache and Config.ToFVelocityCache.Entries
    if entries then
        local pChar = p.Character
        if pChar then
            for part in pairs(entries) do
                if not part or not part.Parent or part:IsDescendantOf(pChar) then
                    entries[part] = nil
                end
            end
        else
            for part in pairs(entries) do
                if not part or not part.Parent then
                    entries[part] = nil
                end
            end
        end
    end
    if Config.State._parryCharConns and Config.State._parryCharConns[p] then
        pcall(function() Config.State._parryCharConns[p]:Disconnect() end)
        Config.State._parryCharConns[p] = nil
    end
    if Config.State._autoCrouchCharConns and Config.State._autoCrouchCharConns[p] then
        pcall(function() Config.State._autoCrouchCharConns[p]:Disconnect() end)
        Config.State._autoCrouchCharConns[p] = nil
    end
    local list = Config.ESPCache.PlayerList
    for i = #list, 1, -1 do
        if list[i] == p then
            table.remove(list, i)
            break
        end
    end
end)
do
    local list = Config.ESPCache.PlayerList
    local fresh = game:GetService("Players"):GetPlayers()
    for i = 1, #fresh do
        table.insert(list, fresh[i])
        Veil_HookSurvivorChar(fresh[i])
    end
end
Config.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
    table.insert(Config.ESPCache.PlayerList, p)
    Veil_HookSurvivorChar(p)
end)
function veil_getTargetPart(char)
    if Config.VeilConfig.TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif Config.VeilConfig.TargetPart == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
end
function Veil_IsKnocked(char)
    return Fn.checkDowned(char)
end
function veil_getClosestSurvivor()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local cam      = workspace.CurrentCamera
    local center   = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local bestDistSq = Config.VeilConfig.FOV * Config.VeilConfig.FOV
    local bestTarget = nil
    for _, p in ipairs(Config.ESPCache.PlayerList) do
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            local part = veil_getTargetPart(char)
            if hum and hum.Health > 0 and part then
                local skip = Config.VeilConfig.KnockCheck and Veil_IsKnocked(char)
                if not skip then
                    local dist3D = (part.Position - myRoot.Position).Magnitude
                    if dist3D <= Config.VeilConfig.MaxDist then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dx = screenPos.X - center.X
                            local dy = screenPos.Y - center.Y
                            local distSq = (dx * dx) + (dy * dy)
                            if distSq < bestDistSq then
                                bestDistSq = distSq
                                bestTarget = { Player = p, Part = part }
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end
function Veil_SolveProjectile(startPos, targetPos, targetVel, spearSpeed, gravity, iterations)
    iterations = iterations or 3
    spearSpeed = math.max(spearSpeed, 20)
    gravity    = math.max(gravity, 0.1)
    local aimPos = targetPos
    local travelTime = (targetPos - startPos).Magnitude / spearSpeed
    for _ = 1, iterations do
        local predictedTargetPos = targetPos + (targetVel * travelTime)
        local horizontalDist = (Vector3.new(predictedTargetPos.X, 0, predictedTargetPos.Z)
            - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
        travelTime = horizontalDist / spearSpeed
        local drop = 0.5 * gravity * travelTime * travelTime
        aimPos = predictedTargetPos + Vector3.new(0, drop, 0)
    end
    return aimPos, travelTime
end
function Veil_GetSmartParams(myChar)
    local isSpecial = myChar and myChar:GetAttribute("special") == true
    local speed     = isSpecial and 165 or 142.5
    local gravity   = workspace.Gravity * 0.5
    return speed, gravity
end
function Veil_ComputeAim()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local startPart = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
    if not startPart then return nil end
    local startPos = startPart.Position
    local spearSpeed, gravity
    if Config.VeilConfig.SmartPredict then
        spearSpeed, gravity = Veil_GetSmartParams(myChar)
    else
        spearSpeed = Config.VeilConfig.SpearSpeed
        if Config.VeilConfig.AutoPredict then
            gravity = workspace.Gravity * 0.5
        else
            gravity = Config.VeilConfig.Gravity
        end
    end
    spearSpeed = math.max(spearSpeed, 20)
    gravity    = math.max(gravity, 0.1)
    local targetInfo = veil_getClosestSurvivor()
    if not (targetInfo and targetInfo.Part) then
        return {
            aimDir       = workspace.CurrentCamera.CFrame.LookVector,
            startPos     = startPos,
            spearSpeed   = spearSpeed,
            gravity      = gravity,
            target       = nil,
            predictedPos = nil,
            travelTime   = nil,
        }
    end
    local targetPart = targetInfo.Part
    local targetPos  = targetPart.Position
    local velocity   = Veil_GetRealVelocity(targetPart, targetInfo.Player.Name)
    local leadMult   = Config.VeilConfig.LeadMultiplier or 1.0
    local aimPos, travelTime = Veil_SolveProjectile(
        startPos,
        targetPos,
        velocity * leadMult,
        spearSpeed,
        gravity,
        Config.VeilConfig.IterationCount
    )
    return {
        aimDir       = (aimPos - startPos).Unit,
        startPos     = startPos,
        spearSpeed   = spearSpeed,
        gravity      = gravity,
        target       = targetInfo,
        predictedPos = aimPos,
        travelTime   = travelTime,
    }
end
function veil_fire()
    if not Config.VeilConfig.Enabled then return end
    local myChar = LocalPlayer.Character
    if not (myChar and myChar:GetAttribute("spearmode") == true) then return end
    if Config.VeilState.attackCooldown then return end
    Config.VeilState.attackCooldown = true
    if Config.VeilState.cooldownHandle then
        pcall(function() task.cancel(Config.VeilState.cooldownHandle) end)
    end
    local cooldownSec = Fn.Veil_GetEffectiveCooldown()
    local fireTime = fast_tick()
    Config.VeilLastFireTime = fireTime
    Config.VeilState.cooldownHandle = task.delay(cooldownSec, function()
        Config.VeilState.attackCooldown = false
        Config.VeilState.cooldownHandle = nil
        if Config.VeilLastFireTime > 0 then
            Fn.Veil_RecordCooldownSample(Config.VeilLastFireTime, fast_tick())
        end
    end)
    local aim = Veil_ComputeAim()
    if not aim then return end
    local aimDir    = aim.aimDir
    local startPos  = aim.startPos
    Config.VeilState.lastPredictedPos = aim.predictedPos
    Config.VeilState.firing = true
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then
            warn("[Veil] Remotes folder not found under ReplicatedStorage — game may have updated")
            return
        end
        local killers = remotes:FindFirstChild("Killers")
        if not killers then
            warn("[Veil] Killers folder not found under Remotes — game may have updated")
            return
        end
        local veil = killers:FindFirstChild("Veil")
        if not veil or not veil:FindFirstChild("Spearthrow") then
            warn("[Veil] Spearthrow remote not found under Killers.Veil — game may have updated")
            return
        end
        veil.Spearthrow:FireServer(aimDir, aim.spearSpeed, startPos)
    end)
    Config.VeilState.firing = false
end
Config.Connections.VeilInputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    local char = LocalPlayer.Character
    local isSpearMode = char and char:GetAttribute("spearmode") == true
    if not Config.VeilConfig.Enabled or not isSpearMode then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.VeilState.chargingSpear = true
    elseif isTouch then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local slasher = pGui:FindFirstChild("Slasher-mob")
            if slasher then
                local ctrl = slasher:FindFirstChild("Controls")
                if ctrl then
                    local attackBtn = ctrl:FindFirstChild("attack")
                    if attackBtn and attackBtn.Visible then
                        local pos     = input.Position
                        local absPos  = attackBtn.AbsolutePosition
                        local absSize = attackBtn.AbsoluteSize
                        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                        and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                            Config.VeilState.chargingSpear = true
                            Config.VeilState.touchInput    = input
                        end
                    end
                end
            end
        end
    end
end)
Config.Connections.VeilInputEnded = UserInputService.InputEnded:Connect(function(input, gp)
    if Config.VeilState.chargingSpear
    and (input == Config.VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        Config.VeilState.chargingSpear = false
        if Config.VeilState.touchInput == input then Config.VeilState.touchInput = nil end
        veil_fire()
    end
end)
function Veil_HideTrajectory()
    local draw = Config.VeilDraw
    if not draw then return end
    local beams = draw.TrajectoryBeams
    if beams then
        for _ = 1, #beams do
            local beam = beams[_]
            if beam then pcall(function() beam.Enabled = false end) end
        end
    end
    if draw.HitCircle then
        pcall(function() draw.HitCircle.Visible = false end)
    end
    if draw.HitMarker then
        pcall(function() draw.HitMarker.Parent = nil end)
    end
end
function Veil_DrawTrajectory(aim)
    if not aim then
        Veil_HideTrajectory()
        return
    end
    Veil_EnsureTrajectoryFolder()
    local beams = Config.VeilDraw.TrajectoryBeams
    local atts  = Config.VeilDraw.TrajectoryAttachments
    if not beams or #beams == 0 or not atts or #atts == 0 then return end
    local pos = aim.startPos
    local vel = aim.aimDir * aim.spearSpeed
    local totalTime = aim.travelTime or 1
    local stepDt = math.max(totalTime / 15, 0.033)
    local gravity = aim.gravity
    local predicted = aim.predictedPos
    local minDist = math.huge
    local points = { pos }
    for _ = 1, 15 do
        pos = pos + vel * stepDt + Vector3.new(0, -0.5 * gravity * stepDt * stepDt, 0)
        vel = vel + Vector3.new(0, -gravity * stepDt, 0)
        points[#points + 1] = pos
        if predicted then
            local d = (pos - predicted).Magnitude
            if d < minDist then minDist = d end
        end
    end
    local willHit = predicted ~= nil and minDist <= 6
    local color = willHit and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    local colorSeq = ColorSequence.new(color)
    for _pi = 1, #points do
        local att = atts[_pi]
        if att then att.WorldPosition = points[_pi] end
    end
    for _bi = 1, #beams do
        local beam = beams[_bi]
        if beam then
            if _bi < #points and Config.VeilConfig.ShowTrajectory then
                beam.Color = colorSeq
                beam.Enabled = true
            else
                beam.Enabled = false
            end
        end
    end
    local targetPart = aim.target and aim.target.Part
    local circle = Config.VeilDraw.HitCircle
    if circle then
        local cam = workspace.CurrentCamera
        if targetPart and targetPart.Parent then
            local sp, on = cam:WorldToViewportPoint(targetPart.Position)
            if on and sp.Z > 0 then
                circle.Visible = true
                circle.Position = Vector2.new(sp.X, sp.Y)
                circle.Color = color
            else
                circle.Visible = false
            end
        else
            circle.Visible = false
        end
    end
    local marker = Config.VeilDraw.HitMarker
    if marker and not circle then
        if targetPart and targetPart.Parent then
            marker.Color = color
            marker.Position = targetPart.Position
            if not marker.Parent then marker.Parent = workspace end
        else
            marker.Parent = nil
        end
    end
    Config.VeilState.lastTrajectoryHit = willHit
end
function AimSpear_HideTrajectory()
    local draw = Config.AttackAimTrajectory
    if not draw then return end
    local beams = draw.Beams
    if beams then
        for _ = 1, #beams do
            local beam = beams[_]
            if beam then pcall(function() beam.Enabled = false end) end
        end
    end
    if draw.HitCircle then
        pcall(function() draw.HitCircle.Visible = false end)
    end
    if draw.HitMarker then
        pcall(function() draw.HitMarker.Parent = nil end)
    end
end
function AimSpear_DrawTrajectory(aim)
    if not aim then
        AimSpear_HideTrajectory()
        return
    end
    AimSpear_EnsureTrajectoryFolder()
    local beams = Config.AttackAimTrajectory.Beams
    local atts  = Config.AttackAimTrajectory.Attachments
    if not beams or #beams == 0 or not atts or #atts == 0 then return end
    local pos = aim.startPos
    local vel = aim.aimDir * aim.spearSpeed
    local totalTime = aim.travelTime or 1
    local stepDt = math.max(totalTime / 15, 0.033)
    local gravity = aim.gravity
    local predicted = aim.predictedPos
    local minDist = math.huge
    local points = { pos }
    for _ = 1, 15 do
        pos = pos + vel * stepDt + Vector3.new(0, -0.5 * gravity * stepDt * stepDt, 0)
        vel = vel + Vector3.new(0, -gravity * stepDt, 0)
        points[#points + 1] = pos
        if predicted then
            local d = (pos - predicted).Magnitude
            if d < minDist then minDist = d end
        end
    end
    local willHit = predicted ~= nil and minDist <= 6
    local color = willHit and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    local colorSeq = ColorSequence.new(color)
    for _pi = 1, #points do
        local att = atts[_pi]
        if att then att.WorldPosition = points[_pi] end
    end
    for _bi = 1, #beams do
        local beam = beams[_bi]
        if beam then
            if _bi < #points and Config.AttackAim.Spear.ShowTrajectory then
                beam.Color = colorSeq
                beam.Enabled = true
            else
                beam.Enabled = false
            end
        end
    end
    local targetPart = aim.targetPart
    local circle = Config.AttackAimTrajectory.HitCircle
    if circle then
        local cam = workspace.CurrentCamera
        if targetPart and targetPart.Parent then
            local sp, on = cam:WorldToViewportPoint(targetPart.Position)
            if on and sp.Z > 0 then
                circle.Visible = true
                circle.Position = Vector2.new(sp.X, sp.Y)
                circle.Color = color
            else
                circle.Visible = false
            end
        else
            circle.Visible = false
        end
    end
    local marker = Config.AttackAimTrajectory.HitMarker
    if marker and not circle then
        if targetPart and targetPart.Parent then
            marker.Color = color
            marker.Position = targetPart.Position
            if not marker.Parent then marker.Parent = workspace end
        else
            marker.Parent = nil
        end
    end
end
Config.Connections.VeilLocalCharAdded = LocalPlayer.CharacterAdded:Connect(function()
    Config.VeilState.chargingSpear = false
    Config.VeilState.touchInput = nil
    if Config.VeilDraw.Highlight then
        Config.VeilDraw.Highlight.Parent = nil
    end
    Veil_HideTrajectory()
    AimSpear_HideTrajectory()
    Veil_ClearVelocityCache()
    ToF_ClearVelocityCache()
end)
Config.Connections.VeilRender = Config.FakeConnection(Config.RenderSteppedTasks, "VeilRender", function()
    local cam         = workspace.CurrentCamera
    local myChar      = LocalPlayer.Character
    local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true
    if Config.VeilDraw.FOVCircle and Config.VeilConfig.Enabled and Config.VeilConfig.ShowFOV and isSpearMode then
        Config.VeilDraw.FOVCircle.Visible  = true
        Config.VeilDraw.FOVCircle.Radius   = Config.VeilConfig.FOV
        local vs = cam.ViewportSize
        if Config.VeilState._lastVPX ~= vs.X or Config.VeilState._lastVPY ~= vs.Y then
            Config.VeilState._lastVPX = vs.X
            Config.VeilState._lastVPY = vs.Y
            Config.VeilDraw.FOVCircle.Position = Vector2.new(vs.X / 2, vs.Y / 2)
        end
    elseif Config.VeilDraw.FOVCircle then
        Config.VeilDraw.FOVCircle.Visible = false
    end
    if Config.VeilState.chargingSpear and Config.VeilConfig.Enabled and isSpearMode then
        local now = fast_tick()
        if now - (Config.VeilState._lastScanAt or 0) >= 1/30 then
            Config.VeilState._lastScanAt = now
            local target = veil_getClosestSurvivor()
            Config.VeilState._lastChargingTarget = target
        end
        local target = Config.VeilState._lastChargingTarget
        if target and target.Part and target.Part.Parent then
            Config.VeilDraw.Highlight.Parent = target.Part.Parent
        else
            Config.VeilDraw.Highlight.Parent = nil
        end
        if Config.VeilConfig.ShowTrajectory
            and not (myChar and myChar:GetAttribute("IsStunned") == true) then
            local aim = Veil_ComputeAim()
            Veil_DrawTrajectory(aim)
        else
            Veil_HideTrajectory()
        end
    else
        Config.VeilDraw.Highlight.Parent = nil
        Config.VeilState._lastChargingTarget = nil
        Veil_HideTrajectory()
    end
end)

do
    local GunAimToggle = UI.AimlockBox:AddToggle("GunAimEnabled", { Text = "Aim Lock", Default = false,
    Callback = function(v) Config.GunAim.Enabled = v end })
UI.AimlockBox:AddLabel("Aimlock Key"):AddKeyPicker("AimlockKeybind", { Default = "R", Mode = "Hold", ChangedCallback = function(new)
    Config.GunAim.Keybind = new
    Fn.setAimHoldingFromTeam(false)
end })
end
UI.AimlockBox:AddDropdown("GunAimTarget", { Values = {"Killer","Survivor","SCP"}, Default = 1, Text = "Target",
    Callback = function(v)
        Config.GunAim.TargetMode = v
        Fn.updateTargetIconVisual("GunAimTargetIcon")
    end })
UI.AimlockBox:AddToggle("GunAimShowTargetIcon", { Text = "Show Selected Target Icon", Default = false,
    Callback = function(v)
        Config.GunAim.ShowTargetIcon = v
        if v then Fn.createGunAimTargetIcon() else Fn.removeToggleIcon("GunAimTargetIcon") end
    end }):AddKeyPicker("GunAimShowTargetIcon_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AimlockBox:AddDropdown("GunAimPart", { Text = "Aim Part", Values = {"Head","HumanoidRootPart","Torso"}, Default = 2,
    Callback = function(v) Config.GunAim.AimPart = v end })
UI.AimlockBox:AddSlider("GunAimFOV", { Text = "FOV", Default = 250, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v) Config.GunAim.FOV = v end })
UI.AimlockBox:AddSlider("GunAimVelSmoothing", { Text = "Velocity Smoothing", Default = 0.35, Min = 0.05, Max = 1.0, Rounding = 2,
    Callback = function(v) Config.GunAim.VelSmoothing = v end })
UI.AimlockBox:AddSlider("GunAimPredict", { Text = "Lead Strength", Default = 1.0, Min = 0, Max = 2, Rounding = 2,
    Callback = function(v) Config.GunAim.PredictStrength = v end })
UI.AimlockBox:AddSlider("GunAimStrength", { Text = "Aim Strength", Default = 1, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) Config.GunAim.Strength = v end })
UI.AimlockBox:AddToggle("GunAimWallCheck", { Text = "Wall Check", Default = true,
    Callback = function(v) Config.GunAim.VisibilityCheck = v end }):AddKeyPicker("GunAimWallCheck_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AimlockBox:AddToggle("GunAimShowLaser", { Text = "Show Laser", Default = false,
    Callback = function(v)
        Config.GunAim.ShowLaser = v
        if not v then FLNS_ToFClearLaser() end
    end }):AddKeyPicker("GunAimShowLaser_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AttackAimBox:AddToggle("AttackAim", { Text = "AimLock Attack", Default = false,
    Callback = function(v) Config.AttackAim.Enabled = v; if v then Fn.startAttackAim() end end })
UI.AttackAimBox:AddLabel("Aimlock Key"):AddKeyPicker("AttackAimKeybind", { Default = "R", Mode = "Hold", ChangedCallback = function(new)
    Config.AttackAim.Keybind = new
    Config.AttackAim.Holding = false
end })
UI.AttackAimBox:AddDropdown("AttackAimMode", { Text = "Aimlock Mode", Values = {"Normal","Spear"}, Default = 1, Multi = false,
    Callback = function(v) Config.State.AttackAimMode = v end })
UI.AttackAimBox:AddToggle("AttackAimLockBehind", { Text = "Lock Behind Character", Default = false,
    Callback = function(v)
        Config.AttackAim.LockBehindChar = v
        AttackAim_StickyTarget = nil
    end })
UI.AttackAimBox:AddSlider("AttackAimRange", { Text = "Lock Range", Default = 250, Min = 30, Max = 500, Rounding = 0,
    Callback = function(v) Config.AttackAim.Range = v end })
UI.AttackAimBox:AddToggle("AttackAimUseHighlight", { Text = "Use Highlight", Default = Config.AttackAim.UseHighlight,
    Callback = function(v) Config.AttackAim.UseHighlight = v end })
UI.AttackAimBox:AddSlider("SpearGravity", { Text = "Spear Gravity", Default = 50, Min = 10, Max = 200, Rounding = 0,
    Callback = function(v) Config.AttackAim.Spear.Gravity = v end })
UI.AttackAimBox:AddToggle("SpearSmartPredict", { Text = "Spear Smart Predict", Default = false,
    Callback = function(v) Config.AttackAim.Spear.SmartPredict = v end }):AddKeyPicker("SpearSmartPredict_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AttackAimBox:AddToggle("SpearTrajectoryBeam", { Text = "Spear Trajectory Beam", Default = true,
    Callback = function(v) Config.AttackAim.Spear.ShowTrajectory = v end }):AddKeyPicker("SpearTrajectoryBeam_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AttackAimBox:AddSlider("AttackAimStrength", { Text = "Aim Strength", Default = 1, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) Config.AttackAim.Strength = v end })
UI.AttackAimBox:AddToggle("AttackAimPredict", { Text = "Enable Prediction", Default = Config.AttackAim.Predict,
    Callback = function(v) Config.AttackAim.Predict = v end }):AddKeyPicker("AttackAimPredict_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.AttackAimBox:AddSlider("AttackAimPredictStrength", { Text = "Prediction Strength", Default = Config.AttackAim.PredictStrength, Min = 0.01, Max = 2, Rounding = 2,
    Callback = function(v) Config.AttackAim.PredictStrength = v end })
UI.TofV1Tab:AddToggle("ToFAimV1Toggle", { Text = "SilentAim ToF V1", Default = false,
    Callback = function(v)
        ToFV1_SetSilentAim(v)
    end }):AddKeyPicker("ToFAimV1Toggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.TofV1Tab:AddToggle("ToFAimV1ShowLaser", { Text = "Show Laser", Default = false,
    Callback = function(v)
        Config.ToFAimV1.ShowLaser = v
        if not v then
            ToFV2_ClearLaser()
        end
    end }):AddKeyPicker("ToFAimV1ShowLaser_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.TofV1Tab:AddDropdown("ToFAimV1Target", { Values = {"Killer", "Survivors", "SCP"}, Default = 1, Text = "Target Mode",
    Callback = function(v)
        Config.ToFAimV1.TargetMode = v
        local iconMode = v
        if iconMode == "Survivors" then iconMode = "Survivor" end
        Config.GunAim.TargetMode = iconMode
        Fn.updateTargetIconVisual("ToFAimV1TargetIcon")
    end })
UI.TofV1Tab:AddToggle("ToFAimV1ShowTargetIcon", { Text = "Show Selected TargetMode", Default = false,
    Callback = function(v)
        Config.ToFAimV1.ShowTargetIcon = v
        if v then Fn.createToFAimV1TargetIcon() else Fn.removeToggleIcon("ToFAimV1TargetIcon") end
    end })
UI.TofV1Tab:AddLabel("Keybind TargetMode"):AddKeyPicker("ToFTargetCycleKeybindV1", {
    Default = "None",
    Mode = "Toggle",
    Callback = function(state)
        if state == true then
            Fn.safeCall("ToF Target Cycle Keybind V1", function()
                Fn.CycleToFTargetModeSync()
            end)
            task.defer(function()
                pcall(function()
                    if Options and Options.ToFTargetCycleKeybindV1 then
                        Options.ToFTargetCycleKeybindV1:SetValue(false)
                    end
                end)
            end)
        end
    end,
})
UI.TofV1Tab:AddToggle("ToFAimV1BypassRestrictions", { Text = "Bypass ToF Restrictions", Default = false,
    Callback = function(v)
        ToFV1_SetBypassRestrictions(v)
    end }):AddKeyPicker("ToFAimV1BypassRestrictions_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.TofV1Tab:AddDropdown("ToFAimV1AimPart", { Values = {"HumanoidRootPart", "Head", "Torso"}, Default = 1, Text = "Aim Part",
    Callback = function(v) Config.ToFAimV1.AimPart = v end })
UI.TofV1Tab:AddSlider("ToFAimV1PredictStrength", { Text = "Lead Multiplier", Default = 1.5, Min = 0.1, Max = 2.0, Rounding = 2,
    Callback = function(v) Config.ToFAimV1.PredictStrength = v end })
UI.TofV1Tab:AddSlider("ToFAimV1VelSmoothing", { Text = "Velocity Smoothing", Default = 0.35, Min = 0.05, Max = 1.0, Rounding = 2,
    Callback = function(v) Config.ToFAimV1.VelSmoothing = v end })
UI.SpearTab:AddToggle("VeilSilentAim", { Text = "Silent Aim Spear (Veil)", Default = false,
    Callback = function(v) Config.VeilConfig.Enabled = v end }):AddKeyPicker("VeilSilentAim_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.SpearTab:AddSlider("VeilFOV", { Text = "Veil FOV", Default = 250, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v) Config.VeilConfig.FOV = v end })
UI.SpearTab:AddSlider("VeilLeadMultiplier", { Text = "Lead Multiplier", Default = 1.0, Min = 0.0, Max = 2.0, Rounding = 2,
    Callback = function(v) Config.VeilConfig.LeadMultiplier = v end })
UI.SpearTab:AddToggle("VeilTrajectory", { Text = "Garis Lintasan Spear (Trajectory)", Default = true,
    Tooltip = "Hijau = kena target, Merah = sesuai keyakinan masing².",
    Callback = function(v) Config.VeilConfig.ShowTrajectory = v end }):AddKeyPicker("VeilTrajectory_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })

Shared.AimSystem               = AimSystem
Shared.ToFV1_State             = ToFV1_State
Shared.ToFV2_State             = ToFV2_State
Shared.FLNS_ToFState           = FLNS_ToFState
Shared.ToFV1_DisconnectInputs  = ToFV1_DisconnectInputs
Shared.ToFV1_StopCache         = ToFV1_StopCache
Shared.ToFV2_ClearLaser        = ToFV2_ClearLaser
Shared.ToFV2_RefreshTargetButtons = ToFV2_RefreshTargetButtons
Shared.ToFV1_SetSilentAim      = ToFV1_SetSilentAim
Fn.ToFV2_RefreshTargetButtons  = ToFV2_RefreshTargetButtons
Fn.ToFV2_UpdateLaser           = ToFV2_UpdateLaser