-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.title = {}

local player = {}

function screen.title.load()
    screen.title.color = Vector4.one()

    local root = Node.create()

    local tw1, tw2, th = 306, 464, 74

    local title = Node.create()
    title:setTranslation(GW/2, GH * 1/3, 0)

    local title1 = newQuad(tw1, th, 'res/misc.material#title-1')
    title:addChild(title1)
    local title2 = newQuad(tw2, th, 'res/misc.material#title-2')
    title:addChild(title2)
    root:addChild(title)

    if ASPECT <= 1 then
        title1:setTranslation(0, -th, 0)
        title2:setTranslation(0, th, 0)
    else
        local w = tw1 + th + tw2
        title1:setTranslation(-w/2 + tw1/2, 0, 0)
        title2:setTranslation(w/2 - tw2/2, 0, 0)
    end

    player[0] = newButton(BUTTON, BUTTON,
        nil,
        function(button)
            game.players = 1
            gotoScreen('level')
        end)
    root:addChild(player[0])

    local versus = newButton(2*BUTTON, BUTTON,
        nil,
        function(button)
            game.players = 2
            gotoScreen('level')
        end)
    root:addChild(versus)

    player[1] = newQuad(BUTTON, BUTTON)
    player[1]:setTranslation(-BUTTON/2, 0, 0)
    versus:addChild(player[1])
    player[2] = newQuad(BUTTON, BUTTON)
    player[2]:setTranslation(BUTTON/2, 0, 0)
    player[2]:setScale(-1, 1, 0)
    versus:addChild(player[2])

    if ASPECT <= 1 then
        player[0]:setTranslation(GW * 1/4, GH * 3/4, 0)
        versus:setTranslation(GW * 3/4 - BUTTON/2, GH * 3/4, 0)
    else
        player[0]:setTranslation(GW * 1/3, GH * 2/3, 0)
        versus:setTranslation(GW * 2/3 - BUTTON/2, GH * 2/3, 0)
    end

    screen.title.root = root
end

function screen.title.enter()
    for i = 0, 2 do
        screen.title.blink(i, false)
    end
end

function screen.title.blink(id, b)
    local mid = id == 2 and 1 or id
    local mb = b and '-blink' or ''
    local material = 'res/misc.material#player-' .. mid .. mb
    player[id]:getModel():setMaterial(material)
end
