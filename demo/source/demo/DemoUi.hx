package demo;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ux.FlxUXButton;
import flixel.ux.FlxUXGroup;

class DemoUi
{
	public static function makeSolidBackdrop():FlxSprite
	{
		var s = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		s.scrollFactor.set();
		return s;
	}

	public static function makeHeader(title:String, subtitle:String):FlxText
	{
		var t = new FlxText(24, 16, FlxG.width - 48, title + "\n" + subtitle);
		t.setFormat(null, 16, FlxColor.WHITE, LEFT);
		t.scrollFactor.set();
		return t;
	}

	public static function makeBox(x:Float, y:Float, w:Float, h:Float, label:String):{ border:FlxSprite, label:FlxText }
	{
		var border = new FlxSprite(x, y).makeGraphic(Std.int(w), Std.int(h), 0x00000000);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, h), 0x00000000);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, w, 2), 0xFF2C3448);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, h - 2, w, 2), 0xFF2C3448);
		border.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, h), 0xFF2C3448);
		border.pixels.fillRect(new openfl.geom.Rectangle(w - 2, 0, 2, h), 0xFF2C3448);
		border.dirty = true;

		var t = new FlxText(x + 10, y + 8, w - 20, label);
		t.setFormat(null, 14, 0xFFB9C0D0, LEFT);
		t.scrollFactor.set();

		return { border: border, label: t };
	}

	public static function addBackButton(state:flixel.FlxSubState, label:String = "Back"):FlxUXButton
	{
		var g = new FlxUXGroup();
		state.add(g);

		var b = g.addButton(label, () -> state.close());
		b.resize(120, 36);
		g.x = FlxG.width - 24 - b.width;
		g.y = 16;
		return b;
	}
}
