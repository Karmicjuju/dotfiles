local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- OS detection (Mac vs Linux)
local function is_macos()
  return wezterm.target_triple:find("darwin") ~= nil
end

-- Set proper terminal type
config.term = "xterm-256color"
config.use_ime = true

-- Font configuration
config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'JetBrains Mono',
  'monospace',
})
config.font_size = is_macos() and 14.5 or 11.0

-- Color scheme
config.color_scheme = 'Catppuccin Frappe'
config.bold_brightens_ansi_colors = true

-- Transparency and blur
if is_macos() then
  config.window_background_opacity = 0.88
  config.macos_window_background_blur = 24
  config.native_macos_fullscreen_mode = true
  -- Make Option key work as Alt (for Alt+hjkl navigation etc.) instead of macOS compose
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
config.window_padding = {
  left = 10,
  right = 10,
  top = 12,
  bottom = 12,
}

-- Scrollback and selection
config.scrollback_lines = 50000
config.selection_word_boundary = ' \t\n{}[]()"\',;:'

-- Tab bar
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

-- Leader key (Ctrl+Space for tmux-style bindings)
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Key bindings
config.keys = {
  -- Send Ctrl+a when pressing leader twice
  { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },

  -- Splitting panes (tmux style)
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Navigate panes (vim keys)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Resize panes
  { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Tab management
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = '&', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true } },
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },

  -- Pane management
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'q', mods = 'LEADER', action = act.PaneSelect },

  -- Copy mode
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },
  { key = ']', mods = 'LEADER', action = act.PasteFrom 'Clipboard' },

  -- Line navigation
  { key = 'LeftArrow', mods = 'ALT', action = act.SendKey { key = 'b', mods = 'ALT' } },
  { key = 'RightArrow', mods = 'ALT', action = act.SendKey { key = 'f', mods = 'ALT' } },
}

-- OS-specific clipboard and shortcuts
if is_macos() then
  local mac_keys = {
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },
    { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = '0', mods = 'CMD', action = act.ResetFontSize },
    { key = '+', mods = 'CMD', action = act.IncreaseFontSize },
    { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
    { key = 'LeftArrow', mods = 'CMD', action = act.SendKey { key = 'a', mods = 'CTRL' } },
    { key = 'RightArrow', mods = 'CMD', action = act.SendKey { key = 'e', mods = 'CTRL' } },
  }
  for _, k in ipairs(mac_keys) do table.insert(config.keys, k) end
else
  local linux_keys = {
    { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
    { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
    { key = 'k', mods = 'CTRL', action = act.ClearScrollback 'ScrollbackAndViewport' },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },
    { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'PrimarySelection' },
    { key = 'LeftArrow', mods = 'CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
    { key = 'RightArrow', mods = 'CTRL', action = act.SendKey { key = 'e', mods = 'CTRL' } },
  }
  for _, k in ipairs(linux_keys) do table.insert(config.keys, k) end
end

-- Split styling
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.9,
}

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

return config
