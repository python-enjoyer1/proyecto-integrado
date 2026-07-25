local love = require("love")
local utils = require("scripts.utils")
local consts = require("scripts.constants")
local set = require("scripts.settings")

local soul_bar = utils.Animation:new({speed = 0.07, looping = true})
soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)

local soul_bar_bg = utils.Animation:new({speed = 0.07})
soul_bar_bg:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_bg.png", 128, 32, 21, 2)

local soul_bar_frame = utils.Animation:new({speed = 0.07, looping = true})
soul_bar_frame:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar_frame.png", 128, 32, 21, 2)

local GUI = {
    style_messages = {},
    message_time = 3.0,
    message_timer = 3.0

}

function GUI:update(dt)
    if self.message_timer > 0 then
        self.message_timer = self.message_timer - dt
    else
        self.message_timer = self.message_time
    end

    soul_bar_bg:update(dt)
    soul_bar:update(dt)
    soul_bar_frame:update(dt)
end

function GUI:draw(font, scale_x, scale_y, player)
    soul_bar_bg:draw(65, 20)
    love.graphics.setScissor(9 * scale_x, 4 * scale_y, 35 * player.stats.souls / player.stats.soul_limit * scale_x, 32 * scale_y)
    soul_bar:draw(65, 20, 0, 1, set.shading, 0, 4) --R shit above is being held up by hopes and prayers
    love.graphics.setScissor()
    soul_bar_frame:draw(65, 20)

    for item = #self.style_messages, 1, -1 do
        local style_message = self.style_messages[item]
        local text = "+" .. style_message.points .. " " .. style_message.message

        utils.text_outline(text, (525 - #style_message.message), font:getHeight(style_message) * 2)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(text, (525 - #style_message.message), font:getHeight(style_message) * 2)
        love.graphics.setColor(1, 1, 1)

        if self.message_timer <= 0 then
            table.remove(self.style_messages, item)
        end
    end
end

return GUI