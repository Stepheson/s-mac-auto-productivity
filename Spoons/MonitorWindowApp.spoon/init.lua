--- === MonitorWindowApp ===
---
--- Window movement library for multi-monitor setups
--- Does NOT handle keyboard shortcuts - only exposes actions

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MonitorWindowApp"
obj.version = "2.2"
obj.author = "Stepheson Alves"
obj.license = "MIT"

-- Internal state
local monitorConfigs = {}
local managerMonitorsMac = require("common.managerMonitorsMac")
local storageManager = require("common.storageManager")
local configParser = require("common.configParser")

-- Garbage collection timer
local gcTimer = nil

-- ========== CONFIGURATION ==========

--- Load configuration from MonitorWindowAppSettings.json
-- @return self
function obj:loadConfig()
    local configPath = hs.configdir .. "/MonitorWindowAppSettings.json"
    monitorConfigs = configParser.loadConfig(configPath) or {}
    print(string.format("MonitorWindowApp: %d configuration(s) loaded from internal file", #monitorConfigs))
    return self
end

-- ========== INTERNAL HELPERS ==========

local function getMonitorConfigByPositionID(positionID)
    for _, config in ipairs(monitorConfigs) do
        if config.positionID == positionID then
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
-- @param monitorConfig table Monitor configuration with positionID, monitorName and margins
-- @param targetWindow userdata (optional) Window object to move, uses focused window if nil
local function moveWindowToMonitorInternal(monitorConfig, targetWindow)
    local win = targetWindow or hs.window.focusedWindow()
    if not win then
        hs.notify.new({ title = "Hammerspoon", informativeText = "No window in focus" }):send()
        return
    end

    -- Use monitorName to find the physical screen
    local targetScreen = managerMonitorsMac.getMonitorByName(monitorConfig.monitorName)

    if not targetScreen then
        print(string.format("Monitor '%s' not found (disconnected) for config '%s'",
            monitorConfig.monitorName, monitorConfig.positionID))
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

        print(string.format("Window moved to config '%s' on monitor '%s'",
            monitorConfig.positionID, monitorConfig.monitorName))

        hs.notify.new({
            title = "Hammerspoon",
            informativeText = string.format("Moved to %s", monitorConfig.positionID)
        }):send()
    end)
end

-- ========== PUBLIC API (ACTIONS) ==========

--- Move focused window to monitor by position ID
--- @param positionID string Configuration ID (e.g., "dell_standard")
--- @param shouldSave boolean (optional) If true, saves position to storage
--- @return self
function obj:moveToMonitor(positionID, shouldSave)
    local config = getMonitorConfigByPositionID(positionID)
    if config then
        moveWindowToMonitorInternal(config)

        if shouldSave then
            self:saveCurrentPosition(positionID)
        end
    else
        print(string.format("⚠️  No configuration found with positionID='%s'", positionID))
        hs.notify.new({ title = "Hammerspoon", informativeText = "Config not found: " .. positionID }):send()
    end
    return self
end

--- Get information about configured monitors
-- @return string Information string with monitor status
function obj:getMonitorInfo()
    local info = "Configured Layouts:\n"

    for i, config in ipairs(monitorConfigs) do
        local connected = managerMonitorsMac.getMonitorByName(config.monitorName) ~= nil
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

        info = info .. string.format("%d. [ID: %s] -> [Monitor: %s] %s%s\n",
            i, config.positionID, config.monitorName, status, marginInfo)
    end

    return info
end

--- Reload configuration
-- @return self
function obj:reloadConfig()
    return self:loadConfig()
end

-- ========== STATE PERSISTENCE ==========

--- Save position of focused window
-- @param positionID string Configuration ID where window was moved
-- @return boolean true if saved successfully
function obj:saveCurrentPosition(positionID)
    local win = hs.window.focusedWindow()

    if not win then
        print("[MonitorWindowApp] No window in focus to save")
        return false
    end

    -- Validate that positionID exists in configuration
    local config = getMonitorConfigByPositionID(positionID)
    if not config then
        print(string.format("[MonitorWindowApp] ⚠️  Invalid positionID: '%s' not found in configuration", positionID))
        return false
    end

    local data = storageManager.load("MonitorWindowApp")
    if not data.window_positions then
        data.window_positions = {}
    end

    local windowId = tostring(win:id())
    local app = win:application()
    local appName = app and app:name() or "Unknown"

    -- Determine current number of screens
    local screens = hs.screen.allScreens()
    local nscreenw = #screens
    print(string.format("[Save] Detected %d screen(s)", nscreenw))

    -- Initialize array for this window if it doesn't exist
    if not data.window_positions[windowId] then
        data.window_positions[windowId] = {}
    end

    -- If it was previously an object (old format), convert to array
    if type(data.window_positions[windowId]) ~= "table" or data.window_positions[windowId].position_id then
        print("[Save] Converting old format to array for ID: " .. windowId)
        data.window_positions[windowId] = {}
    end

    local entries = data.window_positions[windowId]
    local found = false

    -- Update existing entry for this nscreenw
    for i, entry in ipairs(entries) do
        if entry.nscreenw == nscreenw then
            print(string.format("[Save] Updating existing entry for %d screens (Index: %d)", nscreenw, i))
            entry.position_id = positionID
            entry.app_name = appName
            found = true
            break
        end
    end

    -- Add new entry if not found
    if not found then
        print(string.format("[Save] Creating new entry for %d screens", nscreenw))
        table.insert(entries, {
            nscreenw = nscreenw,
            position_id = positionID,
            app_name = appName
        })
    end

    local success = storageManager.save("MonitorWindowApp", data)
    if success then
        print(string.format("[Save] Success! %s (ID:%s) -> Config: %s [Screens: %d]",
            appName, windowId, positionID, nscreenw))
    else
        print("[Save] Failed to write to storage!")
    end

    self:scheduleGarbageCollection()
    return success
end

--- Restore positions of all open windows
-- @return self
function obj:loadPosition()
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
    local nscreenw = #hs.screen.allScreens()
    print(string.format("[Load] Restoring for %d screen(s)", nscreenw))

    -- Match by window_id
    for _, win in ipairs(allWindows) do
        if win:isStandard() and win:isVisible() then
            local windowId = tostring(win:id())
            local entries = data.window_positions[windowId]

            if entries and type(entries) == "table" then
                local positionID = nil
                local appName = "Unknown"

                -- Find entry for current nscreenw
                for _, entry in ipairs(entries) do
                    if entry.nscreenw == nscreenw then
                        positionID = entry.position_id
                        appName = entry.app_name
                        break
                    end
                end

                if positionID then
                    local config = getMonitorConfigByPositionID(positionID)
                    if config then
                        moveWindowToMonitorInternal(config, win)
                        restored = restored + 1
                        print(string.format("[Load] %s (ID:%s) -> Config: %s",
                            appName, windowId, positionID))
                    end
                end
            end
        end
    end

    hs.notify.new({
        title = "MonitorWindowApp",
        informativeText = string.format("%d window(s) restored", restored)
    }):send()

    self:scheduleGarbageCollection()
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
    for windowId, entries in pairs(data.window_positions) do
        -- If window ID is no longer active, remove the ENTIRE entry (all screen configs)
        -- The user specified: "O garbagecoletor apenas poderá apagar o APP não usado, e não o objeto de nscreenw não usado."
        -- This means if the window/app is closed, we remove its data.
        -- But we do NOT remove entries for nscreenw=2 just because we are currently on nscreenw=3.

        if not activeWindows[windowId] then
            data.window_positions[windowId] = nil
            removed = removed + 1
            print(string.format("[GC] Removed stale ID: %s", windowId))
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

    -- Load configuration internally
    self:loadConfig()

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
