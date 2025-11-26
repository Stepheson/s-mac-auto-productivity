-- storageManager.lua
-- Generic JSON storage manager for Spoons
-- Provides serialization, deserialization, and file I/O operations
-- Follows SOLID principles: Single Responsibility for data persistence

local storageManager = {}

-- Private constants
local STORAGE_DIR = "storage"
local logger = hs.logger.new('StorageManager', 'info')

-- ============================================================================
-- PRIVATE METHODS
-- ============================================================================

--- Get the base path of the Hammerspoon configuration
-- @return string Absolute path to Hammerspoon config directory
local function getBasePath()
    local configdir = hs.configdir
    if not configdir then
        logger.e("Failed to get Hammerspoon config directory")
        return nil
    end
    return configdir
end

--- Get the full path to the storage directory
-- @return string Absolute path to storage directory
local function getStoragePath()
    local basePath = getBasePath()
    if not basePath then
        return nil
    end
    return basePath .. "/" .. STORAGE_DIR
end

--- Get the full file path for a given Spoon ID
-- @param spoonId string The Spoon identifier (used as filename)
-- @return string|nil Full path to JSON file or nil on error
local function getFilePath(spoonId)
    if not spoonId or type(spoonId) ~= "string" or spoonId == "" then
        logger.e("Invalid spoonId: must be a non-empty string")
        return nil
    end

    local storagePath = getStoragePath()
    if not storagePath then
        return nil
    end

    return storagePath .. "/" .. spoonId .. ".json"
end

--- Ensure storage directory exists
-- @return boolean true if directory exists or was created successfully
local function ensureStorageDir()
    local storagePath = getStoragePath()
    if not storagePath then
        return false
    end

    -- Check if directory exists
    local attributes = hs.fs.attributes(storagePath)
    if attributes then
        if attributes.mode == "directory" then
            return true
        else
            logger.e("Storage path exists but is not a directory: " .. storagePath)
            return false
        end
    end

    -- Create directory
    local success, error = hs.fs.mkdir(storagePath)
    if success then
        logger.i("Created storage directory: " .. storagePath)
        return true
    else
        logger.e("Failed to create storage directory: " .. (error or "unknown error"))
        return false
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Check if a storage file exists for a given Spoon
-- @param spoonId string The Spoon identifier
-- @return boolean true if file exists
function storageManager.exists(spoonId)
    local filePath = getFilePath(spoonId)
    if not filePath then
        return false
    end

    local attributes = hs.fs.attributes(filePath)
    return attributes ~= nil and attributes.mode == "file"
end

--- Save data to JSON file (Serialization)
-- Runs asynchronously to avoid blocking main thread
-- @param spoonId string The Spoon identifier
-- @param dataTable table The data to save (must be a Lua table)
-- @return boolean true if save was successful
function storageManager.save(spoonId, dataTable)
    -- Validate inputs
    if not spoonId or type(spoonId) ~= "string" or spoonId == "" then
        logger.e("Invalid spoonId for save operation")
        return false
    end

    if not dataTable or type(dataTable) ~= "table" then
        logger.e("Invalid data: must be a table")
        return false
    end

    -- Get file path
    local filePath = getFilePath(spoonId)
    if not filePath then
        return false
    end

    -- Ensure directory exists
    if not ensureStorageDir() then
        return false
    end

    -- Serialize to JSON
    local success, jsonString = pcall(hs.json.encode, dataTable, true)
    if not success then
        logger.e("Failed to serialize data to JSON: " .. tostring(jsonString))
        return false
    end

    -- Write to file (synchronous for simplicity and reliability)
    local file, err = io.open(filePath, "w")
    if not file then
        logger.e("Failed to open file for writing: " .. (err or "unknown error"))
        return false
    end

    file:write(jsonString)
    file:close()

    logger.i(string.format("[%s] Data saved successfully to %s", spoonId, filePath))
    return true
end

--- Load data from JSON file (Deserialization)
-- @param spoonId string The Spoon identifier
-- @return table Data loaded from file, or empty table {} on error/missing file
function storageManager.load(spoonId)
    -- Validate input
    if not spoonId or type(spoonId) ~= "string" or spoonId == "" then
        logger.e("Invalid spoonId for load operation")
        return {}
    end

    -- Get file path
    local filePath = getFilePath(spoonId)
    if not filePath then
        return {}
    end

    -- Check if file exists
    if not storageManager.exists(spoonId) then
        logger.w(string.format("[%s] Storage file does not exist: %s", spoonId, filePath))
        return {}
    end

    -- Read file
    local file, err = io.open(filePath, "r")
    if not file then
        logger.e("Failed to open file for reading: " .. (err or "unknown error"))
        return {}
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        logger.w("File is empty: " .. filePath)
        return {}
    end

    -- Deserialize JSON
    local success, dataTable = pcall(hs.json.decode, content)
    if not success then
        logger.e("Failed to parse JSON from file: " .. tostring(dataTable))
        logger.e("File content: " .. content)
        return {}
    end

    logger.i(string.format("[%s] Data loaded successfully from %s", spoonId, filePath))
    return dataTable or {}
end

return storageManager
