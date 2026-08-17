return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      -- Mostra arquivos que começam com "." (.env, .envrc, .github, ...)
      hidden = true,
      -- Mostra também arquivos listados no .gitignore (.env costuma estar lá)
      ignored = true,
      -- Ruído que não queremos de volta ao ligar `ignored`
      exclude = {
        ".git",
        ".jj",
        ".hg",
        ".svn",
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        ".mypy_cache",
        ".ruff_cache",
        ".pytest_cache",
        ".terraform",
        ".gradle",
        ".idea",
        "target",
        "dist",
        "build",
        ".next",
        ".nuxt",
        ".svelte-kit",
        ".turbo",
        ".cache",
        "vendor",
        ".DS_Store",
      },
      sources = {
        -- O source `files` traz hidden/ignored = false nos próprios defaults,
        -- o que sobrescreve os globais acima. Precisa repetir aqui.
        files = {
          hidden = true,
          ignored = true,
        },
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              width = 25,
            },
          },
        },
      },
    },
  },
}
