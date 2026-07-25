local love = require("love")
local player = require("scripts.player")
local enemies = require("scripts.enemies")
local utils = require("scripts.utils")
local consts = require("scripts.constants")
local shaders = require("scripts.shaders")
local events = require("scripts.events")
local set = require("scripts.settings")
local weapons = require("scripts.weapons")
local projs = require("scripts.projectiles")
local titlescreen = require("scripts.titlescreen")
local gui = require("scripts.gui")

local canvas
local decal_canvas

-- Declare variables here, local please.
local desktop_width, desktop_height
local scale_x, scale_y
local mouse_x, mouse_y

local camera_movement
local camera_x
local camera_y
local look_ahead

--R Tilemap shits
local tilemap

local cursor
local cursor_selection_box

local background_index

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

local chromatic_abr_offset

local min_dt
local next_time

--R temporary shit below
local spawn_timer = 0
local spawn_interval = 5

-- For pre-loading. Loads stuff after loading modules.
function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

    if set.fps_cap ~= nil then
        min_dt = 1 / set.fps_cap
        next_time = love.timer.getTime()
    end

    quit_hold_time = 3
    quit_timer = quit_hold_time
    quitting = false

    paused = false

    titlescreen.show = false
    titlescreen:init()

    seed = utils.generate_seed()

    love.math.setRandomSeed(seed)

    background_index = love.math.random(1, #shaders.backgrounds)

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
    camera_x = 0
    camera_y = 0
    look_ahead = 40

    desktop_width, desktop_height = love.window.getDesktopDimensions()
    scale_x = desktop_width / consts.RENDER_WIDTH
    scale_y = desktop_height / consts.RENDER_HEIGHT

    local tilemap_width = love.math.random(consts.HIGH_MIN_WIDTH, consts.HIGH_MAX_WIDTH)
    local tilemap_height = love.math.random(consts.HIGH_MIN_HEIGHT, consts.HIGH_MAX_HEIGHT)
    tilemap = utils.Tilemap:new({size = {tilemap_width, tilemap_height}})
    tilemap:generate()

    player.position.x = tilemap_width * consts.TILE_SIZE / 2
    player.position.y = tilemap_height * consts.TILE_SIZE / 2

    cursor = utils.Animation:new({speed = 0.1, looping = true})
    cursor:manage_spritesheet(consts.ASSETS_PATH .. "hud/cursor.png", 8, 8, 4, 2)

    cursor_selection_box = {x = 0, y = 0, width = 8, height = 8, types = {"cursorselectionbox"}}

    enemy_table = {}
    weapon_table = {}

    local map_w = tilemap_width * consts.TILE_SIZE
    local map_h = tilemap_height * consts.TILE_SIZE

    decal_canvas = love.graphics.newCanvas(map_w, map_h)
    decal_canvas:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)

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
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 10, speed = love.math.random(140, 160), weight = love.math.random(0.75, 0.85), stun_reduction = love.math.random(1.2, 1.4), stagger = love.math.random(18, 28), stability = love.math.random(18, 28)}})) --R sprinters
        elseif enemy_variation == 2 then
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 20, speed = 100}}))
        elseif enemy_variation == 3 then
            table.insert(enemy_table, enemies.Enemy:new({walk_animation = walk_animation, fall_animation = fall_animation, punch_animation = punch_animation, death_animation = death_animation, position = {x = x, y = y}, stats = {hp = 34, speed = love.math.random(70, 90), weight = love.math.random(1.3, 1.45), stun_reduction = -love.math.random(.4, .7), stagger = love.math.random(23, 33), stability = love.math.random(23, 33), knockback = 500}})) --R heavy people
        end
    end

    table.insert(weapon_table, weapons.Gun:new({type = "heavy_gun"}))
end

