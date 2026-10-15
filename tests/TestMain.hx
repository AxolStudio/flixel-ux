package;

import flixel.ux.FlxUX9Slice;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXCore.FlxUXFocusMode;
import flixel.ux.FlxUXTheme;
import flixel.ux.FlxUXShortcut;
import flixel.util.FlxColor;

@:access(flixel.ux.FlxUXCore)
@:access(flixel.ux.FlxUXButton)
@:access(flixel.FlxGame)
@:access(flixel.input.FlxKeyManager)
@:access(flixel.input.actions.FlxActionManager)
class TestMain
{
	static function main():Void
	{
		testObjectConstructor();
		testJsonConstructor();
		testFactoryMethods();
		testInvalidJsonDefaults();
		testDefaultAnimationSequences();
		testNamedColorParsing();
		testScrollThemeParsing();
		testShortcuts();
		testScrollbarMath();
		openfl.Lib.current.addChild(new flixel.FlxGame(800, 450, UXTestState, 60, 60, true));
	}

	static function testObjectConstructor():Void
	{
		var theme = new FlxUXTheme({
			buttonLabelSize: 20,
			buttonLabelColor: "#123456",
			focusMode: "OVERLAY",
			buttonGraphic: {
				source: "assets/ui/button.png",
				frameWidth: 16,
				frameHeight: 16,
				left: 3,
				top: 4,
				right: 3,
				bottom: 4
			}
		});

		assertEquals(20, theme.buttonLabelSize, "object label size");
		assertEquals(0xFF123456, theme.buttonLabelColor, "object label color");
		assertEquals(FlxUXFocusMode.OVERLAY, theme.focusMode, "object focus mode");
		assertTrue(Std.isOfType(theme.buttonGraphic, FlxUX9Slice), "object 9-slice graphic");
	}

	static function testJsonConstructor():Void
	{
		var theme = new FlxUXTheme('{"buttonLabelSize":22,"focusMode":"NEXT_TO","snapUiToPixels":false}');

		assertEquals(22, theme.buttonLabelSize, "JSON label size");
		assertEquals(FlxUXFocusMode.NEXT_TO, theme.focusMode, "JSON focus mode");
		assertEquals(false, theme.snapUiToPixels, "JSON boolean");
	}

	static function testFactoryMethods():Void
	{
		var objectTheme = FlxUXTheme.fromObject({buttonLabelSize: 18});
		var jsonTheme = FlxUXTheme.fromJson('{"buttonLabelSize":19}');

		assertEquals(18, objectTheme.buttonLabelSize, "fromObject label size");
		assertEquals(19, jsonTheme.buttonLabelSize, "fromJson label size");
	}

	static function testInvalidJsonDefaults():Void
	{
		var theme = new FlxUXTheme("not-json");
		assertEquals(14, theme.buttonLabelSize, "invalid JSON fallback");
	}

	static function testDefaultAnimationSequences():Void
	{
		assertEquals("0,1", FlxUXCore.DEFAULT_BUTTON_ANIM_UP.join(","), "default up animation");
		assertEquals("2,3,4,5", FlxUXCore.DEFAULT_BUTTON_ANIM_OVER.join(","), "default over animation");
		assertEquals("6,7,8,9", FlxUXCore.DEFAULT_BUTTON_ANIM_DOWN.join(","), "default down animation");
		assertEquals("10", FlxUXCore.DEFAULT_BUTTON_ANIM_DISABLED.join(","), "default disabled animation");
	}

	static function testNamedColorParsing():Void
	{
		var theme = new FlxUXTheme({buttonLabelColor: "blue"});
		var invalidTheme = new FlxUXTheme({buttonLabelColor: "not-a-color"});
		assertEquals(0xFF0000FF, theme.buttonLabelColor, "named FlxColor parsing");
		assertEquals(FlxColor.WHITE, invalidTheme.buttonLabelColor, "invalid color fallback");
	}

	static function testShortcuts():Void
	{
		var shortcut = new FlxUXShortcut("Ctrl+Shift+p");
		assertTrue(shortcut.valid, "shortcut parses");
		assertTrue(shortcut.matchesModifiers(true, true, false, false), "exact modifiers");
		assertEquals(false, shortcut.matchesModifiers(true, false, false, false), "missing modifier");
		assertEquals(false, new FlxUXShortcut("P").matchesModifiers(true, false, false, false), "extra modifier");
		assertEquals(false, new FlxUXShortcut("Bogus+P").valid, "invalid modifier");
		assertEquals(false, new FlxUXShortcut(null).valid, "null shortcut");
		assertEquals(false, new FlxUXShortcut("not-a-key").valid, "invalid key");
		assertTrue(new FlxUXShortcut("Shift+Tab").valid, "reverse traversal shortcut");
	}

