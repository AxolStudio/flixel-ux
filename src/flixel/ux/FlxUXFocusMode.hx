package flixel.ux;

/**
 * Which focus highlight strategy to use in NAV mode.
 *
 * Kept as a standalone enum so downstream projects can `import flixel.ux.FlxUXFocusMode`.
 * FlxUXCore also documents and uses this type.
 */
enum FlxUXFocusMode
{
	/** 9-slice focus frame around the focused widget. */
	FRAME;
	/** A sprite drawn next to the focused widget (optionally mirrored). */
	NEXT_TO;
	/** A sprite drawn over the focused widget (typically bottom-right half-hang). */
	OVERLAY;
	/** Pointer hover only: no NAV focus visuals (still allows pointer clicks). */
	HOVER_ONLY;
	/** Dim non-focused widgets (future; no group-level sprite). */
	DIM_UNFOCUSED;
}
