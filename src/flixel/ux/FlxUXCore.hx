package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfFour;
import haxe.extern.EitherType;
import haxe.Json;
import openfl.Assets;
import openfl.display.BitmapData;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;

/**
 * Accepts common Flixel-friendly graphic inputs:
 * - `String` (asset id)
 * - `FlxGraphic`
 * - `FlxSprite`
 * - `BitmapData`
 * - `FlxUX9Slice`
 */
typedef FlxUXGraphicInput = EitherType<OneOfFour<String, flixel.graphics.FlxGraphic, flixel.FlxSprite, BitmapData>, flixel.ux.FlxUX9Slice>;

/** Factory for creating a button label sprite. */
typedef FlxUXLabelFactory = (text:String) -> flixel.FlxSprite;

/**
 * Global input mode used by FlxUX.
 *
 * - `POINTER`: mouse/touch input. Focus does not matter; clicking activates the clicked button.
 * - `NAV`: keyboard/gamepad navigation. Focus matters; confirm activates the focused button.
 */
class FlxUXCore
{
	// (Graphic input typedef is declared at file scope as FlxUXGraphicInput.)

	// --- Built-in defaults (so users can override and easily restore) ---
	public static inline var DEFAULT_MOUSE_GRAPHIC:String = "flixel-ux/mouse_cursor.png";
	public static inline var DEFAULT_BUTTON_SKIN_FPS:Int = 10;
	public static inline var DEFAULT_BUTTON_FRAMES_GRAPHIC:String = "flixel-ux/ux/button.png";
	public static inline var DEFAULT_BUTTON_FRAMES_ANIM_GRAPHIC:String = "flixel-ux/ux/button_anim.png";
	public static inline var DEFAULT_FOCUS_FRAME_FPS:Int = 6;
	public static var DEFAULT_FOCUS_FRAME_GRAPHIC:FlxUX9Slice =
		new FlxUX9Slice("flixel-ux/highlight_frame_9s_anim.png", 40, 40, 14, 17, 15, 18);
	public static inline var DEFAULT_FOCUS_NEXT_TO_GRAPHIC:String = "flixel-ux/highlight_next_to.png";
	public static inline var DEFAULT_FOCUS_OVERLAY_GRAPHIC:String = "flixel-ux/highlight_on.png";
	public static var DEFAULT_BUTTON_GRAPHIC:FlxUX9Slice =
		new FlxUX9Slice(DEFAULT_BUTTON_FRAMES_GRAPHIC, 16, 16, 3, 7, 3, 7);
	public static var DEFAULT_BUTTON_GRAPHIC_ANIM:FlxUX9Slice =
		new FlxUX9Slice(DEFAULT_BUTTON_FRAMES_ANIM_GRAPHIC, 16, 16, 3, 7, 3, 7);

	// --- Button look (null => use built-in default procedural skin) ---
	/**
	 * Default button skin graphic input.
	 *
	 * Accepts: String, FlxGraphic, FlxSprite, BitmapData, FlxUX9Slice.
	 * If null, FlxUXButton uses its procedural `makeGraphic` default.
	 */
	/**
	 * Default button skin graphic input.
	 *
	 * Precedence: button -> group -> core.
	 * If `null`, buttons use the built-in defaults (DEFAULT_BUTTON_GRAPHIC / DEFAULT_BUTTON_GRAPHIC_ANIM).
	 */
	public static var buttonGraphic:Null<FlxUXGraphicInput> = null;

	/** If set, button skins are treated as animated and will update per-state using this FPS. */
	public static var buttonSkinFps:Int = DEFAULT_BUTTON_SKIN_FPS;
	public static inline var DEFAULT_BUTTON_USE_ANIM:Bool = false;
	public static var buttonUseAnim:Bool = DEFAULT_BUTTON_USE_ANIM;

	public static var DEFAULT_BUTTON_ANIM_UP:Array<Int> = [0, 1];
	public static var DEFAULT_BUTTON_ANIM_OVER:Array<Int> = [2, 3, 4, 5];
	public static var DEFAULT_BUTTON_ANIM_DOWN:Array<Int> = [6, 7, 8, 9];
	public static var DEFAULT_BUTTON_ANIM_DISABLED:Array<Int> = [10];

	public static var buttonAnimUp:Array<Int> = DEFAULT_BUTTON_ANIM_UP;
	public static var buttonAnimOver:Array<Int> = DEFAULT_BUTTON_ANIM_OVER;
	public static var buttonAnimDown:Array<Int> = DEFAULT_BUTTON_ANIM_DOWN;
	public static var buttonAnimDisabled:Array<Int> = DEFAULT_BUTTON_ANIM_DISABLED;

	// --- Button sounds (optional; default is no sounds) ---
	/** Sound played when the pointer moves over a button (or it becomes highlighted). Null = no sound. */
	public static var buttonSoundOver:Null<FlxSoundAsset> = null;
	/** Sound played when a button is pressed down. Null = no sound. */
	public static var buttonSoundDown:Null<FlxSoundAsset> = null;
	/** Sound played when a button click/activation completes (mouse up inside / click). Null = no sound. */
	public static var buttonSoundClick:Null<FlxSoundAsset> = null;

