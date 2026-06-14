local love = require("love")
local consts = require("constants")
local events = require("events")

local TitleScreen = {
    background = love.graphics.newImage(consts.TITLESCREEN_PATH .. "background.png"),
    electrical_poles = love.graphics.newImage(consts.TITLESCREEN_PATH .. "electrical_poles.png"),
    metro_dark = love.graphics.newImage(consts.TITLESCREEN_PATH .. "metro_dark.png"),
    metro_light = love.graphics.newImage(consts.TITLESCREEN_PATH .. "metro_light.png"),
    mountains = love.graphics.newImage(consts.TITLESCREEN_PATH .. "mountains.png"),
    show = true,
    scrolling = 0,
    foreground = nil
}

function TitleScreen:init()
    local foregrounds = {self.electrical_poles, self.mountains}
    self.foreground = foregrounds[love.math.random(#foregrounds)]
end

function TitleScreen:update(dt)
    if self.show then
        local foregrounds = {self.electrical_poles, self.mountains}

        if self.scrolling < 640 then
            self.scrolling = self.scrolling + 100.0 * dt
        else
            self.scrolling = -1280
            self.foreground = foregrounds[love.math.random(#foregrounds)]
        end
    end
end

function TitleScreen:draw()
    if self.show then
        love.graphics.draw(self.background, 0, 0)
        love.graphics.draw(self.foreground, self.scrolling, 0)
        love.graphics.draw(self.metro_light, 0, 0)
    end
end

return TitleScreen