hudItems = {'iconP1', 'iconP2', 'healthBar', 'healthBar.bg', 'timeBar', 'timeBar.bg', 'scoreTxt', 'timeTxt'}

function onEvent(name,value1,value2)
	if name == 'hud-alpha' then
		for i = 1,#hudItems do
			for m = 0,7 do
				doTweenAlpha('hud'..i, hudItems[i], value1, value2, 'linear')
				noteTweenAlpha('a'..m, m, value1, value2, 'linear')
			end
		end
	end
end
