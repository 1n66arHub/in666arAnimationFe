--[[
FE UGC ANIMATIONS V2.7.6-OBSIDIAN-R2.6.4
Made By @in66ar

Fix final:
  - FIX: syntax error "local = " di akhir script
  - FIX: tab visual balik ke lama setelah hover
         (attribute _tk_BackgroundColor3 di-update juga)
]]

local track
do
	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	if type(env.__FeUgcAnimKill) == "function" then pcall(env.__FeUgcAnimKill) end
	local conns = {}
	env.__FeUgcAnimKill = function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		table.clear(conns)
		local roots = {}
		pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
		pcall(function() if typeof(gethui) == "function" then table.insert(roots, gethui()) end end)
		pcall(function() table.insert(roots, game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")) end)
		for _, rt in ipairs(roots) do
			pcall(function()
				for _, c in ipairs(rt:GetChildren()) do
					if c.Name == "StudioAnimStudio" then c:Destroy() end
				end
			end)
		end
		pcall(function()
			for _, c in ipairs(game:GetService("SoundService"):GetChildren()) do
				if c.Name == "FeUgcClick" then c:Destroy() end
			end
		end)
	end
	track = function(c) table.insert(conns, c); return c end
end

local Shime = (function()
	local Shime = {}
	Shime.__index = Shime
	local TS = game:GetService("TweenService")
	local function createShimmer(parent)
		local frame = Instance.new("Frame")
		frame.Name = "UIShimmer"
		frame.BackgroundColor3 = Color3.fromRGB(255,255,255)
		frame.BackgroundTransparency = 0
		frame.ClipsDescendants = true
		frame.Size = UDim2.new(1,0,1,0)
		frame.AnchorPoint = Vector2.new(0.5,0.5)
		frame.Position = UDim2.new(0.5,0,0.5,0)
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = parent
		local function updCR()
			if frame.Parent and frame.Parent:FindFirstChildOfClass("UICorner") then
				local pc = frame.Parent:FindFirstChildOfClass("UICorner")
				local c = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
				c.CornerRadius = pc.CornerRadius
				c.Parent = frame
			end
		end
		frame:GetPropertyChangedSignal("Parent"):Connect(updCR)
		updCR()
		local grad = Instance.new("UIGradient")
		grad.Rotation = 15
		grad.Color = ColorSequence.new(Color3.new(1,1,1))
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(0.15,1),
			NumberSequenceKeypoint.new(0.5,0.82),
			NumberSequenceKeypoint.new(0.85,1),
			NumberSequenceKeypoint.new(1,1),
		})
		grad.Offset = Vector2.new(-1,0)
		grad.Parent = frame
		return frame
	end
	Shime.PlaybackState = nil
	function Shime.new(parent, time, style, direction, rc, rev, delay)
		time = time or 1; style = style or Enum.EasingStyle.Linear
		direction = direction or Enum.EasingDirection.InOut
		rc = rc or -1; rev = rev or false; delay = delay or 0
		local self = setmetatable({}, Shime)
		local shimmer = createShimmer(parent)
		self._frame = shimmer
		self._gradient = shimmer:FindFirstChildOfClass("UIGradient")
		self._tween = TS:Create(self._gradient, TweenInfo.new(time, style, direction, rc, rev, delay), {Offset = Vector2.new(1,0)})
		self._tween.Completed:Connect(function()
			shimmer.Visible = false
			self.PlaybackState = Enum.PlaybackState.Completed
		end)
		return self
	end
	function Shime:Play()
		self.PlaybackState = Enum.PlaybackState.Begin
		self._frame.Visible = true
		self._tween:Play()
		self.PlaybackState = Enum.PlaybackState.Playing
	end
	function Shime:Cancel()
		self._tween:Cancel()
		self._frame.Visible = false
		self.PlaybackState = Enum.PlaybackState.Cancelled
	end
	function Shime:Pause() if self._tween then pcall(function() self._tween:Pause() end) end end
	function Shime:Resume() if self._tween then pcall(function() self._tween:Play() end) end end
	return Shime
end)()

local activeShimmers = {}
local function pauseAllShimmers() for _, sh in ipairs(activeShimmers) do pcall(function() sh:Pause() end) end end
local function resumeAllShimmers() for _, sh in ipairs(activeShimmers) do pcall(function() sh:Resume() end) end end

local debouncedWrite, flushPendingWrites, SoundFx
do
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local SFX_URL = "https://cdn.jsdelivr.net/gh/1n66arHub/in666arAnimationFe@main/ui_click.mp3"
local SFX_FILE = "FeUgcAnim_click_v1.mp3"
local SFX_MIN_SIZE = 5000
local SFX_VOLUME = 0.6
local SFX_SETTINGS_FILE = "FE_UGC_Sound.json"

local _writeSeq = 0
local _writeToken = {}
local _writeTimers = {}
local _pendingWrites = {}

function debouncedWrite(file, jsonString, delay)
	delay = delay or 0.3
	if not writefile then return end
	_writeSeq = _writeSeq + 1
	local myToken = _writeSeq
	_writeToken[file] = myToken
	_pendingWrites[file] = jsonString
	if _writeTimers[file] then pcall(task.cancel, _writeTimers[file]) end
	_writeTimers[file] = task.delay(delay, function()
		if _writeToken[file] ~= myToken then return end
		local s = _pendingWrites[file]
		if s == nil then return end
		_writeToken[file] = nil; _pendingWrites[file] = nil; _writeTimers[file] = nil
		local ok = pcall(function() writefile(file, s) end)
		if not ok then warn("[debouncedWrite] write failed: " .. tostring(file)) end
	end)
end

function flushPendingWrites()
	if not writefile then
		_pendingWrites = {}; _writeToken = {}
		for _, t in pairs(_writeTimers) do pcall(task.cancel, t) end
		_writeTimers = {}; return
	end
	for f, s in pairs(_pendingWrites) do
		local ok = pcall(function() writefile(f, s) end)
		if not ok then warn("[flush] write failed: " .. tostring(f)) end
	end
	_pendingWrites = {}; _writeToken = {}
	for _, t in pairs(_writeTimers) do pcall(task.cancel, t) end
	_writeTimers = {}
end

local sfxClick = nil
do
	local getAsset = getcustomasset or getsynasset
	if getAsset and writefile and isfile and readfile then
		pcall(function()
			local needDownload = true
			if isfile(SFX_FILE) then
				local ok, sz = pcall(function() return #readfile(SFX_FILE) end)
				if ok and sz and sz >= SFX_MIN_SIZE then needDownload = false
				else pcall(delfile, SFX_FILE) end
			end
			if needDownload then
				local data = game:HttpGet(SFX_URL)
				local b1, b2 = 0, 0
				if type(data) == "string" and #data >= 2 then b1, b2 = data:byte(1, 2) end
				local isMp3 = type(data) == "string" and #data >= SFX_MIN_SIZE
					and (data:sub(1,3) == "ID3" or (b1 == 0xFF and b2 >= 0xE0))
				if isMp3 then writefile(SFX_FILE, data) end
			end
			if isfile(SFX_FILE) then sfxClick = getAsset(SFX_FILE) end
		end)
	end
end

local sfxEnabled = true
do
	local ok, content = pcall(function()
		if isfile and not isfile(SFX_SETTINGS_FILE) then return nil end
		return readfile(SFX_SETTINGS_FILE)
	end)
	if ok and content then
		local suc, dec = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
		if suc and type(dec) == "table" and dec.enabled ~= nil then
			sfxEnabled = dec.enabled and true or false
		end
	end
end

local function saveSfxSetting()
	debouncedWrite(SFX_SETTINGS_FILE, game:GetService("HttpService"):JSONEncode({enabled = sfxEnabled}))
end

local sfxTemplate = nil
if sfxClick then
	sfxTemplate = Instance.new("Sound")
	sfxTemplate.Name = "FeUgcClick"; sfxTemplate.SoundId = sfxClick
	sfxTemplate.Volume = SFX_VOLUME; sfxTemplate.Parent = SoundService
end

SoundFx = (function()
	local sfx = {}
	function sfx.click()
		if not sfxEnabled or not sfxTemplate then return end
		local snd = sfxTemplate:Clone(); snd.Parent = SoundService; snd:Play()
		Debris:AddItem(snd, 2)
	end
	function sfx.toggle()
		if not sfxEnabled or not sfxTemplate then return end
		local snd = sfxTemplate:Clone(); snd.PlaybackSpeed = 0.85
		snd.Parent = SoundService; snd:Play(); Debris:AddItem(snd, 2)
	end
	function sfx.setEnabled(v) sfxEnabled = v and true or false; saveSfxSetting() end
	function sfx.isEnabled() return sfxEnabled end
	return sfx
end)()
end

local plrs = game:GetService("Players")
local as = game:GetService("AssetService")
local aes = game:GetService("AvatarEditorService")
local rs = game:GetService("RunService")
local hs = game:GetService("HttpService")
local cp = game:GetService("ContentProvider")
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer

local FONT = {
	title = Enum.Font.GothamBlack, subtitle = Enum.Font.SourceSansLight,
	tab = Enum.Font.GothamSemibold, slot = Enum.Font.SourceSansSemibold,
	button = Enum.Font.GothamSemibold, buttonSm = Enum.Font.SourceSansSemibold,
	label = Enum.Font.GothamMedium, chip = Enum.Font.SourceSansSemibold,
}

local m = {
	["runanimation"]="run",["climbanimation"]="climb",["jumpanimation"]="jump",
	["fallanimation"]="fall",["idleanimation"]="idle",["swimidleanimation"]="swimidle",
	["swimanimation"]="swim",["walkanimation"]="walk"
}
local shortNames = {
	["idleanimation"]="Idle",["walkanimation"]="Walk",["runanimation"]="Run",
	["jumpanimation"]="Jump",["fallanimation"]="Fall",["climbanimation"]="Climb",
	["swimidleanimation"]="S.Idle",["swimanimation"]="Swim"
}
local buttonOrder = {"idleanimation","walkanimation","runanimation","jumpanimation","fallanimation","climbanimation","swimidleanimation","swimanimation"}

local function uchr(...) return string.char(...) end
local ICO_DOTS = uchr(226,128,166)
local ICO_DOT  = uchr(226,128,162)

local CACHE_FILE_NAME = "animation_bundle_data_cache.json"
local ANIM_CACHE_URL = "https://raw.githubusercontent.com/TribalFootball/TuffTeto/main/animation_bundle_data_cache.json"
local EQUIPPED_FILE = "FeUgcAnim.json"
local SAVED_BUNDLES_FILE = "FeUgcAnim_Bookmarks.json"
local THEME_FILE = "FE_UGC_Animations_Theme.json"

local EMOTE_URL = "https://raw.githubusercontent.com/DRYF-1/Roblox-Emote/refs/heads/main/EmoteSniper.json"
local emoteList, emoteFiltered = {}, {}
local emoteLoadStatus = "Loading emotes..."

local function fetchSniperJson(url)
	local ok, data = pcall(function() return game:HttpGet(url) end)
	if not ok or type(data) ~= "string" then return nil end
	local suc, dec = pcall(function() return hs:JSONDecode(data) end)
	if not suc or type(dec) ~= "table" or type(dec.data) ~= "table" then return nil end
	return dec.data
end

task.spawn(function()
	local t = tick()
	local data = fetchSniperJson(EMOTE_URL)
	if not data then emoteLoadStatus = "Fetch failed" return end
	for _, info in pairs(data) do
		if type(info) == "table" and info.name and info.id then
			table.insert(emoteList, {Id = tonumber(info.id), Name = tostring(info.name)})
		end
	end
	table.sort(emoteList, function(a,b) return a.Name:lower() < b.Name:lower() end)
	emoteLoadStatus = #emoteList .. " emotes"
	print("[V2.7.6-OBSIDIAN-R2.6.4] Emotes:", emoteLoadStatus, string.format("(%.1fs)", tick() - t))
end)

local Themes = {
Dark = {
	bg=Color3.fromRGB(6,6,8),
	panel=Color3.fromRGB(14,14,16),
	surface=Color3.fromRGB(26,26,30),
	surfaceHi=Color3.fromRGB(42,42,47),
	stroke=Color3.fromRGB(60,60,66),
	strokeStrong=Color3.fromRGB(100,100,106),
	accent=Color3.fromRGB(248,248,248),
	accentDim=Color3.fromRGB(125,125,130),
	silver=Color3.fromRGB(196,196,204),
	silverDim=Color3.fromRGB(120,120,128),
	green=Color3.fromRGB(220,220,220),
	fav=Color3.fromRGB(240,240,240),
	text=Color3.fromRGB(250,250,250),
	textDim=Color3.fromRGB(165,165,170),
	textMuted=Color3.fromRGB(110,110,115),
	subtitle=Color3.fromRGB(140,140,145),
	overlay=Color3.fromRGB(2,2,3),
	onAccent=Color3.fromRGB(12,12,12),
},
Light = {
	bg=Color3.fromRGB(240,240,238),
	panel=Color3.fromRGB(232,232,230),
	surface=Color3.fromRGB(220,220,218),
	surfaceHi=Color3.fromRGB(200,200,198),
	stroke=Color3.fromRGB(180,180,178),
	strokeStrong=Color3.fromRGB(130,130,128),
	accent=Color3.fromRGB(20,20,20),
	accentDim=Color3.fromRGB(110,110,108),
	silver=Color3.fromRGB(70,70,75),
	silverDim=Color3.fromRGB(140,140,145),
	green=Color3.fromRGB(80,80,80),
	fav=Color3.fromRGB(60,60,60),
	text=Color3.fromRGB(12,12,12),
	textDim=Color3.fromRGB(80,80,80),
	textMuted=Color3.fromRGB(130,130,130),
	subtitle=Color3.fromRGB(100,100,100),
	overlay=Color3.fromRGB(220,220,218),
	onAccent=Color3.fromRGB(240,240,238),
}
}

local Theme = "Dark"
local function loadThemeFromFile()
	local ok, content = pcall(function()
		if isfile and not isfile(THEME_FILE) then return nil end
		return readfile(THEME_FILE)
	end)
	if ok and content then
		local suc, dec = pcall(function() return hs:JSONDecode(content) end)
		if suc and dec and type(dec) == "table" then
			local t = dec.theme
			if t == "Dark" or t == "Light" then return t end
		end
	end
	return "Dark"
end
local function saveThemeToFile(t)
	debouncedWrite(THEME_FILE, hs:JSONEncode({theme = t}))
end
Theme = loadThemeFromFile()

local C = {}
local function syncC() for k, v in pairs(Themes[Theme]) do C[k] = v end end
syncC()

local assetCache, fileCache, equippedAnims = {}, {}, {}
local savedBookmarks = {}

local function loadJSON(file)
	local ok, content = pcall(function()
		if isfile and not isfile(file) then return nil end
		return readfile(file)
	end)
	if ok and content then
		local suc, dec = pcall(function() return hs:JSONDecode(content) end)
		return suc and dec or {}
	end
	return {}
end
local function saveJSON(file, data)
	pcall(function() writefile(file, hs:JSONEncode(data)) end)
end

fileCache = loadJSON(CACHE_FILE_NAME)
equippedAnims = loadJSON(EQUIPPED_FILE)
savedBookmarks = loadJSON(SAVED_BUNDLES_FILE)

task.spawn(function()
	local ok, oc = pcall(function() return game:HttpGet(ANIM_CACHE_URL) end)
	if ok and oc then
		pcall(function()
			local od = hs:JSONDecode(oc)
			for k, v in pairs(od) do if not fileCache[k] then fileCache[k] = v end end
			saveJSON(CACHE_FILE_NAME, fileCache)
		end)
	end
end)

local function applySavedAnimations(char)
	if not char then return end
	local animate = char:WaitForChild("Animate", 5)
	local human = char:WaitForChild("Humanoid", 5)
	if not animate or not human then return end
	for _, tr in ipairs(human:GetPlayingAnimationTracks()) do
		pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end)
	end
	animate.Disabled = true
	for slotType, animList in pairs(equippedAnims) do
		local fId = m[string.lower(slotType)]
		if fId then
			local folder = animate:FindFirstChild(fId)
			if folder then
				for _, o in ipairs(folder:GetChildren()) do
					if o:IsA("Animation") then o:Destroy() end
				end
				for _, ad in ipairs(animList) do
					local na = Instance.new("Animation", folder)
					na.Name = ad.Name; na.AnimationId = ad.AnimationId
				end
			end
		end
	end
	task.wait(0.05); animate.Disabled = false
