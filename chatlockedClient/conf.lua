function love.conf(t)
    t.identity = "chatlock_cl"
    t.version = "11.1"
    t.console = false

	t.window.title = "Chatlocked Client"
	t.window.width = 800
	t.window.height = 600
	t.window.resizable = true
	t.window.minwidth = 800
	t.window.minheight = 200
	
    t.modules.audio = false            -- Enable the audio module (boolean)
    t.modules.event = true             -- Enable the event module (boolean)
    t.modules.graphics = true          -- Enable the graphics module (boolean)
    t.modules.image = true             -- Enable the image module (boolean)
    t.modules.joystick = false         -- Enable the joystick module (boolean)
    t.modules.keyboard = true          -- Enable the keyboard module (boolean)
    t.modules.math = false             -- Enable the math module (boolean)
    t.modules.mouse = false            -- Enable the mouse module (boolean)
    t.modules.physics = false          -- Enable the physics module (boolean)
    t.modules.sound = false            -- Enable the sound module (boolean)
    t.modules.system = false           -- Enable the system module (boolean)
    t.modules.timer = false            -- Enable the timer module (boolean)
    t.modules.window = true            -- Enable the window module (boolean)
    t.modules.thread = true            -- Enable the thread module (boolean)
end
