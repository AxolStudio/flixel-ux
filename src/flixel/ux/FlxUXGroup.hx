package flixel.ux;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;

/**
 * UX Group: a lightweight container that is both:
 * - A render/update container you can `add(group)` to a state
 * - A registry for FlxUXCore navigation ordering
 *
 * Internally it contains two layers:
 * - `buttons`: FlxUXButton instances (the widgets)
 * - `sprites`: highlight sprites (around/on/next-to)
 *
 * The highlight layer is intended to be per-group (one moving highlighter), not per-button.
 */
class FlxUXGroup extends flixel.FlxBasic
{
	/** Whether this group participates in any UX behavior at all (separate from FlxBasic.active). */
	public var uxActive:Bool = true;

	/**
	 * Whether this group's widgets should be part of global NAV focus navigation.
	 * Default true.
	 *
	 * Use-cases:
	 * - Mouse-only HUD buttons during gameplay: set capturesNav = false
	 * - Pause menu / modal: capturesNav = true
	 */
	public var capturesNav:Bool = true;

	/**
	 * Optional callback invoked when NAV cancel is pressed while focus is within this group.
	 */
	public var onCancel:Void->Void;

	/** Optional assets/style defaults for buttons created/registered in this group. */
	public var assets:FlxUXAssets = null;

	/** Container x offset applied to all children. */
	public var x(default, set):Float = 0;
	/** Container y offset applied to all children. */
	public var y(default, set):Float = 0;

	/** Buttons layer. */
	public var buttons(default, null):FlxTypedGroup<FlxUXButton>;
	/** Sprite layer for focus/highlight visuals. */
	public var sprites(default, null):FlxTypedGroup<FlxSprite>;

	private var _ordered:Array<FlxUXButton> = [];
	private var _buttonBasePos:Map<FlxUXButton, FlxPoint> = new Map();
	private var _spriteBasePos:Map<FlxSprite, FlxPoint> = new Map();

	/** Per-group focus highlighter (optional). */
	public var focusHighlighter:FlxSprite = null;

	/** Creates a new, empty group. */
	public function new(?autoRegisterWithCore:Bool = true)
	{
		super();
		buttons = new FlxTypedGroup<FlxUXButton>();
		sprites = new FlxTypedGroup<FlxSprite>();

		if (autoRegisterWithCore)
			FlxUXCore.addGroup(this);
	}

	/**
	 * Clears callbacks and removes all button references.
	 *
	 * Note: this does not destroy buttons; it only clears the registry.
	 */
	override public function destroy():Void
	{
		super.destroy();
		if (buttons != null) buttons.destroy();
		if (sprites != null) sprites.destroy();
		buttons = null;
		sprites = null;
		if (focusHighlighter != null) focusHighlighter.destroy();
		focusHighlighter = null;
		onCancel = null;
		_ordered = [];
		_buttonBasePos = new Map();
		_spriteBasePos = new Map();
	}

	/**
	 * Adds an existing button to this group at an optional dense order.
	 *
	 * @return The same button that was provided (for chaining).
	 */
	public function add(button:FlxUXButton, ?order:Int):FlxUXButton
	{
		if (button != null)
		{
			button._uxGroup = this;
			button.applyAssets();
			buttons.add(button);
			_trackButton(button);
		}
		_insertDense(_ordered, button, order);
		return button;
	}

	/**
	 * Convenience helper that constructs a `FlxUXButton` and adds it to this group.
	 *
	 * @param label Button label text.
	 * @param x X position.
	 * @param y Y position.
	 * @param action Callback invoked on activation.
	 * @param order Optional dense order index (insert semantics).
	 */
	public function addButton(label:String, x:Float, y:Float, action:Void->Void, ?order:Int):FlxUXButton
	{
		var b = new FlxUXButton(x, y, label, action);
		b._uxGroup = this;
		b.applyAssets();
		return add(b, order);
	}

	/**
	 * Convenience helper for creating and adding multiple buttons.
	 *
	 * Buttons are created in the order provided and inserted densely starting at `order`
	 * (or appended if `order` is `null`).
	 *
	 * @param items Array of definitions in the form `{ label, x, y, action }`.
	 * @param order Optional dense order index to insert at.
	 * @return The created buttons in the same order as `items`.
	 */
	public function addButtons(items:Array<{ label:String, x:Float, y:Float, action:Void->Void }>, ?order:Int):Array<FlxUXButton>
	{
		var out:Array<FlxUXButton> = [];
		var insertAt = order;
		for (i in 0...items.length)
		{
			var it = items[i];
			if (it == null) continue;
			var b = new FlxUXButton(it.x, it.y, it.label, it.action);
			b._uxGroup = this;
			b.applyAssets();
			out.push(add(b, insertAt));
			if (insertAt != null) insertAt++;
		}
		return out;
	}

	/**
	 * Removes a button from this group.
	 *
	 * @return `true` if the button was present and removed.
	 */
	public function removeButton(button:FlxUXButton):Bool
	{
		var idx = _ordered.indexOf(button);
		if (idx >= 0)
		{
			_ordered.splice(idx, 1);
			if (buttons != null) buttons.remove(button, true);
			_untrackButton(button);
			return true;
		}
		return false;
	}

