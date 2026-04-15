local love = require("love")
require("player") -- Local player does not work for some reason. It is supposedly a "boolean".

-- DECLARE variables here (not define), local please.
-- ...

function love.load()
    love.window.setTitle("Proyecto Integrado")
end

function love.update(dt)
    player:update(dt)
end

function love.draw()
    player:draw()
end