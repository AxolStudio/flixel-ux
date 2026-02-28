package flixel.ux;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.ui.FlxButton.FlxButtonState;

class FlxUXButton extends FlxButton
{
	private static inline var DEFAULT_UP:FlxColor = 0xFF3A3E4A;
	private static inline var DEFAULT_HOVER:FlxColor = 0xFF4A5060;
	private static inline var DEFAULT_DOWN:FlxColor = 0xFF2C2F38;
	private static inline var DEFAULT_DISABLED:FlxColor = 0xFF232531;

	private var _usingDefaultSkin:Bool = false;
	/** Padding around the label used when auto-sizing. */
	public var marginX:Float = 10;
	public var marginY:Float = 6;
	/** If true (default), button `makeGraphic` size is computed from label size. */
	public var autoSizeToLabel:Bool = true;
	/** Optional activation callback invoked when this button is activated via POINTER or NAV. */
	public var action:Void->Void;
	/** Whether this button is currently focused for NAV purposes. */
	public var uxFocused(default, null):Bool = false;
	/** Whether this button is currently showing a NAV "pressed" state. */
	public var uxPressed(default, null):Bool = false;

	/** Optional back-reference used for asset precedence (button -> group -> core). */
	@:allow(flixel.ux.FlxUXGroup)
	private var _uxGroup:FlxUXGroup = null;

	@:allow(flixel.ux.FlxUXCore)
	@:allow(flixel.ux.FlxUXGroup)
	private inline function _getUXGroup():FlxUXGroup
	{
		return _uxGroup;
	}

	// FRAME focus style support: we re-generate the button's background graphic with a border.
	// (This avoids relying on DisplayObject parenting, which FlxSprite/FlxButton don't expose.)
	private var _frameBaseColor:FlxColor = 0xFF3A3E4A;
	private var _focusFrameSprite:FlxSprite = null;

	/**
	 * Creates a UX button.
	 *
	 * @param x X position.
	 * @param y Y position.
	 * @param label Label text.
	 * @param action Optional activation callback.
	 */
	public function new(x:Float = 0, y:Float = 0, label:String = "", ?action:Void->Void)
	{
		// Let FlxButton build its internal label by providing the text up-front.
		// Otherwise `this.label` can be null, depending on Flixel version/setup.
		super(x, y, label);
		this.action = action;

		onUp.callback = () -> activate();

		if (autoSizeToLabel)
			autosize();
	}

	/** Recomputes the button size from the label + margins and rebuilds the base graphic. */
	public function autosize():Void
	{
		if (this.label == null)
			return;

		var w = Std.int(Math.ceil(this.label.width + marginX * 2));
		var h = Std.int(Math.ceil(this.label.height + marginY * 2));
		if (w < 1) w = 1;
		if (h < 1) h = 1;

		// Only change if needed.
		if (Std.int(width) != w || Std.int(height) != h)
			makeGraphic(w, h, _frameBaseColor, true);

		centerLabel();
	}

	/**
	 * Resizes the button to an explicit size.
	 *
	 * This keeps the label centered and (if using the default procedural skin) regenerates the graphic.
	 */
	public function resize(w:Int, h:Int):Void
	{
		if (w < 1) w = 1;
		if (h < 1) h = 1;
		autoSizeToLabel = false;
		makeGraphic(w, h, _frameBaseColor, true);
		_applyDefaultSkin();
		centerLabel();
	}

	/** Centers the label within the current button size (does not resize). */
	public function centerLabel():Void
	{
		if (this.label == null) return;
		this.label.x = x + (width - this.label.width) * 0.5;
		this.label.y = y + (height - this.label.height) * 0.5;
	}

