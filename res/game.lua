-- Memory game
-- Copyright (C) 2013 Marc Lepage

-- http://en.wikipedia.org/wiki/Concentration_(game)

local game

local scene

local q = Quaternion.new()

local touches =
{
    { time=0, down=false, x=0, y=0, dx=0, dy=0, card=nil },
    { time=0, down=false, x=0, y=0, dx=0, dy=0, card=nil }
}

local memory =
{
    difficulty = 'normal',
    sizes = { easy={4,3}, normal={6,4}, hard={8,5} },
    width = 6,
    height = 4,
    cards = {} -- row major
}

-- List of all cards
local cards = {}

-- Tabular arrangement of cards
local tableau =
{
    w=6, h=4, -- dimensions of tableau in cards
    cards={}, -- cards in row major order
    radius=50, -- radius of card in pixels
    ox=250, oy=150, -- origin of layout in pixels
    sx=150, sy=150, -- stride of layout in pixels
}

-- Avoid allocating new objects every frame.
local textColor = Vector4.new(0, 0.5, 1, 1)

local flippedCard

function enter_card_idle(agent, state)
end

function exit_card_idle(agent, state)
end

function enter_card_touched(agent, state)
    local card = agent:getNode()
    local sx, sy = card:getScaleX(), card:getScaleY()
    card:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1.5,1.5,1 }, Curve.QUADRATIC_IN_OUT):play()
end

function exit_card_touched(agent, state)
    local card = agent:getNode()
    local sx, sy = card:getScaleX(), card:getScaleY()
    card:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
end

function enter_card_flipped(agent, state)
    local card = agent:getNode()
    card:getRotation(q)
    local x, y, z, w = q:x(), q:y(), q:z(), q:w()
    card:createAnimation('rotate', Transform.ANIMATE_ROTATE(), 2, { 0, 500 }, { x,y,z,w, 0,1,0,0 }, Curve.QUADRATIC_IN_OUT):play()
    local sx, sy = card:getScaleX(), card:getScaleY()
        card:createAnimation('scale2', Transform.ANIMATE_SCALE(), 3, { 0, 200, 400 }, { sx,sy,1, 1.5,1.5,1.5, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
    if sx ~= 1.5 then
    end
    if flippedCard then
        flippedCard:getAgent():getStateMachine():setState('idle')
    end
    flippedCard = card
end

function exit_card_flipped(agent, state)
    local card = agent:getNode()
    card:getRotation(q)
    local x, y, z, w = q:x(), q:y(), q:z(), q:w()
    card:createAnimation('rotate', Transform.ANIMATE_ROTATE(), 2, { 0, 500 }, { x,y,z,w, 0,0,0,1 }, Curve.QUADRATIC_IN_OUT):play()
end

-- Returns the nearest card and its distance
local function getNearestCard(x, y)
    local nearest, dsq = nil, math.huge
    for _, card in ipairs(cards) do
        local dx, dy = card:getTranslationX() - x, card:getTranslationY() - y
        local d =  dx*dx + dy*dy
        if d < dsq then
            nearest, dsq = card, d
        end
    end
    if nearest then
        return nearest, math.sqrt(dsq)
    end
end

-- Returns the nearest card if it is within the specified distance
local function getCardAt(x, y, dist)
    local card, d = getNearestCard(x, y)
    if card and d <= dist then
        return card
    end
end

local function newCardAgent()
    local agent = AIAgent.create()
    local stateMachine = agent:getStateMachine()
    local state
    state = stateMachine:addState('idle')
    state:addScriptCallback('enter', 'enter_card_idle')
    state:addScriptCallback('exit', 'exit_card_idle')
    state = stateMachine:addState('touched')
    state:addScriptCallback('enter', 'enter_card_touched')
    state:addScriptCallback('exit', 'exit_card_touched')
    state = stateMachine:addState('flipped')
    state:addScriptCallback('enter', 'enter_card_flipped')
    state:addScriptCallback('exit', 'exit_card_flipped')
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
    card:getModel():setMaterial('res/card.material#card-back')

    local front = scene:addNode('card-front')
    card:addChild(front)
    mesh = Mesh.createQuad(
        Vector3.new(R, -R, 0),
        Vector3.new(R, R, 0),
        Vector3.new(-R, -R, 0),
        Vector3.new(-R, R, 0))
    front:setModel(Model.create(mesh))
    front:getModel():setMaterial('res/card.material#card-front')

    card:setAgent(newCardAgent())
    card:getAgent():getStateMachine():setState('idle')
    
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

function keyEvent(event, key)
    if event == Keyboard.KEY_PRESS then
        if key == Keyboard.KEY_ESCAPE then
            Game.getInstance():exit()
        end
    end
end

function touchEvent(event, x, y, id)
    id = id + 1
    if 1 < id then
        return -- ignore extra touches
    end
    local touch = touches[id]
    if event == Touch.TOUCH_PRESS then
        touch.time, touch.down = Game.getAbsoluteTime(), true
        touch.x, touch.y, touch.dx, touch.dy = x, y, 0, 0

        local card = getCardAt(x, y, tableau.sx)
        if card then
            if 'idle' == card:getAgent():getStateMachine():getActiveState():getId() then
                card:getAgent():getStateMachine():setState('touched')
            end
            touch.card = card
        end
    elseif event == Touch.TOUCH_RELEASE then
        touch.time, touch.down = Game.getAbsoluteTime(), false
        touch.x, touch.y, touch.dx, touch.dy = x, y, x - touch.x, y - touch.y

        if touch.card then
            if 'touched' == touch.card:getAgent():getStateMachine():getActiveState():getId() then
                touch.card:getAgent():getStateMachine():setState('flipped')
            end
            touch.card = nil
        end

        -- Basic emulation of tap
        if (Game.getAbsoluteTime() - touch.time) < 200 then
        end
    elseif event == Touch.TOUCH_MOVE then
        touch.time = Game.getAbsoluteTime()
        touch.x, touch.y, touch.dx, touch.dy = x, y, x - touch.x, y - touch.y

        local card = getCardAt(x, y, tableau.sx)
        if touch.card ~= card then
            if touch.card and 'touched' == touch.card:getAgent():getStateMachine():getActiveState():getId() then
                touch.card:getAgent():getStateMachine():setState('idle')
            end
            if card and 'idle' == card:getAgent():getStateMachine():getActiveState():getId() then
                card:getAgent():getStateMachine():setState('touched')
            end
            touch.card = card
        end
        --cards[1]:rotateY(math.rad(touch.dx * 0.5))
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
