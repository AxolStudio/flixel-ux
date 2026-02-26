package flixel.ux;

import flixel.FlxG;

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

/**
 * Selects the navigation algorithm used for focus traversal.
 */
enum FlxUXNavStyle
{
	/** Linear ordering navigation (next/previous). */
	LINEAR;
	/** Spatial navigation (planned, not implemented yet). */
	SPATIAL;
}

/**
 * Determines how confirm/cancel are mapped on a gamepad.
 */
enum FlxUXGamepadFaceStyle
{
	/** Nintendo-style: right-face confirm, bottom-face cancel. */
	NINTENDO;
	/** PlayStation-style: bottom-face confirm, right-face cancel. */
	PSX;
}

class FlxUXCore
{
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
	/** Current navigation style. Only `LINEAR` is implemented at the moment. */
	public static var navStyle:FlxUXCore.FlxUXNavStyle = FlxUXCore.FlxUXNavStyle.LINEAR;

	/** Global theme values used by FlxUX widgets. */
	public static var theme:FlxUXTheme = new FlxUXTheme();
	/** Global assets/styles used by FlxUX widgets (can be overridden per group/button). */
	public static var assets:FlxUXAssets = new FlxUXAssets();

	/**
	 * Action bindings used by FlxUX.
	 *
	 * Created by `init()` and rebuilt by `rebindInputs()`.
	 */
	public static var actions:FlxUXActions;
	/** Mouse/cursor helper used by FlxUX. Created by `init()`. */
	public static var mouse:FlxUXMouse;

	private static var _groups:Array<FlxUXGroup> = [];
	/** Currently focused button for NAV mode, or `null` if nothing is focused. */
	public static var focused:FlxUXButton = null;
	private static var _navConfirmHeld:Bool = false;
	private static var _pointerPreferred:Bool = false;

	private static var _initialized:Bool = false;
	private static var _pendingAutoReady:Bool = false;

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
		if (_initialized) return;
		_initialized = true;

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
		if (!_initialized) init();

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
		_groups = [];
		setFocused(null);
		_navConfirmHeld = false;
	}

	private static function _onStateTransition():Void
	{
		clearGroups();
		ready = false;
		_pendingAutoReady = autoReady;
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
		if (!_initialized) init();
		_insertDense(_groups, group, order);
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
		var i = _groups.indexOf(group);
		if (i >= 0)
		{
			if (focused != null && group.containsButton(focused))
				setFocused(null);

			_groups.splice(i, 1);
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
		var i = _groups.indexOf(group);
		if (i < 0) return;
		_groups.splice(i, 1);
		_insertDense(_groups, group, order);
	}

	@:allow(flixel.ux.FlxUXPlugin)
	private static function internalUpdate(elapsed:Float):Void
	{
		if (!_initialized) init();

		// If autoReady is enabled, allow input again once we're updating inside the new state.
		if (_pendingAutoReady)
		{
			_pendingAutoReady = false;
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
			_pointerPreferred = mouseInput;
		}
		else if (actions.up.triggered || actions.down.triggered || actions.left.triggered || actions.right.triggered
			|| actions.confirm.triggered || actions.cancel.triggered)
		{
			mode = FlxUXCore.FlxUXInputMode.NAV;
			_pointerPreferred = false;
		}

		if (cursorEnabled)
		{
			mouse.enabled = true;
			FlxG.mouse.visible = _pointerPreferred;
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

			if (shouldProcessNav && navStyle == FlxUXCore.FlxUXNavStyle.LINEAR)
			{
				// Sync focused button visuals with confirm pressed state.
				var confirmHeldNow = actions.confirmDown;
				if (focused != null)
					focused.setNavPressed(confirmHeldNow);
				_navConfirmHeld = confirmHeldNow;

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
		}
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
			for (g in _groups)
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
			focused.setNavPressed(_navConfirmHeld);
		}
	}

	/**
	 * NAV targets only: groups must be active AND capturesNav.
	 */
	private static function getFlattenedEligibleNavButtons():Array<FlxUXButton>
	{
		var out:Array<FlxUXButton> = [];
		for (g in _groups)
		{
			if (g == null || !g.active || !g.capturesNav) continue;
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