package flixel.ux;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Small cached 9-slice renderer.
 *
 * Key idea: never re-render per frame. Only build when (asset, frame, target size, slice) changes.
 *
 * NOTE: This currently operates on BitmapData and is target-agnostic.
 */
class FlxUXNineSliceCache
{
	static var _cache:Map<String, FlxGraphic> = new Map();

	public static function clear():Void
	{
		_cache = new Map();
	}

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

		// For now, frameIndex is ignored unless user provides a spritesheet and frame size.
		// We'll slice the requested cell from the spritesheet.
		var srcRect = _frameRect(src, frameW, frameH, frameIndex);
		var out = new BitmapData(targetW, targetH, true, 0x00000000);

		_drawNineSlice(out, src, srcRect, nine.left, nine.top, nine.right, nine.bottom);

		var gfx = FlxGraphic.fromBitmapData(out, false, key);
		_cache.set(key, gfx);
		return gfx;
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
		// Best effort resolution: accept BitmapData directly; otherwise try Flixel asset system.
		if (source == null) return null;
		if (Std.isOfType(source, BitmapData))
			return cast source;
		if (Std.isOfType(source, FlxGraphic))
		{
			var fg:FlxGraphic = cast source;
			return fg.bitmap;
		}
		if (Std.isOfType(source, flixel.FlxSprite))
		{
			var s:flixel.FlxSprite = cast source;
			return (s.graphic != null) ? s.graphic.bitmap : null;
		}

		// FlxG.bitmap can resolve string asset ids to BitmapData.
		var g = flixel.FlxG.bitmap.add(source, false);
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
		// clamp within
		if (x + frameW > src.width) x = 0;
		if (y + frameH > src.height) y = 0;
		return new Rectangle(x, y, frameW, frameH);
	}

	static function _drawNineSlice(out:BitmapData, src:BitmapData, srcRect:Rectangle, left:Int, top:Int, right:Int, bottom:Int):Void
	{
		// Clamp slice sizes.
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

		// Helper to copy or scale a region.
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

		// corners
		blit(0, 0, left, top, 0, 0, left, top);
		blit(sw - right, 0, right, top, dw - right, 0, right, top);
		blit(0, sh - bottom, left, bottom, 0, dh - bottom, left, bottom);
		blit(sw - right, sh - bottom, right, bottom, dw - right, dh - bottom, right, bottom);

		// edges
		blit(left, 0, centerSrcW, top, left, 0, centerDstW, top);
		blit(left, sh - bottom, centerSrcW, bottom, left, dh - bottom, centerDstW, bottom);
		blit(0, top, left, centerSrcH, 0, top, left, centerDstH);
		blit(sw - right, top, right, centerSrcH, dw - right, top, right, centerDstH);

		// center
		blit(left, top, centerSrcW, centerSrcH, left, top, centerDstW, centerDstH);
	}

	public static function getScaled(source:Dynamic, w:Int, h:Int):FlxGraphic
	{
		var key = 'uxscale|' + Std.string(source) + '|to' + w + 'x' + h;
		if (_cache.exists(key)) return _cache.get(key);
		var src = _resolveBitmapData(source);
		if (src == null) return null;
		var out = new BitmapData(w, h, true, 0x00000000);
		var m = new Matrix();
		m.scale(w / src.width, h / src.height);
		out.draw(src, m, null, null, null, true);
		var gfx = FlxGraphic.fromBitmapData(out, false, key);
		_cache.set(key, gfx);
		return gfx;
	}
}
