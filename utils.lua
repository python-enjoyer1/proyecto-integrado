local love = require("love")
local consts = require("constants")
local set = require("settings")

local utils = {}

utils.Vector = {x = 0, y = 0}
utils.Animation = {speed = 1, current_frame = 1}
utils.Tilemap = {} -- Higher floors refer to earlier floors, since you descend in this game.

utils.decal_update = false
local decal

function utils.Vector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function utils.Vector:normalize()
    local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
    if length > 0 then
        self.x = self.x / length
        self.y = self.y / length
    end
end

function utils.Animation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Basically, we have to add the quad thingy.

function utils.Animation:manage_spritesheet(image, width, height, sprite_number, columns) -- Don't call this on update, call on load.
    self.image = love.graphics.newImage(image)
    self.image:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
    self.frames = {}
    self.sprite_width = width
    self.sprite_height = height
    for i = 0, sprite_number - 1 do
        local x = (i % columns) * self.sprite_width
        local y = math.floor(i / columns) * self.sprite_height
        table.insert(
            self.frames,
            love.graphics.newQuad(x, y, self.sprite_width, self.sprite_height, self.image)
        )
    end
end

-- Add the main animation. Basically increases the current_frame until you reach the last frame, then resets current_frame. Also wait based on the speed var.
function utils.Animation:update(dt, paused)
    paused = paused or false
    if not paused then
        self.timer = (self.timer or 0) + dt
        if self.timer >= self.speed then
            self.timer = self.timer - self.speed
            if self.finished then return end  -- stay on last frame
            self.current_frame = self.current_frame + 1

            if self.current_frame > #self.frames then
                if not self.looping then
                    self.current_frame = #self.frames
                    self.finished = true
                else
                    self.current_frame = 1
                end
            end
        end
    end
end

function utils.Animation:draw(x, y, rotate, size, shade, shade_offset_x, shade_offset_y, shade_color)
    rotate = rotate or 0
    size = size or 1
    shade = shade or false
    shade_offset_x = shade_offset_x or 0
    shade_offset_y = shade_offset_y or 0
    shade_color = shade_color or consts.SHADOW_COLOR

    local origin_x, origin_y = self.sprite_width / 2, self.sprite_height / 2

    if shade then
        love.graphics.setColor(shade_color)
        love.graphics.draw(self.image, self.frames[self.current_frame], x + shade_offset_x, y + shade_offset_y, rotate, size, size, origin_x, origin_y)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.draw(self.image, self.frames[self.current_frame], x, y, rotate, size, size, origin_x, origin_y)
end

function utils.has_type(collision, type) --R ts makes it easy to check for collision types
    for i, v in ipairs(collision.types) do
        if v == type then return true end
    end
    return false
end

function utils.Animation:clone()
    local o = utils.Animation:new({
        speed = self.speed,
        looping = self.looping,
        image = self.image,
        frames = self.frames,
        sprite_width = self.sprite_width,
        sprite_height = self.sprite_height,
        current_frame = 1,
        timer = 0,
        finished = false
    })
    return o
end

function utils.check_collision(collision1, collision2)
    local x = collision1.x - collision1.width / 2
    local y = collision1.y - collision1.height / 2
    local x2 = collision2.x - collision2.width / 2
    local y2 = collision2.y - collision2.height / 2

    local hit = x < x2 + collision2.width and
        x2 < x + collision1.width and
        y < y2 + collision2.height and
        y2 < y + collision1.height

    if hit then
        local dx = collision1.x - collision2.x
        local dy = collision1.y - collision2.y
        local overlap_x = (collision1.width / 2 + collision2.width / 2) - math.abs(dx)
        local overlap_y = (collision1.height / 2 + collision2.height / 2) - math.abs(dy)

        --R figure out which one actually gets pushed
        local c1_moves = utils.has_type(collision1, "playercollisionbox") or utils.has_type(collision1, "enemycollisionbox")
        local c2_moves = utils.has_type(collision2, "playercollisionbox") or utils.has_type(collision2, "enemycollisionbox")
        local either_is_main = utils.has_type(collision1, "maincollisionbox") or utils.has_type(collision2, "maincollisionbox")
        local both_are_enemies = utils.has_type(collision1, "enemycollisionbox") and utils.has_type(collision2, "enemycollisionbox")
        local selection_on_interactable = utils.has_type(collision1, "cursorselectionbox") and utils.has_type(collision2, "interactbox")

        if (either_is_main or both_are_enemies or selection_on_interactable) and (c1_moves or c2_moves) then
            if both_are_enemies then
                if overlap_x < overlap_y then
                    local push = (dx > 0 and overlap_x or -overlap_x) * 0.5
                    collision1.x = collision1.x + push
                    collision2.x = collision2.x - push
                else
                    local sign = c1_moves and 1 or -1
                    if overlap_x >= overlap_y then
                        local push = (dx > 0 and overlap_x or -overlap_x) * sign
                        if c1_moves then collision1.x = collision1.x + push
                        else collision2.x = collision2.x - push end
                    else
                        local push = (dy > 0 and overlap_y or -overlap_y) * sign
                        if c1_moves then collision1.y = collision1.y + push
                        else collision2.y = collision2.y - push end
                    end
                end
            elseif selection_on_interactable then
                return true
            else
                local sign = c1_moves and 1 or -1
                if overlap_x < overlap_y then
                    local push = (dx > 0 and overlap_x or -overlap_x) * sign
                    if c1_moves then collision1.x = collision1.x + push
                    else collision2.x = collision2.x - push end
                else
                    local push = (dy > 0 and overlap_y or -overlap_y) * sign
                    if c1_moves then collision1.y = collision1.y + push
                    else collision2.y = collision2.y - push end
                end
            end
        end
    end

    return hit
