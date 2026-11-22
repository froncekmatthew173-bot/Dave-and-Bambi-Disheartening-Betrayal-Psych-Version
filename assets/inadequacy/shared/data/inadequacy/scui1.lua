
-- multiplyPulse
-- Psych Engine 1.0.4
-- Requires the colorMultiply shader holder to exist.

local multiplyPulseDuration = 0.45
local multiplyPulseTime = 0
local multiplyPulseAmount = 0.35
local multiplyBase = 1.0

-- Called by the HScript Call custom event
function multiplyPulse()
    multiplyPulseTime = multiplyPulseDuration
end

-- Add this logic to your EXISTING onUpdatePost
-- if your script already has one.
function onUpdatePost(elapsed)
    if multiplyPulseTime > 0 then
        multiplyPulseTime = math.max(
            0,
            multiplyPulseTime - elapsed
        )

        local progress =
            1 - (multiplyPulseTime / multiplyPulseDuration)

        local pulse =
            math.sin(progress * math.pi)

        setShaderFloat(
            'colorMultiplyHolder',
            'mult',
            multiplyBase + pulse * multiplyPulseAmount
        )
    else
        setShaderFloat(
            'colorMultiplyHolder',
            'mult',
            multiplyBase
        )
    end
end