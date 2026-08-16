-- gui_render.lua - created by Marioiscool246 on 2/7/2024, last updated on 10/16/2024 MM/DD/YY

local sRenderGUI = false

function gui_toggle()
    local guiEnabled = not sRenderGUI

    if (GUIMainWindow ~= nil) then
        GUIMainWindow:on_gui_toggle(guiEnabled)
    end

    if (guiEnabled ~= false) then
        play_sound(SOUND_MENU_MESSAGE_APPEAR, gMarioStates[0].marioObj.header.gfx.cameraToObject)
    else
        play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gMarioStates[0].marioObj.header.gfx.cameraToObject)
    end

    sRenderGUI = guiEnabled

    return false
end

local function hook_on_hud_render()
    local renderGui = sRenderGUI ~= false and is_game_paused() == false

    if (renderGui == false) then
        return
    end

    gMarioStates[0].freeze = 5

    djui_hud_set_resolution(RESOLUTION_DJUI)

    if (GUIMainWindow ~= nil) then
        GUIMainWindow:render()
    end
end

hook_event(HOOK_ON_HUD_RENDER, hook_on_hud_render)
