-- ================================================
-- DIMZ HUB LOADER v2.5 — MODIFIED (autoSell Support)
-- ================================================

local D = true -- ⚙ DEBUG ON/OFF — ganti jadi false kalo udah selesai debugging

-- ╔══════════════════════════════════════════════╗
-- ║  KONFIGURASI — EDIT DI SINI                  ║
-- ╚══════════════════════════════════════════════╝
local LOGO_URL     = "https://tuysstore.my.id/script/ui/papidimz_logo.png"
local PREM_GATEWAY = "https://dimzhub.my.id/api/etfb_gateway.php"
local KEY_GATEWAY  = "https://dimzhub.my.id/api/key_gateway.php"
local API_SECRET   = "GALABUNGAMATAHARI"
local DISCORD_URL  = "https://discord.gg/B6Hce5VwKP"
local KEY_PAGE_URL = "https://dimzhub.my.id/key"
local BUY_PREM_URL = "https://dimzhub.my.id/getdimz"
-- ╔══════════════════════════════════════════════╝

-- ✅ ROBUST FLAG RESOLVER — tahan obfuscation
--    Mencoba baca _G.xxx dari berbagai environment.
--    Dipanggil di awal supaya flags ter-capture sebelum closure wrap.
local function resolveFlag(name)
    local g = getgenv and getgenv()
    if type(g) == "table" and g[name] == true then return true end
    if type(_G) == "table" and _G[name] == true then return true end
    local ok, s = pcall(function() return shared end)
    if ok and type(s) == "table" and s[name] == true then return true end
    local okf, f = pcall(function() return getfenv and getfenv(0) end)
    if okf and type(f) == "table" and f[name] == true then return true end
    return false
end

local FLAG_autoSell  = false
local FLAG_pearlsFarm = false
pcall(function()
    FLAG_autoSell  = resolveFlag("autoSell")
    FLAG_pearlsFarm = resolveFlag("pearlsFarm")
end)
if D then pcall(function() print("[D] flags: autoSell="..tostring(FLAG_autoSell).." pearlsFarm="..tostring(FLAG_pearlsFarm)) end) end

-- ✅ FUNGSI getScriptUrl — DIPERBAIKI: pakai tabel dengan key STRING
--    supaya aman dari bug "number encryption" obfuscator pada placeId
--    besar (14-15 digit), yang sebelumnya bisa bikin false-negative
--    di perbandingan `pid == <angka literal>` (contoh kasus: placeId
--    139802517550914 kebaca "Game Not Supported" walau sudah terdaftar).
local SCRIPT_MAP = {
    ["123960881422056"] = {
        fishing = "https://dimzhub.my.id/storage/app/scripts/publik/gim/escape-tsunami-for-a-brainrot/prem/Arena-Fishing.lua",
        normal  = "https://dimzhub.my.id/storage/app/scripts/publik/gim/escape-tsunami-for-a-brainrot/prem/prem-aren890a.lua",
    },
    ["111917342868480"] = {
        -- ✅ dua varian: autoSell ON/OFF, dipilih di getScriptUrl()
        autoSell = "https://dimzhub.my.id/storage/app/scripts/publik/gim/escape-tsunami-for-a-brainrot/prem/prem-90plaza8099.lua",
        normal   = "https://dimzhub.my.id/storage/app/scripts/publik/gim/escape-tsunami-for-a-brainrot/dailly/3d%20-%20huala.lua",
    },
    ["130342654546662"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/tebak-kata/tekbakjanda.lua",
    },
    ["70411440483149"] = {
        pearlsFarm = "https://dimzhub.my.id/storage/app/scripts/publik/gim/100days/minimalist_info.lua",
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/100days/100d.lua",
    },
    ["139802517550914"] = {
        pearlsFarm = "https://dimzhub.my.id/storage/app/scripts/publik/gim/100days/minimalist_info.lua",
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/100days/100d.lua",
    },
    ["114640202062357"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/swing-obby-for-brainrot/swing_obby_for_brainrot.lua",
    },
    ["101949297449238"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/build-an-island/bai.lua",
    },
    ["94503612388426"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/be-a-fish/[NoPrint]be_a_fish.lua",
    },
    ["17577256698"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/hutan/hutan.lua",
    },
    ["78762878926445"] = {
        normal = "https://dimzhub.my.id/storage/app/scripts/publik/gim/ride-brainrot-for-a-brainrots/ridebrainrot.lua",
    },
}

-- Helper: baca global flag dari _G atau getgenv() (kompatibel berbagai executor)
local function getGlobalFlag(name)
    if _G and type(_G) == "table" and _G[name] == true then return true end
    local ok, val = pcall(function()
        local g = getgenv and getgenv()
        return g and type(g) == "table" and g[name] == true
    end)
    if ok and val then return true end
    local ok2, val2 = pcall(function()
        local s = shared
        return s and type(s) == "table" and s[name] == true
    end)
    if ok2 and val2 then return true end
    local ok3, val3 = pcall(function()
        local f = getfenv and getfenv(0)
        return f and type(f) == "table" and f[name] == true
    end)
    return ok3 and val3 or false
end

local function getScriptUrl(pid, fishing)
    local pidStr = tostring(pid)
    local entry = SCRIPT_MAP[pidStr]
    if not entry then
        if D then pcall(function() print("[D] getScriptUrl: ❌ placeId "..pidStr.." tidak ada di SCRIPT_MAP") end) end
        return nil
    end
    if D then pcall(function() print("[D] getScriptUrl: placeId "..pidStr.." ditemukan, fishing="..tostring(fishing).." autoSell="..tostring(FLAG_autoSell).." pearlsFarm="..tostring(FLAG_pearlsFarm)) end) end

    if fishing and entry.fishing then
        if D then pcall(function() print("[D] getScriptUrl: → fishing") end) end
        return entry.fishing
    end

    if entry.autoSell and (FLAG_autoSell or getGlobalFlag("autoSell")) then
        if D then pcall(function() print("[D] getScriptUrl: → autoSell") end) end
        return entry.autoSell
    end

    if entry.pearlsFarm and (FLAG_pearlsFarm or getGlobalFlag("pearlsFarm")) then
        if D then pcall(function() print("[D] getScriptUrl: → pearlsFarm") end) end
        return entry.pearlsFarm
    end

    if D then pcall(function() print("[D] getScriptUrl: → normal") end) end
    return entry.normal
end

-- ================================================
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local player      = Players.LocalPlayer
local playerGui   = player:WaitForChild("PlayerGui")
local displayName = player.Name
local username    = player.Name:lower()
local placeId     = game.PlaceId

