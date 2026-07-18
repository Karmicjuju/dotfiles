local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- OS detection (Mac vs Linux)
local function is_macos()
  return wezterm.target_triple:find("darwin") ~= nil
end

-- Terminal type
config.term = "xterm-256color"
config.use_ime = true

-- Font
config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'JetBrains Mono',
  'monospace',
})
config.font_size = is_macos() and 14.5 or 11.0

-- Color scheme
config.color_scheme = 'GruvboxDark'
config.bold_brightens_ansi_colors = true

-- Transparency and blur
if is_macos() then
  config.window_background_opacity = 0.88
  config.macos_window_background_blur = 24
  config.native_macos_fullscreen_mode = true
  -- Option acts as Alt (not macOS compose) so Alt-keys reach herdr/apps
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false
  config.front_end = "WebGpu"
else
  config.window_background_opacity = 0.92
  config.enable_wayland = true
  config.front_end = "OpenGL"
  config.default_prog = { '/usr/bin/zsh' }
  config.launch_menu = {
    { label = 'Zsh', args = { '/usr/bin/zsh' } },
    { label = 'Bash', args = { '/usr/bin/bash' } },
  }
end

-- Padding
config.window_padding = { left = 10, right = 10, top = 12, bottom = 12 }

-- Scrollback and selection
config.scrollback_lines = 50000
config.selection_word_boundary = ' \t\n{}[]()"\',;:'

-- Window / tab bar
-- herdr is the multiplexer and draws its own tab/status bar, so WezTerm's is off.
config.window_decorations = "TITLE | RESIZE"
config.enable_tab_bar = false

-- herdr uses the kitty keyboard protocol (CSI-u) for accurate key reporting.
config.enable_kitty_keyboard = true

-- Host-only key bindings.
-- herdr owns multiplexing (panes/tabs/workspaces/prefix), so WezTerm intercepts
-- as little as possible: default bindings are disabled and only OS-level
-- clipboard / font / window actions are kept. Every other key passes to herdr.
config.disable_default_key_bindings = true
if is_macos() then
  config.keys = {
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },
    { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'n', mods = 'CMD', action = act.SpawnWindow },
    { key = '0', mods = 'CMD', action = act.ResetFontSize },
    { key = '+', mods = 'CMD', action = act.IncreaseFontSize },
    { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  }
else
  config.keys = {
    { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
    { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'k', mods = 'CTRL|SHIFT', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnWindow },
    { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'PrimarySelection' },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },
    { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  }
end

-- Visual bell
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}
config.audible_bell = 'Disabled'

-- Performance
config.max_fps = 120
config.animation_fps = 60
config.enable_kitty_graphics = true

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

return config
