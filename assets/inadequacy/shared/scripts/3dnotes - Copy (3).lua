-- Psych Engine 1.0.4
-- Change ONLY the player's note skin mid-song

local changeStep = 3840 -- Step where the skin changes
local newSkin = 'myNotes/lol'

function changeOpponentSkin(skin)
    -- Change the opponent's stationary arrows
    for i = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', i, 'texture', skin)
    end

    -- Change future opponent notes that haven't spawned
    for i = 0, getProperty('unspawnNotes.length') - 1 do
        if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
            setPropertyFromGroup('unspawnNotes', i, 'texture', skin)
        end
    end

    -- Change opponent notes that have already spawned
    for i = 0, getProperty('notes.length') - 1 do
        if getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'texture', skin)
        end
    end
end

function onStepHit()
    if curStep == changeStep then
        changeOpponentSkin(newSkin)
    end
end