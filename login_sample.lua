local LOGIN = require("login")
local FILE_PATH = "C:\\accs.txt"

-- File format == "username:password:script\n"
local accounts = LOGIN.getAccountsFrom(FILE_PATH)
local username = accounts[1][1]
local password = accounts[1][2]
local script = accounts[1][3]

LOGIN.login(username, password, script)
