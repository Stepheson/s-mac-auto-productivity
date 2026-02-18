local module = {}
module.name = "Finder"
module.version = "1.1"
module.author = "Stepheson Alves"
module.description = "Manages Finder visibility and hidden files."
module.parameter_schema = { "native", "forced" }

-- State Cache
module.state = {
    isVisible = false,
    isLoaded = false
}

local systemUtils = require("common.system_utils")

-- Function to return menu items (Schema)
function module.getMenuItems(options)
    options = options or {}
    local mode = options.hiddenfiles or "native"

    local funcToggle = module.toggleHiddenFiles
    if mode == "forced" then
        funcToggle = module.toggleHiddenFilesForced
    end

    local isShown = module.state.isVisible

    return {
        {
            type = "toggle",
            label = "Hidden Files: " .. (mode == "forced" and "(Forced)" or "(Native)"),
            image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/hidden_file_icon.png"),
            description = "Toggle visibility of hidden files",
            currentIndex = isShown and 2 or 1, -- 1=Hidden, 2=Shown
            states = {
                {
                    label = "Hidden",
                    action = funcToggle -- Will toggle to Show
                },
                {
                    label = "Shown",
                    action = funcToggle -- Will toggle to Hide
                }
            }
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
---
-- Function to toggle Hidden Files using Native Shortcut (No Kill) - Preferred
function module.toggleHiddenFiles()
    local finder = hs.appfinder.appFromName("Finder")
    if finder then
        -- Use the native shortcut: Cmd + Shift + .
        -- This toggles visibility instantly without killing Finder
        hs.eventtap.keyStroke({ "cmd", "shift" }, ".", finder)

        -- Optimistic Update (Assuming toggle worked)
        module.state.isVisible = not module.state.isVisible
        local msg = module.state.isVisible and "Finder: Hidden Files Shown (Native)" or
        "Finder: Hidden Files Hidden (Native)"
        hs.alert.show(msg)

        -- Refresh cache after delay to confirm actual usage
        hs.timer.doAfter(1.0, module.updateCache)
    else
        hs.alert.show("Finder is not running")
    end
end

-- Function to toggle Hidden Files using Forced Method (Defaults + Killall) - Fallback
function module.toggleHiddenFilesForced()
    -- 1. Optimistic Update
    local newState = not module.state.isVisible
    module.state.isVisible = newState

    local newStateStr = newState and "true" or "false"
    local msg = newState and "Finder: Hidden Files Shown (Forced)" or "Finder: Hidden Files Hidden (Forced)"

    -- 2. Immediate Feedback
    hs.alert.show(msg)

    -- 3. Async Write
    hs.task.new("/usr/bin/defaults", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            -- 4. Apply Changes
            systemUtils.killApp("Finder")
            print("Finder: Async toggle complete (" .. newStateStr .. ")")
        else
            print("Finder: Error writing defaults: " .. tostring(stdErr))
        end
    end, { "write", "com.apple.finder", "AppleShowAllFiles", "-bool", newStateStr }):start()
end

-- Async State Initialization/Refresh
function module.updateCache()
    hs.task.new("/usr/bin/defaults", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut then
            local clean = stdOut:gsub("%s+", ""):lower()
            module.state.isVisible = (clean == "1" or clean == "true" or clean == "yes" or clean == "on")
            module.state.isLoaded = true
            -- print("Finder: Cache updated. Visible=" .. tostring(module.state.isVisible))
        else
            -- Default to Hidden if key doesn't exist or error
            -- module.state.isVisible = false
        end
    end, { "read", "com.apple.finder", "AppleShowAllFiles" }):start()
end

-- Initial Load
module.updateCache()

return module
