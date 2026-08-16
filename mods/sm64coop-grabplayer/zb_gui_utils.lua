-- gui_utils.lua - created by Marioiscool246 on 2/7/2024, last updated on 3/22/2024 MM/DD/YY

local sFontSizes = {
    [FONT_NORMAL] = 32.0,
    [FONT_MENU] = 64.0,
    [FONT_HUD] = 16.0,
    [FONT_TINY] = 8.0
}

function get_font_size(font)
    local size = sFontSizes[font]

    if (size == nil) then
        size = 32.0
    end

    return size
end

function gui_common_new(gui)
    local newObj = {}

    for i, v in pairs(gui) do
        newObj[i] = v
    end

    return newObj
end