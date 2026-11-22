-- Note colour modes ported from FNF JS Engine (JordanSantiagoYT).
-- Modes: Normal, Quant-Based, Char-Based, Grayscale, Rainbow
-- Select in Mods > Inadequacy PE Port > Mod Settings > Note Color.
--
-- Exact JS Engine r/g/b triplets are used (arrowRGB, quantRGB, etc.).
-- Colours are stored as hex STRINGS and converted with getColorFromHex:
-- raw 0xFF........ Lua literals get mangled by Lua -> Haxe Int conversion.

local NOTE_STYLES = {'Normal', 'Quant-Based', 'Char-Based', 'Grayscale', 'Rainbow'}
local style = 'Char-Based'
local charColorCache = {}
local rainbowTime = 5000

-- ClientPrefs.arrowRGB
local laneRGB = {
	{'FFC24B99', 'FFFFFFFF', 'FF3C1F56'},
	{'FF00FFFF', 'FFFFFFFF', 'FF1542B7'},
	{'FF12FA05', 'FFFFFFFF', 'FF0A4447'},
	{'FFF9393F', 'FFFFFFFF', 'FF651038'}
}

-- ClientPrefs.quantRGB
local quantRGB = {
	{'FFF9393F', 'FFFFFFFF', 'FF651038'}, -- 4th
	{'FF3A48F5', 'FFFFFFFF', 'FF0C3D60'}, -- 8th
	{'FFB200FF', 'FFFFFFFF', 'FF57007F'}, -- 12th
	{'FFFFD800', 'FFFFFFFF', 'FF4D4100'}, -- 16th
	{'FFFF00DC', 'FFFFFFFF', 'FF740066'}, -- 24th
	{'FFFF6A00', 'FFFFFFFF', 'FF652800'}, -- 32nd
	{'FF00FFFF', 'FFFFFFFF', 'FF004B5E'}, -- 48th
	{'FF12FA05', 'FFFFFFFF', 'FF0A4447'}, -- 64th
	{'FFFF7F7F', 'FFFFFFFF', 'FF592C2C'}, -- 96th
	{'FFD67FFF', 'FFFFFFFF', 'FF5F3870'}, -- 128th
	{'FF00FF90', 'FFFFFFFF', 'FF003921'}, -- 192nd
	{'FF7F3300', 'FFFFFFFF', 'FF401800'}, -- 256th
	{'FF007F0E', 'FFFFFFFF', 'FF003404'}, -- 384th
	{'FF230093', 'FFFFFFFF', 'FF0F0043'}, -- 512th
	{'FFE7E7E7', 'FFFFFFFF', 'FF2A2A2A'}, -- 768th
	{'FF00AB64', 'FFFFFFFF', 'FF00321E'}, -- 1024th
	{'FF000000', 'FFFFFFFF', 'FF000000'}, -- 1536th
	{'FFA69C52', 'FFFFFFFF', 'FF2F2D17'}, -- 2048th
	{'FFFFF9AB', 'FFFFFFFF', 'FF45442F'}, -- 3072nd
	{'FFFF6A00', 'FFFFFFFF', 'FF652800'}  -- 6144th
}
local quantSteps = {1536, 768, 512, 384, 256, 192, 128, 96, 64, 48, 32, 24, 16, 12, 8, 6, 4, 3, 2, 1}

local function isValidStyle(s)
	for _, v in ipairs(NOTE_STYLES) do
		if v == s then return true end
	end
	return false
end

function onCreate()
	local saved = getModSetting('noteColorStyle')
	if isValidStyle(saved) then style = saved end
end

local function hex(r, g, b)
	return getColorFromHex(string.format('%02X%02X%02X',
		math.max(0, math.min(255, math.floor(r))),
		math.max(0, math.min(255, math.floor(g))),
		math.max(0, math.min(255, math.floor(b)))))
end

local function darken(r, g, b, amount)
	return hex(r * amount, g * amount, b * amount)
end

local function charColors(tag)
	if tag ~= 'dad' and tag ~= 'gf' and tag ~= 'boyfriend' then tag = 'dad' end
	if charColorCache[tag] ~= nil then return charColorCache[tag] end
	local arr = getProperty(tag .. '.healthColorArray')
	if type(arr) ~= 'table' or arr[1] == nil then
		if tag ~= 'dad' then return charColors('dad') end
		arr = {255, 0, 255}
	end
	local main = hex(arr[1], arr[2], arr[3])
	-- JS Engine: getChar() = build(main, WHITE, main.getDarkened(0.7))
	local palette = {main, getColorFromHex('FFFFFFFF'), darken(arr[1], arr[2], arr[3], 0.3)}
	charColorCache[tag] = palette
	return palette
