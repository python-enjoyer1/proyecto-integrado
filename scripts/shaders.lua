local love = require("love")
local consts = require("scripts.constants")

local shaders = {
    backgrounds = {
        love.graphics.newShader(consts.SHADERS_PATH .. "backgrounds/background1.fs"),
        love.graphics.newShader(consts.SHADERS_PATH .. "backgrounds/background2.fs"),
    },
    static = love.graphics.newShader(consts.SHADERS_PATH .. "static.fs"),
    black_white = love.graphics.newShader(consts.SHADERS_PATH .. "black_white.fs"),
    chromatic_abr = love.graphics.newShader(consts.SHADERS_PATH .. "chromatic_aberration.fs"),
    game_over = love.graphics.newShader(consts.SHADERS_PATH  .. "game_over.fs"),
    whiteout = love.graphics.newShader(consts.SHADERS_PATH .. "whiteout.fs")
}

return shaders