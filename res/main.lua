-- Memory game
-- Copyright (C) 2013 Marc Lepage

-- http://en.wikipedia.org/wiki/Concentration_(game)

GW, GH = 720, 720
GS, GL = math.min(GW, GH), math.max(GW, GH)
ASPECT = GW/GH
BUTTON = 64

game =
{
    players = 1, -- number of players (1 or 2)
    player = 1,  -- current player (1 or 2)
    level = 1,   -- level (1 to 9)
    sizes = {{4,2},{4,3},{4,4},{5,4},{6,4},{6,5},{6,6},{7,6},{8,6}},
}

local blink = { [0]={ t=0, b=false }, { t=0, b=false }, { t=0, b=false } }

screen = {}
local activeScreen
local activeScreenName, nextScreenName
local transitionNode
local transitionTime

local scene

local armedButton
local buttonx, buttony
local buttonHandlers = {}

function newQuad(w, h, material, id)
    local node = Node.create(id)

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

function newButton(w, h, material, handler)
    local button = newQuad(w, h, material)
    local hkey = tostring(handler)
    button:setTag('button', 'true')
    button:setTag('w', tostring(w))
    button:setTag('h', tostring(h))
    button:setTag('handler', hkey)
    buttonHandlers[hkey] = handler
    return button
end

function setButtonSize(button, w, h)
    button:setTag('w', tostring(w))
    button:setTag('h', tostring(h))
end

function setButtonEnabled(button, enabled)
    if enabled then
        button:setTag('disabled', nil)
    else
        button:setTag('disabled', 'true')
    end
end

function gotoScreen(name, force)
    nextScreenName = name
    transitionTime = 0
    scene:addNode(transitionNode)
end

function loadScreen(name)
    if not screen[name] then
        Game.getInstance():getScriptController():loadScript('res/' .. name .. '.lua')
        if screen[name].load then
            screen[name].load()
        end
    end
end

function visitArmButton(node)
    if node:hasTag('button') and not node:hasTag('disabled') then
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
        local sx, sy = node:getScaleX(), node:getScaleY()
        node:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 200 }, { sx,sy,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
        local w, h = tonumber(node:getTag('w')), tonumber(node:getTag('h'))
        local x, y = node:getTranslationX(), node:getTranslationY()
        if x-w/2 <= buttonx and buttonx <= x+w/2 and y-h/2 <= buttony and buttony <= y+h/2 then
            buttonHandlers[node:getTag('handler')](node)
        end
        armedButton = nil
    end
end

local function getLastChild(node)
    local child = node:getFirstChild()
    if child then
        local next = child:getNextSibling()
        while next do
            child, next = next, next:getNextSibling()
        end
    end
    return child
end

local function drawNode(node)
    local model = node:getModel()
    if model then
        model:draw()
    end
    local child = getLastChild(node)
    while child do
        drawNode(child)
        child = child:getPreviousSibling()
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
    if event == Touch.TOUCH_PRESS then
        armButton(x, y)
    elseif event == Touch.TOUCH_RELEASE then
        fireButton(x, y)
    elseif event == Touch.TOUCH_MOVE then
        disarmButton(x, y)
    end
end

function update(elapsedTime)
    for i = 0, 2 do
        blink[i].t = blink[i].t - elapsedTime/1000
        if blink[i].t <= 0 then
            blink[i].b = not blink[i].b
            if activeScreen and activeScreen.blink then
                activeScreen.blink(i, blink[i].b)
            end
            if blink[i].b then
                blink[i].t = 0.1 + 0.3*math.random()
            else
                blink[i].t = 2 + 8*math.random()
            end
        end
    end

    if transitionTime then
        local updatedTime = transitionTime + elapsedTime/1000
        if transitionTime < 0.2 and 0.2 <= updatedTime then
            if activeScreen then
                scene:removeNode(activeScreen.root)
                if activeScreen.exit then
                    activeScreen.exit()
                end
            end
            loadScreen(nextScreenName)
            activeScreenName, activeScreen = nextScreenName, screen[nextScreenName]
            if activeScreen.enter then
                activeScreen.enter()
            end
            scene:removeNode(transitionNode)
            scene:addNode(activeScreen.root)
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
            transitionTime = nil
        end
    end

    if activeScreen and activeScreen.update then
        activeScreen.update(elapsedTime)
    end
end

function render(elapsedTime)
    Game.getInstance():clear(Game.CLEAR_COLOR_DEPTH, (activeScreen and activeScreen.color) or Vector4.one(), 1, 0)

    -- draw scene in reverse child order since children are added first
    local node = scene:getFirstNode()
    while node do
        local next = node:getNextSibling()
        if not next then
            break
        end
        node = next
    end
    while node do
        drawNode(node)
        node = node:getNextSibling()
    end
end

function initialize()
    math.randomseed(os.time())

    scene = Scene.create()

    GW, GH = Game.getInstance():getWidth(), Game.getInstance():getHeight()
    GS, GL = math.min(GW, GH), math.max(GW, GH)
    ASPECT = GW/GH
    BUTTON = GS / 6

    local camera = Camera.createOrthographic(1, 1, 1, 0, 1)

    local matrix = Matrix.new()
    Matrix.createOrthographicOffCenter(0, GW, GH, 0, -100, 100, matrix)
    camera:resetProjectionMatrix()
    camera:setProjectionMatrix(matrix)

    local cameraNode = scene:addNode('camera')
    cameraNode:setCamera(camera)
    scene:setActiveCamera(camera)
    cameraNode:translate(0, 0, 5);

    transitionNode = newQuad(GW, GH, 'res/misc.material#black')
    transitionNode:setTranslation(GW/2, GH/2, 0)
    scene:addNode(transitionNode)

    for i = 0, 2 do
        blink[i].t = 2 + 8*math.random()
    end

    loadScreen('title')
    loadScreen('level')
    loadScreen('game')

    gotoScreen('title')
end

function finalize()
end
