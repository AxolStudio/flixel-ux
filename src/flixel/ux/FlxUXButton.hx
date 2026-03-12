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
	/**
	 * Opt-in debug trace for sizing/layout issues.
	 *
	 * Enable by running with `-D flxux_debug_sizes`.
	 */
	public static inline var DEBUG_SIZES:Bool = #if flxux_debug_sizes true #else false #end;
	/** If enabled, stops logging after the first update+draw window and can auto-exit. */
	public static inline var DEBUG_FIRST_FRAME_ONLY:Bool = #if flxux_debug_first_frame_only true #else false #end;
	/** If enabled (with DEBUG_FIRST_FRAME_ONLY), exits immediately after the first frame window. */
	public static inline var DEBUG_AUTO_EXIT:Bool = #if flxux_debug_auto_exit true #else false #end;
	private static var _debugGateOpen:Bool = true;
	private static var _debugSawUpdate:Bool = false;
	private static var _debugHandledExit:Bool = false;
	private static inline function _debugShouldLog():Bool
	{
		if (!DEBUG_SIZES) return false;
		return _debugGateOpen;
	}
	private static inline function _debugMaybeCloseGateFromUpdate():Void
	{
		if (!DEBUG_SIZES) return;
		if (!DEBUG_FIRST_FRAME_ONLY) return;
		_debugSawUpdate = true;
		// We can’t reliably hook PlayState.draw() without touching the demo,
		// so we define “first frame window” as: after the first button update().
		// That’s still enough to catch the post-layout mutation you described.
		_debugGateOpen = false;
		// Auto-exit intentionally disabled for now (keep the logic around so it can be re-enabled
		// later by changing this single flag).
		var _autoExitEnabled:Bool = false;
		if (_autoExitEnabled && DEBUG_AUTO_EXIT && !_debugHandledExit)
		{
			_debugHandledExit = true;
			try
			{
				#if (openfl || lime)
				openfl.system.System.exit(0);
				#else
				flixel.FlxG.game.step(); // best-effort no-op fallback
				#end
			}
			catch (e:Dynamic) {}
		}
	}
	private static var _debugSeq:Int = 0;
	private var _debugId:Int = ++_debugSeq;
	private inline function _dbgTag():String
	{
		var t = _baseLabelText;
		if (t == null) t = "";
		// Keep logs compact.
		if (t.length > 24) t = t.substr(0, 24) + "…";
		return 'UXBtn#' + _debugId + '("' + t + '")';
	}
	private inline function _dbgSizes(where:String):Void
	{
		if (!_debugShouldLog()) return;
		var lw:Float = (label != null) ? label.width : -1;
		var lh:Float = (label != null) ? label.height : -1;
		var ltw:Float = -1;
		var lth:Float = -1;
		if (label != null && Std.isOfType(label, FlxText))
		{
			var t:FlxText = cast label;
			try
			{
				ltw = t.textField.textWidth;
				lth = t.textField.textHeight;
			}
			catch (e:Dynamic) {}
		}
		var gW:Int = (graphic != null) ? graphic.width : -1;
		var gH:Int = (graphic != null) ? graphic.height : -1;
		trace(_dbgTag() + ' @ ' + where
			+ ' pos=(' + Std.int(x) + ',' + Std.int(y) + ')'
			+ ' size(w,h)=(' + Std.int(width) + ',' + Std.int(height) + ')'
			+ ' frame(w,h)=(' + frameWidth + ',' + frameHeight + ')'
			+ ' graphic(w,h)=(' + gW + ',' + gH + ')'
			+ ' label(w,h)=(' + Std.int(lw) + ',' + Std.int(lh) + ')'
			+ ' tf(w,h)=(' + Std.int(ltw) + ',' + Std.int(lth) + ')'
			+ ' status=' + status
			+ ' usingDefault=' + usingDefaultSkin
			+ ' nineSlice=' + usingNineSliceSkin
			+ ' explicitLock=' + _explicitSizeLocked);
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
	private var _constructed:Bool = false;
	private var _explicitSizeLocked:Bool = false;

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
		_dbgSizes("ctor.afterSuper");

		onUp.callback = () -> activate();
		// One-time construction pass:
		// 1) Apply label formatting (no wrapping unless explicit '\n')
		// 2) Auto-size exactly once (unless the user disables autoSizeToLabel)
		applyLabelOptions();
		_dbgSizes("ctor.afterApplyLabelOptions");
		if (autoSizeToLabel) autosize();
		_dbgSizes("ctor.afterAutosize");
		// Ensure the background skin is generated at the final size *immediately*.
		// Otherwise, buttons can start with inconsistent visuals/sizes before any group helper runs.
		applySkin();
		_dbgSizes("ctor.afterApplySkin");
		_constructed = true;
		_dbgSizes("ctor.done");
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
		_baseLabelText = text;
		if (this.label != null) this.label.text = text;
		applyLabelOptions();
		if (autoSizeToLabel) autosize();
		_dbgSizes("setLabelText.done");
	}

	/** Recomputes the button size from the label + margins and rebuilds the base graphic. */
	public function autosize():Void
	{
		if (this.label == null)
			return;
		_dbgSizes("autosize.start");

		// Force label metrics to be up-to-date before measuring.
		// On some targets/backends, FlxText's underlying TextField hasn't validated yet during create(),
		// which can yield width/height==0 and produce tiny buttons.
		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			// Ensure the OpenFL TextField has current layout.
			// Both calls are safe and cheap; they just sync internal bounds.
			try
			{
				t.textField.text = t.text;
				t.textField.width = 1;
				t.textField.height = 1;
			}
			catch (e:Dynamic) {}
			// Let FlxText update its cached size from the text field this frame.
			t.calcFrame();
		}
		_dbgSizes("autosize.afterCalcFrame");

		// Ensure consistent label layout before measuring.
		// Our contract is: no auto-wrapping; only explicit '\n' creates multiple lines.
		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			t.wordWrap = false;
			t.fieldWidth = 0;
		}

		var labelW:Float = this.label.width;
		var labelH:Float = this.label.height;
		// FlxText width/height can be misleading during creation depending on when the underlying
		// OpenFL TextField regenerates. Prefer glyph bounds when available.
		if (Std.isOfType(this.label, FlxText))
		{
			var t:FlxText = cast this.label;
			try
			{
				// textWidth/textHeight are tight bounds; add a small safety pad to avoid clipping.
				labelW = t.textField.textWidth + 4;
				labelH = t.textField.textHeight + 4;
			}
			catch (e:Dynamic) {}
		}

		// Final guard: if something was still 0 (common during very early creation), fall back to
		// calculating from the glyph bounds.
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

		var w = Std.int(Math.ceil(labelW + marginX * 2));
		var h = Std.int(Math.ceil(labelH + marginY * 2));
		if (w < 1) w = 1;
		if (h < 1) h = 1;

		// Autosize sets an implicit size; it may still be overridden by group helpers later.
		_explicitSizeLocked = false;
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

		centerLabel();
		_dbgSizes("autosize.done");
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
		_dbgSizes('resize.start(' + w + ',' + h + ')');
		autoSizeToLabel = false;
		_explicitSizeLocked = true;
		// IMPORTANT: keep FlxSprite sizing (width/height) and frame sizing (frameWidth/frameHeight)
		// in sync BEFORE any skin regeneration happens.
		// If frameWidth changes without width changing (or vice versa), group layout helpers can
		// position based on one set of dimensions while rendering uses another.
		// On the next loadGraphic() call, FlxSprite will re-derive frameWidth from the graphic,
		// causing the "positioned wide but drawn narrow" behavior.
		// Use setGraphicSize() so we don't fight FlxSprite's internal pixel/frame sizing.
		// setSize() only affects hitbox and can lead to scale-induced distortion when we later
		// load 9-slice graphics at a different pixel size during theme swaps.
		this.setGraphicSize(w, h);
		this.updateHitbox();
		this.frameWidth = w;
		this.frameHeight = h;
		// Preserve the current skin type.
		// IMPORTANT: don't rebuild the base graphic with makeGraphic() here unless we're using the
		// procedural default skin. For 9-slice skins, makeGraphic() can temporarily replace the
		// sprite's graphic and cause bizarre distortion until the next refresh.
		if (usingDefaultSkin)
		{
			makeGraphic(w, h, frameBaseColor, true);
			// makeGraphic/loadGraphic can stomp frame size; force consistency again.
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
			_applyDefaultSkin();
		}
		else
		{
			// Just re-apply the skin at the new size.
			applySkin();
			// loadGraphic() may have reset frameWidth/frameHeight based on the graphic's frame.
			// Enforce the explicit size as authoritative.
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
		}
		centerLabel();
		_dbgSizes("resize.done");
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
		_dbgSizes("centerLabel");
	}

	/** Applies label options (font/size/color/align and optional label factory) using precedence: button -> group -> core. */
	public function applyLabelOptions():Void
	{
		_dbgSizes("applyLabelOptions.start");
		// Factory choice
		// NOTE: We intentionally DO NOT auto-apply the factory after construction.
		// Reason: FlxButton may recreate/reassign its label internally; swapping label objects
		// post-layout can cause size/layout churn. If the user wants a custom label type,
		// they should provide it up-front (via generics or manual assignment).
		if (!_constructed)
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
			// Contract: no wrapping unless explicit newlines.
			// IMPORTANT: keep a stable fieldWidth, otherwise the underlying TextField will
			// re-flow and change its measured width on hover/theme refresh.
			// For single-line labels we use the current fieldWidth (if any) or a minimal value
			// to avoid auto-wrapping. The actual rendered alignment is handled by centerLabel().
			t.wordWrap = false;
			if (_baseLabelText != null && _baseLabelText.indexOf("\n") < 0)
			{
				if (t.fieldWidth <= 0)
					t.fieldWidth = 1;
			}
			else
			{
				// Explicit multiline: keep fieldWidth stable too (don't force wrap-to-button).
				if (t.fieldWidth <= 0)
					t.fieldWidth = 1;
			}

			t.setFormat(font, size, colorNormal, align);
			// Ensure cached bounds are current immediately.
			t.calcFrame();
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
		_dbgSizes("applyLabelOptions.done");
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
		_dbgSizes("applySkin.start");
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
		_dbgSizes("applySkin.afterApplyLabelOptions");

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
		_dbgSizes("applySkin.done");
	}

	private inline function _syncGraphicSizeFromExplicit():Void
	{
		// When a group helper (matchSize/resize) sets width/height, we must keep the
		// underlying graphic sizing in sync or later skin refreshes can regenerate at
		// stale dimensions.
		if (_explicitSizeLocked)
		{
			this.frameWidth = Std.int(Math.max(1, width));
			this.frameHeight = Std.int(Math.max(1, height));
		}
	}

	private function applyGraphicSkin(input:FlxUXGraphicInput, fps:Int):Void
	{
		_dbgSizes("applyGraphicSkin.start");
		usingDefaultSkin = false;
		usingNineSliceSkin = false;
		skinInput = input;
		skinAnimFps = fps;
		lastSkinStateIndex = -1;
		animTime = 0;
		animFrameIndex = 0;
		animSequence = null;
		lastSkinAnimFrameIndex = -1;

		_syncGraphicSizeFromExplicit();
		// When explicit sizing is locked (usually by a group layout helper), width/height are the
		// authoritative size. Using frameWidth/frameHeight here can drift if some previous code set
		// frame* without updating width/height, or if loadGraphic() later re-derives frame size.
		var w:Int = Std.int(Math.max(1, width));
		var h:Int = Std.int(Math.max(1, height));

		if (Std.isOfType(input, flixel.ux.FlxUX9Slice))
		{
			usingNineSliceSkin = true;
			var ns:flixel.ux.FlxUX9Slice = cast input;
			var gfx:FlxGraphic = FlxUX9Slice.get(ns, w, h, 0);
			if (gfx != null)
			{
				// IMPORTANT:
				// FlxUX9Slice.get() returns a *single* rendered bitmap of size (w,h).
				// If we call loadGraphic(gfx) without explicit frame sizing, FlxSprite can
				// end up with frameWidth/frameHeight derived from whatever metadata is on the
				// FlxGraphic (or previous frames), which is exactly the kind of drift that
				// caused theme swaps to show the wrong portion / whole sheet.
				// Loading with explicit (w,h) forces a 1-frame spritesheet contract.
				loadGraphic(gfx, true, w, h);
			}
			// If we're configured for animated skins, start a sequence immediately so it can loop
			// even if the user never hovers/presses the button.
			if (skinAnimFps > 0)
			{
				lastSkinStateIndex = 0;
				animSequence = getAnimSequenceForState(0);
				animFrameIndex = 0;
				animTime = 0;
			}
			// Force regenerate the correct state frame immediately.
			// (Reset both state + animation tracking so we don't early-out when switching skins.)
			lastSkinStateIndex = -1;
			lastSkinAnimFrameIndex = -1;
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
		// Ensure our *rendered* size and hitbox remain the explicit size after loadGraphic().
		// Using setSize() here can leave the sprite scaled unexpectedly or with mismatched frame sizes
		// across theme swaps. setGraphicSize() keeps visual pixels consistent.
		if (_explicitSizeLocked)
		{
			this.setGraphicSize(w, h);
			this.updateHitbox();
			this.frameWidth = w;
			this.frameHeight = h;
		}
		centerLabel();
		_dbgSizes("applyGraphicSkin.done");
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
		_dbgSizes("_applyDefaultSkin.start");
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
		_dbgSizes("_applyDefaultSkin.done");
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
				loadGraphic(gfx, true, w, h);
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
		// NOTE: this can be noisy; use -D flxux_debug_first_frame_only to auto-stop after 1st update.
		_dbgSizes("update.postSuper");

		// Advance 9-slice animation time. We do NOT want to reset the state's sequence on every tick;
		// we just want the next sequence index to be rendered.
		if (usingNineSliceSkin && skinInput != null && skinAnimFps > 0)
		{
			if (animSequence == null)
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

			// Only advance if this state actually has a multi-frame sequence.
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
		_dbgSizes("update.done");
		_debugMaybeCloseGateFromUpdate();
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