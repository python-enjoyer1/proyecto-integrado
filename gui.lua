local love = require("love")
local utils = require("utils")
local consts = require("constants")

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
end

function GUI:draw(font, offset)
    offset = offset or 15

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