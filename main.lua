-- It seems that making the repo private does not change much.
local love = require("love")
local player = require("player")
local enemies = require("enemies")
local utils = require("utils")
local consts = require("constants")
local shaders = require("shaders")
local events = require("events")
local set = require("settings")

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

local background_index

local vcr_osd_mono

local fps
local time

local slow_down

local enemy_table

local seed

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

    seed = utils.generate_seed()

    love.math.setRandomSeed(seed)

    background_index = love.math.random(1, #shaders.backgrounds) -- Do not touch this line. I'll mess with it later.

    vcr_osd_mono = love.graphics.newFont(consts.FONT_PATH .. "vcr_osd_mono.ttf")
    vcr_osd_mono:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

    fps = love.timer.getFPS()
    time = love.timer.getTime()

    if consts.DEBUG then
        set.show_fps = true
    end

    slow_down = 1.0 -- Might change name later, bigger means faster, smaller means slower.

    canvas = love.graphics.newCanvas(consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
    canvas:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

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

    soul_bar = utils.Animation:new({speed = 0.07, looping = true})
    soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)

    soul_bar_bg = utils.Animation:new({speed = 0.07})
    soul_bar_bg:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_bg.png", 128, 32, 21, 2)

    soul_bar_frame = utils.Animation:new({speed = 0.07, looping = true})
    soul_bar_frame:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_frame.png", 128, 32, 21, 2)

    cursor = utils.Animation:new({speed = 0.1, looping = true})
    cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 8, 8, 4, 2)

    enemy_table = {}
    table.insert(enemy_table, enemy)
end

function love.update(dt)
    love.window.setVSync(set.vsync)

    fps = love.timer.getFPS()
    time = love.timer.getTime() * slow_down

    camera_movement = player.stats.speed / 25 -- So that when the player gets fast it stays on the screen.

    if events.screenshake and events.screenshake_duration > 0 then
        events.screenshake_duration = events.screenshake_duration - dt
    elseif events.screenshake_duration <= 0 then
        events.screenshake = false
    end

    local target_x = -player.position.x + consts.RENDER_WIDTH / 2 - (player.velocity.x / player.stats.speed) * look_ahead
    local target_y = -player.position.y + consts.RENDER_HEIGHT / 2 - (player.velocity.y / player.stats.speed) * look_ahead

    global_offset_x = utils.lerp(global_offset_x, target_x, camera_movement, dt)
    global_offset_y = utils.lerp(global_offset_y, target_y, camera_movement, dt)

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / scale_x)
    mouse_y = (mouse_y / scale_y)

    for item = 1, #enemy_table do
        enemy_table[item]:update(dt, player, slow_down)
    end

    player:update(dt, scale_x, scale_y, global_offset_x, global_offset_y, enemy_table, slow_down)

    for i = 1, #tilemap.walls do
        utils.check_collision(player.hitbox, tilemap.walls[i])
    end

    for i = 1, #tilemap.walls do
        utils.check_collision(player.hitbox, tilemap.walls[i])
    end

    --R enemy wall stuff
    for i = 1, #tilemap.walls do
        utils.check_collision(enemy.hitbox, tilemap.walls[i])
    end

    -- Enemy management.
    for i = 1, #enemy_table do
        if not enemy_table[i].render and not player.states.punch then
            table.remove(enemy_table, i)
        end
    end

    -- Shaders.
    shaders.backgrounds[background_index]:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
    shaders.backgrounds[background_index]:send("time", time)

    shaders.game_over:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
    shaders.game_over:send("time", time)

    -- HUD/GUI goes here.
    soul_bar_bg:update(dt)
    soul_bar:update(dt)
    soul_bar_frame:update(dt)
    cursor:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.setShader(shaders.backgrounds[background_index])
    love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
    love.graphics.setShader()

    love.graphics.push()
    love.graphics.translate(global_offset_x, global_offset_y)

    if events.screenshake then
        local dx = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
        local dy = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
        love.graphics.translate(dx, dy)
    end

    tilemap:draw(global_offset_x, global_offset_y)

    enemy:draw()

    player:draw()

    if consts.DEBUG then
        for i = 1, #tilemap.walls do
            utils.draw_collision(tilemap.walls[i])
        end
    end

    love.graphics.pop()

    -- HUD/GUI goes here.
    soul_bar_bg:draw(65, 20)
    soul_bar:draw(65, 20, 0, 1, set.shading, 0, 4)
    soul_bar_frame:draw(65, 20)

    if set.show_fps then -- Unholy math here.
        local length = #tostring(fps)
        local x = (1.0 / length) * (consts.RENDER_WIDTH * length * 0.95) + (3 - length) * 7

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", x - length, 1, length * 9, 12, 3, 3)
        love.graphics.setColor(1, 1, 1)

        love.graphics.setFont(vcr_osd_mono)
        love.graphics.print(fps, x, 0)
    end

    cursor:draw(mouse_x, mouse_y, 0, 1, set.shading, 0, 2)
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0, 0, scale_x, scale_y)
    love.graphics.setShader()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end