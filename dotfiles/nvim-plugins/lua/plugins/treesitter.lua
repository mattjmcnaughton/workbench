return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "rust", "go", "bash", "typescript", "javascript", "lua",
        "python", "json", "yaml", "nix", "dockerfile", "c",
        "gitcommit", "markdown", "tsx", "gitignore", "toml",
        "markdown_inline", "vimdoc"
      },

      sync_install = true,
      auto_install = true,

      indent = {
        enable = true
      },
    })
  end
}
