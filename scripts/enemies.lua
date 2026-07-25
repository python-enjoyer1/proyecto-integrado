local love = require("love")
local utils = require("scripts.utils")
local consts = require("scripts.constants")
local set = require("scripts.settings")
local events = require("scripts.events")
local shaders = require("scripts.shaders")

local enemies = {}

local particle_image = love.graphics.newImage(consts.PARTICLE_PATH .. "red.png")

love.audio.setEffect("reverb", {type = "reverb"})

local default_walk_animation = utils.Animation:new({speed = 0.1, looping = true})
default_walk_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local default_fall_animation = utils.Animation:new({speed = 0.1, looping = true})
default_fall_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1)

local default_punch_animation = utils.Animation:new({speed = 0.05, looping = false})
default_punch_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local default_death_animation = utils.Animation:new({speed = 0.2, looping = false})
default_death_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_death.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 5, 2)

enemies.Enemy = {}

-- This is just so we can have inheritance between different enemy variations.
function enemies.Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    --R sounds
    o.walk_sound = consts.WALK_SOUND
    o.walk_sound_table = {}
    o.walk_sound_timer = 0

    o.punch_sound = consts.HIT_SOUND

    --R animations
    o.walk_animation = o.walk_animation or (default_walk_animation):clone()
    o.fall_animation = o.fall_animation or (default_fall_animation):clone()
    o.punch_animation = o.punch_animation or (default_punch_animation):clone()
    o.death_animation = o.death_animation or (default_death_animation):clone()

    --R general enemy stuff
    o.velocity = utils.Vector:new()
    o.position = {x = o.position and o.position.x or 50, y = o.position and o.position.y or 50}
    o.stats = {
        hp = o.stats.hp or 20,
        speed = o.stats.speed or 100,
        attack_damage = 2,
        soul_amount = love.math.random(consts.MIN_ENEMY_SOUL, consts.MAX_ENEMY_SOUL),
        essence_amount = love.math.random(consts.MIN_ENEMY_ESSENCE, consts.MAX_ENEMY_ESSENCE),
        weight = o.stats.weight or 1,
        stun_duration = 0,
        stun_reduction = o.stats.stun_reduction or 0, --R seconds
        knockback = 400,
        stagger = love.math.random(20, 30),
        stability = love.math.random(20, 30)
    }
    o.states = {
        idle = false,
        punch = false,
        fall = false,
        dead = false,
        chasing = true,
        run_away = false -- If they were to grab a gun.
    }
    o.cooldowns = {
        punch = 0.5
    } --R we should add a utils func for cooldowns
    o.animation = o.walk_animation
    o.movement_vector = utils.Vector:new()
    o.angle = 0
    o.hitbox = {x = o.position.x, y = o.position.y, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "enemycollisionbox"}}
    o.punch_hurtbox = {x = 0, y = 0, width = 20, height = 20, types = {"hurtbox"}, active = false}
    o.punch_timer = 0.5
    o.knockback_velx = 0
    o.knockback_vely = 0
    o.render = true
    o.damage = true
    o.wanted_velocity = {x = 0, y = 0}
    o.neighbors = {}
    o.particle_system = love.graphics.newParticleSystem(particle_image)

    o.particle_system:start()
    o.particle_system:setSpread(math.rad(360))
    o.particle_system:setSpeed(100, 200)
    o.particle_system:setParticleLifetime(0.5)
    o.particle_system:setSizes(1, 2)
    local r, g, b

    if not set.gore then
        r = 0
        g = 0
        b = 0
    else
        r = 1
        g = 1
        b = 1
    end

    o.particle_system:setColors(
        r,
        g,
        b,
        1,

        r,
        g,
        b,
        0.75,

        r,
        g,
        b,
        0.5,

        r,
        g,
        b,
        0.25,

        r,
        g,
        b,
        0.0
    )
    return o
end --R Main.Enemy is shared so i shoved it in here instead

