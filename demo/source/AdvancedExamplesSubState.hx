package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.ux.FlxUXButton;
import flixel.ux.FlxUXGroup;

class AdvancedExamplesSubState extends FlxSubState
{
	var slideContainer:FlxSprite;
	var containerXTarget:Float;

	override public function create():Void
	{
		super.create();

		// Solid black background.
		add(DemoUi.makeSolidBackdrop());

		// A simple sliding container: everything in this substate sits to the right, then tweens in.
		slideContainer = new FlxSprite();
		slideContainer.scrollFactor.set();
		slideContainer.exists = false; // dummy anchor
		add(slideContainer);

		var back = DemoUi.addBackButton(this);
		back.x += FlxG.width; // start off-screen with the rest

		var header = DemoUi.makeHeader(
			"Advanced examples",
			"A few patterns you’ll probably use in real menus: mixed sizes, custom label formatting, and motion.");
		header.x += FlxG.width;
		add(header);

		// Example box
		var box = DemoUi.makeBox(24 + FlxG.width, 140, FlxG.width - 48, FlxG.height - 180, "Mixed sizes + custom label format");
		add(box.border);
		add(box.label);

		// This substate mostly shows that FlxUXGroup + FlxUXButton work fine while being moved/tweened.
		// It also demonstrates label overrides at the Core/Group/Button levels.
		var g = new FlxUXGroup();
		g.x = 40 + FlxG.width;
		g.y = 210;
		add(g);

		// Group-level label defaults (override FlxUXCore defaults for all buttons in this group)
		g.buttonLabelSize = 14;
		g.buttonLabelColor = 0xFF8EE6FF;

		var b1:FlxUXButton = g.addButton("Small", () -> {});
		b1.resize(160, 36);

		var b2:FlxUXButton = g.addButton("Default size (auto)", () -> {});

		var b3:FlxUXButton = g.addButton("Big action", () -> {});
		b3.resize(320, 48);
		// Button-level label overrides (override group/core for this button only)
		b3.buttonLabelSize = 18;
		b3.buttonLabelColor = FlxColor.WHITE;
		b3.applyLabelOptions();

		g.stack(10);

		// Slide everything in.
		FlxTween.tween(back, { x: back.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(header, { x: header.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(box.border, { x: box.border.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(box.label, { x: box.label.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
		FlxTween.tween(g, { x: g.x - FlxG.width }, 0.55, { ease: FlxEase.backOut });
	}

}
