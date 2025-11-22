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

local function moveWindowToMonitorInternal(monitorConfig)
    local win = hs.window.focusedWindow()
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
function obj:moveToMonitor(order)
    local config = getMonitorConfigByOrder(order)
    if config then
        moveWindowToMonitorInternal(config)
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
