-- autoReload.lua
-- Independent module for watching configuration files and triggering reload
-- Usage: require("common.auto_reload").start()

local M = {}

local configWatcher = nil
local reloadTimer = nil

-- Private reload function
local function reloadConfig(files)
    local doReload = false
    for _, file in pairs(files) do
        -- Ignore storage directory (contains position data that shouldn't trigger reload)
        if not file:match("Spoons/storage_configs/") and (file:sub(-4) == ".lua" or file:sub(-5) == ".json") then
            doReload = true
            print(string.format("[AutoReload] Change detected: %s", file))
        end
    end

    if doReload then
        -- Debounce: wait 0.5s before reloading to avoid cascading reloads
        if reloadTimer then
            reloadTimer:stop()
        end
        reloadTimer = hs.timer.doAfter(0.5, function()
            print("[AutoReload] Reloading Hammerspoon...")
            hs.reload()
        end)
    end
end

-- Public API

--- Start watching for configuration changes
function M.start()
    if configWatcher then
        return
    end

    configWatcher = hs.pathwatcher.new(hs.configdir, reloadConfig):start()
    print("[AutoReload] Watcher started")
end

--- Stop watching for configuration changes
function M.stop()
    if configWatcher then
        configWatcher:stop()
        configWatcher = nil
        print("[AutoReload] Watcher stopped")
    end
end

return M
