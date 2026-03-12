package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;

class FocusModesSubState extends FlxSubState
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
			"Focus modes",
			"FlxUX has 5 focus modes. The highlight graphics are customizable (and can be disabled).")
		);
		/**
		 * END OF DEMO SETUP
		 * =====================================================================
		 **/

		var labels = [
			{ name: "FRAME", mode: FlxUXFocusMode.FRAME },
			{ name: "NEXT_TO", mode: FlxUXFocusMode.NEXT_TO },
			{ name: "OVERLAY", mode: FlxUXFocusMode.OVERLAY },
			{ name: "HOVER_ONLY", mode: FlxUXFocusMode.HOVER_ONLY },
			{ name: "DIM_UNFOCUSED", mode: FlxUXFocusMode.DIM_UNFOCUSED },
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
			// For this demo, we want every column to be usable in NAV.
			// HOVER_ONLY / DIM_UNFOCUSED are pointer-oriented by design, so we demonstrate them
			// as *visual styles* while still providing NAV-visible focus feedback.
			g.focusMode = (labels[i].mode == FlxUXFocusMode.HOVER_ONLY || labels[i].mode == FlxUXFocusMode.DIM_UNFOCUSED)
				? FlxUXFocusMode.FRAME
				: labels[i].mode;
			g.buttonLabelColor = 0xFF666666;
			g.buttonLabelColorHover = 0xFF333333;
			g.buttonLabelColorDown = 0xFF333333;
			if (labels[i].mode == FlxUXFocusMode.NEXT_TO)
			{
				g.focusNextToGraphic = "flixel-ux/highlight_next_to.png";
				g.focusNextToMirrored = true;
			}
			else if (labels[i].mode == FlxUXFocusMode.OVERLAY)
			{
				g.focusOverlayGraphic = "flixel-ux/highlight_on.png";
			}
			add(g);

			for (n in 0...4)
				g.addButton(Std.string(n + 1), () -> {});
			g.matchSize();
			g.stack(10);
			g.x = x + (boxW - g.width) * 0.5;
			g.y = topY + 48;
		}

		var hint = new FlxText(24, FlxG.height - 26, FlxG.width - 48, "Tip: press any NAV input (arrows / dpad) to enter NAV mode.");
		hint.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(hint);
	}
}
