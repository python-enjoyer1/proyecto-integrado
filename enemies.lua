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

local particle_systems = {
    particle = particle_system_blood,
    x = 0,
    y = 0,
    start = false,
    emitted = false
}

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

local walk_animation = utils.Animation:new({speed = 0.1, looping = true})
walk_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local fall_animation = utils.Animation:new({speed = 0.1, looping = true})
fall_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1)

local punch_animation = utils.Animation:new({speed = 0.06, looping = true})
punch_animation:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

local default_stun = 3

love.audio.setEffect("reverb", {type = "reverb"})

local walk_sound = love.audio.newSource(consts.SOUND_PATH .. "footstep.wav", "static")
walk_sound:setVolume(set.sfx_volume)
walk_sound:setEffect("reverb")
local walk_sound_table = {}
local walk_sound_timer = 0

local punch_sound = love.audio.newSource(consts.SOUND_PATH .. "punch_hit.wav", "static")
punch_sound:setVolume(set.sfx_volume)
punch_sound:setEffect("reverb")

local PUNCH_COOLDOWN = 0.5
local punch_timer = PUNCH_COOLDOWN

local DEFAULT_SPEED = 100

Main.Enemy = {
    velocity = utils.Vector:new(),
    position = {x = 100, y = 100},
    stats = {
        hp = 20,
        speed = DEFAULT_SPEED,
        attack_damage = 5,
        soul_amount = love.math.random(consts.MIN_ENEMY_SOUL, consts.MAX_ENEMY_SOUL),
        essence_amount = love.math.random(consts.MIN_ENEMY_ESSENCE, consts.MAX_ENEMY_ESSENCE),
        weight = 1, --R base weight is 1, 2 or higher is for big enemies
        stun_duration = 0,
        knockback_velx = 0,
        knockback_vely = 0
    },
    states = {
        idle = false,
        punch = false,
        fall = false,
        dead = false
    },
    animation = walk_animation,
    angle = 0,
    min_distance = 30,
    hitbox = {x = 100, y = 100, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "enemycollisionbox"}},
    punch_hurtbox = {x = 0, y = 0, width = 20, height = 20, types = {"hurtbox"}, active = false}
}

-- This is just so we can have inheritance between different enemy variations.
function Main.Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Enemy:update(dt, target, slow_down)
    if not self.states.dead then
        local speed = self.stats.speed * slow_down

        local movement_vector = utils.Vector:new()

        movement_vector.x = target.position.x - self.position.x
        movement_vector.y = target.position.y - self.position.y
        local distance = math.sqrt(movement_vector.x ^ 2 + movement_vector.y ^ 2)


        if distance > self.min_distance then
            if self.animation ~= fall_animation then
                if walk_sound_timer <= 0 then
                    table.insert(walk_sound_table, walk_sound:clone())
                else
                    walk_sound_timer = walk_sound_timer - dt
                end
            end

            movement_vector:normalize()

            self.velocity.x = movement_vector.x * speed
            self.velocity.y = movement_vector.y * speed

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
            if punch_timer <= 0 then
                self.states.punch = true
                punch_timer = PUNCH_COOLDOWN
            else
                punch_timer = punch_timer - dt
            end
        else
            self.states.idle = false
        end

        if self.stats.stun_duration <= 0 then
            if not self.states.punch then
                self.animation = walk_animation
            else
                self.animation = punch_animation
                if self.animation.current_frame == #self.animation.frames then
                    self.states.punch = false
                end
            end
            self.states.fall = false

        else
            self.stats.stun_duration = self.stats.stun_duration - dt * slow_down
            self.animation = fall_animation
        end

        if target.punch_hurtbox.active then
            --R so enemy doesnt get fucking comboed in 1 punch
            if not self.hit_this_swing then
                if utils.check_collision(self.hitbox, target.punch_hurtbox) and not self.states.fall then
                    self.hit_this_swing = true
                    self.stats.stun_duration = default_stun

                    local angle = math.atan2(self.position.y - target.position.y, self.position.x - target.position.x)
                    local force = target.stats.knockback / self.stats.weight
                    self.stats.knockback_velx = math.cos(angle) * force
                    self.stats.knockback_vely = math.sin(angle) * force

                    events.screenshake = true
                    events.screenshake_duration = consts.DEFAULT_SCREENSHAKE_DURATION
                    events.screenshake_magnitude = 4.0

                    -- Blood particles.
                    table.insert(particle_systems, {
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

                    for system = 1, #particle_systems do
                        if not particle_systems[system].started then
                            particle_systems[system].particle:start()
                            particle_systems[system].started = true
                        end

                        if self.states.dead then
                            particle_systems[system].burst = true
                        end

                        if not particle_systems[system].burst then
                            particle_systems[system].particle:setSpread(math.rad(love.math.random(180, 360)))
                        else
                            particle_systems[system].particle:setSpread(360)
                            particle_systems[system].particle:setSpeed(-consts.BURST_SPEED, consts.BURST_SPEED)
                            events.screenshake = true
                            events.screenshake_duration = 0.3
                            events.screenshake_magnitude = 10.0

                        end

                        particle_systems[system].particle:setDirection(angle)


                        if not particle_systems[system].emitted then
                            if not particle_systems[system].burst then
                                particle_systems[system].particle:emit(love.math.random(consts.MIN_BLOOD, consts.MAX_BLOOD))
                            else
                                particle_systems[system].particle:emit(love.math.random(consts.MIN_BURST, consts.MAX_BURST))
                            end

                            particle_systems[system].emitted = true

                            local step = 1.0 / 600.0
                            particle_systems[system].particle:update(step)
                        end

                        particle_systems[system].particle:setSpeed(0, 0)
                    end
                    self.hit_flag = true
                else
                    self.hit_flag = false
                end
            end
        else
            self.hit_this_swing = false
            self.hit_flag = false
        end

        --R knockback = velocity rn, lerp was tp'ing the enemy
        if math.abs(self.stats.knockback_velx) > 0.1 or math.abs(self.stats.knockback_vely) > 0.1 then
            self.position.x = self.position.x + self.stats.knockback_velx * dt
            self.position.y = self.position.y + self.stats.knockback_vely * dt
            self.stats.knockback_velx = self.stats.knockback_velx * (1 - 10 * dt)
            self.stats.knockback_vely = self.stats.knockback_vely * (1 - 10 * dt)
        end

        if not self.states.fall then
            self.angle = math.atan2(target.position.y - self.position.y, target.position.x - self.position.x)
        end

        self.animation:update(dt, self.states.idle)

        self.hitbox.x = self.position.x
        self.hitbox.y = self.position.y

        for sound = 1, #walk_sound_table do
            if walk_sound_timer <= 0 then
                walk_sound_table[sound]:setPitch((love.math.random(50, 100) / 100) * slow_down * (speed / DEFAULT_SPEED))
                walk_sound_table[sound]:play()
                table.remove(walk_sound_table, sound)
                walk_sound_timer = 50.0 / speed
            end
        end
    else
        -- Freeing up memory. Only release LÖVE2D objects, everything else gets managed by Lua.
        particle_system_blood:release()
        particle_system_burst:release()
        walk_sound:release()
    end
end

function Main.Enemy:draw()
    for system = 1, #particle_systems do
        love.graphics.draw(particle_systems[system].particle, particle_systems[system].x, particle_systems[system].y)
    end

    if not self.states.dead then
        self.animation:draw(self.position.x, self.position.y, self.angle, 1, set.shading, 0, 3)
        if consts.DEBUG then
            utils.draw_collision(self.hitbox)
        end
    end
end

return Main