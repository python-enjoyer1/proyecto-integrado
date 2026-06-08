local love = require("love")
local consts = require("constants")
local set = require("settings")

local Main = {}

Main.Weapons = {}

Main.HeavyGun = {}

function Main.HeavyGun:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.stats = {
        firerate = 10,
        damage = 1,
        weight = 1
    }
    o.position = o.position or {x = 150, y = 150}
    o.rotation = love.math.random(1, 360)
    o.floor_sprite = o.floor_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_floor.png")
    o.hold_sprite = o.hold_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_hold.png")
    o.sprite = o.floor_sprite
    o.render = true

    return o
end

function Main.HeavyGun:update(dt, hold)
    if hold then
        self.sprite = self.hold_sprite
    else
        self.sprite = self.floor_sprite
    end
end

function Main.HeavyGun:draw(offset_x, offset_y)
    if self.render then
        if set.shading then
            love.graphics.setColor(consts.SHADOW_COLOR)
            love.graphics.draw(self.sprite, self.position.x, self.position.y + 2.0, math.rad(self.rotation), 0.5, 0.5)
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.draw(self.sprite, self.position.x, self.position.y, math.rad(self.rotation), 0.5, 0.5)
    end
end

return Main