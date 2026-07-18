return {
  -- ─── Oil: edit your filesystem like a buffer ⭐6.5k ──────────────────
  -- Genuinely different from any tree explorer: open a buffer of the
  -- directory, edit it like text, write to save. Pairs with snacks.explorer.
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,  -- snacks.explorer handles netrw
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = { show_hidden = true },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = { "actions.cd", opts = { scope = "tab" } },
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
      },
    },
    keys = {
      { "-",          "<cmd>Oil<CR>",          desc = "Open parent (Oil)" },
      { "<leader>fo", "<cmd>Oil --float<CR>",  desc = "Oil (floating)" },
    },
  },

  -- ─── Harpoon 2: pinned-file jump list ⭐9k ───────────────────────────
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local h = function() return require("harpoon") end
      return {
        { "<leader>H",  function() h():list():add() end,                                desc = "Harpoon add" },
        { "<leader>h",  function() h().ui:toggle_quick_menu(h():list()) end,            desc = "Harpoon menu" },
        { "<leader>1",  function() h():list():select(1) end,                            desc = "Harpoon 1" },
        { "<leader>2",  function() h():list():select(2) end,                            desc = "Harpoon 2" },
        { "<leader>3",  function() h():list():select(3) end,                            desc = "Harpoon 3" },
        { "<leader>4",  function() h():list():select(4) end,                            desc = "Harpoon 4" },
        { "<leader>5",  function() h():list():select(5) end,                            desc = "Harpoon 5" },
        { "[H",         function() h():list():prev() end,                               desc = "Harpoon prev" },
        { "]H",         function() h():list():next() end,                               desc = "Harpoon next" },
      }
    end,
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
  },

  -- ─── Render Markdown ⭐4.5k ──────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante", "codecompanion" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      file_types = { "markdown", "Avante", "codecompanion" },
      heading = { sign = false, position = "inline" },
      code = { sign = false, width = "block", right_pad = 1 },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked   = { icon = " " },
        custom = {
          todo  = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
        },
      },
    },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown Render" },
    },
  },

  -- ─── nvim-ufo: smarter folding ⭐3k ──────────────────────────────────
  {
    "kevinhwang91/nvim-ufo",
    event = "BufReadPost",
    dependencies = { "kevinhwang91/promise-async" },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
      preview = { win_config = { border = "rounded" } },
    },
    keys = {
      { "zR", function() require("ufo").openAllFolds() end,  desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds except kinds" },
      { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close folds with" },
      { "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
  },

  -- ─── Edgy: window/sidebar manager (folke) ⭐1.1k ─────────────────────
  -- Forces trouble/snacks-explorer/help/quickfix into predictable side
  -- panels so the layout doesn't get chaotic.
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      animate = { enabled = false },
      bottom = {
        { ft = "qf",            title = "QuickFix" },
        { ft = "help",          size = { height = 20 }, filter = function(buf) return vim.bo[buf].buftype == "help" end },
        { ft = "trouble",       filter = function(_, win) return vim.w[win].trouble and vim.w[win].trouble.position == "bottom" end },
        { ft = "snacks_terminal", size = { height = 0.4 }, title = "%{b:snacks_terminal.id}", filter = function(_, win) return vim.w[win].snacks_win and vim.w[win].snacks_win.position == "bottom" end },
      },
      left = {
        { title = "Explorer",  ft = "snacks_layout_box" },
        { title = "Outline",   ft = "trouble", filter = function(_, win) return vim.w[win].trouble and vim.w[win].trouble.position == "left" end },
      },
      right = {
        { title = "Trouble",   ft = "trouble", filter = function(_, win) return vim.w[win].trouble and vim.w[win].trouble.position == "right" end },
      },
      keys = {
        ["<c-Right>"] = function(win) win:resize("width", 2) end,
        ["<c-Left>"]  = function(win) win:resize("width", -2) end,
        ["<c-Up>"]    = function(win) win:resize("height", 2) end,
        ["<c-Down>"]  = function(win) win:resize("height", -2) end,
      },
    },
    keys = {
      { "<leader>ue", function() require("edgy").toggle() end, desc = "Toggle Edgy" },
    },
  },

  -- ─── Claude Code IDE integration ⭐2.7k ──────────────────────────────
  -- Bridges Claude Code with nvim — selections, diffs, file context.
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start = true,
      terminal_cmd = nil,                 -- defaults to `claude`
      log_level = "info",
      track_selection = true,
      visual_demotion_delay_ms = 50,
      port_range = { min = 10000, max = 65535 },
      auto_start_lock_server = true,
      terminal = {
        split_side = "right",
        split_width_percentage = 0.35,
        provider = "snacks",              -- uses snacks.terminal
        auto_close = true,
        snacks_win_opts = {
          keys = {
            claude_hide = { "<C-,>", function(self) self:hide() end, mode = "t", desc = "Hide" },
          },
        },
      },
      diff_opts = {
        auto_close_on_accept = true,
        show_diff_stats = true,
        vertical_split = true,
        open_in_current_tab = true,
      },
    },
    cmd = {
      "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeOpen", "ClaudeCodeSend",
      "ClaudeCodeTreeAdd", "ClaudeCodeAdd", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny",
    },
    keys = {
      { "<leader>a",  nil,                              desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<CR>",            desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<CR>",       desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<CR>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<CR>", desc = "Continue Claude" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>",       desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<CR>",        desc = "Send to Claude",        mode = "v" },
      { "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>",     desc = "Add file from tree",    ft = { "snacks_layout_box" } },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>",  desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>",    desc = "Deny diff" },
    },
  },
}
