local enabled = false
function onCreatePost()
	makeLuaSprite("shaderSpr")
	setSpriteShader("shaderSpr", "blockedGlitchEffect")
  	setShaderFloat("shaderSpr", "time", 0)
end

local elapsedTime = 0
function onUpdate(elapsed)
	elapsedTime = elapsedTime + elapsed
	setShaderFloat("shaderSpr", "time", elapsedTime)
end

function onEvent(n, v1, v2)
	if n == 'GlitchEffect' then
		enabled = not enabled

		if enabled then runHaxeCode('game.camHUD.filters = [new ShaderFilter(game.getLuaObject("shaderSpr").shader)]; return;')
		else runHaxeCode('game.camHUD.filters = []; return;') end
	end
end