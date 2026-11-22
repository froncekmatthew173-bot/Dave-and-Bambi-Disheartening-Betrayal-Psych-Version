package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette.RGBPalettePool;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function playerPosition()
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

		// Rainbow and Quant-Based colors change over time.
		if(useRGBShader && modeColorsActive() && Std.isOfType(FlxG.state, PlayState))
		{
			var style:String = ClientPrefs.data.noteColorStyle;
			if(style == 'Rainbow' || style == 'Quant-Based') updateRGBColors();
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static') || modeColorsActive();
	}

	// Whether the strum should show the active JS Engine color mode even while idle.
	function modeColorsActive():Bool
	{
		return ClientPrefs.data.enableColorShader && ClientPrefs.data.noteColorStyle != 'Normal' && !PlayState.isPixelStage;
	}

	// FNF JS Engine: character noteskin support
	public function updateNoteSkin(skin:String) {
		if (PlayState.isPixelStage) return;

		if (skin == null || skin.length < 1) {
			// Restore the default skin when the new character has none.
			var defaultSkin:String = Note.defaultNoteSkin + Note.getNoteSkinPostfix();
			if (!Paths.fileExists('images/$defaultSkin.png', IMAGE)) defaultSkin = Note.defaultNoteSkin;
			if (texture != defaultSkin) {
				texture = defaultSkin;
				useRGBShader = true;
				rgbShader.enabled = false;
			}
			updateRGBColors();
			return;
		}

		var path:String = Note.getCharNoteskinPath(skin);
		if (path == null || texture == path) return;
		texture = path;
		useRGBShader = false;
		rgbShader.enabled = false;
	}

	// Applies the active note-color mode to this receptor, the same way notes
	// are colored in FNF JS Engine (JordanSantiagoYT).
	public function updateRGBColors() {
		if (rgbShader == null || !useRGBShader) return;

		var palette:RGBPalette = null;
		if (modeColorsActive())
		{
			switch (ClientPrefs.data.noteColorStyle)
			{
				case 'Char-Based':
					var char:Character = (player == 1) ? PlayState.instance.boyfriend : PlayState.instance.dad;
					if (char != null && char.healthColorArray != null)
						palette = RGBPalettePool.getChar(char.healthColorArray);
				case 'Grayscale':
					palette = RGBPalettePool.getGray();
				case 'Rainbow':
					var rainbowTime:Float = (ClientPrefs.data.rainbowTime != 0 ? ClientPrefs.data.rainbowTime * 1000 : Conductor.crochet);
					palette = RGBPalettePool.getRainbow((Conductor.songPosition / rainbowTime * 360) % 360);
				case 'Quant-Based':
					backend.CoolUtil.checkNoteQuant(null, Conductor.songPosition, rgbShader);
					return;
				default:
			}
		}

		if (palette == null) palette = Note.initializeGlobalRGBShader(noteData);
		rgbShader.assign(palette);
	}
}
