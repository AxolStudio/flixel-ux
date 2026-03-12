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
	// Reverse index so we can evict all cached renders for a given source quickly.
	private static var cacheBySource:Map<String, Array<String>> = new Map();

	/** Clears the internal 9-slice cache. */
	public static function clearCache():Void
	{
		cache = new Map();
		cacheBySource = new Map();
	}

	/** Evicts all cached renders produced from the given source input. */
	public static function evictSource(source:FlxUXGraphicInput):Void
	{
		var sk = stableSourceKey(source);
		if (!cacheBySource.exists(sk))
			return;
		var keys = cacheBySource.get(sk);
		cacheBySource.remove(sk);
		if (keys == null) return;
		for (k in keys)
		{
			if (k == null) continue;
			var g = cache.get(k);
			cache.remove(k);
			// IMPORTANT:
			// Do NOT toggle persist/destroyOnNoUse here.
			// On some targets (notably HL/OpenFL) sprites/frames can still reference the graphic
			// for a short time even after we've decided to evict it, and making it destroyable
			// can lead to destroyed bitmap access and placeholder rendering.
			//
			// Removing from our cache is sufficient: subsequent get() calls will re-render.
		}
	}

	/**
	 * Exposes the stable cache identity for a graphic input.
	 *
	 * Used by other FlxUX classes when they need cache keys that must match FlxUX9Slice.get().
	 */
	public static inline function sourceKey(source:FlxUXGraphicInput):String
	{
		return stableSourceKey(source);
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
		{
			var cg = cache.get(key);
			// If the cached graphic was destroyed (possible when destroyOnNoUse is true),
			// don't return it. Flixel will otherwise render a placeholder and we get “wrong theme”.
			if (cg != null && cg.bitmap != null)
				return cg;
			cache.remove(key);
		}

		var src:BitmapData = resolveBitmapData(nine.source);
		if (src == null) return null;

		var frameW:Int = (nine.frameWidth > 0) ? nine.frameWidth : src.width;
		var frameH:Int = (nine.frameHeight > 0) ? nine.frameHeight : src.height;

		var srcRect:Rectangle = frameRect(src, frameW, frameH, frameIndex);
		var out:BitmapData = new BitmapData(targetW, targetH, true, 0x00000000);

		drawNineSlice(out, src, srcRect, nine.left, nine.top, nine.right, nine.bottom);
		// Give the rendered output a deterministic key so FlxG.bitmap can track it consistently
		// across targets and to make debugging/cache eviction reliable.
		var gfx:FlxGraphic = FlxGraphic.fromBitmapData(out, false, key);
		// IMPORTANT:
		// These are *derived* graphics. FlxSprite/animation frames can transiently hold references
		// through draw/update, and some targets (notably HL) will try to query frames on a graphic
		// even after it was destroyed, producing placeholder renders.
		//
		// So we keep derived graphics alive while they are in our cache.
		// Theme/group hot-swaps are handled by explicit eviction (clearCache/evictSource).
		gfx.persist = true;
		gfx.destroyOnNoUse = false;
		cache.set(key, gfx);
		var srcKey = stableSourceKey(nine.source);
		if (!cacheBySource.exists(srcKey))
			cacheBySource.set(srcKey, []);
		cacheBySource.get(srcKey).push(key);
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
			// IMPORTANT:
			// BitmapData doesn't come with a canonical asset id, and FlxGraphic.fromBitmapData()
			// will create a FlxGraphic with a null/unstable key.
			// Our 9-slice cache relies on a stable identity, so we assign an explicit key.
			var key = 'uxbd|' + stableSourceKey(cast bd);
			var g:FlxGraphic = FlxGraphic.fromBitmapData(bd, false, key);
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
		var assetKey:String = stableSourceKey(nine.source);
		var fw:Int = nine.frameWidth;
		var fh:Int = nine.frameHeight;
		var l:Int = nine.left;
		var t:Int = nine.top;
		var r:Int = nine.right;
		var b:Int = nine.bottom;
		return 'ux9|' + assetKey + '|' + fw + 'x' + fh + '|f' + frameIndex + '|to' + w + 'x' + h + '|ns' + l + ',' + t + ',' + r + ',' + b;
	}

	/**
	 * Produces a stable cache key for a graphic input.
	 *
	 * IMPORTANT: Std.string() on objects (FlxGraphic/BitmapData/etc) is not stable and can collide
	 * or vary across runs/targets. That can cause cached 9-slice renders to be reused for the wrong
	 * source, which looks like “wrong slices” or “entire sheet used as one frame”.
	 */
	private static function stableSourceKey(source:FlxUXGraphicInput):String
	{
		if (source == null) return 'null';
		if (Std.isOfType(source, String))
			return 'str:' + cast(source, String);
		if (Std.isOfType(source, FlxGraphic))
		{
			var fg:FlxGraphic = cast source;
			// key is the canonical identity inside FlxG.bitmap
			return (fg.key != null) ? ('gfx:' + fg.key) : ('gfx@' + Std.string(fg));
		}
		if (Std.isOfType(source, FlxSprite))
		{
			var s:FlxSprite = cast source;
			if (s.graphic != null)
				return stableSourceKey(cast s.graphic);
			return 'sprite@' + Std.string(s);
		}
		if (Std.isOfType(source, BitmapData))
		{
			var bd:BitmapData = cast source;
			// BitmapData has no stable id; include dimensions + hashCode when available.
			// openfl exposes __hashCode internally on some targets; guard with try.
			var hc:String = '';
			try
			{
				// @:privateAccess is not needed; Dynamic access is fine.
				var dyn:Dynamic = bd;
				if (Reflect.hasField(dyn, "__hashCode")) hc = ':' + Std.string(Reflect.field(dyn, "__hashCode"));
			}
			catch (_:Dynamic) {}
			return 'bd:' + bd.width + 'x' + bd.height + hc;
		}
		// Fallback for any other EitherType wrapper cases.
		var cls = Type.getClass(source);
		return 'obj:' + ((cls != null) ? Type.getClassName(cls) : 'dynamic') + '@' + Std.string(source);
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
		var rows:Int = Std.int(src.height / frameH);
		if (rows < 1) rows = 1;
		var total:Int = cols * rows;
		var fi:Int = frameIndex;
		if (fi < 0) fi = 0;
		if (fi >= total) fi = total - 1;
		var x:Int = (fi % cols) * frameW;
		var y:Int = Std.int(fi / cols) * frameH;
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

