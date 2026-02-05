local module = {}
module.name = "Screenshot"
module.version = "1.2"
module.author = "Stepheson Alves"
module.description = "Manages global screenshot format (PNG/JPG/TIFF/PDF/GIF/HEIC)."
module.parameter_schema = {}

local systemUtils = require("common.systemUtils")
local iconsManager = require("iconsManager")

-- Function to return menu items (Schema)
function module.getMenuItems(options)
    local current = module.getCurrentFormat()

    -- Define the radio items (no manual visual indicators needed)
    local formatItems = {
        {
            label = "PNG Image",
            description = "Lossless quality (Best for text/UI)",
            value = "png",
            action = function() module.setFormat("png") end
        },
        {
            label = "JPG Image",
            description = "Compressed (Best for photos/sharing)",
            value = "jpg",
            action = function() module.setFormat("jpg") end
        },
        {
            label = "HEIC Image",
            description = "Modern efficient compression (macOS Default)",
            value = "heic",
            action = function() module.setFormat("heic") end
        },
        {
            label = "PDF Document",
            description = "Portable Document Format",
            value = "pdf",
            action = function() module.setFormat("pdf") end
        },
        {
            label = "TIFF Image",
            description = "High quality lossless (Large file size)",
            value = "tiff",
            action = function() module.setFormat("tiff") end
        },
        {
            label = "GIF Image",
            description = "Graphics Interchange Format",
            value = "gif",
            action = function() module.setFormat("gif") end
        }
    }

    local label = "Screenshot Format"
    local knownFormats = { png = true, jpg = true, heic = true, pdf = true, tiff = true, gif = true }
    if knownFormats[current] then
        label = label .. ": " .. current:upper()
    end

    -- Return a Submenu Item that contains the list of formats
    return {
        {
            type = "submenu", -- Handled by EasyLoadModules compatibility layer if needed, or WindowGenerator
            -- WindowGenerator expects 'menu' or 'items' for submenus.
            -- EasyLoadModules maps 'label' -> 'text'.
            label = label,
            description = "Change system screenshot file type",
            image = iconsManager.iconScreenshot,
            menu = formatItems -- Directly pass the list of items as the submenu content
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Internal chooser reference to prevent GC
module.formatChooser = nil

-- Generic function to set screenshot format
function module.setFormat(formatType)
    local typeUpper = formatType:upper()
    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.screencapture", "type", formatType }):start()
    hs.alert.show("Screenshot: Format set to " .. typeUpper)
    systemUtils.killApp("SystemUIServer")
end

-- Function to set screenshot format to PNG
function module.setFormatPNG()
    module.setFormat("png")
end

-- Function to set screenshot format to JPG
function module.setFormatJPG()
    module.setFormat("jpg")
end

-- Function to set screenshot format to TIFF
function module.setFormatTIFF()
    module.setFormat("tiff")
end

-- Function to set screenshot format to PDF
function module.setFormatPDF()
    module.setFormat("pdf")
end

-- Function to set screenshot format to GIF
function module.setFormatGIF()
    module.setFormat("gif")
end

-- Function to set screenshot format to HEIC
function module.setFormatHEIC()
    module.setFormat("heic")
end

-- Function to get current format
function module.getCurrentFormat()
    local output = hs.execute("defaults read com.apple.screencapture type")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "png"                      -- Default assumption if missing
end

return module
