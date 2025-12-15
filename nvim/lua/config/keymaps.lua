-- Keymaps
local map = vim.keymap.set

-- Better escape
map("i", "jk", "<Esc>", { desc = "Escape" })
map("i", "jj", "<Esc>", { desc = "Escape" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
-- Note: <leader>bd handled by snacks.nvim (Snacks.bufdelete)

-- Quickfix
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic quickfix" })
-- Note: [q/]q handled by trouble.nvim with smarter behavior

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Diagnostic navigation
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
