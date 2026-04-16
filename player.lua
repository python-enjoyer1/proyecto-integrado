local love = require("love")
require("utils")

-- If you can think of more stats, then, fucking add them already.
-- Very important. DO NOT MAKE THIS TABLE LOCAL. YOU WILL FUCK IT UP.
player = {
    x = 100,
    y = 100,
    speed = 100,
    attack = 30,
    attack_speed = 5
}

-- Just so you know, you normalize EXCLUSIVELY the vector.
-- Also, sometime we should make a vector class/table.
function player:update(dt)
    local movement_vector = vector:new()

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

    player.x = player.x + (movement_vector.x * dt * player.speed)
    player.y = player.y + (movement_vector.y * dt * player.speed)
end

function player:draw()
    -- Replace with an actual sprite later on.
    love.graphics.rectangle("fill", player.x, player.y, 50, 50)
end