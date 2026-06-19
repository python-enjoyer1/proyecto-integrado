local love = require("love")
local set = require("settings")

local consts = {}

consts.RENDER_WIDTH = 640
consts.RENDER_HEIGHT = 360

consts.DEFAULT_FILTER = "nearest"
consts.DEFAULT_SCREENSHAKE_DURATION = 0.1

consts.CHARACTER_SIZE = 32

consts.TILE_SIZE = 16
consts.VBUCKS_AMOUNT = 9999 -- What the fuck?

consts.ASSETS_PATH = "stuff/assets/"
consts.TILE_PATH = "stuff/assets/tiles/"
consts.SHADERS_PATH = "stuff/shaders/"
consts.SOUND_PATH = "stuff/assets/sounds/"
consts.CONSUMER_PATH = "stuff/assets/characters/consumer/"
consts.PARTICLE_PATH = "stuff/assets/particles/"
consts.FONT_PATH = "stuff/assets/fonts/"
consts.ENEMY_PATH = "stuff/assets/characters/enemies/"
consts.WEAPON_PATH = "stuff/assets/weapons/"
consts.TITLESCREEN_PATH = "stuff/assets/titlescreen/"
consts.DECAL_PATH = "stuff/assets/decals/"

love.audio.setEffect("reverb", {type = "reverb"})

consts.WALK_SOUND = love.audio.newSource(consts.SOUND_PATH .. "footstep.wav", "static")
consts.WALK_SOUND:setVolume(set.sfx_volume)
consts.WALK_SOUND:setEffect("reverb")

consts.HIT_SOUND = love.audio.newSource(consts.SOUND_PATH .. "punch_hit.wav", "static")
consts.HIT_SOUND:setVolume(set.sfx_volume)
consts.HIT_SOUND:setEffect("reverb")

consts.MISS_SOUND = love.audio.newSource(consts.SOUND_PATH .. "punch_miss.wav", "static")
consts.MISS_SOUND:setVolume(set.sfx_volume)
consts.MISS_SOUND:setEffect("reverb")

consts.PARRY_SOUND = love.audio.newSource(consts.SOUND_PATH .. "parry.mp3", "static")
consts.PARRY_SOUND:setVolume(set.sfx_volume / 2)
consts.PARRY_SOUND:setEffect("reverb")

consts.PARRY_END_SOUND = love.audio.newSource(consts.SOUND_PATH .. "parry_end.mp3", "static")
consts.PARRY_END_SOUND:setVolume(set.sfx_volume / 2)
consts.PARRY_END_SOUND:setEffect("reverb")

consts.VAS_INANIMATUM = love.audio.newSource("stuff/assets/music/vas_inanimatum.mp3", "stream")
consts.VAS_INANIMATUM:setVolume(set.music_volume)

consts.MIN_ENEMY_SOUL = 3
consts.MAX_ENEMY_SOUL = 6
consts.MIN_ENEMY_ESSENCE = 5
consts.MAX_ENEMY_ESSENCE = 15

consts.BACKGROUND_COLOR = {0, 0, 0}
consts.SHADOW_COLOR = {0, 0, 0, 0.5}

consts.BLOOD = {}

for count = 1, 1 do -- Change the limit when we add more bloodstains.
    table.insert(consts.BLOOD, love.graphics.newImage(consts.DECAL_PATH .. "blood" .. count .. ".png"))
end

consts.MIN_BURST = 200
consts.MAX_BURST = 400
consts.BURST_SPEED = 10000

consts.HIGH_FLOOR_TILES = {}
consts.HIGH_WALL_TILES = {}

consts.HIGH_MIN_WIDTH = 20
consts.HIGH_MAX_WIDTH = 50
consts.HIGH_MIN_HEIGHT = 20
consts.HIGH_MAX_HEIGHT = 50

for count = 1, 3 do
    local image = love.graphics.newImage(consts.TILE_PATH .. "high_floor/tile" .. count .. ".png")
    image:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
    table.insert(consts.HIGH_FLOOR_TILES, image)
end

for count = 1, 3 do
    local image = love.graphics.newImage(consts.TILE_PATH .. "high_walls/tile" .. count .. ".png")
    image:setFilter(consts.DEFAULT_FILTER, consts.DEFAULT_FILTER)
    table.insert(consts.HIGH_WALL_TILES, image)
end


return consts