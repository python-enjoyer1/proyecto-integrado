local Main = {}

Main.RENDER_WIDTH = 640
Main.RENDER_HEIGHT = 360
Main.DEFAULT_FILTER = "nearest"
Main.CAMERA_MOVEMENT = 3 -- Perfect value, in my opinion.

Main.CHARACTER_SIZE = 32

Main.TILE_SCALE = 1
Main.TILE_SIZE = 32
Main.WALL_TILE_SIZE = 16 -- Later change to the new size.
Main.MIN_WIDTH_TILEMAP = 15
Main.MAX_WIDTH_TILEMAP = 20
Main.MIN_HEIGHT_TILEMAP = 10
Main.MAX_HEIGHT_TILEMAP = 15

Main.ASSETS_PATH = "stuff/assets/"
Main.TILE_PATH = "stuff/assets/tiles/"
Main.DEBUG = false

Main.SHADING = true -- Maybe make it an option for performance?

Main.BACKGROUND_COLOR = {0.294, 0.294, 0.294}

return Main