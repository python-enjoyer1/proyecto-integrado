local love = require("love")
local utils = require("utils")
local consts = require("constants")

local player_walk = utils.Animation:new({speed = 0.08})
local player_punch = utils.Animation:new({speed = 0.04})

player_walk:manage_spritesheet(consts.ASSETS_PATH .. "characters/consumer/consumer_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 7, 3)
player_punch:manage_spritesheet(consts.ASSETS_PATH .. "characters/consumer/consumer_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 8, 3)

local mouse_x, mouse_y

-- local randomasfwall = {x = 200, y = 180, width = 90, height = 90, types = {"collisionbox"}} Great job, by the way.

-- If you can think of more stats, then, add them.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180},
    velocity = utils.Vector:new(),
    stats = {
        speed = 150,
        friction = 1, --R Floor friction
        attack_damage = 10, --R We should prolly replace this with "dmg bonus" since stuff will have predetermined dmg
        attack_speed = 5,
        crit_chance = 1, --R You did mention something about adding critical hits to the game didn't you? -- No, but it's a good idea.
        knockback = 3,
        souls = 30, --R In seconds perhaps?
        soul_gain = 4, -- We could possibly add some randomness.
        soul_limit = 60,
        essence = 0, -- Money.
        essence_gain = 5, -- Add some randomness.
        essence_limit = 100,
        luck = 1,
        view_distance = 500,
        weight = 20, --R How much knockback player takes.
        ammo_boost = 1 -- How much your ammo is multiplied by. By default it's nothing (1), but the Reichmann Relic changes it to 2, duplicating ammo.
    },
    states = {
        idle = true,
        punch = false
    },
    angle = 0,
    animation = player_walk,
    hitbox = {x = 320, y = 180, width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2, types = {"hitbox", "collisionbox"}}
}

function Player:update(dt, scale_x, scale_y, offset_x, offset_y)
    local movement_vector = utils.Vector:new()

    if love.keyboard.isDown("w") then
        movement_vector.y = movement_vector.y - 1
    end

    if love.keyboard.isDown("s") then
        movement_vector.y = movement_vector.y + 1
    end

    if love.keyboard.isDown("a") then
        movement_vector.x = movement_vector.x - 1
    end

    if love.keyboard.isDown("d") then
        movement_vector.x = movement_vector.x + 1
    end

    movement_vector:normalize()

    if movement_vector.x == 0 and movement_vector.y == 0 and not self.states.punch then
        self.states.idle = true
    else
        self.states.idle = false
        if self.states.punch == true then
            self.animation = player_punch
        else
            self.animation = player_walk
        end
    end

    self.velocity.x = movement_vector.x * self.stats.speed
    self.velocity.y = movement_vector.y * self.stats.speed

    self.position.x = self.position.x + (self.velocity.x * dt)
    self.position.y = self.position.y + (self.velocity.y * dt)

    self.hitbox.x = self.position.x
    self.hitbox.y = self.position.y

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / scale_x
    mouse_y = mouse_y / scale_y
    self.angle = math.atan2(mouse_y - self.position.y - offset_y, mouse_x - self.position.x - offset_x) -- RADIANS ALL THE FUCKING TIME.

    if self.states.punch then
        if player_punch.current_frame >= #player_punch.frames then
            self.states.punch = false
            self.animation = player_walk
        end
    end
    self.animation:update(dt, self.states.idle)
    -- utils.check_collision(self.hitbox, randomasfwall)

    self.position.x = self.hitbox.x
    self.position.y = self.hitbox.y
end

function Player:draw()
    self.animation:draw(self.position.x, self.position.y, self.angle, 1, consts.SHADING, 0, 3)

    if consts.DEBUG then
        utils.draw_collision(self.hitbox)
    end
    -- utils.draw_collision(randomasfwall)
end

function Player:punch()
    if not self.states.punch then
        self.states.punch = true
        self.animation = player_punch
        player_punch.current_frame = 1
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        Player:punch()
    end
end

return Player