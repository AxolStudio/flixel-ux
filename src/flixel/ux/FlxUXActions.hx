package flixel.ux;

import flixel.FlxG;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogState;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;

class FlxUXActions
{
	/** Action manager registered with `FlxG.inputs`. */
	public var manager:FlxActionManager;

	/**
	 * Digital navigation actions.
	 *
	 * These are intended for focus navigation in NAV mode.
	 */
	public var up:FlxActionDigital;
	public var down:FlxActionDigital;
	public var left:FlxActionDigital;
	public var right:FlxActionDigital;

	/**
	 * Digital activation actions.
	 */
	public var confirm:FlxActionDigital;
	public var confirmHeld:FlxActionDigital;
	public var confirmUp:FlxActionDigital;
	public var cancel:FlxActionDigital;

	/**
	 * Pointer-related actions.
	 *
	 * Used to detect mouse movement and pointer presses to switch into POINTER mode.
	 */
	public var moveMouse:FlxActionAnalog;
	public var pointerPress:FlxActionDigital;

	/** Whether confirm is currently held (computed from action triggers). */
	public var confirmDown(default, null):Bool = false;
	/** True for one frame when confirm is released (button-up edge). */
	public var confirmReleased(default, null):Bool = false;
	/** Whether pointer press is currently held (mouse/touch), if applicable. */
	public var pointerPressDown(default, null):Bool = false;

	/**
	 * Creates the action binding container and binds inputs immediately.
	 *
	 * You typically won't construct this directly; `FlxUXCore.init()` does it.
	 */
	public function new(
		?keyboardArrows:Bool = true,
		?keyboardWASD:Bool = true,
		?gamepadDpad:Bool = true,
		?gamepadLeftStick:Bool = true,
		?gamepadRightStick:Bool = false,
		?gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle = FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO)
	{
		rebind(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);
	}

