-- Memory game
-- Copyright (C) 2013 Marc Lepage

screen.game = {}

-- states
local IDLE, FLIP1, FLIP2, NOMATCH, MATCH = 1, 2, 3, 4, 5, 6
local STATE = IDLE

local PAUSED = false

-- game info
local PAIRS = 4

-- card size (in pixels)
local SIZE = 64
local BGSIZE = 64

-- nodes
local root
local player = {}
local pause, reset, menu
local dim
local cards = {} -- all pairs of cards

-- flipped cards
local card1, card2

-- quaternions
local q = Quaternion.new()
local q1 = Quaternion.new()
local q2 = Quaternion.new()

local function setCardsEnabled(enabled)
    for i = 1, 26 do
        setButtonEnabled(cards[i][1], enabled)
        setButtonEnabled(cards[i][2], enabled)
    end
end

local function animateCardFlip(card, flip, addEndListener)
    local Y = flip and 1 or 0
    card:getRotation(q)
    local x, y, z, w = q:x(), q:y(), q:z(), q:w()
    local animation = card:createAnimation('rotate', Transform.ANIMATE_ROTATE(), 2, { 0, 400 }, { x,y,z,w, 0,Y,0,1-Y }, Curve.QUADRATIC_IN_OUT)
    if addEndListener then
       animation:getClip():addEndListener('animateCardFlipDone')
    end
    local sx, sy = card:getScaleX(), card:getScaleY()
    if sx ~= 1.2 then
        card:createAnimation('scale', Transform.ANIMATE_SCALE(), 3, { 0, 200, 400 }, { sx,sy,1, 1.2,1.2,1, 1,1,1 }, Curve.QUADRATIC_IN_OUT):play()
    end
    animation:play()
end

local function animateCardNoMatch(card, addEndListener)
    card:getRotation(q)
    local x, y, z, w = q:x(), q:y(), q:z(), q:w()
    local animation = card:createAnimation('rotate', Transform.ANIMATE_ROTATE(), 6, { 0, 75, 225, 375, 525, 600 }, { x,y,z,w, q1:x(),q1:y(),q1:z(),q1:w(), q2:x(),q2:y(),q2:z(),q2:w(), q1:x(),q1:y(),q1:z(),q1:w(), q2:x(),q2:y(),q2:z(),q2:w(), 0,1,0,0 }, Curve.QUADRATIC_IN_OUT)
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

local function animateCardToPlayer(card, addEndListener)
    root:removeChild(card)
    root:addChild(card)
    local px, py = game.player == 1 and -SIZE or GW+SIZE, -SIZE
    local x, y = card:getTranslationX(), card:getTranslationY()
    local animation = card:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 600 }, { x,y,0, px,py,0 }, Curve.QUADRATIC_IN_OUT)
    if addEndListener then
        animation:getClip():addEndListener('animateCardToPlayerDone')
    end
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
        game.player = 1 + (1 - (game.player - 1))
        animatePlayerSwitch(player[1], game.player == 1)
        animatePlayerSwitch(player[2], game.player == 2)
    end
end

function animateCardFlipDone()
    if STATE == FLIP1 then
        if not PAUSED then
            setCardsEnabled(true)
            setButtonEnabled(card1, false)
        end
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
        if not PAUSED then
            setCardsEnabled(true)
        end
    end
end

function animateCardNoMatchDone()
    if not PAUSED then
        setButtonEnabled(card1, true)
        setButtonEnabled(card2, true)
    end
end

function animateCardMatchDone()
    animateCardToPlayer(card1)
    animateCardToPlayer(card2, true)
    PAIRS = PAIRS - 1
end

function animateCardToPlayerDone()
    root:removeChild(card1)
    root:removeChild(card2)
    if PAIRS ~= 0 then
        switchPlayer()
        STATE = IDLE
        if not PAUSED then
            setCardsEnabled(true)
        end
    else
        gotoScreen('complete')
    end
end

function animatePauseDone()
    setButtonEnabled(pause, true)
    setButtonEnabled(reset, true)
    setButtonEnabled(menu, true)
end

function animatePlayDone()
    PAUSED = false
    root:removeChild(dim)
    root:removeChild(reset)
    root:removeChild(menu)
    setButtonEnabled(pause, true)
    if STATE == IDLE then
        setCardsEnabled(true)
    elseif STATE == FLIP1 then
        setCardsEnabled(true)
        setButtonEnabled(card1, false)
    elseif STATE == NOMATCH then
        setCardsEnabled(false)
        setButtonEnabled(card1, true)
        setButtonEnabled(card2, true)
    end
end

local function cardHandler(card)
    if STATE == IDLE then
        card1 = card
        setCardsEnabled(false)
        animateCardFlip(card, true, true)
        STATE = FLIP1
    elseif STATE == FLIP1 then
        card2 = card
        setCardsEnabled(false)
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

    local back = newQuad(256, 256, 'res/card.material#back')
    card:addChild(back)

    local front = newQuad(256, 256, 'res/card.material#front')
    front:rotate(0, 1, 0, 0)
    card:addChild(front)

    local decal = newQuad(192, 192, 'res/card.material#decal-' .. letter)
    decal:rotate(0, 1, 0, 0)
    card:addChild(decal)

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

