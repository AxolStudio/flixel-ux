package flixel.ux;

import flixel.FlxG;
import flixel.input.actions.FlxActionAnalog;
import flixel.input.actions.FlxActionDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionInputDigital.FlxInputState;
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogState;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.mouse.FlxMouseButtonID;

class FlxUXActions
{
	public var manager:FlxActionManager;

	public var up:FlxActionDigital;
	public var down:FlxActionDigital;
	public var left:FlxActionDigital;
	public var right:FlxActionDigital;

	public var confirm:FlxActionDigital;
	public var cancel:FlxActionDigital;

	public var moveMouse:FlxActionAnalog;
	public var pointerPress:FlxActionDigital;

	public function new(
		?keyboardArrows:Bool = true,
		?keyboardWASD:Bool = true,
		?gamepadDpad:Bool = true,
		?gamepadLeftStick:Bool = true,
		?gamepadRightStick:Bool = false,
		?gamepadFaceStyle:FlxUXGamepadFaceStyle = FlxUXGamepadFaceStyle.NINTENDO)
	{
		rebind(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);
	}

	public function rebind(
		?keyboardArrows:Bool = true,
		?keyboardWASD:Bool = true,
		?gamepadDpad:Bool = true,
		?gamepadLeftStick:Bool = true,
		?gamepadRightStick:Bool = false,
		?gamepadFaceStyle:FlxUXGamepadFaceStyle = FlxUXGamepadFaceStyle.NINTENDO):Void
	{
		if (manager != null)
		{
			FlxG.inputs.removeInput(manager);
			manager.destroy();
		}

		manager = FlxG.inputs.addInput(new FlxActionManager());
		manager.resetOnStateSwitch = ResetPolicy.NONE;

		up = new FlxActionDigital();
		down = new FlxActionDigital();
		left = new FlxActionDigital();
		right = new FlxActionDigital();
		confirm = new FlxActionDigital();
		cancel = new FlxActionDigital();

		moveMouse = new FlxActionAnalog();
		pointerPress = new FlxActionDigital();

		manager.addActions([up, down, left, right, confirm, cancel, moveMouse, pointerPress]);

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
		cancel.addKey(FlxKey.ESCAPE, FlxInputState.JUST_PRESSED);

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
			// Right-face confirm, bottom-face cancel
			case FlxUXGamepadFaceStyle.NINTENDO:
				confirm.addGamepad(FlxGamepadInputID.B, FlxInputState.JUST_PRESSED);
				cancel.addGamepad(FlxGamepadInputID.A, FlxInputState.JUST_PRESSED);

			// Bottom-face confirm, right-face cancel
			case FlxUXGamepadFaceStyle.PSX:
				confirm.addGamepad(FlxGamepadInputID.A, FlxInputState.JUST_PRESSED);
				cancel.addGamepad(FlxGamepadInputID.B, FlxInputState.JUST_PRESSED);
		}

		pointerPress.addMouse(FlxMouseButtonID.LEFT, FlxInputState.JUST_PRESSED);
		moveMouse.addMouseMotion(FlxAnalogState.MOVED, FlxInputState.EITHER);
	}
}