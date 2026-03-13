# flixel-ux (FlxUX)

FlxUX is a small UX layer for HaxeFlixel that makes menus and button-based UI work well across mouse, touch, keyboard, and gamepad.

You keep using buttons like normal. FlxUX adds:

- Automatic switching between pointer input and keyboard or gamepad navigation
- Focus management (which button is selected)
- Consistent confirm and cancel handling
- Default UI assets that work out of the box, with simple ways to override them with your own assets

## Key concepts

- `FlxUXCore` is the global manager. It reads input and keeps track of focus.
- `FlxUXGroup` is a container for UI buttons that should participate in navigation.
- `FlxUXButton` is a button that supports FlxUX focus and skins.

In most games, you create one or more `FlxUXGroup`s in each `FlxState`, add those groups to the state, and then add `FlxUXButton`s to each group.

## Installation

Install with haxelib git:

```bash
haxelib git flixel-ux https://github.com/AxolStudio/flixel-ux
```

Then add the library to your project:

`<haxelib name="flixel-ux" />`

## Quick start

Here’s a minimal menu example using `FlxUXGroup`, `addButton()`, and `spread()`.

```haxe
import flixel.FlxState;
import flixel.ux.FlxUXGroup;

class MenuState extends FlxState
{
	override public function create():Void
	{
		super.create();

		var group = new FlxUXGroup();
		add(group);

		group.addButton("Play", startGame);
		group.addButton("Options", openOptions);
		group.addButton("Quit", quit);

		group.spread(8);
		group.alignCenter();
	}

	function startGame():Void {}
	function openOptions():Void {}
	function quit():Void {}
}
```

## Basic usage patterns

### A typical state lifecycle

In most states, you:

1) Create one or more `FlxUXGroup`s
2) `add(group)` them to the state
3) Add buttons with `addButton()` (or `addUXButton()` for existing buttons)
4) Lay them out with `stack()`, `spread()`, `grid()`, then position the group

You usually do not need to call `FlxUXCore.init()` yourself; creating a `FlxUXGroup` auto-initializes FlxUX.

### Vertical menus (stack)

```haxe
var menu = new FlxUXGroup();
add(menu);

menu.addButton("New Game", onNewGame);
menu.addButton("Continue", onContinue);
menu.addButton("Options", onOptions);

menu.stack(6);
menu.alignCenter();
```

### Grid menus

```haxe
import flixel.ux.FlxUXCore.FlxUXGridLastRowAlign;

var grid = new FlxUXGroup();
add(grid);

grid.addButton("A", onA);
grid.addButton("B", onB);
grid.addButton("C", onC);
grid.addButton("D", onD);
grid.addButton("E", onE);

grid.grid(3, 8, 8, FlxUXGridLastRowAlign.CENTER);
grid.alignCenter();
```

### Explicit sizing and matchSize()

Buttons default to `autoSizeToLabel = true`. If you want consistent-sized buttons, you typically do one of these:

```haxe
var g = new FlxUXGroup();
add(g);

g.addButton("Short", onShort);
g.addButton("A much longer label", onLong);

g.matchSize();
g.stack(6);
g.alignCenter();
```

## Customization (core → group → button)

FlxUX configuration follows a simple override chain:

1) `FlxUXCore` (global defaults)
2) `FlxUXGroup` (menu-level defaults)
3) `FlxUXButton` (single-button overrides)

### 1) Global defaults

Adjust the built-in defaults anywhere (commonly in `create()` before you build your menus). Calling `FlxUXCore.init()` is optional; groups auto-init.

```haxe
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXFocusMode;

FlxUXCore.focusMode = FlxUXFocusMode.FRAME;
FlxUXCore.buttonUseAnim = true;
FlxUXCore.buttonSkinFps = 18;
```

### Common settings users tweak

```haxe
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXCore.FlxUXNavCapturePolicy;
import flixel.ux.FlxUXCore.FlxUXNavStyle;

FlxUXCore.pixelArtDefaults = true;
FlxUXCore.snapUiToPixels = true;

FlxUXCore.navEnabled = true;
FlxUXCore.navStyle = FlxUXNavStyle.LINEAR;
FlxUXCore.navCapturePolicy = FlxUXNavCapturePolicy.AUTO;

FlxUXCore.cursorEnabled = true;
```

### 2) Themes (recommended)

Themes bundle the common defaults into one object and can be swapped at runtime.

```haxe
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXTheme;
import openfl.Assets;

FlxUXCore.theme = FlxUXTheme.fromJson(Assets.getText("themes/default.json"));
```

### Changing styles at runtime

FlxUX is designed for runtime style swaps. Assigning `FlxUXCore.theme` clears the 9-slice cache and refreshes any registered groups.

```haxe
FlxUXCore.theme = FlxUXTheme.fromJson(Assets.getText("themes/light.json"));

// Later...
FlxUXCore.theme = FlxUXTheme.fromJson(Assets.getText("themes/dark.json"));
```

### 3) Group and per-button overrides

```haxe
import flixel.ux.FlxUX9Slice;
import flixel.ux.FlxUXTheme;

group.theme = FlxUXTheme.fromJson(Assets.getText("themes/pauseMenu.json"));

var button = group.addButton("Special", onSpecial);
button.theme = FlxUXTheme.fromJson(Assets.getText("themes/specialButton.json"));
```

## Locked state (4th button state)

Flixel internally calls the 4th button state `DISABLED`. In FlxUX, the public API name is **locked**.

When a button is locked:

- It uses the 4th skin state (disabled graphic / animation frames)
- It cannot be focused or activated
- It keeps updating (it does not toggle `active`)

```haxe
var b = group.addButton("Can't click this", onClick);
b.locked = true;
```

### Locked label color

You can style locked labels separately from normal disabled labels.

Precedence is the same as everything else: **button → group → core**.

```haxe
// Global default for all locked buttons
FlxUXCore.buttonLabelColorLocked = 0xFF444444;

// Group override
group.buttonLabelColorLocked = 0xFF222222;

// Per-button override
b.buttonLabelColorLocked = 0xFF111111;
```

See `FlxUXTheme` for the full list of supported fields.

## Demo project

There’s a runnable HaxeFlixel demo project in `demo/` that showcases focus modes, themes, and layout helpers.

See `demo/README.md` for how to run it and what it covers.