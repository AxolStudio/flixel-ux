package flixel.ux;

import flixel.FlxBasic;

/**
 * Global plugin that updates FlxUXCore every frame.
 *
 * Installed automatically by FlxUXCore.init() via FlxG.plugins.addIfUniqueType().
 */
class FlxUXPlugin extends FlxBasic
{
	public function new()
	{
		super();
		visible = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		FlxUXCore.internalUpdate(elapsed);
	}
}