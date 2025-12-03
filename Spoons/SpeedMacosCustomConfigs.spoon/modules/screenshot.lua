local obj = {}

-- Function to set screenshot format to PNG
function obj.setFormatPNG()
    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.screencapture", "type", "png" }):start()
    hs.alert.show("Screenshot: Format set to PNG")
    hs.task.new("/usr/bin/killall", nil, { "SystemUIServer" }):start()
end

-- Function to set screenshot format to JPG
function obj.setFormatJPG()
    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.screencapture", "type", "jpg" }):start()
    hs.alert.show("Screenshot: Format set to JPG")
    hs.task.new("/usr/bin/killall", nil, { "SystemUIServer" }):start()
end

-- Function to return menu items
function obj.getMenuItems()
    return {
        {
            text = "Set Screenshot Format to PNG",
            subText = "defaults write com.apple.screencapture type png",
            func = obj.setFormatPNG
        },
        {
            text = "Set Screenshot Format to JPG",
            subText = "defaults write com.apple.screencapture type jpg",
            func = obj.setFormatJPG
        }
    }
end

return obj
