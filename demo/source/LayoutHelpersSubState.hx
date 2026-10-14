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
		// This screen demonstrates the three layout helpers you’ll use most often:
		// - stack(gap): vertical column
		// - spread(gap): horizontal row
		// - grid(columns, gapX, gapY): fixed column count
		//
		// These helpers position buttons based on their current size.
		// If you want “neat” columns/rows, call matchSize() first.
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);
		add(DemoUi.makeHeader(
			"Layout helpers",
			"These helpers place buttons based on their current sizes: stack (vertical), spread (horizontal), grid (cells)."
		));

		var padX = 12;
		var topY = 120;
		var gap = 10;

		// Left column: stack(gap)
		var stackW = 210;
		var stackBox = DemoUi.makeBox(padX, topY, stackW, FlxG.height - topY - 34, "stack(gap)");
		add(stackBox.border);
		add(stackBox.label);
		var gStack = new FlxUXGroup();
		// Keep styling simple in layout demos so you can focus on placement.
		gStack.buttonLabelColor = 0xFF666666;
		gStack.buttonLabelColorHover = 0xFF333333;
		gStack.buttonLabelColorDown = 0xFF333333;
		add(gStack);
		for (name in ["One", "Two", "Three", "Four"])
		{
			var b = gStack.addButton(name, () -> {});
			b.resize(160, 34);
		}
		// stack(gap) places buttons top-to-bottom.
		gStack.stack(10);
		gStack.x = padX + (stackW - gStack.width) * 0.5;
		gStack.y = topY + 44;

		// Right area
		var rightX = padX + stackW + gap;
		var rightW = FlxG.width - rightX - padX;

		// Top-right: spread(gap)
		var spreadBox = DemoUi.makeBox(rightX, topY, rightW, 110, "spread(gap)");
		add(spreadBox.border);
		add(spreadBox.label);
		{
			var gSpread = new FlxUXGroup();
			gSpread.buttonLabelColor = 0xFF666666;
			gSpread.buttonLabelColorHover = 0xFF333333;
			gSpread.buttonLabelColorDown = 0xFF333333;
			add(gSpread);
			for (i in 0...4)
			{
				var b = gSpread.addButton(Std.string(i + 1), () -> {});
				b.resize(76, 34);
			}
			// spread(gap) places buttons left-to-right.
			gSpread.spread(8);
			gSpread.x = rightX + (rightW - gSpread.width) * 0.5;
			gSpread.y = topY + 50;
		}

		// Bottom-right: grid(columns, gapX, gapY)
		var gridY = topY + 110 + gap;
		var gridBox = DemoUi.makeBox(rightX, gridY, rightW, FlxG.height - gridY - 34, "grid(columns, gapX, gapY)");
		add(gridBox.border);
		add(gridBox.label);
		{
			var gGrid = new FlxUXGroup();
			gGrid.buttonLabelColor = 0xFF666666;
			gGrid.buttonLabelColorHover = 0xFF333333;
			gGrid.buttonLabelColorDown = 0xFF333333;
			add(gGrid);
			for (i in 0...9)
			{
				var b = gGrid.addButton(Std.string(i + 1), () -> {});
				b.resize(44, 28);
			}
			// grid(3, ...) = 3 columns. The last row is centered if it isn't full.
			gGrid.grid(3, 8, 8, FlxUXGridLastRowAlign.CENTER);
			gGrid.x = rightX + (rightW - gGrid.width) * 0.5;
			gGrid.y = gridY + 44;
		}

		var hint = new FlxText(24, FlxG.height - 26, FlxG.width - 48, "Tip: you can call matchSize() first for tidy columns.");
		hint.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(hint);
	}
}