end

local function initAutoEquip(char)
	if not char then return end
	task.spawn(function()
		local animate = char:WaitForChild("Animate", 5)
		local human = char:WaitForChild("Humanoid", 5)
		if animate and human then
			local idleF = animate:WaitForChild("idle", 5)
			if idleF then idleF:WaitForChild("Animation1", 3) end
			task.wait(0.1); applySavedAnimations(char)
		end
	end)
end

if lp.Character then initAutoEquip(lp.Character) end
track(lp.CharacterAdded:Connect(initAutoEquip))

local function get(id, bundleId, assetType)
	local stringId = tostring(id)
	if assetCache[stringId] then return assetCache[stringId] end
	if fileCache[stringId] then
		local rec = {}
		for _, data in ipairs(fileCache[stringId]) do
			local anim = Instance.new("Animation")
			anim.Name, anim.AnimationId = data.Name, data.AnimationId
			table.insert(rec, anim)
		end
		assetCache[stringId] = rec; return rec
	end
	local t, ser = {}, {}
	local descProp = "IdleAnimation"
	local lower = assetType and string.lower(assetType) or ""
	if lower:find("idle") and not lower:find("swim") then descProp = "IdleAnimation"
	elseif lower:find("walk") then descProp = "WalkAnimation"
	elseif lower:find("run") then descProp = "RunAnimation"
	elseif lower:find("jump") then descProp = "JumpAnimation"
	elseif lower:find("fall") then descProp = "FallAnimation"
	elseif lower:find("climb") then descProp = "ClimbAnimation"
	elseif lower:find("swim") then descProp = "SwimAnimation" end
	pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc[descProp] = tonumber(id)
		local dummy = plrs:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		local animate = dummy:FindFirstChild("Animate")
		if animate then
			local tFolders = (descProp == "SwimAnimation") and {"swim","swimidle"} or {string.lower(string.gsub(descProp, "Animation", ""))}
			for _, fName in ipairs(tFolders) do
				local folder = animate:FindFirstChild(fName)
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						if child:IsA("Animation") and child.AnimationId ~= "" then
							local cl = child:Clone()
							table.insert(t, cl)
							table.insert(ser, {Name = cl.Name, AnimationId = cl.AnimationId, BundleId = tostring(bundleId)})
						end
					end
				end
			end
		end
		dummy:Destroy()
	end)
	if #t == 0 then
		pcall(function()
			local objs = game:GetObjects("rbxassetid://" .. stringId)
			if objs and #objs > 0 then
				local function proc(item)
					if item:IsA("Animation") then
						table.insert(t, item:Clone())
						table.insert(ser, {Name = item.Name, AnimationId = item.AnimationId, BundleId = tostring(bundleId)})
					end
				end
				proc(objs[1])
				for _, c in ipairs(objs[1]:GetDescendants()) do proc(c) end
			end
		end)
	end
	assetCache[stringId] = t; fileCache[stringId] = ser
	saveJSON(CACHE_FILE_NAME, fileCache); return t
end

local function clearAssetCache(id)
	local sid = tostring(id)
	assetCache[sid], fileCache[sid] = nil, nil
	saveJSON(CACHE_FILE_NAME, fileCache)
end

local vp = workspace.CurrentCamera.ViewportSize
local scale = math.clamp(math.min(vp.X/1920, vp.Y/1080), 0.55, 3.0) * 1.45
local function s(n) return math.round(n * scale) end

local R_MAIN=s(12) R_PANEL=s(8) R_CARD=s(8) R_BUTTON=s(6) R_INPUT=s(6) R_SMALL=s(4)
local PAD_TOP=s(44) PAD_SIDES=s(14) W,H = s(540),s(415)

local IS_COMPACT = (vp.X < 1100) or (vp.Y < 620)
if IS_COMPACT then
	PAD_TOP = math.max(s(40), 38); PAD_SIDES = s(10)
	W = math.min(W, vp.X - s(24)); H = math.min(H, vp.Y - s(70))
end

local INNER_W = W - (PAD_SIDES*2)
local LEFT_W = IS_COMPACT and math.floor(INNER_W*0.52) or s(268)
local RIGHT_W = INNER_W - LEFT_W - s(1)

local HB = math.max(s(32), 34)
local HDR_BTN = s(28) HDR_GAP = s(4)
local scrollW = s(4) VP_H = s(175) MIN_BTN_SIZE = s(60)
local UI_BUSY = false TOGGLE_COOLDOWN = 0.15

print("[V2.7.6-OBSIDIAN-R2.6.4] Layout: W="..W.." H="..H.." LEFT="..LEFT_W.." RIGHT="..RIGHT_W)

local function tween(obj, props, dur, style, dir)
	local t = ts:Create(obj, TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play(); return t
end
local function createCorner(parent, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or R_SMALL); c.Parent = parent; return c
end
local function createStroke(parent, color, th, tr, key)
	local st = Instance.new("UIStroke")
	st.Color = color or C.stroke; st.Thickness = th or 1; st.Transparency = tr or 0
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if key then
		st:SetAttribute("_tk_Color", key)
		if C[key] then pcall(function() st.Color = C[key] end) end
	end
	st.Parent = parent; return st
end
local function tagTheme(inst, prop, key)
	if not inst or not prop or not key then return inst end
	inst:SetAttribute("_tk_"..prop, key)
	if C[key] then pcall(function() inst[prop] = C[key] end) end
	return inst
end

local setIconColor, setIconName, makeIcon
do
local ICON_URL = "https://cdn.jsdelivr.net/gh/1n66arHub/in666arAnimationFe@main/icons.png"
local ICON_FILE = "FeUgcAnim_icons_v2.png"
local ICON_MIN = 1000
local ICON_CELL = 64
local ICON_SHEET_ROWS = 5
local ICON_MAP = {
	close={0,0},minimize={1,0},sun={2,0},moon={3,0},
	search={0,1},bookmark={1,1},star={2,1},play={3,1},
	back={0,2},next={1,2},reset={2,2},shuffle={3,2},
	copy={0,3},gear={1,3},check={2,3},filter={3,3},
	star_fill={0,4},bookmark_fill={1,4},
}
local ICON_TEXT = {
	close=uchr(226,156,149),minimize=uchr(226,148,128),sun=uchr(226,152,128),moon=uchr(226,152,190),
	search=uchr(226,152,188),bookmark=uchr(226,152,144),star=uchr(226,152,134),play=uchr(226,150,182),
	back=uchr(226,151,128),next=uchr(226,150,182),reset=uchr(226,134,187),shuffle=uchr(226,135,132),
	copy=uchr(226,140,152),gear=uchr(226,154,153),check=uchr(226,156,147),filter=uchr(226,137,161),
	star_fill=uchr(226,152,133),bookmark_fill=uchr(226,152,145),
}
local ICON_FB = {close="X",minimize="-",sun="L",moon="D",search="GO",bookmark="SAVE",star="*",play="PLAY",back="<",next=">",reset="RST",shuffle="SHF",copy="CPY",gear="CFG",check="OK",filter="FLT",star_fill="*",bookmark_fill="SAVE"}

local iconSheet = nil
do
	local getAsset = getcustomasset or getsynasset
	if getAsset and writefile and isfile and readfile then
		pcall(function()
			local need = true
			if isfile(ICON_FILE) then
				local ok, sz = pcall(function() return #readfile(ICON_FILE) end)
				if ok and sz and sz >= ICON_MIN then need = false
				else pcall(delfile, ICON_FILE) end
			end
			if need then
				local data = game:HttpGet(ICON_URL)
				local isPNG = type(data) == "string" and #data >= ICON_MIN and data:sub(1,8) == "\137PNG\r\n\26\n"
				if isPNG then writefile(ICON_FILE, data) end
			end
			if isfile(ICON_FILE) then iconSheet = getAsset(ICON_FILE) end
		end)
	end
end

local function getIco(btn) return btn and btn:FindFirstChild("Ico", true) end
function setIconColor(btn, color)
	local ic = getIco(btn); if not ic then return end
	if ic:IsA("ImageLabel") then ic.ImageColor3 = color else ic.TextColor3 = color end
end
function setIconName(btn, name)
	local ic = getIco(btn); if not ic then return end
	if ic:IsA("ImageLabel") then
		local pos = ICON_MAP[name]
		if pos and pos[2] < ICON_SHEET_ROWS then
			ic.ImageRectOffset = Vector2.new(pos[1]*ICON_CELL, pos[2]*ICON_CELL)
		else
			ic.Image = ""; ic.ImageTransparency = 1
			local fallback = ic.Parent and ic.Parent:FindFirstChild("IcoFB")
			if not fallback and ic.Parent then
				fallback = Instance.new("TextLabel", ic.Parent)
				fallback.Name = "IcoFB"; fallback.BackgroundTransparency = 1
				fallback.Size = UDim2.new(1,0,1,0); fallback.Font = Enum.Font.GothamBold
				fallback.TextSize = math.max(ic.AbsoluteSize.X, 12)
				fallback.TextColor3 = ic.ImageColor3; fallback.Text = ICON_FB[name] or "?"
				fallback.ZIndex = ic.ZIndex + 1
			end
		end
	else
		ic.Text = ICON_TEXT[name] or ICON_FB[name] or "?"
	end
end
function makeIcon(parent, name, size, colorKey)
	if colorKey == nil then colorKey = "textDim" end
	local holder = Instance.new("Frame", parent)
	holder.Name = "IcoHolder"; holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(0, size, 0, size)
	holder.AnchorPoint = Vector2.new(0.5, 0.5); holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	local ico
	if iconSheet then
		ico = Instance.new("ImageLabel", holder)
		ico.Image = iconSheet; ico.ImageRectSize = Vector2.new(ICON_CELL, ICON_CELL)
		ico.ImageColor3 = C[colorKey or "textDim"] or C.textDim
	else
		ico = Instance.new("TextLabel", holder); ico.Font = Enum.Font.GothamBold
		ico.TextSize = math.max(size, 12); ico.TextColor3 = C[colorKey or "textDim"] or C.textDim
	end
	ico.Name = "Ico"; ico.BackgroundTransparency = 1; ico.Size = UDim2.new(1, 0, 1, 0)
	if colorKey then tagTheme(ico, iconSheet and "ImageColor3" or "TextColor3", colorKey) end
	setIconName(parent, name); return holder
end
end

local function applyCoolGradient(parent)
	local ex = parent:FindFirstChild("CoolGrad")
	if ex then ex:Destroy() end
	local grad = Instance.new("UIGradient", parent)
	grad.Name = "CoolGrad"
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.surface),
		ColorSequenceKeypoint.new(0.5, C.panel),
		ColorSequenceKeypoint.new(1, C.bg)
	})
	grad.Rotation = 60; return grad
end

local function applyShimmer(obj, c1, c2)
	local ex = obj:FindFirstChild("ShimmerGrad")
	if ex then ex:Destroy() end
	local grad = Instance.new("UIGradient", obj)
	grad.Name = "ShimmerGrad"
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.5, c2),
		ColorSequenceKeypoint.new(1, c1)
	})
	grad.Rotation = 35; grad.Offset = Vector2.new(-1, 0)
	local tw = ts:Create(grad, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Offset = Vector2.new(1, 0)})
	tw:Play()
end
local function removeShimmer(obj)
	local gg = obj:FindFirstChild("ShimmerGrad"); if gg then gg:Destroy() end
end

local function createLabel(parent, p)
	local l = Instance.new("TextLabel", parent)
	l.BackgroundTransparency = 1; l.Font = p.font or FONT.label
	l.Text = p.text or ""; l.TextSize = p.size or s(11)
	l.TextColor3 = p.color or C.text
	l.TextXAlignment = p.align or Enum.TextXAlignment.Center
	l.Size = p.uiSize or UDim2.new(1,0,1,0)
	l.Position = p.pos or UDim2.new(0,0,0,0)
	l.ClipsDescendants = true
	if p.textKey then tagTheme(l, "TextColor3", p.textKey) end
	return l
end

