-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.title = {}

function screen.title.load()
    screen.title.color = Vector4.one()

    print('loading title screen')

    local root = Node.create()

    local gw, gh = game:getWidth(), game:getHeight()

    local tw1, tw2, th = 306, 464, 74

    local title = Node.create()
    title:setTranslation(gw/2, gh * 1/3, 0)

    local title1 = newQuad(tw1, th, 'res/misc.material#title-1')
    title:addChild(title1)
    local title2 = newQuad(tw2, th, 'res/misc.material#title-2')
    title:addChild(title2)
    root:addChild(title)

    if aspect <= 1 then
        title1:setTranslation(0, -th, 0)
        title2:setTranslation(0, th, 0)
    else
        local w = tw1 + th + tw2
        title1:setTranslation(-w/2 + tw1/2, 0, 0)
        title2:setTranslation(w/2 - tw2/2, 0, 0)
    end

    local single = newButton(defaultButtonSize, defaultButtonSize,
        'res/misc.material#player-s',
        function(button)
            players = 1
            gotoScreen('level')
        end)
    root:addChild(single)

    local versus = newButton(2*defaultButtonSize, defaultButtonSize,
        nil,
        function(button)
            players = 2
            gotoScreen('level')
        end)
    root:addChild(versus)

    local player1 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player1:setTranslation(-defaultButtonSize/2, 0, 0)
    versus:addChild(player1)
    local player2 = newQuad(defaultButtonSize, defaultButtonSize, 'res/misc.material#player-1')
    player2:setTranslation(defaultButtonSize/2, 0, 0)
    player2:setScale(-1, 1, 0)
    versus:addChild(player2)

    if aspect <= 1 then
        single:setTranslation(gw * 1/4, gh * 3/4, 0)
        versus:setTranslation(gw * 3/4 - defaultButtonSize/2, gh * 3/4, 0)
    else
        single:setTranslation(gw * 1/3, gh * 2/3, 0)
        versus:setTranslation(gw * 2/3 - defaultButtonSize/2, gh * 2/3, 0)
    end

    screen.title.root = root
end

function screen.title.enter()
    print('entering title screen')
end

function screen.title.exit()
    print('exiting title screen')
end
