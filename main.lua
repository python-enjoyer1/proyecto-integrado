-- It seems that making the repo private does not change much.
local love = require("love")
local player = require("player")
local enemies = require("enemies")
local utils = require("utils")
local consts = require("constants")
local shaders = require("shaders")
local events = require("events")
local set = require("settings")
local parts = require("particles")
local weapons = require("weapons")
local projs = require("projectiles")
local titlescreen = require("titlescreen")

local canvas

-- Declare variables here, local please.
local desktop_width, desktop_height
local scale_x, scale_y
local mouse_x, mouse_y

local camera_movement
local global_offset_x
local global_offset_y
local look_ahead

--R Tilemap shits
local tilemap

-- HUD elements here.
local soul_bar
local soul_bar_bg
local soul_bar_frame

local cursor
local cursor_selection_box

local background_index
local game_over_background

local vcr_osd_mono

local fps
local time

local slow_down

local enemy_table
local weapon_table

local quit_timer
local quit_hold_time
local quitting

local paused

local seed

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

    quit_hold_time = 3
    quit_timer = quit_hold_time
    quitting = false

    paused = false

    titlescreen.show = false
    titlescreen:init()

    seed = utils.generate_seed()

    love.math.setRandomSeed(seed)

    background_index = love.math.random(1, #shaders.backgrounds)
    game_over_background = shaders.game_over

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

    soul_bar = utils.Animation:new({speed = 0.07, looping = true})
    soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)

    soul_bar_bg = utils.Animation:new({speed = 0.07})
    soul_bar_bg:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_bg.png", 128, 32, 21, 2)

    soul_bar_frame = utils.Animation:new({speed = 0.07, looping = true})
    soul_bar_frame:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_frame.png", 128, 32, 21, 2)

    cursor = utils.Animation:new({speed = 0.1, looping = true})
    cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 8, 8, 4, 2)

    cursor_selection_box = {x = 0, y = 0, width = 8, height = 8, types = {"cursorselectionbox"}}

    enemy_table = {}
    weapon_table = {}

    local map_w = tilemap.width * consts.TILE_SIZE
    local map_h = tilemap.height * consts.TILE_SIZE

    for i = 1, 6 do
        local x = love.math.random(consts.TILE_SIZE, map_w - consts.TILE_SIZE)
        local y = love.math.random(consts.TILE_SIZE, map_h - consts.TILE_SIZE)

        local variant = love.math.random(1, 3)

        local walk_animation = utils.Animation:new({speed = 0.1, looping = true})
        walk_animation:manage_spritesheet(consts.ENEMY_PATH.. "basic_enemy/variation".. variant.. "/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)
        local fall_animation = utils.Animation:new({speed = 0.1, looping = true})
        fall_animation:manage_spritesheet(consts.ENEMY_PATH.. "basic_enemy/variation".. variant.. "/enemy_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1)
        local punch_animation = utils.Animation:new({speed = 0.05, looping = false})
        punch_animation:manage_spritesheet(consts.ENEMY_PATH.. "basic_enemy/variation".. variant.. "/enemy_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)
        local death_animation = utils.Animation:new({speed = 0.2, looping = false})
        death_animation:manage_spritesheet(consts.ENEMY_PATH.. "basic_enemy/variation".. variant.. "/enemy_death.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 5, 2)

        local enemy_variation = love.math.random(1, 3)

        if enemy_variation == 1 then
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 10, speed = love.math.random(140, 160), weight = love.math.random(0.75, 0.85), stun_reduction = love.math.random(1.2, 1.4), stagger = love.math.random(18, 28) ,stability = love.math.random(18, 28)}})) --R sprinters
        elseif enemy_variation == 2 then
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 20, speed = 100}}))
        elseif enemy_variation == 3 then
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 34, speed = love.math.random(70, 90), weight = love.math.random(1.3, 1.45), stun_reduction = -love.math.random(.4, .7), stagger = love.math.random(23, 33), stability = love.math.random(23, 33), knockback = 500}})) --R heavy people
        end
    end

    table.insert(weapon_table, weapons.HeavyGun:new())
end
 