	static function testScrollbarMath():Void
	{
		assertEquals(50.0, flixel.ux.FlxUXScrollBar.calculateThumbLength(100, 50, 100, 20), "proportional thumb");
		assertEquals(20.0, flixel.ux.FlxUXScrollBar.calculateThumbLength(100, 1, 1000, 20), "minimum thumb");
		assertEquals(100.0, flixel.ux.FlxUXScrollBar.calculateThumbLength(100, 100, 50, 20), "no overflow thumb");
		assertEquals(10.0, flixel.ux.FlxUXScrollBar.calculateThumbLength(10, 1, 1000, 20), "thumb cannot exceed track");
	}

	static function testScrollThemeParsing():Void
	{
		var objectTheme = new FlxUXTheme({
			scrollBarTrackGraphic: {
				source: "assets/ui/track.png",
				frameWidth: 8,
				frameHeight: 8,
				left: 2,
				top: 2,
				right: 2,
				bottom: 2
			},
			scrollBarThumbColor: "#66CCDD",
			scrollBarThickness: 18,
			scrollPanelBackgroundGraphic: "assets/ui/panel.png",
			scrollPanelBorderColor: "#AABBCC"
		});
		assertTrue(Std.isOfType(objectTheme.scrollBarTrackGraphic, FlxUX9Slice), "scrollbar graphic accepts nine-slice object");
		assertEquals(0xFF66CCDD, objectTheme.scrollBarThumbColor, "scrollbar color accepts string");
		assertEquals(18.0, objectTheme.scrollBarThickness, "scrollbar dimensions parse");
		assertEquals("assets/ui/panel.png", objectTheme.scrollPanelBackgroundGraphic, "scrollzone image parses");
		assertEquals(0xFFAABBCC, objectTheme.scrollPanelBorderColor, "scrollzone color parses");
		var jsonTheme = FlxUXTheme.fromJson('{"scrollBarArrowGraphic":"ui/arrows.png","scrollBarArrowFrameSize":12,"scrollBarShowButtons":false,"scrollPanelBackgroundColor":"#101820","scrollPanelFocusPadding":6}');
		assertEquals("ui/arrows.png", jsonTheme.scrollBarArrowGraphic, "arrow sheet JSON parses");
		assertEquals(12, jsonTheme.scrollBarArrowFrameSize, "arrow frame size JSON parses");
		assertEquals(false, jsonTheme.scrollBarShowButtons, "scrollbar button setting JSON parses");
		assertEquals(0xFF101820, jsonTheme.scrollPanelBackgroundColor, "scrollzone color JSON parses");
		assertEquals(6.0, jsonTheme.scrollPanelFocusPadding, "scrollzone behavior JSON parses");
	}

	public static function testNavigation():Void
	{
		var group = new flixel.ux.FlxUXGroup();
		flixel.FlxG.state.add(group);
		var first = group.addButton("First", () -> {});
		var skipped = group.addButton("Skip", () -> {});
		skipped.tabStop = false;
		var locked = group.addButton("Locked", () -> {});
		locked.locked = true;
		var second = group.addButton("Second", () -> {});
		second.resize(160, 48);
		group.defaultButton = second;
		second.status = flixel.ui.FlxButton.FlxButtonState.NORMAL;
		second.updateLabelPosition();
		var labelY = second.label.y;
		second.status = flixel.ui.FlxButton.FlxButtonState.PRESSED;
		assertEquals(labelY + 1, second.label.y, "pressed label shifts down one pixel");
		second.updateKeyboardCues();
		assertTrue(second.defaultIndicator.visible, "default button indicator is visible");
		assertEquals(FlxUXCore.buttonLabelColor, second.defaultIndicator.color, "default indicator matches label palette");
		group.defaultButton = null;
		var other = new flixel.ux.FlxUXGroup();
		flixel.FlxG.state.add(other);
		var third = other.addButton("Third", () -> {});
		group.addUXButton(first);
		FlxUXCore.addGroup(group);
		group.update(0);
		other.update(0);
		FlxUXCore.setFocused(null);
		FlxUXCore.traverseTab(true);
		assertEquals(third, FlxUXCore.focused, "reverse Tab starts at last");
		FlxUXCore.traverseTab();
		assertEquals(first, FlxUXCore.focused, "Tab wraps across groups");
		FlxUXCore.traverseTab();
		assertEquals(second, FlxUXCore.focused, "Tab skips non-stops and locked buttons");
		FlxUXCore.traverseTab();
		assertEquals(third, FlxUXCore.focused, "Tab visits each button once");
		FlxUXCore.setFocused(skipped);
		FlxUXCore.traverseTab();
		assertEquals(second, FlxUXCore.focused, "Tab continues after a clicked non-stop");
		other.modal = true;
		FlxUXCore.traverseTab();
		assertEquals(third, FlxUXCore.focused, "modal captures traversal");
		assertEquals(false, FlxUXCore.isGroupInputEligible(group), "modal blocks underlying group");
		other.modal = false;
		var cancellations = 0;
		third.action = () -> cancellations++;
		other.cancelButton = third;
		FlxUXCore.setFocused(null);
		FlxUXCore.cancel();
		assertEquals(1, cancellations, "cancel works without focus");
		third.locked = true;
		other.onCancel = () -> cancellations += 10;
		FlxUXCore.cancel();
		assertEquals(11, cancellations, "locked cancel falls back to callback");
		first.accessKey = "f";
		first.hotkey = "Ctrl+F";
		FlxUXCore.keyboardEnabled = false;
		first.updateKeyboardCues();
		assertEquals(false, first.keyboardCuesVisible, "disabled keyboard hides cues");
		assertEquals(false, first.shortcutLabel.visible, "disabled keyboard hides shortcut label");
		assertEquals(false, first.mnemonicUnderline.visible, "disabled keyboard hides mnemonic");
		FlxUXCore.keyboardEnabled = true;
		#if !FLX_NO_KEYBOARD
		flixel.FlxG.keys.enabled = false;
		first.updateKeyboardCues();
		assertEquals(false, first.keyboardCuesVisible, "disabled manager hides cues");
		flixel.FlxG.keys.enabled = true;
		#end
		assertTrue(first.label.scale.y > 1, "default bitmap label size is honored");
		group.removeButton(first);
		assertEquals(null, first.getUXGroup(), "removed button releases owner");
		first.destroy();
		flixel.FlxG.state.remove(group, true);
		flixel.FlxG.state.remove(other, true);
		group.destroy();
		other.destroy();
		testInputActions();
		testScrollPanel();
		trace("All FlxUX tests passed.");
		#if sys
		Sys.exit(0);
		#elseif js
		js.Syntax.code("window.__flxUXTestsPassed = true");
		#end
	}