end

local function quantPalette(strumTime)
	local currentBpm = curBpm or bpm or 196
	if currentBpm <= 0 then currentBpm = 196 end
	local beat = math.floor((strumTime / (60000 / currentBpm)) * 1536 + 0.5)
	local idx = #quantRGB
	for i = 1, #quantSteps do
		if beat % quantSteps[i] == 0 then idx = i break end
	end
	return quantRGB[idx]
end

local function rainbowPalette(hue)
	hue = hue % 360
	local c, x = 255, 255 * (1 - math.abs((hue / 60) % 2 - 1))
	local r, g, b
	if hue < 60 then r, g, b = c, x, 0
	elseif hue < 120 then r, g, b = x, c, 0
	elseif hue < 180 then r, g, b = 0, c, x
	elseif hue < 240 then r, g, b = 0, x, c
	elseif hue < 300 then r, g, b = x, 0, c
	else r, g, b = c, 0, x end
	return {hex(r, g, b), getColorFromHex('FFFFFFFF'), darken(r, g, b, 0.3)}
end

local function paletteFor(group, index, tag)
	local data = getPropertyFromGroup(group, index, 'noteData') or 0
	if type(data) ~= 'number' then data = 0 end
	if data < 0 then data = 0 end
	local t = getPropertyFromGroup(group, index, 'strumTime')
	if t == nil then t = getSongPosition() or 0 end

	if style == 'Normal' then
		return laneRGB[(data % 4) + 1]
	elseif style == 'Char-Based' then
		return charColors(tag)
	elseif style == 'Grayscale' then
		return {'FFA0A0A0', 'FFFFFFFF', 'FF424242'}
	elseif style == 'Rainbow' then
		return rainbowPalette(t / rainbowTime * 360)
	elseif style == 'Quant-Based' then
		return quantPalette(t)
	end
	return charColors(tag)
end

-- This port's note skins are WHITE (~254,254,254). Feeding the JS triplets
-- (r = main, g = white, b = dark) into the RGB shader makes r+g+b > 1.0 on
-- every channel, so it always clamps to WHITE with a black edge -- that's the
-- "main is white / darkened is black" result.
--
-- So keep the exact tables above as the source, but apply the main colour as a
-- sprite TINT, which multiplies the whole note and reliably produces the right
-- colour. The rgbShader is left enabled with identity uniforms (red/green/
-- blue), so it is ON but does not wash anything out.

local function applyPalette(group, index, p, enable)
	local main = getColorFromHex(p[1])
	setPropertyFromGroup(group, index, 'color', main)
	setPropertyFromGroup(group, index, 'rgbShader.r', getColorFromHex('FF0000'))
	setPropertyFromGroup(group, index, 'rgbShader.g', getColorFromHex('00FF00'))
	setPropertyFromGroup(group, index, 'rgbShader.b', getColorFromHex('0000FF'))
	setPropertyFromGroup(group, index, 'rgbShader.mult', 1)
	if enable then
		setPropertyFromGroup(group, index, 'rgbShader.enabled', true)
	end
end

local function colorNote(index, mustPress)
	local tag = mustPress and 'boyfriend' or 'dad'
	if getPropertyFromGroup('notes', index, 'gfNote') then tag = 'gf' end
	local p = paletteFor('notes', index, tag)
	applyPalette('notes', index, p, true)
	if mustPress then
		setPropertyFromGroup('notes', index, 'noteSplashData.r', getColorFromHex(p[1]))
		setPropertyFromGroup('notes', index, 'noteSplashData.g', getColorFromHex('00FF00'))
		setPropertyFromGroup('notes', index, 'noteSplashData.b', getColorFromHex('0000FF'))
	end
end

function onSpawnNote(index, noteData, noteType, isSustainNote, strumTime)
	local mustPress = getPropertyFromGroup('notes', index, 'mustPress')
	if mustPress == nil then mustPress = false end
	colorNote(index, mustPress)
end

function onCountdownStarted()
	charColorCache = {}
end

function onUpdatePost()
	for i = 0, (getProperty('notes.length') or 0) - 1 do
		local mustPress = getPropertyFromGroup('notes', i, 'mustPress')
		if mustPress == nil then mustPress = false end
		colorNote(i, mustPress)
	end
	for i = 0, (getProperty('opponentStrums.length') or 0) - 1 do
		applyPalette('opponentStrums', i, paletteFor('opponentStrums', i, 'dad'), false)
	end
	for i = 0, (getProperty('playerStrums.length') or 0) - 1 do
		applyPalette('playerStrums', i, paletteFor('playerStrums', i, 'boyfriend'), false)
	end
end