end

function utils.draw_collision(collision)
    local r, g, b = 0, 0, 0
    local count = 0

    local type_colors = {
        hitbox = {0, 0, 1},
        hurtbox = {1, 0, 0},
        maincollisionbox = {1, 1, 1},
        playercollisionbox = {0, 1, 1},
        enemycollisionbox = {1, 0.5, 0},
        interactbox = {0, 1, 0.},
        cursor_selection_box = {0, 0, 0}
    }

    for i, v in ipairs(collision.types) do
        if type_colors[v] then
            r = r + type_colors[v][1]
            g = g + type_colors[v][2]
            b = b + type_colors[v][3]
            count = count + 1
        end
    end

    if count > 0 then
        r, g, b = r / count, g / count, b / count
    end

    love.graphics.setColor(r, g, b)
    love.graphics.push()

    if collision.rotation ~= nil then
        love.graphics.rotate(collision.rotation)
    end
    love.graphics.rectangle("line", collision.x - collision.width / 2, collision.y - collision.height / 2, collision.width, collision.height)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
end

function utils.Tilemap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.type = o.type or "high"
    o.size = o.size or {50, 50}
    o.floor_tiles = o.floor_tiles or consts.HIGH_FLOOR_TILES
    o.wall_tiles = o.wall_tiles or consts.HIGH_WALL_TILES
    o.tilemap = o.tilemap or {}
    o.walls = {}

    return o
end

