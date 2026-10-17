# Changelog

Notable changes to FlxUX are recorded here.

## [0.3.0-beta] - 2026-10-17

### Added

- Configurable Tab and Shift+Tab traversal with per-button `tabStop` controls.
- Configurable keyboard shortcuts and Alt access keys with optional button cues.
- Group-scoped default and cancel buttons, modal input handling, and focus restoration.
- Scrollbars and clipped scroll panels for vertical, horizontal, or two-axis content, with draggable thumbs, arrow buttons, wheel scrolling, keyboard navigation, and automatic focus reveal.
- Theme and JSON options for scrollbar graphics, arrow spritesheets, scroll-panel backgrounds, and borders.
- Pixel-art default graphics for scrollbar tracks, thumbs, and direction arrows.
- Keyboard/action and scrolling examples in the demo.

### Changed

- Improved default button label size and contrast.
- Default buttons use an inset outline that follows the button label palette.
- Pressed labels remain centered and shift down by one pixel.

### Fixed

- Keyboard cues are hidden when keyboard input is unavailable.
- Scroll-panel content and pointer interaction remain clipped to the viewport.
