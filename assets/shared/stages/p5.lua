local shaderName = "yes" -- Make sure your file is named exactly yes.frag in mods/shaders/
local timer = 0
local scrollOffset = 0
local scrollSpeed = .80 -- texture repeats per second

function onCreate()
    -- 1. Create the Background Sprite
    makeLuaSprite('sprite1', 'phase4/fog', -1767, -691, 1.95, 1.85, true)
    scaleObject('sprite1', 5, 10)
    addLuaSprite('sprite1', false)

    initLuaShader('scrollRight')
    setSpriteShader('sprite1', 'scrollRight')
    setShaderFloat('sprite1', 'uOffset', 0)

    function onUpdate(elapsed)
    -- Increase the UV offset over time. The shader uses fract() to wrap it.
    scrollOffset = (scrollOffset + elapsed * scrollSpeed) % 1
    setShaderFloat('sprite1', 'uOffset', scrollOffset)
    setShaderFloat('sprite1', 'uOffset', scrollOffset)
    end
end