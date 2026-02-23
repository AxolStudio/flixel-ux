package flixel.ux;

import flixel.ui.FlxButton;

class FlxUXButton extends FlxButton
{
	public var action:Void->Void;
	public var uxFocused(default, null):Bool = false;

	public function new(x:Float = 0, y:Float = 0, label:String = "", ?action:Void->Void)
	{
		super(x, y);
		this.action = action;

		this.label.text = label;

		onUp.callback = () -> activate();
	}

	public function setFocused(focused:Bool):Void
	{
		uxFocused = focused;

		// placeholder focus indicator for testing
		alpha = uxFocused ? 1.0 : 0.9;
	}

	public inline function isUXEligible():Bool
	{
		return exists && alive && visible && active && enabled;
	}

	public function activate():Void
	{
		if (!isUXEligible())
			return;

		if (action != null)
			action();
	}
}