function love.update(dt)
    if set.vsync then
        set.fps_cap = nil
    end

    if set.fps_cap ~= nil then
        next_time = next_time + min_dt
    end

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / scale_x)
    mouse_y = (mouse_y / scale_y)

    if love.window.hasFocus() and not paused then
        love.audio.setVolume(set.master_volume)
    elseif not events.game_over then
        dt = 0
    end

    dt = math.min(dt, 1 / 30) -- Remember, 1 / framerate = dt, because 1 / frecuency = period (AKA the time that one oscillation/loop takes).

    if not titlescreen.show then
        if events.game_over then
            slow_down = 0.01
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

        camera_x = utils.lerp(camera_x, target_x, camera_movement, dt)
        camera_y = utils.lerp(camera_y, target_y, camera_movement, dt)

        mouse_x, mouse_y = love.mouse.getPosition()
        mouse_x = (mouse_x / scale_x)
        mouse_y = (mouse_y / scale_y)

        cursor_selection_box.x = mouse_x - camera_x
        cursor_selection_box.y = mouse_y - camera_y

        if not paused and love.window.hasFocus() then
            if events.freezeframe_duration <= 0 then
                spawn_timer = spawn_timer + dt * slow_down

                if spawn_timer >= spawn_interval then
                    spawn_timer = 0
                    local x = love.math.random(consts.TILE_SIZE,tilemap.size[1])
                    local y = love.math.random(consts.TILE_SIZE, tilemap.size[2])

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

                for weapon = 1, #weapon_table do
                    weapon_table[weapon]:update(dt, cursor_selection_box, player)
                end

                for item = 1, #enemy_table do
                    enemy_table[item]:update(dt, player, slow_down, tilemap, enemy_table, weapon_table)
                end

                player:update(dt, scale_x, scale_y, camera_x, camera_y, enemy_table, slow_down, tilemap, weapon_table, gui)

                for i = #enemy_table, 1, -1 do
                    if not enemy_table[i].render then
                        table.remove(enemy_table, i)
                    end
                end

                projs.update(dt, enemy_table, tilemap)
            end
        end

        if not events.game_over then
            if chromatic_abr_offset == nil then
                chromatic_abr_offset = math.min(1 / player.stats.souls * 0.005, 0.01)
            else
                chromatic_abr_offset = utils.lerp(chromatic_abr_offset, math.min(1 / player.stats.souls * 0.005, 0.01), 3, dt)
            end
        else
            chromatic_abr_offset = utils.lerp(chromatic_abr_offset, 0, 1, dt)
        end

        if not events.game_over then
            gui:update(dt)
        end
    else
        titlescreen:update(dt, mouse_x, mouse_y)
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

    cursor:update(dt)

    cursor_selection_box.x = mouse_x - camera_x
    cursor_selection_box.y = mouse_y - camera_y
end

