-- lsp.lua - LSP configuration for Neovim 0.11+

-- Configure Ruff LSP
vim.lsp.config.ruff_lsp = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", ".git" },
  init_options = {
    settings = {
      -- Any extra CLI arguments for Ruff go here
      args = {},
    }
  }
}

-- Configure Pyright
vim.lsp.config.pyright = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", ".git" },
  settings = {
    pyright = {
      -- Disable import organization since Ruff will handle this
      disableOrganizeImports = true,
      disableTaggedHints = true,
    },
    python = {
      analysis = {
        -- Disable specific diagnostics to avoid duplicates with Ruff
        diagnosticSeverityOverrides = {
          reportUndefinedVariable = "none",
          -- Add other diagnostics you want to disable
        },
        -- Keep type checking enabled
        typeCheckingMode = "basic",
      },
    },
  },
  -- Configure capabilities to handle duplicate diagnostics
  capabilities = {
    textDocument = {
      publishDiagnostics = {
        tagSupport = {
          valueSet = { 2 }, -- This marks certain diagnostics as "unnecessary"
        },
      },
    },
  },
}

-- Configure gopls
vim.lsp.config.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        nilness = true,
        unusedwrite = true,
        useany = true,
      },
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      completeUnimported = true,
      semanticTokens = true,
      codelenses = {
        generate = true,
        test = true,
        tidy = true,
      },
    },
  },
}

-- Configure lua-language-server
vim.lsp.config.lua_ls = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    '.git',
  },
  settings = {
    Lua = {
      runtime = {
        -- Specify LuaJIT for Neovim
        version = "LuaJIT",
        path = vim.split(package.path, ";"),
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

-- Enable both language servers
vim.lsp.enable({"ruff_lsp", "pyright", "gopls", "lua_ls" })

-- Create an autocmd group for LSP-related autocmds
local lsp_group = vim.api.nvim_create_augroup('lsp_config', { clear = true })

-- Disable Ruff LSP hover in favor of Pyright
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'ruff_lsp' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

-- Auto-format on save
vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- Auto-format on save if the client supports it
    if client and client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = lsp_group,
        buffer = args.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
        end,
        desc = 'LSP: Format on save',
      })
    end
  end,
})
