package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;

class FlxUXScrollBar extends FlxGroup
{
	public var x:Float;
	public var y:Float;
	public var barLength:Float;
	public var vertical:Bool;
	public var thickness:Float = 20;
	public var showButtons:Bool = true;
	public var step:Float = 24;
	public var minThumbSize:Float = 20;
	public var repeatDelay:Float = 0.4;
	public var repeatInterval:Float = 0.08;
	public var trackColor:Null<FlxColor> = null;
	public var thumbColor:Null<FlxColor> = null;
	public var trackGraphic:Null<FlxUXGraphicInput> = null;
	public var thumbGraphic:Null<FlxUXGraphicInput> = null;
	public var buttonGraphic:Null<FlxUXGraphicInput> = null;
	public var arrowGraphic:Null<String> = null;
	public var onChange:Float->Void;
	public var value(default, set):Float = 0;
	public var contentSize(default, null):Float = 0;
	public var viewportSize(default, null):Float = 0;
	public var maximum(get, never):Float;
	public var dragging(default, null):Bool = false;
	public var decreaseButton(default, null):FlxUXButton;
	public var increaseButton(default, null):FlxUXButton;
	public var thumb(default, null):FlxSprite;
	private var decreaseIcon:FlxSprite;
	private var increaseIcon:FlxSprite;
	private var track:FlxSprite;
	private var lastTrackGraphic:Null<FlxUXGraphicInput>;
	private var lastThumbGraphic:Null<FlxUXGraphicInput>;
	private var lastButtonGraphic:Null<FlxUXGraphicInput>;
	private var lastArrowGraphic:Null<String>;
	private var lastArrowFrameSize:Int = -1;
	private var lastTrackWidth:Int = -1;
	private var lastTrackHeight:Int = -1;
	private var lastThumbWidth:Int = -1;
	private var lastThumbHeight:Int = -1;
	private var lastAppliedTheme:FlxUXTheme;
	private var dragOffset:Float = 0;
	private var heldDirection:Int = 0;
	private var repeatTime:Float = 0;
	private var pointer:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, length:Float, vertical:Bool = true)
	{
		FlxUXCore.init();
		super();
		this.x = x;
		this.y = y;
		this.barLength = length;
		this.vertical = vertical;
		track = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		thumb = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(track);
		add(thumb);
		decreaseButton = new FlxUXButton(0, 0, "");
		increaseButton = new FlxUXButton(0, 0, "");
		for (button in [decreaseButton, increaseButton])
		{
			button.tabStop = false;
			button.buttonLabelSize = 8;
			button.applyLabelOptions();
			button.showKeyboardCues = false;
			add(button);
		}
		decreaseIcon = new FlxSprite();
		increaseIcon = new FlxSprite();
		add(decreaseIcon);
		add(increaseIcon);
		decreaseButton.onDown.callback = () -> startStep(-1);
		increaseButton.onDown.callback = () -> startStep(1);
		applyTheme(FlxUXCore.theme);
		refresh();
	}

	public function applyTheme(theme:FlxUXTheme):Void
	{
		if (theme == null) return;
		if (lastAppliedTheme == null || thickness == lastAppliedTheme.scrollBarThickness) thickness = theme.scrollBarThickness;
		if (lastAppliedTheme == null || step == lastAppliedTheme.scrollBarStep) step = theme.scrollBarStep;
		if (lastAppliedTheme == null || minThumbSize == lastAppliedTheme.scrollBarMinThumbSize) minThumbSize = theme.scrollBarMinThumbSize;
		if (lastAppliedTheme == null || showButtons == lastAppliedTheme.scrollBarShowButtons) showButtons = theme.scrollBarShowButtons;
		lastAppliedTheme = theme;
		refresh();
	}

	private function get_maximum():Float
	{
		return Math.max(0, contentSize - viewportSize);
	}

	private function set_value(next:Float):Float
	{
		if (!Math.isFinite(next)) next = 0;
		next = Math.max(0, Math.min(maximum, next));
		if (next == value) return value;
		value = next;
		if (thumb != null) refresh();
		if (onChange != null) onChange(value);
		return value;
	}

	public function setRange(content:Float, viewport:Float):Void
	{
		contentSize = Math.isFinite(content) ? Math.max(0, content) : 0;
		viewportSize = Math.isFinite(viewport) ? Math.max(0, viewport) : 0;
		value = value;
		refresh();
	}

	public static function calculateThumbLength(trackLength:Float, viewport:Float, content:Float, minimum:Float):Float
	{
		if (trackLength <= 0) return 0;
		if (content <= viewport || content <= 0) return trackLength;
		return Math.min(trackLength, Math.max(minimum, trackLength * Math.max(0, viewport) / content));
	}

	public function refresh():Void
	{
		var buttonSize = showButtons ? thickness : 0;
		var trackLength = Math.max(1, barLength - buttonSize * 2);
		var thumbLength = calculateThumbLength(trackLength, viewportSize, contentSize, minThumbSize);
		var thumbOffset = maximum <= 0 ? 0 : (trackLength - thumbLength) * value / maximum;
		track.setPosition(x + (vertical ? 0 : buttonSize), y + (vertical ? buttonSize : 0));
		var activeTheme = FlxUXCore.theme;
		var actualTrackGraphic = trackGraphic != null ? trackGraphic : activeTheme.scrollBarTrackGraphic;
		var actualThumbGraphic = thumbGraphic != null ? thumbGraphic : activeTheme.scrollBarThumbGraphic;
		var actualButtonGraphic = buttonGraphic != null ? buttonGraphic : activeTheme.scrollBarButtonGraphic;
		var actualArrowGraphic = arrowGraphic != null ? arrowGraphic : activeTheme.scrollBarArrowGraphic;
		updateGraphic(track, actualTrackGraphic, Std.int(Math.ceil(vertical ? thickness : trackLength)), Std.int(Math.ceil(vertical ? trackLength : thickness)),
			actualTrackGraphic != lastTrackGraphic || Std.int(Math.ceil(vertical ? thickness : trackLength)) != lastTrackWidth
			|| Std.int(Math.ceil(vertical ? trackLength : thickness)) != lastTrackHeight);
		lastTrackGraphic = actualTrackGraphic;
		lastTrackWidth = Std.int(Math.ceil(vertical ? thickness : trackLength));
		lastTrackHeight = Std.int(Math.ceil(vertical ? trackLength : thickness));
		track.color = trackColor == null ? activeTheme.scrollBarTrackColor : trackColor;
		thumb.setPosition(track.x + (vertical ? 0 : thumbOffset), track.y + (vertical ? thumbOffset : 0));
		var thumbWidth = Std.int(Math.ceil(vertical ? thickness : thumbLength));
		var thumbHeight = Std.int(Math.ceil(vertical ? thumbLength : thickness));
		updateGraphic(thumb, actualThumbGraphic, thumbWidth, thumbHeight,
			actualThumbGraphic != lastThumbGraphic || thumbWidth != lastThumbWidth || thumbHeight != lastThumbHeight);
		lastThumbGraphic = actualThumbGraphic;
		lastThumbWidth = thumbWidth;
		lastThumbHeight = thumbHeight;
		thumb.color = thumbColor == null ? activeTheme.scrollBarThumbColor : thumbColor;
		thumb.alpha = maximum <= 0 ? 0.45 : 1;
		for (button in [decreaseButton, increaseButton])
		{
			button.visible = showButtons;
			if (button.width != thickness || button.height != thickness) button.resize(Std.int(thickness), Std.int(thickness));
		}
		if (actualButtonGraphic != lastButtonGraphic)
		{
			for (button in [decreaseButton, increaseButton])
				if (actualButtonGraphic == null) button.resetButtonSkin(); else button.setButtonSkin(actualButtonGraphic);
			lastButtonGraphic = actualButtonGraphic;
		}
		decreaseButton.setPosition(x, y);
		increaseButton.setPosition(x + (vertical ? 0 : barLength - thickness), y + (vertical ? barLength - thickness : 0));
		updateArrowIcons(actualArrowGraphic, activeTheme.scrollBarArrowFrameSize, buttonSize);
		decreaseButton.locked = maximum <= 0 || value <= 0;
		increaseButton.locked = maximum <= 0 || value >= maximum;
	}

	private function updateGraphic(sprite:FlxSprite, input:Null<FlxUXGraphicInput>, width:Int, height:Int, changed:Bool):Void
	{
		width = Std.int(Math.max(1, width));
		height = Std.int(Math.max(1, height));
		if (input == null)
		{
			if (changed || sprite.graphic == null) sprite.makeGraphic(1, 1, FlxColor.WHITE);
			sprite.scale.set(width, height);
			sprite.updateHitbox();
			return;
		}
		if (changed || sprite.graphic == null)
		{
			sprite.scale.set(1, 1);
			if (Std.isOfType(input, FlxUX9Slice))
				sprite.loadGraphic((cast input:FlxUX9Slice).render(width, height));
			else
				sprite.loadGraphic(FlxUX9Slice.toGraphic(input));
		}
		if (sprite.frameWidth != width || sprite.frameHeight != height)
		{
			sprite.setGraphicSize(width, height);
			sprite.updateHitbox();
		}
	}

	private function updateArrowIcons(graphic:Null<String>, frameSize:Int, buttonSize:Float):Void
	{
		if (graphic != lastArrowGraphic || frameSize != lastArrowFrameSize)
		{
			lastArrowGraphic = graphic;
			lastArrowFrameSize = frameSize;
			for (icon in [decreaseIcon, increaseIcon])
			{
				if (graphic != null && frameSize > 0)
					icon.loadGraphic(FlxUX9Slice.toGraphic(graphic), true, frameSize, frameSize);
				else icon.visible = false;
			}
		}
		if (graphic == null) return;
		decreaseIcon.visible = showButtons;
		increaseIcon.visible = showButtons;
		decreaseIcon.animation.frameIndex = vertical ? 0 : 2;
		increaseIcon.animation.frameIndex = vertical ? 1 : 3;
		var size = Std.int(Math.min(frameSize, buttonSize - 8));
		var iconX = (button:FlxUXButton) -> button.x + (button.width - size) * 0.5;
		var iconY = (button:FlxUXButton) -> button.y + (button.height - size) * 0.5;
		for (pair in [{icon: decreaseIcon, button: decreaseButton}, {icon: increaseIcon, button: increaseButton}])
		{
			pair.icon.setGraphicSize(size, size);
			pair.icon.updateHitbox();
			pair.icon.setPosition(iconX(pair.button), iconY(pair.button));
			pair.icon.cameras = pair.button.cameras;
		}
	}

	private function startStep(direction:Int):Void
	{
		heldDirection = direction;
		repeatTime = repeatDelay;
		value += direction * step;
	}

	override public function update(elapsed:Float):Void
	{
		refresh();
		if (!FlxUXCore.active || !FlxUXCore.ready)
		{
			dragging = false;
			return;
		}
		super.update(elapsed);
		#if !FLX_NO_MOUSE
		if (!FlxG.mouse.enabled)
		{
			dragging = false;
			return;
		}
		FlxG.mouse.getWorldPosition(getDefaultCamera(), pointer);
		var position = vertical ? pointer.y : pointer.x;
		var start = vertical ? track.y : track.x;
		var thumbStart = vertical ? thumb.y : thumb.x;
		var thumbLength = vertical ? thumb.height : thumb.width;
		var trackLength = vertical ? track.height : track.width;
		if (FlxG.mouse.justPressed && maximum > 0)
		{
			if (thumb.overlapsPoint(pointer))
			{
				dragging = true;
				dragOffset = position - thumbStart;
			}
			else if (track.overlapsPoint(pointer)) value += (position < thumbStart ? -1 : 1) * viewportSize;
		}
		if (dragging && FlxG.mouse.pressed && trackLength > thumbLength)
			value = (position - start - dragOffset) / (trackLength - thumbLength) * maximum;
		if (!FlxG.mouse.pressed)
		{
			dragging = false;
			heldDirection = 0;
		}
		if (heldDirection != 0 && repeatInterval > 0 && (decreaseButton.uxPressed || increaseButton.uxPressed
			|| decreaseButton.status == flixel.ui.FlxButton.FlxButtonState.PRESSED || increaseButton.status == flixel.ui.FlxButton.FlxButtonState.PRESSED))
		{
			repeatTime -= elapsed;
			if (repeatTime <= 0)
			{
				value += heldDirection * step;
				repeatTime = repeatInterval;
			}
		}
		#end
	}

	override public function destroy():Void
	{
		onChange = null;
		pointer.put();
		super.destroy();
	}
}