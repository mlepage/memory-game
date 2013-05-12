-- Memory game
-- Copyright (C) 2013 Marc Lepage

-- http://en.wikipedia.org/wiki/Concentration_(game)

local game

local scene

local memory =
{
    difficulty = 'normal',
    sizes = { easy={4,3}, normal={6,4}, hard={8,5} },
    width = 6,
    height = 4,
    cards = {} -- row major
}

local tableau =
{
    w=6, h=4, -- dimensions of tableau in cards
    cards={}, -- cards in row major order
    radius=50, -- radius of card in pixels
    ox=250, oy=150, -- origin of layout in pixels
    sx=150, sy=150, -- stride of layout in pixels
}

-- List of all cards
local cards = {}

-- Avoid allocating new objects every frame.
local textColor = Vector4.new(0, 0.5, 1, 1)

function flippingEnter(agent, state)
    local card = agent:getNode()
    card:createAnimation('scale', Transform.ANIMATE_SCALE(), 3, { 0, 250, 500 }, { 1,1,1, 1.5,1.5,1.5, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
end

function flippingExit(agent, state)
end

function cardIdleEnter(agent, state)
end

function cardIdleExit(agent, state)
end

local function getCardAt(x, y)
    x, y = x - (tableau.ox - tableau.sx/2), y - (tableau.oy - tableau.sy/2)
    local r, c = 1 + math.floor(y/tableau.sy), 1 + math.floor(x/tableau.sx)
    if 1 <= r and r <= tableau.h and 1 <= c and c <= tableau.w then
        return tableau.cards[r][c]
    end
end

local function newCardAgent()
    local agent = AIAgent.create()
    local stateMachine = agent:getStateMachine()
    local state = stateMachine:addState('flipping')
    state:addScriptCallback('enter', 'flippingEnter')
    state:addScriptCallback('exit', 'flippingExit')
    return agent
end

local function newCard()
    local card = scene:addNode('card-' .. #cards+1)

    local R = tableau.radius
    local mesh = Mesh.createQuad(
        Vector3.new(-R, -R, 0),
        Vector3.new(-R, R, 0),
        Vector3.new(R, -R, 0),
        Vector3.new(R, R, 0))
    card:setModel(Model.create(mesh))
    card:getModel():setMaterial('res/card.material')

    card:setAgent(newCardAgent())
    
    return card
end

-- Ensure we have the proper number of cards
local function prepareCards()
    local num = tableau.w * tableau.h
    while (#cards < num) do
        cards[#cards+1] = newCard()
    end
    while (num < #cards) do
        cards[#cards] = nil
    end
end

-- Shuffle the cards
local function shuffleCards()
    for i = 1, #cards do
        local j = math.random(#cards)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

-- Lay out the cards
local function layoutCards()
    local i = 1
    for r = 1, tableau.h do
        tableau.cards[r] = {}
        for c = 1, tableau.w do
            local card = cards[i]
            tableau.cards[r][c] = card
            card:setTranslation(tableau.ox + (c-1)*tableau.sx, tableau.oy + (r-1)*tableau.sy, 0)
            i = i + 1
        end
    end
end

local function startGame()
    prepareCards()
    shuffleCards()
    layoutCards()
end

function drawScene(node)
    local model = node:getModel()
    if model then
        model:draw()
    end
    return true
end

function drawSplash()
    local game = Game.getInstance()
    game:clear(Game.CLEAR_COLOR_DEPTH, 0, 0, 0, 1, 1.0, 0)
    local batch = SpriteBatch.create('res/logo_powered_white.png')
    batch:start()
    batch:draw(game:getWidth() * 0.5, game:getHeight() * 0.5, 0.0, 512.0, 512.0, 0.0, 1.0, 1.0, 0.0, Vector4.one(), true)
    batch:finish()
end

function _controlEvent(control, event)
    print('_controlEvent', event)
    if (event == Control.Listener.CLICK) then
        local deltaX = 10
        _modelNode:rotateY(math.rad(deltaX * 0.5))
    end
end

function _controlEvent2(control, event)
    print('_controlEvent2', event)
    if (event == Control.Listener.CLICK) then
        local deltaX = -10
        _modelNode:rotateY(math.rad(deltaX * 0.5))
    end
end

function keyEvent(evt, key)
    if evt == Keyboard.KEY_PRESS then
        if key == Keyboard.KEY_ESCAPE then
            Game.getInstance():exit()
        end
    end
end

function touchEvent(evt, x, y, contactIndex)
    if evt == Touch.TOUCH_PRESS then
        _touchTime = Game.getAbsoluteTime()
        _touched = true
        _touchX = x
        local card = getCardAt(x, y)
        if card then
            card:getAgent():getStateMachine():setState('flipping')
        end
    elseif evt == Touch.TOUCH_RELEASE then
        _touched = false
        _touchX = 0

        -- Basic emulation of tap to change state
        if (Game.getAbsoluteTime() - _touchTime) < 200 then
            --_scaleClip = _modelNode:createAnimation('scale', Transform.ANIMATE_SCALE(), 3, { 0, 250, 500 }, { 50,50,50, 75,75,75, 50,50,50 }, Curve.QUADRATIC_IN_OUT):getClip()
            --_scaleClip:play()
            --_modelNode:getAgent():getStateMachine():setState('flipping')
            --toggleState()
        end
    elseif evt == Touch.TOUCH_MOVE then
        local deltaX = x - _touchX
        _touchX = x
        _modelNode:rotateY(math.rad(deltaX * 0.5))
    end    
end

function update(elapsedTime)
    _form:update(elapsedTime)
end

function render(elapsedTime)
    -- Clear the color and depth buffers.
    Game.getInstance():clear(Game.CLEAR_COLOR_DEPTH, Vector4.zero(), 1.0, 0)

    -- Visit all the nodes in the scene, drawing the models/mesh.
    scene:visit('drawScene')

    _form:draw()

    -- Draw the fps.
    --local buffer = string.format('%u\n%s', Game.getInstance():getFrameRate(), _stateMachine:getActiveState():getId())
    --_font:start()
    --_font:drawText(buffer, 5, 1, textColor, _font:getSize())
    --_font:finish()
end

function initialize()
    -- Display splash screen for at least 1 second.
    --ScreenDisplayer.start('drawSplash', 1000)

    game = Game.getInstance()

    scene = Scene.create()

    _touched = false
    _touchX = 0

    -- Load font
    --_font = Font.create('res/arial40.gpb')

    --local camera = Camera.createOrthographic(10, 10, 1280/720, 1, 10)
    local camera = Camera.createOrthographic(1, 1, 1, 0, 1)

    local matrix = Matrix.new()
    Matrix.createOrthographicOffCenter(0, game:getWidth(), game:getHeight(), 0, -100, 100, matrix)
    camera:resetProjectionMatrix()
    camera:setProjectionMatrix(matrix)

    local cameraNode = scene:addNode('camera')
    cameraNode:setCamera(camera)
    scene:setActiveCamera(camera)
    cameraNode:translate(0, 0, 5);

    startGame()
    --_modelNode = memory.cards[1][1].node

    _form = Form.create('res/editor.form')
    
    _reset = _form:getControl('reset');
    _reset:addScriptCallback('controlEvent', '_controlEvent');
    _emit = _form:getControl('emit');
    _emit:addScriptCallback('controlEvent', '_controlEvent2');

    ScreenDisplayer.finish()
end

function finalize()
    --_font = nil
    game = nil
    scene = nil
end
