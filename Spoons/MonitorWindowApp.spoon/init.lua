--- === MonitorWindowApp ===
---
--- Biblioteca de movimentação de janelas entre monitores
--- NÃO conhece atalhos de teclado - apenas expõe ações

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MonitorWindowApp"
obj.version = "2.0"
obj.author = "Stepheson Alves"
obj.license = "MIT"

-- Estado interno
local monitorConfigs = {}
local managerMonitorsMac = require("common.managerMonitorsMac")
local storageManager = require("common.storageManager")

-- Garbage collection timer
local gcTimer = nil

-- ========== CONFIGURAÇÃO ==========

function obj:setConfig(config)
    monitorConfigs = config.monitors or {}
    print(string.format("MonitorWindowApp: %d monitor(es) configurado(s)", #monitorConfigs))
    return self
end

-- ========== HELPERS INTERNOS ==========

local function getMonitorConfigByOrder(order)
    for _, config in ipairs(monitorConfigs) do
        if config.order == order then
            return config
        end
    end
    return nil
end

local function calculateTargetFrame(screenFrame, margins)
    margins = margins or {}
    
    local left = margins.left or 0
    local top = margins.top or 0
    local bottom = margins.bottom or 0
    local right = margins.right or 0
    
    return {
        x = screenFrame.x + math.floor(screenFrame.w * left),
        y = screenFrame.y + math.floor(screenFrame.h * top),
        w = screenFrame.w - math.floor(screenFrame.w * (left + right)),
        h = screenFrame.h - math.floor(screenFrame.h * (top + bottom))
    }
end

local function moveWindowToMonitorInternal(monitorConfig, targetWindow)
    -- Se targetWindow não for passado, usar janela em foco
    local win = targetWindow or hs.window.focusedWindow()
    if not win then 
        hs.notify.new({title="Hammerspoon", informativeText="Nenhuma janela em foco"}):send()
        return 
    end
    
    -- Buscar monitor por nome
    local targetScreen = managerMonitorsMac.getMonitorByName(monitorConfig.name)
    
    if not targetScreen then
        print(string.format("Monitor '%s' não encontrado (desconectado)", monitorConfig.name))
        return
    end
    
    local screenFrame = targetScreen:frame()
    local currentFrame = win:frame()
    
    -- PASSO 1: Mover para centro do monitor
    local tempFrame = {
        x = screenFrame.x + (screenFrame.w - currentFrame.w) / 2,
        y = screenFrame.y + (screenFrame.h - currentFrame.h) / 2,
        w = currentFrame.w,
        h = currentFrame.h
    }
    
    win:setFrame(tempFrame, 0)
    
    -- PASSO 2: Aplicar margens após delay
    hs.timer.doAfter(0.2, function()
        win:focus()
        
        local targetFrame = calculateTargetFrame(screenFrame, monitorConfig.margins)
        win:setFrame(targetFrame, 0)
        
        print(string.format("Janela movida para %s", monitorConfig.name))
        hs.notify.new({
            title="Hammerspoon", 
            informativeText=string.format("Movida para %s", monitorConfig.name)
        }):send()
    end)
end

-- ========== API PÚBLICA (AÇÕES) ==========

-- Ação 1: Mover janela para monitor por ordem
-- @param order number Order do monitor (1-9)
-- @param shouldSave boolean (opcional) Se true, salva a posição
function obj:moveToMonitor(order, shouldSave)
    local config = getMonitorConfigByOrder(order)
    if config then
        moveWindowToMonitorInternal(config)
        
        -- Save position if requested
        if shouldSave then
            self:saveCurrentPosition(order)
        end
    else
        print(string.format("⚠️  Nenhum monitor configurado com order=%d", order))
    end
    return self
end

-- Ação 2: Obter informações de monitores configurados
function obj:getMonitorInfo()
    local info = "Monitores configurados:\n"
    
    for i, config in ipairs(monitorConfigs) do
        local connected = managerMonitorsMac.getMonitorByName(config.name) ~= nil
        local status = connected and "✓ Conectado" or "✗ Desconectado"
        
        local marginInfo = ""
        if config.margins then
            local m = config.margins
            marginInfo = string.format(" (L:%.1f%% T:%.1f%% B:%.1f%% R:%.1f%%)",
                (m.left or 0) * 100,
                (m.top or 0) * 100,
                (m.bottom or 0) * 100,
                (m.right or 0) * 100)
        end
        
        info = info .. string.format("%d. [Order:%d] %s %s%s\n", 
          i, config.order, status, config.name, marginInfo)
    end
    
    return info
end

-- Ação 3: Recarregar configuração
function obj:reloadConfig(newConfig)
    return self:setConfig(newConfig)
end

-- ========== STATE PERSISTENCE ==========

-- Ação 4: Salvar posição da janela em foco
function obj:saveCurrentPosition(order)
    local win = hs.window.focusedWindow()
    
    if not win then
        print("[MonitorWindowApp] Nenhuma janela em foco para salvar")
        return false
    end
    
    -- Load existing data
    local data = storageManager.load("MonitorWindowApp")
    if not data.window_positions then
        data.window_positions = {}
    end
    
    -- Save window position
    local windowId = tostring(win:id())
    local app = win:application()
    
    data.window_positions[windowId] = {
        app_name = app and app:name() or "Unknown",
        monitor_order = order
    }
    
    storageManager.save("MonitorWindowApp", data)
    print(string.format("[Save] %s (ID:%s) -> Monitor order %d", 
        data.window_positions[windowId].app_name, windowId, order))
    
    -- Schedule garbage collection
    self:scheduleGarbageCollection()
    return true
end

-- Ação 5: Restaurar posições de todas as janelas abertas
-- @param force boolean (opcional) Se true, ignora window_id e usa apenas app_name
function obj:loadPosition(force)
    local data = storageManager.load("MonitorWindowApp")
    
    if not data.window_positions or next(data.window_positions) == nil then
        hs.notify.new({
            title = "MonitorWindowApp",
            informativeText = "Nenhuma posição salva encontrada"
        }):send()
        print("[Load] Nenhuma posição salva")
        return self
    end
    
    -- Get all open windows
    local allWindows = hs.window.allWindows()
    local restored = 0
    
    if force then
        -- FORCE MODE: Match by app_name (ignora window_id)
        print("[Load] Modo FORCE ativado - usando app_name")
        
        -- Build app_name -> monitor_order map
        local appPositions = {}
        for _, savedPos in pairs(data.window_positions) do
            if savedPos.app_name and savedPos.monitor_order then
                appPositions[savedPos.app_name] = savedPos.monitor_order
            end
        end
        
        -- Restore by app name
        for _, win in ipairs(allWindows) do
            if win:isStandard() and win:isVisible() then
                local app = win:application()
                if app then
                    local appName = app:name()
                    local monitorOrder = appPositions[appName]
                    
                    if monitorOrder then
                        local config = getMonitorConfigByOrder(monitorOrder)
                        if config then
                            -- Pass window reference directly to avoid focus issues
                            moveWindowToMonitorInternal(config, win)
                            restored = restored + 1
                            print(string.format("[Load-Force] %s -> Monitor order %d", 
                                appName, monitorOrder))
                        end
                    end
                end
            end
        end
    else
        -- NORMAL MODE: Match by window_id
        for _, win in ipairs(allWindows) do
            if win:isStandard() and win:isVisible() then
                local windowId = tostring(win:id())
                local savedPos = data.window_positions[windowId]
                
                if savedPos then
                    -- Restore position
                    local config = getMonitorConfigByOrder(savedPos.monitor_order)
                    if config then
                        -- Pass window reference directly to avoid focus issues
                        moveWindowToMonitorInternal(config, win)
                        restored = restored + 1
                        print(string.format("[Load] %s (ID:%s) -> Monitor order %d", 
                            savedPos.app_name, windowId, savedPos.monitor_order))
                    end
                end
            end
        end
    end
    
    hs.notify.new({
        title = "MonitorWindowApp",
        informativeText = string.format("%d janela(s) restaurada(s)", restored)
    }):send()
    
    return self
end

-- Ação 6: Agendar garbage collection
function obj:scheduleGarbageCollection()
    -- Cancel existing timer
    if gcTimer then
        gcTimer:stop()
    end
    
    -- Schedule new cleanup
    gcTimer = hs.timer.doAfter(10, function()
        self:cleanupStaleEntries()
    end)
    
    print("[GC] Garbage collection agendado para 10s")
end

-- Ação 7: Limpar entradas obsoletas
function obj:cleanupStaleEntries()
    local data = storageManager.load("MonitorWindowApp")
    
    if not data.window_positions then
        return
    end
    
    -- Get all active window IDs
    local activeWindows = {}
    for _, win in ipairs(hs.window.allWindows()) do
        activeWindows[tostring(win:id())] = true
    end
    
    -- Remove stale entries
    local removed = 0
    for windowId, entry in pairs(data.window_positions) do
        if not activeWindows[windowId] then
            data.window_positions[windowId] = nil
            removed = removed + 1
            print(string.format("[GC] Removido ID obsoleto: %s (%s)", windowId, entry.app_name))
        end
    end
    
    -- Save cleaned data
    if removed > 0 then
        storageManager.save("MonitorWindowApp", data)
        print(string.format("[GC] %d entrada(s) removida(s)", removed))
    else
        print("[GC] Nenhuma entrada obsoleta encontrada")
    end
end

-- ========== LIFECYCLE ==========

function obj:init()
    hs.window.animationDuration = 0
    print("MonitorWindowApp Spoon: init() chamado")
    return self
end

function obj:start()
    print("MonitorWindowApp Spoon: Pronto (aguardando atalhos de init.lua)")
    return self
end

function obj:stop()
    print("MonitorWindowApp Spoon: Parado")
    return self
end

return obj
