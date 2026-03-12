package;

import demo.DemoUi;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ux.FlxUXButton;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;
import flixel.ux.FlxUXTheme;

class ThemesSubState extends FlxSubState
{
	var info:FlxText;
	var currentThemeName:String = "";
	var header:FlxText;
	var _themeBefore:FlxUXTheme;
	var _themeBlue:FlxUXTheme;
	var _themeRed:FlxUXTheme;
	var _themeDefault:FlxUXTheme;

	override public function create():Void
	{
		super.create();
		_themeBefore = FlxUXCore.theme;
		_themeDefault = new FlxUXTheme();
		_themeBlue = makeBlueTheme();
		_themeRed = makeRedTheme();
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

		var gap = 12;
		var startX = 16;
		var startY = 120;
		var bottomH = FlxG.height - 150;
		var colW = Std.int((FlxG.width - startX * 2 - gap * 2) / 3);

		// Column 1: Theme object swap (FlxUXTheme)
		var boxThemeObj = DemoUi.makeBox(startX, startY, colW, bottomH, "Change theme with FlxUXTheme");
		add(boxThemeObj.border);
		add(boxThemeObj.label);
		var gThemeObj = new FlxUXGroup();
		gThemeObj.x = boxThemeObj.border.x + 16;
		gThemeObj.y = boxThemeObj.border.y + 50;
		add(gThemeObj);
		gThemeObj.addButton("Default", () -> applyThemeObject(_themeDefault, "DEFAULT (object)"));
		gThemeObj.addButton("Blue", () -> applyThemeObject(_themeBlue, "BLUE (object)"));
		gThemeObj.addButton("Red", () -> applyThemeObject(_themeRed, "RED (object)"));
		for (b in gThemeObj.getEligibleButtonsOrdered()) b.resize(colW - 32, 38);
		gThemeObj.stack(10);

		// Column 2: Theme swap via JSON
		var boxThemeJson = DemoUi.makeBox(startX + colW + gap, startY, colW, bottomH, "Change theme with JSON");
		add(boxThemeJson.border);
		add(boxThemeJson.label);
		var gThemeJson = new FlxUXGroup();
		gThemeJson.x = boxThemeJson.border.x + 16;
		gThemeJson.y = boxThemeJson.border.y + 50;
		add(gThemeJson);
		gThemeJson.addButton("Default", () -> {
			FlxUXCore.loadThemeFromJsonString(themeDefaultJson());
			onThemeApplied("DEFAULT (JSON)");
		});
		gThemeJson.addButton("Blue", () -> {
			FlxUXCore.loadThemeFromJsonString(themeBlueJson());
			onThemeApplied("BLUE (JSON)");
		});
		gThemeJson.addButton("Red", () -> {
			FlxUXCore.loadThemeFromJsonString(themeRedJson());
			onThemeApplied("RED (JSON)");
		});
		for (b in gThemeJson.getEligibleButtonsOrdered()) b.resize(colW - 32, 38);
		gThemeJson.stack(10);

		// Column 3: Group-only overrides
		var boxGroupOnly = DemoUi.makeBox(startX + (colW + gap) * 2, startY, colW, bottomH, "Change only this group");
		add(boxGroupOnly.border);
		add(boxGroupOnly.label);
		var gGroupOnly = new FlxUXGroup();
		gGroupOnly.x = boxGroupOnly.border.x + 16;
		gGroupOnly.y = boxGroupOnly.border.y + 50;
		// Ensure this group never inherits animated-skin settings from the core theme.
		gGroupOnly.buttonUseAnim = false;
		gGroupOnly.buttonSkinFps = 0;
		add(gGroupOnly);

		gGroupOnly.addButton("Default", () -> {
			// IMPORTANT: When the core theme is DEFAULT, FlxUXCore.buttonUseAnim/buttonSkinFps
			// may be set such that the built-in default sheet becomes animated.
			// For the standalone override demo we want this group to remain stable and static.
			gGroupOnly.resetButtonSkin();
			gGroupOnly.useDefaultButtonSkinStatic();
			gGroupOnly.buttonLabelColor = null;
			gGroupOnly.buttonLabelColorHover = null;
			gGroupOnly.buttonLabelColorDown = null;
			gGroupOnly.buttonLabelColorDisabled = null;
			gGroupOnly.refreshTheme();
		});
		gGroupOnly.addButton("Blue", () -> {
			gGroupOnly.setButtonSkin(new flixel.ux.FlxUX9Slice("assets/ux/button_blue.png", 16, 16, 3, 7, 3, 7), 0);
			gGroupOnly.buttonUseAnim = false;
			gGroupOnly.buttonSkinFps = 0;
			gGroupOnly.buttonLabelColor = 0xFFEAF0FF;
			gGroupOnly.buttonLabelColorHover = 0xFFFFFFFF;
			gGroupOnly.buttonLabelColorDown = 0xFFFFFFFF;
			gGroupOnly.buttonLabelColorDisabled = 0xFF9AA4BF;
			gGroupOnly.refreshTheme();
		});
		gGroupOnly.addButton("Red", () -> {
			gGroupOnly.setButtonSkin(new flixel.ux.FlxUX9Slice("assets/ux/button_red.png", 16, 16, 3, 7, 3, 7), 0);
			gGroupOnly.buttonUseAnim = false;
			gGroupOnly.buttonSkinFps = 0;
			gGroupOnly.buttonLabelColor = 0xFFFFEFF2;
			gGroupOnly.buttonLabelColorHover = 0xFFFFFFFF;
			gGroupOnly.buttonLabelColorDown = 0xFFFFFFFF;
			gGroupOnly.buttonLabelColorDisabled = 0xFFC9A0A8;
			gGroupOnly.refreshTheme();
		});
		for (b in gGroupOnly.getEligibleButtonsOrdered()) b.resize(colW - 32, 38);
		gGroupOnly.stack(10);

		applyThemeObject(_themeDefault, "DEFAULT (object)");
	}

