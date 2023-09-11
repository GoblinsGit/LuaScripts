local API = require("api")

-- To use: 
--  * Update UNCHECKED_STR and CHECKED_STR to match the checked and unchecked animal name. 
--  * Put unchecked animal in the first action bar slot
--  * Save preset 1 as an inventory full of unchecked animals
--  * Start near POF bank

-- Requirements
--  * 20 construction, 19 farming, POF unlocked
--  * POF Bank chest upgrade unlocked
--  * Lots of unchecked animals :)

local UNCHECKED_STR = "Kandarin cow (unchecked)"
local CHECKED_STR = "Kandarin cow"

PICKLE_CHAT_INTERFACE = { { 1184,2,-1,-1,0 }, { 1184,10,-1,2,0 } }
PICKLE_SELL_INTERFACE = { { 1188,5,-1,-1,0 }, { 1188,4,-1,5,0 } }


local function loadPreset()
    API.DoAction_Interface(0x24,0xffffffff,1,517,119,1,5376)
    waitUntil(function() return not API.BankOpen2()end, 5)
end


local function check(count)
    for i=1,count do
        -- Doaction on action bar interface, you could also use the DoAction_Ability function
        API.DoAction_Interface(0x2e,0xbdbf,1,1430,64,-1,5376)
        API.RandomSleep2(50, 45, 45)
    end
end


local function isInterfaceVisible(interface_components)
    return API.ScanForInterfaceTest2Get(false, interface_components)[1].x ~= 0
end


function waitUntil(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep2(600, 200, 200)
    end
    return start + timeout > os.time()
end

last_action = os.time()

while API.Read_LoopyLoop() do
    time = os.time()


    if time - last_action > 45 then
        API.Write_LoopyLoop(false)
    end

    if not API.BankOpen2() and not API.InvFull_() then
        print("Opening bank")
        API.DoAction_Object1(0x2e,80,{ 112369 },50)
        waitUntil(function()return API.BankOpen2()end, 3)

        goto continue
    end

    if API.BankOpen2() then
        loadPreset()
        goto continue
    end

    if API.InvItemcount_String(UNCHECKED_STR) > 0 then
        print("Checking animals")
        check(API.InvItemcount_String(UNCHECKED_STR))
        goto continue
    end

    if API.InvItemcount_String(CHECKED_STR) > 0 and not isInterfaceVisible(PICKLE_CHAT_INTERFACE) then
        API.DoAction_NPC(0x29,3328,{ 8947 },50)
        waitUntil(function()return isInterfaceVisible(PICKLE_CHAT_INTERFACE)end, 3)
        goto continue
    end

    if isInterfaceVisible(PICKLE_CHAT_INTERFACE) or isInterfaceVisible(PICKLE_SELL_INTERFACE) then
        API.KeyboardPress(' ')
        waitUntil(function()return isInterfaceVisible(PICKLE_SELL_INTERFACE)end, 3)
        API.KeyboardPress('1')
        waitUntil(function()return not API.InvFull_()end, 3)
        if not isInterfaceVisible(PICKLE_CHAT_INTERFACE) and not isInterfaceVisible(PICKLE_SELL_INTERFACE) then
            print("Animals sold, updating timeout")
            last_action = os.time()
        end
        goto continue
    end

    ::continue::
    API.RandomSleep2(600, 200, 200)
end