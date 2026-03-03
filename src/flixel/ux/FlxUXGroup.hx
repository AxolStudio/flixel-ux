package flixel.ux;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxAxes;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.ux.FlxUXCore.FlxUXNavStyle;
import flixel.ux.FlxUXCore.FlxUXFocusMode;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;
import flixel.ux.FlxUXCore.FlxUXFocusMode;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;

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
class FlxUXGroup extends FlxGroup
{
	// ---------------------------------------------------------------------------------------------
	// Public configuration
	// ---------------------------------------------------------------------------------------------

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

	// Focus highlight settings (null => fall back to FlxUXCore, then built-in defaults)
	public var focusMode:Null<FlxUXFocusMode> = null;
	/** Default button skin graphic input for buttons in this group (null => FlxUXCore.buttonGraphic). */
	public var buttonGraphic:Null<FlxUXGraphicInput> = null;
	/** Optional animated skin FPS for buttons in this group (<= 0 => FlxUXCore.buttonSkinFps). */
	public var buttonSkinFps:Int = 0;
	/** Optional override for whether buttons in this group use the animated default sheet when no custom graphic is set. */
	public var buttonUseAnim:Null<Bool> = null;
	/** Optional per-state sequences when using the animated default sheet. */
	public var buttonAnimUp:Null<Array<Int>> = null;
	public var buttonAnimOver:Null<Array<Int>> = null;
	public var buttonAnimDown:Null<Array<Int>> = null;
	public var buttonAnimDisabled:Null<Array<Int>> = null;

	/** Clears group-level button skin overrides (buttons fall back to FlxUXCore defaults). */
	public function resetButtonSkin():Void
	{
		buttonGraphic = null;
		buttonSkinFps = 0;
		buttonUseAnim = null;
		buttonAnimUp = null;
		buttonAnimOver = null;
		buttonAnimDown = null;
		buttonAnimDisabled = null;
	}

	/** Forces the built-in static default sheet for this group (no per-state animation playback). */
	public function useDefaultButtonSkinStatic():Void
	{
		buttonGraphic = null;
		buttonUseAnim = false;
		buttonSkinFps = 0;
	}

	/** Forces the built-in animated default sheet for this group. */
	public function useDefaultButtonSkinAnim(fps:Int = 0):Void
	{
		buttonGraphic = null;
		buttonUseAnim = true;
		buttonSkinFps = (fps > 0) ? fps : 0;
	}

	/** Sets a custom skin for all buttons in this group. */
	public function setButtonSkin(graphic:FlxUXGraphicInput, fps:Int = 0):Void
	{
		buttonGraphic = graphic;
		buttonSkinFps = (fps > 0) ? fps : 0;
	}

	/** Overrides per-state animation sequences for buttons in this group. */
	public function setButtonAnimSequences(up:Array<Int>, over:Array<Int>, down:Array<Int>, disabled:Array<Int>):Void
	{
		buttonAnimUp = up;
		buttonAnimOver = over;
		buttonAnimDown = down;
		buttonAnimDisabled = disabled;
	}

	/**
	 * Re-applies theme defaults to this group and re-skins existing buttons.
	 *
	 * This intentionally keeps explicit per-group/per-button overrides intact.
	 */
	public function refreshTheme():Void
	{
		// Update highlight padding if this group hasn't customized it.
		// Heuristic: if still at the built-in default (12), follow theme.
		if (highlightPadX == 12 && FlxUXCore.theme != null)
			highlightPadX = FlxUXCore.theme.highlightPadX;
		if (highlightPadY == 12 && FlxUXCore.theme != null)
			highlightPadY = FlxUXCore.theme.highlightPadY;

		if (buttons != null)
		{
			for (b in buttons)
			{
				if (b == null) continue;
				b.uxGroup = this;
				b.applySkin();
			}
		}

		// Force highlight visuals to update using the new focus settings.
		updateFocusGraphics();
	}
	public var focusFrameGraphic:Null<FlxUXGraphicInput> = null;
	public var focusNextToGraphic:Null<FlxUXGraphicInput> = null;
	public var focusNextToMirrored:Null<Bool> = null;
	public var focusNextToGraphicRight:Null<FlxUXGraphicInput> = null;
	public var focusNextToFlipRight:Null<Bool> = null;
	public var focusNextToGap:Null<Float> = null;
	public var focusNextToOffsetY:Null<Float> = null;
	public var focusOverlayGraphic:Null<FlxUXGraphicInput> = null;
	public var focusOverlayOffsetX:Null<Float> = null;
	public var focusOverlayOffsetY:Null<Float> = null;

