local love = require("love")
local utils = require("utils")
local consts = require("constants")

local player_sprite = utils.Animation:new({speed = 0.1})
player_sprite:manage_spritesheet("stuff/assets/characters/consumer.png", consts.CHARACTER_SIZE, 7, 3)

local mouse_x, mouse_y

-- If you can think of more stats, then, fucking add them already.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180, z = 0}, -- Layers on the z-axis, maybe scaling, we'll see.
    stats = {
        speed = 100,
        attack_damage = 30,
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you? No, but it's a good idea.
        knockback = 3,
        souls = 30, --R In seconds perhaps?
        soul_gain = 4, -- We could possibly add some randomness.
        soul_limit = 60,
        essence = 0, -- Money.
        essence_gain = 5, -- Add some randomness.
        essence_limit = 100,
        luck = 1,
        view_distance = 500,
        weight = 20, --R How much knockback player takes.
        ammo_boost = 1 -- How much your ammo is multiplied by. By default it's nothing (1), but the Reichmann Relic changes it to 2, duplicating ammo.
    },
    states = {
        idle = true
    },
    angle = 0
}

-- Just so you know, you normalize EXCLUSIVELY the vector.
-- Also, sometime we should make a vector class/table.
function Player:update(dt, scale_x, scale_y)
    local movement_vector = utils.Vector:new() -- We should maybe move this line outside the update so it doesn't always create a new vector.

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

    if movement_vector.x == 0 and movement_vector.y == 0 then
        self.states.idle = true
    else
        self.states.idle = false
    end

    self.position.x = self.position.x + (movement_vector.x * dt * self.stats.speed)
    self.position.y = self.position.y + (movement_vector.y * dt * self.stats.speed)

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / scale_x
    mouse_y = mouse_y / scale_y
    self.angle = math.atan2(mouse_y - self.position.y, mouse_x - self.position.x) -- RADIANS ALL THE FUCKING TIME.

    player_sprite:update(dt, self.states.idle)
end

function Player:draw()
    -- Replace with an actual sprite later on.
    player_sprite:draw(self.position.x, self.position.y, self.angle)
end

return Player