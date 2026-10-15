package flixel.ux;

import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

class FlxUXShortcut
{
	public var key(default, null):FlxKey = FlxKey.NONE;
	public var ctrl(default, null):Bool = false;
	public var shift(default, null):Bool = false;
	public var alt(default, null):Bool = false;
	public var meta(default, null):Bool = false;
	public var valid(default, null):Bool = false;

	public function new(value:String)
	{
		if (value == null || StringTools.trim(value) == "")
			return;
		var parts = value.toUpperCase().split("+");
		for (index in 0...parts.length)
		{
			var part = StringTools.trim(parts[index]);
			if (index == parts.length - 1)
			{
				part = switch (part)
				{
					case "ESC": "ESCAPE";
					case "RETURN": "ENTER";
					case "PGUP": "PAGEUP";
					case "PGDN": "PAGEDOWN";
					default: part;
				};
				key = FlxKey.fromString(part);
				valid = key != FlxKey.NONE && key != FlxKey.ANY;
			}
			else
				switch (part)
				{
					case "CTRL", "CONTROL":
						ctrl = true;
					case "SHIFT":
						shift = true;
					case "ALT":
						alt = true;
					case "META", "CMD", "COMMAND":
						meta = true;
					default:
						return;
				}
		}
	}

	public function matchesModifiers(control:Bool, shifted:Bool, alternate:Bool, command:Bool):Bool
	{
		return valid && ctrl == control && shift == shifted && alt == alternate && meta == command;
	}

	public function check(state:FlxInputState):Bool
	{
		#if !FLX_NO_KEYBOARD
		if (!valid || FlxG.keys == null || !FlxG.keys.enabled)
			return false;
		return matchesModifiers(FlxG.keys.pressed.CONTROL, FlxG.keys.pressed.SHIFT, FlxG.keys.pressed.ALT, FlxG.keys.pressed.WINDOWS)
			&& FlxG.keys.checkStatus(key, state);
		#else
		return false;
		#end
	}
}