	// --- Button labels (optional; defaults to FlxText label) ---
	/** Default label font (asset id). Null uses the default font. */
	public static var buttonLabelFont:Null<String> = null;
	/** Default label size. */
	public static var buttonLabelSize:Int = 14;
	/** Default label color. */
	public static var buttonLabelColor:flixel.util.FlxColor = 0xFF666666;
	/** Default label color when highlighted/hovered. Null => fall back to buttonLabelColor. */
	public static var buttonLabelColorHover:Null<flixel.util.FlxColor> = 0xFF333333;
	/** Default label color when pressed. Null => fall back to buttonLabelColorHover, then buttonLabelColor. */
	public static var buttonLabelColorDown:Null<flixel.util.FlxColor> = 0xFF333333;
	/** Default label color when disabled. Null => fall back to buttonLabelColor. */
	public static var buttonLabelColorDisabled:Null<flixel.util.FlxColor> = 0xFF777777;
	/** Default label alignment (recommended CENTER for buttons). */
	public static var buttonLabelAlign:FlxTextAlign = CENTER;
	/** Optional factory for creating custom label sprites (e.g. FlxBitmapText). Null uses FlxText. */
	public static var buttonLabelFactory:Null<FlxUXLabelFactory> = null;
	// --- Focus highlight configuration (null => core/group fallback => built-in default) ---
	/** Current focus highlight mode (defaults to FRAME). */
	public static var focusMode:FlxUXFocusMode = FlxUXFocusMode.FRAME;
	/** Frames per second for animated focus frame (when focusFrameGraphic is a spritesheet 9-slice). */
	public static var focusFrameFps:Int = DEFAULT_FOCUS_FRAME_FPS;

	/**
	 * Focus frame graphic input.
	 *
	 * Accepts: String, FlxGraphic, FlxSprite, BitmapData, FlxUX9Slice.
	 */
	public static var focusFrameGraphic:FlxUXGraphicInput = DEFAULT_FOCUS_FRAME_GRAPHIC;

	/** Focus next-to graphic input. */
	public static var focusNextToGraphic:Null<FlxUXGraphicInput> = null;
	/** If true, also show next-to graphic on right side. */
	public static var focusNextToMirrored:Bool = false;
	/** Optional right-side graphic input for mirrored next-to. If null, uses focusNextToGraphic (optionally flipped). */
	public static var focusNextToGraphicRight:Null<FlxUXGraphicInput> = null;
	/** If true, flips the right-side next-to graphic horizontally. */
	public static var focusNextToFlipRight:Bool = true;
	/** Gap between button and next-to graphic (pixels). */
	public static var focusNextToGap:Float = 6;
	/** Y offset applied to next-to sprites (pixels). */
	public static var focusNextToOffsetY:Float = 0;

	/** Focus overlay (on-top) graphic input. */
	public static var focusOverlayGraphic:Null<FlxUXGraphicInput> = null;
	/** Overlay placement: x = buttonRight + offsetX, y = buttonBottom + offsetY (defaults give half-hang). */
	public static var focusOverlayOffsetX:Float = -8;
	public static var focusOverlayOffsetY:Float = -8;

	/**
	 * When `false`, FlxUX will not process user input (NAV or pointer-triggered mode switching).
	 *
	 * This is intended for state transitions, fades, and other moments where input should be
	 * temporarily ignored.
	 *
	 * Notes:
	 * - `ready` is set to `false` automatically on Flixel state transitions.
	 * - If `autoReady` is `true` (default), FlxUX will set `ready = true` automatically once
	 *   the new state is created.
	 */
	public static var ready(default, set):Bool = true;

	/**
	 * If `true` (default), FlxUX will automatically enable input (`ready = true`) after a state
	 * transition once the new state has been created.
	 *
	 * Set this to `false` if you want to enable input manually after a fade/tween.
	 */
	public static var autoReady:Bool = true;

	/**
	 * Master enable for FlxUX as a system (plugin still runs, but logic early-outs).
	 */
	public static var active:Bool = true;

	/**
	 * Controls whether NAV processing (focus/confirm/cancel) is allowed at all.
	 * Useful if a game wants FlxUX cursor service but never wants FlxUX to read nav.
	 */
	public static var navEnabled:Bool = true;

	/**
	 * Controls whether FlxUX mouse service runs (hardware cursor override / pressed state).
	 */
	public static var cursorEnabled:Bool = true;

	/**
	 * If true (default), FlxUX will disable sprite antialiasing globally using `FlxSprite.defaultAntialiasing`.
	 *
	 * This helps pixel art UI look crisp by default. Games that want smoothing can set this to `false`
	 * before calling `FlxUXCore.init()`.
	 */
	public static var pixelArtDefaults:Bool = true;

