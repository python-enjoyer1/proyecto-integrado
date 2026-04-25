local love = require("love")
local utils = require("utils")
local consts = require("constants")

local player_walk = utils.Animation:new({speed = 0.1})
local player_punch = utils.Animation:new({speed = 0.05})

player_walk:manage_spritesheet(consts.ASSETS_PATH .. "characters/consumer/consumer_walk.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 7, 3)
player_punch:manage_spritesheet(consts.ASSETS_PATH .. "characters/consumer/consumer_punch.png", consts.CHARACTER_SIZE, consts.CHARACTER_SIZE, 10, 3)

-- HUD elements here.
local soul_bar = utils.Animation:new({speed = 0.5}) -- Jarvis, fix this shit.

soul_bar:manage_spritesheet(consts.ASSETS_PATH .. "hud/soul_bar.png", 128, 32, 21, 2)

local mouse_x, mouse_y

-- If you feel the screenshake isn't quite well timed, you're completely free to change it.
-- Also, later we should make it so the screenshake only applies when punching an enemy.
local screenshake = false
local screenshake_duration = 0.1 -- For the punching. Also, making the screenshake into a function is difficult and unnecessary.
local screenshake_magnitude = 3 --   ^^
local screenshake_timer = 0

-- If you can think of more stats, then, fucking add them already.
--R Remove the stats that you think wouldn't work, aight?
local Player = {
    position = {x = 320, y = 180, z = 0}, -- Layers on the z-axis, maybe scaling, we'll see.
    stats = {
        speed = 100,
        attack_damage = 1, --R We should prolly replace this with "dmg bonus" since stuff will have predetermined dmg
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
    player_animation = player_walk,
    player_hitbox = {width = consts.CHARACTER_SIZE / 2, height = consts.CHARACTER_SIZE / 2}
}

-- Just so you know, you normalize EXCLUSIVELY the vector.
-- Also, sometime we should make a vector class/table.
function Player:update(dt, scale_x, scale_y)
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

    --[[local is_moving = movement_vector.x ~= 0 and movement_vector.y ~= 0

    self.states.idle = not is_moving and not self.states.punch]]

    --R The lines above should be a better alt, but you decide. -- Brother, if you see a better way, then add it yourself, I cannnot read minds yet.

    if movement_vector.x == 0 and movement_vector.y == 0 and not self.states.punch then
        self.states.idle = true
    else
        self.states.idle = false
        if self.states.punch == true then
            self.player_animation = player_punch
        else
            self.player_animation = player_walk
        end
    end

    self.position.x = self.position.x + (movement_vector.x * dt * self.stats.speed)
    self.position.y = self.position.y + (movement_vector.y * dt * self.stats.speed)

    mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = mouse_x / scale_x
    mouse_y = mouse_y / scale_y
    self.angle = math.atan2(mouse_y - self.position.y, mouse_x - self.position.x) -- RADIANS ALL THE FUCKING TIME.

    if self.states.punch then
        if player_punch.current_frame >= #player_punch.frames then
            self.states.punch = false
            self.player_animation = player_walk
        end
    end

    local collision = utils.check_collision(self.position.x, self.position.y, self.player_hitbox.width, self.player_hitbox.height, 100, 100, 50, 50)
    print(collision) -- Remove the collision update and drawing when you get tired of testing.

    self.player_animation:update(dt, self.states.idle)
    soul_bar:update(dt)
    --self.player_animation:update(dt, not is_moving or self.states.punch)
end

function Player:draw()
    self.player_animation:draw(self.position.x, self.position.y, self.angle)

    if consts.DEBUG then
        utils.draw_collision(self.position.x, self.position.y, self.player_hitbox.width, self.player_hitbox.height, 100, 100, 50, 50)
    end

    -- HUD elements here
    soul_bar:draw(65, 20)
end

function Player:punch()
    if not self.states.punch then
        self.states.punch = true
        self.player_animation = player_punch
        player_punch.current_frame = 1
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        Player:punch()
    end
end

return Player