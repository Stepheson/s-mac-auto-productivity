local M = {}

-- Cache da configuração carregada
local cachedConfig = nil

-- ========== CARREGAMENTO E PARSING ==========

-- RESPONSABILIDADE ÚNICA: Parse JSON
function M.loadConfig(filePath)
    local file = io.open(filePath, "r")
    if not file then
        print("⚠️  ProfileSettings.json não encontrado em: " .. filePath)
        print("   Usando configuração padrão vazia")
        cachedConfig = {}
        return cachedConfig
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse JSON usando hs.json nativo
    local success, config = pcall(hs.json.decode, content)
    if not success then
        print("❌ Erro ao parsear ProfileSettings.json:")
        print("   " .. tostring(config))
        print("   Usando configuração padrão vazia")
        cachedConfig = {}
        return cachedConfig
    end
    
    cachedConfig = config
    print("✅ ProfileSettings.json carregado com sucesso")
    
    return cachedConfig
end

-- ========== ACESSO AO CACHE ==========

-- Retorna cache atual
function M.getCachedConfig()
    return cachedConfig or {}
end

-- Limpa cache (útil para reload)
function M.clearCache()
    cachedConfig = nil
end

return M