function utils.Tilemap:generate()
    self.center_position = {
        self.size[1] / 2 + consts.RENDER_WIDTH / 2 - consts.TILE_SIZE / 2,
        self.size[2] / 2 + consts.RENDER_HEIGHT / 2 - consts.TILE_SIZE / 2
    }

    for x = 1, self.size[1] do
        self.tilemap[x] = {}
        for y = 1, self.size[2] do
            if x > 1 and y == 1 then
                if x < self.size[1] then
                    self.tilemap[x][y] = {
                        index = 3,
                        type = "wall",
                        rotation = math.rad(180),
                        side = "up"
                    }
                else
                    self.tilemap[x][y] = {
                        index = 1,
                        type = "wall",
                        rotation = math.rad(180)
                    }
                end
            elseif x == 1 and y == 1 then
                self.tilemap[x][y] = {
                    index = 1,
                    type = "wall",
                    rotation = math.rad(90)
                }
            elseif x == 1 and y > 1 then
                if y < self.size[2] then
                    self.tilemap[x][y] = {
                        index = 3,
                        type = "wall",
                        rotation = math.rad(270),
                        side = "left"
                    }
                else
                    self.tilemap[x][y] = {
                        index = 1,
                        type = "wall",
                        rotation = math.rad(360)
                    }
                end
            elseif x < self.size[1] and y == self.size[2] then
                self.tilemap[x][y] = {
                    index = 3,
                    type = "wall",
                    side = "down"
                }
            elseif x == self.size[1] and y < self.size[2] then
                self.tilemap[x][y] = {
                    index = 3,
                    type = "wall",
                    rotation = math.rad(270),
                    side = "right"
                }
            elseif x == self.size[1] and y == self.size[2] then
                self.tilemap[x][y] = {
                    index = 1,
                    type = "wall",
                    rotation = math.rad(270)
                }
            else
                self.tilemap[x][y] = {
                    index = love.math.random(#self.floor_tiles),
                    type = "floor"
                }
            end
        end
    end

    local map_width = self.size[1] * consts.TILE_SIZE
    local map_height = self.size[2] * consts.TILE_SIZE
    local t_size = consts.TILE_SIZE
    self.walls = {
        {x = map_width / 2 - (t_size / 2), y = 0, width = map_width, height = t_size, types = {"maincollisionbox"}},
        {x = 0, y = map_height / 2 - (t_size / 2), width = t_size, height = map_height, types = {"maincollisionbox"}},
        {x = map_width / 2 - (t_size / 2), y = map_height - t_size, width = map_width, height = t_size, types = {"maincollisionbox"}},
        {x = map_width - t_size, y = map_height - map_height / 2 - t_size / 2, width = t_size, height = map_height, types = {"maincollisionbox"}},
    }
end

function utils.Tilemap:draw(camera_x, camera_y)
    for x = 1, self.size[1] do
        for y = 1, self.size[2] do
            local screen_x = (x - 1) * consts.TILE_SIZE
            local screen_y = (y - 1) * consts.TILE_SIZE

            local offset = 10

            if screen_x < (consts.RENDER_WIDTH - camera_x) + offset and
            screen_y < (consts.RENDER_HEIGHT - camera_y) + offset and
            -screen_x < camera_x + offset and -screen_y < camera_y + offset then
                if self.tilemap[x][y].type == "floor" then
                    love.graphics.draw(
                        self.floor_tiles[self.tilemap[x][y].index],
                        screen_x,
                        screen_y,
                        0,
                        1,
                        1,
                        consts.TILE_SIZE / 2,
                        consts.TILE_SIZE / 2
                    )
                end
            end
        end
    end
    for x = 1, self.size[1] do
        for y = 1, self.size[2] do
            local rotation = 0

            local screen_x = (x - 1) * consts.TILE_SIZE
            local screen_y = (y - 1) * consts.TILE_SIZE

            local offset = 10

            if screen_x < (consts.RENDER_WIDTH - camera_x) + offset and
            screen_y < (consts.RENDER_HEIGHT - camera_y) + offset and
            -screen_x < camera_x + offset and -screen_y < camera_y + offset then
                if self.tilemap[x][y].type == "wall" then
                    if self.tilemap[x][y].rotation ~= nil then
                        rotation = self.tilemap[x][y].rotation
                    end

                    if set.shading then
                        love.graphics.push()
                        love.graphics.setColor(consts.SHADOW_COLOR)

                        local shadow_offset = 3

                        if self.tilemap[x][y].side ~= nil then
                            if self.tilemap[x][y].side == "up" then
                                love.graphics.translate(0, shadow_offset)
                            elseif self.tilemap[x][y].side == "down" then
                                love.graphics.translate(0, -shadow_offset)
                            elseif self.tilemap[x][y].side == "left" then
                                love.graphics.translate(shadow_offset, 0)
                            elseif self.tilemap[x][y].side == "right" then
                                love.graphics.translate(-shadow_offset, 0)
                            end
                        end

                        love.graphics.draw(
                            self.wall_tiles[self.tilemap[x][y].index],
                            screen_x,
                            screen_y,
                            rotation,
                            1,
                            1,
                            consts.TILE_SIZE / 2,
                            consts.TILE_SIZE / 2
                        )

                        love.graphics.setColor(1, 1, 1)
                        love.graphics.pop()
                    end

                    love.graphics.draw(
                        self.wall_tiles[self.tilemap[x][y].index],
                        screen_x,
                        screen_y,
                        rotation,
                        1,
                        1,
                        consts.TILE_SIZE / 2,
                        consts.TILE_SIZE / 2
                    )
                end
            end
        end
    end

    if set.debug then
        for collision = 1, #self.walls do
            utils.draw_collision(self.walls[collision])
        end
    end
end

function utils.lerp(a, b, x, dt)
    local t = (1.0 - math.exp(-x * dt))
    return a * (1.0 - t) + b * t
end

-- A bit complex, but basically, multiplying by big prime numbers replicates randomness very well.
function utils.generate_seed()
    local seed = math.floor(os.time() + (love.timer.getTime() * 30666738388173)) % 2147483647
    return seed
end

function utils.text_outline(text, x, y, offset, color, scale)
    offset = offset or 1
    color = color or {1, 1, 1}
    scale = scale or 1

    love.graphics.setColor(color)

    love.graphics.print(text, x + offset, y, 0, scale, scale)
    love.graphics.print(text, x - offset, y, 0, scale, scale)
    love.graphics.print(text, x, y + offset, 0, scale, scale)
    love.graphics.print(text, x, y - offset, 0, scale, scale)

    love.graphics.setColor(1, 1, 1)
end

function utils.add_decal(d)
    utils.decal_update = true
    decal = d
end

-- Use in draw
function utils.draw_decal()
    if utils.decal_update then
        love.graphics.draw(
            decal.image,
            decal.x,
            decal.y,
            decal.rotation,
            decal.scale,
            decal.scale,
            decal.image:getWidth() / 2,
            decal.image:getHeight() / 2
        )
        utils.decal_update = false
    end
end

return utils