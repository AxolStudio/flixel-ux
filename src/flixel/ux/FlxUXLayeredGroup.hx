package flixel.ux;

import flixel.group.FlxGroup;

/**
 * A simple 3-layer container intended for UX widgets:
 * - underlays: draw below widgets (e.g. focus frame behind button)
 * - widgets: the actual buttons
 * - overlays: draw above widgets (e.g. glow, caret, etc.)
 */
class FlxUXLayeredGroup extends FlxGroup
{
	public var underlays(default, null):FlxGroup;
	public var widgets(default, null):FlxGroup;
	public var overlays(default, null):FlxGroup;

	public function new(maxSize:Int = 0)
	{
		super(maxSize);
		underlays = new FlxGroup();
		widgets = new FlxGroup();
		overlays = new FlxGroup();
		add(underlays);
		add(widgets);
		add(overlays);
	}
}