	/** If true, FlxUXGroup layout helpers will snap button positions to whole pixels. */
	public static var snapUiToPixels:Bool = true;
	/** Hardware cursor graphic input (optional). Accepts: String, FlxGraphic, FlxSprite, BitmapData. */
	public static var mouseCursorGraphic:FlxUXGraphicInput = DEFAULT_MOUSE_GRAPHIC;

	/** Restores built-in defaults (graphics + common focus settings). */
	public static function resetDefaults():Void
	{
		mouseCursorGraphic = DEFAULT_MOUSE_GRAPHIC;
		buttonGraphic = null;
		buttonSkinFps = DEFAULT_BUTTON_SKIN_FPS;
		buttonUseAnim = DEFAULT_BUTTON_USE_ANIM;
		buttonAnimUp = DEFAULT_BUTTON_ANIM_UP;
		buttonAnimOver = DEFAULT_BUTTON_ANIM_OVER;
		buttonAnimDown = DEFAULT_BUTTON_ANIM_DOWN;
		buttonAnimDisabled = DEFAULT_BUTTON_ANIM_DISABLED;
		buttonSoundOver = null;
		buttonSoundDown = null;
		buttonSoundClick = null;
		buttonLabelFont = null;
		buttonLabelSize = 14;
		buttonLabelColor = 0xFF666666;
		buttonLabelColorHover = 0xFF333333;
		buttonLabelColorDown = 0xFF333333;
		buttonLabelColorDisabled = 0xFF777777;
		buttonLabelAlign = CENTER;
		buttonLabelFactory = null;
		focusMode = FlxUXFocusMode.FRAME;
		focusFrameFps = DEFAULT_FOCUS_FRAME_FPS;
		focusFrameGraphic = DEFAULT_FOCUS_FRAME_GRAPHIC;
		focusNextToGraphic = null;
		focusNextToMirrored = false;
		focusNextToGraphicRight = null;
		focusNextToFlipRight = true;
		focusNextToGap = 6;
		focusNextToOffsetY = 0;
		focusOverlayGraphic = null;
		focusOverlayOffsetX = -8;
		focusOverlayOffsetY = -8;
	}

	/** Resets button skin settings to the built-in defaults (does not change focus/mouse defaults). */
	public static function resetButtonDefaults():Void
	{
		buttonGraphic = null;
		buttonSkinFps = DEFAULT_BUTTON_SKIN_FPS;
		buttonUseAnim = DEFAULT_BUTTON_USE_ANIM;
		buttonAnimUp = DEFAULT_BUTTON_ANIM_UP;
		buttonAnimOver = DEFAULT_BUTTON_ANIM_OVER;
		buttonAnimDown = DEFAULT_BUTTON_ANIM_DOWN;
		buttonAnimDisabled = DEFAULT_BUTTON_ANIM_DISABLED;
		buttonSoundOver = null;
		buttonSoundDown = null;
		buttonSoundClick = null;
		buttonLabelFont = null;
		buttonLabelSize = 14;
		buttonLabelColor = 0xFF666666;
		buttonLabelColorHover = 0xFF333333;
		buttonLabelColorDown = 0xFF333333;
		buttonLabelColorDisabled = 0xFF777777;
		buttonLabelAlign = CENTER;
		buttonLabelFactory = null;
	}

	/** Forces the built-in static button sheet (no per-state animation playback). */
	public static function useDefaultButtonSkinStatic():Void
	{
		buttonGraphic = null;
		buttonUseAnim = false;
		buttonSkinFps = 0;
	}

	/** Forces the built-in animated button sheet + uses the default sequences. */
	public static function useDefaultButtonSkinAnim(fps:Int = DEFAULT_BUTTON_SKIN_FPS):Void
	{
		buttonGraphic = null;
		buttonUseAnim = true;
		buttonSkinFps = (fps > 0) ? fps : DEFAULT_BUTTON_SKIN_FPS;
		buttonAnimUp = DEFAULT_BUTTON_ANIM_UP;
		buttonAnimOver = DEFAULT_BUTTON_ANIM_OVER;
		buttonAnimDown = DEFAULT_BUTTON_ANIM_DOWN;
		buttonAnimDisabled = DEFAULT_BUTTON_ANIM_DISABLED;
	}

	/**
	 * Sets a custom button skin graphic for all buttons (can be overridden per-group/per-button).
	 *
	 * If you pass a `FlxUX9Slice` and `fps > 0`, it will animate using per-state sequences.
	 */
	public static function setButtonSkin(graphic:FlxUXGraphicInput, fps:Int = 0):Void
	{
		buttonGraphic = graphic;
		buttonSkinFps = (fps > 0) ? fps : 0;
	}

	/** Overrides the per-state animation sequences used by the animated default (and any 9-slice anim skin). */
	public static function setButtonAnimSequences(up:Array<Int>, over:Array<Int>, down:Array<Int>, disabled:Array<Int>):Void
	{
		buttonAnimUp = up;
		buttonAnimOver = over;
		buttonAnimDown = down;
		buttonAnimDisabled = disabled;
	}