	/**
	 * Rebuilds all action bindings.
	 *
	 * Destroys any previous manager and installs a new one into `FlxG.inputs`.
	 */
	public function rebind(
		?keyboardArrows:Bool = true,
		?keyboardWASD:Bool = true,
		?gamepadDpad:Bool = true,
		?gamepadLeftStick:Bool = true,
		?gamepadRightStick:Bool = false,
		?gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle = FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO):Void
	{
		if (manager != null)
		{
			FlxG.inputs.remove(manager);
			manager.destroy();
		}

		manager = FlxG.inputs.addInput(new FlxActionManager());
		manager.resetOnStateSwitch = ResetPolicy.NONE;

		up = new FlxActionDigital();
		down = new FlxActionDigital();
		left = new FlxActionDigital();
		right = new FlxActionDigital();
		confirm = new FlxActionDigital();
		confirmHeld = new FlxActionDigital();
		confirmUp = new FlxActionDigital();
		cancel = new FlxActionDigital();

		moveMouse = new FlxActionAnalog();
		pointerPress = new FlxActionDigital();

		manager.addActions([up, down, left, right, confirm, confirmHeld, confirmUp, cancel, moveMouse, pointerPress]);

		#if !FLX_NO_KEYBOARD
		if (keyboardArrows)
		{
			up.addKey(FlxKey.UP, FlxInputState.JUST_PRESSED);
			down.addKey(FlxKey.DOWN, FlxInputState.JUST_PRESSED);
			left.addKey(FlxKey.LEFT, FlxInputState.JUST_PRESSED);
			right.addKey(FlxKey.RIGHT, FlxInputState.JUST_PRESSED);
		}

		if (keyboardWASD)
		{
			up.addKey(FlxKey.W, FlxInputState.JUST_PRESSED);
			down.addKey(FlxKey.S, FlxInputState.JUST_PRESSED);
			left.addKey(FlxKey.A, FlxInputState.JUST_PRESSED);
			right.addKey(FlxKey.D, FlxInputState.JUST_PRESSED);
		}

		confirm.addKey(FlxKey.ENTER, FlxInputState.JUST_PRESSED);
		confirm.addKey(FlxKey.SPACE, FlxInputState.JUST_PRESSED);
		confirmHeld.addKey(FlxKey.ENTER, FlxInputState.PRESSED);
		confirmHeld.addKey(FlxKey.SPACE, FlxInputState.PRESSED);
		confirmUp.addKey(FlxKey.ENTER, FlxInputState.JUST_RELEASED);
		confirmUp.addKey(FlxKey.SPACE, FlxInputState.JUST_RELEASED);
		cancel.addKey(FlxKey.ESCAPE, FlxInputState.JUST_PRESSED);
		#end

		#if !FLX_NO_GAMEPAD
		if (gamepadDpad)
		{
			up.addGamepad(FlxGamepadInputID.DPAD_UP, FlxInputState.JUST_PRESSED);
			down.addGamepad(FlxGamepadInputID.DPAD_DOWN, FlxInputState.JUST_PRESSED);
			left.addGamepad(FlxGamepadInputID.DPAD_LEFT, FlxInputState.JUST_PRESSED);
			right.addGamepad(FlxGamepadInputID.DPAD_RIGHT, FlxInputState.JUST_PRESSED);
		}

		if (gamepadLeftStick)
		{
			up.addGamepad(FlxGamepadInputID.LEFT_STICK_DIGITAL_UP, FlxInputState.JUST_PRESSED);
			down.addGamepad(FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN, FlxInputState.JUST_PRESSED);
			left.addGamepad(FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT, FlxInputState.JUST_PRESSED);
			right.addGamepad(FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT, FlxInputState.JUST_PRESSED);
		}

		if (gamepadRightStick)
		{
			up.addGamepad(FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP, FlxInputState.JUST_PRESSED);
			down.addGamepad(FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN, FlxInputState.JUST_PRESSED);
			left.addGamepad(FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT, FlxInputState.JUST_PRESSED);
			right.addGamepad(FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT, FlxInputState.JUST_PRESSED);
		}

		switch (gamepadFaceStyle)
		{
			case FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO:
				confirm.addGamepad(FlxGamepadInputID.B, FlxInputState.JUST_PRESSED);
				confirmHeld.addGamepad(FlxGamepadInputID.B, FlxInputState.PRESSED);
				confirmUp.addGamepad(FlxGamepadInputID.B, FlxInputState.JUST_RELEASED);
				cancel.addGamepad(FlxGamepadInputID.A, FlxInputState.JUST_PRESSED);

			case FlxUXCore.FlxUXGamepadFaceStyle.PSX:
				confirm.addGamepad(FlxGamepadInputID.A, FlxInputState.JUST_PRESSED);
				confirmHeld.addGamepad(FlxGamepadInputID.A, FlxInputState.PRESSED);
				confirmUp.addGamepad(FlxGamepadInputID.A, FlxInputState.JUST_RELEASED);
				cancel.addGamepad(FlxGamepadInputID.B, FlxInputState.JUST_PRESSED);
		}
		#end

		#if !FLX_NO_MOUSE
		pointerPress.addMouse(FlxMouseButtonID.LEFT, FlxInputState.JUST_PRESSED);
		moveMouse.addMouseMotion(FlxAnalogState.MOVED);
		#end

		// Reset derived states after rebinding.
		confirmDown = false;
		confirmReleased = false;
		pointerPressDown = false;
	}

	/**
	 * Updates derived button state for "hold" and "release" behavior.
	 *
	 * Flixel's action system primarily exposes per-frame triggers (via `triggered` / `check()`).
	 * For UI interactions we also need "is held" and "released this frame" semantics.
	 */
	public function update():Void
	{
		// ActionManager will update actions as part of FlxG.inputs.
		// We just combine per-frame triggers into the semantics FlxUXCore wants.
		confirmDown = confirmHeld.triggered;
		confirmReleased = confirmUp.triggered;
		pointerPressDown = pointerPress.triggered;
	}
}