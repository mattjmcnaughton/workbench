return {
  "mattjmcnaughton/llm-chat.nvim",
  branch = "main",

  config = function()
    require("llm_chat").setup({
      litellm = {
        url = os.getenv("LITELLM_URL"),
        timeout = 30,
        api_key_env = "LITELLM_API_KEY",
      },

      -- Logging configuration
      logger = {
        enabled = true, -- Enable logging
        directory = vim.fn.stdpath('data') .. '/llm_chat_logs',
      },

      -- Persona configuration
      personas = {
        directory = vim.fn.stdpath('config') .. '/llm-personas', -- Directory for personas
        default = "default", -- Default persona to use
      },

      -- Model configuration
      models = {
        default = "anthropic-claude-3-7-sonnet", -- Fallback model if discovery fails
        cache_ttl = 3600, -- How long to cache model list (in seconds)
      },

      -- Chat buffer appearance
      buffer = {
        filetype = "markdown", -- Use markdown for syntax highlighting
        user_prefix = "🧑 User: ", -- Prefix for user messages
        assistant_prefix = "🖥️ Assistant: ", -- Prefix for assistant responses
      },

      -- Keymaps for chat buffer (nil means no mapping)
      keymaps = {
        send = "<C-s>", -- Ctrl+s to send message
        new_chat = "<C-n>", -- Ctrl+n to start new chat
      },
    })
  end
}
