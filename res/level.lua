-- Memory game
-- Copyright 2013 Marc Lepage
-- Licensed under the Apache License, Version 2.0
-- http://www.apache.org/licenses/LICENSE-2.0

screen.level = {}

local root
local player = {}
local levels = {}

function screen.level.load()
    screen.level.color = Vector4.one()

    root = Node.create()

    local lsize = GS / 4
    local lspace = GS / 5 * 3/2

    if ASPECT <= 1 then
        lsize = lsize * 13/16
        lspace = lspace * 13/16
    end

    local back = newButton(BUTTON, BUTTON,
        'res/button.material#back',
        function(button)
            gotoScreen('title')
        end)
    back:setTranslation(BUTTON/2, GH - BUTTON/2, 0)
    root:addChild(back)

    local l = 0
    for r = -1, 1 do
        for c = -1, 1 do
            l = l + 1
            do
                local level = l
                local button = newButton(lsize, lsize,
                    nil,
                    function(button)
                        game.level = level
                        gotoScreen('game')
                    end)
                button:setTranslation(GW/2 + c*lspace, GH/2 + r*lspace, 0)
                root:addChild(button)
                levels[l] = button
            end
        end
    end

    player[0] = newQuad(BUTTON, BUTTON)
    player[0]:setTranslation(BUTTON/2, BUTTON/2, 0)

    player[1] = newQuad(BUTTON, BUTTON)
    player[1]:setTranslation(BUTTON/2, BUTTON/2, 0)

    player[2] = newQuad(BUTTON, BUTTON)
    player[2]:setTranslation(GW - BUTTON/2, BUTTON/2, 0)
    player[2]:setScale(-1, 1, 1)

    while levels do
        screen.level.loadinc()
    end

    screen.level.root = root
end

function screen.level.loadinc()
    if levels then
        local l = #levels
        levels[l]:getModel():setMaterial('res/button.material#level-' .. l)
        levels[l] = nil
        if #levels == 0 then
            levels = nil
        end
    end
    return levels == nil
end

function screen.level.enter()
    if game.players == 1 then
        screen.level.blink(0, false)
        root:addChild(player[0])
    else
        screen.level.blink(1, false)
        screen.level.blink(2, false)
        root:addChild(player[1])
        root:addChild(player[2])
    end
end

function screen.level.exit()
    root:removeChild(player[0])
    root:removeChild(player[1])
    root:removeChild(player[2])
end

function screen.level.blink(id, b)
    local key = id .. tostring(b)
    if materials[key] then
        player[id]:getModel():setMaterial(materials[key])
    else
        local name = 'res/misc.material#player-' .. (id == 2 and 1 or id) .. (b and '-blink' or '')
        player[id]:getModel():setMaterial(name)
        materials[key] = player[id]:getModel():getMaterial()
        materials[key]:addRef()
    end
end
