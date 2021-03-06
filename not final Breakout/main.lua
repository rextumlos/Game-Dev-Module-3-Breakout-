--[[
    GD50
    Breakout Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally developed by Atari in 1976. An effective evolution of
    Pong, Breakout ditched the two-player mechanic in favor of a single-
    player game where the player, still controlling a paddle, was tasked
    with eliminating a screen full of differently placed bricks of varying
    values by deflecting a ball back at them.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.

    Credit for graphics (amazing work!):
    https://opengameart.org/users/buch

    Credit for music (great loop):
    http://freesound.org/people/joshuaempyre/sounds/251461/
    http://www.soundcloud.com/empyreanma
]]

require 'src/Dependencies'

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()

    love.graphics.setDefaultFilter('nearest', 'nearest')


    math.randomseed(os.time())


    love.window.setTitle('Breakout')


    gFonts = {
        ['sml'] = love.graphics.newFont('fonts/font.ttf', 8),
        ['mdm'] = love.graphics.newFont('fonts/font.ttf', 16),
        ['lrg'] = love.graphics.newFont('fonts/font.ttf', 32)
    }
    love.graphics.setFont(gFonts['sml'])

    gTextures = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['main'] = love.graphics.newImage('graphics/breakout.png'),
        ['arrows'] = love.graphics.newImage('graphics/arrows.png'),
        ['hearts'] = love.graphics.newImage('graphics/hearts.png'),
        ['particle'] = love.graphics.newImage('graphics/particle.png')
    }


    gFrames = {
        ['arrows'] = GenerateQuads(gTextures['arrows'], 24, 24),
        ['paddles'] = GenerateQuadsPaddles(gTextures['main']),
        ['balls'] = GenerateQuadsBalls(gTextures['main']),
        ['bricks'] = GenerateQuadsBricks(gTextures['main']),
        ['powerups'] = GenerateQuadsPowerups(gTextures['main']), 
        ['hearts'] = GenerateQuads(gTextures['hearts'], 10, 9)
    }
    

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })


    gSounds = {
        ['paddle-hit'] = love.audio.newSource('sounds/paddle_hit.wav','static'),
        ['score'] = love.audio.newSource('sounds/score.wav','static'),
        ['wall-hit'] = love.audio.newSource('sounds/wall_hit.wav','static'),
        ['confirm'] = love.audio.newSource('sounds/confirm.wav','static'),
        ['select'] = love.audio.newSource('sounds/select.wav','static'),
        ['no-select'] = love.audio.newSource('sounds/no-select.wav','static'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav','static'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav','static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav','static'),
        ['victory'] = love.audio.newSource('sounds/victory.wav','static'),
        ['recover'] = love.audio.newSource('sounds/recover.wav','static'),
        ['high-score'] = love.audio.newSource('sounds/high_score.wav','static'),
        ['pause'] = love.audio.newSource('sounds/pause.wav','static'),

        ['music'] = love.audio.newSource('sounds/music.wav','stream')
    }



    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['serve'] = function() return ServeState() end,
        ['game-over'] = function() return GameOverState() end,
        ['victory'] = function() return VictoryState() end,
        ['high-Scrs'] = function() return HighScrstate() end,
        ['enter-high-score'] = function() return EnterHighScrstate() end,
        ['paddle-select'] = function() return PaddleSelectState() end
    }
    gStateMachine:change('start', {
        highScrs = loadHighScrs()
    })

    gSounds['music']:play()
    gSounds['music']:setLooping(true)

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)

    gStateMachine:update(dt)


    love.keyboard.keysPressed = {}
end

function love.keypressed(key)

    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end

function love.draw()

    push:apply('start')


    local bgrWidth = gTextures['background']:getWidth()
    local bgrHeight = gTextures['background']:getHeight()

    love.graphics.draw(gTextures['background'], 

        0, 0, 

        0,

        VIRTUAL_WIDTH / (bgrWidth - 1), VIRTUAL_HEIGHT / (bgrHeight - 1))
    

    gStateMachine:render()

    displayFPS()
    
    push:apply('end')
end

function loadHighScrs()
    love.filesystem.setIdentity('breakout')

    if not love.filesystem.getInfo('breakout.lst') == nil then
        local Scrs = ''
        for i = 10, 1, -1 do
            Scrs = Scrs .. 'CTO\n'
            Scrs = Scrs .. tostring(i * 1000) .. '\n'
        end

        love.filesystem.write('breakout.lst', Scrs)
    end

    local name = true
    local crntName = nil
    local cntr = 1

    local Scrs = {}

    for i = 1, 10 do
        Scrs[i] = {
            name = nil,
            score = nil
        }
    end


    for line in love.filesystem.lines('breakout.lst') do
        if name then
            Scrs[cntr].name = string.sub(line, 1, 3)
        else
            Scrs[cntr].score = tonumber(line)
            cntr = cntr + 1
        end


        name = not name
    end

    return Scrs
end


function renderHealth(health)

    local healthX = VIRTUAL_WIDTH - 100
    

    for i = 1, health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][1], healthX, 4)
        healthX = healthX + 11
    end


    for i = 1, 3 - health do
        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][2], healthX, 4)
        healthX = healthX + 11
    end
end


function renderKeys(keys) 
    love.graphics.draw(gTextures['main'], gFrames['powerups'][10], VIRTUAL_WIDTH - 40,  VIRTUAL_HEIGHT - 15, 0)
    love.graphics.setFont(gFonts['sml'])
    love.graphics.print("X "..keys, VIRTUAL_WIDTH - 20, VIRTUAL_HEIGHT - 15)
end

function displayFPS()

    love.graphics.setFont(gFonts['sml'])
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
end


function renderScore(score)
    love.graphics.setFont(gFonts['sml'])
    love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)
    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end