	/** Optional per-group navigation style override. If null, FlxUXCore.navStyle is used. */
	public var navStyle:Null<FlxUXNavStyle> = null;

	/** Padding (in pixels) added around the focused button when drawing the focus FRAME. */
	public var highlightPadX:Float = 12;
	/** Padding (in pixels) added around the focused button when drawing the focus FRAME. */
	public var highlightPadY:Float = 12;

	// ---------------------------------------------------------------------------------------------
	// Transform + bounds
	// ---------------------------------------------------------------------------------------------

	/**
	 * Group position (moves all tracked children).
	 *
	 * Note: FlxGroup doesn't normally have x/y; FlxUXGroup provides them as a convenience
	 * transform so you can tween/animate a menu/popup as a single unit.
	 */
	public var x(default, set):Float = 0;
	public var y(default, set):Float = 0;

	/** Left-most x among buttons (world-space). Read-only. */
	public var boundsX(get, never):Float;
	/** Top-most y among buttons (world-space). Read-only. */
	public var boundsY(get, never):Float;
	/** Width of the button bounds. Read-only. */
	public var width(get, never):Float;
	/** Height of the button bounds. Read-only. */
	public var height(get, never):Float;

	// ---------------------------------------------------------------------------------------------
	// Layers
	// ---------------------------------------------------------------------------------------------

	/** Buttons layer. */
	public var buttons(default, null):FlxTypedGroup<FlxUXButton>;
	/** Sprite layer for focus/highlight visuals. */
	public var sprites(default, null):FlxTypedGroup<FlxSprite>;

	// ---------------------------------------------------------------------------------------------
	// Internals
	// ---------------------------------------------------------------------------------------------

	private var orderedButtons:Array<FlxUXButton> = [];
	private var buttonBasePos:Map<FlxUXButton, FlxPoint> = new Map();
	private var spriteBasePos:Map<FlxSprite, FlxPoint> = new Map();
	private var lastHighlightKey:String = null;

	/** Per-group focus highlighter (optional). */
	public var focusHighlighter:FlxSprite = null;
	/** Optional focus sprite shown next to the focused button (left). */
	public var focusSideLeft:FlxSprite = null;
	/** Optional focus sprite shown next to the focused button (right). */
	public var focusSideRight:FlxSprite = null;
	/** Optional focus sprite shown on top of the focused button. */
	public var focusOverlay:FlxSprite = null;

	public function new(maxSize:Int = 0)
	{
		FlxUXCore.init();

		super(maxSize);
		FlxUXCore.addGroup(this);
		buttons = new FlxTypedGroup<FlxUXButton>();
		sprites = new FlxTypedGroup<FlxSprite>();
		add(buttons);
		add(sprites);

		onCancel = null;
		orderedButtons = [];
		buttonBasePos = new Map();
		spriteBasePos = new Map();

		focusHighlighter = new FlxSprite();
		focusHighlighter.moves = false;
		focusHighlighter.visible = false;
		focusSideLeft = new FlxSprite();
		focusSideLeft.moves = false;
		focusSideLeft.visible = false;
		focusSideRight = new FlxSprite();
		focusSideRight.moves = false;
		focusSideRight.visible = false;
		focusOverlay = new FlxSprite();
		focusOverlay.moves = false;
		focusOverlay.visible = false;

		sprites.add(focusHighlighter);
		sprites.add(focusSideLeft);
		sprites.add(focusSideRight);
		sprites.add(focusOverlay);

		trackSprite(focusHighlighter);
		trackSprite(focusSideLeft);
		trackSprite(focusSideRight);
		trackSprite(focusOverlay);
	}

