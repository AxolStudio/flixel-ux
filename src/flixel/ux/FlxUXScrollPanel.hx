package flixel.ux;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;

@:access(flixel.group.FlxTypedGroup)
class FlxUXScrollPanel extends FlxGroup
{
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;
	public var verticalEnabled:Bool = true;
	public var horizontalEnabled:Bool = false;
	public var autoHideScrollbars:Bool = true;
	public var wheelEnabled:Bool = true;
	public var keyboardScrolling:Bool = true;
	public var wheelStep:Float = 32;
	public var focusPadding:Float = 8;
	public var backgroundColor:Null<FlxColor> = null;
	public var backgroundGraphic:Null<FlxUXGraphicInput> = null;
	public var borderColor:Null<FlxColor> = null;
	public var borderGraphic:Null<FlxUXGraphicInput> = null;
	public var borderThickness:Null<Float> = null;
	public var onScroll:Void->Void;
	public var content(default, null):FlxGroup;
	public var background(default, null):FlxSprite;
	public var border(default, null):FlxSprite;
	public var verticalBar(default, null):FlxUXScrollBar;
	public var horizontalBar(default, null):FlxUXScrollBar;
	public var viewportCamera(default, null):FlxCamera;
	public var viewportWidth(default, null):Float;
	public var viewportHeight(default, null):Float;
	public var scrollX(get, set):Float;
	public var scrollY(get, set):Float;
	public var contentBounds(default, null):FlxRect = new FlxRect();
	public var ownerState(default, null):flixel.FlxState;

	private var explicitBounds:Bool = false;
	private var lastAppliedTheme:FlxUXTheme;
	private var lastBackgroundGraphic:Null<FlxUXGraphicInput>;
	private var lastBorderGraphic:Null<FlxUXGraphicInput>;
	private var lastBackgroundWidth:Int = -1;
	private var lastBackgroundHeight:Int = -1;
	private var lastBorderWidth:Int = -1;
	private var lastBorderHeight:Int = -1;
	private var lastBorderFrameThickness:Float = -1;
	private var pointer:FlxPoint = FlxPoint.get();
	private var previousCameras:Map<FlxBasic, Array<FlxCamera>> = new Map();
	private var previousScroll:Map<FlxObject, FlxPoint> = new Map();

	public function new(x:Float = 0, y:Float = 0, width:Float = 320, height:Float = 240)
	{
		FlxUXCore.init();
		super();
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		ownerState = FlxUXCore.currentState();
		content = new FlxGroup();
		viewportCamera = new FlxCamera(Std.int(x), Std.int(y), Std.int(Math.max(1, width)), Std.int(Math.max(1, height)), 1);
		FlxG.cameras.add(viewportCamera, false);
		FlxG.signals.preDraw.add(syncCameraVisibility);
		background = new FlxSprite();
		background.scrollFactor.set(1, 1);
		background.cameras = [viewportCamera];
		add(background);
		verticalBar = new FlxUXScrollBar(x + width - 20, y, height, true);
		horizontalBar = new FlxUXScrollBar(x, y + height - 20, width, false);
		verticalBar.onChange = value -> applyScroll();
		horizontalBar.onChange = value -> applyScroll();
		add(content);
		add(verticalBar);
		add(horizontalBar);
		border = new FlxSprite();
		add(border);
		FlxUXCore.addScrollPanel(this);
		applyTheme(FlxUXCore.theme);
		refresh();
	}

	public function applyTheme(theme:FlxUXTheme):Void
	{
		if (theme == null)
			return;
		if (lastAppliedTheme == null || focusPadding == lastAppliedTheme.scrollPanelFocusPadding)
			focusPadding = theme.scrollPanelFocusPadding;
		if (lastAppliedTheme == null || borderThickness == lastAppliedTheme.scrollPanelBorderThickness)
			borderThickness = theme.scrollPanelBorderThickness;
		lastAppliedTheme = theme;
		verticalBar.applyTheme(theme);
		horizontalBar.applyTheme(theme);
		refresh();
	}

	public function refreshTheme():Void
	{
		applyTheme(FlxUXCore.theme);
	}

	public function addContent<T:FlxBasic>(item:T):T
	{
		content.add(item);
		attach(item);
		refresh();
		return item;
	}

	public function removeContent<T:FlxBasic>(item:T):T
	{
		content.remove(item, true);
		detach(item);
		refresh();
		return item;
	}