function love.update(dt)
    if not titlescreen.show then
        if events.game_over then
            slow_down = 0.01
        end

        if love.window.hasFocus() and not paused then
            love.audio.setVolume(1.0)
        elseif not events.game_over then
            dt = 0
        end

        if events.screenshake_delay > 0 then
            events.screenshake_delay = events.screenshake_delay - dt

            if events.screenshake_delay <= 0 then
                consts.PARRY_END_SOUND:stop()
                consts.PARRY_END_SOUND:play()
            end
        elseif events.screenshake and events.screenshake_duration > 0 then
            events.screenshake_duration = events.screenshake_duration - dt
        elseif events.screenshake_duration <= 0 then
            events.screenshake = false
        end

        if events.freezeframe_duration > 0 then
            events.freezeframe_duration = events.freezeframe_duration - dt
            dt = 0
        end

        if love.keyboard.isDown(set.keybinds.exit) and quit_timer > 0 and not paused then
            quit_timer = quit_timer - dt
            quitting = true
        elseif love.keyboard.isDown(set.keybinds.exit) and quit_timer <= 0 then
            love.event.quit()
        end

        love.window.setVSync(set.vsync)

        fps = love.timer.getFPS()

        if not paused then
            time = love.timer.getTime()
        end

        camera_movement = player.stats.speed / 25 -- So that when the player gets fast it stays on the screen.

        local target_x = -player.position.x + consts.RENDER_WIDTH / 2 - (player.velocity.x / player.stats.speed) * look_ahead
        local target_y = -player.position.y + consts.RENDER_HEIGHT / 2 - (player.velocity.y / player.stats.speed) * look_ahead

        global_offset_x = utils.lerp(global_offset_x, target_x, camera_movement, dt)
        global_offset_y = utils.lerp(global_offset_y, target_y, camera_movement, dt)

        mouse_x, mouse_y = love.mouse.getPosition()
        mouse_x = (mouse_x / scale_x)
        mouse_y = (mouse_y / scale_y)

        cursor_selection_box.x = mouse_x - global_offset_x
        cursor_selection_box.y = mouse_y - global_offset_y

        if not paused and love.window.hasFocus() then
            if events.freezeframe_duration <= 0 then
                for weapon = 1, #weapon_table do
                    weapon_table[weapon]:update(dt, cursor_selection_box, player)
                end

                for item = 1, #enemy_table do
                    enemy_table[item]:update(dt, player, slow_down, tilemap, enemy_table)
                end

                player:update(dt, scale_x, scale_y, global_offset_x, global_offset_y, enemy_table, slow_down, tilemap, weapon_table)

                for i = #enemy_table, 1, -1 do
                    if not enemy_table[i].render then
                        table.remove(enemy_table, i)
                    end
                end

                projs.update(dt, enemy_table)
            end

            parts.update() --R keeping ts outside cuz it'll prolly look awesome
        end

        -- Shaders.
        shaders.backgrounds[background_index]:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
        shaders.backgrounds[background_index]:send("time", time)

        shaders.game_over:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
        shaders.game_over:send("time", time)

        shaders.chromatic_abr:send("offset", {1 / math.max(player.stats.souls, 0) * 0.005, 1 / math.max(player.stats.souls, 0) * 0.005})

        -- HUD/GUI goes here.
        soul_bar_bg:update(dt)
        soul_bar:update(dt)
        soul_bar_frame:update(dt)
        cursor:update(dt)
    else
        titlescreen:update(dt)
    end

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / scale_x)
    mouse_y = (mouse_y / scale_y)

    cursor_selection_box.x = mouse_x - global_offset_x
    cursor_selection_box.y = mouse_y - global_offset_y

    if events.screenshake_delay > 0 then
        events.screenshake_delay = events.screenshake_delay - dt

        if events.screenshake_delay <= 0 then
            consts.PARRY_END_SOUND:stop()
            consts.PARRY_END_SOUND:play()
        end
    elseif events.screenshake and events.screenshake_duration > 0 then
        events.screenshake_duration = events.screenshake_duration - dt
    elseif events.screenshake_duration <= 0 then
        events.screenshake = false
    end

    if events.freezeframe_duration > 0 then
        events.freezeframe_duration = events.freezeframe_duration - dt
        dt = 0
    end