-- ── HWID ─────────────────────────────────────────
local hwid = "unknown"
pcall(function()
    if D then pcall(function() print("[D] HWID: gethwid="..tostring(gethwid).." identifyexecutor="..tostring(identifyexecutor).." readfile="..tostring(readfile)) end) end
    if gethwid ~= nil then
        local ok, h = pcall(gethwid)
        if ok and h and tostring(h) ~= "" then
            hwid = tostring(h)
            if D then pcall(function() print("[D] HWID: ✅ gethwid="..hwid) end) end
            return
        end
    end
    if HWID ~= nil and tostring(HWID) ~= "" then
        hwid = tostring(HWID)
        if D then pcall(function() print("[D] HWID: ✅ HWID global="..hwid) end) end
        return
    end
    if identifyexecutor ~= nil then
        local exec = ""
        pcall(function() exec = identifyexecutor() end)
        local uid = ""
        pcall(function()
            if game:GetService("RbxAnalyticsService") then
                uid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
            end
        end)
        local extra = ""
        pcall(function()
            if readfile then
                writefile("_hwidtest.txt", "1")
                if getcustomasset then
                    local p = getcustomasset("_hwidtest.txt")
                    if p and #p > 5 then
                        extra = p:match("([A-Za-z0-9%-]+)[/\\][^/\\]+$") or ""
                    end
                end
                pcall(function() delfile("_hwidtest.txt") end)
            end
        end)
        local combined = exec .. "_" .. uid .. "_" .. extra
        if D then pcall(function() print("[D] HWID: combined="..combined) end) end
        if combined ~= "__" then hwid = combined; if D then pcall(function() print("[D] HWID: ✅ "..hwid) end) end; return end
    end
    pcall(function()
        hwid = "rblx_" .. tostring(player.UserId) .. "_" .. tostring(placeId)
        if D then pcall(function() print("[D] HWID: fallback="..hwid) end) end
    end)
end)

-- ── Saved Key ────────────────────────────────────
local savedKey   = ""
local savedToken = ""
pcall(function()
    if readfile == nil then
        if D then pcall(function() print("[D] savedKey: readfile nil") end) end
        return
    end
    local ok, raw = pcall(readfile, "dimzhub_key.txt")
    if not ok or not raw then
        if D then pcall(function() print("[D] savedKey: file tidak ada") end) end
        return
    end
    for line in raw:gmatch("[^\n]+") do
        if line:sub(1,4) == "key=" then savedKey   = line:sub(5) end
        if line:sub(1,4) == "tok=" then savedToken = line:sub(5) end
    end
    if D then pcall(function() print("[D] savedKey: key="..savedKey:sub(1,10).." tok="..savedToken:sub(1,10)) end) end
end)

local function saveKey(k, t)
    pcall(function()
        if writefile then
            writefile("dimzhub_key.txt", "key=" .. tostring(k) .. "\ntok=" .. tostring(t or ""))
        end
    end)
end

local function clearKey()
    pcall(function()
        if writefile then writefile("dimzhub_key.txt", "") end
    end)
    savedKey   = ""
    savedToken = ""
end

-- ── Deteksi fishing ──────────────────────────────
local isFishing = false
pcall(function()
    local ok, fa = pcall(function()
        return workspace
            :WaitForChild("GameObjects",3)
            :WaitForChild("PlaceSpecific",3)
            :WaitForChild("tsunami_arena",3)
            :WaitForChild("FishingArenaMap",3)
    end)
    isFishing = ok and fa ~= nil
end)
if D then pcall(function() print("[D] isFishing="..tostring(isFishing)) end) end

-- ── Bersihkan GUI lama ───────────────────────────
for _, v in ipairs(playerGui:GetChildren()) do
    if v.Name == "DimzLoaderUI" or v.Name == "DimzMiniUI" then v:Destroy() end
end

-- ================================================
-- HELPERS
-- ================================================
local C3 = Color3.fromRGB
local U2 = UDim2.new

local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent = parent end
    return o
end

local function rnd(r, obj)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
    return c
end

local function stk(col, th, obj)
    local s = Instance.new("UIStroke")
    s.Color = col; s.Thickness = th; s.Parent = obj
    return s
end

