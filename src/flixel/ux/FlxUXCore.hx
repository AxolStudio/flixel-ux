package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfFour;
import haxe.extern.EitherType;
import openfl.display.BitmapData;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import openfl.Assets;

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
	public static inline var DEFAULT_MOUSE_GRAPHIC:String = "flixel-ux/mouse_cursor.png";
	public static inline var DEFAULT_BUTTON_SKIN_FPS:Int = 10;
	public static inline var DEFAULT_BUTTON_FRAMES_GRAPHIC:String = "flixel-ux/ux/button.png";
	public static inline var DEFAULT_FOCUS_FRAME_FPS:Int = 6;
	public static var DEFAULT_FOCUS_FRAME_GRAPHIC:FlxUX9Slice = new FlxUX9Slice("flixel-ux/highlight_frame_9s_anim.png", 40, 40, 14, 17, 15, 18);
	public static inline var DEFAULT_FOCUS_NEXT_TO_GRAPHIC:String = "flixel-ux/highlight_next_to.png";
	public static inline var DEFAULT_FOCUS_OVERLAY_GRAPHIC:String = "flixel-ux/highlight_on.png";
	public static var DEFAULT_BUTTON_GRAPHIC:FlxUX9Slice = new FlxUX9Slice(DEFAULT_BUTTON_FRAMES_GRAPHIC, 16, 16, 3, 7, 3, 7);
	public static var DEFAULT_SCROLL_TRACK_GRAPHIC:FlxUX9Slice = new FlxUX9Slice("flixel-ux/scroll_track.png", 8, 8, 3, 3, 3, 3);
	public static var DEFAULT_SCROLL_THUMB_GRAPHIC:FlxUX9Slice = new FlxUX9Slice("flixel-ux/scroll_thumb.png", 12, 12, 4, 4, 4, 4);
	public static inline var DEFAULT_SCROLL_ARROW_GRAPHIC:String = "flixel-ux/scroll_arrows.png";

	/**
	 * Default button skin graphic input.
	 *
	 * Precedence: button -> group -> core.
	 * If `null`, buttons use the built-in default (DEFAULT_BUTTON_GRAPHIC).
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

	/** Sound played when the pointer moves over a button (or it becomes highlighted). Null = no sound. */
	public static var buttonSoundOver:Null<FlxSoundAsset> = null;

	/** Sound played when a button is pressed down. Null = no sound. */
	public static var buttonSoundDown:Null<FlxSoundAsset> = null;

	/** Sound played when a button click/activation completes (mouse up inside / click). Null = no sound. */
	public static var buttonSoundClick:Null<FlxSoundAsset> = null;

	/** Default label font (asset id). Null uses the default font. */
	public static var buttonLabelFont:Null<String> = null;

	/** Default label size. */
	public static var buttonLabelSize:Int = 14;

	/** Default label color. */
	public static var buttonLabelColor:flixel.util.FlxColor = 0xFF222222;

	/** Default label color when highlighted/hovered. Null => fall back to buttonLabelColor. */
	public static var buttonLabelColorHover:Null<flixel.util.FlxColor> = 0xFF333333;

	/** Default label color when pressed. Null => fall back to buttonLabelColorHover, then buttonLabelColor. */
	public static var buttonLabelColorDown:Null<flixel.util.FlxColor> = 0xFF333333;

	/** Default label color when disabled. Null => fall back to buttonLabelColor. */
	public static var buttonLabelColorDisabled:Null<flixel.util.FlxColor> = 0xFF777777;

	/** Default label color when a FlxUXButton is locked (forced DISABLED). Null => fall back to buttonLabelColorDisabled. */
	public static var buttonLabelColorLocked:Null<flixel.util.FlxColor> = 0xFF111111;

	/** Default label alignment (recommended CENTER for buttons). */
	public static var buttonLabelAlign:FlxTextAlign = CENTER;

	/** Optional factory for creating custom label sprites (e.g. FlxBitmapText). Null uses FlxText. */
	public static var buttonLabelFactory:Null<FlxUXLabelFactory> = null;

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
		buttonLabelColor = 0xFF222222;
		buttonLabelColorHover = 0xFF333333;
		buttonLabelColorDown = 0xFF333333;
		buttonLabelColorDisabled = 0xFF777777;
		buttonLabelColorLocked = 0xFF111111;
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
		buttonLabelColor = 0xFF222222;
		buttonLabelColorHover = 0xFF333333;
		buttonLabelColorDown = 0xFF333333;
		buttonLabelColorDisabled = 0xFF777777;
		buttonLabelColorLocked = 0xFF111111;
		buttonLabelAlign = CENTER;
		buttonLabelFactory = null;
	}

	/**
	 * Convenience helper for demos/apps that want to load a theme by asset path.
	 *
	 * This sets `FlxUXCore.theme` using JSON loaded from `openfl.Assets.getText(assetId)`.
	 */
	public static function loadThemeFromAsset(assetId:String):Void
	{
		if (assetId == null)
			return;
		var json = Assets.getText(assetId);
		theme = FlxUXTheme.fromJson(json);
	}

	/** Forces the built-in static button sheet (no per-state animation playback). */
	public static function useDefaultButtonSkinStatic():Void
	{
		buttonGraphic = null;
		buttonUseAnim = false;
		buttonSkinFps = 0;
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

	/** Overrides the per-state animation sequences used by any animated 9-slice button skin. */
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
	public static var keyboardEnabled:Bool = true;
	public static var keyboardTab:Bool = true;
	public static var keyboardHomeEnd:Bool = true;
	public static var paneNavigation:Bool = false;
	public static var shortcutsEnabled:Bool = true;
	public static var showKeyboardCues:Bool = true;
	public static var captureShortcuts:Bool = true;
	public static var keyboardBindings:Map<String, Array<String>> = new Map();
	public static var navRepeatDelay:Float = 0.4;
	public static var navRepeatInterval:Float = 0.09;

	public static function isKeyboardEnabled():Bool
	{
		#if !FLX_NO_KEYBOARD
		return keyboardEnabled && FlxG.keys != null && FlxG.keys.enabled;
		#else
		return false;
		#end
	}

	public static function currentState():flixel.FlxState
	{
		var state:flixel.FlxState = FlxG.state;
		while (state != null && state.subState != null)
			state = state.subState;
		return state;
	}

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

	/**
	 * Global theme values used by FlxUX widgets.
	 */
	public static var theme(get, set):FlxUXTheme;

	private static var currentTheme:FlxUXTheme = new FlxUXTheme();

	private static function get_theme():FlxUXTheme
	{
		return currentTheme;
	}

	private static function set_theme(value:FlxUXTheme):FlxUXTheme
	{
		currentTheme = (value != null) ? value : new FlxUXTheme();
		FlxUX9Slice.clearCache();
		applyTheme();
		refreshLiveUi();
		return currentTheme;
	}

	/** Applies the currently active theme to any core-wide defaults. */
	public static function applyTheme():Void
	{
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
	 * This is called automatically when `FlxUXCore.theme` is assigned.
	 */
	public static function refreshLiveUi():Void
	{
		if (groups == null)
			return;
		for (g in groups)
		{
			if (g == null)
				continue;
			g.refreshTheme();
		}
		if (scrollPanels != null)
			for (panel in scrollPanels)
				if (panel != null)
					panel.refreshTheme();
	}

	private static var scrollPanels:Array<FlxUXScrollPanel> = [];

	@:allow(flixel.ux.FlxUXScrollPanel)
	private static function addScrollPanel(panel:FlxUXScrollPanel):Void
	{
		if (panel != null && scrollPanels.indexOf(panel) < 0)
			scrollPanels.push(panel);
	}

	@:allow(flixel.ux.FlxUXScrollPanel)
	private static function removeScrollPanel(panel:FlxUXScrollPanel):Void
	{
		if (panel != null)
			scrollPanels.remove(panel);
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
	private static var lastStateKey:String = "";
	private static var navButtonsUpdatedThisFrame:Map<FlxUXButton, Bool> = new Map();
	private static var lastScope:flixel.FlxState;
	private static var savedFocus:Map<flixel.FlxState, FlxUXButton> = new Map();
	private static var pressedButton:FlxUXButton;
	private static var repeatDirection:Int = -1;
	private static var repeatTime:Float = 0;
	private static var lastModal:FlxUXGroup;
	private static var focusBeforeModal:FlxUXButton;
	private static var modalFocus:Map<FlxUXGroup, FlxUXButton> = new Map();

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
		if (initialized)
			return;
		if (flixel.FlxG.inputs == null)
			return;
		initialized = true;

		if (pixelArtDefaults)
		{
			FlxSprite.defaultAntialiasing = false;
		}

		actions = new FlxUXActions(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);

		mouse = new FlxUXMouse();
		mouse.init();

		FlxG.plugins.addIfUniqueType(new FlxUXPlugin());

		FlxG.signals.preStateSwitch.add(onStateTransition);
		FlxG.signals.preStateCreate.add((unused) -> onStateTransition());
		#if html5
		js.Browser.window.addEventListener("keydown", captureBrowserShortcut, true);
		#end
	}

	#if html5
	private static function captureBrowserShortcut(event:js.html.KeyboardEvent):Void
	{
		if (!captureShortcuts
			|| !active
			|| !ready
			|| !navEnabled
			|| !shortcutsEnabled
			|| !isKeyboardEnabled()
			|| navCapturePolicy == FlxUXNavCapturePolicy.NEVER)
			return;
		var target:js.html.Element = cast event.target;
		if (target != null
			&& (target.tagName == "INPUT"
				|| target.tagName == "TEXTAREA"
				|| target.tagName == "SELECT"
				|| target.getAttribute("contenteditable") == "true"))
			return;
		for (group in groups)
			if (isGroupInputEligible(group))
				for (button in group.getEligibleButtonsOrdered())
					for (binding in [button.hotkey, button.accessKey == null ? null : "ALT+" + button.accessKey])
					{
						var shortcut = new FlxUXShortcut(binding);
						if (shortcut.valid
							&& shortcut.key == event.keyCode
							&& shortcut.matchesModifiers(event.ctrlKey, event.shiftKey, event.altKey, event.metaKey))
							event.preventDefault();
					}
	}
	#end

	/**
	 * Rebuilds action bindings using the current configuration flags.
	 *
	 * If FlxUX has not been initialized yet, this will call `init()` first.
	 */
	public static function rebindInputs():Void
	{
		if (!initialized)
			init();
		if (actions == null)
			return;

		actions.rebind(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);
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
		pressedButton = null;
		savedFocus.clear();
		lastScope = null;
		lastModal = null;
		focusBeforeModal = null;
		modalFocus.clear();
	}

	private static function onStateTransition():Void
	{
		clearGroups();
		setFocused(null);
		ready = false;
		pendingAutoReady = autoReady;
		lastStateKey = "";
	}

	private static function set_ready(value:Bool):Bool
	{
		if (ready == value)
			return value;

		ready = value;
		if (!ready)
		{
			setFocused(null);
			navConfirmHeld = false;
			clearNavButtonsUpdatedThisFrame();
			if (groups != null)
			{
				for (g in groups)
					if (g != null)
						g.updateFocusGraphics();
			}
			return value;
		}

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
		if (!initialized)
			init();
		if (group == null || groups.indexOf(group) >= 0)
			return;
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
			modalFocus.remove(group);
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
		if (i < 0)
			return;
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
		if (i < 0)
			i = 0;
		if (i > arr.length)
			i = arr.length;
		arr.insert(i, item);
	}

	@:allow(flixel.ux.FlxUXPlugin)
	private static function internalUpdate(elapsed:Float):Void
	{
		if (!initialized)
			init();
		if (actions == null)
			return;
		var scope = currentState();
		if (scope != lastScope)
		{
			if (lastScope != null && focused != null && focused.getUXGroup() != null && focused.getUXGroup().ownerState == lastScope)
				savedFocus.set(lastScope, focused);
			lastScope = scope;
			pressedButton = null;
			navConfirmHeld = false;
			setFocused(null);
			var previous = savedFocus.get(scope);
			if (previous != null && getFlattenedEligibleNavButtons().indexOf(previous) >= 0)
				setFocused(previous);
			lastModal = null;
			focusBeforeModal = null;
			var ancestors:Array<flixel.FlxState> = [];
			var ancestor = FlxG.state;
			while (ancestor != null)
			{
				ancestors.push(ancestor);
				ancestor = ancestor.subState;
			}
			for (state in savedFocus.keys())
				if (ancestors.indexOf(state) < 0)
					savedFocus.remove(state);
		}
		if (pendingAutoReady)
		{
			pendingAutoReady = false;
			ready = true;
		}
		if (!ready || !active)
			return;
		actions.update();
		#if FLX_NO_MOUSE
		var mouseInput = false;
		#else
		var mouseInput = FlxG.mouse.enabled && (actions.moveMouse.triggered || actions.pointerPressDown);
		#end
		var touchInput = hasTouchPointerInput();
		if (mouseInput || touchInput)
		{
			mode = FlxUXCore.FlxUXInputMode.POINTER;
			pointerPreferred = mouseInput;
		}
		#if FLX_NO_MOUSE
		if (mouse != null)
			mouse.enabled = false;
		#else
		if (cursorEnabled && mouse != null && FlxG.mouse.enabled)
		{
			mouse.enabled = true;
			FlxG.mouse.visible = pointerPreferred;
			mouse.update(elapsed, actions.pointerPressDown);
		}
		else
		{
			if (mouse != null)
				mouse.enabled = false;
			FlxG.mouse.visible = false;
		}
		#end

		if (!navEnabled || navCapturePolicy == FlxUXNavCapturePolicy.NEVER)
			return;
		var targets = getFlattenedEligibleNavButtons();
		var modal = modalGroup();
		if (modal != lastModal)
		{
			if (lastModal == null)
				focusBeforeModal = focused;
			else if (focused != null)
				modalFocus.set(lastModal, focused);
			var previous = modal == null ? focusBeforeModal : modalFocus.get(modal);
			lastModal = modal;
			if (previous != null && targets.indexOf(previous) >= 0)
				setFocused(previous);
		}
		if (focused != null && targets.indexOf(focused) < 0)
			setFocused(null);
		if (targets.length == 0 && navCapturePolicy == FlxUXNavCapturePolicy.AUTO)
			return;
		if (pressedButton != null && (targets.indexOf(pressedButton) < 0 || pressedButton != focused && focused != null))
		{
			pressedButton.setNavPressed(false);
			pressedButton = null;
		}
		var shortcutButton:FlxUXButton = null;
		if (shortcutsEnabled && isKeyboardEnabled())
			for (button in targets)
				if (button.shortcutTriggered())
				{
					if (shortcutButton == null)
						shortcutButton = button;
					#if debug
					else
						trace("FlxUX: duplicate active shortcut; first registered button wins.");
					#end
				}
		if (shortcutButton != null)
		{
			enterNavMode();
			setFocused(shortcutButton);
			shortcutButton.activate();
			return;
		}
		var direction = navigationDirection(elapsed);
		var panel = focused == null ? null : focused.scrollPanel;
		if (panel != null && panel.handleKeyboard())
		{
			enterNavMode();
			return;
		}
		var tabForward = keyboardTab && actions.tabNext.triggered;
		var tabBackward = keyboardTab && actions.tabPrevious.triggered;
		var first = keyboardHomeEnd && actions.first.triggered;
		var last = keyboardHomeEnd && actions.last.triggered;
		var nextPane = paneNavigation && actions.paneNext.triggered;
		var previousPane = paneNavigation && actions.panePrevious.triggered;
		if (direction >= 0 || tabForward || tabBackward || first || last || nextPane || previousPane || actions.confirm.triggered
			|| actions.accept.triggered || actions.cancel.triggered)
			enterNavMode();
		if (tabForward || tabBackward)
		{
			traverseTab(tabBackward);
			return;
		}
		if (nextPane || previousPane)
		{
			focusPane(previousPane);
			return;
		}
		if (first || last)
		{
			var menuTargets = focused == null ? targets : [for (button in targets) if (button.getUXGroup() == focused.getUXGroup()) button];
			if (menuTargets.length > 0)
				setFocused(menuTargets[last ? menuTargets.length - 1 : 0]);
			return;
		}
		if (direction >= 0)
		{
			if (focused == null)
				tryFocusFirstEligible();
			else if (effectiveNavStyle() == FlxUXNavStyle.LINEAR)
			{
				if (direction == 1 || direction == 3)
					focusNext(targets);
				else
					focusPrev(targets);
			}
			else
				focusSpatial(targets, direction == 2 ? -1 : direction == 3 ? 1 : 0, direction == 0 ? -1 : direction == 1 ? 1 : 0);
		}
		if (actions.cancel.triggered)
		{
			if (pressedButton != null)
				pressedButton.setNavPressed(false);
			pressedButton = null;
			cancel();
			return;
		}
		if (actions.confirm.triggered || actions.accept.triggered)
		{
			pressedButton = focused;
			if (pressedButton == null && (actions.accept.triggered || actions.gamepadConfirmTriggered))
			{
				var group = activeGroup();
				if (group != null && targets.indexOf(group.defaultButton) >= 0)
					pressedButton = group.defaultButton;
				else if (actions.gamepadConfirmTriggered && tryFocusFirstEligible())
					pressedButton = focused;
			}
		}
		navConfirmHeld = actions.confirmDown;
		if (pressedButton != null)
			pressedButton.setNavPressed(navConfirmHeld);
		if (actions.confirmReleased && pressedButton != null)
		{
			var button = pressedButton;
			pressedButton = null;
			button.setNavPressed(false);
			if (targets.indexOf(button) >= 0)
				button.activate();
		}
	}

	private static function enterNavMode():Void
	{
		mode = FlxUXInputMode.NAV;
		pointerPreferred = false;
	}

	private static function navigationDirection(elapsed:Float):Int
	{
		var presses = [
			actions.up.triggered,
			actions.down.triggered,
			actions.left.triggered,
			actions.right.triggered
		];
		for (index in 0...4)
			if (presses[index])
			{
				repeatDirection = index;
				repeatTime = navRepeatDelay;
				return index;
			}
		if (repeatDirection < 0)
			return -1;
		if (!actions.directionHeld[repeatDirection].triggered)
		{
			repeatDirection = -1;
			return -1;
		}
		if (navRepeatInterval <= 0)
			return -1;
		repeatTime -= elapsed;
		if (repeatTime > 0)
			return -1;
		repeatTime = navRepeatInterval;
		return repeatDirection;
	}

	public static function traverseTab(reverse:Bool = false):Void
	{
		var targets = getFlattenedEligibleNavButtons();
		if (targets.length == 0)
			return;
		var index = targets.indexOf(focused);
		if (index < 0)
			index = reverse ? 0 : -1;
		for (offset in 1...targets.length + 1)
		{
			var candidate = targets[(index + (reverse ? -offset : offset) + targets.length * 2) % targets.length];
			if (candidate.tabStop)
			{
				setFocused(candidate);
				return;
			}
		}
	}

	private static function focusPane(reverse:Bool):Void
	{
		var panes:Array<FlxUXGroup> = [];
		for (button in getFlattenedEligibleNavButtons())
			if (panes.indexOf(button.getUXGroup()) < 0)
				panes.push(button.getUXGroup());
		if (panes.length == 0)
			return;
		var index = focused == null ? (reverse ? 0 : -1) : panes.indexOf(focused.getUXGroup());
		index = (index + (reverse ? panes.length - 1 : 1) + panes.length) % panes.length;
		setFocused(panes[index].getEligibleButtonsOrdered()[0]);
	}

	public static function activeGroup():FlxUXGroup
	{
		if (focused != null && isGroupInputEligible(focused.getUXGroup()))
			return focused.getUXGroup();
		for (group in groups)
			if (isGroupInputEligible(group) && (group.defaultButton != null || group.cancelButton != null))
				return group;
		for (group in groups)
			if (isGroupInputEligible(group) && group.onCancel != null)
				return group;
		for (group in groups)
			if (isGroupInputEligible(group))
				return group;
		return null;
	}

	public static function isGroupInputEligible(group:FlxUXGroup, requireNav:Bool = true):Bool
	{
		if (group == null || !group.exists || !group.alive || !group.visible || !group.active || !group.uxActive || requireNav && !group.capturesNav
			|| group.ownerState != currentState())
			return false;
		if (group.scrollPanel != null && (!group.scrollPanel.exists || !group.scrollPanel.visible || !group.scrollPanel.active))
			return false;
		var modal = modalGroup();
		return modal == null || modal == group;
	}

	public static function modalGroup():FlxUXGroup
	{
		var index = groups.length;
		while (index-- > 0)
		{
			var candidate = groups[index];
			if (candidate != null
				&& candidate.modal
				&& candidate.ownerState == currentState()
				&& candidate.exists
				&& candidate.alive
				&& candidate.visible
				&& candidate.active
				&& candidate.uxActive
				&& candidate.capturesNav)
				return candidate;
		}
		return null;
	}

	private static function effectiveNavStyle():FlxUXNavStyle
	{
		if (focused != null)
		{
			var g = focused.getUXGroup();
			if (g != null && g.navStyle != null)
				return g.navStyle;
		}
		return navStyle;
	}

	private static function focusSpatial(list:Array<FlxUXButton>, dirX:Int, dirY:Int):Void
	{
		if (focused == null)
			return;
		if (list == null || list.length == 0)
			return;

		if (effectiveNavStyle() != FlxUXNavStyle.SPATIAL)
		{
			if (dirX > 0 || dirY > 0)
				focusNext(list);
			else
				focusPrev(list);
			return;
		}

		var origin = screenCenter(focused);
		var focusedGroup = focused.getUXGroup();

		inline function scoreCandidate(b:FlxUXButton):Float
		{
			var position = screenCenter(b);
			var dx = position.x - origin.x;
			var dy = position.y - origin.y;
			position.put();

			if (dirX < 0 && dx >= 0)
				return Math.POSITIVE_INFINITY;
			if (dirX > 0 && dx <= 0)
				return Math.POSITIVE_INFINITY;
			if (dirY < 0 && dy >= 0)
				return Math.POSITIVE_INFINITY;
			if (dirY > 0 && dy <= 0)
				return Math.POSITIVE_INFINITY;

			var primary = (dirX != 0) ? Math.abs(dx) : Math.abs(dy);
			var secondary = (dirX != 0) ? Math.abs(dy) : Math.abs(dx);
			return primary * 1000 + secondary;
		}

		var best:FlxUXButton = null;
		var bestScore = Math.POSITIVE_INFINITY;
		for (b in list)
		{
			if (b == null || b == focused)
				continue;
			if (focusedGroup != null && b.getUXGroup() != focusedGroup)
				continue;
			var s = scoreCandidate(b);
			if (s < bestScore)
			{
				bestScore = s;
				best = b;
			}
		}

		if (best == null)
		{
			var bestGroup:FlxUXGroup = null;
			var bestGroupScore = Math.POSITIVE_INFINITY;

			for (g in groups)
			{
				if (!isGroupInputEligible(g))
					continue;
				if (focusedGroup != null && g == focusedGroup)
					continue;
				var elig = [for (button in list) if (button.getUXGroup() == g) button];
				if (elig == null || elig.length == 0)
					continue;

				var gx0 = Math.POSITIVE_INFINITY;
				var gy0 = Math.POSITIVE_INFINITY;
				var gx1 = Math.NEGATIVE_INFINITY;
				var gy1 = Math.NEGATIVE_INFINITY;
				for (button in elig)
				{
					var position = screenCenter(button);
					var zoom = button.getDefaultCamera().zoom;
					gx0 = Math.min(gx0, position.x - button.width * zoom * 0.5);
					gy0 = Math.min(gy0, position.y - button.height * zoom * 0.5);
					gx1 = Math.max(gx1, position.x + button.width * zoom * 0.5);
					gy1 = Math.max(gy1, position.y + button.height * zoom * 0.5);
					position.put();
				}
				var gcx = (gx0 + gx1) * 0.5;
				var gcy = (gy0 + gy1) * 0.5;

				if (dirX < 0 && gx1 > origin.x)
					continue;
				if (dirX > 0 && gx0 < origin.x)
					continue;
				if (dirY < 0 && gy1 > origin.y)
					continue;
				if (dirY > 0 && gy0 < origin.y)
					continue;

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
				var elig = [for (button in list) if (button.getUXGroup() == bestGroup) button];
				for (b in elig)
				{
					if (b == null)
						continue;
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
				bestScore = Math.POSITIVE_INFINITY;
				for (b in list)
				{
					if (b == null || b == focused)
						continue;
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
		if (best != null)
			setFocused(best);
	}

	private static function screenCenter(button:FlxUXButton):FlxPoint
	{
		var camera = button.getDefaultCamera();
		var point = button.getScreenPosition(null, camera);
		point.x = camera.x + (point.x + button.width * 0.5 - camera.viewMarginX) * camera.zoom;
		point.y = camera.y + (point.y + button.height * 0.5 - camera.viewMarginY) * camera.zoom;
		return point;
	}

	/**
	 * Triggers the active group's cancel callback, if the focused button belongs to one.
	 *
	 * This only considers active groups that capture NAV.
	 */
	public static function cancel():Void
	{
		var group = activeGroup();
		if (group == null)
			return;
		if (group.cancelButton != null && group.containsButton(group.cancelButton) && group.cancelButton.isUXEligible())
			group.cancelButton.activate();
		else if (group.onCancel != null)
			group.onCancel();
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
		if (list == null || list.length == 0)
			return;
		if (focused == null)
		{
			setFocused(list[0]);
			return;
		}

		var idx = list.indexOf(focused);
		if (idx < 0)
		{
			setFocused(list[0]);
			return;
		}

		setFocused(list[(idx + 1) % list.length]);
	}

	private static function focusPrev(list:Array<FlxUXButton>):Void
	{
		if (list == null || list.length == 0)
			return;
		if (focused == null)
		{
			setFocused(list[list.length - 1]);
			return;
		}

		var idx = list.indexOf(focused);
		if (idx < 0)
		{
			setFocused(list[list.length - 1]);
			return;
		}

		var prevIndex = idx - 1;
		if (prevIndex < 0)
			prevIndex = list.length - 1;

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
			focused.setNavPressed(false);
			if (focused.getUXGroup() != null)
				savedFocus.set(focused.getUXGroup().ownerState, focused);
			if (focused.scrollPanel != null)
				focused.scrollPanel.ensureVisible(focused);
		}

		if (prev != null)
		{
			var gPrev = prev.getUXGroup();
			if (gPrev != null)
				gPrev.updateFocusGraphics();
		}
		if (focused != null)
		{
			var gNow = focused.getUXGroup();
			if (gNow != null)
				gNow.updateFocusGraphics();
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
			if (!isGroupInputEligible(g))
				continue;
			var buttons = g.getEligibleButtonsOrdered();
			for (b in buttons)
			{
				if (b == null)
					continue;
				if (!navButtonsUpdatedThisFrame.exists(b))
					continue;
				if (out.indexOf(b) < 0)
					out.push(b);
			}
		}

		return out;
	}

	@:allow(flixel.ux.FlxUXButton)
	private static function markNavButtonUpdatedThisFrame(b:FlxUXButton):Void
	{
		if (b == null)
			return;
		navButtonsUpdatedThisFrame.set(b, true);
	}

	@:allow(flixel.ux.FlxUXPlugin)
	private static function clearNavButtonsUpdatedThisFrame():Void
	{
		for (b in navButtonsUpdatedThisFrame.keys())
			navButtonsUpdatedThisFrame.remove(b);
	}

	private static function hasTouchPointerInput():Bool
	{
		#if FLX_NO_TOUCH
		return false;
		#else
		if (FlxG.touches == null || FlxG.touches.list == null)
			return false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null)
				continue;

			if (touch.justPressed || touch.pressed)
				return true;
		}

		return false;
		#end
	}

	private static function stateTickKey():String
	{
		if (FlxG.state == null)
			return "";
		var hx:Dynamic = Reflect.field(FlxG.state, "hashCode");
		if (hx != null)
			return Std.string(hx);
		return Std.string(FlxG.state);
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
