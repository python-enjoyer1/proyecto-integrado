local love = require("love")

-- Define variables here, local please.
local player

function love.load()
    love.window.setTitle("Proyecto Integrado")

    player = {
        x = 100,
        y = 100,
        speed = 50
    }
end

function love.update(dt)
    if love.keyboard.isDown("w") then
        player.y = player.y - (player.speed * dt)
    end

    if love.keyboard.isDown("s") then
        player.y = player.y + (player.speed * dt)
    end

    if love.keyboard.isDown("a") then
        player.x = player.x - (player.speed * dt)
    end

    if love.keyboard.isDown("d") then
        player.x = player.x + (player.speed * dt)
    end
end

function love.draw()
    -- Replace with an actual sprite later on.
    love.graphics.rectangle("fill", player.x, player.y, 50, 50)
end