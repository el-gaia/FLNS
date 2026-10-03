local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Library            = Shared.Library
local Window             = Shared.Window
local UI                 = Shared.UI
local RunService         = Shared.RunService
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
local fast_tick          = Shared.fast_tick
local randomString       = Shared.randomString
local getProtectedGui    = Shared.getProtectedGui
local WatermarkObj = nil
local _WM_FPSCounter = { count = 0, last = fast_tick(), cached = 0 }
local function WM_GetFPS()
    if Config and Config.State and Config.State.FPS and Config.State.FPS > 0 then
        return Config.State.FPS
    end
    _WM_FPSCounter.count = _WM_FPSCounter.count + 1
    local now = fast_tick()
    if now - _WM_FPSCounter.last >= 1 then
        local fps = _WM_FPSCounter.count / (now - _WM_FPSCounter.last)
        _WM_FPSCounter.count = 0
        _WM_FPSCounter.last = now
        _WM_FPSCounter.cached = math.floor(fps)
    end
    return _WM_FPSCounter.cached or 0
end
local _WM_PingCache = { value = 0, last = 0 }
local function WM_GetPing()
    local now = fast_tick()
    if now - _WM_PingCache.last < 1 then
        return _WM_PingCache.value
    end
    _WM_PingCache.last = now
    local ping = 0
    pcall(function()
        if LocalPlayer and LocalPlayer.GetNetworkPing then
            local ok, v = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if ok and type(v) == "number" and v == v and v > 0 then
                ping = math.floor(v)
            end
        end
    end)
    if ping > 0 then
        _WM_PingCache.value = ping
        return ping
    end
    pcall(function()
        local Stats = game:GetService("Stats")
        if not Stats then return end
        local function parsePingValue(val)
            if type(val) == "number" then
                return math.floor(val)
            elseif type(val) == "string" then
                local n = tonumber(val:match("(%d+)"))
                return n and math.floor(n) or 0
            end
            return 0
        end
        local function tryGetValue(item)
            if not item or not item.GetValue then return 0 end
            local ok, v = pcall(function() return item:GetValue() end)
            if not ok then return 0 end
            return parsePingValue(v)
        end
        local net = Stats:FindFirstChild("Network")
        if net then
            local serverStats = net:FindFirstChild("ServerStatsItem")
            if serverStats then
                local dataPing = serverStats:FindFirstChild("Data Ping")
                if dataPing then
                    ping = tryGetValue(dataPing)
                    if ping > 0 then _WM_PingCache.value = ping; return end
                end
            end
            local dataPing2 = net:FindFirstChild("Data Ping")
            if dataPing2 then
                ping = tryGetValue(dataPing2)
                if ping > 0 then _WM_PingCache.value = ping; return end
            end
            for _, desc in ipairs(net:GetDescendants()) do
                if (desc.Name == "Data Ping" or desc.Name == "Ping") then
                    local v = tryGetValue(desc)
                    if v > 0 then ping = v; _WM_PingCache.value = ping; return end
                end
            end
        end
        for _, desc in ipairs(Stats:GetDescendants()) do
            if (desc.Name == "Data Ping" or desc.Name == "Ping") then
                local v = tryGetValue(desc)
                if v > 0 then ping = v; _WM_PingCache.value = ping; return end
            end
        end
    end)
    if ping > 0 then
        _WM_PingCache.value = ping
    end
    return ping
end
local function WM_UpdateText()
    if not WatermarkObj or WatermarkObj.Destroyed then return end
    local fps = WM_GetFPS()
    local ms = WM_GetPing()
    pcall(function()
        WatermarkObj:SetText(string.format("FALLENS | %d FPS | Ping: %d ms", fps, ms))
    end)
end
local function WM_Create()
    if WatermarkObj then return end
    pcall(function()
        WatermarkObj = Library:AddDraggableLabel({
            Text = "FALLENS | 0 FPS | Ping: 0 ms",
            Icon = "",
        })
        if WatermarkObj and WatermarkObj.Label then
            WatermarkObj.Label.Position = UDim2.fromOffset(6, 6)
        end
        if Config.Connections.WatermarkConn then Config.Connections.WatermarkConn:Disconnect() Config.Connections.WatermarkConn = nil end
        local accumulator = 0
        Config.Connections.WatermarkConn = RunService.Heartbeat:Connect(function(dt)
            accumulator = accumulator + dt
            if accumulator >= 0.5 then
                accumulator = 0
                WM_UpdateText()
            end
        end)
    end)
end
local function WM_Destroy()
    if not WatermarkObj then return end
    pcall(function()
        if Config.Connections.WatermarkConn then Config.Connections.WatermarkConn:Disconnect() Config.Connections.WatermarkConn = nil end
        if WatermarkObj.Destroy then
            WatermarkObj:Destroy()
        elseif WatermarkObj.Remove then
            WatermarkObj:Remove()
        elseif WatermarkObj.SetVisible then
            WatermarkObj:SetVisible(false)
        end
    end)
    WatermarkObj = nil
