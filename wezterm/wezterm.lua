local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- OS detection
local function get_os()
  local target = wezterm.target_triple
  if target:find("windows") then
    return "windows"
  elseif target:find("darwin") then
    return "macos"
  else
    return "linux"
  end
end

local os = get_os()

-- Helper to get the appropriate modifier key for the OS
local function cmd_or_ctrl()
  if os == "macos" then
    return "CMD"
  else
    return "CTRL"
  end
end

-- Set proper terminal type
config.term = "xterm-256color"

-- Fix key encoding issues
config.enable_csi_u_key_encoding = false
config.use_ime = true

-- Font configuration (OS-specific)
if os == "windows" then
  config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Medium' })
  config.font_size = 12.0
  -- Windows often needs different font fallbacks
  config.font = wezterm.font_with_fallback({
    'JetBrainsMono Nerd Font',
    'JetBrains Mono',
    'Cascadia Code',
    'Consolas',
  })
elseif os == "macos" then
  config.font = wezterm.font('JetBrainsMono Nerd Font')
  config.font_size = 14.5
else -- Linux (Arch)
  config.font = wezterm.font('JetBrainsMono Nerd Font')
  config.font_size = 11.0
  -- Linux might need font fallbacks too
  config.font = wezterm.font_with_fallback({
    'JetBrainsMono Nerd Font',
    'JetBrains Mono',
    'DejaVu Sans Mono',
    'monospace',
  })
end

-- Color scheme (Catppuccin)
config.color_scheme = 'Catppuccin Frappe'

-- Transparency and blur (OS-specific)
if os == "macos" then
  config.window_background_opacity = 0.88
  config.macos_window_background_blur = 24
  -- macOS specific window settings
  config.native_macos_fullscreen_mode = true
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false
elseif os == "linux" then
  config.window_background_opacity = 0.92
  -- Linux doesn't have native blur, but transparency works
  -- Wayland/X11 specific settings can go here if needed
  config.enable_wayland = true  -- Enable Wayland support when available
elseif os == "windows" then
  config.window_background_opacity = 0.95
  -- Windows 11 supports acrylic blur
  config.win32_system_backdrop = 'Acrylic'
  -- Windows specific settings
  config.default_prog = { 'pwsh.exe' }  -- PowerShell Core if available, or use cmd.exe
end

-- Make colors pop more
config.bold_brightens_ansi_colors = true

-- Padding
config.window_padding = {
  left = 10,
  right = 10,
  top = 12,
  bottom = 12,
}

-- Selection behavior
config.selection_word_boundary = ' \t\n{}[]()"\',;:'

-- Scrollback
config.scrollback_lines = 128000000

-- Color space and rendering (OS-specific)
if os == "macos" then
  config.front_end = "WebGpu"  -- Better color handling on macOS
elseif os == "windows" then
  config.front_end = "WebGpu"  -- Also good on Windows
else -- Linux
  -- WebGpu might not work on all Linux systems, fallback to OpenGL
  config.front_end = "OpenGL"
end

-- Tab bar styling
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

-- Shell integration (OS-specific)
if os == "windows" then
  -- Try PowerShell Core first, then Windows PowerShell, then cmd
  config.default_prog = { 'pwsh.exe' }
  config.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh.exe' } },
    { label = 'Windows PowerShell', args = { 'powershell.exe' } },
    { label = 'Command Prompt', args = { 'cmd.exe' } },
    { label = 'Git Bash', args = { 'C:\\Program Files\\Git\\bin\\bash.exe' } },
  }
elseif os == "macos" then
  -- Let WezTerm auto-detect on macOS (uses default shell)
  -- config.default_prog = { '/bin/zsh' }
elseif os == "linux" then
  -- Check for common shells on Linux
  config.default_prog = { '/usr/bin/zsh' }  -- Arch typically has zsh here
  -- Fallback options
  config.launch_menu = {
    { label = 'Zsh', args = { '/usr/bin/zsh' } },
    { label = 'Bash', args = { '/usr/bin/bash' } },
    { label = 'Fish', args = { '/usr/bin/fish' } },
  }
end

