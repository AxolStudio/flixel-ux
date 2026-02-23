package flixel.ux;

/**
 * Determines when FlxUX should process NAV input (keyboard/gamepad focus + confirm/cancel).
 *
 * POINTER behavior (mouse clicks) remains normal Flixel behavior through FlxButton callbacks.
 */
enum FlxUXNavCapturePolicy
{
	/**
	 * Default: only process NAV when there is at least one eligible NAV target
	 * (i.e., an eligible button in an active group that captures NAV).
	 */
	AUTO;

	/** Always process NAV when FlxUXCore.navEnabled is true. */
	ALWAYS;

	/** Never process NAV (mouse/touch-only UX). */
	NEVER;
}