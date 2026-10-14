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
		// Demo-only setup: background + header text.
		bgColor = FlxColor.BLACK;

		var title = new FlxText(0, 20, FlxG.width, "flixel-ux demo");
		title.setFormat(null, 24, FlxColor.WHITE, CENTER);
		add(title);

		var subtitle = new FlxText(0, 54, FlxG.width, "A small showcase of FlxUX features that you can use as a guide.");
		subtitle.setFormat(null, 14, 0xFFB9C0D0, CENTER);
		add(subtitle);

		// Create a FlxUXGroup and add it to the state.
		// This matters: in NAV mode, FlxUX only navigates buttons that Flixel is updating.
		var menu = new FlxUXGroup();
		add(menu);

		// Add buttons to the group. These automatically participate in pointer + NAV focus.
		menu.addButton("Focus modes", () -> openSubState(new FocusModesSubState()));
		menu.addButton("Themes + overrides", () -> openSubState(new ThemesSubState()));
		menu.addButton("Layout helpers", () -> openSubState(new LayoutHelpersSubState()));
		menu.addButton("Navigation modes", () -> openSubState(new NavigationModesSubState()));
		menu.addButton("Advanced examples", () -> openSubState(new AdvancedExamplesSubState()));

		#if sys
		// ONLY if we are on a Sys target (windows, hashlink, etc) do we add a "Quit" button.
		menu.addButton("Quit", () -> Sys.exit(0));
		#end

		// Make all buttons the same size based on the largest label.
		menu.matchSize();

		// Arrange in a 2-column grid.
		// With 5 buttons, the final row has 1 button, and we center-align that last row.
		menu.grid(2, 18, 14, FlxUXGridLastRowAlign.CENTER);

		// Center the whole group based on its button bounds.
		menu.alignCenter();

		super.create();
	}
}