	/**
	 * Determines when FlxUX should process NAV input (keyboard/gamepad focus + confirm/cancel).
	 *
	 * POINTER behavior (mouse clicks) remains normal Flixel behavior through FlxButton callbacks.
	 */
	public static var navCapturePolicy:FlxUXNavCapturePolicy = FlxUXNavCapturePolicy.AUTO;

	/**
	 * Keyboard NAV bindings configuration.
	 *
	 * Set these before calling `init()`, or call `rebindInputs()` to apply changes at runtime.
	 */
	public static var keyboardArrows:Bool = true;
	public static var keyboardWASD:Bool = true;

	/**
	 * Gamepad NAV bindings configuration.
	 *
	 * Set these before calling `init()`, or call `rebindInputs()` to apply changes at runtime.
	 */
	public static var gamepadDpad:Bool = true;
	public static var gamepadLeftStick:Bool = true;
	public static var gamepadRightStick:Bool = false;

	/**
	 * Determines how gamepad confirm/cancel are mapped.
	 *
	 * - `NINTENDO` (default): right-face confirm, bottom-face cancel
	 * - `PSX`: bottom-face confirm, right-face cancel
	 */
	public static var gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle = FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO;

	/** Current global input mode (POINTER or NAV). Updated automatically each frame. */
	public static var mode:FlxUXCore.FlxUXInputMode = FlxUXCore.FlxUXInputMode.POINTER;
	/** Current navigation style. */
	public static var navStyle:FlxUXNavStyle = FlxUXNavStyle.LINEAR;

	/** Global theme values used by FlxUX widgets (planned). */
	public static var theme:FlxUXTheme = new FlxUXTheme();

	/** Sets the active theme and applies any immediate core-wide values. */
	public static function setTheme(t:FlxUXTheme):Void
	{
		theme = (t != null) ? t : new FlxUXTheme();
		applyTheme();
		refreshLiveUi();
	}

	/** Applies the currently active theme to any core-wide defaults. */
	public static function applyTheme():Void
	{
		// Apply theme values to core-wide defaults.
		// (We intentionally don't touch sounds here yet.)
		if (theme == null)
			theme = new FlxUXTheme();

		pixelArtDefaults = theme.pixelArtDefaults;
		snapUiToPixels = theme.snapUiToPixels;

		buttonUseAnim = theme.buttonUseAnim;
		buttonSkinFps = theme.buttonSkinFps;
		buttonGraphic = theme.buttonGraphic;
		buttonAnimUp = theme.buttonAnimUp;
		buttonAnimOver = theme.buttonAnimOver;
		buttonAnimDown = theme.buttonAnimDown;
		buttonAnimDisabled = theme.buttonAnimDisabled;
		buttonSoundOver = theme.buttonSoundOver;
		buttonSoundDown = theme.buttonSoundDown;
		buttonSoundClick = theme.buttonSoundClick;
		buttonLabelFont = theme.buttonLabelFont;
		buttonLabelSize = theme.buttonLabelSize;
		buttonLabelColor = theme.buttonLabelColor;
		buttonLabelColorHover = theme.buttonLabelColorHover;
		buttonLabelColorDown = theme.buttonLabelColorDown;
		buttonLabelColorDisabled = theme.buttonLabelColorDisabled;
		buttonLabelAlign = switch (StringTools.trim(theme.buttonLabelAlign).toLowerCase())
		{
			case "left": LEFT;
			case "right": RIGHT;
			default: CENTER;
		};

		focusMode = theme.focusMode;
		focusFrameFps = theme.focusFrameFps;
		focusFrameGraphic = theme.focusFrameGraphic;
		focusNextToGraphic = theme.focusNextToGraphic;
		focusNextToMirrored = theme.focusNextToMirrored;
		focusNextToGraphicRight = theme.focusNextToGraphicRight;
		focusNextToFlipRight = theme.focusNextToFlipRight;
		focusNextToGap = theme.focusNextToGap;
		focusNextToOffsetY = theme.focusNextToOffsetY;
		focusOverlayGraphic = theme.focusOverlayGraphic;
		focusOverlayOffsetX = theme.focusOverlayOffsetX;
		focusOverlayOffsetY = theme.focusOverlayOffsetY;
	}

	/**
	 * Re-applies skin/highlight visuals to any groups/buttons that are currently registered.
	 *
	 * This is called automatically when `setTheme()` is used.
	 */
	public static function refreshLiveUi():Void
	{
		if (groups == null) return;
		for (g in groups)
		{
			if (g == null) continue;
			g.refreshTheme();
		}
	}

	/** Loads a theme from a JSON string and activates it. */
	public static function loadThemeFromJsonString(json:String):FlxUXTheme
	{
		var obj:Dynamic = null;
		try
		{
			obj = Json.parse(json);
		}
		catch (_)
		{
			obj = null;
		}
		var t = FlxUXTheme.fromObject(obj);
		setTheme(t);
		return t;
	}

