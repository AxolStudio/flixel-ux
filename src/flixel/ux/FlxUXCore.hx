package flixel.ux;

import flixel.FlxG;

class FlxUXCore
{
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

	public static var navCapturePolicy:FlxUXNavCapturePolicy = FlxUXNavCapturePolicy.AUTO;

	public static var mode:FlxUXInputMode = FlxUXInputMode.POINTER;
	public static var navStyle:FlxUXNavStyle = FlxUXNavStyle.LINEAR;

	public static var theme:FlxUXTheme = new FlxUXTheme();

	public static var actions:FlxUXActions;
	public static var mouse:FlxUXMouse;

	private static var _groups:Array<FlxUXGroup> = [];
	public static var focused:FlxUXButton = null;
	private static var _pointerPreferred:Bool = false;

	private static var _initialized:Bool = false;

	public static function init():Void
	{
		if (_initialized) return;
		_initialized = true;

		actions = new FlxUXActions();

		mouse = new FlxUXMouse();
		mouse.init();

		FlxG.plugins.addIfUniqueType(new FlxUXPlugin());

		FlxG.signals.preStateSwitch.add(_onStateTransition);
		FlxG.signals.preStateReset.add(_onStateTransition);
		FlxG.signals.preStateCreate.add(_onStateTransition);
	}

	public static function clearGroups():Void
	{
		_groups = [];
		setFocused(null);
	}

	private static function _onStateTransition():Void
	{
		clearGroups();
	}

	public static function addGroup(group:FlxUXGroup, ?order:Int):Void
	{
		_insertDense(_groups, group, order);
	}

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

		// Always allow mode switching & cursor handling, independent from NAV capture.
		var mouseInput = actions.moveMouse.triggered || actions.pointerPress.triggered;
		var touchInput = _hasTouchPointerInput();

		if (mouseInput || touchInput)
		{
			mode = FlxUXInputMode.POINTER;
			// Touch behaves like pointer UX but should not show a mouse cursor.
			_pointerPreferred = mouseInput;
		}
		else if (actions.up.triggered || actions.down.triggered || actions.left.triggered || actions.right.triggered
			|| actions.confirm.triggered || actions.cancel.triggered)
		{
			mode = FlxUXInputMode.NAV;
			_pointerPreferred = false;
		}

		if (cursorEnabled)
		{
			mouse.enabled = true;
			FlxG.mouse.visible = _pointerPreferred;
			mouse.update(elapsed, actions.pointerPress.pressed);
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
		if (mode == FlxUXInputMode.NAV && navEnabled)
		{
			var navTargets = getFlattenedEligibleNavButtons(); // groups that capture nav only
			var hasTargets = navTargets.length > 0;

			var shouldProcessNav = switch (navCapturePolicy)
			{
				case FlxUXNavCapturePolicy.NEVER: false;
				case FlxUXNavCapturePolicy.ALWAYS: true;
				case FlxUXNavCapturePolicy.AUTO: hasTargets;
			};

			if (shouldProcessNav && navStyle == FlxUXNavStyle.LINEAR)
			{
				if (actions.right.triggered || actions.down.triggered)
					focusNext(navTargets);
				else if (actions.left.triggered || actions.up.triggered)
					focusPrev(navTargets);

				if (actions.confirm.triggered)
					activateFocused();

				if (actions.cancel.triggered)
					cancel();
			}
		}
	}

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

	public static function activateFocused():Void
	{
		if (focused != null && focused.isUXEligible())
			focused.activate();
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

	public static function setFocused(button:FlxUXButton):Void
	{
		if (button == focused)
			return;

		if (focused != null)
			focused.setFocused(false);

		focused = button;

		if (focused != null)
			focused.setFocused(true);
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
		if (FlxG.touches == null || FlxG.touches.list == null)
			return false;

		for (touch in FlxG.touches.list)
		{
			if (touch == null) continue;

			if (touch.justPressed || touch.pressed)
				return true;
		}

		return false;
	}
}