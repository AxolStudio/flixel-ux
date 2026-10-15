package flixel.ux;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalKeyboard;

class FlxUXKeyboardInput extends FlxActionInputDigitalKeyboard
{
	var shortcut:FlxUXShortcut;

	public function new(binding:String, state:FlxInputState)
	{
		shortcut = new FlxUXShortcut(binding);
		super(shortcut.key, state);
	}

	override public function check(action:FlxAction):Bool
	{
		return FlxUXCore.isKeyboardEnabled() && shortcut.check(trigger);
	}
}