-- Leader key (Ctrl+Space for consistency across platforms)
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Key bindings
config.keys = {
  -- Send Ctrl+a when pressing leader twice
  {
    key = 'a',
    mods = 'LEADER|CTRL',
    action = act.SendKey { key = 'a', mods = 'CTRL' },
  },
  
  -- Splitting panes (tmux style)
  {
    key = '%',
    mods = 'LEADER|SHIFT',  -- Shift+5 = %
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '"',
    mods = 'LEADER|SHIFT',  -- Shift+' = "
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Alternative split bindings (more convenient)
  {
    key = '|',
    mods = 'LEADER|SHIFT',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  
  -- Navigate panes (tmux style with vim keys)
  {
    key = 'h',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Down',
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'l',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Right',
  },
  -- Arrow key navigation (tmux default)
  {
    key = 'LeftArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'DownArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Down',
  },
  {
    key = 'UpArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'RightArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Right',
  },
  
  -- Resize panes (tmux style)
  {
    key = 'H',
    mods = 'LEADER|SHIFT',
    action = act.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'J',
    mods = 'LEADER|SHIFT',
    action = act.AdjustPaneSize { 'Down', 5 },
  },
  {
    key = 'K',
    mods = 'LEADER|SHIFT',
    action = act.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'L',
    mods = 'LEADER|SHIFT',
    action = act.AdjustPaneSize { 'Right', 5 },
  },
  
  -- Tab management (tmux style)
  {
    key = 'c',
    mods = 'LEADER',
    action = act.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = act.ActivateTabRelative(1),
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = act.ActivateTabRelative(-1),
  },
  {
    key = '&',
    mods = 'LEADER|SHIFT',
    action = act.CloseCurrentTab { confirm = true },
  },
  -- Number keys to jump to tabs
  {
    key = '1',
    mods = 'LEADER',
    action = act.ActivateTab(0),
  },
  {
    key = '2',
    mods = 'LEADER',
    action = act.ActivateTab(1),
  },
  {
    key = '3',
    mods = 'LEADER',
    action = act.ActivateTab(2),
  },
  {
    key = '4',
    mods = 'LEADER',
    action = act.ActivateTab(3),
  },
  {
    key = '5',
    mods = 'LEADER',
    action = act.ActivateTab(4),
  },
  
  -- Close pane (tmux style)
  {
    key = 'x',
    mods = 'LEADER',
    action = act.CloseCurrentPane { confirm = true },
  },
  
  -- Zoom pane (tmux style)
  {
    key = 'z',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },
  
  -- Copy mode (tmux style)
  {
    key = '[',
    mods = 'LEADER',
    action = act.ActivateCopyMode,
  },
  
  -- Paste (tmux style)
  {
    key = ']',
    mods = 'LEADER',
    action = act.PasteFrom 'Clipboard',
  },
  
  -- Show pane selector (tmux style)
  {
    key = 'q',
    mods = 'LEADER',
    action = act.PaneSelect,
  },
  
  -- Detach (close window but keep panes - closest equivalent)
  {
    key = 'd',
    mods = 'LEADER',
    action = act.DetachDomain 'CurrentPaneDomain',
  },
  
  -- OS-agnostic shortcuts (use cmd_or_ctrl helper)
  -- Clear screen
  {
    key = 'k',
    mods = cmd_or_ctrl(),
    action = act.ClearScrollback 'ScrollbackAndViewport',
  },
  -- Reset font size
  {
    key = '0',
    mods = cmd_or_ctrl(),
    action = act.ResetFontSize,
  },
  -- Font size adjustments
  {
    key = '+',
    mods = cmd_or_ctrl(),
    action = act.IncreaseFontSize,
  },
  {
    key = '-',
    mods = cmd_or_ctrl(),
    action = act.DecreaseFontSize,
  },
  
  -- Line navigation (OS-specific)
  {
    key = 'LeftArrow',
    mods = cmd_or_ctrl(),
    action = act.SendKey { key = 'a', mods = 'CTRL' },  -- Beginning of line
  },
  {
    key = 'RightArrow',
    mods = cmd_or_ctrl(),
    action = act.SendKey { key = 'e', mods = 'CTRL' },  -- End of line
  },
  {
    key = 'LeftArrow',
    mods = 'ALT',
    action = act.SendKey { key = 'b', mods = 'ALT' },  -- Back one word
  },
  {
    key = 'RightArrow',
    mods = 'ALT',
    action = act.SendKey { key = 'f', mods = 'ALT' },  -- Forward one word
  },
}

-- Add OS-specific keybindings
if os == "windows" then
  -- Windows-specific bindings
  table.insert(config.keys, {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = act.PasteFrom 'Clipboard',
  })
  table.insert(config.keys, {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = act.CopyTo 'Clipboard',
  })
elseif os == "macos" then
  -- macOS-specific bindings (keep existing CMD shortcuts)
  table.insert(config.keys, {
    key = 'v',
    mods = 'CMD',
    action = act.PasteFrom 'Clipboard',
  })
  table.insert(config.keys, {
    key = 'c',
    mods = 'CMD',
    action = act.CopyTo 'Clipboard',
  })
elseif os == "linux" then
  -- Linux-specific bindings
  table.insert(config.keys, {
    key = 'v',
    mods = 'CTRL|SHIFT',
    action = act.PasteFrom 'Clipboard',
  })
  table.insert(config.keys, {
    key = 'c',
    mods = 'CTRL|SHIFT',
    action = act.CopyTo 'Clipboard',
  })
  -- Additional Linux clipboard support for selection buffer
  table.insert(config.keys, {
    key = 'Insert',
    mods = 'SHIFT',
    action = act.PasteFrom 'PrimarySelection',
  })
end

-- Split styling
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.9,
}

-- Visual bell instead of audio
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

-- Enable Kitty graphics protocol (for image support in terminals)
config.enable_kitty_graphics = true

return config