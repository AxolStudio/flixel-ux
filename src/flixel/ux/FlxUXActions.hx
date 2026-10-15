package flixel.ux;

import flixel.FlxG;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.FlxInput.FlxInputState;
#if !FLX_NO_MOUSE
import flixel.input.actions.FlxActionInputAnalog.FlxAnalogState;
import flixel.input.mouse.FlxMouseButton.FlxMouseButtonID;
#end
#if !FLX_NO_KEYBOARD
import flixel.input.keyboard.FlxKey;
#end
#if !FLX_NO_GAMEPAD
import flixel.input.gamepad.FlxGamepadInputID;
#end

class FlxUXActions
{
	/** Action manager registered with `FlxG.inputs`. */
	public var manager:FlxActionManager;

	/** Digital navigation actions (intended for NAV focus traversal). */
	public var up:FlxActionDigital;

	public var down:FlxActionDigital;
	public var left:FlxActionDigital;
	public var right:FlxActionDigital;
	public var tabNext:FlxActionDigital;
	public var tabPrevious:FlxActionDigital;
	public var first:FlxActionDigital;
	public var last:FlxActionDigital;
	public var pageUp:FlxActionDigital;
	public var pageDown:FlxActionDigital;
	public var paneNext:FlxActionDigital;
	public var panePrevious:FlxActionDigital;
	public var directionHeld:Array<FlxActionDigital>;

	/** Digital activation actions. */
	public var confirm:FlxActionDigital;

	public var accept:FlxActionDigital;
	public var acceptHeld:FlxActionDigital;
	public var acceptUp:FlxActionDigital;

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
	public var pointerPressHeld:FlxActionDigital;

	/** Whether confirm is currently held (computed from action triggers). */
	public var confirmDown(default, null):Bool = false;

	/** True for one frame when confirm is released (button-up edge). */
	public var confirmReleased(default, null):Bool = false;

	public var gamepadConfirmTriggered(default, null):Bool = false;

	/** Whether pointer press is currently held (mouse/touch), if applicable. */
	public var pointerPressDown(default, null):Bool = false;

	/** Default ctor values used by `rebind()` to rebuild identically later. */
	public var keyboardArrows:Bool;

	public var keyboardWASD:Bool;
	public var gamepadDpad:Bool;
	public var gamepadLeftStick:Bool;
	public var gamepadRightStick:Bool;
	public var gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle;

	/**
	 * Creates the action binding container and binds inputs immediately.
	 *
	 * You typically won't construct this directly; `FlxUXCore.init()` does it.
	 */
	public function new(?keyboardArrows:Bool = true, ?keyboardWASD:Bool = true, ?gamepadDpad:Bool = true, ?gamepadLeftStick:Bool = true,
			?gamepadRightStick:Bool = false, ?gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle = FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO)
	{
		this.keyboardArrows = keyboardArrows;
		this.keyboardWASD = keyboardWASD;
		this.gamepadDpad = gamepadDpad;
		this.gamepadLeftStick = gamepadLeftStick;
		this.gamepadRightStick = gamepadRightStick;
		this.gamepadFaceStyle = gamepadFaceStyle;
		rebind(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);
	}

	/** Destroys the action manager and unhooks it from `FlxG.inputs`. */
	public function destroy():Void
	{
		if (manager != null)
		{
			FlxG.inputs.remove(manager);
			manager.destroy();
			manager = null;
		}
	}

	/** Rebinds actions using the last ctor values. */
	public inline function rebindDefaults():Void
	{
		rebind(keyboardArrows, keyboardWASD, gamepadDpad, gamepadLeftStick, gamepadRightStick, gamepadFaceStyle);
	}

