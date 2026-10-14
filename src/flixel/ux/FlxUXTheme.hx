package flixel.ux;

import flixel.util.FlxColor;
import haxe.DynamicAccess;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;
import flixel.system.FlxAssets.FlxSoundAsset;

class FlxUXTheme
{
	/** Color used for focus highlights (where applicable). */
	public var focusColor:FlxColor = 0xFFFFFFFF;

	/** Default alpha applied to disabled widgets (where applicable). */
	public var disabledAlpha:Float = 0.4;

	public var pixelArtDefaults:Bool = true;
	public var snapUiToPixels:Bool = true;

	public var buttonUseAnim:Bool = false;
	public var buttonSkinFps:Int = FlxUXCore.DEFAULT_BUTTON_SKIN_FPS;
	public var buttonGraphic:Null<FlxUXGraphicInput> = null;
	public var buttonAnimUp:Array<Int> = [0, 1];
	public var buttonAnimOver:Array<Int> = [2, 3, 4, 5];
	public var buttonAnimDown:Array<Int> = [6, 7, 8, 9];
	public var buttonAnimDisabled:Array<Int> = [10];

	public var buttonSoundOver:Null<FlxSoundAsset> = null;
	public var buttonSoundDown:Null<FlxSoundAsset> = null;
	public var buttonSoundClick:Null<FlxSoundAsset> = null;

	public var buttonLabelFont:Null<String> = null;
	public var buttonLabelSize:Int = 14;
	public var buttonLabelColor:FlxColor = 0xFF666666;
	public var buttonLabelColorHover:Null<FlxColor> = 0xFF333333;
	public var buttonLabelColorDown:Null<FlxColor> = 0xFF333333;
	public var buttonLabelColorDisabled:Null<FlxColor> = 0xFF777777;

	/** Label color when a FlxUXButton is locked (forced DISABLED). Null => fall back to buttonLabelColorDisabled. */
	public var buttonLabelColorLocked:Null<FlxColor> = null;

	public var buttonLabelAlign:String = "center";

	public var focusMode:FlxUXCore.FlxUXFocusMode = FlxUXCore.FlxUXFocusMode.FRAME;
	public var focusFrameFps:Int = FlxUXCore.DEFAULT_FOCUS_FRAME_FPS;
	public var focusFrameGraphic:FlxUXGraphicInput = FlxUXCore.DEFAULT_FOCUS_FRAME_GRAPHIC;
	public var focusNextToGraphic:Null<FlxUXGraphicInput> = null;
	public var focusNextToMirrored:Bool = false;
	public var focusNextToGraphicRight:Null<FlxUXGraphicInput> = null;
	public var focusNextToFlipRight:Bool = true;
	public var focusNextToGap:Float = 6;
	public var focusNextToOffsetY:Float = 0;
	public var focusOverlayGraphic:Null<FlxUXGraphicInput> = null;
	public var focusOverlayOffsetX:Float = -8;
	public var focusOverlayOffsetY:Float = -8;

	public var highlightPadX:Float = 12;
	public var highlightPadY:Float = 12;

	/** Creates a theme from an optional settings object or JSON string. */
	public function new(?data:Dynamic)
	{
		if (data == null)
			return;

		var parsed:FlxUXTheme = Std.isOfType(data, String) ? fromJson(cast data) : fromObject(data);
		copyFrom(parsed);
	}

