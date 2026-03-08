package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;

class PlayState extends FlxState
{
	override public function create():Void
	{
		super.create();
		bgColor = FlxColor.fromRGB(0x10, 0x12, 0x18);

		FlxUXCore.init();

		var title = new FlxText(0, 20, FlxG.width, "flixel-ux demo");
		title.setFormat(null, 24, FlxColor.WHITE, CENTER);
		add(title);

		var subtitle = new FlxText(0, 54, FlxG.width, "Mouse works, but this demo is mainly for keyboard/gamepad NAV.");
		subtitle.setFormat(null, 14, 0xFFB9C0D0, CENTER);
		add(subtitle);

		var menu = new FlxUXGroup();
		add(menu);

		menu.addButton("Focus modes", () -> openSubState(new FocusModesSubState()));
		menu.addButton("Themes + overrides", () -> openSubState(new ThemesSubState()));
		menu.addButton("Layout helpers", () -> openSubState(new LayoutHelpersSubState()));
		menu.addButton("Advanced examples", () -> openSubState(new AdvancedExamplesSubState()));
		#if sys
		menu.addButton("Quit", () -> Sys.exit(0));
		#end

		menu.matchSize();
		menu.stack(14);
		menu.alignCenter();
		menu.y += 60;
	}
}

