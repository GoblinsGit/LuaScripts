local API = require("api")
local LOGIN = {}

local TIMEOUT = 15

local CURSOR_LOCATION_VARBIT_ID = 174
local CURSOR_OFFSET_VARBIT_ID = 1099

local USERNAME_BOX_VARBIT_STR = "00000000000000000000000001100100"
local PASSWORD_BOX_VARBIT_STR = "00000000000000000000000001100101"
local INVALID_BOX_VARBIT_STR = "00000000000000000000000001100110"
local CURSOR_OFFSET_BY_0_VARBIT_STR = "00000000000000000000000000000000"

local BACKSPACE_KEY = 8
local TAB_KEY = 9
local RETURN_KEY = 13
local ESC_KEY = 27
local SPACE_KEY = 32

local USERNAME_BOX = 0
local PASSWORD_BOX = 1
local NONE = 2


function LOGIN.getAccountsFrom(file_path)
    local accounts = {}
    for line in io.lines(file_path) do
        account = {}
        for w in line:gmatch("([^:]+):?") do
            table.insert(account, w)
        end
        accounts[#accounts + 1] = account
    end
    return accounts
end

function LOGIN.getCursorState()
    cursor_box = tostring(API.VB_GetBits(CURSOR_LOCATION_VARBIT_ID))
    if cursor_box == USERNAME_BOX_VARBIT_STR then
        return USERNAME_BOX
    end
    if cursor_box == PASSWORD_BOX_VARBIT_STR then
        return PASSWORD_BOX
    end

    return NONE
end


-- Credit to Cyro and Higgins for inspiration
function LOGIN.getUsernameInterfaceText()
    return API.ScanForInterfaceTest2Get(false,
               {{744, 0, -1, -1, 0}, {744, 26, -1, 0, 0}, {744, 39, -1, 26, 0}, {744, 52, -1, 39, 0},
                {744, 93, -1, 52, 0}, {744, 94, -1, 93, 0}, {744, 96, -1, 94, 0}, {744, 110, -1, 96, 0},
                {744, 111, -1, 110, 0}})[1].textids
end

function LOGIN.isGamesSessionExpired()
    return API.ScanForInterfaceTest2Get(false, { { 744,0,-1,-1,0 }, { 744,197,-1,0,0 }, { 744,338,-1,197,0 }, { 744,340,-1,338,0 }, { 744,342,-1,340,0 }, { 744,345,-1,342,0 } })[1].textids:match("^Your game session")
end

function LOGIN.isInvalidDetailsInterfaceVisible()
    return API.ScanForInterfaceTest2Get(false, { { 744,0,-1,-1,0 }, { 744,197,-1,0,0 }, { 744,338,-1,197,0 }, { 744,340,-1,338,0 }, { 744,342,-1,340,0 }, { 744,345,-1,342,0 } })[1].textids:match("^Invalid email or password")
end 

function LOGIN.isAlreadyLoggedInInterfaceVisible()
    return API.ScanForInterfaceTest2Get(false, { { 744,0,-1,-1,0 }, { 744,197,-1,0,0 }, { 744,338,-1,197,0 }, { 744,340,-1,338,0 }, { 744,342,-1,340,0 }, { 744,345,-1,342,0 } })[1].textids:match("^Your account has not")
end

function LOGIN.keyboardType(str)
    -- Does not work well when multiple clients are using the keyboard at the same time.
    API.TypeOnkeyboard(str)
end

function LOGIN.typeCreds(username, password)
    -- Move cursor to username field if needed
    if LOGIN.getCursorState() == PASSWORD_BOX then
        print("Moving cursor to username")
        API.KeyboardPress2(TAB_KEY, .6, .2)
    end

    -- Remove any characters in username field
    cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    while cursor_offset ~= CURSOR_OFFSET_BY_0_VARBIT_STR
        and API.GetGameState() == 1
        and LOGIN.getCursorState() ~= NONE
        and API.Read_LoopyLoop() do

        API.KeyboardPress2(BACKSPACE_KEY, .2, .1)
        cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    end

    -- Type username then tab
    LOGIN.keyboardType(username)
    -- API.TypeOnkeyboard(username)
    API.RandomSleep2(1500, 100, 100)

    API.KeyboardPress2(TAB_KEY, 600, 200)

    if (LOGIN.getUsernameInterfaceText() == "" 
        or LOGIN.getUsernameInterfaceText():lower() ~= username:lower()) then

        print("Failed to type username")
        return false
    end

    -- Remove any text in password field
    cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    while cursor_offset ~= CURSOR_OFFSET_BY_0_VARBIT_STR 
        and API.GetGameState() == 1 
        and LOGIN.getCursorState() ~= NONE 
        and API.Read_LoopyLoop() do

        API.KeyboardPress2(BACKSPACE_KEY, 100, 50)
        cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    end

    -- Failsafe to avoid typing password in plainsight somewhere
    if LOGIN.getCursorState() ~= PASSWORD_BOX then
        print("Failed to login, invalid cursor state")
        return false
    end

    -- Type password then return
    LOGIN.keyboardType(password)
    API.RandomSleep2(500, 100, 100)

    API.KeyboardPress2(RETURN_KEY, 100, 50)
    return true
end

function LOGIN.wait_until(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep(.6, .2, .2)
    end
    return start + timeout > os.time()
end

function LOGIN.login(username, password, script)
    if API.GetGameState() == 3 then
        print("Already logged in")
        return false
    end

    if API.GetGameState() == 2 then
        print("Logged into lobby... pressing space")
        API.KeyboardPress2(SPACE_KEY, .6, .2)
        return LOGIN.wait_until((function()
            return API.GetGameState() == 3
        end), TIMEOUT)
    end

    local loggedIn = false
    API.Write_LoopyLoop(true)

    while(API.Read_LoopyLoop() and not loggedIn) do
        if LOGIN.isAlreadyLoggedInInterfaceVisible()
            and LOGIN.getCursorState() == NONE
            and API.GetGameState() == 1 then

            -- Account already logged in
            if LOGIN.isAlreadyLoggedInInterfaceVisible() then
                print("account already logged in")
                API.KeyboardPress2(ESC_KEY, .2, .1)
                return false
            end
            -- NOTE: If you want to add logic to try another account, here is a good spot to update user/pass/script then continue looping.
        end
    
        if LOGIN.isGamesSessionExpired() then
            API.Write_LoopyLoop(false)
            print("Game session expired")
            return false
        end
    
        if LOGIN.isInvalidDetailsInterfaceVisible() then
            print("Failed to type credentials, retrying")
            API.KeyboardPress2(ESC_KEY, .2, .1)
            LOGIN.wait_until((function()
                return LOGIN.getCursorState() ~= NONE
            end), TIMEOUT)
        end

        if API.GetGameState() == 1 and LOGIN.getCursorState() == NONE then
            -- This should catch the settings page if it is open
            API.KeyboardPress2(ESC_KEY, .2, .1)
            LOGIN.wait_until((function()
                    return LOGIN.getCursorState() ~= NONE
                end), TIMEOUT)
        end

        if API.GetGameState() == 1 and LOGIN.getCursorState() ~= NONE then
            -- Login from login screen
            if (LOGIN.typeCreds(username, password)) then
                -- If login success, wait for up to 15 seconds until lobby appears
                LOGIN.wait_until((function()
                    return API.GetGameState() == 2
                        or LOGIN.isAlreadyLoggedInInterfaceVisible()
                        or LOGIN.isInvalidDetailsInterfaceVisible()
                        or LOGIN.isGamesSessionExpired()
                end), TIMEOUT)
            end
        end

        if API.GetGameState() == 2 then
            -- User is in the lobby, use space to login. Adding world selection from here isn't too hard.
            -- TODO: Add logic to catch f2p/p2p
            API.KeyboardPress2(SPACE_KEY, .6, .2)
            LOGIN.wait_until((function()
                return API.GetGameState() == 3
            end), TIMEOUT)
        end

        if API.GetGameState() == 3 then
            API.Write_LoopyLoop(false)
            loggedIn = true
        end
    end

    API.RandomSleep2(3000, 1000, 2000)
    if loggedIn == true then
        print("Starting script" .. script)
        API.Write_LoopyLoop(true)

        -- If you are calling this from another script, you may eventually run into a stack overflow because of this potential recursive nature of this call.
        -- Ideally you would comment this line out and call require(script) somewhere else. Ex. on client startup. 
        require(script)
    end
end

return LOGIN


