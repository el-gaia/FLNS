local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Library            = Shared.Library
local Options            = Shared.Options
local UI                 = Shared.UI
local Players            = Shared.Players
local UserInputService   = Shared.UserInputService
local RunService         = Shared.RunService
local Lighting           = Shared.Lighting
local TweenService       = Shared.TweenService
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
function Fn.applyMaxZoom()
    if Config.Connections.MaxZoomHook then
        Config.Connections.MaxZoomHook:Disconnect()
        Config.Connections.MaxZoomHook = nil
    end
    if Config.CameraZoom.MaxZoom then
        local function updateZoom()
            if not Config.CameraZoom.MaxZoom then return end
            local attrVal = LocalPlayer:GetAttribute("CameraMaxZoomDistance")
            local maxDist
            if type(attrVal) == "number" then
                maxDist = math.clamp(attrVal, Config.CameraZoom.MinDistance, Config.CameraZoom.MaxZoomMax)
            else
                maxDist = math.clamp(Config.CameraZoom.MaxDistance,
                                     Config.CameraZoom.MinDistance,
                                     Config.CameraZoom.MaxZoomMax)
            end
            if LocalPlayer.CameraMaxZoomDistance ~= maxDist then
                LocalPlayer.CameraMaxZoomDistance = maxDist
            end
            if LocalPlayer.CameraMinZoomDistance ~= Config.CameraZoom.MinDistance then
                LocalPlayer.CameraMinZoomDistance = Config.CameraZoom.MinDistance
            end
        end
        updateZoom()
        Config.Connections.MaxZoomHook = LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(updateZoom)
    else
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end
function Fn.applyCameraFOV()
    if Config.Connections.FOVHook then
        Config.Connections.FOVHook:Disconnect()
        Config.Connections.FOVHook = nil
    end
    if Config.Connections.CamHook then
        Config.Connections.CamHook:Disconnect()
        Config.Connections.CamHook = nil
    end
    local function updateFOV()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local targetFOV = Config.CameraZoom.FOVEnabled and Config.CameraZoom.FOV or Config.CameraZoom.DefaultFOV
        if cam.FieldOfView ~= targetFOV then
            cam.FieldOfView = targetFOV
        end
    end
    local function setupCamHook()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if Config.Connections.FOVHook then
            Config.Connections.FOVHook:Disconnect()
            Config.Connections.FOVHook = nil
        end
        if Config.CameraZoom.FOVEnabled then
            local function enforceFOV()
                if cam.FieldOfView ~= Config.CameraZoom.FOV then
                    cam.FieldOfView = Config.CameraZoom.FOV
                end
            end
            enforceFOV()
            Config.Connections.FOVHook = cam:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFOV)
        else
            updateFOV()
        end
    end
    setupCamHook()
    Config.Connections.CamHook = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setupCamHook)
end
function Fn.ApplyKorless()
    if not Config.KorlessState then
        Config.KorlessState = { active = true }
    else
        Config.KorlessState.active = true
    end
    Config.Korless.Enabled = true
    Fn.safeCall("KorlessHook", function()
        if Fn._CharLook_EnsureHook then
            Fn._CharLook_EnsureHook()
        end
    end)
    local plr = game.Players.LocalPlayer
    Config.KorlessState._morphBusy = false
    local function Morph()
        if Config.KorlessState._morphBusy then return end
        Config.KorlessState._morphBusy = true
        local tries = 0
        local char
        while tries < 50 do
            char = plr.Character
            if char
                and char:FindFirstChild("HumanoidRootPart")
                and char:FindFirstChild("Right Leg")
                and char:FindFirstChild("Head") then
                break
            end
            char = nil
            task.wait(0.1)
            tries = tries + 1
        end
        if not char then
            Config.KorlessState._morphBusy = false
            warn("[KorlessMorph] Character parts not ready after 5s, aborting Morph")
            return
        end
        task.wait(0.1)
        if not char.Parent or char ~= plr.Character then
            Config.KorlessState._morphBusy = false
            return
        end
        Fn.safeCall("KorlessMorph", function()
            char.Head.Transparency = 1
            local face = char.Head:FindFirstChild("face")
            if face then
                face:Destroy()
            end
            char["Right Leg"].Transparency = 1
            local existingMesh = char:FindFirstChild("KorlessHead")
            if existingMesh then existingMesh:Destroy() end
            local mesh = Instance.new("MeshPart")
            mesh.Name = "KorlessHead"
            mesh.Size = Vector3.new(1.5,1.5,1.5)
            mesh.CanCollide = false
            mesh.Anchored = false
            mesh.Massless = true
            mesh.MeshId = "rbxassetid://902942096"
            mesh.TextureID = "rbxassetid://902843398"
            mesh.CFrame = char["Right Leg"].CFrame * CFrame.new(0,0.5,0)
            mesh.Parent = char
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = char["Right Leg"]
            weld.Part1 = mesh
            weld.Parent = mesh
        end)
        Config.KorlessState._morphBusy = false
    end
    task.spawn(Morph)
    if Config.Connections.KorlessMorph then
        Fn._destroyConn("KorlessMorph", Config.Connections.KorlessMorph)
        Config.Connections.KorlessMorph = nil
    end
    Config.Connections.KorlessMorph = plr.CharacterAdded:Connect(function()
        if Config.State and Config.State.unloaded then return end
        if not Config.KorlessState or not Config.KorlessState.active then return end
        task.wait(1)
        task.spawn(Morph)
    end)
end
function Fn.RemoveKorless()
    Config.Korless.Enabled = false
    if Config.KorlessState then
        Config.KorlessState.active = false
        Config.KorlessState._morphBusy = false
    end
    if Config.Connections.KorlessMorph then
        Fn._destroyConn("KorlessMorph", Config.Connections.KorlessMorph)
        Config.Connections.KorlessMorph = nil
    end
    local plr = game.Players.LocalPlayer
    local char = plr and plr.Character
    if char then
        Fn.safeCall("KorlessMorphRestore", function()
            if char:FindFirstChild("Head") then
                char.Head.Transparency = 0
            end
            if char:FindFirstChild("Right Leg") then
                char["Right Leg"].Transparency = 0
            end
            local mesh = char:FindFirstChild("KorlessHead")
            if mesh then mesh:Destroy() end
        end)
    end
end
function Fn.applyVisual(force)
    if force or Config.LastVisualState.Fullbright ~= Config.Visual.Fullbright then
        Config.LastVisualState.Fullbright = Config.Visual.Fullbright
        if Config.Visual.Fullbright then
            Lighting.Brightness = 2; Lighting.ClockTime = 14
            Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1)
        else
            Lighting.Brightness = Config.OriginalLighting.Brightness
            Lighting.ClockTime  = Config.OriginalLighting.ClockTime
            Lighting.Ambient    = Config.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = Config.OriginalLighting.OutdoorAmbient
        end
    end
    if force or Config.LastVisualState.NoShadow ~= Config.Visual.NoShadow then
        Config.LastVisualState.NoShadow = Config.Visual.NoShadow
        Lighting.GlobalShadows = not Config.Visual.NoShadow
    end
    local ambientChanged = Config.LastVisualState.Ambient ~= Config.Visual.Ambient
        or Config.LastVisualState.AmbientColor ~= Config.Visual.AmbientColor
        or Config.LastVisualState.Brightness   ~= Config.Visual.Brightness
        or Config.LastVisualState.ClockTime    ~= Config.Visual.ClockTime
    if force or ambientChanged then
        Config.LastVisualState.Ambient      = Config.Visual.Ambient
        Config.LastVisualState.AmbientColor = Config.Visual.AmbientColor
        Config.LastVisualState.Brightness   = Config.Visual.Brightness
        Config.LastVisualState.ClockTime    = Config.Visual.ClockTime
        if Config.Visual.Ambient then
            Lighting.Ambient        = Config.Visual.AmbientColor
            Lighting.OutdoorAmbient = Config.Visual.AmbientColor
            Lighting.Brightness     = Config.Visual.Brightness
            Lighting.ClockTime      = Config.Visual.ClockTime
        elseif not Config.Visual.Fullbright then
            Lighting.Brightness     = Config.OriginalLighting.Brightness
            Lighting.ClockTime      = Config.OriginalLighting.ClockTime
            Lighting.Ambient        = Config.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = Config.OriginalLighting.OutdoorAmbient
        end
    end
end
Fn.hideSkyOrClouds = function(v)
    if not v or v.Parent == nil then return end
    if v:IsA("Sky") then
        if Config.DisabledSkies[v] == nil then
            Config.DisabledSkies[v] = v.Parent
        end
        pcall(function() v.Parent = nil end)
    elseif v:IsA("Clouds") then
        if Config.DisabledClouds[v] == nil then
            Config.DisabledClouds[v] = v.Parent
        end
        pcall(function() v.Parent = nil end)
    end
end
Fn.hideSurfaceAppearance = function(v)
    if not v or v.Parent == nil then return end
    if v:IsA("SurfaceAppearance") then
        if Config.DisabledTextures[v] == nil then
            Config.DisabledTextures[v] = v.Parent
        end
        pcall(function() v.Parent = nil end)
    end
end
local function getVisualCleanupContainers()
    local list = { Lighting }
    local map = workspace:FindFirstChild("Map")
    if map then table.insert(list, map) end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then table.insert(list, terrain) end
    return list
end
function Fn.applyOptimization(force)
    if not (force or Config.LastOptimizationState.CleanSky ~= Config.Visual.CleanSky) then
        return
    end
    Config.LastOptimizationState.CleanSky = Config.Visual.CleanSky
    if Config.Visual.CleanSky then
        for _, container in ipairs(getVisualCleanupContainers()) do
            pcall(function()
                for _, v in pairs(container:GetDescendants()) do
                    Fn.hideSkyOrClouds(v)
                end
            end)
        end
    else
        for sky, parent in pairs(Config.DisabledSkies) do
            if sky and parent then
                pcall(function() sky.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledSkies) do Config.DisabledSkies[k] = nil end
        for clouds, parent in pairs(Config.DisabledClouds) do
            if clouds and parent then
                pcall(function() clouds.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledClouds) do Config.DisabledClouds[k] = nil end
    end
end
function Fn.applyCleanTexture(force)
    if not (force or Config.LastOptimizationState.CleanTexture ~= Config.Visual.CleanTexture) then
        return
    end
    Config.LastOptimizationState.CleanTexture = Config.Visual.CleanTexture
    if Config.Visual.CleanTexture then
        for _, container in ipairs(getVisualCleanupContainers()) do
            pcall(function()
                for _, v in pairs(container:GetDescendants()) do
                    Fn.hideSurfaceAppearance(v)
                end
            end)
        end
    else
        for sa, parent in pairs(Config.DisabledTextures) do
            if sa and parent then
                pcall(function() sa.Parent = parent end)
            end
        end
        for k in pairs(Config.DisabledTextures) do Config.DisabledTextures[k] = nil end
    end
end
function Fn.applyNoScreenEffects()
    if Config.LastVisualState.NoScreenEffects == Config.Visual.NoScreenEffects then return end
    Config.LastVisualState.NoScreenEffects = Config.Visual.NoScreenEffects
    if Config.Visual.NoScreenEffects then
        for _, v in pairs(Lighting:GetChildren()) do
            for _, t in pairs(Config.ScreenEffectTypes) do
                if v:IsA(t) then Config.DisabledEffects[v] = v.Enabled; v.Enabled = false end
            end
        end
    else
        for obj, s in pairs(Config.DisabledEffects) do
            if obj and obj.Parent then obj.Enabled = s end
        end
        for k in pairs(Config.DisabledEffects) do Config.DisabledEffects[k] = nil end
    end
