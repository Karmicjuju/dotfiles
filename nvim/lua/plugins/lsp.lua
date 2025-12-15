return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
      inlay_hints = { enabled = true },
      codelens = { enabled = false },
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              completion = { callSnippet = "Replace" },
              hint = { enable = true },
            },
          },
        },
        pyright = {},
        ruff = {},
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = { command = "clippy" },
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
              gofumpt = true,
            },
          },
        },
        ts_ls = {},
        clangd = {},
        bashls = {},
        terraformls = {},
        ansiblels = {},
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              },
            },
          },
        },
        taplo = {},
        jsonls = {},
        html = {},
        cssls = {},
      },
    },
    config = function(_, opts)
      -- Diagnostics
      vim.diagnostic.config(opts.diagnostics)

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", "<cmd>Telescope lsp_definitions<CR>", "Goto Definition")
          map("gr", "<cmd>Telescope lsp_references<CR>", "References")
          map("gI", "<cmd>Telescope lsp_implementations<CR>", "Goto Implementation")
          map("gy", "<cmd>Telescope lsp_type_definitions<CR>", "Goto Type Definition")
          map("gD", vim.lsp.buf.declaration, "Goto Declaration")
          map("K", vim.lsp.buf.hover, "Hover")
          map("gK", vim.lsp.buf.signature_help, "Signature Help")
          map("<c-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "v" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cA", function()
            vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
          end, "Source Action")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Inlay hints
          if client and client:supports_method("textDocument/inlayHint") then
            if opts.inlay_hints.enabled then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
            map("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "Toggle Inlay Hints")
          end

          -- Document highlight
          if client and client:supports_method("textDocument/documentHighlight") then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp_highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp_detach", { clear = true }),
              callback = function(e)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "lsp_highlight", buffer = e.buf })
              end,
            })
          end
        end,
      })

      -- Setup servers via mason-lspconfig
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local servers = opts.servers

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})
        require("lspconfig")[server].setup(server_opts)
      end

      local have_mason, mlsp = pcall(require, "mason-lspconfig")
      local all_servers = vim.tbl_keys(servers)

      if have_mason then
        mlsp.setup({
          ensure_installed = all_servers,
          handlers = { setup },
        })
      else
        for _, server in ipairs(all_servers) do
          setup(server)
        end
      end
    end,
  },

  -- Mason: Package manager for LSP servers
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },

  -- Mason-lspconfig: Bridge between mason and lspconfig
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = true,
  },

  -- Mason tool installer
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
    opts = {
      ensure_installed = {
        "stylua",
        "biome",
        "prettierd",
        "shfmt",
        "ruff",
        "goimports",
        "ansible-lint",
      },
    },
  },

  -- Fidget: LSP progress
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {},
  },
}
