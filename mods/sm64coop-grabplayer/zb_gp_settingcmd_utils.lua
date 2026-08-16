-- zb_gp_settingcmd_utils.lua - created by Marioiscool246 on 10/16/2024, last updated on 10/16/2024 MM/DD/YY

function gp_settingcmd_new()
    local newObj = {}

    for i, v in pairs(GPSettingCommand) do
        newObj[i] = v
    end

    return newObj
end