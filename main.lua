local love = require("love")
local Player = require("player")
local utils = require("utils")

-- Declare variables here, local please.
local desktop_width, desktop_height
local scale_x, scale_y

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- Makes it so pixel art doesn't look blurry as shit.
    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = desktop_width / love.graphics.getWidth()
    scale_y = desktop_height / love.graphics.getHeight()
end

function love.update(dt)
    Player:update(dt)
end

function love.draw()
    love.graphics.scale(scale_x, scale_y)
    Player:draw()
end

-- Jokes on you, it's still here.
--R what the fuck
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end