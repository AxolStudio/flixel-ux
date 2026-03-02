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

	private var _loaded:Bool = false;
	private var _cursorSprite:FlxSprite;
	private var _lastCursorKey:String = null;

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

		_cursorSprite = new FlxSprite();
		_loaded = true;

		reloadCursorScale();
	}

	/**
	 * Recalculates and reapplies cursor scaling based on the current stage size.
	 */
	public function reloadCursorScale():Void
	{
		if (!overrideHardwareCursor || !_loaded || FlxG.stage == null)
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
		if (!enabled || !overrideHardwareCursor || !_loaded || !FlxG.mouse.visible)
			return;

		var input:Dynamic = FlxUXCore.mouseCursorGraphic;
		if (input == null)
			return;

		// Load/refresh cursor sprite if needed
		var key = Std.string(input);
		if (_lastCursorKey != key)
		{
			_lastCursorKey = key;
			// Cursor supports a 2-frame convention (up/down). If the source is a spritesheet,
			// we load it as animated with inferred frame size.
			if (Std.isOfType(input, String))
			{
				var s:String = cast input;
				var bd = openfl.utils.Assets.getBitmapData(s, false);
				if (bd != null && bd.height > 0)
				{
					// Default FlxUX cursor is 2 frames (up/down) of 24x24.
					// The sheet may be either horizontal (48x24) or vertical (24x48).
					var fw = bd.width;
					var fh = bd.height;
					if (bd.width == 48 && bd.height == 24)
					{
						// Horizontal strip: 2 columns
						_cursorSprite.loadGraphic(s, true, 24, 24);
					}
					else if (bd.width == 24 && bd.height == 48)
					{
						// Vertical strip: 2 rows
						_cursorSprite.loadGraphic(s, true, 24, 24);
					}
					else
					{
						// Generic fallback: assume 2 frames stacked vertically.
						var frameH = Std.int(bd.height / 2);
						if (frameH > 0)
							_cursorSprite.loadGraphic(s, true, bd.width, frameH);
						else
							_cursorSprite.loadGraphic(s);
					}
				}
				else
				{
					_cursorSprite.loadGraphic(s);
				}
			}
			else
			{
				var g = FlxUX9Slice.toGraphic(input);
				if (g == null)
					return;
				_cursorSprite.loadGraphic(g);
			}
			_cursorSprite.antialiasing = false;
			_cursorSprite.scrollFactor.set();
			// Ensure a predictable 2-frame animation exists if frames are available.
			if (_cursorSprite.frames != null && _cursorSprite.frames.frames.length >= 2)
			{
				// fps=0 (or 1) doesn't matter; we manually set frameIndex.
				_cursorSprite.animation.add("ux_cursor", [0, 1], 0, false);
				_cursorSprite.animation.play("ux_cursor", true);
			}
		}

		_cursorSprite.update(elapsed);

		// Use 2-frame convention if possible: frame 1 while pressed.
		if (_cursorSprite.frames != null && _cursorSprite.frames.frames.length >= 2)
			_cursorSprite.animation.frameIndex = pressed ? 1 : 0;

		// Copy current frame pixels into the actual hardware cursor bitmap.
		var frame = _cursorSprite.frame;
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