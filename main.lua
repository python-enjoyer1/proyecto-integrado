local love = require("love")
local Player = require("player")
local utils = require("utils")
local consts = require("constants")

-- Declare variables here, local please. We could move the render_width and height to a constants.lua.
local desktop_width, desktop_height
local scale_x, scale_y
local mouse_x, mouse_y

-- HUD elements here.
local soul_bar = utils.Animation:new({speed = 0.07})
local cursor = utils.Animation:new({speed = 0.1})

soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)
cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 16, 16, 4, 2)

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)

    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = math.floor(desktop_width / consts.RENDER_WIDTH)
    scale_y = math.floor(desktop_height / consts.RENDER_HEIGHT)
end

function love.update(dt)
    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / scale_x
    mouse_y = mouse_y / scale_y

    Player:update(dt, scale_x, scale_y)

    -- HUD/GUI goes here.
    soul_bar:update(dt)
    cursor:update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.3, 0.3, 0.3)
    love.graphics.scale(scale_x, scale_y)

    Player:draw()

    -- HUD/GUI goes here.
    soul_bar:draw(65, 20, 0, 1, consts.SHADING, 0, 3)
    cursor:draw(mouse_x, mouse_y, 0, 1, consts.SHADING, 0, 3)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end