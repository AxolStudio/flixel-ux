# flixel-ux (FlxUX)

FlxUX is a small UX layer for HaxeFlixel that makes menus and button-based UI work well across mouse, touch, keyboard, and gamepad.

## Demo Project

There’s a runnable HaxeFlixel demo project in `demo/` that showcases focus modes, themes, and layout helpers.

See `demo/README.md` for how to run it and what it covers.

Play the demo in your browser:

- https://axolstudio.github.io/flixel-ux/

![FlxUX demo screenshot](demo/screenshot.png)

## Features

- **Single “menu UX layer” that works across mouse + keyboard + gamepad**
	- Automatically switches between pointer input and navigation input.
- **Navigation + focus management**
	- Keeps track of which button is focused.
	- Navigation styles: LINEAR and SPATIAL.
	- Configurable input capture policy (AUTO/ALWAYS/NEVER).
- **A clean override chain: core → group → button**
	- Set app-wide defaults in `FlxUXCore`.
	- Override per-menu in `FlxUXGroup`.
	- Override per-button in `FlxUXButton`.
- **Skinnable buttons (static or animated)**
	- 9-slice button skins by default.
	- Optional animated skins via sprite sheets + named animation sequences.
- **Themes you can swap at runtime**
	- Load from JSON (`FlxUXTheme.fromJson(...)`) or set up in code.
	- Applying a theme refreshes registered groups and clears cached 9-slice graphics.
- **Layout helpers for common menu patterns**
	- `stack()`, `spread()`, and `grid()`.
	- Last-row alignment options for short grid rows.
	- `matchSize()` for consistent button sizing.
- **Cursor + highlight visuals**
	- Optional mouse cursor sprite.
	- Multiple focus highlight modes (FRAME / NEXT_TO / OVERLAY).

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

### Core System Overview

- `FlxUXCore` is the global manager. It reads input and keeps track of focus.
- `FlxUXGroup` is a container for UI buttons that should participate in navigation.
- `FlxUXButton` is a button that supports FlxUX focus and skins.

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

## Navigation

FlxUX supports two navigation styles: **LINEAR** and **SPATIAL**.

You can set the default navigation style globally:

```haxe
FlxUXCore.navStyle = FlxUXNavStyle.LINEAR;

// or
FlxUXCore.navStyle = FlxUXNavStyle.SPATIAL;
```

### LINEAR navigation

LINEAR navigation is essentially a "next / previous" list.

- Pressing **DOWN** or **RIGHT** moves to the next eligible button in the order it was added.
- Pressing **UP** or **LEFT** moves to the previous eligible button.
- When FlxUX reaches the last eligible button in a group, it continues to the next eligible group in the state.
- When it reaches the end of the final eligible group, selection wraps back to the start.

LINEAR is great for simple menus because the behavior is predictable and doesn't depend on button positions.

### SPATIAL navigation

SPATIAL navigation tries to move focus based on where buttons are on screen.

- Pressing a direction searches for the "best" next button in that direction.
- This is typically what you want for grids and irregular layouts.

Because SPATIAL is position-based, your layout matters: if you move buttons around, the navigation results will change.

### What is Navigable in FlxUX?

In **NAV mode** (keyboard/gamepad), FlxUX only considers buttons that are being **updated by Flixel**.

In practice, a button can be focused if:

- Its `FlxUXButton.update()` is getting called this frame, and
- The button is eligible (`exists`, `alive`, `visible`, `active`, and not `locked`), and
- Its `FlxUXGroup` is eligible (`exists`, `alive`, `visible`, `active`, `uxActive = true`, `capturesNav = true`).

This matches how Flixel “modal” UI works: when you open a `subState`, the underlying state typically stops updating, so those hidden buttons automatically become non-navigable.

Groups also belong to the state/substate where they were created. Only the current deepest state receives input, even if underlying UI intentionally keeps updating. Within that state, an eligible modal group can further restrict input.

## Styling

FlxUX styling is based on a simple override chain:

1) **`FlxUXCore`** (global defaults for your whole project)
2) **`FlxUXGroup`** (menu-level defaults)
3) **`FlxUXButton`** (per-button overrides)

The easiest way to think about it is: set a good-looking global default in `FlxUXCore`, then override only where you need to.

### Global button skin (applies to every button)

