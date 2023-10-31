-- Modified version of AIO Divination by JCurtis
-- Original Author: JCurtis
-- Modified by Goblins to remove long sleeps, remove gui, add inventory check, add timeout.

local API = require("api")
local UTILS = require("utils")

local player = API.GetLocalPlayerName()
local npcs = {
    18150,
    18151,
    18153,
    18155,
    18157,
    18159,
    18161
}
local timeout = os.time() + 300

while API.Read_LoopyLoop() do
    if not API.InventoryInterfaceCheckvarbit() then
        print("Opening inventory")
        API.DoAction_Interface(0xc2,0xffffffff,1,1431,0,9,5392)
    end

    if API.InvFull_() then
        API.DoAction_Object1(0xc8,0,{ 93489 },50)
        API.DoAction_Object1(0xc8,0,{ 87306 },50)
        timeout = os.time() + 300
    end

    if not API.IsPlayerAnimating_(player, 100) and (not API.InvFull_()) then
        print("Harvest")
        API.DoAction_NPC(0xc8, 3120, npcs, 50)
    end

    if os.time() > timeout then
        print("Timeout")
        API.Write_LoopyLoop(false)
        return
    end

    -- UTILS.idle() --Add idle here if you want to use. 
    API.DoRandomEvents()
end