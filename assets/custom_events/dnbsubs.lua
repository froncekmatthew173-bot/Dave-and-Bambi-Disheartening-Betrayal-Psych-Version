
useFromText = false
-- Set true to load subtitles from data/song/subs.txt

function string:split(s)
    return stringSplit(self, s)
end

function onCreate()
    addHaxeLibrary('Type')
    addHaxeLibrary('FlxTypeText', 'flixel.addons.text')
    addHaxeLibrary('FlxTimer', 'flixel.util')
    addHaxeLibrary('FlxTween', 'flixel.tweens')
    addHaxeLibrary('ClientPrefs')

    luaDebugMode = true

    if useFromText then
        subs = getTextFromFile('data/' .. songPath .. '/subs.txt')

        if not subs or subs == '' then
            debugPrint('DNB Subs: subtitles file not found or empty!')
            return
        end

        subs = subs:split('\n')
        subs.index = 0
    end
end

function onEvent(n, sub, v2)
    if n ~= 'dnbsubs' then
        return
    end

    -- Read settings safely
    local settings = (v2 or ''):split(', ')

    local size = tonumber(settings[1]) or 36
    local typespeed = tonumber(settings[2]) or 0.02
    local showtime = tonumber(settings[3]) or 1

    -- Allow commas to be passed through the event
    sub = (sub or ''):gsub(',/', ',')

    if useFromText then
        subs.index = subs.index + 1
        sub = subs[subs.index]
    end

    if sub == nil or sub == '' then
        debugPrint('DNB Subs: subtitle text is empty!')
        return
    end

    runHaxeCode([[
        var subtitleString:String = subtitleText;
        var subtitleSize:Int = subtitleFontSize;
        var subtitleSpeed:Float = subtitleTypeSpeed;
        var subtitleDuration:Float = subtitleShowTime;

        var subtitleObj = new FlxTypeText(
            0, 0, FlxG.width, subtitleString, subtitleSize
        );

        subtitleObj.y = (FlxG.height / 2) - 200;

        subtitleObj.setFormat(
            Paths.font("vcr.ttf"),
            subtitleSize,
            0xFFFFFFFF,
            'center',
            Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE,
            0xFF000000
        );

        subtitleObj.antialiasing = ClientPrefs.globalAntialiasing;
        subtitleObj.borderSize = 2;
        subtitleObj.cameras = [game.camHUD];
        subtitleObj.screenCenter(0x01);

        game.add(subtitleObj);

        subtitleObj.start(
            subtitleSpeed / game.playbackRate,
            false,
            false,
            [],
            function() {
                new FlxTimer().start(
                    subtitleDuration / game.playbackRate,
                    function(timer) {
                        FlxTween.tween(
                            subtitleObj,
                            {alpha: 0},
                            0.5 / game.playbackRate,
                            {
                                onComplete: function(tween) {
                                    game.remove(subtitleObj);
                                    subtitleObj.destroy();
                                }
                            }
                        );
                    }
                );
            }
        );
    ]], {
        subtitleText = sub,
        subtitleFontSize = size,
        subtitleTypeSpeed = typespeed,
        subtitleShowTime = showtime
    })
end