-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

local playerS, player1, player2
local pause

function screen.game.load()
    screen.game.color = Vector4.new(0.5, 0.5, 0.5, 1)

    print('loading game screen')

    local root = Node.create()

    local gw, gh = game:getWidth(), game:getHeight()
    local lsize = math.min(gw, gh) / 4
    local lspace = math.min(gw, gh) / 5 * 3/2

    if aspect <= 1 then
        lsize = 0.8*lsize
        lspace = 0.8*lspace
    end

    pause = newButton(defaultButtonSize, defaultButtonSize,
        'res/button.material#pause',
        function(button)
            gotoScreen('level')
        end)
    root:addChild(pause)

    playerS = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-s')
    playerS:setTranslation(defaultButtonSize/2, defaultButtonSize/2, 0)

    player1 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player1:setTranslation(defaultButtonSize/2, defaultButtonSize/2, 0)

    player2 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player2:setTranslation(gw - defaultButtonSize/2, defaultButtonSize/2, 0)
    player2:setScale(-1, 1, 1)

    screen.game.root = root
end

function screen.game.enter()
    print('entering game screen')
    local root = screen.game.root
    local gw, gh = game:getWidth(), game:getHeight()
    if players == 1 then
        root:addChild(playerS)
        root:removeChild(player1)
        root:removeChild(player2)
        pause:setTranslation(gw - defaultButtonSize/2, defaultButtonSize/2, 0)
    else
        root:removeChild(playerS)
        root:addChild(player1)
        root:addChild(player2)
        pause:setTranslation(gw/2, defaultButtonSize/2, 0)
    end
end