Set a graphic on `FlxUXCore` and every new `FlxUXButton` will use it unless a group or button overrides it.

#### A basic 4-frame button graphic

This is the classic Flixel button layout: a single spritesheet with 4 frames:

1) UP
2) OVER
3) DOWN
4) LOCKED (disabled)

```haxe
// Applies to all FlxUXButtons (unless overridden)
FlxUXCore.buttonGraphic = "assets/images/ui/button_4frame.png";
```

#### A 4-frame 9-slice button graphic

If your buttons are 9-slice skins, you can still use the same 4-frame idea. Each frame is treated as its own 9-slice source.

```haxe
FlxUXCore.buttonGraphic = new FlxUX9Slice(
	"assets/images/ui/button_4frame_9slice.png",
	16,
	16,
	6,
	6,
	6,
	6);
```

Animations are also supported (sprite sheets + named sequences), but for most menus a static 4-frame skin is the simplest starting point.

### Global label styling

```haxe
FlxUXCore.buttonLabelColor = 0xFFFFFFFF;
FlxUXCore.buttonLabelColorLocked = 0xFF777777;
FlxUXCore.buttonLabelSize = 18;
```

Label size and color follow the same core → group → button override order as other button styling. When using a custom label factory, apply label styling and keyboard cues in the custom renderer.

### Override per menu (group)

If one menu needs a different look, set the same properties on the `FlxUXGroup`. This overrides the core defaults for buttons in that group.

```haxe
var menu = new FlxUXGroup();
add(menu);

menu.buttonGraphic = "assets/images/ui/pause_button_4frame.png";
menu.buttonLabelColor = 0xFFFFE7B0;
```

### Override a single button

For one-off special cases, set it directly on the button. This overrides both the group and the core.

```haxe
var danger = menu.addButton("Delete Save", onDelete);
danger.buttonGraphic = "assets/images/ui/danger_button_4frame.png";
danger.buttonLabelColor = 0xFFFF4B4B;
```

## Themes

Themes are the “bundle everything” version of the same override chain. Instead of setting lots of individual properties, you can package them into a `FlxUXTheme` and apply it.

### Create a theme in code

```haxe
var myTheme = new FlxUXTheme({
	buttonGraphic: new FlxUX9Slice("assets/images/ui/button_4frame_9slice.png", 16, 16, 6, 6, 6, 6),
	buttonLabelColor: 0xFFFFFFFF,
	buttonLabelColorLocked: 0xFF777777
});

FlxUXCore.theme = myTheme;
```

### Group and button theme overrides

The same override chain still applies:

- `FlxUXCore.theme` sets the default theme
- `group.theme` overrides it for that menu
- `button.theme` overrides it for that one button

```haxe
menu.theme = new FlxUXTheme({ buttonLabelColor: 0xFFFFE7B0 });

var special = menu.addButton("Special", onSpecial);
special.theme = new FlxUXTheme({ buttonLabelColor: 0xFF00E5FF });
```

### Load a theme from JSON

```haxe
var themeJson = Assets.getText("themes/default.json");
FlxUXCore.theme = FlxUXTheme.fromJson(themeJson);
```

You can also pass the JSON string directly to the constructor: `new FlxUXTheme(themeJson)`. `FlxUXTheme.fromObject()` remains available when you prefer the factory-method style. See `FlxUXTheme` for the full list of supported settings.

## Keyboard and dialog actions

Tab and Shift+Tab traverse eligible buttons in group/button registration order, once each before wrapping. This order is independent of spatial navigation. `tabStop = false` excludes a button only from Tab traversal; it remains available to arrows, pointer input, and shortcuts. Existing `setGroupOrder()` and `setButtonOrder()` methods customize traversal order.

```haxe
var menu = new FlxUXGroup();
add(menu);
var print = menu.addButton("Print", printDocument);
print.accessKey = "p";      // Alt+P, with an underlined P.
print.hotkey = "Ctrl+P";    // Separate command shortcut/caption.
var accept = menu.addButton("Accept", acceptChanges);
var cancel = menu.addButton("Cancel", cancelChanges);
menu.defaultButton = accept;
menu.cancelButton = cancel;
```

Shortcuts and access keys default to `null`; no application commands are assigned automatically. Modifiers match exactly, so Ctrl+S does not also trigger WASD navigation. If active shortcuts conflict, the first eligible button in registration order takes precedence.

