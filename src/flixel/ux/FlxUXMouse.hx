package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.PixelSnapping;
import openfl.display.BitmapData;
import openfl.events.Event;

class FlxUXMouse
{
	/** Whether the cursor helper is active. */
	public var enabled:Bool = true;
	/** If true, FlxUX will call `FlxG.mouse.load()` to override the hardware cursor scale. */
	public var overrideHardwareCursor:Bool = true;

	private var loaded:Bool = false;
	private var cursorSprite:FlxSprite;
	private var lastCursorKey:String = null;

	/** Creates a new cursor helper. Call `init()` to install hooks and apply scaling. */
	public function new() {}

	/**
	 * Initializes the cursor helper.
	 *
	 * Installs stage resize/fullscreen hooks (when available) and applies cursor scaling.
	 */
	public function init():Void
	{
		if (!overrideHardwareCursor)
			return;

		if (FlxG.stage != null)
		{
			FlxG.stage.addEventListener(Event.RESIZE, (_) -> reloadCursorScale());
			FlxG.stage.addEventListener(Event.FULLSCREEN, (_) -> reloadCursorScale());
		}

		cursorSprite = new FlxSprite();
		loaded = true;

		reloadCursorScale();
	}

	/**
	 * Recalculates and reapplies cursor scaling based on the current stage size.
	 */
	public function reloadCursorScale():Void
	{
		if (!overrideHardwareCursor || !loaded || FlxG.stage == null)
			return;

		var mScale:Float = FlxG.stage.stageHeight / FlxG.height;

		FlxG.mouse.load(null, mScale, 0, 0);
		FlxG.mouse.cursor.smoothing = false;
		FlxG.mouse.cursor.pixelSnapping = PixelSnapping.ALWAYS;
	}

	/**
	 * Updates the cursor helper.
	 *
	 * Called automatically from FlxUXCore's plugin.
	 */
	public function update(elapsed:Float, pressed:Bool):Void
	{
		if (!enabled || !overrideHardwareCursor || !loaded || !FlxG.mouse.visible)
			return;

		var input:FlxUXCore.GraphicInput = FlxUXCore.mouseCursorGraphic;
		if (input == null)
			return;

		var key:String = Std.string(input);
		if (lastCursorKey != key)
		{
			lastCursorKey = key;
			if (Std.isOfType(input, String))
			{
				var s:String = cast input;
				var bd:BitmapData = openfl.utils.Assets.getBitmapData(s, false);
				if (bd != null && bd.height > 0)
				{
					var fw:Int = bd.width;
					var fh:Int = bd.height;
					if (bd.width == 48 && bd.height == 24)
					{
						cursorSprite.loadGraphic(s, true, 24, 24);
					}
					else if (bd.width == 24 && bd.height == 48)
					{
						cursorSprite.loadGraphic(s, true, 24, 24);
					}
					else
					{
						var frameH:Int = Std.int(bd.height / 2);
						if (frameH > 0)
							cursorSprite.loadGraphic(s, true, bd.width, frameH);
						else
							cursorSprite.loadGraphic(s);
					}
				}
				else
				{
					cursorSprite.loadGraphic(s);
				}
			}
			else
			{
				var g = FlxUX9Slice.toGraphic(input);
				if (g == null)
					return;
				cursorSprite.loadGraphic(g);
			}
			cursorSprite.antialiasing = false;
			cursorSprite.scrollFactor.set();
			if (cursorSprite.frames != null && cursorSprite.frames.frames.length >= 2)
			{
				cursorSprite.animation.add("ux_cursor", [0, 1], 0, false);
				cursorSprite.animation.play("ux_cursor", true);
			}
		}

		cursorSprite.update(elapsed);

		if (cursorSprite.frames != null && cursorSprite.frames.frames.length >= 2)
			cursorSprite.animation.frameIndex = pressed ? 1 : 0;

		var frame = cursorSprite.frame;
		if (frame == null || frame.parent == null) return;

		var fw = Std.int(frame.frame.width);
		var fh = Std.int(frame.frame.height);
		if (fw <= 0 || fh <= 0) return;
		var out = new BitmapData(fw, fh, true, 0x00000000);
		var r = new openfl.geom.Rectangle(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height);
		out.copyPixels(frame.parent.bitmap, r, new openfl.geom.Point(0, 0), null, null, true);

		// Re-load the cursor bitmap each update so we can animate.
		var mScale:Float = (FlxG.stage != null) ? (FlxG.stage.stageHeight / FlxG.height) : 1;
		FlxG.mouse.load(out, mScale, 0, 0);
		FlxG.mouse.cursor.smoothing = false;
		FlxG.mouse.cursor.pixelSnapping = PixelSnapping.ALWAYS;
	}
}