local API = require("api")


local draynor = {
    x1 = 3090,
    x2 = 3110,
    y1 = 3290, 
    y2 = 3320
}

local interfaces = {
    playerDialog = { { 1191,0,-1,-1,0 } },
    npcDialog = { { 1184,2,-1,-1,0 } }, 
    serverDialog = { { 1186,2,-1,-1,0 } },
    serverContinue = { { 1189,2,-1,-1,0 } }, 
    questStart = { { 1500,0,-1,-1,0 }, { 1500,329,-1,0,0 }, { 1500,399,-1,329,0 }, { 1500,407,-1,399,0 }, { 1500,408,-1,407,0 }, { 1500,408,3,408,0 } },
    selectRitual = { { 1224,0,-1,-1,0 }, { 1224,2,-1,0,0 }, { 1224,3,-1,2,0 }, { 1224,6,-1,3,0 }, { 1224,11,-1,6,0 }, { 1224,43,-1,11,0 }, { 1224,43,3,43,0 } },
    makeAll = { { 1370,0,-1,-1,0 }, { 1370,2,-1,0,0 }, { 1370,24,-1,2,0 }, { 1370,27,-1,24,0 }, { 1370,28,-1,27,0 }, { 1370,29,-1,28,0 }, { 1370,29,3,29,0 } },
    repair = { { 847,0,-1,-1,0 }, { 847,30,-1,0,0 }, { 847,30,14,30,0 } },
    wellOfSouls = { { 1222,0,-1,-1,0 }, { 1222,28,-1,0,0 }, { 1222,28,14,28,0 } },
    mostAnnoyingInterfaceInTheGame = { { 955,4,-1,-1,0 }, { 955,6,-1,4,0 }, { 955,9,-1,6,0 }, { 955,10,-1,9,0 }, { 955,13,-1,10,0 }, { 955,13,0,13,0 } }
}

local npcs = {
    ritualSites = {30501, 30502, 30503, 30504, 30505, 30514, 30515, 30513, 30512},
    trolls = {30261, 30260}
}

local items = {
    ritualCandle = 55245,
    basicGhostlyInk = 55244,
    deathGuard = 55502
}

local function isInterfaceVisible(interface_components)
    return API.ScanForInterfaceTest2Get(false, interface_components)[1].x ~= nil 
        and API.ScanForInterfaceTest2Get(false, interface_components)[1].x ~= 0
end

local function getQuestVBState()
    return API.VB_FindPSett(10982, 0).state
end

local function isChatboxOpen()
    return isInterfaceVisible(interfaces['serverContinue']) 
        or isInterfaceVisible(interfaces['playerDialog']) 
        or isInterfaceVisible(interfaces['npcDialog']) 
        or isInterfaceVisible(interfaces['serverDialog'])
end

local function filterNPCsByName(objs, name)
    local query =  API.GetAllObjArray1(objs, 100, {1})
    local filtered = {} 
    for _, obj in ipairs(query) do
        if obj ~= nil and obj.Name == name then
            filtered[#filtered+1]=obj.Id
        end
    end
    return filtered
end

local function place(sites)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, sites, 50)
    API.RandomSleep2(1200, 1200, 2400)
    if isInterfaceVisible(interfaces['makeAll']) then
        API.TypeOnkeyboard(" ")
        API.RandomSleep2(3600, 600, 2400)
    else
        API.RandomSleep2(2000, 1200, 400)
    end
end

