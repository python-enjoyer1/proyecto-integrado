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

Main.ASSETS_PATH = "stuff/assets/"
Main.TILE_PATH = "stuff/assets/tiles/"
Main.SHADERS_PATH = "stuff/shaders/"
Main.SOUND_PATH = "stuff/assets/sounds/"
Main.CONSUMER_PATH = "stuff/assets/characters/consumer/"
Main.PARTICLE_PATH = "stuff/assets/particles/"
Main.FONT_PATH = "stuff/assets/fonts/"

Main.DEBUG = false

Main.MIN_ENEMY_SOUL = 5
Main.MAX_ENEMY_SOUL = 20
Main.MIN_ENEMY_ESSENCE = 5
Main.MAX_ENEMY_ESSENCE = 15

Main.BACKGROUND_COLOR = {0, 0, 0}
Main.SHADOW_COLOR = {0, 0, 0, 0.5}

Main.MIN_BLOOD = 100
Main.MAX_BLOOD = 200
Main.BLOOD_SPEED = 5000

return Main