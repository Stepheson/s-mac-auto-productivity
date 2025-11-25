--- === MonitorWindowApp ===
---
--- Window movement library for multi-monitor setups
--- Does NOT handle keyboard shortcuts - only exposes actions

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MonitorWindowApp"
obj.version = "2.0"
obj.author = "Stepheson Alves"
obj.license = "MIT"

-- Internal state
local monitorConfigs = {}
local managerMonitorsMac = require("common.managerMonitorsMac")
local storageManager = require("common.storageManager")

-- Garbage collection timer
local gcTimer = nil

-- ========== CONFIGURATION ==========

--- Set monitor configuration from ProfileSettings.json
-- @param config table Configuration object containing MonitorWindowApp array
-- @return self
function obj:setConfig(config)
    monitorConfigs = config.MonitorWindowApp or {}
    print(string.format("MonitorWindowApp: %d monitor(s) configured", #monitorConfigs))
    return self
end

-- ========== INTERNAL HELPERS ==========

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

--- Internal function to move window to monitor
-- @param monitorConfig table Monitor configuration with name and margins
-- @param targetWindow userdata (optional) Window object to move, uses focused window if nil
local function moveWindowToMonitorInternal(monitorConfig, targetWindow)
    local win = targetWindow or hs.window.focusedWindow()
    if not win then
        hs.notify.new({ title = "Hammerspoon", informativeText = "No window in focus" }):send()
        return
    end

    local targetScreen = managerMonitorsMac.getMonitorByName(monitorConfig.name)

    if not targetScreen then
        print(string.format("Monitor '%s' not found (disconnected)", monitorConfig.name))
        return
    end

    local screenFrame = targetScreen:frame()
    local currentFrame = win:frame()

    -- STEP 1: Move to center of monitor
    local tempFrame = {
        x = screenFrame.x + (screenFrame.w - currentFrame.w) / 2,
        y = screenFrame.y + (screenFrame.h - currentFrame.h) / 2,
        w = currentFrame.w,
        h = currentFrame.h
    }

    win:setFrame(tempFrame, 0)

    -- STEP 2: Apply margins after delay
    hs.timer.doAfter(0.2, function()
        win:focus()

        local targetFrame = calculateTargetFrame(screenFrame, monitorConfig.margins)
        win:setFrame(targetFrame, 0)

        print(string.format("Window moved to %s", monitorConfig.name))
        hs.notify.new({
            title = "Hammerspoon",
            informativeText = string.format("Moved to %s", monitorConfig.name)
        }):send()
    end)
end

-- ========== PUBLIC API (ACTIONS) ==========

--- Move focused window to monitor by order
-- @param order number Monitor order (1-4)
-- @param shouldSave boolean (optional) If true, saves position to storage
-- @return self
function obj:moveToMonitor(order, shouldSave)
    local config = getMonitorConfigByOrder(order)
    if config then
        moveWindowToMonitorInternal(config)

        if shouldSave then
            self:saveCurrentPosition(order)
        end
    else
        print(string.format("⚠️  No monitor configured with order=%d", order))
    end
    return self
end

--- Get information about configured monitors
-- @return string Information string with monitor status
function obj:getMonitorInfo()
    local info = "Configured monitors:\n"

    for i, config in ipairs(monitorConfigs) do
        local connected = managerMonitorsMac.getMonitorByName(config.name) ~= nil
        local status = connected and "✓ Connected" or "✗ Disconnected"

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

--- Reload configuration
-- @param newConfig table New configuration object
-- @return self
function obj:reloadConfig(newConfig)
    return self:setConfig(newConfig)
end

-- ========== STATE PERSISTENCE ==========

--- Save position of focused window
-- @param order number Monitor order where window was moved
-- @return boolean true if saved successfully
function obj:saveCurrentPosition(order)
    local win = hs.window.focusedWindow()

    if not win then
        print("[MonitorWindowApp] No window in focus to save")
        return false
    end

    local data = storageManager.load("MonitorWindowApp")
    if not data.window_positions then
        data.window_positions = {}
    end

    local windowId = tostring(win:id())
    local app = win:application()

    data.window_positions[windowId] = {
        app_name = app and app:name() or "Unknown",
        monitor_order = order
    }

    storageManager.save("MonitorWindowApp", data)
    print(string.format("[Save] %s (ID:%s) -> Monitor order %d",
        data.window_positions[windowId].app_name, windowId, order))

    self:scheduleGarbageCollection()
    return true
end

--- Restore positions of all open windows
-- @param force boolean (optional) If true, ignores window_id and uses only app_name
-- @return self
function obj:loadPosition(force)
    local data = storageManager.load("MonitorWindowApp")

    if not data.window_positions or next(data.window_positions) == nil then
        hs.notify.new({
            title = "MonitorWindowApp",
            informativeText = "No saved positions found"
        }):send()
        print("[Load] No saved positions")
        return self
    end

    local allWindows = hs.window.allWindows()
    local restored = 0

    if force then
        -- FORCE MODE: Match by app_name (ignores window_id)
        print("[Load] FORCE mode activated - using app_name")

        local appPositions = {}
        for _, savedPos in pairs(data.window_positions) do
            if savedPos.app_name and savedPos.monitor_order then
                appPositions[savedPos.app_name] = savedPos.monitor_order
            end
        end

        for _, win in ipairs(allWindows) do
            if win:isStandard() and win:isVisible() then
                local app = win:application()
                if app then
                    local appName = app:name()
                    local monitorOrder = appPositions[appName]

                    if monitorOrder then
                        local config = getMonitorConfigByOrder(monitorOrder)
                        if config then
                            moveWindowToMonitorInternal(config, win)
                            restored = restored + 1
                            print(string.format("[Load-Force] %s -> Monitor order %d",
                                appName, monitorOrder))
                        end
                    end
                end
            end
        end
    else
        -- NORMAL MODE: Match by window_id
        for _, win in ipairs(allWindows) do
            if win:isStandard() and win:isVisible() then
                local windowId = tostring(win:id())
                local savedPos = data.window_positions[windowId]

                if savedPos then
                    local config = getMonitorConfigByOrder(savedPos.monitor_order)
                    if config then
                        moveWindowToMonitorInternal(config, win)
                        restored = restored + 1
                        print(string.format("[Load] %s (ID:%s) -> Monitor order %d",
                            savedPos.app_name, windowId, savedPos.monitor_order))
                    end
                end
            end
        end
    end

    hs.notify.new({
        title = "MonitorWindowApp",
        informativeText = string.format("%d window(s) restored", restored)
    }):send()

    return self
end

--- Schedule garbage collection
function obj:scheduleGarbageCollection()
    if gcTimer then
        gcTimer:stop()
    end

    gcTimer = hs.timer.doAfter(10, function()
        self:cleanupStaleEntries()
    end)

    print("[GC] Garbage collection scheduled for 10s")
end

--- Clean up stale entries from storage
function obj:cleanupStaleEntries()
    local data = storageManager.load("MonitorWindowApp")

    if not data.window_positions then
        return
    end

    local activeWindows = {}
    for _, win in ipairs(hs.window.allWindows()) do
        activeWindows[tostring(win:id())] = true
    end

    local removed = 0
    for windowId, entry in pairs(data.window_positions) do
        if not activeWindows[windowId] then
            data.window_positions[windowId] = nil
            removed = removed + 1
            print(string.format("[GC] Removed stale ID: %s (%s)", windowId, entry.app_name))
        end
    end

    if removed > 0 then
        storageManager.save("MonitorWindowApp", data)
        print(string.format("[GC] %d entry/entries removed", removed))
    else
        print("[GC] No stale entries found")
    end
end

-- ========== LIFECYCLE ==========

function obj:init()
    hs.window.animationDuration = 0
    print("MonitorWindowApp Spoon: init() called")
    return self
end

function obj:start()
    print("MonitorWindowApp Spoon: Ready (waiting for hotkeys from init.lua)")
    return self
end

function obj:stop()
    print("MonitorWindowApp Spoon: Stopped")
    return self
end

return obj