	private function copyFrom(source:FlxUXTheme):Void
	{
		focusColor = source.focusColor;
		disabledAlpha = source.disabledAlpha;
		pixelArtDefaults = source.pixelArtDefaults;
		snapUiToPixels = source.snapUiToPixels;
		buttonUseAnim = source.buttonUseAnim;
		buttonSkinFps = source.buttonSkinFps;
		buttonGraphic = source.buttonGraphic;
		buttonAnimUp = source.buttonAnimUp;
		buttonAnimOver = source.buttonAnimOver;
		buttonAnimDown = source.buttonAnimDown;
		buttonAnimDisabled = source.buttonAnimDisabled;
		buttonSoundOver = source.buttonSoundOver;
		buttonSoundDown = source.buttonSoundDown;
		buttonSoundClick = source.buttonSoundClick;
		buttonLabelFont = source.buttonLabelFont;
		buttonLabelSize = source.buttonLabelSize;
		buttonLabelColor = source.buttonLabelColor;
		buttonLabelColorHover = source.buttonLabelColorHover;
		buttonLabelColorDown = source.buttonLabelColorDown;
		buttonLabelColorDisabled = source.buttonLabelColorDisabled;
		buttonLabelColorLocked = source.buttonLabelColorLocked;
		buttonLabelAlign = source.buttonLabelAlign;
		focusMode = source.focusMode;
		focusFrameFps = source.focusFrameFps;
		focusFrameGraphic = source.focusFrameGraphic;
		focusNextToGraphic = source.focusNextToGraphic;
		focusNextToMirrored = source.focusNextToMirrored;
		focusNextToGraphicRight = source.focusNextToGraphicRight;
		focusNextToFlipRight = source.focusNextToFlipRight;
		focusNextToGap = source.focusNextToGap;
		focusNextToOffsetY = source.focusNextToOffsetY;
		focusOverlayGraphic = source.focusOverlayGraphic;
		focusOverlayOffsetX = source.focusOverlayOffsetX;
		focusOverlayOffsetY = source.focusOverlayOffsetY;
		highlightPadX = source.highlightPadX;
		highlightPadY = source.highlightPadY;
	}

	/**
	 * Builds a theme from a JSON string.
	 */
	public static function fromJson(json:String):FlxUXTheme
	{
		if (json == null)
			return new FlxUXTheme();
		try
		{
			return fromObject(haxe.Json.parse(json));
		}
		catch (_)
		{
			return new FlxUXTheme();
		}
	}

