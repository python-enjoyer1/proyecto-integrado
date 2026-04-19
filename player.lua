local love = require("love")
local utils = require("utils")

-- If you can think of more stats, then, fucking add them already.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 100, y = 100, z = 0}, -- Layers on the z-axis, maybe scaling, we'll see.
    stats = {
        speed = 100,
        attack_damage = 30,
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you?
        knockback = 3,
        souls = 30, --R In seconds perhaps?
        soul_gain = 4,
        soul_limit = 60,
        luck = 1,
        view_distance = 500,
        weight = 20 --R How much knockback player takes.
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

    Player.position.x = Player.position.x + (movement_vector.x * dt * Player.speed)
    Player.position.y = Player.position.y + (movement_vector.y * dt * Player.speed)
end

function Player:draw()
    -- Replace with an actual sprite later on.
    love.graphics.rectangle("fill", Player.position.x, Player.position.y, 50, 50)
end

return Player   