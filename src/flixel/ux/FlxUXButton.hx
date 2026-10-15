package flixel.ux;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText;
import flixel.ui.FlxBitmapTextButton;
import flixel.ui.FlxButton.FlxButtonState;
import flixel.util.FlxColor;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;

class FlxUXButton extends FlxBitmapTextButton
{
	public var text(get, set):String;

	private inline function get_text():String
	{
		return label != null ? label.text : null;
	}

	private function set_text(value:String):String
	{
		setLabelText(value);
		return value;
	}

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

	public var tabStop:Bool = true;
	public var scrollPanel:Null<FlxUXScrollPanel> = null;
	public var hotkey(default, set):Null<String> = null;
	public var accessKey(default, set):Null<String> = null;
	public var showKeyboardCues:Bool = true;
	public var showDefaultIndicator:Bool = true;
	public var defaultIndicatorColor:Null<FlxColor> = null;
	public var keyboardCuesVisible(default, null):Bool = false;

	private var hotkeyInput:FlxUXShortcut;
	private var accessKeyInput:FlxUXShortcut;
	private var shortcutLabel:FlxBitmapText;
	private var mnemonicUnderline:FlxSprite;
	private var defaultIndicator:FlxSprite;
	private var defaultIndicatorWidth:Int = -1;
	private var defaultIndicatorHeight:Int = -1;

	private function set_hotkey(value:Null<String>):Null<String>
	{
		hotkey = value;
		hotkeyInput = value == null ? null : new FlxUXShortcut(value);
		if (shortcutLabel != null)
			shortcutLabel.destroy();
		shortcutLabel = null;
		if (hotkeyInput != null && hotkeyInput.valid)
		{
			shortcutLabel = new FlxBitmapText();
			shortcutLabel.text = value;
			shortcutLabel.scale.set(2, 2);
			shortcutLabel.autoSize = true;
			shortcutLabel.updateHitbox();
		}
		if (constructed && autoSizeToLabel)
			autosize();
		return value;
	}

	private function set_accessKey(value:Null<String>):Null<String>
	{
		accessKey = value;
		accessKeyInput = value == null || value.length != 1 ? null : new FlxUXShortcut("ALT+" + value);
		return value;
	}

	/** Whether this button is currently focused for NAV purposes. */
	public var uxFocused(default, null):Bool = false;

	/** Whether this button is currently showing a NAV "pressed" state. */
	public var uxPressed(default, null):Bool = false;

	/**
	 * If true, the button is visually and interactively DISABLED (4th state).
	 *
	 * Contract:
	 * - Does NOT change FlxBasic.active.
	 * - Prevents focus and activation.
	 * - Forces the button to stay in the DISABLED visual state until unlocked.
	 */
	public var locked(get, set):Bool;

	private var _locked:Bool = false;

	private inline function get_locked():Bool
		return _locked;

	private function set_locked(v:Bool):Bool
	{
		if (_locked == v)
			return _locked;
		_locked = v;

		if (_locked)
		{
			uxFocused = false;
			uxPressed = false;
			if (FlxUXCore.focused == this)
				FlxUXCore.setFocused(null);
			status = FlxButtonState.DISABLED;
		}
		else
		{
			status = FlxButtonState.NORMAL;
		}

		updateFrameFromStatus();
		applyLabelStateColor();
		return _locked;
	}

	/** Optional back-reference used for asset precedence (button -> group -> core). */
	@:allow(flixel.ux.FlxUXGroup)
	private var uxGroup:FlxUXGroup = null;

	/**
	 * Optional per-button theme.
	 *
	 * Setting this copies theme fields onto the button's override variables and calls `applySkin()`.
	 */
	public var theme(get, set):Null<FlxUXTheme>;

	private var currentTheme:Null<FlxUXTheme> = null;

	private function get_theme():Null<FlxUXTheme>
	{
		return currentTheme;
	}

