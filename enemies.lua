local love = require("love")
local utils = require("utils")
local consts = require("constants")

local Main = {}

local enemy_walk = utils.Animation:new({speed = 0.1, looping = true})

enemy_walk:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local default_stun = 3

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
        punch = false
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
            self.stats.stun_duration = self.stats.stun_duration - dt
        end

        self.states.idle = false
    else
        self.states.idle = true
        self.animation.current_frame = 1
    end

    --utils.check_collision(self.hitbox, target.hitbox) R dont do this

    if target.punch_hurtbox.active then
        --R so enemy doesnt get fucking comboed in 1 punch
        if not self.hit_this_swing and utils.check_collision(self.hitbox, target.punch_hurtbox) then
            self.hit_this_swing = true
            self.stats.stun_duration = default_stun

            local angle = math.atan2(self.position.y - target.position.y, self.position.x - target.position.x)
            local force = target.stats.knockback / self.stats.weight
            self.stats.knockback_velx = math.cos(angle) * force
            self.stats.knockback_vely = math.sin(angle) * force
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

    self.angle = math.atan2(target.position.y - self.position.y, target.position.x - self.position.x)

    self.animation:update(dt, self.states.idle)

    self.hitbox.x = self.position.x
    self.hitbox.y = self.position.y
end

function Main.Enemy:draw()
    enemy_walk:draw(self.position.x, self.position.y, self.angle, 1, consts.SHADING, 0, 3)

    if consts.DEBUG then
        utils.draw_collision(self.hitbox)
    end
end

return Main