	/**
	 * Builds a theme from a parsed JSON object.
	 *
	 * Supported fields (optional):
	 * - focusColor: number (0xAARRGGBB) or string ("#RRGGBB" / "#AARRGGBB")
	 * - disabledAlpha: number
	 */
	public static function fromObject(obj:Dynamic):FlxUXTheme
	{
		var t = new FlxUXTheme();
		if (obj == null)
			return t;
		var map:DynamicAccess<Dynamic> = cast obj;

		inline function asString(v:Dynamic, fallback:Null<String>):Null<String>
		{
			if (Std.isOfType(v, String))
				return (v : String);
			return fallback;
		}

		inline function asBool(v:Dynamic, fallback:Bool):Bool
		{
			if (Std.isOfType(v, Bool))
				return (v : Bool);
			if (Std.isOfType(v, Int))
				return ((v : Int) != 0);
			return fallback;
		}

		inline function asInt(v:Dynamic, fallback:Int):Int
		{
			if (Std.isOfType(v, Int))
				return (v : Int);
			if (Std.isOfType(v, Float))
				return Std.int((v : Float));
			return fallback;
		}

		inline function asFloat(v:Dynamic, fallback:Float):Float
		{
			if (Std.isOfType(v, Float) || Std.isOfType(v, Int))
				return (v : Float);
			return fallback;
		}

		inline function asIntArray(v:Dynamic, fallback:Array<Int>):Array<Int>
		{
			if (v == null)
				return fallback;
			if (Std.isOfType(v, Array))
			{
				var out:Array<Int> = [];
				for (x in (v : Array<Dynamic>))
					out.push(asInt(x, 0));
				return out;
			}
			return fallback;
		}

		inline function asNineSlice(v:Dynamic):Null<FlxUXGraphicInput>
		{
			if (v == null)
				return null;
			if (Std.isOfType(v, String))
				return cast(v, String);
			if (Std.isOfType(v, Array) || Std.isOfType(v, Int) || Std.isOfType(v, Float) || Std.isOfType(v, Bool))
				return null;

			var dm:DynamicAccess<Dynamic> = cast v;
			var src:Null<String> = asString(dm.get("source"), null);
			if (src == null)
				src = asString(dm.get("asset"), null);
			if (src == null)
				return null;

			var l:Int = asInt(dm.get("left"), 0);
			var top:Int = asInt(dm.get("top"), 0);
			var r:Int = asInt(dm.get("right"), 0);
			var b:Int = asInt(dm.get("bottom"), 0);
			var fw:Int = asInt(dm.get("frameWidth"), 0);
			var fh:Int = asInt(dm.get("frameHeight"), 0);
			return new flixel.ux.FlxUX9Slice(src, fw, fh, l, top, r, b);
		}

		if (map.exists("disabledAlpha"))
		{
			var v:Dynamic = map.get("disabledAlpha");
			t.disabledAlpha = asFloat(v, t.disabledAlpha);
		}
		if (map.exists("focusColor"))
		{
			var c:Dynamic = map.get("focusColor");
			if (Std.isOfType(c, Int))
				t.focusColor = (c : Int);
			else if (Std.isOfType(c, String))
				t.focusColor = parseColorString(cast c);
		}

		if (map.exists("pixelArtDefaults"))
			t.pixelArtDefaults = asBool(map.get("pixelArtDefaults"), t.pixelArtDefaults);
		if (map.exists("snapUiToPixels"))
			t.snapUiToPixels = asBool(map.get("snapUiToPixels"), t.snapUiToPixels);

		if (map.exists("buttonUseAnim"))
			t.buttonUseAnim = asBool(map.get("buttonUseAnim"), t.buttonUseAnim);
		if (map.exists("buttonSkinFps"))
			t.buttonSkinFps = asInt(map.get("buttonSkinFps"), t.buttonSkinFps);
		if (map.exists("buttonGraphic"))
		{
			var g:Dynamic = map.get("buttonGraphic");
			var parsed:Dynamic = asNineSlice(g);
			if (parsed != null)
				t.buttonGraphic = cast parsed;
		}
		if (map.exists("buttonAnimUp"))
			t.buttonAnimUp = asIntArray(map.get("buttonAnimUp"), t.buttonAnimUp);
		if (map.exists("buttonAnimOver"))
			t.buttonAnimOver = asIntArray(map.get("buttonAnimOver"), t.buttonAnimOver);
		if (map.exists("buttonAnimDown"))
			t.buttonAnimDown = asIntArray(map.get("buttonAnimDown"), t.buttonAnimDown);
		if (map.exists("buttonAnimDisabled"))
			t.buttonAnimDisabled = asIntArray(map.get("buttonAnimDisabled"), t.buttonAnimDisabled);

		if (map.exists("buttonSoundOver"))
		{
			var s:Dynamic = map.get("buttonSoundOver");
			if (Std.isOfType(s, String))
				t.buttonSoundOver = cast(s, String);
		}
		if (map.exists("buttonSoundDown"))
		{
			var s:Dynamic = map.get("buttonSoundDown");
			if (Std.isOfType(s, String))
				t.buttonSoundDown = cast(s, String);
		}
		if (map.exists("buttonSoundClick"))
		{
			var s:Dynamic = map.get("buttonSoundClick");
			if (Std.isOfType(s, String))
				t.buttonSoundClick = cast(s, String);
		}

		if (map.exists("buttonLabelFont"))
			t.buttonLabelFont = asString(map.get("buttonLabelFont"), t.buttonLabelFont);
		if (map.exists("buttonLabelSize"))
			t.buttonLabelSize = asInt(map.get("buttonLabelSize"), t.buttonLabelSize);
		if (map.exists("buttonLabelColor"))
		{
			var c:Dynamic = map.get("buttonLabelColor");
			if (Std.isOfType(c, Int))
				t.buttonLabelColor = (c : Int);
			else if (Std.isOfType(c, String))
				t.buttonLabelColor = parseColorString(cast c);
		}
		if (map.exists("buttonLabelColorHover"))
		{
			var c:Dynamic = map.get("buttonLabelColorHover");
			if (Std.isOfType(c, Int))
				t.buttonLabelColorHover = (c : Int);
			else if (Std.isOfType(c, String))
				t.buttonLabelColorHover = parseColorString(cast c);
		}
		if (map.exists("buttonLabelColorDown"))
		{
			var c:Dynamic = map.get("buttonLabelColorDown");
			if (Std.isOfType(c, Int))
				t.buttonLabelColorDown = (c : Int);
			else if (Std.isOfType(c, String))
				t.buttonLabelColorDown = parseColorString(cast c);
		}
		if (map.exists("buttonLabelColorDisabled"))
		{
			var c:Dynamic = map.get("buttonLabelColorDisabled");
			if (Std.isOfType(c, Int))
				t.buttonLabelColorDisabled = (c : Int);
			else if (Std.isOfType(c, String))
				t.buttonLabelColorDisabled = parseColorString(cast c);
		}
		if (map.exists("buttonLabelColorLocked"))
		{
			var c:Dynamic = map.get("buttonLabelColorLocked");
			if (Std.isOfType(c, Int))
				t.buttonLabelColorLocked = (c : Int);
			else if (Std.isOfType(c, String))
				t.buttonLabelColorLocked = parseColorString(cast c);
		}
		if (map.exists("buttonLabelAlign"))
			t.buttonLabelAlign = asString(map.get("buttonLabelAlign"), t.buttonLabelAlign);

		if (map.exists("focusMode"))
		{
			var m:Dynamic = map.get("focusMode");
			if (Std.isOfType(m, String))
			{
				switch (StringTools.trim((m : String)).toUpperCase())
				{
					case "FRAME":
						t.focusMode = FlxUXCore.FlxUXFocusMode.FRAME;
					case "NEXT_TO":
						t.focusMode = FlxUXCore.FlxUXFocusMode.NEXT_TO;
					case "OVERLAY":
						t.focusMode = FlxUXCore.FlxUXFocusMode.OVERLAY;
					case "HOVER_ONLY":
						t.focusMode = FlxUXCore.FlxUXFocusMode.HOVER_ONLY;
					case "DIM_UNFOCUSED":
						t.focusMode = FlxUXCore.FlxUXFocusMode.DIM_UNFOCUSED;
					default:
				}
			}
		}
		if (map.exists("focusFrameFps"))
			t.focusFrameFps = asInt(map.get("focusFrameFps"), t.focusFrameFps);
		if (map.exists("focusFrameGraphic"))
		{
			var fg:Dynamic = map.get("focusFrameGraphic");
			var parsedFg:Dynamic = asNineSlice(fg);
			if (parsedFg != null)
				t.focusFrameGraphic = cast parsedFg;
		}
		if (map.exists("focusNextToGraphic"))
		{
			var ng:Dynamic = map.get("focusNextToGraphic");
			if (Std.isOfType(ng, String))
				t.focusNextToGraphic = cast(ng, String);
		}
		if (map.exists("focusNextToMirrored"))
			t.focusNextToMirrored = asBool(map.get("focusNextToMirrored"), t.focusNextToMirrored);
		if (map.exists("focusNextToGraphicRight"))
		{
			var ngr:Dynamic = map.get("focusNextToGraphicRight");
			if (Std.isOfType(ngr, String))
				t.focusNextToGraphicRight = cast(ngr, String);
		}
		if (map.exists("focusNextToFlipRight"))
			t.focusNextToFlipRight = asBool(map.get("focusNextToFlipRight"), t.focusNextToFlipRight);
		if (map.exists("focusNextToGap"))
			t.focusNextToGap = asFloat(map.get("focusNextToGap"), t.focusNextToGap);
		if (map.exists("focusNextToOffsetY"))
			t.focusNextToOffsetY = asFloat(map.get("focusNextToOffsetY"), t.focusNextToOffsetY);
		if (map.exists("focusOverlayGraphic"))
		{
			var og:Dynamic = map.get("focusOverlayGraphic");
			if (Std.isOfType(og, String))
				t.focusOverlayGraphic = cast(og, String);
		}
		if (map.exists("focusOverlayOffsetX"))
			t.focusOverlayOffsetX = asFloat(map.get("focusOverlayOffsetX"), t.focusOverlayOffsetX);
		if (map.exists("focusOverlayOffsetY"))
			t.focusOverlayOffsetY = asFloat(map.get("focusOverlayOffsetY"), t.focusOverlayOffsetY);

		if (map.exists("highlightPadX"))
			t.highlightPadX = asFloat(map.get("highlightPadX"), t.highlightPadX);
		if (map.exists("highlightPadY"))
			t.highlightPadY = asFloat(map.get("highlightPadY"), t.highlightPadY);

		return t;
	}

	/**
	 * Parses a common color string.
	 */
	private static function parseColorString(s:String):FlxColor
	{
		if (s == null)
			return FlxColor.WHITE;
		var color = FlxColor.fromString(s);
		return (color != null) ? color : FlxColor.WHITE;
	}
}
