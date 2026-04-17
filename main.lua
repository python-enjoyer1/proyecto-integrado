local love = require("love")
local Player = require("Player")
local utils = require("utils") -- Local Player does not work for some reason. It is supposedly a "boolean".

-- DECLARE variables here (not define), local please.
-- ...

function love.load()
    love.window.setTitle("Proyecto Integrado")
end

function love.update(dt)
    Player:update(dt)
    utils.Timer.Update(dt)
end

function love.draw()
    Player:draw()
end

-- Jokes on you, it's still here.
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end