	/** Applies this button's skin based on FlxUXCore/group settings (called by FlxUXGroup). */
	@:allow(flixel.ux.FlxUXGroup)
	private function applySkin():Void
	{
		var input:Dynamic = null;
		if (_uxGroup != null && _uxGroup.buttonGraphic != null)
			input = _uxGroup.buttonGraphic;
		else
			input = FlxUXCore.buttonGraphic;

		if (input == null)
		{
			_applyDefaultSkin();
			return;
		}

		_usingDefaultSkin = false;
		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));

		// 9-slice convenience
		if (Std.isOfType(input, flixel.ux.FlxUX9Slice))
		{
			var ns:flixel.ux.FlxUX9Slice = cast input;
			var gfx = FlxUXNineSliceCache.get(ns, w, h, 0);
			if (gfx != null)
				loadGraphic(gfx);
		}
		else
		{
			var g = flixel.ux.FlxUXGraphics.toGraphic(input);
			if (g != null)
				loadGraphic(g);
		}

		antialiasing = false;
		centerLabel();
	}

	private function _applyDefaultSkin():Void
	{
		_usingDefaultSkin = true;
		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));

		// 4-frame vertical strip: UP, HOVER, DOWN, DISABLED.
		makeGraphic(w, h * 4, 0x00000000, true);
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, h), DEFAULT_UP);
		pixels.fillRect(new openfl.geom.Rectangle(0, h, w, h), DEFAULT_HOVER);
		pixels.fillRect(new openfl.geom.Rectangle(0, h * 2, w, h), DEFAULT_DOWN);
		pixels.fillRect(new openfl.geom.Rectangle(0, h * 3, w, h), DEFAULT_DISABLED);
		dirty = true;
		loadGraphic(pixels, true, w, h);
		centerLabel();
		_updateFrameFromStatus();
	}

	private function _updateFrameFromStatus():Void
	{
		if (!_usingDefaultSkin) return;

		switch (status)
		{
			case FlxButtonState.HIGHLIGHT:
				animation.frameIndex = 1;
			case FlxButtonState.PRESSED:
				animation.frameIndex = 2;
			default:
				animation.frameIndex = 0;
		}
	}

	/**
	 * Sets whether this button is focused for NAV.
	 *
	 * FlxUXCore calls this automatically when focus changes.
	 */
	public function setFocused(focused:Bool):Void
	{
		uxFocused = focused;
		_applyFocusVisual(uxFocused);
	}

	private function _applyFocusVisual(focused:Bool):Void
	{
		// Simple: focus visuals are drawn by the group (frame / next-to / overlay).
		// Keep button visuals stable and FlxButton-like.
		alpha = 1.0;
		if (_focusFrameSprite != null)
			_focusFrameSprite.visible = false;
	}

	private function _applyFrame(enabled:Bool, color:FlxColor, thickness:Int):Void
	{
		var t = thickness;
		if (t < 1) t = 1;

		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));
		var base = _frameBaseColor;

		if (!enabled)
		{
			// Keep a plain graphic so we don't shift visuals unexpectedly.
			makeGraphic(w, h, base, true);
			return;
		}

		makeGraphic(w, h, base, true);
		// Draw border into this sprite's pixels.
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, t), color);
		pixels.fillRect(new openfl.geom.Rectangle(0, h - t, w, t), color);
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, t, h), color);
		pixels.fillRect(new openfl.geom.Rectangle(w - t, 0, t, h), color);
		dirty = true;
	}

	/**
	 * Sets whether this button should appear pressed due to NAV confirm being held.
	 *
	 * This only affects visuals/state. Activation is handled separately.
	 */
	public function setNavPressed(pressed:Bool):Void
	{
		if (uxPressed == pressed)
			return;

		uxPressed = pressed;

		// Keep it simple: drive FlxButton's status so default skins/graphics react.
		// Pointer clicks continue to work normally through FlxButton's own input handling.
		status = uxPressed ? FlxButtonState.PRESSED : FlxButtonState.NORMAL;
		_updateFrameFromStatus();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Pointer UX: treat hover as focus so the group's highlighter follows the mouse.
		if (FlxUXCore.mode == flixel.ux.FlxUXCore.FlxUXInputMode.POINTER)
		{
			if (status == FlxButtonState.HIGHLIGHT && FlxUXCore.focused != this)
				FlxUXCore.setFocused(this);
		}

		_updateFrameFromStatus();
	}

	/**
	 * Returns `true` if the button can currently be interacted with via FlxUX.
	 */
	public inline function isUXEligible():Bool
	{
		return exists && alive && visible && active;
	}

	/**
	 * Activates this button.
	 *
	 * If the button is not eligible, this does nothing.
	 */
	public function activate():Void
	{
		if (!isUXEligible())
			return;

		if (action != null)
			action();
	}
}