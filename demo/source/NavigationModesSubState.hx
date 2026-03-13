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
		/**
		 *  Demo setup - you can ignore this section
		 * =====================================================================
		 **/
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
		/**
		 * END OF DEMO SETUP
		 * =====================================================================
		 **/

		var box = DemoUi.makeBox(24, 120, FlxG.width - 48, FlxG.height - 160, "LINEAR vs SPATIAL");
		add(box.border);
		add(box.label);

		// Toggle group (separate from the grid)
		var controls = new FlxUXGroup();
		controls.x = box.border.x + 16;
		controls.y = box.border.y + 34;
		add(controls);
		toggleButton = controls.addButton("Nav: LINEAR (toggle)", toggleNav);
		toggleButton.resize(260, 36);

		// Grid group
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
		grid.grid(4, 12, 12);

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
		// Set globally, and also set the group explicitly so it stays stable even if other demo pages change core state.
		FlxUXCore.navStyle = navStyle;
		grid.navStyle = navStyle;
		info.text = 'FlxUXCore.navStyle = ' + ((navStyle == LINEAR) ? "LINEAR" : "SPATIAL") + ';\n(grid.navStyle is also set)';
	}
}
