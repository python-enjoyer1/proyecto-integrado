local love = require("love")
local Player = require("player")
local utils = require("utils")
local consts = require("constants")

-- Declare variables here, local please. We could move the render_width and height to a constants.lua.
local desktop_width, desktop_height
local scale_x, scale_y

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = desktop_width / consts.RENDER_WIDTH
    scale_y = desktop_height / consts.RENDER_HEIGHT
    love.graphics.setDefaultFilter("nearest", "nearest")
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