	private function set_theme(value:Null<FlxUXTheme>):Null<FlxUXTheme>
	{
		currentTheme = value;
		if (value == null)
		{
			resetButtonSkin();
			resetButtonSounds();
			buttonLabelFont = null;
			buttonLabelSize = 0;
			buttonLabelColor = null;
			buttonLabelColorHover = null;
			buttonLabelColorDown = null;
			buttonLabelColorDisabled = null;
			buttonLabelColorLocked = null;
			buttonLabelAlign = null;
			buttonLabelFactory = null;
		}
		else
		{
			buttonUseAnim = value.buttonUseAnim;
			buttonSkinFps = value.buttonSkinFps;
			buttonGraphic = value.buttonGraphic;
			buttonAnimUp = value.buttonAnimUp;
			buttonAnimOver = value.buttonAnimOver;
			buttonAnimDown = value.buttonAnimDown;
			buttonAnimDisabled = value.buttonAnimDisabled;
			buttonSoundOver = value.buttonSoundOver;
			buttonSoundDown = value.buttonSoundDown;
			buttonSoundClick = value.buttonSoundClick;
			buttonLabelFont = value.buttonLabelFont;
			buttonLabelSize = value.buttonLabelSize;
			buttonLabelColor = value.buttonLabelColor;
			buttonLabelColorHover = value.buttonLabelColorHover;
			buttonLabelColorDown = value.buttonLabelColorDown;
			buttonLabelColorDisabled = value.buttonLabelColorDisabled;
			buttonLabelColorLocked = value.buttonLabelColorLocked;
			buttonLabelAlign = switch (StringTools.trim(value.buttonLabelAlign).toLowerCase())
			{
				case "left": flixel.text.FlxText.FlxTextAlign.LEFT;
				case "right": flixel.text.FlxText.FlxTextAlign.RIGHT;
				default: flixel.text.FlxText.FlxTextAlign.CENTER;
			};
		}
		applyLabelOptions();
		applySkin();
		return currentTheme;
	}

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

	public var buttonSoundOver:Null<FlxSoundAsset> = null;
	public var buttonSoundDown:Null<FlxSoundAsset> = null;
	public var buttonSoundClick:Null<FlxSoundAsset> = null;

	public var buttonLabelFont:Null<String> = null;
	public var buttonLabelSize:Int = 0;
	public var buttonLabelColor:Null<flixel.util.FlxColor> = null;

	/** Optional per-button label color when hovered/highlighted. */
	public var buttonLabelColorHover:Null<flixel.util.FlxColor> = null;

	/** Optional per-button label color when pressed. */
	public var buttonLabelColorDown:Null<flixel.util.FlxColor> = null;

	/** Optional per-button label color when disabled. */
	public var buttonLabelColorDisabled:Null<flixel.util.FlxColor> = null;

	/** Optional per-button label color when locked (forced DISABLED). */
	public var buttonLabelColorLocked:Null<flixel.util.FlxColor> = null;

	public var buttonLabelAlign:Null<FlxTextAlign> = null;
	public var buttonLabelFactory:Null<flixel.ux.FlxUXCore.FlxUXLabelFactory> = null;

	private var baseLabelText:String = "";
	private var constructed:Bool = false;
	private var explicitSizeLocked:Bool = false;

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
	private inline function getUXGroup():FlxUXGroup
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
		baseLabelText = label;
		this.action = action;

