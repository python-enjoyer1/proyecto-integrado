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

-- Jokes on you, it's still here.
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end