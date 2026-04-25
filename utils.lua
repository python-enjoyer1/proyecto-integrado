local love = require("love")
local consts = require("constants")
local Main = {}

-- Yoooooooo. I implemented the vector class. If there's any shit you feel ain't right then change it.
--R I approve of this.

Main.Timer = {stored_times = {}} --R basically a wait() then does a callback
Main.Vector = {x = 0, y = 0}
Main.Animation = {speed = 1, current_frame = 1}
Main.CollisionBox = {x  = 0, y = 0, width = 0, height = 0, hurtbox = false}

function Main.Vector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Vector:normalize()
    local length = math.sqrt(self.x^2 + self.y^2)
    if length > 0 then
        self.x = self.x / length
        self.y = self.y / length
    end
end

--R Timer Functions. Only use if it's for delayed triggers, else use coroutines.

function Main.Timer:new(duration, on_complete) --R Set amount of time u want to wait then runs code.
    table.insert(self.stored_times, {time = duration, callback = on_complete})
end

-- Good shit, but remember to only capitalize if making a class, not a variable.
--R Got it.
function Main.Timer:update(dt) --R just put this into love.update()
    for i=#self.stored_times, 1,-1 do --R this prevents other indexes to fill in gaps after deletion.
        local stored = self.stored_times[i]
        stored.time = stored.time - dt
        if stored.time <= 0 then
            stored.callback()
            table.remove(self.stored_times, i)
        end
    end
end

function Main.Animation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Basically, we have to add the quad thingy.
function Main.Animation:manage_spritesheet(image, sprite_size, sprite_number, columns) -- Don't call this on update, call on load.
    self.image = love.graphics.newImage(image)
    self.image:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
    self.frames = {}
    self.sprite_size = sprite_size
    for i=0, sprite_number-1 do
        local x = (i % columns) * sprite_size
        local y = math.floor(i / columns) * sprite_size
        table.insert(
            self.frames,
            love.graphics.newQuad(x, y, sprite_size, sprite_size, self.image)
        )
    end
end

-- Add the main animation. Basically increases the current_frame until you reach the last frame, then resets current_frame. Also wait based on the speed var.
function Main.Animation:update(dt, paused)
    paused = paused or false
    if not paused then
        self.timer = (self.timer or 0) + dt --R (self.timer or 0) just checks whether self.timer exists, if it doesn't then it uses 0 instead
        if self.timer >= self.speed then
            self.timer = self.timer - self.speed
            self.current_frame = self.current_frame + 1

            if self.current_frame > #self.frames then
                self.current_frame = 1
            end
        end
    end
end

function Main.Animation:draw(x, y, rotate, size)
    rotate = rotate or 0
    size = size or 1
    local origin_x, origin_y = self.sprite_size / 2, self.sprite_size / 2
    love.graphics.draw(self.image, self.frames[self.current_frame], x, y, rotate, size, size, origin_x, origin_y)
end

function Main.check_collision(x1, y1, width1, height1, x2, y2, width2, height2)
    return x1 < x2+width2 and
         x2 < x1+width1 and
         y1 < y2+height2 and
         y2 < y1+height1
end

function Main.draw_collision(x1, y1, width1, height1, x2, y2, width2, height2, debug)
    debug = debug or false
    if debug then
        love.graphics.push()
        love.graphics.setColor(0, 0, 255)
        love.graphics.translate(-width1 / 2, -height1 / 2)
        love.graphics.rectangle("line", x1, y1, width1, height1)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.setColor(255, 0, 0)
        love.graphics.translate(-width2 / 2, -height2 / 2)
        love.graphics.rectangle("line", x2, y2, width2, height2)
        love.graphics.pop()

        love.graphics.setColor(255, 255, 255)
    end
end

return Main