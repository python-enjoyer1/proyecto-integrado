local love = require("love")

function love.conf(t)
    t.window.title = "METRO ANIMUS"
    t.window.width = 640
    t.window.height = 360
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
end