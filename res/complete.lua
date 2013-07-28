-- Memory game
-- Copyright 2013 Marc Lepage
-- Licensed under the Apache License, Version 2.0
-- http://www.apache.org/licenses/LICENSE-2.0

screen.complete = {}

-- nodes
local root
local player = {}
local next

local function animatePlayerToCenter(player)
    local x, y = player:getTranslationX(), player:getTranslationY()
    player:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 1000 }, { x,y,0, GW/2,GH*2/5,0 }, Curve.QUADRATIC_IN_OUT):play()
    player:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 1000 }, { 1,1,1, 3,3,1 }, Curve.QUADRATIC_IN_OUT):play()
end

function screen.complete.load()
    screen.complete.color = Vector4.one()

    root = Node.create()

    player[0] = newQuad(BUTTON, BUTTON)
    player[1] = newQuad(BUTTON, BUTTON)
    player[2] = newQuad(-BUTTON, BUTTON)

    local menu = newButton(BUTTON, BUTTON,
        'res/button.material#menu',
        function(button)
            gotoScreen('level')
        end)
    root:addChild(menu)

    local reset = newButton(BUTTON, BUTTON,
        'res/button.material#reset',
        function(button)
            gotoScreen('game')
        end)
    root:addChild(reset)

    next = newButton(BUTTON, BUTTON,
        'res/button.material#next',
        function(button)
            game.level = game.level + 1
            gotoScreen('game')
        end)
    root:addChild(next)

    menu:setTranslation(GW * 1/3, GH * 4/5, 0)
    reset:setTranslation(GW * 1/2, GH * 4/5, 0)
    next:setTranslation(GW * 2/3, GH * 4/5, 0)

    screen.complete.draw = screen.game.draw

    screen.complete.root = root
end

function screen.complete.enter()
    root:addChild(score[1])
    if game.players == 1 then
        screen.complete.blink(0, false)
        root:addChild(player[0])
        player[0]:setScale(1, 1, 1)
        player[0]:setTranslation(BUTTON/2, BUTTON/2, 0)
        animatePlayerToCenter(player[0])
    else
        screen.complete.blink(1, false)
        screen.complete.blink(2, false)
        root:addChild(score[2])
        root:addChild(player[1])
        root:addChild(player[2])
        player[1]:setScale(1, 1, 1)
        player[2]:setScale(1, 1, 1)
        player[1]:setTranslation(BUTTON/2, BUTTON/2, 0)
        player[2]:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
        local other = 1 + (1 - (game.player - 1))
        if game.score[game.player] <= game.score[other] then
            game.player = other
        end
        animatePlayerToCenter(player[game.player])
    end

    if game.level < 9 then
        root:addChild(next)
    end
end

function screen.complete.exit()
    root:removeChild(score[1])
    root:removeChild(score[2])
    root:removeChild(player[0])
    root:removeChild(player[1])
    root:removeChild(player[2])
    root:removeChild(next)
end

function screen.complete.blink(id, b)
    local key = id .. tostring(b)
    if materials[key] then
        player[id]:getModel():setMaterial(materials[key])
    else
        local name = 'res/misc.material#player-' .. (id == 2 and 1 or id) .. (b and '-blink' or '')
        player[id]:getModel():setMaterial(name)
        materials[key] = player[id]:getModel():getMaterial()
        materials[key]:addRef()
    end
end
