--[[
FE UGC ANIMATIONS v2.2.0
Universal Animation Manager
Made By @in66ar

v2.2.0 CHANGES (audit + fix):  
  - Clear button uses ASCII "X" (no Unicode glyph)  
  - Search placeholder uses textDim for readable Light mode  
  - Clear button gets subtle background + hover (theme aware)  
  - Stroke theme binding on buttons (strokeKey)  
  - Version bumped to v2.2.0
  - Floating/minimize toggle drag fix (touch + mouse, custom UIS-based)

v2.1.0:  
  - Dark Mode (default, graphite)  
  - Light Mode (off-white / charcoal)  
  - Theme switching (real-time)  
  - Theme persistence (FE_UGC_Animations_Theme.json)

]]

local plrs = game:GetService("Players")
local as = game:GetService("AssetService")
local aes = game:GetService("AvatarEditorService")
local rs = game:GetService("RunService")
local hs = game:GetService("HttpService")
local cp = game:GetService("ContentProvider")
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local lp = plrs.LocalPlayer

local m = {
["runanimation"]      = "run",
["climbanimation"]    = "climb",
["jumpanimation"]     = "jump",
["fallanimation"]     = "fall",
["idleanimation"]     = "idle",
["swimidleanimation"] = "swimidle",
["swimanimation"]     = "swim",
["walkanimation"]     = "walk"
}

local shortNames = {
["idleanimation"]     = "Idle",
["walkanimation"]     = "Walk",
["runanimation"]      = "Run",
["jumpanimation"]     = "Jump",
["fallanimation"]     = "Fall",
["climbanimation"]    = "Climb",
["swimidleanimation"] = "S.Idle",
["swimanimation"]     = "Swim"
}

local buttonOrder = {
"idleanimation",
"walkanimation",
"runanimation",
"jumpanimation",
"fallanimation",
"climbanimation",
"swimidleanimation",
"swimanimation"
}

-- Safe unicode icon bytes, built via string.char so the source file's own
-- encoding can never corrupt these glyphs (avoids the "mojibake" issue).
local function uchr(...) return string.char(...) end
local ICO_BACK      = uchr(226,134,144) -- ←
local ICO_NEXT      = uchr(226,134,146) -- →
local ICO_STAR_ON   = uchr(226,152,133) -- ★
local ICO_STAR_OFF  = uchr(226,152,134) -- ☆
local ICO_CHECK     = uchr(226,156,147) -- ✓
local ICO_PLAY      = uchr(226,150,182) -- ▶
local ICO_DOTS      = uchr(226,128,166) -- …
local ICO_DOT       = uchr(226,128,162) -- •
-- NOTE: Clear button deliberately uses ASCII "X" instead of a Unicode glyph.

local CACHE_FILE_NAME = "animation_bundle_data_cache.json"
local ANIM_CACHE_URL = "https://raw.githubusercontent.com/TribalFootball/TuffTeto/main/animation_bundle_data_cache.json"
local SEEN_BUNDLES_FILE = "seen_anim_bundles_cache.json"
local EQUIPPED_FILE = "FeUgcAnim.json"
local SAVED_BUNDLES_FILE = "FeUgcAnim_Bookmarks.json"
local THEME_FILE = "FE_UGC_Animations_Theme.json"

-- ============================================================
-- THEME SYSTEM
-- ============================================================

local Themes = {
Dark = {
bg         = Color3.fromRGB(17, 18, 20),
panel      = Color3.fromRGB(23, 24, 27),
surface    = Color3.fromRGB(30, 31, 35),
surfaceHi  = Color3.fromRGB(40, 41, 45),
stroke     = Color3.fromRGB(55, 56, 61),

accent     = Color3.fromRGB(185, 188, 193),
accentDim  = Color3.fromRGB(105, 108, 114),

green      = Color3.fromRGB(135, 165, 145),
fav        = Color3.fromRGB(190, 170, 115),

text       = Color3.fromRGB(238, 238, 236),
textDim    = Color3.fromRGB(165, 166, 169),
textMuted  = Color3.fromRGB(105, 106, 110),
subtitle   = Color3.fromRGB(125, 126, 130),

overlay    = Color3.fromRGB(10, 11, 13),
onAccent   = Color3.fromRGB(20, 22, 26),
},
Light = {
bg         = Color3.fromRGB(245, 245, 243),
panel      = Color3.fromRGB(238, 238, 236),
surface    = Color3.fromRGB(230, 230, 228),
surfaceHi  = Color3.fromRGB(218, 218, 215),
stroke     = Color3.fromRGB(200, 200, 197),

accent     = Color3.fromRGB(75, 77, 80),
accentDim  = Color3.fromRGB(125, 127, 130),

green      = Color3.fromRGB(95, 130, 108),
fav        = Color3.fromRGB(145, 125, 75),

text       = Color3.fromRGB(25, 26, 28),
textDim    = Color3.fromRGB(90, 91, 94),
textMuted  = Color3.fromRGB(135, 136, 139),
subtitle   = Color3.fromRGB(105, 106, 109),

overlay    = Color3.fromRGB(235, 235, 232),
onAccent   = Color3.fromRGB(245, 245, 243),
}
}

local Theme = "Dark"

local function loadThemeFromFile()
local ok, content = pcall(function()
if isfile and not isfile(THEME_FILE) then return nil end
return readfile(THEME_FILE)
end)
if ok and content then
local suc, decoded = pcall(function() return hs:JSONDecode(content) end)
if suc and decoded and type(decoded) == "table" then
local t = decoded.theme
if t == "Dark" or t == "Light" then
return t
end
end
end
return "Dark"
end

local function saveThemeToFile(themeName)
pcall(function()
if writefile then
writefile(THEME_FILE, hs:JSONEncode({theme = themeName}))
end
end)
end

Theme = loadThemeFromFile()

-- C is the single source of truth for current theme colors.
-- It is kept in sync with Themes[Theme] via syncC().
local C = {}
local function syncC()
for k, v in pairs(Themes[Theme]) do
C[k] = v
end
end
syncC()

-- ============================================================
-- CACHE / FILE HELPERS
-- ============================================================

local assetCache, fileCache, seenBundles, equippedAnims = {}, {}, {}, {}
local savedBookmarks = {}

local function loadJSON(file)
local ok, content = pcall(function()
if isfile and not isfile(file) then return nil end
return readfile(file)
end)
if ok and content then
local suc, decoded = pcall(function() return hs:JSONDecode(content) end)
return suc and decoded or {}
end
return {}
end

local function saveJSON(file, data)
pcall(function() writefile(file, hs:JSONEncode(data)) end)
end

fileCache = loadJSON(CACHE_FILE_NAME)
seenBundles = loadJSON(SEEN_BUNDLES_FILE)
equippedAnims = loadJSON(EQUIPPED_FILE)
savedBookmarks = loadJSON(SAVED_BUNDLES_FILE)

