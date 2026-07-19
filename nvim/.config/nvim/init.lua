-- Neovim Configuration
-- Leader keys must be set before lazy.nvim loads
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable Nerd Font icons (JetBrainsMono Nerd Font configured in WezTerm)
vim.g.have_nerd_font = true

-- Load configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