	/** Loads a theme from an embedded text asset id (e.g. "assets/themes/default.json") and activates it. */
	public static function loadThemeFromAsset(assetId:String):FlxUXTheme
	{
		if (assetId == null) return theme;
		var json:String = null;
		try
		{
			json = Assets.getText(assetId);
		}
		catch (_)
		{
			json = null;
		}
		if (json == null) return theme;
		return loadThemeFromJsonString(json);
	}

	/**
	 * Action bindings used by FlxUX.
	 *
	 * Created by `init()` and rebuilt by `rebindInputs()`.
	 */
	public static var actions:FlxUXActions;
	/** Mouse/cursor helper used by FlxUX. Created by `init()`. */
	public static var mouse:FlxUXMouse;

	private static var groups:Array<FlxUXGroup> = [];
	/** Currently focused button for NAV mode, or `null` if nothing is focused. */
	public static var focused:FlxUXButton = null;
	private static var navConfirmHeld:Bool = false;
	private static var pointerPreferred:Bool = false;

	private static var initialized:Bool = false;
	private static var pendingAutoReady:Bool = false;

	/**
	 * Initializes FlxUX.
	 *
	 * This is safe to call multiple times.
	 *
	 * Creates the action bindings and mouse helper, installs the FlxUX plugin, and hooks
	 * Flixel state transition signals so groups are automatically cleared between states.
	 */
	public static function init():Void
	{
		if (initialized) return;
		initialized = true;
		// FlxUX must not initialize until FlxGame has been constructed.
		// In some setups FlxUXGroup may be created very early; safely no-op until FlxG.inputs exists.
		if (flixel.FlxG.inputs == null)
			return;

		if (pixelArtDefaults)
		{
			FlxSprite.defaultAntialiasing = false;
		}

		actions = new FlxUXActions(
			keyboardArrows,
			keyboardWASD,
			gamepadDpad,
			gamepadLeftStick,
			gamepadRightStick,
			gamepadFaceStyle);

		mouse = new FlxUXMouse();
		mouse.init();

		FlxG.plugins.addIfUniqueType(new FlxUXPlugin());

		FlxG.signals.preStateSwitch.add(_onStateTransition);
		FlxG.signals.preStateCreate.add((_) -> _onStateTransition());
	}

	/**
	 * Rebuilds action bindings using the current configuration flags.
	 *
	 * If FlxUX has not been initialized yet, this will call `init()` first.
	 */
	public static function rebindInputs():Void
	{
		if (!initialized) init();

		actions.rebind(
			keyboardArrows,
			keyboardWASD,
			gamepadDpad,
			gamepadLeftStick,
			gamepadRightStick,
			gamepadFaceStyle);
	}

	/**
	 * Removes all registered groups from FlxUX and clears the focused button.
	 *
	 * Note: groups are not destroyed; they are only unregistered.
	 */
	public static function clearGroups():Void
	{
		groups = [];
		setFocused(null);
		navConfirmHeld = false;
	}

	private static function _onStateTransition():Void
	{
		clearGroups();
		ready = false;
		pendingAutoReady = autoReady;
	}

	private static function set_ready(value:Bool):Bool
	{
		if (ready == value)
			return value;

		ready = value;

		// When input becomes ready in NAV mode, ensure we have a deterministic focus.
		if (ready && mode == FlxUXCore.FlxUXInputMode.NAV)
			tryFocusFirstEligible();

		return value;
	}

	/**
	 * Registers a group with FlxUX so it can participate in NAV focus traversal.
	 *
	 * @param group The group to add.
	 * @param order Optional dense ordering index (insert semantics).
	 */
	public static function addGroup(group:FlxUXGroup, ?order:Int):Void
	{
		if (!initialized) init();
		insertDense(groups, group, order);
	}

	/**
	 * Unregisters a group.
	 *
	 * If the currently focused button belongs to this group, focus will be cleared.
	 *
	 * @return `true` if the group was present and removed.
	 */
	public static function removeGroup(group:FlxUXGroup):Bool
	{
		var i = groups.indexOf(group);
		if (i >= 0)
		{
			if (focused != null && group.containsButton(focused))
				setFocused(null);
			groups.splice(i, 1);
			return true;
		}
		return false;
	}

	/**
	 * Changes a group's dense ordering index within FlxUX.
	 *
	 * Uses insert semantics: the group is removed then reinserted at the clamped index.
	 */
	public static function setGroupOrder(group:FlxUXGroup, order:Int):Void
	{
		var i = groups.indexOf(group);
		if (i < 0) return;
		groups.splice(i, 1);
		insertDense(groups, group, order);
	}

	private static function insertDense<T>(arr:Array<T>, item:T, ?index:Int):Void
	{
		if (index == null)
		{
			arr.push(item);
			return;
		}

		var i:Int = index;
		if (i < 0) i = 0;
		if (i > arr.length) i = arr.length;
		arr.insert(i, item);
	}