	/** Returns true if the given button is currently registered in this group. */
	public inline function containsButton(button:FlxUXButton):Bool
	{
		return _ordered.indexOf(button) >= 0;
	}

	/**
	 * Changes a button's dense ordering index within this group.
	 *
	 * Uses insert semantics: the button is removed then reinserted at the clamped index.
	 */
	public function setButtonOrder(button:FlxUXButton, newOrder:Int):Void
	{
		var idx = _ordered.indexOf(button);
		if (idx < 0) return;

		_ordered.splice(idx, 1);
		_insertDense(_ordered, button, newOrder);
	}

	/**
	 * Gets an ordered list of buttons that are eligible for NAV focus.
	 *
	 * Ineligible buttons (not `exists/alive/visible/active/enabled`) are skipped.
	 */
	public function getEligibleButtonsOrdered():Array<FlxUXButton>
	{
		if (!uxActive) return [];

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

	private function _trackButton(child:FlxUXButton):Void
	{
		if (child == null) return;
		_buttonBasePos.set(child, FlxPoint.get(child.x, child.y));
		child.x = x + _buttonBasePos.get(child).x;
		child.y = y + _buttonBasePos.get(child).y;
	}

	private function _untrackButton(child:FlxUXButton):Void
	{
		if (child == null) return;
		var p = _buttonBasePos.get(child);
		if (p != null) p.put();
		_buttonBasePos.remove(child);
	}

	private function set_x(v:Float):Float
	{
		if (x == v) return v;
		x = v;
		_applyContainerOffset();
		return v;
	}

	private function set_y(v:Float):Float
	{
		if (y == v) return v;
		y = v;
		_applyContainerOffset();
		return v;
	}

	private function _applyContainerOffset():Void
	{
		for (child => base in _buttonBasePos)
		{
			if (child == null || base == null) continue;
			child.x = x + base.x;
			child.y = y + base.y;
		}
		for (child => base in _spriteBasePos)
		{
			if (child == null || base == null) continue;
			child.x = x + base.x;
			child.y = y + base.y;
		}
	}

	/** Read-only width based on button bounds. */
	public function get_width():Float
	{
		var minX:Float = Math.POSITIVE_INFINITY;
		var maxX:Float = Math.NEGATIVE_INFINITY;
		for (b in _ordered)
		{
			if (b == null) continue;
			minX = Math.min(minX, b.x);
			maxX = Math.max(maxX, b.x + b.width);
		}
		if (minX == Math.POSITIVE_INFINITY) return 0;
		return maxX - minX;
	}

	/** Read-only height based on button bounds. */
	public function get_height():Float
	{
		var minY:Float = Math.POSITIVE_INFINITY;
		var maxY:Float = Math.NEGATIVE_INFINITY;
		for (b in _ordered)
		{
			if (b == null) continue;
			minY = Math.min(minY, b.y);
			maxY = Math.max(maxY, b.y + b.height);
		}
		if (minY == Math.POSITIVE_INFINITY) return 0;
		return maxY - minY;
	}

	/** Sets all button widths to match the widest button. */
	public function matchWidth():Void
	{
		var maxW:Float = 0;
		for (b in _ordered)
			if (b != null) maxW = Math.max(maxW, b.width);
		for (b in _ordered)
			if (b != null)
			{
				b.setGraphicSize(Std.int(maxW), Std.int(b.height));
				b.updateHitbox();
				b.centerLabel();
			}
	}

	/**
	 * Evenly distributes buttons horizontally across a span.
	 *
	 * @param spanWidth The total span to distribute across.
	 * @param startX Optional start x relative to current group x (default 0).
	 */
	public function spreadEvenlyH(spanWidth:Float, startX:Float = 0):Void
	{
		var list = getEligibleButtonsOrdered();
		// Use all registered buttons, not just eligible, for layout.
		list = _ordered.copy();
		list = list.filter(b -> b != null);
		if (list.length == 0) return;
		if (list.length == 1)
		{
			_setChildBaseX(list[0], startX);
			return;
		}

		var totalW:Float = 0;
		for (b in list) totalW += b.width;
		var gaps = list.length - 1;
		var gap = (spanWidth - totalW) / gaps;
		if (gap < 0) gap = 0;

		var cx = startX;
		for (b in list)
		{
			_setChildBaseX(b, cx);
			cx += b.width + gap;
		}
		_applyContainerOffset();
	}

	private function _setChildBaseX(child:FlxUXButton, baseX:Float):Void
	{
		if (child == null) return;
		var p = _buttonBasePos.get(child);
		if (p == null)
		{
			_trackButton(child);
			p = _buttonBasePos.get(child);
		}
		p.x = baseX;
	}

	override public function update(elapsed:Float):Void
	{
		if (!exists || !active) return;
		if (buttons != null) buttons.update(elapsed);
		if (sprites != null) sprites.update(elapsed);
		super.update(elapsed);
	}

	override public function draw():Void
	{
		if (!exists || !visible) return;
		if (sprites != null) sprites.draw();
		if (buttons != null) buttons.draw();
	}
}