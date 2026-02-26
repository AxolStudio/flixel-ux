package flixel.ux;

import flixel.util.FlxColor;
import flixel.ux.FlxUXGraphicSpec;

/**
 * Asset/theme configuration for FlxUX widgets.
 *
 * This is intentionally simple and Flixel-native:
 * - Button visuals are controlled via `FlxButton.loadGraphic()`.
 * - Focus visuals are controlled by a small set of built-in modes.
 *
 * Precedence (high -> low):
 * - button.assets
 * - group.assets
 * - FlxUXCore.assets
 */
class FlxUXAssets
{
	/** Visual skin for the button itself. */
	public var buttonSkin:FlxUXGraphicSpec = null;

	/** Visual used for FRAME focus style. */
	public var focusFrame:FlxUXGraphicSpec = null;

	/** Visual used for SPRITE_NEXT_TO_BUTTON focus style. */
	public var focusSide:FlxUXSideSpriteSpec = null;

	/** Visual used for SPRITE_ON_BUTTON focus style. */
	public var focusOverlay:FlxUXOverlaySpriteSpec = null;

	/** Optional bitmap font asset id/path (intended for FlxBitmapText/FlxBitmapFont usage). */
	public var bitmapFont:FlxUXBitmapFontSpec = null;

	/** How to show focus when in NAV mode. */
	public var focusStyle:FlxUXFocusStyle = FlxUXFocusStyle.HOVER_ONLY;

	/** Used by some focus styles (like FRAME). */
	public var focusColor:FlxColor = 0xFFFFFFFF;

	/** Used by some focus styles (like FRAME). */
	public var focusFrameThickness:Int = 2;

	/** Fallback alpha for unfocused buttons when using focus styles that dim. */
	public var unfocusedAlpha:Float = 0.9;

	public function new() {}

	public function clone():FlxUXAssets
	{
		var a = new FlxUXAssets();
		a.buttonSkin = buttonSkin;
		a.focusFrame = focusFrame;
		a.focusSide = focusSide;
		a.focusOverlay = focusOverlay;
		a.bitmapFont = bitmapFont;
		a.focusStyle = focusStyle;
		a.focusColor = focusColor;
		a.focusFrameThickness = focusFrameThickness;
		a.unfocusedAlpha = unfocusedAlpha;
		return a;
	}
}

/**
 * Focus indicator strategies.
 */
enum FlxUXFocusStyle
{
	/** No extra visuals; only use the normal FlxButton hover/pressed states. */
	HOVER_ONLY;

	/** Dims unfocused buttons by adjusting alpha. */
	DIM_UNFOCUSED;

	/** Draws a colored rectangle "frame" around the button (using `makeGraphic`). */
	FRAME;

	/** Placeholder for future: show a sprite layered on the button. */
	SPRITE_ON_BUTTON;

	/** Placeholder for future: show a sprite next to the button. */
	SPRITE_NEXT_TO_BUTTON;
}
