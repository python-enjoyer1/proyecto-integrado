local love = require("love")
local utils = require("utils")
local consts = require("constants")
local set = require("settings")
local events = require("events")

local Main = {}

local particle_path

if set.gore then
    particle_path = "blood/red.png"
else
    particle_path = "blood/pink.png"
end
local particle_image = love.graphics.newImage(consts.PARTICLE_PATH .. particle_path)

local particle_system_blood = love.graphics.newParticleSystem(particle_image)
local particle_system_burst = love.graphics.newParticleSystem(particle_image)

particle_system_blood:setEmitterLifetime(-1) -- -1 means it never stops.
particle_system_blood:setParticleLifetime(1) --R dont mind me -- I absolutely mind.
particle_system_blood:setSizeVariation(1)
particle_system_blood:setColors(1, 1, 1, 1, 1, 1, 1, 1)
particle_system_blood:setSpeed(0, consts.BLOOD_SPEED)
particle_system_blood:setLinearDamping(0, 1500)

particle_system_burst:setEmitterLifetime(-1)
particle_system_burst:setParticleLifetime(1)
particle_system_burst:setSizeVariation(1, 2)
particle_system_burst:setColors(1, 1, 1, 1, 1, 1, 1, 1)
particle_system_burst:setSpeed(consts.BURST_SPEED)

love.audio.setEffect("reverb", {type = "reverb"})

local default_walk_animation = utils.Animation:new({speed = 0.1, looping = true})
default_walk_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local default_fall_animation = utils.Animation:new({speed = 0.1, looping = true})
default_fall_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1)

local default_punch_animation = utils.Animation:new({speed = 0.05, looping = false})
default_punch_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local default_death_animation = utils.Animation:new({speed = 0.2, looping = false})
default_death_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/variation1/enemy_death.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 5, 2)

Main.Enemy = {}

-- This is just so we can have inheritance between different enemy variations.
function Main.Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    --R particle thing
    o.particle_systems = {}

    --R sounds
    o.walk_sound = consts.WALK_SOUND
    o.walk_sound_table = {}
    o.walk_sound_timer = 0

    o.punch_sound = consts.HIT_SOUND

    --R animations
    o.walk_animation = (o.walk_animation or default_walk_animation):clone()
    o.fall_animation = (o.fall_animation or default_fall_animation):clone()
    o.punch_animation = (o.punch_animation or default_punch_animation):clone()
    o.death_animation = (o.death_animation or default_death_animation):clone()

    --R general enemy stuff
    o.velocity = utils.Vector:new()
    o.position = {x = o.position and o.position.x or 100, y = o.position and o.position.y or 100}
    o.stats = {
        hp = o.stats.hp or 20,
        speed = o.stats.speed or 100,
        attack_damage = 5,
        soul_amount = love.math.random(consts.MIN_ENEMY_SOUL, consts.MAX_ENEMY_SOUL),
        essence_amount = love.math.random(consts.MIN_ENEMY_ESSENCE, consts.MAX_ENEMY_ESSENCE),
        weight = 1,
        stun_duration = 0,
        knockback = 100,
        stagger = love.math.random(20, 30),
        stability = love.math.random(20, 30),
    }
    o.states = {
        idle = false,
        punch = false,
        fall = false,
        dead = false
    }
    o.cooldowns = {
        punch = 0.5
    }
    o.animation = o.walk_animation
    o.movement_vector = utils.Vector:new()
    o.angle = 0
    o.min_distance = 30
    o.hitbox = {x = o.position.x, y = o.position.y, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "enemycollisionbox"}}
    o.punch_hurtbox = {x = 0, y = 0, width = 20, height = 20, types = {"hurtbox"}, active = false}
    o.punch_timer = 0.5
    o.knockback_velx = 0
    o.knockback_vely = 0
    o.render = true
    return o
end --R Main.Enemy is shared so i shoved it in here instead

