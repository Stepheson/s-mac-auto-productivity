local obj = {}
obj.name = "Screenshot"
obj.version = "1.2"
obj.author = "Stepheson Alves"
obj.description = "Manages global screenshot format (PNG/JPG/TIFF/PDF/GIF/HEIC)."
obj.parameter_schema = {}

-- Internal chooser reference to prevent GC
obj.formatChooser = nil

-- Generic function to set screenshot format
function obj.setFormat(formatType)
    local typeUpper = formatType:upper()
    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.screencapture", "type", formatType }):start()
    hs.alert.show("Screenshot: Format set to " .. typeUpper)
    hs.task.new("/usr/bin/killall", nil, { "SystemUIServer" }):start()
end

-- Function to set screenshot format to PNG
function obj.setFormatPNG()
    obj.setFormat("png")
end

-- Function to set screenshot format to JPG
function obj.setFormatJPG()
    obj.setFormat("jpg")
end

-- Function to set screenshot format to TIFF
function obj.setFormatTIFF()
    obj.setFormat("tiff")
end

-- Function to set screenshot format to PDF
function obj.setFormatPDF()
    obj.setFormat("pdf")
end

-- Function to set screenshot format to GIF
function obj.setFormatGIF()
    obj.setFormat("gif")
end

-- Function to set screenshot format to HEIC
function obj.setFormatHEIC()
    obj.setFormat("heic")
end

-- Function to get current format
function obj.getCurrentFormat()
    local output = hs.execute("defaults read com.apple.screencapture type")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "png"                      -- Default assumption if missing
end

-- Submenu selection handler
function obj.onFormatChoice(choice)
    if not choice then return end

    -- Generic handling based on value
    if choice.value then
        obj.setFormat(choice.value)
    end
end

-- Function to open the format selection submenu
function obj.showFormatMenu()
    if not obj.formatChooser then
        obj.formatChooser = hs.chooser.new(obj.onFormatChoice)
        obj.formatChooser:placeholderText("Select Screenshot Format")
    end

    local current = obj.getCurrentFormat()

    local choices = {
        {
            text = "PNG Image",
            subText = "Lossless quality (Best for text/UI)",
            value = "png"
        },
        {
            text = "JPEG Image",
            subText = "Compressed (Best for photos/sharing)",
            value = "jpg"
        },
        {
            text = "HEIC Image",
            subText = "Modern efficient compression (macOS Default)",
            value = "heic"
        },
        {
            text = "PDF Document",
            subText = "Portable Document Format",
            value = "pdf"
        },
        {
            text = "TIFF Image",
            subText = "High quality lossless (Large file size)",
            value = "tiff"
        },
        {
            text = "GIF Image",
            subText = "Graphics Interchange Format",
            value = "gif"
        }
    }

    -- Mark current with a visual indicator
    for _, item in ipairs(choices) do
        if item.value == current then
            item.text = item.text .. " (Current)"
        end
        item.valid = true
    end

    obj.formatChooser:choices(choices)
    obj.formatChooser:show()
end

-- Function to return menu items
function obj.getMenuItems(options)
    local current = obj.getCurrentFormat()
    local label = "Screenshot Format"

    -- List of known formats to display
    local knownFormats = { png = true, jpg = true, heic = true, pdf = true, tiff = true, gif = true }

    if knownFormats[current] then
        label = label .. " (Current: " .. current:upper() .. ")"
    else
        -- Fallback for unknown or empty format
        if current and current ~= "" then
            label = label .. " (Current: " .. current .. ")"
        end
    end

    return {
        {
            text = label,
            subText = "Change system screenshot file type...",
            func = obj.showFormatMenu
        }
    }
end

return obj
