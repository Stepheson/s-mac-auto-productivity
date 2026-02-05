local module = {}
local spoonPath = hs.spoons.scriptPath() or ""
local iconPath

iconPath = spoonPath .. "images/create_file_icon.png"
module.pathCreateFile = iconPath
module.iconCreateFile = hs.image.imageFromPath(iconPath)

iconPath = spoonPath .. "images/hidden_file_icon.png"
--module.pathCreateFile = iconPath
module.iconHidden_file = hs.image.imageFromPath(iconPath)

iconPath = spoonPath .. "images/screenshot_icon.png"
--module.pathCreateFile = iconPath
module.iconScreenshot = hs.image.imageFromPath(iconPath)

iconPath = spoonPath .. "images/autoHidden_dock_icon.png"
--module.pathCreateFile = iconPath
module.iconAutoHidden_dock = hs.image.imageFromPath(iconPath)

iconPath = spoonPath .. "images/quickChar_icon.png"
--module.pathSymbols = iconPath
module.iconQuickChar = hs.image.imageFromPath(iconPath)

return module
