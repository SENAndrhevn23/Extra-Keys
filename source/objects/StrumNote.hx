package objects;

import backend.animation.PsychAnimationController;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var useRGBShader:Bool = true;

	private var _texture:String = null;
	public var texture(get, set):String;
	private function get_texture():String return _texture;
	private function set_texture(value:String):String
	{
		if (_texture != value)
		{
			_texture = value;
			reloadNote();
		}
		return _texture;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int)
	{
		super(x, y);
		animation = new PsychAnimationController(this);

		noteData = leData;
		this.player = player;
		ID = noteData;

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB)
			useRGBShader = false;

		var arr:Array<FlxColor> = null;
		if (PlayState.isPixelStage)
		{
			if (ClientPrefs.data.arrowRGBPixel != null && leData >= 0 && leData < ClientPrefs.data.arrowRGBPixel.length)
				arr = ClientPrefs.data.arrowRGBPixel[leData];
		}
		else
		{
			if (ClientPrefs.data.arrowRGB != null && leData >= 0 && leData < ClientPrefs.data.arrowRGB.length)
				arr = ClientPrefs.data.arrowRGB[leData];
		}

		if (arr != null && arr.length >= 3)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		_texture = Note.defaultNoteSkin;
		reloadNote();
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote():Void
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		var skin:String = _texture;
		if (skin == null || skin == '')
			skin = Note.defaultNoteSkin;

		if (PlayState.isPixelStage)
		{
			var pixelSkin:String = 'pixelUI/' + skin;
			var graphic = Paths.image(pixelSkin);
			if (graphic != null)
			{
				loadGraphic(graphic, true, Std.int(graphic.width / 4), Std.int(graphic.height / 5));
				antialiasing = false;
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			}
		}
		else
		{
			var atlas = Paths.getSparrowAtlas(skin);
			if (atlas == null)
			{
				trace('Missing strum atlas: ' + skin);
				atlas = Paths.getSparrowAtlas(Note.defaultNoteSkin);
			}
			if (atlas != null)
				frames = atlas;

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));
		}

		updateHitbox();
		if (lastAnim != null)
			playAnim(lastAnim, true);
	}

	public function playAnim(anim:String, ?force:Bool = false):Void
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if (useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	override function update(elapsed:Float):Void
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}
}
