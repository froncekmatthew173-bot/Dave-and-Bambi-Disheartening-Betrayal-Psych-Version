-- ============================================================
-- EXPUNGED SHOWDOWN - ALWAYS-ON BLOOM
-- T-Bar Engine
-- ============================================================

function onCreatePost()

    -- Load the shader from:
    -- mods/shaders/expungedBloom.frag
    initLuaShader('expungedBloom')

    -- This object exists only so T-Bar can create
    -- the FlxRuntimeShader instance.
    makeLuaSprite('_fullscreenShader', '', 0, 0)

    setSpriteShader(
        '_fullscreenShader',
        'expungedBloom'
    )

    -- Bloom amount
    setShaderFloat(
        '_fullscreenShader',
        'bloomStrength',
        0.85
    )

    -- Overall brightness
    setShaderFloat(
        '_fullscreenShader',
        'exposure',
        0.8
    )

    -- Attach the shader to the GAME camera.
    -- It will therefore process the game every frame.
    runHaxeCode([[
        game.camGame.filters = [
            new ShaderFilter(
                game.getLuaObject('_fullscreenShader').shader
            )
        ];

        game.camGame.filtersEnabled = true;
    ]])
end