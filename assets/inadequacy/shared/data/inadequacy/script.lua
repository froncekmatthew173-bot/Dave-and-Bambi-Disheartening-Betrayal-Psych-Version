
-- Psych Engine 1.0.4
-- DNB: Disheartening Betrayal shader controller

local useColorMultiply = false
local useNTSC = true

-- Color multiplier:
-- 1.0 = normal
-- 0.5 = darker
-- 1.5 = brighter
local colorMult = 0.75

-- NTSC effect settings
local ntscInterlace = 1
local ntscFrame = 0

function onCreate()
    if not shadersEnabled then
        return
    end

    -- Color Multiply shader (file is "color multiply.frag", with a space)
    initLuaShader('color multiply')
    makeLuaSprite('colorMultiplyHolder')
    setSpriteShader('colorMultiplyHolder', 'color multiply')
    setShaderFloat('colorMultiplyHolder', 'mult', colorMult)

    -- NTSC shader
    initLuaShader('flixel-ntsc')
    makeLuaSprite('ntscHolder')
    setSpriteShader('ntscHolder', 'flixel-ntsc')
    setShaderInt('ntscHolder', 'uFrame', 0)
    setShaderFloat('ntscHolder', 'uInterlace', ntscInterlace)
end

function onCreatePost()
    if not shadersEnabled then
        return
    end

    local filters = {}

    if useColorMultiply then
        table.insert(filters, 'colorMultiplyHolder')
    end

    if useNTSC then
        table.insert(filters, 'ntscHolder')
    end

    if #filters > 0 then
        addHaxeLibrary('ShaderFilter', 'openfl.filters')

        local filterCode = 'game.camGame.setFilters(['

        for i, name in ipairs(filters) do
            if i > 1 then
                filterCode = filterCode .. ', '
            end

            filterCode = filterCode ..
                'new ShaderFilter(game.getLuaObject("' ..
                name .. '").shader)'
        end

        filterCode = filterCode .. ']);'

        runHaxeCode(filterCode)
    end
end

function onUpdatePost(elapsed)
    if not shadersEnabled or not useNTSC then
        return
    end

    -- Advance the NTSC phase over time
    ntscFrame = ntscFrame + 1
    setShaderInt('ntscHolder', 'uFrame', ntscFrame)
end