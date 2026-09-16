# Paletas de ghostty vendorizadas

O ghostty já traz os temas de todos os nossos slugs, menos os três jellybeans.
Estes arquivos vieram de [`WTFox/jellybeans.nvim`](https://github.com/WTFox/jellybeans.nvim),
pasta `extras/ghostty`, baixados em **2026-09-16**:

| arquivo | fundo |
| --- | --- |
| `jellybeans-muted` | `#101010` |
| `jellybeans-mono` | `#151515` |
| `jellybeans-hc` | `#060606` |

O manifesto do tema aponta para eles por `ghostty_file=`, e o `render_ghostty`
concatena o conteúdo no `~/.config/ghostty/theme.conf`. Para atualizar, baixe de
novo de `extras/ghostty` e rode `./tests/theme-test.sh` — a asserção de coerência
acusa se o fundo do arquivo divergir dos papéis do manifesto.
