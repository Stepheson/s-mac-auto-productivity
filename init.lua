print("==========================================")
print("Carregando Hammerspoon...")
print("==========================================")

-- ===== CONFIGURAR PATH PARA COMMON UTILITIES =====
package.path = package.path .. ";" .. hs.configdir .. "/Spoons/?.lua"

-- ===== CARREGAR CONFIGURAÇÃO JSON (CENTRALIZADO) =====
local configParser = require("common.configParser")
local configPath = hs.configdir .. "/ProfileSettings.json"
local appConfig = configParser.loadConfig(configPath)

-- ===== CARREGAR SPOONS =====
hs.loadSpoon("MonitorWindowApp")
hs.loadSpoon("AppCycler")

-- ===== INJETAR CONFIGURAÇÃO NOS SPOONS =====
spoon.MonitorWindowApp:setConfig(appConfig)

-- ===== GERENCIAMENTO CENTRALIZADO DE ATALHOS =====
local globalHotkeys = {}

function registerAllHotkeys()
  print("==========================================")
  print("Registrando atalhos centralizados...")
  print("==========================================")
  
  -- Limpar atalhos antigos
  for _, hk in ipairs(globalHotkeys) do
    hk:delete()
  end
  globalHotkeys = {}
  
  -- ========== ATALHOS DE NAVEGAÇÃO E SAVE (MONITORES 1-4) ==========
  -- Alt+[1-4]: Mover para monitor E salvar posição automaticamente
  for i = 1, 4 do
    table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, tostring(i), function()
      spoon.MonitorWindowApp:moveToMonitor(i, true)  -- shouldSave = true
    end))
  end
  print("  Alt+[1-4] -> Mover para monitor e SALVAR (máx 4 monitores)")
  
  
  -- ========== ATALHO DE LOAD (RESTAURAR POSIÇÕES) ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, "6", function()
    -- Alt+6: Restaurar posições salvas (por window_id)
    spoon.MonitorWindowApp:loadPosition()
  end))
  print("  Alt+6 -> Restaurar posições (window_id)")
  
  table.insert(globalHotkeys, hs.hotkey.bind({"alt", "shift"}, "6", function()
    -- Alt+Shift+6: Restaurar posições FORCE (por app_name)
    spoon.MonitorWindowApp:loadPosition(true)
  end))
  print("  Alt+Shift+6 -> Restaurar posições FORCE (app_name)")
  
  -- ========== ATALHOS DE ALTERNÂNCIA DE APPS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, "tab", function()
    -- Alt+Tab: Ciclar apps no monitor atual
    spoon.AppCycler:cycle()
  end))
  print("  Alt+Tab -> AppCycler:cycle()")
  
  -- ========== ATALHOS DE DEBUG ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt", "shift"}, "m", function()
    -- Alt+Shift+M: Mostrar monitores conectados
    local managerMonitorsMac = require("common.managerMonitorsMac")
    managerMonitorsMac.printConnectedMonitors()
  end))
  print("  Alt+Shift+M -> Debug: mostrar monitores")
  
  -- ========== ATALHOS DE SISTEMA ==========
  -- Cmd+H: Muted (desabilitar hide padrão do Mac)
  table.insert(globalHotkeys, hs.hotkey.bind({"cmd"}, "h", function() end))
  print("  Cmd+H -> Muted (Mac Hide desabilitado)")
  
  print("==========================================")
  print(string.format("Total: %d atalho(s) registrado(s)", #globalHotkeys))
  print("==========================================")
end

function unregisterAllHotkeys()
  for _, hk in ipairs(globalHotkeys) do
    hk:delete()
  end
  globalHotkeys = {}
  print("Todos os atalhos removidos")
end

-- ===== CICLO DE VIDA DOS MÓDULOS =====

function startAll()
  spoon.MonitorWindowApp:start()
  spoon.AppCycler:start()
  registerAllHotkeys()
  hs.alert.show("🟢 Hammerspoon Ativo")
end

function stopAll()
  unregisterAllHotkeys()
  spoon.MonitorWindowApp:stop()
  spoon.AppCycler:stop()
  hs.alert.show("🔴 Hammerspoon Inativo")
end

-- ===== INICIALIZAÇÃO =====
local modulesActive = true
startAll()
print("Módulos iniciados automaticamente")

-- ===== CONTROLES GLOBAIS =====

-- Alt+Shift+0: Desativar todos os módulos
hs.hotkey.bind({"alt", "shift"}, "0", function()
  if modulesActive then
    print("Desativando módulos...")
    stopAll()
    modulesActive = false
  end
end)

-- Alt+Shift+1: Ativar todos os módulos
hs.hotkey.bind({"alt", "shift"}, "1", function()
  if not modulesActive then
    print("Ativando módulos...")
    startAll()
    modulesActive = true
  end
end)

-- ===== AUTO RELOAD =====
function reloadConfig(files)
  local doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" or file:sub(-5) == ".json" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

print("==========================================")
print("Hammerspoon carregado com sucesso!")
print("==========================================")