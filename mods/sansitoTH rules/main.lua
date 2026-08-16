-- Función para mostrar reglas con colores hexadecimales
function mostrar_todo_sansito()
    -- Bienvenida en AZUL
    djui_chat_message_create("[#5555ff]¡Bienvenido Al Server Oficial De MH De SansitoTH!")
    
    local lang = get_os_language():sub(1, 2)
    
    if lang == "es" then
        djui_chat_message_create("[#ffff00]--- REGLAS DEL SERVIDOR ---")
        djui_chat_message_create("[#ff0000]1.[#ffffff] No usar hacks.")
        djui_chat_message_create("[#ff0000]2.[#ffffff] No ser irrespetuoso.")
        djui_chat_message_create("[#ff0000]3.[#ffffff] No insultar a nadie.")
        djui_chat_message_create("[#ff0000]4.[#ffffff] No pedir mods. Serán siempre los mismos.")
        djui_chat_message_create("[#ff0000]5.[#ffffff] El administrador (sansitoTH) nunca hablará.")
        djui_chat_message_create("[#ff0000]6.[#ffffff] Orden aleatorio, pero 1ra partida sansitoTH es corredor.")
    else
        djui_chat_message_create("[#ffff00]--- SERVER RULES ---")
        djui_chat_message_create("[#ff0000]1.[#ffffff] No hacking.")
        djui_chat_message_create("[#ff0000]2.[#ffffff] Do not be disrespectful.")
        djui_chat_message_create("[#ff0000]3.[#ffffff] Do not insult anyone.")
        djui_chat_message_create("[#ff0000]4.[#ffffff] Don't ask for mods. They stay the same.")
        djui_chat_message_create("[#ff0000]5.[#ffffff] The admin (sansitoTH) will never speak.")
        djui_chat_message_create("[#ff0000]6.[#ffffff] Random order, but 1st game sansitoTH is runner.")
    end
    return true
end

-- Al conectar, ejecutar con 5 segundos de espera
hook_event(HOOK_ON_PLAYER_CONNECTED, function(m)
    if m.playerIndex == 0 then
        create_unthreaded_timer(5, mostrar_todo_sansito)
    end
end)

-- Comandos manuales
hook_chat_command("server", "- Ver reglas", mostrar_todo_sansito)
hook_chat_command("reglasth", "- Ver reglas", mostrar_todo_sansito)