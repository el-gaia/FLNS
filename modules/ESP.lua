local Shared = ...
local Config             = Shared.Config
local Fn                 = Shared.Fn
local Options            = Shared.Options
local Window             = Shared.Window
local UI                 = Shared.UI
local Players            = Shared.Players
local RunService         = Shared.RunService
local ReplicatedStorage  = Shared.ReplicatedStorage
local LocalPlayer        = Shared.LocalPlayer
local PlayerGui          = Shared.PlayerGui
local Remotes            = Shared.Remotes
local fast_tick          = Shared.fast_tick
local hookKillerIfKiller = Shared.hookKillerIfKiller
for _, obj in ipairs(workspace:GetDescendants()) do
    if string.find(string.lower(obj.Name), "scp") then Config.ESPCache.SCP[obj] = true end
    if obj.Name == "Generator" then Config.ESPCache.Generators[obj] = true
    elseif obj.Name == "Window" then Config.ESPCache.Windows[obj] = true
    elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then Config.ESPCache.Pallets[obj] = true
    end
    if obj:IsA("BasePart") and string.match(obj.Name, "^GeneratorPoint%d+$") then
        Config.ESPCache.GeneratorPoints[obj] = true
    end
end
Config.Connections.DescendantAdded = workspace.DescendantAdded:Connect(function(obj)
    if Config.Visual.CleanSky and (obj:IsA("Sky") or obj:IsA("Clouds")) then
        Fn.hideSkyOrClouds(obj)
    end
    if Config.Visual.CleanTexture and obj:IsA("SurfaceAppearance") then
        Fn.hideSurfaceAppearance(obj)
    end
    local name = string.lower(obj.Name)
    if string.find(name, "scp") then Config.ESPCache.SCP[obj] = true end
    if obj.Name == "Generator" then Config.ESPCache.Generators[obj] = true
    elseif obj.Name == "Window" then Config.ESPCache.Windows[obj] = true
    elseif obj.Name == "Pallet" or obj.Name == "Palletwrong" then Config.ESPCache.Pallets[obj] = true
    end
    if obj:IsA("BasePart") and string.match(obj.Name, "^GeneratorPoint%d+$") then
        Config.ESPCache.GeneratorPoints[obj] = true
    end
end)
Config.Connections.DescendantRemoving = workspace.DescendantRemoving:Connect(function(obj)
    local name = obj.Name
    local low  = string.lower(name)
    if string.find(low, "scp") then
        Config.ESPCache.SCP[obj] = nil
    elseif name == "Generator" then
        Config.ESPCache.Generators[obj] = nil
    elseif name == "Window" then
        Config.ESPCache.Windows[obj] = nil
    elseif name == "Pallet" or name == "Palletwrong" then
        Config.ESPCache.Pallets[obj] = nil
        if Config.State.UsedPallets and Config.State.UsedPallets[obj] then
            Config.State.UsedPallets[obj] = nil
        end
    end
    if Config.ESPCache.GeneratorPoints[obj] then
        Config.ESPCache.GeneratorPoints[obj] = nil
    end
    if Config.ESPCache.Objects[obj] then
        Config.ESPCache.Objects[obj]:Destroy()
        Config.ESPCache.Objects[obj] = nil
    end
    if Config.ESPCache.AncestryConns[obj] then
        Config.ESPCache.AncestryConns[obj]:Disconnect()
        Config.ESPCache.AncestryConns[obj] = nil
    end
end)
function Fn.removeESP(obj)
    if Config.ESPCache.Objects[obj] then
        Config.ESPCache.Objects[obj]:Destroy()
        Config.ESPCache.Objects[obj] = nil
    end
    if Config.ESPCache.ObjectVisuals[obj] then
        Config.ESPCache.ObjectVisuals[obj] = nil
    end
    if Config.ESPCache.AncestryConns[obj] then
        Config.ESPCache.AncestryConns[obj]:Disconnect()
        Config.ESPCache.AncestryConns[obj] = nil
    end
end
function Fn.createESP(obj, visual)
    if not obj then return end
    if not visual then return end
    if Config.ESPCache.Objects[obj] then
        local h = Config.ESPCache.Objects[obj]
        h.FillColor = visual.FillColor
        h.OutlineColor = visual.OutlineColor
        h.FillTransparency = visual.FillTransparency
        h.OutlineTransparency = visual.OutlineTransparency
        Config.ESPCache.ObjectVisuals[obj] = visual
        return
    end
    local h = Instance.new("Highlight")
    h.FillColor = visual.FillColor
    h.OutlineColor = visual.OutlineColor
    h.FillTransparency = visual.FillTransparency
    h.OutlineTransparency = visual.OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
    Config.ESPCache.Objects[obj] = h
    Config.ESPCache.ObjectVisuals[obj] = visual
    Config.ESPCache.AncestryConns[obj] = obj.AncestryChanged:Connect(function(_, parent)
        if not parent then Fn.removeESP(obj) end
    end)
end
function Fn.refreshESPVisuals()
    local function syncOpt(optName, tbl, colorField, transpField)
        local opt = Options and Options[optName]
        if not opt then return end
        if opt.Value and colorField then
            tbl[colorField] = opt.Value
        end
        if type(opt.Transparency) == "number" and transpField then
            tbl[transpField] = opt.Transparency
        end
    end
    syncOpt("SurvivorESPFillColor",       Config.ESPVisual.Survivor,  "FillColor",   "FillTransparency")
    syncOpt("SurvivorESPOutlineColor",    Config.ESPVisual.Survivor,  "OutlineColor","OutlineTransparency")
    syncOpt("KillerESPFillColor",         Config.ESPVisual.Killer,    "FillColor",   "FillTransparency")
    syncOpt("KillerESPOutlineColor",      Config.ESPVisual.Killer,    "OutlineColor","OutlineTransparency")
    syncOpt("ESPGeneratorFillColor",      Config.ESPVisual.Generator, "FillColor",   "FillTransparency")
    syncOpt("ESPGeneratorOutlineColor",   Config.ESPVisual.Generator, "OutlineColor","OutlineTransparency")
    syncOpt("ESPSCPFillColor",            Config.ESPVisual.SCP,       "FillColor",   "FillTransparency")
    syncOpt("ESPSCPOutlineColor",         Config.ESPVisual.SCP,       "OutlineColor","OutlineTransparency")
    syncOpt("ESPPalletFillColor",         Config.ESPVisual.Pallet,    "FillColor",   "FillTransparency")
    syncOpt("ESPPalletOutlineColor",      Config.ESPVisual.Pallet,    "OutlineColor","OutlineTransparency")
    syncOpt("ESPWindowFillColor",         Config.ESPVisual.Window,    "FillColor",   "FillTransparency")
    syncOpt("ESPWindowOutlineColor",      Config.ESPVisual.Window,    "OutlineColor","OutlineTransparency")
    for obj, h in pairs(Config.ESPCache.Objects) do
        local visual = Config.ESPCache.ObjectVisuals[obj]
        if visual and h and h.Parent then
            h.FillColor = visual.FillColor
            h.OutlineColor = visual.OutlineColor
            h.FillTransparency = visual.FillTransparency
            h.OutlineTransparency = visual.OutlineTransparency
        end
    end
    for gen in pairs(Config.ESPCache.Generators) do
        local h
        if gen and gen.FindFirstChild then
            h = gen:FindFirstChild("GenHighlight")
        end
        if h and Config.ESPVisual.Generator then
            local visual = Config.ESPVisual.Generator
            h.FillColor = visual.FillColor
            h.OutlineColor = visual.OutlineColor
            h.FillTransparency = visual.FillTransparency
            h.OutlineTransparency = visual.OutlineTransparency
        end
    end
end
function Fn.removeStatusESP(char)
    if Config.ESPCache.Status[char] then
        Config.ESPCache.Status[char]:Destroy()
        Config.ESPCache.Status[char] = nil
    end
    if Config.ESPCache.InfoBillboards[char] then
        Config.ESPCache.InfoBillboards[char]:Destroy()
        Config.ESPCache.InfoBillboards[char] = nil
    end
    if Config.ESPCache.StatusStates[char] then
        Config.ESPCache.StatusStates[char] = nil
    end
end
function Fn.GetSurvivorItem(player)
    if not player then return nil end
    local character = player.Character
    if not character then return nil end
    for _, obj in ipairs(character:GetDescendants()) do
        if Config.ESPItems[obj.Name] and (obj:IsA("Tool") or obj:IsA("Accessory") or obj:IsA("Model")) then
            return obj.Name
        end
    end
    return nil
