# flixel-ux (FlxUX)

A small UX layer for **HaxeFlixel** focused on improving `FlxButton` usability across **mouse**, **touch**, **keyboard**, and **gamepad**.

FlxUX is focused on **interaction**. You create and add buttons as you normally would; FlxUX handles input mode switching and navigation (focus + confirm/cancel).

## What FlxUX does (why you’d use it)

When you add `FlxUXButton`s to one or more `FlxUXGroup`s in a state (or substate), FlxUX handles switching between common input styles and provides consistent button navigation.

In practice, this means:

- **Mouse**: hover/click works like a normal `FlxButton`.
- **Touch**: tap behaves like pointer UX (no mouse cursor required).
- **Keyboard**: directional input moves focus; confirm activates the focused button.
- **Gamepad**: same as keyboard navigation, with configurable face-button confirm/cancel.

This is intended to reduce UI glue code: you don’t need separate “mouse menu code” and “controller menu code”, and you don’t need to manually track which button is focused.

## Key concepts

- **`FlxUXButton`**: the button you add to the state (renders like a normal Flixel button).
- **`FlxUXGroup`**: a registry of buttons you want FlxUX to include in navigation.
- **`FlxUXCore`**: the global manager that reads inputs and moves focus between eligible buttons.

## Installation

Install via haxelib git:

```bash
haxelib git flixel-ux https://github.com/AxolStudio/flixel-ux
```

Then add to your project:

- In `Project.xml`:
  - `<haxelib name="flixel-ux" />`

Or in your `.hxml`:

- `-lib flixel-ux`

## Quick start

### 1) Initialize once

Call `FlxUXCore.init()` once early (for example, in `Main` or the first state that runs):

```haxe
import flixel.ux.FlxUXCore;

FlxUXCore.init();
```

### 2) Create one or more groups (basic menu example)

FlxUX clears registered groups on **Flixel state transitions**. Typically you create and register groups in each state’s `create()`.

> This is only a basic example. You can have multiple groups per state (for example: a menu group + a footer group).

```haxe
import flixel.FlxState;
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXGroup;

class MenuState extends FlxState
{
	override public function create():Void
	{
		super.create();

		var group = new FlxUXGroup();
		FlxUXCore.addGroup(group);

		var play = group.addButton("Play", 100, 100, startGame);
		add(play);
	}

	function startGame():Void
	{
		// TODO: switch to your game state
	}
}
```

## Creating multiple buttons

For simple menus, `FlxUXGroup.addButtons()` creates and registers multiple buttons at once:

```haxe
var buttons = group.addButtons([
	{ label: "Play",    x: 100, y: 100, action: startGame },
	{ label: "Options", x: 100, y: 140, action: openOptions },
	{ label: "Quit",    x: 100, y: 180, action: quitGame }
]);

for (b in buttons)
	add(b);
```

## Input modes

FlxUX automatically switches between:

- **POINTER**: mouse/touch input (click/tap activates the clicked button)
- **NAV**: keyboard/gamepad navigation (confirm activates the focused button)

Default NAV bindings:
- Keyboard: arrows + WASD
- Gamepad: D-pad + left stick

## Configurations (common)

This section covers the most commonly used configuration points. Full reference docs can live in the wiki.

### Core

- Disable all FlxUX logic temporarily (for transitions, pauses, etc.):
	- `FlxUXCore.active = false`
- Disable NAV input but keep pointer behavior:
	- `FlxUXCore.navEnabled = false`
- Gate input during fades/tweens:
	- FlxUX sets `FlxUXCore.ready = false` automatically on state transitions.
	- If `FlxUXCore.autoReady = true` (default), FlxUX will re-enable input automatically once the new state starts updating.
	- Set `FlxUXCore.autoReady = false` if you want to set `FlxUXCore.ready = true` yourself at the end of a fade.

### Groups

- Exclude a group from NAV focus traversal (mouse/touch only):
	- `group.capturesNav = false`
- Disable a group without destroying it:
	- `group.active = false`

## Theming / styling (planned)

FlxUX includes a `FlxUXCore.theme` object intended for widget/theme values (focus highlighting, disabled alpha, etc.).

The theme system is not fully implemented yet. For now:

- Expect the theme API to expand as styling support is added.
- Hover docs on `FlxUXTheme` / `FlxUXCore.theme` describe currently available fields.

## Troubleshooting

### Buttons render, but keyboard/gamepad navigation doesn’t work

Check:
- `FlxUXCore.init()` was called.
- Your group was registered via `FlxUXCore.addGroup(group)`.
- `group.capturesNav` is `true`.
- Buttons are eligible (`visible`, `active`, and `enabled`).
- NAV is allowed:
  - `FlxUXCore.navEnabled == true`
  - `FlxUXCore.navCapturePolicy != NEVER`

### UI stops responding after switching states

This is expected: FlxUX clears registered groups on state transitions.
Recreate and re-register groups in each state’s `create()`.