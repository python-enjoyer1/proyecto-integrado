local love = require("love")
local consts = require("constants")
local Main = {}

Main.Timer = {stored_times = {}} --R basically a wait() then does a callback
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
    local length = math.sqrt(self.x^2 + self.y^2)
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
    for i=0, sprite_number-1 do
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
        self.timer = (self.timer or 0) + dt --R (self.timer or 0) just checks whether self.timer exists, if it doesn't then it uses 0 instead
        if self.timer >= self.speed then
            self.timer = self.timer - self.speed
            self.current_frame = self.current_frame + 1

            if self.current_frame > #self.frames then
                self.current_frame = 1
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
    shade_color = shade_color or {0, 0, 0}
    local origin_x, origin_y = self.sprite_width / 2, self.sprite_height / 2
    if shade then
        love.graphics.setColor(shade_color)
        love.graphics.draw(self.image, self.frames[self.current_frame], x + shade_offset_x, y + shade_offset_y, rotate, size, size, origin_x, origin_y)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.draw(self.image, self.frames[self.current_frame], x, y, rotate, size, size, origin_x, origin_y)
end

function Main.check_collision(collision1, collision2)
    collision1.x = collision1.x - collision1.width / 2
    collision1.y = collision1.y - collision1.height / 2
    collision2.x = collision2.x - collision2.width / 2
    collision2.y = collision2.y - collision2.height / 2

    return collision1.x < collision2.x + collision2.width and
        collision2.x < collision1.x + collision1.width and
         collision1.y < collision2.y + collision2.height and
         collision2.y < collision1.y + collision1.height
end

function Main.draw_collision(collision)
    if collision.type == "hitbox" then
        love.graphics.setColor(0, 0, 1)
    elseif collision.type == "hurtbox" then
        love.graphics.setColor(1, 0, 0)
    elseif collision.type == "collisionbox" then
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.rectangle("line", collision.x, collision.y, collision.width, collision.height)

    love.graphics.setColor(1, 1, 1)
end

function Main.Tilemap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Tilemap:generate(tile_number, wall_tile_number, premade) --R keeping premade js in case we do make premade maps
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
                position = {x = x, y = y}
            })
            x = x + consts.TILE_SIZE
        end
        y = y + consts.TILE_SIZE
    end

    local wall_x = -consts.WALL_TILE_SIZE -- So they also fill the corners.
    local wall_y = -consts.WALL_TILE_SIZE

    for i = 1, (self.height * 2 + -wall_y / consts.WALL_TILE_SIZE) + 1 do -- Since wall_y is already negative it will make it so no tiles are missing at the bottom.
        table.insert(self.tilemap, { -- Fills the corner of the room.
            tile = wall_tiles[1], -- Later change to the index that corresponds to the corner.
            position = {x = wall_x, y = wall_y}
        })
        wall_y = wall_y + consts.WALL_TILE_SIZE
    end
    wall_x = wall_x + consts.WALL_TILE_SIZE
    wall_y = consts.WALL_TILE_SIZE - consts.TILE_SIZE

    for i = 1, self.width * (consts.TILE_SIZE / consts.WALL_TILE_SIZE) do
        table.insert(self.tilemap, {
                tile = wall_tiles[1],
                position = {x = wall_x, y = wall_y} -- Prototypical code.
            })
        wall_x = wall_x + consts.WALL_TILE_SIZE
    end

    table.insert(self.tilemap, {
        tile = wall_tiles[1],
        position = {x = wall_x, y = wall_y}
    })
end

function Main.Tilemap:draw()
    for i = 1, #self.tilemap do
        love.graphics.push()
        love.graphics.scale(consts.TILE_SCALE, consts.TILE_SCALE)
        love.graphics.draw(self.tilemap[i].tile, self.tilemap[i].position.x, self.tilemap[i].position.y)
        love.graphics.pop()
    end
end

function Main.lerp(a, b, x, dt)
    local t = (1.0 - math.exp(-x * dt))
    return a * (1.0 - t) + b * t
end

return Main