local function createButton(parent, p)
	local b = Instance.new("TextButton", parent)
	b.Size = p.uiSize or UDim2.new(0, s(80), 0, s(26))
	b.Position = p.pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3 = p.bg or C.surfaceHi
	b.BackgroundTransparency = p.bgTransparency or 0
	b.Text = p.text or ""; b.TextColor3 = p.color or C.text
	b.Font = p.font or FONT.button; b.TextSize = p.size or s(11)
	b.ClipsDescendants = true; b.AutoButtonColor = false
	createCorner(b, p.radius or R_BUTTON)
	if p.strokeColor or p.strokeKey then
		createStroke(b, p.strokeColor or C.stroke, 1, nil, p.strokeKey)
	end
	if p.bgKey then tagTheme(b, "BackgroundColor3", p.bgKey) end
	if p.textKey then tagTheme(b, "TextColor3", p.textKey) end
	local function getBase()
		local ak = b:GetAttribute("_tk_BackgroundColor3")
		if ak and C[ak] then return C[ak] end
		if p.bgKey and C[p.bgKey] then return C[p.bgKey] end
		return p.bg or C.surfaceHi
	end
	b.MouseEnter:Connect(function()
		if b:GetAttribute("_noHover") then return end
		local target = p.hoverBg or getBase():Lerp(Color3.new(1,1,1), 0.08)
		tween(b, {BackgroundColor3 = target}, 0.12)
	end)
	b.MouseLeave:Connect(function()
		if b:GetAttribute("_noHover") then return end
		tween(b, {BackgroundColor3 = getBase()}, 0.12)
	end)
	b.MouseButton1Down:Connect(function()
		tween(b, {Size = (p.uiSize or b.Size) - UDim2.new(0,0,0,1)}, 0.06)
		SoundFx.click()
	end)
	b.MouseButton1Up:Connect(function() tween(b, {Size = p.uiSize or b.Size}, 0.08) end)
	return b
end

local gp = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
if gp:FindFirstChild("StudioAnimStudio") then gp.StudioAnimStudio:Destroy() end
do
	local pg = lp:FindFirstChild("PlayerGui")
	local old = pg and pg:FindFirstChild("StudioAnimStudio")
	if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "StudioAnimStudio"; gui.ResetOnSpawn = false
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

gui.Destroying:Connect(function() pcall(flushPendingWrites) end)

local mf = Instance.new("CanvasGroup", gui)
mf.Size, mf.Position, mf.AnchorPoint = UDim2.new(0,0,0,0), UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5)
mf.BackgroundColor3, mf.BackgroundTransparency = C.bg, 0
mf.GroupTransparency = 1
mf.Active, mf.Draggable = true, true
tagTheme(mf, "BackgroundColor3", "bg")
createCorner(mf, R_MAIN)
applyCoolGradient(mf)
local mfEdge = Instance.new("UIStroke", mf)
mfEdge.Color = C.bg
mfEdge.Thickness = 1
mfEdge.Transparency = 1
mfEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

do
local mfPad = Instance.new("UIPadding", mf)
mfPad.PaddingTop = UDim.new(0, PAD_TOP); mfPad.PaddingBottom = UDim.new(0, PAD_SIDES)
mfPad.PaddingLeft = UDim.new(0, PAD_SIDES); mfPad.PaddingRight = UDim.new(0, PAD_SIDES)
end
do
	local ring = Instance.new("Frame", mf)
	ring.Name = "InnerRing"
	ring.Position = UDim2.new(0, -PAD_SIDES + s(4), 0, -PAD_TOP + s(4))
	ring.Size = UDim2.new(1, PAD_SIDES * 2 - s(8), 1, PAD_TOP + PAD_SIDES - s(8))
	ring.BackgroundTransparency = 1; ring.BorderSizePixel = 0
	ring.ZIndex = 0; ring.Active = false
	createCorner(ring, math.max(R_MAIN - s(3), 2))
	createStroke(ring, C.stroke, 1, 0.85, "stroke")
end

task.delay(0.1, function()
	tween(mf, {Size = UDim2.new(0, W, 0, H), GroupTransparency = 0}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

local showToast
do
local notifHolder = Instance.new("Frame", gui)
notifHolder.Name = "NotifHolder"; notifHolder.BackgroundTransparency = 1
notifHolder.AnchorPoint = Vector2.new(1,0)
notifHolder.Position = UDim2.new(1, -s(14), 0, s(20))
notifHolder.Size = UDim2.new(0, s(230), 1, -s(40)); notifHolder.ZIndex = 60

local nLay = Instance.new("UIListLayout", notifHolder)
nLay.Padding = UDim.new(0, s(6)); nLay.SortOrder = Enum.SortOrder.LayoutOrder
nLay.HorizontalAlignment = Enum.HorizontalAlignment.Right

local NOTIF_MAX = 5
local notifCount = 0

local function pushNotif(msg, kind)
	kind = kind or "info"
	notifCount = notifCount + 1
	local kids = {}
	for _, c in ipairs(notifHolder:GetChildren()) do
		if c:IsA("Frame") then table.insert(kids, c) end
	end
	if #kids >= NOTIF_MAX then
		table.sort(kids, function(a,b) return a.LayoutOrder < b.LayoutOrder end)
		local oldest = kids[1]
		if oldest then
			tween(oldest, {BackgroundTransparency = 1}, 0.2)
			task.delay(0.2, function() if oldest and oldest.Parent then oldest:Destroy() end end)
		end
	end
	local accent = C.accent
	if kind == "success" then accent = C.green
	elseif kind == "warn" then accent = C.fav
	elseif kind == "error" then accent = C.accentDim end
	local card = Instance.new("Frame", notifHolder)
	card.Name = "Notif_"..notifCount; card.LayoutOrder = notifCount
	card.Size = UDim2.new(1,0,0,s(38)); card.BackgroundColor3 = C.surface
	card.BackgroundTransparency = 0; card.BorderSizePixel = 0
	card.AnchorPoint = Vector2.new(1,0); card.Position = UDim2.new(1, s(240), 0, 0)
	card.ClipsDescendants = true
	tagTheme(card, "BackgroundColor3", "surface")
	createCorner(card, R_BUTTON)
	local st = createStroke(card, C.strokeStrong, 1, 0.2, "strokeStrong")
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local bar = Instance.new("Frame", card)
	bar.Size = UDim2.new(0, s(3), 0.65, 0); bar.Position = UDim2.new(0, 0, 0.175, 0)
	bar.BackgroundColor3 = accent; bar.BorderSizePixel = 0
	createCorner(bar, s(2))
	local dot = Instance.new("Frame", card)
	dot.Size = UDim2.new(0, s(6), 0, s(6)); dot.Position = UDim2.new(0, s(10), 0.5, -s(3))
	dot.BackgroundColor3 = accent; dot.BorderSizePixel = 0
	createCorner(dot, s(3))
	local lbl = Instance.new("TextLabel", card)
	lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1, -s(26), 1, 0)
	lbl.Position = UDim2.new(0, s(22), 0, 0)
	lbl.Font = FONT.label; lbl.TextSize = s(10); lbl.Text = tostring(msg)
	lbl.TextColor3 = C.text; lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	tagTheme(lbl, "TextColor3", "text")
	local pb = Instance.new("Frame", card)
	pb.Size = UDim2.new(1, -s(16), 0, s(2)); pb.Position = UDim2.new(0, s(8), 1, -s(4))
	pb.BackgroundColor3 = C.surfaceHi; pb.BorderSizePixel = 0
	pb.BackgroundTransparency = 0.3; createCorner(pb, s(1))
	local pf = Instance.new("Frame", pb)
	pf.Size = UDim2.new(1,0,1,0); pf.BackgroundColor3 = accent
	pf.BorderSizePixel = 0; createCorner(pf, s(1))
	tween(card, {Position = UDim2.new(1,0,0,0)}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(pf, {Size = UDim2.new(0,0,1,0)}, 1.9, Enum.EasingStyle.Linear)
	task.delay(2, function()
		if card and card.Parent then
			tween(card, {Position = UDim2.new(1, s(240), 0, 0), BackgroundTransparency = 1}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.25, function() if card then card:Destroy() end end)
		end
	end)
end

local VALID_TOAST_KINDS = { info = true, success = true, warn = true, error = true }

function showToast(msg, kindOverride)
	local kind
	if kindOverride and VALID_TOAST_KINDS[kindOverride] then
		kind = kindOverride
	else
		local l = string.lower(tostring(msg))
		if l:find("fail") or l:find("error") then kind = "error"
		elseif l:find("equip") or l:find("reset") or l:find("saved") or l:find("playing") then kind = "success"
		else kind = "info" end
	end
	pushNotif(msg, kind)
end
end

local minBtn = Instance.new("CanvasGroup", gui)
minBtn.Size, minBtn.Position, minBtn.AnchorPoint = UDim2.new(0,0,0,0), UDim2.new(1, -s(40), 0, s(30)), Vector2.new(0.5,0.5)
minBtn.BackgroundTransparency = 1; minBtn.GroupTransparency = 1
minBtn.Visible = false
minBtn.Active, minBtn.Draggable, minBtn.ClipsDescendants = true, false, true

do
local minBtnBg = Instance.new("Frame", minBtn)
minBtnBg.Size, minBtnBg.BackgroundColor3, minBtnBg.BorderSizePixel = UDim2.new(1,0,1,0), C.panel, 0
tagTheme(minBtnBg, "BackgroundColor3", "panel")
Instance.new("UICorner", minBtnBg).CornerRadius = UDim.new(0.5, 0)
createStroke(minBtnBg, C.strokeStrong, 1, 0, "strokeStrong")
applyCoolGradient(minBtnBg)
end
createLabel(minBtn, {text = "UGC", font = FONT.title, size = s(13), textKey = "text"})
local minBtnHit = Instance.new("TextButton", minBtn)
minBtnHit.Size, minBtnHit.BackgroundTransparency, minBtnHit.Text, minBtnHit.ClipsDescendants = UDim2.new(1,0,1,0), 1, "", true

do
	local drag = {active = false, moved = false, dragStart = nil, startPos = nil}
	local DT = 4
	local function beginDrag(input)
		drag.active = true; drag.moved = false
		drag.dragStart = input.Position; drag.startPos = minBtn.Position
	end
	local function updateDrag(input)
		if not drag.active or not drag.dragStart or not drag.startPos then return end
		local delta = input.Position - drag.dragStart
		if math.abs(delta.X) > DT or math.abs(delta.Y) > DT then drag.moved = true end
		local cam = workspace.CurrentCamera
		local vs = (cam and cam.ViewportSize) or Vector2.new(1920,1080)
		local ax = drag.startPos.X.Scale * vs.X + drag.startPos.X.Offset + delta.X
		local ay = drag.startPos.Y.Scale * vs.Y + drag.startPos.Y.Offset + delta.Y
		local hw = minBtn.AbsoluteSize.X * 0.5; local hh = minBtn.AbsoluteSize.Y * 0.5
		if hw < 1 then hw = MIN_BTN_SIZE * 0.5 end
		if hh < 1 then hh = MIN_BTN_SIZE * 0.5 end
		ax = math.clamp(ax, hw, vs.X - hw); ay = math.clamp(ay, hh, vs.Y - hh)
		minBtn.Position = UDim2.new(0, ax, 0, ay)
	end
	local function endDrag()
		drag.active = false
		task.delay(0.15, function() drag.moved = false end)
	end
	minBtnHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then beginDrag(input) end
	end)
	track(uis.InputChanged:Connect(function(input)
		if not drag.active then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then updateDrag(input) end
	end))
	track(uis.InputEnded:Connect(function(input)
		if not drag.active then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then endDrag() end
	end))
	minBtnHit.MouseButton1Click:Connect(function()
		if drag.moved then return end
		if UI_BUSY then return end
		UI_BUSY = true; SoundFx.toggle()
		minBtn.Visible = false; minBtn.GroupTransparency = 1
		minBtn.Size = UDim2.new(0,0,0,0)
		mf.Size = UDim2.new(0, W, 0, H); mf.GroupTransparency = 0
		mf.Visible = true; resumeAllShimmers()
		task.wait(TOGGLE_COOLDOWN); UI_BUSY = false
	end)
end

local headerBar = Instance.new("Frame", mf)
headerBar.Size = UDim2.new(1,0,0,PAD_TOP - s(6))
headerBar.Position = UDim2.new(0,0,0,-PAD_TOP); headerBar.BackgroundTransparency = 1

createLabel(headerBar, {
	text = "FE UGC ANIMATIONS", font = FONT.title, size = s(15),
	align = Enum.TextXAlignment.Left,
	uiSize = UDim2.new(1, -s(220), 0, s(18)),
	pos = UDim2.new(0, s(2), 0, s(3)), textKey = "text"
})

do
local subLbl = createLabel(headerBar, {
	text = "by @in66ar  ·  v2.7.6-r2.6.4", font = FONT.subtitle, size = s(10),
	align = Enum.TextXAlignment.Left,
	uiSize = UDim2.new(1, -s(220), 0, s(14)),
	pos = UDim2.new(0, s(2), 0, s(22)), textKey = "subtitle"
})
do
	local ok, ff = pcall(function()
		return Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Light, Enum.FontStyle.Italic)
	end)
	if ok and ff then pcall(function() subLbl.FontFace = ff end) end
end
end

local tabDiscoverBtn, tabSavedBtn, tabEmoteBtn
do
local titleW = s(150)
local btnAreaW = 5 * HDR_BTN + 4 * HDR_GAP + s(8)
local tabsW = math.clamp(W - titleW - btnAreaW - s(30), s(150), s(300))

local tabsPill = Instance.new("Frame", headerBar)
tabsPill.Size = UDim2.new(0, tabsW, 0, HB)
tabsPill.AnchorPoint = Vector2.new(0, 0.5)
tabsPill.Position = UDim2.new(0, titleW, 0.5, 0); tabsPill.BorderSizePixel = 0
tagTheme(tabsPill, "BackgroundColor3", "panel")
createCorner(tabsPill, HB)
createStroke(tabsPill, C.strokeStrong, 1, 0.2, "strokeStrong")
local tPad = Instance.new("UIPadding", tabsPill)
tPad.PaddingLeft = UDim.new(0, 3); tPad.PaddingRight = UDim.new(0, 3)
tPad.PaddingTop = UDim.new(0, 3); tPad.PaddingBottom = UDim.new(0, 3)

tabDiscoverBtn = createButton(tabsPill, {
	uiSize = UDim2.new(1/3, -2, 1, 0), pos = UDim2.new(0,0,0,0),
	text = "Discover", font = FONT.tab, size = s(10),
	bg = C.accent, textKey = "onAccent", radius = HB
})
tabSavedBtn = createButton(tabsPill, {
	uiSize = UDim2.new(1/3, -2, 1, 0), pos = UDim2.new(1/3, 0, 0, 0),
	text = "Saved", font = FONT.tab, size = s(10),
	bg = C.bg, textKey = "text", radius = HB
})
tabEmoteBtn = createButton(tabsPill, {
	uiSize = UDim2.new(1/3, -2, 1, 0), pos = UDim2.new(2/3, 0, 0, 0),
	text = "Emotes", font = FONT.tab, size = s(10),
	bg = C.bg, textKey = "text", radius = HB
})
end

