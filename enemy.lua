local love = require("love")
local utils = require("utils")
local consts = require("constants")

local enemy_walk = utils.Animation:new({speed = 0.1})

enemy_walk:manage_spritesheet(consts.ASSETS_PATH .. "characters/enemies/basic_enemy/enemy_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local Enemy = {
    velocity = utils.Vector:new(),
    position = {x = 100, y = 100},
    stats = {
        speed = 100,
        attack_damage = 5,
        soul_amount = love.math.random(consts.MIN_ENEMY_SOUL, consts.MAX_ENEMY_SOUL),
        essence_amount = love.math.random(consts.MIN_ENEMY_ESSENCE, consts.MAX_ENEMY_ESSENCE)
    },
    states = {},
    angle = 0,
    min_distance = 30
}

function Enemy:update(dt, target)
    local movement_vector = utils.Vector:new()

    movement_vector.x = target.position.x - self.position.x
    movement_vector.y = target.position.y - self.position.y
    local distance = math.sqrt(movement_vector.x^2 + movement_vector.y^2)


    if distance > self.min_distance then
        movement_vector:normalize()

        self.velocity.x = movement_vector.x * self.stats.speed
        self.velocity.y = movement_vector.y * self.stats.speed

        self.position.x = self.position.x + (self.velocity.x * dt)
        self.position.y = self.position.y + (self.velocity.y * dt)
    end

    self.angle = math.atan2(target.position.y - self.position.y, target.position.x - self.position.x)

    enemy_walk:update(dt)
end

function Enemy:draw()
    enemy_walk:draw(self.position.x, self.position.y, self.angle, 1, consts.SHADING, 0, 3)
end

return Enemy