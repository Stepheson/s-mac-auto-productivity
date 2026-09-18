local M = {}

-- ========== WINDOW AND FOCUS UTILITIES ==========

--- Get complete information about focused window and monitor
-- @return table|nil Information table with window, app, screen, screenId, screenName or nil if no focus
function M.getFocusedWindowInfo()
    local win = hs.window.focusedWindow()
    if not win then
        return nil
    end

    local screen = win:screen()
    if not screen then
        return nil
    end

    return {
        window = win,
        app = win:application(),
        screen = screen,
        screenId = screen:id(),
        screenName = screen:name() or "Unknown Monitor"
    }
end

--- Get visible windows on a specific monitor with filtering and stable sorting
-- @param screenId userdata Screen ID to filter windows
-- @param mode number 0=All, 1=Apps Only, 2=Instances Only (Current App)
-- @return table Array of {window, app, name} for visible windows
function M.getVisibleWindowsOnScreen(screenId, mode)
    local visibleWindows = {}
    local seenApps = {}
    local focusedApp = nil

    -- Determine focused app for Mode 2
    if mode == 2 then
        local win = hs.window.focusedWindow()
        if win then focusedApp = win:application() end
    end

    -- 1. Collect all valid windows on screen
    local allWindows = hs.window.allWindows() -- Use allWindows for stable base, we will sort manually

    for _, win in ipairs(allWindows) do
        if win:isStandard() and win:isVisible() then
            local winScreen = win:screen()
            local app = win:application()

            if winScreen and winScreen:id() == screenId and app then
                local appName = app:name()
                local shouldAdd = false

                if mode == 1 then
                    -- Mode 1: Apps Only (Unique)
                    if not seenApps[appName] then
                        seenApps[appName] = true
                        shouldAdd = true
                    end
                elseif mode == 2 then
                    -- Mode 2: Instances Only (Current App)
                    if focusedApp and app:bundleID() == focusedApp:bundleID() then
                        shouldAdd = true
                    end
                else
                    -- Mode 0 (Default): All Windows
                    shouldAdd = true
                end

                if shouldAdd then
                    table.insert(visibleWindows, {
                        window = win,
                        app = app,
                        name = appName,
                        id = win:id()
                    })
                end
            end
        end
    end

    -- 2. Stable Sort: App Name (A-Z) -> Window ID (Ascending)
    -- This ensures the order doesn't change when focus changes (Z-order)
    table.sort(visibleWindows, function(a, b)
        if a.name == b.name then
            return a.id < b.id
        else
            return a.name < b.name
        end
    end)

    return visibleWindows
end

-- ========== MONITOR SEARCH & CACHE ==========

local cachedScreens = nil
local screenWatcher = nil

--- Refresh internal screen cache from hardware
local function refreshScreens()
    cachedScreens = hs.screen.allScreens()
    return cachedScreens
end

--- Initialize screen change watcher if not already running
local function initWatcher()
    if not screenWatcher then
        screenWatcher = hs.screen.watcher.new(function()
            refreshScreens()
        end)
        screenWatcher:start()
    end
end

--- Get all connected screens (cached by default, with automatic event-driven updates)
-- @param forceRefresh boolean (optional) Force query to hardware
-- @return table Array of hs.screen objects
function M.getAllScreens(forceRefresh)
    initWatcher()
    if forceRefresh or not cachedScreens then
        return refreshScreens()
    end
    return cachedScreens
end

--- Get monitor object by name (string) or list of candidate names (table)
-- Uses memory cache for instant resolution, with automatic on-demand hardware refresh if not found
-- @param monitorName string|table Name or array of candidate names to find
-- @return userdata|nil hs.screen object or nil if not found
function M.getMonitorByName(monitorName)
    if not monitorName then return nil end

    local names = type(monitorName) == "table" and monitorName or { monitorName }

    local function findIn(screens)
        for _, targetName in ipairs(names) do
            for _, s in ipairs(screens) do
                if s:name() == targetName then
                    return s
                end
            end
        end
        return nil
    end

    -- 1. Try cache (0ms, fast path)
    local screen = findIn(M.getAllScreens())

    -- 2. Fallback on-demand: query hardware if not found (handles sleep/wake or newly attached display)
    if not screen then
        screen = findIn(M.getAllScreens(true))
    end

    return screen
end

--- Stop screen watcher and clear cache
function M.stopWatcher()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    cachedScreens = nil
end

--- Debug: Print all connected monitors
function M.printConnectedMonitors()
    local screens = M.getAllScreens(true)
    print("\n[DEBUG] Connected Monitors:")
    for i, s in ipairs(screens) do
        print(string.format("  %d. Name: '%s' | ID: %s", i, s:name(), s:id()))
    end
    print("---------------------------------------------------\n")
end

--- Calculate centered coordinates for a window based on monitor orientation
-- @param widthRatioLandscape number Width ratio for landscape (default 0.25)
-- @param widthRatioPortrait number Width ratio for portrait (default 0.60)
-- @param verticalOffsetRatio number Vertical position ratio from top (default 0.35)
-- @return table containing widthPct and centerPoint (hs.geometry.point)
function M.getCenteredCoordinates(widthRatioLandscape, widthRatioPortrait, verticalOffsetRatio)
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    local isPortrait = frame.h > frame.w

    local widthPct = widthRatioLandscape or 0.25
    if isPortrait then
        widthPct = widthRatioPortrait or 0.60
    end

    local offset = verticalOffsetRatio or 0.35

    local winWidth = frame.w * widthPct
    local x = frame.x + (frame.w - winWidth) / 2
    local y = frame.y + (frame.h * offset)

    return {
        widthPct = widthPct,
        centerPoint = hs.geometry.point(x, y)
    }
end

return M
