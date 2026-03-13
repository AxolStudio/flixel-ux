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
  - A simple “slide-in panel” tween (demo-only).
  - Shows reordering buttons with `FlxUXGroup.reverse()` and then re-running layout helpers.