function enemies.Enemy:update(dt, target, slow_down, tilemap, enemy_table, weapon_table)
    if not self.states.dead then
        self.target = target

        self.movement_vector.x = 0
        self.movement_vector.y = 0

        self.wanted_velocity.x = 0
        self.wanted_velocity.y = 0

        local speed = self.stats.speed * slow_down
        self.punch_animation.speed = (self.cooldowns.punch / 10) / slow_down
        self.walk_animation.speed = 55.0 / (speed * 5)

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

        if self.states.chasing then
            self.movement_vector.x = (target.position.x - self.position.x)
            self.movement_vector.y = (target.position.y - self.position.y)
        elseif self.states.run_away then
            self.movement_vector.x = (self.position.x - target.position.x)
            self.movement_vector.y = (self.position.y - target.position.y)
        end

        self.movement_vector:normalize()

        local distance = math.sqrt((target.position.x - self.position.x) ^ 2 + (target.position.y - self.position.y) ^ 2)
        local min_distance = 30

        if distance > min_distance then
            if self.animation ~= self.fall_animation then
                if self.walk_sound_timer <= 0 then
                    table.insert(self.walk_sound_table, self.walk_sound:clone())
                else
                    self.walk_sound_timer = self.walk_sound_timer - dt
                end
            end

            self:manage_neighbors(enemy_table)

            for item = 1, #self.neighbors do
                local enemy = self.neighbors[item]

                if enemy ~= self then
                    local dx = self.position.x - enemy.position.x
                    local dy = self.position.y - enemy.position.y
                    local min_enemy_distance = 50

                    local squared_enemy_distance = dx ^ 2 + dy ^ 2
                    local squared_min_enemy_distance = min_enemy_distance ^ 2

                    -- Square roots are computationally expensive.
                    if squared_enemy_distance <= squared_min_enemy_distance and squared_enemy_distance > 0 then -- Avoid division by zero.
                        local enemy_distance = math.sqrt(squared_enemy_distance)

                        local push_x = (dx / enemy_distance)
                        local push_y = (dy / enemy_distance)

                        local force = (min_enemy_distance - enemy_distance) / min_distance

                        self.movement_vector.x = self.movement_vector.x + push_x * force
                        self.movement_vector.y = self.movement_vector.y + push_y * force
                    end
                end
            end

            self.movement_vector:normalize()

            self.wanted_velocity = {
                x = self.wanted_velocity.x + self.movement_vector.x * speed,
                y = self.wanted_velocity.y + self.movement_vector.y * speed
            }

            self.velocity.x = utils.lerp(self.velocity.x, self.wanted_velocity.x, 50, dt)
            self.velocity.y = utils.lerp(self.velocity.y, self.wanted_velocity.y, 50, dt)

            if self.stats.stun_duration <= 0 then
                self.position.x = self.position.x + (self.velocity.x * dt)
                self.position.y = self.position.y + (self.velocity.y * dt)
            else
                self.states.fall = true
            end

            self.states.idle = false
        elseif not self.states.punch then
            self.states.idle = true
            self.animation.current_frame = 1
            if self.punch_timer <= 0 and not target.states.fall then
                self.states.punch = true
                self.punch_animation.current_frame = 1
                self.punch_animation.finished = false
                self.punch_timer = self.cooldowns.punch
            elseif not target.states.fall then
                self.punch_timer = self.punch_timer - dt * slow_down
            else
                self.punch_timer = self.cooldowns.punch
            end
        else
            self.states.idle = false
        end

        if self.stats.stun_duration <= 0 then
            if not self.states.punch then
                self.damage = true
                self.animation = self.walk_animation
            else
                self.animation = self.punch_animation
                if self.punch_animation.current_frame >= 5 and self.punch_animation.current_frame <= 7 then
                    self.punch_sound:setPitch(slow_down)
                    self.punch_sound:play()
                    if self.damage then
                        target.stats.souls = math.max(target.stats.souls - self.stats.attack_damage, 0)
                        self.damage = false
                    end
                    self.punch_hurtbox.active = true
                    local reach = 20
                    self.punch_hurtbox.x = self.position.x + math.cos(self.angle) * reach
                    self.punch_hurtbox.y = self.position.y + math.sin(self.angle) * reach
                else
                    self.punch_hurtbox.active = false
                end
                if self.punch_animation.finished then
                    self.states.punch = false
                    self.punch_animation.current_frame = 1
                    self.punch_animation.finished = false
                end
            end
            self.states.fall = false
        else
            self.punch_hurtbox.active = false
            self.stats.stun_duration = self.stats.stun_duration - (dt * slow_down)
            self.animation = self.fall_animation
        end

        if target.punch_hurtbox.active then
            --R so enemy doesnt get fucking comboed in 1 punch
            if not self.hit_this_swing then
                if utils.check_collision(self.hitbox, target.punch_hurtbox) and not self.states.fall then
                    self.particle_system:emit(love.math.random(100, 300))

                    utils.add_decal({
                        image = consts.BLOOD[love.math.random(#consts.BLOOD)],
                        x = self.position.x,
                        y = self.position.y,
                        rotation = math.rad(love.math.random(0, 360)),
                        scale = 1
                    })

                    if target.stats.stagger < self.stats.stability then
                        self.hit_this_swing = true

                        local angle = math.atan2(self.position.y - target.position.y, self.position.x - target.position.x)
                        local force = target.stats.knockback * 1.5 / self.stats.weight
                        self.knockback_velx = math.cos(angle) * force
                        self.knockback_vely = math.sin(angle) * force

                        if set.screenshake_allowed then
                            events.screenshake = true
                            events.screenshake_duration = consts.DEFAULT_SCREENSHAKE_DURATION
                            events.screenshake_magnitude = 2.5
                        end

                        self.stats.hp = self.stats.hp - target.stats.attack_damage
                        if self.stats.hp <= 0 then
                            self.states.dead = true
                        end
                        self.hit_flag = true
                    else
                        self.hit_this_swing = true
                        self.stats.stun_duration = 3 - self.stats.stun_reduction

                        local angle = math.atan2(self.position.y - target.position.y, self.position.x - target.position.x)
                        local force = target.stats.knockback / self.stats.weight
                        self.knockback_velx = math.cos(angle) * force
                        self.knockback_vely = math.sin(angle) * force

                        if set.screenshake_allowed then
                            events.screenshake = true
                            events.screenshake_duration = consts.DEFAULT_SCREENSHAKE_DURATION
                            events.screenshake_magnitude = 4.0
                        end

                        self.stats.hp = self.stats.hp - target.stats.attack_damage

                        if self.stats.hp <= 0 then
                            self.states.dead = true
                        end

                        self.hit_flag = true
                    end
                else
                    self.hit_flag = false
                end
            end
        else
            self.hit_this_swing = false
            self.hit_flag = false
        end

        --R knockback = velocity rn, lerp was tp'ing the enemy
        if math.abs(self.knockback_velx) > 0.1 or math.abs(self.knockback_vely) > 0.1 then
            self.position.x = self.position.x + self.knockback_velx * dt
            self.position.y = self.position.y + self.knockback_vely * dt
            self.knockback_velx = utils.lerp(self.knockback_velx, 0, 7, dt)
            self.knockback_vely = utils.lerp(self.knockback_vely, 0, 7, dt)
        end

        self.hitbox.x = self.position.x
        self.hitbox.y = self.position.y

        for collision = 1, #tilemap.walls do
            utils.check_collision(self.hitbox, tilemap.walls[collision])
        end

        if not self.states.fall then
            for i = 1, #enemy_table do
                if enemy_table[i] ~= self then
                    utils.check_collision(self.hitbox, enemy_table[i].hitbox)
                end
            end
        end

        self.position.x = self.hitbox.x
        self.position.y = self.hitbox.y

        if not self.states.fall then
            self.angle = math.atan2(target.position.y - self.position.y, target.position.x - self.position.x)
        end

        self.animation:update(dt, self.states.idle)

        for sound = 1, #self.walk_sound_table do
            if self.walk_sound_timer <= 0 then
                self.walk_sound_table[sound]:setPitch((love.math.random(50, 100) / 100) * slow_down * (speed / self.stats.speed))
                self.walk_sound_table[sound]:play()
                self.walk_sound_table[sound]:release()
                table.remove(self.walk_sound_table, sound)
                self.walk_sound_timer = 50.0 / speed
            end
        end

        self.particle_system:update(dt)
    else
        self.particle_system:release()
        self.animation = self.death_animation
        if self.animation.finished and self.render then
            utils.add_decal({
                image = consts.BLOOD[love.math.random(#consts.BLOOD)],
                x = self.position.x,
                y = self.position.y,
                rotation = math.rad(love.math.random(0, 360)),
                scale = 1.25
            })
            self.render = false
            if set.screenshake_allowed then
                events.screenshake = true
                events.screenshake_duration = 0.1
                events.screenshake_magnitude = 7.0
            end
            target.stats.souls = math.min(target.stats.souls + self.stats.soul_amount, target.stats.soul_limit)
        else
            self.animation:update(dt)
        end
    end
end

function enemies.Enemy:draw()
    if self.render then
        if self.target ~= nil and self.target.states.dead then
            love.graphics.setShader(shaders.static)
        end

        self.animation:draw(self.position.x, self.position.y, self.angle, 1, set.shading, 0, 3)

        if not self.states.dead then
            love.graphics.draw(self.particle_system, self.position.x, self.position.y)
        end
        love.graphics.setShader()
    end

    if set.debug and self.render then
        utils.draw_collision(self.hitbox)
        if self.punch_hurtbox.active then
            utils.draw_collision(self.punch_hurtbox)
        end
    end
end

function enemies.Enemy:manage_neighbors(enemy_table)
    self.neighbors = {}
    local squared_min_enemy_distance = 2500


    for item = 1, #enemy_table do
        local enemy = enemy_table[item]

        if enemy ~= self then
            local dx = self.position.x - enemy.position.x
            local dy = self.position.y - enemy.position.y

            local squared_enemy_distance = dx ^ 2 + dy ^ 2

            if squared_enemy_distance <= squared_min_enemy_distance then
                table.insert(self.neighbors, enemy)
            end
        end
    end
end

return enemies