Enter activates the focused button, or the active group's default button when no button is focused. Space activates only the focused button. Confirm activation completes on release and stays attached to the original pressed button. Escape activates the active group's eligible cancel button, falling back to `onCancel`. Default/cancel references must point to buttons in their own group; both default to `null`.

Groups belong to the state/substate in which they are created. Only the current, deepest state receives input, even when underlying states keep updating. Within a state, `group.modal = true` gives the last registered eligible modal group exclusive input. Closing a substate or releasing a modal group restores the previous eligible focus. Ordinary arrow/gamepad navigation remains available, and held directions repeat after a configurable delay.

### Keyboard availability and customization

`FlxUXCore.keyboardEnabled = false`, `FlxG.keys.enabled = false`, and the `FLX_NO_KEYBOARD` define disable FlxUX keyboard input. Shortcut captions and mnemonic underlines disappear automatically without resizing buttons; gamepad and pointer behavior remain available. Keyboard cues can also be hidden globally or per button with `showKeyboardCues = false`. The default-button marker is independent of keyboard cues and can be disabled with `button.showDefaultIndicator = false` or recolored with `defaultIndicatorColor`.

| Setting | Default |
| --- | --- |
| `keyboardTab` | `true` |
| `keyboardHomeEnd` | `true` |
| `paneNavigation` (F6 / Shift+F6) | `false` |
| `shortcutsEnabled`, `showKeyboardCues` | `true` |
| `navRepeatDelay`, `navRepeatInterval` | `0.4`, `0.09` seconds; interval <= 0 disables repeat |
| `captureShortcuts` (HTML5 assigned shortcuts) | `true` |

Home/End select the first/last eligible button in the focused group. Optional F6 traversal moves between eligible groups. Override keyboard bindings before initialization, or call `rebindInputs()` afterward:

```haxe
FlxUXCore.keyboardBindings.set("tabNext", ["TAB", "E"]);
FlxUXCore.keyboardBindings.set("tabPrevious", ["SHIFT+TAB", "Q"]);
FlxUXCore.keyboardBindings.set("first", []); // Disable this binding.
FlxUXCore.rebindInputs();
```

Binding names: `up`, `down`, `left`, `right`, `tabNext`, `tabPrevious`, `first`, `last`, `pageUp`, `pageDown`, `paneNext`, `panePrevious`, `confirm`, `accept`, and `cancel`. `confirm` defaults to Enter/Space and gamepad confirm; `accept` defaults to Enter and permits default-button activation. To remove Enter entirely, override both `confirm` and `accept`. Key names use `FlxKey` names, with optional Ctrl/Shift/Alt/Meta modifiers. Existing arrow/WASD/gamepad binding flags are preserved.

On HTML5, only assigned, eligible shortcuts are prevented from invoking their browser defaults; set `captureShortcuts = false` to leave those defaults alone. Browser/OS-reserved shortcuts are not guaranteed. Flixel separately owns its `FlxG.keys.preventDefaultKeys` list, including Tab by default: applications embedding the game in a keyboard-navigable page should customize that list to allow focus to leave the game. These controls do not provide a DOM/screen-reader accessibility tree.

## Scrolling

`FlxUXScrollPanel` clips arbitrary Flixel group/sprite content in an owned camera. `FlxUXGroup` children retain navigation, and focusing a child automatically reveals it.

```haxe
var panel = new flixel.ux.FlxUXScrollPanel(24, 80, 360, 240);
add(panel);
var inventory = new FlxUXGroup();
for (index in 0...30)
	inventory.addButton("Item " + index, () -> {});
inventory.stack(8);
panel.addContent(inventory);
panel.horizontalEnabled = true; // Vertical is enabled by default.
panel.refresh();
```

Content coordinates are local to the panel's camera, not screen coordinates. Panels use screen-space x/y and an unrotated, zoom-1 viewport; put them directly in the state UI, rather than inside transformed camera/group hierarchies. Nested/overlapping panels and virtualized lists are not supported. Child controls continue updating while their panel is active, including offscreen content.

