-- Event notes hooks
local madeInvisNotes = false
function onCreate()
	makeLuaSprite('dark');
	makeGraphic('dark', screenWidth * 2, screenHeight * 2, '000000')
	screenCenter('dark')
	setScrollFactor('dark', 0, 0)
	setProperty('dark.alpha', 0.0001)
	setObjectOrder('dark', 9999) --Generally in front of literally everything
end

function onEvent(n, v1, v2)
	if n == 'Dark' then
		madeInvisNotes = not madeInvisNotes
		cancelTween('darkAlpha')
		cancelTween('hud')

		local value1 = stringSplit(v1, ',')
		local value2 = stringSplit(v2, ',')

		doTweenAlpha('darkalpha', 'dark', tonumber(value1[2]), tonumber(value2[2]), 'sineInOut');

		if value1[1]:lower() == 'true' then
			makeInvisibleNotes(madeInvisNotes, tonumber(value2[2]))
		end
		if (value1[3] ~= nil and value1[3] ~= '') and (value1[3]:lower() == 'true') then
			doTweenAlpha('hud', 'uiGroup', tonumber(value2[1]), tonumber(value2[2]), 'sineInOut')
		end
    end
end

function makeInvisibleNotes(invisible, time)
	for i = 0,7 do
		cancelTween('hia'..i)
		noteTweenAlpha('hia'..i, i, invisible and 0 or 1, time)
	end
end

function onStepHit()
	if songName == 'Blocked' then
		if curStep == 1200 then
			doTweenAlpha('er', 'dark', 0.7, (stepCrochet / 1000) * 8)
		elseif curStep == 1216 then
			setProperty('dark.alpha', 0.0001)
		end
	end
end