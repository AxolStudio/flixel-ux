package;

import demo.DemoUi;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;

class KeyboardExamplesSubState extends FlxSubState
{
	private var status:FlxText;
	private var keyboardBefore:Bool;
	private var notes:FlxText;

	override public function create():Void
	{
		super.create();
		keyboardBefore = FlxUXCore.keyboardEnabled;
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);
		add(DemoUi.makeHeader("Keyboard + actions", "Tab order, access keys, shortcuts, and default/cancel buttons."));
		status = new FlxText(32, 100, 736, "Ready");
		status.setFormat(null, 16, 0xFFFFFFFF);
		add(status);
		var actions = new FlxUXGroup();
		add(actions);
		var print = actions.addButton("Print", () -> status.text = "Print activated");
		print.hotkey = "Ctrl+P";
		print.accessKey = "p";
		print.resize(320, 54);
		var skipped = actions.addButton("Skipped by Tab", () -> status.text = "Pointer / arrows still work");
		skipped.tabStop = false;
		skipped.resize(320, 54);
		var accept = actions.addButton("Accept", () -> status.text = "Accepted");
		accept.accessKey = "a";
		accept.resize(320, 54);
		var cancel = actions.addButton("Cancel", () -> status.text = "Cancelled");
		cancel.accessKey = "c";
		cancel.resize(320, 54);
		actions.defaultButton = accept;
		actions.cancelButton = cancel;
		actions.stack(12);
		actions.x = 32;
		actions.y = 146;
		var toggle = actions.addButton("Keyboard: on", null, 380, 0);
		toggle.action = () ->
		{
			FlxUXCore.keyboardEnabled = !FlxUXCore.keyboardEnabled;
			toggle.text = FlxUXCore.keyboardEnabled ? "Keyboard: on" : "Keyboard: off";
		};
		toggle.resize(340, 48);
		actions.addButton("Clear focus", () ->
		{
			FlxUXCore.mode = NAV;
			FlxUXCore.setFocused(null);
		}, 380, 62).resize(340, 48);
		notes = new FlxText(412, 286, 340, "Print: Ctrl+P / Alt+P\nEnter: focused or default\nEscape: cancel\nSpace: focused only");
		notes.setFormat(null, 16, 0xFFE2E7ED);
		add(notes);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		notes.visible = FlxUXCore.isKeyboardEnabled();
	}

	override public function close():Void
	{
		FlxUXCore.keyboardEnabled = keyboardBefore;
		super.close();
	}
}