local soundBtn = createButton(headerBar, {
	uiSize = UDim2.new(0, HDR_BTN, 0, HDR_BTN),
	pos = UDim2.new(1, -(HDR_BTN*5 + HDR_GAP*4), 0, 0),
	bgKey = "surface", bgTransparency = 0, text = "", radius = R_BUTTON,
	strokeColor = C.strokeStrong, strokeKey = "strokeStrong"
})
soundBtn.Text = "♪"; soundBtn.TextSize = s(13); soundBtn.TextColor3 = C.text
tagTheme(soundBtn, "TextColor3", "text")
if not SoundFx.isEnabled() then soundBtn.Text = "×"; soundBtn.TextColor3 = C.textMuted end

local resetBtn = createButton(headerBar, {
	uiSize = UDim2.new(0, HDR_BTN, 0, HDR_BTN),
	pos = UDim2.new(1, -(HDR_BTN*4 + HDR_GAP*3), 0, 0),
	bgKey = "surface", bgTransparency = 0, text = "", radius = R_BUTTON,
	strokeColor = C.strokeStrong, strokeKey = "strokeStrong"
})
makeIcon(resetBtn, "reset", s(14))

local themeBtn = createButton(headerBar, {
	uiSize = UDim2.new(0, HDR_BTN, 0, HDR_BTN),
	pos = UDim2.new(1, -(HDR_BTN*3 + HDR_GAP*2), 0, 0),
	bgKey = "surface", bgTransparency = 0, text = "", radius = R_BUTTON,
	strokeColor = C.strokeStrong, strokeKey = "strokeStrong"
})
makeIcon(themeBtn, (Theme == "Dark") and "sun" or "moon", s(14))

local minWindowBtn = createButton(headerBar, {
	uiSize = UDim2.new(0, HDR_BTN, 0, HDR_BTN),
	pos = UDim2.new(1, -(HDR_BTN*2 + HDR_GAP*1), 0, 0),
	bgKey = "surface", bgTransparency = 0, text = "", radius = R_BUTTON,
	strokeColor = C.strokeStrong, strokeKey = "strokeStrong"
})
makeIcon(minWindowBtn, "minimize", s(14))

local closeWindowBtn = createButton(headerBar, {
	uiSize = UDim2.new(0, HDR_BTN, 0, HDR_BTN),
	pos = UDim2.new(1, -HDR_BTN, 0, 0),
	bgKey = "surface", bgTransparency = 0, text = "", radius = R_BUTTON,
	strokeColor = C.strokeStrong, strokeKey = "strokeStrong",
	hoverBg = Color3.fromRGB(75,75,80)
})
makeIcon(closeWindowBtn, "close", s(14))

closeWindowBtn.MouseButton1Click:Connect(function()
	if UI_BUSY then return end
	UI_BUSY = true; SoundFx.toggle(); flushPendingWrites()
	tween(mf, {GroupTransparency = 1, Size = UDim2.new(0,0,0,0)}, 0.2)
	tween(minBtn, {GroupTransparency = 1}, 0.2)
	task.delay(0.22, function() gui:Destroy(); UI_BUSY = false end)
end)

minWindowBtn.MouseButton1Click:Connect(function()
	if UI_BUSY then return end
	UI_BUSY = true; SoundFx.toggle()
	mf.Visible = false; mf.GroupTransparency = 1
	mf.Size = UDim2.new(0,0,0,0)
	minBtn.Size = UDim2.new(0, MIN_BTN_SIZE, 0, MIN_BTN_SIZE)
	minBtn.GroupTransparency = 0; minBtn.Visible = true
	pauseAllShimmers()
	task.wait(TOGGLE_COOLDOWN); UI_BUSY = false
end)

soundBtn.MouseButton1Click:Connect(function()
	local on = not SoundFx.isEnabled()
	SoundFx.setEnabled(on)
	soundBtn.Text = on and "♪" or "×"
	soundBtn.TextColor3 = on and C.text or C.textMuted
	if on then SoundFx.click() end
	showToast(on and "Sound: ON" or "Sound: OFF", "info")
end)

local lp_frame = Instance.new("Frame", mf)
lp_frame.Size, lp_frame.Position, lp_frame.BackgroundTransparency = UDim2.new(0, LEFT_W, 1, 0), UDim2.new(0,0,0,0), 1

do
local lpBackdrop = Instance.new("Frame", lp_frame)
lpBackdrop.Name = "PanelBackdrop"
lpBackdrop.Size = UDim2.new(1, 0, 1, 0); lpBackdrop.Position = UDim2.new(0, 0, 0, 0)
lpBackdrop.BackgroundColor3 = C.surface; lpBackdrop.BackgroundTransparency = 0
lpBackdrop.BorderSizePixel = 0; lpBackdrop.ZIndex = 0; lpBackdrop.Active = false
tagTheme(lpBackdrop, "BackgroundColor3", "surface")
createCorner(lpBackdrop, R_PANEL)
createStroke(lpBackdrop, C.strokeStrong, 1, 0, "strokeStrong")
end

local searchRow = Instance.new("Frame", lp_frame)
searchRow.Size, searchRow.Position, searchRow.BackgroundTransparency = UDim2.new(1, -s(12), 0, s(30)), UDim2.new(0, s(6), 0, s(8)), 1
searchRow.ZIndex = 2

local sb = Instance.new("TextBox", searchRow)
sb.Size, sb.PlaceholderText, sb.Text = UDim2.new(1, -s(62), 1, 0), "Search animations...", ""
sb.BackgroundColor3, sb.BackgroundTransparency, sb.TextColor3, sb.ClipsDescendants = C.bg, 0.15, C.text, true
sb.PlaceholderColor3 = C.textDim
sb.Font, sb.TextSize = FONT.label, s(11)
sb.TextXAlignment = Enum.TextXAlignment.Left; sb.ClearTextOnFocus = false
createCorner(sb, R_INPUT)
tagTheme(sb, "BackgroundColor3", "bg")
tagTheme(sb, "TextColor3", "text")
tagTheme(sb, "PlaceholderColor3", "textDim")
do
local sbStroke = createStroke(sb, C.strokeStrong, 1, 0.2, "strokeStrong")
local sbPad = Instance.new("UIPadding", sb)
sbPad.PaddingLeft = UDim.new(0, s(10)); sbPad.PaddingRight = UDim.new(0, s(24))

local clearSearchBtn = Instance.new("TextButton", sb)
clearSearchBtn.Size = UDim2.new(0, s(16), 0, s(16))
clearSearchBtn.AnchorPoint = Vector2.new(1, 0.5)
clearSearchBtn.Position = UDim2.new(1, -s(6), 0.5, 0)
clearSearchBtn.BackgroundColor3 = C.surfaceHi; clearSearchBtn.BackgroundTransparency = 0
clearSearchBtn.Text = ""; clearSearchBtn.AutoButtonColor = false
clearSearchBtn.Visible = false; clearSearchBtn.ZIndex = 3
createCorner(clearSearchBtn, R_SMALL)
tagTheme(clearSearchBtn, "BackgroundColor3", "surfaceHi")
makeIcon(clearSearchBtn, "close", s(11))
clearSearchBtn.MouseButton1Click:Connect(function()
	SoundFx.click(); sb.Text = ""; clearSearchBtn.Visible = false
end)
sb:GetPropertyChangedSignal("Text"):Connect(function()
	clearSearchBtn.Visible = (#sb.Text > 0)
end)
sb.Focused:Connect(function() tween(sbStroke, {Color = C.accent, Transparency = 0}, 0.15) end)
sb.FocusLost:Connect(function() tween(sbStroke, {Color = C.strokeStrong, Transparency = 0.2}, 0.15) end)
end

local searchBtn = createButton(searchRow, {
	uiSize = UDim2.new(0, s(56), 1, 0), pos = UDim2.new(1, -s(56), 0, 0),
	text = "", bgKey = "accent", textKey = "onAccent",
	font = FONT.button, size = s(11), radius = R_INPUT
})
makeIcon(searchBtn, "search", s(14), "onAccent")

local gridScroller = Instance.new("ScrollingFrame", lp_frame)
gridScroller.Size = UDim2.new(1, -s(12), 1, -s(72))
gridScroller.Position = UDim2.new(0, s(6), 0, s(44))
gridScroller.BackgroundColor3, gridScroller.BackgroundTransparency, gridScroller.BorderSizePixel = C.bg, 0.25, 0
gridScroller.ScrollBarThickness = scrollW
gridScroller.ScrollBarImageColor3 = C.accentDim
gridScroller.ScrollBarImageTransparency = 0.3
gridScroller.CanvasSize = UDim2.new(0,0,0,0)
gridScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
gridScroller.ZIndex = 1
tagTheme(gridScroller, "BackgroundColor3", "bg")
tagTheme(gridScroller, "ScrollBarImageColor3", "accentDim")
createCorner(gridScroller, R_PANEL)
createStroke(gridScroller, C.stroke, 1, 0.3, "stroke")

local loadingOverlay = Instance.new("TextLabel", lp_frame)
loadingOverlay.Size, loadingOverlay.Position = gridScroller.Size, gridScroller.Position
loadingOverlay.BackgroundColor3, loadingOverlay.BackgroundTransparency, loadingOverlay.ZIndex = C.bg, 0.1, 10
loadingOverlay.Text, loadingOverlay.TextColor3, loadingOverlay.Font, loadingOverlay.ClipsDescendants = "Loading...", C.textDim, FONT.button, true
loadingOverlay.TextSize = s(11); loadingOverlay.Visible = false
tagTheme(loadingOverlay, "BackgroundColor3", "bg")
tagTheme(loadingOverlay, "TextColor3", "textDim")
createCorner(loadingOverlay, R_PANEL)
applyShimmer(loadingOverlay, C.panel, C.surface)

local pageLbl
do
local footer = Instance.new("Frame", lp_frame)
footer.Size = UDim2.new(1, -s(12), 0, s(18))
footer.Position = UDim2.new(0, s(6), 1, -s(22))
footer.BackgroundTransparency = 1; footer.ZIndex = 1

pageLbl = createLabel(footer, {
	text = "Loading...", font = FONT.label, size = s(10),
	textKey = "textMuted", uiSize = UDim2.new(1,0,1,0), pos = UDim2.new(0,0,0,0)
})
pageLbl.TextXAlignment = Enum.TextXAlignment.Center
end

do
local divider = Instance.new("Frame", mf)
divider.Size, divider.Position, divider.BackgroundColor3 = UDim2.new(0,1,1,0), UDim2.new(0, LEFT_W + s(6), 0, 0), C.strokeStrong
divider.BackgroundTransparency = 0.4; divider.BorderSizePixel = 0
tagTheme(divider, "BackgroundColor3", "strokeStrong")
end

local rp = Instance.new("Frame", mf)
rp.Size, rp.Position, rp.BackgroundTransparency = UDim2.new(0, RIGHT_W - s(6), 1, 0), UDim2.new(0, LEFT_W + s(12), 0, 0), 1

do
local rpBackdrop = Instance.new("Frame", rp)
rpBackdrop.Name = "PanelBackdrop"
rpBackdrop.Size = UDim2.new(1, 0, 1, 0); rpBackdrop.Position = UDim2.new(0, 0, 0, 0)
rpBackdrop.BackgroundColor3 = C.surface; rpBackdrop.BackgroundTransparency = 0
rpBackdrop.BorderSizePixel = 0; rpBackdrop.ZIndex = 0; rpBackdrop.Active = false
tagTheme(rpBackdrop, "BackgroundColor3", "surface")
createCorner(rpBackdrop, R_PANEL)
createStroke(rpBackdrop, C.strokeStrong, 1, 0, "strokeStrong")
end

createLabel(rp, {
	text = "PREVIEW", font = FONT.button, size = s(9),
	align = Enum.TextXAlignment.Left,
	uiSize = UDim2.new(1,0,0,s(10)), pos = UDim2.new(0, s(10), 0, s(8)),
	textKey = "textMuted"
})

local PREVIEW_INNER_WIDTH_RATIO  = 0.90
local PREVIEW_INNER_HEIGHT_RATIO = 0.90

local previewFrame = Instance.new("Frame", rp)
previewFrame.Name = "PreviewFrame"
previewFrame.Size = UDim2.new(1, -s(20), 0, VP_H + s(6))
previewFrame.Position = UDim2.new(0.5, 0, 0, s(22) + math.floor((VP_H + s(6)) / 2))
previewFrame.AnchorPoint = Vector2.new(0.5, 0.5)
previewFrame.BackgroundColor3 = C.overlay
previewFrame.BackgroundTransparency = 0.4
previewFrame.BorderSizePixel = 0; previewFrame.ZIndex = 1
previewFrame.Active = false
tagTheme(previewFrame, "BackgroundColor3", "overlay")
createCorner(previewFrame, s(14))
createStroke(previewFrame, C.strokeStrong, 2, 0, "strokeStrong")

local masterViewport = Instance.new("ViewportFrame", rp)
masterViewport.Name = "MasterViewport"
masterViewport.Size = UDim2.new(PREVIEW_INNER_WIDTH_RATIO, 0, 0, math.floor((VP_H + s(6)) * PREVIEW_INNER_HEIGHT_RATIO))
masterViewport.AnchorPoint = Vector2.new(0.5, 0.5)
masterViewport.Position = UDim2.new(0.5, 0, 0, s(22) + math.floor((VP_H + s(6)) / 2))
masterViewport.BackgroundColor3, masterViewport.BackgroundTransparency = C.overlay, 0.05
masterViewport.ZIndex = 2
tagTheme(masterViewport, "BackgroundColor3", "overlay")
createCorner(masterViewport, s(10))
createStroke(masterViewport, C.stroke, 1, 0.3, "stroke")

local previewBorder = Instance.new("ImageLabel", rp)
previewBorder.Name = "PreviewBorder"
previewBorder.Size = UDim2.new(1, -s(20), 0, VP_H + s(6))
previewBorder.Position = UDim2.new(0.5, 0, 0, s(22) + math.floor((VP_H + s(6)) / 2))
previewBorder.AnchorPoint = Vector2.new(0.5, 0.5)
previewBorder.BackgroundTransparency = 1
previewBorder.Image = (Theme == "Dark") and "rbxassetid://74516945382386" or "rbxassetid://108111145991423"
previewBorder.ImageTransparency = 0
previewBorder.ScaleType = Enum.ScaleType.Stretch
previewBorder.Active = false
previewBorder.ZIndex = 3
previewBorder.Visible = true

local function pollPreviewBorder()
	task.spawn(function()
		local tries = 0
		while tries < 12 and not previewBorder.IsLoaded do
			task.wait(0.4)
			tries = tries + 1
		end
		if not previewBorder.IsLoaded then
			previewBorder.Visible = false
			previewFrame.BackgroundTransparency = 0.4
		else
			previewBorder.Visible = true
			previewFrame.BackgroundTransparency = 1
			local fs = previewFrame:FindFirstChildOfClass("UIStroke")
			if fs then fs.Transparency = 1 end
		end
	end)
end
pollPreviewBorder()

local statusFrame = Instance.new("Frame", rp)
statusFrame.Size, statusFrame.Position = UDim2.new(1, -s(20), 0, s(26)), UDim2.new(0, s(10), 0, VP_H + s(38))
statusFrame.BackgroundColor3, statusFrame.BackgroundTransparency = C.bg, 0.2
statusFrame.ZIndex = 1
tagTheme(statusFrame, "BackgroundColor3", "bg")
createCorner(statusFrame, R_BUTTON)
createStroke(statusFrame, C.strokeStrong, 1, 0.2, "strokeStrong")

local statusLabel = createLabel(statusFrame, {
	text = "No bundle selected", font = FONT.button, size = s(10),
	align = Enum.TextXAlignment.Left,
	uiSize = UDim2.new(1, -s(14), 1, 0), pos = UDim2.new(0, s(8), 0, 0),
	textKey = "textDim"
})

local buttonContainer = Instance.new("Frame", rp)
buttonContainer.Size, buttonContainer.Position = UDim2.new(1, -s(20), 0, s(46)), UDim2.new(0, s(10), 0, VP_H + s(68))
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 1
local gbl = Instance.new("UIGridLayout", buttonContainer)
local btnW = math.floor((RIGHT_W - s(26) - s(12)) / 4)
gbl.CellSize, gbl.CellPadding = UDim2.new(0, btnW, 0, s(21)), UDim2.new(0, s(4), 0, s(4))

local actRow = Instance.new("Frame", rp)
actRow.Size, actRow.Position, actRow.BackgroundTransparency = UDim2.new(1, -s(20), 0, s(60)), UDim2.new(0, s(10), 1, -s(64)), 1
actRow.ZIndex = 1

local bookmarkBtn = createButton(actRow, {
	uiSize = UDim2.new(1,0,0,s(24)), pos = UDim2.new(0,0,0,0),
	text = "Save to Saved Tab", bgKey = "panel", bgTransparency = 0, textKey = "textDim",
	font = FONT.button, size = s(10), radius = R_BUTTON,
	strokeColor = C.accentDim, strokeKey = "accentDim"
})
bookmarkBtn.Name = "BookmarkBtn"
bookmarkBtn.Visible = false

local wearSelectedBtn = createButton(actRow, {
	uiSize = UDim2.new(0.48, 0, 0, s(30)), pos = UDim2.new(0, 0, 1, -s(30)),
	text = "Wear Selected", bgKey = "panel", textKey = "text",
	font = FONT.button, size = s(10), radius = R_BUTTON,
	strokeColor = C.accent, strokeKey = "accent"
})
wearSelectedBtn.Visible = false

local wearAllBtn = createButton(actRow, {
	uiSize = UDim2.new(0.48, 0, 1, -s(30)), pos = UDim2.new(0.52, 0, 1, -s(30)),
	text = "Wear All", bgKey = "accent", textKey = "onAccent",
	font = FONT.button, size = s(10), radius = R_BUTTON
})
wearAllBtn.Visible = false

local activeGridThreads, currentBundleItems, animationButtons = {}, {}, {}
local activeMasterTrack, activeMasterType = nil, nil
local activeBundleName, activeBundleId = "None", nil
local searchResults, savedTabList = {}, {}
local catalogCursor = nil
local currentTab = "Discover"
local userSelectedAnimSlot = "idleanimation"
local renderedCount = 0
local renderingMore = false
local renderToken = 0
local ITEMS_PER_LOAD = 6
local emoteAnimCache = {}
local emoteValidCache = {}
local executeSearch, refreshTabVisuals, refreshAnimButtonVisuals

local function preloadAnimations(tracks)
	local i = {}
	for _, t in ipairs(tracks) do table.insert(i, t) end
	if #i > 0 then pcall(function() cp:PreloadAsync(i) end) end
end

local function buildViewportSkeleton(vpFrame)
	local wm = vpFrame:FindFirstChildOfClass("WorldModel")
	if not wm then wm = Instance.new("WorldModel", vpFrame)
	else for _,c in ipairs(wm:GetChildren()) do c:Destroy() end end
	local char = lp.Character
	if not char then
		local t0 = tick()
		while not lp.Character and tick() - t0 < 3 do task.wait(0.1) end
		char = lp.Character
	end
	if not char then return nil, nil, nil end
	local wasArch = char.Archivable
	char.Archivable = true
	local clone = char:Clone()
	pcall(function() char.Archivable = wasArch end)
	if not clone then return nil, nil, nil end
	clone.Parent = wm
	local root = clone:WaitForChild("HumanoidRootPart", 5)
	local human = clone:FindFirstChildOfClass("Humanoid")
	local anim
	if human then anim = human:FindFirstChildOfClass("Animator") or Instance.new("Animator", human) end
	local af = clone:FindFirstChild("Animate"); if af then af.Disabled = true end
	local cam = vpFrame:FindFirstChildOfClass("Camera") or Instance.new("Camera", vpFrame)
	vpFrame.CurrentCamera = cam
	cam.CFrame = CFrame.new(Vector3.new(0, 1.5, 6), Vector3.new(0, 0, 0))
	if vpFrame.Name == "MasterViewport" then
		cam.FieldOfView = 55
		cam.CFrame = CFrame.new(Vector3.new(0, 1.2, 5.5), Vector3.new(0, 0.5, 0))
	end
	local angle = 0
	local conn = rs.RenderStepped:Connect(function(dt)
		if clone and clone.Parent and root and root.Parent then
			angle = angle + math.rad(25*dt)
			clone:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(0, angle, 0))
		end
	end)
	return clone, anim, conn
