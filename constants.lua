local love = require("love")
local set = require("settings")

local Main = {}

Main.RENDER_WIDTH = 640
Main.RENDER_HEIGHT = 360

Main.DEFAULT_FILTER = "nearest"
Main.DEFAULT_SCREENSHAKE_DURATION = 0.1

Main.CHARACTER_SIZE = 32

Main.TILE_SCALE = 1
Main.TILE_SIZE = 32
Main.WALL_TILE_SIZE = 16
Main.MIN_WIDTH_TILEMAP = 15
Main.MAX_WIDTH_TILEMAP = 20
Main.MIN_HEIGHT_TILEMAP = 10
Main.MAX_HEIGHT_TILEMAP = 15
Main.WALL_SHADOW_OFFSET = 5
Main.VBUCKS_AMOUNT = 9999

Main.ASSETS_PATH = "stuff/assets/"
Main.TILE_PATH = "stuff/assets/tiles/"
Main.SHADERS_PATH = "stuff/shaders/"
Main.SOUND_PATH = "stuff/assets/sounds/"
Main.CONSUMER_PATH = "stuff/assets/characters/consumer/"
Main.PARTICLE_PATH = "stuff/assets/particles/"
Main.FONT_PATH = "stuff/assets/fonts/"
Main.ENEMY_PATH = "stuff/assets/characters/enemies/"
Main.WEAPON_PATH = "stuff/assets/weapons/"
Main.TITLESCREEN_PATH = "stuff/assets/titlescreen/"

love.audio.setEffect("reverb", {type = "reverb"})

Main.WALK_SOUND = love.audio.newSource(Main.SOUND_PATH .. "footstep.wav", "static")
Main.WALK_SOUND:setVolume(set.sfx_volume)
Main.WALK_SOUND:setEffect("reverb")

Main.HIT_SOUND = love.audio.newSource(Main.SOUND_PATH .. "punch_hit.wav", "static")
Main.HIT_SOUND:setVolume(set.sfx_volume)
Main.HIT_SOUND:setEffect("reverb")

Main.MISS_SOUND = love.audio.newSource(Main.SOUND_PATH .. "punch_miss.wav", "static")
Main.MISS_SOUND:setVolume(set.sfx_volume)
Main.MISS_SOUND:setEffect("reverb")

Main.PARRY_SOUND = love.audio.newSource(Main.SOUND_PATH .. "parry.mp3", "static")
Main.PARRY_SOUND:setVolume(set.sfx_volume / 2)
Main.PARRY_SOUND:setEffect("reverb")

Main.PARRY_END_SOUND = love.audio.newSource(Main.SOUND_PATH .. "parry_end.mp3", "static")
Main.PARRY_END_SOUND:setVolume(set.sfx_volume/2)
Main.PARRY_END_SOUND:setEffect("reverb")

Main.MIN_ENEMY_SOUL = 3
Main.MAX_ENEMY_SOUL = 6
Main.MIN_ENEMY_ESSENCE = 5
Main.MAX_ENEMY_ESSENCE = 15

Main.BACKGROUND_COLOR = {0, 0, 0}
Main.SHADOW_COLOR = {0, 0, 0, 0.5}

Main.MIN_BLOOD = 100
Main.MAX_BLOOD = 200
Main.BLOOD_SPEED = 5000

Main.MIN_BURST = 200
Main.MAX_BURST = 400
Main.BURST_SPEED = 10000

return Main