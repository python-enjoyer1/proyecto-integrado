local love = require("love")
local utils = require("utils")
local consts = require("constants")

local Main = {}

Main.HeavyGun = {}

function Main.HeavyGun:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.position = o.position or {x = 150, y = 150}
    o.floor_sprite = o.floor_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_floor.png")
    o.hold_sprite = o.hold_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_hold.png")
end

return Main