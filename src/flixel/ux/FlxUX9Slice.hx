package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.ux.FlxUXCore.FlxUXGraphicInput;

/**
 * Simple 9-slice description.
 *
 * Provide a source graphic and slice sizes. FlxUX will render it to requested sizes internally (cached).
 */
class FlxUX9Slice
{
	/** Source graphic input (String asset id/path, FlxGraphic, FlxSprite, BitmapData, etc). */
	public var source:FlxUXGraphicInput;

	/** Optional frame size if source is a spritesheet. */
	public var frameWidth:Int;
	public var frameHeight:Int;

	/** 9-slice borders. */
	public var left:Int;
	public var top:Int;
	public var right:Int;
	public var bottom:Int;
	private static var cache:Map<String, FlxGraphic> = new Map();

	/** Clears the internal 9-slice cache. */
	public static function clearCache():Void
	{
		cache = new Map();
	}

	/**
	 * Renders (and caches) a 9-slice into a `FlxGraphic` of the requested size.
	 */
	public static function get(nine:FlxUX9Slice, targetW:Int, targetH:Int, ?frameIndex:Int = 0):FlxGraphic
	{
		if (nine == null) return null;
		if (targetW < 1) targetW = 1;
		if (targetH < 1) targetH = 1;

		var key:String = makeKey(nine, targetW, targetH, frameIndex);
		if (cache.exists(key))
			return cache.get(key);

		var src:BitmapData = resolveBitmapData(nine.source);
		if (src == null) return null;

		var frameW:Int = (nine.frameWidth > 0) ? nine.frameWidth : src.width;
		var frameH:Int = (nine.frameHeight > 0) ? nine.frameHeight : src.height;

		var srcRect:Rectangle = frameRect(src, frameW, frameH, frameIndex);
		var out:BitmapData = new BitmapData(targetW, targetH, true, 0x00000000);

		drawNineSlice(out, src, srcRect, nine.left, nine.top, nine.right, nine.bottom);
		var gfx:FlxGraphic = FlxGraphic.fromBitmapData(out);
		// These rendered graphics are cached and reused; prevent Flixel from GC'ing them.
		gfx.persist = true;
		gfx.destroyOnNoUse = false;
		cache.set(key, gfx);
		return gfx;
	}

