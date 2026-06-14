-- Similar to constants.lua but the values can be changed by the player.
local Main = {}

Main.sfx_volume = 1.0
Main.music_volume = 1.0
Main.screenshake_allowed = true
Main.smooth_camera = true
Main.gore = true
Main.ca_allowed = true -- CA means Chromatic Aberration, the shader that separates the red, green, and blue colors.
Main.show_fps = true
Main.shading = true
Main.vsync = false
Main.debug = false
Main.keybinds = {
    exit = "f1",
    pause = "escape",
    pick_up = "f"
}

return Main