local textSize = 36
local textSpeed = 0.02
local textTime = 1

local amount = 0
local activeSubs = 0

function onCreate()
    runHaxeCode([[
        createCallback('setSubtitleCallback', function(sub:String, ?duration:Float) {
            if (duration == null || duration <= 0) duration = 1;
            getVar(sub).completeCallback = function() {
                new FlxTimer().start(duration, function(tmr) {
                    FlxTween.tween(getVar(sub), { alpha: 0 }, 0.5, { onComplete: function(twn) {
                        getVar(sub).destroy();
                        remove(getVar(sub));
                        removeVar(sub);
                    } });
                });
            }
        });

        return;
    ]])
end

function onEvent(n,v1,v2)
    if n == 'Subtitles' then
        amount = amount + 1
        activeSubs = activeSubs + 1

        local value2 = stringSplit(v2, ',')
        textSize = tonumber(value2[1])
        textSpeed = tonumber(value2[2])
        textTime = tonumber(value2[3])

        createInstance('subs'..amount, 'flixel.addons.text.FlxTypeText', {0, ((screenHeight / 2) - 200), screenWidth, v1, 36})
        callMethod('subs'..amount..'.setFormat', {'comic.ttf', textSize, getColorFromHex('FFFFFF'), "center"})
        setTextBorder('subs'..amount, 2, 'black')
        setObjectCamera('subs'..amount, 'camHUD')
        addInstance('subs'..amount, true)

        callMethod('subs'..amount..'.start', {textSpeed})
        setSubtitleCallback('subs'..amount, textTime)
    end
end