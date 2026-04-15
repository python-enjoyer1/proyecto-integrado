local love = require("love")
require("utils")

-- If you can think of more stats, then, fucking add them already.
-- Very important. DO NOT MAKE THIS TABLE LOCAL. YOU WILL FUCK IT UP.
player = {
    x = 100,
    y = 100,
    speed = 50,
    attack = 30,
    attack_speed = 5
}

-- Add normalization.
function player:update(dt)
    local movement = {0, 0}

    if love.keyboard.isDown("w") then
        movement[2] = movement[2] - 1
    end

    if love.keyboard.isDown("s") then
        movement[2] = movement[2] + 1
    end

    if love.keyboard.isDown("a") then
        movement[1] = movement[1] - 1
    end

    if love.keyboard.isDown("d") then
        movement[1] = movement[1] + 1
    end

    player.x = player.x + (movement[1] * dt * player.speed)
    player.y = player.y + (movement[2] * dt * player.speed)
end

function player:draw()
    -- Replace with an actual sprite later on.
    love.graphics.rectangle("fill", player.x, player.y, 50, 50)
end