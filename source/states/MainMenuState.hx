package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxObject;
import lime.app.Application;
import backend.Song;
import backend.Achievements;
import backend.Paths;
import backend.ClientPrefs;
import options.OptionsState;
import states.editors.MasterEditorMenu;
import substates.OutdatedSubState;
import states.PlayState;
import flixel.effects.FlxFlicker;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = RIGHT;

	var allowMouse:Bool = true;
	var selectedSomethin:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	var optionShit:Array<String> = ["play", "extras", "options", "credits"];
	var leftOption:String = "";
	var rightOption:String = "";

	var camFollow:FlxObject;

	var sky:FlxSprite;
	var flatgrass:FlxSprite;
	var groundOne:FlxSprite;
	var hills:FlxSprite;
	var groundTwo:FlxSprite;
	var clouds:FlxBackdrop;
	var logo:FlxSprite;
	var bgGroup:FlxSpriteGroup;

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		Mods.loadTopMod();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;
		FlxG.mouse.visible = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		FlxG.camera.follow(camFollow, null, 0.08);

		// Backgrounds
		bgGroup = new FlxSpriteGroup();
		sky = new FlxSprite().loadGraphic(Paths.image("menus/MenuDB/sky"));
		clouds = new FlxBackdrop(Paths.image("menus/MenuDB/clouds_scrolling"), X);
		flatgrass = new FlxSprite().loadGraphic(Paths.image("menus/MenuDB/flattgrass"));
		groundOne = new FlxSprite().loadGraphic(Paths.image("menus/MenuDB/back_grounds_one"));
		hills = new FlxSprite().loadGraphic(Paths.image("menus/MenuDB/backgrounds_two"));
		groundTwo = new FlxSprite().loadGraphic(Paths.image("menus/MenuDB/ground"));

		for (sprite in [sky, clouds, flatgrass, groundOne, hills, groundTwo]) {
			sprite.scale.set(0.8, 0.8);
			sprite.updateHitbox();
			bgGroup.add(sprite);
		}

		sky.screenCenter(FlxAxes.X);
		sky.y = -50;
		sky.scrollFactor.set(0.2, 0.2);

		clouds.screenCenter(FlxAxes.X);
		clouds.y = -50;
		clouds.velocity.x = -20;
		clouds.scrollFactor.set(0.3, 0.3);

		flatgrass.setPosition(100, (FlxG.height / 2) - 150);
		flatgrass.scrollFactor.set(0.4, 0.4);

		groundOne.screenCenter(FlxAxes.X);
		groundOne.y = (FlxG.height / 2) + 50;
		groundOne.scrollFactor.set(0.5, 0.5);

		hills.setPosition(250, 0);
		hills.scrollFactor.set(0.8, 0.8);

		groundTwo.screenCenter(FlxAxes.X);
		groundTwo.y = FlxG.height / 2;
		groundTwo.scrollFactor.set(1.4, 1.4);

		for (thing in [sky, clouds, flatgrass, groundOne, hills, groundTwo])
			thing.antialiasing = true;

		add(bgGroup);

		// Logo
		logo = new FlxSprite(20).loadGraphic(Paths.image("menus/MenuDB/logo"));
		logo.scale.set(0.7, 0.7);
		logo.updateHitbox();
		logo.y = (FlxG.height / 2) - 200;
		logo.antialiasing = true;
		logo.scrollFactor.set(0, 0);
		add(logo);

		// Menu items
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var item = createMenuItem(optionShit[i], 0, (i * 140) + 90);
			item.y += (4 - optionShit.length) * 70;
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

		// Version text
		var psychVer = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var fnfVer = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get("version"), 12);
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		changeItem();
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem = new FlxSprite(x, y).loadGraphic(Paths.image("menus/MenuDB/selection/" + name));
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		add(menuItem);
		return menuItem;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P) changeItem(-1);
			if (controls.UI_DOWN_P) changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound("cancelMenu"));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound("confirmMenu"));

				var option = optionShit[curSelected];
				switch (option)
				{
					case "play":
						PlayState.SONG = Song.loadFromJson("inadequacy", "hard");
						MusicBeatState.switchState(new PlayState());
					case "extras":
						MusicBeatState.switchState(new FreeplayState());
					case "credits":
						MusicBeatState.switchState(new CreditsState());
					case "options":
						MusicBeatState.switchState(new OptionsState());
						OptionsState.onPlayState = false;
				}
			}
		}
	}

	function changeItem(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound("scrollMenu"));
	}
}
