local obj = {}
obj.name = "Screenshot"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.description = "Manages global screenshot format (PNG/JPG)."
obj.parameter_schema = {}

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

-- Function to get current format
function obj.getCurrentFormat()
    local output, status, type, rc = hs.execute("defaults read com.apple.screencapture type")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return ""
end

-- Function to return menu items
function obj.getMenuItems()
    local current = obj.getCurrentFormat()
    local pngPrefix = (current == "png") and "(*) " or "( ) "
    local jpgPrefix = (current == "jpg") and "(*) " or "( ) "

    return {
        {
            text = pngPrefix .. "Set Screenshot Format to PNG",
            subText = "defaults write com.apple.screencapture type png",
            func = obj.setFormatPNG
        },
        {
            text = jpgPrefix .. "Set Screenshot Format to JPG",
            subText = "defaults write com.apple.screencapture type jpg",
            func = obj.setFormatJPG
        }
    }
end

return obj
