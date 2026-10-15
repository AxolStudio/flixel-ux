package;

import demo.DemoUi;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXCore.FlxUXNavStyle;
import flixel.ux.FlxUXGroup;
import flixel.ux.FlxUXScrollPanel;

class ScrollingSubState extends FlxSubState
{
	private var status:FlxText;
	private var notes:FlxText;

	override public function create():Void
	{
		super.create();
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);
		add(DemoUi.makeHeader("Scrolling", "Inventory-style content with proportional scrollbars and focus reveal."));
		status = new FlxText(24, 90, 750, "Inventory");
		status.setFormat(null, 16, 0xFFFFFFFF);
		add(status);
		var panel = new FlxUXScrollPanel(24, 130, 484, 286);
		panel.horizontalEnabled = true;
		add(panel);
		var inventory = new FlxUXGroup();
		inventory.navStyle = FlxUXNavStyle.SPATIAL;
		var names = ["Potion", "Shield", "Bow", "Boots", "Crystal", "Map"];
		for (index in 0...36)
		{
			var name = names[index % names.length] + " " + (index + 1);
			inventory.addButton(name, () -> status.text = name).resize(186, 44);
		}
		inventory.grid(3, 16, 12);
		inventory.x = 16;
		inventory.y = 16;
		panel.addContent(inventory);
		panel.addContent(new FlxSprite(16, 698).makeGraphic(590, 8, 0xFFB6DFB3));
		var controls = new FlxUXGroup();
		add(controls);
		controls.addButton("Top", () -> panel.scrollTo(0, 0)).resize(230, 44);
		controls.addButton("Both axes", () ->
		{
			panel.horizontalEnabled = !panel.horizontalEnabled;
			panel.refresh();
		}).resize(230, 44);
		controls.addButton("Arrow buttons", () ->
		{
			panel.verticalBar.showButtons = !panel.verticalBar.showButtons;
			panel.horizontalBar.showButtons = panel.verticalBar.showButtons;
		}).resize(230, 44);
		controls.stack(16);
		controls.x = 546;
		controls.y = 146;
		notes = new FlxText(546, 340, 230, "");
		notes.setFormat(null, 14, 0xFFE2E7ED);
		add(notes);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var inputs:Array<String> = [];
		#if !FLX_NO_MOUSE
		if (FlxG.mouse.enabled) inputs.push(FlxUXCore.isKeyboardEnabled() ? "Wheel / Shift+wheel" : "Mouse wheel");
		#end
		if (FlxUXCore.isKeyboardEnabled())
		{
			inputs.push("Page Up / Page Down");
			inputs.push("Tab / arrows");
		}
		#if !FLX_NO_GAMEPAD
		if (FlxG.gamepads.numActiveGamepads > 0) inputs.push("Gamepad navigation");
		#end
		notes.text = inputs.join("\n");
	}
}