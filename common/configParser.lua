local M = {}

-- Configuration cache
local cachedConfig = nil

-- ========== LOADING AND PARSING ==========

--- Load and parse JSON configuration file
-- @param filePath string Path to ProfileSettings.json
-- @return table Parsed configuration or empty table on error
function M.loadConfig(filePath)
    local file = io.open(filePath, "r")
    if not file then
        print("⚠️  ProfileSettings.json not found at: " .. filePath)
        print("   Using default empty configuration")
        cachedConfig = {}
        return cachedConfig
    end

    local content = file:read("*all")
    file:close()

    local success, config = pcall(hs.json.decode, content)
    if not success then
        print("❌ Error parsing ProfileSettings.json:")
        print("   " .. tostring(config))
        print("   Using default empty configuration")
        cachedConfig = {}
        return cachedConfig
    end

    cachedConfig = config
    print("✅ ProfileSettings.json loaded successfully")

    return cachedConfig
end

return M
