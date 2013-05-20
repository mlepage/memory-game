-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

function screen.game.load()
    screen.game.color = Vector4.new(0.5, 0.5, 0.5, 1)

    print('loading game screen')

    local gw, gh = game:getWidth(), game:getHeight()
    local lsize = math.min(gw, gh) / 4
    local lspace = math.min(gw, gh) / 5 * 3/2

    if gw <= gh then
        lsize = 0.8*lsize
        lspace = 0.8*lspace
    end

    local root = Node.create()

    local pause = newButton(defaultButtonSize, defaultButtonSize,
        'res/button.material#pause',
        function(button)
            gotoScreen('level')
        end)
    pause:setTranslation(gw/2, defaultButtonSize/2, 0)
    root:addChild(pause)

    screen.game.root = root
end

function screen.game.enter()
    print('entering game screen')
end
