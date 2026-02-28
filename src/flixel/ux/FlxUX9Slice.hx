package flixel.ux;

/**
 * Simple 9-slice description.
 *
 * This is intentionally Flixel-style and lightweight: you provide a source graphic and the slice sizes.
 * FlxUX will render it to the requested size internally (cached).
 */
class FlxUX9Slice
{
	/** Source graphic input (String asset id/path, FlxGraphic, FlxSprite, BitmapData, etc). */
	public var source:Dynamic;

	/** Optional frame size if source is a spritesheet. */
	public var frameWidth:Int;
	public var frameHeight:Int;

	/** 9-slice borders. */
	public var left:Int;
	public var top:Int;
	public var right:Int;
	public var bottom:Int;

	public function new(source:Dynamic, frameWidth:Int, frameHeight:Int, left:Int, top:Int, right:Int, bottom:Int)
	{
		this.source = source;
		this.frameWidth = frameWidth;
		this.frameHeight = frameHeight;
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}
}
