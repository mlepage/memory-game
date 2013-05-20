-- Memory game
-- Copyright (C) 2013 Marc Lepage

-- http://en.wikipedia.org/wiki/Concentration_(game)

game = Game.getInstance()

screen = {}
local activeScreen, nextScreen
local activeScreenName, nextScreenName
local transitionNode
local transitionTime

local scene

local armedButton
local buttonx, buttony
local buttonHandlers = {}

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
    w=8, h=6, -- dimensions of tableau in cards
    cards={}, -- cards in row major order
    radius=40, -- radius of card in pixels
    ox=180, oy=50, -- origin of layout in pixels
    sx=120, sy=120, -- stride of layout in pixels
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

local function newQuad(w, h, material, id)
    local node = scene:addNode(id)

    w, h = w/2, h/2
    local mesh = Mesh.createQuad(
        Vector3.new(-w, -h, 0),
        Vector3.new(-w, h, 0),
        Vector3.new(w, -h, 0),
        Vector3.new(w, h, 0))
    node:setModel(Model.create(mesh))

    if material then
        node:getModel():setMaterial(material)
    end

    return node
end

local function newQuad2(w, h, material)
    local node = Node.create()

    w, h = w/2, h/2
    node:setModel(Model.create(
        Mesh.createQuad(
            Vector3.new(-w, -h, 0),
            Vector3.new(-w, h, 0),
            Vector3.new(w, -h, 0),
            Vector3.new(w, h, 0))))

    if material then
        node:getModel():setMaterial(material)
    end

    return node
end

local function newCard()
    local size = tableau.radius*2

    local card = newQuad(size, size, 'res/card.material#card-back', 'card-' .. #cards+1)

    local front = newQuad(size, size, 'res/card.material#card-front')
    front:rotate(0, 1, 0, 0)
    card:addChild(front)

    local symbol = newQuad(size/2, size/2, 'res/card.material#card-z')
    symbol:translate(0, 0, -1)
    symbol:rotate(0, 1, 0, 0)
    card:addChild(symbol)

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

function newButton(w, h, material, handler)
    local button = newQuad2(w, h, material)
    local hkey = tostring(handler)
    button:setTag('button', 'true')
    button:setTag('w', tostring(w))
    button:setTag('h', tostring(h))
    button:setTag('handler', hkey)
    buttonHandlers[hkey] = handler
    return button
end

function gotoScreen(name)
    nextScreenName = name
end

local function startGame()
    prepareCards()
    shuffleCards()
    layoutCards()
end

function visitArmButton(node)
    if node:hasTag('button') then
        local w, h = tonumber(node:getTag('w')), tonumber(node:getTag('h'))
        local x, y = node:getTranslationX(), node:getTranslationY()
        if x-w/2 <= buttonx and buttonx <= x+w/2 and y-h/2 <= buttony and buttony <= y+h/2 then
            local sx, sy = node:getScaleX(), node:getScaleY()
            node:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1.2,1.2,1 }, Curve.QUADRATIC_IN_OUT):play()
            armedButton = node
        end
        return false
    end
    return true
end

local function armButton(x, y)
    buttonx, buttony = x, y
    scene:visit('visitArmButton')
end

local function disarmButton(x, y)
    buttonx, buttony = x, y
    if armedButton then
        local node = armedButton
        local w, h = tonumber(node:getTag('w')), tonumber(node:getTag('h'))
        local x, y = node:getTranslationX(), node:getTranslationY()
        if not (x-w/2 <= buttonx and buttonx <= x+w/2 and y-h/2 <= buttony and buttony <= y+h/2) then
            local sx, sy = node:getScaleX(), node:getScaleY()
            node:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
            armedButton = nil
        end
    end
end

local function fireButton(x, y)
    buttonx, buttony = x, y
    if armedButton then
        local node = armedButton
        local w, h = tonumber(node:getTag('w')), tonumber(node:getTag('h'))
        local x, y = node:getTranslationX(), node:getTranslationY()
        if x-w/2 <= buttonx and buttonx <= x+w/2 and y-h/2 <= buttony and buttony <= y+h/2 then
            buttonHandlers[node:getTag('handler')](node)
        end
        local sx, sy = node:getScaleX(), node:getScaleY()
        node:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
        armedButton = nil
    end
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

        armButton(x, y)

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

        fireButton(x, y)

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

        disarmButton(x, y)

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
    if activeScreenName ~= nextScreenName then
        if not transitionTime then
            transitionTime = 0
            scene:addNode(transitionNode)
        else
            local updatedTime = transitionTime + elapsedTime/1000
            if transitionTime < 0.2 and 0.2 <= updatedTime then
                if activeScreen then
                    scene:removeNode(activeScreen.root)
                    if activeScreen.exit then
                        activeScreen.exit()
                    end
                end
                if not screen[nextScreenName] then
                    game:getScriptController():loadScript('res/' .. nextScreenName .. '.lua')
                    if screen[nextScreenName].load then
                        screen[nextScreenName].load()
                    end
                end
                nextScreen = screen[nextScreenName]
                if nextScreen.enter then
                    nextScreen.enter()
                end
                scene:removeNode(transitionNode)
                scene:addNode(nextScreen.root)
                scene:addNode(transitionNode)
            end
            transitionTime = updatedTime
            if updatedTime < 0.4 then
                local a = 1 - math.abs((updatedTime - 0.2) / 0.2)
                local effect = transitionNode:getModel():getMaterial():getTechnique():getPassByIndex(0):getEffect()
                local uniform = effect:getUniform('u_modulateAlpha')
                effect:setValue(uniform, a)
            else
                scene:removeNode(transitionNode)
                activeScreenName, activeScreen = nextScreenName, nextScreen
                transitionTime = nil
            end
        end
    end
end

function render(elapsedTime)
    game:clear(Game.CLEAR_COLOR_DEPTH, (activeScreen and activeScreen.color) or Vector4.one(), 1, 0)
    scene:visit('drawScene')
end

function initialize()
    scene = Scene.create()

    local gw, gh = game:getWidth(), game:getHeight()

    local camera = Camera.createOrthographic(1, 1, 1, 0, 1)

    local matrix = Matrix.new()
    Matrix.createOrthographicOffCenter(0, gw, gh, 0, -100, 100, matrix)
    camera:resetProjectionMatrix()
    camera:setProjectionMatrix(matrix)

    local cameraNode = scene:addNode('camera')
    cameraNode:setCamera(camera)
    scene:setActiveCamera(camera)
    cameraNode:translate(0, 0, 5);

    transitionNode = newQuad2(gw, gh, 'res/card.material#black')
    transitionNode:setTranslation(gw/2, gh/2, 0)
    scene:addNode(transitionNode)

    gotoScreen('title')
end

function finalize()
end
