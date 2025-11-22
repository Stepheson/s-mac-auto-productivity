print("==========================================")
print("Carregando Hammerspoon...")
print("==========================================")

-- ===== CONFIGURAR PATH PARA COMMON UTILITIES =====
package.path = package.path .. ";" .. hs.configdir .. "/Spoons/?.lua"

-- ===== LOAD SPOONS =====
hs.loadSpoon("WindowManager")
hs.loadSpoon("AppCycler")

function MuteMacHideShotcut()
  hs.alert.show("Mac Hide Shotcut Muted")
  hs.hotkey.bind({"cmd"}, "h", function() end)
end

function startAll()
  spoon.WindowManager:start()
  spoon.AppCycler:start()
end

function stoptAll()
  spoon.WindowManager:stop()
  spoon.AppCycler:stop()
end

-- ===== ATIVAR MÓDULOS NO LOAD =====
local modulesActive = true
MuteMacHideShotcut()
startAll()
print("Módulos iniciados automaticamente")

-- ===== CONTROLE DE ATIVAÇÃO DOS MÓDULOS =====
-- Alt+Shift+0: Desativar módulos
hs.hotkey.bind({"alt", "shift"}, "0", function()
  if modulesActive then
    print("Desativando módulos...")
    stoptAll()
    modulesActive = false
    hs.alert.show("🔴 Módulos Desativado")
  end
end)

-- Alt+Shift+1: Ativar módulos
hs.hotkey.bind({"alt", "shift"}, "1", function()
  if not modulesActive then
    print("Ativando módulos...")
    MuteMacHideShotcut()
    startAll()
    modulesActive = true
    hs.alert.show("🟢 Módulos Ativado")
  end
end)

-- ===== AUTO RELOAD =====
function reloadConfig(files)
  local doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
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