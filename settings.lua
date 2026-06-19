-- Similar to constants.lua but the values can be changed by the player.
local set = {}

set.master_volume = 1.0
set.sfx_volume = 1.0
set.music_volume = 1.0
set.screenshake_allowed = true
set.smooth_camera = true
set.gore = false
set.ca_allowed = true -- CA means Chromatic Aberration, the shader that separates the red, green, and blue colors.
set.show_fps = true
set.shading = true
set.vsync = false
set.debug = false
set.keybinds = {
    exit = "f1",
    pause = "escape",
    pick_up = "f",
    lower_vol = "f2",
    raise_vol = "f3"
}

return set