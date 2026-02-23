# FlxUX (flixel.ux)

FlxUX is a lightweight UX layer for HaxeFlixel focused on one thing: **making buttons work smoothly across mouse/touch/keyboard/gamepad with minimal overhead**.

## v1.0 Scope
- `FlxUXButton` (extends `FlxButton`)
- `FlxUXGroup` (registry of buttons, local ordering)
- `FlxUXCore` (global input + global chained navigation across groups)
- **Plugin-based update hook** (no per-state `update()` boilerplate)

## Core Behavior (locked rules)
### Input modes
- **POINTER**: mouse/touch input. Focus does not matter. Click activates the clicked button.
- **NAV**: keyboard/gamepad navigation. Focus matters. Confirm activates focused button.

Pointer nuance:
- Mouse and touch both switch to `POINTER` mode.
- Only mouse input shows a cursor.
- Touch input keeps cursor hidden.

Mode switching:
- Pointer movement / pointer press => POINTER mode
- Nav input (up/down/left/right/confirm/cancel) => NAV mode

### NAV input defaults (configurable)
- Keyboard navigation: Arrow keys + WASD (default both enabled)
- Gamepad navigation: D-pad + left stick (right stick optional, default off)
- Gamepad confirm/cancel style:
	- `NINTENDO` (default): right-face confirm, bottom-face cancel
	- `PSX`: bottom-face confirm, right-face cancel

Set these before `FlxUXCore.init()` via:
- `FlxUXCore.keyboardArrows`
- `FlxUXCore.keyboardWASD`
- `FlxUXCore.gamepadDpad`
- `FlxUXCore.gamepadLeftStick`
- `FlxUXCore.gamepadRightStick`
- `FlxUXCore.gamepadFaceStyle`

Runtime changes are supported too:
- Update any of the fields above.
- Call `FlxUXCore.rebindInputs()` to apply immediately.

### Navigation (LINEAR)
- `Right` or `Down` => focus **next**
- `Left` or `Up` => focus **previous**
- Wraps around
- Skips ineligible buttons (invisible/disabled/etc.)
- Jumps across groups by default (global chaining)

### Ordering rules
All ordering is **0-based** and **dense (no gaps)**:
- Groups in `FlxUXCore` have a dense order.
- Buttons in each `FlxUXGroup` have a dense order.
- Setting an order performs an "insert at index" with shifting, clamped to valid range.

### Active flags
- `FlxUXCore.active`: master enable/disable all UX input handling (UI can still render).
- `FlxUXCore.navEnabled`: master enable/disable NAV processing only.
- `FlxUXCore.cursorEnabled`: master enable/disable cursor service only.
- `FlxUXCore.navCapturePolicy`:
	- `AUTO` (default): NAV only runs when there is at least one eligible NAV target.
	- `ALWAYS`: NAV always runs when `navEnabled` is true.
	- `NEVER`: NAV never runs.
- `FlxUXGroup.active`: enable/disable interaction for just that group.
- `FlxUXGroup.capturesNav` (default `true`): whether the group participates in NAV focus traversal.

This separation prevents gameplay interference:
- No navigable UI targets + `AUTO` policy => FlxUX does not consume NAV behavior.
- Mouse-only HUD buttons => set `capturesNav = false`.
- Pause/menu UI => keep `capturesNav = true`.

Gamepad/keyboard-first UX expectation:
- Cursor visibility does not gate interaction.
- As long as buttons are registered in active groups that capture NAV, they are reachable/activatable via keyboard/gamepad without needing a mouse.

## Automatic cleanup on state switches
FlxUX automatically removes all registered groups when a state is switched/reset/created (via `FlxG.signals.*` hooks).
- Groups are **not destroyed** unless you call `group.destroy()` yourself.
- You should re-register groups in each state's `create()` (or whenever you want them active).

Substates:
- Flixel does not provide the same global signals for substate open/close.
- If you want substate-specific cleanup, call `FlxUXCore.clearGroups()` manually when opening/closing substates.

## Minimal usage
```haxe
// early in game boot (Main, first State create, etc.)
FlxUXCore.init();

// in a State create():
var groupA = new FlxUXGroup();
FlxUXCore.addGroup(groupA);

var play = groupA.addButton("Play", 100, 100, () -> startGame());
add(play);

// no need to call FlxUXCore.update() in State.update()