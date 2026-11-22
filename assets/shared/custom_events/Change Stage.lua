function onEvent(name, value1, value2)
    if name == 'Change Stage' then
        
        local newStage = value1
        if newStage == nil or newStage == '' then
            return
        end

        -- remove old stage script
        if luaSpriteExists('stageBack') then
            removeLuaSprite('stageBack', true)
        end

        -- clear stage group safely
        for i = 0, getProperty('grpStage.members.length')-1 do
            removeFromGroup('grpStage', i)
        end

        -- load new stage script
        addLuaScript('stages/' .. newStage)

        -- force recreate stage
        callOnLuas('onCreate')
        callOnLuas('onCreatePost')

        curStage = newStage
    end
end