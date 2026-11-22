function onEvent(name, value1, value2)
    if name == 'Red Flash' then
        local targetAlpha = tonumber(value1) or 0.5
        local duration = tonumber(value2) or 0.5

        setProperty('redOverlay.alpha', targetAlpha)
        doTweenAlpha('redFade', 'redOverlay', 0, duration, 'linear')
    end
end