-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.level = {}

function screen.level.load()
    screen.level.color = Vector4.zero()

    print('loading level screen')

    local gw, gh = game:getWidth(), game:getHeight()
    local sz = math.min(gw, gh) / 6

    local root = Node.create()

    local single = newButton(sz, sz, 'res/card.material#head-p',
        function(button)
            gotoScreen('title')
        end)
    single:setTranslation(gw * 1/3, gh * 2/3, 0)
    root:addChild(single)

    local versus = newButton(sz, sz, 'res/card.material#head-f',
        function(button)
            gotoScreen('level')
        end)
    versus:setTranslation(gw * 2/3, gh * 2/3, 0)
    root:addChild(versus)

    screen.level.root = root
end

function screen.level.enter()
    print('entering level screen')
end
