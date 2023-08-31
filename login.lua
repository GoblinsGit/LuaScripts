local API = require("api")
local UTILS = require("utils")

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


local function getAccountsFrom(file_path)
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

local function getCursorState()
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
local function getUsernameInterfaceText()
    return API.ScanForInterfaceTest2Get(false,
               {{744, 0, -1, -1, 0}, {744, 26, -1, 0, 0}, {744, 39, -1, 26, 0}, {744, 52, -1, 39, 0},
                {744, 93, -1, 52, 0}, {744, 94, -1, 93, 0}, {744, 96, -1, 94, 0}, {744, 110, -1, 96, 0},
                {744, 111, -1, 110, 0}})[1].textids
end

-- Credit to Cyro and Higgins for this function
local function isInvalidDetailsInterfaceVisible()
    return (API.ScanForInterfaceTest2Get(false,
               {{744, 0, -1, -1, 0}, {744, 197, -1, 0, 0}, {744, 338, -1, 197, 0}, {744, 340, -1, 338, 0},
                {744, 342, -1, 340, 0}, {744, 345, -1, 342, 0}})[1].textids ~= "")
end

local function login(username, password)
    -- Move cursor to username field if needed
    if getCursorState() == PASSWORD_BOX then
        print("Moving cursor to username")
        API.KeyboardPress2(TAB_KEY, .6, .2)
    end

    -- Remove any characters in username field
    cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    while cursor_offset ~= CURSOR_OFFSET_BY_0_VARBIT_STR and API.GetGameState() == 1 and getCursorState() ~= NONE and
        API.Read_LoopyLoop() do
        API.KeyboardPress2(BACKSPACE_KEY, .2, .1)
        cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    end

    -- Type username then tab
    API.TypeOnkeyboard2(username)
    API.KeyboardPress2(TAB_KEY, .6, .2)

    if (getUsernameInterfaceText() == "" or getUsernameInterfaceText():lower() ~= username:lower()) then
        print("Failed to type username")
        return false
    end

    -- Remove any text in password field
    cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    while cursor_offset ~= CURSOR_OFFSET_BY_0_VARBIT_STR and API.GetGameState() == 1 and getCursorState() ~= NONE and
        API.Read_LoopyLoop() do
        API.KeyboardPress2(BACKSPACE_KEY, .2, .1)
        cursor_offset = tostring(API.VB_GetBits(CURSOR_OFFSET_VARBIT_ID))
    end

    -- Failsafe to avoid typing password in plainsight somewhere
    if getCursorState() ~= PASSWORD_BOX then
        print("Failed to login, invalid cursor state")
        return false
    end

    -- Type password then return
    API.TypeOnkeyboard2(password)
    API.KeyboardPress2(RETURN_KEY, .2, .1)
    return true
end

local function wait_until(x, timeout)
    start = os.time()
    while not x() and start + timeout > os.time() do
        API.RandomSleep(.6, .2, .2)
    end
    return start + timeout > os.time()
end


-- Modify FILE_PATH to be the absolute path to a colon and newline deliminated accounts file (username:password\n)
local FILE_PATH = "C:\\Users\\{USER}\\Documents\\wow_look_at_all_my_accounts.txt"

local accounts = getAccountsFrom(FILE_PATH)
local username = accounts[1][1]
local password = accounts[1][2]

while API.Read_LoopyLoop() do
    if API.GetGameState() == 1 and getCursorState() == NONE then
        if #accounts > 1 then
            print("Account login failed, trying next account")
            table.remove(accounts, 1)
            username = accounts[1][1]
            password = accounts[1][2]
        else
            API.Write_LoopyLoop(false)
            print("No more accounts to login with")
        end

        API.KeyboardPress2(ESC_KEY, .2, .1)
        wait_until((function()
                return getCursorState() ~= NONE
            end), TIMEOUT)
        goto continue
    end

    if API.GetGameState() == 1 and getCursorState() ~= NONE then
        -- Login from login screen
        if (login(username, password)) then
            -- If login success, wait for up to 15 seconds until lobby appears 
            wait_until((function()
                return API.GetGameState() == 2
            end), TIMEOUT)
        end

        goto continue
    end

    if API.GetGameState() == 2 then
        -- User is in the lobby, use space to login. Future state could add world selection.
        API.KeyboardPress2(SPACE_KEY, .6, .2)
        wait_until((function()
            return API.GetGameState() == 3
        end), TIMEOUT)
        goto continue
    end

    if API.GetGameState() == 3 then
        -- User is logged in. Why even run the script at this point?
        API.Write_LoopyLoop(false)
        goto continue
    end

    ::continue::
    API.RandomSleep2(1500, 200, 200)
end
