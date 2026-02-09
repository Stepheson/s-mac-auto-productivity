-- common/file_manager.lua
-- Centralized File I/O Manager
-- Handles low-level file operations (read, write, exists, mkdir)

local fileManager = {}
local logger = hs.logger.new('FileManager', 'info')

--- Check if a file exists
--- @param path string Absolute path to check
--- @return boolean
function fileManager.exists(path)
    if not path then return false end
    local attr = hs.fs.attributes(path)
    return attr ~= nil and attr.mode == "file"
end

--- Check if a directory exists
--- @param path string Absolute path to check
--- @return boolean
function fileManager.dirExists(path)
    if not path then return false end
    local attr = hs.fs.attributes(path)
    return attr ~= nil and attr.mode == "directory"
end

--- Create a directory (and parents if needed - via mkdir)
--- @param path string Absolute path
--- @return boolean success
function fileManager.createDir(path)
    if fileManager.dirExists(path) then return true end
    local success, err = hs.fs.mkdir(path)
    if not success then
        logger.e("Failed to create directory: " .. path .. " Error: " .. (err or "unknown"))
    end
    return success
end

--- Read file content
--- @param path string Absolute path
--- @return string|nil content content, or nil on error
--- @return string|nil error Error message if failed
function fileManager.readFile(path)
    if not fileManager.exists(path) then
        logger.w("File not found: " .. path)
        return nil, "File not found: " .. path
    end

    local file, err = io.open(path, "r")
    if not file then
        logger.e("Failed to open file for reading: " .. path .. " Error: " .. (err or "unknown"))
        return nil, err
    end

    local content = file:read("*all")
    file:close()
    return content, nil
end

--- Write content to file
--- @param path string Absolute path
--- @param content string Content to write
--- @param mode string|nil "w" (overwrite, default) or "a" (append)
--- @return boolean success
function fileManager.writeFile(path, content, mode)
    mode = mode or "w"
    local file, err = io.open(path, mode)
    if not file then
        logger.e("Failed to open file for writing: " .. path .. " Error: " .. (err or "unknown"))
        return false
    end

    file:write(content)
    file:close()
    return true
end

return fileManager
