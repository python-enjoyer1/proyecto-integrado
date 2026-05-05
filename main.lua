-- It seems that making the repo private does not change much.
local love = require("love")
local player = require("player")
local enemies = require("enemies")
local utils = require("utils")
local consts = require("constants")
local shaders = require("shaders")

local canvas

-- Declare variables here, local please.
local desktop_width, desktop_height
local scale_x, scale_y
local mouse_x, mouse_y

local camera_movement
local global_offset_x
local global_offset_y
local look_ahead

local enemy

--R Tilemap shits
local tilemap

-- HUD elements here.
local soul_bar
local soul_bar_bg
local soul_bar_frame

local cursor


-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

    canvas = love.graphics.newCanvas(consts.RENDER_WIDTH, consts.RENDER_HEIGHT)

    camera_movement = 0
    global_offset_x = 0
    global_offset_y = 0
    look_ahead = 40

    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = desktop_width / consts.RENDER_WIDTH
    scale_y = desktop_height / consts.RENDER_HEIGHT

    tilemap = utils.Tilemap:new({type = "high", width = 1, height = 1})
    tilemap:generate(3, 3)

    player.position.x = (tilemap.width * consts.TILE_SIZE) / 2
    player.position.y = (tilemap.height * consts.TILE_SIZE) / 2

    enemy = enemies.Enemy:new()

    soul_bar = utils.Animation:new({speed = 0.07})
    soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)

    soul_bar_bg = utils.Animation:new({speed = 0.07})
    soul_bar_bg:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_bg.png", 128, 32, 21, 2)

    soul_bar_frame = utils.Animation:new({speed = 0.07})
    soul_bar_frame:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_frame.png", 128, 32, 21, 2)

    cursor = utils.Animation:new({speed = 0.1})
    cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 8, 8, 4, 2)
end

function love.update(dt)
    camera_movement = player.stats.speed / 25 -- So that when the player gets fast it stays on the screen.

    local target_x = -player.position.x + consts.RENDER_WIDTH / 2 - (player.velocity.x / player.stats.speed) * look_ahead
    local target_y = -player.position.y + consts.RENDER_HEIGHT / 2 - (player.velocity.y / player.stats.speed) * look_ahead

    global_offset_x = utils.lerp(global_offset_x, target_x, camera_movement, dt)
    global_offset_y = utils.lerp(global_offset_y, target_y, camera_movement, dt)

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / scale_x)
    mouse_y = (mouse_y / scale_y)

    enemy:update(dt, player)

    player:update(dt, scale_x, scale_y, global_offset_x, global_offset_y)

    for i = 1, #tilemap.walls do
        utils.check_collision(player.hitbox, tilemap.walls[i])
    end

    player.position.x = player.hitbox.x
    player.position.y = player.hitbox.y

    -- HUD/GUI goes here.
    soul_bar_bg:update(dt)
    soul_bar:update(dt)
    soul_bar_frame:update(dt)
    cursor:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.setShader(shaders.background)
    shaders.background:send("screen_size", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
    love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
    love.graphics.setShader()

    love.graphics.push()
    love.graphics.translate(global_offset_x, global_offset_y)

    tilemap:draw()

    enemy:draw()

    player:draw()

    if consts.DEBUG then
        for i = 1, #tilemap.walls do
            utils.draw_collision(tilemap.walls[i]) -- Great code.
        end
    end

    love.graphics.pop()

    -- HUD/GUI goes here.

    soul_bar_bg:draw(65, 20)
    soul_bar:draw(65, 20, 0, 1, consts.SHADING, 0, 4)
    soul_bar_frame:draw(65, 20)

    cursor:draw(mouse_x, mouse_y, 0, 1, consts.SHADING, 0, 2)
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0, 0, scale_x, scale_y)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end