local function tw(obj, dur, props, sty, dir)
    TweenService:Create(obj,
        TweenInfo.new(dur, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

-- ================================================
-- ██ MINI LOADER — pojok kanan bawah
-- ================================================
local miniGui = new("ScreenGui", {
    Name="DimzMiniUI", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true
}, playerGui)

local miniCard = new("Frame", {
    Size=U2(0,268,0,68), Position=U2(1,-282,1,10),
    BackgroundColor3=C3(10,10,20), BorderSizePixel=0, ZIndex=200
}, miniGui)
rnd(12, miniCard)
local miniS = stk(C3(80,200,255), 1.5, miniCard)

local miniTopLine = new("Frame", {
    Size=U2(0.55,0,0,2), Position=U2(0.22,0,0,0),
    BackgroundColor3=C3(80,200,255), BackgroundTransparency=0.4,
    BorderSizePixel=0, ZIndex=201
}, miniCard); rnd(1, miniTopLine)

local mOuterRing = new("Frame", {
    Size=U2(0,44,0,44), Position=U2(0,12,0.5,-22),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=201
}, miniCard); rnd(22, mOuterRing)
local mOuterS = stk(C3(80,200,255), 1.2, mOuterRing)

local mInnerRing = new("Frame", {
    Size=U2(0,33,0,33), Position=U2(0.5,-16.5,0.5,-16.5),
    BackgroundColor3=C3(14,14,32), BorderSizePixel=0, ZIndex=202
}, mOuterRing); rnd(16.5, mInnerRing)
local mInnerS = stk(C3(130,90,240), 1.0, mInnerRing)

local mStarInnerC = new("Frame", {
    Size=U2(0,0,0,0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=204
}, mInnerRing)

local mOrbitPos = {
    U2(0.5,-2, 0,-2), U2(0.5,-2, 1,-2),
    U2(0,-2, 0.5,-2), U2(1,-2, 0.5,-2),
}
for i, pos in ipairs(mOrbitPos) do
    local dot = new("Frame", {
        Size=U2(0,4,0,4), Position=pos,
        BackgroundColor3=C3(80,200,255), BorderSizePixel=0, ZIndex=202
    }, mOuterRing); rnd(2, dot)
    task.spawn(function()
        task.wait((i-1)*0.45)
        while mOuterRing.Parent do
            tw(dot,0.5,{BackgroundTransparency=0},  Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
            task.wait(0.55)
            tw(dot,0.5,{BackgroundTransparency=0.8},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
            task.wait(0.55)
        end
    end)
end

new("TextLabel", {
    Size=U2(1,-70,0,16), Position=U2(0,64,0,11),
    BackgroundTransparency=1, Text="DIMZ HUB",
    TextColor3=C3(80,200,255), TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=201
}, miniCard)

local miniSt = new("TextLabel", {
    Size=U2(1,-70,0,12), Position=U2(0,64,0,29),
    BackgroundTransparency=1, Text="Detecting game...",
    TextColor3=C3(80,115,155), TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=201
}, miniCard)

local mBarBg = new("Frame", {
    Size=U2(1,-24,0,4), Position=U2(0,12,1,-10),
    BackgroundColor3=C3(18,22,38), BorderSizePixel=0, ZIndex=201
}, miniCard); rnd(2, mBarBg)
local mBarFill = new("Frame", {
    Size=U2(0,0,1,0), BackgroundColor3=C3(80,200,255),
    BorderSizePixel=0, ZIndex=202
}, mBarBg); rnd(2, mBarFill)

local mStatusDot = new("Frame", {
    Size=U2(0,6,0,6), Position=U2(1,-14,0,10),
    BackgroundColor3=C3(80,200,255), BorderSizePixel=0, ZIndex=202
}, miniCard); rnd(3, mStatusDot)

tw(miniCard, 0.5, {Position=U2(1,-282,1,-80)}, Enum.EasingStyle.Back)

local mBA, mPA = true, true

task.spawn(function()
    local f=true
    while mBA do
        tw(mBarFill, 0.65,
            {Size=U2(f and 0.70 or 0.08, 0, 1, 0),
             BackgroundColor3=f and C3(80,200,255) or C3(110,85,255)},
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        f=not f; task.wait(0.7)
    end
end)

task.spawn(function()
    local b=true
    while mPA do
        local col = b and C3(80,200,255) or C3(24,68,118)
        tw(mOuterS, 0.55, {Color=col}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        b=not b; task.wait(0.6)
    end
end)

task.spawn(function()
    local t=0
    while miniCard.Parent do
        t=t+0.02
        local a=(math.sin(t)+1)/2
        local bv=(math.sin(t+0.9)+1)/2
        if mOuterS.Parent then
            mOuterS.Color=C3(math.floor(28+a*55),math.floor(125+a*75),math.floor(195+a*60))
        end
        if mInnerS.Parent then
            mInnerS.Color=C3(math.floor(80+bv*60),math.floor(58+bv*80),math.floor(200+bv*55))
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    local t=0
    while miniCard.Parent do
        t=t+0.03
        local a=(math.sin(t)+1)/2
        local col1=C3(math.floor(30+a*40),math.floor(160+a*60),math.floor(230+a*25))
        local col2=C3(math.floor(110+a*60),math.floor(70+a*50),math.floor(220+a*35))
        for _, b in ipairs(mInnerRing:GetChildren()) do
            if b:IsA("Frame") and b~=mStarInnerC then b.BackgroundColor3=col1 end
        end
        for _, b in ipairs(mStarInnerC:GetChildren()) do
            if b:IsA("Frame") then b.BackgroundColor3=col2 end
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    while miniCard.Parent do
        tw(mStatusDot,0.5,{BackgroundTransparency=0},  Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        task.wait(0.55)
        tw(mStatusDot,0.5,{BackgroundTransparency=0.85},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        task.wait(0.55)
    end
end)

local function setMSt(txt,col) miniSt.Text=txt; miniSt.TextColor3=col or C3(80,115,155) end
local function stopMini() mBA=false; mPA=false end

local function miniOutEarly()
    tw(miniCard, 0.3, {Position=U2(1,10,1,-80)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.35)
    pcall(function() miniGui:Destroy() end)
end

local miniOut = miniOutEarly

-- ── Step 1: Deteksi game ─────────────────────────
task.wait(0.4); setMSt("Reading game..."); task.wait(0.5)

local gameName = "Unknown Game"
pcall(function()
    local info = MarketplaceService:GetProductInfo(placeId)
    if info and info.Name then gameName = info.Name end
end)
if D then pcall(function() print("[D] placeId="..tostring(placeId).." gameName="..gameName) end) end

setMSt("✓ "..gameName, C3(80,200,255))
tw(mBarFill, 0.4, {Size=U2(0.6,0,1,0), BackgroundColor3=C3(50,210,130)})
task.wait(0.85); stopMini()

-- ── Cek apakah game didukung ─────────────────────
local scriptUrl = getScriptUrl(placeId, false)
if D then pcall(function() print("[D] getScriptUrl → "..tostring(scriptUrl)) end) end
if not scriptUrl then
    tw(miniS, 0.3, {Color=C3(255,75,75)})
    tw(mOuterS, 0.3, {Color=C3(255,75,75)})
    tw(mInnerS, 0.3, {Color=C3(255,75,75)})
    tw(mBarFill, 0.3, {BackgroundColor3=C3(255,75,75), Size=U2(1,0,1,0)})
    setMSt("Game Not Supported", C3(255,80,80))
    for _, b in ipairs(mInnerRing:GetChildren()) do
        if b:IsA("Frame") then tw(b,0.3,{BackgroundColor3=C3(255,80,80)}) end
    end
    for _, b in ipairs(mStarInnerC:GetChildren()) do
        if b:IsA("Frame") then tw(b,0.3,{BackgroundColor3=C3(255,80,80)}) end
    end
    task.wait(4)
    miniOut()
    return
end

-- ================================================
-- ██ MAIN CARD
-- ================================================
local CW = 348

local function cardH(state)
    if state == "loading" then return 250 end
    if state == "result"  then return 268 end
    if state == "key"     then return 340 end
    return 250
end

local screenGui = new("ScreenGui", {
    Name="DimzLoaderUI", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true
}, playerGui)

local overlay = new("Frame", {
    Size=U2(1,0,1,0), BackgroundColor3=C3(0,0,0),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=100
}, screenGui)

local CH = cardH("loading")

local card = new("Frame", {
    Size=U2(0,CW,0,CH),
    Position=U2(0.5,-CW/2, 0.5,-CH/2),
    BackgroundColor3=C3(10,10,20),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=101,
    Visible=false
}, screenGui)
rnd(14, card)
local cardStroke = stk(C3(80,200,255), 1.5, card)

local function showMainCard()
    card.Visible = true
    card.Position = U2(0.5,-CW/2, 0.75, 0)
    tw(card, 0.08, {BackgroundTransparency=0})
    tw(card, 0.5, {Position=U2(0.5,-CW/2, 0.5,-CH/2)}, Enum.EasingStyle.Back)
end

miniOut = function()
    tw(miniCard, 0.3, {Position=U2(1,10,1,-80)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.35)
    pcall(function() miniGui:Destroy() end)
    showMainCard()
end

-- ── HEADER ───────────────────────────────────────
local header = new("Frame", {
    Size=U2(1,0,0,36), Position=U2(0,0,0,0),
    BackgroundColor3=C3(14,14,26), BorderSizePixel=0, ZIndex=103
}, card)
rnd(14, header)
new("Frame", {
    Size=U2(1,0,0,10), Position=U2(0,0,1,-10),
    BackgroundColor3=C3(14,14,26), BorderSizePixel=0, ZIndex=102
}, header)
new("Frame", {
    Size=U2(1,0,0,1), Position=U2(0,0,1,-1),
    BackgroundColor3=C3(80,200,255), BackgroundTransparency=0.82,
    BorderSizePixel=0, ZIndex=104
}, header)

local d1 = new("Frame", {
    Size=U2(0,6,0,6), Position=U2(0,12,0.5,-3),
    BackgroundColor3=C3(80,200,255), BorderSizePixel=0, ZIndex=104
}, header); rnd(3,d1)
local d2 = new("Frame", {
    Size=U2(0,6,0,6), Position=U2(0,22,0.5,-3),
    BackgroundColor3=C3(80,200,255), BackgroundTransparency=0.55,
    BorderSizePixel=0, ZIndex=104
}, header); rnd(3,d2)

new("TextLabel", {
    Size=U2(1,-130,1,0), Position=U2(0,34,0,0),
    BackgroundTransparency=1, Text="DIMZ HUB",
    TextColor3=C3(80,200,255), TextSize=12, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=104
}, header)

local btnDc = new("TextButton", {
    Size=U2(0,70,0,22), Position=U2(1,-106,0.5,-11),
    BackgroundColor3=C3(88,101,242), BorderSizePixel=0,
    Text="", AutoButtonColor=false, ZIndex=105
}, header); rnd(5, btnDc)

local dcIcon = new("Frame", {
    Size=U2(0,13,0,11), Position=U2(0,6,0.5,-5.5),
    BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ZIndex=106
}, btnDc); rnd(4, dcIcon)
new("Frame", {
    Size=U2(0,5,0,4), Position=U2(0,1,1,-2),
    BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ZIndex=106,
    Rotation=15
}, dcIcon)
for i=0,2 do
    new("Frame", {
        Size=U2(0,2,0,2),
        Position=U2(0, 2+(i*4), 0.5, -1),
        BackgroundColor3=C3(88,101,242),
        BorderSizePixel=0, ZIndex=107
    }, dcIcon); 
end

local dcTxtLbl = new("TextLabel", {
    Size=U2(1,-22,1,0), Position=U2(0,21,0,0),
    BackgroundTransparency=1, Text="Discord",
    TextColor3=C3(255,255,255), TextSize=11,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=106
}, btnDc)

btnDc.MouseEnter:Connect(function() tw(btnDc,0.15,{BackgroundColor3=C3(105,118,255)}) end)
btnDc.MouseLeave:Connect(function() tw(btnDc,0.15,{BackgroundColor3=C3(88,101,242)}) end)

local btnClose = new("TextButton", {
    Size=U2(0,30,0,22), Position=U2(1,-32,0.5,-11),
    BackgroundColor3=C3(192,45,45), BorderSizePixel=0,
    Text="", AutoButtonColor=false, ZIndex=105
}, header); rnd(5, btnClose)

local xA = new("Frame", {
    Size=U2(0,14,0,2), Position=U2(0.5,-7,0.5,-1),
    BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ZIndex=106,
    Rotation=45
}, btnClose); rnd(1,xA)
local xB = new("Frame", {
    Size=U2(0,14,0,2), Position=U2(0.5,-7,0.5,-1),
    BackgroundColor3=C3(255,255,255), BorderSizePixel=0, ZIndex=106,
    Rotation=-45
}, btnClose); rnd(1,xB)

btnClose.MouseEnter:Connect(function() tw(btnClose,0.15,{BackgroundColor3=C3(220,55,55)}) end)
btnClose.MouseLeave:Connect(function() tw(btnClose,0.15,{BackgroundColor3=C3(192,45,45)}) end)

-- ── DRAGGABLE ──────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=card.Position
        end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            card.Position=U2(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ── LOGO ZONE ────────────────────────────────────
local outerRing = new("Frame", {
    Size=U2(0,82,0,82), Position=U2(0.5,-41,0,40),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=102
}, card); rnd(41, outerRing)
local outerS = stk(C3(80,200,255), 1.2, outerRing)

local innerRing = new("Frame", {
    Size=U2(0,62,0,62), Position=U2(0.5,-31,0.5,-31),
    BackgroundColor3=C3(14,14,32), BorderSizePixel=0, ZIndex=103
}, outerRing); rnd(31, innerRing)
local innerS = stk(C3(130,90,240), 1.0, innerRing)

local logoImg = new("ImageLabel", {
    Size=U2(0,50,0,50), Position=U2(0.5,-25,0.5,-25),
    BackgroundTransparency=1, Image="",
    ScaleType=Enum.ScaleType.Fit, ZIndex=105, Visible=false
}, innerRing); rnd(10, logoImg)

local logoFallback = new("TextLabel", {
    Size=U2(1,0,1,0), BackgroundTransparency=1,
    Text=isFishing and "🎣" or "⭐", TextSize=26,
    Font=Enum.Font.Gotham, ZIndex=104, Visible=true
}, innerRing)

task.spawn(function()
    local loaded = false
    pcall(function()
        if writefile and isfile and getcustomasset then
            if D then pcall(function() print("[D] logo: download via writefile") end) end
            if not isfile("dimzhub_logo.png") then
                local data = game:HttpGet(LOGO_URL, true)
                if D then pcall(function() print("[D] logo: GET "..LOGO_URL.." → len="..tostring(#(data or ""))) end) end
                writefile("dimzhub_logo.png", data)
            end
            local uri = getcustomasset("dimzhub_logo.png")
            if D then pcall(function() print("[D] logo: customasset uri="..tostring(uri)) end) end
            if uri and uri ~= "" then
                logoImg.Image = uri
                logoImg.Visible = true
                logoFallback.Visible = false
                loaded = true
            end
        end
    end)
    if not loaded then
        pcall(function()
            logoImg.Image = LOGO_URL
            logoImg.Visible = true
            task.wait(2.5)
            if logoImg.IsLoaded then
                logoFallback.Visible = false
                loaded = true
            else
                logoImg.Visible = false
            end
        end)
    end
end)

local orbitPos = {
    U2(0.5,-3, 0,-3), U2(0.5,-3, 1,-3),
    U2(0,-3, 0.5,-3), U2(1,-3, 0.5,-3),
}
for i, pos in ipairs(orbitPos) do
    local dot = new("Frame", {
        Size=U2(0,5,0,5), Position=pos,
        BackgroundColor3=C3(80,200,255), BorderSizePixel=0, ZIndex=104
    }, outerRing); rnd(3,dot)
    task.spawn(function()
        task.wait((i-1)*0.45)
        while outerRing.Parent do
            tw(dot,0.5,{BackgroundTransparency=0},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
            task.wait(0.55)
            tw(dot,0.5,{BackgroundTransparency=0.8},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
            task.wait(0.55)
        end
    end)
end

task.spawn(function()
    local t=0
    while card.Parent do
        t=t+0.02
        local a=(math.sin(t)+1)/2
        local b=(math.sin(t+0.9)+1)/2
        if outerS.Parent then
            outerS.Color=C3(math.floor(28+a*55),math.floor(125+a*75),math.floor(195+a*60))
        end
        if innerS.Parent then
            innerS.Color=C3(math.floor(80+b*60),math.floor(58+b*80),math.floor(200+b*55))
        end
        task.wait(0.05)
    end
end)

-- ── GAME NAME ────────────────────────────────────
new("TextLabel", {
    Size=U2(1,-20,0,18), Position=U2(0,10,0,128),
    BackgroundTransparency=1, Text=gameName,
    TextColor3=C3(80,200,255), TextSize=12, Font=Enum.Font.GothamBold,
    TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=102
}, card)

-- ── USERNAME ─────────────────────────────────────
new("TextLabel", {
    Size=U2(1,-20,0,14), Position=U2(0,10,0,147),
    BackgroundTransparency=1,
    Text="\xF0\x9F\x91\xA4  " .. displayName,
    TextColor3=C3(48,70,105), TextSize=11, Font=Enum.Font.Gotham, ZIndex=102
}, card)

-- ── SEPARATOR ────────────────────────────────────
new("Frame", {
    Size=U2(1,-20,0,1), Position=U2(0,10,0,164),
    BackgroundColor3=C3(80,200,255), BackgroundTransparency=0.85,
    BorderSizePixel=0, ZIndex=102
}, card)

-- ── STATUS ROW ───────────────────────────────────
local statusRow = new("Frame", {
    Size=U2(1,-20,0,18), Position=U2(0,10,0,170),
    BackgroundTransparency=1, ZIndex=102
}, card)

local statusLbl = new("TextLabel", {
    Size=U2(1,-32,1,0), BackgroundTransparency=1,
    Text="Connecting to server", TextColor3=C3(118,145,170),
    TextSize=11, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102
}, statusRow)

local dotsLbl = new("TextLabel", {
    Size=U2(0,28,1,0), Position=U2(1,-28,0,0),
    BackgroundTransparency=1, Text="·  ",
    TextColor3=C3(80,200,255), TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102
}, statusRow)

-- ── PROGRESS BAR ─────────────────────────────────
local barBg = new("Frame", {
    Size=U2(1,-20,0,5), Position=U2(0,10,0,193),
    BackgroundColor3=C3(18,22,38), BorderSizePixel=0, ZIndex=102
}, card); rnd(3,barBg)

local barFill = new("Frame", {
    Size=U2(0,0,1,0), BackgroundColor3=C3(80,200,255),
    BorderSizePixel=0, ZIndex=103
}, barBg); rnd(3,barFill)

-- ── RESULT BOX ───────────────────────────────────
local resultBox = new("Frame", {
    Size=U2(1,-20,0,34), Position=U2(0,10,0,204),
    BackgroundColor3=C3(14,16,28), BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=102, Visible=false
}, card); rnd(8,resultBox)

local resultLbl = new("TextLabel", {
    Size=U2(1,-16,1,0), Position=U2(0,10,0,0),
    BackgroundTransparency=1, Text="",
    TextSize=11, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=103
}, resultBox)

-- ── KEY INPUT SECTION ────────────────────────────
local keySection = new("Frame", {
    Size=U2(1,-20,0,106), Position=U2(0,10,0,204),
    BackgroundTransparency=1, BorderSizePixel=0,
    ZIndex=102, Visible=false
}, card)

local keyInfoLbl = new("TextLabel", {
    Size=U2(1,0,0,14), Position=U2(0,0,0,0),
    BackgroundTransparency=1, Text="Enter your key.",
    TextColor3=C3(255,155,30), TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=103
}, keySection)

local keyBox = new("TextBox", {
    Size=U2(1,0,0,26), Position=U2(0,0,0,20),
    BackgroundColor3=C3(15,18,32), BorderSizePixel=0,
    Text="", PlaceholderText="Enter Your Key (Press Enter to Verify)",
    PlaceholderColor3=C3(42,56,88),
    TextColor3=C3(195,215,255), TextSize=10,
    Font=Enum.Font.Gotham, ClearTextOnFocus=false, ZIndex=103
}, keySection)
rnd(6, keyBox)
stk(C3(36,54,88), 1, keyBox)
do
    local p=Instance.new("UIPadding")
    p.PaddingLeft=UDim.new(0,8); p.PaddingRight=UDim.new(0,8)
    p.Parent=keyBox
end

local btnRow = new("Frame", {
    Size=U2(1,0,0,26), Position=U2(0,0,0,52),
    BackgroundTransparency=1, ZIndex=103
}, keySection)

local btnGetKey = new("TextButton", {
    Size=U2(0.48,0,1,0), BackgroundColor3=C3(86,62,202),
    BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=104
}, btnRow); rnd(6, btnGetKey)
local getKeyLbl = new("TextLabel", {
    Size=U2(1,0,1,0), BackgroundTransparency=1,
    Text="Get Key", TextColor3=C3(255,255,255),
    TextSize=11, Font=Enum.Font.GothamBold, ZIndex=105
}, btnGetKey)

local btnVerify = new("TextButton", {
    Size=U2(0.48,0,1,0), Position=U2(0.52,0,0,0),
    BackgroundColor3=C3(18,24,42), BorderSizePixel=0,
    Text="", AutoButtonColor=false, ZIndex=104
}, btnRow); rnd(6, btnVerify)
stk(C3(44,62,108), 1, btnVerify)
local verifyLbl = new("TextLabel", {
    Size=U2(1,0,1,0), BackgroundTransparency=1,
    Text="Verify", TextColor3=C3(158,185,255),
    TextSize=11, Font=Enum.Font.GothamBold, ZIndex=105
}, btnVerify)

btnGetKey.MouseEnter:Connect(function() tw(btnGetKey,0.12,{BackgroundColor3=C3(102,76,220)}) end)
btnGetKey.MouseLeave:Connect(function() tw(btnGetKey,0.12,{BackgroundColor3=C3(86,62,202)}) end)
btnVerify.MouseEnter:Connect(function() tw(btnVerify,0.12,{BackgroundColor3=C3(26,32,55)}) end)
btnVerify.MouseLeave:Connect(function() tw(btnVerify,0.12,{BackgroundColor3=C3(18,24,42)}) end)

local premBanner = new("Frame", {
    Size=U2(1,0,0,22), Position=U2(0,0,0,84),
    BackgroundColor3=C3(22,16,4), BorderSizePixel=0,
    ClipsDescendants=true, ZIndex=103
}, keySection)
rnd(5, premBanner)
stk(C3(175,136,0), 1, premBanner)

new("TextLabel", {
    Size=U2(0.60,0,1,0), Position=U2(0,8,0,0),
    BackgroundTransparency=1, Text="Tired of key? Buy Premium",
    TextColor3=C3(180,148,42), TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=105
}, premBanner)

local buyBtn = new("TextButton", {
    Size=U2(0,60,0,16), Position=U2(1,-65,0.5,-8),
    BackgroundColor3=C3(182,128,0), BorderSizePixel=0,
    Text="", AutoButtonColor=false, ZIndex=106
}, premBanner); rnd(4, buyBtn)
local buyLbl = new("TextLabel", {
    Size=U2(1,0,1,0), BackgroundTransparency=1,
    Text="Buy Now", TextColor3=C3(16,10,0),
    TextSize=9, Font=Enum.Font.GothamBold, ZIndex=107
}, buyBtn)

local shimmer = new("Frame", {
    Size=U2(0,32,1,0), Position=U2(-0.15,0,0,0),
    BackgroundColor3=C3(255,230,128), BackgroundTransparency=0.6,
    BorderSizePixel=0, ZIndex=104
}, premBanner); rnd(2, shimmer)
task.spawn(function()
    while keySection.Parent do
        shimmer.Position=U2(-0.15,0,0,0)
        tw(shimmer, 1.3, {Position=U2(1.1,0,0,0)}, Enum.EasingStyle.Linear)
        task.wait(2.1)
    end
end)

-- ================================================
-- HELPER ANIMASI
-- ================================================
local function animBar(scale, dur, col)
    tw(barFill, dur, {Size=U2(scale,0,1,0)})
    if col then tw(barFill, dur*0.3, {BackgroundColor3=col}) end
end

local function animStroke(col, dur)
    tw(cardStroke, dur or 0.3, {Color=col})
end

local function resizeCard(state)
    local h = cardH(state)
    local curPos = card.Position
    tw(card, 0.28, {
        Size = U2(0,CW,0,h),
        Position = U2(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, -(h/2))
    })
end

local function showResult(txt, tc, bc)
    keySection.Visible = false
    resultBox.Visible  = true
    resultLbl.Text       = txt
    resultLbl.TextColor3 = tc
    tw(resultBox, 0.25, {BackgroundTransparency=0, BackgroundColor3=bc})
    resizeCard("result")
end

local function showKeyInput(msg, isExp)
    resultBox.Visible  = false
    keySection.Visible = true
    statusLbl.Text     = ""
    dotsLbl.Text       = ""
    if msg then
        keyInfoLbl.Text       = msg
        keyInfoLbl.TextColor3 = isExp and C3(255,155,30) or C3(255,80,80)
    end
    resizeCard("key")
end

local function shakeCard()
    local b = card.Position
    for i = 1,6 do
        tw(card,0.04,{Position=U2(b.X.Scale,b.X.Offset+(i%2==0 and 7 or -7),b.Y.Scale,b.Y.Offset)})
        task.wait(0.045)
    end
    tw(card,0.08,{Position=b})
end

local function fadeClose(delay)
    task.wait(delay or 0)
    local p = card.Position
    tw(card,0.4,{Position=U2(p.X.Scale,p.X.Offset,p.Y.Scale+0.1,p.Y.Offset)},
        Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tw(overlay,0.4,{BackgroundTransparency=1})
    task.wait(0.45)
    pcall(function() screenGui:Destroy() end)
end

local dotsOn  = true
local pulseOn = true
local barOn   = true
local dotF    = {"·  ","·· ","···","·· "}
local dotI    = 0

task.spawn(function()
    while dotsOn do
        dotI=(dotI%#dotF)+1
        pcall(function() dotsLbl.Text=dotF[dotI] end)
        task.wait(0.3)
    end
end)
task.spawn(function()
    local b=true
    while pulseOn do
        tw(cardStroke,0.55,{Color=b and C3(80,200,255) or C3(24,66,118)},
            Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        b=not b; task.wait(0.6)
    end
end)
task.spawn(function()
    local f=true
    while barOn do
        tw(barFill,0.65,{Size=U2(f and 0.5 or 0.05,0,1,0)},
            Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
        f=not f; task.wait(0.7)
    end
end)

local function stopAnims()
    dotsOn=false; pulseOn=false; barOn=false
    task.wait(0.05)
    pcall(function() dotsLbl.Text="" end)
end

-- ================================================
-- API CALL
-- ================================================
local function requestProxy(url, method, headers, body)
    local tbl = {Url = url, Method = method, Headers = headers, Body = body}
    if D then pcall(function()
        local av = ("request=%s syn=%s http=%s HttpGet=%s"):format(
            tostring(request), tostring(syn and syn.request),
            tostring(http and http.request), tostring(game.HttpGet))
        print("[D] req methods: "..av)
    end) end

    if request then
        local ok, res = pcall(request, tbl)
        if D then pcall(function() print("[D] request() → ok="..tostring(ok).." type="..type(res).." code="..tostring(res and res.StatusCode)) end) end
        if ok and res and type(res) == "table" and res.Body then return res end
    end

    if syn and syn.request then
        local ok, res = pcall(syn.request, tbl)
        if D then pcall(function() print("[D] syn.request() → ok="..tostring(ok).." type="..type(res).." code="..tostring(res and res.StatusCode)) end) end
        if ok and res and type(res) == "table" and res.Body then return res end
    end

    if http and http.request then
        local ok, res = pcall(http.request, tbl)
        if D then pcall(function() print("[D] http.request(tbl) → ok="..tostring(ok).." type="..type(res)) end) end
        if ok and res and type(res) == "table" and res.Body then return res end
        local ok, res = pcall(http.request, url, method, headers, body)
        if D then pcall(function() print("[D] http.request(pos) → ok="..tostring(ok).." type="..type(res)) end) end
        if ok then
            if type(res) == "table" then return res end
            if type(res) == "string" then return {Body = res} end
        end
    end

    if method == "POST" then
        local ok, res = pcall(function()
            return game:HttpGet(url .. "?" .. HttpService:URLEncode(body))
        end)
        if D then pcall(function() print("[D] game:HttpGet → ok="..tostring(ok).." len="..tostring(#(res or ""))) end) end
        if ok and res and res ~= "" then return {Body = res} end
    end

    if D then pcall(function() print("[D] ❌ SEMUA METHOD GAGAL") end) end
    return nil
end

local function callApi(url, payload)
    local body = HttpService:JSONEncode(payload)
    if D then pcall(function() print("[D] callApi → POST "..url.." payload="..body:sub(1,100)) end) end
    local res = requestProxy(url, "POST",
        {
            ["Content-Type"] = "application/json",
            ["X-Api-Secret"] = API_SECRET,
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
        body
    )
    if not res then
        if D then pcall(function() print("[D] callApi: ❌ res = nil") end) end
        return nil, "Empty response"
    end
    if not res.Body then
        if D then pcall(function() print("[D] callApi: ❌ res.Body = nil, status="..tostring(res.StatusCode)) end) end
        return nil, "Empty response"
    end
    local bodyStr = tostring(res.Body)
    local code = res.StatusCode or "?"
    if D then pcall(function() print("[D] callApi: status="..tostring(code).." body("..#bodyStr.."c)="..bodyStr:sub(1,250)) end) end
    local dok, dec = pcall(HttpService.JSONDecode, HttpService, bodyStr)
    if not dok then
        if D then pcall(function() print("[D] callApi: ❌ JSON decode gagal") end) end
        return nil, "JSON error"
    end
    if D then pcall(function() print("[D] callApi: ✅ sukses — "..tostring(dec.success)) end) end
    return dec, nil
end

-- ================================================
-- LOAD SCRIPT UTAMA
-- ================================================
local function loadMain()
    statusLbl.Text       = "Loading script..."
    statusLbl.TextColor3 = C3(118,145,170)
    animBar(1,0.3)
    task.wait(0.3)
    
    -- ✅ URL sudah dipilih berdasarkan _G.pearlsFarm di getScriptUrl
    local url = getScriptUrl(placeId,isFishing)
    if not url then
        animStroke(C3(255,75,75))
        animBar(1,0.2,C3(255,75,75))
        statusLbl.Text       = "Script not available"
        statusLbl.TextColor3 = C3(255,80,80)
        resultLbl.Text       = "❌  No script found for this game."
        resultLbl.TextColor3 = C3(255,80,80)
        resultBox.Visible    = true
        task.wait(5)
        pcall(function() screenGui:Destroy() end)
        return
    end
    
    -- Download source + inject key langsung ke execution context yang sama
    if D then pcall(function() print("[D] loadMain: GET "..url) end) end
    local src = game:HttpGet(url)
    if D then pcall(function() print("[D] loadMain: GET → len="..tostring(#(src or ""))) end) end
    if not src or src == "" then
        if D then pcall(function() print("[D] loadMain: ❌ gagal download") end) end
        animStroke(C3(255,148,38))
        statusLbl.Text       = "Failed to load"
        statusLbl.TextColor3 = C3(255,148,38)
        resultLbl.Text       = "⚠  Failed to download script"
        resultLbl.TextColor3 = C3(255,148,38)
        resultBox.Visible    = true
        task.wait(5)
        pcall(function() screenGui:Destroy() end)
        return
    end
    
    local inject = ""
    if savedKey and savedKey ~= "" then
        local safeKey   = string.format("%q", savedKey)
        local safeToken = string.format("%q", savedToken or "")
        inject = "do local _k=" .. safeKey .. ";local _t=" .. safeToken
            .. ";_G.DIMZ_KEY=_k;_G.DIMZ_TOKEN=_t;_G.Key=_k"
            .. ";" .. "pcall(function()"
            .. "if writefile then writefile(\"dimzhub_key.txt\","
            .. "\"key=\".._k..\"\\ntok=\"..(_t or \"\")) end end)"
            .. ";pcall(function()"
            .. "if getgenv then getgenv().Key=_k end end) end"
    else
        inject = "do _G.DIMZ_PREMIUM=true end"
    end
    
    if D then pcall(function() print("[D] loadMain: loadstring "..tostring(#(inject..src)).." chars") end) end
    local ls_ok, ls_fn, ls_err = pcall(loadstring, inject .. "\n" .. src)
    if D then pcall(function() print("[D] loadMain: loadstring → ok="..tostring(ls_ok).." type="..type(ls_fn).." err="..tostring(ls_err or ls_fn):sub(1,80)) end) end
    if not ls_ok or type(ls_fn) ~= "function" then
        local load_err = (ls_ok and ls_err) or ls_fn or "loadstring error"
        animStroke(C3(255,148,38))
        statusLbl.Text       = "Failed to load"
        statusLbl.TextColor3 = C3(255,148,38)
        resultLbl.Text       = "⚠  " .. tostring(load_err):sub(1,80)
        resultLbl.TextColor3 = C3(255,148,38)
        resultBox.Visible    = true
        task.wait(5)
        pcall(function() screenGui:Destroy() end)
        return
    end
    local sp_ok, sp_err = pcall(task.spawn, ls_fn)
    if D then pcall(function() print("[D] loadMain: task.spawn → ok="..tostring(sp_ok).." err="..tostring(sp_err or "?")) end) end
    if not sp_ok then
        pcall(task.spawn, function()
            local s, e = pcall(ls_fn)
        end)
    end
    fadeClose(0.4)
end

-- ================================================
-- VERIFY KEY
-- ================================================
local verifying = false

local function doVerify()
    if verifying then return end
    local key = keyBox.Text:match("^%s*(.-)%s*$")
    if #key < 6 then
        keyInfoLbl.Text       = "Key is too short."
        keyInfoLbl.TextColor3 = C3(255,80,80)
        return
    end

    verifying = true
    keySection.Visible=false; resultBox.Visible=false
    dotsOn=true; barOn=true

    statusLbl.Text="Security Handshake..."
    statusLbl.TextColor3=C3(80,200,255)
    animBar(0.3,0.5,C3(80,200,255))
    task.wait(1.0)
    statusLbl.Text="Encrypting key..."
    statusLbl.TextColor3=C3(110,170,255)
    animBar(0.6,0.4,C3(110,170,255))
    task.wait(1.0)
    statusLbl.Text="Verifying key..."
    statusLbl.TextColor3=C3(118,145,170)

    if D then pcall(function() print("[D] doVerify: callApi verify_key key="..key:sub(1,8).." hwid="..hwid:sub(1,20)) end) end
    local res,err = callApi(KEY_GATEWAY,{
        action="verify_key", key_value=key,
        hwid=hwid, username=username, game=gameName
    })
    dotsOn=false; barOn=false; verifying=false
    if D then pcall(function() print("[D] doVerify: res="..tostring(res).." err="..tostring(err)) end) end

    if not res then
        if D then pcall(function() print("[D] doVerify: ❌ callApi gagal: "..tostring(err)) end) end
        animBar(1,0.3,C3(255,75,75)); animStroke(C3(255,75,75))
        statusLbl.Text="Connection failed"; task.wait(1.5)
        showKeyInput("Connection failed. Please try again.",false)
        return
    end

    if not res.success then
        local reason = res.reason or ""
        local isExp  = (reason=="key_expired")
        local col    = C3(255,65,65)
        local stMsg  = "Invalid key"
        local infoMsg= res.message or "Invalid key."

        if reason == "key_expired" then
            col=C3(255,148,30); stMsg="Key expired"
            infoMsg=res.message or "Key has expired. Please get a new key."
        elseif reason == "key_not_found" then
            stMsg="Key not found"
            infoMsg="Key not found in database. Please check your key."
        elseif reason == "key_deleted" then
            stMsg="Key deleted"
            infoMsg="This key has been deleted. Contact admin or get a new key."
        elseif reason == "hwid_mismatch" then
            col=C3(255,100,50); stMsg="HWID mismatch"
            infoMsg="This key is registered on another device. Contact admin."
        elseif reason == "hwid_empty" then
            col=C3(255,148,30); stMsg="Re-verification required"
            infoMsg="Please re-enter your key to re-register this device."
        elseif reason == "banned" then
            col=C3(180,20,20); stMsg="Account banned"
            infoMsg="Your account is banned. Contact admin on Discord."
        elseif reason == "max_devices" then
            col=C3(255,100,50); stMsg="Device limit reached"
            infoMsg="Key is already in use on another device. 1 key = 1 device."
        end

        animBar(1,0.3,col); animStroke(col)
        statusLbl.Text       = stMsg
        statusLbl.TextColor3 = col
        task.wait(0.6); shakeCard(); task.wait(0.5)
        showKeyInput(infoMsg, isExp)
        return
    end

    clearKey(); saveKey(key, res.session_token or "")
    local isVip = (res.vip==1)
    animBar(0.9,0.3,C3(50,210,130)); animStroke(C3(50,210,130))
    statusLbl.Text       = isVip and "VIP Key ⭐" or "Key valid ✓"
    statusLbl.TextColor3 = C3(50,220,130)
    showResult((isVip and "⭐  " or "✅  ")..(res.username or displayName),
        C3(50,225,130), C3(5,32,14))
    animBar(1,0.25); task.wait(1.1); loadMain()
end

-- ================================================
-- MAIN FLOW
-- ================================================
task.spawn(function()
    task.wait(0.5)

    setMSt("Security Handshake...", C3(80,200,255))
    task.wait(1.0)
    setMSt("Encrypting session...", C3(110,170,255))
    task.wait(1.0)
    setMSt("Contacting server...", C3(80,115,155))

    if D then pcall(function() print("[D] mainFlow: callApi PREM_GATEWAY username="..username) end) end
    local res,err = callApi(PREM_GATEWAY,{
        action="check_member_premium", username=username
    })
    stopAnims()
    if D then pcall(function() print("[D] mainFlow: res="..tostring(res).." err="..tostring(err)) end) end

    if not res then
        if D then pcall(function() print("[D] mainFlow: ❌ PREM_GATEWAY gagal: "..tostring(err)) end) end
        tw(mBarFill, 0.3, {BackgroundColor3=C3(255,75,75), Size=U2(1,0,1,0)})
        setMSt("Connection failed", C3(255,80,80)); task.wait(1.0)
        miniOut(); task.wait(0.1)
        animBar(1,0.3,C3(255,75,75)); animStroke(C3(255,75,75))
        statusLbl.Text="Connection failed"
        statusLbl.TextColor3=C3(255,100,80)
        showResult("❌  Failed to connect to server.",C3(255,100,80),C3(48,10,10))
        task.wait(4)
        pcall(function() screenGui:Destroy() end); return
    end

    if res.success then
        local isVip=(res.vip==1)
        if res.activation_key and res.activation_key ~= "" then
            savedKey   = res.activation_key
            savedToken = ""
        end
        tw(mBarFill, 0.4, {BackgroundColor3=C3(50,210,130), Size=U2(1,0,1,0)})
        setMSt(isVip and "✓ VIP Member" or "✓ Member verified", C3(50,210,130))
        task.wait(0.6); miniOut(); task.wait(0.15)
        animBar(0.75,0.3,C3(50,210,130)); animStroke(C3(50,210,130))
        statusLbl.Text       = isVip and "VIP Member ⭐" or "Member verified"
        statusLbl.TextColor3 = C3(50,220,130)
        showResult((isVip and "⭐  " or "✅  ")..(res.username or displayName).."  |  HP: "..(res.nomor or "—"),
            C3(50,225,130), C3(5,32,14))
        animBar(1,0.25); task.wait(1.0); loadMain(); return
    end

    setMSt("Checking saved key...", C3(80,115,155))
    task.wait(0.3)

    if savedKey ~= "" then
        if D then pcall(function() print("[D] mainFlow: callApi check_session") end) end
        local kres,kerr = callApi(KEY_GATEWAY,{
            action="check_session", key_value=savedKey,
            session_token=savedToken, hwid=hwid,
            username=username, game=gameName
        })
        if D then pcall(function() print("[D] mainFlow: kres="..tostring(kres).." kerr="..tostring(kerr)) end) end

        if kerr or not kres then
            if D then pcall(function() print("[D] mainFlow: ❌ check_session gagal") end) end
            tw(mBarFill, 0.3, {BackgroundColor3=C3(255,75,75), Size=U2(1,0,1,0)})
            setMSt("Connection failed", C3(255,80,80)); task.wait(0.8)
            saveKey(savedKey,savedToken)
            miniOut(); task.wait(0.15)
            animBar(1,0.3,C3(255,75,75)); animStroke(C3(255,75,75))
            statusLbl.Text="Connection failed"
            shakeCard(); task.wait(0.4)
            showKeyInput("Connection failed. Your key is saved, please try again.",false)
            return
        end

        if kres.success then
            local isVip=(kres.vip==1)
            tw(mBarFill, 0.4, {BackgroundColor3=C3(50,210,130), Size=U2(1,0,1,0)})
            setMSt("✓ Key active", C3(50,210,130)); task.wait(0.6)
            miniOut(); task.wait(0.15)
            animBar(0.85,0.3,C3(50,210,130)); animStroke(C3(50,210,130))
            statusLbl.Text="Key active ✓"
            statusLbl.TextColor3=C3(50,220,130)
            showResult((isVip and "⭐  " or "✅  ")..(kres.username or displayName),
                C3(50,225,130), C3(5,32,14))
            animBar(1,0.25); task.wait(1.0); loadMain(); return
        end

        local reason  = kres.reason or ""
        local isExp   = (reason=="key_expired" or reason=="session_invalid")
        local col     = C3(255,65,65)
        local stMsg   = "Invalid key"
        local infoMsg = kres.message or "Invalid key. Please enter a new key."

        if reason == "hwid_empty" then
            clearKey()
            col=C3(255,148,30); stMsg="Re-verification required"
            infoMsg="Your device is not registered. Please re-enter your key to re-register."
            tw(mBarFill, 0.3, {BackgroundColor3=col, Size=U2(1,0,1,0)})
            setMSt(stMsg, col); task.wait(0.8)
            miniOut(); task.wait(0.15)
            animBar(1,0.3,col); animStroke(col)
            statusLbl.Text       = stMsg
            statusLbl.TextColor3 = col
            shakeCard(); task.wait(0.4)
            showKeyInput(infoMsg, false)
            return
        end

        clearKey()

        if reason == "key_expired" then
            col=C3(255,148,30); stMsg="Key expired"
            infoMsg="Key has expired. Get a new key at dimzhub.my.id/key"
        elseif reason == "hwid_mismatch" then
            col=C3(255,100,50); stMsg="HWID mismatch"
            infoMsg="This key is registered on another device. Contact admin if this is yours."
        elseif reason == "key_not_found" then
            stMsg="Key not found"
            infoMsg="This key no longer exists in the database. Get a new key."
        elseif reason == "key_deleted" then
            stMsg="Key deleted"
            infoMsg="This key was deleted by admin. Get a new key."
        elseif reason == "session_invalid" then
            col=C3(255,148,30); stMsg="Session invalid"
            infoMsg="Session expired. Please re-enter your key."
        elseif reason == "banned" then
            col=C3(180,20,20); stMsg="Account banned"
            infoMsg="Your account is banned. Contact admin on Discord."
        end

        if kres.message and kres.message ~= "" then infoMsg = kres.message end

        tw(mBarFill, 0.3, {BackgroundColor3=col, Size=U2(1,0,1,0)})
        setMSt(stMsg, col); task.wait(0.8)
        miniOut(); task.wait(0.15)
        animBar(1,0.3,col); animStroke(col)
        statusLbl.Text       = stMsg
        statusLbl.TextColor3 = col
        shakeCard(); task.wait(0.4)
        showKeyInput(infoMsg, isExp)

    else
        tw(mBarFill, 0.3, {BackgroundColor3=C3(255,148,30), Size=U2(0.8,0,1,0)})
        setMSt("No key found", C3(255,148,30)); task.wait(0.6)
        miniOut(); task.wait(0.15)
        animBar(1,0.3,C3(255,148,30)); animStroke(C3(255,148,30))
        statusLbl.Text       = "No key found"
        statusLbl.TextColor3 = C3(255,148,30)
        shakeCard(); task.wait(0.3)
        showKeyInput(displayName.." has no key. Get your key first!",false)
    end
end)

-- ================================================
-- BUTTON EVENTS
-- ================================================
btnClose.MouseButton1Click:Connect(function()
    tw(card,0.28,{BackgroundTransparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tw(overlay,0.28,{BackgroundTransparency=1})
    task.wait(0.3)
    pcall(function() screenGui:Destroy() end)
    pcall(miniOut)
end)

btnDc.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(DISCORD_URL) end)
    tw(btnDc, 0.1, {BackgroundColor3=C3(50,210,130)})
    dcTxtLbl.Text = "✓ Copied!"
    dcIcon.Visible = false
    task.wait(1.3)
    tw(btnDc, 0.2, {BackgroundColor3=C3(88,101,242)})
    dcTxtLbl.Text = "Discord"
    dcIcon.Visible = true
end)

btnGetKey.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(KEY_PAGE_URL) end)
    getKeyLbl.Text="Copied!"
    keyInfoLbl.TextColor3=C3(80,200,255)
    keyInfoLbl.Text="Link copied! Open it in your browser."
    keyInfoLbl.TextColor3=C3(80,200,255)
    task.wait(2)
    pcall(function() getKeyLbl.Text="Get Key" end)
end)

buyBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard(BUY_PREM_URL) end)
    buyLbl.Text="Copied!"
    task.wait(1.5)
    pcall(function() buyLbl.Text="Buy Now" end)
end)

btnVerify.MouseButton1Click:Connect(function() doVerify() end)
keyBox.FocusLost:Connect(function(enter) if enter then doVerify() end end)
