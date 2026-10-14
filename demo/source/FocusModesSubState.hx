package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXGroup;
import flixel.ux.FlxUXCore.FlxUXFocusMode;

class FocusModesSubState extends FlxSubState
{
	override public function create():Void
	{
		super.create();
		// This screen demonstrates three of the focus highlight strategies.
		//
		// Key idea:
		// - Focus visuals are a *group* concern.
		// - You can set a global default with FlxUXCore.focusMode.
		// - Or override the focus mode per menu by setting group.focusMode.
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);
		add(DemoUi.makeHeader(
			"Focus modes",
			"FlxUX has 5 focus modes. The highlight graphics are customizable (and can be disabled)."
		));

		// We’ll build three columns, each backed by its own FlxUXGroup.
		// Each group contains the same buttons, but uses a different focusMode.

		var labels = [
			{
				name: "FRAME",
				mode: FlxUXFocusMode.FRAME
			},
			{
				name: "NEXT_TO",
				mode: FlxUXFocusMode.NEXT_TO
			},
			{
				name: "OVERLAY",
				mode: FlxUXFocusMode.OVERLAY
			},
		];

		var topY = 120;
		var padX = 24;
		var gapX = 16;
		var boxW = (FlxG.width - padX * 2 - gapX * (labels.length - 1)) / labels.length;
		var boxH = FlxG.height - topY - 32;

		for (i in 0...labels.length)
		{
			var x = padX + i * (boxW + gapX);
			var box = DemoUi.makeBox(x, topY, boxW, boxH, labels[i].name);
			add(box.border);
			add(box.label);

			var g = new FlxUXGroup();
			// Per-group override:
			// this menu uses its own focusMode instead of whatever FlxUXCore.focusMode is.
			g.focusMode = labels[i].mode;
			// Use simple label colors so the highlight graphics are the star of the show.
			g.buttonLabelColor = 0xFF666666;
			g.buttonLabelColorHover = 0xFF333333;
			g.buttonLabelColorDown = 0xFF333333;
			if (labels[i].mode == FlxUXFocusMode.NEXT_TO)
			{
				// NEXT_TO mode needs an arrow/marker graphic.
				g.focusNextToGraphic = "flixel-ux/highlight_next_to.png";
				g.focusNextToMirrored = true;
			}
			else if (labels[i].mode == FlxUXFocusMode.OVERLAY)
			{
				// OVERLAY mode draws a sprite on top of the button.
				g.focusOverlayGraphic = "flixel-ux/highlight_on.png";
			}
			add(g);
			// Add a small stack of matching buttons.
			for (n in 0...4)
				g.addButton(Std.string(n + 1), () -> {});
			// matchSize() makes every button match the largest one in the group.
			g.matchSize();
			// stack(gap) lays them out top-to-bottom.
			g.stack(10);
			g.x = x + (boxW - g.width) * 0.5;
			g.y = topY + 48;
		}

		// Tip: on desktop, FlxUX switches into NAV mode automatically when you press a nav input.
		var hint = new FlxText(24, FlxG.height - 26, FlxG.width - 48, "Tip: press any NAV input (arrows / dpad) to enter NAV mode.");
		hint.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(hint);
	}
}
