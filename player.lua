local love = require("love")
local utils = require("utils")
local consts = require("constants")
local set = require("settings")
local events = require("events")
local shaders = require("shaders")

local walk_animation = utils.Animation:new({speed = 0.08, looping = true})
walk_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 7, 3)

local punch_animation = utils.Animation:new({speed = 0.04, looping = false})
punch_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local fall_animation = utils.Animation:new({speed = 0.1, looping = true})
fall_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1) --R placeholderlocal fall_animation = utils.Animation:new({speed = 0.1, looping = true})

local heavy_gun_animation = utils.Animation:new({speed = 0.1, looping = false})
heavy_gun_animation:manage_spritesheet(consts.CONSUMER_PATH .. "consumer_heavy_gun.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 5, 2) --R placeholderlocal fall_animation = utils.Animation:new({speed = 0.1, looping = true})

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

local update = true

local image = love.graphics.newImage(consts.PARTICLE_PATH .. "red.png")
local particle_system = love.graphics.newParticleSystem(image)

local dash_timer = 1.0

-- If you can think of more stats, then, add them.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180},
    velocity = utils.Vector:new(),
    stats = {
        speed = DEFAULT_SPEED,
        dash_limit = 3,
        dash = 3,
        dash_speed = 10,
        friction = 1, --R Floor friction
        attack_damage = 4, --R We should prolly replace this with "dmg bonus" since stuff will have predetermined dmg
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you? -- No, but it's a good idea.
        knockback = 400,
        stagger = 25,
        souls = 15, --R In seconds perhaps?
        soul_gain = 3, -- We could possibly add some randomness. --R extra soul gain
        soul_limit = 25,
        essence = 0, -- Money.
        essence_gain = 5, -- Add some randomness.
        essence_limit = 100,
        luck = 1,
        view_distance = 500,
        weight = 1, --R How much knockback player takes.
        ammo_boost = 1, -- How much your ammo is multiplied by. By default it's nothing (1), but the Reichmann Relic changes it to 2, duplicating ammo.
        stun_duration = 0,
        stun_reduction = 0,
        stability = 30,
        recovery_speed = 0.5 -- How much faster you get up while spamming space.
    },
    cooldowns = {
        dash = 1.0
    },
    states = {
        idle = true,
        punch = false,
        stunned = false,
        fall = false,
        dead = false,
        dash = false
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
    holding = {false, nil},
    render = true
}