	@:allow(flixel.ux.FlxUXPlugin)
	private static function internalUpdate(elapsed:Float):Void
	{
		if (!initialized) init();
		if (pendingAutoReady)
		{
			// If autoReady is enabled, allow input again once we're updating inside the new state.
			pendingAutoReady = false;
			ready = true;
		}

		if (!ready)
			return;

		actions.update();

		// Always allow mode switching & cursor handling, independent from NAV capture.
		var mouseInput = actions.moveMouse.triggered || actions.pointerPressDown;
		var touchInput = _hasTouchPointerInput();

		if (mouseInput || touchInput)
		{
			mode = FlxUXCore.FlxUXInputMode.POINTER;
			// Touch behaves like pointer UX but should not show a mouse cursor.
			pointerPreferred = mouseInput;
		}
		else if (actions.up.triggered || actions.down.triggered || actions.left.triggered || actions.right.triggered
			|| actions.confirm.triggered || actions.cancel.triggered)
		{
			mode = FlxUXCore.FlxUXInputMode.NAV;
			pointerPreferred = false;
		}

		if (cursorEnabled)
		{
			mouse.enabled = true;
			FlxG.mouse.visible = pointerPreferred;
			mouse.update(elapsed, actions.pointerPressDown);
		}
		else
		{
			mouse.enabled = false;
			FlxG.mouse.visible = false;
		}

		if (!active)
			return;

		// POINTER: FlxButtons handle mouse clicks themselves.

		// NAV: only if allowed by policy and there are eligible nav targets (AUTO).
		if (mode == FlxUXCore.FlxUXInputMode.NAV && navEnabled)
		{
			var navTargets = getFlattenedEligibleNavButtons(); // groups that capture nav only
			var hasTargets = navTargets.length > 0;

			var shouldProcessNav = switch (navCapturePolicy)
			{
				case FlxUXNavCapturePolicy.NEVER: false;
				case FlxUXNavCapturePolicy.ALWAYS: true;
				case FlxUXNavCapturePolicy.AUTO: hasTargets;
			};

			if (shouldProcessNav && _effectiveNavStyle() == FlxUXNavStyle.LINEAR)
			{
				// Sync focused button visuals with confirm pressed state.
				var confirmHeldNow = actions.confirmDown;
				if (focused != null)
					focused.setNavPressed(confirmHeldNow);
				navConfirmHeld = confirmHeldNow;

				if (actions.right.triggered || actions.down.triggered)
					focusNext(navTargets);
				else if (actions.left.triggered || actions.up.triggered)
					focusPrev(navTargets);

				// Activate on release (button-up) so holding confirm shows pressed state.
				if (actions.confirmReleased)
				{
					if (focused != null) focused.setNavPressed(false);
					activateFocused();
				}

				if (actions.cancel.triggered)
					cancel();
			}
			else if (shouldProcessNav)
			{
				// SPATIAL (or future): directionally pick the nearest neighbor.
				var dirX = 0;
				var dirY = 0;
				if (actions.left.triggered) dirX = -1;
				else if (actions.right.triggered) dirX = 1;
				else if (actions.up.triggered) dirY = -1;
				else if (actions.down.triggered) dirY = 1;

				if (dirX != 0 || dirY != 0)
					focusSpatial(navTargets, dirX, dirY);

				// Activate on release (button-up) so holding confirm shows pressed state.
				if (actions.confirmReleased)
				{
					if (focused != null) focused.setNavPressed(false);
					activateFocused();
				}

				if (actions.cancel.triggered)
					cancel();
			}
		}
	}

	private static function _effectiveNavStyle():FlxUXNavStyle
	{
		if (focused != null)
		{
			var g = focused._getUXGroup();
			if (g != null && g.navStyle != null)
				return g.navStyle;
		}
		return navStyle;
	}

