package flixel.ux;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
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

	/** Source frame width if this slice comes from a spritesheet (0 uses source width). */
	public var effectiveFrameWidth(get, never):Int;
	private function get_effectiveFrameWidth():Int
	{
		if (frameWidth > 0) return frameWidth;
		var src = resolveBitmapData(source);
		return (src != null) ? src.width : 0;
	}

	/** Source frame height if this slice comes from a spritesheet (0 uses source height). */
	public var effectiveFrameHeight(get, never):Int;
	private function get_effectiveFrameHeight():Int
	{
		if (frameHeight > 0) return frameHeight;
		var src = resolveBitmapData(source);
		return (src != null) ? src.height : 0;
	}

	/** The slice borders clamped to the current effective frame size. */
	public var clamped(get, never):{ left:Int, top:Int, right:Int, bottom:Int };
	private function get_clamped():{ left:Int, top:Int, right:Int, bottom:Int }
	{
		var fw = effectiveFrameWidth;
		var fh = effectiveFrameHeight;
		var l = left;
		var t = top;
		var r = right;
		var b = bottom;
		if (l < 0) l = 0;
		if (t < 0) t = 0;
		if (r < 0) r = 0;
		if (b < 0) b = 0;
		if (fw > 0)
		{
			l = Std.int(Math.min(l, fw));
			r = Std.int(Math.min(r, fw - l));
		}
		if (fh > 0)
		{
			t = Std.int(Math.min(t, fh));
			b = Std.int(Math.min(b, fh - t));
		}
		return { left: l, top: t, right: r, bottom: b };
	}

	/** Mutates slice borders. Returns `this` for chaining. */
	public inline function setBorders(left:Int, top:Int, right:Int, bottom:Int):FlxUX9Slice
	{
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
		return this;
	}

	/** Mutates frame size. Returns `this` for chaining. */
	public inline function setFrameSize(frameWidth:Int, frameHeight:Int):FlxUX9Slice
	{
		this.frameWidth = frameWidth;
		this.frameHeight = frameHeight;
		return this;
	}

	/** Evicts cached renders produced from this slice's source graphic. */
	public inline function evict():Void
	{
		evictSource(source);
	}

	/** Renders (and caches) this slice to a `FlxGraphic`. */
	public inline function render(targetW:Int, targetH:Int, ?frameIndex:Int = 0):FlxGraphic
	{
		return get(this, targetW, targetH, frameIndex);
	}

	/** Returns the cache key that would be used for a render of this slice. */
	public inline function cacheKey(targetW:Int, targetH:Int, ?frameIndex:Int = 0):String
	{
		return makeKey(this, targetW, targetH, frameIndex);
	}
	private static var cache:Map<String, FlxGraphic> = new Map();
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
			cache.remove(k);
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
		var gfx:FlxGraphic = FlxGraphic.fromBitmapData(out, false, key);
		gfx.persist = true;
		gfx.destroyOnNoUse = false;
		cache.set(key, gfx);
		var srcKey = stableSourceKey(nine.source);
		if (!cacheBySource.exists(srcKey))
			cacheBySource.set(srcKey, []);
		var keys = cacheBySource.get(srcKey);
		if (keys.indexOf(key) < 0) keys.push(key);
		return gfx;
	}

	/** Returns true if a cached render exists and is still valid. */
	public static function has(nine:FlxUX9Slice, targetW:Int, targetH:Int, ?frameIndex:Int = 0):Bool
	{
		if (nine == null) return false;
		if (targetW < 1) targetW = 1;
		if (targetH < 1) targetH = 1;
		var key = makeKey(nine, targetW, targetH, frameIndex);
		if (!cache.exists(key)) return false;
		var g = cache.get(key);
		return (g != null && g.bitmap != null);
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

	/** Produces a stable identity string for cache keys. */
	private static function stableSourceKey(source:FlxUXGraphicInput):String
	{
		if (source == null) return 'null';
		if (Std.isOfType(source, String))
			return 'str:' + cast(source, String);
		if (Std.isOfType(source, FlxGraphic))
		{
			var fg:FlxGraphic = cast source;
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
			var hc:String = '';
			try
			{
				var dyn:Dynamic = bd;
				if (Reflect.hasField(dyn, "__hashCode")) hc = ':' + Std.string(Reflect.field(dyn, "__hashCode"));
			}
			catch (_:Dynamic) {}
			return 'bd:' + bd.width + 'x' + bd.height + hc;
		}
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
		if (frameW > src.width) frameW = src.width;
		if (frameH > src.height) frameH = src.height;
		var cols:Int = Std.int(src.width / frameW);
		if (cols < 1) cols = 1;
		var rows:Int = Std.int(src.height / frameH);
		if (rows < 1) rows = 1;
		var total:Int = cols * rows;
		if (total < 1) total = 1;
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

		function blitScaled(sx:Int, sy:Int, sW:Int, sH:Int, dx:Int, dy:Int, dW:Int, dH:Int):Void
		{
			if (sW <= 0 || sH <= 0 || dW <= 0 || dH <= 0) return;
			var rect:Rectangle = new Rectangle(srcRect.x + sx, srcRect.y + sy, sW, sH);
			if (sW == dW && sH == dH)
			{
				out.copyPixels(src, rect, new Point(dx, dy), null, null, true);
				return;
			}
			var m = new Matrix();
			m.scale(dW / sW, dH / sH);
			m.translate(dx - rect.x * (dW / sW), dy - rect.y * (dH / sH));
			out.draw(src, m, null, null, new Rectangle(dx, dy, dW, dH), false);
		}

		blitScaled(0, 0, left, top, 0, 0, left, top);
		blitScaled(sw - right, 0, right, top, dw - right, 0, right, top);
		blitScaled(0, sh - bottom, left, bottom, 0, dh - bottom, left, bottom);
		blitScaled(sw - right, sh - bottom, right, bottom, dw - right, dh - bottom, right, bottom);

		blitScaled(left, 0, centerSrcW, top, left, 0, centerDstW, top);
		blitScaled(left, sh - bottom, centerSrcW, bottom, left, dh - bottom, centerDstW, bottom);
		blitScaled(0, top, left, centerSrcH, 0, top, left, centerDstH);
		blitScaled(sw - right, top, right, centerSrcH, dw - right, top, right, centerDstH);

		blitScaled(left, top, centerSrcW, centerSrcH, left, top, centerDstW, centerDstH);
	}

	public function new(source:FlxUXGraphicInput, ?frameWidth:Int = 0, ?frameHeight:Int = 0, left:Int, top:Int, right:Int, bottom:Int)
	{
		this.source = source;
		this.frameWidth = (frameWidth != null) ? frameWidth : 0;
		this.frameHeight = (frameHeight != null) ? frameHeight : 0;
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}

	/** Creates a 9-slice with the common "uniform borders" case. */
	public static inline function uniform(source:FlxUXGraphicInput, border:Int, ?frameWidth:Int = 0, ?frameHeight:Int = 0):FlxUX9Slice
	{
		return new FlxUX9Slice(source, frameWidth, frameHeight, border, border, border, border);
	}

	/** Creates a 9-slice from explicit borders. */
	public static inline function borders(source:FlxUXGraphicInput, left:Int, top:Int, right:Int, bottom:Int, ?frameWidth:Int = 0, ?frameHeight:Int = 0):FlxUX9Slice
	{
		return new FlxUX9Slice(source, frameWidth, frameHeight, left, top, right, bottom);
	}
}

