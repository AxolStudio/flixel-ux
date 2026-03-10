package flixel.ux;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.ui.FlxButton.FlxButtonState;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxBitmapText;

class FlxUXButton extends FlxButton
{
	private static inline var DEFAULT_BUTTON_DEPTH:Int = 4;
	private static inline var DEFAULT_UP:FlxColor = 0xFF3A3E4A;
	private static inline var DEFAULT_HOVER:FlxColor = 0xFF4A5060;
	private static inline var DEFAULT_DOWN:FlxColor = 0xFF2C2F38;
	private static inline var DEFAULT_DISABLED:FlxColor = 0xFF232531;

	private var usingDefaultSkin:Bool = false;
	private var usingNineSliceSkin:Bool = false;
	private var skinInput:Null<FlxUXGraphicInput> = null;
	private var skinAnimFps:Int = 0;
	private var lastSkinStateIndex:Int = -1;
	private var lastSkinAnimFrameIndex:Int = -1;
	private var animTime:Float = 0;
	private var animFrameIndex:Int = 0;
	private var animSequence:Array<Int> = null;
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
	private var uxGroup:FlxUXGroup = null;

	/** Optional per-button skin override (null => group/core/default). */
	public var buttonGraphic:Null<FlxUXGraphicInput> = null;
	/** Optional per-button animated skin FPS (<= 0 => group/core fallback). */
	public var buttonSkinFps:Int = 0;
	/** Optional per-button override for whether to use animated default skin when no custom graphic is set. */
	public var buttonUseAnim:Null<Bool> = null;
	/** Optional per-button per-state animation sequences (only used for the animated default sheet). */
	public var buttonAnimUp:Null<Array<Int>> = null;
	public var buttonAnimOver:Null<Array<Int>> = null;
	public var buttonAnimDown:Null<Array<Int>> = null;
	public var buttonAnimDisabled:Null<Array<Int>> = null;

	// Button sounds (null => fall back to group/core; default is no sounds)
	public var buttonSoundOver:Null<FlxSoundAsset> = null;
	public var buttonSoundDown:Null<FlxSoundAsset> = null;
	public var buttonSoundClick:Null<FlxSoundAsset> = null;

	// Button labels (null/0 => fall back to group/core)
	public var buttonLabelFont:Null<String> = null;
	public var buttonLabelSize:Int = 0;
	public var buttonLabelColor:Null<flixel.util.FlxColor> = null;
	/** Optional per-button label color when hovered/highlighted. */
	public var buttonLabelColorHover:Null<flixel.util.FlxColor> = null;
	/** Optional per-button label color when pressed. */
	public var buttonLabelColorDown:Null<flixel.util.FlxColor> = null;
	/** Optional per-button label color when disabled. */
	public var buttonLabelColorDisabled:Null<flixel.util.FlxColor> = null;
	public var buttonLabelAlign:Null<FlxTextAlign> = null;
	public var buttonLabelFactory:Null<flixel.ux.FlxUXCore.FlxUXLabelFactory> = null;

	private var _baseLabelText:String = "";

	/** Clears per-button skin overrides (this button falls back to group/core). */
	public function resetButtonSkin():Void
	{
		buttonGraphic = null;
		buttonSkinFps = 0;
		buttonUseAnim = null;
		buttonAnimUp = null;
		buttonAnimOver = null;
		buttonAnimDown = null;
		buttonAnimDisabled = null;
		applySkin();
	}

	/** Clears per-button sound overrides (this button falls back to group/core, which default to no sounds). */
	public function resetButtonSounds():Void
	{
		buttonSoundOver = null;
		buttonSoundDown = null;
		buttonSoundClick = null;
		applySkin();
	}

	/** Forces the built-in static default sheet for this button (no per-state animation playback). */
	public function useDefaultButtonSkinStatic():Void
	{
		buttonGraphic = null;
		buttonUseAnim = false;
		buttonSkinFps = 0;
		applySkin();
	}

