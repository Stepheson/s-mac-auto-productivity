--- === AppCycler ===
---
--- Alternância de aplicativos no mesmo monitor
--- Permite ciclar entre apps usando Alt+Tab

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AppCycler"
obj.version = "1.0"
obj.author = "Stepheson Alves"
obj.license = "MIT"
obj.homepage = "https://github.com/yourusername/hammerspoon-config"

-- Internal state
obj.hotkeys = {}
local lastExecutionTime = 0
local minimumDelay = 0.15  -- 150ms entre execuções
local isExecuting = false  -- Lock global
local lastFocusedScreenId = nil

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
    
    local currentWin = hs.window.focusedWindow()
    if not currentWin then
      isExecuting = false
      hs.alert.show("Nenhuma janela em foco", 1)
      return
    end
    
    local currentScreen = currentWin:screen()
    local targetScreenId = currentScreen:id()
    local currentApp = currentWin:application()
    
    print(string.format(">>> EXECUTANDO no Monitor ID: %s (%s)", targetScreenId, currentScreen:name()))
    
    local allWindows = hs.window.allWindows()
    local allAppsOnScreen = {}
    
    -- Pegar TODOS os apps APENAS do monitor alvo (EVITA DUPLICATAS)
    for _, win in ipairs(allWindows) do
      local app = win:application()
      local winScreen = win:screen()
      
      if winScreen and winScreen:id() == targetScreenId and 
         win:isStandard() and
         win:subrole() ~= "AXUnknown" then
        
        -- Evitar duplicatas (mesmo app = uma entrada só)
        local appAlreadyAdded = false
        for _, existing in ipairs(allAppsOnScreen) do
          if existing.app == app then
            appAlreadyAdded = true
            break
          end
        end
        
        if not appAlreadyAdded then
          table.insert(allAppsOnScreen, {
            window = win,
            app = app,
            name = app:name()
          })
        end
      end
    end
    
    if #allAppsOnScreen <= 1 then
      isExecuting = false
      hs.alert.show("Nenhum outro app neste monitor", 1)
      return
    end
    
    table.sort(allAppsOnScreen, function(a, b)
      return a.name < b.name
    end)
    
    local currentIndex = 1
    for i, appData in ipairs(allAppsOnScreen) do
      if appData.app == currentApp then
        currentIndex = i
        break
      end
    end
    
    local nextIndex = currentIndex + 1
    if nextIndex > #allAppsOnScreen then
      nextIndex = 1
    end
    
    local nextWindow = allAppsOnScreen[nextIndex].window
    local nextApp = allAppsOnScreen[nextIndex].app
    local nextName = allAppsOnScreen[nextIndex].name
    
    -- Validação antes de ativar
    if nextWindow:screen():id() ~= targetScreenId then
        isExecuting = false
        print(">>> ABORTADO: Janela não está no monitor correto")
        return
    end
    
    -- Salvar o screen ID antes de ativar
    lastFocusedScreenId = targetScreenId
    
    nextApp:activate()
    nextWindow:focus()
    
    hs.alert.show(string.format("→ %s (%d/%d)", nextName, nextIndex, #allAppsOnScreen), 0.8)
    print(string.format(">>> SUCESSO: %s (%d/%d)", nextName, nextIndex, #allAppsOnScreen))
    
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