	public function setContentSize(width:Float, height:Float, originX:Float = 0, originY:Float = 0):Void
	{
		explicitBounds = true;
		contentBounds.set(originX, originY, Math.max(0, width), Math.max(0, height));
		refresh();
	}

	public function useAutomaticContentBounds():Void
	{
		explicitBounds = false;
		refresh();
	}

	private function attach(item:FlxBasic):Void
	{
		if (item == null)
			return;
		if (!previousCameras.exists(item))
			previousCameras.set(item, item.cameras);
		item.cameras = [viewportCamera];
		if (Std.isOfType(item, FlxObject))
		{
			var object:FlxObject = cast item;
			if (!previousScroll.exists(object))
				previousScroll.set(object, FlxPoint.get(object.scrollFactor.x, object.scrollFactor.y));
			object.scrollFactor.set(1, 1);
		}
		if (Std.isOfType(item, FlxUXGroup))
			(cast item : FlxUXGroup).scrollPanel = this;
		if (Std.isOfType(item, FlxUXButton))
			(cast item : FlxUXButton).scrollPanel = this;
		var group = FlxTypedGroup.resolveGroup(item);
		if (group != null)
			for (child in group.members)
				attach(child);
	}

	private function detach(item:FlxBasic):Void
	{
		if (item == null)
			return;
		if (previousCameras.exists(item))
		{
			item.cameras = previousCameras.get(item);
			previousCameras.remove(item);
		}
		if (Std.isOfType(item, FlxObject))
		{
			var object:FlxObject = cast item;
			var factor = previousScroll.get(object);
			if (factor != null)
			{
				object.scrollFactor.copyFrom(factor);
				factor.put();
				previousScroll.remove(object);
			}
		}
		if (Std.isOfType(item, FlxUXGroup))
			(cast item : FlxUXGroup).scrollPanel = null;
		if (Std.isOfType(item, FlxUXButton))
			(cast item : FlxUXButton).scrollPanel = null;
		var group = FlxTypedGroup.resolveGroup(item);
		if (group != null)
			for (child in group.members)
				detach(child);
	}

	private function measure(item:FlxBasic):Void
	{
		if (item == null || !item.exists || !item.visible)
			return;
		if (Std.isOfType(item, FlxUXGroup))
		{
			measure((cast item : FlxUXGroup).buttons);
			return;
		}
		var group = FlxTypedGroup.resolveGroup(item);
		if (group != null)
		{
			for (child in group.members)
				measure(child);
		}
		else if (Std.isOfType(item, FlxObject))
		{
			var object:FlxObject = cast item;
			contentBounds.union(FlxRect.weak(object.x, object.y, object.width, object.height));
		}
	}

