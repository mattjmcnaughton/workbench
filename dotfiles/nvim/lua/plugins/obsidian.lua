local vault_dir = os.getenv("OBSIDIAN_VAULT_DIR")

if vault_dir == nil then
  return {
    "epwalsh/obsidian.nvim",

    dependencies = {
      "nvim-lua/plenary.nvim",
    }
  }
else
  return {
    "epwalsh/obsidian.nvim",

    lazy = false,

    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    event = {
      -- TODO: Replace w/ actual path...
      "BufReadPre " .. vault_dir .. "/*.md",
      "BufNewFile " .. vault_dir .. "/*.md",
    },


    opts = {
      workspaces = {
        {
          name = "second-brain",
          path = vault_dir
        }
      },

      daily_notes = {
        folder = "scheduled/daily",
        default_tags = { "daily" },
      },

      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },

      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",

      preferred_link_style = "markdown",

      templates = {
        folder = "templates",
      },

      -- Disable additional UI to silence warnings.
      ui = {
        enable = false,
      },

      -- Optional, customize how note IDs are generated given an optional title.
      ---@param title string|?
      ---@return string
      note_id_func = function(title)
        -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
        -- In this case a note with the title 'My new note' will be given an ID that looks
        -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
        local suffix = ""
        if title ~= nil then
          -- If title is given, transform it into valid file name.
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- If title is nil, just add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,
    }
  }
end
