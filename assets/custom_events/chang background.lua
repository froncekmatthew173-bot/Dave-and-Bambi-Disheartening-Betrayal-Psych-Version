function onEvent(name, value1, value2)
{
    if (name === 'ChangeStage')
    {
        // value1 = stage name
        // value2 = optional (camera zoom or variant)

        switch (value1)
        {
            case 'stage2':
                // Remove old stage
                removeLuaSprite('bg', true);
                removeLuaSprite('stageFront', true);

                // Add new stage
                makeLuaSprite('bg', 'stages/stage2/bg', -600, -200);
                addLuaSprite('bg', false);

                makeLuaSprite('stageFront', 'stages/stage2/front', -650, 600);
                addLuaSprite('stageFront', false);

                // Optional zoom
                if (value2 != '')
                    setProperty('defaultCamZoom', parseFloat(value2));
            break;

            case 'darkStage':
                makeLuaSprite('darkBG', 'stages/dark/bg', -500, -300);
                addLuaSprite('darkBG', false);

                setProperty('defaultCamZoom', 0.8);
            break;
        }
    }
}