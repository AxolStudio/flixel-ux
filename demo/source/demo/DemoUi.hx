package demo;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ux.FlxUXButton;
import flixel.ux.FlxUXGroup;

class DemoUi
{
	private static inline var SCREEN_MARGIN:Int = 16;
	private static inline var HEADER_TOP:Int = 12;
	private static inline var BACK_BUTTON_W:Int = 120;
	private static inline var BACK_BUTTON_H:Int = 36;
	private static inline var BACK_BUTTON_SPACE:Int = 140;
	private static inline var BORDER_COLOR:Int = 0xFF2C3448;
	private static inline var LABEL_COLOR:Int = 0xFFB9C0D0;

	public static function makeSolidBackdrop():FlxSprite
	{
		// Demo-only helper: a simple black background so the UI is readable.
		var s = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		s.scrollFactor.set();
		return s;
	}

	public static function makeHeader(title:String, subtitle:String):FlxText
	{
		// Demo-only helper: leave space on the right for the back button.
		var t = new FlxText(SCREEN_MARGIN, HEADER_TOP, FlxG.width - SCREEN_MARGIN - SCREEN_MARGIN - BACK_BUTTON_SPACE, title + "\n" + subtitle);
		t.setFormat(null, 16, FlxColor.WHITE, LEFT);
		t.scrollFactor.set();
		return t;
	}

	public static function makeBox(x:Float, y:Float, w:Float, h:Float, label:String):{ border:FlxSprite, label:FlxText }
	{
		// Demo-only helper: light-weight box border + label.
		var border = new FlxSprite(x, y).makeGraphic(Std.int(w), Std.int(h), 0x00000000);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, h), 0x00000000);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, 2), BORDER_COLOR);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, h - 2, w, 2), BORDER_COLOR);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, h), BORDER_COLOR);
		border.pixels.fillRect(new openfl.geom.Rectangle(w - 2, 0, 2, h), BORDER_COLOR);
		border.dirty = true;

		var t = new FlxText(x + 10, y + 8, w - 20, label);
		t.setFormat(null, 14, LABEL_COLOR, LEFT);
		t.scrollFactor.set();

		return { border: border, label: t };
	}

	public static function addBackButton(state:flixel.FlxSubState, label:String = "Back"):FlxUXButton
	{
		// Demo-only helper: creates a 1-button group in the top-right that closes the current substate.
		var g = new FlxUXGroup();
		state.add(g);

		var b = g.addButton(label, () -> state.close());
		b.resize(BACK_BUTTON_W, BACK_BUTTON_H);
		g.x = FlxG.width - SCREEN_MARGIN - b.width;
		g.y = HEADER_TOP;
		return b;
	}
}
