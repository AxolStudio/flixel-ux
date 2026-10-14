package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ux.FlxUXButton;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;
import flixel.ux.FlxUXTheme;

class ThemesSubState extends FlxSubState
{
	private var info:FlxText;
	private var header:FlxText;
	private var themeBefore:FlxUXTheme;
	private var blueTheme:FlxUXTheme;
	private var redTheme:FlxUXTheme;
	private var groupOnly:FlxUXGroup;
	private var manualButton:FlxUXButton;
	private var manualGroup:FlxUXGroup;
	private var animExample:FlxUXButton;

	override public function create():Void
	{
		super.create();
		// Demo setup (visuals + theme objects used by the demo).
		themeBefore = FlxUXCore.theme;
		blueTheme = makeBlueTheme();
		redTheme = FlxUXTheme.fromJson(themeRedJson());
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);

		header = DemoUi.makeHeader(
			"Themes (red / blue)",
			"This substate demonstrates swapping FlxUXTheme objects at runtime and also loading themes from JSON."
		);
		add(header);

		info = new FlxText(24, 86, FlxG.width - 48, "");
		info.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(info);
		// End demo setup.

		var gap:Int = 12;
		var startX:Int = 16;
		// Make the section boxes a bit shorter so the header/info never crowd them.
		// Keep the boxes flush with the bottom of the screen.
		var bottomMargin:Int = 16;
		var boxBottom:Int = FlxG.height - bottomMargin;
		var bottomH:Int = FlxG.height - 180;
		var startY:Int = boxBottom - bottomH;
		var colW:Int = Std.int((FlxG.width - startX * 2 - gap * 2) / 3);

		// This screen demonstrates the 3 places you can apply style:
		// 1) Core (global): FlxUXCore.theme affects every group/button without overrides.
		// 2) A single group: group.theme affects only that one menu.
		// 3) Manual per-button overrides: no theme at all, just set button properties.

		var boxGlobal = DemoUi.makeBox(startX, startY, colW, bottomH, "Set theme globally");
		add(boxGlobal.border);
		add(boxGlobal.label);
		var globalGroup = new FlxUXGroup();
		globalGroup.x = boxGlobal.border.x + 16;
		globalGroup.y = boxGlobal.border.y + 50;
		add(globalGroup);
		globalGroup.addButton("Switch to Default", switchDefaultGlobally);
		globalGroup.addButton("Switch to Blue", switchBlueGlobally);
		globalGroup.addButton("Switch to Red", switchRedGlobally);
		// This group follows FlxUXCore.theme, so we don't set group.theme here.
		globalGroup.buttonUseAnim = null;
		globalGroup.buttonSkinFps = 0;
		for (b in globalGroup.getEligibleButtonsOrdered())
			b.resize(colW - 32, 38);
		globalGroup.stack(10);

		var boxGroup = DemoUi.makeBox(startX + colW + gap, startY, colW, bottomH, "Set THIS group only");
		add(boxGroup.border);
		add(boxGroup.label);
		groupOnly = new FlxUXGroup();
		groupOnly.x = boxGroup.border.x + 16;
		groupOnly.y = boxGroup.border.y + 50;
		add(groupOnly);
		groupOnly.addButton("Switch group to Default", switchDefaultGroup);
		groupOnly.addButton("Switch group to Blue", switchBlueGroup);
		groupOnly.addButton("Switch group to Red", switchRedGroup);
		// This column is about group theming, so we keep button skins static for consistency.
		groupOnly.buttonUseAnim = null;
		groupOnly.buttonSkinFps = 0;
		for (b in groupOnly.getEligibleButtonsOrdered())
			b.resize(colW - 32, 38);
		groupOnly.stack(10);

		var boxManual = DemoUi.makeBox(startX + (colW + gap) * 2, startY, colW, bottomH, "No theme (manual overrides)");
		add(boxManual.border);
		add(boxManual.label);
		manualGroup = new FlxUXGroup();
		manualGroup.x = boxManual.border.x + 16;
		manualGroup.y = boxManual.border.y + 50;
		add(manualGroup);
		// Ensure manual overrides stay readable and don't change on hover/press.
		manualGroup.buttonUseAnim = null;
		manualGroup.buttonSkinFps = 0;
		manualGroup.buttonLabelColorHover = null;
		manualGroup.buttonLabelColorDown = null;

		// Manual overrides can be great for one-off buttons.
		// Here are a few examples.

		// 1) Different label color (no action)
		manualButton = manualGroup.addButton("Custom label color", null);
		manualButton.buttonLabelColor = 0xFF1E7FA8;
		manualButton.buttonLabelColorHover = 0xFF1E7FA8;
		manualButton.buttonLabelColorDown = 0xFF1E7FA8;
		manualButton.applyLabelOptions();
		manualButton.resize(colW - 32, 38);

		// 2) Larger button
		var big = manualGroup.addButton("Larger button", null);
		big.resize(colW - 32, 54);

		// 3) Another property: left-aligned label
		var left = manualGroup.addButton("Left-aligned label", null);
		left.buttonLabelAlign = LEFT;
		left.applyLabelOptions();
		left.resize(colW - 32, 38);

		// 4) Animated button skin (demo-local spritesheet)
		//
		// This is the most common pattern for animation:
		// - Provide an animated spritesheet (a 9-slice sheet with multiple frames)
		// - Set an FPS > 0
		// - Provide frame sequences for each button state (up/over/down/disabled)
		//
		// Note: FlxUX doesn't ship a default animated button skin.
		// This example uses demo assets: demo/assets/ux/button_anim.png.
		animExample = manualGroup.addButton("Animated skin", null);
		animExample.setButtonSkin(new flixel.ux.FlxUX9Slice("assets/ux/button_anim.png", 16, 16, 3, 7, 3, 7), 18);
		animExample.buttonUseAnim = true;
		animExample.setButtonAnimSequences(
			[0, 1],
			[2, 3],
			[4, 5],
			[6]
		);
		animExample.resize(colW - 32, 38);

