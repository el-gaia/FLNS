local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Window             = Shared.Window
local UI                 = Shared.UI
local Lighting           = Shared.Lighting
local fast_tick          = Shared.fast_tick
Config.ESP = {
    Survivor  = false,
    Killer    = false,
    Generator = false,
    Pallet    = false,
    Window    = false,
    SCP       = false,
    Distance  = 100
}
Config.ESPStatus = {
    Enabled      = false,
    ShowName     = true,
    ShowDistance = true,
    ShowHealth   = false,
    ShowItem     = true,
    ItemDisplayMode = { Image = true, Text = false },
    ShowKillerName = false,
    Radius       = 100
}
Config.HookCountDisplay = {
    Enabled  = false,
    ShowFor  = "Survivor",
}
Config.StunNotification = {
    Enabled        = false,
    MusicId        = "rbxassetid://113189826880132",
    StickerId      = "rbxassetid://135216096316191",
    _sound         = nil,
    _billboard     = nil,
    _wasStunned    = false,
    _lastKillerChar = nil,
}
Config.SmoothCam = {
    Enabled   = false,
    Height    = -1,
    Stiffness = 9.5,
}
Config.NextKillerDisplay = {
    Enabled        = false,
    Label          = nil,
    LastUpdate     = 0,
    UpdateInterval = 0.5
}
Config.KillerPerksDisplay = {
    Enabled        = false,
    Label          = nil,
    LastUpdate     = 0,
    UpdateInterval = 0.5,
    PerkDatabase   = {},
}
Config.ESPItems = {
    ["Twist of Fate"]   = true,
    ["Bandage"]         = true,
    ["Motion Tracker"]  = true,
    ["Gate"]            = true,
    ["Shadow Clone"]    = true,
    ["Parrying Dagger"] = true
}
Config.TeamColors = {
    Survivor = Color3.fromRGB(0,255, 0),
    Killer   = Color3.fromRGB(255, 60, 60),
    Generator = Color3.fromRGB(255, 170, 0),
    Pallet    = Color3.fromRGB(74, 255, 181),
    Window    = Color3.fromRGB(74, 255, 181),
    SCP       = Color3.fromRGB(255, 0, 0)
}
Config.ESPVisual = {
    Survivor  = { FillColor = Color3.fromRGB(0, 255, 0),   FillTransparency = 0.50, OutlineColor = Color3.fromRGB(0, 255, 0),   OutlineTransparency = 0.0 },
    Killer    = { FillColor = Color3.fromRGB(255, 60, 60), FillTransparency = 0.50, OutlineColor = Color3.fromRGB(255, 60, 60), OutlineTransparency = 0.0 },
    Generator = { FillColor = Color3.fromRGB(255, 170, 0), FillTransparency = 0.50, OutlineColor = Color3.fromRGB(255, 170, 0), OutlineTransparency = 0.0 },
    Pallet    = { FillColor = Color3.fromRGB(74, 255, 181),FillTransparency = 0.50, OutlineColor = Color3.fromRGB(74, 255, 181),OutlineTransparency = 0.0 },
    Window    = { FillColor = Color3.fromRGB(74, 255, 181),FillTransparency = 0.50, OutlineColor = Color3.fromRGB(74, 255, 181),OutlineTransparency = 0.0 },
    SCP       = { FillColor = Color3.fromRGB(255, 0, 0),   FillTransparency = 0.50, OutlineColor = Color3.fromRGB(255, 0, 0),   OutlineTransparency = 0.0 },
}
Config.Auto = {
    SkillCheck       = false,
    SkillCheckMode   = "perfect",
    Parry            = false,
    ParryShowButton  = false,
    ParryDelay       = 0,
    ParryDistance    = 15,
    ParryMode        = "Instant",
    FaceSensitivity  = 0.7,
    RequireFacing    = true,
    ParryVisualFX     = true,
    ParryFaceLock     = true,
    ParryApplySlow    = true,
    ParryUICooldown   = true,
    ParryLockDuration = 0.8,
    ParryAnim         = "Enten",
    ParryAnims = {
        NoSkin     ="rbxassetid://109133187196613",
        Enten      = "rbxassetid://127096285501517",
        Stopwatch  = "rbxassetid://81793464499285",
        Fih        = "rbxassetid://123307242865945",
        BloodShield= "rbxassetid://75939529748815",
    },
    PalletDrop       = false,
    PalletDropDist   = 5,
    GenBoost = { Enabled = false, LastBroadcast = 0 },
    Flee = { Enabled = false, DetectDistance = 50, Cooldown = 0.1, ShowButton = false, Keybind = "None" },
    ParryVisual = {
        Enabled = false,
        Color = Color3.fromRGB(255, 80, 80),
        Transparency = 0.9,
        StrokeColor  = Color3.fromRGB(51, 124, 255),
        StrokeTransparency   = 0.1,
        StrokeThickness      = 0.35,
        StrokeSegments       = 72,
        StrokeLightEmission  = 1,
        StrokeLightInfluence = 0,
    },
    AutoCrouch = { Enabled = false, DetectDistance = 15, AnimId = "rbxassetid://80411309607666", WalkSpeed = 6 },
    SelfHeal   = { Enabled = false },
    Bandage = { Auto = false, Instant = true, Threshold = 95, Cooldown = 1.5, ShowButton = false, Busy = false, Heartbeat = nil, LastTrigger = 0, _lastScan = 0 },
}
Config.Flowstate = {
    Enabled = false,
    WatcherActive = false,
    ShowButton = false,
    Keybind = "None",
}
Config.Moonwalk = {
    Enabled   = false,
    ShowButton = false,
    SpamSpeed = 30,
    Intensity = 35,
    SlowSpeed = 13,
    UseSlow   = true
}
Config.FakeParry = {
    Enabled   = false,
    Animation = "Enten",
    Keybind   = Enum.KeyCode.V,
    ShowButton = false,
    Anims = {
        Enten     = "rbxassetid://127096285501517",
        Stopwatch = "rbxassetid://81793464499285",
        Fih       = "rbxassetid://123307242865945",
        BloodShield = "rbxassetid://75939529748815"
    }
}
Config.GunAim = {
    Enabled         = false,
    Holding         = false,
    TargetMode      = "Killer",
    Strength        = 1,
    Predict         = true,
    PredictStrength = 1.0,
    BulletSpeed     = 200,
    VelSmoothing    = 0.35,
    FOV             = 250,
    VisibilityCheck = true,
    Target          = nil,
    AimPart         = "HumanoidRootPart",
    ShowLaser       = false,
    ShowTargetIcon  = false,
    _cachedGunPart  = nil,
    Keybind = Enum.KeyCode.R,
    Colors = { Killer = Color3.fromRGB(255, 80, 80), Survivor = Color3.fromRGB(80, 220, 255), SCP = Color3.fromRGB(255, 0, 0) }
}

