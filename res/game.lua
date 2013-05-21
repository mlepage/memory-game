-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

local q = Quaternion.new()

local playerS, player1, player2
local pause

local cards = {} -- all pairs of cards

local function newCard(letter)
    local card = newQuad(256, 256, 'res/card.material#back')

    local decal = newQuad(192, 192, 'res/card.material#decal-' .. letter)
    decal:rotate(0, 1, 0, 0)
    card:addChild(decal)

    local front = newQuad(256, 256, 'res/card.material#front')
    front:rotate(0, 1, 0, 0)
    card:addChild(front)

    card:setTag('letter', letter)

    return card
end

function screen.game.load()
    screen.game.color = Vector4.new(0.25, 0.25, 0.25, 1)

    print('loading game screen')

    local root = Node.create()

    pause = newButton(BUTTON, BUTTON,
        'res/button.material#pause',
        function(button)
            gotoScreen('level')
        end)
    root:addChild(pause)

    playerS = newQuad(BUTTON, BUTTON, 'res/misc.material#player-s')
    playerS:setTranslation(BUTTON/2, BUTTON/2, 0)

    player1 = newQuad(BUTTON, BUTTON, 'res/misc.material#player-1')
    player1:setTranslation(BUTTON/2, BUTTON/2, 0)

    player2 = newQuad(BUTTON, BUTTON, 'res/misc.material#player-1')
    player2:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    player2:setScale(-1, 1, 1)

    for i = 1, 26 do
        local letter = string.char(string.byte('a') + i - 1)
        cards[i] = { newCard(letter), newCard(letter) }
    end

    -- TEMP couple of cards for testing
    local card1 = cards[1][1]
    card1:setTranslation(GW * 1/3, GH/2, 0)
    root:addChild(card1)
    local card2 = cards[1][2]
    card2:setTranslation(GW * 2/3, GH/2, 0)
    root:addChild(card2)
    card2:rotate(0, 1, 0, 0)

    screen.game.root = root
end

function screen.game.enter()
    print('entering game screen')
    local root = screen.game.root
    if game.players == 1 then
        root:addChild(playerS)
        root:removeChild(player1)
        root:removeChild(player2)
        pause:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    else
        root:removeChild(playerS)
        root:addChild(player1)
        root:addChild(player2)
        pause:setTranslation(GW/2, BUTTON/2, 0)
    end
end
