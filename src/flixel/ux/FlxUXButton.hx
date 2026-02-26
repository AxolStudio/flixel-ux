package flixel.ux;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.ui.FlxButton.FlxButtonState;

class FlxUXButton extends FlxButton
{
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
	/** Optional per-button assets/style override. */
	public var assets:FlxUXAssets = null;

	/** Optional back-reference used for asset precedence (button -> group -> core). */
	@:allow(flixel.ux.FlxUXGroup)
	private var _uxGroup:FlxUXGroup = null;

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

	/** Centers the label within the current button size (does not resize). */
	public function centerLabel():Void
	{
		if (this.label == null) return;
		this.label.x = x + (width - this.label.width) * 0.5;
		this.label.y = y + (height - this.label.height) * 0.5;
	}

	/** Applies assets/theme rules (called automatically when added/created via FlxUXGroup). */
	public function applyAssets():Void
	{
		var a = resolveAssets();
		if (a == null) return;

		if (a.buttonSkin != null)
		{
			// If nine-slice is specified, render once (cached) to the current size.
			if (a.buttonSkin.nineSlice != null)
			{
				var w = Std.int(Math.max(1, width));
				var h = Std.int(Math.max(1, height));
				var gfx = FlxUXNineSliceCache.get(a.buttonSkin, w, h, 0);
				if (gfx != null)
					loadGraphic(gfx);
			}
			else
			{
				// Keep it compatible with a wide range of Flixel versions.
				var w = a.buttonSkin.width;
				var h = a.buttonSkin.height;
				if (w == null) w = 0;
				if (h == null) h = 0;
				loadGraphic(a.buttonSkin.asset, a.buttonSkin.animated == true, w, h);
			}
		}

		_applyFocusVisual(false);
	}

	private inline function resolveAssets():FlxUXAssets
	{
		if (assets != null) return assets;
		if (_uxGroup != null && _uxGroup.assets != null) return _uxGroup.assets;
		return FlxUXCore.assets;
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
		var a = resolveAssets();
		if (a == null)
			return;

		switch (a.focusStyle)
		{
			case HOVER_ONLY:
				// Do nothing: mouse hover visuals come from FlxButton.
				alpha = 1.0;
				_applyFrame(false, a.focusColor, a.focusFrameThickness);

			case DIM_UNFOCUSED:
				alpha = focused ? 1.0 : a.unfocusedAlpha;
				_applyFrame(false, a.focusColor, a.focusFrameThickness);

			case FRAME:
				alpha = 1.0;
				_applyFrame(focused, a.focusColor, a.focusFrameThickness);
				_applyFocusFrameOverlay(focused, a);

			case SPRITE_ON_BUTTON:
				// TODO (placeholder): for now behave like HOVER_ONLY.
				alpha = 1.0;
				_applyFrame(false, a.focusColor, a.focusFrameThickness);

			case SPRITE_NEXT_TO_BUTTON:
				// TODO (placeholder): for now behave like HOVER_ONLY.
				alpha = 1.0;
				_applyFrame(false, a.focusColor, a.focusFrameThickness);
		}
	}

	private function _applyFocusFrameOverlay(focused:Bool, a:FlxUXAssets):Void
	{
		// Only engage overlay mode when a graphic is provided.
		if (a == null || a.focusFrame == null)
		{
			if (_focusFrameSprite != null)
				_focusFrameSprite.visible = false;
			return;
		}

		if (_focusFrameSprite == null)
		{
			_focusFrameSprite = new FlxSprite();
			_focusFrameSprite.moves = false;
			_focusFrameSprite.visible = false;
		}

		_focusFrameSprite.visible = focused;
		if (!focused) return;

		// Size the overlay to button size (for now). Users can bake padding into the art.
		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));
		var gfx = (a.focusFrame.nineSlice != null) ? FlxUXNineSliceCache.get(a.focusFrame, w, h, 0) : null;
		if (gfx != null)
			_focusFrameSprite.loadGraphic(gfx);
		else
			_focusFrameSprite.loadGraphic(a.focusFrame.asset, a.focusFrame.animated == true, a.focusFrame.width != null ? a.focusFrame.width : 0,
				a.focusFrame.height != null ? a.focusFrame.height : 0);

		_focusFrameSprite.x = x;
		_focusFrameSprite.y = y;
		_focusFrameSprite.scrollFactor.set(scrollFactor.x, scrollFactor.y);
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