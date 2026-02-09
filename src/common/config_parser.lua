local M = {}
local fileManager = require("common.file_manager")

-- Configuration cache
local cachedConfig = nil

-- ========== LOADING AND PARSING ==========

--- Load and parse JSON configuration file
-- @param filePath string Path to ProfileSettings.json
-- @return table Parsed configuration or empty table on error
function M.loadConfig(filePath)
    local content = fileManager.readFile(filePath)

    if not content then
        print("⚠️  Config file not found or unreadable: " .. filePath)
        print("   Using default empty configuration")
        cachedConfig = {}
        return cachedConfig
    end

    local success, config = pcall(hs.json.decode, content)
    if not success then
        print("❌ Error parsing JSON config at: " .. filePath)
        print("   " .. tostring(config))
        print("   Using default empty configuration")
        cachedConfig = {}
        return cachedConfig
    end

    cachedConfig = config
    print("✅ Config loaded successfully: " .. filePath:match("^.+/(.+)$")) -- Print just filename

    return cachedConfig
end

return M
