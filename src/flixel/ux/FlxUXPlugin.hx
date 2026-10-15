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
		flixel.FlxG.signals.postUpdate.add(postUpdate);
	}

	override public function update(elapsed:Float):Void
	{
		if (!exists || !active)
			return;
		super.update(elapsed);
	}

	private function postUpdate():Void
	{
		if (exists && active)
			FlxUXCore.internalUpdate(flixel.FlxG.elapsed);
		FlxUXCore.clearNavButtonsUpdatedThisFrame();
	}

	override public function destroy():Void
	{
		flixel.FlxG.signals.postUpdate.remove(postUpdate);
		super.destroy();
	}
}
