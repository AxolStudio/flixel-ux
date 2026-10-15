# Flixel-UX demo

This folder is a tiny HaxeFlixel project that showcases `flixel-ux`.

## Run it

From the `demo/` folder:

- HashLink (recommended / fast iteration):
  - `lime test hl -debug`

If you prefer HTML5:
- `lime test html5 -debug`

## What’s in the demo

The main menu opens a few substates. Each one is focused on a couple FlxUX features.

- **Focus modes**
  - Shows three focus highlight strategies: FRAME / NEXT_TO / OVERLAY.
  - Demonstrates per-group focus overrides via `group.focusMode`.

- **Themes + overrides**
  - Swaps between themes at runtime by assigning `FlxUXCore.theme`.
  - Demonstrates how overrides work:
    - Core defaults → Group overrides → Button overrides.
  - Includes an example of an animated button skin using the demo spritesheet `assets/ux/button_anim.png`.

- **Layout helpers**
  - Shows `stack()`, `spread()`, and `grid()`.
  - Includes `FlxUXGridLastRowAlign` behavior for short final rows.

- **Advanced examples**
  - A simple slide-in tween.
  - Shows reordering buttons with `FlxUXGroup.reverse()` and then re-running layout helpers.

- **Keyboard + actions**
  - Tab/Shift+Tab, excluded tab stops, Alt access keys, and a Ctrl+P shortcut.
  - Default/cancel buttons, a distinct default marker, and keyboard-disabled cue behavior.

- **Scrolling**
  - An inventory grid in a clipped viewport with vertical/horizontal bars.
  - Thumb dragging, arrow buttons, wheel/page scrolling, and keyboard/gamepad focus reveal.
  - Matching pixel-art track, thumb, and direction-arrow graphics.

Keyboard-specific cues are hidden when keyboard input is disabled.