	static function testInputActions():Void
	{
		#if !FLX_NO_KEYBOARD
		var menu = new flixel.ux.FlxUXGroup();
		flixel.FlxG.state.add(menu);
		var accepted = 0;
		var otherClicks = 0;
		var first = menu.addButton("Accept", () -> accepted++);
		var second = menu.addButton("Other", () -> otherClicks++);
		first.hotkey = "Ctrl+S";
		menu.defaultButton = first;
		FlxUXCore.pendingAutoReady = false;
		FlxUXCore.ready = true;
		FlxUXCore.lastScope = FlxUXCore.currentState();
		FlxUXCore.mode = NAV;
		FlxUXCore.setFocused(null);
		flixel.FlxG.keys.reset();
		flixel.FlxG.keys.update();
		function frame():Void
		{
			flixel.FlxG.game.ticks++;
			FlxUXCore.actions.manager.update();
			menu.update(0.016);
			FlxUXCore.internalUpdate(0.016);
			FlxUXCore.clearNavButtonsUpdatedThisFrame();
			flixel.FlxG.keys.update();
		}
		var enter = flixel.FlxG.keys.getKey(flixel.input.keyboard.FlxKey.ENTER);
		enter.press();
		frame();
		assertEquals(0, accepted, "confirm waits for release");
		enter.release();
		frame();
		assertEquals(1, accepted, "Enter activates default without focus");
		var space = flixel.FlxG.keys.getKey(flixel.input.keyboard.FlxKey.SPACE);
		space.press();
		frame();
		space.release();
		frame();
		assertEquals(1, accepted, "Space does not activate default without focus");
		var control = flixel.FlxG.keys.getKey(flixel.input.keyboard.FlxKey.CONTROL);
		var letter = flixel.FlxG.keys.getKey(flixel.input.keyboard.FlxKey.S);
		control.press();
		letter.press();
		frame();
		assertEquals(2, accepted, "shortcut activates once");
		assertEquals(false, FlxUXCore.actions.down.triggered, "Ctrl shortcut suppresses WASD");
		letter.release();
		control.release();
		frame();
		space.press();
		frame();
		FlxUXCore.setFocused(second);
		space.release();
		frame();
		assertEquals(0, otherClicks, "release cannot activate a different focused button");
		FlxUXCore.keyboardEnabled = false;
		control.press();
		letter.press();
		frame();
		assertEquals(2, accepted, "disabled keyboard blocks shortcut");
		letter.release();
		control.release();
		frame();
		FlxUXCore.keyboardEnabled = true;
		FlxUXCore.keyboardBindings.set("tabNext", ["N"]);
		FlxUXCore.rebindInputs();
		FlxUXCore.setFocused(first);
		var next = flixel.FlxG.keys.getKey(flixel.input.keyboard.FlxKey.N);
		next.press();
		frame();
		assertEquals(second, FlxUXCore.focused, "Tab traversal binding can be overridden");
		next.release();
		frame();
		FlxUXCore.keyboardBindings.remove("tabNext");
		FlxUXCore.rebindInputs();
		FlxUXCore.setFocused(first);
		var dialog = new flixel.ux.FlxUXGroup();
		flixel.FlxG.state.add(dialog);
		dialog.modal = true;
		var close = dialog.addButton("Close", () -> {});
		dialog.update(0);
		frame();
		FlxUXCore.setFocused(close);
		dialog.modal = false;
		frame();
		assertEquals(first, FlxUXCore.focused, "closing modal group restores focus");
		flixel.FlxG.state.remove(dialog, true);
		dialog.destroy();
		flixel.FlxG.state.remove(menu, true);
		menu.destroy();
		#end
	}

