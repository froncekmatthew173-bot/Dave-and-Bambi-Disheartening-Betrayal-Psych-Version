import flixel.FlxSprite;
import Main;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import haxe.ds.StringMap;
import openfl.text.TextFormat;
import flixel.FlxBasic;
import flixel.util.FlxStringUtil;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.util.FlxGradient;
import backend.Difficulty;

//import flixel.addons.display.FlxRadialGauge;
import Sys;
// you can configure these below

var settings:StringMap = [
	"font" => "comic.ttf", // if you want the regular vcr font, just replace "comic.ttf" with "vcr.ttf"
	"fontScale" => 1, // only use this if your font is too small
	"strumSkin" => 'noteSkins/NOTE_3D_strumline',
	"notesSkin" => 'noteSkins/NOTE_3D_assets',
	"sustainsSkin" => 'noteSkins/NOTE_3D_holds'
];

var credits:StringMap = [
	"Supernovae" => "Original Song made by ArchWk!",
	"Glitch" => "Original Song made by DeadShadow and PixelGH!",
	"Kabunga" => "OH MY GOD I JUST DEFLATED"
];

var timerColors:StringMap = [ //REMEMBER TO INCLUDE THE 0xFF OTHERWISE IT'LL MAKE THE COLOR BLUE OR BLACK
	'test' => 0xFF000000
];

var barImages:StringMap = [
	'test' => 'healthBar-vol1',
];

var threeDeeEnabled:Bool = false;
var threeDeeSongs = ['Polygonized', 'Kabunga'];

// don't touch ANY of the shit below unless you know what you're doing

var iconProp1:FlxSprite;
var iconProp2:FlxSprite;

var kadeEngineWatermark:FlxText;
var creditsWatermark:FlxText;

var timerBG:FlxShapeCircle;
var timer:FlxSprite;
var pieChart;
var alarmClock:FlxSprite;

var accuracyText:FlxText;
var missesText:FlxText;
var scoreText:FlxText;

var scoreImage:FlxSprite;
var missesImage:FlxSprite;
var accuracyImage:FlxSprite;

