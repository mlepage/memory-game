-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

local q = Quaternion.new()

local root
local playerS, player1, player2
local pause

local cards = {} -- all pairs of cards

local function newCard(letter)
    local card = Node.create('card')

    local decal = newQuad(192, 192, 'res/card.material#decal-' .. letter)
    decal:rotate(0, 1, 0, 0)
    card:addChild(decal)

    local front = newQuad(256, 256, 'res/card.material#front')
    front:rotate(0, 1, 0, 0)
    card:addChild(front)

    local back = newQuad(256, 256, 'res/card.material#back')
    card:addChild(back)

    card:setTag('letter', letter)

    return card
end

local function setCardSize(card, size)
    local scale = size/256
    local child = card:getFirstChild()
    while child do
        child:setScale(scale, scale, 1)
        child = child:getNextSibling()
    end
end

function screen.game.load()
    screen.game.color = Vector4.new(0.25, 0.25, 0.25, 1)

    root = Node.create()

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
    --card2:rotate(0, 1, 0, 0)
    setCardSize(card2, 100)

    screen.game.root = root
end

function screen.game.enter()
    if game.players == 1 then
        root:addChild(playerS)
        pause:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    else
        root:addChild(player1)
        root:addChild(player2)
        pause:setTranslation(GW/2, BUTTON/2, 0)
    end

    local total = game.w * game.h
    local used = {}
    while #used < total do
        local i = math.random(26)
        if not cards[i].used then
            used[#used+1] = cards[i][1]
            used[#used+1] = cards[i][2]
            cards[i].used = true
        end
    end
    for i = 1, total do
        local j = math.random(total)
        used[i], used[j] = used[j], used[i]
    end

    -- space reserved for top
    local top = BUTTON*0.85

    -- screen aspect ratio
    local sw, sh = GW, GH - top
    local sa = sw/sh

    -- tableau aspect ratio (minimum two rows)
    local th = 2
    local tw = math.ceil(total/th)
    local ta = tw/th
    local te = 0

    -- find tableau that best matches screen aspect ratio
    while true do
        local h = th + 1
        local w = math.ceil(total/h)
        local a = w/h
        local e = w*h - total
        if math.abs(a-sa) < math.abs(ta-sa) or
                (math.abs(a-sa) == math.abs(ta-sa) and e < te) then
            tw, th, ta, te = w, h, a, e
        else
            break
        end
    end

    -- unit width and height: card is 4 units, margin is 1 unit
    local uw, uh = tw*4 + tw+1, th*4 + th+1
    -- card size and margin (in pixels)
    local size = 4 * math.min(GW/uw, (GH-top)/uh)
    local margin = size/4
    -- offset of tableau
    local ox, oy = (GW-uw*margin)/2, (GH-top-uh*margin)/2

    local i = 1
    local y = top + oy + margin + size/2
    for r = 1, th do
        local x = ox + margin + size/2
        if r == th then
            x = x + (margin+size)*te/2
        end
        for c = 1, tw do
            local card = used[i]
            setCardSize(card, size)
            card:setTranslation(x, y, 0)
            card:rotate(0, 1, 0, 0)
            root:addChild(card)
            if i == total then
                break;
            end
            i = i + 1
            x = x + margin + size
        end
        y = y + margin + size
    end
end

function screen.game.exit()
    root:removeChild(playerS)
    root:removeChild(player1)
    root:removeChild(player2)

    for i = 1, 26 do
        root:removeChild(cards[i][1])
        root:removeChild(cards[i][2])
        cards[i].used = nil
    end
end
