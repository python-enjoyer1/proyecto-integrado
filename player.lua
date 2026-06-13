local love = require("love")
local utils = require("utils")
local consts = require("constants")
local set = require("settings")
local events = require("events")

local walk_animation = utils.Animation:new({speed = 0.08, looping = true})
walk_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 7, 3)

local punch_animation = utils.Animation:new({speed = 0.04, looping = false})
punch_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local fall_animation = utils.Animation:new({speed = 0.1, looping = true})
fall_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1) --R placeholder

local mouse_x, mouse_y

love.audio.setEffect("reverb", {type = "reverb"})

local walk_sound = consts.WALK_SOUND
local walk_sound_table = {} -- Makes it so footsteps can be speeded played at different speeds.
local walk_sound_timer = 0

local miss_sound = consts.MISS_SOUND

local punch_sound = consts.HIT_SOUND

-- add this near the top of player.lua with the other locals
local punch_sound_played = false

local DEFAULT_SPEED = 150

-- If you can think of more stats, then, add them.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180},
    velocity = utils.Vector:new(),
    stats = {
        speed = DEFAULT_SPEED,
        friction = 1, --R Floor friction
        attack_damage = 4, --R We should prolly replace this with "dmg bonus" since stuff will have predetermined dmg
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you? -- No, but it's a good idea.
        knockback = 400,
        stagger = 25,
        souls = 30, --R In seconds perhaps?
        soul_gain = 4, -- We could possibly add some randomness.
        soul_limit = 60,
        essence = 0, -- Money.
        essence_gain = 5, -- Add some randomness.
        essence_limit = 100,
        luck = 1,
        view_distance = 500,
        weight = 1, --R How much knockback player takes.
        ammo_boost = 1, -- How much your ammo is multiplied by. By default it's nothing (1), but the Reichmann Relic changes it to 2, duplicating ammo.
        stun_duration = 0,
        stun_reduction = 0,
        stability = 300,
        recovery_speed = 0.5 -- How much faster you get up while spamming space.
    },
    states = {
        idle = true,
        punch = false,
        stunned = false,
        fall = false,
        dead = false,
    },
    hit_this_swing = false,
    parried_this_swing = false,
    iframe_timer = 0,
    knockback_velx = 0,
    knockback_vely = 0,
    angle = 0,
    animation = walk_animation,
    hitbox = {x = 320, y = 180, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "playercollisionbox"}},
    punch_hurtbox = {x = 0, y = 0, width = 20, height = 20, types = {"hurtbox"}, active = false},
    held_weapon = nil, --R will be the current weapon held, if none then nil
    render = true
}

