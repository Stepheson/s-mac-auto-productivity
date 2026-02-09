-- ========== HAMMERSPOON ENTRY POINT ==========
-- This file acts as a configuration file, wiring together Spoons and Hotkeys.
-- All logic is encapsulated within the Spoons and Common modules.

print("===========================================")
print("Loading Hammerspoon Configuration...")
print("===========================================")

-- ========== PATH CONFIGURATION ==========
-- Ensure we can load Spoons and common modules


-- ========== LOAD SPOONS ==========
hs.loadSpoon("AutomationControl")
hs.loadSpoon("MonitorWindowApp")
hs.loadSpoon("AppCycler")
hs.loadSpoon("EasyLoadModules")

-- ========== HOTKEYS ==========

local hotkeys = {}


-- ========== SIDE HOTKEY MODULE ==========
local SideHotkey = require("common.side_hotkey")
local WindowGenerator = require("common.window_generator")

-- 1. Master Switch (Always Active)
-- These are NOT added to the 'hotkeys' list, so AutomationControl doesn't disable them.
SideHotkey.bind({ "rightAlt", "rightShift" }, "0", function()
  spoon.AutomationControl:stop()
end)

SideHotkey.bind({ "rightAlt", "rightShift" }, "1", function()
  spoon.AutomationControl:start()
end)

-- Block the left command to prevent accidental closing.
table.insert(hotkeys, SideHotkey.bind({ "leftCmd" }, "h", function() end))
table.insert(hotkeys, SideHotkey.bind({ "leftCmd" }, "q", function() end))
-- System is not managed by AutomationControl.
--hs.hotkey.bind({ "cmd" }, "h", function() end)

-- 2. Operational Hotkeys (Managed)
-- These are added to the list to be disabled on stop().

-- Monitor Navigation

table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "§", function()
  spoon.MonitorWindowApp:loadPosition()
end))

table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "1", function()
  print("Hotkey LeftAlt+1 pressed")
  spoon.MonitorWindowApp:moveToMonitor("dell_standard_margin_spaceleft", true)
end))

table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "2", function()
  spoon.MonitorWindowApp:moveToMonitor("monitor_MX279_margin_spaceleft", true)
end))

table.insert(hotkeys, SideHotkey.bind({ "leftAlt", "shift" }, "2", function()
  spoon.MonitorWindowApp:moveToMonitor("monitor_MX279_margin_spaceleft_top", true)
end))

table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "3", function()
  spoon.MonitorWindowApp:moveToMonitor("builtin_standard_margin_spaceleft", true)
end))

-- App Cycling
table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "tab", function()
  spoon.AppCycler:cycle(0)
end))

table.insert(hotkeys, SideHotkey.bind({ "leftAlt" }, "q", function()
  WindowGenerator:show()
end))

-- Debug Tools
table.insert(hotkeys, SideHotkey.bind({ "rightAlt", "rightShift" }, "m", function()
  local managerMonitorsMac = require("common.manager_monitors_mac")
  managerMonitorsMac.printConnectedMonitors()
end))

-- ========== AUTOMATION CONTROL INJECTION ==========

if spoon.AutomationControl then
  spoon.AutomationControl:registerSpoon(spoon.MonitorWindowApp)
  spoon.AutomationControl:registerSpoon(spoon.AppCycler)
  spoon.AutomationControl:registerSpoon(spoon.EasyLoadModules)
  spoon.AutomationControl:registerHotkeys(hotkeys)
  spoon.AutomationControl:start()
else
  print("⚠️ AutomationControl Spoon not found. Hotkeys active in unmanaged mode.")
end
