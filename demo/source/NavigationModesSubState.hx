package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXCore.FlxUXNavStyle;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;
import flixel.ux.FlxUXButton;

class NavigationModesSubState extends FlxSubState
{
	private var info:FlxText;
	private var navStyle:FlxUXNavStyle = LINEAR;
	private var grid:FlxUXGroup;
	private var toggleButton:FlxUXButton;

	override public function create():Void
	{
		super.create();
		// This screen demonstrates the two NAV traversal styles:
		// - LINEAR: next/previous traversal in the group's ordered list
		// - SPATIAL: direction-based navigation (nearest neighbor in the direction you pressed)
		//
		// Tip: in SPATIAL mode, the grid layout makes the behavior feel natural.
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);

		var header = DemoUi.makeHeader(
			"Navigation modes",
			"Toggle between LINEAR and SPATIAL navigation on a grid."
		);
		add(header);

		info = new FlxText(24, 86, FlxG.width - 48, "");
		info.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(info);

		var box = DemoUi.makeBox(24, 120, FlxG.width - 48, FlxG.height - 160, "LINEAR vs SPATIAL");
		add(box.border);
		add(box.label);

		// Controls menu (separate group from the grid).
		// Keeping it separate makes sure it doesn't interfere with spatial selection in the grid.
		var controls = new FlxUXGroup();
		controls.x = box.border.x + 16;
		controls.y = box.border.y + 34;
		add(controls);
		toggleButton = controls.addButton("Nav: LINEAR (toggle)", toggleNav);
		toggleButton.resize(260, 36);

		// Grid menu.
		// We use button labels like "1,1" so it's easy to see which cell you landed on.
		grid = new FlxUXGroup();
		grid.x = box.border.x + 16;
		grid.y = controls.y + 58;
		add(grid);

		for (y in 0...4)
		{
			for (x in 0...4)
			{
				var b = grid.addButton('${x + 1},${y + 1}', null);
				b.resize(76, 34);
			}
		}
		// grid(columns, gapX, gapY) lays the buttons out visually.
		grid.grid(4, 12, 12);

		// Apply starting nav style.
		applyNavStyle();
	}

	private function toggleNav():Void
	{
		navStyle = (navStyle == LINEAR) ? SPATIAL : LINEAR;
		applyNavStyle();
		if (toggleButton != null)
		{
			toggleButton.label.text = 'Nav: ' + ((navStyle == LINEAR) ? "LINEAR" : "SPATIAL") + " (toggle)";
		}
	}

	private function applyNavStyle():Void
	{
		// navStyle can be set globally (FlxUXCore) and/or per-group (FlxUXGroup).
		//
		// In a real game, you'd usually pick one:
		// - global default for your whole UI
		// - group override for special menus
		//
		// In this demo, we set BOTH so this screen always behaves consistently,
		// even if other demo screens changed the core defaults.
		FlxUXCore.navStyle = navStyle;
		grid.navStyle = navStyle;
		info.text = 'FlxUXCore.navStyle = ' + ((navStyle == LINEAR) ? "LINEAR" : "SPATIAL") + ';\n(grid.navStyle is also set)';
	}
}
