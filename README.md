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

- `Project.xml`: `<haxelib name="flixel-ux" />`
- `.hxml`: `-lib flixel-ux`

## Quick start

### 1) Create a group and add it to the state

Create a `FlxUXGroup` and add the group to your state.

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
	}
}
```

### 2) Add buttons to the group

Add buttons through the group. You do not need to separately add each button to the state.

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

		group.addButton("Play", startGame, 100, 100);
		group.addButton("Options", openOptions, 100, 140);
	}

	function startGame():Void {}
	function openOptions():Void {}
}
```

## How FlxUX works

- `FlxUXCore` can be initialized with custom settings, or configured at runtime.
- `FlxUXCore` defines default behavior and look for your groups and buttons.
- You can override those defaults per group or per button.
- FlxUX automatically switches between `POINTER` and `NAV` modes based on player input.
- In `NAV` mode, you can choose different focus styles.

Optional explicit initialization with custom defaults:

```haxe
import flixel.ux.FlxUXCore;
import flixel.ux.FlxUXFocusMode;

FlxUXCore.buttonUseAnim = true;
FlxUXCore.buttonSkinFps = 18;
FlxUXCore.focusMode = FlxUXFocusMode.FRAME;
FlxUXCore.init();
```

Runtime updates are also supported:

```haxe
import flixel.ux.FlxUXNavStyle;

FlxUXCore.focusMode = FlxUXFocusMode.NEXT_TO;
FlxUXCore.navStyle = FlxUXNavStyle.SPATIAL;
```

## Layout helpers

`FlxUXGroup` includes a few simple layout helpers for menus.

Match sizes:

```haxe
// Make all buttons the same width
group.matchWidth();

// Make all buttons the same height
group.matchHeight();

// Make all buttons the same width and height
group.matchSize();
```

Stack buttons vertically:

```haxe
// Stack buttons from top to bottom
group.stack(8);
```

Spread buttons horizontally:

```haxe
// Lay buttons out left to right
group.spread(8);
```

Grid layout:

```haxe
// 3 columns, 8px gaps, center the final row if it is not full
group.grid(3, 8, 8, FlxUXGridLastRowAlign.CENTER);
```

Center the group on screen:

```haxe
group.alignCenter();
```

## Styles and graphics

FlxUX supports styling at three levels:

1. Core defaults (`FlxUXCore`)
2. Group defaults (`FlxUXGroup`)
3. Per-button overrides (`FlxUXButton`)

Override priority is button, then group, then core.

You can set custom graphics for:

- Button visuals
- Focus frame visuals
- Focus next-to visuals
- Focus overlay visuals

Supported button skin styles include:

- Normal static graphics
- Animated graphics
- 9-slice graphics
- 9-slice graphics with animation

Examples:

```haxe
import flixel.ux.FlxUX9Slice;

// Core-wide button default (9-slice)
FlxUXCore.setButtonSkin(new FlxUX9Slice("assets/ui/button_9s.png", 8, 8, 8, 8, 16, 16));

// Core focus visuals
FlxUXCore.focusMode = FlxUXFocusMode.FRAME;
FlxUXCore.focusFrameGraphic = new FlxUX9Slice("assets/ui/focus_frame.png", 10, 10, 10, 10, 40, 40);
FlxUXCore.focusNextToGraphic = "assets/ui/focus_arrow.png";
FlxUXCore.focusOverlayGraphic = "assets/ui/focus_overlay.png";

// Group-level override
group.setButtonSkin(new FlxUX9Slice("assets/ui/pause_button.png", 6, 6, 6, 6, 16, 16), 12);

// Button-level override
button.setButtonSkin("assets/ui/special_button_strip.png");
```

Focus style options:

- `FlxUXFocusMode.FRAME`
- `FlxUXFocusMode.NEXT_TO`
- `FlxUXFocusMode.OVERLAY`
- `FlxUXFocusMode.HOVER_ONLY`
- `FlxUXFocusMode.DIM_UNFOCUSED`

## Themes

Themes package style defaults into a single reusable object.

You can define a theme in code:

```haxe
import flixel.ux.FlxUXTheme;

var myTheme = new FlxUXTheme();
myTheme.buttonUseAnim = true;
myTheme.buttonSkinFps = 18;
myTheme.focusMode = FlxUXFocusMode.FRAME;
myTheme.highlightPadX = 10;
myTheme.highlightPadY = 10;

FlxUXCore.setTheme(myTheme);
```

Or load a theme from JSON at startup or any other time:

```haxe
FlxUXCore.loadThemeFromAsset("themes/default.json");
```

`setTheme()` and `loadThemeFromAsset()` apply core defaults and refresh currently registered FlxUX UI.

Common theme fields include:

- Pixel-art defaults and snapping
- Button skin defaults and animation sequences
- Focus highlight style and graphics
- Highlight padding

### Theme JSON format

Most properties are numbers, booleans, strings, or arrays. Graphics can be either a string asset id, or a 9-slice object.

Example:

```json
{
	"pixelArtDefaults": true,
	"snapUiToPixels": true,

	"buttonUseAnim": false,
	"buttonSkinFps": 10,
	"buttonGraphic": {
		"source": "flixel-ux/ux/button.png",
		"left": 6,
		"top": 6,
		"right": 6,
		"bottom": 6
	},

	"focusMode": "FRAME",
	"focusFrameGraphic": {
		"source": "flixel/images/ui/box.png",
		"left": 4,
		"top": 4,
		"right": 4,
		"bottom": 4
	},

	"highlightPadX": 12,
	"highlightPadY": 12
}
```

See `FlxUXTheme` for all supported fields.