local M = {}

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

return M
