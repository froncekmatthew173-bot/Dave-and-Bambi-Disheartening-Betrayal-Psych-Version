-- Psych Engine 1.0.4
-- Change ONLY the opponent's note skin mid-song

local changeStep = 1472 -- Step where the skin changes
local newSkin = 'myNotes/lol'

function changeOpponentSkin(skin)
    -- Change the opponent's stationary arrows
    for i = 0, getProperty('opponentStrums.length') - 1 do
        setPropertyFromGroup('opponentStrums', i, 'texture', skin)
    end

    -- Change future opponent notes that haven't spawned
    for i = 0, getProperty('unspawnNotes.length') - 1 do
        if not getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
            setPropertyFromGroup('unspawnNotes', i, 'texture', skin)
        end
    end

    -- Change opponent notes that have already spawned
    for i = 0, getProperty('notes.length') - 1 do
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'texture', skin)
        end
    end
end

function onStepHit()
    if curStep == changeStep then
        changeOpponentSkin(newSkin)
    end
end