	public function refresh():Void
	{
		width = Math.max(64, width);
		height = Math.max(64, height);
		attach(content);
		if (!explicitBounds)
		{
			contentBounds.set(0, 0, 0, 0);
			measure(content);
		}
		var showVertical = verticalEnabled && !autoHideScrollbars;
		var showHorizontal = horizontalEnabled && !autoHideScrollbars;
		for (iteration in 0...3)
		{
			viewportWidth = width - (showVertical ? verticalBar.thickness : 0);
			viewportHeight = height - (showHorizontal ? horizontalBar.thickness : 0);
			showVertical = verticalEnabled && (!autoHideScrollbars || contentBounds.height > viewportHeight);
			showHorizontal = horizontalEnabled && (!autoHideScrollbars || contentBounds.width > viewportWidth);
		}
		viewportWidth = width - (showVertical ? verticalBar.thickness : 0);
		viewportHeight = height - (showHorizontal ? horizontalBar.thickness : 0);
		viewportCamera.x = x;
		viewportCamera.y = y;
		viewportCamera.width = Std.int(viewportWidth);
		viewportCamera.height = Std.int(viewportHeight);
		var theme = FlxUXCore.theme;
		viewportCamera.bgColor = FlxColor.TRANSPARENT;
		var actualBackgroundColor = backgroundColor == null ? theme.scrollPanelBackgroundColor : backgroundColor;
		var actualBackgroundGraphic = backgroundGraphic != null ? backgroundGraphic : theme.scrollPanelBackgroundGraphic;
		var actualBorderGraphic = borderGraphic != null ? borderGraphic : theme.scrollPanelBorderGraphic;
		updatePanelGraphic(background, actualBackgroundGraphic, Std.int(viewportWidth),
			Std.int(viewportHeight), actualBackgroundGraphic != lastBackgroundGraphic || Std.int(viewportWidth) != lastBackgroundWidth || Std.int(viewportHeight) != lastBackgroundHeight);
		lastBackgroundGraphic = actualBackgroundGraphic;
		lastBackgroundWidth = Std.int(viewportWidth);
		lastBackgroundHeight = Std.int(viewportHeight);
		background.cameras = [viewportCamera];
		background.scrollFactor.set(1, 1);
		background.color = actualBackgroundGraphic == null ? actualBackgroundColor : FlxColor.WHITE;
		var borderWidth = Std.int(width);
		var borderHeight = Std.int(height);
		updatePanelGraphic(border, actualBorderGraphic, borderWidth,
			borderHeight, actualBorderGraphic != lastBorderGraphic || borderWidth != lastBorderWidth || borderHeight != lastBorderHeight);
		lastBorderGraphic = actualBorderGraphic;
		lastBorderWidth = borderWidth;
		lastBorderHeight = borderHeight;
		border.cameras = null;
		border.scrollFactor.set();
		border.setPosition(x, y);
		if (actualBorderGraphic == null)
		{
			var thickness = Std.int(Math.max(1, borderThickness == null ? theme.scrollPanelBorderThickness : borderThickness));
			border.scale.set(1, 1);
			if (border.frameWidth != borderWidth || border.frameHeight != borderHeight || lastBorderFrameThickness != thickness)
			{
				border.makeGraphic(borderWidth, borderHeight, 0x00000000, true);
				border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, borderWidth, thickness), FlxColor.WHITE);
				border.pixels.fillRect(new openfl.geom.Rectangle(0, borderHeight - thickness, borderWidth, thickness), FlxColor.WHITE);
				border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, thickness, borderHeight), FlxColor.WHITE);
				border.pixels.fillRect(new openfl.geom.Rectangle(borderWidth - thickness, 0, thickness, borderHeight), FlxColor.WHITE);
				border.dirty = true;
				lastBorderFrameThickness = thickness;
			}
			border.color = borderColor == null ? theme.scrollPanelBorderColor : borderColor;
			border.visible = visible;
		}
		else
		{
			border.color = FlxColor.WHITE;
			border.visible = visible;
		}
		verticalBar.x = x + viewportWidth;
		verticalBar.y = y;
		verticalBar.barLength = viewportHeight;
		horizontalBar.x = x;
		horizontalBar.y = y + viewportHeight;
		horizontalBar.barLength = viewportWidth;
		verticalBar.visible = showVertical;
		horizontalBar.visible = showHorizontal;
		verticalBar.setRange(verticalEnabled ? contentBounds.height : viewportHeight, viewportHeight);
		horizontalBar.setRange(horizontalEnabled ? contentBounds.width : viewportWidth, viewportWidth);
		applyScroll();
	}

	private function updatePanelGraphic(sprite:FlxSprite, input:Null<FlxUXGraphicInput>, targetWidth:Int, targetHeight:Int, changed:Bool):Void
	{
		sprite.visible = true;
		if (input == null)
		{
			if (changed || sprite.graphic == null)
				sprite.makeGraphic(1, 1, FlxColor.WHITE);
			sprite.scale.set(targetWidth, targetHeight);
			sprite.updateHitbox();
			return;
		}
		if (changed || sprite.graphic == null)
		{
			if (Std.isOfType(input, FlxUX9Slice))
				sprite.loadGraphic((cast input : FlxUX9Slice).render(targetWidth, targetHeight));
			else
				sprite.loadGraphic(FlxUX9Slice.toGraphic(input));
		}
		if (sprite.frameWidth != targetWidth || sprite.frameHeight != targetHeight)
		{
			sprite.setGraphicSize(targetWidth, targetHeight);
			sprite.updateHitbox();
		}
	}

	private function syncCameraVisibility():Void
	{
		viewportCamera.visible = visible && exists && ownerState == FlxUXCore.currentState();
	}

	private function get_scrollX():Float
		return horizontalBar.value;

	private function get_scrollY():Float
		return verticalBar.value;

	private function set_scrollX(value:Float):Float
		return horizontalBar.value = value;

	private function set_scrollY(value:Float):Float
		return verticalBar.value = value;

	private function applyScroll():Void
	{
		var nextX = contentBounds.x + scrollX;
		var nextY = contentBounds.y + scrollY;
		var changed = viewportCamera.scroll.x != nextX || viewportCamera.scroll.y != nextY;
		viewportCamera.scroll.set(nextX, nextY);
		if (background != null)
			background.setPosition(nextX, nextY);
		if (changed && onScroll != null)
			onScroll();
	}

	public function scrollTo(x:Float, y:Float):Void
	{
		scrollX = x;
		scrollY = y;
	}

	public function ensureVisible(object:FlxObject):Void
	{
		if (object == null)
			return;
		var left = viewportCamera.scroll.x;
		var top = viewportCamera.scroll.y;
		var nextX = scrollX;
		var nextY = scrollY;
		if (object.x < left + focusPadding)
			nextX += object.x - left - focusPadding;
		else if (object.x + object.width > left + viewportWidth - focusPadding)
			nextX += object.x + object.width - left - viewportWidth + focusPadding;
		if (object.y < top + focusPadding)
			nextY += object.y - top - focusPadding;
		else if (object.y + object.height > top + viewportHeight - focusPadding)
			nextY += object.y + object.height - top - viewportHeight + focusPadding;
		scrollTo(nextX, nextY);
	}

	public function containsPointer(input:FlxPointer):Bool
	{
		if (!exists || !alive || !visible || !active || ownerState != FlxUXCore.currentState())
			return false;
		input.getViewPosition(viewportCamera, pointer);
		return pointer.x >= 0 && pointer.y >= 0 && pointer.x < viewportWidth && pointer.y < viewportHeight;
	}

	public function handleKeyboard():Bool
	{
		if (!keyboardScrolling || !FlxUXCore.isKeyboardEnabled())
			return false;
		var pageUp = FlxUXCore.actions.pageUp.triggered;
		var pageDown = FlxUXCore.actions.pageDown.triggered;
		var home = FlxUXCore.keyboardHomeEnd && FlxUXCore.actions.first.triggered;
		var end = FlxUXCore.keyboardHomeEnd && FlxUXCore.actions.last.triggered;
		if (!pageUp && !pageDown && !home && !end)
			return false;
		if (verticalEnabled)
			scrollY = home ? 0 : end ? verticalBar.maximum : scrollY + (pageUp ? -1 : 1) * viewportHeight;
		else if (horizontalEnabled)
			scrollX = home ? 0 : end ? horizontalBar.maximum : scrollX + (pageUp ? -1 : 1) * viewportWidth;
		return true;
	}

	override public function update(elapsed:Float):Void
	{
		refresh();
		var modal = FlxUXCore.modalGroup();
		var available = ownerState == FlxUXCore.currentState()
			&& FlxUXCore.active
			&& FlxUXCore.ready
			&& (modal == null || modal.scrollPanel == this);
		viewportCamera.visible = visible && available;
		if (!available)
			return;
		content.update(elapsed);
		if (verticalBar.visible)
			verticalBar.update(elapsed);
		if (horizontalBar.visible)
			horizontalBar.update(elapsed);
		#if !FLX_NO_MOUSE
		if (wheelEnabled && FlxG.mouse.enabled && FlxG.mouse.wheel != 0 && containsPointer(FlxG.mouse))
		{
			var horizontal = !verticalEnabled;
			#if !FLX_NO_KEYBOARD
			if (FlxUXCore.isKeyboardEnabled() && FlxG.keys.pressed.SHIFT)
				horizontal = true;
			#end
			if (horizontal && horizontalEnabled)
				scrollX -= FlxG.mouse.wheel * wheelStep;
			else if (!horizontal && verticalEnabled)
				scrollY -= FlxG.mouse.wheel * wheelStep;
		}
		#end
	}

	override public function draw():Void
	{
		viewportCamera.visible = visible && exists && ownerState == FlxUXCore.currentState();
		if (viewportCamera.visible)
			super.draw();
	}

	override public function destroy():Void
	{
		onScroll = null;
		FlxUXCore.removeScrollPanel(this);
		for (factor in previousScroll)
			factor.put();
		previousScroll.clear();
		previousCameras.clear();
		pointer.put();
		FlxG.signals.preDraw.remove(syncCameraVisibility);
		if (FlxG.cameras.list.indexOf(viewportCamera) >= 0)
			FlxG.cameras.remove(viewportCamera, true);
		super.destroy();
	}
}
