local love = require("love")
local Player = require("player")
local utils = require("utils")

-- Declare variables here, local please.
local fullscreen

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    fullscreen = false
end

function love.update(dt)
    Player:update(dt)
end

function love.draw()
    Player:draw()
end

-- Jokes on you, it's still here.
--R what the fuck
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "f11" then
        fullscreen = not fullscreen
        love.window.setFullscreen(fullscreen, "desktop")
    end
end