end
WM_Create()
task.spawn(function()
    task.wait(0.2)
    if WatermarkObj and not WatermarkObj.Destroyed then
        _WM_PingCache.last = 0
        pcall(function() WM_UpdateText() end)
    end
end)
do
    local MTB = Config.MenuToggleButton
    function Fn.createMenuToggleButton()
        if MTB._gui then return end
        Fn.safeCall("Create MenuToggleButton", function()
            local gui = Instance.new("ScreenGui")
            gui.Name           = randomString()
            gui.ResetOnSpawn   = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.IgnoreGuiInset = true
            gui.DisplayOrder   = 9998
            pcall(function() gui.Parent = getProtectedGui() end)
            if not (gui.Parent and gui.Parent:IsA("PlayerGui") or gui.Parent == game) then
                if not gui.Parent then gui.Parent = PlayerGui end
            end
            MTB._gui = gui
            local size = MTB.Size or 44
            local btn = Instance.new("ImageButton")
            btn.Name                = randomString()
            btn.Size                = UDim2.fromOffset(size, size)
            btn.Position            = UDim2.new(0, 10, 0.5, 0)
            btn.AnchorPoint         = Vector2.new(0, 0.5)
            btn.BackgroundColor3    = Library.Scheme.BackgroundColor   or Color3.fromRGB(29, 42, 55)
            btn.BackgroundTransparency = 0
            btn.AutoButtonColor     = false
            btn.Parent              = gui
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = btn
            local stroke = Instance.new("UIStroke")
            stroke.Thickness       = 1.5
            stroke.Color           = Library.Scheme.OutlineColor or Color3.fromRGB(59, 89, 128)
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = btn
            MTB._stroke = stroke
            local icon = Instance.new("ImageLabel")
            icon.Name                = randomString()
            icon.Size                = UDim2.fromScale(0.85, 0.85)
            icon.Position            = UDim2.fromScale(0.075, 0.075)
            icon.BackgroundTransparency = 1
            icon.Image               = "rbxassetid://91112706169806"
            icon.ScaleType           = Enum.ScaleType.Fit
            icon.Parent              = btn
            MTB._icon = icon
            MTB._button = btn
            btn.MouseButton1Click:Connect(function()
                Fn.safeCall("MenuToggleButton Click", function()
                    if type(Library.Toggle) == "function" then
                        Library:Toggle()
                    elseif Library.Toggled ~= nil then
                        Library.Toggled = not Library.Toggled
                    end
                end)
            end)
            btn.MouseEnter:Connect(function()
                if MTB._stroke then MTB._stroke.Thickness = 2.5 end
            end)
            btn.MouseLeave:Connect(function()
                if MTB._stroke then MTB._stroke.Thickness = 1.5 end
            end)
        end)
    end
    function Fn.removeMenuToggleButton()
        Fn.safeCall("Remove MenuToggleButton", function()
            if MTB._gui then MTB._gui:Destroy() end
        end)
        MTB._gui    = nil
        MTB._button = nil
        MTB._icon   = nil
        MTB._stroke = nil
    end
end
UI.GUIBox:AddToggle("ShowFALLENS", { Text = "Show FALLENS", Default = true, Callback = function(v)
    if v then
        WM_Create()
    else
        WM_Destroy()
    end
end }):AddKeyPicker("ShowFALLENS_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.GUIBox:AddToggle("ShowMenuToggleButton", { Text = "Show Menu Toggle Icon", Default = true, Callback = function(v)
    Config.MenuToggleButton.Enabled = v
    if v then Fn.createMenuToggleButton() else Fn.removeMenuToggleButton() end
end })
UI.UIBox:AddLabel("Menu bind")
        :AddKeyPicker("MenuKeybind", { Default = "LeftControl", NoUI = true, Text = "Menu keybind" })
UI.UIBox:AddButton({ Text = "Unload Script",
    Func = function()
        pcall(function()
            if Fn and type(Fn.unloadScript) == "function" then
                Fn.unloadScript()
            end
        end)
    end })
UI.GUIBox:AddDivider()
UI.GUIBox:AddToggle("ShowFlowstateToggleIcon", { Text = "Show Flowstate Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Flowstate.ShowButton = v
        if v then Fn.createFlowstateToggleButton() else Fn.removeFlowstateToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowSpeedBoostToggleIcon", { Text = "Show Speed Boost Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Movement.SpeedBoost.ShowButton = v
        if v then Fn.createSpeedBoostToggleButton() else Fn.removeSpeedBoostToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowNoclipToggleIcon", { Text = "Show Noclip Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Noclip.ShowButton = v
        if v then Fn.createNoclipToggleButton() else Fn.removeNoclipToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowInvisibleToggleIcon", { Text = "Show Invisible Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Invisible.ShowButton = v
        if v then Fn.createInvisibleToggleButton() else Fn.removeInvisibleToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowFlyToggleIcon", { Text = "Show Fly Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Fly.ShowButton = v
        if v then Fn.createFlyToggleButton() else Fn.removeFlyToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowFleeToggleIcon", { Text = "Show Flee Killer Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Auto.Flee.ShowButton = v
        if v then Fn.createFleeToggleButton() else Fn.removeFleeToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowAutoParryToggleIcon", { Text = "Show Auto Parry Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Auto.ParryShowButton = v
        if v then Fn.createAutoParryToggleButton() else Fn.removeAutoParryToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowAutoBandageToggleIcon", { Text = "Show Auto Bandage Toggle Icon",
    Default= false,
    Callback = function(v)
        Config.Auto.Bandage.ShowButton = v
        if v then Fn.createAutoBandageToggleButton() else Fn.removeAutoBandageToggleButton() end
    end })
