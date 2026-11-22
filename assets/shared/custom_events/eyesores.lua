local shakeCam = false

function onCreatePost()
    if shadersEnabled then
        makeLuaSprite('chrom', nil, 0, 0)
        setSpriteShader('chrom', 'Eyesores')

        setShaderFloat('chrom', 'uWaveAmplitude', 0)
        setShaderFloat('chrom', 'uFrequency', 1)
        setShaderFloat('chrom', 'uSpeed', 1)
        setShaderFloat('chrom', 'uTime', 0)
        setShaderBool('chrom', 'uEnabled', false)
    end
end

function onUpdatePost(elapsed)
    if shadersEnabled then setShaderFloat('chrom', 'uTime', getShaderFloat('chrom', 'uTime') + elapsed) end
    if shakeCam and flashingLights then
        cameraShake('camGame', 0.010, 0.010)
    end
end

function fadePulse(fadeIn)
    startTween('ware', 'chrom', {x = (fadeIn and 1 or 0)}, (fadeIn and 2 or 1), {onUpdate = 'updateShader', onComplete = 'completeShader'})
end

function updateShader()
    setShaderFloat('chrom', 'uWaveAmplitude', getProperty('chrom.x'))
end

function completeShader()
    if not shakeCam then
       runHaxeCode([[
            game.camGame.filters = [];
            return;
        ]])
    end 
end

function enablePulse(enabled)
    shakeCam = (enabled:lower() == 'true' and true or false)
    fadePulse(shakeCam)
    if enabled:lower() == 'true' then
        runHaxeCode([[
            game.camGame.filters = [new ShaderFilter(game.getLuaObject("chrom").shader)];
            return;
        ]])
    end
end

function onEvent(n,v1,v2)
    if n == 'Eyesores' and shadersEnabled then
        enablePulse(v1)
    end
end