- Bounds are measured automatically from visible, existing content. Use `setContentSize(width, height, originX, originY)` for explicit bounds and `useAutomaticContentBounds()` to restore measurement.
- Bars appear only on enabled axes with overflow. Set `autoHideScrollbars = false` to keep enabled bars visible. Values clamp when content or viewport dimensions change.
- Arrow buttons step and repeat; track clicks page; the proportional thumb can be dragged with the mouse. Mouse-disabled builds retain keyboard/gamepad navigation and automatic reveal.
- The wheel scrolls vertically; Shift+wheel scrolls horizontally when enabled. Customize `wheelStep`, or disable `wheelEnabled`.
- With a child focused, Page Up/Down and Home/End scroll the panel without changing focus. Disable `keyboardScrolling` or override the shared bindings to change this behavior.
- `scrollX`, `scrollY`, `scrollTo()`, `ensureVisible()`, `focusPadding`, and `onScroll` provide programmatic control.
- Customize `verticalBar` / `horizontalBar`: `thickness`, `showButtons`, `step`, `minThumbSize`, repeat timing, `trackColor`, `thumbColor`, and arrow button skins. Call `refresh()` after layout changes.
- Customize each scrollbar's `trackGraphic`, `thumbGraphic`, `buttonGraphic`, and `arrowGraphic`. Track/thumb/button graphics accept asset IDs or `FlxUX9Slice` values; use 9-slices when the art needs fixed pixel borders at different sizes. Arrow graphics are a four-frame horizontal spritesheet ordered up, down, left, right; set `scrollBarArrowFrameSize` in the theme to match its square frames. Set `trackColor` or `thumbColor` to tint or override the theme colors.
- FlxUX includes pixel-art defaults for the track, thumb, and four arrow icons. Supply your own asset IDs to match your game's UI style.
- Theme fields include `scrollBarTrackGraphic`, `scrollBarThumbGraphic`, `scrollBarButtonGraphic`, `scrollBarArrowGraphic`, `scrollBarArrowFrameSize`, `scrollBarTrackColor`, `scrollBarThumbColor`, `scrollBarThickness`, `scrollBarStep`, `scrollBarMinThumbSize`, and `scrollBarShowButtons`. Scrollzone fields include `scrollPanelBackgroundGraphic`, `scrollPanelBackgroundColor`, `scrollPanelBorderGraphic`, `scrollPanelBorderColor`, `scrollPanelBorderThickness`, and `scrollPanelFocusPadding`. Graphics accept an asset ID string or a 9-slice object.
- Set theme-wide graphics/options in code or JSON. Per-instance values override the theme:

```haxe
FlxUXCore.theme = FlxUXTheme.fromJson(Assets.getText("themes/ui.json"));

panel.backgroundColor = 0xFF172027;
panel.verticalBar.trackColor = 0xFF28343B;
panel.verticalBar.thumbGraphic = "assets/ui/inventory_thumb.png";
panel.verticalBar.increaseButton.setButtonSkin("assets/ui/scroll_button.png");
```

```json
{
	"scrollBarTrackGraphic": {
		"source": "assets/ui/scroll_track.png",
		"frameWidth": 8,
		"frameHeight": 8,
		"left": 3,
		"top": 3,
		"right": 3,
		"bottom": 3
	},
	"scrollBarThumbGraphic": "assets/ui/scroll_thumb.png",
	"scrollBarButtonGraphic": "assets/ui/scroll_button.png",
	"scrollBarArrowGraphic": "assets/ui/scroll_arrows.png",
	"scrollBarArrowFrameSize": 8,
	"scrollBarThickness": 20,
	"scrollBarTrackColor": "#1C242A",
	"scrollBarThumbColor": "#FFFFFF",
	"scrollPanelBackgroundColor": "#14191E",
	"scrollPanelBackgroundGraphic": "assets/ui/inventory_background.png",
	"scrollPanelBorderColor": "#77838C",
	"scrollPanelBorderGraphic": {
		"source": "assets/ui/inventory_border.png",
		"left": 4,
		"top": 4,
		"right": 4,
		"bottom": 4
	},
	"scrollPanelBorderThickness": 1,
	"scrollPanelFocusPadding": 8
}
```

- Add/remove content with `addContent()` / `removeContent()` so removed children regain their previous cameras/scroll factors. The panel owns its remaining content and viewport camera; destroying it releases both.

`FlxUXScrollBar` can also be used independently. Construct it with x/y, bar length, and vertical orientation; call `setRange(contentSize, viewportSize)`, then use `value`, `maximum`, and `onChange`. `value` ranges from zero to `maximum`.
