package flixel.ux;

// This module intentionally combines:
// - FlxUX9Slice (the data)
// - FlxUX9SliceRender (9-slice renderer/cache + graphic input resolver)
// so there are fewer files.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Simple 9-slice description.
 *
 * Provide a source graphic and slice sizes. FlxUX will render it to requested sizes internally (cached).
 */
class FlxUX9Slice
{
	// ---------------------------------------------------------------------------------------------
	// Cache + helpers (KISS: single type to remember)
	// ---------------------------------------------------------------------------------------------
	static var _cache:Map<String, FlxGraphic> = new Map();

	/** Clears the internal 9-slice cache. */
	public static function clearCache():Void
	{
		_cache = new Map();
	}

	/**
	 * Renders (and caches) a 9-slice into a `FlxGraphic` of the requested size.
	 */
	public static function get(nine:FlxUX9Slice, targetW:Int, targetH:Int, ?frameIndex:Int = 0):FlxGraphic
	{
		if (nine == null) return null;
		if (targetW < 1) targetW = 1;
		if (targetH < 1) targetH = 1;

		var key = _makeKey(nine, targetW, targetH, frameIndex);
		if (_cache.exists(key))
			return _cache.get(key);

		var src = _resolveBitmapData(nine.source);
		if (src == null) return null;

		var frameW = (nine.frameWidth > 0) ? nine.frameWidth : src.width;
		var frameH = (nine.frameHeight > 0) ? nine.frameHeight : src.height;

		var srcRect = _frameRect(src, frameW, frameH, frameIndex);
		var out = new BitmapData(targetW, targetH, true, 0x00000000);

		_drawNineSlice(out, src, srcRect, nine.left, nine.top, nine.right, nine.bottom);

		var gfx = FlxGraphic.fromBitmapData(out, false, key);
		_cache.set(key, gfx);
		return gfx;
	}

	/**
	 * Converts Flixel-style "graphic input" to `FlxGraphic`.
	 */
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
		return FlxG.bitmap.add(input, false);
	}

	static function _makeKey(nine:FlxUX9Slice, w:Int, h:Int, frameIndex:Int):String
	{
		var assetKey = Std.string(nine.source);
		var fw = nine.frameWidth;
		var fh = nine.frameHeight;
		var l = nine.left;
		var t = nine.top;
		var r = nine.right;
		var b = nine.bottom;
		return 'ux9|' + assetKey + '|' + fw + 'x' + fh + '|f' + frameIndex + '|to' + w + 'x' + h + '|ns' + l + ',' + t + ',' + r + ',' + b;
	}

	@:allow(flixel.ux.FlxUXGroup)
	static function _resolveBitmapData(source:Dynamic):BitmapData
	{
		if (source == null) return null;
		if (Std.isOfType(source, BitmapData))
			return cast source;
		if (Std.isOfType(source, FlxGraphic))
		{
			var fg:FlxGraphic = cast source;
			return fg.bitmap;
		}
		if (Std.isOfType(source, FlxSprite))
		{
			var s:FlxSprite = cast source;
			return (s.graphic != null) ? s.graphic.bitmap : null;
		}
		var g = FlxG.bitmap.add(source, false);
		return (g != null) ? g.bitmap : null;
	}

	static function _frameRect(src:BitmapData, frameW:Int, frameH:Int, frameIndex:Int):Rectangle
	{
		if (frameW <= 0) frameW = src.width;
		if (frameH <= 0) frameH = src.height;
		var cols = Std.int(src.width / frameW);
		if (cols < 1) cols = 1;
		var x = (frameIndex % cols) * frameW;
		var y = Std.int(frameIndex / cols) * frameH;
		if (x + frameW > src.width) x = 0;
		if (y + frameH > src.height) y = 0;
		return new Rectangle(x, y, frameW, frameH);
	}

	static function _drawNineSlice(out:BitmapData, src:BitmapData, srcRect:Rectangle, left:Int, top:Int, right:Int, bottom:Int):Void
	{
		if (left < 0) left = 0;
		if (top < 0) top = 0;
		if (right < 0) right = 0;
		if (bottom < 0) bottom = 0;

		var sw = Std.int(srcRect.width);
		var sh = Std.int(srcRect.height);
		left = Std.int(Math.min(left, sw));
		right = Std.int(Math.min(right, sw - left));
		top = Std.int(Math.min(top, sh));
		bottom = Std.int(Math.min(bottom, sh - top));

		var dw = out.width;
		var dh = out.height;

		var centerSrcW = sw - left - right;
		var centerSrcH = sh - top - bottom;
		var centerDstW = Std.int(Math.max(0, dw - left - right));
		var centerDstH = Std.int(Math.max(0, dh - top - bottom));

		function blit(sx:Int, sy:Int, sW:Int, sH:Int, dx:Int, dy:Int, dW:Int, dH:Int):Void
		{
			if (sW <= 0 || sH <= 0 || dW <= 0 || dH <= 0) return;
			var rect = new Rectangle(srcRect.x + sx, srcRect.y + sy, sW, sH);
			var tmp = new BitmapData(sW, sH, true, 0x00000000);
			tmp.copyPixels(src, rect, new Point(0, 0));
			if (sW == dW && sH == dH)
			{
				out.copyPixels(tmp, tmp.rect, new Point(dx, dy), null, null, true);
			}
			else
			{
				var m = new Matrix();
				m.scale(dW / sW, dH / sH);
				m.translate(dx, dy);
				out.draw(tmp, m, null, null, null, true);
			}
			tmp.dispose();
		}

		blit(0, 0, left, top, 0, 0, left, top);
		blit(sw - right, 0, right, top, dw - right, 0, right, top);
		blit(0, sh - bottom, left, bottom, 0, dh - bottom, left, bottom);
		blit(sw - right, sh - bottom, right, bottom, dw - right, dh - bottom, right, bottom);

		blit(left, 0, centerSrcW, top, left, 0, centerDstW, top);
		blit(left, sh - bottom, centerSrcW, bottom, left, dh - bottom, centerDstW, bottom);
		blit(0, top, left, centerSrcH, 0, top, left, centerDstH);
		blit(sw - right, top, right, centerSrcH, dw - right, top, right, centerDstH);

		blit(left, top, centerSrcW, centerSrcH, left, top, centerDstW, centerDstH);
	}

	/** Source graphic input (String asset id/path, FlxGraphic, FlxSprite, BitmapData, etc). */
	public var source:Dynamic;

	/** Optional frame size if source is a spritesheet. */
	public var frameWidth:Int;
	public var frameHeight:Int;

	/** 9-slice borders. */
	public var left:Int;
	public var top:Int;
	public var right:Int;
	public var bottom:Int;

	public function new(source:Dynamic, frameWidth:Int, frameHeight:Int, left:Int, top:Int, right:Int, bottom:Int)
	{
		this.source = source;
		this.frameWidth = frameWidth;
		this.frameHeight = frameHeight;
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}
}

