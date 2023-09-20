--[[
# Script Name:      taverlySummoning.lua
# Description:      Create pouches in
# Autor:            Goblins (Goblins#7738 - Discord)
# Version:          1.0
--]]

-- Shout out to dead for the format ^

local API = require("api")
UTILS = {}

-- If the script does not currently support your pouch, add the primary ingredient's id to this table.
UTILS.ids = {
    summoning_primaries = {1440, 1442, 1444, 6979, 2351, 2359, 2361, 2353, 2859, 2138, 2359, 9736, 383, 440, 6032}
}

UTILS.CHARMS = {12158, 12159, 12160, 12163}

local MAKE_ALL_INTERFACE_COMPONENTS = {{1370, 0, -1, -1, 0}, {1370, 2, -1, 0, 0}, {1370, 4, -1, 2, 0},
                                       {1370, 5, -1, 4, 0}, {1370, 13, -1, 5, 0}}
local obelisk_area = {
    x1 = 2910,
    x2 = 2940,
    y1 = 3420,
    y2 = 3456
}

local bank_area = {
    x1 = 2870,
    x2 = 2909,
    y1 = 3409,
    y2 = 3456
}

local middleTile1 = WPOINT.new(2894, 3415, 0)
local middleTile2 = WPOINT.new(2911, 3421, 0)
local obelisk_tile = WPOINT.new(2931, 3448, 0)
local bank_tile = WPOINT.new(2878, 3417, 0)

function UTILS.inArea(coords)
    return API.PInArea22(coords['x1'], coords['x2'], coords['y1'], coords['y2'])
end

function UTILS.isInterfaceVisible(interface_components)
    return API.ScanForInterfaceTest2Get(false, interface_components)[1].x ~= 0
end

function UTILS.distance(tile)
    if tile == nil then
        print("Distance called on nil tile")
        return -1
    end
    local player = API.PlayerCoord()
    local x = player.x - tile.x
    local y = player.y - tile.y
    return math.sqrt(x * x + y * y)
end

falseFunction = function()
    return not API.Read_LoopyLoop()
end
function UTILS.walkPath(path, dist, condition)
    math.randomseed(os.time())
    if condition == nil then
        condition = falseFunction
    end

    for i, tile in ipairs(path) do
        if (not prev == nil) and UTILS.distance(prev) > dist then
            return false
        end
        sign = -1
        if math.random() > .5 then
            sign = 1
        end

        rand1 = math.floor(math.random() * dist * .75) * sign
        rand2 = math.floor(math.random() * dist * .75) * sign
        local t = WPOINT.new(tile.x + rand1, tile.y + rand2, tile.z)
        prev = curr
        curr = tile
        if not API.DoAction_Tile(t) then
            return false
        else

            UTILS.waitUntil(function()
                return UTILS.distance(tile) < dist or condition()
            end, 20)
        end

        if condition() then
            return true
        end
    end
    return not curr == nil or UTILS.distance(curr) <= dist
end

function UTILS.waitUntil(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(600, 200, 200)
    end
    return start + timeout > os.time()
end

local function loadPreset()
    print("Loading preset")
    API.DoAction_Interface(0x24, 0xffffffff, 1, 517, 119, 1, 5392)
    UTILS.waitUntil(function()
        return not API.BankOpen2()
    end, 5)

end

local function getNextIdle()
    delay = math.random(150, 280)
    return os.time() + delay
end

local function makeAll()
    if UTILS.isInterfaceVisible(MAKE_ALL_INTERFACE_COMPONENTS) then
        print("Making all pouches")
        API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, 4512)
        API.RandomSleep2(3000, 200, 200)
        UTILS.waitUntil(function()
            return not API.InvItemFound2(UTILS.ids['summoning_primaries']) and not API.IsPlayerAnimating_()
        end, 3)
        return
    end
end

local function idle_timeout(last_action)
    time = os.time()
    if time > next_idle then
        print("Arrow key idle")
        next_idle = getNextIdle()
        local key = math.random(37, 41)
        API.KeyboardPress(key)
    end

    if (time - last_action) > 200 then
        API.Write_LoopyLoop(false)
    end
end

last_action = os.time()
next_idle = getNextIdle()

while API.Read_LoopyLoop() do
    idle_timeout(last_action)

    if UTILS.inArea(bank_area) then
        if not API.BankOpen2() and not API.InvItemFound2(UTILS.ids['summoning_primaries']) then
            print("Opening bank")
            if UTILS.distance(bank_tile) > 30 then
                UTILS.walkPath({middleTile2, middleTile1, bank_tile}, 1, nil)
            end
            UTILS.waitUntil(function()
                return API.DoAction_NPC(0x5, 3120, {14924}, 50)
            end, 15)
            UTILS.waitUntil(API.BankOpen2, 3)
        end

        if API.BankOpen2() then
            print("Loading preset")
            loadPreset()
        end

        if API.InvItemFound2(UTILS.ids['summoning_primaries']) and API.InvItemFound2(UTILS.CHARMS) then
            print("Walking to obelisk")
            UTILS.walkPath({middleTile1, middleTile2, obelisk_tile}, 5, nil)
        end
    end

    if UTILS.inArea(obelisk_area) then
        if API.InvItemFound2(UTILS.ids['summoning_primaries']) and
            UTILS.isInterfaceVisible(MAKE_ALL_INTERFACE_COMPONENTS) and API.GetGameState() == 3 then
            print("Making pouches")
            makeAll()
            last_action = os.time()
        end

        if API.InvItemFound2(UTILS.ids['summoning_primaries']) and API.InvItemFound2(UTILS.CHARMS) then
            print("Opening obelisk interface")
            API.DoAction_Object1(0x29, 0, {67036}, 50)
            UTILS.waitUntil(function()
                return UTILS.isInterfaceVisible(MAKE_ALL_INTERFACE_COMPONENTS)
            end, 5)
        end

        if not API.InvItemFound2(UTILS.ids['summoning_primaries']) then
            print("Walking to bank")
            UTILS.walkPath({middleTile2, middleTile1, bank_tile}, 5, nil)

        end
    end

    if API.GetGameState() == 2 or API.GetGameState() == 1 then
        API.Write_LoopyLoop(false)
    end
end
