-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.level = {}

local playerS, player1, player2

function screen.level.load()
    screen.level.color = Vector4.one()

    print('loading level screen')

    local root = Node.create()

    local gw, gh = game:getWidth(), game:getHeight()
    local lsize = math.min(gw, gh) / 4
    local lspace = math.min(gw, gh) / 5 * 3/2

    if gw <= gh then
        lsize = lsize * 13/16
        lspace = lspace * 13/16
    end

    local back = newButton(defaultButtonSize, defaultButtonSize,
        'res/button.material#back',
        function(button)
            gotoScreen('title')
        end)
    back:setTranslation(defaultButtonSize/2, gh - defaultButtonSize/2, 0)
    root:addChild(back)

    local l = 0
    for r = -1, 1 do
        for c = -1, 1 do
            l = l + 1
            local button = newButton(lsize, lsize,
                'res/button.material#level-' .. l,
                function(button)
                    -- TODO set level to local l
                    gotoScreen('game')
                end)
            button:setTranslation(gw/2 + c*lspace, gh/2 + r*lspace, 0)
            root:addChild(button)
        end
    end

    playerS = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-s')
    playerS:setTranslation(defaultButtonSize/2, defaultButtonSize/2, 0)

    player1 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player1:setTranslation(defaultButtonSize/2, defaultButtonSize/2, 0)

    player2 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player2:setTranslation(gw - defaultButtonSize/2, defaultButtonSize/2, 0)
    player2:setScale(-1, 1, 1)

    screen.level.root = root
end

function screen.level.enter()
    print('entering level screen')
    local root = screen.level.root
    if players == 1 then
        root:addChild(playerS)
        root:removeChild(player1)
        root:removeChild(player2)
    else
        root:removeChild(playerS)
        root:addChild(player1)
        root:addChild(player2)
    end
end