local function setPaused(paused)
    local px, py = pause:getTranslationX(), pause:getTranslationY()
    if paused then
        PAUSED = true
        setCardsEnabled(false)
        setButtonEnabled(pause, false)
        setButtonEnabled(reset, false)
        setButtonEnabled(menu, false)
        pause:getModel():setMaterial('res/button.material#play')
        root:removeChild(pause)
        root:addChild(dim)
        root:addChild(reset)
        root:addChild(menu)
        root:addChild(pause)
        reset:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 3, { 0, 200, 400 }, { px,py,0, px,py,0, px-BUTTON,py,0 }, Curve.QUADRATIC_IN_OUT):play()
        local animation = menu:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 400 }, { px,py,0, px-2*BUTTON,py,0 }, Curve.QUADRATIC_IN_OUT)
        animation:getClip():addEndListener('animatePauseDone')
        animation:play()
    else
        setCardsEnabled(false)
        setButtonEnabled(pause, false)
        setButtonEnabled(reset, false)
        setButtonEnabled(menu, false)
        pause:getModel():setMaterial('res/button.material#pause')
        local x, y = reset:getTranslationX(), reset:getTranslationY()
        reset:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 200 }, { x,y,0, px,py,0 }, Curve.QUADRATIC_IN_OUT):play()
        x, y = menu:getTranslationX(), menu:getTranslationY()
        local animation = menu:createAnimation('translate', Transform.ANIMATE_TRANSLATE(), 2, { 0, 400 }, { x,y,0, px,py,0 }, Curve.QUADRATIC_IN_OUT)
        animation:getClip():addEndListener('animatePlayDone')
        animation:play()
    end
end

function screen.game.load()
    screen.game.color = Vector4.one()

    root = Node.create()

    dim = newQuad(GW, GH, 'res/misc.material#dim')
    dim:setTranslation(GW/2, GH/2, 0)

    menu = newButton(BUTTON, BUTTON,
        'res/button.material#menu',
        function(button)
            gotoScreen('level')
        end)

    reset = newButton(BUTTON, BUTTON,
        'res/button.material#reset',
        function(button)
            gotoScreen('game')
        end)

    pause = newButton(BUTTON, BUTTON,
        'res/button.material#pause',
        function(button)
            setPaused(not PAUSED)
        end)
    root:addChild(pause)

    player[0] = newQuad(BUTTON, BUTTON)
    player[0]:setTranslation(BUTTON/2, BUTTON/2, 0)

    player[1] = newQuad(BUTTON, BUTTON)
    player[1]:setTranslation(BUTTON/2, BUTTON/2, 0)

    player[2] = newQuad(-BUTTON, BUTTON)
    player[2]:setTranslation(GW - BUTTON/2, BUTTON/2, 0)

    for i = 1, 26 do
        local letter = string.char(string.byte('a') + i - 1)
        cards[i] = { newCard(letter), newCard(letter) }
    end

    -- set quaternions
    local card = cards[1][1]
    card:setRotation(0, 1, 0, 0)
    card:rotate(Vector3.unitZ(), math.rad(15))
    card:getRotation(q1)
    card:setRotation(0, 1, 0, 0)
    card:rotate(Vector3.unitZ(), math.rad(-15))
    card:getRotation(q2)
    card:setRotation(0, 0, 0, 1)

    screen.game.root = root
end

function screen.game.enter()
    local px, py
    if game.players == 1 then
        screen.game.blink(0, false)
        root:addChild(player[0])
        player[0]:setScale(1, 1, 1)
        pause:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    else
        screen.game.blink(1, false)
        screen.game.blink(2, false)
        root:addChild(player[1])
        root:addChild(player[2])
        player[1]:setScale(1, 1, 1)
        player[2]:setScale(1, 1, 1)
        pause:setTranslation(GW/2, BUTTON/2, 0)
    end

    PAUSED = false
    root:removeChild(reset)
    root:removeChild(menu)

    local total = game.sizes[game.level][1] * game.sizes[game.level][2]
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
        game.player = 1
    else
        game.player = 2
        switchPlayer()
    end
end

function screen.game.exit()
    pause:getModel():setMaterial('res/button.material#pause')
    root:removeChild(dim)
    root:removeChild(player[0])
    root:removeChild(player[1])
    root:removeChild(player[2])

    for i = 1, 26 do
        root:removeChild(cards[i][1])
        root:removeChild(cards[i][2])
        cards[i].used = nil
    end
end

function screen.game.blink(id, b)
    local mid = id == 2 and 1 or id
    local mb = b and '-blink' or ''
    local material = 'res/misc.material#player-' .. mid .. mb
    player[id]:getModel():setMaterial(material)
end
