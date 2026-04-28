local Main = {}

Main.RENDER_WIDTH = 640
Main.RENDER_HEIGHT = 360
Main.DEFAULT_FILTER = "nearest"
Main.CHARACTER_SIZE = 32
Main.TILE_SCALE = 1
Main.TILE_SIZE = 32 * Main.TILE_SCALE
Main.MIN_TILEMAP = 15
Main.MAX_TILEMAP = 25
Main.ASSETS_PATH = "stuff/assets/"
Main.TILE_PATH = "stuff/assets/tiles/"
Main.DEBUG = false
Main.SHADING = true -- Maybe make it an option for performance?

return Main