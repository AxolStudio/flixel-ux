package flixel.ux;

/** Generic sprite graphic spec: single graphic OR spritesheet animation, optionally 9-sliced. */
typedef FlxUXGraphicSpec =
{
	/** Asset id/path or BitmapData/etc (whatever Flixel accepts). */
	var asset:Dynamic;

	/** Frame size for spritesheets (and for single-frame too if you want explicit sizing). */
	@:optional var width:Int;
	@:optional var height:Int;

	/** If true, treat as an animated spritesheet (LoadGraphic animated=true). */
	@:optional var animated:Bool;

	/** Optional list of frame indices used for animation. */
	@:optional var frames:Array<Int>;

	/** Optional animation fps. */
	@:optional var fps:Int;

	/** Optional nine-slice definition (for scalable frames/buttons). */
	@:optional var nineSlice:FlxUXNineSliceSpec;
}

typedef FlxUXNineSliceSpec =
{
	var left:Int;
	var top:Int;
	var right:Int;
	var bottom:Int;
}

enum FlxUXSide
{
	LEFT;
	RIGHT;
	BOTH;
}

/** Spec for a focus sprite that appears next to the button. */
typedef FlxUXSideSpriteSpec =
{
	var graphic:FlxUXGraphicSpec;
	@:optional var graphicOther:FlxUXGraphicSpec;
	var side:FlxUXSide;
	@:optional var mirrorOther:Bool;
	@:optional var gap:Float;
	@:optional var offsetY:Float;
}

enum FlxUXAnchor
{
	TOP_LEFT;
	TOP_RIGHT;
	BOTTOM_LEFT;
	BOTTOM_RIGHT;
	CENTER;
}

/** Spec for a focus sprite that overlays the button itself. */
typedef FlxUXOverlaySpriteSpec =
{
	var graphic:FlxUXGraphicSpec;
	@:optional var anchor:FlxUXAnchor;
	@:optional var offsetX:Float;
	@:optional var offsetY:Float;
}

typedef FlxUXBitmapFontSpec =
{
	var asset:Dynamic;
	@:optional var size:Int;
}