end
function Fn.GetItemImageId(itemName)
    if not itemName or itemName == "" then return nil end
    local cached = Config.ESPCache.ItemImages[itemName]
    if cached ~= nil then
        return cached or nil
    end
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then
        Config.ESPCache.ItemImages[itemName] = false
        return nil
    end
    local itemObj = itemsFolder:FindFirstChild(itemName)
    if not itemObj then
        Config.ESPCache.ItemImages[itemName] = false
        return nil
    end
    if itemObj:IsA("Decal") or itemObj:IsA("Texture") then
        Config.ESPCache.ItemImages[itemName] = itemObj.Texture
        return itemObj.Texture
    end
    local texture = itemObj:FindFirstChildWhichIsA("Decal", true)
                  or itemObj:FindFirstChildWhichIsA("Texture", true)
    if texture then
        Config.ESPCache.ItemImages[itemName] = texture.Texture
        return texture.Texture
    end
    local namedTexture = itemObj:FindFirstChild("Texture", true)
    if namedTexture and (namedTexture:IsA("Decal") or namedTexture:IsA("Texture")) then
        Config.ESPCache.ItemImages[itemName] = namedTexture.Texture
        return namedTexture.Texture
    end
    Config.ESPCache.ItemImages[itemName] = false
    return nil
end
function Fn.GetKillerName(player, char)
    if not player then return nil end
    local killerName = Fn.GetGameValue(player, "SelectedKiller")
    if type(killerName) == "string" and killerName ~= "" then
        return killerName
    end
    if char then
        local charKillerName = Fn.GetGameValue(char, "SelectedKiller")
        if type(charKillerName) == "string" and charKillerName ~= "" then
            return charKillerName
        end
    end
    return nil
end
function Fn.GetGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child then
        local ok, val = pcall(function() return child.Value end)
        if ok then return val end
    end
    return nil
end
function Fn.setupNextKillerLabel()
    if not Config.NextKillerDisplay.Label then return end
    Fn.safeCall("NextKillerLabel Setup", function()
        if Config.NextKillerDisplay.Enabled then
            Config.NextKillerDisplay.Label:SetText("Next Killer: Calculating...")
            Config.NextKillerDisplay.Label:SetVisible(true)
        else
            Config.NextKillerDisplay.Label:SetText("Next Killer: -")
            Config.NextKillerDisplay.Label:SetVisible(false)
        end
    end)
end
function Fn.updateNextKillerDisplay()
    if not Config.NextKillerDisplay.Enabled then return end
    if not Config.NextKillerDisplay.Label then return end
    local dl       = Config.NextKillerDisplay.Label
    local teamName = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    if teamName:find("spectator") or teamName:find("lobby") then
        local now = fast_tick()
        if now - Config.NextKillerDisplay.LastUpdate < Config.NextKillerDisplay.UpdateInterval then
            return
        end
        Config.NextKillerDisplay.LastUpdate = now
        local _srcList = Config.ESPCache.PlayerList
        local nk = nil
        local bestAllow = false
        local bestChance = -math.huge
        for i = 1, #_srcList do
            local p = _srcList[i]
            local pAllow = Fn.GetGameValue(p, "AllowKiller") or false
            local pChance = Fn.GetGameValue(p, "KillerChance") or 0
            local isBetter = false
            if not nk then
                isBetter = true
            elseif pAllow ~= bestAllow then
                isBetter = pAllow == true
            else
                isBetter = pChance > bestChance
            end
            if isBetter then
                nk = p
                bestAllow = pAllow
                bestChance = pChance
            end
        end
        if nk then
            local displayName = (nk == LocalPlayer) and "YOU" or tostring(Fn.GetGameValue(nk, "SelectedKiller") or nk.Name)
            dl:SetText(string.format(
                'Next Killer: <font color="#FF5555">%s</font>',
                displayName
            ))
        end
    else
        dl:SetText("Next Killer: -")
    end
end
function Fn.dumpKillerPerks()
    local db = Config.KillerPerksDisplay.PerkDatabase
    for k in pairs(db) do db[k] = nil end
    local idx = {}
    if Config.KillerPerksDisplay.PerkIndex then
        for k in pairs(Config.KillerPerksDisplay.PerkIndex) do
            Config.KillerPerksDisplay.PerkIndex[k] = nil
        end
    else
        Config.KillerPerksDisplay.PerkIndex = {}
    end
    idx = Config.KillerPerksDisplay.PerkIndex
    local killersFolder = ReplicatedStorage:FindFirstChild("Killers")
    if not killersFolder then
        warn("[KillerPerksDisplay] Killers folder not found in ReplicatedStorage")
        return
    end
    local function indexPerk(name)
        if type(name) ~= "string" or name == "" then return end
        db[name] = true
        idx[name] = name
    end
    pcall(function()
        local general = killersFolder:FindFirstChild("!General")
        if general then
            local perks = general:FindFirstChild("Perks")
            if perks then
                for _, child in ipairs(perks:GetChildren()) do
                    indexPerk(child.Name)
                end
            end
        end
    end)
    pcall(function()
        for _, killerFolder in ipairs(killersFolder:GetChildren()) do
            if killerFolder.Name ~= "!General" then
                local perks = killerFolder:FindFirstChild("Perks")
                if perks then
                    for _, child in ipairs(perks:GetChildren()) do
                        indexPerk(child.Name)
                    end
                end
            end
        end
    end)
end
function Fn.scanPlayerPerks(char)
    local db  = Config.KillerPerksDisplay.PerkDatabase
    local idx = Config.KillerPerksDisplay.PerkIndex or {}
    if not char then return {} end
    if next(db) == nil then
        Fn.dumpKillerPerks()
        idx = Config.KillerPerksDisplay.PerkIndex or {}
    end
    local found, seen = {}, {}
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            local scriptName = desc.Name
            for perkName in pairs(idx) do
                if not seen[perkName] then
                    local startPos, endPos = string.find(scriptName, perkName, 1, true)
                    if startPos then
                        seen[perkName] = true
                        local afterName = string.sub(scriptName, endPos + 1)
                        local level = string.match(afterName, "^%s*(%d+)")
                        if level then
                            table.insert(found, perkName .. " lvl " .. level)
                        else
                            table.insert(found, perkName)
                        end
                    end
                end
            end
        end
    end
    return found
end
function Fn.getActiveKiller()
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Killer" then
            return plr
        end
    end
    return nil
end
function Fn.setupKillerPerksLabel()
    if not Config.KillerPerksDisplay.Label then return end
    if Config.KillerPerksDisplay.Enabled then
        if next(Config.KillerPerksDisplay.PerkDatabase) == nil then
            Fn.safeCall("KillerPerks Dump", Fn.dumpKillerPerks)
        end
        Fn.safeCall("KillerPerksLabel Setup", function()
            Config.KillerPerksDisplay.Label:SetText("Killer Perks: ...")
            Config.KillerPerksDisplay.Label:SetVisible(true)
        end)
        Fn.safeCall("KillerPerks Watcher Start", Fn.startKillerPerksWatcher)
    else
        Fn.safeCall("KillerPerks Watcher Stop", Fn.stopKillerPerksWatcher)
        Fn.safeCall("KillerPerksLabel Hide", function()
            Config.KillerPerksDisplay.Label:SetText("Killer Perks: -")
            Config.KillerPerksDisplay.Label:SetVisible(false)
        end)
    end
end
function Fn.updateKillerPerksDisplay()
    if not Config.KillerPerksDisplay.Enabled then return end
    if not Config.KillerPerksDisplay.Label then return end
    local dl = Config.KillerPerksDisplay.Label
    if not Fn.isSurvivorTeam() then
        dl:SetText("Killer Perks: -")
        return
    end
    Config.KillerPerksDisplay.LastUpdate = fast_tick()
    local killer = Fn.getActiveKiller()
    if not killer or not killer.Character then
        dl:SetText('Killer Perks: <font color="#B4B4B4">No Killer</font>')
        return
    end
    local perks = Fn.scanPlayerPerks(killer.Character)
    local header = string.format(
        'Killer Perks [<font color="#FF5050">%s</font>]',
        killer.Name
    )
    if #perks == 0 then
        dl:SetText(header .. '\n<font color="#B4B4B4">  no perks detected</font>')
    else
        local lines = { header }
        for _, perk in ipairs(perks) do
            table.insert(lines, string.format(
                '  • <font color="#FFC800">%s</font>',
                perk
            ))
        end
        dl:SetText(table.concat(lines, "\n"))
    end
