local module = {}
local spoonPath = hs.spoons.scriptPath() or ""

-- Helper generic method to load icons
-- Return both the absolute path and the hs.image object
local function loadIcon(fileName)
    local fullPath = spoonPath .. "images/" .. fileName
    local image = hs.image.imageFromPath(fullPath)
    return image, fullPath
end

-- Create File (Needs path for AppleScript dialog)
module.iconCreateFile,
module.pathCreateFile
                           = loadIcon("create_file_icon.png")

-- Other Modules
module.iconQuickChar       = loadIcon("quickChar_icon.png")
module.iconHidden_file     = loadIcon("hidden_file_icon.png")
module.iconScreenshot      = loadIcon("screenshot_icon.png")
module.iconAutoHidden_dock = loadIcon("autoHidden_dock_icon.png")
-- module.iconHelp            = loadIcon("help_icon.png")

return module
