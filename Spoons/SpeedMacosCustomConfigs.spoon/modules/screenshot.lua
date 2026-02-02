local obj = {}
obj.name = "Screenshot"
obj.version = "1.2"
obj.author = "Stepheson Alves"
obj.description = "Manages global screenshot format (PNG/JPG/TIFF/PDF/GIF/HEIC)."
obj.parameter_schema = {}

-- Function to return menu items (Schema)
function obj.getMenuItems(options)
    local current = obj.getCurrentFormat()

    -- Define the radio items (no manual visual indicators needed)ß
    local formatItems = {
        {
            label = "PNG Image",
            description = "Lossless quality (Best for text/UI)",
            value = "png",
            action = function() obj.setFormat("png") end
        },
        {
            label = "JPG Image",
            description = "Compressed (Best for photos/sharing)",
            value = "jpg",
            action = function() obj.setFormat("jpg") end
        },
        {
            label = "HEIC Image",
            description = "Modern efficient compression (macOS Default)",
            value = "heic",
            action = function() obj.setFormat("heic") end
        },
        {
            label = "PDF Document",
            description = "Portable Document Format",
            value = "pdf",
            action = function() obj.setFormat("pdf") end
        },
        {
            label = "TIFF Image",
            description = "High quality lossless (Large file size)",
            value = "tiff",
            action = function() obj.setFormat("tiff") end
        },
        {
            label = "GIF Image",
            description = "Graphics Interchange Format",
            value = "gif",
            action = function() obj.setFormat("gif") end
        }
    }

    local label = "Screenshot Format"
    local knownFormats = { png = true, jpg = true, heic = true, pdf = true, tiff = true, gif = true }
    if knownFormats[current] then
        label = label .. ": " .. current:upper()
    end

    -- Return a Submenu containing a RadioGroup
    return {
        {
            type = "submenu",
            label = label,
            description = "Change system screenshot file type",
            items = {
                {
                    type = "radioGroup",
                    currentValue = current,
                    items = formatItems
                }
            }
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

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

return obj
