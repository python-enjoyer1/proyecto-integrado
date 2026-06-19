local love = require("love")
local consts = require("constants")
local utils = require("utils")

local projectiles = {}

function projectiles.add(x, y, angle, stats) --R projectiles yum yum
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
        hitbox = {x = x, y = y, width = 4, height = 4, types = {"projectile"}},
        active = true
    })
end

function projectiles.update(dt, enemy_table)
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj.x = proj.x + math.cos(proj.angle) * proj.speed * dt
        proj.y = proj.y + math.sin(proj.angle) * proj.speed * dt

        proj.hitbox.x = proj.x
        proj.hitbox.y = proj.y

        for j = 1, #enemy_table do
            local enemy = enemy_table[j]
            if enemy.render and utils.check_collision(proj.hitbox, enemy.hitbox) then
                local angle = math.atan2(enemy.position.y - proj.y, enemy.position.x - proj.x)
                local force = 200 / enemy.stats.weight  --R tune this pls
                enemy.knockback_velx = math.cos(angle) * force
                enemy.knockback_vely = math.sin(angle) * force
                enemy.stats.stun_duration = 1

                enemy.stats.hp = enemy.stats.hp - proj.damage
                if enemy.stats.hp <= 0 then
                    enemy.states.dead = true
                end

                proj.hits = proj.hits + 1
                if proj.hits > proj.pierce then
                    proj.active = false
                    break
                end
            end
        end

        if not proj.active then
            table.remove(projectiles, i)
        end
    end
end

function projectiles.draw()
    for i = 1, #projectiles do
        --R temporary projectile sprite replacement
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", projectiles[i].x - 2, projectiles[i].y - 2, 2, 2)
        love.graphics.setColor(1, 1, 1)
    end
end

return projectiles