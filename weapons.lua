local love = require("love")
local consts = require("constants")
local set = require("settings")
local utils = require("utils")
local projs = require("projectiles")

local Main = {}

Main.Weapons = {}

Main.HeavyGun = {}

function Main.HeavyGun:new(o) --R we should js replace this with "Gun" we can add an o.GunType in this or smth
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.stats = {
        firerate = 10, --R per second
        projectile_speed = 300,
        damage = 3,
        weight = 1,
        pierce = 1, --R pierces through enemies or walls perhaps
        bounces = 0, --R bounces on walls
        hold_fire = true --R click or hold 2 shoot
    }
    o.fire_timer = 0 --R time between each shot
    o.position = o.position or {x = 150, y = 150}
    o.rotation = love.math.random(1, 360)
    o.projectile_offset = {front = 15, right = 8.5} --R didnt know what 2 name so negative front is back and negative right is left
    o.floor_sprite = o.floor_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_floor.png")
    o.hold_sprite = o.hold_sprite or love.graphics.newImage(consts.WEAPON_PATH .. "range/heavy_gun_hold.png")
    o.interact_box = {x = o.position.x, y = o.position.y, width = 20, height = 20, types = {"interactbox"}}
    o.sprite = o.floor_sprite
    o.render = true
    o.image_dimensions = {55, 32}
    o.mouse_on = false
    o.whiteout_shader = love.graphics.newShader("stuff/shaders/whiteout.fs")
    o.hold = false
    o.distance = 100
    o.max_distance = 45

    return o
end

function Main.HeavyGun:update(dt, mouse_selection_box, player)
    self.player = player
    self.distance = math.sqrt((player.position.x - self.position.x) ^ 2 + (player.position.y - self.position.y) ^ 2)
    self.interact_box.x = self.position.x
    self.interact_box.y = self.position.y


    if self.hold then
        self.position.x = self.player.position.x
        self.position.y = self.player.position.y
        self.sprite = self.hold_sprite
        player.holding = {true, "heavy_gun"}

        self.fire_timer = self.fire_timer - dt
        if self.fire_timer <= 0 then
            if self.stats.hold_fire and love.mouse.isDown(1) or self.fire_requested then
                projs.add(
                    player.position.x + math.cos(player.angle) * self.projectile_offset.front + math.cos(player.angle + math.pi / 2) * self.projectile_offset.right,
                    player.position.y + math.sin(player.angle) * self.projectile_offset.front + math.sin(player.angle + math.pi / 2) * self.projectile_offset.right,
                    player.angle,
                    self.stats
                )
                self.fire_timer = 1 / self.stats.firerate
                self.fire_requested = false
            end
        end
    else
        self.mouse_on = utils.check_collision(mouse_selection_box, self.interact_box)
        self.sprite = self.floor_sprite
    end
end

function Main.HeavyGun:draw(offset_x, offset_y)
    if self.render then
        if set.shading then
            love.graphics.setColor(consts.SHADOW_COLOR)
            if not self.hold then
                love.graphics.draw(self.sprite, self.position.x, self.position.y + 2.0, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
            else
                love.graphics.draw(self.sprite, self.player.position.x, self.player.position.y + 2.0, self.player.angle)
            end
            love.graphics.setColor(1, 1, 1)
        end

        if (self.mouse_on or self.distance <= self.max_distance) and not self.hold then
            local offset = 1
            love.graphics.setShader(self.whiteout_shader)
            love.graphics.draw(self.sprite, self.position.x + offset, self.position.y, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
            love.graphics.draw(self.sprite, self.position.x - offset, self.position.y, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
            love.graphics.draw(self.sprite, self.position.x, self.position.y + offset, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
            love.graphics.draw(self.sprite, self.position.x, self.position.y - offset, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
            love.graphics.setShader()
        end

        if not self.hold then
            love.graphics.draw(self.sprite, self.position.x, self.position.y, math.rad(self.rotation), 0.5, 0.5, self.image_dimensions[1] / 2, self.image_dimensions[2] / 2)
        else
            love.graphics.draw(self.sprite, self.player.position.x, self.player.position.y, self.player.angle)
        end
    end
    if set.debug then
        utils.draw_collision(self.interact_box)
    end
end

function Main.HeavyGun:mousepressed(button)
    if button == 2 and self.mouse_on and self.distance <= self.max_distance then
        self.hold = true
    end
end

function Main.HeavyGun:keypressed(key)
    if key == set.keybinds.pick_up and self.distance <= self.max_distance then
        self.hold = true
    end
end

return Main