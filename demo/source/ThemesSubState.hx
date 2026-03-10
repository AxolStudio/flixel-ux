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

	override public function create():Void
	{
		super.create();
		_themeBefore = FlxUXCore.theme;
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);

		header = DemoUi.makeHeader(
			"Themes (red / blue)",
			"This substate defines two JSON themes (red + blue) and swaps them at runtime using FlxUXCore.setTheme()."
		);
		add(header);

		info = new FlxText(24, 86, FlxG.width - 48, "");
		info.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(info);

		var boxTheme = DemoUi.makeBox(16, 120, 250, FlxG.height - 150, "Theme swap (global)");
		add(boxTheme.border);
		add(boxTheme.label);

		var boxOverrides = DemoUi.makeBox(16 + 250 + 12, 120, FlxG.width - 16 * 2 - 250 - 12, FlxG.height - 150, "Group-only themes");
		add(boxOverrides.border);
		add(boxOverrides.label);

		// Theme swap buttons.
		var gTheme = new FlxUXGroup();
		gTheme.x = boxTheme.border.x + 16;
		gTheme.y = boxTheme.border.y + 50;
		add(gTheme);

		gTheme.addButton("Apply BLUE theme", () -> applyBlueTheme());
		gTheme.addButton("Apply RED theme", () -> applyRedTheme());
		gTheme.addButton("Re-apply BLUE", () -> {
			// Convenience helper: parses JSON and activates it.
			FlxUXCore.loadThemeFromJsonString(themeBlueJson());
			onThemeApplied("BLUE (loadThemeFromJsonString)");
		});
		var jsonHint = new FlxText(gTheme.x, gTheme.y + 3 * (38 + 10) + 6, boxTheme.border.width - 32,
			"(Same as Apply BLUE, but via loadThemeFromJsonString)");
		jsonHint.setFormat(null, 10, 0xFFB9C0D0, LEFT);
		add(jsonHint);
		for (b in gTheme.getEligibleButtonsOrdered())
			b.resize(220, 38);
		gTheme.matchSize();
		gTheme.stack(10);

		// Right side: group-only themes (independent of global theme)
		var gRight = new FlxUXGroup();
		gRight.x = boxOverrides.border.x + 16;
		gRight.y = boxOverrides.border.y + 50;
		add(gRight);
		gRight.addButton("Group: default", () -> {
			gRight.setButtonSkin(FlxUXCore.DEFAULT_BUTTON_GRAPHIC, 0);
			gRight.buttonLabelColor = null;
			gRight.buttonLabelColorHover = null;
			gRight.buttonLabelColorDown = null;
			gRight.buttonLabelColorDisabled = null;
			gRight.refreshTheme();
		});
		gRight.addButton("Group: BLUE", () -> {
			gRight.setButtonSkin(new flixel.ux.FlxUX9Slice("assets/ux/button_blue.png", 0, 0, 16, 16, 3, 7), 0);
			gRight.buttonLabelColor = 0xFFEAF0FF;
			gRight.buttonLabelColorHover = 0xFFFFFFFF;
			gRight.buttonLabelColorDown = 0xFFFFFFFF;
			gRight.buttonLabelColorDisabled = 0xFF9AA4BF;
			gRight.refreshTheme();
		});
		gRight.addButton("Group: RED", () -> {
			gRight.setButtonSkin(new flixel.ux.FlxUX9Slice("assets/ux/button_red.png", 0, 0, 16, 16, 3, 7), 0);
			gRight.buttonLabelColor = 0xFFFFEFF2;
			gRight.buttonLabelColorHover = 0xFFFFFFFF;
			gRight.buttonLabelColorDown = 0xFFFFFFFF;
			gRight.buttonLabelColorDisabled = 0xFFC9A0A8;
			gRight.refreshTheme();
		});

		// Sample buttons affected by the group-only theme
		gRight.addButton("Sample A", () -> {});
		gRight.addButton("Sample B", () -> {});
		for (b in gRight.getEligibleButtonsOrdered())
			b.resize(180, 36);
		gRight.matchSize();
		gRight.stack(10);

		applyBlueTheme();
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

	function applyThemeJson(json:String, name:String):Void
	{
		// FlxUXCore.setTheme() applies the theme globally and refreshes existing FlxUX UI.
		FlxUXCore.setTheme(FlxUXTheme.fromObject(haxe.Json.parse(json)));
		onThemeApplied(name);
	}

	function applyBlueTheme():Void
	{
		applyThemeJson(themeBlueJson(), "BLUE");
	}

	function applyRedTheme():Void
	{
		applyThemeJson(themeRedJson(), "RED");
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
				+ '"left":16,"top":16,"right":3,"bottom":7'
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
				+ '"left":16,"top":16,"right":3,"bottom":7'
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