function Main.Enemy:update(dt, target, slow_down, tilemap, target_table)
    if not self.states.dead then
        local speed = self.stats.speed * slow_down
        self.punch_animation.speed = (self.cooldowns.punch / 10) / slow_down
        self.walk_animation.speed = (self.stats.speed / 1000) / slow_down

        self.movement_vector.x = target.position.x - self.position.x
        self.movement_vector.y = target.position.y - self.position.y
        local distance = math.sqrt(self.movement_vector.x ^ 2 + self.movement_vector.y ^ 2)


        if distance > self.min_distance then
            if self.animation ~= self.fall_animation then
                if self.walk_sound_timer <= 0 then
                    table.insert(self.walk_sound_table, self.walk_sound:clone())
                else
                    self.walk_sound_timer = self.walk_sound_timer - dt
                end
            end

            self.movement_vector:normalize()

            self.velocity.x = self.movement_vector.x * speed
            self.velocity.y = self.movement_vector.y * speed

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
            if self.punch_timer <= 0 then
                self.states.punch = true
                self.punch_animation.current_frame = 1
                self.punch_animation.finished = false
                self.punch_timer = self.cooldowns.punch
            else
                self.punch_timer = self.punch_timer - dt * slow_down
            end
        else
            self.states.idle = false
        end

        if self.stats.stun_duration <= 0 then
            if not self.states.punch then
                self.animation = self.walk_animation
            else
                self.animation = self.punch_animation
                if self.punch_animation.current_frame >= 5 and self.punch_animation.current_frame <= 7 then
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

                        table.insert(self.particle_systems, {
                            particle = particle_system_blood:clone(),
                            x = self.position.x,
                            y = self.position.y,
                            started = false,
                            emitted = false
                        })

                        self.stats.hp = self.stats.hp - target.stats.attack_damage
                        if self.stats.hp <= 0 then
                            self.states.dead = true
                        end

                        for system = 1, #self.particle_systems do
                            if not self.particle_systems[system].started then
                                self.particle_systems[system].particle:start()
                                self.particle_systems[system].started = true
                            end

                            if self.states.dead then
                                self.particle_systems[system].burst = true
                            end

                            if not self.particle_systems[system].burst then
                                self.particle_systems[system].particle:setSpread(math.rad(love.math.random(180, 360)))
                            else
                                self.particle_systems[system].particle:setSpread(360)
                                self.particle_systems[system].particle:setSpeed(-consts.BURST_SPEED, consts.BURST_SPEED)

                                if set.screenshake_allowed then
                                    events.screenshake = true
                                    events.screenshake_duration = 0.3
                                    events.screenshake_magnitude = 10.0
                                end

                            end

                            self.particle_systems[system].particle:setDirection(angle)


                            if not self.particle_systems[system].emitted then
                                if not self.particle_systems[system].burst then
                                    self.particle_systems[system].particle:emit(love.math.random(consts.MIN_BLOOD, consts.MAX_BLOOD))
                                else
                                    self.particle_systems[system].particle:emit(love.math.random(consts.MIN_BURST, consts.MAX_BURST))
                                end

                                self.particle_systems[system].emitted = true

                                local step = 1.0 / 600.0
                                self.particle_systems[system].particle:update(step)
                            end

                            self.particle_systems[system].particle:setSpeed(0, 0)
                        end
                        self.hit_flag = true
                    else
                        self.hit_this_swing = true
                        self.stats.stun_duration = 3

                        local angle = math.atan2(self.position.y - target.position.y, self.position.x - target.position.x)
                        local force = target.stats.knockback / self.stats.weight
                        self.knockback_velx = math.cos(angle) * force
                        self.knockback_vely = math.sin(angle) * force

                        if set.screenshake_allowed then
                            events.screenshake = true
                            events.screenshake_duration = consts.DEFAULT_SCREENSHAKE_DURATION
                            events.screenshake_magnitude = 4.0
                        end

                        -- Blood particles.
                        table.insert(self.particle_systems, {
                            particle = particle_system_blood:clone(),
                            x = self.position.x,
                            y = self.position.y,
                            started = false,
                            emitted = false
                        })

                        self.stats.hp = self.stats.hp - target.stats.attack_damage
                        if self.stats.hp <= 0 then
                            self.states.dead = true
                        end

                        for system = 1, #self.particle_systems do
                            if not self.particle_systems[system].started then
                                self.particle_systems[system].particle:start()
                                self.particle_systems[system].started = true
                            end

                            if self.states.dead then
                                self.particle_systems[system].burst = true
                            end

                            if not self.particle_systems[system].burst then
                                self.particle_systems[system].particle:setSpread(math.rad(love.math.random(180, 360)))
                            else
                                self.particle_systems[system].particle:setSpread(360)
                                self.particle_systems[system].particle:setSpeed(-consts.BURST_SPEED, consts.BURST_SPEED)

                                if set.screenshake_allowed then
                                    events.screenshake = true
                                    events.screenshake_duration = 0.3
                                    events.screenshake_magnitude = 10.0
                                end

                            end

                            self.particle_systems[system].particle:setDirection(angle)


                            if not self.particle_systems[system].emitted then
                                if not self.particle_systems[system].burst then
                                    self.particle_systems[system].particle:emit(love.math.random(consts.MIN_BLOOD, consts.MAX_BLOOD))
                                else
                                    self.particle_systems[system].particle:emit(love.math.random(consts.MIN_BURST, consts.MAX_BURST))
                                end

                                self.particle_systems[system].emitted = true

                                local step = 1.0 / 600.0
                                self.particle_systems[system].particle:update(step)
                            end

                            self.particle_systems[system].particle:setSpeed(0, 0)
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
            self.knockback_velx = self.knockback_velx * (1 - 7 * dt)
            self.knockback_vely = self.knockback_vely * (1 - 7 * dt)
        end

        self.hitbox.x = self.position.x
        self.hitbox.y = self.position.y

        for i = 1, #tilemap.walls do
            utils.check_collision(self.hitbox, tilemap.walls[i])
        end

        for i = 1, #target_table do
            if target_table[i] ~= self then
                utils.check_collision(self.hitbox, target_table[i].hitbox)
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

    else
        self.animation = self.death_animation
        if self.animation.finished and self.render then
            self.render = false
        else
            self.animation:update(dt)
        end
    end
end

function Main.Enemy:draw()
    for system = 1, #self.particle_systems do
        love.graphics.draw(self.particle_systems[system].particle, self.particle_systems[system].x, self.particle_systems[system].y)
    end

    if self.render then
        self.animation:draw(self.position.x, self.position.y, self.angle, 1, set.shading, 0, 3)
    end

    if set.debug and self.render then
        utils.draw_collision(self.hitbox)
        if self.punch_hurtbox.active then
            utils.draw_collision(self.punch_hurtbox)
        end
    end
end

return Main