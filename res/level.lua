-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.level = {}

local playerS, player1, player2

function screen.level.load()
    screen.level.color = Vector4.one()

    local root = Node.create()

    local lsize = GS / 4
    local lspace = GS / 5 * 3/2

    if ASPECT <= 1 then
        lsize = lsize * 13/16
        lspace = lspace * 13/16
    end

    local back = newButton(BUTTON, BUTTON,
        'res/button.material#back',
        function(button)
            gotoScreen('title')
        end)
    back:setTranslation(BUTTON/2, GH - BUTTON/2, 0)
    root:addChild(back)

    local l = 0
    for r = -1, 1 do
        for c = -1, 1 do
            l = l + 1
            do
                local level = l
                local button = newButton(lsize, lsize,
                    'res/button.material#level-' .. l,
                    function(button)
                        game.level = level
                        game.w, game.h = game.sizes[level][1], game.sizes[level][2]
                        gotoScreen('game')
                    end)
                button:setTranslation(GW/2 + c*lspace, GH/2 + r*lspace, 0)
                root:addChild(button)
            end
        end
    end

    playerS = newQuad(BUTTON, BUTTON, 'res/misc.material#player-s')
    playerS:setTranslation(BUTTON/2, BUTTON/2, 0)

    player1 = newQuad(BUTTON, BUTTON, 'res/misc.material#player-1')
    player1:setTranslation(BUTTON/2, BUTTON/2, 0)

    player2 = newQuad(BUTTON, BUTTON, 'res/misc.material#player-1')
    player2:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    player2:setScale(-1, 1, 1)

    screen.level.root = root
end

function screen.level.enter()
    local root = screen.level.root
    if game.players == 1 then
        root:addChild(playerS)
        root:removeChild(player1)
        root:removeChild(player2)
    else
        root:removeChild(playerS)
        root:addChild(player1)
        root:addChild(player2)
    end
end
