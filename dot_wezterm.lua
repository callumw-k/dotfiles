-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font_with_fallback({
	"Monaspace Neon",
	"Symbols Nerd Font Mono",
})
config.font_size = 12
config.line_height = 1.1
config.window_close_confirmation = "NeverPrompt"

config.default_prog = { "zellij" }

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Macchiato"

-- and finally, return the configuration to wezterm
return config
