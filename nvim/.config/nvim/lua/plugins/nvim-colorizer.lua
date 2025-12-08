return {
	"norcalli/nvim-colorizer.lua",
	config = function()
		require("colorizer").setup({
			"*",
			css = { rgb_fn = true },
			html = { names = true }, -- Desabilita nomes de cores (ex: "Blue") no HTML
		}, {
			RGB = true,
			RRGGBB = true,
			names = true,
			RRGGBBAA = true,
			AARRGGBB = true,
			rgb_fn = true,
			hsl_fn = true,
			css = false,
			css_fn = false,

			mode = "background",
		})
	end,
}
