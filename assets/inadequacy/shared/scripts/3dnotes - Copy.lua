function onUpdate(elapsed)
    if dadName == 'perditus-p4' then
		for i=0,4,1 do
			setPropertyFromGroup('opponentStrums', i, 'texture', 'myNotes/lol')
			--setPropertyFromGroup('unspawnNotes', i, 'texture', 'NOTE_assets')
		end
		for i = 0, getProperty('unspawnNotes.length')-1 do
			if not getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
				setPropertyFromGroup('unspawnNotes', i, 'texture', 'myNotes/lol'); --Change texture
			end
		end
    end
end