print("==========================================")
print("Loading Hammerspoon...")
print("==========================================")

-- ========== CONFIGURE PATH FOR COMMON UTILITIES ==========
package.path = package.path .. ";" .. hs.configdir .. "/Spoons/?.lua"

-- ========== LOAD JSON CONFIGURATION ==========
local configParser = require("common.configParser")
local configPath = hs.configdir .. "/ProfileSettings.json"
local appConfig = configParser.loadConfig(configPath)

-- ========== LOAD SPOONS ==========
hs.loadSpoon("MonitorWindowApp")
hs.loadSpoon("AppCycler")

-- ========== INJECT CONFIGURATION INTO SPOONS ==========
spoon.MonitorWindowApp:setConfig(appConfig)

-- ========== CENTRALIZED HOTKEY MANAGEMENT ==========
local globalHotkeys = {}

function registerAllHotkeys()
  print("==========================================")
  print("Registering centralized hotkeys...")
  print("==========================================")
  
  -- Clear old hotkeys
  for _, hk in ipairs(globalHotkeys) do
    hk:delete()
  end
  globalHotkeys = {}
  
  -- ========== MONITOR NAVIGATION & SAVE (1-4) ==========
  for i = 1, 4 do
    table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, tostring(i), function()
      spoon.MonitorWindowApp:moveToMonitor(i, true)
    end))
  end
  print("  Alt+[1-4] -> Move to monitor and SAVE (max 4 monitors)")
  
  
  -- ========== LOAD HOTKEYS (RESTORE POSITIONS) ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, "6", function()
    spoon.MonitorWindowApp:loadPosition()
  end))
  print("  Alt+6 -> Restore positions (window_id)")
  
  table.insert(globalHotkeys, hs.hotkey.bind({"alt", "shift"}, "6", function()
    spoon.MonitorWindowApp:loadPosition(true)
  end))
  print("  Alt+Shift+6 -> Restore positions FORCE (app_name)")
  
  -- ========== APP CYCLING HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt"}, "tab", function()
    spoon.AppCycler:cycle()
  end))
  print("  Alt+Tab -> AppCycler:cycle()")
  
  -- ========== DEBUG HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"alt", "shift"}, "m", function()
    local managerMonitorsMac = require("common.managerMonitorsMac")
    managerMonitorsMac.printConnectedMonitors()
  end))
  print("  Alt+Shift+M -> Debug: show connected monitors")
  
  -- ========== SYSTEM HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({"cmd"}, "h", function() end))
  print("  Cmd+H -> Muted (Mac Hide disabled)")
  
  print("==========================================")
  print(string.format("Total: %d hotkey(s) registered", #globalHotkeys))
  print("==========================================")
end

function unregisterAllHotkeys()
  for _, hk in ipairs(globalHotkeys) do
    hk:delete()
  end
  globalHotkeys = {}
  print("All hotkeys removed")
end

-- ========== MODULE LIFECYCLE ==========

function startAll()
  spoon.MonitorWindowApp:start()
  spoon.AppCycler:start()
  registerAllHotkeys()
  hs.alert.show("🟢 Hammerspoon Active")
end

function stopAll()
  unregisterAllHotkeys()
  spoon.MonitorWindowApp:stop()
  spoon.AppCycler:stop()
  hs.alert.show("🔴 Hammerspoon Inactive")
end

-- ========== INITIALIZATION ==========
local modulesActive = true
startAll()
print("Modules started automatically")

-- ========== GLOBAL CONTROLS ==========

hs.hotkey.bind({"alt", "shift"}, "0", function()
  if modulesActive then
    print("Deactivating modules...")
    stopAll()
    modulesActive = false
  end
end)

hs.hotkey.bind({"alt", "shift"}, "1", function()
  if not modulesActive then
    print("Activating modules...")
    startAll()
    modulesActive = true
  end
end)

-- ========== AUTO RELOAD ==========
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
print("Hammerspoon loaded successfully!")
print("==========================================")