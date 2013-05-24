-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

-- states
local IDLE, FLIP1, FLIP2, FLIP, NOMATCH, MATCH = 1, 2, 3, 4, 5, 6
local STATE = IDLE

-- game info
local PLAYER = 1
local PAIRS = 4

-- card size (in pixels)
local SIZE = 64

-- nodes
local root
local playerS, player1, player2
local pause
local cards = {} -- all pairs of cards

-- flipped cards
local card1, card2

-- temporary quaternion
local q = Quaternion.new()

local function setAllCardsEnabled(enabled)
    for i = 1, 26 do
        setButtonEnabled(cards[i][1], enabled)
        setButtonEnabled(cards[i][2], enabled)
    end
end

local function animateCardFlip(card, flip, addEndListener)
    local Y = flip and 1 or 0
    local x, y, z, w
    card:getRotation(q)
    x, y, z, w = q:x(), q:y(), q:z(), q:w()
    local animation = card:createAnimation('rotate', Transform.ANIMATE_ROTATE(), 2, { 0, 400 }, { x,y,z,w, 0,Y,0,1-Y }, Curve.QUADRATIC_IN_OUT)
    if addEndListener then
       animation:getClip():addEndListener('animateCardFlipDone')
    end
    animation:play()
end

local function animateCardNoMatch(card, addEndListener)
    local sx, sy = card:getScaleX(), card:getScaleY()
    local animation = card:createAnimation('scale', Transform.ANIMATE_SCALE(), 3, { 0, 150, 300 }, { sx,sy,1, 0.8,0.8,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT)
    animation:getClip():setRepeatCount(3)
    if addEndListener then
        animation:getClip():addEndListener('animateCardNoMatchDone')
    end
    animation:play()
end

local function animateCardMatch(card, addEndListener)
    local sx, sy = card:getScaleX(), card:getScaleY()
    local animation = card:createAnimation('scale', Transform.ANIMATE_SCALE(), 3, { 0, 150, 300 }, { sx,sy,1, 1.2,1.2,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT)
    animation:getClip():setRepeatCount(3)
    if addEndListener then
        animation:getClip():addEndListener('animateCardMatchDone')
    end
    animation:play()
end

local function animateCardToPlayer(card)
    local px, py = PLAYER == 1 and -SIZE or GW+SIZE, -SIZE
    local x, y = card:getTranslationX(), card:getTranslationY()
    local animation = card:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 600 }, { x,y,0, px,py,0 }, Curve.QUADRATIC_IN_OUT)
    animation:play()
end

local function animatePlayerSwitch(player, active)
    local px, py = active and 1 or 0.75
    local sx, sy = player:getScaleX(), player:getScaleY()
    local animation = player:createAnimation('scale', Transform.ANIMATE_SCALE(), 2, { 0, 400 }, { sx,sy,1, px,px,1 }, Curve.QUADRATIC_IN_OUT)
    animation:play()
end

local function switchPlayer()
    if game.players == 2 then
        PLAYER = 1 + (1 - (PLAYER - 1))
        animatePlayerSwitch(player1, PLAYER == 1)
        animatePlayerSwitch(player2, PLAYER == 2)
    end
end

function animateCardFlipDone()
    if STATE == FLIP1 then
        setAllCardsEnabled(true)
        setButtonEnabled(card1, false)
    elseif STATE == FLIP2 then
        STATE = card1:getTag('letter') == card2:getTag('letter') and MATCH or NOMATCH
        if STATE == MATCH then
            animateCardMatch(card1)
            animateCardMatch(card2, true)
        elseif STATE == NOMATCH then
            animateCardNoMatch(card1)
            animateCardNoMatch(card2, true)
        end
    elseif STATE == IDLE then
        switchPlayer()
        setAllCardsEnabled(true)
    end
end

function animateCardNoMatchDone()
    setButtonEnabled(card1, true)
    setButtonEnabled(card2, true)
end

function animateCardMatchDone()
    animateCardToPlayer(card1)
    animateCardToPlayer(card2)
    PAIRS = PAIRS - 1
    if PAIRS ~= 0 then
        switchPlayer()
        setAllCardsEnabled(true)
        STATE = IDLE
    else
        -- TODO game over man
    end
end

local function cardHandler(card)
    if STATE == IDLE then
        card1 = card
        setAllCardsEnabled(false)
        animateCardFlip(card, true, true)
        STATE = FLIP1
    elseif STATE == FLIP1 then
        card2 = card
        setAllCardsEnabled(false)
        animateCardFlip(card, true, true)
        STATE = FLIP2
    elseif STATE == NOMATCH then
        setButtonEnabled(card1, false)
        setButtonEnabled(card2, false)
        animateCardFlip(card1, false)
        animateCardFlip(card2, false, true)
        STATE = IDLE
    end
end

local function newCard(letter)
    local card = newButton(BUTTON, BUTTON, nil, cardHandler)

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
    setButtonSize(card, size, size)
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

    player2 = newQuad(-BUTTON, BUTTON, 'res/misc.material#player-1')
    player2:setTranslation(GW - BUTTON/2, BUTTON/2, 0)

    for i = 1, 26 do
        local letter = string.char(string.byte('a') + i - 1)
        cards[i] = { newCard(letter), newCard(letter) }
    end

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
    SIZE = 4 * math.min(GW/uw, (GH-top)/uh)
    local margin = SIZE/4
    -- offset of tableau
    local ox, oy = (GW-uw*margin)/2, (GH-top-uh*margin)/2

    local i = 1
    local y = top + oy + margin + SIZE/2
    for r = 1, th do
        local x = ox + margin + SIZE/2
        if r == th then
            x = x + (margin+SIZE)*te/2
        end
        for c = 1, tw do
            local card = used[i]
            setButtonEnabled(card, true)
            setCardSize(card, SIZE)
            card:setScale(1, 1, 1)
            card:setRotation(0, 0, 0, 1)
            card:setTranslation(x, y, 0)
            root:addChild(card)
            if i == total then
                break;
            end
            i = i + 1
            x = x + margin + SIZE
        end
        y = y + margin + SIZE
    end

    STATE = IDLE
    PAIRS = total/2
    if game.players == 1 then
        PLAYER = 1
    else
        PLAYER = 2
        switchPlayer()
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
