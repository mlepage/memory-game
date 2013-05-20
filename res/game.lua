-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

function screen.game.load()
    screen.game.color = Vector4.zero()

    print('loading game screen')

    local gw, gh = game:getWidth(), game:getHeight()
    local lsize = math.min(gw, gh) / 4
    local lspace = math.min(gw, gh) / 5 * 3/2

    if gw <= gh then
        lsize = 0.8*lsize
        lspace = 0.8*lspace
    end

    local root = Node.create()

    local level = newButton(defaultButtonSize, defaultButtonSize,
        'res/card.material#head-p',
        function(button)
            gotoScreen('level')
        end)
    level:setTranslation(gw/2, defaultButtonSize/2, 0)
    root:addChild(level)

    screen.game.root = root
end

function screen.game.enter()
    print('entering game screen')
end
