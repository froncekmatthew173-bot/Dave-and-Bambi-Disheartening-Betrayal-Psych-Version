
-- Perditus P3 / P4 floating effect

local floatAmplitude = 20 -- Height of the floating motion
local floatSpeed = 2.5    -- Floating speed

local floatTime = 0
local floatBaseY = nil
local lastDadName = ''

function onUpdate(elapsed)
    if dadName == 'perditus-p3' or dadName == '4ditus' then

        -- Save the opponent's starting Y position
        if floatBaseY == nil or lastDadName ~= dadName then
            floatBaseY = getProperty('dad.y')
            floatTime = 0
        end

        -- Move the opponent smoothly up and down
        floatTime = floatTime + elapsed

        setProperty(
            'dad.y',
            floatBaseY + math.sin(floatTime * floatSpeed) * floatAmplitude
        )

    else
        -- Reset the stored position when another opponent is used
        floatBaseY = nil
        floatTime = 0
    end

    lastDadName = dadName
end