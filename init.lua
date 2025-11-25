-- ========== HAMMERSPOON GLOBALS ==========
-- Note: "hs" and "spoon" are global tables provided by Hammerspoon runtime

print("===========================================")
print("Loading Hammerspoon...")
print("===========================================")

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

local function registerAllHotkeys()
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
    table.insert(globalHotkeys, hs.hotkey.bind({ "alt" }, tostring(i), function()
      spoon.MonitorWindowApp:moveToMonitor(i, true)
    end))
  end
  print("  Alt+[1-4] -> Move to monitor and SAVE (max 4 monitors)")


  -- ========== LOAD HOTKEYS (RESTORE POSITIONS) ==========
  table.insert(globalHotkeys, hs.hotkey.bind({ "alt" }, "6", function()
    spoon.MonitorWindowApp:loadPosition()
  end))
  print("  Alt+6 -> Restore positions (window_id)")

  table.insert(globalHotkeys, hs.hotkey.bind({ "alt", "shift" }, "6", function()
    spoon.MonitorWindowApp:loadPosition(true)
  end))
  print("  Alt+Shift+6 -> Restore positions FORCE (app_name)")

  -- ========== APP CYCLING HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({ "alt" }, "tab", function()
    spoon.AppCycler:cycle()
  end))
  print("  Alt+Tab -> AppCycler:cycle()")

  -- ========== DEBUG HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({ "alt", "shift" }, "m", function()
    local managerMonitorsMac = require("common.managerMonitorsMac")
    managerMonitorsMac.printConnectedMonitors()
  end))
  print("  Alt+Shift+M -> Debug: show connected monitors")

  -- ========== SYSTEM HOTKEYS ==========
  table.insert(globalHotkeys, hs.hotkey.bind({ "cmd" }, "h", function() end))
  print("  Cmd+H -> Muted (Mac Hide disabled)")

  print("==========================================")
  print(string.format("Total: %d hotkey(s) registered", #globalHotkeys))
  print("==========================================")
end

local function unregisterAllHotkeys()
  for _, hk in ipairs(globalHotkeys) do
    hk:delete()
  end
  globalHotkeys = {}
  print("All hotkeys removed")
end

-- ========== MODULE LIFECYCLE ==========

local function startAll()
  spoon.MonitorWindowApp:start()
  spoon.AppCycler:start()
  registerAllHotkeys()

  -- Build list of active Spoons
  local activeSpoons = {}
  if spoon.MonitorWindowApp then
    table.insert(activeSpoons, "• " .. spoon.MonitorWindowApp.name)
  end
  if spoon.AppCycler then
    table.insert(activeSpoons, "• " .. spoon.AppCycler.name)
  end

  local message = "Spoons Active:\n" .. table.concat(activeSpoons, "\n")
  hs.alert.show("🟢 " .. message)
end

local function stopAll()
  unregisterAllHotkeys()
  spoon.MonitorWindowApp:stop()
  spoon.AppCycler:stop()

  -- Build list of stopped Spoons
  local stoppedSpoons = {}
  if spoon.MonitorWindowApp then
    table.insert(stoppedSpoons, "• " .. spoon.MonitorWindowApp.name)
  end
  if spoon.AppCycler then
    table.insert(stoppedSpoons, "• " .. spoon.AppCycler.name)
  end

  local message = "Spoons Inactive:\n" .. table.concat(stoppedSpoons, "\n")
  hs.alert.show("🔴 " .. message)
end

-- ========== INITIALIZATION ==========
local modulesActive = true
startAll()
print("Modules started automatically")

-- ========== GLOBAL CONTROLS ==========

hs.hotkey.bind({ "alt", "shift" }, "0", function()
  if modulesActive then
    print("Deactivating modules...")
    stopAll()
    modulesActive = false
  end
end)

hs.hotkey.bind({ "alt", "shift" }, "1", function()
  if not modulesActive then
    print("Activating modules...")
    startAll()
    modulesActive = true
  end
end)

-- ========== AUTO RELOAD ==========
local function reloadConfig(files)
  local doReload = false
  for _, file in pairs(files) do
    -- Ignore storage directory (contains position data that shouldn"t trigger reload)
    if not file:match("storage/") and (file:sub(-4) == ".lua" or file:sub(-5) == ".json") then
      doReload = true
      print(string.format("[AutoReload] Change detected: %s", file))
    end
  end
  if doReload then
    print("[AutoReload] Reloading Hammerspoon...")
    hs.reload()
  end
end

local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

print("==========================================")
print("Hammerspoon loaded successfully!")
print("==========================================")
