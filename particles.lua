local love = require("love")
local consts = require("constants")
local set = require("settings")

local Main = {}

local particle_path

if set.gore then
    particle_path = "blood/red.png"
else
    particle_path = "blood/pink.png"
end
local particle_image = love.graphics.newImage(consts.PARTICLE_PATH .. particle_path)

local particle_system_blood = love.graphics.newParticleSystem(particle_image)
local particle_system_burst = love.graphics.newParticleSystem(particle_image)

particle_system_blood:setEmitterLifetime(-1) -- -1 means it never stops.
particle_system_blood:setParticleLifetime(1) --R dont mind me -- I absolutely mind.
particle_system_blood:setSizeVariation(1)
particle_system_blood:setColors(1, 1, 1, 1, 1, 1, 1, 1)
particle_system_blood:setSpeed(0, consts.BLOOD_SPEED)
particle_system_blood:setLinearDamping(0, 1500)

particle_system_burst:setEmitterLifetime(-1)
particle_system_burst:setParticleLifetime(1)
particle_system_burst:setSizeVariation(1, 2)
particle_system_burst:setColors(1, 1, 1, 1, 1, 1, 1, 1)
particle_system_burst:setSpeed(consts.BURST_SPEED)

local particle_systems = {}

function Main.add(p_type, x, y)
    if p_type == "blood" then
        table.insert(particle_systems, {
            particle = particle_system_blood:clone(),
            x = x,
            y = y,
            started = false,
            emitted = false,
            type = "blood"
        })
    elseif p_type == "burst" then
        table.insert(particle_systems, {
            particle = particle_system_burst:clone(),
            x = x,
            y = y,
            started = false,
            emitted = false,
            type = "burst"
        })
    end

    --[[R alt? unless u're planning smth

    table.insert(particle_systems, {
        particle = particle_system_burst:clone(),
        x = x,
        y = y,
        started = false,
        emitted = false,
        type = p_type
    })

    ]]
end

function Main.update()

    print(#particle_systems)
    for system = 1, #particle_systems do
        if not particle_systems[system].started then
            particle_systems[system].particle:start()
            particle_systems[system].started = true
        end

        if particle_systems[system].type == "blood" then
            particle_systems[system].particle:setSpread(math.rad(love.math.random(180, 360)))
        elseif particle_systems[system].type == "burst" then
            particle_systems[system].particle:setSpread(360)
            particle_systems[system].particle:setSpeed(-consts.BURST_SPEED, consts.BURST_SPEED)
        end

        if not particle_systems[system].emitted then
            if particle_systems[system].type == "blood" then
                particle_systems[system].particle:emit(love.math.random(consts.MIN_BLOOD, consts.MAX_BLOOD))
            elseif particle_systems[system].type == "burst" then
                particle_systems[system].particle:emit(love.math.random(consts.MIN_BURST, consts.MAX_BURST))
            end

            particle_systems[system].emitted = true
            local step = 1.0 / 600.0
            particle_systems[system].particle:update(step)
        end
        particle_systems[system].particle:setSpeed(0, 0)
    end
end

function Main.draw()
    for system = 1, #particle_systems do
        love.graphics.draw(particle_systems[system].particle, particle_systems[system].x, particle_systems[system].y)
    end
end

return Main