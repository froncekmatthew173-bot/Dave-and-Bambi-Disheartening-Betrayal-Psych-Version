import Reflect;
import backend.StageData;
using StringTools;

var stages:Map<String, Dynamic> = new haxe.ds.StringMap();

function onCreatePost() {
    // onEventPushed doesn't work for event scripts LOLLLLL
    for (event in game.eventNotes) {
        if (event.event.toLowerCase() == 'change stage json') {
            precacheStage(event.value1);
        }
    }
}

function onEvent(n:String, v1:String, v2:String) {
    if (n.toLowerCase() == 'change stage json') {
        changeStage(v1);
    }
}

var madeGf:Bool = false;
function precacheStage(json:String) {
    if (stages.exists(json)) return true;

    var stageFile:Dynamic = StageData.getStageFile(json);
    
    if (stageFile.objects != null && stageFile.objects.length > 0) {
        stages.set(json, []);
        var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageFile.objects, !stageFile.hide_girlfriend ? game.gfGroup : null, game.dadGroup, game.boyfriendGroup, null);
        for (m in list.keyValueIterator()) {
            stages.get(json)[m.value.ID] = [m.key, m.value];
        }

        if (!stageFile.hide_girlfriend && game.gf == null && !madeGf) {
            var newGf = new Character(0, 0, PlayState.SONG.gfVersion);
            game.startCharacterPos(newGf);
            game.gfGroup.scrollFactor.set(0.95, 0.95);
            stages.get(json).push(['gf', newGf]);
            game.gfGroup.add(newGf);
            madeGf = true;
        }
        return true;
    }
    else return false;
}

function changeStage(stage:String) {
    if (!stages.exists(stage) && !precacheStage(stage)) return;

    var oldStage:Dynamic = StageData.getStageFile(PlayState.curStage);

remove(game.boyfriendGroup);
remove(game.gfGroup);
remove(game.dadGroup);

// Only remove stage objects if the old stage has an object list.
if (oldStage != null && oldStage.objects != null) {
    for (obj in oldStage.objects) {
        if (obj == null || obj.name == null || obj.name.length < 1) continue;

        remove(getVar(obj.name));
        removeVar(obj.name);
    }
}

    var luaPath:String = findScript('stages/' + PlayState.curStage, '.lua');
    if (luaPath != null) {
        for (luaInstance in game.luaArray) {
            if (luaInstance.scriptName == luaPath) {
                game.luaArray.remove(luaInstance);
                luaInstance.stop();
                break;
            }
        }
    }
    var hxPath:String = findScript('stages/' + PlayState.curStage, '.hx');
    if (hxPath != null) {
        for (hxInstance in game.hscriptArray) {
            if (hxInstance.origin == hxPath) {
                game.hscriptArray.remove(hxInstance);
                hxInstance.destroy();
                break;
            }
        }
    }

    PlayState.curStage = stage;

    var stageFile:Dynamic = StageData.getStageFile(stage);
    var stageObjs:Array<Dynamic> = stages.get(stage);

    if (!stageFile.hide_girlfriend && game.gf == null) {
        game.gf = stageObjs[stageObjs.length - 1][1];
        stageObjs.pop();
    }

    game.defaultCamZoom = stageFile.defaultZoom;
    if (!game.camZooming) game.camZooming = true;

    PlayState.stageUI = "normal";
    if (stageFile.stageUI != null && stageFile.stageUI.trim().length > 0) {
        PlayState.stageUI = stageFile.stageUI;
    }
    else if (stageFile.isPixelStage == true) {
        PlayState.stageUI = "pixel";
    }

    game.BF_X = stageFile.boyfriend[0];
    game.BF_Y = stageFile.boyfriend[1];
    game.GF_X = stageFile.girlfriend[0];
    game.GF_Y = stageFile.girlfriend[1];
    game.DAD_X = stageFile.opponent[0];
    game.DAD_Y = stageFile.opponent[1];
    game.boyfriendGroup.setPosition(game.BF_X, game.BF_Y);
    game.gfGroup.setPosition(game.GF_X, game.GF_Y);
    game.dadGroup.setPosition(game.DAD_X, game.DAD_Y);
 
     if (stageFile.camera_speed != null) game.cameraSpeed = stageFile.camera_speed;

    game.boyfriendCameraOffset = stageFile.camera_boyfriend;
    if (game.boyfriendCameraOffset == null) game.boyfriendCameraOffset = [0, 0];

    game.opponentCameraOffset = stageFile.camera_opponent;
    if (game.opponentCameraOffset == null) game.opponentCameraOffset = [0, 0];

    game.girlfriendCameraOffset = stageFile.camera_girlfriend;
    if (game.girlfriendCameraOffset == null) game.girlfriendCameraOffset = [0, 0];

    game.moveCameraSection();
    game.camGame.snapToTarget();

    for (obj in stageObjs) {
        if (obj == null) continue;
        add(obj[1]);
        setVar(obj[0], obj[1]);
    }

    var luaPath:String = findScript('stages/' + PlayState.curStage, '.lua');
    if (luaPath != null) {
        var lua = new psychlua.FunkinLua(luaPath);
        lua.call('onCreatePost');
    }
    var hxPath:String = findScript('stages/' + PlayState.curStage, '.hx');
    if (hxPath != null) {
        game.initHScript(hxPath);
        var hx = game.hscriptArray[game.hscriptArray.length - 1];
        if (hx.exists('onCreatePost')) hx.call('onCreatePost');
    }
}

// i'm still wondering why this function isn't static like are we deadass bro
function findScript(scriptFile:String, ext:String) {
    if (ext == null || ext.trim().length < 1) ext = '.lua';
    if (!scriptFile.endsWith(ext)) scriptFile += ext;
    var path:String = Paths.getPath(scriptFile, 'text');
    if (FileSystem.exists(path)) return path;
    else if (FileSystem.exists(scriptFile)) return scriptFile;
    return null;
}