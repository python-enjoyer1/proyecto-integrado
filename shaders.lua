local love = require("love")
local consts = require("constants")

local shaders = {
    background = love.graphics.newShader(consts.SHADERS_PATH .. "background.fs"),
    black_white = love.graphics.newShader(consts.SHADERS_PATH .. "black_white.fs")
}

return shaders