		onUp.callback = () -> activate();
		applyLabelOptions();
		if (autoSizeToLabel)
			autosize();
		applySkin();
		constructed = true;
	}

	/**
	 * Preferred way to change a button's label text.
	 *
	 * Contract:
	 * - No wrapping unless `text` contains `\n`.
	 * - If `autoSizeToLabel` is enabled, the button auto-sizes exactly once (now),
	 *   and will not change size again unless the label text changes later.
	 */
	public function setLabelText(text:String):Void
	{
		baseLabelText = text;
		if (this.label != null)
		{
			this.label.text = text;
			this.label.autoSize = true;
			this.label.updateHitbox();
		}
		applyLabelOptions();
		if (autoSizeToLabel)
			autosize();
	}

	/** Recomputes the button size from the label + margins and rebuilds the base graphic. */
	public function autosize():Void
	{
		if (this.label == null)
			return;
		if (Std.isOfType(this.label, FlxBitmapText))
		{
			var text:FlxBitmapText = cast this.label;
			text.autoSize = true;
			text.fieldWidth = 0;
		}

		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			try
			{
				t.textField.text = t.text;
				t.textField.width = 1;
				t.textField.height = 1;
			}
			catch (e:Dynamic) {}
			t.calcFrame();
		}

		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			t.wordWrap = false;
			t.fieldWidth = 0;
		}

		var labelW:Float = this.label.width;
		var labelH:Float = this.label.height;
		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			try
			{
				labelW = t.textField.textWidth + 4;
				labelH = t.textField.textHeight + 4;
			}
			catch (e:Dynamic) {}
		}

		if (labelW <= 0 && Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			labelW = Math.max(1, t.textField.textWidth + 4);
		}
		if (labelH <= 0 && Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			labelH = Math.max(1, t.textField.textHeight + 4);
		}

		var w = Std.int(Math.ceil(labelW + marginX * 2 + (shortcutLabel == null ? 0 : shortcutLabel.width + 12)));
		var h = Std.int(Math.ceil(labelH + marginY * 2 + (shortcutLabel == null ? 0 : shortcutLabel.height + 4)));
		if (w < 1)
			w = 1;
		if (h < 1)
			h = 1;

		explicitSizeLocked = false;
		if (Std.int(width) != w || Std.int(height) != h)
		{
			makeGraphic(w, h, frameBaseColor, true);
			if (usingDefaultSkin)
				applyDefaultSkin();
			else
				applySkin();
		}

		centerLabel();
	}

	/**
	 * Resizes the button to an explicit size.
	 *
	 * This keeps the label centered and (if using the default procedural skin) regenerates the graphic.
	 */
	public function resize(w:Int, h:Int):Void
	{
		if (w < 1)
			w = 1;
		if (h < 1)
			h = 1;
		autoSizeToLabel = false;
		explicitSizeLocked = true;
		this.setGraphicSize(w, h);
		this.updateHitbox();
		this.frameWidth = w;
		this.frameHeight = h;
		if (usingDefaultSkin)
		{
			makeGraphic(w, h, frameBaseColor, true);
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
			applyDefaultSkin();
		}
		else
		{
			applySkin();
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
		}
		centerLabel();
	}

	/** Centers the label within the current button size (does not resize). */
	public function centerLabel():Void
	{
		if (this.label == null)
			return;
		if (Std.isOfType(this.label, FlxBitmapText))
		{
			var text:FlxBitmapText = cast this.label;
			text.alignment = buttonLabelAlign != null ? buttonLabelAlign : uxGroup != null
				&& uxGroup.buttonLabelAlign != null ? uxGroup.buttonLabelAlign : FlxUXCore.buttonLabelAlign;
			text.autoSize = false;
			text.fieldWidth = Std.int(width / text.scale.x);
			text.updateHitbox();
		}
		this.label.x = x + (width - this.label.width) * 0.5;
		this.label.y = y + (height - this.label.height) * 0.5;
		if (Std.isOfType(this.label, FlxBitmapText))
		{
			var text:FlxBitmapText = cast this.label;
			var top:Float = Math.POSITIVE_INFINITY;
			var bottom:Float = Math.NEGATIVE_INFINITY;
			for (index in 0...text.text.length)
			{
				var frame:flixel.graphics.frames.FlxFrame = text.font.getCharFrame(text.text.charCodeAt(index));
				if (frame == null || frame.frame.height == 0)
					continue;
				top = Math.min(top, frame.offset.y);
				bottom = Math.max(bottom, frame.offset.y + frame.frame.height);
			}
			if (top != Math.POSITIVE_INFINITY)
			{
				bottom += (text.numLines - 1) * (text.font.lineHeight + text.lineSpacing);
				text.y = y + height * 0.5 - (top + bottom) * text.scale.y * 0.5;
			}
		}
		if (shortcutLabel != null && height >= label.height + shortcutLabel.height + 8)
			label.y -= (shortcutLabel.height + 4) * 0.5;
	}

	override function updateLabelPosition():Void
	{
		if (!constructed)
		{
			super.updateLabelPosition();
			return;
		}
		centerLabel();
		if (status == FlxButtonState.PRESSED && label != null)
			label.y += pressedLabelOffsetY;
	}

	/** Pixel offset applied to the centered label while the button is pressed. */
	public var pressedLabelOffsetY:Float = 1;

	/** Applies label options (font/size/color/align and optional label factory) using precedence: button -> group -> core. */
	public function applyLabelOptions():Void
	{
		if (!constructed)
		{
			var factory = (buttonLabelFactory != null) ? buttonLabelFactory : ((uxGroup != null && uxGroup.buttonLabelFactory != null) ? uxGroup.buttonLabelFactory : FlxUXCore.buttonLabelFactory);
			if (factory != null)
			{
				var newLabel = factory(this.label != null ? this.label.text : "");
				if (newLabel != null && newLabel != this.label)
					this.label = cast newLabel;
			}
		}

		var font:Null<String> = null;
		if (buttonLabelFont != null)
			font = buttonLabelFont;
		else if (uxGroup != null && uxGroup.buttonLabelFont != null)
			font = uxGroup.buttonLabelFont;
		else
			font = FlxUXCore.buttonLabelFont;

		var size:Int = 0;
		if (buttonLabelSize > 0)
			size = buttonLabelSize;
		else if (uxGroup != null && uxGroup.buttonLabelSize > 0)
			size = uxGroup.buttonLabelSize;
		else
			size = FlxUXCore.buttonLabelSize;
		if (size <= 0)
			size = 14;

		var colorNormal:flixel.util.FlxColor = FlxUXCore.buttonLabelColor;
		if (buttonLabelColor != null)
			colorNormal = buttonLabelColor;
		else if (uxGroup != null && uxGroup.buttonLabelColor != null)
			colorNormal = uxGroup.buttonLabelColor;

		var colorHover = FlxUXCore.buttonLabelColorHover;
		if (buttonLabelColorHover != null)
			colorHover = buttonLabelColorHover;
		else if (uxGroup != null && uxGroup.buttonLabelColorHover != null)
			colorHover = uxGroup.buttonLabelColorHover;

		var colorDown = FlxUXCore.buttonLabelColorDown;
		if (buttonLabelColorDown != null)
			colorDown = buttonLabelColorDown;
		else if (uxGroup != null && uxGroup.buttonLabelColorDown != null)
			colorDown = uxGroup.buttonLabelColorDown;

		var colorDisabled = FlxUXCore.buttonLabelColorDisabled;
		if (buttonLabelColorDisabled != null)
			colorDisabled = buttonLabelColorDisabled;
		else if (uxGroup != null && uxGroup.buttonLabelColorDisabled != null)
			colorDisabled = uxGroup.buttonLabelColorDisabled;

		var align:FlxTextAlign = CENTER;
		if (buttonLabelAlign != null)
			align = buttonLabelAlign;
		else if (uxGroup != null && uxGroup.buttonLabelAlign != null)
			align = uxGroup.buttonLabelAlign;
		else
			align = FlxUXCore.buttonLabelAlign;

		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			t.wordWrap = false;
			if (baseLabelText != null && baseLabelText.indexOf("\n") < 0)
			{
				if (t.fieldWidth <= 0)
					t.fieldWidth = 1;
			}
			else
			{
				if (t.fieldWidth <= 0)
					t.fieldWidth = 1;
			}

			t.setFormat(font, size, colorNormal, align);
			t.calcFrame();
		}
		else if (Std.isOfType(this.label, FlxBitmapText))
		{
			var bitmapText:FlxBitmapText = cast this.label;
			var textScale = Math.max(1, Math.round(size / bitmapText.font.lineHeight));
			bitmapText.scale.set(textScale, textScale);
			bitmapText.alignment = align;
			bitmapText.color = colorNormal;
			bitmapText.updateHitbox();
		}
		else
		{
			this.label.color = colorNormal;
		}

		applyLabelStateColor();

		centerLabel();
	}

	private function applyLabelStateColor():Void
	{
		if (this.label == null)
			return;
		var normal:flixel.util.FlxColor = (buttonLabelColor != null) ? buttonLabelColor : ((uxGroup != null && uxGroup.buttonLabelColor != null) ? uxGroup.buttonLabelColor : FlxUXCore.buttonLabelColor);
		var hover:Null<flixel.util.FlxColor> = (buttonLabelColorHover != null) ? buttonLabelColorHover : ((uxGroup != null
			&& uxGroup.buttonLabelColorHover != null) ? uxGroup.buttonLabelColorHover : FlxUXCore.buttonLabelColorHover);
		var down:Null<flixel.util.FlxColor> = (buttonLabelColorDown != null) ? buttonLabelColorDown : ((uxGroup != null && uxGroup.buttonLabelColorDown != null) ? uxGroup.buttonLabelColorDown : FlxUXCore.buttonLabelColorDown);
		var dis:Null<flixel.util.FlxColor> = (buttonLabelColorDisabled != null) ? buttonLabelColorDisabled : ((uxGroup != null
			&& uxGroup.buttonLabelColorDisabled != null) ? uxGroup.buttonLabelColorDisabled : FlxUXCore.buttonLabelColorDisabled);
		var lock:Null<flixel.util.FlxColor> = (buttonLabelColorLocked != null) ? buttonLabelColorLocked : ((uxGroup != null
			&& uxGroup.buttonLabelColorLocked != null) ? uxGroup.buttonLabelColorLocked : FlxUXCore.buttonLabelColorLocked);

		var c = normal;
		if (_locked)
			c = (lock != null) ? lock : ((dis != null) ? dis : normal);
		else if (!active)
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
		var sOver = (buttonSoundOver != null) ? buttonSoundOver : ((uxGroup != null && uxGroup.buttonSoundOver != null) ? uxGroup.buttonSoundOver : FlxUXCore.buttonSoundOver);
		var sDown = (buttonSoundDown != null) ? buttonSoundDown : ((uxGroup != null && uxGroup.buttonSoundDown != null) ? uxGroup.buttonSoundDown : FlxUXCore.buttonSoundDown);
		var sClick = (buttonSoundClick != null) ? buttonSoundClick : ((uxGroup != null && uxGroup.buttonSoundClick != null) ? uxGroup.buttonSoundClick : FlxUXCore.buttonSoundClick);
		if (onOver != null)
		{
			if (sOver != null)
			{
				if (onOver.sound == null)
					onOver.sound = new FlxSound();
				onOver.sound.loadEmbedded(sOver, false, false);
			}
			else
				onOver.sound = null;
		}
		if (onDown != null)
		{
			if (sDown != null)
			{
				if (onDown.sound == null)
					onDown.sound = new FlxSound();
				onDown.sound.loadEmbedded(sDown, false, false);
			}
			else
				onDown.sound = null;
		}
		if (onUp != null)
		{
			if (sClick != null)
			{
				if (onUp.sound == null)
					onUp.sound = new FlxSound();
				onUp.sound.loadEmbedded(sClick, false, false);
			}
			else
				onUp.sound = null;
		}
		applyLabelColorsForStatus();

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
			applyGraphicSkin(FlxUXCore.DEFAULT_BUTTON_GRAPHIC, 0);
			return;
		}

		applyGraphicSkin(input, fps);
	}

	private inline function syncGraphicSizeFromExplicit():Void
	{
		if (explicitSizeLocked)
		{
			this.frameWidth = Std.int(Math.max(1, width));
			this.frameHeight = Std.int(Math.max(1, height));
		}
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

		syncGraphicSizeFromExplicit();
		var w:Int = Std.int(Math.max(1, width));
		var h:Int = Std.int(Math.max(1, height));

		if (Std.isOfType(input, flixel.ux.FlxUX9Slice))
		{
			usingNineSliceSkin = true;
			var ns:flixel.ux.FlxUX9Slice = cast input;
			var gfx:FlxGraphic = FlxUX9Slice.get(ns, w, h, 0);
			if (gfx != null)
			{
				loadGraphic(gfx, true, w, h);
			}
			if (skinAnimFps > 0)
			{
				lastSkinStateIndex = 0;
				animSequence = getAnimSequenceForState(0);
				animFrameIndex = 0;
				animTime = 0;
			}
			lastSkinStateIndex = -1;
			lastSkinAnimFrameIndex = -1;
			updateFrameFromStatus();
		}
		else
		{
			var g:FlxGraphic = flixel.ux.FlxUX9Slice.toGraphic(input);
			if (g != null)
			{
				loadGraphic(g, true, w, h);
				updateFrameFromStatus();
			}
		}

		antialiasing = false;
		if (explicitSizeLocked)
		{
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
		}
		centerLabel();
	}

	private function applyLabelColorsForStatus():Void
	{
		if (this.label == null)
			return;

		var c:Null<FlxColor> = null;
		if (!active)
			c = getEffectiveLabelColorDisabled();
		else
		{
			switch (status)
			{
				case FlxButtonState.HIGHLIGHT:
					c = getEffectiveLabelColorHover();
				case FlxButtonState.PRESSED:
					c = getEffectiveLabelColorDown();
				default:
					c = getEffectiveLabelColorUp();
			}
		}
		if (c != null)
			this.label.color = c;
	}

	private inline function getEffectiveLabelColorUp():Null<FlxColor>
	{
		if (buttonLabelColor != null)
			return buttonLabelColor;
		if (uxGroup != null && uxGroup.buttonLabelColor != null)
			return uxGroup.buttonLabelColor;
		return FlxUXCore.buttonLabelColor;
	}

	private inline function getEffectiveLabelColorHover():Null<FlxColor>
	{
		if (buttonLabelColorHover != null)
			return buttonLabelColorHover;
		if (uxGroup != null && uxGroup.buttonLabelColorHover != null)
			return uxGroup.buttonLabelColorHover;
		return FlxUXCore.buttonLabelColorHover;
	}

	private inline function getEffectiveLabelColorDown():Null<FlxColor>
	{
		if (buttonLabelColorDown != null)
			return buttonLabelColorDown;
		if (uxGroup != null && uxGroup.buttonLabelColorDown != null)
			return uxGroup.buttonLabelColorDown;
		return FlxUXCore.buttonLabelColorDown;
	}

	private inline function getEffectiveLabelColorDisabled():Null<FlxColor>
	{
		if (_locked)
		{
			if (buttonLabelColorLocked != null)
				return buttonLabelColorLocked;
			if (uxGroup != null && uxGroup.buttonLabelColorLocked != null)
				return uxGroup.buttonLabelColorLocked;
			if (FlxUXCore.buttonLabelColorLocked != null)
				return FlxUXCore.buttonLabelColorLocked;
			if (buttonLabelColorDisabled != null)
				return buttonLabelColorDisabled;
			if (uxGroup != null && uxGroup.buttonLabelColorDisabled != null)
				return uxGroup.buttonLabelColorDisabled;
			return FlxUXCore.buttonLabelColorDisabled;
		}
		if (buttonLabelColorDisabled != null)
			return buttonLabelColorDisabled;
		if (uxGroup != null && uxGroup.buttonLabelColorDisabled != null)
			return uxGroup.buttonLabelColorDisabled;
		return FlxUXCore.buttonLabelColorDisabled;
	}

	/**
	 * Called by groups when core/group defaults have changed and the button needs to re-evaluate
	 * its effective skin input + animation settings.
	 */
	public function refreshSkinFromDefaults():Void
	{
		applyLabelOptions();
		applySkin();
	}

	private function getAnimSequenceForState(stateIndex:Int):Array<Int>
	{
		switch (stateIndex)
		{
			case 0:
				if (buttonAnimUp != null)
					return buttonAnimUp;
				if (uxGroup != null && uxGroup.buttonAnimUp != null)
					return uxGroup.buttonAnimUp;
				return FlxUXCore.buttonAnimUp;
			case 1:
				if (buttonAnimOver != null)
					return buttonAnimOver;
				if (uxGroup != null && uxGroup.buttonAnimOver != null)
					return uxGroup.buttonAnimOver;
				return FlxUXCore.buttonAnimOver;
			case 2:
				if (buttonAnimDown != null)
					return buttonAnimDown;
				if (uxGroup != null && uxGroup.buttonAnimDown != null)
					return uxGroup.buttonAnimDown;
				return FlxUXCore.buttonAnimDown;
			default:
				if (buttonAnimDisabled != null)
					return buttonAnimDisabled;
				if (uxGroup != null && uxGroup.buttonAnimDisabled != null)
					return uxGroup.buttonAnimDisabled;
				return FlxUXCore.buttonAnimDisabled;
		}
	}

	private function applyDefaultSkin():Void
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
		loadGraphic(graphic, true, w, h);
		centerLabel();
		updateFrameFromStatus();
	}

	private function updateFrameFromStatus():Void
	{
		var stateIndex:Int = 0;
		if (_locked)
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

		if (usingDefaultSkin)
		{
			animation.frameIndex = stateIndex;
			return;
		}

		if (usingNineSliceSkin && skinInput != null)
		{
			var w:Int = Std.int(Math.max(1, width));
			var h:Int = Std.int(Math.max(1, height));
			var ns:flixel.ux.FlxUX9Slice = cast skinInput;

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

				var seqIndex:Int = 0;
				if (animSequence != null && animSequence.length > 0)
					seqIndex = animFrameIndex % animSequence.length;

				if (lastSkinAnimFrameIndex == seqIndex)
					return;
				lastSkinAnimFrameIndex = seqIndex;

				var fi:Int = 0;
				if (animSequence != null && animSequence.length > 0)
					fi = animSequence[seqIndex];
				var gfxAnim:FlxGraphic = FlxUX9Slice.get(ns, w, h, fi);
				if (gfxAnim != null)
					loadGraphic(gfxAnim, true, w, h);
				return;
			}

			if (lastSkinStateIndex == stateIndex)
				return;
			lastSkinStateIndex = stateIndex;
			animSequence = null;

			var gfx:FlxGraphic = FlxUX9Slice.get(ns, w, h, stateIndex);
			if (gfx != null)
				loadGraphic(gfx, true, w, h);
			return;
		}

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
		applyFocusVisual(uxFocused);
	}

	private function applyFocusVisual(focused:Bool):Void
	{
		alpha = 1.0;
		if (focusFrameSprite != null)
			focusFrameSprite.visible = false;
	}

	private function applyFrame(enabled:Bool, color:FlxColor, thickness:Int):Void
	{
		var t = thickness;
		if (t < 1)
			t = 1;

		var w = Std.int(Math.max(1, width));
		var h = Std.int(Math.max(1, height));
		var base = frameBaseColor;

		if (!enabled)
		{
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
		if (_locked)
			return;
		if (uxPressed == pressed)
			return;

		uxPressed = pressed;

		status = uxPressed ? FlxButtonState.PRESSED : FlxButtonState.NORMAL;
		updateFrameFromStatus();
		updateLabelPosition();
	}

	/** Suppresses stale pointer hover while keyboard/gamepad navigation is active. */
	override function updateButton():Void
	{
		if (!FlxUXCore.active || !FlxUXCore.ready || uxGroup != null && !FlxUXCore.isGroupInputEligible(uxGroup, false))
		{
			status = _locked ? FlxButtonState.DISABLED : FlxButtonState.NORMAL;
			return;
		}
		var actions:FlxUXActions = FlxUXCore.actions;
		if (FlxUXCore.mode == flixel.ux.FlxUXCore.FlxUXInputMode.NAV
			&& actions != null
			&& !actions.moveMouse.triggered
			&& !actions.pointerPressHeld.triggered)
		{
			status = uxPressed ? FlxButtonState.PRESSED : FlxButtonState.NORMAL;
			return;
		}
		super.updateButton();
	}

	override function checkInput(pointer:flixel.input.FlxPointer, input:flixel.input.IFlxInput, justPressedPosition:flixel.math.FlxPoint,
			camera:flixel.FlxCamera):Bool
	{
		#if !FLX_NO_MOUSE
		if (Std.isOfType(pointer, flixel.input.mouse.FlxMouse) && !FlxG.mouse.enabled)
			return false;
		#end
		if (scrollPanel != null && !scrollPanel.containsPointer(pointer))
			return false;
		return super.checkInput(pointer, input, justPressedPosition, camera);
	}

	override function onUpHandler():Void
	{
		var allowed = FlxUXCore.active
			&& FlxUXCore.ready
			&& !_locked
			&& (uxGroup == null || FlxUXCore.isGroupInputEligible(uxGroup, false));
		#if !FLX_NO_MOUSE
		if (!Std.isOfType(currentInput, flixel.input.FlxPointer))
			allowed = allowed && FlxG.mouse.enabled;
		#end
		if (scrollPanel != null)
		{
			if (Std.isOfType(currentInput, flixel.input.FlxPointer))
				allowed = allowed && scrollPanel.containsPointer(cast currentInput);
			#if !FLX_NO_MOUSE
			else
				allowed = allowed && FlxG.mouse.enabled && scrollPanel.containsPointer(FlxG.mouse);
			#end
		}
		if (!allowed)
		{
			status = FlxButtonState.NORMAL;
			input.release();
			currentInput = null;
			return;
		}
		super.onUpHandler();
	}

	override public function update(elapsed:Float):Void
	{
		FlxUXCore.markNavButtonUpdatedThisFrame(this);
		if (_locked)
		{
			super.update(elapsed);
			status = FlxButtonState.DISABLED;
			updateFrameFromStatus();
			applyLabelStateColor();
			centerLabel();
			return;
		}

		super.update(elapsed);

		if (usingNineSliceSkin && skinInput != null && skinAnimFps > 0)
		{
			if (animSequence == null)
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
				animSequence = getAnimSequenceForState(stateIndex);
			}

			if (animSequence != null && animSequence.length > 1)
			{
				animTime += elapsed;
				if (skinAnimFps <= 0)
					skinAnimFps = 1;
				var frameDur:Float = 1.0 / skinAnimFps;
				while (animTime >= frameDur)
				{
					animTime -= frameDur;
					animFrameIndex++;
					lastSkinAnimFrameIndex = -1;
				}
			}
		}

		if (FlxUXCore.mode == flixel.ux.FlxUXCore.FlxUXInputMode.POINTER)
		{
			if (status == FlxButtonState.HIGHLIGHT && FlxUXCore.focused != this)
				FlxUXCore.setFocused(this);
		}

		updateFrameFromStatus();
		applyLabelStateColor();
		updateLabelPosition();
	}

	/**
	 * Returns `true` if the button can currently be interacted with via FlxUX.
	 */
	public inline function isUXEligible():Bool
	{
		return exists && alive && visible && active && !_locked;
	}

	public function shortcutTriggered():Bool
	{
		return hotkeyInput != null
			&& hotkeyInput.check(flixel.input.FlxInput.FlxInputState.JUST_PRESSED)
			|| accessKeyInput != null
			&& accessKeyInput.check(flixel.input.FlxInput.FlxInputState.JUST_PRESSED);
	}

	private function updateKeyboardCues():Void
	{
		keyboardCuesVisible = showKeyboardCues && FlxUXCore.showKeyboardCues && FlxUXCore.shortcutsEnabled && FlxUXCore.isKeyboardEnabled();
		if (shortcutLabel != null)
		{
			shortcutLabel.visible = keyboardCuesVisible
				&& width >= shortcutLabel.width + marginX * 2
				&& height >= label.height + shortcutLabel.height + 8;
			shortcutLabel.color = label.color;
			shortcutLabel.alpha = alpha;
			shortcutLabel.x = x + width - marginX - shortcutLabel.width;
			shortcutLabel.y = y + height - shortcutLabel.height - 3;
			shortcutLabel.cameras = cameras;
			shortcutLabel.scrollFactor.copyFrom(scrollFactor);
		}
		if (mnemonicUnderline == null)
			mnemonicUnderline = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		mnemonicUnderline.visible = false;
		if (keyboardCuesVisible && accessKeyInput != null && accessKeyInput.valid && label != null)
		{
			var index = baseLabelText.toLowerCase().indexOf(accessKey.toLowerCase());
			if (index >= 0 && Std.isOfType(label, FlxBitmapText))
			{
				var bitmapText:FlxBitmapText = cast label;
				var total = 0.0;
				var before = 0.0;
				var letterWidth = 0.0;
				for (position in 0...baseLabelText.length)
				{
					var frame = bitmapText.font.getCharFrame(baseLabelText.charCodeAt(position));
					var advance = frame == null ? bitmapText.font.spaceWidth : frame.sourceSize.x;
					if (position < index)
						before += advance + bitmapText.letterSpacing;
					if (position == index)
						letterWidth = advance;
					total += advance + bitmapText.letterSpacing;
				}
				total -= bitmapText.letterSpacing;
				mnemonicUnderline.scale.set(Math.max(1, letterWidth * label.scale.x), 1);
				mnemonicUnderline.updateHitbox();
				var textLeft = switch (bitmapText.alignment)
				{
					case LEFT: label.x;
					case RIGHT: label.x + label.width - total * label.scale.x;
					default: x + (width - total * label.scale.x) * 0.5;
				};
				mnemonicUnderline.x = textLeft + before * label.scale.x;
				mnemonicUnderline.y = label.y + bitmapText.font.lineHeight * label.scale.y - 1;
				mnemonicUnderline.color = label.color;
				mnemonicUnderline.alpha = alpha;
				mnemonicUnderline.cameras = cameras;
				mnemonicUnderline.scrollFactor.copyFrom(scrollFactor);
				mnemonicUnderline.visible = true;
			}
		}
		if (defaultIndicator == null)
			defaultIndicator = new FlxSprite();
		defaultIndicator.visible = showDefaultIndicator && uxGroup != null && uxGroup.defaultButton == this && isUXEligible();
		var indicatorWidth = Std.int(Math.max(1, width - 4));
		var indicatorHeight = Std.int(Math.max(1, height - 4));
		if (defaultIndicatorWidth != indicatorWidth || defaultIndicatorHeight != indicatorHeight)
		{
			defaultIndicatorWidth = indicatorWidth;
			defaultIndicatorHeight = indicatorHeight;
			defaultIndicator.makeGraphic(indicatorWidth, indicatorHeight, 0x00000000, true);
			var pixels = defaultIndicator.pixels;
			pixels.fillRect(new openfl.geom.Rectangle(0, 0, indicatorWidth, 1), FlxColor.WHITE);
			pixels.fillRect(new openfl.geom.Rectangle(0, indicatorHeight - 1, indicatorWidth, 1), FlxColor.WHITE);
			pixels.fillRect(new openfl.geom.Rectangle(0, 0, 1, indicatorHeight), FlxColor.WHITE);
			pixels.fillRect(new openfl.geom.Rectangle(indicatorWidth - 1, 0, 1, indicatorHeight), FlxColor.WHITE);
			defaultIndicator.dirty = true;
		}
		defaultIndicator.setPosition(x + 2, y + 2);
		defaultIndicator.color = defaultIndicatorColor == null ? effectiveNormalLabelColor() : defaultIndicatorColor;
		defaultIndicator.alpha = alpha;
		defaultIndicator.cameras = cameras;
		defaultIndicator.scrollFactor.copyFrom(scrollFactor);
	}

	private function effectiveNormalLabelColor():FlxColor
	{
		if (buttonLabelColor != null)
			return buttonLabelColor;
		if (uxGroup != null && uxGroup.buttonLabelColor != null)
			return uxGroup.buttonLabelColor;
		return FlxUXCore.buttonLabelColor;
	}

	override public function draw():Void
	{
		super.draw();
		updateKeyboardCues();
		if (shortcutLabel != null && shortcutLabel.visible)
			shortcutLabel.draw();
		if (mnemonicUnderline.visible)
			mnemonicUnderline.draw();
		if (defaultIndicator.visible)
			defaultIndicator.draw();
	}

	override public function destroy():Void
	{
		if (shortcutLabel != null)
			shortcutLabel.destroy();
		if (mnemonicUnderline != null)
			mnemonicUnderline.destroy();
		if (defaultIndicator != null)
			defaultIndicator.destroy();
		super.destroy();
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
