local love = require("love")
local utils = require("utils")
local consts = require("constants")

local player_sprite = utils.Animation:new({5})
player_sprite:manage_spritesheet("stuff/assets/characters/consumer.png", consts.CHARACTER_SIZE, 7, 3)

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
    }

}

-- Just so you know, you normalize EXCLUSIVELY the vector.
-- Also, sometime we should make a vector class/table.
function Player:update(dt)
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

    Player.position.x = Player.position.x + (movement_vector.x * dt * Player.stats.speed)
    Player.position.y = Player.position.y + (movement_vector.y * dt * Player.stats.speed)

    player_sprite:update(dt, false)
end

function Player:draw()
    -- Replace with an actual sprite later on.
    player_sprite:draw(Player.position.x, Player.position.y, 1)
end

return Player   