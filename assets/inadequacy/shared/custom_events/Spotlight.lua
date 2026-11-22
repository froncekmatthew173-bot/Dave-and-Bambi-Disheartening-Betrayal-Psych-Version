local spotlightEnabled = false

function onCreatePost()
    luaDebugMode = true
    makeLuaSprite('spotlight', 'spotlight', 0, 0)
    setBlendMode('spotlight', 'add')
    setGraphicSize('spotlight', math.floor(getProperty('spotlight.width') * (getProperty('dad.width') / getProperty('spotlight.width')) * 1.3))
    setProperty('spotlight.origin.y', (getProperty('spotlight.origin.y') - (getProperty('spotlight.frameHeight') / 2)))
    setProperty('spotlight.alpha', 0.0001)
    setObjectOrder('spotlight', 999999)

    setProperty('spotlight.x', getProperty('dad.x') + (getProperty('dad.width') - getProperty('spotlight.width')) / 2)
    setProperty('spotlight.y', (getMidpointY('dad') - (getProperty('spotlight.height') / 2)))
    --updateSpotlight(false)
end

local elapsedTime = 0
function onUpdatePost(elapsed)
    elapsedTime = elapsedTime + elapsed
    if spotlightEnabled then
        if (getProperty('gf.animation.finished') and stringStartsWith(getProperty('gf.animation.name'), 'sing')) then
            setProperty('gf.skipDance', true)
        end
        setProperty('spotlight.angle', math.sin(elapsedTime * 2) * 3)
    end
end

function onSectionHit()
    if spotlightEnabled then
        updateSpotlight(mustHitSection)
    end
end

function updateSpotlight(bfSection)
    local singer = (bfSection and 'boyfriend' or 'dad')

    setProperty('gf.skipDance', false)
    playAnim('gf', (bfSection and 'singRIGHT' or 'singLEFT'), true, false, 0)

    local newPosX = (getProperty(singer..'.x') + (getProperty(singer..'.width') - getProperty('spotlight.width')) / 2)
    local newPosY = (getMidpointY(singer) - (getProperty('spotlight.height') / 2))

    startTween('heuo', 'spotlight', {x = newPosX, y = newPosY}, 0.66, {ease = 'circOut'})
end

function onEvent(n,v1,v2)
    if n == 'Spotlight' then
        if v1:lower() == 'true' then
            setProperty('spotlight.alpha', 1)
        else
            doTweenAlpha('byeybeee', 'spotlight', 0, 1)
        end
        spotlightEnabled = (v1:lower() == 'true')
    end
end