local love = require("love")
local utils = require("utils")

-- If you can think of more stats, then, fucking add them already.
-- Very important. DO NOT MAKE THIS TABLE LOCAL. YOU WILL FUCK IT UP.
--R I was thinking of making Player.Position a thing so that we can put xpos, ypos, zpos (scaling and ñayering based on zpos)
-- Good idea (slight nitpick, I would just name it z, not zpos but no matter)
-- Also, could you capitalize the Player class but nothing inside of it? 
--R m not gna add pos to the final part of each axis, its just to be more clear
local Player = {
    x = 100,
    y = 100,
    speed = 100,   attack = 30,
    attack_speed = 5
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

    Player.x = Player.x + (movement_vector.x * dt * Player.speed)
    Player.y = Player.y + (movement_vector.y * dt * Player.speed)
end

function Player:draw()
    -- Replace with an actual sprite later on.
    love.graphics.rectangle("fill", Player.x, Player.y, 50, 50)
end

return Player   