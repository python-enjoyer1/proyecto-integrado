-- TODO: Re-implement the player miss sound, since I moved the player audio in enemies.lua to player.lua.
local love = require("love")
local utils = require("utils")
local consts = require("constants")
local set = require("settings")

local walk_animation = utils.Animation:new({speed = 0.08, looping = true})
walk_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 7, 3)

local punch_animation = utils.Animation:new({speed = 0.04, looping = false})
punch_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local mouse_x, mouse_y

love.audio.setEffect("reverb", {type = "reverb"})

local walk_sound = love.audio.newSource(consts.SOUND_PATH .. "footstep.wav", "static")
walk_sound:setVolume(set.sfx_volume)
walk_sound:setEffect("reverb")
local walk_sound_table = {} -- Makes it so footsteps can be speeded played at different speeds.
local walk_sound_timer = 0

local miss_sound = love.audio.newSource(consts.SOUND_PATH .. "punch_miss.wav", "static")
miss_sound:setVolume(set.sfx_volume)
miss_sound:setEffect("reverb")
miss_sound:setPitch(0.7)

local punch_sound = love.audio.newSource(consts.SOUND_PATH .. "punch_hit.wav", "static")
punch_sound:setVolume(set.sfx_volume)
punch_sound:setEffect("reverb")

-- add this near the top of player.lua with the other locals
local punch_sound_played = false

-- If you can think of more stats, then, add them.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180},
    velocity = utils.Vector:new(),
    stats = {
        speed = 150,
        friction = 1, --R Floor friction
        attack_damage = 4, --R We should prolly replace this with "dmg bonus" since stuff will have predetermined dmg
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you? -- No, but it's a good idea.
        knockback = 500,
        souls = 30, --R In seconds perhaps?
        soul_gain = 4, -- We could possibly add some randomness.
        soul_limit = 60,
        essence = 0, -- Money.
        essence_gain = 5, -- Add some randomness.
        essence_limit = 100,
        luck = 1,
        view_distance = 500,
        weight = 20, --R How much knockback player takes.
        ammo_boost = 1, -- How much your ammo is multiplied by. By default it's nothing (1), but the Reichmann Relic changes it to 2, duplicating ammo.
        stun_duration = 0
    },
    states = {
        idle = true,
        punch = false,
        stunned = false
    },
    angle = 0,
    animation = walk_animation,
    hitbox = {x = 320, y = 180, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "playercollisionbox"}},
    punch_hurtbox = {x = 0, y = 0, width = 20, height = 20, types = {"hurtbox"}, active = false}
}

function Player:update(dt, scale_x, scale_y, offset_x, offset_y, targets)
    self.targets = targets

    punch_animation.speed = 1.0 / (self.stats.attack_speed * 5)
    punch_sound:setPitch(self.stats.attack_speed / 5)
    miss_sound:setPitch(self.stats.attack_speed / 5)

    walk_animation.speed = 55.0 / (self.stats.speed * 5)

    local movement_vector = utils.Vector:new()

    if love.keyboard.isDown("w") then
        movement_vector.y = movement_vector.y - 1
    end

    if love.keyboard.isDown("s") then
        movement_vector.y = movement_vector.y + 1
    end

    if love.keyboard.isDown("a") then
        movement_vector.x = movement_vector.x - 1
    end

    if love.keyboard.isDown("d") then
        movement_vector.x = movement_vector.x + 1
    end

    movement_vector:normalize()

    self.states.walk = false

    if movement_vector.x == 0 and movement_vector.y == 0 and not self.states.punch then
        self.states.idle = true
    else
        if movement_vector.x ~= 0 or movement_vector.y ~= 0 then
            if walk_sound_timer <= 0 then
                table.insert(walk_sound_table, walk_sound:clone())
            else
                walk_sound_timer = walk_sound_timer - dt
            end
        end

        self.states.idle = false
        if self.states.punch == true then
            self.animation = punch_animation
        else
            self.animation = walk_animation
        end
    end

    self.velocity.x = movement_vector.x * self.stats.speed
    self.velocity.y = movement_vector.y * self.stats.speed

    self.position.x = self.position.x + (self.velocity.x * dt)
    self.position.y = self.position.y + (self.velocity.y * dt)

    self.hitbox.x = self.position.x
    self.hitbox.y = self.position.y

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / scale_x
    mouse_y = mouse_y / scale_y
    self.angle = math.atan2(mouse_y - self.position.y - offset_y, mouse_x - self.position.x - offset_x) -- RADIANS ALL THE FUCKING TIME.

    self.animation:update(dt, self.states.idle)

    if self.states.punch and punch_animation.current_frame >= 5 and punch_animation.current_frame <= 7 then
        self.punch_hurtbox.active = true
        local reach = 20
        self.punch_hurtbox.x = self.position.x + math.cos(self.angle) * reach
        self.punch_hurtbox.y = self.position.y + math.sin(self.angle) * reach
    else
        if self.punch_hurtbox.active and not punch_sound_played then
            local hit_anything = false
            for i = 1, #targets do
                if targets[i].hit_flag then
                    hit_anything = true
                    break
                end
            end
            if hit_anything then
                punch_sound:play()
            else
                miss_sound:play()
            end
            punch_sound_played = true
        end
        self.punch_hurtbox.active = false
        if punch_animation.finished then
            self.states.punch = false
            self.animation = walk_animation
            punch_animation.finished = false
        end
    end

    self.position.x = self.hitbox.x
    self.position.y = self.hitbox.y

    for i = 1, #walk_sound_table do
        if walk_sound_timer <= 0 then
            walk_sound_table[i]:setPitch(love.math.random(50, 100) / 100)
            walk_sound_table[i]:play()
            table.remove(walk_sound_table, i)
            walk_sound_timer = 50.0 / self.stats.speed
        end
    end
end

function Player:draw()
    self.animation:draw(self.position.x, self.position.y, self.angle, 1, consts.SHADING, 0, 3)

    if consts.DEBUG then
        utils.draw_collision(self.hitbox)
        if self.punch_hurtbox.active then
            utils.draw_collision(self.punch_hurtbox)
        end
    end
end

function Player:punch()
    if not self.states.punch then
        self.states.punch = true
        self.animation = punch_animation
        punch_animation.current_frame = 1
        punch_animation.finished = false
        punch_sound_played = false
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        Player:punch()
    end
end

return Player