UI.GUIBox:AddToggle("ShowInstantEscapeToggleIcon", { Text = "Show Instant Escape Toggle Icon",
    Default= false,
    Callback = function(v)
        if v then Fn.createInstantEscapeToggleButton() else Fn.removeInstantEscapeToggleButton() end
    end })
UI.GUIBox:AddDivider()
UI.GUIBox:AddToggle("ToggleIconsDraggable", { Text = "Draggable Toggle Icons",
    Default= true,
    Callback = function(v)
        Fn.setToggleIconsDraggable(v)
    end })
UI.GUIBox:AddButton({ Text = "Reset Icon Positions",
    Func = function()
        local cfg = Config.ToggleIcons
        for k in pairs(cfg.Positions) do cfg.Positions[k] = nil end
        if cfg._icons.Flowstate then Fn.createFlowstateToggleButton() end
        if cfg._icons.SpeedBoost then Fn.createSpeedBoostToggleButton() end
        if cfg._icons.Noclip then Fn.createNoclipToggleButton() end
        if cfg._icons.Invisible then Fn.createInvisibleToggleButton() end
        if cfg._icons.Fly then Fn.createFlyToggleButton() end
        if cfg._icons.Flee then Fn.createFleeToggleButton() end
        if cfg._icons.AutoParry then Fn.createAutoParryToggleButton() end
        if cfg._icons.AutoBandage then Fn.createAutoBandageToggleButton() end
        if cfg._icons.InstantEscape then Fn.createInstantEscapeToggleButton() end
        if cfg._icons.GunAimTargetIcon then Fn.createGunAimTargetIcon() end
        if cfg._icons.ToFAimV1TargetIcon then Fn.createToFAimV1TargetIcon() end
    end })
UI.GUIBox:AddSlider("ToggleIconSize", { Text = "Toggle Icon Size",
    Default  = 48,
    Min      = 28,
    Max      = 80,
    Rounding = 0,
    Callback = function(v)
        Config.ToggleIcons.IconSize = v
        if Config.ToggleIcons._icons.Flowstate then Fn.createFlowstateToggleButton() end
        if Config.ToggleIcons._icons.SpeedBoost then Fn.createSpeedBoostToggleButton() end
        if Config.ToggleIcons._icons.Noclip then Fn.createNoclipToggleButton() end
        if Config.ToggleIcons._icons.Invisible then Fn.createInvisibleToggleButton() end
        if Config.ToggleIcons._icons.Fly then Fn.createFlyToggleButton() end
        if Config.ToggleIcons._icons.Flee then Fn.createFleeToggleButton() end
        if Config.ToggleIcons._icons.AutoParry then Fn.createAutoParryToggleButton() end
        if Config.ToggleIcons._icons.AutoBandage then Fn.createAutoBandageToggleButton() end
        if Config.ToggleIcons._icons.InstantEscape then Fn.createInstantEscapeToggleButton() end
        if Config.ToggleIcons._icons.GunAimTargetIcon then Fn.createGunAimTargetIcon() end
        if Config.ToggleIcons._icons.ToFAimV1TargetIcon then Fn.createToFAimV1TargetIcon() end
    end })
task.spawn(function()
    task.wait(0.1)
    if Config.MenuToggleButton.Enabled then
        Fn.createMenuToggleButton()
    end
end)
UI.UIBox:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = Library.ShowCustomCursor,
        Callback = function(Value)
                Library.ShowCustomCursor = Value
        end,
})
UI.UIBox:AddToggle("AlwaysOnTop", {
        Text = "Always On Top",
        Default = Window.AlwaysOnTop,
        Callback = function(Value)
                Window:SetAlwaysOnTop(Value)
        end,
})
UI.UIBox:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Side",
        Callback = function(Value)
                Library:SetNotifySide(Value)
        end,
})
UI.UIBox:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(Value)
                Value = Value:gsub("%%", "")
                local DPI = tonumber(Value)
                Library:SetDPIScale(DPI)
        end,
})
UI.UIBox:AddSlider("UICornerSlider", {
        Text = "Corner Radius",
        Default = Library.CornerRadius,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Callback = function(value)
                Window:SetCornerRadius(value)
        end
})

Shared.WM_Destroy = WM_Destroy