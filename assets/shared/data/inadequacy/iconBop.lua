-- Psych Engine Lua version of:
-- //CODE BY I exist, resourced by ya boi Hyper, HScript port by Jikken
-- Ported to Lua by ChatGPT

------------------------------------------
-- CONFIG
------------------------------------------
local bpmbased = false
local speed = 0.35
local transition = 'quintOut'

-- Internal values
local iconhp = 1
local iconhp2 = 1
local doIconBop = false

------------------------------------------
-- ON CREATE
------------------------------------------
function onCreatePost()
    doIconBop = false -- disable default Codename icon bop if applicable
end

------------------------------------------
-- BEAT BOP LOGIC
------------------------------------------
function onBeatHit()
    if not doIconBop and not getPropertyFromClass('PlayState','startingSong') then
        cancelTween('iconP1ScaleX')
        cancelTween('iconP1ScaleY')
        cancelTween('iconP2ScaleX')
        cancelTween('iconP2ScaleY')

        -- Apply the dynamic health-based scaling before tween
        setProperty('iconP1.scale.x', iconhp)
        setProperty('iconP1.scale.y', getProperty('iconP1.scale.y') / iconhp)

        setProperty('iconP2.scale.x', iconhp2)
        setProperty('iconP2.scale.y', getProperty('iconP2.scale.y') / iconhp2)

        local duration = bpmbased and (getPropertyFromClass('Conductor','crochet') / 1500) or speed

        -- Tween back to default scale
        doTweenX('iconP1ScaleX', 'iconP1.scale', getProperty('iconP1.defaultScale'), duration, transition)
        doTweenY('iconP1ScaleY', 'iconP1.scale', getProperty('iconP1.defaultScale'), duration, transition)

        doTweenX('iconP2ScaleX', 'iconP2.scale', getProperty('iconP2.defaultScale'), duration, transition)
        doTweenY('iconP2ScaleY', 'iconP2.scale', getProperty('iconP2.defaultScale'), duration, transition)
    end
end

------------------------------------------
-- POST UPDATE (runs every frame)
------------------------------------------
function onUpdatePost(elapsed)
    -- health ratio math identical to original HScript
    local hpPercent = getProperty('healthBar.percent')
    iconhp = (hpPercent / 35 * 0.5) + 1
    iconhp2 = (-hpPercent / 35 * 0.5) + 2.5

    -- Adjust icon origins (matching Codename-style anchor)
    local iconP1H = getProperty('iconP1.height')
    local iconP2H = getProperty('iconP2.height')
    local iconP1W = getProperty('iconP1.width')
    local iconP2W = getProperty('iconP2.width')

    local iconP1Def = getProperty('iconP1.defaultScale')
    local iconP2Def = getProperty('iconP2.defaultScale')

    -- Same math as origin.set(...) lines
    setProperty('iconP1.origin.x', 0)
    setProperty('iconP1.origin.y', (-iconP1H * iconP1Def) + iconP1H)

    setProperty('iconP2.origin.x', iconP2W)
    setProperty('iconP2.origin.y', (-iconP2H * iconP2Def) + iconP2H)
end