function love.draw()
    love.graphics.setFont(vcr_osd_mono)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    if not titlescreen.show then
        shaders.backgrounds[background_index]:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
        shaders.backgrounds[background_index]:send("time", time)

        shaders.game_over:send("resolution", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})
        shaders.game_over:send("time", time)

        shaders.chromatic_abr:send("offset", {chromatic_abr_offset, chromatic_abr_offset})

        shaders.static:send("time", time)
        shaders.static:send("window_coords", {consts.RENDER_WIDTH, consts.RENDER_HEIGHT})

        if not events.game_over then
            love.graphics.setShader(shaders.backgrounds[background_index])
        else
            love.graphics.setShader(shaders.game_over)
        end

        love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
        love.graphics.setShader()

        love.graphics.push()

        love.graphics.translate(camera_x, camera_y)

        tilemap:draw(camera_x, camera_y)

        love.graphics.pop()
        love.graphics.setCanvas(decal_canvas)

        if not set.gore then
            love.graphics.setColor(0, 0, 0)
        end

        utils.draw_decal()
        love.graphics.setColor(1, 1, 1)
        love.graphics.setCanvas(canvas)

        love.graphics.draw(decal_canvas, camera_x, camera_y)
        love.graphics.push()

        love.graphics.translate(camera_x, camera_y)

        projs.draw()

        for weapon = 1, #weapon_table do
            if not weapon_table[weapon].hold then
                weapon_table[weapon]:draw(camera_x, camera_y)
            else
                break
            end
        end

        for i = 1, #enemy_table do
            enemy_table[i]:draw()
        end

        player:draw()
        tilemap:draw_walls(camera_x, camera_y)

        for weapon = 1, #weapon_table do
            if weapon_table[weapon].hold then
                weapon_table[weapon]:draw(camera_x, camera_y)
            else
                break
            end
        end

        love.graphics.pop()

        -- HUD/GUI goes here.
        if not events.game_over then
            gui:draw(vcr_osd_mono, scale_x, scale_y, player)
        end

        for weapon = 1, #weapon_table do
            if weapon_table[weapon].hold then
                if weapon_table[weapon].ammo > 0 then
                    utils.text_outline(weapon_table[weapon].ammo .. " BULLETS", 10, 340)

                    love.graphics.setColor(0, 0, 0)
                    love.graphics.print(weapon_table[weapon].ammo .. " BULLETS", 10, 340)
                    love.graphics.setColor(1, 1, 1)
                else
                    utils.text_outline("NO AMMO :(", 10, 340)

                    love.graphics.setColor(0, 0, 0)
                    love.graphics.print("NO AMMO :(", 10, 340)
                    love.graphics.setColor(1, 1, 1)
                end
            end
        end

        if set.show_fps and not paused then -- Unholy math here.
            local length = #tostring(fps .. " FPS")
            local x = (1.0 / length) * (consts.RENDER_WIDTH * length * 0.95) + (3 - length) * 7

            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", x - length, 1, length * 9, 12, 3, 3)
            love.graphics.setColor(1, 1, 1)

            utils.text_outline(fps .. " FPS", x, 0)

            love.graphics.setColor(0, 0, 0)
            love.graphics.print(fps .. " FPS", x, 0)
            love.graphics.setColor(1, 1, 1)
        end

        if events.freezeframe_duration > 0 then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
            love.graphics.setColor(1, 1, 1)
        end

        if quitting and not paused then
            utils.text_outline("QUITTING...", 5, 345, 1, {1, 1, 1, 0.5})
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.print("QUITTING...", 5, 345)
            love.graphics.setColor(1, 1, 1)
        end

        if paused then
            love.graphics.setColor(0, 0, 0, 0.75)
            love.graphics.rectangle("fill", 0, 0, consts.RENDER_WIDTH, consts.RENDER_HEIGHT)
            love.graphics.setColor(1, 1, 1)
            love.graphics.push()
            love.graphics.translate(-(vcr_osd_mono:getWidth("PAUSED") / 2), -(vcr_osd_mono:getHeight("PAUSED") / 2))
            utils.text_outline("PAUSED", consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print("PAUSED", consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2)
            love.graphics.pop()
        end


        if events.game_over then
            love.graphics.push()
            if events.game_over_message == nil then
                events.game_over_message = consts.GAME_OVER_MESSAGES[love.math.random(#consts.GAME_OVER_MESSAGES)]
            end

            love.graphics.translate(-(vcr_osd_mono:getWidth(events.game_over_message) / 2) * 2, -(vcr_osd_mono:getHeight(events.game_over_message) / 2) * 2)

            -- Outline.
            utils.text_outline(events.game_over_message, consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2 - 100, 1, {1, 1, 1}, 2)

            love.graphics.setColor(0, 0, 0)
            love.graphics.print(events.game_over_message, consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2 - 100, 0, 2, 2)
            love.graphics.setColor(1, 1, 1)
            love.graphics.pop()
        end

        if set.debug then
            utils.draw_collision({x = mouse_x, y = mouse_y, width = 9, height = 8, types = {"cursorselectionbox"}})
        end
    else
        titlescreen:draw()
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, 640, 20)
        love.graphics.rectangle("fill", 0, 340, 640, 20)
        love.graphics.setColor(1, 1, 1)
    end

    cursor:draw(mouse_x, mouse_y, 0, 1, set.shading, 0, 2)

    if events.screenshake and (events.screenshake_delay or 0) <= 0 and not paused then
        local dx = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
        local dy = love.math.random(-events.screenshake_magnitude, events.screenshake_magnitude)
        love.graphics.translate(dx, dy)
    end

    love.graphics.setCanvas()
    if not paused and set.ca_allowed then
        love.graphics.setShader(shaders.chromatic_abr)
    end
    love.graphics.draw(canvas, 0, 0, 0, scale_x, scale_y)
    love.graphics.setShader()

    if set.fps_cap ~= nil then
        local current_time = love.timer.getTime()
        if next_time <= current_time then
            next_time = current_time
            return
        end
        love.timer.sleep(next_time - current_time)
    end
end

function love.mousepressed(x, y, button)
    player:mousepressed(button)

    for i = 1, #weapon_table do
        weapon_table[i]:mousepressed(button)
    end
end

function love.keypressed(key, scancode)
    if scancode == set.keybinds.pause and not events.game_over and not titlescreen.show then
        paused = not paused
    end

    if scancode == set.keybinds.lower_vol then
        set.master_volume = math.max(set.master_volume - 0.1, 0)
    end

    if scancode == set.keybinds.raise_vol then
        set.master_volume = math.min(set.master_volume + 0.1, 2.0)
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
