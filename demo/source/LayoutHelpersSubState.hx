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

		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);

		add(DemoUi.makeHeader(
			"Layout helpers",
			"These helpers place buttons based on their current sizes: stack (vertical), spread (horizontal), grid (cells).")
		);

		var topY = 120;
		var padX = 24;
		var gapX = 16;
		var boxW = (FlxG.width - padX * 2 - gapX * 2) / 3;
		var boxH = FlxG.height - topY - 32;

		// STACK
		{
			var x = padX;
			var box = DemoUi.makeBox(x, topY, boxW, boxH, "stack(gap)");
			add(box.border);
			add(box.label);

			var g = new FlxUXGroup();
			add(g);
			g.addButton("Short", () -> {});
			g.addButton("Medium label", () -> {});
			g.addButton("A very long label", () -> {});
			g.matchSize();
			g.stack(12);
			g.x = x + (boxW - g.width) * 0.5;
			g.y = topY + 56;
		}

		// SPREAD
		{
			var x = padX + (boxW + gapX);
			var box = DemoUi.makeBox(x, topY, boxW, boxH, "spread(gap)");
			add(box.border);
			add(box.label);

			var g = new FlxUXGroup();
			add(g);
			g.addButton("1", () -> {});
			g.addButton("2", () -> {});
			g.addButton("3", () -> {});
			g.addButton("4", () -> {});
			g.matchSize();
			g.spread(12);
			g.x = x + (boxW - g.width) * 0.5;
			g.y = topY + 110;
		}

		// GRID
		{
			var x = padX + (boxW + gapX) * 2;
			var box = DemoUi.makeBox(x, topY, boxW, boxH, "grid(columns, gapX, gapY)");
			add(box.border);
			add(box.label);

			var g = new FlxUXGroup();
			add(g);
			for (i in 0...10)
				g.addButton(Std.string(i + 1), () -> {});
			g.matchSize();
			g.grid(3, 12, 12, FlxUXGridLastRowAlign.CENTER);
			g.x = x + (boxW - g.width) * 0.5;
			g.y = topY + 56;
		}

		var hint = new FlxText(24, FlxG.height - 26, FlxG.width - 48, "Tip: you can call matchSize() first for tidy columns.");
		hint.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(hint);
	}
}