task.spawn(function()
local ok, onlineContent = pcall(function() return game:HttpGet(ANIM_CACHE_URL) end)
if ok and onlineContent then
pcall(function()
local onlineData = hs:JSONDecode(onlineContent)
for k, v in pairs(onlineData) do if not fileCache[k] then fileCache[k] = v end end
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
			for _, animData in ipairs(animList) do  
				local newAnim = Instance.new("Animation", folder)  
				newAnim.Name = animData.Name  
				newAnim.AnimationId = animData.AnimationId  
			end  
		end  
	end  
end  

task.wait(0.05)  
animate.Disabled = false

end

local function initAutoEquip(char)
if not char then return end
task.spawn(function()
local animate = char:WaitForChild("Animate", 5)
local human = char:WaitForChild("Humanoid", 5)

if animate and human then  
		local idleFolder = animate:WaitForChild("idle", 5)  
		if idleFolder then  
			idleFolder:WaitForChild("Animation1", 3)  
		end  

		task.wait(0.1)  
		applySavedAnimations(char)  
	end  
end)

end

if lp.Character then
initAutoEquip(lp.Character)
end

lp.CharacterAdded:Connect(initAutoEquip)

local function get(id, bundleId, assetType)
local stringId = tostring(id)
if assetCache[stringId] then return assetCache[stringId] end
if fileCache[stringId] then
local reconstructed = {}
for _, data in ipairs(fileCache[stringId]) do
local anim = Instance.new("Animation")
anim.Name, anim.AnimationId = data.Name, data.AnimationId
table.insert(reconstructed, anim)
end
assetCache[stringId] = reconstructed
return reconstructed
end

local t, serializableData = {}, {}  
local descProp = "IdleAnimation"  
local lowerType = assetType and string.lower(assetType) or ""  

if lowerType:find("idle") and not lowerType:find("swim") then descProp = "IdleAnimation"  
elseif lowerType:find("walk") then descProp = "WalkAnimation"  
elseif lowerType:find("run") then descProp = "RunAnimation"  
elseif lowerType:find("jump") then descProp = "JumpAnimation"  
elseif lowerType:find("fall") then descProp = "FallAnimation"  
elseif lowerType:find("climb") then descProp = "ClimbAnimation"  
elseif lowerType:find("swim") then descProp = "SwimAnimation"  
end  

pcall(function()  
	local desc = Instance.new("HumanoidDescription")  
	desc[descProp] = tonumber(id)  
	local dummy = plrs:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)  
	local animate = dummy:FindFirstChild("Animate")  
	if animate then  
		local targetFolders = (descProp == "SwimAnimation") and {"swim", "swimidle"} or {string.lower(string.gsub(descProp, "Animation", ""))}  
		for _, folderName in ipairs(targetFolders) do  
			local folder = animate:FindFirstChild(folderName)  
			if folder then  
				for _, child in ipairs(folder:GetChildren()) do  
					if child:IsA("Animation") and child.AnimationId ~= "" then  
						local clone = child:Clone()  
						table.insert(t, clone)  
						table.insert(serializableData, { Name = clone.Name, AnimationId = clone.AnimationId, BundleId = tostring(bundleId) })  
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
			local function processItem(item)  
				if item:IsA("Animation") then  
					table.insert(t, item:Clone())  
					table.insert(serializableData, { Name = item.Name, AnimationId = item.AnimationId, BundleId = tostring(bundleId) })  
				end  
			end  
			processItem(objs[1])  
			for _, c in ipairs(objs[1]:GetDescendants()) do processItem(c) end  
		end  
	end)  
end  

assetCache[stringId] = t  
fileCache[stringId] = serializableData  
saveJSON(CACHE_FILE_NAME, fileCache)  
return t

end

local function clearAssetCache(id)
local stringId = tostring(id)
assetCache[stringId], fileCache[stringId] = nil, nil
saveJSON(CACHE_FILE_NAME, fileCache)
end

-- ============================================================
-- UI FOUNDATION
-- ============================================================

local vp = workspace.CurrentCamera.ViewportSize
local scale = math.clamp(math.min(vp.X / 1920, vp.Y / 1080), 0.55, 3.0) * 1.45
local function s(n) return math.round(n * scale) end

-- corner radii (consistent scale)
local R_MAIN    = s(12)
local R_PANEL   = s(8)
local R_CARD    = s(8)
local R_BUTTON  = s(6)
local R_INPUT   = s(6)
local R_SMALL   = s(4)

local PAD_TOP = s(44)
local PAD_SIDES = s(14)
local W, H = s(540), s(365)
local INNER_W = W - (PAD_SIDES * 2)
local LEFT_W = s(268)
local RIGHT_W = INNER_W - LEFT_W - s(1)

local scrollW = s(4)
local FOOT_H = s(28)
local VP_H = s(138)
local MIN_BTN_SIZE = s(60)
local UI_BUSY = false
local TOGGLE_COOLDOWN = 0.15

-- ---------- helpers ----------

local function tween(obj, props, duration, style, direction)
local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
local t = ts:Create(obj, info, props)
t:Play()
return t
end

local function createCorner(parent, radius)
local cr = Instance.new("UICorner", parent)
cr.CornerRadius = UDim.new(0, radius or R_SMALL)
return cr
end

local function createStroke(parent, color, thickness, transparency, themeKey)
local st = Instance.new("UIStroke", parent)
st.Color = color or C.stroke
st.Thickness = thickness or 1
st.Transparency = transparency or 0
if themeKey then
st:SetAttribute("_tk_Color", themeKey)
if C[themeKey] then
pcall(function() st.Color = C[themeKey] end)
end
end
return st
end

-- Tag helper: registers a theme binding on an instance.
-- Attr name pattern: "_tk_<PropertyName>" -> theme key
local function tagTheme(inst, prop, key)
if not inst or not prop or not key then return inst end
inst:SetAttribute("_tk_" .. prop, key)
if C[key] then
pcall(function() inst[prop] = C[key] end)
end
return inst
end

local function applyCoolGradient(parent)
local existing = parent:FindFirstChild("CoolGrad")
if existing then existing:Destroy() end
local grad = Instance.new("UIGradient", parent)
grad.Name = "CoolGrad"
grad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, C.surface),
ColorSequenceKeypoint.new(0.5, C.panel),
ColorSequenceKeypoint.new(1, C.bg)
})
grad.Rotation = 60
return grad
end

local function applyShimmer(obj, colorStart, colorMid)
local existing = obj:FindFirstChild("ShimmerGrad")
if existing then existing:Destroy() end
local grad = Instance.new("UIGradient", obj)
grad.Name = "ShimmerGrad"
grad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, colorStart),
ColorSequenceKeypoint.new(0.5, colorMid),
ColorSequenceKeypoint.new(1, colorStart)
})
grad.Rotation = 35
grad.Offset = Vector2.new(-1, 0)

local tw = ts:Create(grad, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Offset = Vector2.new(1, 0)})  
tw:Play()

end

local function removeShimmer(obj)
local g2 = obj:FindFirstChild("ShimmerGrad")
if g2 then g2:Destroy() end
end

local function createLabel(parent, props)
local lbl = Instance.new("TextLabel", parent)
lbl.BackgroundTransparency = 1
lbl.Font = props.font or Enum.Font.Gotham
lbl.Text = props.text or ""
lbl.TextSize = props.size or s(11)
lbl.TextColor3 = props.color or C.text
lbl.TextXAlignment = props.align or Enum.TextXAlignment.Center
lbl.Size = props.uiSize or UDim2.new(1, 0, 1, 0)
lbl.Position = props.pos or UDim2.new(0, 0, 0, 0)
lbl.ClipsDescendants = true
if props.textKey then
tagTheme(lbl, "TextColor3", props.textKey)
end
return lbl
end

local function createButton(parent, props)
local btn = Instance.new("TextButton", parent)
btn.Size = props.uiSize or UDim2.new(0, s(80), 0, s(26))
btn.Position = props.pos or UDim2.new(0, 0, 0, 0)
btn.BackgroundColor3 = props.bg or C.surfaceHi
btn.BackgroundTransparency = props.bgTransparency or 0
btn.Text = props.text or ""
btn.TextColor3 = props.color or C.text
btn.Font = props.font or Enum.Font.GothamBold
btn.TextSize = props.size or s(11)
btn.ClipsDescendants = true
btn.AutoButtonColor = false
createCorner(btn, props.radius or R_BUTTON)
if props.strokeColor or props.strokeKey then
createStroke(btn, props.strokeColor or C.stroke, 1, nil, props.strokeKey)
end

if props.bgKey then tagTheme(btn, "BackgroundColor3", props.bgKey) end  
if props.textKey then tagTheme(btn, "TextColor3", props.textKey) end  

local function getBase()  
	if props.bgKey and C[props.bgKey] then return C[props.bgKey] end  
	return props.bg or C.surfaceHi  
end  

btn.MouseEnter:Connect(function()  
	local target = props.hoverBg or getBase():Lerp(Color3.new(1,1,1), 0.06)  
	tween(btn, {BackgroundColor3 = target}, 0.12)  
end)  
btn.MouseLeave:Connect(function()  
	tween(btn, {BackgroundColor3 = getBase()}, 0.12)  
end)  
btn.MouseButton1Down:Connect(function() tween(btn, {Size = (props.uiSize or btn.Size) - UDim2.new(0,0,0,1)}, 0.06) end)  
btn.MouseButton1Up:Connect(function() tween(btn, {Size = props.uiSize or btn.Size}, 0.08) end)  

return btn

end

-- ============================================================
-- ROOT GUI
-- ============================================================

local gp = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
if gp:FindFirstChild("StudioAnimStudio") then gp.StudioAnimStudio:Destroy() end

local g = Instance.new("ScreenGui", gp)
g.Name = "StudioAnimStudio"
g.ResetOnSpawn = false
if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end

local mf = Instance.new("CanvasGroup", g)
mf.Size, mf.Position, mf.AnchorPoint = UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5)
mf.BackgroundColor3, mf.BackgroundTransparency = C.bg, 0.02
mf.GroupTransparency = 1
mf.Active, mf.Draggable = true, true
tagTheme(mf, "BackgroundColor3", "bg")
createCorner(mf, R_MAIN)
applyCoolGradient(mf)
createStroke(mf, C.stroke, 1, 0.15, "stroke")

local mfPad = Instance.new("UIPadding", mf)
mfPad.PaddingTop = UDim.new(0, PAD_TOP)
mfPad.PaddingBottom = UDim.new(0, PAD_SIDES)
mfPad.PaddingLeft = UDim.new(0, PAD_SIDES)
mfPad.PaddingRight = UDim.new(0, PAD_SIDES)

