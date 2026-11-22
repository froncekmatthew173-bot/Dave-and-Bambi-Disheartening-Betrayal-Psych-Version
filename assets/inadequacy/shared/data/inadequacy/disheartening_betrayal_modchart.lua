-- Disheartening Betrayal - Psych Engine 1.0.4 Lua modchart port
-- Recreates the supplied Haxe timeline with approximate 3D note-position transforms.
-- Save as: mods/data/<song-folder-name>/script.lua
--
-- Important: the original framework has its own 3D renderer. This script recreates
-- the timing and the main note movement effects, but it cannot be pixel-identical.

local modchartEnabled = true

-- Match the original Manager's arrow-size constants: 160 * 0.7 = 112.
local ARROW_SIZE = 112
local ARROW_HALF = ARROW_SIZE * 0.5

-- Original rotation events. Times and durations are in beats, not steps.
local tracks = {
    rotateX = {
        {124,   1.5,  10, 'expoOut'},
        {125.5, 1.5,  20, 'expoOut'},
        {127,   1.5,  30, 'expoOut'},
        {128,   4,     0, 'quartOut'},
        {156,   1.5,  10, 'expoOut'},
        {157.5, 1.5,  20, 'expoOut'},
        {159,   1.5,  30, 'expoOut'},
        {160,   4,     0, 'quartOut'},
        {368,   8,  -360, 'quartOut'},
        {512,   8,     0, 'expoOut'},
        {756,   8,   -45, 'quartOut'},
        {820,   8,  -360, 'quartOut'}
    },
    rotateYZ = {
        {96, 8, 0, 'expoOut'}
    },
    tornado = {
        {240,  4, 0.3,  'quartOut'},
        {496,  4, 0,    'quartOut'},
        {512,  4, 0.3,  'quartOut'},
        {624,  4, 0,    'quartOut'},
        {756,  4, 0.5,  'quartOut'},
        {896,  4, 0.25, 'quartOut'},
        {960,  4, 0.5,  'quartOut'},
        {1088, 4, 0.25, 'quartOut'}
    },
    drunk = {
        {240,  4, 0.5,  'quartOut'},
        {496,  4, 0,    'quartOut'},
        {512,  4, 0.5,  'quartOut'},
        {624,  4, 0,    'quartOut'},
        {628,  4, 0.1,  'quartOut'},
        {896,  4, 0.5,  'quartOut'},
        {960,  4, 0.25, 'quartOut'},
        {1088, 4, 0,    'quartOut'}
    },
    beat = {
        {240,  4, 0.5,  'quartOut'},
        {624,  4, 0,    'quartOut'},
        {628,  4, 0.5,  'quartOut'},
        {756,  4, 0.1,  'quartOut'},
        {896,  4, 0.25, 'quartOut'},
        {960,  4, 0.5,  'quartOut'},
        {1088, 4, 0,    'quartOut'}
    },
    schmovintipsy = {
        {628, 4, 0.1,  'quartOut'},
        {756, 4, 0,    'quartOut'},
        {896, 4, 0.5,  'quartOut'},
        {960, 4, 0.25, 'quartOut'}
    }
}

local noteBaseX = {}
local noteLastSetY = {}
local noteLastOffsetY = {}
local strumBase = {opponent = {}, player = {}}
local strumLastSetY = {opponent = {}, player = {}}
local strumLastOffsetY = {opponent = {}, player = {}}

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function easeValue(kind, t)
    t = clamp(t, 0, 1)
    if kind == 'quartOut' then
        return 1 - (1 - t) ^ 4
    elseif kind == 'expoOut' then
        if t >= 1 then return 1 end
        return 1 - 2 ^ (-10 * t)
    end
    return t
end

-- Evaluate a sequence of ease events while holding the last value between events.
local function trackValue(events, initialValue, beat)
    local value = initialValue
    for _, event in ipairs(events) do
        local startBeat, duration, target, easing = event[1], event[2], event[3], event[4]
        if beat < startBeat then
            return value
        elseif beat < startBeat + duration then
            local from = value
            local t = (beat - startBeat) / duration
            return from + (target - from) * easeValue(easing, t)
        else
            value = target
        end
    end
    return value
end

local function modifierValue(name, beat, player)
    if name == 'rotateX' then
        return trackValue(tracks.rotateX, 0, beat)
    elseif name == 'rotateY' or name == 'rotateZ' then
        -- Original Haxe: set(..., 45, player 0), set(..., -45, player 1).
        local initial = (player == 0) and 45 or -45
        return trackValue(tracks.rotateYZ, initial, beat)
    end
    return trackValue(tracks[name] or {}, 0, beat)
