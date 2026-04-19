local love = require("love")

function love.conf(t)
    t.window.title = "Proyecto Integrado"
    t.window.width = 640 -- You can honestly put any size that scales to modern resolutions but this is the recommended.
    t.window.height = 360
    t.window.fullscreentype = "desktop"
end