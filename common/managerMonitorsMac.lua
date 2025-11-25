local M = {}

-- ========== UTILITÁRIOS DE JANELA E FOCO ==========

-- Retorna informações completas sobre a janela/monitor em foco
function M.getFocusedWindowInfo()
    local win = hs.window.focusedWindow()
    if not win then
        return nil
    end
    
    local screen = win:screen()
    if not screen then
        return nil
    end
    
    return {
        window = win,
        app = win:application(),
        screen = screen,
        screenId = screen:id(),
        screenName = screen:name() or "Monitor Desconhecido"
    }
end

-- Retorna apenas janelas visíveis em um monitor específico
-- Filtra por mainWindow quando possível para pegar a janela principal de cada app
function M.getVisibleWindowsOnScreen(screenId)
    local visibleWindows = {}
    local seenApps = {}
    
    -- Primeiro, tentar pegar as janelas principais (mainWindow)
    local allWindows = hs.window.orderedWindows()  -- Ordenadas por Z-order (visibilidade)
    
    for _, win in ipairs(allWindows) do
        if win:isStandard() and win:isVisible() then
            local winScreen = win:screen()
            local app = win:application()
            
            if winScreen and winScreen:id() == screenId and app then
                local appName = app:name()
                
                -- Só adicionar se ainda não tivermos esse app
                if not seenApps[appName] then
                    seenApps[appName] = true
                    table.insert(visibleWindows, {
                        window = win,
                        app = app,
                        name = appName
                    })
                end
            end
        end
    end
    
    return visibleWindows
end

-- ========== BUSCA DE MONITORES POR NOME ==========

-- Busca monitor por nome exato
function M.getMonitorByName(monitorName)
    local screens = hs.screen.allScreens()
    
    for _, screen in ipairs(screens) do
        local screenName = screen:name()
        if screenName == monitorName then
            return screen
        end
    end
    
    return nil
end

-- Retorna lista de todos os monitores conectados com informações
function M.getAllConnectedMonitors()
    local screens = hs.screen.allScreens()
    local monitors = {}
    
    for _, screen in ipairs(screens) do
        table.insert(monitors, {
            name = screen:name(),
            id = screen:id(),
            frame = screen:frame(),
            isPrimary = (screen == hs.screen.primaryScreen())
        })
    end
    
    return monitors
end

-- Imprime lista de monitores conectados (útil para debug)
function M.printConnectedMonitors()
    local monitors = M.getAllConnectedMonitors()
    
    print("=== Monitores Conectados ===")
    for i, mon in ipairs(monitors) do
        local primary = mon.isPrimary and " (PRIMARY)" or ""
        print(string.format("%d. %s%s", i, mon.name, primary))
        print(string.format("   ID: %s", mon.id))
        print(string.format("   Resolução: %dx%d", mon.frame.w, mon.frame.h))
    end
    print("============================")
end

return M
