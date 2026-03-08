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

	override public function create():Void
	{
		super.create();
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

		var boxTheme = DemoUi.makeBox(24, 130, 520, FlxG.height - 170, "Theme swap (global)");
		add(boxTheme.border);
		add(boxTheme.label);

		var boxOverrides = DemoUi.makeBox(24 + 520 + 16, 130, FlxG.width - 24 * 2 - 520 - 16, FlxG.height - 170, "Overrides (group + button)");
		add(boxOverrides.border);
		add(boxOverrides.label);

		// Theme swap buttons.
		var gTheme = new FlxUXGroup();
		gTheme.x = 44;
		gTheme.y = 200;
		add(gTheme);

		gTheme.addButton("Apply BLUE theme", () -> applyBlueTheme());
		gTheme.addButton("Apply RED theme", () -> applyRedTheme());
		gTheme.addButton("Re-apply BLUE (loadThemeFromJsonString)", () -> {
			// Convenience helper: parses JSON and activates it.
			FlxUXCore.loadThemeFromJsonString(themeBlueJson());
			onThemeApplied("BLUE (loadThemeFromJsonString)");
		});
		gTheme.matchSize();
		gTheme.stack(12);

		// Overrides demonstrate precedence: Core/theme -> group -> button.
		var gOverrides = new FlxUXGroup();
		gOverrides.x = boxOverrides.border.x + 20;
		gOverrides.y = 200;
		add(gOverrides);

		// Group-level label override
		gOverrides.buttonLabelSize = 18;
		gOverrides.buttonLabelColor = 0xFFFFD37D;

		var b1 = gOverrides.addButton("Group override", () -> {});
		var b2 = gOverrides.addButton("Button override", () -> {});
		// Per-button override wins
		b2.buttonLabelSize = 14;
		b2.buttonLabelColor = 0xFF8EE6FF;
		b2.applyLabelOptions();

		gOverrides.matchSize();
		gOverrides.stack(12);

		applyBlueTheme();
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
			+ '"buttonLabelColor":"#E7EAF2"'
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
			+ '"buttonLabelColor":"#FFE7EA"'
			+ '}';
	}
}