task.delay(0.1, function()
tween(mf, {Size = UDim2.new(0, W, 0, H), GroupTransparency = 0}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

-- ---------- minimized pill ----------

local minBtn = Instance.new("CanvasGroup", g)
minBtn.Size, minBtn.Position, minBtn.AnchorPoint = UDim2.new(0, 0, 0, 0), UDim2.new(1, -s(40), 0, s(30)), Vector2.new(0.5, 0.5)
minBtn.BackgroundTransparency = 1
minBtn.GroupTransparency = 1
minBtn.Visible = false
-- Custom drag below: disable built-in Draggable so it doesn't fight with
-- our InputBegan/InputChanged tracking (smoother on mobile).
minBtn.Active, minBtn.Draggable, minBtn.ClipsDescendants = true, false, true

local minBtnBg = Instance.new("Frame", minBtn)
minBtnBg.Size, minBtnBg.BackgroundColor3, minBtnBg.BorderSizePixel = UDim2.new(1, 0, 1, 0), C.panel, 0
tagTheme(minBtnBg, "BackgroundColor3", "panel")
local minBtnCorner = Instance.new("UICorner", minBtnBg)
minBtnCorner.CornerRadius = UDim.new(0.5, 0)
local minBtnStroke = createStroke(minBtnBg, C.stroke, 1, 0.2, "stroke")
applyCoolGradient(minBtnBg)

local minBtnLabel = createLabel(minBtn, {
text = "UGC", font = Enum.Font.GothamBlack, size = s(13), textKey = "text"
})

local minBtnHit = Instance.new("TextButton", minBtn)
minBtnHit.Size, minBtnHit.BackgroundTransparency, minBtnHit.Text, minBtnHit.ClipsDescendants = UDim2.new(1, 0, 1, 0), 1, "", true

-- ============================================================
-- FLOATING / MINIMIZE TOGGLE — CUSTOM DRAG (touch + mouse)
-- ============================================================
-- Uses UserInputService global InputChanged/InputEnded so the drag
-- keeps tracking even when the pointer leaves the button (fast swipes).
-- Tap (no movement past threshold) still restores the UI.
do
	local drag = {
		active = false,
		moved = false,
		dragStart = nil,
		startPos = nil,
	}

	local DRAG_THRESHOLD = 4

	local function beginDrag(input)
		drag.active = true
		drag.moved = false
		drag.dragStart = input.Position
		drag.startPos = minBtn.Position
	end

	local function updateDrag(input)
		if not drag.active or not drag.dragStart or not drag.startPos then return end
		local delta = input.Position - drag.dragStart
		if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
			drag.moved = true
		end
		local camera = workspace.CurrentCamera
		local vpSize = (camera and camera.ViewportSize) or Vector2.new(1920, 1080)
		local absX = drag.startPos.X.Scale * vpSize.X + drag.startPos.X.Offset + delta.X
		local absY = drag.startPos.Y.Scale * vpSize.Y + drag.startPos.Y.Offset + delta.Y
		-- Clamp to screen so the pill can never leave the viewport.
		local halfW = minBtn.AbsoluteSize.X * 0.5
		local halfH = minBtn.AbsoluteSize.Y * 0.5
		if halfW < 1 then halfW = MIN_BTN_SIZE * 0.5 end
		if halfH < 1 then halfH = MIN_BTN_SIZE * 0.5 end
		absX = math.clamp(absX, halfW, vpSize.X - halfW)
		absY = math.clamp(absY, halfH, vpSize.Y - halfH)
		minBtn.Position = UDim2.new(0, absX, 0, absY)
	end

	local function endDrag()
		drag.active = false
	end

	minBtnHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	uis.InputChanged:Connect(function(input)
		if not drag.active then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	uis.InputEnded:Connect(function(input)
		if not drag.active then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)

	minBtnHit.MouseButton1Click:Connect(function()
		-- Swallow click that was actually a drag.
		if drag.moved then
			drag.moved = false
			return
		end
		if UI_BUSY then return end
		UI_BUSY = true

		minBtn.Visible = false
		minBtn.GroupTransparency = 1
		minBtn.Size = UDim2.new(0, 0, 0, 0)

		mf.Size = UDim2.new(0, W, 0, H)
		mf.GroupTransparency = 0
		mf.Visible = true

		task.wait(TOGGLE_COOLDOWN)
		UI_BUSY = false
	end)
end

-- ---------- header ----------

local headerBar = Instance.new("Frame", mf)
headerBar.Size = UDim2.new(1, 0, 0, PAD_TOP - s(6))
headerBar.Position = UDim2.new(0, 0, 0, -PAD_TOP)
headerBar.BackgroundTransparency = 1

local titleLbl = createLabel(headerBar, {
text = "FE UGC ANIMATIONS",
font = Enum.Font.GothamBlack,
size = s(16),
align = Enum.TextXAlignment.Left,
uiSize = UDim2.new(1, -s(170), 0, s(17)),
pos = UDim2.new(0, s(2), 0, s(2)),
textKey = "text"
})

local subtitleLbl = createLabel(headerBar, {
text = "by @in66ar v2.2.0",
font = Enum.Font.GothamMedium,
size = s(11),
align = Enum.TextXAlignment.Left,
uiSize = UDim2.new(1, -s(170), 0, s(15)),
pos = UDim2.new(0, s(2), 0, s(20)),
textKey = "subtitle"
})

-- Theme toggle button (text-only: LIGHT / DARK)
local themeBtn = createButton(headerBar, {
uiSize = UDim2.new(0, s(50), 0, s(24)),
pos = UDim2.new(1, -s(106), 0, s(2)),
bgKey = "surface",
bgTransparency = 0.25,
text = (Theme == "Dark") and "LIGHT" or "DARK",
textKey = "textDim",
font = Enum.Font.GothamBold,
size = s(9),
radius = R_BUTTON
})

local minWindowBtn = createButton(headerBar, {
uiSize = UDim2.new(0, s(24), 0, s(24)),
pos = UDim2.new(1, -s(52), 0, s(2)),
bgKey = "surface",
bgTransparency = 0.25,
text = "-",
textKey = "textDim",
font = Enum.Font.GothamBold,
size = s(16),
radius = R_BUTTON
})

local closeWindowBtn = createButton(headerBar, {
uiSize = UDim2.new(0, s(24), 0, s(24)),
pos = UDim2.new(1, -s(24), 0, s(2)),
bgKey = "surface",
bgTransparency = 0.25,
text = "X",
textKey = "textDim",
font = Enum.Font.GothamBold,
size = s(12),
radius = R_BUTTON,
hoverBg = Color3.fromRGB(70, 45, 45)
})

closeWindowBtn.MouseButton1Click:Connect(function()
tween(mf, {GroupTransparency = 1, Size = UDim2.new(0,0,0,0)}, 0.2)
tween(minBtn, {GroupTransparency = 1}, 0.2)
task.delay(0.22, function() g:Destroy() end)
end)

minWindowBtn.MouseButton1Click:Connect(function()
if UI_BUSY then return end
UI_BUSY = true

mf.Visible = false  
mf.GroupTransparency = 1  
mf.Size = UDim2.new(0, 0, 0, 0)  

minBtn.Size = UDim2.new(0, MIN_BTN_SIZE, 0, MIN_BTN_SIZE)  
minBtn.GroupTransparency = 0  
minBtn.Visible = true  

task.wait(TOGGLE_COOLDOWN)  
UI_BUSY = false

end)

-- ---------- left panel ----------

local lp_frame = Instance.new("Frame", mf)
lp_frame.Size, lp_frame.Position, lp_frame.BackgroundTransparency = UDim2.new(0, LEFT_W, 1, 0), UDim2.new(0, 0, 0, 0), 1

local header = Instance.new("Frame", lp_frame)
header.Size, header.Position, header.BackgroundTransparency = UDim2.new(1, -s(8), 0, s(26)), UDim2.new(0, s(4), 0, s(2)), 1

local tabDiscoverBtn = createButton(header, {
uiSize = UDim2.new(0.48, 0, 1, 0), pos = UDim2.new(0, 0, 0, 0),
text = "Discover", font = Enum.Font.GothamBold, size = s(11),
bgKey = "surfaceHi", textKey = "text", radius = R_BUTTON
})

local tabSavedBtn = createButton(header, {
uiSize = UDim2.new(0.48, 0, 1, 0), pos = UDim2.new(0.52, 0, 0, 0),
text = "Saved", font = Enum.Font.GothamBold, size = s(11),
bgKey = "surface", bgTransparency = 0.3, textKey = "textMuted", radius = R_BUTTON
})

local tabDiscoverUnderline = Instance.new("Frame", tabDiscoverBtn)
tabDiscoverUnderline.Size = UDim2.new(0.5, 0, 0, s(2))
tabDiscoverUnderline.Position = UDim2.new(0.25, 0, 1, -s(2))
tabDiscoverUnderline.BackgroundColor3 = C.accent
tabDiscoverUnderline.BorderSizePixel = 0
tabDiscoverUnderline.Visible = true
tagTheme(tabDiscoverUnderline, "BackgroundColor3", "accent")
createCorner(tabDiscoverUnderline, s(2))

local tabSavedUnderline = Instance.new("Frame", tabSavedBtn)
tabSavedUnderline.Size = UDim2.new(0.5, 0, 0, s(2))
tabSavedUnderline.Position = UDim2.new(0.25, 0, 1, -s(2))
tabSavedUnderline.BackgroundColor3 = C.accent
tabSavedUnderline.BorderSizePixel = 0
tabSavedUnderline.Visible = false
tagTheme(tabSavedUnderline, "BackgroundColor3", "accent")
createCorner(tabSavedUnderline, s(2))

local searchRow = Instance.new("Frame", lp_frame)
searchRow.Size, searchRow.Position, searchRow.BackgroundTransparency = UDim2.new(1, -s(8), 0, s(28)), UDim2.new(0, s(4), 0, s(60)), 1

local sb = Instance.new("TextBox", searchRow)
sb.Size, sb.PlaceholderText, sb.Text = UDim2.new(1, -s(60), 1, 0), "Search animations...", ""
sb.BackgroundColor3, sb.BackgroundTransparency, sb.TextColor3, sb.ClipsDescendants = C.surface, 0.1, C.text, true
sb.PlaceholderColor3 = C.textDim
sb.Font, sb.TextSize = Enum.Font.Gotham, s(11)
sb.TextXAlignment = Enum.TextXAlignment.Left
sb.ClearTextOnFocus = false
createCorner(sb, R_INPUT)
tagTheme(sb, "BackgroundColor3", "surface")
tagTheme(sb, "TextColor3", "text")
tagTheme(sb, "PlaceholderColor3", "textDim")
local sbStroke = createStroke(sb, C.stroke, 1, 0.2, "stroke")
local sbPad = Instance.new("UIPadding", sb)
sbPad.PaddingLeft = UDim.new(0, s(8))
sbPad.PaddingRight = UDim.new(0, s(22))

-- clear button (subtle, only visible when search has text)
local clearSearchBtn = Instance.new("TextButton", sb)
clearSearchBtn.Size = UDim2.new(0, s(16), 0, s(16))
clearSearchBtn.Position = UDim2.new(1, -s(20), 0.5, -s(8))
clearSearchBtn.BackgroundColor3 = C.surfaceHi
clearSearchBtn.BackgroundTransparency = 0.15
clearSearchBtn.Text = "X"
clearSearchBtn.TextColor3 = C.textDim
clearSearchBtn.Font = Enum.Font.GothamBold
clearSearchBtn.TextSize = s(10)
clearSearchBtn.AutoButtonColor = false
clearSearchBtn.Visible = false
clearSearchBtn.ZIndex = 3
createCorner(clearSearchBtn, R_SMALL)
tagTheme(clearSearchBtn, "BackgroundColor3", "surfaceHi")
tagTheme(clearSearchBtn, "TextColor3", "textDim")

clearSearchBtn.MouseEnter:Connect(function()
local base = C.surfaceHi
tween(clearSearchBtn, {BackgroundColor3 = base:Lerp(Color3.new(1,1,1), 0.10)}, 0.12)
end)
clearSearchBtn.MouseLeave:Connect(function()
tween(clearSearchBtn, {BackgroundColor3 = C.surfaceHi}, 0.12)
end)

clearSearchBtn.MouseButton1Click:Connect(function()
sb.Text = ""
clearSearchBtn.Visible = false
end)

sb:GetPropertyChangedSignal("Text"):Connect(function()
clearSearchBtn.Visible = (#sb.Text > 0)
end)

sb.Focused:Connect(function() tween(sbStroke, {Color = C.accentDim, Transparency = 0}, 0.15) end)
sb.FocusLost:Connect(function() tween(sbStroke, {Color = C.stroke, Transparency = 0.2}, 0.15) end)

local searchBtn = createButton(searchRow, {
uiSize = UDim2.new(0, s(54), 1, 0), pos = UDim2.new(1, -s(54), 0, 0),
text = "Search", bgKey = "surfaceHi", textKey = "text",
font = Enum.Font.GothamBold, size = s(11), radius = R_INPUT,
strokeColor = C.stroke, strokeKey = "stroke"
})

local gridScroller = Instance.new("ScrollingFrame", lp_frame)
gridScroller.Size, gridScroller.Position = UDim2.new(1, -s(8), 1, -s(128)), UDim2.new(0, s(4), 0, s(94))
gridScroller.BackgroundColor3, gridScroller.BackgroundTransparency, gridScroller.BorderSizePixel = C.panel, 0.35, 0
gridScroller.ScrollBarThickness = scrollW
gridScroller.ScrollBarImageColor3 = C.accentDim
gridScroller.ScrollBarImageTransparency = 0.4
tagTheme(gridScroller, "BackgroundColor3", "panel")
tagTheme(gridScroller, "ScrollBarImageColor3", "accentDim")
createCorner(gridScroller, R_PANEL)
createStroke(gridScroller, C.stroke, 1, 0.35, "stroke")

local loadingOverlay = Instance.new("TextLabel", lp_frame)
loadingOverlay.Size, loadingOverlay.Position = gridScroller.Size, gridScroller.Position
loadingOverlay.BackgroundColor3, loadingOverlay.BackgroundTransparency, loadingOverlay.ZIndex = C.bg, 0.15, 10
loadingOverlay.Text, loadingOverlay.TextColor3, loadingOverlay.Font, loadingOverlay.ClipsDescendants = "Loading...", C.textDim, Enum.Font.GothamBold, true
loadingOverlay.TextSize = s(11)
loadingOverlay.Visible = false
tagTheme(loadingOverlay, "BackgroundColor3", "bg")
tagTheme(loadingOverlay, "TextColor3", "textDim")
createCorner(loadingOverlay, R_PANEL)
applyShimmer(loadingOverlay, C.panel, C.surfaceHi)

local footer = Instance.new("Frame", lp_frame)
footer.Size, footer.Position, footer.BackgroundTransparency = UDim2.new(1, -s(8), 0, FOOT_H), UDim2.new(0, s(4), 1, -FOOT_H), 1

local prevBtn = createButton(footer, {
uiSize = UDim2.new(0, s(54), 1, 0), pos = UDim2.new(0, 0, 0, 0),
text = ICO_BACK .. " Back", bgKey = "surface", bgTransparency = 0.15, textKey = "textDim",
font = Enum.Font.GothamBold, size = s(10), radius = R_BUTTON,
strokeColor = C.stroke, strokeKey = "stroke"
})

local pageLbl = createLabel(footer, {
text = "Page 1", font = Enum.Font.Gotham, size = s(10), textKey = "textDim",
uiSize = UDim2.new(1, -s(118), 1, 0), pos = UDim2.new(0, s(59), 0, 0)
})

local nextBtn = createButton(footer, {
uiSize = UDim2.new(0, s(54), 1, 0), pos = UDim2.new(1, -s(54), 0, 0),
text = "Next " .. ICO_NEXT, bgKey = "surface", bgTransparency = 0.15, textKey = "textDim",
font = Enum.Font.GothamBold, size = s(10), radius = R_BUTTON,
strokeColor = C.stroke, strokeKey = "stroke"
})

local divider = Instance.new("Frame", mf)
divider.Size, divider.Position, divider.BackgroundColor3 = UDim2.new(0, 1, 1, 0), UDim2.new(0, LEFT_W + s(6), 0, 0), C.stroke
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
tagTheme(divider, "BackgroundColor3", "stroke")

-- ---------- right panel ----------

local rp = Instance.new("Frame", mf)
rp.Size, rp.Position, rp.BackgroundTransparency = UDim2.new(0, RIGHT_W - s(6), 1, 0), UDim2.new(0, LEFT_W + s(12), 0, 0), 1

local previewLbl = createLabel(rp, {
text = "PREVIEW", font = Enum.Font.GothamBold, size = s(9),
align = Enum.TextXAlignment.Left,
uiSize = UDim2.new(1, 0, 0, s(10)), pos = UDim2.new(0, s(2), 0, 0),
textKey = "textMuted"
})

local masterViewport = Instance.new("ViewportFrame", rp)
masterViewport.Size, masterViewport.Position = UDim2.new(1, 0, 0, VP_H), UDim2.new(0, 0, 0, s(12))
masterViewport.BackgroundColor3, masterViewport.BackgroundTransparency = C.overlay, 0.05
tagTheme(masterViewport, "BackgroundColor3", "overlay")
createCorner(masterViewport, R_CARD)
createStroke(masterViewport, C.stroke, 1, 0.2, "stroke")

local statusFrame = Instance.new("Frame", rp)
statusFrame.Size, statusFrame.Position = UDim2.new(1, 0, 0, s(26)), UDim2.new(0, 0, 0, VP_H + s(18))
statusFrame.BackgroundColor3, statusFrame.BackgroundTransparency = C.surface, 0.3
tagTheme(statusFrame, "BackgroundColor3", "surface")
createCorner(statusFrame, R_BUTTON)
createStroke(statusFrame, C.stroke, 1, 0.4, "stroke")

local statusLabel = createLabel(statusFrame, {
text = "No bundle selected", font = Enum.Font.GothamSemibold, size = s(10),
align = Enum.TextXAlignment.Left,
uiSize = UDim2.new(1, -s(14), 1, 0), pos = UDim2.new(0, s(7), 0, 0),
textKey = "textDim"
})

local buttonContainer = Instance.new("Frame", rp)
buttonContainer.Size, buttonContainer.Position = UDim2.new(1, 0, 0, s(48)), UDim2.new(0, 0, 0, VP_H + s(50))
buttonContainer.BackgroundTransparency = 1
local gridBtnLayout = Instance.new("UIGridLayout", buttonContainer)
local btnW = math.floor((RIGHT_W - s(6) - s(12)) / 4)
gridBtnLayout.CellSize, gridBtnLayout.CellPadding = UDim2.new(0, btnW, 0, s(21)), UDim2.new(0, s(4), 0, s(4))

local actRow = Instance.new("Frame", rp)
actRow.Size, actRow.Position, actRow.BackgroundTransparency = UDim2.new(1, 0, 0, s(64)), UDim2.new(0, 0, 1, -s(64)), 1

local bookmarkBtn = createButton(actRow, {
uiSize = UDim2.new(1, 0, 0, s(24)), pos = UDim2.new(0, 0, 0, 0),
text = "Save to Saved Tab", bgKey = "panel", bgTransparency = 0.05, textKey = "textMuted",
font = Enum.Font.GothamBold, size = s(10), radius = R_BUTTON,
strokeColor = C.stroke, strokeKey = "stroke"
})
bookmarkBtn.Visible = false

local wearSelectedBtn = createButton(actRow, {
uiSize = UDim2.new(0.48, 0, 0, s(30)), pos = UDim2.new(0, 0, 1, -s(30)),
text = "Wear Selected", bgKey = "surfaceHi", textKey = "text",
font = Enum.Font.GothamBold, size = s(10), radius = R_BUTTON,
strokeColor = C.stroke, strokeKey = "stroke"
})
wearSelectedBtn.Visible = false

local wearAllBtn = createButton(actRow, {
uiSize = UDim2.new(0.48, 0, 0, s(30)), pos = UDim2.new(0.52, 0, 1, -s(30)),
text = "Wear All", bgKey = "surface", bgTransparency = 0.1, textKey = "text",
font = Enum.Font.GothamBold, size = s(10), radius = R_BUTTON,
strokeColor = C.stroke, strokeKey = "stroke"
})
wearAllBtn.Visible = false

-- ============================================================
-- STATE
-- ============================================================

local activeGridThreads, currentBundleItems, animationButtons = {}, {}, {}
local targetBundleItems, activeMasterTrack, activeMasterType = nil, nil, nil
local activeBundleName, activeBundleId = "None", nil
local searchResults, savedTabList = {}, {}
local catalogCursor, currentPageIndex, itemsPerPage = nil, 1, 5
local currentTab = "Discover"
local userSelectedAnimSlot = "idleanimation"

-- forward declarations so callbacks defined earlier can reference them
local executeSearch
local refreshTabVisuals
local refreshAnimButtonVisuals

-- ============================================================
-- LOGIC
-- ============================================================

local function preloadAnimations(tracks)
local i = {}
for _, t in ipairs(tracks) do table.insert(i, t) end
if #i > 0 then pcall(function() cp:PreloadAsync(i) end) end
end

local function buildViewportSkeleton(vpFrame)
local wm = vpFrame:FindFirstChildOfClass("WorldModel")
if not wm then wm = Instance.new("WorldModel", vpFrame)
else for _,c in ipairs(wm:GetChildren()) do c:Destroy() end end

local char = lp.Character or lp.CharacterAdded:Wait()  
if not char then  
	return nil, nil, nil  
end  
char.Archivable = true  
local clone = char:Clone()  
if not clone then return nil, nil, nil end  
clone.Parent = wm  

local root = clone:WaitForChild("HumanoidRootPart", 5)  
local human = clone:FindFirstChildOfClass("Humanoid")  

local anim  
if human then  
	anim = human:FindFirstChildOfClass("Animator") or Instance.new("Animator", human)  
end  

local animateFolder = clone:FindFirstChild("Animate")  
if animateFolder then animateFolder.Disabled = true end  

local cam = vpFrame:FindFirstChildOfClass("Camera") or Instance.new("Camera", vpFrame)  
vpFrame.CurrentCamera = cam  
cam.CFrame = CFrame.new(Vector3.new(0, 1.5, 6), Vector3.new(0, 0, 0))  

local angle = 0  
local conn = rs.RenderStepped:Connect(function(dt)  
	if clone and clone.Parent and root and root.Parent then  
		angle = angle + math.rad(25*dt)  
		clone:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(0, angle, 0))  
	end  
end)  
return clone, anim, conn

end

local function applyAnimationToCharacter(character, targetAnimations, slotType)
if not character then return end
local animate = character:WaitForChild("Animate", 5)
local human = character:FindFirstChildOfClass("Humanoid")
if not animate or not human then return end
for _, tr in ipairs(human:GetPlayingAnimationTracks()) do
pcall(function() tr:AdjustWeight(0,0); tr:Stop(0) end)
end
animate.Disabled = true
local cleanSlot = string.lower(slotType or "")
local fId = m[cleanSlot]
if fId then
local folder = animate:FindFirstChild(fId)
if folder then
for _, o in ipairs(folder:GetChildren()) do if o:IsA("Animation") then o:Destroy() end end
equippedAnims[cleanSlot] = {}
for _, animAsset in ipairs(targetAnimations) do
local newAnim = Instance.new("Animation", folder)
newAnim.Name, newAnim.AnimationId = animAsset.Name, animAsset.AnimationId
table.insert(equippedAnims[cleanSlot], {Name=newAnim.Name, AnimationId=newAnim.AnimationId})
end
saveJSON(EQUIPPED_FILE, equippedAnims)
end
end
task.wait(0.05); animate.Disabled = false
end

local function getSpecificTrack(fetchedTracks, targetType)
if not fetchedTracks or #fetchedTracks == 0 then return nil end
if targetType == "swimidleanimation" then
for _, tr in ipairs(fetchedTracks) do if string.lower(tr.Name):find("idle") then return tr end end
return fetchedTracks[2] or fetchedTracks[1]
elseif targetType == "swimanimation" then
for _, tr in ipairs(fetchedTracks) do if string.lower(tr.Name) == "swim" then return tr end end
end
return fetchedTracks[1]
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
if not lp.Character then return end
local tLoad, tApply = {}, {}
for _, lt in ipairs(buttonOrder) do
local pay = items[lt]
if pay then
local t = get(pay.Id, nil, pay.AssetType)
if lt == "idleanimation" then
tApply[lt] = t; for _,x in ipairs(t) do table.insert(tLoad, x) end
else
local spec = getSpecificTrack(t, lt)
if spec then tApply[lt] = {spec}; table.insert(tLoad, spec) end
end
end
end
preloadAnimations(tLoad)
for slot, tracks in pairs(tApply) do applyAnimationToCharacter(lp.Character, tracks, slot) end
end

local function wearBundleQuickly(bundleId, onDone)
task.spawn(function()
local ok, res = pcall(function() return as:GetBundleDetailsAsync(bundleId) end)
if ok and res and res.Items and lp.Character then
local items = {}
for _, item in ipairs(res.Items) do
local lt = string.lower(item.AssetType or "")
if lt == "swimanimation" then
items["swimanimation"] = item; items["swimidleanimation"] = item
elseif shortNames[lt] then
items[lt] = item
end
end
applyBundleItemsToCharacter(items)
end
if onDone then onDone() end
end)
end

local function toggleBookmark(bundleId, bundleName)
local sId = tostring(bundleId)
local nowSaved
if savedBookmarks[sId] then
savedBookmarks[sId] = nil
nowSaved = false
else
savedBookmarks[sId] = {Id = bundleId, Name = bundleName, Fav = false, Time = tick()}
nowSaved = true
end
saveJSON(SAVED_BUNDLES_FILE, savedBookmarks)
return nowSaved
end

local masterRenderGen = 0
local function renderMasterTrack(itemPayload, assetTypeName)
if activeMasterTrack then activeMasterTrack:Stop() activeMasterTrack = nil end
masterRenderGen = masterRenderGen + 1
local myGen = masterRenderGen
local dummy, animator = buildViewportSkeleton(masterViewport)
local lowerType = string.lower(assetTypeName or "")
local displayType = shortNames[lowerType] or "Track"

statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " " .. displayType .. " (loading...)"  
applyShimmer(statusLabel, C.textDim, C.text)  

local vpShimmer = masterViewport:FindFirstChild("LoadingShimmer")  
if not vpShimmer then  
	vpShimmer = Instance.new("Frame", masterViewport)  
	vpShimmer.Name = "LoadingShimmer"  
	vpShimmer.Size, vpShimmer.BackgroundColor3, vpShimmer.BorderSizePixel = UDim2.new(1,0,1,0), C.overlay, 0  
	createCorner(vpShimmer, R_CARD)  
	applyShimmer(vpShimmer, C.overlay, C.surface)  
end  

task.spawn(function()  
	local attempt, fetchedTracks, trackToPlay = 0, nil, nil  
	while myGen == masterRenderGen do  
		fetchedTracks = get(itemPayload.Id, nil, itemPayload.AssetType)  
		trackToPlay = (fetchedTracks and #fetchedTracks>0) and getSpecificTrack(fetchedTracks, lowerType) or nil  
		if trackToPlay then break end  
		attempt = attempt + 1  
		statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " " .. displayType .. " (reloading " .. attempt .. ")"  
		clearAssetCache(itemPayload.Id)  
		task.wait(math.min(0.5 + attempt * 0.3, 3))  
	end  

	if myGen ~= masterRenderGen then return end  

	if trackToPlay then  
		removeShimmer(statusLabel)  
		if masterViewport:FindFirstChild("LoadingShimmer") then masterViewport.LoadingShimmer:Destroy() end  
	end  

	activeMasterType = assetTypeName  
	statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " " .. displayType  
	local isIdle = (lowerType == "idleanimation")  
	if isIdle and fetchedTracks and #fetchedTracks > 1 and animator then  
		local pointer = 1  
		while myGen == masterRenderGen and dummy and dummy.Parent do  
			if activeMasterTrack then activeMasterTrack:Stop() end  
			local ok, playedTrack = tryPlayTrack(animator, fetchedTracks[pointer], false)  
			while not ok and myGen == masterRenderGen do  
				clearAssetCache(itemPayload.Id)  
				fetchedTracks = get(itemPayload.Id, nil, itemPayload.AssetType)  
				if not fetchedTracks or #fetchedTracks == 0 then task.wait(0.4); continue end  
				pointer = pointer > #fetchedTracks and 1 or pointer  
				task.wait(0.4); ok, playedTrack = tryPlayTrack(animator, fetchedTracks[pointer], false)  
			end  
			if myGen ~= masterRenderGen then return end  
			activeMasterTrack = playedTrack  
			if activeMasterTrack then activeMasterTrack.Stopped:Wait() end  
			if not fetchedTracks or #fetchedTracks == 0 then return end  
			pointer = (pointer % #fetchedTracks) + 1  
		end  
	elseif trackToPlay and animator then  
		local ok, playedTrack = tryPlayTrack(animator, trackToPlay, true)  
		while not ok and myGen == masterRenderGen do  
			clearAssetCache(itemPayload.Id)  
			task.wait(0.4)  
			local reloaded = get(itemPayload.Id, nil, itemPayload.AssetType)  
			trackToPlay = (reloaded and #reloaded>0) and getSpecificTrack(reloaded, lowerType) or nil  
			if trackToPlay then ok, playedTrack = tryPlayTrack(animator, trackToPlay, true) end  
		end  
		if myGen ~= masterRenderGen then return end  
		activeMasterTrack = playedTrack  
	end  
end)

end

for _, lowerType in ipairs(buttonOrder) do
local btn = createButton(buttonContainer, {
uiSize = UDim2.new(0, btnW, 0, s(21)),
bgKey = "surface", bgTransparency = 0.25, textKey = "textMuted",
text = shortNames[lowerType], font = Enum.Font.GothamBold, size = s(9.5), radius = R_SMALL,
strokeColor = C.stroke, strokeKey = "stroke"
})

btn.MouseButton1Click:Connect(function()  
	userSelectedAnimSlot = lowerType  
	local payload = currentBundleItems[lowerType]  
	if payload then  
		wearSelectedBtn.Visible = true  
		renderMasterTrack(payload, lowerType)  
		if refreshAnimButtonVisuals then refreshAnimButtonVisuals() end  
	end  
end)  
animationButtons[lowerType] = btn

end

local function refreshBookmarkBtn()
if not activeBundleId then bookmarkBtn.Visible = false return end
bookmarkBtn.Visible = true
if savedBookmarks[tostring(activeBundleId)] then
bookmarkBtn.Text = "Saved to Saved Tab"
bookmarkBtn.TextColor3 = C.fav
else
bookmarkBtn.Text = "Save to Saved Tab"
bookmarkBtn.TextColor3 = C.textMuted
end
end

refreshAnimButtonVisuals = function()
for slot, b in pairs(animationButtons) do
local isSel = (slot == userSelectedAnimSlot) and currentBundleItems[slot]
local hasData = currentBundleItems[slot] ~= nil
if isSel then
b.BackgroundColor3 = C.surfaceHi
b.TextColor3 = C.text
elseif hasData then
b.BackgroundColor3 = C.surface
b.TextColor3 = C.text
else
b.BackgroundColor3 = C.surface
b.TextColor3 = C.textMuted
end
end
end

bookmarkBtn.MouseButton1Click:Connect(function()
toggleBookmark(activeBundleId, activeBundleName)
refreshBookmarkBtn()
if currentTab == "Saved" then executeSearch(sb.Text) end
end)

local function inspectBundleDetails(bundleId, bundleName)
table.clear(currentBundleItems)
wearSelectedBtn.Visible, wearAllBtn.Visible = false, false
activeBundleName, activeBundleId = bundleName or "Unknown", bundleId
statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " Loading..."
applyShimmer(statusLabel, C.textDim, C.text)
refreshBookmarkBtn()
refreshAnimButtonVisuals()

task.spawn(function()  
	local ok, res = pcall(function() return as:GetBundleDetailsAsync(bundleId) end)  
	if not ok or not res or not res.Items then  
		statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " Couldn't load"  
		removeShimmer(statusLabel)  
		return  
	end  
	targetBundleItems = res.Items  
	wearAllBtn.Visible = true  

	for _, item in ipairs(res.Items) do  
		local lt = string.lower(item.AssetType or "")  
		if lt == "swimanimation" then  
			currentBundleItems["swimanimation"] = item; currentBundleItems["swimidleanimation"] = item  
		elseif shortNames[lt] then  
			currentBundleItems[lt] = item  
		end  
	end  

	local slotToPlay = currentBundleItems[userSelectedAnimSlot] and userSelectedAnimSlot or "idleanimation"  
	refreshAnimButtonVisuals()  

	if currentBundleItems[slotToPlay] then  
		wearSelectedBtn.Visible = true  
		renderMasterTrack(currentBundleItems[slotToPlay], slotToPlay)  
	else  
		statusLabel.Text = truncate(activeBundleName, 24) .. " " .. ICO_DOT .. " No preview"  
		removeShimmer(statusLabel)  
	end  
end)

end

local function clearActiveGridContext()
for _, t in ipairs(activeGridThreads) do pcall(task.cancel, t) end
activeGridThreads = {}
for _, c in ipairs(gridScroller:GetChildren()) do
if c:IsA("ViewportFrame") or c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
c:Destroy()
end
end
end

local function drawEmptyState(title, subtitle)
clearActiveGridContext()
loadingOverlay.Visible = false

local wrap = Instance.new("Frame", gridScroller)  
wrap.Size = UDim2.new(1, 0, 1, 0)  
wrap.Position = UDim2.new(0, 0, 0, 0)  
wrap.BackgroundTransparency = 1  

local t = Instance.new("TextLabel", wrap)  
t.Size = UDim2.new(1, 0, 0, s(20))  
t.Position = UDim2.new(0, 0, 0.5, -s(16))  
t.BackgroundTransparency = 1  
t.Text = title  
t.Font = Enum.Font.GothamBold  
t.TextSize = s(11)  
t.TextColor3 = C.text  
tagTheme(t, "TextColor3", "text")  

local sub = Instance.new("TextLabel", wrap)  
sub.Size = UDim2.new(1, 0, 0, s(14))  
sub.Position = UDim2.new(0, 0, 0.5, s(4))  
sub.BackgroundTransparency = 1  
sub.Text = subtitle  
sub.Font = Enum.Font.Gotham  
sub.TextSize = s(9)  
sub.TextColor3 = C.textMuted  
tagTheme(sub, "TextColor3", "textMuted")  

gridScroller.CanvasSize = UDim2.new(0, 0, 0, s(220))  
pageLbl.Text = "Page 1"  
prevBtn.BackgroundTransparency, prevBtn.TextColor3 = 0.5, C.textMuted  
nextBtn.BackgroundTransparency, nextBtn.TextColor3 = 0.5, C.textMuted

end

local function drawGridPage(dataList)
clearActiveGridContext()
loadingOverlay.Visible = false

if not dataList or #dataList == 0 then  
	if currentTab == "Saved" then  
		drawEmptyState("No Saved Animations", "Save animations to find them here.")  
	else  
		drawEmptyState("No results found", "Try searching again.")  
	end  
	return  
end  

local start = (currentPageIndex - 1) * itemsPerPage + 1  
local ending = math.min(currentPageIndex * itemsPerPage, #dataList)  

local usableWidth = LEFT_W - s(8) - scrollW  
local boxHeight = s(94)  
local actionRowH = s(16)  
local nameRowH = s(14)  

local idx = 1  
for i = start, ending do  
	local bundle = dataList[i]  
	if not bundle then break end  

	-- IMPORTANT: this must stay a ViewportFrame (not a plain Frame),  
	-- because buildViewportSkeleton() below requires a ViewportFrame.  
	local box = Instance.new("ViewportFrame", gridScroller)  
	box.BackgroundColor3, box.BackgroundTransparency, box.BorderSizePixel = C.panel, 0.05, 0  
	tagTheme(box, "BackgroundColor3", "panel")  
	createCorner(box, R_CARD)  
	createStroke(box, C.stroke, 1, 0.2, "stroke")  

	local boxWidth, posX, posY = 0, 0, 0  

	if idx <= 2 then  
		boxWidth = math.floor((usableWidth - s(24)) / 2)  
		posX = s(8) + (idx - 1) * (boxWidth + s(8))  
		posY = s(8)  
	else  
		boxWidth = math.floor((usableWidth - s(32)) / 3)  
		local col = idx - 3  
		posX = s(8) + col * (boxWidth + s(8))  
		posY = s(8) + boxHeight + s(8)  
	end  

	box.AnchorPoint = Vector2.new(0.5, 0.5)  
	box.Position = UDim2.new(0, posX + boxWidth/2, 0, posY + boxHeight/2)  
	box.Size = UDim2.new(0, 0, 0, 0)  

	tween(box, {Size = UDim2.new(0, boxWidth, 0, boxHeight)}, 0.3 + (idx * 0.05), Enum.EasingStyle.Back, Enum.EasingDirection.Out)  

	local skeleton = Instance.new("Frame", box)  
	skeleton.Size, skeleton.BackgroundColor3, skeleton.BorderSizePixel, skeleton.ZIndex = UDim2.new(1,0,1,0), C.panel, 0, 2  
	tagTheme(skeleton, "BackgroundColor3", "panel")  
	createCorner(skeleton, R_CARD)  
	applyShimmer(skeleton, C.panel, C.surfaceHi)  

	local label = Instance.new("TextLabel", box)  
	label.Size, label.Position, label.BackgroundColor3, label.BackgroundTransparency = UDim2.new(1, 0, 0, nameRowH), UDim2.new(0, 0, 1, -(nameRowH + actionRowH)), C.overlay, 0.3  
	label.Text, label.TextColor3, label.Font, label.TextSize, label.ZIndex, label.ClipsDescendants = truncate(bundle.Name, 9), C.text, Enum.Font.GothamBold, s(8), 3, true  
	tagTheme(label, "BackgroundColor3", "overlay")  
	tagTheme(label, "TextColor3", "text")  

	local hitBtn = Instance.new("TextButton", box)  
	hitBtn.Size, hitBtn.Position, hitBtn.BackgroundTransparency, hitBtn.Text, hitBtn.ZIndex, hitBtn.ClipsDescendants = UDim2.new(1, 0, 1, -actionRowH), UDim2.new(0,0,0,0), 1, "", 4, true  
	hitBtn.MouseEnter:Connect(function() tween(box, {BackgroundColor3 = C.surface}, 0.12) end)  
	hitBtn.MouseLeave:Connect(function() tween(box, {BackgroundColor3 = C.panel}, 0.12) end)  
	hitBtn.MouseButton1Click:Connect(function() inspectBundleDetails(bundle.Id, bundle.Name) end)  

	if currentTab == "Saved" then  
		local favBtn = Instance.new("TextButton", box)  
		favBtn.Size, favBtn.Position, favBtn.BackgroundTransparency = UDim2.new(0, s(20), 0, s(20)), UDim2.new(1, -s(22), 0, s(2)), 1  
		favBtn.Text, favBtn.Font, favBtn.TextSize, favBtn.ZIndex, favBtn.ClipsDescendants = (bundle.Fav and ICO_STAR_ON or ICO_STAR_OFF), Enum.Font.GothamBold, s(13), 5, true  
		favBtn.TextColor3 = bundle.Fav and C.fav or C.textMuted  
		favBtn:SetAttribute("_fav", bundle.Fav and true or false)  

		favBtn.MouseButton1Click:Connect(function()  
			local sId = tostring(bundle.Id)  
			if savedBookmarks[sId] then  
				savedBookmarks[sId].Fav = not savedBookmarks[sId].Fav  
				saveJSON(SAVED_BUNDLES_FILE, savedBookmarks)  

				bundle.Fav = savedBookmarks[sId].Fav  
				favBtn.Text = bundle.Fav and ICO_STAR_ON or ICO_STAR_OFF  
				favBtn.TextColor3 = bundle.Fav and C.fav or C.textMuted  
				favBtn:SetAttribute("_fav", bundle.Fav and true or false)  
			end  
		end)  
	end  

	local cardActions = Instance.new("Frame", box)  
	cardActions.Size, cardActions.Position, cardActions.BackgroundTransparency = UDim2.new(1, 0, 0, actionRowH), UDim2.new(0, 0, 1, -actionRowH), 1  
	cardActions.ZIndex = 6  

	local alreadySaved = savedBookmarks[tostring(bundle.Id)] ~= nil  

	local saveCardBtn = Instance.new("TextButton", cardActions)  
	saveCardBtn.Size, saveCardBtn.Position = UDim2.new(0.5, -s(1), 1, 0), UDim2.new(0, 0, 0, 0)  
	saveCardBtn.BackgroundColor3, saveCardBtn.BackgroundTransparency = C.surface, 0.05  
	tagTheme(saveCardBtn, "BackgroundColor3", "surface")  
	saveCardBtn.Text = alreadySaved and (ICO_CHECK .. " Saved") or "+ Save"  
	saveCardBtn.TextColor3 = alreadySaved and C.fav or C.textDim  
	saveCardBtn.Font, saveCardBtn.TextSize, saveCardBtn.ZIndex, saveCardBtn.ClipsDescendants = Enum.Font.GothamBold, s(7), 6, true  
	saveCardBtn:SetAttribute("_savedState", alreadySaved and true or false)  
	createCorner(saveCardBtn, R_SMALL)  

	local wearCardBtn = Instance.new("TextButton", cardActions)  
	wearCardBtn.Size, wearCardBtn.Position = UDim2.new(0.5, -s(1), 1, 0), UDim2.new(0.5, s(2), 0, 0)  
	wearCardBtn.BackgroundColor3, wearCardBtn.BackgroundTransparency = C.surface, 0.05  
	tagTheme(wearCardBtn, "BackgroundColor3", "surface")  
	wearCardBtn.Text, wearCardBtn.TextColor3 = ICO_PLAY .. " Wear", C.textDim  
	tagTheme(wearCardBtn, "TextColor3", "textDim")  
	wearCardBtn.Font, wearCardBtn.TextSize, wearCardBtn.ZIndex, wearCardBtn.ClipsDescendants = Enum.Font.GothamBold, s(7), 6, true  
	createCorner(wearCardBtn, R_SMALL)  

	saveCardBtn.MouseButton1Click:Connect(function()  
		local nowSaved = toggleBookmark(bundle.Id, bundle.Name)  
		saveCardBtn.Text = nowSaved and (ICO_CHECK .. " Saved") or "+ Save"  
		saveCardBtn.TextColor3 = nowSaved and C.fav or C.textDim  
		saveCardBtn:SetAttribute("_savedState", nowSaved and true or false)  
		if activeBundleId == bundle.Id then refreshBookmarkBtn() end  
		if currentTab == "Saved" and not nowSaved then  
			executeSearch(sb.Text)  
		end  
	end)  

	wearCardBtn.MouseButton1Click:Connect(function()  
		wearCardBtn.Text = ICO_DOTS  
		wearBundleQuickly(bundle.Id, function()  
			if wearCardBtn and wearCardBtn.Parent then wearCardBtn.Text = ICO_PLAY .. " Wear" end  
		end)  
	end)  

	local dummy, animator, conn = buildViewportSkeleton(box)  
	local loopThread = task.spawn(function()  
		if not animator then return end  
		local ok, details = pcall(function() return as:GetBundleDetailsAsync(bundle.Id) end)  
		if not ok or not details or not details.Items then return end  
		local usableTracks = {}  
		for _, subItem in ipairs(details.Items) do if m[string.lower(subItem.AssetType or "")] then table.insert(usableTracks, subItem) end end  
		if #usableTracks == 0 then return end  
		local tIdx, cellTrack = 1, nil  
		while box and box.Parent do  
			local subItem = usableTracks[tIdx]  
			if not subItem then break end  
			local assets = get(subItem.Id, bundle.Id, subItem.AssetType)  
			if assets and #assets > 0 then  
				if cellTrack then cellTrack:Stop() end  
				cellTrack = animator:LoadAnimation(assets[1]); cellTrack.Looped = true  
				if skeleton.Parent then skeleton:Destroy() end  
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

	idx = idx + 1  
end  

gridScroller.CanvasSize = UDim2.new(0, 0, 0, s(220))  
pageLbl.Text = "Page " .. tostring(currentPageIndex)  
prevBtn.BackgroundTransparency, prevBtn.TextColor3 = (currentPageIndex > 1) and 0.15 or 0.5, (currentPageIndex > 1) and C.text or C.textMuted

end

executeSearch = function(query)
currentPageIndex = 1
loadingOverlay.Visible, pageLbl.Text = true, "Loading..."

if currentTab == "Saved" then  
	savedTabList = {}  
	local q = string.lower(query or "")  
	for _, v in pairs(savedBookmarks) do  
		if q == "" or string.lower(v.Name):find(q) then table.insert(savedTabList, v) end  
	end  
	table.sort(savedTabList, function(a, b)  
		if a.Fav == b.Fav then return (a.Time or 0) > (b.Time or 0) end  
		return a.Fav and not b.Fav  
	end)  
	drawGridPage(savedTabList)  
else  
	searchResults, catalogCursor = {}, nil  
	local p = CatalogSearchParams.new()  
	p.SearchKeyword, p.BundleTypes, p.IncludeOffSale, p.Limit = query or "", {Enum.BundleType.Animations}, true, 120  
	pcall(function() p.CreatorType = Enum.CreatorType.User end)  
	pcall(function() p.SalesTypeFilter = Enum.SalesTypeFilter.All end)  
	pcall(function() p.SortType = Enum.CatalogSortType.RecentlyCreated end)  
	task.spawn(function()  
		local ok, pages = pcall(function() return aes:SearchCatalog(p) end)  
		if ok and pages then  
			catalogCursor = pages  
			searchResults = pages:GetCurrentPage()  
			drawGridPage(searchResults)  
		else  
			pageLbl.Text, loadingOverlay.Text = "Error", "Search Error"  
		end  
	end)  
end

end

-- ---------- tab switching ----------

refreshTabVisuals = function()
local discoverActive = (currentTab == "Discover")
tabDiscoverBtn.BackgroundColor3 = discoverActive and C.surfaceHi or C.surface
tabDiscoverBtn.TextColor3 = discoverActive and C.text or C.textMuted
tabDiscoverBtn.BackgroundTransparency = discoverActive and 0 or 0.3
tabDiscoverUnderline.Visible = discoverActive

tabSavedBtn.BackgroundColor3 = (not discoverActive) and C.surfaceHi or C.surface  
tabSavedBtn.TextColor3 = (not discoverActive) and C.text or C.textMuted  
tabSavedBtn.BackgroundTransparency = (not discoverActive) and 0 or 0.3  
tabSavedUnderline.Visible = not discoverActive

end

local function setTab(tabName)
if currentTab == tabName then return end
currentTab = tabName
refreshTabVisuals()
executeSearch(sb.Text)
end

tabDiscoverBtn.MouseButton1Click:Connect(function() setTab("Discover") end)
tabSavedBtn.MouseButton1Click:Connect(function() setTab("Saved") end)

nextBtn.MouseButton1Click:Connect(function()
local activeList = (currentTab == "Saved") and savedTabList or searchResults
if (currentPageIndex * itemsPerPage < #activeList) then
currentPageIndex = currentPageIndex + 1
loadingOverlay.Visible = true; drawGridPage(activeList)
elseif currentTab == "Discover" and catalogCursor and not catalogCursor.IsFinished then
loadingOverlay.Visible, pageLbl.Text = true, "Loading..."
task.spawn(function()
local ok = pcall(function() catalogCursor:AdvanceToNextPageAsync() end)
if ok then
local nc = catalogCursor:GetCurrentPage()
for _, v in ipairs(nc) do table.insert(searchResults, v) end
currentPageIndex = currentPageIndex + 1; drawGridPage(searchResults)
end
end)
end
end)

prevBtn.MouseButton1Click:Connect(function()
if currentPageIndex > 1 then
currentPageIndex = currentPageIndex - 1
loadingOverlay.Visible = true; drawGridPage((currentTab == "Saved") and savedTabList or searchResults)
end
end)

wearSelectedBtn.MouseButton1Click:Connect(function()
if not activeMasterType or not lp.Character then return end
wearSelectedBtn.Text = "Loading..."
applyShimmer(wearSelectedBtn, C.surface, C.surfaceHi)
local payload = currentBundleItems[string.lower(activeMasterType)]
if payload then
local tracks = get(payload.Id, nil, payload.AssetType)
local tPlay = getSpecificTrack(tracks, string.lower(activeMasterType))
if tPlay then preloadAnimations({tPlay}); applyAnimationToCharacter(lp.Character, {tPlay}, activeMasterType) end
end
wearSelectedBtn.Text = "Wear Selected"
removeShimmer(wearSelectedBtn)
end)

wearAllBtn.MouseButton1Click:Connect(function()
if not lp.Character then return end
wearAllBtn.Text = "Loading..."
applyShimmer(wearAllBtn, C.surfaceHi, C.text)
applyBundleItemsToCharacter(currentBundleItems)
wearAllBtn.Text = "Wear All"
removeShimmer(wearAllBtn)
end)

searchBtn.MouseButton1Click:Connect(function() executeSearch(sb.Text) end)
sb.FocusLost:Connect(function(enterPressed) if enterPressed then executeSearch(sb.Text) end end)

-- ============================================================
-- THEME APPLICATION
-- ============================================================

local applyTheme
applyTheme = function(newTheme, skipSave)
if newTheme ~= "Dark" and newTheme ~= "Light" then newTheme = "Dark" end
Theme = newTheme
syncC()

-- 1) Update all tagged properties across UI tree  
for _, d in ipairs(g:GetDescendants()) do  
	local okAttrs, attrs = pcall(function() return d:GetAttributes() end)  
	if okAttrs and attrs then  
		for attrName, key in pairs(attrs) do  
			if type(attrName) == "string" and attrName:sub(1, 4) == "_tk_" and type(key) == "string" and C[key] then  
				local propName = attrName:sub(5)  
				pcall(function() d[propName] = C[key] end)  
			end  
		end  
	end  

	-- fav state (Saved tab star)  
	local favAttr = d:GetAttribute("_fav")  
	if favAttr ~= nil then  
		d.TextColor3 = favAttr and C.fav or C.textMuted  
	end  

	-- save-card state  
	local savedAttr = d:GetAttribute("_savedState")  
	if savedAttr ~= nil then  
		d.TextColor3 = savedAttr and C.fav or C.textDim  
	end  
end  

-- 2) Update cool gradients  
for _, d in ipairs(g:GetDescendants()) do  
	if d:IsA("UIGradient") and d.Name == "CoolGrad" then  
		d.Color = ColorSequence.new({  
			ColorSequenceKeypoint.new(0, C.surface),  
			ColorSequenceKeypoint.new(0.5, C.panel),  
			ColorSequenceKeypoint.new(1, C.bg)  
		})  
	end  
end  

-- 3) Refresh state-dependent visuals  
if refreshTabVisuals then refreshTabVisuals() end  
if refreshAnimButtonVisuals then refreshAnimButtonVisuals() end  
refreshBookmarkBtn()  

-- 4) Update theme button text  
themeBtn.Text = (Theme == "Dark") and "LIGHT" or "DARK"  

-- 5) Shimmer refresh  
for _, d in ipairs(g:GetDescendants()) do  
	if d:IsA("UIGradient") and d.Name == "ShimmerGrad" then  
		d.Color = ColorSequence.new({  
			ColorSequenceKeypoint.new(0, C.panel),  
			ColorSequenceKeypoint.new(0.5, C.surfaceHi),  
			ColorSequenceKeypoint.new(1, C.panel)  
		})  
	end  
end  

-- 6) Persist  
if not skipSave then  
	saveThemeToFile(Theme)  
end

end

themeBtn.MouseButton1Click:Connect(function()
local nextTheme = (Theme == "Dark") and "Light" or "Dark"
applyTheme(nextTheme)
end)

-- ============================================================
-- INIT
-- ============================================================

themeBtn.Text = (Theme == "Dark") and "LIGHT" or "DARK"

executeSearch("")
