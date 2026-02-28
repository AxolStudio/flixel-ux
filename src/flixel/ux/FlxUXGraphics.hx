package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

/**
 * Internal helpers for accepting "graphic input" in a Flixel-friendly way.
 *
 * Supported inputs (best effort):
 * - String asset id/path
 * - FlxGraphic
 * - FlxSprite (uses its existing graphic/bitmap)
 * - BitmapData
 */
class FlxUXGraphics
{
	public static function toGraphic(input:Dynamic):FlxGraphic
	{
		if (input == null) return null;
		if (Std.isOfType(input, FlxGraphic)) return cast input;
		if (Std.isOfType(input, FlxSprite))
		{
			var s:FlxSprite = cast input;
			return s.graphic;
		}
		if (Std.isOfType(input, BitmapData))
		{
			var bd:BitmapData = cast input;
			return FlxGraphic.fromBitmapData(bd);
		}

		// String asset id/path or other FlxG.bitmap-resolvable value.
		return FlxG.bitmap.add(input, false);
	}
}