function Player:update(dt, scale_x, scale_y, offset_x, offset_y, targets, slow_down, tilemap, weapon_table)
    self.targets = targets

    local speed = self.stats.speed * slow_down
    local attack_speed = self.stats.attack_speed * slow_down

    self.slow_down = slow_down

    punch_animation.speed = 1.0 / (attack_speed * 5)
    punch_sound:setPitch(attack_speed / 5)
    miss_sound:setPitch(attack_speed / 5)

    walk_animation.speed = 55.0 / (speed * 5)

    local movement_vector = utils.Vector:new()

    self.stats.souls = self.stats.souls - dt * slow_down
    if self.stats.souls <= 0 then
        self.states.dead = true
    end

    if self.stats.stun_duration <= 0 then
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

    self.velocity.x = movement_vector.x * (speed)
    self.velocity.y = movement_vector.y * (speed)

    self.position.x = self.position.x + (self.velocity.x * dt)
    self.position.y = self.position.y + (self.velocity.y * dt)

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

    for i = 1, #targets do
        if targets[i].punch_hurtbox and targets[i].punch_hurtbox.active then
            if self.punch_hurtbox.active and punch_animation.current_frame >= 5 and punch_animation.current_frame <= 7 and
            targets[i].punch_animation.current_frame >= 5 and targets[i].punch_animation.current_frame <= 7 and
            utils.check_collision(self.punch_hurtbox, targets[i].punch_hurtbox) then

                if not self.parried_this_swing then
                    self.parried_this_swing = true

                    self.punch_hurtbox.active = false
                    targets[i].punch_hurtbox.active = false

                    consts.PARRY_SOUND:stop()
                    consts.PARRY_SOUND:play()
                    
                    events.freezeframe_duration = 0.15 
                    if set.screenshake_allowed then
                        events.screenshake = true
                        events.screenshake_delay = 0.4
                        events.screenshake_duration = 0.2
                        events.screenshake_magnitude = 8.0
                    end

                    local angle = math.atan2(targets[i].position.y - self.position.y, targets[i].position.x - self.position.x)
                    local force = -(targets[i].stats.knockback * 0.8 / self.stats.weight)
                    self.knockback_velx = math.cos(angle) * force
                    self.knockback_vely = math.sin(angle) * force

                    angle = math.atan2(self.position.y - targets[i].position.y, self.position.x - targets[i].position.x)
                    force = -(self.stats.knockback * 1.2 / targets[i].stats.weight)
                    targets[i].knockback_velx = math.cos(angle) * force
                    targets[i].knockback_vely = math.sin(angle) * force
                end
            end
            if not self.hit_this_swing and self.iframe_timer <= 0 and utils.check_collision(self.hitbox, targets[i].punch_hurtbox) then
                self.hit_this_swing = true
                local angle = math.atan2(self.position.y - targets[i].position.y, self.position.x - targets[i].position.x)
                local force
                if targets[i].stats.stagger < self.stats.stability then
                    force = targets[i].stats.knockback * 1.5 / self.stats.weight
                else
                    force = targets[i].stats.knockback / self.stats.weight

                    self.states.fall = true
                    self.stats.stun_duration = 3 - self.stats.stun_reduction
                    self.iframe_timer = 2
                end
                self.knockback_velx = math.cos(angle) * force
                self.knockback_vely = math.sin(angle) * force

                if set.screenshake_allowed then
                    events.screenshake = true
                    events.screenshake_duration = consts.DEFAULT_SCREENSHAKE_DURATION
                    events.screenshake_magnitude = 4.0
                end
            end
        else
            self.hit_this_swing = false
        end
    end

    if math.abs(self.knockback_velx or 0) > 0.1 or math.abs(self.knockback_vely or 0) > 0.1 then
        self.position.x = self.position.x + self.knockback_velx * dt
        self.position.y = self.position.y + self.knockback_vely * dt
        self.knockback_velx = utils.lerp(self.knockback_velx, 0, 7, dt)
        self.knockback_vely = utils.lerp(self.knockback_vely, 0, 7, dt)
    end

    if self.stats.stun_duration > 0 then
        self.stats.stun_duration = self.stats.stun_duration - (dt * slow_down)
        self.animation = fall_animation
        self.punch_hurtbox.active = false
    else
        if not self.states.punch then
            self.animation = walk_animation
        end
        self.states.fall = false
    end

    self.hitbox.x = self.position.x
    self.hitbox.y = self.position.y

    if self.iframe_timer > 0 then
        self.iframe_timer = self.iframe_timer - dt
    end

    for i = 1, #tilemap.walls do
        utils.check_collision(self.hitbox, tilemap.walls[i])
    end

    self.position.x = self.hitbox.x
    self.position.y = self.hitbox.y

    for i = #walk_sound_table, 1, -1 do
        if walk_sound_timer <= 0 then
            walk_sound_table[i]:setPitch((love.math.random(50, 100) / 100) * slow_down * speed / DEFAULT_SPEED)
            walk_sound_table[i]:play()
            walk_sound_table[i]:release()
            table.remove(walk_sound_table, i)
            walk_sound_timer = 50.0 / speed
        end
    end
end

function Player:draw()
    self.animation:draw(self.position.x, self.position.y, self.angle, 1, set.shading, 0, 3)

    if set.debug then
        utils.draw_collision(self.hitbox)
        if self.punch_hurtbox.active then
            utils.draw_collision(self.punch_hurtbox)
        end
    end
end

function Player:punch()
    if not self.states.punch and self.stats.stun_duration <= 0 then
        self.parried_this_swing = false
        self.states.punch = true
        self.animation = punch_animation
        punch_animation.current_frame = 1
        punch_animation.finished = false
        punch_sound_played = false
    end
end

function Player:mousepressed(button)
    if button == 1 then
        self:punch()
    end

    if button == 2 then
        --R ill figure this shit out later
    end
end

function Player:keypressed(key)
    if key == "space" and self.states.fall and self.stats.stun_duration > 0 then
        self.stats.stun_duration = self.stats.stun_duration - self.stats.recovery_speed * self.slow_down
    elseif self.stats.stun_duration <= 0 then
        self.stats.stun_duration = 0
    end
end

return Player