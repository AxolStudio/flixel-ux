package;

import flixel.ux.FlxUX9Slice;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXCore.FlxUXFocusMode;
import flixel.ux.FlxUXTheme;
import flixel.util.FlxColor;

class TestMain
{
	static function main():Void
	{
		testObjectConstructor();
		testJsonConstructor();
		testFactoryMethods();
		testInvalidJsonDefaults();
		testDefaultAnimationSequences();
		testNamedColorParsing();
		trace("All FlxUX tests passed.");
		Sys.exit(0);
	}

	static function testObjectConstructor():Void
	{
		var theme = new FlxUXTheme({
			buttonLabelSize: 20,
			buttonLabelColor: "#123456",
			focusMode: "OVERLAY",
			buttonGraphic: {
				source: "assets/ui/button.png",
				frameWidth: 16,
				frameHeight: 16,
				left: 3,
				top: 4,
				right: 3,
				bottom: 4
			}
		});

		assertEquals(20, theme.buttonLabelSize, "object label size");
		assertEquals(0xFF123456, theme.buttonLabelColor, "object label color");
		assertEquals(FlxUXFocusMode.OVERLAY, theme.focusMode, "object focus mode");
		assertTrue(Std.isOfType(theme.buttonGraphic, FlxUX9Slice), "object 9-slice graphic");
	}

	static function testJsonConstructor():Void
	{
		var theme = new FlxUXTheme('{"buttonLabelSize":22,"focusMode":"NEXT_TO","snapUiToPixels":false}');

		assertEquals(22, theme.buttonLabelSize, "JSON label size");
		assertEquals(FlxUXFocusMode.NEXT_TO, theme.focusMode, "JSON focus mode");
		assertEquals(false, theme.snapUiToPixels, "JSON boolean");
	}

	static function testFactoryMethods():Void
	{
		var objectTheme = FlxUXTheme.fromObject({buttonLabelSize: 18});
		var jsonTheme = FlxUXTheme.fromJson('{"buttonLabelSize":19}');

		assertEquals(18, objectTheme.buttonLabelSize, "fromObject label size");
		assertEquals(19, jsonTheme.buttonLabelSize, "fromJson label size");
	}

	static function testInvalidJsonDefaults():Void
	{
		var theme = new FlxUXTheme("not-json");
		assertEquals(14, theme.buttonLabelSize, "invalid JSON fallback");
	}

	static function testDefaultAnimationSequences():Void
	{
		assertEquals("0,1", FlxUXCore.DEFAULT_BUTTON_ANIM_UP.join(","), "default up animation");
		assertEquals("2,3,4,5", FlxUXCore.DEFAULT_BUTTON_ANIM_OVER.join(","), "default over animation");
		assertEquals("6,7,8,9", FlxUXCore.DEFAULT_BUTTON_ANIM_DOWN.join(","), "default down animation");
		assertEquals("10", FlxUXCore.DEFAULT_BUTTON_ANIM_DISABLED.join(","), "default disabled animation");
	}

	static function testNamedColorParsing():Void
	{
		var theme = new FlxUXTheme({buttonLabelColor: "blue"});
		var invalidTheme = new FlxUXTheme({buttonLabelColor: "not-a-color"});
		assertEquals(0xFF0000FF, theme.buttonLabelColor, "named FlxColor parsing");
		assertEquals(FlxColor.WHITE, invalidTheme.buttonLabelColor, "invalid color fallback");
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void
	{
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}

	static function assertTrue(value:Bool, label:String):Void
	{
		if (!value)
			throw '$label: expected true';
	}
}
