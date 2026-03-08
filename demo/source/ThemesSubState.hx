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

	override public function create():Void
	{
		super.create();
		add(DemoUi.makeSolidBackdrop());
		DemoUi.addBackButton(this);

		add(DemoUi.makeHeader(
			"Themes + overrides",
			"Theme values apply globally, but groups/buttons can override them. This demo swaps between two themes at runtime.")
		);

		info = new FlxText(24, 86, FlxG.width - 48, "");
		info.setFormat(null, 12, 0xFFB9C0D0, LEFT);
		add(info);

		var boxTheme = DemoUi.makeBox(24, 130, 520, FlxG.height - 170, "Theme swap (global)");
		add(boxTheme.border);
		add(boxTheme.label);

		var boxOverrides = DemoUi.makeBox(24 + 520 + 16, 130, FlxG.width - 24 * 2 - 520 - 16, FlxG.height - 170, "Overrides (group + button)");
		add(boxOverrides.border);
		add(boxOverrides.label);

		// Global theme swap group
		var gTheme = new FlxUXGroup();
		gTheme.x = 44;
		gTheme.y = 200;
		add(gTheme);

		gTheme.addButton("Apply Theme A", () -> applyThemeA());
		gTheme.addButton("Apply Theme B", () -> applyThemeB());
		gTheme.addButton("Reload from JSON (Theme A)", () -> FlxUXCore.loadThemeFromJsonString(themeAJson()));
		gTheme.matchSize();
		gTheme.stack(12);

		// Overrides group: shows that group overrides win over core/theme
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

		applyThemeA();
	}

	function applyThemeA():Void
	{
		FlxUXCore.setTheme(FlxUXTheme.fromObject(haxe.Json.parse(themeAJson())));
		info.text = "Active theme: A (loaded via JSON string)";
	}

	function applyThemeB():Void
	{
		FlxUXCore.setTheme(FlxUXTheme.fromObject(haxe.Json.parse(themeBJson())));
		info.text = "Active theme: B (loaded via JSON string)";
	}

	static function themeAJson():String
	{
		return '{'
			+ '"uiAssetVariant":"_blue",'
			+ '"buttonUseAnim":false,'
			+ '"buttonSkinFps":0,'
			+ '"buttonLabelSize":14,'
			+ '"buttonLabelColor":"#E7EAF2"'
			+ '}';
	}

	static function themeBJson():String
	{
		return '{'
			+ '"uiAssetVariant":"_red",'
			+ '"buttonUseAnim":false,'
			+ '"buttonSkinFps":0,'
			+ '"buttonLabelSize":14,'
			+ '"buttonLabelColor":"#B9C0D0"'
			+ '}';
	}
}
