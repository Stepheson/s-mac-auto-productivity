--- === AppCycler ===
---
--- Application cycling library for same-monitor workflows
--- Does NOT handle keyboard shortcuts - only exposes actions
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AppCycler"
obj.version = "1.2"
obj.author = "Stepheson Alves"
obj.license = "MIT"

-- Internal state
local isExecuting = false
local managerMonitorsMac = require("common.managerMonitorsMac")

-- ========== PUBLIC API (ACTIONS) ==========

--- Cycle through visible apps/windows on the current monitor
--- @param mode number (optional) 0=All (default), 1=Apps Only, 2=Instances Only
--- @return self
function obj:cycle(mode)
  if isExecuting then
    return self
  end

  -- Default to Mode 0 (All)
  mode = mode or 0

  isExecuting = true

  -- Safety unlock after timeout
  hs.timer.doAfter(0.5, function() isExecuting = false end)

  local winInfo = managerMonitorsMac.getFocusedWindowInfo()
  if not winInfo then
    isExecuting = false
    return self
  end

  local screenId = winInfo.screenId
  local currentWin = winInfo.window

  -- Get filtered and sorted windows
  local windows = managerMonitorsMac.getVisibleWindowsOnScreen(screenId, mode)

  if #windows < 2 then
    isExecuting = false
    return self
  end

  -- Find current index in the sorted list
  local currentIndex = -1
  for i, w in ipairs(windows) do
    if w.window:id() == currentWin:id() then
      currentIndex = i
      break
    end
  end

  -- Calculate next index (Circular)
  local nextIndex = 1
  if currentIndex ~= -1 then
    nextIndex = currentIndex + 1
    if nextIndex > #windows then
      nextIndex = 1
    end
  end

  -- Focus next window
  local target = windows[nextIndex]
  if target then
    target.window:focus()

    -- Visual feedback
    hs.alert.show(string.format("→ %s (%d/%d)", target.name, nextIndex, #windows), 0.5)
  end

  -- Release lock after short delay
  hs.timer.doAfter(0.15, function() isExecuting = false end)

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
