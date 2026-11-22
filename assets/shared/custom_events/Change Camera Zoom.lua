function onEvent(n, v1, v2)
    if n == 'Change Camera Zoom' then
        if v1:lower() == 'set' then
            setProperty('defaultCamZoom', tonumber(v2))
        elseif v1:lower() == 'add' then
            setProperty('defaultCamZoom', getProperty('defaultCamZoom') + tonumber(v2))
        elseif v1:lower() == 'tween' then
            --tween shits
        end
    end
end