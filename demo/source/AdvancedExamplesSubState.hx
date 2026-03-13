package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ux.FlxUXGroup;

class AdvancedExamplesSubState extends FlxSubState
{
	override public function create():Void
	{
		super.create();
		// This screen demonstrates a common “advanced menu” pattern:
		// 1) You have a group of buttons.
		// 2) You change the order of those buttons at runtime.
		// 3) You call a layout helper again (spread/stack/grid) to re-position them.
		//
		// The important idea: layout helpers operate on the group’s current button order.
		add(DemoUi.makeSolidBackdrop());

		var back = DemoUi.addBackButton(this);
		back.x += FlxG.width;

		var header = DemoUi.makeHeader(
			"Advanced examples",
			"A common menu pattern: reordering a list of buttons, then re-applying layout helpers.");
		header.x += FlxG.width;
		add(header);

		var box = DemoUi.makeBox(24 + FlxG.width, 140, FlxG.width - 48, FlxG.height - 180, "");
		add(box.border);
		// box.label intentionally unused on this screen.

		var contentTop = 168;
		var topRow = new FlxUXGroup();
		topRow.y = contentTop;
		add(topRow);
		// Create 5 buttons and add them to the same group.
		// These buttons will participate in NAV focus and also support the normal pointer clicks.

		for (t in ["1", "2", "3", "4", "5"])
		{
			var b = topRow.addButton(t, null);
			b.resize(80, 38);
		}
		// spread(gap) lays them out left-to-right with a consistent space between each.
		topRow.spread(12);
		// Start off-screen to the right so we can slide the whole group in.
		topRow.x = 24 + FlxG.width + (FlxG.width - 48 - topRow.width) * 0.5;

		var reverseBtnW = 340;
		var reverseBtn = new flixel.ux.FlxUXButton(24 + FlxG.width + (FlxG.width - 48 - reverseBtnW) * 0.5, contentTop + 58, "Reverse", () ->
		{
			// reverse() changes the group’s internal ordering.
			// Re-run spread() so the positions update to match the new order.
			topRow.reverse();
			topRow.spread(12);
			// After the slide-in, this re-centers the group on screen.
			topRow.x = 24 + (FlxG.width - 48 - topRow.width) * 0.5;
		});
		reverseBtn.resize(reverseBtnW, 40);
		add(reverseBtn);

		var enabledDisabled = new FlxUXGroup();
		var pairTotalW = 520;
		enabledDisabled.x = 24 + FlxG.width + (FlxG.width - 48 - pairTotalW) * 0.5;
		enabledDisabled.y = contentTop + 120;
		add(enabledDisabled);

		var enabledBtn = enabledDisabled.addButton("Enabled", null);
		var pairGap = 16;
		var pairBtnW = Std.int((pairTotalW - pairGap) / 2);
		enabledBtn.resize(pairBtnW, 40);
		var disabledBtn = enabledDisabled.addButton("Disabled", null);
		disabledBtn.resize(pairBtnW, 40);
		// locked = the 4th Flixel button state (disabled) but with FlxUX semantics:
		// it can’t be focused or activated, but it still updates normally.
		disabledBtn.locked = true;
		enabledDisabled.spread(pairGap);

		// Slide everything in from right to left.
		FlxTween.tween(back, { x: back.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(header, { x: header.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(box.border, { x: box.border.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(topRow, { x: topRow.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(reverseBtn, { x: reverseBtn.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(enabledDisabled, { x: enabledDisabled.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
	}

}