	private static function focusSpatial(list:Array<FlxUXButton>, dirX:Int, dirY:Int):Void
	{
		if (focused == null) return;
		if (list == null || list.length == 0) return;

		// If the focused group requests LINEAR (override), honor it.
		if (_effectiveNavStyle() != FlxUXNavStyle.SPATIAL)
		{
			if (dirX > 0 || dirY > 0) focusNext(list);
			else focusPrev(list);
			return;
		}

		var origin = FlxPoint.get(focused.x + focused.width * 0.5, focused.y + focused.height * 0.5);
		var focusedGroup = focused._getUXGroup();

		inline function scoreCandidate(b:FlxUXButton):Float
		{
			var cx = b.x + b.width * 0.5;
			var cy = b.y + b.height * 0.5;
			var dx = cx - origin.x;
			var dy = cy - origin.y;

			// Direction filter
			if (dirX < 0 && dx >= 0) return Math.POSITIVE_INFINITY;
			if (dirX > 0 && dx <= 0) return Math.POSITIVE_INFINITY;
			if (dirY < 0 && dy >= 0) return Math.POSITIVE_INFINITY;
			if (dirY > 0 && dy <= 0) return Math.POSITIVE_INFINITY;

			var primary = (dirX != 0) ? Math.abs(dx) : Math.abs(dy);
			var secondary = (dirX != 0) ? Math.abs(dy) : Math.abs(dx);
			return primary * 1000 + secondary;
		}

		// Pass 1: try within current group.
		var best:FlxUXButton = null;
		var bestScore = Math.POSITIVE_INFINITY;
		for (b in list)
		{
			if (b == null || b == focused) continue;
			if (focusedGroup != null && b._getUXGroup() != focusedGroup) continue;
			var s = scoreCandidate(b);
			if (s < bestScore)
			{
				bestScore = s;
				best = b;
			}
		}

		// Pass 2: if no neighbor in-group, allow moving to another group.
		// We do this in two steps:
		//  1) choose the best *group* in the intended direction using group bounds
		//  2) choose the best button within that group using the same scoring
		if (best == null)
		{
			var bestGroup:FlxUXGroup = null;
			var bestGroupScore = Math.POSITIVE_INFINITY;

			// Find candidate groups (excluding the current one)
			for (g in groups)
			{
				if (g == null || !g.active || !g.capturesNav || !g.uxActive) continue;
				if (focusedGroup != null && g == focusedGroup) continue;
				var elig = g.getEligibleButtonsOrdered();
				if (elig == null || elig.length == 0) continue;

				// Use group button-bounds as a representative rectangle
				var gx0 = g.boundsX;
				var gy0 = g.boundsY;
				var gx1 = gx0 + g.width;
				var gy1 = gy0 + g.height;
				var gcx = (gx0 + gx1) * 0.5;
				var gcy = (gy0 + gy1) * 0.5;

				// Determine if the group is actually in the requested direction.
				// For LEFT, the group's right edge must be <= origin.x (so it's not above/below-only).
				// For UP, the group's bottom edge must be <= origin.y, etc.
				if (dirX < 0 && gx1 > origin.x) continue;
				if (dirX > 0 && gx0 < origin.x) continue;
				if (dirY < 0 && gy1 > origin.y) continue;
				if (dirY > 0 && gy0 < origin.y) continue;

				var dx = gcx - origin.x;
				var dy = gcy - origin.y;
				var primary = (dirX != 0) ? Math.abs(dx) : Math.abs(dy);
				var secondary = (dirX != 0) ? Math.abs(dy) : Math.abs(dx);
				var score = primary * 1000 + secondary;
				if (score < bestGroupScore)
				{
					bestGroupScore = score;
					bestGroup = g;
				}
			}

			if (bestGroup != null)
			{
				bestScore = Math.POSITIVE_INFINITY;
				var elig = bestGroup.getEligibleButtonsOrdered();
				for (b in elig)
				{
					if (b == null) continue;
					var s = scoreCandidate(b);
					if (s < bestScore)
					{
						bestScore = s;
						best = b;
					}
				}
			}
			else
			{
				// Fallback to any button if no group qualifies (should be rare).
				bestScore = Math.POSITIVE_INFINITY;
				for (b in list)
				{
					if (b == null || b == focused) continue;
					var s = scoreCandidate(b);
					if (s < bestScore)
					{
						bestScore = s;
						best = b;
					}
				}
			}
		}

		origin.put();
		if (best != null) setFocused(best);
	}

	/**
	 * Triggers the active group's cancel callback, if the focused button belongs to one.
	 *
	 * This only considers active groups that capture NAV.
	 */
	public static function cancel():Void
	{
		if (focused != null)
		{
			for (g in groups)
			{
				if (g == null || !g.active || !g.capturesNav) continue;
				var elig = g.getEligibleButtonsOrdered();
				if (elig.indexOf(focused) >= 0)
				{
					if (g.onCancel != null)
						g.onCancel();
					return;
				}
			}
		}
	}

	/**
	 * Activates the currently focused button, if it is eligible.
	 */
	public static function activateFocused():Void
	{
		if (focused != null && focused.isUXEligible())
			focused.activate();
	}

	/**
	 * Attempts to focus the first eligible NAV target.
	 *
	 * This is useful for menus that are created while already in NAV mode, or when opening
	 * a pause menu / modal and you want a deterministic initial focus.
	 *
	 * @return `true` if focus was changed to a valid button.
	 */
	public static function tryFocusFirstEligible():Bool
	{
		var navTargets = getFlattenedEligibleNavButtons();
		if (navTargets.length == 0)
			return false;
		setFocused(navTargets[0]);
		return focused != null;
	}

	private static function focusNext(list:Array<FlxUXButton>):Void
	{
		if (list.length == 0) return;

		var idx = list.indexOf(focused);
		if (idx < 0) idx = -1;

		setFocused(list[(idx + 1) % list.length]);
	}

	private static function focusPrev(list:Array<FlxUXButton>):Void
	{
		if (list.length == 0) return;

		var idx = list.indexOf(focused);
		if (idx < 0) idx = 0;

		var prevIndex = idx - 1;
		if (prevIndex < 0) prevIndex = list.length - 1;

		setFocused(list[prevIndex]);
	}

