package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;
import openfl.display.PixelSnapping;
import openfl.display.BitmapData;
import openfl.events.Event;

class FlxUXMouse
{
	/** Whether the cursor helper is active. */
	public var enabled:Bool = true;

	/** If true, FlxUX will call `FlxG.mouse.load()` to override the hardware cursor scale. */
	public var overrideHardwareCursor:Bool = true;

	/** Frames per second for animated cursors. */
	public var cursorFps:Int = 0;

	/** Frame sequence for cursor "up" state (not pressed). */
	public var cursorAnimUp:Array<Int> = [0];

	/** Frame sequence for cursor "down" state (pressed). */
	public var cursorAnimDown:Array<Int> = [1];

	private var loaded:Bool = false;
	private var cursorSprite:FlxSprite;
	private var lastCursorKey:String = null;
	private var cursorFrames:Array<BitmapData> = [];
	private var cursorFrameW:Int = 0;
	private var cursorFrameH:Int = 0;
	private var animTime:Float = 0;
	private var animIndex:Int = 0;
	private var lastPressed:Bool = false;
	private var lastRenderedFrame:Int = -1;
	private var lastRenderedState:Int = -1;

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
			FlxG.stage.addEventListener(Event.RESIZE, (unused) -> reloadCursorScale());
			FlxG.stage.addEventListener(Event.FULLSCREEN, (unused) -> reloadCursorScale());
		}

		cursorSprite = new FlxSprite();
		loaded = true;
		cursorFrames = [];
		cursorFrameW = 0;
		cursorFrameH = 0;
		animTime = 0;
		animIndex = 0;
		lastPressed = false;
		lastRenderedFrame = -1;
		lastRenderedState = -1;

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

		var input:FlxUXGraphicInput = FlxUXCore.mouseCursorGraphic;
		if (input == null)
			return;

		var key:String = FlxUX9Slice.sourceKey(input);
		if (lastCursorKey != key)
		{
			lastCursorKey = key;
			loadCursorInput(input);
			cursorSprite.antialiasing = false;
			cursorSprite.scrollFactor.set();
			animTime = 0;
			animIndex = 0;
			lastRenderedFrame = -1;
			lastRenderedState = -1;
		}

		var state:Int = pressed ? 1 : 0;
		var seq = pressed ? cursorAnimDown : cursorAnimUp;
		if (seq == null || seq.length == 0)
			seq = [pressed ? 1 : 0];

		if (!pressed && lastPressed)
		{
			animTime = 0;
			animIndex = 0;
		}
		else if (pressed && !lastPressed)
		{
			animTime = 0;
			animIndex = 0;
		}
		lastPressed = pressed;

		if (cursorFps > 0 && seq.length > 1)
		{
			if (cursorFps <= 0)
				cursorFps = 1;
			animTime += elapsed;
			var frameDur:Float = 1.0 / cursorFps;
			while (animTime >= frameDur)
			{
				animTime -= frameDur;
				animIndex++;
			}
		}

		var seqIndex:Int = (seq.length > 0) ? (animIndex % seq.length) : 0;
		var frameIndex:Int = (seq.length > 0) ? seq[seqIndex] : 0;

		if (state == lastRenderedState && frameIndex == lastRenderedFrame)
			return;

		lastRenderedState = state;
		lastRenderedFrame = frameIndex;
		applyHardwareCursorFrame(frameIndex);
	}

	private function loadCursorInput(input:FlxUXGraphicInput):Void
	{
		cursorFrames = [];
		cursorFrameW = 0;
		cursorFrameH = 0;

		var bd:BitmapData = null;
		if (Std.isOfType(input, String))
		{
			try
				bd = openfl.utils.Assets.getBitmapData(cast input, false)
			catch (_:Dynamic)
				bd = null;
		}
		else
		{
			var g = FlxUX9Slice.toGraphic(input);
			bd = (g != null) ? g.bitmap : null;
			if (g != null)
				cursorSprite.loadGraphic(g);
		}

		if (bd == null)
			return;

		var split = detectSpriteSheet(bd);
		cursorFrameW = split.frameWidth;
		cursorFrameH = split.frameHeight;
		if (cursorFrameW <= 0)
			cursorFrameW = bd.width;
		if (cursorFrameH <= 0)
			cursorFrameH = bd.height;
		if (cursorFrameW > bd.width)
			cursorFrameW = bd.width;
		if (cursorFrameH > bd.height)
			cursorFrameH = bd.height;

		var cols:Int = (cursorFrameW > 0) ? Std.int(bd.width / cursorFrameW) : 1;
		var rows:Int = (cursorFrameH > 0) ? Std.int(bd.height / cursorFrameH) : 1;
		if (cols < 1)
			cols = 1;
		if (rows < 1)
			rows = 1;
		var total = cols * rows;

		for (i in 0...total)
		{
			var sx:Int = (i % cols) * cursorFrameW;
			var sy:Int = Std.int(i / cols) * cursorFrameH;
			var out = new BitmapData(cursorFrameW, cursorFrameH, true, 0x00000000);
			out.copyPixels(bd, new openfl.geom.Rectangle(sx, sy, cursorFrameW, cursorFrameH), new openfl.geom.Point(0, 0), null, null, true);
			cursorFrames.push(out);
		}

		if (Std.isOfType(input, String))
		{
			if (total > 1)
				cursorSprite.loadGraphic(cast input, true, cursorFrameW, cursorFrameH);
			else
				cursorSprite.loadGraphic(cast input);
		}
	}

	private function applyHardwareCursorFrame(frameIndex:Int):Void
	{
		if (cursorFrames == null || cursorFrames.length == 0)
			return;
		var i = frameIndex;
		if (i < 0)
			i = 0;
		if (i >= cursorFrames.length)
			i = cursorFrames.length - 1;
		var mScale:Float = (FlxG.stage != null) ? (FlxG.stage.stageHeight / FlxG.height) : 1;
		FlxG.mouse.load(cursorFrames[i], mScale, 0, 0);
		FlxG.mouse.cursor.smoothing = false;
		FlxG.mouse.cursor.pixelSnapping = PixelSnapping.ALWAYS;
	}

	private function detectSpriteSheet(bd:BitmapData):{frameWidth:Int, frameHeight:Int}
	{
		if (bd.width == 48 && bd.height == 24)
			return {frameWidth: 24, frameHeight: 24};
		if (bd.width == 24 && bd.height == 48)
			return {frameWidth: 24, frameHeight: 24};

		if (bd.height % 2 == 0)
		{
			var fh:Int = Std.int(bd.height / 2);
			if (fh > 0)
				return {frameWidth: bd.width, frameHeight: fh};
		}

		return {frameWidth: bd.width, frameHeight: bd.height};
	}
}