end
Config.State._killerPerksWatcher = {
    killerPlayer        = nil,
    killerCharConn      = nil,
    killerChildConn     = nil,
    killerAncestryConn  = nil,
    killerPlayerRemoved = nil,
}
function Fn._detachKillerCharWatcher()
    local w = Config.State._killerPerksWatcher
    if not w then return end
    if w.killerChildConn then
        pcall(function() w.killerChildConn:Disconnect() end)
        w.killerChildConn = nil
    end
    if w.killerAncestryConn then
        pcall(function() w.killerAncestryConn:Disconnect() end)
        w.killerAncestryConn = nil
    end
end
function Fn._attachKillerCharWatcher(char)
    local w = Config.State._killerPerksWatcher
    if not w or not char then return end
    Fn._detachKillerCharWatcher()
    w.killerChildConn = char.DescendantAdded:Connect(function(desc)
        if Config.State.unloaded then return end
        if not Config.KillerPerksDisplay.Enabled then return end
        if not Fn.isSurvivorTeam() then return end
        if not (desc:IsA("Script") or desc:IsA("LocalScript")) then return end
        local now = fast_tick()
        if now - (Config.KillerPerksDisplay.LastUpdate or 0) < Config.KillerPerksDisplay.UpdateInterval then
            return
        end
        Fn.safeCall("KillerPerks DescendantAdded Refresh", Fn.updateKillerPerksDisplay)
    end)
    w.killerAncestryConn = char.AncestryChanged:Connect(function(_, parent)
        if Config.State.unloaded then return end
        if parent == nil then
            Fn._detachKillerCharWatcher()
            Fn.safeCall("KillerPerks Ancestry Refresh", Fn.updateKillerPerksDisplay)
        end
    end)
end
function Fn.stopKillerPerksWatcher()
    local w = Config.State._killerPerksWatcher
    if not w then return end
    Fn._detachKillerCharWatcher()
    if w.killerCharConn then
        pcall(function() w.killerCharConn:Disconnect() end)
        w.killerCharConn = nil
    end
    w.killerPlayer = nil
end
function Fn.startKillerPerksWatcher()
    if not Config.KillerPerksDisplay.Enabled then return end
    if not Fn.isSurvivorTeam() then return end
    if Config.State.unloaded then return end
    Fn.stopKillerPerksWatcher()
    local w = Config.State._killerPerksWatcher
    local killer = Fn.getActiveKiller()
    w.killerPlayer = killer
    if killer then
        w.killerCharConn = killer.CharacterAdded:Connect(function(newChar)
            if Config.State.unloaded then return end
            if not Config.KillerPerksDisplay.Enabled then return end
            if not Fn.isSurvivorTeam() then return end
            task.delay(0.6, function()
                if Config.State.unloaded then return end
                if not Config.KillerPerksDisplay.Enabled then return end
                if not Fn.isSurvivorTeam() then return end
                if killer.Character == newChar then
                    Fn._attachKillerCharWatcher(newChar)
                    Fn.safeCall("KillerPerks CharAdded Refresh", Fn.updateKillerPerksDisplay)
                end
            end)
        end)
        if killer.Character then
            Fn._attachKillerCharWatcher(killer.Character)
        end
    end
    Fn.safeCall("KillerPerks Initial Refresh", Fn.updateKillerPerksDisplay)
end
function Fn.ApplyGenHighlight(object, visual)
    if not visual then return end
    local h = object:FindFirstChild("GenHighlight") or Instance.new("Highlight")
    h.Name = "GenHighlight"
    h.Adornee = object
    h.FillColor = visual.FillColor
    h.OutlineColor = visual.OutlineColor
    h.FillTransparency = visual.FillTransparency
    h.OutlineTransparency = visual.OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = object