	/** Forces the built-in animated default sheet for this button. */
	public function useDefaultButtonSkinAnim(fps:Int = 0):Void
	{
		buttonGraphic = null;
		buttonUseAnim = true;
		buttonSkinFps = fps;
		applySkin();
	}

	/** Sets a custom skin just for this button. */
	public function setButtonSkin(graphic:FlxUXGraphicInput, fps:Int = 0):Void
	{
		buttonGraphic = graphic;
		buttonSkinFps = fps;
		applySkin();
	}

	/** Overrides per-state animation sequences for just this button. */
	public function setButtonAnimSequences(up:Array<Int>, over:Array<Int>, down:Array<Int>, disabled:Array<Int>):Void
	{
		buttonAnimUp = up;
		buttonAnimOver = over;
		buttonAnimDown = down;
		buttonAnimDisabled = disabled;
		applySkin();
	}

	@:allow(flixel.ux.FlxUXCore)
	@:allow(flixel.ux.FlxUXGroup)
	private inline function _getUXGroup():FlxUXGroup
	{
		return uxGroup;
	}

	private var frameBaseColor:FlxColor = 0xFF3A3E4A;
	private var focusFrameSprite:FlxSprite = null;

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
		super(x, y, label);
		_baseLabelText = label;
		this.action = action;

		onUp.callback = () -> activate();
		// Apply label formatting defaults once at creation.
		applyLabelOptions();

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
		{
			// Autosize is the one time we *do* want to change the underlying size based on label.
			// After this, groups can safely call matchSize()/grid()/etc.
			makeGraphic(w, h, frameBaseColor, true);
			// Keep the current skin consistent with the new size.
			if (usingDefaultSkin)
				_applyDefaultSkin();
			else
				applySkin();
		}

