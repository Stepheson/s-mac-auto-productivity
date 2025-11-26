--- === AppCycler ===
---
--- Application cycling library for same-monitor workflows
--- Does NOT handle keyboard shortcuts - only exposes actions

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AppCycler"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.license = "MIT"

-- Internal state
local lastExecutionTime = 0
local minimumDelay = 0.15
local isExecuting = false

local managerMonitorsMac = require("common.managerMonitorsMac")

-- ========== INTERNAL LOGIC ==========

local function cycleAppsOnCurrentMonitor()
  -- LOCK: Prevent simultaneous executions
  if isExecuting then
    print(">>> BLOCKED: Execution already in progress")
    return
  end

  -- DEBOUNCE: Prevent rapid executions
  local currentTime = hs.timer.secondsSinceEpoch()
  local timeSinceLastExecution = currentTime - lastExecutionTime

  if timeSinceLastExecution < minimumDelay then
    print(string.format(">>> BLOCKED: Too fast (%.3fs since last execution)", timeSinceLastExecution))
    hs.alert.show("⏸ Wait...", 0.3)
    return
  end

  isExecuting = true
  lastExecutionTime = currentTime

  local focusedInfo = managerMonitorsMac.getFocusedWindowInfo()
  if not focusedInfo then
    isExecuting = false
    hs.alert.show("No window in focus", 1)
    return
  end

  local currentApp = focusedInfo.app
  local targetScreenId = focusedInfo.screenId

  print(string.format(">>> EXECUTING on Monitor ID: %s (%s)", targetScreenId, focusedInfo.screenName))

  local visibleApps = managerMonitorsMac.getVisibleWindowsOnScreen(targetScreenId)

  if #visibleApps <= 1 then
    isExecuting = false
    hs.alert.show("No other apps on this monitor", 1)
    return
  end

  -- Sort alphabetically by name
  table.sort(visibleApps, function(a, b)
    return a.name < b.name
  end)

  -- Find current app index
  local currentIndex = 1
  for i, appData in ipairs(visibleApps) do
    if appData.app == currentApp then
      currentIndex = i
      break
    end
  end

  -- Calculate next index (circular)
  local nextIndex = currentIndex + 1
  if nextIndex > #visibleApps then
    nextIndex = 1
  end

  local nextWindow = visibleApps[nextIndex].window
  local nextApp = visibleApps[nextIndex].app
  local nextName = visibleApps[nextIndex].name

  -- Final validation: ensure window is still on correct monitor and screen exists
  local nextScreen = nextWindow:screen()
  if not nextScreen or nextScreen:id() ~= targetScreenId then
    isExecuting = false
    print(">>> ABORTED: Window not on correct monitor or was closed")
    return
  end

  -- Activate app and focus window
  nextApp:activate()
  hs.timer.doAfter(0.05, function()
    nextWindow:focus()
  end)

  hs.alert.show(string.format("→ %s (%d/%d)", nextName, nextIndex, #visibleApps), 0.8)
  print(string.format(">>> SUCCESS: %s (%d/%d)", nextName, nextIndex, #visibleApps))

  isExecuting = false
end

-- ========== PUBLIC API (ACTIONS) ==========

--- Cycle between apps on current monitor
-- @return self
function obj:cycle()
  cycleAppsOnCurrentMonitor()
  return self
end

-- ========== LIFECYCLE ==========

function obj:init()
  print("AppCycler Spoon: init() called")
  -- Start Auto-Reload
  require("common.autoReload").start()
  return self
end

function obj:start()
  print("AppCycler Spoon: Ready (waiting for hotkeys from init.lua)")
  return self
end

function obj:stop()
  print("AppCycler Spoon: Stopped")
  isExecuting = false
  return self
end

return obj