function Player:update(dt, scale_x, scale_y, offset_x, offset_y, targets, slow_down, tilemap, weapon_table)
    if update then
        self.weapon_table = weapon_table
        self.targets = targets

        local speed = self.stats.speed * slow_down
        local attack_speed = self.stats.attack_speed * slow_down

        self.slow_down = slow_down

        punch_animation.speed = 1.0 / (attack_speed * 5)
        punch_sound:setPitch(attack_speed / 5)
        miss_sound:setPitch(attack_speed / 5)

        walk_animation.speed = 55.0 / (speed * 5)

        if self.holding[1] then
            if self.holding[2] == "heavy_gun" then
                self.animation = heavy_gun_animation
            end
        end

        for item = 1, #weapon_table do
            if self.stats.ammo_boost > 1 then
                local weapon = weapon_table[item]

                if weapon.boosted == nil then
                    weapon.ammo = weapon.ammo * self.stats.ammo_boost
                    weapon.boosted = true
                end
            else
                break
            end
        end

        local movement_vector = utils.Vector:new()

        self.stats.souls = self.stats.souls - dt * slow_down
        self.stats.souls = math.max(self.stats.souls, 0)

        if self.stats.souls <= self.stats.soul_limit / 3 then
            if set.screenshake_allowed then
                events.screenshake = true
                events.screenshake_magnitude = 1.0
                events.screenshake_duration = 0.1
            end
        end

        if self.stats.souls <= 0 then
            punch_sound:setPitch(5.0)
            punch_sound:stop()
            punch_sound:play()
            events.freezeframe_duration = 0.1
            self.states.dead = true
            events.game_over = true
        end

        if self.stats.stun_duration <= 0 and not self.states.dead then
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
            if self.states.punch == true and not self.holding[1] then
                self.animation = punch_animation
            elseif not self.holding[1] then
                self.animation = walk_animation
            end
        end

        self.velocity.x = utils.lerp(self.velocity.x, movement_vector.x * (speed), 50, dt)
        self.velocity.y = utils.lerp(self.velocity.y, movement_vector.y * (speed), 50, dt)

        if self.states.dash then
            self.velocity.x = self.velocity.x * self.stats.dash_speed
            self.velocity.y = self.velocity.y * self.stats.dash_speed
            self.stats.dash = math.max(self.stats.dash - 1, 0)
            self.states.dash = false
            self.iframe_timer = 0.5
        elseif self.stats.dash < self.stats.dash_limit then
            if dash_timer <= 0 then
                self.stats.dash = math.min(self.stats.dash + 1, self.stats.dash_limit)
                dash_timer = self.cooldowns.dash
            else
                dash_timer = dash_timer - dt
            end
        end

        self.position.x = self.position.x + (self.velocity.x * dt)
        self.position.y = self.position.y + (self.velocity.y * dt)

        if self.position.x > 0 then
            self.position.x = math.min(self.position.x, (tilemap.size[1] * consts.TILE_SIZE) - consts.CHARACTER_SIZE)
        else
            self.position.x = math.max(self.position.x, consts.TILE_SIZE + consts.CHARACTER_SIZE)
        end

        if self.position.y > 0 then
            self.position.y = math.min(self.position.y, (tilemap.size[2] * consts.TILE_SIZE) - consts.CHARACTER_SIZE)
        else
            self.position.y = math.max(self.position.y, consts.TILE_SIZE + consts.CHARACTER_SIZE)
        end

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
                        self.states.idle = true
                        self.stats.souls = math.min(self.stats.souls + self.stats.soul_gain * 1.5, self.stats.soul_limit)

                        events.freezeframe_duration = 0.15
                        if set.screenshake_allowed then
                            events.screenshake = true
                            events.screenshake_delay = 0.15
                            events.screenshake_duration = 0.2
                            events.screenshake_magnitude = 8.0
                        end

                        local angle = math.atan2(targets[i].position.y - self.position.y, targets[i].position.x - self.position.x)
                        local force = -(targets[i].stats.knockback * 1.1 / self.stats.weight)
                        self.knockback_velx = math.cos(angle) * force
                        self.knockback_vely = math.sin(angle) * force

                        angle = math.atan2(self.position.y - targets[i].position.y, self.position.x - targets[i].position.x)
                        force = -(self.stats.knockback * 1.4 / targets[i].stats.weight)
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
            for i = 1, #self.weapon_table do
                self.weapon_table[i].hold = false
                self.holding = {false, nil}
            end
            self.punch_hurtbox.active = false
        else
            if not self.states.punch and not self.holding[1] then
                self.animation = walk_animation
            end
            self.states.fall = false
        end

        self.hitbox.x = self.position.x
        self.hitbox.y = self.position.y

        if self.iframe_timer > 0 then
            self.iframe_timer = self.iframe_timer - dt
        end

        for collision = 1, #tilemap.walls do
            utils.check_collision(self.hitbox, tilemap.walls[collision])
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

        if self.states.dead then
            events.screenshake = true
            events.screenshake_magnitude = 5
            events.screenshake_duration = 0.5
            update = false
        end
    end
end

function Player:draw()
    if not self.states.dead then
        self.animation:draw(self.position.x, self.position.y, self.angle, 1, set.shading, 0, 3)
    end

    if set.debug then
        utils.draw_collision(self.hitbox)
        if self.punch_hurtbox.active then
            utils.draw_collision(self.punch_hurtbox)
        end
    end
end

function Player:punch()
    if not self.states.punch and self.stats.stun_duration <= 0  and not self.holding[1] and not self.states.dead then
        self.parried_this_swing = false
        self.states.punch = true
        self.animation = punch_animation
        punch_animation.current_frame = 1
        punch_animation.finished = false
        punch_sound_played = false
    end
end

function Player:dash()
    if not self.states.dead and self.stats.stun_duration <= 0 then
        self.states.dash = true
    end
end

function Player:mousepressed(button)
    if button == 1 then
        if self.holding[1] and not self.weapon_table[1].stats.hold_fire then
            self.weapon_table[1].fire_requested = true
        elseif not self.holding[1] then
            self:punch()
        end
    end
end

function Player:keypressed(key)
    if key == "space" and self.states.fall and self.stats.stun_duration > 0 then
        self.stats.stun_duration = self.stats.stun_duration - self.stats.recovery_speed * self.slow_down
    elseif self.stats.stun_duration <= 0 then
        self.stats.stun_duration = 0
    end

    if key == set.keybinds.dash and self.stats.dash > 0 then
        self:dash()
    end
end

return Player