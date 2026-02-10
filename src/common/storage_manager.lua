-- storageManager.lua
-- Generic JSON storage manager for Spoons
-- Provides serialization, deserialization
-- Delegates File I/O to common.file_manager
-- Follows SOLID: Responsible for Logic of Persistence (WHAT to save), not I/O (HOW to save)

local storageManager = {}
local fileManager = require("common.file_manager")
local logger = hs.logger.new('StorageManager', 'info')

-- Private constants
local STORAGE_DIR = "Spoons/storage_configs"

-- ============================================================================
-- PRIVATE METHODS
-- ============================================================================

--- Get the full path to the storage directory
-- @return string Absolute path to storage directory
local function getStoragePath()
    local configdir = hs.configdir
    if not configdir then return nil end
    return configdir .. "/" .. STORAGE_DIR
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
    if not storagePath then return nil end

    return storagePath .. "/" .. spoonId .. ".json"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Check if a storage file exists for a given Spoon
-- @param spoonId string The Spoon identifier
-- @return boolean true if file exists
function storageManager.exists(spoonId)
    local filePath = getFilePath(spoonId)
    return fileManager.exists(filePath)
end

--- Save data to JSON file (Serialization)
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

    local filePath = getFilePath(spoonId)
    if not filePath then return false end

    -- Ensure storage directory exists
    local storagePath = getStoragePath()
    if not fileManager.createDir(storagePath) then
        return false
    end

    -- Serialize to JSON
    local success, jsonString = pcall(hs.json.encode, dataTable, true)
    if not success then
        logger.e("Failed to serialize data to JSON: " .. tostring(jsonString))
        return false
    end

    -- Delegate write to FileManager
    local writeSuccess = fileManager.writeFile(filePath, jsonString)

    if writeSuccess then
        logger.i(string.format("[%s] Data saved successfully to %s", spoonId, filePath))
    end

    return writeSuccess
end

--- Load data from JSON file (Deserialization)
-- @param spoonId string The Spoon identifier
-- @return table Data loaded from file, or empty table {} on error/missing file
function storageManager.load(spoonId)
    local filePath = getFilePath(spoonId)
    if not filePath then return {} end

    -- Delegate read to FileManager
    local content = fileManager.readFile(filePath)

    if not content or content == "" then
        -- logger.w("File not found or empty: " .. filePath)
        return {}
    end

    -- Deserialize JSON
    local success, dataTable = pcall(hs.json.decode, content)
    if not success then
        logger.e("Failed to parse JSON from file: " .. tostring(dataTable))
        return {}
    end

    -- logger.i(string.format("[%s] Data loaded successfully", spoonId))
    return dataTable or {}
end

return storageManager