local function repair() 
    print(#filterNPCsByName(npcs['ritualSites'], "Elemental I (depleted)"))
    API.DoAction_NPC(0xae,API.OFF_ACT_InteractNPC_route2,filterNPCsByName(npcs['ritualSites'], "Elemental I (depleted)"),50)
    print("interacted")
    API.RandomSleep2(1200, 1200, 2400)
    if isInterfaceVisible(interfaces['repair']) then
        print("repair visible")
        API.TypeOnkeyboard('y')
        API.RandomSleep2(3600, 600, 2400)
    else
        API.RandomSleep2(2300, 1200, 2400)
    end
end


while API.Read_LoopyLoop() do
    while API.Read_LoopyLoop() and isInterfaceVisible(interfaces['mostAnnoyingInterfaceInTheGame']) do
        print("Closing annoying interface")
        API.DoAction_Interface(0x24,0xffffffff,1,955,18,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(1200, 1200, 1000)
    end


    if not isChatboxOpen() then
        if API.PInArea22(draynor['x1'], draynor['x2'], draynor['y1'], draynor['y2'])  and not isChatboxOpen() then -- and not chatbox or quest
            print("Entering quest portal")
            if isInterfaceVisible(interfaces['questStart']) then
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1500, 409, -1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 600, 1200)
            elseif not isChatboxOpen() then
                API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, { 127140, 127141 }, 50)
                API.RandomSleep2(1200, 600, 0)
            end
        end
        
        if getQuestVBState() == 178 then
            print("Clearing ritual site")
            place(filterNPCsByName(npcs['ritualSites'], "Mound of dust"))
        end

        if getQuestVBState() == 562 then
            print("Selecting ritual")
            API.DoAction_Object1(0x29,0,{ 127319 },50)
            API.RandomSleep2(2400, 600, 1200)
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1224, 44, -1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 600, 300)
        end

        if (getQuestVBState() == 690 
            or getQuestVBState() == 946 
            or getQuestVBState() == 1074 
            or getQuestVBState() == 9788)
            and not API.InventoryInterfaceCheckvarbit() then
            print("Open inventory")
            API.DoAction_Interface(0xc2,0xffffffff,1,1431,0,9,API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 0, 1200)
        end
        
        if getQuestVBState() == 690 and API.InvItemcount_1(items['ritualCandle']) > 0 then
            print("Place candles")
            place(filterNPCsByName(npcs['ritualSites'], "Light source spot"))
        elseif getQuestVBState() == 690 and not isChatboxOpen() then
            API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, { 30258 },50)
            API.RandomSleep2(1200, 600, 0)
        end

        if getQuestVBState() == 946 and API.InvStackSize(items['basicGhostlyInk']) > 0 then
            print("Placing glyphs")
            place(filterNPCsByName(npcs['ritualSites'], "Glyph spot"))
        elseif getQuestVBState() == 946 and not isChatboxOpen() then
            API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, { 30258 },50)
            API.RandomSleep2(1200, 600, 0)
        end

        if getQuestVBState() == 1074 and API.InvStackSize(items['basicGhostlyInk']) > 0 then
            print("repairing glyphs")
            repair() 
        elseif getQuestVBState() == 1074 and not isChatboxOpen() then
            API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, { 30258 },50)
            API.RandomSleep2(1200, 600, 0)
        end

        if not API.IsPlayerAnimating_(API.GetLocalPlayerName(), 100) and getQuestVBState() == 1330 then
            print("Starting ritual")
            API.DoAction_Object1(0x29,0,{ 127224 },50)
            API.RandomSleep2(2400, 1200, 0)
        end

        if (getQuestVBState() == 1596 or getQuestVBState() == 3644) and not isInterfaceVisible(interfaces['wellOfSouls']) then
            print("Opening well of souls")
            API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0,{ 127273 }, 50)
            API.RandomSleep2(1200, 600, 0)
        end

        if (getQuestVBState() == 1596 or getQuestVBState() == 3644) and isInterfaceVisible(interfaces['wellOfSouls']) then
            API.DoAction_Interface(0x2e, 0xffffffff, 1, 1222, 27, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(5000, 600, 0)
        end

        if getQuestVBState() == 9788 and API.InvItemcount_1(items['deathGuard']) > 0 then
            print("Putting on death guard")
            if API.InvItemcount_1(items['deathGuard']) > 0 then
                API.DoAction_Inventory1(items['deathGuard'], 1, 2, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 0, 600)
            end
        end

        if (getQuestVBState() == 9788 or getQuestVBState() == 75324 or getQuestVBState() == 42556) and API.InvItemcount_1(items['deathGuard']) == 0 and not API.IsPlayerAnimating_(API.GetLocalPlayerName(), 100) then
            print("Attacking trolls")
            API.DoAction_NPC(0x2a, API.OFF_ACT_AttackNPC_route, npcs['trolls'], 50)
            API.RandomSleep2(3000, 0, 600)
        end
        if getQuestVBState() == 110140 then
            print("Spending talent point")
            API.DoAction_Object1(0x29,0,{ 127273 },50)
            API.RandomSleep2(2400, 600, 1200)
            if isInterfaceVisible(interfaces['wellOfSouls']) then
                API.DoAction_Interface(0x2e, 0xffffffff, 1, 1222, 27, 1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 300, 600)
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1222, 54, -1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 300, 300)
                API.DoAction_Interface(0x24, 0xffffffff, 1, 1222, 74, -1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 300, 300)
            end
        end

        if getQuestVBState() == 112188 and isInterfaceVisible(interfaces['wellOfSouls']) then
            API.DoAction_Interface(0x24, 0xffffffff, 1, 1222, 29, -1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 300, 300)
        elseif getQuestVBState() == 112188 and not isChatboxOpen() then
            API.DoAction_NPC(0x2c, API.OFF_ACT_InteractNPC_route, { 30259 }, 50)
            API.RandomSleep2(3000, 300, 300)
        end

        if getQuestVBState() == 245318 then
            API.Write_LoopyLoop(false)
            print("quest done")
            return
        end

    else 
        while API.Read_LoopyLoop() and isChatboxOpen() do
            API.TypeOnkeyboard(" ")
            API.RandomSleep2(600, 0, 1200)
        end
    end

    API.RandomSleep2(2400, 600, 0)
end