		manualGroup.stack(10);

		switchDefaultGlobally();
	}

	override public function close():Void
	{
		FlxUXCore.theme = themeBefore;
		super.close();
	}

	private function setInfo(text:String):Void
	{
		info.text = text;
	}

	private function switchDefaultGlobally():Void
	{
		// Global theme: affects every FlxUXGroup / FlxUXButton that doesn't have overrides.
		FlxUXCore.theme = new FlxUXTheme();
		keepCoreButtonsStatic();
		setInfo("GLOBAL THEME\nFlxUXCore.theme = new FlxUXTheme();");
	}

	private function switchBlueGlobally():Void
	{
		// Global theme can be any FlxUXTheme object.
		FlxUXCore.theme = blueTheme;
		keepCoreButtonsStatic();
		setInfo("GLOBAL THEME\nFlxUXCore.theme = blueTheme;\n(blueTheme is created in code)");
	}

	private function switchRedGlobally():Void
	{
		// JSON themes go through FlxUXTheme.fromJson(...) first.
		FlxUXCore.theme = redTheme;
		keepCoreButtonsStatic();
		setInfo("GLOBAL THEME\nFlxUXCore.theme = redTheme;\n(redTheme was loaded from JSON)");
	}

	private function keepCoreButtonsStatic():Void
	{
		// This demo screen is about theme objects and override precedence.
		// The animated button example is configured manually in the right column.
		FlxUXCore.buttonUseAnim = false;
		FlxUXCore.buttonSkinFps = 0;
	}

	private function switchDefaultGroup():Void
	{
		// Group theme: only affects buttons inside this group.
		// Setting to null clears group overrides so it follows FlxUXCore again.
		groupOnly.theme = null;
		setInfo("GROUP THEME\ngroupOnly.theme = null;\n(group follows FlxUXCore.theme again)");
	}

	private function switchBlueGroup():Void
	{
		// This group now uses blueTheme, even if the global theme is red/default.
		groupOnly.theme = blueTheme;
		groupOnly.buttonUseAnim = false;
		groupOnly.buttonSkinFps = 0;
		setInfo("GROUP THEME\ngroupOnly.theme = blueTheme;");
	}

	private function switchRedGroup():Void
	{
		// This group now uses redTheme, even if the global theme is blue/default.
		groupOnly.theme = redTheme;
		groupOnly.buttonUseAnim = false;
		groupOnly.buttonSkinFps = 0;
		setInfo("GROUP THEME\ngroupOnly.theme = redTheme;");
	}

	function makeBlueTheme():FlxUXTheme
	{
		var t = new FlxUXTheme();
		t.pixelArtDefaults = true;
		t.snapUiToPixels = true;
		t.buttonUseAnim = false;
		t.buttonSkinFps = 0;
		// Button skin (9-slice spritesheet: 16x16 frames, 3/7 borders)
		t.buttonGraphic = new flixel.ux.FlxUX9Slice("assets/ux/button_blue.png", 16, 16, 3, 7, 3, 7);
		// Label styling
		t.buttonLabelSize = 14;
		t.buttonLabelColor = 0xFFEAF0FF;
		t.buttonLabelColorHover = 0xFFFFFFFF;
		t.buttonLabelColorDown = 0xFFFFFFFF;
		t.buttonLabelColorDisabled = 0xFF9AA4BF;
		// Focus visuals
		t.focusMode = FRAME;
		t.focusFrameFps = 6;
		t.focusFrameGraphic = new flixel.ux.FlxUX9Slice("assets/ux/highlight_frame_9s_anim_blue.png", 40, 40, 14, 17, 15, 18);
		t.focusNextToGraphic = "assets/ux/highlight_next_to_blue.png";
		t.focusOverlayGraphic = "assets/ux/highlight_on_blue.png";
		return t;
	}

	private static function themeRedJson():String
	{
		return '{'
			+ '"pixelArtDefaults":true,'
			+ '"snapUiToPixels":true,'
			+ '"buttonUseAnim":false,'
			+ '"buttonSkinFps":0,' // Button skin (9-slice)
			+ '"buttonGraphic":{'
			+ '"source":"assets/ux/button_red.png",'
			+ '"frameWidth":16,"frameHeight":16,'
			+ '"left":3,"top":7,"right":3,"bottom":7'
			+ '},' // Focus visuals
			+ '"focusMode":"FRAME",'
			+ '"focusFrameFps":6,'
			+ '"focusFrameGraphic":{'
			+ '"source":"assets/ux/highlight_frame_9s_anim_red.png",'
			+ '"frameWidth":40,"frameHeight":40,'
			+ '"left":14,"top":17,"right":15,"bottom":18'
			+ '},'
			+ '"focusNextToGraphic":"assets/ux/highlight_next_to_red.png",'
			+ '"focusOverlayGraphic":"assets/ux/highlight_on_red.png",' // Label styling
			+ '"buttonLabelSize":14,'
			+ '"buttonLabelColor":"#FFEFF2",'
			+ '"buttonLabelColorHover":"#FFFFFF",'
			+ '"buttonLabelColorDown":"#FFFFFF",'
			+ '"buttonLabelColorDisabled":"#C9A0A8"'
			+ '}';
	}
}
