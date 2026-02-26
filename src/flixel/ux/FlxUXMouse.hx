package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.PixelSnapping;
import openfl.events.Event;

class FlxUXMouse
{
	/** Whether the cursor helper is active. */
	public var enabled:Bool = true;
	/** If true, FlxUX will call `FlxG.mouse.load()` to override the hardware cursor scale. */
	public var overrideHardwareCursor:Bool = true;

	private var _loaded:Bool = false;
	private var _cursorSprite:FlxSprite;

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

		// TODO: update FlxG.mouse.cursor.bitmapData from cursor sprite frame
	}
}