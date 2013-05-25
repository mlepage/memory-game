-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.complete = {}

-- nodes
local root
local playerS, player1, player2
local next

local function animatePlayerToCenter(player)
    local x, y = player:getTranslationX(), player:getTranslationY()
    player:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 1000 }, { x,y,0, GW/2,GH/3,0 }, Curve.QUADRATIC_IN_OUT):play()
    player:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 1000 }, { 1,1,1, 3,3,1 }, Curve.QUADRATIC_IN_OUT):play()
end

function screen.complete.load()
    screen.complete.color = Vector4.one()

    root = Node.create()

    playerS = newQuad(BUTTON, BUTTON, 'res/misc.material#player-s')
    player1 = newQuad(BUTTON, BUTTON, 'res/misc.material#player-1')
    player2 = newQuad(-BUTTON, BUTTON, 'res/misc.material#player-1')

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

    menu:setTranslation(GW * 1/3, GH * 2/3, 0)
    reset:setTranslation(GW * 1/2, GH * 2/3, 0)
    next:setTranslation(GW * 2/3, GH * 2/3, 0)

    screen.complete.root = root
end

function screen.complete.enter()
    if game.players == 1 then
        root:addChild(playerS)
        playerS:setTranslation(BUTTON/2, BUTTON/2, 0)
        animatePlayerToCenter(playerS)
    else
        root:addChild(player1)
        root:addChild(player2)
        player1:setTranslation(BUTTON/2, BUTTON/2, 0)
        player2:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
        animatePlayerToCenter(game.player == 1 and player1 or player2)
    end

    if game.level < 9 then
        root:addChild(next)
    end
end

function screen.complete.exit()
    root:removeChild(playerS)
    root:removeChild(player1)
    root:removeChild(player2)
    root:removeChild(next)
end
