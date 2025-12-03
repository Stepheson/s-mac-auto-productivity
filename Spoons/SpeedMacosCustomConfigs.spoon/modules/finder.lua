local obj = {}

-- Function to show hidden files
function obj.showHiddenFiles()
    hs.task.new("/usr/bin/defaults", nil, {"write", "com.apple.finder", "AppleShowAllFiles", "-bool", "true"}):start()
    hs.alert.show("Finder: Showing Hidden Files")
    hs.task.new("/usr/bin/killall", nil, {"Finder"}):start()
end

-- Function to hide hidden files
function obj.hideHiddenFiles()
    hs.task.new("/usr/bin/defaults", nil, {"write", "com.apple.finder", "AppleShowAllFiles", "-bool", "false"}):start()
    hs.alert.show("Finder: Hiding Hidden Files")
    hs.task.new("/usr/bin/killall", nil, {"Finder"}):start()
end

-- Function to show path bar
function obj.showPathBar()
    hs.task.new("/usr/bin/defaults", nil, {"write", "com.apple.finder", "ShowPathbar", "-bool", "true"}):start()
    hs.alert.show("Finder: Path Bar Enabled")
    hs.task.new("/usr/bin/killall", nil, {"Finder"}):start()
end

-- Function to return menu items
function obj.getMenuItems()
    return {
        {
            text = "Show Hidden Files",
            subText = "defaults write com.apple.finder AppleShowAllFiles -bool true",
            func = obj.showHiddenFiles
        },
        {
            text = "Hide Hidden Files",
            subText = "defaults write com.apple.finder AppleShowAllFiles -bool false",
            func = obj.hideHiddenFiles
        },
        {
            text = "Show Path Bar",
            subText = "defaults write com.apple.finder ShowPathbar -bool true",
            func = obj.showPathBar
        }
    }
end

return obj