	/**
	 * Rebuilds all action bindings.
	 *
	 * Destroys any previous manager and installs a new one into `FlxG.inputs`.
	 */
	public function rebind(?keyboardArrows:Bool = true, ?keyboardWASD:Bool = true, ?gamepadDpad:Bool = true, ?gamepadLeftStick:Bool = true,
			?gamepadRightStick:Bool = false, ?gamepadFaceStyle:FlxUXCore.FlxUXGamepadFaceStyle = FlxUXCore.FlxUXGamepadFaceStyle.NINTENDO):Void
	{
		this.keyboardArrows = keyboardArrows;
		this.keyboardWASD = keyboardWASD;
		this.gamepadDpad = gamepadDpad;
		this.gamepadLeftStick = gamepadLeftStick;
		this.gamepadRightStick = gamepadRightStick;
		this.gamepadFaceStyle = gamepadFaceStyle;

		destroy();

		manager = FlxG.inputs.addInput(new FlxActionManager());

		up = new FlxActionDigital();
		down = new FlxActionDigital();
		left = new FlxActionDigital();
		right = new FlxActionDigital();
		tabNext = new FlxActionDigital();
		tabPrevious = new FlxActionDigital();
		first = new FlxActionDigital();
		last = new FlxActionDigital();
		pageUp = new FlxActionDigital();
		pageDown = new FlxActionDigital();
		paneNext = new FlxActionDigital();
		panePrevious = new FlxActionDigital();
		directionHeld = [
			new FlxActionDigital(),
			new FlxActionDigital(),
			new FlxActionDigital(),
			new FlxActionDigital()
		];
		confirm = new FlxActionDigital();
		accept = new FlxActionDigital();
		acceptHeld = new FlxActionDigital();
		acceptUp = new FlxActionDigital();
		confirmHeld = new FlxActionDigital();
		confirmUp = new FlxActionDigital();
		cancel = new FlxActionDigital();

		moveMouse = new FlxActionAnalog();
		pointerPress = new FlxActionDigital();
		pointerPressHeld = new FlxActionDigital();

		manager.addActions([
			pageUp,
			pageDown,
			accept,
			acceptHeld,
			acceptUp,
			tabNext,
			tabPrevious,
			first,
			last,
			paneNext,
			panePrevious,
			directionHeld[0],
			directionHeld[1],
			directionHeld[2],
			directionHeld[3],
			up,
			down,
			left,
			right,
			confirm,
			confirmHeld,
			confirmUp,
			cancel,
			moveMouse,
			pointerPress,
			pointerPressHeld
		]);

		#if !FLX_NO_KEYBOARD
		var names = ["up", "down", "left", "right"];
		var arrowKeys = ["UP", "DOWN", "LEFT", "RIGHT"];
		var wasdKeys = ["W", "S", "A", "D"];
		var directions = [up, down, left, right];
		for (index in 0...4)
		{
			var defaults:Array<String> = [];
			if (keyboardArrows)
				defaults.push(arrowKeys[index]);
			if (keyboardWASD)
				defaults.push(wasdKeys[index]);
			bindKeyboard(directions[index], names[index], defaults, JUST_PRESSED);
			bindKeyboard(directionHeld[index], names[index], defaults, PRESSED);
		}
		bindKeyboard(tabNext, "tabNext", ["TAB"], JUST_PRESSED);
		bindKeyboard(tabPrevious, "tabPrevious", ["SHIFT+TAB"], JUST_PRESSED);
		bindKeyboard(first, "first", ["HOME"], JUST_PRESSED);
		bindKeyboard(last, "last", ["END"], JUST_PRESSED);
		bindKeyboard(pageUp, "pageUp", ["PAGEUP"], JUST_PRESSED);
		bindKeyboard(pageDown, "pageDown", ["PAGEDOWN"], JUST_PRESSED);
		bindKeyboard(paneNext, "paneNext", ["F6"], JUST_PRESSED);
		bindKeyboard(panePrevious, "panePrevious", ["SHIFT+F6"], JUST_PRESSED);
		bindKeyboard(confirm, "confirm", ["ENTER", "SPACE"], JUST_PRESSED);
		bindKeyboard(accept, "accept", ["ENTER"], JUST_PRESSED);
		bindKeyboard(acceptHeld, "accept", ["ENTER"], PRESSED);
		bindKeyboard(acceptUp, "accept", ["ENTER"], JUST_RELEASED);
		bindKeyboard(confirmHeld, "confirm", ["ENTER", "SPACE"], PRESSED);
		bindKeyboard(confirmUp, "confirm", ["ENTER", "SPACE"], JUST_RELEASED);
		bindKeyboard(cancel, "cancel", ["ESCAPE"], JUST_PRESSED);
		#else
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
		#else
		#end

		#if !FLX_NO_GAMEPAD
		var heldIDs = [
			FlxGamepadInputID.DPAD_UP,
			FlxGamepadInputID.DPAD_DOWN,
			FlxGamepadInputID.DPAD_LEFT,
			FlxGamepadInputID.DPAD_RIGHT
		];
		var stickIDs = [
			  FlxGamepadInputID.LEFT_STICK_DIGITAL_UP, FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN,
			FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT, FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT
		];
		var rightIDs = [
			  FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP, FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN,
			FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT, FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT
		];
		for (index in 0...4)
		{
			if (gamepadDpad)
				directionHeld[index].addGamepad(heldIDs[index], PRESSED);
			if (gamepadLeftStick)
				directionHeld[index].addGamepad(stickIDs[index], PRESSED);
			if (gamepadRightStick)
				directionHeld[index].addGamepad(rightIDs[index], PRESSED);
		}
		#end

		#if !FLX_NO_MOUSE
		pointerPress.addMouse(FlxMouseButtonID.LEFT, FlxInputState.JUST_PRESSED);
		pointerPressHeld.addMouse(FlxMouseButtonID.LEFT, FlxInputState.PRESSED);
		moveMouse.addMouseMotion(FlxAnalogState.MOVED);
		#else
		#end

		confirmDown = false;
		confirmReleased = false;
		pointerPressDown = false;
	}

	private function bindKeyboard(action:FlxActionDigital, name:String, defaults:Array<String>, state:FlxInputState):Void
	{
		var bindings = FlxUXCore.keyboardBindings.exists(name) ? FlxUXCore.keyboardBindings.get(name) : defaults;
		if (bindings != null)
			for (binding in bindings)
				action.add(new FlxUXKeyboardInput(binding, state));
	}

	/** Updates derived state like "held" and "released" from Flixel's per-frame triggers. */
	public function update():Void
	{
		gamepadConfirmTriggered = false;
		for (input in confirm.inputs)
			if (input.device == flixel.input.actions.FlxActionInput.FlxInputDevice.GAMEPAD && input.check(confirm))
				gamepadConfirmTriggered = true;
		confirmDown = confirmHeld != null && confirmHeld.triggered || acceptHeld != null && acceptHeld.triggered;
		confirmReleased = confirmUp != null && confirmUp.triggered || acceptUp != null && acceptUp.triggered;
		pointerPressDown = (pointerPressHeld != null) ? pointerPressHeld.triggered : false;
	}
}
