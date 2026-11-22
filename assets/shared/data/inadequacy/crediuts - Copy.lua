
-- Credits sprite: fade in at step 384, then fade out

local fadeDuration = 0.4
local displayTime = 2.5

function onCreate()
    makeLuaSprite('dwasd', 'goodending', 0, 0)

    setObjectCamera('dwasd', 'hud')
    screenCenter('dwasd', 'xy')

    scaleObject('dwasd', 1, 1)

    setProperty('dwasd.alpha', 0)
    addLuaSprite('dwasd', true)
end

function onStepHit()
    if curStep == 4940 then
        -- Fade in
        doTweenAlpha(
            'creditsFadeIn',
            'dwasd',
            1,
            fadeDuration,
            'quadOut'
        )

        -- Wait before fading out
        runTimer('hidedwasd', displayTime)
    end
end