end

local function withAnimateEnabled(animate, fn)
	if not animate then return false, "no_animate" end
	animate.Disabled = true
	local ok, result = pcall(fn)
	animate.Disabled = false
	return ok, result
end

local function applyAnimationToCharacter(character, targetAnimations, slotType)
	if not character then return false end
	local animate = character:WaitForChild("Animate", 5)
	local human = character:FindFirstChildOfClass("Humanoid")
	if not animate or not human then return false end
	for _, tr in ipairs(human:GetPlayingAnimationTracks()) do
		pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end)
	end
	local cleanSlot = string.lower(slotType or "")
	local fId = m[cleanSlot]; local success = false
	withAnimateEnabled(animate, function()
		if not fId then return end
		local folder = animate:FindFirstChild(fId); if not folder then return end
		local payload, toCreate = {}, {}
		for _, aA in ipairs(targetAnimations) do
			local na = Instance.new("Animation")
			na.Name, na.AnimationId = aA.Name, aA.AnimationId
			table.insert(toCreate, na)
			table.insert(payload, {Name = na.Name, AnimationId = na.AnimationId})
		end
		if #toCreate == 0 then return end
		local ok = pcall(function()
			for _, o in ipairs(folder:GetChildren()) do if o:IsA("Animation") then o:Destroy() end end
			for _, na in ipairs(toCreate) do na.Parent = folder end
		end)
		if ok then
			equippedAnims[cleanSlot] = payload
			saveJSON(EQUIPPED_FILE, equippedAnims); success = true
		else
			for _, na in ipairs(toCreate) do pcall(function() na:Destroy() end) end
		end
	end)
	task.wait(0.05); return success
end

local function resetToDefaultAnimations()
	local char = lp.Character; if not char then return false end
	local animate = char:FindFirstChild("Animate")
	local human = char:FindFirstChildOfClass("Humanoid")
	if not animate or not human then return false end
	local ok = pcall(function()
		local desc = plrs:GetHumanoidDescriptionFromUserId(lp.UserId)
		local rigType = human.RigType or Enum.HumanoidRigType.R15
		local dummy = plrs:CreateHumanoidModelFromDescription(desc, rigType)
		local sa = dummy:FindFirstChild("Animate"); assert(sa, "no default Animate")
		for _, tr in ipairs(human:GetPlayingAnimationTracks()) do
			pcall(function() tr:AdjustWeight(0, 0); tr:Stop(0) end)
		end
		animate.Disabled = true
		for _, fN in pairs(m) do
			local dst = animate:FindFirstChild(fN); local src = sa:FindFirstChild(fN)
			if dst and src then
				for _, o in ipairs(dst:GetChildren()) do if o:IsA("Animation") then o:Destroy() end end
				for _, o in ipairs(src:GetChildren()) do if o:IsA("Animation") then o:Clone().Parent = dst end end
			end
		end
		dummy:Destroy(); task.wait(0.05); animate.Disabled = false
	end)
	if not ok then pcall(function() animate.Disabled = false end) return false end
	for k in pairs(equippedAnims) do equippedAnims[k] = nil end
	saveJSON(EQUIPPED_FILE, equippedAnims); return true
end

resetBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		showToast("Resetting...", "info")
		local done = resetToDefaultAnimations()
		showToast(done and "Reset to default" or "Reset failed", done and "success" or "error")
	end)
end)

local function getSpecificTrack(tracks, tType)
	if not tracks or #tracks == 0 then return nil end
	if tType == "swimidleanimation" then
		for _, tr in ipairs(tracks) do if string.lower(tr.Name):find("idle") then return tr end end
		return tracks[2] or tracks[1]
	elseif tType == "swimanimation" then
		for _, tr in ipairs(tracks) do if string.lower(tr.Name) == "swim" then return tr end end
	end
	return tracks[1]
end

local function truncate(str, maxLen)
	if not str then return "" end
	return #str > maxLen and str:sub(1, maxLen-1)..ICO_DOTS or str
end

local function tryPlayTrack(animator, track, looped)
	if not animator or not track then return false, nil end
	local ok, pt = pcall(function() local tr = animator:LoadAnimation(track); tr.Looped=looped; tr:Play(); return tr end)
	if not ok or not pt then return false, nil end
	task.wait(0.15)
	if not pt.IsPlaying then pcall(function() pt:Stop() end); return false, nil end
	return true, pt
end

local function applyBundleItemsToCharacter(items)
	local result = { status = "no_character", succeeded = 0, failed = 0, no_data = 0, skipped = 0 }
	if not lp.Character then return result end
	local char = lp.Character
	local animate = char:FindFirstChild("Animate")
	local human = char:FindFirstChildOfClass("Humanoid")
	if not animate or not human then return result end
	if not items or next(items) == nil then result.status = "empty_bundle"; return result end
	local tLoad, tApply = {}, {}
	for _, lt in ipairs(buttonOrder) do
		local pay = items[lt]
		if pay then
			local t = get(pay.Id, nil, pay.AssetType)
			if lt == "idleanimation" then
				if t and #t > 0 then
					tApply[lt] = t
					for _, x in ipairs(t) do table.insert(tLoad, x) end
				else result.no_data = result.no_data + 1 end
			else
				local spec = getSpecificTrack(t, lt)
				if spec then
					tApply[lt] = {spec}; table.insert(tLoad, spec)
				else result.no_data = result.no_data + 1 end
			end
		else result.skipped = result.skipped + 1 end
	end
	if next(tApply) == nil then
		result.status = (result.no_data > 0) and "no_usable_data" or "empty_bundle"
		return result
	end
	preloadAnimations(tLoad)
	withAnimateEnabled(animate, function()
		for _, tr in ipairs(human:GetPlayingAnimationTracks()) do
			pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end)
		end
		for slot, tracks in pairs(tApply) do
			local fId = m[string.lower(slot)]
			local folder = fId and animate:FindFirstChild(fId)
			if not folder then result.failed = result.failed + 1
			else
				local payload, toCreate = {}, {}
				for _, aA in ipairs(tracks) do
					local na = Instance.new("Animation")
					na.Name, na.AnimationId = aA.Name, aA.AnimationId
					table.insert(toCreate, na)
					table.insert(payload, {Name = na.Name, AnimationId = na.AnimationId})
				end
				local ok = pcall(function()
					for _, o in ipairs(folder:GetChildren()) do
						if o:IsA("Animation") then o:Destroy() end
					end
					for _, na in ipairs(toCreate) do na.Parent = folder end
				end)
				if ok then
					equippedAnims[string.lower(slot)] = payload
					result.succeeded = result.succeeded + 1
				else result.failed = result.failed + 1 end
			end
		end
		saveJSON(EQUIPPED_FILE, equippedAnims)
	end)
	if result.succeeded > 0 and result.failed == 0 and result.no_data == 0 then
		result.status = "full_success"
	elseif result.succeeded > 0 then result.status = "partial"
	elseif result.failed > 0 then result.status = "full_failure"
	else result.status = "no_usable_data" end
	task.wait(0.05); return result
end

local function wearBundleQuickly(bundleId, onDone)
	task.spawn(function()
		local success = false
		local ok, err = pcall(function()
			local res = as:GetBundleDetailsAsync(bundleId)
			if not (res and res.Items and lp.Character) then return end
			local items = {}
			for _, item in ipairs(res.Items) do
				local lt = string.lower(item.AssetType or "")
				if lt == "swimanimation" then
					items["swimanimation"] = item; items["swimidleanimation"] = item
				elseif shortNames[lt] then items[lt] = item end
			end
			local r = applyBundleItemsToCharacter(items)
			success = (r and (r.status == "full_success" or r.status == "partial"))
		end)
		if not ok then warn("[wearBundleQuickly] error:", err) end
		if onDone then pcall(onDone, success) end
	end)
end

local function toggleBookmark(bundleId, bundleName)
	local sid = tostring(bundleId); local nowSaved
	if savedBookmarks[sid] then savedBookmarks[sid] = nil; nowSaved = false
	else savedBookmarks[sid] = {Id = bundleId, Name = bundleName, Fav = false, Time = tick()}; nowSaved = true end
	saveJSON(SAVED_BUNDLES_FILE, savedBookmarks); return nowSaved
end

local function playEmoteFromList(e)
	local char = lp.Character
	if not char then showToast("Character belum spawn", "warn") return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then showToast("Humanoid nggak ketemu", "error") return end
	showToast("Playing: " .. truncate(e.Name, 20), "success")
	local ok1, r1 = pcall(function() return humanoid:PlayEmote(e.Name) end)
	if ok1 and r1 then return end
	task.spawn(function()
		pcall(function()
			local desc = humanoid:FindFirstChildOfClass("HumanoidDescription")
			if desc then
				desc:SetEmotes({[e.Name] = {e.Id}}); task.wait(0.2)
				local ok2, r2 = pcall(function() return humanoid:PlayEmote(e.Name) end)
				if not ok2 or not r2 then showToast("Gagal play: " .. e.Name, "error") end
			end
		end)
	end)
end

