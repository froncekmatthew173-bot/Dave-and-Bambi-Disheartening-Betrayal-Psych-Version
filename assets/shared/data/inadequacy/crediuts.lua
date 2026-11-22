
-- Credits sprite: fade in at step 384, then fade out

local fadeDuration = 0.4
local displayTime = 2.5

function onCreate()
    makeLuaSprite('creditsSprite', 'songCard', 0, 0)

    setObjectCamera('creditsSprite', 'hud')
    screenCenter('creditsSprite', 'xy')

    setProperty('creditsSprite.alpha', 0)
    addLuaSprite('creditsSprite', true)
end

function onStepHit()
    if curStep == 384 then
        -- Fade in
        doTweenAlpha(
            'creditsFadeIn',
            'creditsSprite',
            1,
            fadeDuration,
            'quadOut'
        )

        -- Wait before fading out
        runTimer('hideCreditsSprite', displayTime)
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'hideCreditsSprite' then
        doTweenAlpha(
            'creditsFadeOut',
            'creditsSprite',
            0,
            fadeDuration,
            'quadIn'
        )
    end
end