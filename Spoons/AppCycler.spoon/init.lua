--- === AppCycler ===
---
--- Alternância de aplicativos no mesmo monitor
--- Permite ciclar entre apps usando Alt+Tab

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AppCycler"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.license = "MIT"
obj.homepage = "https://github.com/yourusername/hammerspoon-config"

-- Internal state
obj.hotkeys = {}
local lastExecutionTime = 0
local minimumDelay = 0.15  -- 150ms entre execuções
local isExecuting = false  -- Lock global

-- Carregar utilitários comuns
local managerMonitorsMac = require("common.managerMonitorsMac")

-- ========== MÉTODOS PRIVADOS ==========

local function cycleAppsOnCurrentMonitor()
    -- TRAVA: Prevenir execuções simultâneas
    if isExecuting then
      print(">>> BLOQUEADO: Já existe uma execução em andamento")
      return
    end
    
    -- DEBOUNCE: Prevenir execuções muito rápidas
    local currentTime = hs.timer.secondsSinceEpoch()
    local timeSinceLastExecution = currentTime - lastExecutionTime
    
    if timeSinceLastExecution < minimumDelay then
      print(string.format(">>> BLOQUEADO: Muito rápido (%.3fs desde última execução)", timeSinceLastExecution))
      hs.alert.show("⏸ Aguarde...", 0.3)
      return
    end
    
    -- Ativar lock
    isExecuting = true
    lastExecutionTime = currentTime
    
    -- Usar utilitário comum para pegar informações da janela em foco
    local focusedInfo = managerMonitorsMac.getFocusedWindowInfo()
    if not focusedInfo then
      isExecuting = false
      hs.alert.show("Nenhuma janela em foco", 1)
      return
    end
    
    local currentApp = focusedInfo.app
    local targetScreenId = focusedInfo.screenId
    
    print(string.format(">>> EXECUTANDO no Monitor ID: %s (%s)", targetScreenId, focusedInfo.screenName))
    
    -- Usar utilitário comum para pegar apenas janelas visíveis no monitor
    local visibleApps = managerMonitorsMac.getVisibleWindowsOnScreen(targetScreenId)
    
    if #visibleApps <= 1 then
      isExecuting = false
      hs.alert.show("Nenhum outro app neste monitor", 1)
      return
    end
    
    -- Ordenar alfabeticamente por nome
    table.sort(visibleApps, function(a, b)
      return a.name < b.name
    end)
    
    -- Encontrar índice do app atual
    local currentIndex = 1
    for i, appData in ipairs(visibleApps) do
      if appData.app == currentApp then
        currentIndex = i
        break
      end
    end
    
    -- Calcular próximo índice (circular)
    local nextIndex = currentIndex + 1
    if nextIndex > #visibleApps then
      nextIndex = 1
    end
    
    local nextWindow = visibleApps[nextIndex].window
    local nextApp = visibleApps[nextIndex].app
    local nextName = visibleApps[nextIndex].name
    
    -- Validação final: garantir que a janela ainda está no monitor correto
    if nextWindow:screen():id() ~= targetScreenId then
        isExecuting = false
        print(">>> ABORTADO: Janela não está no monitor correto")
        return
    end
    
    -- Ativar o app e focar na janela
    nextApp:activate()
    hs.timer.doAfter(0.05, function()
        nextWindow:focus()
    end)
    
    hs.alert.show(string.format("→ %s (%d/%d)", nextName, nextIndex, #visibleApps), 0.8)
    print(string.format(">>> SUCESSO: %s (%d/%d)", nextName, nextIndex, #visibleApps))
    
    isExecuting = false
end


-- ========== MÉTODOS PÚBLICOS ==========

function obj:init()
  print("AppCycler Spoon: init() chamado")
  return self
end

-- Configurar atalhos
function obj:setupHotkeys()
  print("AppCycler Spoon: Configurando atalhos...")
  
  -- Limpa hotkeys antigos
  for _, hk in ipairs(self.hotkeys) do
    hk:delete()
  end
  self.hotkeys = {}
  
  -- Alt+Tab: Ciclar entre apps do monitor atual
  table.insert(self.hotkeys, hs.hotkey.bind({"alt"}, "tab", function()
    cycleAppsOnCurrentMonitor()
  end))
  
  print("AppCycler Spoon: " .. #self.hotkeys .. " atalho(s) configurado(s)!")
end

-- Método público para ciclar manualmente
function obj:cycle()
  cycleAppsOnCurrentMonitor()
  return self
end

-- Iniciar módulo
function obj:start()
  self:setupHotkeys()
  
  hs.notify.new({
    title="App Cycler", 
    informativeText="Carregado!\nAlt+Tab: Ciclar apps no monitor atual"
  }):send()
  
  print("App Cycler Spoon configurado com sucesso")
  return self
end

-- Método para parar e deletar todos os hotkeys
function obj:stop()
  print("AppCycler Spoon: stop() chamado")
  
  if self.hotkeys then
    for _, hk in ipairs(self.hotkeys) do
      hk:delete()
    end
    self.hotkeys = {}
    print("AppCycler Spoon: todos os hotkeys deletados")
  end
  return self
end

return obj