	override public function close():Void
	{
		// Restore whatever theme was active before entering this substate.
		FlxUXCore.setTheme(_themeBefore);
		super.close();
	}

	function onThemeApplied(name:String):Void
	{
		currentThemeName = name;
		info.text = "Active theme: " + currentThemeName + "\n"
			+ "- Theme-driven: button skins + label styling";
	}

	function applyThemeObject(theme:FlxUXTheme, name:String):Void
	{
		FlxUXCore.setTheme(theme);
		onThemeApplied(name);
	}

	function applyThemeJson(json:String, name:String):Void
	{
		// FlxUXCore.setTheme() applies the theme globally and refreshes existing FlxUX UI.
		FlxUXCore.setTheme(FlxUXTheme.fromObject(haxe.Json.parse(json)));
		onThemeApplied(name);
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

	function makeRedTheme():FlxUXTheme
	{
		var t = new FlxUXTheme();
		t.pixelArtDefaults = true;
		t.snapUiToPixels = true;
		t.buttonUseAnim = false;
		t.buttonSkinFps = 0;
		// Button skin (9-slice spritesheet: 16x16 frames, 3/7 borders)
		t.buttonGraphic = new flixel.ux.FlxUX9Slice("assets/ux/button_red.png", 16, 16, 3, 7, 3, 7);
		// Label styling
		t.buttonLabelSize = 14;
		t.buttonLabelColor = 0xFFFFEFF2;
		t.buttonLabelColorHover = 0xFFFFFFFF;
		t.buttonLabelColorDown = 0xFFFFFFFF;
		t.buttonLabelColorDisabled = 0xFFC9A0A8;
		// Focus visuals
		t.focusMode = FRAME;
		t.focusFrameFps = 6;
		t.focusFrameGraphic = new flixel.ux.FlxUX9Slice("assets/ux/highlight_frame_9s_anim_red.png", 40, 40, 14, 17, 15, 18);
		t.focusNextToGraphic = "assets/ux/highlight_next_to_red.png";
		t.focusOverlayGraphic = "assets/ux/highlight_on_red.png";
		return t;
	}

	// Default theme JSON (matches FlxUXTheme defaults)
	static function themeDefaultJson():String
	{
		return '{'
			+ '"pixelArtDefaults":true,'
			+ '"snapUiToPixels":true'
			+ '}';
	}

	// BLUE theme
	static function themeBlueJson():String
	{
		return '{'
			+ '"pixelArtDefaults":true,'
			+ '"snapUiToPixels":true,'
			+ '"buttonUseAnim":false,'
			+ '"buttonSkinFps":0,'
			// Button skin (9-slice)
			+ '"buttonGraphic":{'
				+ '"source":"assets/ux/button_blue.png",'
				+ '"frameWidth":16,"frameHeight":16,'
				+ '"left":3,"top":7,"right":3,"bottom":7'
			+ '},'
			// Focus visuals
			+ '"focusMode":"FRAME",'
			+ '"focusFrameFps":6,'
			+ '"focusFrameGraphic":{'
				+ '"source":"assets/ux/highlight_frame_9s_anim_blue.png",'
				+ '"left":40,"top":40,"right":14,"bottom":17,'
				+ '"frameWidth":15,"frameHeight":18'
			+ '},'
			+ '"focusNextToGraphic":"assets/ux/highlight_next_to_blue.png",'
			+ '"focusOverlayGraphic":"assets/ux/highlight_on_blue.png",'
			// Label styling
			+ '"buttonLabelSize":14,'
			+ '"buttonLabelColor":"#EAF0FF",'
			+ '"buttonLabelColorHover":"#FFFFFF",'
			+ '"buttonLabelColorDown":"#FFFFFF",'
			+ '"buttonLabelColorDisabled":"#9AA4BF"'
			+ '}';
	}

	// RED theme
	static function themeRedJson():String
	{
		return '{'
			+ '"pixelArtDefaults":true,'
			+ '"snapUiToPixels":true,'
			+ '"buttonUseAnim":false,'
			+ '"buttonSkinFps":0,'
			// Button skin (9-slice)
			+ '"buttonGraphic":{'
				+ '"source":"assets/ux/button_red.png",'
				+ '"frameWidth":16,"frameHeight":16,'
				+ '"left":3,"top":7,"right":3,"bottom":7'
			+ '},'
			// Focus visuals
			+ '"focusMode":"FRAME",'
			+ '"focusFrameFps":6,'
			+ '"focusFrameGraphic":{'
				+ '"source":"assets/ux/highlight_frame_9s_anim_red.png",'
				+ '"left":40,"top":40,"right":14,"bottom":17,'
				+ '"frameWidth":15,"frameHeight":18'
			+ '},'
			+ '"focusNextToGraphic":"assets/ux/highlight_next_to_red.png",'
			+ '"focusOverlayGraphic":"assets/ux/highlight_on_red.png",'
			// Label styling
			+ '"buttonLabelSize":14,'
			+ '"buttonLabelColor":"#FFEFF2",'
			+ '"buttonLabelColorHover":"#FFFFFF",'
			+ '"buttonLabelColorDown":"#FFFFFF",'
			+ '"buttonLabelColorDisabled":"#C9A0A8"'
			+ '}';
	}
}