	/**
	 * Adds an existing button to this group at an optional dense order.
	 *
	 * @return The same button that was provided (for chaining).
	 */
	/**
	 * Adds a UX button to this group (and registers it for navigation ordering).
	 *
	 * Named differently from FlxGroup.add() so users can still use normal group add/remove
	 * for their own extensions.
	 */
	public function addUXButton(button:FlxUXButton, ?order:Int):FlxUXButton
	{
		if (button != null)
		{
			button.uxGroup = this;
			button.applySkin();
			buttons.add(button);
			trackButton(button);
		}
		insertDense(orderedButtons, button, order);
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
	public function addButton(label:String, action:Void->Void, ?x:Float = 0, ?y:Float = 0, ?order:Int):FlxUXButton
	{
		var b = new FlxUXButton(x, y, label, action);
		b.uxGroup = this;
		return addUXButton(b, order);
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
			b.uxGroup = this;
			out.push(addUXButton(b, insertAt));
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
		var idx = orderedButtons.indexOf(button);
		if (idx >= 0)
		{
			orderedButtons.splice(idx, 1);
			if (buttons != null) buttons.remove(button, true);
			untrackButton(button);
			return true;
		}
		return false;
	}

	/** Returns true if the given button is currently registered in this group. */
	public inline function containsButton(button:FlxUXButton):Bool
	{
		return orderedButtons.indexOf(button) >= 0;
	}

	/**
	 * Changes a button's dense ordering index within this group.
	 *
	 * Uses insert semantics: the button is removed then reinserted at the clamped index.
	 */
	public function setButtonOrder(button:FlxUXButton, newOrder:Int):Void
	{
		var idx = orderedButtons.indexOf(button);
		if (idx < 0) return;

		orderedButtons.splice(idx, 1);
		insertDense(orderedButtons, button, newOrder);
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
		for (b in orderedButtons)
		{
			if (b != null && b.isUXEligible())
				out.push(b);
		}
		return out;
	}

	private static function insertDense<T>(arr:Array<T>, item:T, ?order:Int):Void
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

	private function trackButton(child:FlxUXButton):Void
	{
		if (child == null) return;
		buttonBasePos.set(child, FlxPoint.get(child.x, child.y));
		child.x = x + buttonBasePos.get(child).x;
		child.y = y + buttonBasePos.get(child).y;
	}

	private function untrackButton(child:FlxUXButton):Void
	{
		if (child == null) return;
		var p = buttonBasePos.get(child);
		if (p != null) p.put();
		buttonBasePos.remove(child);
	}

	private function set_x(v:Float):Float
	{
		if (x == v) return v;
		x = v;
		applyContainerOffset();
		return v;
	}

	private function set_y(v:Float):Float
	{
		if (y == v) return v;
		y = v;
		applyContainerOffset();
		return v;
	}

	private function applyContainerOffset():Void
	{
		for (child => base in buttonBasePos)
		{
			if (child == null || base == null) continue;
			child.x = x + base.x;
			child.y = y + base.y;
		}
		for (child => base in spriteBasePos)
		{
			if (child == null || base == null) continue;
			child.x = x + base.x;
			child.y = y + base.y;
		}
	}

	/** Left-most x among buttons (world-space). */
	public function get_boundsX():Float
	{
		var minX:Float = Math.POSITIVE_INFINITY;
			for (b in orderedButtons)
		{
			if (b == null) continue;
			minX = Math.min(minX, b.x);
		}
		return (minX == Math.POSITIVE_INFINITY) ? 0 : minX;
	}

	/** Top-most y among buttons (world-space). */
	public function get_boundsY():Float
	{
		var minY:Float = Math.POSITIVE_INFINITY;
			for (b in orderedButtons)
		{
			if (b == null) continue;
			minY = Math.min(minY, b.y);
		}
		return (minY == Math.POSITIVE_INFINITY) ? 0 : minY;
	}

	/** Read-only width based on button bounds. */
	public function get_width():Float
	{
		var minX:Float = Math.POSITIVE_INFINITY;
		var maxX:Float = Math.NEGATIVE_INFINITY;
			for (b in orderedButtons)
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
			for (b in orderedButtons)
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
			for (b in orderedButtons)
			if (b != null) maxW = Math.max(maxW, b.width);
			for (b in orderedButtons)
			if (b != null)
			{
				b.resize(Std.int(maxW), Std.int(b.height));
			}
	}

	/** Sets all button heights to match the tallest button. */
	public function matchHeight():Void
	{
		var maxH:Float = 0;
			for (b in orderedButtons)
			if (b != null) maxH = Math.max(maxH, b.height);
			for (b in orderedButtons)
			if (b != null)
			{
				b.resize(Std.int(b.width), Std.int(maxH));
			}
	}

	/** Sets all button widths + heights to match the largest button. */
	public inline function matchSize():Void
	{
		matchWidth();
		matchHeight();
	}

	/** Centers this group on the screen based on its current button bounds. */
	public function alignCenter():Void
	{
		var gx = boundsX;
		var gy = boundsY;
		var w = width;
		var h = height;
		var targetX = (flixel.FlxG.width - w) * 0.5;
		var targetY = (flixel.FlxG.height - h) * 0.5;
		this.x += targetX - gx;
		this.y += targetY - gy;
		if (FlxUXCore.snapUiToPixels)
		{
			this.x = Std.int(this.x);
			this.y = Std.int(this.y);
		}
	}

	/**
	 * Layout buttons vertically.
	 *
	 * This is the preferred name for vertical stacking.
	 *
	 * @param gap Space between buttons.
	 */
	public function stack(gap:Float):Void
	{
		var yCursor:Float = 0;
			for (b in orderedButtons)
		{
			if (b == null) continue;
			_setChildBasePos(b, 0, yCursor);
			b.x = x + 0;
			b.y = y + yCursor;
			if (FlxUXCore.snapUiToPixels)
			{
				b.x = Std.int(b.x);
				b.y = Std.int(b.y);
			}
			yCursor += b.height + gap;
		}
	}

	/**
	 * Backward compatible alias for `stack()`.
	 */
	public inline function stackVertical(gap:Float):Void
	{
		stack(gap);
	}

	/**
	 * Layout buttons horizontally.
	 *
	 * @param gap Space between buttons.
	 */
	public function spread(gap:Float):Void
	{
		var xCursor:Float = 0;
		for (b in orderedButtons)
		{
			if (b == null) continue;
			_setChildBasePos(b, xCursor, 0);
			b.x = x + xCursor;
			b.y = y + 0;
			if (FlxUXCore.snapUiToPixels)
			{
				b.x = Std.int(b.x);
				b.y = Std.int(b.y);
			}
			xCursor += b.width + gap;
		}
	}

	/**
	 * Layout buttons into a grid.
	 *
	 * Buttons are placed in order, filling rows left-to-right.
	 *
	 * @param columns Number of columns. Must be >= 1.
	 * @param gapX Horizontal gap between cells.
	 * @param gapY Vertical gap between cells.
	 * @param lastRowAlign Alignment for the final row when it is not full.
	 */
	public function grid(columns:Int, gapX:Float, gapY:Float, lastRowAlign:flixel.ux.FlxUXCore.FlxUXGridLastRowAlign = LEFT):Void
	{
		if (columns < 1) columns = 1;
		var cellW:Float = 0;
		var cellH:Float = 0;
		for (b in orderedButtons)
		{
			if (b == null) continue;
			cellW = Math.max(cellW, b.width);
			cellH = Math.max(cellH, b.height);
		}

		// Count buttons (orderedButtons can contain nulls).
		var count:Int = 0;
		for (b in orderedButtons)
			if (b != null) count++;
		if (count <= 0) return;

		var rows:Int = Std.int(Math.ceil(count / columns));
		var fullRows:Int = Std.int(count / columns);
		var lastRowCount:Int = count - fullRows * columns;
		if (lastRowCount <= 0) lastRowCount = columns;

		var lastRowOffsetX:Float = 0;
		if (lastRowCount < columns)
		{
			var rowW:Float = lastRowCount * cellW + (lastRowCount - 1) * gapX;
			var fullW:Float = columns * cellW + (columns - 1) * gapX;
			switch (lastRowAlign)
			{
				case CENTER: lastRowOffsetX = (fullW - rowW) * 0.5;
				case RIGHT: lastRowOffsetX = (fullW - rowW);
				case LEFT: lastRowOffsetX = 0;
			}
		}

		var i:Int = 0;
		var logicalIndex:Int = 0;
		for (b in orderedButtons)
		{
			if (b == null) continue;
			var col:Int = logicalIndex % columns;
			var row:Int = Std.int(logicalIndex / columns);
			var bx:Float = col * (cellW + gapX);
			var by:Float = row * (cellH + gapY);
			if (row == rows - 1 && lastRowCount < columns)
				bx += lastRowOffsetX;
			_setChildBasePos(b, bx, by);
			b.x = x + bx;
			b.y = y + by;
			if (FlxUXCore.snapUiToPixels)
			{
				b.x = Std.int(b.x);
				b.y = Std.int(b.y);
			}
			logicalIndex++;
			i++;
		}
	}

	private function _setChildBaseX(child:FlxUXButton, baseX:Float):Void
	{
		if (child == null) return;
		var p = buttonBasePos.get(child);
		if (p == null)
		{
			trackButton(child);
			p = buttonBasePos.get(child);
		}
		p.x = baseX;
	}

	private function _setChildBaseY(child:FlxUXButton, baseY:Float):Void
	{
		if (child == null) return;
		var p = buttonBasePos.get(child);
		if (p == null)
		{
			trackButton(child);
			p = buttonBasePos.get(child);
		}
		p.y = baseY;
	}

	private function _setChildBasePos(child:FlxUXButton, baseX:Float, baseY:Float):Void
	{
		if (child == null) return;
		var p = buttonBasePos.get(child);
		if (p == null)
		{
			trackButton(child);
			p = buttonBasePos.get(child);
		}
		p.x = baseX;
		p.y = baseY;
	}

	private function trackSprite(child:FlxSprite):Void
	{
		if (child == null) return;
		if (!spriteBasePos.exists(child))
			spriteBasePos.set(child, FlxPoint.get(child.x - x, child.y - y));
	}

	override public function update(elapsed:Float):Void
	{
		if (!exists || !active) return;
		// Keep focus highlight animation running even if we reposition it manually.
		if (focusHighlighter != null) focusHighlighter.update(elapsed);
		// Keep highlighter in sync even if focus changed without a direct callback.
		updateFocusGraphics();
		super.update(elapsed);
	}

	/**
	 * Called by FlxUXCore when focus changes, and also polled during update as a safety net.
	 */
	public function updateFocusGraphics():Void
	{
		if (focusHighlighter == null) return;

		// Only show focus highlight in NAV mode (keyboard/gamepad).
		// In POINTER mode (mouse/touch), rely on hover/pressed visuals.
		if (FlxUXCore.mode != flixel.ux.FlxUXCore.FlxUXInputMode.NAV)
		{
			focusHighlighter.visible = false;
			if (focusSideLeft != null) focusSideLeft.visible = false;
			if (focusSideRight != null) focusSideRight.visible = false;
			if (focusOverlay != null) focusOverlay.visible = false;
				lastHighlightKey = null;
			return;
		}

		var focused = FlxUXCore.focused;
		if (focused == null || focused._getUXGroup() != this)
		{
			focusHighlighter.visible = false;
			if (focusSideLeft != null) focusSideLeft.visible = false;
			if (focusSideRight != null) focusSideRight.visible = false;
			if (focusOverlay != null) focusOverlay.visible = false;
				lastHighlightKey = null;
			return;
		}

		var mode:FlxUXFocusMode = (focusMode != null) ? focusMode : FlxUXCore.focusMode;
		var frameInput:FlxUXGraphicInput = (focusFrameGraphic != null) ? focusFrameGraphic : FlxUXCore.focusFrameGraphic;
		var nextToInput:FlxUXGraphicInput = (focusNextToGraphic != null) ? focusNextToGraphic : FlxUXCore.focusNextToGraphic;
		var nextToMirrored:Bool = (focusNextToMirrored != null) ? focusNextToMirrored : FlxUXCore.focusNextToMirrored;
		var nextToRightInput:FlxUXGraphicInput = (focusNextToGraphicRight != null) ? focusNextToGraphicRight : FlxUXCore.focusNextToGraphicRight;
		var nextToFlipRight:Bool = (focusNextToFlipRight != null) ? focusNextToFlipRight : FlxUXCore.focusNextToFlipRight;
		var nextToGap:Float = (focusNextToGap != null) ? focusNextToGap : FlxUXCore.focusNextToGap;
		var nextToOffY:Float = (focusNextToOffsetY != null) ? focusNextToOffsetY : FlxUXCore.focusNextToOffsetY;
		var overlayInput:FlxUXGraphicInput = (focusOverlayGraphic != null) ? focusOverlayGraphic : FlxUXCore.focusOverlayGraphic;
		var overlayOffX:Float = (focusOverlayOffsetX != null) ? focusOverlayOffsetX : FlxUXCore.focusOverlayOffsetX;
		var overlayOffY:Float = (focusOverlayOffsetY != null) ? focusOverlayOffsetY : FlxUXCore.focusOverlayOffsetY;

		// "Buffer" semantics: pad is extra space OUTSIDE the button.
		// Example pad=12 => highlight is 24px larger in both directions and positioned -12,-12.
		var themePadX:Float = (FlxUXCore.theme != null) ? FlxUXCore.theme.highlightPadX : 12;
		var themePadY:Float = (FlxUXCore.theme != null) ? FlxUXCore.theme.highlightPadY : 12;
		var padX = (highlightPadX != 12) ? highlightPadX : themePadX;
		var padY = (highlightPadY != 12) ? highlightPadY : themePadY;
		var tx = focused.x - padX;
		var ty = focused.y - padY;
		var tw = Std.int(Math.ceil(focused.width + padX * 2));
		var th = Std.int(Math.ceil(focused.height + padY * 2));
		if (tw < 1) tw = 1;
		if (th < 1) th = 1;

		// Apply focus visuals based on style.
		switch (mode)
		{
			case FRAME:
				focusHighlighter.visible = (frameInput != null);
				if (focusHighlighter.visible)
				applyFocusFrameGraphic(frameInput, tw, th);
				if (focusSideLeft != null) focusSideLeft.visible = false;
				if (focusSideRight != null) focusSideRight.visible = false;
				if (focusOverlay != null) focusOverlay.visible = false;

			case NEXT_TO:
				focusHighlighter.visible = false;
				if (focusOverlay != null) focusOverlay.visible = false;
				applyFocusNextTo(nextToInput, nextToRightInput, nextToMirrored, nextToFlipRight, nextToGap, nextToOffY, focused);

			case OVERLAY:
				focusHighlighter.visible = false;
				if (focusSideLeft != null) focusSideLeft.visible = false;
				if (focusSideRight != null) focusSideRight.visible = false;
				applyFocusOverlay(overlayInput, overlayOffX, overlayOffY, focused);

			default:
				// HOVER_ONLY / DIM_UNFOCUSED: no group-level sprite.
				focusHighlighter.visible = false;
				if (focusSideLeft != null) focusSideLeft.visible = false;
				if (focusSideRight != null) focusSideRight.visible = false;
				if (focusOverlay != null) focusOverlay.visible = false;
				lastHighlightKey = null;
			return;
		}

		if (focusHighlighter.visible)
			focusHighlighter.scrollFactor.set(focused.scrollFactor.x, focused.scrollFactor.y);

		// Position (for FRAME highlighter only)
		if (focusHighlighter.visible)
		{
			focusHighlighter.x = tx;
			focusHighlighter.y = ty;
			var bpH = spriteBasePos.get(focusHighlighter);
			if (bpH != null)
			{
				bpH.x = tx - x;
				bpH.y = ty - y;
			}
		}

		// Side/overlay sprites base positions are updated inside their helpers.
	}


	private function applyFocusFrameGraphic(input:FlxUXGraphicInput, tw:Int, th:Int):Void
	{
		if (input == null || focusHighlighter == null)
			return;

		// Avoid reloading/rebuilding the same highlight graphic every frame (would reset animation).
		// This key is about *rendered output*, not the focused button.
		inline function setKey(k:String):Bool
		{
				if (lastHighlightKey == k)
				return false;
				lastHighlightKey = k;
			return true;
		}

		// Support 9-slice object
		if (Std.isOfType(input, flixel.ux.FlxUX9Slice))
		{
			var ns:flixel.ux.FlxUX9Slice = cast input;
			// If the source is a spritesheet (frameHeight>0) allow animation by stacking
			// rendered frames vertically into a single tw x (th*frames) bitmap.
			var frames = 1;
			if (ns.frameWidth > 0 && ns.frameHeight > 0)
			{
				var bd = FlxUX9Slice.resolveBitmapData(ns.source);
				if (bd != null)
				{
					var cols = Std.int(bd.width / ns.frameWidth);
					if (cols < 1) cols = 1;
					var rows = Std.int(bd.height / ns.frameHeight);
					if (rows < 1) rows = 1;
					frames = cols * rows;
				}
			}

			if (frames <= 1)
			{
				var k = 'ux9frame|' + Std.string(ns.source) + '|' + ns.frameWidth + 'x' + ns.frameHeight + '|to' + tw + 'x' + th;
				if (!setKey(k))
					return;
				var gfx = FlxUX9Slice.get(ns, tw, th, 0);
				if (gfx != null)
					focusHighlighter.loadGraphic(gfx);
			}
			else
			{
				var key = 'ux9frameanim|' + Std.string(ns.source) + '|' + ns.frameWidth + 'x' + ns.frameHeight + '|to' + tw + 'x' + th + '|n' + frames;
				if (!setKey(key))
					return;
				var out = new BitmapData(tw, th * frames, true, 0x00000000);
				for (i in 0...frames)
				{
					var g = FlxUX9Slice.get(ns, tw, th, i);
					if (g == null || g.bitmap == null) continue;
					out.copyPixels(g.bitmap, new Rectangle(0, 0, tw, th), new Point(0, i * th), null, null, true);
				}
				var sheet = FlxGraphic.fromBitmapData(out, false, key);
				focusHighlighter.loadGraphic(sheet, true, tw, th);
				var idx:Array<Int> = [];
				for (i in 0...frames) idx.push(i);
				focusHighlighter.animation.add("idle", idx, FlxUXCore.focusFrameFps, true);
				focusHighlighter.animation.play("idle", true);
			}
			focusHighlighter.antialiasing = false;
			return;
		}

		// Anything else: treat as a standard Flixel graphic input.
		var g = flixel.ux.FlxUX9Slice.toGraphic(input);
		if (g != null)
		{
			var k = 'uxframe|' + Std.string(input) + '|to' + tw + 'x' + th;
			if (!setKey(k))
				return;
			focusHighlighter.loadGraphic(g);
		}
		focusHighlighter.antialiasing = false;
	}

	private function applyFocusNextTo(leftInput:FlxUXGraphicInput, rightInput:FlxUXGraphicInput, mirrored:Bool, flipRight:Bool, gap:Float, offY:Float, focused:FlxUXButton):Void
	{
		if (focusSideLeft == null || focusSideRight == null) return;
		if (focused == null || leftInput == null)
		{
			focusSideLeft.visible = false;
			focusSideRight.visible = false;
			return;
		}

		// Left
		focusSideLeft.visible = true;
		var gL = flixel.ux.FlxUX9Slice.toGraphic(leftInput);
		if (gL != null) focusSideLeft.loadGraphic(gL);
		focusSideLeft.antialiasing = false;
		focusSideLeft.x = focused.x - focusSideLeft.width - gap;
		focusSideLeft.y = focused.y + (focused.height - focusSideLeft.height) * 0.5 + offY;

		// Right
		if (mirrored)
		{
			focusSideRight.visible = true;
			var rIn = (rightInput != null) ? rightInput : leftInput;
			var gR = flixel.ux.FlxUX9Slice.toGraphic(rIn);
			if (gR != null) focusSideRight.loadGraphic(gR);
			focusSideRight.antialiasing = false;
			focusSideRight.x = focused.x + focused.width + gap;
			focusSideRight.y = focused.y + (focused.height - focusSideRight.height) * 0.5 + offY;
			focusSideRight.flipX = flipRight;
		}
		else
		{
			focusSideRight.visible = false;
		}
	}

	private function applyFocusOverlay(input:FlxUXGraphicInput, offX:Float, offY:Float, focused:FlxUXButton):Void
	{
		if (focusOverlay == null) return;
		if (focused == null || input == null)
		{
			focusOverlay.visible = false;
			return;
		}

		focusOverlay.visible = true;
		var g = flixel.ux.FlxUX9Slice.toGraphic(input);
		if (g != null) focusOverlay.loadGraphic(g);
		focusOverlay.antialiasing = false;
		focusOverlay.x = focused.x + focused.width + offX;
		focusOverlay.y = focused.y + focused.height + offY;
	}


}