end
Config.Connections.LightingChild = Lighting.ChildAdded:Connect(function(v)
    if Config.Visual.CleanSky and (v:IsA("Sky") or v:IsA("Clouds")) then
        Fn.hideSkyOrClouds(v)
    end
    if Config.Visual.CleanTexture and v:IsA("SurfaceAppearance") then
        Fn.hideSurfaceAppearance(v)
    end
    if Config.Visual.NoScreenEffects then
        for _, t in pairs(Config.ScreenEffectTypes) do
            if v:IsA(t) then Config.DisabledEffects[v] = v.Enabled; v.Enabled = false end
        end
    end
end)
function Fn.enforceSmoothCamera()
    if not Fn.isSurvivorTeam() then
        return
    end
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local smoothCamera = character:FindFirstChild("SmoothCamera")
    if not smoothCamera then
        return
    end
    if not smoothCamera:IsA("LocalScript") then
        return
    end
    if Config.SmoothCam.Enabled then
        smoothCamera:SetAttribute("CameraHeight", Config.SmoothCam.Height)
        smoothCamera:SetAttribute("CameraStiffness", Config.SmoothCam.Stiffness)
    else
        smoothCamera:SetAttribute("CameraHeight", -1)
        smoothCamera:SetAttribute("CameraStiffness", 9.5)
    end
end
function Fn.resetSmoothCamera()
    local character = LocalPlayer.Character
    if not character then return end
    local smoothCamera = character:FindFirstChild("SmoothCamera")
    if smoothCamera and smoothCamera:IsA("LocalScript") then
        pcall(function() smoothCamera:SetAttribute("CameraHeight", -1) end)
        pcall(function() smoothCamera:SetAttribute("CameraStiffness", 9.5) end)
    end
end
UI.MorphAvaBox:AddButton({ Text = "Apply Korless",
    Func = function()
        Fn.ApplyKorless()
    end })
UI.MorphAvaBox:AddButton({ Text = "Remove Korless",
    Func = function()
        Fn.RemoveKorless()
    end })
UI.VisualBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false,
    Callback = function(v) Config.Visual.Fullbright = v; Fn.applyVisual() end }):AddKeyPicker("Fullbright_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.VisualBox:AddToggle("NoShadow", { Text = "No Shadow", Default = false,
    Callback = function(v) Config.Visual.NoShadow = v end }):AddKeyPicker("NoShadow_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.VisualBox:AddToggle("NoScreenEffects", { Text = "No Screen Effects", Default = false,
    Callback = function(v) Config.Visual.NoScreenEffects = v; Fn.applyNoScreenEffects() end }):AddKeyPicker("NoScreenEffects_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.VisualBox:AddToggle("CleanSky", { Text = "Clean Sky", Default = false,
    Callback = function(v) Config.Visual.CleanSky = v; Fn.applyOptimization() end }):AddKeyPicker("CleanSky_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.VisualBox:AddToggle("CleanTexture", { Text = "Clean Texture", Default = false,
    Callback = function(v) Config.Visual.CleanTexture = v; Fn.applyCleanTexture() end }):AddKeyPicker("CleanTexture_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.VisualBox:AddToggle("NoCutscene", { Text = "Skip End Screen", Default = false,
    Callback = function(v) Config.NoCutscene = v end }):AddKeyPicker("NoCutscene_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddToggle("ThirdPersonToggle", { Text = "Third Person View",
    Default = false,
    Callback = function(v)
        Config.Killer.ThirdPerson = v
        if not v then
            Fn.UpdateThirdPerson()
        end
    end }):AddKeyPicker("ThirdPersonToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddToggle("MaxZoom", { Text = "Max Zoom", Default = false,
    Callback = function(v) Config.CameraZoom.MaxZoom = v; Fn.applyMaxZoom() end }):AddKeyPicker("MaxZoom_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddSlider("MaxZoomDistance", { Text = "Max Zoom Distance", Default = 0.5, Min = 0.5, Max = 20, Rounding = 2,
    Callback = function(v)
        Config.CameraZoom.MaxDistance = v
        if Config.CameraZoom.MaxZoom then Fn.applyMaxZoom() end
    end })
UI.ZoomBox:AddToggle("CustomFOV", { Text = "Custom FOV", Default = false,
    Callback = function(v) Config.CameraZoom.FOVEnabled = v; Fn.applyCameraFOV() end }):AddKeyPicker("CustomFOV_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddSlider("CameraFOV", { Text = "Camera FOV", Default = 70, Min = 40, Max = 120, Rounding = 0,
    Callback = function(v)
        Config.CameraZoom.FOV = v
        if Config.CameraZoom.FOVEnabled then Fn.applyCameraFOV() end
    end })
UI.ZoomBox:AddToggle("SmoothCamToggle", { Text = "Smooth Camera",
    Default = false,
    Callback = function(v)
        Config.SmoothCam.Enabled = v
        Fn.safeCall("SmoothCam Toggle", Fn.enforceSmoothCamera)
    end }):AddKeyPicker("SmoothCamToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ZoomBox:AddSlider("SmoothCamStiffness", { Text = "Camera Stiffness",
    Default = 9.5, Min = 0, Max = 30, Rounding = 1,
    Callback = function(v)
        Config.SmoothCam.Stiffness = v
        if Config.SmoothCam.Enabled then
            Fn.safeCall("SmoothCam Stiffness", Fn.enforceSmoothCamera)
        end
    end })
UI.TimeBox:AddSlider("ClockTime", { Text = "Clock Time", Default = 14, Min = 0, Max = 24, Rounding = 0,
    Callback = function(v) Config.Visual.ClockTime = v; Config.Visual.Ambient = true; Fn.applyVisual() end })
UI.TimeBox:AddSlider("Brightness", { Text = "Brightness", Default = 2, Min = 0, Max = 5, Rounding = 1,
    Callback = function(v) Config.Visual.Brightness = v; Config.Visual.Ambient = true; Fn.applyVisual() end })
