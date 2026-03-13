package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ux.FlxUXGroup;

class AdvancedExamplesSubState extends FlxSubState
{
	private var slideContainer:FlxSprite;
	private var containerXTarget:Float;

	override public function create():Void
	{
		super.create();
		/**
		 *  Demo setup - you can ignore this section
		 * =====================================================================
		 **/
		add(DemoUi.makeSolidBackdrop());

		slideContainer = new FlxSprite();
		slideContainer.scrollFactor.set();
		slideContainer.exists = false;
		add(slideContainer);

		var back = DemoUi.addBackButton(this);
		back.x += FlxG.width;

		var header = DemoUi.makeHeader(
			"Advanced examples",
			"A common menu pattern: reordering a list of buttons, then re-applying layout helpers.");
		header.x += FlxG.width;
		add(header);

		var box = DemoUi.makeBox(24 + FlxG.width, 140, FlxG.width - 48, FlxG.height - 180, "");
		add(box.border);
		/** 
		 * END OF DEMO SETUP
		 * =====================================================================
		 **/

		var contentTop = 168;
		var topRow = new FlxUXGroup();
		topRow.y = contentTop;
		add(topRow);

		for (t in ["1", "2", "3", "4", "5"])
		{
			var b = topRow.addButton(t, null);
			b.resize(80, 38);
		}
		topRow.spread(12);
		topRow.x = 24 + (FlxG.width - 48 - topRow.width) * 0.5;

		var reverseBtnW = 340;
		var reverseBtn = new flixel.ux.FlxUXButton(24 + FlxG.width + (FlxG.width - 48 - reverseBtnW) * 0.5, contentTop + 58, "Reverse", () ->
		{
			topRow.reverse();
			topRow.spread(12);
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
		disabledBtn.locked = true;
		enabledDisabled.spread(pairGap);

		// Slide everything in.
		FlxTween.tween(back, { x: back.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(header, { x: header.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(box.border, { x: box.border.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		// box.label intentionally not used on this screen.
		FlxTween.tween(topRow, { x: topRow.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(reverseBtn, { x: reverseBtn.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(enabledDisabled, { x: enabledDisabled.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
	}

}
