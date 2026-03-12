package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXCore.FlxUXGridLastRowAlign;
import flixel.ux.FlxUXGroup;

class LayoutHelpersSubState extends FlxSubState
{
	override public function create():Void
	{
		super.create();
		/**
		 * Demo setup - you can ignore this section
		 * =====================================================================
		 **/
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);
		add(DemoUi.makeHeader(
			"Layout helpers",
			"These helpers place buttons based on their current sizes: stack (vertical), spread (horizontal), grid (cells).")
		);
		/**
		 * END OF DEMO SETUP
		 * =====================================================================
		 **/

		var padX = 12;
		var topY = 120;
		var gap = 10;

		// Left column: STACK (full height)
		var stackW = 210;
		var stackBox = DemoUi.makeBox(padX, topY, stackW, FlxG.height - topY - 34, "stack(gap)");
		add(stackBox.border);
		add(stackBox.label);
		var gStack = new FlxUXGroup();
		gStack.buttonLabelColor = 0xFF666666;
		gStack.buttonLabelColorHover = 0xFF333333;
		gStack.buttonLabelColorDown = 0xFF333333;
		add(gStack);
		for (name in ["One", "Two", "Three", "Four"])
		{
			var b = gStack.addButton(name, () -> {});
			b.resize(160, 34);
		}
		gStack.stack(10);
		gStack.x = padX + (stackW - gStack.width) * 0.5;
		gStack.y = topY + 44;

		// Right area
		var rightX = padX + stackW + gap;
		var rightW = FlxG.width - rightX - padX;

		// Top-right: SPREAD
		var spreadBox = DemoUi.makeBox(rightX, topY, rightW, 110, "spread(gap)");
		add(spreadBox.border);
		add(spreadBox.label);
		{
			var g = new FlxUXGroup();
			g.buttonLabelColor = 0xFF666666;
			g.buttonLabelColorHover = 0xFF333333;
			g.buttonLabelColorDown = 0xFF333333;
			add(g);
			for (i in 0...4)
			{
				var b = g.addButton(Std.string(i + 1), () -> {});
				b.resize(76, 34);
			}
			g.spread(8);
			g.x = rightX + (rightW - g.width) * 0.5;
			g.y = topY + 50;
		}

		// Bottom-right: GRID
		var gridY = topY + 110 + gap;
		var gridBox = DemoUi.makeBox(rightX, gridY, rightW, FlxG.height - gridY - 34, "grid(columns, gapX, gapY)");
		add(gridBox.border);
		add(gridBox.label);
		{
			var g = new FlxUXGroup();
			g.buttonLabelColor = 0xFF666666;
			g.buttonLabelColorHover = 0xFF333333;
			g.buttonLabelColorDown = 0xFF333333;
			add(g);
			for (i in 0...9)
			{
				var b = g.addButton(Std.string(i + 1), () -> {});
				b.resize(44, 28);
			}
			g.grid(3, 8, 8, FlxUXGridLastRowAlign.CENTER);
			g.x = rightX + (rightW - g.width) * 0.5;
			g.y = gridY + 44;
		}

		var hint = new FlxText(24, FlxG.height - 26, FlxG.width - 48, "Tip: you can call matchSize() first for tidy columns.");
		hint.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(hint);
	}
}