	/**
	 * Converts Flixel-style "graphic input" to `FlxGraphic`.
	 */
	public static function toGraphic(input:FlxUXGraphicInput):FlxGraphic
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
			var g:FlxGraphic = FlxGraphic.fromBitmapData(bd);
			g.persist = true;
			g.destroyOnNoUse = false;
			return g;
		}
		if (Std.isOfType(input, String))
		{
			return FlxG.bitmap.add(cast(input, String), false);
		}
		return null;
	}

	private static function makeKey(nine:FlxUX9Slice, w:Int, h:Int, frameIndex:Int):String
	{
		var assetKey:String = Std.string(nine.source);
		var fw:Int = nine.frameWidth;
		var fh:Int = nine.frameHeight;
		var l:Int = nine.left;
		var t:Int = nine.top;
		var r:Int = nine.right;
		var b:Int = nine.bottom;
		return 'ux9|' + assetKey + '|' + fw + 'x' + fh + '|f' + frameIndex + '|to' + w + 'x' + h + '|ns' + l + ',' + t + ',' + r + ',' + b;
	}

	@:allow(flixel.ux.FlxUXGroup)
	private static function resolveBitmapData(source:FlxUXGraphicInput):BitmapData
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
		if (Std.isOfType(source, String))
		{
			var g = FlxG.bitmap.add(cast(source, String), false);
			return (g != null) ? g.bitmap : null;
		}
		return null;
	}

	private static function frameRect(src:BitmapData, frameW:Int, frameH:Int, frameIndex:Int):Rectangle
	{
		if (frameW <= 0) frameW = src.width;
		if (frameH <= 0) frameH = src.height;
		var cols:Int = Std.int(src.width / frameW);
		if (cols < 1) cols = 1;
		var x:Int = (frameIndex % cols) * frameW;
		var y:Int = Std.int(frameIndex / cols) * frameH;
		if (x + frameW > src.width) x = 0;
		if (y + frameH > src.height) y = 0;
		return new Rectangle(x, y, frameW, frameH);
	}

	private static function drawNineSlice(out:BitmapData, src:BitmapData, srcRect:Rectangle, left:Int, top:Int, right:Int, bottom:Int):Void
	{
		if (left < 0) left = 0;
		if (top < 0) top = 0;
		if (right < 0) right = 0;
		if (bottom < 0) bottom = 0;

		var sw:Int = Std.int(srcRect.width);
		var sh:Int = Std.int(srcRect.height);
		left = Std.int(Math.min(left, sw));
		right = Std.int(Math.min(right, sw - left));
		top = Std.int(Math.min(top, sh));
		bottom = Std.int(Math.min(bottom, sh - top));

		var dw:Int = out.width;
		var dh:Int = out.height;

		var centerSrcW:Int = sw - left - right;
		var centerSrcH:Int = sh - top - bottom;
		var centerDstW:Int = Std.int(Math.max(0, dw - left - right));
		var centerDstH:Int = Std.int(Math.max(0, dh - top - bottom));

		// Nearest-neighbor scaling for pixel art.
		function blitNearest(sx:Int, sy:Int, sW:Int, sH:Int, dx:Int, dy:Int, dW:Int, dH:Int):Void
		{
			if (sW <= 0 || sH <= 0 || dW <= 0 || dH <= 0) return;
			var rect:Rectangle = new Rectangle(srcRect.x + sx, srcRect.y + sy, sW, sH);
			if (sW == dW && sH == dH)
			{
				out.copyPixels(src, rect, new Point(dx, dy), null, null, true);
				return;
			}

			// Scale using nearest-neighbor by copying 1x1 pixels.
			var sx0:Int = Std.int(rect.x);
			var sy0:Int = Std.int(rect.y);
			var scaleX:Float = sW / dW;
			var scaleY:Float = sH / dH;
			var p:Point = new Point();
			var pixelRect:Rectangle = new Rectangle(0, 0, 1, 1);
			for (yy in 0...dH)
			{
				var srcY:Int = sy0 + Std.int(yy * scaleY);
				if (srcY < sy0) srcY = sy0;
				if (srcY >= sy0 + sH) srcY = sy0 + sH - 1;
				pixelRect.y = srcY;
				p.y = dy + yy;
				for (xx in 0...dW)
				{
					var srcX:Int = sx0 + Std.int(xx * scaleX);
					if (srcX < sx0) srcX = sx0;
					if (srcX >= sx0 + sW) srcX = sx0 + sW - 1;
					pixelRect.x = srcX;
					p.x = dx + xx;
					out.copyPixels(src, pixelRect, p, null, null, true);
				}
			}
		}

		blitNearest(0, 0, left, top, 0, 0, left, top);
		blitNearest(sw - right, 0, right, top, dw - right, 0, right, top);
		blitNearest(0, sh - bottom, left, bottom, 0, dh - bottom, left, bottom);
		blitNearest(sw - right, sh - bottom, right, bottom, dw - right, dh - bottom, right, bottom);

		blitNearest(left, 0, centerSrcW, top, left, 0, centerDstW, top);
		blitNearest(left, sh - bottom, centerSrcW, bottom, left, dh - bottom, centerDstW, bottom);
		blitNearest(0, top, left, centerSrcH, 0, top, left, centerDstH);
		blitNearest(sw - right, top, right, centerSrcH, dw - right, top, right, centerDstH);

		blitNearest(left, top, centerSrcW, centerSrcH, left, top, centerDstW, centerDstH);
	}

	public function new(source:FlxUXGraphicInput, frameWidth:Int, frameHeight:Int, left:Int, top:Int, right:Int, bottom:Int)
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

