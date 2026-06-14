local love = require("love")
local consts = require("constants")
local utils = require("utils")

local Main = {}

local projectiles = {}

function Main.add(x, y, angle, stats) --R projectiles yum yum
    table.insert(projectiles, {
        x = x,
        y = y,
        angle = angle,
        speed = stats.projectile_speed,
        damage = stats.damage,
        pierce = stats.pierce,
        bounces = stats.bounces,
        hits = 0,
        bounces_left = stats.bounces,
        active = true
    })
end

function Main.update(dt, enemy_table)
    for i=#projectiles, 1, -1 do
        local proj = projectiles[i]
        proj.x = proj.x + math.cos(proj.angle) * proj.speed * dt
        proj.y = proj.y + math.sin(proj.angle) * proj.speed * dt

        if not proj.active then
            table.remove(projectiles, i)
        end
    end
end

function Main.draw()
    for i = 1, #projectiles do
        --R temporary projectile sprite replacement
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", projectiles[i].x - 2, projectiles[i].y - 2, 4, 4)
        love.graphics.setColor(1, 1, 1)
    end
end

return Main