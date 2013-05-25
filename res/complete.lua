-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.complete = {}

-- nodes
local root
local playerS, player1, player2
local next

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
    else
        root:addChild(player1)
        root:addChild(player2)
        player1:setTranslation(BUTTON/2, BUTTON/2, 0)
        player2:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
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