end
function Fn.CreateBillboard(text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GenESP"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = billboard
    return billboard
end
function Fn.UpdateGenerator(generator)
    if not generator or not generator.Parent then return end
    if not Config.ESP.Generator then
        local old = generator:FindFirstChild("GenESP")
        if old then old:Destroy() end
        local h = generator:FindFirstChild("GenHighlight")
        if h then h:Destroy() end
        return
    end
    local percent = Fn.GetGameValue(generator, "RepairProgress") or Fn.GetGameValue(generator, "Progress") or 0
    local billboard = generator:FindFirstChild("GenESP")
    if percent >= 100 then
        if billboard then billboard:Destroy() end
        return
    end
    local cp = math.clamp(percent, 0, 100)
    local color = Config.TeamColors.Generator:Lerp(Color3.fromRGB(0, 255, 120), cp / 100)
    local text = string.format("[%.0f%%]", percent)
    if not billboard then
        billboard = Fn.CreateBillboard(text, color)
        billboard.Adornee = generator
        billboard.Parent = generator
    else
        local lbl = billboard:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = text; lbl.TextColor3 = color end
    end
    Fn.ApplyGenHighlight(generator, Config.ESPVisual.Generator)
end
function Fn.UpdateMapESP(obj, root)
    if not obj or not root then return end
    local pos
    if obj:IsA("Model") then pos = obj:GetPivot().Position
    elseif obj:IsA("BasePart") then pos = obj.Position end
    if not pos then return end
    local distance = (pos - root.Position).Magnitude
    if obj.Name == "Window" then
        if Config.ESP.Window and distance <= Config.ESP.Distance then Fn.createESP(obj, Config.ESPVisual.Window)
        else Fn.removeESP(obj) end
    end
    if obj.Name == "Pallet" or obj.Name == "Palletwrong" then
        if Config.ESP.Pallet and distance <= Config.ESP.Distance then Fn.createESP(obj, Config.ESPVisual.Pallet)
        else Fn.removeESP(obj) end
    end
end
function Fn.ToRomanNumeral(n)
    n = tonumber(n) or 0
    if n <= 0 then return "0" end
    local romanMap = {
        {1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"},
        {100,  "C"}, {90,  "XC"}, {50,  "L"}, {40,  "XL"},
        {10,   "X"}, {9,   "IX"}, {5,   "V"}, {4,   "IV"},
        {1,    "I"}
    }
    local result = ""
    local remaining = math.floor(n)
    for _, pair in ipairs(romanMap) do
        local value, symbol = pair[1], pair[2]
        while remaining >= value do
            result = result .. symbol
            remaining = remaining - value
        end
    end
    return result
end
function Fn.GetSurvivorHookCount(char)
    if not char then return nil end
    local ok, value = pcall(function() return char:GetAttribute("HookCount") end)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end
function Fn.PlayStunMusic()
    if not Config.StunNotification._sound then
        local sound = Instance.new("Sound")
        sound.SoundId = Config.StunNotification.MusicId
        sound.Looped = false
        sound.Volume = 1
        sound.Parent = workspace
        Config.StunNotification._sound = sound
    end
    pcall(function()
        local snd = Config.StunNotification._sound
        snd:Stop()
        snd.TimePosition = 0
        snd:Play()
    end)
end
function Fn.StopStunMusic()
    if Config.StunNotification._sound then
        pcall(function() Config.StunNotification._sound:Stop() end)
    end
end
function Fn.DestroyStunMusic()
    if Config.StunNotification._sound then
        pcall(function() Config.StunNotification._sound:Destroy() end)
        Config.StunNotification._sound = nil
    end
end
function Fn.ShowStunSticker(char)
    if Config.StunNotification._billboard then
        Fn.HideStunSticker()
    end
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StunSticker"
    billboard.Size = UDim2.new(0, 56, 0, 56)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 200
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.Parent = char
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = Config.StunNotification.StickerId
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Parent = billboard
    Config.StunNotification._billboard = billboard
end
function Fn.HideStunSticker()
    if Config.StunNotification._billboard then
        pcall(function() Config.StunNotification._billboard:Destroy() end)
        Config.StunNotification._billboard = nil
    end
end
function Fn.UpdateStunNotification()
    if not Config.StunNotification.Enabled then
        if Config.StunNotification._wasStunned then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
        return
    end
    local killerChar = nil
    local playerList = Config.ESPCache.PlayerList
    for i = 1, #playerList do
        local p = playerList[i]
        if p.Team and p.Team.Name == "Killer" and p.Character then
            killerChar = p.Character
            break
        end
    end
    if not killerChar then
        if Config.StunNotification._wasStunned then
            Fn.StopStunMusic()
            Fn.HideStunSticker()
            Config.StunNotification._wasStunned = false
            Config.StunNotification._lastKillerChar = nil
        end
        return
    end
    local isStunned = killerChar:GetAttribute("IsStunned") == true
    if isStunned and not Config.StunNotification._wasStunned then
        Fn.PlayStunMusic()
        Fn.ShowStunSticker(killerChar)
        Config.StunNotification._wasStunned = true
        Config.StunNotification._lastKillerChar = killerChar
    elseif not isStunned and Config.StunNotification._wasStunned then
        Fn.StopStunMusic()
        Fn.HideStunSticker()
        Config.StunNotification._wasStunned = false
        Config.StunNotification._lastKillerChar = nil
    elseif isStunned and Config.StunNotification._wasStunned then
        if Config.StunNotification._lastKillerChar ~= killerChar then
            Fn.HideStunSticker()
            Fn.ShowStunSticker(killerChar)
            Config.StunNotification._lastKillerChar = killerChar
        end
    end
end
function Fn.CleanupStunNotification()
    Fn.StopStunMusic()
    Fn.DestroyStunMusic()
    Fn.HideStunSticker()
    Config.StunNotification._wasStunned = false
    Config.StunNotification._lastKillerChar = nil
end
function Fn.createStatusESP(player, char, root)
    if not Config.ESPStatus.Enabled then Fn.removeStatusESP(char); return end
    if not root then return end
    local head, hum, targetRoot
    do
        local children = char:GetChildren()
        for _, obj in ipairs(children) do
            local name = obj.Name
            if name == "Head" then
                head = obj
            elseif name == "HumanoidRootPart" then
                targetRoot = obj
            elseif obj:IsA("Humanoid") then
                hum = obj
            end
        end
    end
    if not head or not hum or not targetRoot then return end
    local isDown = Fn.checkDowned(char)
    local dist = (head.Position - root.Position).Magnitude
    if dist > Config.ESPStatus.Radius then Fn.removeStatusESP(char); return end
    local isKiller = player.Team and player.Team.Name == "Killer"
    local killer = nil
    if isKiller and Config.ESPStatus.ShowKillerName then
        killer = Fn.GetKillerName(player, char)
    end
    local heldItem = nil
    local itemImageId = nil
    if not isKiller and Config.ESPStatus.ShowItem then
        heldItem = Fn.GetSurvivorItem(player)
        if heldItem then
            itemImageId = Fn.GetItemImageId(heldItem)
        end
    end
    local showItemImage = Config.ESPStatus.ItemDisplayMode.Image == true
    local showItemText  = Config.ESPStatus.ItemDisplayMode.Text  == true
    local renderItemIcon = heldItem and itemImageId and showItemImage
    local renderItemText = heldItem and showItemText
        and not (heldItem and itemImageId and showItemImage)
    if heldItem and not itemImageId and Config.ESPStatus.ShowItem and not renderItemText then
        renderItemText = true
    end
    local nameText = ""
    if isDown then nameText = "DOWN " end
    if Config.ESPStatus.ShowName then
        nameText = nameText .. player.Name
        if isKiller and killer then
            nameText = nameText .. " (" .. killer .. ")"
        end
    else
        if isKiller and killer then
            nameText = nameText .. killer
        end
    end
    if renderItemText and heldItem then
        nameText = nameText .. " [" .. heldItem .. "]"
    end
    local hookCountText = ""
    if Config.HookCountDisplay.Enabled and not isKiller then
        local hc = Fn.GetSurvivorHookCount(char)
        if hc ~= nil then
            hookCountText = " [Hook " .. Fn.ToRomanNumeral(hc) .. "]"
        end
    end
    if hookCountText ~= "" then
        nameText = nameText .. hookCountText
    end
    local infoText = ""
    if Config.ESPStatus.ShowDistance then
        infoText = "Dist: " .. tostring(math.floor(dist + 0.5))
    end
    if Config.ESPStatus.ShowHealth then
        if infoText ~= "" then infoText = infoText .. "  " end
        infoText = infoText .. "HP: " .. tostring(math.floor(hum.Health + 0.5))
    end
    local hasTopContent = nameText ~= "" or renderItemIcon
    local hasBottomContent = infoText ~= ""
    if not hasTopContent and not hasBottomContent then
        Fn.removeStatusESP(char); return
    end
    local teamColor = Color3.new(1, 1, 1)
    if player.Team then
        if player.Team.Name == "Killer" then teamColor = Config.TeamColors.Killer
        elseif player.Team.Name == "Survivors" then teamColor = Config.TeamColors.Survivor end
    end
    if isDown then teamColor = Color3.fromRGB(255, 0, 0) end
    local infoColor = teamColor
    if not isDown then
        infoColor = Color3.fromRGB(220, 220, 220)
    end
    local state = Config.ESPCache.StatusStates[char]
    if not state then
        state = {}
        Config.ESPCache.StatusStates[char] = state
    end
    if hasTopContent then
        local billboard = Config.ESPCache.Status[char]
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "StatusESP"
            billboard.Size = UDim2.new(0, 130, 0, 18)
            billboard.AlwaysOnTop = true
            billboard.LightInfluence = 0
            billboard.MaxDistance = Config.ESPStatus.Radius * 1.5
            billboard.Adornee = head
            billboard.StudsOffset = Vector3.new(0, 2.0, 0)
            billboard.Parent = char
            local nameRow = Instance.new("Frame")
            nameRow.Name = "NameRow"
            nameRow.Size = UDim2.new(1, 0, 1, 0)
            nameRow.BackgroundTransparency = 1
            nameRow.Parent = billboard
            local nameRowLayout = Instance.new("UIListLayout")
            nameRowLayout.FillDirection = Enum.FillDirection.Horizontal
            nameRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            nameRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            nameRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
            nameRowLayout.Padding = UDim.new(0, 2)
            nameRowLayout.Parent = nameRow
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.AutomaticSize = Enum.AutomaticSize.X
            nameLabel.Size = UDim2.new(0, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = teamColor
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextWrapped = false
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Text = nameText
            nameLabel.LayoutOrder = 1
            nameLabel.Parent = nameRow
            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Name = "ItemImage"
            imageLabel.Size = UDim2.new(0, 14, 0, 14)
            imageLabel.BackgroundTransparency = 1
            imageLabel.Visible = false
            imageLabel.Image = ""
            imageLabel.ScaleType = Enum.ScaleType.Fit
            imageLabel.LayoutOrder = 2
            imageLabel.Parent = nameRow
            Config.ESPCache.Status[char] = billboard
            state.nameText = nameText
            state.teamColor = teamColor
            state.itemImage = renderItemIcon and itemImageId or ""
            state.itemVisible = renderItemIcon
            state.topAdornee = head
            state.topMaxDist = billboard.MaxDistance
        else
            local nameRow = billboard:FindFirstChild("NameRow")
            if not nameRow then
                local container = billboard:FindFirstChild("Container")
                nameRow = container and container:FindFirstChild("NameRow")
            end
            if not nameRow then
                Config.ESPCache.Status[char] = nil
                billboard:Destroy()
                return Fn.createStatusESP(player, char, root)
            end
            local maxDist = Config.ESPStatus.Radius * 1.5
            if state.topMaxDist ~= maxDist then
                billboard.MaxDistance = maxDist
                state.topMaxDist = maxDist
            end
            if state.topAdornee ~= head then
                billboard.Adornee = head
                state.topAdornee = head
            end
            local nameLabel = nameRow:FindFirstChild("NameLabel")
            if nameLabel then
                if state.nameText ~= nameText then
                    nameLabel.Text = nameText
                    state.nameText = nameText
                end
                if state.teamColor ~= teamColor then
                    nameLabel.TextColor3 = teamColor
                    state.teamColor = teamColor
                end
            end
            local imageLabel = nameRow:FindFirstChild("ItemImage")
            if imageLabel then
                local newImage = renderItemIcon and itemImageId or ""
                local newVisible = renderItemIcon == true
                if state.itemImage ~= newImage then
                    imageLabel.Image = newImage
                    state.itemImage = newImage
                end
                if state.itemVisible ~= newVisible then
                    imageLabel.Visible = newVisible
                    state.itemVisible = newVisible
                end
            end
        end
    else
        if Config.ESPCache.Status[char] then
            Config.ESPCache.Status[char]:Destroy()
            Config.ESPCache.Status[char] = nil
            state.nameText = nil
            state.topAdornee = nil
        end
    end
    if hasBottomContent then
        local infoBillboard = Config.ESPCache.InfoBillboards[char]
        if not infoBillboard then
            infoBillboard = Instance.new("BillboardGui")
            infoBillboard.Name = "StatusESPInfo"
            infoBillboard.Size = UDim2.new(0, 100, 0, 14)
            infoBillboard.AlwaysOnTop = true
            infoBillboard.LightInfluence = 0
            infoBillboard.MaxDistance = Config.ESPStatus.Radius * 1.5
            infoBillboard.Adornee = targetRoot
            infoBillboard.StudsOffset = Vector3.new(0, -3.0, 0)
            infoBillboard.Parent = char
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Name = "InfoLabel"
            infoLabel.Size = UDim2.new(1, 0, 1, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = infoColor
            infoLabel.TextStrokeTransparency = 0.2
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 10
            infoLabel.TextWrapped = false
            infoLabel.TextTruncate = Enum.TextTruncate.AtEnd
            infoLabel.Text = infoText
            infoLabel.Parent = infoBillboard
            Config.ESPCache.InfoBillboards[char] = infoBillboard
            state.infoText = infoText
            state.infoColor = infoColor
            state.bottomAdornee = targetRoot
            state.bottomMaxDist = infoBillboard.MaxDistance
        else
            local maxDist = Config.ESPStatus.Radius * 1.5
            if state.bottomMaxDist ~= maxDist then
                infoBillboard.MaxDistance = maxDist
                state.bottomMaxDist = maxDist
            end
            if state.bottomAdornee ~= targetRoot then
                infoBillboard.Adornee = targetRoot
                state.bottomAdornee = targetRoot
            end
            local infoLabel = infoBillboard:FindFirstChild("InfoLabel")
            if infoLabel then
                if state.infoText ~= infoText then
                    infoLabel.Text = infoText
                    state.infoText = infoText
                end
                if state.infoColor ~= infoColor then
                    infoLabel.TextColor3 = infoColor
                    state.infoColor = infoColor
                end
            end
        end
    else
        if Config.ESPCache.InfoBillboards[char] then
            Config.ESPCache.InfoBillboards[char]:Destroy()
            Config.ESPCache.InfoBillboards[char] = nil
            state.infoText = nil
            state.bottomAdornee = nil
        end
    end
end
function Fn.UpdateSCPEsp(root)
    local scpCache = Config.ESPCache.SCP
    if next(scpCache) == nil then return end
    if not Config.ESP.SCP then
        for obj in pairs(scpCache) do Fn.removeESP(obj) end
        return
    end
    local espDist = Config.ESP.Distance
    local scpColor = Config.ESPVisual.SCP
    local rootPos = root.Position
    for obj in pairs(scpCache) do
        if obj and obj.Parent then
            local pos
            if obj:IsA("Model") then pos = obj:GetPivot().Position
            elseif obj:IsA("BasePart") then pos = obj.Position end
            if pos then
                if (pos - rootPos).Magnitude <= espDist then
                    Fn.createESP(obj, scpColor)
                else
                    Fn.removeESP(obj)
                end
            end
        end
    end
end

function Fn._getM2AimlockTarget()
    local root = Fn.getRoot()
    if not root then return nil end
    local cfg = Config.Killer.M2Aimlock
    local range = cfg.Range or 250
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Character and plr.Team and plr.Team.Name == "Survivors" then
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and Fn.isM2AimlockTargetValid(char, root) then
                local d = (hrp.Position - root.Position).Magnitude
                if d < shortest and d <= range then
                    shortest = d; closest = char
                end
            end
        end
    end
    return closest, shortest
end

function Fn.GetNearestKiller()
    local root = Fn.getRoot()
    if not root then return nil, math.huge end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Killer" and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < shortest then shortest = dist; closest = hrp end
            end
        end
    end
    return closest, shortest
end

function Fn.stopFlowstate()
    local char = LocalPlayer.Character
    if char then
        pcall(function()
            char:SetAttribute("Flowstate", false)
        end)
    end
end
function Fn.GetFarthestGeneratorPoint(killerRoot)
    if not killerRoot then return nil end
    local bestPoint, farthestDistance = nil, 0
    for obj in pairs(Config.ESPCache.GeneratorPoints) do
        if obj and obj.Parent and obj:IsA("BasePart") then
            local dist = (obj.Position - killerRoot.Position).Magnitude
            if dist > farthestDistance then farthestDistance = dist; bestPoint = obj end
        end
    end
    return bestPoint
end

function Fn.startParryHook()
    if Config.State._parryPlayerAddedConn then return end
    for _, p in ipairs(Config.ESPCache.PlayerList) do
        if p ~= LocalPlayer then
            if p.Character then
                hookKillerIfKiller(p, p.Character)
            end
            Config.State._parryCharConns[p] = p.CharacterAdded:Connect(function(char)
                task.spawn(function()
                    local hum = char:WaitForChild("Humanoid", 5)
                    if not hum then return end
                    local animator = hum:WaitForChild("Animator", 5)
                    if not animator then return end
                    if Config.State.unloaded then return end
                    if not Config.State._parryCharConns[p] then return end
                    hookKillerIfKiller(p, char)
                end)
            end)
        end
    end
    Config.State._parryPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        Config.State._parryCharConns[p] = p.CharacterAdded:Connect(function(char)
            task.spawn(function()
                local hum = char:WaitForChild("Humanoid", 5)
                if not hum then return end
                local animator = hum:WaitForChild("Animator", 5)
                if not animator then return end
                if Config.State.unloaded then return end
                if not Config.State._parryCharConns[p] then return end
                hookKillerIfKiller(p, char)
            end)
        end)
        if p.Character then
            hookKillerIfKiller(p, p.Character)
        end
    end)
end

function Fn.getClosestTarget(targetMode, aimPart, fov, visibilityCheck)
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest, shortest = nil, fov
    local playerList = Config.ESPCache.PlayerList
    for i = 1, #playerList do
        local p = playerList[i]
        if p ~= LocalPlayer and p.Character and p.Team then
            local valid = (targetMode == "Killer" and p.Team.Name == "Killer")
                       or (targetMode == "Survivor" and p.Team.Name == "Survivors")
            if valid then
                local hrp = p.Character:FindFirstChild(aimPart)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 and not Fn.checkDowned(p.Character) then
                    local pos, visible = cam:WorldToViewportPoint(hrp.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then
                            if visibilityCheck and not Fn.isVisible(hrp) then continue end
                            shortest = dist; closest = hrp
                        end
                    end
                end
            end
        end
    end
    if targetMode == "SCP" then
        for obj in pairs(Config.ESPCache.SCP) do
            if obj and obj.Parent then
                local part
                if obj:IsA("Model") then part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                elseif obj:IsA("BasePart") then part = obj end
                if part then
                    local pos, visible = cam:WorldToViewportPoint(part.Position)
                    if visible then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < shortest then shortest = dist; closest = part end
                    end
                end
            end
        end
    end
    return closest
end

function Fn.getClosestSurvivorForStalk()
    local root = Fn.getRoot()
    if not root then return nil end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if Fn.isStalkTargetValid(plr, root) then
            local hrp = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - root.Position).Magnitude
            if dist < shortest then shortest = dist; closest = plr end
        end
    end
    return closest
end

function Fn.GetNearestAliveSurvivor()
    local root = Fn.getRoot()
    if not root then return nil end
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Config.ESPCache.PlayerList) do
        if plr ~= LocalPlayer and plr.Character
        and plr.Team and plr.Team.Name == "Survivors" then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 30 and not Fn.checkDowned(plr.Character) then
                local d = (hrp.Position - root.Position).Magnitude
                if d < shortest then shortest = d; closest = plr.Character end
            end
        end
    end
    return closest
end

function Fn.rescanWindows()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Window" and not Config.ESPCache.Windows[obj] then
            Config.ESPCache.Windows[obj] = true
        end
    end
end
function Fn.HandleBlockVaults()
    if not Config.Killer.BlockVaults then return end
    local isKiller = LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
    if not isKiller then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local vaultEvent = remotes and remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultEvent")
    if not vaultEvent then return end
    local memo = Config.State._vaultFireOK
    if memo == nil then
        memo = setmetatable({}, { __mode = "k" })
        Config.State._vaultFireOK = memo
    end
    local function collectAndFire(container)
        for _, part in ipairs(container:GetDescendants()) do
            if part:IsA("BasePart") and not memo[part] then
                local ok = Fn.safeCall("BlockVaults", function() vaultEvent:FireServer(part, true) end)
                if ok then
                    memo[part] = true
                end
            end
        end
    end
    local map = workspace:FindFirstChild("Map")
    local vaultsFolder = map and map:FindFirstChild("Vaults")
    if vaultsFolder then
        for _, vault in ipairs(vaultsFolder:GetChildren()) do
            collectAndFire(vault)
        end
    else
        for window in pairs(Config.ESPCache.Windows) do
            if window and window.Parent then
                collectAndFire(window)
            end
        end
    end
end

Config.Connections.RenderLoop = Config.FakeConnection(Config.HeartbeatTasks, "RenderLoop", function()
    local now = fast_tick()
    Config.State.Frames = Config.State.Frames + 1
    if now - Config.State.LastTick >= 1 then
        Config.State.FPS    = Config.State.Frames
        Config.State.Frames = 0
        Config.State.LastTick = now
    end
    if now - Config.Timers.lastDisplayUpdate >= 0.5 then
        Config.Timers.lastDisplayUpdate = now
        Fn.updateNextKillerDisplay()
    end
    local root = Fn.getRoot()
    if not root then return end
    if not Fn.isSpectatorTeam() then
        if now - Config.Timers.lastESPUpdate >= 0.15 then
            Config.Timers.lastESPUpdate = now
            local playerList = Config.ESPCache.PlayerList
            local espDist = Config.ESP.Distance
            local espSurvivor = Config.ESP.Survivor
            local espKiller = Config.ESP.Killer
            local statusEnabled = Config.ESPStatus.Enabled
            local survivorColor = Config.ESPVisual.Survivor
            local killerColor = Config.ESPVisual.Killer
            for i = 1, #playerList do
                local p = playerList[i]
                if p ~= LocalPlayer and p.Character then
                    local char = p.Character
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local distance = (hrp.Position - root.Position).Magnitude
                            if distance <= espDist then
                                local team = p.Team
                                if team then
                                    if espSurvivor and team.Name == "Survivors" then
                                        Fn.createESP(char, survivorColor)
                                    elseif espKiller and team.Name == "Killer" then
                                        Fn.createESP(char, killerColor)
                                    else
                                        Fn.removeESP(char)
                                    end
                                else
                                    Fn.removeESP(char)
                                end
                            else
                                Fn.removeESP(char)
                            end
                        end
                        if statusEnabled then
                            Fn.createStatusESP(p, char, root)
                        elseif Config.ESPCache.Status[char] or Config.ESPCache.InfoBillboards[char] then
                            Fn.removeStatusESP(char)
                        end
                    else
                        Fn.removeESP(char)
                        if Config.ESPCache.Status[char] or Config.ESPCache.InfoBillboards[char] then
                            Fn.removeStatusESP(char)
                        end
                    end
                end
            end
        end
        if now - (Config.Timers.lastVisualApply or 0) >= 0.5 then
            Config.Timers.lastVisualApply = now
            Fn.applyVisual()
            Fn.applyNoScreenEffects()
        end
        if now - Config.Timers.lastMapESPUpdate >= 0.25 then
            Config.Timers.lastMapESPUpdate = now
            if Config.ESP.Generator then
                for gen in pairs(Config.ESPCache.Generators) do Fn.UpdateGenerator(gen) end
            end
            if Config.ESP.Window then
                for obj in pairs(Config.ESPCache.Windows) do Fn.UpdateMapESP(obj, root) end
            else
                for obj in pairs(Config.ESPCache.Windows) do
                    if Config.ESPCache.Objects[obj] then Fn.removeESP(obj) end
                end
            end
            if Config.ESP.Pallet then
                for obj in pairs(Config.ESPCache.Pallets) do Fn.UpdateMapESP(obj, root) end
            else
                for obj in pairs(Config.ESPCache.Pallets) do
                    if Config.ESPCache.Objects[obj] then Fn.removeESP(obj) end
                end
            end
            Fn.UpdateSCPEsp(root)
        end
    end
    if not Fn.isSpectatorTeam() then
        Fn.updateParryCircle()
        Fn.drawCrosshair()
    end
    Fn.UpdateThirdPerson()
end)
function Fn.FLNS_EscapeRichText(text)
    if text == nil then return "" end
    local s = tostring(text)
    s = s:gsub("&", "&")
    s = s:gsub("<", "<")
    s = s:gsub(">", ">")
    return s
end
function Fn.FLNS_MapStringFromValue(value)
    if type(value) == "string" then
        return value
    elseif typeof and typeof(value) == "Instance" then
        return value.Name
    elseif type(value) == "table" then
        return value.Title
            or value.title
            or value.Name
            or value.name
            or value.Map
            or value.map
            or value.MapName
            or value.mapName
            or value.Location
            or value.location
    end
    return nil
end
function Fn.FLNS_MapDescFromValue(value)
    if type(value) ~= "table" then return nil end
    return value.Desc or value.desc or value.Description or value.description
end
function Fn.FLNS_SetPredictedMap(name, desc, source)
    name = Fn.FLNS_MapStringFromValue(name) or name
    if not name or tostring(name) == "" then return end
    Config.PredictMap.State.Name = tostring(name)
    if desc and tostring(desc) ~= "" then
        Config.PredictMap.State.Desc = tostring(desc)
    end
    Config.PredictMap.State.Source = source or "Detected"
end
function Fn.FLNS_ReadCurrentWorkspaceMap()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local camScene = map:FindFirstChild("Camerascene1", true)
    local title = camScene and camScene:GetAttribute("title")
    local desc = camScene and camScene:GetAttribute("desc")
    if title then
        return tostring(title), desc and tostring(desc) or nil
    end
    for _, child in ipairs(map:GetChildren()) do
        local childTitle = child:GetAttribute("title")
            or child:GetAttribute("Title")
            or child:GetAttribute("MapName")
        if childTitle then
            return tostring(childTitle),
                child:GetAttribute("desc") or child:GetAttribute("Description")
        end
    end
    return map.Name ~= "Map" and map.Name or "Map Loaded", nil
end
function Fn.FLNS_TryPredictMapRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local mechanics = remotes and remotes:FindFirstChild("Mechanics")
    local chat = mechanics and mechanics:FindFirstChild("Chat")
    local getMapData = chat and chat:FindFirstChild("GetMapData")
    if not (getMapData and getMapData:IsA("RemoteFunction")) then return false end
    local attempts = { {}, { "Current" }, { "Next" }, { "Map" } }
    for _, args in ipairs(attempts) do
        local ok, data = pcall(function()
            return getMapData:InvokeServer(unpack(args))
        end)
        if ok and data ~= nil then
            local name = Fn.FLNS_MapStringFromValue(data)
            local desc = Fn.FLNS_MapDescFromValue(data)
            if name then
                Fn.FLNS_SetPredictedMap(name, desc, "Predicted")
                return true
            end
        end
    end
    return false
end
function Fn.FLNS_PredictMapText()
    local name   = Fn.FLNS_EscapeRichText(Config.PredictMap.State.Name or "Unknown")
    local source = Fn.FLNS_EscapeRichText(Config.PredictMap.State.Source or "Idle")
    local phase    = tostring(Config.PredictMap.State.Phase or "")
    local timeLeft = Config.PredictMap.State.TimeLeft
    local timerText = ""
    if timeLeft then
        timerText = " [" .. phase .. " " .. tostring(timeLeft) .. "s]"
    elseif phase ~= "" then
        timerText = " [" .. phase .. "]"
    end
    return 'Map: <font color="#FFCC50">' .. name .. '</font> | <font color="#BEAAFF">' .. source .. timerText .. '</font>'
end
function Fn.FLNS_SetupPredictMapGui()
    if not Config.PredictMap.Label then return end
    Fn.safeCall("PredictMap Setup", function()
        Config.PredictMap.Label:SetText("Map: -")
        Config.PredictMap.Label:SetVisible(Config.PredictMap.Enabled)
    end)
end
function Fn.FLNS_BindPredictMapEvents()
    local conns = Config.PredictMap.Connections
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local messages = remotes:FindFirstChild("Messages")
    local mapInfo = messages and messages:FindFirstChild("Mapinfo")
    if mapInfo and mapInfo:IsA("RemoteEvent") then
        table.insert(conns, mapInfo.OnClientEvent:Connect(function(a, b, c)
            local name = Fn.FLNS_MapStringFromValue(a)
                or Fn.FLNS_MapStringFromValue(b)
                or Fn.FLNS_MapStringFromValue(c)
            local desc = Fn.FLNS_MapDescFromValue(a)
                or Fn.FLNS_MapDescFromValue(b)
                or Fn.FLNS_MapDescFromValue(c)
            if name then
                Fn.FLNS_SetPredictedMap(name, desc, "Predicted")
            end
        end))
    end
    local timeEvent = remotes:FindFirstChild("TimeUpdateEvent")
    if timeEvent and timeEvent:IsA("RemoteEvent") then
        table.insert(conns, timeEvent.OnClientEvent:Connect(function(phase, timeLeft)
            Config.PredictMap.State.Phase = tostring(phase or "")
            Config.PredictMap.State.TimeLeft = tonumber(timeLeft)
            if tostring(phase) == "Intermission"
                and tonumber(timeLeft)
                and tonumber(timeLeft) <= 20 then
                pcall(Fn.FLNS_TryPredictMapRemote)
            end
            if tostring(phase) == "Round" and Config.PredictMap.Label then
                Fn.safeCall("PredictMap Hide on Round", function()
                    Config.PredictMap.Label:SetText("Map: - (in round)")
                end)
            end
        end))
    end
    table.insert(conns, workspace.ChildAdded:Connect(function(child)
        if child and child.Name == "Map" then
            task.delay(0.25, function()
                local name, desc = Fn.FLNS_ReadCurrentWorkspaceMap()
                if name then Fn.FLNS_SetPredictedMap(name, desc, "Confirmed") end
            end)
        end
    end))
end
function Fn.StartPredictMap()
    if Config.PredictMap.Running then return end
    Config.PredictMap.Running = true
    Fn.FLNS_SetupPredictMapGui()
    Fn.FLNS_BindPredictMapEvents()
    task.spawn(function()
        while Config.PredictMap.Enabled and Config.PredictMap.Running do
            local currentName, currentDesc = Fn.FLNS_ReadCurrentWorkspaceMap()
            if currentName then
                Fn.FLNS_SetPredictedMap(currentName, currentDesc, "Confirmed")
            else
                pcall(Fn.FLNS_TryPredictMapRemote)
            end
            if Config.PredictMap.Label then
                Fn.safeCall("PredictMap Update", function()
                    Config.PredictMap.Label:SetText(Fn.FLNS_PredictMapText())
                    Config.PredictMap.Label:SetVisible(true)
                end)
            end
            task.wait(1)
        end
    end)
end
function Fn.StopPredictMap()
    Config.PredictMap.Running = false
    if Config.PredictMap.Label then
        Fn.safeCall("PredictMap Hide", function()
            Config.PredictMap.Label:SetText("Map: -")
            Config.PredictMap.Label:SetVisible(false)
        end)
    end
    for _, conn in ipairs(Config.PredictMap.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Config.PredictMap.Connections = {}
end
local FLNS_HideSurvivorIconImage = "rbxassetid://91112706169806"
local FLNS_HideSurvivorIconText  = "FALLENS"
local FLNS_HSI_WHITE   = Color3.fromRGB(255, 255, 255)
local FLNS_HSI_ZERO_V2 = Vector2.new(0, 0)
local FLNS_HSI_SCALE   = Enum.ScaleType.Crop
local _hsiAccumulator = 0
local _hsiAppliedSig  = ""
Config._HideSurvivorIconState.SlotCache = nil
function Fn.FLNS_RefreshSurvivorSlotCache()
    local slots = {}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        Config._HideSurvivorIconState.SlotCache = slots
        return slots
    end
    for _, gui in ipairs(playerGui:GetChildren()) do
        local isMobGui = gui:IsA("ScreenGui") and gui.Name:match("%-mob$") ~= nil
        if isMobGui then
            local frame = gui:FindFirstChild("Frame")
            if frame then
                for i = 1, 5 do
                    local survivorFrame = frame:FindFirstChild("Survivor" .. i)
                    local imageLabel = survivorFrame and survivorFrame:FindFirstChild("ImageLabel")
                    local textLabel  = survivorFrame and survivorFrame:FindFirstChild("TextLabel")
                    if (imageLabel and imageLabel:IsA("ImageLabel"))
                        or (textLabel and textLabel:IsA("TextLabel")) then
                        table.insert(slots, {
                            ImageLabel = imageLabel,
                            TextLabel  = textLabel,
                        })
                    end
                end
            end
        end
    end
    Config._HideSurvivorIconState.SlotCache = slots
    return slots
end
function Fn.FLNS_GetSurvivorSlots()
    if Config._HideSurvivorIconState.SlotCache then
        return Config._HideSurvivorIconState.SlotCache
    end
    return Fn.FLNS_RefreshSurvivorSlotCache()
end
function Fn.FLNS_ApplyHideSurvivorIcon()
    local originals = Config._HideSurvivorIconState.Originals
    for _, slot in ipairs(Fn.FLNS_GetSurvivorSlots()) do
        local imageLabel = slot.ImageLabel
        if imageLabel and imageLabel:IsA("ImageLabel") then
            if not originals[imageLabel] then
                originals[imageLabel] = {
                    Image             = imageLabel.Image,
                    ImageColor3       = imageLabel.ImageColor3,
                    ImageTransparency = imageLabel.ImageTransparency,
                    ImageRectOffset   = imageLabel.ImageRectOffset,
                    ImageRectSize     = imageLabel.ImageRectSize,
                    ScaleType         = imageLabel.ScaleType,
                }
            end
            imageLabel.Image             = FLNS_HideSurvivorIconImage
            imageLabel.ImageColor3       = FLNS_HSI_WHITE
            imageLabel.ImageTransparency = 0
            imageLabel.ImageRectOffset   = FLNS_HSI_ZERO_V2
            imageLabel.ImageRectSize     = FLNS_HSI_ZERO_V2
            imageLabel.ScaleType         = FLNS_HSI_SCALE
        end
        local textLabel = slot.TextLabel
        if textLabel and textLabel:IsA("TextLabel") then
            if not originals[textLabel] then
                originals[textLabel] = {
                    Text             = textLabel.Text,
                    TextColor3       = textLabel.TextColor3,
                    TextTransparency = textLabel.TextTransparency,
                }
            end
            textLabel.Text             = FLNS_HideSurvivorIconText
            textLabel.TextColor3       = FLNS_HSI_WHITE
            textLabel.TextTransparency = 0
        end
    end
end
function Fn.FLNS_RestoreSurvivorIcons()
    local originals = Config._HideSurvivorIconState.Originals
    for object, original in pairs(originals) do
        if object and object.Parent and original then
            pcall(function()
                if original.Image ~= nil and object:IsA("ImageLabel") then
                    object.Image             = original.Image
                    object.ImageColor3       = original.ImageColor3
                    object.ImageTransparency = original.ImageTransparency
                    object.ImageRectOffset   = original.ImageRectOffset
                    object.ImageRectSize     = original.ImageRectSize
                    object.ScaleType         = original.ScaleType
                end
                if original.Text ~= nil and object:IsA("TextLabel") then
                    object.Text             = original.Text
                    object.TextColor3       = original.TextColor3
                    object.TextTransparency = original.TextTransparency
                end
            end)
        end
    end
    Config._HideSurvivorIconState.Originals = {}
end
function Fn.FLNS_SetHideSurvivorIcon(enabled)
    Config.Visual.HideSurvivorIcon = enabled and true or false
    if Config.Visual.HideSurvivorIcon then
        Fn.FLNS_RefreshSurvivorSlotCache()
        Fn.FLNS_ApplyHideSurvivorIcon()
        if not Config._HideSurvivorIconState.Connection then
            Config._HideSurvivorIconState.Connection =
                RunService.Heartbeat:Connect(function(dt)
                    if not Config.Visual.HideSurvivorIcon then return end
                    _hsiAccumulator = _hsiAccumulator + dt
                    if _hsiAccumulator < 0.2 then return end
                    _hsiAccumulator = 0
                    local slots = Fn.FLNS_GetSurvivorSlots()
                    local sig = #slots
                    for i = 1, #slots do
                        local img = slots[i].ImageLabel
                        if img and img.Image ~= FLNS_HideSurvivorIconImage then
                            sig = sig .. "_" .. i
                        end
                    end
                    if sig == _hsiAppliedSig then return end
                    _hsiAppliedSig = sig
                    Fn.FLNS_ApplyHideSurvivorIcon()
                end)
        end
        if not Config._HideSurvivorIconState.PlayerGuiConn then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                Config._HideSurvivorIconState.PlayerGuiConn =
                    playerGui.DescendantAdded:Connect(function(child)
                        if child:IsA("ScreenGui") and child.Name:match("%-mob$") then
                            Config._HideSurvivorIconState.SlotCache = nil
                        elseif child:IsA("Frame") and child.Parent
                            and child.Parent:IsA("ScreenGui")
                            and child.Parent.Name:match("%-mob$") then
                            Config._HideSurvivorIconState.SlotCache = nil
                        end
                    end)
            end
        end
    else
        if Config._HideSurvivorIconState.Connection then
            pcall(function() Config._HideSurvivorIconState.Connection:Disconnect() end)
            Config._HideSurvivorIconState.Connection = nil
        end
        if Config._HideSurvivorIconState.PlayerGuiConn then
            pcall(function() Config._HideSurvivorIconState.PlayerGuiConn:Disconnect() end)
            Config._HideSurvivorIconState.PlayerGuiConn = nil
        end
        Config._HideSurvivorIconState.SlotCache = nil
        Fn.FLNS_RestoreSurvivorIcons()
    end
end
getgenv().FLNS_SetHideSurvivorIcon = Fn.FLNS_SetHideSurvivorIcon
do
    local toggle = UI.ESPBox:AddToggle("SurvivorESP", { Text = "ESP Survivor", Default = false,
        Callback = function(v) Config.ESP.Survivor = v end }):AddKeyPicker("SurvivorESP_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("SurvivorESPFillColor", { Default = Config.ESPVisual.Survivor.FillColor, Transparency = Config.ESPVisual.Survivor.FillTransparency, Title = "Survivor Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Survivor.FillColor = color
            if transparency ~= nil then Config.ESPVisual.Survivor.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("SurvivorESPOutlineColor", { Default = Config.ESPVisual.Survivor.OutlineColor, Transparency = Config.ESPVisual.Survivor.OutlineTransparency, Title = "Survivor Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Survivor.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.Survivor.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
do
    local toggle = UI.ESPBox:AddToggle("KillerESP", { Text = "ESP Killer", Default = false,
        Callback = function(v) Config.ESP.Killer = v end }):AddKeyPicker("KillerESP_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("KillerESPFillColor", { Default = Config.ESPVisual.Killer.FillColor, Transparency = Config.ESPVisual.Killer.FillTransparency, Title = "Killer Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Killer.FillColor = color
            if transparency ~= nil then Config.ESPVisual.Killer.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("KillerESPOutlineColor", { Default = Config.ESPVisual.Killer.OutlineColor, Transparency = Config.ESPVisual.Killer.OutlineTransparency, Title = "Killer Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Killer.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.Killer.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
do
    local toggle = UI.ESPBox:AddToggle("ESPGenerator", { Text = "Generator", Default = false,
        Callback = function(v) Config.ESP.Generator = v end }):AddKeyPicker("ESPGenerator_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("ESPGeneratorFillColor", { Default = Config.ESPVisual.Generator.FillColor, Transparency = Config.ESPVisual.Generator.FillTransparency, Title = "Generator Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Generator.FillColor = color
            if transparency ~= nil then Config.ESPVisual.Generator.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("ESPGeneratorOutlineColor", { Default = Config.ESPVisual.Generator.OutlineColor, Transparency = Config.ESPVisual.Generator.OutlineTransparency, Title = "Generator Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Generator.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.Generator.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
do
    local toggle = UI.ESPBox:AddToggle("ESPSCP", { Text = "SCP", Default = false,
        Callback = function(v) Config.ESP.SCP = v end }):AddKeyPicker("ESPSCP_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("ESPSCPFillColor", { Default = Config.ESPVisual.SCP.FillColor, Transparency = Config.ESPVisual.SCP.FillTransparency, Title = "SCP Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.SCP.FillColor = color
            if transparency ~= nil then Config.ESPVisual.SCP.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("ESPSCPOutlineColor", { Default = Config.ESPVisual.SCP.OutlineColor, Transparency = Config.ESPVisual.SCP.OutlineTransparency, Title = "SCP Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.SCP.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.SCP.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
do
    local toggle = UI.ESPBox:AddToggle("ESPPallet", { Text = "Pallet", Default = false,
        Callback = function(v) Config.ESP.Pallet = v end }):AddKeyPicker("ESPPallet_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("ESPPalletFillColor", { Default = Config.ESPVisual.Pallet.FillColor, Transparency = Config.ESPVisual.Pallet.FillTransparency, Title = "Pallet Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Pallet.FillColor = color
            if transparency ~= nil then Config.ESPVisual.Pallet.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("ESPPalletOutlineColor", { Default = Config.ESPVisual.Pallet.OutlineColor, Transparency = Config.ESPVisual.Pallet.OutlineTransparency, Title = "Pallet Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Pallet.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.Pallet.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
do
    local toggle = UI.ESPBox:AddToggle("ESPWindow", { Text = "Window", Default = false,
        Callback = function(v) Config.ESP.Window = v end }):AddKeyPicker("ESPWindow_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true }):AddColorPicker("ESPWindowFillColor", { Default = Config.ESPVisual.Window.FillColor, Transparency = Config.ESPVisual.Window.FillTransparency, Title = "Window Fill Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Window.FillColor = color
            if transparency ~= nil then Config.ESPVisual.Window.FillTransparency = transparency end
            Fn.refreshESPVisuals()
        end }):AddColorPicker("ESPWindowOutlineColor", { Default = Config.ESPVisual.Window.OutlineColor, Transparency = Config.ESPVisual.Window.OutlineTransparency, Title = "Window Outline Color",
        Callback = function(color, transparency)
            Config.ESPVisual.Window.OutlineColor = color
            if transparency ~= nil then Config.ESPVisual.Window.OutlineTransparency = transparency end
            Fn.refreshESPVisuals()
        end })
end
UI.ESPBox:AddSlider("ESPDistance", { Text = "ESP Radius", Default = 100, Min = 10, Max = 1000, Rounding = 0,
    Callback = function(v) Config.ESP.Distance = v end })
UI.ESPStatusBox:AddToggle("EnableStatus", { Text = "Enable Status ESP", Default = false,
    Callback = function(v) Config.ESPStatus.Enabled = v end }):AddKeyPicker("EnableStatus_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddToggle("ShowName", { Text = "Show Name", Default = true,
    Callback = function(v) Config.ESPStatus.ShowName = v end }):AddKeyPicker("ShowName_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddToggle("ShowItemESP", { Text = "Show Item", Default = true,
    Callback = function(v) Config.ESPStatus.ShowItem = v end }):AddKeyPicker("ShowItemESP_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddDropdown("ItemDisplayMode", { Text = "Item Display Mode",
    Values = { "Image", "Text" },
    Default = { "Image" },
    Multi = true,
    Callback = function(v)
        Config.ESPStatus.ItemDisplayMode.Image = v.Image == true
        Config.ESPStatus.ItemDisplayMode.Text  = v.Text  == true
        if Config.ESPStatus.ItemDisplayMode.Image or Config.ESPStatus.ItemDisplayMode.Text then
            Config.ESPStatus.ShowItem = true
        end
    end })
UI.ESPStatusBox:AddToggle("ShowKillerName", { Text = "Show Killer Name", Default = false,
    Callback = function(v) Config.ESPStatus.ShowKillerName = v end }):AddKeyPicker("ShowKillerName_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddToggle("ShowDistance", { Text = "Show Distance", Default = true,
    Callback = function(v) Config.ESPStatus.ShowDistance = v end }):AddKeyPicker("ShowDistance_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddToggle("ShowHealth", { Text = "Show Health", Default = false,
    Callback = function(v) Config.ESPStatus.ShowHealth = v end }):AddKeyPicker("ShowHealth_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddToggle("HookCountDisplayToggle", { Text = "Hook Count Display",
    Default = false,
    Callback = function(v)
        Config.HookCountDisplay.Enabled = v
    end }):AddKeyPicker("HookCountDisplayToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
UI.ESPStatusBox:AddSlider("StatusRadius", { Text = "Status Radius", Default = 100, Min = 20, Max = 500, Rounding = 0,
    Callback = function(v) Config.ESPStatus.Radius = v end })
UI.ESPStatusBox:AddDivider()
UI.ESPStatusBox:AddToggle("NextKillerDisplay", { Text = "Next Killer Display", Default = false,
    Callback = function(v)
        Config.NextKillerDisplay.Enabled = v
        Fn.setupNextKillerLabel()
    end }):AddKeyPicker("NextKillerDisplay_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
Config.NextKillerDisplay.Label = UI.ESPStatusBox:AddLabel("Next Killer: -")
UI.ESPStatusBox:AddToggle("KillerPerksDisplay", { Text = "Killer Perks Display", Default = false,
    Callback = function(v)
        Config.KillerPerksDisplay.Enabled = v
        Fn.setupKillerPerksLabel()
    end }):AddKeyPicker("KillerPerksDisplay_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
Config.KillerPerksDisplay.Label = UI.ESPStatusBox:AddLabel({
    Text     = "Killer Perks: -",
    DoesWrap = true,
    Size     = 14,
})
UI.ESPStatusBox:AddToggle("PredictMapToggle", { Text = "Predict Next Map", Default = false,
    Callback = function(v)
        Config.PredictMap.Enabled = v
        if v then Fn.StartPredictMap() else Fn.StopPredictMap() end
    end }):AddKeyPicker("PredictMapToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })
Config.PredictMap.Label = UI.ESPStatusBox:AddLabel("Map: -")
UI.ESPStatusBox:AddToggle("HideSurvivorIconToggle", { Text = "Replace Survivor Icons", Default = false,
    Callback = function(v) Fn.FLNS_SetHideSurvivorIcon(v) end }):AddKeyPicker("HideSurvivorIconToggle_Keybind", { Default = "None", Mode = "Toggle", SyncToggleState = true })