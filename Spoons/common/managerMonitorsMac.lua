local M = {}

-- Tabela para armazenar hotkeys
M.hotkeys = {}

-- ========== IDENTIFICAÇÃO DE MONITORES ==========

function M.getMonitorByIndex(index)
    local screens = hs.screen.allScreens()
    local primaryScreen = hs.screen.primaryScreen()
    local builtinScreen = nil
    local externalScreens = {}
    
    for _, screen in ipairs(screens) do
        if screen:name():find("Built%-in") or screen:name():find("Liquid") then
            builtinScreen = screen
        elseif screen ~= primaryScreen then
            table.insert(externalScreens, screen)
        end
    end
    
    local monitorMap = {
        [1] = primaryScreen,
        [2] = externalScreens[1] or primaryScreen,
        [3] = builtinScreen or externalScreens[2] or primaryScreen
    }
    
    return monitorMap[index]
end

-- ========== EXIBIR NOME DO MONITOR ATUAL ==========

function M.showCurrentMonitorName()
    local win = hs.window.focusedWindow()
    if not win then 
        hs.alert.show("❌ Nenhuma janela em foco", 3)
        return 
    end
    
    local screen = win:screen()
    if not screen then 
        hs.alert.show("❌ Monitor não detectado", 3)
        return 
    end
    
    local monitorId = screen:id()
    local monitorName = screen:name() or "Monitor Desconhecido"
    
    -- Determinar qual índice é este monitor
    local monitorIndex = "?"
    for i = 1, 3 do
        local mon = M.getMonitorByIndex(i)
        if mon and mon:id() == monitorId then
            monitorIndex = i
            break
        end
    end
    
    hs.alert.show(string.format("🖥 Monitor %s: %s", monitorIndex, monitorName), 2)
    print(string.format("Monitor atual: [%s] %s (ID: %s)", monitorIndex, monitorName, monitorId))
end

-- ========== CONTROLE DE HOTKEYS ==========

function M.startMonitorWatcher()
    -- Limpar hotkeys antigos
    for _, hk in ipairs(M.hotkeys) do
        hk:delete()
    end
    M.hotkeys = {}
    
    -- Alt+K: Mostrar nome do monitor atual
    table.insert(M.hotkeys, hs.hotkey.bind({"alt"}, "k", function()
        M.showCurrentMonitorName()
    end))
    
    print("Manager Monitors Mac: Hotkey Alt+K configurado")
end

function M.stopMonitorWatcher()
    -- Remover todos os hotkeys
    for _, hk in ipairs(M.hotkeys) do
        hk:delete()
    end
    M.hotkeys = {}
    print("Manager Monitors Mac: Hotkey removido")
end

return M