local function resolveEmoteAnimId(emoteId)
	local key = tostring(emoteId)
	if emoteAnimCache[key] ~= nil then return emoteAnimCache[key] end
	if type(game.GetObjects) ~= "function" then return nil end
	local resolved = nil
	pcall(function()
		local objs = game:GetObjects("rbxassetid://" .. key)
		if objs and #objs > 0 then
			local function findAnim(obj)
				if obj:IsA("Animation") then
					local aid = obj.AnimationId
					if aid and aid ~= "" and aid ~= "rbxassetid://0" then return aid end
				end
				for _, c in ipairs(obj:GetChildren()) do
					local f = findAnim(c); if f then return f end
				end
				return nil
			end
			resolved = findAnim(objs[1])
			for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
		end
	end)
	emoteAnimCache[key] = resolved or false
	return resolved
end

local previewEmoteGen = 0
local previewEmoteConn = nil
local previewEmoteTrack = nil
local masterRenderGen = 0
local masterConn = nil

local function stopAllMaster()
	if previewEmoteConn then previewEmoteConn:Disconnect(); previewEmoteConn = nil end
	if previewEmoteTrack then pcall(function() previewEmoteTrack:Stop() end); previewEmoteTrack = nil end
	if masterConn then masterConn:Disconnect(); masterConn = nil end
	if activeMasterTrack then pcall(function() activeMasterTrack:Stop() end); activeMasterTrack = nil end
	if masterViewport then
		local sk = masterViewport:FindFirstChild("LoadingShimmer")
		if sk then sk:Destroy() end
	end
	if statusLabel then removeShimmer(statusLabel) end
end