	/**
	 * Sets the focused button for NAV mode.
	 *
	 * Updates focus state on both the previous and new button.
	 */
	public static function setFocused(button:FlxUXButton):Void
	{
		var prev = focused;
		if (button == focused)
			return;

		if (focused != null)
		{
			focused.setNavPressed(false);
			focused.setFocused(false);
		}

		focused = button;

		if (focused != null)
		{
			focused.setFocused(true);
			// If confirm is already held while focus changes, keep pressed visuals in sync.
			focused.setNavPressed(navConfirmHeld);
		}

		// Update per-group highlighter visuals.
		if (prev != null)
		{
			var gPrev = prev._getUXGroup();
			if (gPrev != null) gPrev.updateFocusGraphics();
		}
		if (focused != null)
		{
			var gNow = focused._getUXGroup();
			if (gNow != null) gNow.updateFocusGraphics();
		}
	}

	/**
	 * NAV targets only: groups must be active AND capturesNav.
	 */
	private static function getFlattenedEligibleNavButtons():Array<FlxUXButton>
	{
		var out:Array<FlxUXButton> = [];
		for (g in groups)
		{
			if (g == null || !g.uxActive || !g.capturesNav) continue;
			var buttons = g.getEligibleButtonsOrdered();
			for (b in buttons)
				out.push(b);
		}

		// keep focused valid
		if (focused != null && out.indexOf(focused) < 0)
		{
			if (focused != null) focused.setFocused(false);
			focused = null;
		}

		if (focused == null && out.length > 0)
			setFocused(out[0]);

		return out;
	}

	private static function _insertDense<T>(arr:Array<T>, item:T, ?order:Int):Void
	{
		var maxIndex = arr.length;
		var pos = order;

		if (pos == null)
			pos = maxIndex;
		else
		{
			if (pos < 0) pos = 0;
			if (pos > maxIndex) pos = maxIndex;
		}

		arr.insert(pos, item);
	}

	private static function _hasTouchPointerInput():Bool
	{
		#if FLX_NO_TOUCH
		return false;
		#else
		if (FlxG.touches == null || FlxG.touches.list == null)
			return false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null) continue;

			if (touch.justPressed || touch.pressed)
				return true;
		}

		return false;
		#end
	}
}

/** Alignment options for the final row in `FlxUXGroup.grid()` when it is not full. */
enum FlxUXGridLastRowAlign
{
	LEFT;
	CENTER;
	RIGHT;
}

/**
 * Which focus highlight strategy to use in NAV mode.
 */
enum FlxUXFocusMode
{
	/** 9-slice focus frame around the focused widget. */
	FRAME;
	/** A sprite drawn next to the focused widget (optionally mirrored). */
	NEXT_TO;
	/** A sprite drawn over the focused widget (typically bottom-right half-hang). */
	OVERLAY;
	/** Pointer hover only: no NAV focus visuals (still allows pointer clicks). */
	HOVER_ONLY;
	/** Dim non-focused widgets (future; no group-level sprite). */
	DIM_UNFOCUSED;
}

// -------------------------------------------------------------------------------------------------
// Enums (kept here so FlxUXCore is the one-stop shop for configuration types)
// -------------------------------------------------------------------------------------------------

/**
 * Global input mode used by FlxUX.
 *
 * - `POINTER`: mouse/touch input. Focus does not matter; clicking activates the clicked button.
 * - `NAV`: keyboard/gamepad navigation. Focus matters; confirm activates the focused button.
 */
enum FlxUXInputMode
{
	/** Pointer-centric UX (mouse/touch). */
	POINTER;
	/** Navigation-centric UX (keyboard/gamepad). */
	NAV;
}

/** Determines how confirm/cancel are mapped on a gamepad. */
enum FlxUXGamepadFaceStyle
{
	/** Nintendo-style: right-face confirm, bottom-face cancel. */
	NINTENDO;
	/** PlayStation-style: bottom-face confirm, right-face cancel. */
	PSX;
}

/** Simple alignment enum for FlxUX layout helpers. */
enum FlxUXAlign
{
	LEFT;
	CENTER;
	RIGHT;
}

/** Selects the navigation algorithm used for focus traversal. */
enum FlxUXNavStyle
{
	/** Linear ordering navigation (next/previous). */
	LINEAR;
	/** Spatial navigation (direction-based nearest neighbor). */
	SPATIAL;
}

/**
 * Determines when FlxUX should process NAV input (keyboard/gamepad focus + confirm/cancel).
 *
 * POINTER behavior (mouse clicks) remains normal Flixel behavior through FlxButton callbacks.
 */
enum FlxUXNavCapturePolicy
{
	/** Default: only process NAV when there is at least one eligible NAV target. */
	AUTO;
	/** Always process NAV when FlxUXCore.navEnabled is true. */
	ALWAYS;
	/** Never process NAV (mouse/touch-only UX). */
	NEVER;
}

// FlxUXFocusMode is declared at the bottom of this file.