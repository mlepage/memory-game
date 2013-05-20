-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.level = {}

function screen.level.load()
    screen.level.color = Vector4.one()

    print('loading level screen')

    local gw, gh = game:getWidth(), game:getHeight()
    local lsize = math.min(gw, gh) / 4
    local lspace = math.min(gw, gh) / 5 * 3/2

    if gw <= gh then
        lsize = 0.8*lsize
        lspace = 0.8*lspace
    end

    local root = Node.create()

    local back = newButton(defaultButtonSize, defaultButtonSize,
        'res/card.material#head-p',
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
                'res/card.material#level-' .. l,
                function(button)
                    -- TODO set level to local l
                    gotoScreen('title')
                end)
            button:setTranslation(gw/2 + c*lspace, gh/2 + r*lspace, 0)
            root:addChild(button)
        end
    end

    screen.level.root = root
end

function screen.level.enter()
    print('entering level screen')
end