do
    local section = UI.MusicBox
    local notify  = Fn.notify
    if not Config._MusicPlayer then
        Config._MusicPlayer = { Sound = nil, Connections = {} }
    end
    local function mpTrackConn(conn)
        if conn and typeof(conn) == "RBXScriptConnection" then
            table.insert(Config._MusicPlayer.Connections, conn)
        end
        return conn
    end

    local function makeUI(parent, className, props)
        local obj = Instance.new(className)
        if parent ~= nil then obj.Parent = parent end
        if props then
            for k, v in pairs(props) do
                pcall(function() obj[k] = v end)
            end
        end
        return obj
    end

    local function resolveSectionContainer(sec)
        if typeof(sec) == "Instance" then
            return sec
        end
        for _, prop in ipairs({ "Container", "Handler", "Frame", "Content", "ContentFrame" }) do
            local ok, val = pcall(function() return sec[prop] end)
            if ok and val and typeof(val) == "Instance" and val:IsA("GuiObject") then
                return val
            end
        end
        local rootOk, root = pcall(function() return sec.Root end)
        if rootOk and root and typeof(root) == "Instance" then
            for _, child in ipairs(root:GetChildren()) do
                if child:IsA("Frame") and child:FindFirstChildOfClass("UIListLayout") then
                    return child
                end
            end
        end
        return nil
    end

    local function jsonEncodeString(s)
        return '"' .. s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t') .. '"'
    end

    local function jsonEncodeSongs(tbl)
        local items = {}
        for _, song in ipairs(tbl) do
            local isFile  = song.IsFile == true
            local saveId  = isFile and (song.RawPath or "") or (song.Id or "")
            local rawPath = isFile and (song.RawPath or "") or ""
            local entry = string.format(
                '{"Name":%s,"Id":%s,"Icon":%s,"RawPath":%s,"IsFile":"%s"}',
                jsonEncodeString(song.Name or ""),
                jsonEncodeString(saveId),
                jsonEncodeString(song.Icon or ""),
                jsonEncodeString(rawPath),
                tostring(isFile)
            )
            table.insert(items, entry)
        end
        return "[" .. table.concat(items, ",") .. "]"
    end

    local function jsonDecodeSongs(str)
        local result = {}
        local pos = 1
        while pos <= #str do
            local objStart = str:find("{", pos, true)
            if not objStart then break end
            local objEnd = str:find("}", objStart, true)
            if not objEnd then break end
            local obj = str:sub(objStart, objEnd)
            local entry = {}
            for key in obj:gmatch('"(%w+)"%s*:') do
                local _, valQ = obj:find('"' .. key .. '"%s*:%s*"', 1)
                if valQ then
                    local val = {}
                    local i = valQ + 1
                    while i <= #obj do
                        local c = obj:sub(i, i)
                        if c == '"' then break end
                        if c == '\\' then
                            i = i + 1
                            local esc = obj:sub(i, i)
                            local map = {['"']='"',['\\']='\\',['n']='\n',['r']='\r',['t']='\t'}
                            table.insert(val, map[esc] or esc)
                        else
                            table.insert(val, c)
                        end
                        i = i + 1
                    end
                    entry[key] = table.concat(val)
                end
            end
            if entry.Name and entry.Id and entry.Icon then table.insert(result, entry) end
            pos = objEnd + 1
        end
        return result
    end

    local MP_SAVE_FILE = "Fallens Directory/Music_Player.json"

    local function mp_canFileIO()
        return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    end

    local function mp_saveCustomSongs(songsTable, defaultCount)
        if not mp_canFileIO() then return end
        local custom = {}
        for i = defaultCount + 1, #songsTable do
            local song = songsTable[i]
            if song and not song.FromFolder then table.insert(custom, song) end
        end
        local saveDir = MP_SAVE_FILE:match("^(.+)/[^/\\]+$") or "Fallens Directory"
        local dirOk, dirExists = pcall(isfolder, saveDir)
        if not dirOk or not dirExists then
            local made = pcall(makefolder, saveDir)
            if not made then return end
        end
        pcall(writefile, MP_SAVE_FILE, jsonEncodeSongs(custom))
    end

    local function mp_loadCustomSongs()
        if not mp_canFileIO() then return {} end
        local existOk, exists = pcall(isfile, MP_SAVE_FILE)
        if not existOk or not exists then return {} end
        local ok, content = pcall(readfile, MP_SAVE_FILE)
        if not ok or not content or content == "" then return {} end
        local ok2, decoded = pcall(jsonDecodeSongs, content)
        if not ok2 or type(decoded) ~= "table" then return {} end
        for _, s in ipairs(decoded) do
            local isFile = (s.IsFile == "true")
            if not isFile and type(s.Id) == "string" and s.Id:match("^getcustomasset://") then
                isFile = true
            end
            s.IsFile = isFile
            if isFile then
                local raw = (type(s.RawPath) == "string" and s.RawPath ~= "" and s.RawPath) or nil
                if not raw and type(s.Id) == "string" and s.Id ~= ""
                    and not s.Id:match("^rbxassetid://")
                    and not s.Id:match("^getcustomasset://") then
                    raw = s.Id
                end
                s.RawPath = raw
            end
        end
        return decoded
    end

    local MP_MUSIC_FOLDER     = "Fallens Music"
    local MP_ICON_SONG_FOLDER = "rbxthumb://type=Asset&id=13780950281&w=150&h=150"
    local MP_AUDIO_EXTS = {
        ogg = { magic = "OggS" },
        mp3 = { magic = "\255\251", alt = "ID3" },
    }

    local function mp_canFolderIO()
        return mp_canFileIO()
            and type(isfolder)   == "function"
            and type(makefolder) == "function"
            and type(listfiles)  == "function"
    end

    local function mp_ensureMusicFolder()
        if not mp_canFolderIO() then return false end
        local ok, exists = pcall(isfolder, MP_MUSIC_FOLDER)
        if not ok or not exists then
            pcall(makefolder, MP_MUSIC_FOLDER)
        end
        return true
    end

    local function mp_resolveLocalAudio(path)
        if type(getcustomasset) == "function" then
            local ok, res = pcall(getcustomasset, path)
            if ok and res and res ~= "" then return res end
        end
        if type(getsynasset) == "function" then
            local ok, res = pcall(getsynasset, path)
            if ok and res and res ~= "" then return res end
        end
        if type(getasset) == "function" then
            local ok, res = pcall(getasset, path)
            if ok and res and res ~= "" then return res end
        end
        return nil
    end

    local function mp_validateAudioFile(data, ext)
        if not data or #data < 4 then return false end
        local info = MP_AUDIO_EXTS[ext]
        if not info then return false end
        local header = data:sub(1, 4)
        if header:sub(1, #info.magic) == info.magic then return true end
        if info.alt and header:sub(1, #info.alt) == info.alt then return true end
        return false
    end

    local function mp_loadFolderSongs()
        if not mp_canFolderIO() then return {} end
        mp_ensureMusicFolder()
        local okL, files = pcall(listfiles, MP_MUSIC_FOLDER)
        if not okL or type(files) ~= "table" then return {} end
        local result = {}
        for _, path in ipairs(files) do
            local filename    = path:match("[^/\\]+$") or path
            local ext         = (filename:match("%.([^%.]+)$") or ""):lower()
            if MP_AUDIO_EXTS[ext] then
                local displayName = filename:match("^(.-)%.[^%.]+$") or filename
                local okD, data   = pcall(readfile, path)
                local canPlay     = mp_validateAudioFile(data, ext)
                local resolvedId  = nil
                if canPlay then
                    resolvedId = mp_resolveLocalAudio(path)
                end
                table.insert(result, {
                    Name    = canPlay
                                and displayName
                                or  (displayName .. " (corrupt/unsupported)"),
                    Id      = resolvedId or "",
                    Icon    = MP_ICON_SONG_FOLDER,
                    IsFile  = true,
                    FromFolder = true,
                    RawPath = path,
                    CanPlay = canPlay,
                    FileExt = ext,
                })
            end
        end
        return result
    end

    local IC = Color3.fromRGB(215, 215, 215)
    local function clickLayer(parent, zi)
        return makeUI(parent, "TextButton", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = zi or 20
        })
    end

    local MP_LUCIDE_ICONS = {
        play         = "lucide:play",
        pause        = "lucide:pause",
        skipBack     = "lucide:skip-back",
        skipForward  = "lucide:skip-forward",
    }
    local MP_ICON_FALLBACKS = {
        play         = "rbxassetid://135609604299893",
        pause        = "rbxassetid://74873705394436",
        skipBack     = "rbxassetid://70466132711334",
        skipForward  = "rbxassetid://124844823753990",
    }

    local function _mp_makeLucideIcon(parent, iconName, S, color, bsz)
        bsz = bsz or parent.Size.X.Offset
        color = color or IC
        local iconLabel = makeUI(parent, "ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, S, 0, S),
            BackgroundTransparency = 1,
            ImageColor3 = color,
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
        })
        local resolved = false
        pcall(function()
            if Library and Library.SetIconMode then
                Library:SetIconMode(iconLabel, iconName)
                resolved = iconLabel.Image ~= ""
            end
        end)
        if not resolved then
            local fallback = MP_ICON_FALLBACKS[iconName == MP_LUCIDE_ICONS.play and "play"
                or iconName == MP_LUCIDE_ICONS.pause and "pause"
                or iconName == MP_LUCIDE_ICONS.skipBack and "skipBack"
                or iconName == MP_LUCIDE_ICONS.skipForward and "skipForward"
                or "play"]
            pcall(function() iconLabel.Image = fallback end)
        end
        return iconLabel
    end

    local function iconSkipBack(parent, S, color)
        return _mp_makeLucideIcon(parent, MP_LUCIDE_ICONS.skipBack, S, color)
    end
    local function iconSkipForward(parent, S, color)
        return _mp_makeLucideIcon(parent, MP_LUCIDE_ICONS.skipForward, S, color)
    end
    local function iconPlay(parent, S, color, bsz)
        return _mp_makeLucideIcon(parent, MP_LUCIDE_ICONS.play, S, color, bsz)
    end
    local function iconPause(parent, S, color, bsz)
        return _mp_makeLucideIcon(parent, MP_LUCIDE_ICONS.pause, S, color, bsz)
    end

    local function _mp_buildInfoSection(parent, MP_ICON_SONG, MP_ICON_VOL, MP_ICON_MUTE)
        task.spawn(function()
            local ContentProvider = game:GetService("ContentProvider")
            local preloadInstances = {}
            for _, id in ipairs({ MP_ICON_SONG, MP_ICON_VOL, MP_ICON_MUTE }) do
                local tmp = Instance.new("ImageLabel")
                tmp.Image = id
                table.insert(preloadInstances, tmp)
            end
            pcall(function() ContentProvider:PreloadAsync(preloadInstances) end)
            for _, img in ipairs(preloadInstances) do img:Destroy() end
        end)
        local songInfoFrame = makeUI(parent, "Frame", {
            Size = UDim2.new(1, -2, 0, 32),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BackgroundTransparency = 0.2, BorderSizePixel = 0
        })
        makeUI(songInfoFrame, "UICorner", { CornerRadius = UDim.new(0, 8) })
        makeUI(songInfoFrame, "TextLabel", {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 8, 0, 4),
            BackgroundTransparency = 1, Text = "NOW PLAYING",
            TextColor3 = Library.Scheme.FontColor , TextSize = 9,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
        })
        local songNameLabel = makeUI(songInfoFrame, "TextLabel", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 18),
            BackgroundTransparency = 1, Text = "Select a song",
            TextColor3 = Library.Scheme.FontColor , TextSize = 12,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        return {
            songNameLabel = songNameLabel,
        }
    end

    local function _mp_buildProgressSection(parent, sound)
        local function formatTime(s)
            if not s or s < 0 then return "0:00" end
            return string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
        end
        local progressOuter = makeUI(parent, "Frame", {
            Size = UDim2.new(1, -2, 0, 6),
            BackgroundColor3 = Color3.fromRGB(55, 55, 55), BorderSizePixel = 0, ZIndex = 2
        })
        makeUI(progressOuter, "UICorner", { CornerRadius = UDim.new(1, 0) })
        local progressBar = makeUI(progressOuter, "Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(130, 130, 130), BorderSizePixel = 0, ZIndex = 3
        })
        makeUI(progressBar, "UICorner", { CornerRadius = UDim.new(1, 0) })
        local progressThumb = makeUI(progressOuter, "Frame", {
            Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            BorderSizePixel = 0, ZIndex = 5, Visible = false
        })
        makeUI(progressThumb, "UICorner", { CornerRadius = UDim.new(1, 0) })
        local progressHit = makeUI(progressOuter, "TextButton", {
            Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.5, -10),
            BackgroundTransparency = 1, Text = "", ZIndex = 10
        })
        local timeRow = makeUI(parent, "Frame", {
            Size = UDim2.new(1, -2, 0, 12), BackgroundTransparency = 1, BorderSizePixel = 0
        })
        local currentTimeLabel = makeUI(timeRow, "TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = "0:00",
            TextColor3 = Library.Scheme.FontColor , TextSize = 10,
            Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left
        })
        local totalTimeLabel = makeUI(timeRow, "TextLabel", {
            Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1, Text = "0:00",
            TextColor3 = Library.Scheme.FontColor , TextSize = 10,
            Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right
        })
        local isScrubbing = false
        local function getSeekRatio(inputPos)
            local outerPos  = progressOuter.AbsolutePosition
            local outerSize = progressOuter.AbsoluteSize
            return math.clamp((inputPos.X - outerPos.X) / outerSize.X, 0, 1)
        end
        local function seekTo(ratio)
            if sound.IsLoaded and sound.TimeLength and sound.TimeLength > 0 then
                sound.TimePosition = ratio * sound.TimeLength
                progressBar.Size = UDim2.new(ratio, 0, 1, 0)
                progressThumb.Position = UDim2.new(ratio, 0, 0.5, 0)
                currentTimeLabel.Text = formatTime(ratio * sound.TimeLength)
            end
        end
        mpTrackConn(progressHit.MouseEnter:Connect(function()
            progressThumb.Visible = true
            TweenService:Create(progressOuter, TweenInfo.new(0.1), { Size = UDim2.new(1, -2, 0, 8) }):Play()
            TweenService:Create(progressBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(180, 180, 180) }):Play()
        end))
        mpTrackConn(progressHit.MouseLeave:Connect(function()
            if not isScrubbing then
                progressThumb.Visible = false
                TweenService:Create(progressOuter, TweenInfo.new(0.1), { Size = UDim2.new(1, -2, 0, 6) }):Play()
                TweenService:Create(progressBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(130, 130, 130) }):Play()
            end
        end))
        mpTrackConn(progressHit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isScrubbing = true; progressThumb.Visible = true; seekTo(getSeekRatio(input.Position))
            end
        end))
        mpTrackConn(UserInputService.InputChanged:Connect(function(input)
            if isScrubbing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                seekTo(getSeekRatio(input.Position))
            end
        end))
        mpTrackConn(UserInputService.InputEnded:Connect(function(input)
            if isScrubbing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                isScrubbing = false
                seekTo(getSeekRatio(input.Position))
                progressThumb.Visible = false
                TweenService:Create(progressOuter, TweenInfo.new(0.1), { Size = UDim2.new(1, -2, 0, 6) }):Play()
                TweenService:Create(progressBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(130, 130, 130) }):Play()
            end
        end))
        return {
            progressBar      = progressBar,
            progressThumb    = progressThumb,
            currentTimeLabel = currentTimeLabel,
            totalTimeLabel   = totalTimeLabel,
            isScrubbing      = function() return isScrubbing end,
            formatTime       = formatTime,
        }
    end

    local function _mp_buildControls(parent)
        local BTN_SM = 34; local BTN_LG = 44
        local ICON_SM = 14; local ICON_LG = 16
        local controlRow = makeUI(parent, "Frame", {
            Size = UDim2.new(1, -2, 0, 52), BackgroundTransparency = 1, BorderSizePixel = 0
        })
        local prevFrame = makeUI(controlRow, "Frame", {
            Size = UDim2.new(0, BTN_SM, 0, BTN_SM),
            Position = UDim2.new(0.5, -BTN_LG/2-BTN_SM-8, 0.5, -BTN_SM/2),
            BackgroundColor3 = Color3.fromRGB(48,48,48), BorderSizePixel = 0
        })
        makeUI(prevFrame, "UICorner", { CornerRadius = UDim.new(1,0) })
        makeUI(prevFrame, "UIStroke", { Color = Color3.fromRGB(80,80,80), Thickness = 1, Transparency = 0.2 })
        iconSkipBack(prevFrame, ICON_SM, IC)
        local prevClick = clickLayer(prevFrame, 20)
        local playFrame = makeUI(controlRow, "Frame", {
            Size = UDim2.new(0, BTN_LG, 0, BTN_LG),
            Position = UDim2.new(0.5, -BTN_LG/2, 0.5, -BTN_LG/2),
            BackgroundColor3 = Color3.fromRGB(55,55,55), BorderSizePixel = 0
        })
        makeUI(playFrame, "UICorner", { CornerRadius = UDim.new(1,0) })
        makeUI(playFrame, "UIStroke", { Color = Color3.fromRGB(100,100,100), Thickness = 1.2, Transparency = 0.1 })
        local playIconHolder = makeUI(playFrame, "Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 2 })
        iconPlay(playIconHolder, ICON_LG, IC, BTN_LG)
        local pauseIconHolder = makeUI(playFrame, "Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ZIndex = 2, Visible = false })
        iconPause(pauseIconHolder, ICON_LG, IC, BTN_LG)
        local playClick = clickLayer(playFrame, 20)
        local nextFrame = makeUI(controlRow, "Frame", {
            Size = UDim2.new(0, BTN_SM, 0, BTN_SM),
            Position = UDim2.new(0.5, BTN_LG/2+8, 0.5, -BTN_SM/2),
            BackgroundColor3 = Color3.fromRGB(48,48,48), BorderSizePixel = 0
        })
        makeUI(nextFrame, "UICorner", { CornerRadius = UDim.new(1,0) })
        makeUI(nextFrame, "UIStroke", { Color = Color3.fromRGB(80,80,80), Thickness = 1, Transparency = 0.2 })
        iconSkipForward(nextFrame, ICON_SM, IC)
        local nextClick = clickLayer(nextFrame, 20)
        mpTrackConn(prevClick.MouseEnter:Connect(function()
            TweenService:Create(prevFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(68,68,68) }):Play()
        end))
        mpTrackConn(prevClick.MouseLeave:Connect(function()
            TweenService:Create(prevFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(48,48,48) }):Play()
        end))
        mpTrackConn(nextClick.MouseEnter:Connect(function()
            TweenService:Create(nextFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(68,68,68) }):Play()
        end))
        mpTrackConn(nextClick.MouseLeave:Connect(function()
            TweenService:Create(nextFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(48,48,48) }):Play()
        end))
        mpTrackConn(playClick.MouseEnter:Connect(function()
            TweenService:Create(playFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(75,75,75) }):Play()
        end))
        mpTrackConn(playClick.MouseLeave:Connect(function()
            TweenService:Create(playFrame, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(55,55,55) }):Play()
        end))
        return {
            playClick       = playClick,
            prevClick       = prevClick,
            nextClick       = nextClick,
            playIconHolder  = playIconHolder,
            pauseIconHolder = pauseIconHolder,
        }
    end

    local function _mp_buildVolumeSection(sec, MP_ICON_VOL, MP_ICON_MUTE, sound, isMutedRef, savedVolumeRef)
        local function setVolume(vol)
            vol = math.clamp(vol, 0, 1)
            sound.Volume = vol
            if not isMutedRef[1] then savedVolumeRef[1] = vol end
        end
        local volSlider = sec:AddSlider("MusicVolume", {
            Text = "Volume",
            Default = 50,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Suffix = "%",
            Callback = function(v)
                local vol = v / 100
                if isMutedRef[1] and v > 0 then
                    isMutedRef[1] = false
                end
                setVolume(vol)
            end,
        })
        local muteBtn = sec:AddButton({
            Text = "Mute",
            Func = function()
                isMutedRef[1] = not isMutedRef[1]
                if isMutedRef[1] then
                    savedVolumeRef[1] = sound.Volume > 0 and sound.Volume or savedVolumeRef[1]
                    sound.Volume = 0
                    muteBtn:SetText("Unmute")
                    if volSlider and volSlider.SetValue then
                        volSlider:SetValue(0)
                    end
                else
                    setVolume(savedVolumeRef[1])
                    muteBtn:SetText("Mute")
                    if volSlider and volSlider.SetValue then
                        volSlider:SetValue(math.floor(savedVolumeRef[1] * 100))
                    end
                end
            end,
        })
        setVolume(savedVolumeRef[1])
        return {
            volSlider = volSlider,
            muteBtn   = muteBtn,
        }
    end

    local function createMusicPlayerPage(sec)
        local MP_ICON_SONG = "rbxthumb://type=Asset&id=13780950281&w=150&h=150"
        local MP_ICON_VOL  = "rbxthumb://type=Asset&id=117386765962827&w=150&h=150"
        local MP_ICON_MUTE = "rbxthumb://type=Asset&id=96383895319411&w=150&h=150"
        local DEFAULT_SONGS = {
            { Name = "Kagayaku Shunkan", Id = "rbxassetid://113287483392873", Icon = MP_ICON_SONG }
        }
        local DEFAULT_COUNT = #DEFAULT_SONGS
        local songs = {}
        for _, s in ipairs(DEFAULT_SONGS) do table.insert(songs, s) end
        for _, s in ipairs(mp_loadCustomSongs()) do
            if s.IsFile and s.RawPath then
                local resolved = mp_resolveLocalAudio(s.RawPath)
                s.Id      = resolved or ""
                s.CanPlay = (resolved ~= nil)
            elseif s.IsFile then
                s.Id = ""; s.CanPlay = false
            end
            table.insert(songs, s)
        end
        local songByName = {}
        local function rebuildSongMap()
            songByName = {}
            for _, s in ipairs(songs) do songByName[s.Name] = s end
        end
        rebuildSongMap()
        local function getSongNames()
            local names = {}
            for _, s in ipairs(songs) do table.insert(names, s.Name) end
            return names
        end
        local sound = Instance.new("Sound")
        sound.Name = "FallensMusicPlayer"; sound.Volume = 0.5
        do
            local parented = pcall(function()
                sound.Parent = game:GetService("SoundService")
            end)
            if not parented then
                pcall(function()
                    sound.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                        or LocalPlayer
                end)
            end
        end
        local isMutedRef       = { false }
        local savedVolumeRef   = { 0.5 }
        local currentSongIndex = 1
        local isPlaying        = false
        local isChangingSong   = false
        local optionsFrame6 = resolveSectionContainer(sec)
        if not optionsFrame6 then
            warn("[FALLENS] Music Player: failed to resolve ModernV2 section container; custom widgets will not be rendered.")
            return sound
        end
        local infoResult  = _mp_buildInfoSection(optionsFrame6, MP_ICON_SONG, MP_ICON_VOL, MP_ICON_MUTE)
        local progResult  = _mp_buildProgressSection(optionsFrame6, sound)
        local ctrlResult  = _mp_buildControls(optionsFrame6)
        local volResult   = _mp_buildVolumeSection(sec, MP_ICON_VOL, MP_ICON_MUTE, sound, isMutedRef, savedVolumeRef)
        local songNameLabel  = infoResult.songNameLabel
        local progressBar    = progResult.progressBar
        local progressThumb  = progResult.progressThumb
        local currentTimeLabel = progResult.currentTimeLabel
        local totalTimeLabel   = progResult.totalTimeLabel
        local formatTime     = progResult.formatTime
        local playClick      = ctrlResult.playClick
        local prevClick      = ctrlResult.prevClick
        local nextClick      = ctrlResult.nextClick
        local playIconHolder = ctrlResult.playIconHolder
        local pauseIconHolder = ctrlResult.pauseIconHolder
        local volSlider      = volResult.volSlider
        local muteBtn        = volResult.muteBtn
        local function setPlayState(playing)
            playIconHolder.Visible  = not playing
            pauseIconHolder.Visible = playing
        end
        local function playSongByName(songName, autoPlay)
            local songEntry = songByName[songName]
            if not songEntry then return end
            for i, s in ipairs(songs) do
                if s.Name == songName then currentSongIndex = i; break end
            end
            isChangingSong = true
            sound:Stop(); sound.TimePosition = 0
            if songEntry.IsFile then
                if songEntry.CanPlay == false then
                    songNameLabel.Text = "File missing, corrupt, or unsupported!"
                    isPlaying = false; setPlayState(false)
                    task.defer(function() isChangingSong = false end); return
                end
                local assigned = false
                if songEntry.Id and songEntry.Id ~= "" then
                    local ok1 = pcall(function() sound.SoundId = songEntry.Id end)
                    if ok1 then assigned = true end
                end
                if not assigned and songEntry.RawPath then
                    local resolved = mp_resolveLocalAudio(songEntry.RawPath)
                    if resolved then
                        songEntry.Id = resolved
                        local ok2 = pcall(function() sound.SoundId = resolved end)
                        if ok2 then assigned = true end
                    end
                end
                if not assigned then
                    local fmt = songEntry.FileExt and songEntry.FileExt:upper() or "audio"
                    songNameLabel.Text = "Failed to load " .. fmt .. " file!"
                    isPlaying = false; setPlayState(false)
                    task.defer(function() isChangingSong = false end); return
                end
            else
                local okSet = pcall(function() sound.SoundId = songEntry.Id end)
                if not okSet then
                    songNameLabel.Text = "Invalid sound ID!"
                    isPlaying = false; setPlayState(false)
                    task.defer(function() isChangingSong = false end); return
                end
            end
            songNameLabel.Text = songEntry.Name
            if autoPlay then
                isPlaying = true; setPlayState(true)
                local wantId = tostring(songEntry.Id)
                task.spawn(function()
                    pcall(function()
                        if not sound.IsLoaded then
                            local loaded = false
                            local conn = sound.Loaded:Connect(function() loaded = true end)
                            local t0 = os.clock()
                            while not loaded and not sound.IsLoaded and os.clock() - t0 < 8 do
                                task.wait(0.1)
                            end
                            if conn then conn:Disconnect() end
                        end
                        if sound.IsLoaded then
                            sound.TimePosition = 0; sound:Play()
                        elseif isPlaying and sound.SoundId == wantId then
                            isPlaying = false; setPlayState(false)
                            songNameLabel.Text = (songEntry.Name or "?") .. " - failed to load"
                        end
                    end)
                end)
            end
            task.defer(function() isChangingSong = false end)
        end
        local playlistDropdown = sec:AddDropdown("MusicPlaylist", { Text = "Playlist",
            Values           = getSongNames(),
            Default          = songs[1] and songs[1].Name or nil,
            Multi            = false,
            Searchable = true,
            Callback         = function(value)
                if value and value ~= "" then
                    playSongByName(value, true)
                end
            end })
        local function rebuildPlaylist()
            rebuildSongMap()
            local names = getSongNames()
            Options.MusicPlaylist:SetValues(names)
        end
        sec:AddLabel("Add Custom Song")
        local songNameInput = sec:AddInput("MusicSongName", { Text = "Song Name",
            Default     = "",
            Placeholder = "Enter song name...",
            Numeric     = false,
        })
        local songIdInput = sec:AddInput("MusicSongId", { Text = "Sound ID / Path",
            Default     = "",
            Placeholder = "rbxassetid://ID  |  12345678  |  Fallens Music/song.mp3",
            Numeric     = false,
        })
        sec:AddButton({ Text = "+ Add Song",
            Func = function()
                local rawName = Options.MusicSongName.Value
                if type(rawName) == "string" then rawName = rawName:match("^%s*(.-)%s*$") end
                local rawId   = Options.MusicSongId.Value
                if type(rawId) == "string" then rawId = rawId:match("^%s*(.-)%s*$") end
                if not rawName or rawName == "" then
                    notify("Music Player", "Song name cannot be empty!", 3)
                    return
                end
                if not rawId or rawId == "" then
                    notify("Music Player", "Enter a Sound ID or local file path!", 3)
                    return
                end
                local finalId; local isFile = false
                if rawId:match("^rbxassetid://") then
                    finalId = rawId
                elseif rawId:match("^%d+$") then
                    finalId = "rbxassetid://" .. rawId
                elseif rawId:lower():match("%.mp3$") or rawId:lower():match("%.ogg$") then
                    if not mp_canFolderIO() then
                        notify("Music Player", "File IO not supported on this executor!", 3)
                        return
                    end
                    local okD, data = pcall(readfile, rawId)
                    local ext = (rawId:match("%.([^%.]+)$") or ""):lower()
                    if not mp_validateAudioFile(data, ext) then
                        notify("Music Player", "File not found or corrupt: " .. rawId, 4)
                        return
                    end
                    local resolved = mp_resolveLocalAudio(rawId)
                    if not resolved then
                        notify("Music Player", "GetCustomAsset() failed for this file!", 4)
                        return
                    end
                    finalId = resolved; isFile = true
                else
                    notify("Music Player", "Invalid input! Use ID, rbxassetid://, or .mp3/.ogg path", 4)
                    return
                end
                local finalName = rawName
                if songByName[finalName] then
                    local counter = 2
                    while songByName[finalName .. " (" .. counter .. ")"] do
                        counter = counter + 1
                    end
                    finalName = rawName .. " (" .. counter .. ")"
                end
                table.insert(songs, {
                    Name = finalName, Id = finalId, Icon = MP_ICON_SONG,
                    IsFile = isFile, RawPath = isFile and rawId or nil, CanPlay = true,
                })
                mp_saveCustomSongs(songs, DEFAULT_COUNT)
                rebuildPlaylist()
                Options.MusicSongName:SetText("")
                Options.MusicSongId:SetText("")
                notify("Music Player", "\"" .. finalName .. "\" added to playlist!", 3)
            end,
        })
        sec:AddButton({ Text = "- Remove Current Song",
            Func = function()
                local currentName = songs[currentSongIndex] and songs[currentSongIndex].Name
                if not currentName then
                    notify("Music Player", "No song selected.", 3)
                    return
                end
                if currentSongIndex <= DEFAULT_COUNT then
                    notify("Music Player", "Cannot remove default songs.", 3)
                    return
                end
                table.remove(songs, currentSongIndex)
                if currentSongIndex > #songs then currentSongIndex = #songs end
                if currentSongIndex < 1 then currentSongIndex = 1 end
                mp_saveCustomSongs(songs, DEFAULT_COUNT)
                rebuildPlaylist()
                local newName = songs[currentSongIndex] and songs[currentSongIndex].Name or nil
                if newName then
                    Options.MusicPlaylist:SetValue(newName)
                    songNameLabel.Text = newName
                else
                    songNameLabel.Text = "Select a song"
                end
                notify("Music Player", "Removed: " .. currentName, 3)
            end,
        })
        sec:AddLabel("Fallens Music Folder")
        sec:AddButton({ Text = "Scan Fallens Music Folder",
            Func = function()
                if not mp_canFolderIO() then
                    notify("Music Player", "File IO not supported on this executor!", 3)
                    return
                end
                task.spawn(function()
                    local newSongs, keptPaths = {}, {}
                    for _, s in ipairs(songs) do
                        if not s.IsFile or not s.FromFolder then
                            table.insert(newSongs, s)
                            if s.RawPath then keptPaths[s.RawPath] = true end
                        end
                    end
                    local folderSongs = mp_loadFolderSongs()
                    local added = 0
                    for _, s in ipairs(folderSongs) do
                        if not keptPaths[s.RawPath] then
                            table.insert(newSongs, s); added = added + 1
                        end
                    end
                    while #songs > 0 do table.remove(songs) end
                    for _, s in ipairs(newSongs) do table.insert(songs, s) end
                    rebuildPlaylist()
                    if #folderSongs == 0 then
                        notify("Music Player", "No MP3 or OGG files found in Fallens Music/ folder.", 4)
                    elseif added == 0 then
                        notify("Music Player", "Folder songs are already in the playlist.", 4)
                    else
                        notify("Music Player", added .. " audio file(s) found and added to playlist!", 4)
                    end
                end)
            end,
        })
        if songs[1] then
            songNameLabel.Text = songs[1].Name
        end
        mpTrackConn(playClick.MouseButton1Click:Connect(function()
            if not isPlaying then
                if not sound.SoundId or sound.SoundId == "" then
                    if songs[1] then
                        playSongByName(songs[1].Name, true)
                    end
                else
                    sound:Resume(); isPlaying = true; setPlayState(true)
                end
            else
                sound:Pause(); isPlaying = false; setPlayState(false)
            end
        end))
        mpTrackConn(nextClick.MouseButton1Click:Connect(function()
            local nextIdx = currentSongIndex % #songs + 1
            local nextName = songs[nextIdx] and songs[nextIdx].Name
            if nextName then
                Options.MusicPlaylist:SetValue(nextName)
            end
        end))
        mpTrackConn(prevClick.MouseButton1Click:Connect(function()
            local prevIdx = ((currentSongIndex - 2) % #songs) + 1
            local prevName = songs[prevIdx] and songs[prevIdx].Name
            if prevName then
                Options.MusicPlaylist:SetValue(prevName)
            end
        end))
        mpTrackConn(sound.Ended:Connect(function()
            if isChangingSong then return end
            if isPlaying then
                task.defer(function()
                    local nextIdx = currentSongIndex % #songs + 1
                    local nextName = songs[nextIdx] and songs[nextIdx].Name
                    if nextName then
                        Options.MusicPlaylist:SetValue(nextName)
                    end
                end)
            end
        end))
        local _mpTrackAcc = 0
        local _mpLastPosFloor = -1
        local _mpLastLenFloor = -1
        local _mpLastRatio    = -1
        mpTrackConn(RunService.Heartbeat:Connect(function(dt)
            if not sound.IsLoaded or not sound.TimeLength or sound.TimeLength <= 0 then return end
            if progResult.isScrubbing() then return end
            _mpTrackAcc = _mpTrackAcc + dt
            if _mpTrackAcc < 1/15 then return end
            _mpTrackAcc = 0
            local pos = sound.TimePosition or 0
            local len = sound.TimeLength
            local posFloor = math.floor(pos)
            local lenFloor = math.floor(len)
            local ratio = pos / len
            if ratio ~= _mpLastRatio then
                _mpLastRatio = ratio
                progressBar.Size = UDim2.new(ratio, 0, 1, 0)
                progressThumb.Position = UDim2.new(ratio, 0, 0.5, 0)
            end
            if posFloor ~= _mpLastPosFloor then
                _mpLastPosFloor = posFloor
                currentTimeLabel.Text = formatTime(pos)
            end
            if lenFloor ~= _mpLastLenFloor then
                _mpLastLenFloor = lenFloor
                totalTimeLabel.Text = formatTime(len)
            end
        end))
        return sound
    end

    local sound = createMusicPlayerPage(section)
    if sound then Config._MusicPlayer.Sound = sound end

    function Fn.unloadMusicPlayer()
        if not Config._MusicPlayer then return end
        if Config._MusicPlayer.Connections then
            for _, conn in ipairs(Config._MusicPlayer.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            Config._MusicPlayer.Connections = {}
        end
        if Config._MusicPlayer.Sound then
            pcall(function() Config._MusicPlayer.Sound:Stop() end)
            pcall(function() Config._MusicPlayer.Sound:Destroy() end)
            Config._MusicPlayer.Sound = nil
        end
        Config._MusicPlayer = nil
    end
end
do

    local function AttachAccessoryLocal(char, accessory)
        if not char or not accessory then return false end
        if not (accessory:IsA("Accessory") or accessory:IsA("Hat")) then return false end
        local handle = accessory:FindFirstChild("Handle")
        if not handle then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local ok, err = pcall(function() hum:AddAccessory(accessory) end)
            if ok then
                local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChild("AccessoryWeld")
                if weld then return true end
            end
        end
        accessory.Parent = char
        local handleAtt = handle:FindFirstChildOfClass("Attachment")
        if not handleAtt then return false end
        local targetAtt = nil
        local targetPart = nil
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local att = part:FindFirstChild(handleAtt.Name)
                if att and att:IsA("Attachment") then
                    targetAtt = att
                    targetPart = part
                    break
                end
            end
        end
        if targetAtt and targetPart then
            local oldWeld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChild("AccessoryWeld")
            if oldWeld then oldWeld:Destroy() end
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = targetPart
            weld.Part1 = handle
            weld.C0 = targetAtt.CFrame
            weld.C1 = handleAtt.CFrame
            weld.Parent = handle
            handle.Anchored = false
            handle.CanCollide = false
            return true
        end
        pcall(function()
            accessory.Parent = char
            local oldWeld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChild("AccessoryWeld")
            if oldWeld then oldWeld:Destroy() end
            local accType = accessory.AccessoryType
            local isHeadAcc = (
                accType == Enum.AccessoryType.Hat or
                accType == Enum.AccessoryType.Hair or
                accType == Enum.AccessoryType.Face or
                accType == Enum.AccessoryType.Unknown
            )
            local anchorName = isHeadAcc and "Head" or "HumanoidRootPart"
            local anchorPart = char:FindFirstChild(anchorName) or char:FindFirstChild("HumanoidRootPart")
            if not anchorPart then return end
            local offsetCF = anchorPart.CFrame:ToObjectSpace(handle.CFrame)
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = anchorPart
            weld.Part1 = handle
            weld.C0 = offsetCF
            weld.C1 = CFrame.new()
            weld.Parent = handle
            handle.Anchored = false
            handle.CanCollide = false
        end)
        return true
    end

    local function makeUniqueAccName(char, accessory)
        local baseName = accessory.Name
        baseName = baseName:gsub("_FLNS%d+$", "")
        accessory.Name = baseName
        local idx = 1
        local used = {}
        for _, obj in ipairs(char:GetChildren()) do
            if (obj:IsA("Accessory") or obj:IsA("Hat")) and obj ~= accessory then
                used[obj.Name] = true
            end
        end
        while used[accessory.Name] do
            idx = idx + 1
            accessory.Name = baseName .. "_FLNS" .. idx
        end
    end

    local RANDOM_IDS = {978663613,5261700291,1846241644,4993456331,424866237,4312175249,176548116,2270483006,1387071394,2705922253,10115152913,254675749,5282085572,2819144629,2342272463,3877709773,3641789924,5023103942,2298753899,5022264302,66372478,1059023987,2530406197,1992137495,402058769,1208673935,1735121788,3236271187,4797655515,8820259986,1538346377,7081300715,1648676291,2818915354,263336582,1510381464,683993767,1033636351,4004052767,7709627778,5196381745,4983064295,937392108,974086214,6004535943,744532329,2216132529,797871247,442581442,7927897698,4344692203,113408119,4439685307,670917583,5158458988,373349,2994206407,596318021,2574020621,7757117305,1780106970,3872493784,382383327,1921058820,1817915221,2799348313,189511979}

    local AC_CURRENT_AVATAR  = nil
    local AC_MORPH_SNAPSHOT  = nil
    local ac_statusLabel     = nil

    local AC = {}
    function AC.setStatus(text, color)
        if ac_statusLabel then
            pcall(function() ac_statusLabel:SetText("Status: " .. tostring(text)) end)
        end
    end

    local FLNS = {}
    FLNS.phantomModel       = nil
    FLNS.phantomConnections = {}
    FLNS.phantomReapplyConn = nil
    FLNS.phantomDestroying  = false
    FLNS.respawnHideConn    = nil

    function FLNS.getFloorOffset(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return 0 end
        local hipH = hum.HipHeight
        if hipH <= 0 then hipH = 2 end
        return hipH + hrp.Size.Y * 0.5
    end

    FLNS.isItemPart = function(v)
        if v:FindFirstAncestorOfClass("Tool") then return true end
        if Config and Config.ESPItems then
            local cur = v
            while cur do
                if Config.ESPItems[cur.Name] then return true end
                cur = cur.Parent
            end
        end
        return false
    end

    function FLNS.hideChar(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if not char:GetAttribute("FLNS_HRPHideApplied") then
                char:SetAttribute("FLNS_HRPHideApplied", true)
                char:SetAttribute("FLNS_OrigDDT", hum.DisplayDistanceType.Name)
                char:SetAttribute("FLNS_OrigNDD", hum.NameDisplayDistance)
                char:SetAttribute("FLNS_OrigHDD", hum.HealthDisplayDistance)
            end
            hum.DisplayDistanceType   = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance   = 0
            hum.HealthDisplayDistance = 0
        end
        for _, v in ipairs(char:GetDescendants()) do
            if FLNS.isItemPart(v) then continue end
            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                if v.Name ~= "HumanoidRootPart" then
                    if not v:GetAttribute("FLNS_Hidden") then
                        v:SetAttribute("FLNS_Hidden", true)
                        v:SetAttribute("FLNS_OrigT", v.Transparency)
                        if v:IsA("BasePart") then
                            v:SetAttribute("FLNS_OrigCS", v.CastShadow)
                        end
                    end
                    pcall(function() v.Transparency = 1 end)
                    if v:IsA("BasePart") then
                        pcall(function() v.CastShadow = false end)
                    end
                end
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                if not v:GetAttribute("FLNS_Hidden") then
                    v:SetAttribute("FLNS_Hidden", true)
                    v:SetAttribute("FLNS_OrigE", v.Enabled)
                end
                pcall(function() v.Enabled = false end)
            end
        end
    end

    function FLNS.rehideMarked(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and char:GetAttribute("FLNS_HRPHideApplied") then
            hum.DisplayDistanceType   = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance   = 0
            hum.HealthDisplayDistance = 0
        end
        for _, v in ipairs(char:GetDescendants()) do
            if v:GetAttribute("FLNS_Hidden") then
                if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                    if v.Name ~= "HumanoidRootPart" then
                        pcall(function() v.Transparency = 1 end)
                        if v:IsA("BasePart") then
                            pcall(function() v.CastShadow = false end)
                        end
                    end
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    pcall(function() v.Enabled = false end)
                end
            end
        end
    end

    function FLNS.connectHideConn(char)
        if FLNS.respawnHideConn then
            pcall(function() FLNS.respawnHideConn:Disconnect() end)
            FLNS.respawnHideConn = nil
        end
        FLNS.respawnHideConn = char.DescendantAdded:Connect(function(v)
            if FLNS.isItemPart(v) then return end
            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                if v.Name ~= "HumanoidRootPart" then
                    if not v:GetAttribute("FLNS_Hidden") then
                        v:SetAttribute("FLNS_Hidden", true)
                        v:SetAttribute("FLNS_OrigT", v.Transparency)
                        if v:IsA("BasePart") then
                            v:SetAttribute("FLNS_OrigCS", v.CastShadow)
                        end
                    end
                    pcall(function() v.Transparency = 1 end)
                    if v:IsA("BasePart") then
                        pcall(function() v.CastShadow = false end)
                    end
                end
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                if not v:GetAttribute("FLNS_Hidden") then
                    v:SetAttribute("FLNS_Hidden", true)
                    v:SetAttribute("FLNS_OrigE", v.Enabled)
                end
                pcall(function() v.Enabled = false end)
            end
        end)
        return FLNS.respawnHideConn
    end

    function FLNS.showChar(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local ddtName = char:GetAttribute("FLNS_OrigDDT")
            if ddtName then
                pcall(function()
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType[ddtName]
                        or Enum.HumanoidDisplayDistanceType.Subject
                end)
                hum.NameDisplayDistance   = char:GetAttribute("FLNS_OrigNDD") or 100
                hum.HealthDisplayDistance = char:GetAttribute("FLNS_OrigHDD") or 100
                char:SetAttribute("FLNS_OrigDDT", nil)
                char:SetAttribute("FLNS_OrigNDD", nil)
                char:SetAttribute("FLNS_OrigHDD", nil)
                char:SetAttribute("FLNS_HRPHideApplied", nil)
            else
                hum.DisplayDistanceType   = Enum.HumanoidDisplayDistanceType.Subject
                hum.NameDisplayDistance   = 100
                hum.HealthDisplayDistance = 100
            end
        end
        for _, v in ipairs(char:GetDescendants()) do
            if v:GetAttribute("FLNS_Hidden") then
                if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                    local origT = v:GetAttribute("FLNS_OrigT")
                    pcall(function() v.Transparency = (origT ~= nil) and origT or 0 end)
                    if v:IsA("BasePart") then
                        local origCS = v:GetAttribute("FLNS_OrigCS")
                        if origCS ~= nil then
                            pcall(function() v.CastShadow = origCS end)
                        else
                            pcall(function() v.CastShadow = true end)
                        end
                    end
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    local origE = v:GetAttribute("FLNS_OrigE")
                    pcall(function() v.Enabled = origE end)
                end
                v:SetAttribute("FLNS_Hidden", nil)
                v:SetAttribute("FLNS_OrigT", nil)
                v:SetAttribute("FLNS_OrigCS", nil)
                v:SetAttribute("FLNS_OrigE", nil)
            end
        end
    end

    FLNS.motorMap = {}
    function FLNS.buildMotorMap(realChar, phantomChar)
        FLNS.motorMap = {}
        if not realChar or not phantomChar then return end
        local phantomMotors = {}
        for _, m in ipairs(phantomChar:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part0 and m.Part1 then
                local key = m.Part0.Name .. "\0" .. m.Part1.Name
                phantomMotors[key] = m
                if m.Name and m.Name ~= "" then
                    phantomMotors["n:" .. m.Name] = phantomMotors["n:" .. m.Name] or m
                end
            end
        end
        for _, m in ipairs(realChar:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part0 and m.Part1 then
                local key = m.Part0.Name .. "\0" .. m.Part1.Name
                local pm = phantomMotors[key]
                if not pm and m.Name and m.Name ~= "" then
                    pm = phantomMotors["n:" .. m.Name]
                end
                if pm then
                    table.insert(FLNS.motorMap, { real = m, phantom = pm })
                end
            end
        end
    end

    function FLNS.preparePhantom(phantomChar)
        local hum = phantomChar:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType   = Enum.HumanoidDisplayDistanceType.None
            hum.NameDisplayDistance   = 0
            hum.HealthDisplayDistance = 0
            hum.AutoJumpEnabled       = false
            pcall(function()
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                hum.JumpHeight = 0
                hum.AutoRotate = false
                hum.PlatformStand = true
                hum.MaxHealth = 1e9
                hum.Health = 1e9
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            end)
            if not hum:FindFirstChildOfClass("Animator") then
                Instance.new("Animator", hum)
            end
        end
        for _, v in ipairs(phantomChar:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                v.Massless   = true
                v.CanTouch   = false
                v.CanQuery   = false
                if v.Name == "HumanoidRootPart" then
                    v.Anchored = true
                else
                    v.Anchored = false
                end
                pcall(function()
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
        for _, v in ipairs(phantomChar:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                pcall(function() v:Destroy() end)
            end
        end
    end

    function FLNS.destroyPhantom(keepHidden)
        pcall(function() RunService:UnbindFromRenderStep("FLNS_PhantomSync") end)
        if FLNS.respawnHideConn then
            pcall(function() FLNS.respawnHideConn:Disconnect() end)
            FLNS.respawnHideConn = nil
        end
        FLNS.motorMap = {}
        FLNS.phantomDestroying = true
        if FLNS.phantomModel then
            pcall(function() FLNS.phantomModel:Destroy() end)
            FLNS.phantomModel = nil
        end
        FLNS.phantomDestroying = false
        for _, conn in ipairs(FLNS.phantomConnections) do
            pcall(function() conn:Disconnect() end)
        end
        FLNS.phantomConnections = {}
        local char = LocalPlayer.Character
        if char then
            if not keepHidden then
                FLNS.showChar(char)
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera
            if cam and hum then
                cam.CameraSubject = hum
            end
        end
    end

    function FLNS.buildPhantom(desc, displayName)
        local char = LocalPlayer.Character
        if not char then return false, "No character" end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false, "No humanoid" end
        FLNS.hideChar(char)
        local hiddenChar = char
        local rigType = hum.RigType
        local ok, phantomChar = pcall(function()
            return Players:CreateHumanoidModelFromDescription(desc, rigType)
        end)
        if not ok or not phantomChar then
            if not FLNS.phantomModel then
                FLNS.showChar(char)
            end
            return false, "CreateHumanoidModelFromDescription failed"
        end
        phantomChar.Name = "FLNS_Phantom_" .. (displayName or "Avatar")
        FLNS.preparePhantom(phantomChar)
        FLNS.destroyPhantom(true)
        char = LocalPlayer.Character
        if not char then
            pcall(function() phantomChar:Destroy() end)
            pcall(function() FLNS.showChar(hiddenChar) end)
            return false, "No character"
        end
        hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            pcall(function() phantomChar:Destroy() end)
            pcall(function() FLNS.showChar(hiddenChar) end)
            return false, "No humanoid"
        end
        FLNS.hideChar(char)
        FLNS.connectHideConn(char)
        phantomChar.Parent = workspace
        FLNS.phantomModel   = phantomChar
        FLNS.buildMotorMap(char, phantomChar)
        do
            local cam = workspace.CurrentCamera
            if cam and hum then cam.CameraSubject = hum end
        end
        do
            local realHRP    = char:FindFirstChild("HumanoidRootPart")
            local phantomHRP = phantomChar:FindFirstChild("HumanoidRootPart")
            if realHRP and phantomHRP then
                local realFloor    = FLNS.getFloorOffset(char)
                local phantomFloor = FLNS.getFloorOffset(phantomChar)
                local realBaseY    = realHRP.Position.Y - realFloor
                phantomHRP.CFrame  = CFrame.new(
                    realHRP.Position.X,
                    realBaseY + phantomFloor,
                    realHRP.Position.Z
                ) * (realHRP.CFrame - realHRP.CFrame.Position)
            end
        end
        local phantomHum = phantomChar:FindFirstChildOfClass("Humanoid")
        if phantomHum then
            pcall(function()
                phantomHum.PlatformStand = true
                phantomHum.WalkSpeed = 0
                phantomHum.AutoRotate = false
            end)
        end
        local phantomVisualParts = {}
        local phantomBaseParts = {}
        for _, v in ipairs(phantomChar:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                table.insert(phantomVisualParts, v)
            end
            if v:IsA("BasePart") then
                table.insert(phantomBaseParts, v)
            end
        end
        local function syncLoop(dt)
            local realChar = LocalPlayer.Character
            if not realChar or not FLNS.phantomModel then return end
            if not FLNS.phantomModel.Parent then return end
            local realHRP    = realChar:FindFirstChild("HumanoidRootPart")
            local phantomHRP = FLNS.phantomModel:FindFirstChild("HumanoidRootPart")
            if realHRP and phantomHRP then
                local realFloor    = FLNS.getFloorOffset(realChar)
                local phantomFloor = FLNS.getFloorOffset(FLNS.phantomModel)
                local realBaseY    = realHRP.Position.Y - realFloor
                local targetCF = CFrame.new(
                    realHRP.Position.X,
                    realBaseY + phantomFloor,
                    realHRP.Position.Z
                ) * (realHRP.CFrame - realHRP.CFrame.Position)
                phantomHRP.CFrame = targetCF
                if not phantomHRP.Anchored then
                    phantomHRP.Anchored = true
                end
            end
            for i = 1, #FLNS.motorMap do
                local pair = FLNS.motorMap[i]
                local rm, pm = pair.real, pair.phantom
                if rm and pm and rm.Parent and pm.Parent then
                    pm.Transform = rm.Transform
                end
            end
            local cam = workspace.CurrentCamera
            if cam then
                local realHead = realChar:FindFirstChild("Head")
                if realHead then
                    local dist = (cam.CFrame.Position - realHead.Position).Magnitude
                    local firstPerson = dist < 1.0
                    local ltm = firstPerson and 1 or 0
                    for i = 1, #phantomVisualParts do
                        local v = phantomVisualParts[i]
                        if v.LocalTransparencyModifier ~= ltm then
                            v.LocalTransparencyModifier = ltm
                        end
                    end
                end
            end
        end
        RunService:BindToRenderStep("FLNS_PhantomSync", Enum.RenderPriority.Character.Value + 1, syncLoop)
        local _FLNSSteppedAcc = 0
        table.insert(FLNS.phantomConnections, RunService.Stepped:Connect(function(_, dt)
            if not FLNS.phantomModel or not FLNS.phantomModel.Parent then return end
            _FLNSSteppedAcc = _FLNSSteppedAcc + dt
            if _FLNSSteppedAcc < 0.1 then return end
            _FLNSSteppedAcc = 0
            for i = 1, #phantomBaseParts do
                local v = phantomBaseParts[i]
                if v.CanCollide then v.CanCollide = false end
                if not v.Massless then v.Massless = true end
                if v.CanTouch then v.CanTouch = false end
                if v.Name == "HumanoidRootPart" and not v.Anchored then
                    v.Anchored = true
                end
            end
        end))
        do
            local keepAlive = true
            table.insert(FLNS.phantomConnections, {
                Disconnect = function() keepAlive = false end
            })
            task.spawn(function()
                while keepAlive do
                    task.wait(1.5)
                    if not keepAlive then break end
                    if not FLNS.phantomModel or not FLNS.phantomModel.Parent then break end
                    local realChar = LocalPlayer.Character
                    if realChar then
                        FLNS.rehideMarked(realChar)
                    end
                    local ph = FLNS.phantomModel and FLNS.phantomModel:FindFirstChildOfClass("Humanoid")
                    if ph then
                        pcall(function()
                            if ph.Health < ph.MaxHealth then
                                ph.Health = ph.MaxHealth
                            end
                            ph.PlatformStand = true
                        end)
                    end
                end
            end)
        end
        do
            local thisPhantom = phantomChar
            local ancestryConn
            ancestryConn = thisPhantom.AncestryChanged:Connect(function(_, parent)
                if parent then return end
                if ancestryConn then pcall(function() ancestryConn:Disconnect() end) end
                if FLNS.phantomModel == thisPhantom then
                    FLNS.phantomModel = nil
                end
                if FLNS.phantomDestroying then return end
                if AC_CURRENT_AVATAR and AC_CURRENT_AVATAR.desc then
                    task.defer(function()
                        if FLNS.phantomDestroying then return end
                        if not AC_CURRENT_AVATAR then return end
                        if FLNS.phantomModel and FLNS.phantomModel.Parent then return end
                        local d = AC_CURRENT_AVATAR.desc
                        local n = AC_CURRENT_AVATAR.name
                        pcall(function() FLNS.buildPhantom(d, n) end)
                    end)
                end
            end)
            table.insert(FLNS.phantomConnections, ancestryConn)
        end
        return true, "Berhasil morph menjadi " .. (displayName or "Avatar")
    end

    local AC_MORPHCHAR
    AC_MORPHCHAR = function(char, name, id, desc, onDone, forPlayer)
        task.spawn(function()
            local okAll, errAll = xpcall(function()
                if not char or not char.Parent then return "Target character vanished" end
                local isLocalChar = (char == LocalPlayer.Character)
                if isLocalChar then
                    local ok, msg = FLNS.buildPhantom(desc, name)
                    if not ok then
                        AC.setStatus("Gagal: " .. tostring(msg), Color3.fromRGB(155, 45, 45))
                        return "Local morph failed: " .. tostring(msg)
                    end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and name then
                        pcall(function() hum.DisplayName = name end)
                    end
                    return nil
                else
                    local hum = char:WaitForChild("Humanoid", 5)
                    if not hum then return "Target has no Humanoid" end
                    local rigType = hum.RigType
                    local ok, refModel = pcall(function()
                        return Players:CreateHumanoidModelFromDescription(desc, rigType)
                    end)
                    if not ok or not refModel then return "Failed to build reference model" end
                    local snap = {
                        char = char, player = forPlayer,
                        displayName = hum.DisplayName,
                        parts = {}, accessories = {}, clothing = {}, charMeshes = {},
                        faceDecals = {}, scales = {},
                    }
                    for _, v in ipairs(char:GetChildren()) do
                        if v:IsA("Accessory") or v:IsA("Hat") then
                            table.insert(snap.accessories, v:Clone())
                        elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                            table.insert(snap.clothing, v:Clone())
                        elseif v:IsA("CharacterMesh") then
                            table.insert(snap.charMeshes, v:Clone())
                        end
                    end
                    local headSnap = char:FindFirstChild("Head")
                    if headSnap then
                        for _, d in ipairs(headSnap:GetChildren()) do
                            if d:IsA("Decal") then
                                table.insert(snap.faceDecals, { Name = d.Name, Texture = d.Texture, Face = d.Face })
                            end
                        end
                    end
                    local bcSnap = char:FindFirstChildOfClass("BodyColors")
                    if bcSnap then snap.bodyColors = bcSnap:Clone() end
                    local snapPartNames = {
                        "Head","UpperTorso","LowerTorso",
                        "RightUpperArm","RightLowerArm","RightHand",
                        "LeftUpperArm","LeftLowerArm","LeftHand",
                        "RightUpperLeg","RightLowerLeg","RightFoot",
                        "LeftUpperLeg","LeftLowerLeg","LeftFoot",
                        "Torso","Left Arm","Right Arm","Left Leg","Right Leg",
                    }
                    for _, pname in ipairs(snapPartNames) do
                        local dst = char:FindFirstChild(pname)
                        if dst and dst:IsA("BasePart") then
                            local rec = { isMesh = dst:IsA("MeshPart"), color = dst.Color }
                            if dst:IsA("MeshPart") then
                                rec.meshId    = dst.MeshId
                                rec.textureId = dst.TextureID
                            else
                                local sm = dst:FindFirstChildOfClass("SpecialMesh")
                                if sm then
                                    rec.sm = { MeshId = sm.MeshId, TextureId = sm.TextureId, Scale = sm.Scale }
                                end
                            end
                            snap.parts[pname] = rec
                        end
                    end
                    for _, sn in ipairs({"BodyHeightScale","BodyWidthScale","BodyHeadScale","BodyTypeScale","BodyProportionScale"}) do
                        local dv = hum:FindFirstChild(sn)
                        if dv then snap.scales[sn] = dv.Value end
                    end
                    if not (AC_MORPH_SNAPSHOT and AC_MORPH_SNAPSHOT.char == char) then
                        AC_MORPH_SNAPSHOT = snap
                    end
                    for _, v in ipairs(char:GetChildren()) do
                        if v:IsA("Accessory") or v:IsA("Hat")
                        or v:IsA("Shirt")       or v:IsA("Pants")
                        or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh")
                        or v:IsA("BodyColors") then
                            pcall(function() v:Destroy() end)
                        end
                    end
                    local head = char:FindFirstChild("Head")
                    if head then
                        for _, d in ipairs(head:GetChildren()) do
                            if d:IsA("Decal") then pcall(function() d:Destroy() end) end
                        end
                    end
                    local partNames = {
                        "Head","UpperTorso","LowerTorso",
                        "RightUpperArm","RightLowerArm","RightHand",
                        "LeftUpperArm","LeftLowerArm","LeftHand",
                        "RightUpperLeg","RightLowerLeg","RightFoot",
                        "LeftUpperLeg","LeftLowerLeg","LeftFoot",
                        "Torso","Left Arm","Right Arm","Left Leg","Right Leg",
                    }
                    for _, pname in ipairs(partNames) do
                        local src = refModel:FindFirstChild(pname)
                        local dst = char:FindFirstChild(pname)
                        if src and dst then
                            if src:IsA("MeshPart") and dst:IsA("MeshPart") then
                                pcall(function() dst.MeshId    = src.MeshId    end)
                                pcall(function() dst.TextureID = src.TextureID end)
                                pcall(function() dst.Color     = src.Color     end)
                            elseif src:IsA("Part") and dst:IsA("Part") then
                                pcall(function() dst.Color = src.Color end)
                                local sm = src:FindFirstChildOfClass("SpecialMesh")
                                if sm then
                                    local dm = dst:FindFirstChildOfClass("SpecialMesh")
                                    if not dm then dm = Instance.new("SpecialMesh"); dm.Parent = dst end
                                    pcall(function() dm.MeshId    = sm.MeshId    end)
                                    pcall(function() dm.TextureId = sm.TextureId end)
                                    pcall(function() dm.Scale     = sm.Scale     end)
                                end
                            end
                        end
                    end
                    local srcBC = refModel:FindFirstChildOfClass("BodyColors")
                    if srcBC then
                        local dstBC = char:FindFirstChildOfClass("BodyColors")
                        if not dstBC then dstBC = Instance.new("BodyColors"); dstBC.Parent = char end
                        for _, p in ipairs({"HeadColor3","TorsoColor3","LeftArmColor3","RightArmColor3","LeftLegColor3","RightLegColor3"}) do
                            pcall(function() dstBC[p] = srcBC[p] end)
                        end
                    end
                    local refHum = refModel:FindFirstChildOfClass("Humanoid")
                    if refHum then
                        for _, sn in ipairs({"BodyHeightScale","BodyWidthScale","BodyHeadScale","BodyTypeScale","BodyProportionScale"}) do
                            local sv = refHum:FindFirstChild(sn)
                            if sv then
                                local dv = hum:FindFirstChild(sn)
                                if not dv then dv = Instance.new("NumberValue"); dv.Name = sn; dv.Parent = hum end
                                pcall(function() dv.Value = sv.Value end)
                            end
                        end
                    end
                    for _, v in ipairs(refModel:GetChildren()) do
                        if v:IsA("Accessory") or v:IsA("Hat") then
                            local clone = v:Clone()
                            makeUniqueAccName(char, clone)
                            AttachAccessoryLocal(char, clone)
                        elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                            local clone = v:Clone()
                            clone.Parent = char
                        end
                    end
                    refModel:Destroy()
                    if name then pcall(function() hum.DisplayName = name end) end
                    return nil
                end
            end, function(err)
                warn("[AvatarChanger] error:", err)
                return tostring(err)
            end)
            if onDone then
                onDone(okAll and errAll == nil, errAll)
            end
        end)
    end

    local AC_APPLYAVATAR
    AC_APPLYAVATAR = function(userid)
        task.spawn(function()
            xpcall(function()
                AC.setStatus("Fetching...", Color3.fromRGB(195, 165, 50))
                local txt  = tostring(userid):gsub("%s+", "")
                local ID   = tonumber(txt)
                local NAME = nil
                if ID then
                    local ok = pcall(function()
                        NAME = Players:GetNameFromUserIdAsync(ID)
                    end)
                    if not ok or not NAME then
                        AC.setStatus("User not found!", Color3.fromRGB(155, 45, 45))
                        return
                    end
                else
                    local ok = pcall(function()
                        ID   = Players:GetUserIdFromNameAsync(txt)
                        NAME = txt
                    end)
                    if not ok or not ID then
                        AC.setStatus("User not found!", Color3.fromRGB(155, 45, 45))
                        return
                    end
                    pcall(function() NAME = Players:GetNameFromUserIdAsync(ID) end)
                    NAME = NAME or txt
                end
                AC.setStatus("Loading avatar...", Color3.fromRGB(195, 165, 50))
                local ok_desc, DESC = pcall(function()
                    return Players:GetHumanoidDescriptionFromUserId(ID)
                end)
                if not ok_desc or not DESC then
                    AC.setStatus("Failed to load description!", Color3.fromRGB(155, 45, 45))
                    return
                end
                if FLNS.phantomReapplyConn then
                    pcall(function() FLNS.phantomReapplyConn:Disconnect() end)
                    FLNS.phantomReapplyConn = nil
                end
                if AC_CURRENT_AVATAR and AC_CURRENT_AVATAR._conn then
                    pcall(function() AC_CURRENT_AVATAR._conn:Disconnect() end)
                    AC_CURRENT_AVATAR._conn = nil
                end
                AC_CURRENT_AVATAR = {id = ID, name = NAME, desc = DESC}
                local ok_build, msg = FLNS.buildPhantom(DESC, NAME)
                if ok_build then
                    AC.setStatus("Applied: " .. NAME, Color3.fromRGB(55, 175, 55))
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then pcall(function() hum.DisplayName = NAME end) end
                    end
                else
                    AC.setStatus("Gagal: " .. tostring(msg), Color3.fromRGB(155, 45, 45))
                    return
                end
                FLNS.phantomReapplyConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if not (AC_CURRENT_AVATAR and AC_CURRENT_AVATAR.id == ID) then return end
                    if not newChar then return end
                    FLNS.hideChar(newChar)
                    FLNS.connectHideConn(newChar)
                    task.spawn(function()
                        local hum = newChar:WaitForChild("Humanoid", 5)
                        newChar:WaitForChild("HumanoidRootPart", 5)
                        pcall(function()
                            if hum then hum:GetAppliedDescription() end
                        end)
                        task.wait(0.15)
                        if not (AC_CURRENT_AVATAR and AC_CURRENT_AVATAR.id == ID) then return end
                        if not newChar or not newChar.Parent then return end
                        FLNS.buildPhantom(DESC, NAME)
                        if hum then pcall(function() hum.DisplayName = NAME end) end
                    end)
                end)
                AC_CURRENT_AVATAR._conn = FLNS.phantomReapplyConn
            end, function(err)
                AC.setStatus("Error!", Color3.fromRGB(155, 45, 45))
                warn("[AvatarChanger] error:", err)
            end)
        end)
    end

    local AC_APPLY_TO_PLAYER = function(targetInput)
        task.spawn(function()
            xpcall(function()
                if not AC_CURRENT_AVATAR then
                    AC.setStatus("Apply your avatar first!", Color3.fromRGB(195, 165, 50))
                    return
                end
                local txt = tostring(targetInput):gsub("%s+", "")
                if txt == "" then
                    AC.setStatus("Enter target username/ID!", Color3.fromRGB(195, 165, 50))
                    return
                end
                AC.setStatus("Searching for target...", Color3.fromRGB(195, 165, 50))
                local targetPlayer = nil
                local txtLower = txt:lower()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        if plr.Name:lower() == txtLower or plr.DisplayName:lower() == txtLower then
                            targetPlayer = plr; break
                        end
                    end
                end
                if not targetPlayer then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer then
                            if plr.Name:lower():find(txtLower, 1, true) or plr.DisplayName:lower():find(txtLower, 1, true) then
                                targetPlayer = plr; break
                            end
                        end
                    end
                end
                local numId = tonumber(txt)
                if not targetPlayer and numId then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.UserId == numId then
                            targetPlayer = plr; break
                        end
                    end
                end
                if not targetPlayer then
                    AC.setStatus("Player not found on server!", Color3.fromRGB(155, 45, 45))
                    return
                end
                local targetChar = targetPlayer.Character
                if not targetChar then
                    AC.setStatus("Character " .. targetPlayer.Name .. " not found!", Color3.fromRGB(155, 45, 45))
                    return
                end
                AC.setStatus("Applying to " .. targetPlayer.Name .. "...", Color3.fromRGB(195, 165, 50))
                AC_MORPHCHAR(targetChar, targetPlayer.DisplayName, AC_CURRENT_AVATAR.id, AC_CURRENT_AVATAR.desc, function(okM, msg)
                    if okM then
                        AC.setStatus("Applied to: " .. targetPlayer.Name, Color3.fromRGB(55, 175, 55))
                    else
                        AC.setStatus("Morph failed: " .. tostring(msg), Color3.fromRGB(155, 45, 45))
                    end
                end, targetPlayer)
            end, function(err)
                AC.setStatus("Error!", Color3.fromRGB(155, 45, 45))
            end)
        end)
    end

    local function AC_UNDO_MORPH()
        local snap = AC_MORPH_SNAPSHOT
        if not snap then
            AC.setStatus("No player morph to undo", Color3.fromRGB(195, 165, 50))
            return
        end
        local char = snap.char
        if not char or not char.Parent then
            AC_MORPH_SNAPSHOT = nil
            AC.setStatus("Target left - morph already reset by respawn", Color3.fromRGB(195, 165, 50))
            return
        end
        if snap.player and snap.player.Parent and snap.player.Character ~= char then
            AC_MORPH_SNAPSHOT = nil
            AC.setStatus("Target respawned - morph already reset", Color3.fromRGB(195, 165, 50))
            return
        end
        task.spawn(function()
            local okAll, errAll = xpcall(function()
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum then return "Target has no Humanoid" end
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants")
                    or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
                        pcall(function() v:Destroy() end)
                    end
                end
                for pname, rec in pairs(snap.parts) do
                    local dst = char:FindFirstChild(pname)
                    if dst and dst:IsA("BasePart") then
                        pcall(function() dst.Color = rec.color end)
                        if rec.isMesh then
                            pcall(function() dst.MeshId = rec.meshId end)
                            pcall(function() dst.TextureID = rec.textureId end)
                        else
                            local sm = dst:FindFirstChildOfClass("SpecialMesh")
                            if rec.sm then
                                if not sm then
                                    sm = Instance.new("SpecialMesh")
                                    sm.Parent = dst
                                end
                                pcall(function() sm.MeshId = rec.sm.MeshId end)
                                pcall(function() sm.TextureId = rec.sm.TextureId end)
                                pcall(function() sm.Scale = rec.sm.Scale end)
                            elseif sm then
                                pcall(function() sm:Destroy() end)
                            end
                        end
                    end
                end
                local head = char:FindFirstChild("Head")
                if head then
                    for _, fd in ipairs(snap.faceDecals) do
                        pcall(function()
                            local d = Instance.new("Decal")
                            d.Name = fd.Name
                            d.Texture = fd.Texture
                            d.Face = fd.Face
                            d.Parent = head
                        end)
                    end
                end
                if snap.bodyColors then
                    pcall(function() snap.bodyColors:Clone().Parent = char end)
                end
                for _, c in ipairs(snap.charMeshes) do
                    pcall(function() c:Clone().Parent = char end)
                end
                for _, c in ipairs(snap.clothing) do
                    pcall(function() c:Clone().Parent = char end)
                end
                for _, c in ipairs(snap.accessories) do
                    pcall(function()
                        local acc = c:Clone()
                        makeUniqueAccName(char, acc)
                        AttachAccessoryLocal(char, acc)
                    end)
                end
                for sn, val in pairs(snap.scales) do
                    local dv = hum:FindFirstChild(sn)
                    if dv then pcall(function() dv.Value = val end) end
                end
                pcall(function() hum.DisplayName = snap.displayName end)
                return nil
            end, function(err)
                warn("[AvatarChanger] undo error:", err)
                return tostring(err)
            end)
            if okAll and errAll == nil then
                AC_MORPH_SNAPSHOT = nil
                AC.setStatus("Restored target's original avatar", Color3.fromRGB(55, 175, 55))
            else
                AC.setStatus("Undo failed: " .. tostring(errAll), Color3.fromRGB(155, 45, 45))
            end
        end)
    end

    Config._AvatarChangerCleanup = function()
        if FLNS.phantomReapplyConn then
            pcall(function() FLNS.phantomReapplyConn:Disconnect() end)
            FLNS.phantomReapplyConn = nil
        end
        if AC_CURRENT_AVATAR and AC_CURRENT_AVATAR._conn then
            pcall(function() AC_CURRENT_AVATAR._conn:Disconnect() end)
            AC_CURRENT_AVATAR._conn = nil
        end
        AC_CURRENT_AVATAR = nil
        AC_MORPH_SNAPSHOT = nil
        if FLNS.phantomModel or #FLNS.phantomConnections > 0 or FLNS.respawnHideConn then
            FLNS.destroyPhantom()
        end
    end

    local ac_state = { input = "", target = "" }
    ac_statusLabel = UI.AvatarChangerBox:AddLabel("Status: Idle")
    UI.AvatarChangerBox:AddInput("ACInput", { Default = "",
        Numeric = false,
        Finished = true,
        Text = "User ID / Username",
        Placeholder = "User ID or Username",
        Callback = function(Value)
            ac_state.input = Value
        end })
    UI.AvatarChangerBox:AddInput("ACTarget", { Default = "",
        Numeric = false,
        Finished = true,
        Text = "Target Player",
        Placeholder = "PlayerName or DisplayName",
        Callback = function(Value)
            ac_state.target = Value
        end })
    UI.AvatarChangerBox:AddButton({ Text = "Apply Avatar",
        Func = function()
            if ac_state.input and ac_state.input ~= "" then
                AC_APPLYAVATAR(ac_state.input)
            else
                AC.setStatus("Enter User ID/Name first!", Color3.fromRGB(195, 165, 50))
            end
        end,
     })
    UI.AvatarChangerBox:AddButton({ Text = "Apply to Player",
        Func = function()
            if ac_state.target and ac_state.target ~= "" then
                AC_APPLY_TO_PLAYER(ac_state.target)
            else
                AC.setStatus("Enter target name first!", Color3.fromRGB(195, 165, 50))
            end
        end,
     })
    UI.AvatarChangerBox:AddButton({ Text = "Undo Player Morph",
        Func = function()
            AC_UNDO_MORPH()
        end,
     })
    UI.AvatarChangerBox:AddButton({ Text = "Random Avatar",
        Func = function()
            local rnd = RANDOM_IDS[math.random(1, #RANDOM_IDS)]
            ac_state.input = tostring(rnd)
            pcall(function() Options.ACInput:SetText(tostring(rnd)) end)
            AC_APPLYAVATAR(rnd)
        end,
     })
    UI.AvatarChangerBox:AddButton({ Text = "Reset to Original",
        Func = function()
            FLNS.destroyPhantom()
            if FLNS.phantomReapplyConn then
                pcall(function() FLNS.phantomReapplyConn:Disconnect() end)
                FLNS.phantomReapplyConn = nil
            end
            AC_CURRENT_AVATAR = nil
            AC.setStatus("Reset to original", Color3.fromRGB(145, 145, 145))
        end,
     })

    function Fn.unloadAvatarChanger()
        if Config._AvatarChangerCleanup then
            pcall(function() Config._AvatarChangerCleanup() end)
            Config._AvatarChangerCleanup = nil
        else
            pcall(function()
                if FLNS.phantomReapplyConn then
                    FLNS.phantomReapplyConn:Disconnect()
                    FLNS.phantomReapplyConn = nil
                end
            end)
            pcall(function()
                if FLNS.phantomModel or #FLNS.phantomConnections > 0 or FLNS.respawnHideConn then
                    FLNS.destroyPhantom()
                end
            end)
        end
    end
end