end

local function scaleRange(value, inLow, inHigh, outLow, outHigh)
    if math.abs(inHigh - inLow) < 0.0001 then return outLow end
    return (value - inLow) * (outHigh - outLow) / (inHigh - inLow) + outLow
end

local function tornadoShift(lane, distance, amount, screenH)
    if amount == 0 then return 0 end
    local xOffset = (ARROW_SIZE * 1.5) - (ARROW_SIZE * lane)
    local minX = -xOffset
    local maxX = xOffset
    local between = scaleRange(xOffset, minX, maxX, -1, 1)
    between = clamp(between, -1, 1)
    local radians = math.acos(between) + (distance * 0.8) * 6 / screenH
    local adjusted = scaleRange(math.cos(radians), -1, 1, minX, maxX)
    return -(adjusted - xOffset) * amount
end

-- Recreates the supplied Rotate.hx position rotation. Projection is approximate.
local function rotatePosition(x, y, width, height, originX, originY, ax, ay, az)
    local rx = (x + width * 0.5) - originX
    local ry = (y + height * 0.5) - originY
    local rz = 0

    local xRad, yRad, zRad = math.rad(ax), math.rad(ay), math.rad(az)
    local sx, cx = math.sin(xRad), math.cos(xRad)
    local sy, cy = math.sin(yRad), math.cos(yRad)
    local sz, cz = math.sin(zRad), math.cos(zRad)

    -- Rotate X, then Y, then Z.
    local ry1 = ry * cx - rz * sx
    local rz1 = ry * sx + rz * cx
    local rx2 = rx * cy + rz1 * sy
    local rz2 = -rx * sy + rz1 * cy
    local rx3 = rx2 * cz - ry1 * sz
    local ry3 = rx2 * sz + ry1 * cz

    -- Mild perspective approximates the original renderer's depth effect.
    local focal = 900
    local denominator = math.max(180, focal - rz2)
    local perspective = focal / denominator

    return originX + rx3 * perspective - width * 0.5,
           originY + ry3 * perspective - height * 0.5
end

local function beatPulse(beat, distance)
    -- Based on Beat.hx's beatMath(), with its default speed=1, offset=0, mult=0.
    local fBeat = beat + 0.2
    if fBeat <= 0 then return 0 end
    local oddBeat = math.floor(fBeat) % 2 ~= 0
    fBeat = (fBeat % 1 + 1) % 1
    if fBeat >= 0.5 then return 0 end

    local amount
    if fBeat < 0.2 then
        amount = (fBeat / 0.2) ^ 2
    else
        local fcBeat = fBeat / 0.5
        amount = (1 - fcBeat) * (1 + fcBeat)
    end
    if oddBeat then amount = -amount end
    return 20 * amount * math.cos(distance * 0.01)
end

local function effectPosition(baseX, baseY, width, height, lane, player, distance, beat, songTime, originX, originY, screenH)
    local rx = modifierValue('rotateX', beat, player)
    local ry = modifierValue('rotateY', beat, player)
    local rz = modifierValue('rotateZ', beat, player)

    local x, y = rotatePosition(baseX, baseY, width, height, originX, originY, rx, ry, rz)

    -- Drunk.hx: default drunkSpeed=0, drunkPeriod=0, drunkOffset=0;
    -- only the base 'drunk' X channel is animated by this chart.
    local drunk = modifierValue('drunk', beat, player)
    local drunkPhase = songTime * 0.001 + lane * 0.2 + distance * 10 / screenH
    x = x + math.cos(drunkPhase) * ARROW_HALF * drunk

    -- Tornado.hx horizontal lane curve.
    x = x + tornadoShift(lane, distance, modifierValue('tornado', beat, player), screenH)

    -- SchmovinTipsy.hx vertical wave (not the separate Tipsy.hx modifier).
    local tipsy = modifierValue('schmovintipsy', beat, player)
    y = y + math.sin(beat * 0.25 * math.pi + lane) * ARROW_HALF * tipsy

    -- Beat.hx's default axis is X.
    x = x + beatPulse(beat, distance) * modifierValue('beat', beat, player)

    return x, y
end

