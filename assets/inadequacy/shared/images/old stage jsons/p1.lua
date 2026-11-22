function onCreate()
	-- Background Sprites
	makeLuaSprite('sprite2', 'phase1/sky', -1021, -686)
	setScrollFactor('sprite2', 1.15, 1.1)
	scaleObject('sprite2', 3.65, 3.1)
	setProperty('sprite2.antialiasing', false)
	setProperty('sprite2.alpha', 1)
	setProperty('sprite2.angle', 0)
	setProperty('sprite2.flipX', false)
	setProperty('sprite2.flipY', false)
	setProperty('sprite2.color', getColorFromHex('FFFFFF'))
	addLuaSprite('sprite2', false)

	makeLuaSprite('sprite1', 'phase1/ground', -1022, -501)
	setScrollFactor('sprite1', 1, 1)
	scaleObject('sprite1', 3.65, 3.65)
	setProperty('sprite1.antialiasing', false)
	setProperty('sprite1.alpha', 1)
	setProperty('sprite1.angle', 0)
	setProperty('sprite1.flipX', false)
	setProperty('sprite1.flipY', false)
	setProperty('sprite1.color', getColorFromHex('FFFFFF'))
	addLuaSprite('sprite1', false)
end

function onCreatePost()
	setProperty('defaultCamZoom', 0.5)
	setProperty('cameraSpeed', 1.5)
	
	-- Character Positions & GF Visibility
	setProperty('boyfriend.x', 1170)
	setProperty('boyfriend.y', 400)
	setProperty('dad.x', -40)
	setProperty('dad.y', 160)
	setProperty('gf.x', 400)
	setProperty('gf.y', 130)
	setProperty('gf.visible', false)
end