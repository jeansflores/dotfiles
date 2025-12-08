return {
	"projekt0n/github-nvim-theme",
	name = "github-theme",
	priority = 1000,
	lazy = false,
	config = function()
		require("github-theme").setup({
			options = {
				transparent = true,
				terminal_colors = true,
				styles = {
					comments = "italic",
					keywords = "bold",
					functions = "italic",
					variables = "bold",
					types = "italic,bold",
				},
			},
		})
		vim.cmd("colorscheme github_dark")
	end,
}
