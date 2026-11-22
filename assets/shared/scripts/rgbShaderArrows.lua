--[[
  DISABLED - kept for reference only.

  This script (from the original mod) attaches its own runtime "rgb" shader to
  notes/strums and then pokes it with setShaderFloat()/setShaderFloatArray()
  every frame.

  It CANNOT work together with noteColor.lua in Psych Engine 1.0.x:

    * noteColor.lua uses the engine built-in rgbShader (RGBShaderReference).
    * On every strum update the engine does
          rgbShader.enabled = (anim != 'static')
      which sets sprite.shader to RGBPaletteShader (a plain FlxShader), or null.
    * That overwrites the custom runtime "rgb" shader from this script.
    * setShaderFloat() then sees a shader that is not a FlxRuntimeShader and
      spams "setShaderFloat: Shader is not FlxRuntimeShader!" on screen.
    * This script also turned on luaDebugMode, which is what made those engine
      debug messages visible in the first place.

  noteColor.lua provides the same RGB recolouring through the supported engine
  API, so this script is redundant. To use it again, disable noteColor.lua and
  change ENABLED below to true (the old code is left intact underneath).

  NOTE: even on its own, the old code had a few bugs that are worth fixing if
  you re-enable it:
    - line 39's `a == x or b == y and 1.0 or 0.0` relies on Lua precedence and
      does not do what it looks like it does.
    - the note-splash loop was nested inside the strum loop (O(n*m) per frame)
      and used the strum index `i` for splash colours instead of `j`.
]]

local ENABLED = false

if not ENABLED then return end

local noteRGBSettings = { -- 1 = Border part, 2 = White part, and 3 = Colored part
	{{127, 0, 0}, {255, 255, 255}, {255, 0, 0}},
	{{127, 0, 0}, {255, 255, 255}, {255, 0, 0}},
	{{127, 0, 0}, {255, 255, 255}, {255, 0, 0}},
	{{127, 0, 0}, {255, 255, 255}, {255, 0, 0}},
	{{63, 127, 127}, {255, 255, 255}, {127, 255, 255}},
	{{63, 127, 127}, {255, 255, 255}, {127, 255, 255}},
	{{63, 127, 127}, {255, 255, 255}, {127, 255, 255}},
	{{63, 127, 127}, {255, 255, 255}, {127, 255, 255}}
}

n = 0
function onCreatePost()
	initLuaShader('rgb')

	for i = 0, getProperty('strumLineNotes.members.length') - 1 do
		setProperty('strumLineNotes.members['.. i ..'].texture', 'NOTE_assets')
		setSpriteShader('strumLineNotes.members['.. i ..']', 'rgb')
		setShaderFloatArray('strumLineNotes.members['.. i ..']', 'r', {noteRGBSettings[i+1][1][1] / 255.0, noteRGBSettings[i+1][1][2] / 255.0, noteRGBSettings[i+1][1][3] / 255.0})
		setShaderFloatArray('strumLineNotes.members['.. i ..']', 'g', {noteRGBSettings[i+1][2][1] / 255.0, noteRGBSettings[i+1][2][2] / 255.0, noteRGBSettings[i+1][2][3] / 255.0})
		setShaderFloatArray('strumLineNotes.members['.. i ..']', 'b', {noteRGBSettings[i+1][3][1] / 255.0, noteRGBSettings[i+1][3][2] / 255.0, noteRGBSettings[i+1][3][3] / 255.0})
	end

	for j = 0, getProperty('unspawnNotes.length') - 1 do
		n = getProperty('unspawnNotes['.. j .. '].mustPress') and getProperty('unspawnNotes['.. j .. '].noteData') + 4 or getProperty('unspawnNotes['.. j .. '].noteData')
		setProperty('unspawnNotes['.. j .. '].texture', 'NOTE_assets_RGB')
		setProperty('unspawnNotes['.. j .. '].noteSplashTexture', 'noteSplashes/noteSplashes')
		setSpriteShader('unspawnNotes['.. j ..']', 'rgb')
		setShaderFloatArray('unspawnNotes['.. j ..']', 'b', {noteRGBSettings[n+1][1][1] / 255.0, noteRGBSettings[n+1][1][2] / 255.0, noteRGBSettings[n+1][1][3] / 255.0})
		setShaderFloatArray('unspawnNotes['.. j ..']', 'g', {noteRGBSettings[n+1][2][1] / 255.0, noteRGBSettings[n+1][2][2] / 255.0, noteRGBSettings[n+1][2][3] / 255.0})
		setShaderFloatArray('unspawnNotes['.. j ..']', 'r', {noteRGBSettings[n+1][3][1] / 255.0, noteRGBSettings[n+1][3][2] / 255.0, noteRGBSettings[n+1][3][3] / 255.0})
		setShaderFloat('unspawnNotes['.. j ..']', 'mult', 1.0)
	end
end

function onUpdate(elapsed)
	for i = 0, getProperty('strumLineNotes.members.length') - 1 do
		local tag = 'strumLineNotes.members['.. i ..']'
		local anim = getProperty(tag .. '.animation.curAnim.name')
		local pressed = (anim == 'confirm' or anim == 'pressed')
		setSpriteShader(tag, 'rgb') -- re-apply: the engine resets strum shaders
		setShaderFloat(tag, 'mult', pressed and 1.0 or 0.0)
	end

	for j = 0, getProperty('grpNoteSplashes.members.length') - 1 do
		local tag = 'grpNoteSplashes.members['.. j ..']'
		local idx = (getProperty(tag .. '.noteData') or 0) + 1
		local col = noteRGBSettings[idx] or noteRGBSettings[1]
		setSpriteShader(tag, 'rgb')
		setShaderFloatArray(tag, 'b', {col[1][1] / 255.0, col[1][2] / 255.0, col[1][3] / 255.0})
		setShaderFloatArray(tag, 'g', {col[2][1] / 255.0, col[2][2] / 255.0, col[2][3] / 255.0})
		setShaderFloatArray(tag, 'r', {col[3][1] / 255.0, col[3][2] / 255.0, col[3][3] / 255.0})
		setShaderFloat(tag, 'mult', 1.0)
	end
end

-- Stuff you'll want to use for hex conversion

-- Thanks cherif
function hex2rgb(hex)
	local hex = hex:gsub("#","")
	if hex:len() == 3 then
		return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
	else
		return tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
	end
end
