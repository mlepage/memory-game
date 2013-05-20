-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.title = {}

function screen.title.load()
    screen.title.color = Vector4.one()

    print('loading title screen')

    local gw, gh = game:getWidth(), game:getHeight()

    local root = Node.create()

    local single = newButton(defaultButtonSize, defaultButtonSize,
        'res/card.material#head-f',
        function(button)
            players = 1
            gotoScreen('level')
        end)
    single:setTranslation(gw * 1/3, gh * 2/3, 0)
    root:addChild(single)

    local versus = newButton(defaultButtonSize, defaultButtonSize,
        'res/card.material#head-p',
        function(button)
            players = 2
            gotoScreen('level')
        end)
    versus:setTranslation(gw * 2/3, gh * 2/3, 0)
    root:addChild(versus)

    screen.title.root = root
end

function screen.title.enter()
    print('entering title screen')
end

function screen.title.exit()
    print('exiting title screen')
end
