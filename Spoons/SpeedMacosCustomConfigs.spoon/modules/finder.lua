local obj = {}
obj.name = "Finder"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.description = "Manages Finder visibility and hidden files."
obj.parameter_schema = { "native", "forced" }

-- Function to return menu items (Schema)
function obj.getMenuItems(options)
    options = options or {}
    local mode = options.hiddenfiles or "native"

    local funcToggle = obj.toggleHiddenFiles
    if mode == "forced" then
        funcToggle = obj.toggleHiddenFilesForced
    end

    local isShown = obj.getHiddenFilesState()

    return {
        {
            type = "toggle",
            label = "Hidden Files: " .. (mode == "forced" and "(Forced)" or "(Native)"),
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
function obj.toggleHiddenFiles()
    local finder = hs.appfinder.appFromName("Finder")
    if finder then
        -- Use the native shortcut: Cmd + Shift + .
        -- This toggles visibility instantly without killing Finder
        hs.eventtap.keyStroke({ "cmd", "shift" }, ".", finder)
        hs.alert.show("Finder: Toggled Hidden Files (Native)")
    else
        hs.alert.show("Finder is not running")
    end
end

-- Function to toggle Hidden Files using Forced Method (Defaults + Killall) - Fallback
function obj.toggleHiddenFilesForced()
    -- We can read the state just to flip it, or just blindly flip based on assumptions?
    -- Better to read the state to flip it correctly.
    local output, status = hs.execute("defaults read com.apple.finder AppleShowAllFiles")
    local currentState = "false"
    if output then
        local cleanOutput = output:gsub("%s+", ""):lower()
        if (cleanOutput == "1" or cleanOutput == "true" or cleanOutput == "yes" or cleanOutput == "on") then
            currentState = "true"
        end
    end

    local newState = (currentState == "true") and "false" or "true"

    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.finder", "AppleShowAllFiles", "-bool", newState }):start()

    local msg = (newState == "true") and "Finder: Hidden Files Shown (Forced)" or "Finder: Hidden Files Hidden (Forced)"
    hs.alert.show(msg)

    hs.task.new("/usr/bin/killall", nil, { "Finder" }):start()

    print("[Finder] Toggled hidden files (Forced mode)")
end

-- Helper to get current hidden files state
function obj.getHiddenFilesState()
    local output = hs.execute("defaults read com.apple.finder AppleShowAllFiles")
    if output then
        local clean = output:gsub("%s+", ""):lower()
        if clean == "1" or clean == "true" or clean == "yes" then
            return true
        end
    end
    return false
end

return obj