local function renderMasterTrack(itemPayload, assetTypeName)
	stopAllMaster()
	masterRenderGen = masterRenderGen + 1
	local myGen = masterRenderGen
	local dummy, animator, conn = buildViewportSkeleton(masterViewport)
	masterConn = conn
	local lower = string.lower(assetTypeName or "")
	local disp = shortNames[lower] or "Track"
	statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." "..disp.." (loading...)"
	local vps = masterViewport:FindFirstChild("LoadingShimmer")
	if not vps then
		vps = Instance.new("Frame", masterViewport)
		vps.Name = "LoadingShimmer"
		vps.Size, vps.BackgroundColor3, vps.BorderSizePixel = UDim2.new(1,0,1,0), C.overlay, 0
		createCorner(vps, R_CARD); applyShimmer(vps, C.overlay, C.surface)
	end
	task.spawn(function()
		local attempt, fetched, ttp = 0, nil, nil
		while myGen == masterRenderGen and attempt < 6 do
			fetched = get(itemPayload.Id, nil, itemPayload.AssetType)
			ttp = (fetched and #fetched>0) and getSpecificTrack(fetched, lower) or nil
			if ttp then break end
			attempt = attempt + 1
			statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." "..disp.." (retry "..attempt..")"
			clearAssetCache(itemPayload.Id)
			task.wait(math.min(0.5 + attempt*0.3, 3))
		end
		if myGen ~= masterRenderGen then return end
		if attempt >= 6 and not ttp then
			statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." "..disp.." (unavailable)"
			if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end
			return
		end
		if ttp then
			if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end
		end
		activeMasterType = assetTypeName
		statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." "..disp
		local isIdle = (lower == "idleanimation")
		if isIdle and fetched and #fetched > 1 and animator then
			local ptr = 1
			while myGen == masterRenderGen and dummy and dummy.Parent do
				if activeMasterTrack then activeMasterTrack:Stop() end
				local ok, played = tryPlayTrack(animator, fetched[ptr], false)
				while not ok and myGen == masterRenderGen do
					clearAssetCache(itemPayload.Id)
					fetched = get(itemPayload.Id, nil, itemPayload.AssetType)
					if not fetched or #fetched == 0 then task.wait(0.4); continue end
					ptr = (ptr % #fetched) + 1
					task.wait(0.4); ok, played = tryPlayTrack(animator, fetched[ptr], false)
				end
				if myGen ~= masterRenderGen then return end
				activeMasterTrack = played
				if activeMasterTrack then activeMasterTrack.Stopped:Wait() end
				if not fetched or #fetched == 0 then return end
				ptr = (ptr % #fetched) + 1
			end
		elseif ttp and animator then
			local ok, played = tryPlayTrack(animator, ttp, true)
			while not ok and myGen == masterRenderGen do
				clearAssetCache(itemPayload.Id); task.wait(0.4)
				local rl = get(itemPayload.Id, nil, itemPayload.AssetType)
				ttp = (rl and #rl>0) and getSpecificTrack(rl, lower) or nil
				if ttp then ok, played = tryPlayTrack(animator, ttp, true) end
			end
			if myGen ~= masterRenderGen then return end
			activeMasterTrack = played
		end
	end)
end

local function previewEmoteInMaster(e)
	stopAllMaster()
	activeMasterType = nil
	previewEmoteGen = previewEmoteGen + 1
	masterRenderGen = masterRenderGen + 1
	local myGen = previewEmoteGen
	statusLabel.Text = "Emote: " .. truncate(e.Name, 20) .. " (loading...)"
	local vpShimmer = masterViewport:FindFirstChild("LoadingShimmer")
	if not vpShimmer then
		vpShimmer = Instance.new("Frame", masterViewport)
		vpShimmer.Name = "LoadingShimmer"
		vpShimmer.Size, vpShimmer.BackgroundColor3, vpShimmer.BorderSizePixel = UDim2.new(1,0,1,0), C.overlay, 0
		createCorner(vpShimmer, R_CARD); applyShimmer(vpShimmer, C.overlay, C.surface)
	end
	local dummy, animator, conn = buildViewportSkeleton(masterViewport)
	previewEmoteConn = conn
	task.spawn(function()
		task.wait(0.3)
		if myGen ~= previewEmoteGen then return end
		if not animator then
			statusLabel.Text = "Emote: " .. truncate(e.Name, 20) .. " (no animator)"
			if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end
			return
		end
		local resolvedId = resolveEmoteAnimId(e.Id)
		local animId = resolvedId or ("rbxassetid://" .. tostring(e.Id))
		local anim = Instance.new("Animation"); anim.AnimationId = animId
		local ok, track = pcall(function()
			local t = animator:LoadAnimation(anim)
			t.Looped = true; t:Play(); return t
		end)
		if ok and track then
			previewEmoteTrack = track
			statusLabel.Text = "Emote: " .. truncate(e.Name, 22)
		else statusLabel.Text = "Emote: " .. truncate(e.Name, 20) .. " (failed)" end
		if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end
	end)
end

local function paintSlotBtn(b, state)
	local t = Themes[Theme]
	if state == "sel" then
		b.BackgroundColor3 = t.accent; b.TextColor3 = t.onAccent
		b:SetAttribute("_tk_BackgroundColor3", "accent"); b:SetAttribute("_tk_TextColor3", "onAccent")
	elseif state == "has" then
		b.BackgroundColor3 = t.surfaceHi; b.TextColor3 = t.text
		b:SetAttribute("_tk_BackgroundColor3", "surfaceHi"); b:SetAttribute("_tk_TextColor3", "text")
	else
		b.BackgroundColor3 = t.bg; b.TextColor3 = t.textMuted
		b:SetAttribute("_tk_BackgroundColor3", "bg"); b:SetAttribute("_tk_TextColor3", "textMuted")
	end
end

for _, lt in ipairs(buttonOrder) do
	local btn = createButton(buttonContainer, {
		uiSize = UDim2.new(0, btnW, 0, s(21)),
		bgKey = "bg", bgTransparency = 0, textKey = "textMuted",
		text = string.upper(shortNames[lt]),
		font = FONT.slot, size = s(9), radius = R_SMALL,
		strokeColor = C.strokeStrong, strokeKey = "strokeStrong"
	})
	btn.MouseButton1Click:Connect(function()
		local payload = currentBundleItems[lt]
		if not payload then
			showToast("Slot " .. string.upper(shortNames[lt] or lt) .. " kosong", "warn")
			return
		end
		userSelectedAnimSlot = lt
		wearSelectedBtn.Visible = true
		renderMasterTrack(payload, lt)
		for s2, b in pairs(animationButtons) do
			if s2 == lt then paintSlotBtn(b, "sel")
			elseif currentBundleItems[s2] then paintSlotBtn(b, "has")
			else paintSlotBtn(b, "empty") end
		end
	end)
	animationButtons[lt] = btn
end

local function refreshBookmarkBtn()
	if not activeBundleId then bookmarkBtn.Visible = false return end
	bookmarkBtn.Visible = true
	local t = Themes[Theme]
	local isSaved = savedBookmarks[tostring(activeBundleId)] ~= nil
	if isSaved then
		bookmarkBtn.Text = "Saved to Saved Tab"
		bookmarkBtn.BackgroundColor3 = t.accent
		bookmarkBtn.TextColor3 = t.onAccent
		bookmarkBtn:SetAttribute("_tk_BackgroundColor3", "accent")
		bookmarkBtn:SetAttribute("_tk_TextColor3", "onAccent")
	else
		bookmarkBtn.Text = "Save to Saved Tab"
		bookmarkBtn.BackgroundColor3 = t.panel
		bookmarkBtn.TextColor3 = t.textDim
		bookmarkBtn:SetAttribute("_tk_BackgroundColor3", "panel")
		bookmarkBtn:SetAttribute("_tk_TextColor3", "textDim")
	end
	bookmarkBtn:SetAttribute("_saveState", isSaved)
end

refreshAnimButtonVisuals = function()
	for slot, b in pairs(animationButtons) do
		local isSel = (slot == userSelectedAnimSlot) and currentBundleItems[slot] ~= nil
		local hasData = currentBundleItems[slot] ~= nil
		if isSel then paintSlotBtn(b, "sel")
		elseif hasData then paintSlotBtn(b, "has")
		else paintSlotBtn(b, "empty") end
	end
end

bookmarkBtn.MouseButton1Click:Connect(function()
	local nowS = toggleBookmark(activeBundleId, activeBundleName)
	showToast(nowS and "Saved to bookmarks" or "Removed from saved", nowS and "success" or "info")
	refreshBookmarkBtn()
	if currentTab == "Saved" then executeSearch(sb.Text) end
end)

local function inspectBundleDetails(bundleId, bundleName)
	table.clear(currentBundleItems)
	wearSelectedBtn.Visible, wearAllBtn.Visible = false, false
	activeBundleName, activeBundleId = bundleName or "Unknown", bundleId
	statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." Loading..."
	refreshBookmarkBtn(); refreshAnimButtonVisuals()
	task.spawn(function()
		local ok, res = pcall(function() return as:GetBundleDetailsAsync(bundleId) end)
		if not ok or not res or not res.Items then
			statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." Couldn't load"
			return
		end
		for _, item in ipairs(res.Items) do
			local lt = string.lower(item.AssetType or "")
			if lt == "swimanimation" then
				currentBundleItems["swimanimation"] = item
				currentBundleItems["swimidleanimation"] = item
			elseif shortNames[lt] then currentBundleItems[lt] = item end
		end
		wearAllBtn.Visible = true
		local slotToPlay = currentBundleItems[userSelectedAnimSlot] and userSelectedAnimSlot or "idleanimation"
		refreshAnimButtonVisuals()
		if currentBundleItems[slotToPlay] then
			wearSelectedBtn.Visible = true
			renderMasterTrack(currentBundleItems[slotToPlay], slotToPlay)
		else
			statusLabel.Text = truncate(activeBundleName, 24).." "..ICO_DOT.." No preview"
		end
	end)
end

local function clearActiveGridContext()
	for _, t in ipairs(activeGridThreads) do pcall(task.cancel, t) end
	table.clear(activeGridThreads)
	for _, c in ipairs(gridScroller:GetChildren()) do
		pcall(function() c:Destroy() end)
	end
end

local function clearGridFull()
	renderToken = renderToken + 1
	renderingMore = false
	clearActiveGridContext()
	renderedCount = 0
	gridScroller.CanvasPosition = Vector2.new(0,0)
end

local function drawEmptyState(title, subtitle)
	clearActiveGridContext(); loadingOverlay.Visible = false
	local wrap = Instance.new("Frame", gridScroller)
	wrap.Size = UDim2.new(1,0,0,s(180)); wrap.Position = UDim2.new(0,0,0,s(20))
	wrap.BackgroundTransparency = 1
	local t = Instance.new("TextLabel", wrap)
	t.Size = UDim2.new(1,0,0,s(20)); t.Position = UDim2.new(0,0,0,s(60))
	t.BackgroundTransparency = 1; t.Text = title
	t.Font = FONT.button; t.TextSize = s(11); t.TextColor3 = C.text
	tagTheme(t, "TextColor3", "text")
	local sub = Instance.new("TextLabel", wrap)
	sub.Size = UDim2.new(1,0,0,s(14)); sub.Position = UDim2.new(0,0,0,s(84))
	sub.BackgroundTransparency = 1; sub.Text = subtitle
	sub.Font = FONT.label; sub.TextSize = s(9); sub.TextColor3 = C.textMuted
	tagTheme(sub, "TextColor3", "textMuted")
	pageLbl.Text = "0 items"
end

local function validateEmoteBatch(emoteIds)
	if not emoteIds or #emoteIds == 0 then return {} end
	local result = {}; local toCheck = {}
	for _, id in ipairs(emoteIds) do
		local key = tostring(id)
		if emoteValidCache[key] ~= nil then result[id] = emoteValidCache[key]
		else table.insert(toCheck, id) end
	end
	if #toCheck == 0 then return result end
	for i = 1, #toCheck, 50 do
		local chunk = {}
		for j = i, math.min(i + 49, #toCheck) do table.insert(chunk, tostring(toCheck[j])) end
		local url = "https://thumbnails.roblox.com/v1/assets?assetIds="
			.. table.concat(chunk, ",") .. "&size=420x420&format=Png"
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if ok and body then
			local suc, dec = pcall(function() return hs:JSONDecode(body) end)
			if suc and dec and dec.data then
				for _, entry in ipairs(dec.data) do
					local tid = tonumber(entry.targetId)
					if tid then
						local isValid = (entry.state == "Completed") and entry.imageUrl and entry.imageUrl ~= ""
						emoteValidCache[tostring(tid)] = isValid; result[tid] = isValid
					end
				end
			end
		end
		task.wait(0.05)
	end
	for _, id in ipairs(toCheck) do
		if result[id] == nil then
			emoteValidCache[tostring(id)] = true; result[id] = true
		end
	end
	return result
end

local function createBundleCard(bundle, idx)
	local usableWidth = LEFT_W - s(12) - scrollW
	local boxHeight = s(138)
	local actionRowH = s(26); local nameRowH = s(28)
	local boxWidth = math.floor((usableWidth - s(24)) / 2)
	local row = math.floor((idx - 1) / 2)
	local col = (idx - 1) % 2
	local posX = s(8) + col * (boxWidth + s(8))
	local posY = s(8) + row * (boxHeight + s(8))

	local box = Instance.new("Frame", gridScroller)
	box.BackgroundColor3 = C.surface
	box.BackgroundTransparency = 0
	box.BorderSizePixel = 0
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.new(0, posX + boxWidth/2, 0, posY + boxHeight/2)
	box.Size = UDim2.new(0, 0, 0, 0)
	box.ClipsDescendants = true
	tagTheme(box, "BackgroundColor3", "surface")
	createCorner(box, R_CARD)
	createStroke(box, C.strokeStrong, 1, 0.15, "strokeStrong")
	tween(box, {Size = UDim2.new(0, boxWidth, 0, boxHeight)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local vp = Instance.new("ViewportFrame", box)
	vp.Size = UDim2.new(1, 0, 1, -(nameRowH + actionRowH))
	vp.Position = UDim2.new(0, 0, 0, 0)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.ZIndex = 1

	local skel = Instance.new("Frame", box)
	skel.Size = vp.Size
	skel.Position = vp.Position
	skel.BackgroundColor3 = C.panel
	skel.BorderSizePixel = 0
	skel.ZIndex = 2
	tagTheme(skel, "BackgroundColor3", "panel")
	createCorner(skel, R_CARD)
	applyShimmer(skel, C.panel, C.surface)

	local label = Instance.new("TextLabel", box)
	label.Size = UDim2.new(1, 0, 0, nameRowH)
	label.Position = UDim2.new(0, 0, 1, -(nameRowH + actionRowH))
	label.BackgroundColor3 = C.bg
	label.BackgroundTransparency = 0.3
	label.Text = bundle.Name
	label.TextColor3 = C.text
	label.Font = FONT.buttonSm
	label.TextSize = s(10)
	label.ZIndex = 3
	label.ClipsDescendants = true
	tagTheme(label, "BackgroundColor3", "bg")
	tagTheme(label, "TextColor3", "text")
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd

	local hitBtn = Instance.new("TextButton", box)
	hitBtn.Size = UDim2.new(1, 0, 1, -actionRowH)
	hitBtn.Position = UDim2.new(0, 0, 0, 0)
	hitBtn.BackgroundTransparency = 1
	hitBtn.Text = ""
	hitBtn.ZIndex = 4
	hitBtn.AutoButtonColor = false
	hitBtn.MouseButton1Click:Connect(function()
		SoundFx.click(); inspectBundleDetails(bundle.Id, bundle.Name)
	end)

	if currentTab == "Saved" then
		local favBtn = Instance.new("TextButton", box)
		favBtn.Size = UDim2.new(0, s(22), 0, s(22))
		favBtn.Position = UDim2.new(1, -s(24), 0, s(2))
		favBtn.BackgroundTransparency = 1
		favBtn.Text = ""
		favBtn.ZIndex = 5
		favBtn.AutoButtonColor = false
		makeIcon(favBtn, bundle.Fav and "star_fill" or "star", s(14), false)
		setIconColor(favBtn, bundle.Fav and C.fav or C.textMuted)
		favBtn:SetAttribute("_fav", bundle.Fav and true or false)
		favBtn.MouseButton1Click:Connect(function()
			SoundFx.click()
			local sid = tostring(bundle.Id)
			if savedBookmarks[sid] then
				savedBookmarks[sid].Fav = not savedBookmarks[sid].Fav
				saveJSON(SAVED_BUNDLES_FILE, savedBookmarks)
				bundle.Fav = savedBookmarks[sid].Fav
				setIconName(favBtn, bundle.Fav and "star_fill" or "star")
				setIconColor(favBtn, bundle.Fav and C.fav or C.textMuted)
				favBtn:SetAttribute("_fav", bundle.Fav and true or false)
			end
		end)
	end

	local cardActions = Instance.new("Frame", box)
	cardActions.Size = UDim2.new(1, 0, 0, actionRowH)
	cardActions.Position = UDim2.new(0, 0, 1, -actionRowH)
	cardActions.BackgroundTransparency = 1
	cardActions.ZIndex = 6

	local alreadySaved = savedBookmarks[tostring(bundle.Id)] ~= nil
	local saveCardBtn = Instance.new("TextButton", cardActions)
	saveCardBtn.Size = UDim2.new(0.5, -s(1), 1, 0)
	saveCardBtn.Position = UDim2.new(0, 0, 0, 0)
	local t0 = Themes[Theme]
	if alreadySaved then
		saveCardBtn.BackgroundColor3 = t0.accent
		saveCardBtn.TextColor3 = t0.onAccent
		saveCardBtn.Text = "SAVED"
	else
		saveCardBtn.BackgroundColor3 = t0.surfaceHi
		saveCardBtn.TextColor3 = t0.text
		saveCardBtn.Text = "SAVE"
	end
	saveCardBtn.BackgroundTransparency = 0
	saveCardBtn.Font = FONT.buttonSm
	saveCardBtn.TextSize = s(9)
	saveCardBtn.ZIndex = 7
	saveCardBtn.AutoButtonColor = false
	saveCardBtn.ClipsDescendants = true
	saveCardBtn:SetAttribute("_saveState", alreadySaved)
	saveCardBtn:SetAttribute("_cardSave", true)
	saveCardBtn:SetAttribute("_tk_BackgroundColor3", alreadySaved and "accent" or "surfaceHi")
	saveCardBtn:SetAttribute("_tk_TextColor3", alreadySaved and "onAccent" or "text")
	createCorner(saveCardBtn, R_SMALL)
	createStroke(saveCardBtn, C.strokeStrong, 1, 0.3, "strokeStrong")
	saveCardBtn.MouseButton1Down:Connect(function()
		saveCardBtn.Size = UDim2.new(0.5, -s(1), 1, -1)
		SoundFx.click()
	end)
	saveCardBtn.MouseButton1Up:Connect(function() saveCardBtn.Size = UDim2.new(0.5, -s(1), 1, 0) end)

	local wearCardBtn = Instance.new("TextButton", cardActions)
	wearCardBtn.Size = UDim2.new(0.5, -s(1), 1, 0)
	wearCardBtn.Position = UDim2.new(0.5, s(2), 0, 0)
	wearCardBtn.BackgroundColor3 = C.accent
	wearCardBtn.BackgroundTransparency = 0
	wearCardBtn.Text = "PLAY"
	wearCardBtn.TextColor3 = C.onAccent
	wearCardBtn.Font = FONT.buttonSm
	wearCardBtn.TextSize = s(9)
	wearCardBtn.ZIndex = 7
	wearCardBtn.AutoButtonColor = false
	wearCardBtn.ClipsDescendants = true
	createCorner(wearCardBtn, R_SMALL)
	tagTheme(wearCardBtn, "BackgroundColor3", "accent")
	tagTheme(wearCardBtn, "TextColor3", "onAccent")
	wearCardBtn.MouseButton1Down:Connect(function()
		wearCardBtn.Size = UDim2.new(0.5, -s(1), 1, -1)
		SoundFx.click()
	end)
	wearCardBtn.MouseButton1Up:Connect(function() wearCardBtn.Size = UDim2.new(0.5, -s(1), 1, 0) end)

	saveCardBtn.MouseButton1Click:Connect(function()
		local nowS = toggleBookmark(bundle.Id, bundle.Name)
		local t = Themes[Theme]
		if nowS then
			saveCardBtn.Text = "SAVED"
			saveCardBtn.BackgroundColor3 = t.accent
			saveCardBtn.TextColor3 = t.onAccent
			saveCardBtn:SetAttribute("_tk_BackgroundColor3", "accent")
			saveCardBtn:SetAttribute("_tk_TextColor3", "onAccent")
		else
			saveCardBtn.Text = "SAVE"
			saveCardBtn.BackgroundColor3 = t.surfaceHi
			saveCardBtn.TextColor3 = t.text
			saveCardBtn:SetAttribute("_tk_BackgroundColor3", "surfaceHi")
			saveCardBtn:SetAttribute("_tk_TextColor3", "text")
		end
		saveCardBtn:SetAttribute("_saveState", nowS)
		showToast(nowS and "Saved to bookmarks" or "Removed from saved", nowS and "success" or "info")
		if activeBundleId == bundle.Id then refreshBookmarkBtn() end
		if currentTab == "Saved" and not nowS then executeSearch(sb.Text) end
	end)

	wearCardBtn.MouseButton1Click:Connect(function()
		wearCardBtn.Text = ICO_DOTS
		wearBundleQuickly(bundle.Id, function(success)
			if wearCardBtn and wearCardBtn.Parent then wearCardBtn.Text = "PLAY" end
			showToast(success and ("Equipped " .. truncate(bundle.Name, 14)) or "Failed to load", success and "success" or "error")
		end)
	end)

	local dummy, animator, conn = buildViewportSkeleton(vp)
	local loopThread = task.spawn(function()
		if not animator then return end
		local ok, details = pcall(function() return as:GetBundleDetailsAsync(bundle.Id) end)
		if not ok or not details or not details.Items then return end
		local usableTracks = {}
		for _, si in ipairs(details.Items) do
			if m[string.lower(si.AssetType or "")] then table.insert(usableTracks, si) end
		end
		if #usableTracks == 0 then return end
		local tIdx, cellTrack = 1, nil
		while box and box.Parent do
			local si = usableTracks[tIdx]; if not si then break end
			local assets = get(si.Id, bundle.Id, si.AssetType)
			if assets and #assets > 0 then
				if cellTrack then cellTrack:Stop() end
				cellTrack = animator:LoadAnimation(assets[1]); cellTrack.Looped = true
				if skel.Parent then skel:Destroy() end
				cellTrack:Play()
			end
			task.wait(3.0); tIdx = (tIdx % #usableTracks) + 1
		end
	end)
	table.insert(activeGridThreads, loopThread)
	box.Destroying:Connect(function()
		pcall(task.cancel, loopThread)
		if conn then conn:Disconnect() end
	end)
end

local function createEmoteCard(e, idx)
	local pad = s(6)
	local usableWidth = LEFT_W - s(12) - scrollW
	local cardW = math.floor((usableWidth - pad*2 - s(6)) / 2)
	local thumbH = math.floor(cardW * 0.72)
	local nameH = s(16); local btnH = s(22)
	local cardH = pad + thumbH + s(2) + nameH + s(2) + btnH + pad
	local col = (idx - 1) % 2; local row = math.floor((idx - 1) / 2)
	local posX = pad + col * (cardW + s(6))
	local posY = pad + row * (cardH + s(6))

	local card = Instance.new("Frame", gridScroller)
	card.Size = UDim2.new(0, cardW, 0, cardH)
	card.Position = UDim2.new(0, posX, 0, posY)
	card.BackgroundColor3 = C.surface
	card.BackgroundTransparency = 0
	card.BorderSizePixel = 0
	card.ZIndex = 1
	card.LayoutOrder = idx
	card.ClipsDescendants = true
	tagTheme(card, "BackgroundColor3", "surface")
	createCorner(card, R_CARD)
	createStroke(card, C.strokeStrong, 1, 0.15, "strokeStrong")

	local vp = Instance.new("ViewportFrame", card)
	vp.Size = UDim2.new(1, -pad*2, 0, thumbH)
	vp.Position = UDim2.new(0, pad, 0, pad)
	vp.BackgroundColor3 = C.bg
	vp.BackgroundTransparency = 0.1
	vp.BorderSizePixel = 0
	vp.ZIndex = 1
	tagTheme(vp, "BackgroundColor3", "bg")
	createCorner(vp, R_SMALL + 2)

	local skel = Instance.new("Frame", card)
	skel.Size = vp.Size
	skel.Position = vp.Position
	skel.BackgroundColor3 = C.panel
	skel.BorderSizePixel = 0
	skel.ZIndex = 2
	tagTheme(skel, "BackgroundColor3", "panel")
	createCorner(skel, R_SMALL + 2)
	applyShimmer(skel, C.panel, C.surface)

	local nameLbl = Instance.new("TextLabel", card)
	nameLbl.Size = UDim2.new(1, -pad*2, 0, nameH)
	nameLbl.Position = UDim2.new(0, pad, 0, pad + thumbH + s(2))
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = truncate(e.Name, 14)
	nameLbl.Font = FONT.buttonSm
	nameLbl.TextSize = s(9)
	nameLbl.TextColor3 = C.text
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.ZIndex = 3
	tagTheme(nameLbl, "TextColor3", "text")

	local actionBtn = Instance.new("TextButton", card)
	actionBtn.Size = UDim2.new(1, -pad*2, 0, btnH)
	actionBtn.Position = UDim2.new(0, pad, 0, pad + thumbH + s(2) + nameH + s(2))
	actionBtn.BackgroundColor3 = C.accent
	actionBtn.BorderSizePixel = 0
	actionBtn.Text = "PLAY"
	actionBtn.Font = FONT.buttonSm
	actionBtn.TextSize = s(9)
	actionBtn.TextColor3 = C.onAccent
	actionBtn.AutoButtonColor = false
	actionBtn.ZIndex = 5
	tagTheme(actionBtn, "BackgroundColor3", "accent")
	tagTheme(actionBtn, "TextColor3", "onAccent")
	createCorner(actionBtn, R_SMALL)
	actionBtn.MouseButton1Down:Connect(function()
		actionBtn.Size = UDim2.new(1, -pad*2, 0, btnH-1)
		SoundFx.click()
	end)
	actionBtn.MouseButton1Up:Connect(function() actionBtn.Size = UDim2.new(1, -pad*2, 0, btnH) end)
	actionBtn.MouseButton1Click:Connect(function() playEmoteFromList(e) end)

	local cardHit = Instance.new("TextButton", card)
	cardHit.Size = UDim2.new(1, 0, 0, pad + thumbH + s(2) + nameH)
	cardHit.Position = UDim2.new(0, 0, 0, 0)
	cardHit.BackgroundTransparency = 1
	cardHit.Text = ""
	cardHit.ZIndex = 4
	cardHit.AutoButtonColor = false
	cardHit.MouseButton1Click:Connect(function()
		SoundFx.click(); previewEmoteInMaster(e)
	end)

	task.spawn(function()
		task.wait(math.min(0.03 * idx, 0.4))
		if not card.Parent then return end
		local tpl = lp.Character; if not tpl then return end
		local wasArch = tpl.Archivable
		tpl.Archivable = true
		local clone = tpl:Clone()
		pcall(function() tpl.Archivable = wasArch end)
		if not clone then return end
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then pcall(function() d:Destroy() end) end
		end
		local wm = Instance.new("WorldModel", vp)
		clone.Parent = wm
		local human = clone:FindFirstChildOfClass("Humanoid")
		local animator = human and (human:FindFirstChildOfClass("Animator") or Instance.new("Animator", human))
		local af = clone:FindFirstChild("Animate"); if af then af.Disabled = true end
		clone:PivotTo(CFrame.new(0,0,0))
		local cam = Instance.new("Camera", vp)
		cam.FieldOfView = 40
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, 8.5), Vector3.new(0, -0.2, 0))
		vp.CurrentCamera = cam
		if animator and e.Id then
			local resolvedId = resolveEmoteAnimId(e.Id)
			if resolvedId then
				local anim = Instance.new("Animation"); anim.AnimationId = resolvedId
				pcall(function()
					local track = animator:LoadAnimation(anim)
					track.Looped = true; track:Play()
				end)
			end
		end
		if skel.Parent then skel:Destroy() end
		local angle = 0
		local conn = rs.RenderStepped:Connect(function(dt)
			if clone and clone.Parent then
				angle = angle + math.rad(25*dt)
				clone:PivotTo(CFrame.Angles(0, angle, 0))
			end
		end)
		card.Destroying:Connect(function() conn:Disconnect() end)
	end)
end

local function getActiveList()
	if currentTab == "Saved" then return savedTabList end
	if currentTab == "Emotes" then return emoteFiltered end
	return searchResults
end
local function getStatusText() if currentTab == "Emotes" then return emoteLoadStatus end return nil end

local function renderMore()
	if renderingMore then return end
	local list = getActiveList()
	if not list or renderedCount >= #list then
		if currentTab == "Discover" and catalogCursor and not catalogCursor.IsFinished then
			renderingMore = true; local token = renderToken
			task.spawn(function()
				local ok = pcall(function() catalogCursor:AdvanceToNextPageAsync() end)
				renderingMore = false
				if token ~= renderToken then return end
				if ok then
					for _, v in ipairs(catalogCursor:GetCurrentPage()) do table.insert(searchResults, v) end
					renderMore()
				end
			end)
		end
		return
	end

	renderingMore = true
	local myToken = renderToken

	if currentTab == "Emotes" then
		local candidates = {}; local scanIdx = renderedCount
		local maxAtt = ITEMS_PER_LOAD * 10; local scanned = 0
		while #candidates < ITEMS_PER_LOAD * 3 and scanIdx < #list and scanned < maxAtt do
			scanIdx = scanIdx + 1; scanned = scanned + 1
			table.insert(candidates, list[scanIdx])
		end
		local idList = {}
		for _, e in ipairs(candidates) do table.insert(idList, e.Id) end
		local validMap = validateEmoteBatch(idList)
		if myToken ~= renderToken then renderingMore = false; return end
		local validRendered = 0; local consumed = 0
		for i, e in ipairs(candidates) do
			if myToken ~= renderToken then renderingMore = false; return end
			consumed = i
			if validMap[e.Id] ~= false then
				validRendered = validRendered + 1
				createEmoteCard(e, renderedCount + validRendered)
			end
			if validRendered >= ITEMS_PER_LOAD then break end
		end
		renderedCount = renderedCount + consumed
		task.delay(1.2, function()
			if myToken ~= renderToken then return end
			if currentTab ~= "Emotes" then return end
			local cards = {}
			for _, c in ipairs(gridScroller:GetChildren()) do
				if c:IsA("Frame") and c:FindFirstChildOfClass("ViewportFrame") then table.insert(cards, c) end
			end
			if #cards == 0 then return end
			table.sort(cards, function(a, b)
				local la, lb = a.LayoutOrder or 0, b.LayoutOrder or 0
				if la == lb then return a.Name < b.Name end
				return la < lb
			end)
			local pad = s(6)
			local usableWidth = LEFT_W - s(12) - scrollW
			local cardW = math.floor((usableWidth - pad*2 - s(6)) / 2)
			local thumbH = math.floor(cardW * 0.72)
			local cardH = pad + thumbH + s(2) + s(16) + s(2) + s(22) + pad
			for idx, c in ipairs(cards) do
				local col = (idx - 1) % 2; local row = math.floor((idx - 1) / 2)
				local posX = pad + col * (cardW + s(6))
				local posY = pad + row * (cardH + s(6))
				pcall(function() tween(c, {Position = UDim2.new(0, posX, 0, posY)}, 0.2) end)
			end
		end)
	else
		local last = math.min(renderedCount + ITEMS_PER_LOAD, #list)
		for i = renderedCount + 1, last do
			if myToken ~= renderToken then renderingMore = false; return end
			local item = list[i]
			if item then createBundleCard(item, i) end
		end
		renderedCount = last
	end

	if myToken ~= renderToken then renderingMore = false; return end
	renderingMore = false
	local st = getStatusText()
	if st then pageLbl.Text = st .. "  ·  " .. renderedCount .. "/" .. #list
	else pageLbl.Text = "Showing " .. renderedCount .. " of " .. #list end
	task.delay(0.15, function()
		if myToken ~= renderToken then return end
		if gridScroller.AbsoluteCanvasSize.Y <= gridScroller.AbsoluteWindowSize.Y + 40 then renderMore() end
	end)
end

executeSearch = function(query)
	clearGridFull(); local token = renderToken; query = query or ""
	if currentTab == "Emotes" then
		loadingOverlay.Visible = false; emoteFiltered = {}
		if emoteLoadStatus:find("Loading") then pageLbl.Text = "Loading emotes..."; return end
		local q = string.lower(query)
		for _, e in ipairs(emoteList) do
			if q == "" or string.find(string.lower(e.Name), q, 1, true) then table.insert(emoteFiltered, e) end
		end
		if #emoteFiltered == 0 then drawEmptyState("No emotes found", "Coba kata kunci lain.")
		else renderMore() end
		return
	end
	loadingOverlay.Visible = true; pageLbl.Text = "Loading..."
	if currentTab == "Saved" then
		savedTabList = {}; local q = string.lower(query)
		for _, v in pairs(savedBookmarks) do
			if q == "" or string.lower(v.Name):find(q, 1, true) then table.insert(savedTabList, v) end
		end
		table.sort(savedTabList, function(a,b)
			if a.Fav == b.Fav then return (a.Time or 0) > (b.Time or 0) end
			return a.Fav and not b.Fav
		end)
		loadingOverlay.Visible = false
		if #savedTabList == 0 then drawEmptyState("No Saved Animations", "Save animations to find them here.")
		else renderMore() end
	else
		searchResults, catalogCursor = {}, nil
		local p = CatalogSearchParams.new()
		p.SearchKeyword, p.BundleTypes, p.IncludeOffSale, p.Limit = query, {Enum.BundleType.Animations}, true, 120
		pcall(function() p.CreatorType = Enum.CreatorType.User end)
		pcall(function() p.SalesTypeFilter = Enum.SalesTypeFilter.All end)
		pcall(function() p.SortType = Enum.CatalogSortType.RecentlyCreated end)
		task.spawn(function()
			local ok, pages = pcall(function() return aes:SearchCatalog(p) end)
			if token ~= renderToken then return end
			loadingOverlay.Visible = false
			if ok and pages then
				catalogCursor = pages; searchResults = pages:GetCurrentPage()
				if #searchResults == 0 then drawEmptyState("No results found", "Try searching again.")
				else renderMore() end
			else
				pageLbl.Text = "Error"
				drawEmptyState("Search Error", "Coba lagi nanti.")
				showToast("Search error", "error")
			end
		end)
	end
end

gridScroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local y = gridScroller.CanvasPosition.Y
	local maxY = gridScroller.AbsoluteCanvasSize.Y - gridScroller.AbsoluteWindowSize.Y
	if maxY > 0 and y >= maxY - s(80) then renderMore() end
end)

-- ⭐ FIX UTAMA: update attribute biar warna tab ga balik setelah hover
refreshTabVisuals = function()
	local function paint(btn, active)
		if active then
			-- TAB DI-TAP = PUTIH (Dark) / HITAM (Light)
			btn.BackgroundColor3 = C.accent
			btn.BackgroundTransparency = 0
			btn.TextColor3 = C.onAccent
			btn:SetAttribute("_tk_BackgroundColor3", "accent")
			btn:SetAttribute("_tk_TextColor3", "onAccent")
		else
			-- TAB BELUM TAP = HITAM (Dark) / PUTIH (Light)
			btn.BackgroundColor3 = C.bg
			btn.BackgroundTransparency = 0
			btn.TextColor3 = C.text
			btn:SetAttribute("_tk_BackgroundColor3", "bg")
			btn:SetAttribute("_tk_TextColor3", "text")
		end
		local st = btn:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = 1 end
	end
	paint(tabDiscoverBtn, currentTab == "Discover")
	paint(tabSavedBtn, currentTab == "Saved")
	paint(tabEmoteBtn, currentTab == "Emotes")
end

local function setTab(tabName)
	if currentTab == tabName then return end
	renderingMore = false
	currentTab = tabName
	refreshTabVisuals()
	clearGridFull()
	executeSearch(sb.Text)
end

tabDiscoverBtn.MouseButton1Click:Connect(function() setTab("Discover") end)
tabSavedBtn.MouseButton1Click:Connect(function() setTab("Saved") end)
tabEmoteBtn.MouseButton1Click:Connect(function() setTab("Emotes") end)

wearSelectedBtn.MouseButton1Click:Connect(function()
	if not activeMasterType or not lp.Character then
		if not activeMasterType then showToast("Pilih slot animasi dulu", "warn") end
		return
	end
	wearSelectedBtn.Text = "Loading..."
	local okAll = pcall(function()
		local payload = currentBundleItems[string.lower(activeMasterType)]
		if not payload then return end
		local tracks = get(payload.Id, nil, payload.AssetType)
		local tPlay = getSpecificTrack(tracks, string.lower(activeMasterType))
		if tPlay then
			preloadAnimations({tPlay})
			local success = applyAnimationToCharacter(lp.Character, {tPlay}, activeMasterType)
			if success then showToast("Equipped " .. (shortNames[string.lower(activeMasterType)] or "animation"), "success")
			else showToast("Slot apply failed", "error") end
		else showToast("Failed to load", "error") end
	end)
	if not okAll then showToast("Equip error", "error") end
	wearSelectedBtn.Text = "Wear Selected"
end)

wearAllBtn.MouseButton1Click:Connect(function()
	if not lp.Character then return end
	wearAllBtn.Text = "Loading..."
	local result = applyBundleItemsToCharacter(currentBundleItems)
	if result.status == "no_character" then showToast("Character unavailable", "error")
	elseif result.status == "empty_bundle" or result.status == "no_usable_data" then showToast("No slots to equip", "warn")
	elseif result.status == "full_success" then showToast("Equipped full bundle (" .. result.succeeded .. " slots)", "success")
	elseif result.status == "partial" then showToast("Partial: " .. result.succeeded .. " ok, " .. result.failed .. " failed", "warn")
	elseif result.status == "full_failure" then showToast("Equip failed", "error") end
	wearAllBtn.Text = "Wear All"
end)

searchBtn.MouseButton1Click:Connect(function() executeSearch(sb.Text) end)
sb.FocusLost:Connect(function(enterPressed) if enterPressed then executeSearch(sb.Text) end end)

local applyTheme
applyTheme = function(newTheme, skipSave)
	if newTheme ~= "Dark" and newTheme ~= "Light" then newTheme = "Dark" end
	Theme = newTheme; syncC()
	local shimmersToRedo = {}
	for _, d in ipairs(gui:GetDescendants()) do
		local okA, attrs = pcall(function() return d:GetAttributes() end)
		if okA and attrs then
			for attrName, key in pairs(attrs) do
				if type(attrName) == "string" and attrName:sub(1,4) == "_tk_" and type(key) == "string" and C[key] then
					local pN = attrName:sub(5)
					pcall(function() d[pN] = C[key] end)
				end
			end
		end
		local favA = d:GetAttribute("_fav")
		if favA ~= nil then setIconColor(d, favA and C.fav or C.textMuted) end
		if d:IsA("UIGradient") then
			if d.Name == "CoolGrad" then
				d.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, C.surface),
					ColorSequenceKeypoint.new(0.5, C.panel),
					ColorSequenceKeypoint.new(1, C.bg)
				})
			elseif d.Name == "ShimmerGrad" then table.insert(shimmersToRedo, d) end
		end
	end
	for _, g in ipairs(shimmersToRedo) do
		local parent = g.Parent
		if parent then g:Destroy(); applyShimmer(parent, C.panel, C.surface) end
	end
	if mfEdge then mfEdge.Color = C.bg; mfEdge.Transparency = 1 end
	if refreshTabVisuals then refreshTabVisuals() end
	if refreshAnimButtonVisuals then refreshAnimButtonVisuals() end
	refreshBookmarkBtn()
	setIconName(themeBtn, (Theme == "Dark") and "sun" or "moon")
	if previewBorder then
		previewBorder.Image = (Theme == "Dark") and "rbxassetid://74516945382386" or "rbxassetid://108111145991423"
		previewBorder.Visible = true
		local fs = previewFrame:FindFirstChildOfClass("UIStroke")
		if fs then fs.Transparency = 0 end
		previewFrame.BackgroundTransparency = 0.4
		pollPreviewBorder()
	end
	if not skipSave then saveThemeToFile(Theme) end
end

local _themeBusy = false
themeBtn.MouseButton1Click:Connect(function()
	if _themeBusy then return end
	_themeBusy = true
	local nextT = (Theme == "Dark") and "Light" or "Dark"
	applyTheme(nextT)
	showToast("Theme: " .. nextT, "info")
	task.delay(0.3, function() _themeBusy = false end)
end)

setIconName(themeBtn, (Theme == "Dark") and "sun" or "moon")
refreshTabVisuals()
executeSearch("")

task.spawn(function()
	local t0 = tick()
	while emoteLoadStatus:find("Loading") and tick() - t0 < 30 do
		task.wait(0.3)
	end
	if currentTab == "Emotes" and #emoteFiltered == 0 and #emoteList > 0 then
		executeSearch(sb.Text)
	elseif currentTab == "Emotes" and emoteLoadStatus == "Fetch failed" then
		drawEmptyState("Emote source offline", "Coba lagi nanti.")
	end
end)

-- ⭐ FIX: variabel shimmerButtons yang tadinya kosong
local shimmerButtons = {
	searchBtn, resetBtn, soundBtn, themeBtn,
	tabDiscoverBtn, tabSavedBtn, tabEmoteBtn,
}
for _, btn in ipairs(shimmerButtons) do
	local sh = Shime.new(btn, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.5)
	sh:Play()
	table.insert(activeShimmers, sh)
end

print("[FE UGC Animations V2.7.6-OBSIDIAN-R2.6.4] Loaded -- @in66ar")
