local love = require("love")
local player = require("player")
local utils = require("utils")
local consts = require("constants")

-- Declare variables here, local please. We could move the render_width and height to a constants.lua.
local desktop_width, desktop_height
local scale_x, scale_y
local mouse_x, mouse_y

local global_offset_x
local global_offset_y

--R Tilemap shits
local tilemap

-- HUD elements here.
local soul_bar
local cursor

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)

    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = math.floor(desktop_width / consts.RENDER_WIDTH)
    scale_y = math.floor(desktop_height / consts.RENDER_HEIGHT)

    tilemap = utils.Tilemap:new({type = "high", width = 1, height = 1})
    tilemap:generate(3)

    player.position.x = (tilemap.width * consts.TILE_SIZE) / 2
    player.position.y = (tilemap.height * consts.TILE_SIZE) / 2

    soul_bar = utils.Animation:new({speed = 0.07})
    cursor = utils.Animation:new({speed = 0.1})

    soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)
    cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 8, 8, 4, 2)
end

function love.update(dt)
    global_offset_x = -player.position.x + (consts.RENDER_WIDTH / 2)
    global_offset_y = -player.position.y + (consts.RENDER_HEIGHT / 2)

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / scale_x)
    mouse_y = (mouse_y / scale_y)

    player:update(dt, scale_x, scale_y, global_offset_x, global_offset_y)

    -- HUD/GUI goes here.
    soul_bar:update(dt)
    cursor:update(dt)
end

function love.draw()
    love.graphics.scale(scale_x, scale_y)

    love.graphics.push()
    love.graphics.translate(global_offset_x, global_offset_y)

    tilemap:draw()

    player:draw()
    love.graphics.pop()

    -- HUD/GUI goes here.
    soul_bar:draw(65, 20, 0, 1, consts.SHADING, 0, 3)
    cursor:draw(mouse_x, mouse_y, 0, 1, consts.SHADING, 0, 2)

end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end