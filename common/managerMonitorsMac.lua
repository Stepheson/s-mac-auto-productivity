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

--- Get only visible windows on a specific monitor
-- Filters by mainWindow when possible to get the main window of each app
-- @param screenId userdata Screen ID to filter windows
-- @return table Array of {window, app, name} for visible windows
function M.getVisibleWindowsOnScreen(screenId)
    local visibleWindows = {}
    local seenApps = {}

    local allWindows = hs.window.orderedWindows()

    for _, win in ipairs(allWindows) do
        if win:isStandard() and win:isVisible() then
            local winScreen = win:screen()
            local app = win:application()

            if winScreen and winScreen:id() == screenId and app then
                local appName = app:name()

                if not seenApps[appName] then
                    seenApps[appName] = true
                    table.insert(visibleWindows, {
                        window = win,
                        app = app,
                        name = appName
                    })
                end
            end
        end
    end

    return visibleWindows
end

-- ========== MONITOR SEARCH ==========

--- Find monitor by exact name
-- @param monitorName string Exact monitor name
-- @return userdata|nil Screen object or nil if not found
function M.getMonitorByName(monitorName)
    local screens = hs.screen.allScreens()

    for _, screen in ipairs(screens) do
        local screenName = screen:name()
        if screenName == monitorName then
            return screen
        end
    end

    return nil
end

--- Get list of all connected monitors with information
-- @return table Array of monitor information objects
local function getAllConnectedMonitors()
    local screens = hs.screen.allScreens()
    local monitors = {}

    for _, screen in ipairs(screens) do
        table.insert(monitors, {
            name = screen:name(),
            id = screen:id(),
            frame = screen:frame(),
            isPrimary = (screen == hs.screen.primaryScreen())
        })
    end

    return monitors
end

--- Print list of connected monitors (useful for debugging)
function M.printConnectedMonitors()
    local monitors = getAllConnectedMonitors()

    print("=== Connected Monitors ===")
    for i, mon in ipairs(monitors) do
        local primary = mon.isPrimary and " (PRIMARY)" or ""
        print(string.format("%d. %s%s", i, mon.name, primary))
        print(string.format("   ID: %s", mon.id))
        print(string.format("   Resolution: %dx%d", mon.frame.w, mon.frame.h))
    end
    print("==========================")
end

return M
