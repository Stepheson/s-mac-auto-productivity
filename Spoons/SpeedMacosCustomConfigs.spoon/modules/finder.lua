local obj = {}

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

-- Function to return menu items
function obj.getMenuItems(options)
    -- Options is a table, e.g. { hiddenfiles = "forced" } handled by the Spoon

    options = options or {}
    local mode = options.hiddenfiles or "native"
    local funcToCall = obj.toggleHiddenFiles
    local menuText = "Toggle Hidden Files"

    if mode == "forced" then
        funcToCall = obj.toggleHiddenFilesForced
        menuText = menuText .. " (Forced)"
    end

    return {
        {
            text = menuText,
            subText = "Toggle visibility of hidden files", -- Static text, no status
            func = funcToCall
        }
    }
end

return obj
