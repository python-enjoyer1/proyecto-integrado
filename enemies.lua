local love = require("love")
local utils = require("utils")
local consts = require("constants")
local set = require("settings")
local events = require("events")

local Main = {}

local particle

if set.gore then
    particle = "red.png"
else
    particle = "pink.png"
end
local blood_particle = love.graphics.newImage(consts.PARTICLE_PATH .. particle)

local particle_system = love.graphics.newParticleSystem(blood_particle)

particle_system:setParticleLifetime(2, 5)
particle_system:setEmissionRate(5)
particle_system:setSizeVariation(1)
particle_system:setColors(1, 1, 1, 1, 1, 1, 1, 0)

local enemy_walk = utils.Animation:new({speed = 0.1, looping = true})
enemy_walk:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local enemy_fall = utils.Animation:new({speed = 0.1, looping = true})
enemy_fall:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_fall.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 1, 1)

local default_stun = 3

love.audio.setEffect("echo", {type = "reverb"})

local player_hit = love.audio.newSource(consts.SOUND_PATH .. "punch_hit.wav", "static")
player_hit:setVolume(set.sfx_volume)
player_hit:setEffect("echo")

local player_miss = love.audio.newSource(consts.SOUND_PATH .. "punch_miss.wav", "static")
player_miss:setVolume(set.sfx_volume)
player_miss:setEffect("echo")


Main.Enemy = {
    velocity = utils.Vector:new(),
    position = {x = 100, y = 100},
    stats = {
        hp = 20,
        speed = 100,
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
    },
    animation = enemy_walk,
    angle = 0,
    min_distance = 30,
    hitbox = {x = 100, y = 100, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "enemycollisionbox"}}
}

-- This is just so we can have inheritance between different enemy variations.
function Main.Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Enemy:update(dt, target)
    local movement_vector = utils.Vector:new()

    movement_vector.x = target.position.x - self.position.x
    movement_vector.y = target.position.y - self.position.y
    local distance = math.sqrt(movement_vector.x^2 + movement_vector.y^2)


    if distance > self.min_distance then
        movement_vector:normalize()

        self.velocity.x = movement_vector.x * self.stats.speed
        self.velocity.y = movement_vector.y * self.stats.speed

        if self.stats.stun_duration <= 0 then
            self.position.x = self.position.x + (self.velocity.x * dt)
            self.position.y = self.position.y + (self.velocity.y * dt)
        else
            self.states.fall = true
        end

        self.states.idle = false
    else
        self.states.idle = true
        self.animation.current_frame = 1
    end

    if self.stats.stun_duration <= 0 then
        self.animation = enemy_walk
        self.states.fall = false
    else
        self.stats.stun_duration = self.stats.stun_duration - dt
        self.animation = enemy_fall
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
                events.screenshake_magnitude = 2
                player_hit:play()
            elseif target.animation.finished then
                player_miss:play()
                print("nig")
            end
        end
    else
        self.hit_this_swing = false
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

    particle_system:update(dt)
end

function Main.Enemy:draw()
    love.graphics.draw(particle_system, self.position.x, self.position.y)
    self.animation:draw(self.position.x, self.position.y, self.angle, 1, consts.SHADING, 0, 3)

    if consts.DEBUG then
        utils.draw_collision(self.hitbox)
    end
end

return Main