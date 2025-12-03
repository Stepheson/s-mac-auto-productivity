local obj = {}

-- Function to show hidden files
function obj.showHiddenFiles()
    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.finder", "AppleShowAllFiles", "-bool", "true" }):start()
    hs.alert.show("Finder: Showing Hidden Files")
    hs.task.new("/usr/bin/killall", nil, { "Finder" }):start()
end

-- Function to hide hidden files
-- Function to toggle Hidden Files
function obj.toggleHiddenFiles()
    local currentState = obj.getHiddenFilesState()
    local newState = (currentState == "1" or currentState == "true") and "false" or "true"

    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.finder", "AppleShowAllFiles", "-bool", newState }):start()

    local msg = (newState == "true") and "Finder: Hidden Files Shown" or "Finder: Hidden Files Hidden"
    hs.alert.show(msg)

    hs.task.new("/usr/bin/killall", nil, { "Finder" }):start()
end

-- Function to toggle Path Bar
function obj.togglePathBar()
    local currentState = obj.getPathBarState()
    local newState = (currentState == "1" or currentState == "true") and "false" or "true"

    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.finder", "ShowPathbar", "-bool", newState }):start()

    local msg = (newState == "true") and "Finder: Path Bar Shown" or "Finder: Path Bar Hidden"
    hs.alert.show(msg)

    hs.task.new("/usr/bin/killall", nil, { "Finder" }):start()
end

-- Function to get hidden files state
function obj.getHiddenFilesState()
    local output, status = hs.execute("defaults read com.apple.finder AppleShowAllFiles")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "0"                        -- Default to hidden (false/0)
end

-- Function to get path bar state
function obj.getPathBarState()
    local output, status = hs.execute("defaults read com.apple.finder ShowPathbar")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "0"                        -- Default to hidden (false/0)
end

-- Function to return menu items
function obj.getMenuItems()
    local hiddenState = obj.getHiddenFilesState()
    local pathBarState = obj.getPathBarState()

    local isHiddenShown = (hiddenState == "1" or hiddenState == "true")
    local isPathBarShown = (pathBarState == "1" or pathBarState == "true")

    local hiddenPrefix = isHiddenShown and "(*) " or "( ) "
    local pathBarPrefix = isPathBarShown and "(*) " or "( ) "

    return {
        {
            text = hiddenPrefix .. "Toggle Hidden Files",
            subText = "Current: " .. (isHiddenShown and "Shown" or "Hidden"),
            func = obj.toggleHiddenFiles
        },
        {
            text = pathBarPrefix .. "Toggle Path Bar",
            subText = "Current: " .. (isPathBarShown and "Shown" or "Hidden"),
            func = obj.togglePathBar
        }
    }
end

return obj