local function captureStrums()
    for lane = 0, 3 do
        if strumBase.opponent[lane] == nil then
            local x = getPropertyFromGroup('opponentStrums', lane, 'x')
            local y = getPropertyFromGroup('opponentStrums', lane, 'y')
            local w = getPropertyFromGroup('opponentStrums', lane, 'width') or ARROW_SIZE
            local h = getPropertyFromGroup('opponentStrums', lane, 'height') or ARROW_SIZE
            if x ~= nil and y ~= nil then strumBase.opponent[lane] = {x = x, y = y, w = w, h = h} end
        end
        if strumBase.player[lane] == nil then
            local x = getPropertyFromGroup('playerStrums', lane, 'x')
            local y = getPropertyFromGroup('playerStrums', lane, 'y')
            local w = getPropertyFromGroup('playerStrums', lane, 'width') or ARROW_SIZE
            local h = getPropertyFromGroup('playerStrums', lane, 'height') or ARROW_SIZE
            if x ~= nil and y ~= nil then strumBase.player[lane] = {x = x, y = y, w = w, h = h} end
        end
    end
end

local function originFor(player, screenH)
    local side = (player == 0) and 'opponent' or 'player'
    local central = strumBase[side][2] or strumBase[side][1] or strumBase[side][0]
    local ox = (central ~= nil) and (central.x + central.w * 0.5) or ((screenWidth or 1280) * 0.5)
    return ox, screenH * 0.5
end

local function processStrums(groupName, side, player, beat, songTime, screenH)
    for lane = 0, 3 do
        local base = strumBase[side][lane]
        if base ~= nil then
            local originX, originY = originFor(player, screenH)
            local outX, outY = effectPosition(base.x, base.y, base.w, base.h, lane, player, 0, beat, songTime, originX, originY, screenH)
            setPropertyFromGroup(groupName, lane, 'x', outX)
            setPropertyFromGroup(groupName, lane, 'y', outY)
        end
    end
end

local function noteKey(i)
    local strumTime = getPropertyFromGroup('notes', i, 'strumTime') or 0
    local lane = getPropertyFromGroup('notes', i, 'noteData') or 0
    local mustPress = getPropertyFromGroup('notes', i, 'mustPress') and 1 or 0
    local sustain = getPropertyFromGroup('notes', i, 'isSustainNote') and 1 or 0
    local noteType = getPropertyFromGroup('notes', i, 'noteType') or ''
    return string.format('%.3f_%d_%d_%d_%s', strumTime, lane, mustPress, sustain, tostring(noteType))
end

local function processNotes(beat, songTime, screenH)
    local count = getProperty('notes.length') or 0
    for i = 0, count - 1 do
        local lane = getPropertyFromGroup('notes', i, 'noteData')
        local currentX = getPropertyFromGroup('notes', i, 'x')
        local currentY = getPropertyFromGroup('notes', i, 'y')
        local mustPress = getPropertyFromGroup('notes', i, 'mustPress')
        if lane ~= nil and currentX ~= nil and currentY ~= nil then
            lane = lane % 4
            local player = mustPress and 1 or 0
            local key = noteKey(i)
            if noteBaseX[key] == nil then noteBaseX[key] = currentX end

            -- Notes are recalculated vertically by the engine every frame. If a note
            -- didn't move since our last write, subtract our previous Y offset to avoid drift.
            local baseY = currentY
            if noteLastSetY[key] ~= nil and math.abs(currentY - noteLastSetY[key]) < 0.05 then
                baseY = currentY - (noteLastOffsetY[key] or 0)
            end

            local width = getPropertyFromGroup('notes', i, 'width') or ARROW_SIZE
            local height = getPropertyFromGroup('notes', i, 'height') or ARROW_SIZE
            local side = (player == 0) and 'opponent' or 'player'
            local receptor = strumBase[side][lane]
            local receptorY = (receptor ~= nil) and receptor.y or 0
            local distance = baseY - receptorY
            local originX, originY = originFor(player, screenH)
            local outX, outY = effectPosition(noteBaseX[key], baseY, width, height, lane, player, distance, beat, songTime, originX, originY, screenH)

            setPropertyFromGroup('notes', i, 'x', outX)
            setPropertyFromGroup('notes', i, 'y', outY)
            noteLastSetY[key] = outY
            noteLastOffsetY[key] = outY - baseY
        end
    end
end

function onUpdatePost(elapsed)
    if not modchartEnabled then return end

    -- curDecBeat gives fractional beat timing in Psych Engine; fallback is less smooth.
    local beat = curDecBeat
    if beat == nil then beat = (curStep or 0) / 4 end

    local songTime = 0
    if getSongPosition ~= nil then
        songTime = getSongPosition() or 0
    end

    local screenH = screenHeight or 720
    captureStrums()

    -- Run on receptors as well as notes, similar to the original arrow renderer.
    processStrums('opponentStrums', 'opponent', 0, beat, songTime, screenH)
    processStrums('playerStrums', 'player', 1, beat, songTime, screenH)
    processNotes(beat, songTime, screenH)
end
