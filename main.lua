local love = require("love")
local Player = require("player")
local utils = require("utils")
local consts = require("constants")

-- Declare variables here, local please. We could move the render_width and height to a constants.lua.
local render_width, render_height
local desktop_width, desktop_height
local scale_x, scale_y
local animation

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    render_width, render_height = 640, 360
    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = desktop_width / render_width
    scale_y = desktop_height / render_height
    animation = utils.Animation:new({0.3})
    animation:manage_spritesheet("stuff/assets/items/apple_serpent.png", consts.SPRITE_SIZE, 22, 5)

    love.graphics.setDefaultFilter("nearest", "nearest") -- Makes it so pixel art doesn't look blurry as shit.
end

function love.update(dt)
    animation:update(dt)
    Player:update(dt)
end

function love.draw()
    animation:draw(100, 100, 1)
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