		// Prevent further implicit resizing after the initial autosize.
		autoSizeToLabel = false;

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
		// Preserve the current skin type.
		// IMPORTANT: don't rebuild the base graphic with makeGraphic() here unless we're using the
		// procedural default skin. For 9-slice skins, makeGraphic() can temporarily replace the
		// sprite's graphic and cause bizarre distortion until the next refresh.
		if (usingDefaultSkin)
		{
			makeGraphic(w, h, frameBaseColor, true);
			_applyDefaultSkin();
		}
		else
		{
			// Just re-apply the skin at the new size.
			// applySkin() uses current width/height, so ensure our size is set first.
			this.frameWidth = w;
			this.frameHeight = h;
			applySkin();
		}
		centerLabel();
	}

	/** Centers the label within the current button size (does not resize). */
	public function centerLabel():Void
	{
		if (this.label == null) return;
		// FlxButton's label is a separate object positioned in world coordinates.
		this.label.x = x + (width - this.label.width) * 0.5;
		var yOff:Float = 0;
		// Built-in button art has a 4px "depth"; lift the label when not pressed.
		if (usingNineSliceSkin && skinInput == FlxUXCore.DEFAULT_BUTTON_GRAPHIC_ANIM && status != FlxButtonState.PRESSED)
			yOff = -DEFAULT_BUTTON_DEPTH;
		else if (usingNineSliceSkin && skinInput == FlxUXCore.DEFAULT_BUTTON_GRAPHIC && status != FlxButtonState.PRESSED)
			yOff = -DEFAULT_BUTTON_DEPTH;
		this.label.y = y + (height - this.label.height) * 0.5 + yOff;
	}

	/** Applies label options (font/size/color/align and optional label factory) using precedence: button -> group -> core. */
	public function applyLabelOptions():Void
	{
		// Factory choice
		var factory = (buttonLabelFactory != null) ? buttonLabelFactory : ((uxGroup != null && uxGroup.buttonLabelFactory != null) ? uxGroup.buttonLabelFactory : FlxUXCore.buttonLabelFactory);
		if (factory != null)
		{
			// Replace label sprite if it's not already a custom one.
			var newLabel = factory(this.label != null ? this.label.text : "");
			if (newLabel != null)
			{
				// Remove the old label from the button and attach the new one.
				// FlxButton manages label as a public field.
				this.label = cast newLabel;
			}
		}

		var font:Null<String> = null;
		if (buttonLabelFont != null) font = buttonLabelFont;
		else if (uxGroup != null && uxGroup.buttonLabelFont != null) font = uxGroup.buttonLabelFont;
		else font = FlxUXCore.buttonLabelFont;

		var size:Int = 0;
		if (buttonLabelSize > 0) size = buttonLabelSize;
		else if (uxGroup != null && uxGroup.buttonLabelSize > 0) size = uxGroup.buttonLabelSize;
		else size = FlxUXCore.buttonLabelSize;
		if (size <= 0) size = 14;

		var colorNormal:flixel.util.FlxColor = FlxUXCore.buttonLabelColor;
		if (buttonLabelColor != null) colorNormal = buttonLabelColor;
		else if (uxGroup != null && uxGroup.buttonLabelColor != null) colorNormal = uxGroup.buttonLabelColor;

		var colorHover = FlxUXCore.buttonLabelColorHover;
		if (buttonLabelColorHover != null) colorHover = buttonLabelColorHover;
		else if (uxGroup != null && uxGroup.buttonLabelColorHover != null) colorHover = uxGroup.buttonLabelColorHover;

		var colorDown = FlxUXCore.buttonLabelColorDown;
		if (buttonLabelColorDown != null) colorDown = buttonLabelColorDown;
		else if (uxGroup != null && uxGroup.buttonLabelColorDown != null) colorDown = uxGroup.buttonLabelColorDown;

		var colorDisabled = FlxUXCore.buttonLabelColorDisabled;
		if (buttonLabelColorDisabled != null) colorDisabled = buttonLabelColorDisabled;
		else if (uxGroup != null && uxGroup.buttonLabelColorDisabled != null) colorDisabled = uxGroup.buttonLabelColorDisabled;

		var align:FlxTextAlign = CENTER;
		if (buttonLabelAlign != null) align = buttonLabelAlign;
		else if (uxGroup != null && uxGroup.buttonLabelAlign != null) align = uxGroup.buttonLabelAlign;
		else align = FlxUXCore.buttonLabelAlign;

		// Apply formatting if label is a FlxText.
		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			// Only allow wrapping if the user explicitly inserted a newline.
			// Otherwise, keep a single-line label and grow the button / let users resize.
			if (_baseLabelText != null && _baseLabelText.indexOf("\n") < 0)
				t.fieldWidth = 0;
			else
				t.fieldWidth = Std.int(this.width - marginX * 2);

			t.setFormat(font, size, colorNormal, align);
		}
		// Bitmap labels are user-controlled; we can at least tint.
		else if (Std.isOfType(this.label, FlxBitmapText))
		{
			this.label.color = colorNormal;
		}
		else
		{
			this.label.color = colorNormal;
		}

		_applyLabelStateColor();

		centerLabel();
	}

	private function _applyLabelStateColor():Void
	{
		if (this.label == null) return;
		// Precedence already resolved in applyLabelOptions by storing on fields; here we just pick a state.
		var normal:flixel.util.FlxColor = (buttonLabelColor != null) ? buttonLabelColor
			: ((uxGroup != null && uxGroup.buttonLabelColor != null) ? uxGroup.buttonLabelColor : FlxUXCore.buttonLabelColor);
		var hover:Null<flixel.util.FlxColor> = (buttonLabelColorHover != null) ? buttonLabelColorHover
			: ((uxGroup != null && uxGroup.buttonLabelColorHover != null) ? uxGroup.buttonLabelColorHover : FlxUXCore.buttonLabelColorHover);
		var down:Null<flixel.util.FlxColor> = (buttonLabelColorDown != null) ? buttonLabelColorDown
			: ((uxGroup != null && uxGroup.buttonLabelColorDown != null) ? uxGroup.buttonLabelColorDown : FlxUXCore.buttonLabelColorDown);
		var dis:Null<flixel.util.FlxColor> = (buttonLabelColorDisabled != null) ? buttonLabelColorDisabled
			: ((uxGroup != null && uxGroup.buttonLabelColorDisabled != null) ? uxGroup.buttonLabelColorDisabled : FlxUXCore.buttonLabelColorDisabled);

		var c = normal;
		if (!active)
			c = (dis != null) ? dis : normal;
		else
		{
			switch (status)
			{
				case FlxButtonState.PRESSED:
					c = (down != null) ? down : ((hover != null) ? hover : normal);
				case FlxButtonState.HIGHLIGHT:
					c = (hover != null) ? hover : normal;
				default:
					c = normal;
			}
		}
		this.label.color = c;
	}

	/** Applies this button's skin based on FlxUXCore/group settings (called by FlxUXGroup). */
	@:allow(flixel.ux.FlxUXGroup)
	private function applySkin():Void
	{
		// Apply sound overrides (button -> group -> core). Default is no sounds.
		var sOver = (buttonSoundOver != null) ? buttonSoundOver : ((uxGroup != null && uxGroup.buttonSoundOver != null) ? uxGroup.buttonSoundOver : FlxUXCore.buttonSoundOver);
		var sDown = (buttonSoundDown != null) ? buttonSoundDown : ((uxGroup != null && uxGroup.buttonSoundDown != null) ? uxGroup.buttonSoundDown : FlxUXCore.buttonSoundDown);
		var sClick = (buttonSoundClick != null) ? buttonSoundClick : ((uxGroup != null && uxGroup.buttonSoundClick != null) ? uxGroup.buttonSoundClick : FlxUXCore.buttonSoundClick);
		// FlxButton's events store a FlxSound instance, not an asset id.
		// Keep it simple for users: they provide assets, we load/clear the event sounds.
		if (onOver != null)
		{
			if (sOver != null) onOver.sound.loadEmbedded(sOver, false, false);
			else onOver.sound = null;
		}
		if (onDown != null)
		{
			if (sDown != null) onDown.sound.loadEmbedded(sDown, false, false);
			else onDown.sound = null;
		}
		if (onUp != null)
		{
			if (sClick != null) onUp.sound.loadEmbedded(sClick, false, false);
			else onUp.sound = null;
		}
		// Apply label options (format + optional bitmap label factory)
		applyLabelOptions();

		var input:Null<FlxUXGraphicInput> = null;
		if (buttonGraphic != null)
			input = buttonGraphic;
		else if (uxGroup != null && uxGroup.buttonGraphic != null)
			input = uxGroup.buttonGraphic;
		else
			input = FlxUXCore.buttonGraphic;

		var fps:Int = 0;
		if (buttonSkinFps > 0)
			fps = buttonSkinFps;
		else if (uxGroup != null && uxGroup.buttonSkinFps > 0)
			fps = uxGroup.buttonSkinFps;
		else
			fps = FlxUXCore.buttonSkinFps;

		var useAnim:Bool = FlxUXCore.buttonUseAnim;
		if (buttonUseAnim != null)
			useAnim = buttonUseAnim;
		else if (uxGroup != null && uxGroup.buttonUseAnim != null)
			useAnim = uxGroup.buttonUseAnim;

		if (input == null)
		{
			// Built-in fallback: choose static/animated default sheet based on core/group settings.
			var fallback:FlxUXGraphicInput = (useAnim && fps > 0) ? FlxUXCore.DEFAULT_BUTTON_GRAPHIC_ANIM : FlxUXCore.DEFAULT_BUTTON_GRAPHIC;
			applyGraphicSkin(fallback, (useAnim && fps > 0) ? fps : 0);
			return;
		}

		applyGraphicSkin(input, fps);
	}

	private function applyGraphicSkin(input:FlxUXGraphicInput, fps:Int):Void
	{
		usingDefaultSkin = false;
		usingNineSliceSkin = false;
		skinInput = input;
		skinAnimFps = fps;
		lastSkinStateIndex = -1;
		animTime = 0;
		animFrameIndex = 0;
		animSequence = null;
		lastSkinAnimFrameIndex = -1;

		var w:Int = Std.int(Math.max(1, width));
		var h:Int = Std.int(Math.max(1, height));

		if (Std.isOfType(input, flixel.ux.FlxUX9Slice))
		{
			usingNineSliceSkin = true;
			var ns:flixel.ux.FlxUX9Slice = cast input;
			var gfx:FlxGraphic = FlxUX9Slice.get(ns, w, h, 0);
			if (gfx != null)
				loadGraphic(gfx);
			// If we're configured for animated skins, start a sequence immediately so it can loop
			// even if the user never hovers/presses the button.
			if (skinAnimFps > 0)
			{
				lastSkinStateIndex = 0;
				animSequence = getAnimSequenceForState(0);
				animFrameIndex = 0;
				animTime = 0;
			}
			_updateFrameFromStatus();
		}
		else
		{
			var g:FlxGraphic = flixel.ux.FlxUX9Slice.toGraphic(input);
			if (g != null)
			{
				// Expect a 4-frame vertical spritesheet for FlxButton.
				loadGraphic(g, true, w, h);
				_updateFrameFromStatus();
			}
		}

		antialiasing = false;
		centerLabel();
	}

	private function getAnimSequenceForState(stateIndex:Int):Array<Int>
	{
		switch (stateIndex)
		{
			case 0:
				if (buttonAnimUp != null) return buttonAnimUp;
				if (uxGroup != null && uxGroup.buttonAnimUp != null) return uxGroup.buttonAnimUp;
				return FlxUXCore.buttonAnimUp;
			case 1:
				if (buttonAnimOver != null) return buttonAnimOver;
				if (uxGroup != null && uxGroup.buttonAnimOver != null) return uxGroup.buttonAnimOver;
				return FlxUXCore.buttonAnimOver;
			case 2:
				if (buttonAnimDown != null) return buttonAnimDown;
				if (uxGroup != null && uxGroup.buttonAnimDown != null) return uxGroup.buttonAnimDown;
				return FlxUXCore.buttonAnimDown;
			default:
				if (buttonAnimDisabled != null) return buttonAnimDisabled;
				if (uxGroup != null && uxGroup.buttonAnimDisabled != null) return uxGroup.buttonAnimDisabled;
				return FlxUXCore.buttonAnimDisabled;
		}
	}



	private function _applyDefaultSkin():Void
	{
		usingDefaultSkin = true;
		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));

		makeGraphic(w, h * 4, 0x00000000, true);
		pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, h), DEFAULT_UP);
		pixels.fillRect(new openfl.geom.Rectangle(0, h, w, h), DEFAULT_HOVER);
		pixels.fillRect(new openfl.geom.Rectangle(0, h * 2, w, h), DEFAULT_DOWN);
		pixels.fillRect(new openfl.geom.Rectangle(0, h * 3, w, h), DEFAULT_DISABLED);
		dirty = true;
		// makeGraphic already assigned the pixels/graphic. Calling loadGraphic(pixels) can make us hold a
		// BitmapData reference we don't actually own (and it may get destroyed), causing runtime crashes.
		loadGraphic(graphic, true, w, h);
		centerLabel();
		_updateFrameFromStatus();
	}

	private function _updateFrameFromStatus():Void
	{
		var stateIndex:Int = 0;
		if (!active)
			stateIndex = 3;
		else
		{
			switch (status)
			{
				case FlxButtonState.HIGHLIGHT:
					stateIndex = 1;
				case FlxButtonState.PRESSED:
					stateIndex = 2;
				default:
					stateIndex = 0;
			}
		}

		// Default procedural skin uses a 4-frame vertical sheet.
		if (usingDefaultSkin)
		{
			animation.frameIndex = stateIndex;
			return;
		}

		// Non-default: if it's a nine-slice skin, regenerate per state.
		if (usingNineSliceSkin && skinInput != null)
		{
			if (skinAnimFps > 0)
			{
				if (lastSkinStateIndex != stateIndex)
				{
					lastSkinStateIndex = stateIndex;
					animSequence = getAnimSequenceForState(stateIndex);
					animFrameIndex = 0;
					animTime = 0;
					lastSkinAnimFrameIndex = -1;
				}
			}
			else
			{
				if (lastSkinStateIndex == stateIndex)
					return;
				lastSkinStateIndex = stateIndex;
				animSequence = null;
			}

			var frame:Int = stateIndex;
			var seqIndex:Int = -1;
			if (skinAnimFps > 0 && animSequence != null && animSequence.length > 0)
			{
				seqIndex = animFrameIndex % animSequence.length;
				frame = animSequence[seqIndex];
				// If we're still on the same state and same animation cell as last time, nothing to do.
				if (lastSkinStateIndex == stateIndex && lastSkinAnimFrameIndex == seqIndex)
					return;
				lastSkinAnimFrameIndex = seqIndex;
			}

			var w:Int = Std.int(Math.max(1, width));
			var h:Int = Std.int(Math.max(1, height));
			var ns:flixel.ux.FlxUX9Slice = cast skinInput;
			var gfx:FlxGraphic = FlxUX9Slice.get(ns, w, h, frame);
			if (gfx != null)
				loadGraphic(gfx);
			return;
		}

		// Non-default: if using an image spritesheet, assume it's already a 4-frame vertical sheet.
		if (animation != null && animation.numFrames >= 4)
			animation.frameIndex = stateIndex;
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
		alpha = 1.0;
		if (focusFrameSprite != null)
			focusFrameSprite.visible = false;
	}

	private function _applyFrame(enabled:Bool, color:FlxColor, thickness:Int):Void
	{
		var t = thickness;
		if (t < 1) t = 1;

		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));
		var base = frameBaseColor;

		if (!enabled)
		{
			// Keep a plain graphic so we don't shift visuals unexpectedly.
			makeGraphic(w, h, base, true);
			return;
		}

		makeGraphic(w, h, base, true);
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

		// Advance 9-slice animation time. We do NOT want to reset the state's sequence on every tick;
		// we just want the next sequence index to be rendered.
		if (usingNineSliceSkin && skinInput != null && skinAnimFps > 0)
		{
			if (animSequence == null || animSequence.length <= 1)
			{
				// Ensure the sequence exists for the current state.
				var stateIndex:Int = 0;
				if (!active) stateIndex = 3;
				else
				{
					switch (status)
					{
						case FlxButtonState.HIGHLIGHT:
							stateIndex = 1;
						case FlxButtonState.PRESSED:
							stateIndex = 2;
						default:
							stateIndex = 0;
					}
				}
				animSequence = getAnimSequenceForState(stateIndex);
			}

			if (animSequence != null && animSequence.length > 1)
			{
				animTime += elapsed;
				var frameDur:Float = 1.0 / skinAnimFps;
				while (animTime >= frameDur)
				{
					animTime -= frameDur;
					animFrameIndex++;
					// Force redraw for the new frame cell.
					lastSkinAnimFrameIndex = -1;
				}
			}
		}

		// Pointer UX: treat hover as focus so the group's highlighter follows the mouse.
		if (FlxUXCore.mode == flixel.ux.FlxUXCore.FlxUXInputMode.POINTER)
		{
			if (status == FlxButtonState.HIGHLIGHT && FlxUXCore.focused != this)
				FlxUXCore.setFocused(this);
		}

		_updateFrameFromStatus();
		_applyLabelStateColor();
		centerLabel();
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