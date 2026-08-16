-- z_gp_settingcmd_main.lua - created by Marioiscool246 on 10/16/2024, last updated on 10/16/2024 MM/DD/YY

-- main command table
GPSettingCommands = {}

GPSettingCommand = {
    name = "",
    helpString = "",
    valueHelpString = "",
    cmdCallback = nil,
}

---@param name string
---@param helpString string
---@param cmdCallback function
function GPSettingCommand:init(name, helpString, valueHelpString, cmdCallback, serverOnly)
    if (serverOnly and not network_is_server()) then
        return
    end

    if (name == '' or name:match("[^%a_]+")) then
        error("GPSettingCommand tried to init without a valid name! (alphabetical characters and underscores only)")
        return
    end

    if (name == 'help') then
        error("GPSettingCommand tried to init with reserved name!")
        return
    end

    self.name = name
    self.helpString = helpString
    self.valueHelpString = valueHelpString
    self.cmdCallback = cmdCallback

    table.insert(GPSettingCommands, self)
end

function GPSettingCommand:print_help()
    if (self.helpString == '') then
        return
    end

    djui_chat_message_create(string.format("\\#FFFF00\\%s:\\#FFFFFF\\ %s", self.name, self.helpString));
end

function GPSettingCommand:print_value_help()
    if (self.valueHelpString == '') then
        return
    end

    djui_chat_message_create(string.format("\\#FFFF00\\%s values:\\#FFFFFF\\ %s", self.name, self.valueHelpString));
end

---@param args table
function GPSettingCommand:execute(args)
    if (self.cmdCallback == nil) then
        return
    end

    if (self.cmdCallback(args) == false) then
        self:print_value_help()
    end
end