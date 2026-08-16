-- z_gp_helpcmd.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

local function cmd_gp_help()
    djui_chat_message_create("\\#FFFF00\\Grab Player Mod Help & Controls:")
    djui_chat_message_create("Use the /gp_settings command to toggle the gui to view or change settings for the grab mod")
    djui_chat_message_create("Attack with a single punch to grab")
    djui_chat_message_create("Press the jump button repeatedly to escape from a player that's grabbing you (if it's enabled)")
    djui_chat_message_create("Ground pound a player that's grabbing another player to break up the grab (if it's enabled)")
    djui_chat_message_create("Press L and X at the same time while not moving to change the grab mode while grabbing another player (if it's allowed and enabled)")

    return true
end

hook_chat_command("gp_help", "- Displays help and controls for the Grab Player mod", cmd_gp_help)