local love = require("love")
local consts = require("constants")

local shaders = {
    backgrounds = {
        love.graphics.newShader(consts.SHADERS_PATH .. "backgrounds/background1.fs"),
        love.graphics.newShader(consts.SHADERS_PATH .. "backgrounds/background2.fs")
    },
    static = love.graphics.newShader(consts.SHADERS_PATH .. "static.fs"),
    black_white = love.graphics.newShader(consts.SHADERS_PATH .. "black_white.fs"),
    chromatic_abr = love.graphics.newShader(consts.SHADERS_PATH .. "chromatic_aberration.fs")
}

return shaders