local module = {}
module.name = "Dock"
module.version = "1.1"
module.author = "Stepheson Alves"
module.description = "Manages Dock auto-hide settings."
module.parameter_schema = {}

-- State Cache
module.state = {
    isEnabled = false,
    isLoaded = false
}

local systemUtils = require("common.system_utils")

-- Function to return menu items (Schema)
function module.getMenuItems()
    -- Optimistic Read: Return cached state immediately
    local isEnabled = module.state.isEnabled

    return {
        {
            type = "toggle",
            label = "Dock Auto-Hide",
            image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/autoHidden_dock_icon.png"),
            description = "Toggle Dock auto-hide setting",
            currentIndex = isEnabled and 2 or 1, -- 1=Disabled, 2=Enabled
            states = {
                {
                    label = "Disabled",
                    action = module.toggleDockAutoHide
                },
                {
                    label = "Enabled",
                    action = module.toggleDockAutoHide
                }
            }
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Function to toggle Dock auto-hide (Optimistic & Async)
function module.toggleDockAutoHide()
    -- 1. Optimistic Update
    local newState = not module.state.isEnabled
    module.state.isEnabled = newState

    local newStateStr = newState and "true" or "false"
    local msg = newState and "Dock: Auto-Hide Enabled" or "Dock: Auto-Hide Disabled"

    -- 2. Immediate Feedback
    hs.alert.show(msg)

    -- 3. Async Write
    hs.task.new("/usr/bin/defaults", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            -- 4. Apply Changes
            systemUtils.killApp("Dock")
            print("Dock: Async toggle complete (" .. newStateStr .. ")")
        else
            print("Dock: Error writing defaults: " .. tostring(stdErr))
            -- Revert state on failure? For now, we assume success or user will retry.
        end
    end, { "write", "com.apple.dock", "autohide", "-bool", newStateStr }):start()
end

-- Async State Initialization/Refresh
function module.updateCache()
    hs.task.new("/usr/bin/defaults", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut then
            local clean = stdOut:gsub("%s+", "")
            module.state.isEnabled = (clean == "1" or clean == "true")
            module.state.isLoaded = true
            -- print("Dock: Cache updated. AutoHide=" .. tostring(module.state.isEnabled))
        end
    end, { "read", "com.apple.dock", "autohide" }):start()
end

-- Initial Load
module.updateCache()

return module
