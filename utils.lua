local love = require("love")
local consts = require("constants")
local set = require("settings")

local Main = {}

Main.Vector = {x = 0, y = 0}
Main.Animation = {speed = 1, current_frame = 1}
Main.Tilemap = {type = "high", width = 1, height = 1, walls = {}} -- Higher floors refer to earlier floors, since you descend in this game.

function Main.Vector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Vector:normalize()
    local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
    if length > 0 then
        self.x = self.x / length
        self.y = self.y / length
    end
end

function Main.Animation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Basically, we have to add the quad thingy.

function Main.Animation:manage_spritesheet(image, width, height, sprite_number, columns) -- Don't call this on update, call on load.
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
function Main.Animation:update(dt, paused)
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

function Main.Animation:draw(x, y, rotate, size, shade, shade_offset_x, shade_offset_y, shade_color)
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

function Main.has_type(collision, type) --R ts makes it easy to check for collision types
    for i, v in ipairs(collision.types) do
        if v == type then return true end
    end
    return false
end

function Main.Animation:clone()
    local o = Main.Animation:new({
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

function Main.check_collision(collision1, collision2)
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
        local c1_moves = Main.has_type(collision1, "playercollisionbox") or Main.has_type(collision1, "enemycollisionbox")
        local c2_moves = Main.has_type(collision2, "playercollisionbox") or Main.has_type(collision2, "enemycollisionbox")
        local either_is_main = Main.has_type(collision1, "maincollisionbox") or Main.has_type(collision2, "maincollisionbox")
        local both_are_enemies = Main.has_type(collision1, "enemycollisionbox") and Main.has_type(collision2, "enemycollisionbox")

        if (either_is_main or both_are_enemies) and (c1_moves or c2_moves) then
            if both_are_enemies then
                if overlap_x < overlap_y then
                    local push = (dx > 0 and overlap_x or -overlap_x) * 0.5
                    collision1.x = collision1.x + push
                    collision2.x = collision2.x - push
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

function Main.draw_collision(collision)
    local r, g, b = 0, 0, 0
    local count = 0

    local type_colors = {
        hitbox = {0, 0, 1},
        hurtbox = {1, 0, 0},
        maincollisionbox = {1, 1, 1},
        playercollisionbox = {0, 1, 1},
        enemycollisionbox = {1, 0.5, 0}
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
    love.graphics.rectangle("line", collision.x - collision.width / 2, collision.y - collision.height / 2, collision.width, collision.height)
    love.graphics.setColor(1, 1, 1)
end

function Main.Tilemap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Small note: [1] = corner, [2] = connector, [3] = edge.
function Main.Tilemap:generate(tile_number, wall_tile_number, premade) --R keeping premade js in case we do make premade maps
    self.walls = {}
    self.tilemap = {}

    local corner_index = 1
    local connector_index = 2
    local edge_index = 3

    premade = premade or nil
    wall_tile_number = wall_tile_number or 0

    self.width = self.width * love.math.random(consts.MIN_WIDTH_TILEMAP, consts.MAX_WIDTH_TILEMAP)
    self.height = self.height * love.math.random(consts.MIN_HEIGHT_TILEMAP, consts.MAX_HEIGHT_TILEMAP)

    local tiles = {}
    for i = 1, tile_number do
        local tile = love.graphics.newImage(consts.TILE_PATH .. "/" .. self.type .. "/" .. self.type .. i .. ".png")
        tile:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
        table.insert(tiles, tile)
    end

    local wall_tiles = {}
    for i = 1, wall_tile_number do
        local wall_tile = love.graphics.newImage(consts.TILE_PATH .. "/" .. self.type .. "_walls/" .. self.type .. "_wall" .. i .. ".png")
        wall_tile:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
        table.insert(wall_tiles, wall_tile)
    end

    self.tilemap = {}
    local y = 0
    for row = 1, self.height do
        local x = 0
        for col = 1, self.width do
            table.insert(self.tilemap, {
                tile = tiles[love.math.random(1, #tiles)],
                position = {x = x, y = y},
                rotation = 0
            })
            x = x + consts.TILE_SIZE
        end
        y = y + consts.TILE_SIZE
    end

    local wall_x = -consts.WALL_TILE_SIZE / 2-- So they also fill the corners.
    local wall_y = -consts.WALL_TILE_SIZE / 2

    for i = 1, (self.height * 2 + -wall_y / consts.WALL_TILE_SIZE) + 1 do
        table.insert(self.tilemap, {
            tile = wall_tiles[edge_index],
            position = {x = wall_x, y = wall_y},
            rotation = math.rad(90),
            origin_x = consts.WALL_TILE_SIZE / 2,
            origin_y = consts.WALL_TILE_SIZE / 2,
            tile_type = "left"
        })
        wall_y = wall_y + consts.WALL_TILE_SIZE
    end

    wall_x = 0
    wall_y = consts.WALL_TILE_SIZE - consts.TILE_SIZE

    for i = 1, self.width * (consts.TILE_SIZE / consts.WALL_TILE_SIZE) do
        table.insert(self.tilemap, {
                tile = wall_tiles[edge_index],
                position = {x = wall_x, y = wall_y},
                tile_type = "upper"
        })

        wall_x = wall_x + consts.WALL_TILE_SIZE
    end

    local right_x = self.width * consts.TILE_SIZE + consts.WALL_TILE_SIZE / 2
    local right_y = -consts.WALL_TILE_SIZE + consts.WALL_TILE_SIZE / 2

    for i = 1, (self.height * 2) + 1 do
        table.insert(self.tilemap, {
            tile = wall_tiles[edge_index],
            position = {x = right_x, y = right_y + consts.WALL_TILE_SIZE},
            rotation = math.rad(90),
            origin_x = consts.WALL_TILE_SIZE / 2,
            origin_y = consts.WALL_TILE_SIZE / 2,
            tile_type = "right"
        })
        right_y = right_y + consts.WALL_TILE_SIZE
    end

    local bottom_x = 0
    local bottom_y = self.height * consts.TILE_SIZE


    for i = 1, self.width * (consts.TILE_SIZE / consts.WALL_TILE_SIZE) do
        table.insert(self.tilemap, {
            tile = wall_tiles[edge_index],
            position = {x = bottom_x, y = bottom_y},
            tile_type = "lower"
        })
        bottom_x = bottom_x + consts.WALL_TILE_SIZE
    end

    -- Top right corner.
    table.insert(self.tilemap, {
        tile = wall_tiles[corner_index],
        position = {x = wall_x + consts.WALL_TILE_SIZE, y = wall_y + consts.WALL_TILE_SIZE},
        rotation = math.rad(180)
    })

    -- Bottom right corner.
    table.insert(self.tilemap, {
        tile = wall_tiles[corner_index],
        position = {x = wall_x, y = consts.WALL_TILE_SIZE * (self.height * 2) + consts.WALL_TILE_SIZE},
        rotation = math.rad(270)
    })

    -- Bottom left corner.
    table.insert(self.tilemap, {
        tile = wall_tiles[corner_index],
        position = {x = -consts.WALL_TILE_SIZE, y = consts.WALL_TILE_SIZE * (self.height * 2)}
    })

    -- Top left corner.
    table.insert(self.tilemap, {
        tile = wall_tiles[corner_index],
        position = {x = 0, y = -consts.WALL_TILE_SIZE},
        rotation = math.rad(90)
    })

    --R left wall
    table.insert(self.walls, {
        x = -consts.WALL_TILE_SIZE / 2,
        y = self.height * consts.TILE_SIZE / 2,
        width = consts.WALL_TILE_SIZE,
        height = self.height * consts.TILE_SIZE + consts.WALL_TILE_SIZE * 2,
        types = {"maincollisionbox"}
    })

    --R right wall
    table.insert(self.walls, {
        x = self.width * consts.TILE_SIZE + consts.WALL_TILE_SIZE / 2,
        y = self.height * consts.TILE_SIZE / 2,
        width = consts.WALL_TILE_SIZE,
        height = self.height * consts.TILE_SIZE + consts.WALL_TILE_SIZE * 2,
        types = {"maincollisionbox"}
    })

    --R top wall
    table.insert(self.walls, {
        x = self.width * consts.TILE_SIZE / 2,
        y = -consts.WALL_TILE_SIZE / 2,
        width = self.width * consts.TILE_SIZE + consts.WALL_TILE_SIZE * 2,
        height = consts.WALL_TILE_SIZE,
        types = {"maincollisionbox"}
    })

    --R bottom wall
    table.insert(self.walls, {
        x = self.width * consts.TILE_SIZE / 2,
        y = self.height * consts.TILE_SIZE + consts.WALL_TILE_SIZE / 2,
        width = self.width * consts.TILE_SIZE + consts.WALL_TILE_SIZE * 2,
        height = consts.WALL_TILE_SIZE,
        types = {"maincollisionbox"}
    })
end

function Main.Tilemap:draw(offset_x, offset_y)

    for i = 1, #self.tilemap do
        local tile = self.tilemap[i].tile
        local x = self.tilemap[i].position.x
        local y = self.tilemap[i].position.y

        local r = self.tilemap[i].rotation or 0
        local ox = self.tilemap[i].origin_x or 0
        local oy = self.tilemap[i].origin_y or 0
        local tile_type = self.tilemap[i].tile_type or nil

        local screen_x = x + offset_x
        local screen_y = y + offset_y

        if screen_x > -consts.WALL_TILE_SIZE * 2 and screen_x < consts.RENDER_WIDTH + consts.WALL_TILE_SIZE * 2 and
        screen_y > -consts.WALL_TILE_SIZE * 2 and screen_y < consts.RENDER_HEIGHT + consts.WALL_TILE_SIZE * 2 then --R ts is getting long
            -- Peak optimization done by ME. Basically any tiles that are not in the view of the player, are simply, not rendered. Quite awesome, isn't it?
            if x < (consts.RENDER_WIDTH - offset_x) + 15 and y < (consts.RENDER_HEIGHT - offset_y) + 15 then
                love.graphics.push()
                love.graphics.scale(consts.TILE_SCALE, consts.TILE_SCALE)

                if set.shading then
                    love.graphics.setColor(consts.SHADOW_COLOR)
                    if tile_type == "upper" then
                        love.graphics.draw(tile, x, y + consts.WALL_SHADOW_OFFSET, r, 1, 1, ox, oy)
                    elseif tile_type == "lower" then
                        love.graphics.draw(tile, x, y - consts.WALL_SHADOW_OFFSET, r, 1, 1, ox, oy)
                    elseif tile_type == "left" then
                        love.graphics.draw(tile, x + consts.WALL_SHADOW_OFFSET, y, r, 1, 1, ox, oy)
                    elseif tile_type == "right" then
                        love.graphics.draw(tile, x - consts.WALL_SHADOW_OFFSET, y, r, 1, 1, ox, oy)
                    end
                end

                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(tile, x, y, r, 1, 1, ox, oy)
                love.graphics.pop()
            end
        end
    end

    if set.debug then
        for i = 1, #self.walls do
            Main.draw_collision(self.walls[i])
        end
    end
end

function Main.lerp(a, b, x, dt)
    local t = (1.0 - math.exp(-x * dt))
    return a * (1.0 - t) + b * t
end

-- A bit complex, but basically, multiplying by big prime numbers replicates randomness very well.
function Main.generate_seed()
    local seed = math.floor(os.time() + (love.timer.getTime() * 30666738388173)) % 2147483647
    return seed
end

return Main