var ogIconSize:Array<Array<Int>> = [];
function onCreatePost() {
	var songName = PlayState.SONG.song;
		if (settings.get("font") == "comic.ttf")
			Main.fpsVar.defaultTextFormat = new TextFormat(Paths.font('comic.ttf'), 15, 0xFFFFFF, true);
		else
			Main.fpsVar.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF, false);
		
		game.showCombo = true;

		iconProp1 = new FlxSprite().makeGraphic(game.iconP1._frame.frame.width, game.iconP1._frame.frame.height, 0xFF000000);
		ogIconSize.push([game.iconP1._frame.frame.width, game.iconP1._frame.frame.height]);
		iconProp2 = new FlxSprite().makeGraphic(game.iconP2._frame.frame.width, game.iconP2._frame.frame.height, 0xFF000000);
		ogIconSize.push([game.iconP2._frame.frame.width, game.iconP2._frame.frame.height]);

		game.timeBar.kill();

		game.healthBar.set_barWidth(game.healthBar.bg.width - 8);
		game.healthBar.set_barHeight(game.healthBar.bg.height - 8);
		game.healthBar.barOffset.set(4, 4);
		game.healthBar.screenCenter(1);
		game.healthBar.y = (ClientPrefs.data.downScroll ? 50 : FlxG.height * 0.9);

		var barImageThing = ('uiElements/' + (barImages.get(songName) != null ? barImages.get(songName) : 'healthBar-vol1'));
		game.healthBar.bg.loadGraphic(Paths.image(barImageThing));

		game.iconP1.y = game.healthBar.y - (game.iconP1.height / 2);
		game.iconP2.y = game.healthBar.y - (game.iconP2.height / 2);
		game.timeBar.y = (ClientPrefs.data.downScroll ? (FlxG.height * 0.9) + 20 : 30);

		game.timeTxt.setFormat(Paths.font(settings.get("font")), 25 * settings.get("fontScale"), 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		game.timeTxt.borderSize = 2.5 * settings.get("fontScale");

		game.scoreTxt.y = game.healthBar.y + 40;
		game.scoreTxt.visible = false;

		game.botplayTxt.y = game.healthBar.bg.y + (ClientPrefs.data.downScroll ? 100 : -100);
		game.botplayTxt.setFormat(Paths.font(settings.get("font")), 42 * settings.get("fontScale"), 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		game.botplayTxt.borderSize = 2.5 * settings.get("fontScale");

		kadeEngineWatermark = new FlxText(4, game.healthBar.bg.y + (credits.get(songName) != null ? 30 : 50), 0, songName);
		kadeEngineWatermark.setFormat(Paths.font(settings.get("font")), 16 * settings.get("fontScale"), 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
		kadeEngineWatermark.borderSize = 1.25 * settings.get("fontScale");
		kadeEngineWatermark.camera = game.camHUD;
		uiGroup.add(kadeEngineWatermark);

		if (credits.get(songName) != null) {
			creditsWatermark = new FlxText(4, game.healthBar.bg.y + 50, 0, credits.get(songName));
			creditsWatermark.setFormat(Paths.font(settings.get("font")), 16 * settings.get("fontScale"), 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
			creditsWatermark.borderSize = 1.25 * settings.get("fontScale");
			creditsWatermark.camera = game.camHUD;
			uiGroup.add(creditsWatermark);
		}

		game.comboGroup.camera = game.camGame;
		game.grpNoteSplashes.visible = false;
		
		switch(songName) {
			case 'Overdrive':
				timeTxt.visible = false;
				game.healthBar.bg.loadGraphic(Paths.image('uiElements/fnfengine'));
			case 'Backseat':
				if (Difficulty.getString() == 'playrobot') {healthBar.leftToRight = true;}
		}

		if (threeDeeSongs.contains(songName)) {
			threeDeeEnabled = true;
			doNoteShits();
		}
	makeTexts();
	return;
}

function makeClock() {
	timerBG = new FlxShapeCircle(0, 0, 50, {}, -1);
	timerBG.camera = camHUD;
	timerBG.screenCenter(1);
	timerBG.color = FlxColor.GRAY;
	uiGroup.add(timerBG);

	timer = new FlxSprite(0, 0).makeGraphic(100, 100, FlxColor.WHITE);
	timer.camera = camHUD;
	timer.screenCenter(1);
	timer.flipX = true;
	uiGroup.add(timer);

	timerBG.y = (defaultPlayerStrumY0 + (ClientPrefs.data.downScroll ? 20 : -20));
	timer.y = (defaultPlayerStrumY0 + (ClientPrefs.data.downScroll ? 20 : -20));

	//the thing that actually makes it the pie chart
	pieChart = game.createRuntimeShader('PieChart');
	timer.shader = pieChart;
	pieChart.setBool('useGradient', false);
	pieChart.setFloat('_amount', 0);
	pieChart.setFloat('_start', 0);
	pieChart.setFloat('_end', 360);

	alarmClock = new FlxSprite(0, defaultPlayerStrumY0 + (ClientPrefs.data.downScroll ? -5 : -45));
	if (threeDeeSongs.contains(PlayState.SONG.song)) {
		alarmClock.loadGraphic(Paths.image('uiElements/timer-3d'));
		alarmClock.y += (ClientPrefs.data.downScroll ? -10 : 10);
		timer.y += (ClientPrefs.data.downScroll ? -10 : 10);
		timerBG.y += (ClientPrefs.data.downScroll ? -10 : 10);
		timeTxt.y += (ClientPrefs.data.downScroll ? 0 : 20);
	} else alarmClock.loadGraphic(Paths.image('uiElements/timer'));
	alarmClock.camera = game.camHUD;
	alarmClock.screenCenter(1);
	uiGroup.add(alarmClock);

	var xValues = getMinAndMax(game.timeTxt.width, game.timeBar.width);
	var yValues = getMinAndMax(game.timeTxt.height, game.timeBar.height);
	game.timeTxt.x = game.timeBar.x - ((xValues[0] - xValues[1]) / 2);

	if (ClientPrefs.data.middleScroll) {
		for (obj in [timerBG, timer, alarmClock, timeTxt]) {
			obj.x -= 300;
		}
		for (i in 0...game.opponentStrums.length) {
			game.opponentStrums.members[i].x += (i > 1 ? 50 : -50);
		}
	}

	timerBG.alpha = 0.0001;
	timer.alpha = 0.0001;
	alarmClock.alpha = 0.0001;
	timeTxt.y += (ClientPrefs.data.downScroll ? 0 : 110);

	setVar('alarmClock', alarmClock);
	setVar('timer', timer);
	setVar('timerBG', timerBG);

	if (PlayState.SONG.song != 'Backseat') {
		if (timerColors.get(PlayState.SONG.song) != null) timer.color = timerColors.get(PlayState.SONG.song);
		else timer.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
	} else {FlxGradient.overlayGradientOnFlxSprite(timer, timer.width, timer.height, [0xFFFFBF0F, 0xFFFF130F], 1, 0, 1, 180);}

	if ((getModSetting('timetype') != 'Disabled') && (getModSetting('timetype') != 'Time Elapsed / Left')) {
		ClientPrefs.data.timeBarType = getModSetting('timetype');
	} else {}
}

function makeTexts() {
	accuracyImage = new FlxSprite(450, scoreTxt.y - 25).loadGraphic(Paths.image('uiElements/accuracy'));
	accuracyImage.camera = camHUD;
	accuracyImage.scale.set(0.5, 0.5);
	uiGroup.add(accuracyImage);

	accuracyText = new FlxText(accuracyImage.x + 30, 0, 0, '0');
	uiGroup.add(accuracyText);

	missesImage = new FlxSprite(590, scoreTxt.y - 20).loadGraphic(Paths.image('uiElements/misses'));
	missesImage.camera = camHUD;
	missesImage.scale.set(0.5, 0.5);
	uiGroup.add(missesImage);

	missesText = new FlxText(missesImage.x + 60, 0, FlxG.width, '0');
	uiGroup.add(missesText);

	scoreImage = new FlxSprite(740, scoreTxt.y - 25).loadGraphic(Paths.image('uiElements/score'));
	scoreImage.camera = camHUD;
	scoreImage.scale.set(0.5, 0.5);
	uiGroup.add(scoreImage);

	scoreText = new FlxText(scoreImage.x + 65, 0, FlxG.width + 350, '0');
	uiGroup.add(scoreText);

	for (texts in [accuracyText, missesText, scoreText]) {
		if (PlayState.SONG.song == 'Overdrive') {
			texts.setFormat(Paths.font(settings.get("font")), 20 * settings.get("fontScale"), 0xFFFFFFFF, "left", FlxTextBorderStyle.OUTLINE, 0xFF000000);
			texts.borderSize = 3;
		} else {
			texts.setFormat(Paths.font(settings.get("font")), 20 * settings.get("fontScale"), 0xFFFFFFFF, "left", FlxTextBorderStyle.OUTLINE, 0xFF000000);
			texts.borderSize = 1.5 * settings.get('fontScale');
		}
		texts.camera = camHUD;
		texts.y = scoreTxt.y;
	}
}

function doNoteShits() {
	for (note in unspawnNotes) {
		if ((note.noteType != 'shape' && !note.mustPress) || (note.noteType != 'shape' && note.mustPress && FlxG.random.int(0,2) == 1)) {
			if (note.isSustainNote) {
				note.texture = settings.get('sustainsSkin');
				note.scale.y += (!StringTools.endsWith(note.animation.name, 'holdend') ? 0.2 : 0);
				note.offsetY -= (StringTools.endsWith(note.animation.name, 'holdend') ? 5 : 0);
			} else {note.texture = settings.get('notesSkin');}
			note.rgbShader.enabled = false;
		}
	}
}

function onCountdownStarted() {
		for (i in game.strumLineNotes) {
			i.x += 5.5;
			if (ClientPrefs.data.downScroll)
				i.y -= 15;
		}
		for (j in 0...game.playerStrums.length) {
			game.setOnScripts('defaultPlayerStrumX' + j, game.playerStrums.members[j].x);
			game.setOnScripts('defaultPlayerStrumY' + j, game.playerStrums.members[j].y);
		}
		for (j in 0...game.opponentStrums.length) {
			game.setOnScripts('defaultOpponentStrumX' + j, game.opponentStrums.members[j].x);
			game.setOnScripts('defaultOpponentStrumY' + j, game.opponentStrums.members[j].y);
		}
		if (threeDeeSongs.contains(PlayState.SONG.song)) {
			for (strum in opponentStrums.members) {
				strum.texture = settings.get('strumSkin');
				strum.useRGBShader = false;
			}
		}
	makeClock();
	return;
}

function onSpawnNote(note) {
	if (note.isSustainNote) note.noAnimation = true;
}

function goodNoteHitPre(note) {
	if (threeDeeEnabled) {
		if (note.noteType == 'shape' || note.texture == 'noteSkins/3D_NOTE_assets') PlayState.stageUI = '3D';
		else PlayState.stageUI = 'normal';
	}
}

var scorePerSecond:Float = 200;
function goodNoteHit(note) {
	if (note.isSustainNote) boyfriend.holdTimer = 0;
}

function opponentNoteHit(note) {
	if (note.isSustainNote) dad.holdTimer = 0;
}

function onSongStart() {
	if (PlayState.SONG.song != 'Overdrive') {
		if (timerBG != null && timer != null && alarmClock != null) {
			for (timers in [timerBG, timer, alarmClock]) {
				FlxTween.tween(timers, {alpha: 1}, 0.5 / playbackRate, {ease: FlxEase.circOut});
			}
		}
	}
}

function onUpdatePost() {
		var fill = (Conductor.songPosition / game.songLength);
		if (pieChart != null) pieChart.setFloat('_amount', fill);

		var thingy = 0.88;
		var healthFlip = game.healthBar.leftToRight;
		iconProp1.setGraphicSize(Std.int(FlxMath.lerp(ogIconSize[0][0], iconProp1.width, thingy)), Std.int(FlxMath.lerp(ogIconSize[0][1], iconProp1.height, thingy)));
		iconProp1.updateHitbox();
		iconProp2.setGraphicSize(Std.int(FlxMath.lerp(ogIconSize[1][0], iconProp2.width, thingy)), Std.int(FlxMath.lerp(ogIconSize[1][1], iconProp2.height, thingy)));
		iconProp2.updateHitbox();

		game.iconP1.scale.set(iconProp1.width / 150, iconProp1.height / 150);
		game.iconP2.scale.set(iconProp2.width / 150, iconProp2.height / 150);

		var iconOffset = 26;
		if (healthFlip) {
			game.iconP2.flipX = true;
			game.iconP1.flipX = true;
			var bfArray = game.boyfriend.healthColorArray;
			var dadArray = game.dad.healthColorArray;
			game.healthBar.leftBar.color = FlxColor.fromRGB(bfArray[0], bfArray[1], bfArray[2]);
			game.healthBar.rightBar.color = FlxColor.fromRGB(dadArray[0], dadArray[1], dadArray[2]);
			game.iconP2.x = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(100 - game.healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
			game.iconP1.x = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(100 - game.healthBar.percent, 0, 100, 100, 0) * 0.01)) - (game.iconP1.width - iconOffset);
		} else {
			game.iconP1.x = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(game.healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
			game.iconP2.x = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(game.healthBar.percent, 0, 100, 100, 0) * 0.01)) - (game.iconP2.width - iconOffset);
		}

		game.iconP1.origin.set(0, 0);
		game.iconP2.origin.set(0, 0);

		if (missesText != null && scoreText != null && accuracyText != null) {
			switch (PlayState.SONG.song.toLowerCase())
			{
				default: 
					missesText.text = songMisses;
					scoreText.text = FlxStringUtil.formatMoney(songScore, false);
					accuracyText.text = (truncateFloat(ratingPercent * 100, 2) + '%');
			}
		}

		if (game.camZooming) {
			game.camGame.zoom = FlxMath.lerp(game.defaultCamZoom, game.camGame.zoom, 0.95);
			game.camHUD.zoom = FlxMath.lerp(1, game.camHUD.zoom, 0.95);
		}
		if (getModSetting('timetype') == 'Time Elapsed / Left') {
			game.timeTxt.text = FlxStringUtil.formatTime(Conductor.songPosition / 1000) + ' / ' + FlxStringUtil.formatTime(songLength / 1000);
		}
	}

function onBeatHit() {
	var funny = Math.max(Math.min(game.health, 1.9), 0.1);
	iconProp1.setGraphicSize(Std.int(iconProp1.width + (50 * (funny + 0.1))), Std.int(iconProp1.height - (25 * funny)));
	iconProp1.updateHitbox();
	iconProp2.setGraphicSize(Std.int(iconProp2.width + (50 * ((2 - funny) + 0.1))), Std.int(iconProp2.height - (25 * (2 - funny))));
	iconProp2.updateHitbox();
}

function onStepHit() {
	switch(PlayState.SONG.song) {
		case 'Splitathon':
			switch(curStep){
				case 4096:
					timer.color = 0xFF25BF37;
				case 6288:
					timer.color = 0xFF0F5FFF;
				case 6928:
					timer.color = 0xFFFFFFFF;
					FlxGradient.overlayGradientOnFlxSprite(timer, timer.width, timer.height, [0xFF00B515, 0xFF4965FF], 1, 0, 1, 180);
				case 7696:
					FlxGradient.overlayGradientOnFlxSprite(timer, timer.width, timer.height, [FlxColor.WHITE], 1, 0, 1, 180);
					timer.color = 0xFF0F5FFF;
			}
		case 'Mealie':
			if (curStep == 1440) {
				timer.color = 0xFFFFFFFF;
				FlxGradient.overlayGradientOnFlxSprite(timer, timer.width, timer.height, [0xFF00B515, 0xFF4965FF], 1, 0, 1, 180);
			}
		case 'Bot Trot':
			var dadColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			var bfColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

			if (curStep == 1600) {
				FlxTween.color(timer, ((Conductor.stepCrochet / 1000) * 224), dadColor, bfColor, {ease: FlxEase.linear});
			}
			if (curStep == 2324) {
				FlxTween.color(timer, 1, bfColor, dadColor, {ease: FlxEase.linear});
			}
	}
}

function onEvent(n:String, v1:String) {
	if (n == 'Change Character')
		reloadIcons(v1);
}

function onDestroy() {
	Main.fpsVar.defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFF, false);
	Main.fpsVar.visible = ClientPrefs.data.showFPS;
}

function truncateFloat(number:Float, precision:Int):Float {
	var num = number;
	num = num * Math.pow(10, precision);
	num = Math.round(num) / Math.pow(10, precision);
	return num;
}

function reloadIcons(char:String) {
	if (char.toLowerCase() == 'dad' || char.toLowerCase() == 'opponent' || char == '0') {
		ogIconSize.shift();
		ogIconSize.insert(0, [game.iconP2._frame.frame.width, game.iconP2._frame.frame.height]);
	} else {
		ogIconSize.pop();
		ogIconSize.push([game.iconP1._frame.frame.width, game.iconP1._frame.frame.height]);
	}
}

function getMinAndMax(value1:Float, value2:Float):Array<Float>
{
	var minAndMaxs:Array<Float> = [];

	var min = Math.min(value1, value2);
	var max = Math.max(value1, value2);

	minAndMaxs.push(min);
	minAndMaxs.push(max);

	return minAndMaxs;
}
