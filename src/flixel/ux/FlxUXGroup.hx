package flixel.ux;

class FlxUXGroup
{
	/** Whether this group participates in any UX behavior at all. */
	public var active:Bool = true;

	/**
	 * Whether this group's widgets should be part of global NAV focus navigation.
	 * Default true.
	 *
	 * Use-cases:
	 * - Mouse-only HUD buttons during gameplay: set capturesNav = false
	 * - Pause menu / modal: capturesNav = true
	 */
	public var capturesNav:Bool = true;

	public var onCancel:Void->Void;

	private var _ordered:Array<FlxUXButton> = [];

	public function new() {}

	public function destroy():Void
	{
		onCancel = null;
		_ordered = [];
	}

	public function add(button:FlxUXButton, ?order:Int):FlxUXButton
	{
		_insertDense(_ordered, button, order);
		return button;
	}

	public function addButton(label:String, x:Float, y:Float, action:Void->Void, ?order:Int):FlxUXButton
	{
		var b = new FlxUXButton(x, y, label, action);
		return add(b, order);
	}

	public function removeButton(button:FlxUXButton):Bool
	{
		var idx = _ordered.indexOf(button);
		if (idx >= 0)
		{
			_ordered.splice(idx, 1);
			return true;
		}
		return false;
	}

	public inline function containsButton(button:FlxUXButton):Bool
	{
		return _ordered.indexOf(button) >= 0;
	}

	public function setButtonOrder(button:FlxUXButton, newOrder:Int):Void
	{
		var idx = _ordered.indexOf(button);
		if (idx < 0) return;

		_ordered.splice(idx, 1);
		_insertDense(_ordered, button, newOrder);
	}

	public function getEligibleButtonsOrdered():Array<FlxUXButton>
	{
		if (!active) return [];

		var out:Array<FlxUXButton> = [];
		for (b in _ordered)
		{
			if (b != null && b.isUXEligible())
				out.push(b);
		}
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
}