	static function testScrollPanel():Void
	{
		var cameraCount = flixel.FlxG.cameras.list.length;
		var previousTheme = FlxUXCore.theme;
		FlxUXCore.clearGroups();
		var panel = new flixel.ux.FlxUXScrollPanel(30, 40, 200, 160);
		flixel.FlxG.state.add(panel);
		var scrollTheme = new FlxUXTheme({
			scrollBarThickness: 16,
			scrollBarStep: 32,
			scrollPanelBackgroundColor: "#223344",
			scrollPanelBorderColor: "#AABBCC",
			scrollPanelBorderThickness: 2,
			scrollPanelFocusPadding: 5
		});
		FlxUXCore.theme = scrollTheme;
		assertEquals(16.0, panel.verticalBar.thickness, "existing scrollbar refreshes from theme");
		assertEquals(32.0, panel.verticalBar.step, "scroll step refreshes from theme");
		assertEquals(5.0, panel.focusPadding, "focus reveal padding refreshes from theme");
		assertEquals(0xFF223344, panel.background.color, "panel background refreshes from theme");
		assertEquals(0xFFAABBCC, panel.border.color, "panel border refreshes from theme");
		panel.backgroundColor = 0xFF010203;
		FlxUXCore.theme = new FlxUXTheme({scrollBarThickness: 18, scrollPanelBackgroundColor: "#334455"});
		assertEquals(18.0, panel.verticalBar.thickness, "scrollbar updates on a second theme change");
		assertEquals(0xFF010203, panel.background.color, "explicit panel color overrides theme");
		FlxUXCore.theme = previousTheme;
		panel.backgroundColor = null;
		panel.horizontalEnabled = true;
		panel.setContentSize(500, 600);
		assertTrue(panel.verticalBar.visible && panel.horizontalBar.visible, "both scrollbars visible");
		assertEquals(180.0, panel.viewportWidth, "vertical bar reserves viewport width");
		assertEquals(140.0, panel.viewportHeight, "horizontal bar reserves viewport height");
		panel.scrollTo(9999, 9999);
		assertEquals(320.0, panel.scrollX, "horizontal scroll clamps");
		assertEquals(460.0, panel.scrollY, "vertical scroll clamps");
		panel.scrollTo(-10, -20);
		assertEquals(0.0, panel.scrollX, "negative scroll clamps");
		var menu = new flixel.ux.FlxUXGroup();
		var button = menu.addButton("Far away", () -> {}, 350, 450);
		panel.addContent(menu);
		FlxUXCore.setFocused(button);
		assertTrue(panel.scrollX > 0 && panel.scrollY > 0, "focus reveals child");
		assertEquals(panel.viewportCamera, button.cameras[0], "child uses viewport camera");
		#if !FLX_NO_MOUSE
		var clippedClicks = 0;
		button.action = () -> clippedClicks++;
		flixel.FlxG.mouse.setRawPositionUnsafe(-100, -100);
		button.status = flixel.ui.FlxButton.FlxButtonState.PRESSED;
		button.onUpHandler();
		assertEquals(0, clippedClicks, "mouse-up outside viewport cannot activate child");
		#end
		panel.removeContent(menu);
		assertEquals(null, button.scrollPanel, "detached child releases panel");
		menu.destroy();
		panel.setContentSize(10, 10);
		assertEquals(false, panel.verticalBar.visible, "no overflow hides vertical bar");
		assertEquals(false, panel.horizontalBar.visible, "no overflow hides horizontal bar");
		assertEquals(0.0, panel.scrollY, "shrinking bounds clamps scroll");
		flixel.FlxG.state.remove(panel, true);
		panel.destroy();
		assertEquals(cameraCount, flixel.FlxG.cameras.list.length, "panel destroys owned camera");
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void
	{
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}

	static function assertTrue(value:Bool, label:String):Void
	{
		if (!value)
			throw '$label: expected true';
	}
}

class UXTestState extends flixel.FlxState
{
	override public function create():Void
	{
		super.create();
		TestMain.testNavigation();
	}
}
