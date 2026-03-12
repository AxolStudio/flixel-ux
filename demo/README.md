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
  - Shows different focus behaviors (frame / next-to / on / hover / dim).
  - Uses `FlxUXGroup` boxes with borders + labels.

- **Themes + overrides**
  - Swaps between themes at runtime by assigning `FlxUXCore.theme`.
  - Demonstrates how overrides work:
    - Core defaults → Group overrides → Button overrides.

- **Layout helpers**
  - Shows `stack()`, `spread()`, and `grid()`.
  - Includes `FlxUXGridLastRowAlign` behavior for short final rows.

- **Advanced examples**
  - A simple “slide-in panel” tween (demo-only).
  - Also shows label overrides (group defaults + one button override).