Config.ToFAimV2 = { Enabled = false }
Config.ToFAimV1 = {
    Enabled             = false,
    TargetMode          = "Killer",
    AimPart             = "HumanoidRootPart",
    ShowLaser           = false,
    ShowTargetIcon      = false,
    BulletSpeed         = 200,
    PredictStrength     = 1.5,
    VelSmoothing        = 0.35,
    BypassRestrictions  = false,
    CachedShouldRedirect = false,
    CachedRedirectDir   = nil,
    CachedOriginPos     = nil,
    CachedTargetPos     = nil,
    _isAiming           = false,
}
Config.AttackAim = {
    Enabled         = false,
    Holding         = false,
    Keybind         = Enum.KeyCode.R,
    Strength        = 1,
    Predict         = true,
    PredictStrength = 0.12,
    FOV             = 250,
    VisibilityCheck = true,
    AimPart         = "HumanoidRootPart",
    UseHighlight    = true,
    LockBehindChar  = false,
    Range           = 250,
    Spear = { Enabled = false, Gravity = 50, Speed = 160, FOV = 250, AimPart = "HumanoidRootPart", SmartPredict = true, ShowTrajectory = true }
}
Config.VeilConfig = {
    Enabled              = false,
    ShowFOV              = true,
    FOV                  = 250,
    SpearSpeed           = 165,
    Gravity              = workspace.Gravity * 0.5,
    MaxDist              = 500,
    AutoPredict          = false,
    TargetPart           = "Torso",
    LeadMultiplier       = 1.6,
    KnockCheck           = true,
    IterationCount       = 3,
    SmartPredict          = true,
    ShowTrajectory        = true,
}
Config.VeilState = {
    chargingSpear    = false,
    touchInput       = nil,
    attackCooldown   = false,
    cooldownHandle   = nil,
    lastPredictedPos = nil,
    firing           = false,
    lastTarget       = nil,
    lastTargetTick   = 0,
    realSpearCooldown      = nil,
    oldMakeMoveCooldown    = nil,
    oldSpearFireServer     = nil,
    spearRemote            = nil,
    lastTrajectoryHit      = nil,
}
Config.VeilVelocityCache = {}
Config.ToFVelocityCache = {
    Entries   = {},
    Smoothing = 0.35,
    WindowSec  = 0.100,
    MaxSampleAge = 0.300,
    MaxSaneVelocity = 250,
}
Config.GenBypass = {
    Enabled     = false,
    Button      = nil,
    UI          = nil,
    Cache       = {},
    CacheTimer  = 0,
    Processed   = {},
    HotkeyCode  = Enum.KeyCode.G,
    _epoch      = 0,
    _running    = false,
}
Config.Killer = {
    KillAll   = false,
    KillRange = 500,
    BypassCooldown = false,
    NoCooldownHidden = false,
    M2Aimlock = {
        Enabled      = false,
        Range        = 250,
        LockStrength = 1.0,
        LockDuration = 2.5,
        TargetPart   = "HumanoidRootPart",
        RotateChar   = true,
        IgnoreDowned   = true,
        SwitchOnDowned = true,
        _active     = false,
        _targetChar = nil,
        _targetPart = nil,
        _releaseAt  = 0,
        _lastTriggerAt = 0,
        _nextValidateAt = 0,
        _m2Fn       = nil,
        _gyro       = nil,
        _prepareConn = nil,
    },
    InfiniteLunge = false,
    ThirdPerson = false,
    ThirdPersonWasActive = false,
    OriginalCameraType = nil,
    _ThirdPersonOffset = Vector3.new(2, 1, 8),
    _cachedHum = nil,
    AntiBlind = false,
    BlockVaults = false,
    Stalk = {
        Enabled            = false,
        StalkRange         = 150,
        Target             = nil,
        MinHealth          = 0,
        Cooldown           = 2,
        RequireLineOfSight = false,
        _remote   = nil,
        _remoteAt = 0,
        _killerOk = false,
        _killerAt = 0,
    },
    Mods = { GodMode = false, AntiFall = false },
    BreakSpeedEnabled = false,
    BreakSpeed = 0,
}
Config.NoCutscene = false
Config.NoCutsceneHooked = false
Config._NoCutsceneState = {
    fakeBindable = nil,
    fakeRemote   = nil,
    conns        = {},
}
Config.Masked = {
    Enabled      = false,
    CurrentPower = "Cobra",
    Powers = {"Cobra", "Richter", "Brandon", "Rabbit", "Alex"}
}
Config.CameraZoom = {
    MaxZoom        = false,
    MaxDistance    = 0.5,
    MinDistance    = 0.5,
    MaxZoomMax     = 20,
    FOVEnabled     = false,
    FOV            = 70,
    DefaultFOV     = workspace.CurrentCamera.FieldOfView
}
Config.Crosshair = {
    Enabled   = false,
    Size      = 8,
    Thickness = 2,
    Color     = Color3.fromRGB(255, 255, 255),
    Style     = "Plus",
    OffsetX   = 0,
    OffsetY   = 0
}
Config.Movement = {
    FakePerfectLanding = {
        Enabled = false,
        Value = 1.40
    },
    Vault = {
        Enabled       = false,
        Speed         = 1,
        HeartbeatRate = 0.10,
        LastApply     = 0
    },
    FakeFastVault = {
        Enabled = false,
    },
    AntiSlowVault = {
        Enabled       = false,
        ModuleHooked  = false,
        ControllerRef = nil,
        OrigFuncs     = nil,
    },
    SkillCheckSpeed = {
        Enabled       = false,
        Speed         = 1,
        HeartbeatRate = 0.10,
        LastApply     = 0
    },
    SpeedBoost = {
        Enabled           = false,
        ShowButton        = false,
        Multiplier        = 1.1,
        HeartbeatRate     = 0.15,
        LastApply         = 0,
    }
}
Config.Visual = {
    Fullbright      = false,
    NoShadow        = false,
    Ambient         = false,
    AmbientColor    = Color3.fromRGB(255, 255, 255),
    ClockTimeEnabled = true,
    Brightness      = 2,
    ClockTime       = 14,
    NoFog           = false,
    CleanSky        = false,
    CleanTexture    = false,
    NoScreenEffects = false
}
Config.EmoteButton = {
    Show        = false,
    GuiInstance = nil
}
Config.Noclip = {
    Enabled   = false,
    Connection = nil,
    Parts     = {},
    IgnoreNames = {},
    ShowButton = false,
    Keybind = "None",
}
Config.Fly = {
    Enabled       = false,
    VehicleFly    = false,
    Speed         = 1,
    QEFly         = true,
    MobileButton  = false,
    ShowButton    = false,
    Keybind       = "None",
    State = {
        iyflyspeed         = 50,
        vehicleflyspeed    = 100,
        QEfly              = true,
        flyKeyDown         = nil,
        flyKeyUp           = nil,
        FLYING             = false,
        velocityHandlerName = "iyfly_velocity",
        gyroHandlerName    = "iyfly_gyro",
        mfly1              = nil,
        mfly2              = nil,
    },
}
Config.JerkTool = {
    Active = false,
    Connection = nil,
}
Config.ToggleIcons = {
    Draggable   = true,
    IconSize    = 48,
    Gap         = 8,
    AnchorXOffset = -10,
    AnchorYOffset = 180,
    Positions   = {},
    _gui        = nil,
    _icons      = {},
    _stackCount = 0,
    _uisConn    = nil,
    _activeDrag = nil,
    _dragStart  = nil,
    _dragStartPos = nil,
}
Config.MenuToggleButton = {
    Enabled  = true,
    Size     = 44,
    _gui     = nil,
    _button  = nil,
    _icon    = nil,
    _stroke  = nil,
}
Config.TargetIconShared = {
    ModeList = { "Killer", "Survivor", "SCP" },
    Labels   = { Killer = "K", Survivor = "S", SCP = "SCP" },
    Colors   = {
        Killer   = Color3.fromRGB(255, 60, 60),
        Survivor = Color3.fromRGB(80, 220, 255),
        SCP      = Color3.fromRGB(255, 0, 0),
    },
}
Config.PredictMap = {
    Enabled        = false,
    Label          = nil,
    LastUpdate     = 0,
    UpdateInterval = 0.5,
    State = {
        Name     = "Unknown",
        Desc     = "Waiting for map data...",
        Source   = "Idle",
        Phase    = "",
        TimeLeft = nil,
    },
    Connections = {},
    Running     = false,
}
Config.Visual.HideSurvivorIcon = false
Config._HideSurvivorIconState = {
    Connection = nil,
    Originals  = {},
}
Config.Invisible = {
    Enabled        = false,
    ShowButton     = false,
    HookActive     = false,
    OriginalFire   = nil,
    Remote         = nil,
    CharConn       = nil,
}
Config.Fling = {
    Enabled        = false,
    Busy           = false,
    Target         = nil,
    TargetLabel    = "",
    PulseTime      = 0.3,
    Attempts       = 3,
    SuccessDist    = 8,
    Cooldown       = 0.3,
}
Config.Korless = {
    Enabled        = false,
    Offset         = -1000,
    SinkHead       = true,
    SinkRightLeg   = true,
    KeepRotation   = true,
    CharConn       = nil,
}
Config.Connections = {
    Moonwalk           = nil,
    SpeedBoost         = nil,
    Vault              = nil,
    FakeFastVault      = nil,
    FakeFastVaultChar  = nil,
    AntiSlowVaultTag   = nil,
    SkillCheckSpeed    = nil,
    GunAim             = nil,
    AttackAim          = nil,
    Stalk              = nil,
    SkillHeartbeat     = nil,
    CooldownBypass     = nil,
    DescendantAdded    = nil,
    DescendantRemoving = nil,
    LightingChild      = nil,
    AimKeyBegan        = nil,
    AimKeyEnded        = nil,
    FakeParryKey       = nil,
    CharacterInit      = nil,
    CharacterRemove    = nil,
    TeamChanged        = nil,
    MainHeartbeat      = nil,
    RenderLoop         = nil,
    FOVLoop            = nil,
    ParryPoll          = nil,
    GenBoostListener   = nil,
    VeilRender         = nil,
    VeilInputBegan     = nil,
    VeilInputEnded     = nil,
    VeilLocalCharAdded = nil,
    GenBypassKey       = nil,
    PlayerRemoving     = nil,
    HideSurvivorIcon  = nil,
    KorlessMorph      = nil,
    ParryResultHook   = nil,
    WatermarkConn     = nil,
    CharWalkingConn   = nil,
    InvisibleHook     = nil,
    M2AimlockInputBegan = nil,
    M2AimlockRender     = nil,
}
Config.Threads = {
    GenBypassLoop     = nil,
    Flee              = nil,
    AimButtonRebind   = nil,
    AutoStalk         = nil,
    JerkToolLoop      = nil,
    NoCooldownHidden  = nil,
}
Config.State = {
    MoonwalkButton      = nil,
    FakeParryButton     = nil,
    FakeParryToggleButton = nil,
    ToFV2TargetButton   = nil,
    SpeedBoostToggleButton = nil,
    FlowstateToggleButton = nil,
    FleeToggleButton    = nil,
    NoclipToggleButton  = nil,
    FlyToggleButton     = nil,
    AutoParryToggleButton = nil,
    AutoBandageToggleButton = nil,
    InstantEscapeToggleButton = nil,
    ToFTargetCycleKeybindConn = nil,
    ToggleIconsGui      = nil,
    FakeParryTrack      = nil,
    ParryCircle         = nil,
    KillerTarget        = nil,
    GunAimButtonConn    = nil,
    GunAimBeganConn     = nil,
    GunAimEndedConn     = nil,
    CurrentGunButton    = nil,
    CurrentAttackButton = nil,
    AttackAimBeganConn  = nil,
    AttackAimEndedConn  = nil,
    busy                = false,
    ParryActive         = false,
    AttackAimMode       = "Normal",
    LastFlee            = 0,
    lastParry         = 0,
    lastParryPressAt  = 0,
    lastManualParryInputAt = 0,
    ParryCooldown       = false,
    ParryCooldownThread = nil,
    FPS                 = 0,
    Frames              = 0,
    LastTick            = fast_tick(),
    LastCrosshairStyle  = nil,
    UsedPallets         = {},
    CurrentEmoteTrack   = nil,
    CurrentEmoteSound   = nil,
    _parryPlayerAddedConn   = nil,
    _parryCharConns         = {},
    _espCleanedForSpectator = false,
    unloaded                = false,
    LastStalkFire           = 0,
    _cachedAttackConfig      = nil,
    _ilOrigMaxHold           = nil,
    _ilScanning              = false,
    _ilScanNext              = 0,
    _ilScanEpoch             = 0,
    _ilFailNotified          = false,
    _skillHeartbeatCheck     = nil,
    AutoCrouchActive       = false,
    AutoCrouchKiller       = nil,
    AutoCrouchOriginals    = nil,
    _autoCrouchSpeedLast   = 0,
    _autoCrouchPlayerAddedConn = nil,
    _autoCrouchCharConns   = {},
    _autoCrouchAnims       = {},
    _vaultFireOK           = nil
}
Config.Timers = {
    lastESPUpdate    = 0,
    lastMapESPUpdate = 0,
    lastDisplayUpdate = 0,
    lastKillerUpdate = 0,
    lastGodMode      = 0,
    lastTracerScan   = 0,
    lastPalletScan   = 0,
    lastPalletDrop   = 0,
    lastVaultBlock      = 0,
    lastCooldownBypass  = 0,
    lastVisualApply   = 0,
    lastAttrEnforce   = 0,
    lastStunCheck     = 0,
    lastSmoothCam     = 0,
}
Config.State.DefaultSpeedBoost = nil
Config.State.TempSpeedBoostEnd = 0
Config.ESPCache = {
    Objects    = {},
    ObjectVisuals = {},
    Status     = {},
    SCP        = {},
    Generators = {},
    Windows    = {},
    Pallets    = {},
    AncestryConns = {},
    ItemImages = {},
    InfoBillboards = {},
    PlayerList = {},
    StatusStates = {}
}
Config.ESPCache.GeneratorPoints = {}
Config.OriginalLighting = {
    Brightness     = Lighting.Brightness,
    ClockTime      = Lighting.ClockTime,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows  = Lighting.GlobalShadows
}
Config.LastVisualState = {
    Fullbright     = nil,
    NoShadow       = nil,
    Ambient        = nil,
    AmbientColor   = nil,
    Brightness     = nil,
    ClockTime      = nil,
    NoScreenEffects = nil
}
Config.LastOptimizationState = {
    CleanSky     = nil,
    CleanTexture = nil
}
Config.KillerAnims = {
    ["rbxassetid://105374834496520"] = true,
    ["rbxassetid://113255068724446"] = true,
    ["rbxassetid://118907603246885"] = true,
    ["rbxassetid://129784271201071"] = true,
    ["rbxassetid://117042998468241"] = true,
    ["rbxassetid://122812055447896"] = true,
    ["rbxassetid://78935059863801"]  = true,
    ["rbxassetid://74968262036854"]  = true,
    ["rbxassetid://78432063483146"]  = true,
    ["rbxassetid://132817836308238"] = true,
    ["rbxassetid://133963973694098"] = true,
    ["rbxassetid://111920872708571"] = true,
    ["rbxassetid://80411309607666"]  = true,
    ["rbxassetid://114699370608778"] = true,
    ["rbxassetid://82666958311998"]  = true,
    ["rbxassetid://110355011987939"] = true,
    ["rbxassetid://139369275981139"] = true,
    ["rbxassetid://135002183282873"] = true,
    ["rbxassetid://121216847022485"] = true,
    ["rbxassetid://130593238885843"] = true,
    ["rbxassetid://117070354890871"] = true,
    ["rbxassetid://106871536134254"] = true,
    ["rbxassetid://138720291317243"] = true
}
Config.hookedKillers = {}
Config.VaultTracks   = {}
Config.FakeFastVault = {
    WALK_VAULT_ID = "rbxassetid://126081405469607",
    RUN_VAULT_ID  = "rbxassetid://83873880822918",
    SPEED         = 2,
    ResetDelay    = 2,
}
Config.CrosshairDrawings = {}
Config.DisabledEffects   = {}
Config.DisabledSkies     = {}
Config.DisabledClouds    = {}
Config.DisabledTextures  = {}
Config.AttackPaths = {
    "Slasher-mob.Controls.attack",
    "Masked-mob.Controls.attack",
    "Killer-mob.Controls.attack",
    "Hidden-mob.Controls.attack"
}
Config.ScreenEffectTypes = {
    "ColorCorrectionEffect",
    "DepthOfFieldEffect",
    "BlurEffect",
    "SunRaysEffect",
    "BloomEffect"
}
Config.EmoteData = {
    ["24 Hour Cinderella"] = {anim = "rbxassetid://137195203725366", sound = "rbxassetid://121099446613414"},
    ["Applause"] = {anim = "rbxassetid://96328361165090", sound = "rbxassetid://115490787020749"},
    ["Arm Swing"] = {anim = "rbxassetid://80552139463944", sound = "rbxassetid://74216458932348"},
    ["Backflip"] = {anim = "rbxassetid://74705617908505"},
    ["Broken Doll"] = {anim = "rbxassetid://131796630104825", sound = "rbxassetid://88284355540646"},
    ["California Girls"] = {anim = "rbxassetid://123552803041504", sound = "rbxassetid://87899327891544"},
    ["Christmas Spirit"] = {anim = "rbxassetid://137859761110514"},
    ["Floating Rest"] = {anim = "rbxassetid://114593021219597"},
    ["Friday Night"] = {anim = "rbxassetid://83229063951016", sound = "rbxassetid://85355610204255"},
    ["Ghoul"] = {anim = "rbxassetid://130415594909401", sound = "rbxassetid://123004139176580"},
    ["Griddy"] = {anim = "rbxassetid://75586690784894"},
    ["Kwik Flip"] = {anim = "rbxassetid://73896868179198", sound = "rbxassetid://124209794918032"},
    ["Manrobics"] = {anim = "rbxassetid://134677515695156", sound = "rbxassetid://109596159930017"},
    ["Oneplays"] = {anim = "rbxassetid://140625405103474", sound = "rbxassetid://94749073728335"},
    ["Pop Off"] = {anim = "rbxassetid://130933486827090", sound = "rbxassetid://137966860089117"},
    ["Quick Combo"] = {anim = "rbxassetid://105592621576604", sound = "rbxassetid://88505795419631"},
    ["Rambunctious"] = {anim = "rbxassetid://81054496834622"},
    ["Rampage"] = {anim = "rbxassetid://79155929355612"},
    ["Schadenfreude"] = {anim = "rbxassetid://138303785534052", sound = "rbxassetid://92070710839040"},
    ["Source"] = {anim = "rbxassetid://122615684039119"},
    ["Static"] = {anim = "rbxassetid://95096724457263", sound = "rbxassetid://70950516511572"},
    ["The Dab"] = {anim = "rbxassetid://93350677984372"},
    ["Thriller"] = {anim = "rbxassetid://99835792883875", sound = "rbxassetid://139985043810748"},
    ["Tor Monitor Ketua"] = {anim = "rbxassetid://81792358514569", sound = "rbxassetid://72665050838808"},
    ["Vulnerable"] = {anim = "rbxassetid://121773684313913", sound = "rbxassetid://135265751184744"},
    ["Warcry"] = {anim = "rbxassetid://120101930689931", sound = "rbxassetid://82600868380136"},
    ["Wave"] = {anim = "rbxassetid://99670106766588"}
}
Config.EmoteButton.List = {}
for name, _ in pairs(Config.EmoteData) do
    table.insert(Config.EmoteButton.List, name)
end
table.sort(Config.EmoteButton.List)
Config.EmoteButton.Selected = Config.EmoteButton.List[1]
Config.PARRY_DEBOUNCE = 0.05
Config.TouchID        = 8822
Config.ActionPath     = "Survivor-mob.Controls.action.check"
Config.RayParams = RaycastParams.new()
Config.RayParams.FilterType = Enum.RaycastFilterType.Blacklist
Config.HeartbeatTasks = {}
Config.HeartbeatTasksArray = {}
Config.RenderSteppedTasks = {}
Config.RenderSteppedTasksArray = {}