end

function love.draw()
    love.graphics.setFont(vcr_osd_mono)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    if not titlescreen.show then
        if not events.game_over then
            love.graphics.setShader(shaders.backgrounds[background_index])
        else
            love.graphics.setShader(shaders.game_over)
        end

        love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
        love.graphics.setShader()

        love.graphics.push()
        love.graphics.translate(global_offset_x, global_offset_y)

        if events.screenshake and (events.screenshake_delay or 0) <= 0 and not paused then
            local dx = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
            local dy = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
            love.graphics.translate(dx, dy)
        end

        tilemap:draw(global_offset_x, global_offset_y)

        parts.draw(global_offset_x, global_offset_y)

        projs.draw()

        for weapon = 1, #weapon_table do
            if not weapon_table[weapon].hold then
                weapon_table[weapon]:draw(global_offset_x, global_offset_y)
            else
                break
            end
        end

        for i = 1, #enemy_table do
            enemy_table[i]:draw()
        end

        player:draw()

        for weapon = 1, #weapon_table do
            if weapon_table[weapon].hold then
                weapon_table[weapon]:draw(global_offset_x, global_offset_y)
            else
                break
            end
        end

        love.graphics.pop()

        -- HUD/GUI goes here.
        soul_bar_bg:draw(65, 20)
        love.graphics.setScissor(9 * scale_x, 4 * scale_y, 35 * player.stats.souls / player.stats.soul_limit * scale_x, 32 * scale_y)
        soul_bar:draw(65, 20, 0, 1, set.shading, 0, 4) --R shit above is being held up by hopes and prayers
        love.graphics.setScissor()
        soul_bar_frame:draw(65, 20)

        if set.show_fps and not paused then -- Unholy math here.
            local length = #tostring(fps)
            local x = (1.0 / length) * (consts.RENDER_WIDTH * length * 0.95) + (3 - length) * 7
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", x - length, 1, length * 9, 12, 3, 3)
            love.graphics.setColor(1, 1, 1)

            love.graphics.print(fps, x, 0)
        end

        if events.freezeframe_duration > 0 then
            love.graphics.setColor(1, 1, 1, .3)
            love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
            love.graphics.setColor(1, 1, 1)
        end

        if quitting and not paused then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.print("QUITTING...", 5, 345)
            love.graphics.setColor(1, 1, 1)
        end

        if paused then
            love.graphics.setColor(0, 0, 0, 0.75)
            love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
            love.graphics.setColor(1, 1, 1)
        end

        if paused then
            love.graphics.push()
            love.graphics.translate(-(vcr_osd_mono:getWidth("PAUSED") / 2), -(vcr_osd_mono:getHeight("PAUSED") / 2))
            love.graphics.print("PAUSED", consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2)
            love.graphics.pop()
        end

        love.graphics.setColor(1, 1, 1)

        if set.debug then
            utils.draw_collision({x = mouse_x, y = mouse_y, width = 9, height = 8, types = {"cursorselectionbox"}})
        end
    else
        titlescreen:draw()
    end

    if events.game_over then
        love.graphics.push()
        love.graphics.translate(-(vcr_osd_mono:getWidth("GAME OVER") / 2), -(vcr_osd_mono:getHeight("GAME OVER") / 2))
        love.graphics.print("GAME OVER", consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2)
        love.graphics.pop()
    end

    cursor:draw(mouse_x, mouse_y, 0, 1, set.shading, 0, 2)

    love.graphics.setCanvas()
    love.graphics.draw(canvas, 0, 0, 0, scale_x, scale_y)
    love.graphics.setShader()
end

function love.mousepressed(x, y, button)
    player:mousepressed(button)

    for i = 1, #weapon_table do
        weapon_table[i]:mousepressed(button)
    end
end

function love.keypressed(key, scancode)
    if scancode == set.keybinds.pause and not events.game_over then
        paused = not paused
    end

    player:keypressed(scancode)

    for i = 1, #weapon_table do
        weapon_table[i]:keypressed(scancode)
    end
end

function love.keyreleased(key, scancode)
    if scancode == set.keybinds.exit then
        quitting = false
        quit_timer = quit_hold_time
    end
end