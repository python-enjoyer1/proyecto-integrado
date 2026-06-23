local love = require("love")
local consts = require("constants")
local utils = require("utils")

local size = {640, 360}
local move_x, move_y = 0, 0
local offset_cap = 50

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

    for key, value in pairs(self) do
        if type(value) == "userdata" then
            value:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
        end
    end
end

function TitleScreen:update(dt, mouse_x, mouse_y)
    if self.show then
        consts.VAS_INANIMATUM:play()

        mouse_x = mouse_x - consts.RENDER_WIDTH / 2
        mouse_y = mouse_y - consts.RENDER_HEIGHT / 2

        if move_x < 0 then
            move_x = math.max(utils.lerp(move_x, -mouse_x / 2, 2, dt), offset_cap * -1)
        else
            move_x = math.min(utils.lerp(move_x, -mouse_x / 2, 2, dt), offset_cap)
        end

        if move_y < 0 then
            move_y = math.max(utils.lerp(move_y, -mouse_y / 2, 2, dt), offset_cap * -1)
        else
            move_y = math.min(utils.lerp(move_y, -mouse_y / 2, 2, dt), offset_cap)
        end

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

        love.graphics.push()
        love.graphics.translate(move_x, move_y)
        love.graphics.draw(self.foreground, self.scrolling, 60)
        love.graphics.draw(self.metro_light, consts.RENDER_WIDTH / 2, consts.RENDER_HEIGHT / 2, 0, 2, 2, size[1] / 2, size[2] / 2)
        love.graphics.pop()
    end
end

return TitleScreen