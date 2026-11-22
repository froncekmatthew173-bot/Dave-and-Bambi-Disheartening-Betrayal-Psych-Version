package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette.RGBPalettePool;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var useRGBShader(default, set):Bool = true;
	private function set_useRGBShader(value:Bool):Bool
	{
		useRGBShader = value;
		if (rgbShader != null) rgbShader.enabled = value;
		return value;
	}

	// Per-character noteskin (from the character JSON "noteskin" field)
	public var charNoteskin:String = '';

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		if (rgbShader == null) return;
		var idx:Int = noteData % colArray.length;
		if (idx < 0) idx = 0;
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[idx];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[idx];

		if (arr != null && arr.length >= 3)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
		// Keep the "last applied" state in sync so switching note color modes
		// later is not mistaken for a script overriding the shader.
		rememberAppliedColors();
	}

	// Resolves a character noteskin name to an image path, if it exists.
	// JS Engine keeps skins in images/noteskins/, but mods also use images/
	// directly or images/myNotes/, so check all of those locations.
	public static function getCharNoteskinPath(skin:String):String
	{
		if (skin == null || skin.length < 1) return null;
		skin = skin.trim().replace('\\', '/');

		var candidates:Array<String> = [skin];
		if (!skin.contains('/')) {
			candidates.push('noteskins/' + skin);
			candidates.push('noteSkins/' + skin);
			candidates.push('myNotes/' + skin);
		}

		for (path in candidates)
			if (Paths.fileExists('images/$path.png', IMAGE)) return path;
		return null;
	}

	// Applies the noteskin defined on this note's character (JS Engine feature).
	public function applyCharNoteskin(skin:String)
	{
		var path:String = getCharNoteskinPath(skin);
		if (path == null || PlayState.isPixelStage) return;
		charNoteskin = skin;
		texture = path;
		useRGBShader = false;
	}

	// Restores the normal skin when the new character has no noteskin.
	public function resetCharNoteskin()
	{
		if (charNoteskin == null || charNoteskin.length < 1) return;
		charNoteskin = '';
		texture = ''; // reloadNote() resolves the song/default skin from here
		useRGBShader = ClientPrefs.data.enableColorShader && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
		rgbShader.enabled = useRGBShader;
	}

	function charColors():Null<Array<Int>>
	{
		if (PlayState.instance == null || noteData < 0) return null;
		var char = gfNote ? PlayState.instance.gf : (mustPress ? PlayState.instance.boyfriend : PlayState.instance.dad);
		if (char == null) char = PlayState.instance.dad;
		if (char == null) char = PlayState.instance.boyfriend;
		return char != null ? char.healthColorArray : null;
	}

	// The last colors applied by updateRGBColors(). If a script changes the
	// shader colors afterwards we detect it here and keep the custom colors,
	// instead of overwriting them on the next recolor (e.g. a character swap).
	var appliedR:Null<FlxColor> = null;
	var appliedG:Null<FlxColor> = null;
	var appliedB:Null<FlxColor> = null;
	// Once a script (or a custom note type) has set its own shader colors, the
	// engine stops recoloring this note so those colors are never lost.
	public var customRGBLocked:Bool = false;

	function rememberAppliedColors()
	{
		appliedR = rgbShader.r;
		appliedG = rgbShader.g;
		appliedB = rgbShader.b;
	}

	// Same idea for splash colors: -1 means "use the note's shader palette".
	// Values a script set explicitly are kept across recolors.
	var appliedSplashR:FlxColor = -1;
	var appliedSplashG:FlxColor = -1;
	var appliedSplashB:FlxColor = -1;
	public var customSplashLocked:Bool = false;

	function resetSplashColors(force:Bool = false)
	{
		if (!force && !customSplashLocked &&
			(noteSplashData.r != appliedSplashR || noteSplashData.g != appliedSplashG || noteSplashData.b != appliedSplashB))
			customSplashLocked = true; // a script set splash-only colors

		if (customSplashLocked)
		{
			appliedSplashR = noteSplashData.r;
			appliedSplashG = noteSplashData.g;
			appliedSplashB = noteSplashData.b;
			return;
		}
		noteSplashData.r = -1;
		noteSplashData.g = -1;
		noteSplashData.b = -1;
		appliedSplashR = -1;
		appliedSplashG = -1;
		appliedSplashB = -1;
	}

	function setHurtSplashColors()
	{
		noteSplashData.r = 0xFFFF0000;
		noteSplashData.g = 0xFF101010;
		noteSplashData.b = -1;
		noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
		appliedSplashR = noteSplashData.r;
		appliedSplashG = noteSplashData.g;
		appliedSplashB = noteSplashData.b;
	}

	/**
	 * Recolors this note according to the active ClientPrefs note color style.
	 * Ported from FNF JS Engine (JordanSantiagoYT).
	 *
	 * Optional r/g/b arguments let scripts force their own colors on top of the
	 * mode palette (same as JS Engine). Colors a script sets directly on the
	 * shader are preserved across recolors.
	 */
	public function updateRGBColors(?r:FlxColor, ?g:FlxColor, ?b:FlxColor)
	{
		if (!useRGBShader || !ClientPrefs.data.enableColorShader) return;
		if (rgbShader == null) rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));

		if (!customRGBLocked && appliedR != null && (rgbShader.r != appliedR || rgbShader.g != appliedG || rgbShader.b != appliedB))
			customRGBLocked = true; // a script changed the shader colors

		if (customRGBLocked)
		{
			// Keep scripted/custom colors (and splash colors) intact.
			if (r != null) rgbShader.r = r;
			if (g != null) rgbShader.g = g;
			if (b != null) rgbShader.b = b;
			rememberAppliedColors();
			return;
		}

		if (noteType == 'Hurt Note')
		{
			if (!customRGBLocked) {
				rgbShader.assign(RGBPalettePool.get(0xFF101010, 0xFFFF0000, 0xFF990022));
				rememberAppliedColors();
			}
			if (!customSplashLocked) setHurtSplashColors();
		}
		else
		{
			switch (ClientPrefs.data.noteColorStyle)
			{
				case 'Rainbow':
					var rainbowTime:Float = (ClientPrefs.data.rainbowTime != 0 ? ClientPrefs.data.rainbowTime * 1000 : Conductor.crochet);
					rgbShader.assign(RGBPalettePool.getRainbow((strumTime / rainbowTime * 360) % 360));
				case 'Quant-Based':
					var songTime:Float = isSustainNote && parent != null ? parent.strumTime : strumTime;
					backend.CoolUtil.checkNoteQuant(this, songTime, rgbShader);
				case 'Char-Based':
					var colors = charColors();
					if (colors != null) rgbShader.assign(RGBPalettePool.getChar(colors));
					else defaultRGB();
				case 'Grayscale':
					rgbShader.assign(RGBPalettePool.getGray());
				default:
			}
			resetSplashColors();
		}

		if (r != null) rgbShader.r = r;
		if (g != null) rgbShader.g = g;
		if (b != null) rgbShader.b = b;
		rememberAppliedColors();
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}

			// Note type .txt files may set custom rgbShader/splash colors.
			// Detect that here so the color pass below doesn't overwrite them.
			if (value != null && value.length > 1) {
				var preR = rgbShader != null ? rgbShader.r : -1;
				var preG = rgbShader != null ? rgbShader.g : -1;
				var preB = rgbShader != null ? rgbShader.b : -1;
				var preSR = noteSplashData.r, preSG = noteSplashData.g, preSB = noteSplashData.b;
				NoteTypesConfig.applyNoteTypeData(this, value);
				if (rgbShader != null && (rgbShader.r != preR || rgbShader.g != preG || rgbShader.b != preB))
					customRGBLocked = true;
				if (noteSplashData.r != preSR || noteSplashData.g != preSG || noteSplashData.b != preSB)
					customSplashLocked = true;
			}
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}

		// Apply colors after noteType and note-type data are in place.
		if (noteType == 'Hurt Note') {
			if (!customRGBLocked && rgbShader != null) {
				rgbShader.assign(RGBPalettePool.get(0xFF101010, 0xFFFF0000, 0xFF990022));
				rememberAppliedColors();
			}
			if (!customSplashLocked) setHurtSplashColors();
		} else if (ClientPrefs.data.noteColorStyle == 'Normal' || !ClientPrefs.data.enableColorShader) {
			if (!customRGBLocked) defaultRGB();
		} else {
			updateRGBColors();
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int, ?note:Note)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette;
			final style = ClientPrefs.data.noteColorStyle;

			if (note != null)
			{
				// These modes recolor every note individually, so start from a
				// neutral palette until updateRGBColors() assigns the right one.
				switch (style)
				{
					case 'Grayscale', 'Rainbow', 'Char-Based':
						newRGB = RGBPalettePool.getGray();
					default:
						newRGB = getLanePalette(noteData, PlayState.isPixelStage, style == 'Quant-Based');
				}
			}
			else
				newRGB = getLanePalette(noteData, PlayState.isPixelStage, style == 'Quant-Based');

			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	static function getLanePalette(noteData:Int, pixel:Bool, quant:Bool):RGBPalette
	{
		var newRGB:RGBPalette = new RGBPalette();
		var idx:Int = noteData % colArray.length;
		if (idx < 0) idx = 0;
		var arr:Array<FlxColor> = quant ? ClientPrefs.data.quantRGB[idx] : (pixel ? ClientPrefs.data.arrowRGBPixel[idx] : ClientPrefs.data.arrowRGB[idx]);

		if (arr != null && arr.length >= 3)
		{
			newRGB.r = arr[0];
			newRGB.g = arr[1];
			newRGB.b = arr[2];
		}
		else
		{
			newRGB.r = 0xFFFF0000;
			newRGB.g = 0xFF00FF00;
			newRGB.b = 0xFF0000FF;
		}
		return newRGB;
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}
		// Scripts (noteskinchange events, custom note types, etc.) can change
		// a note's texture. Keep the RGB shader active for those notes so the
		// active note colors still apply. Character noteskins opt out through
		// useRGBShader = false in applyCharNoteskin().

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
