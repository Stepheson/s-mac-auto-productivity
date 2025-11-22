--- === WindowManager ===
---
--- Gerenciamento de janelas e monitores no Hammerspoon
--- Move janelas entre monitores com atalhos de teclado

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowManager"
obj.version = "1.0"
obj.author = "Stepheson Alves"
obj.license = "MIT"
obj.homepage = "https://github.com/yourusername/hammerspoon-config"

-- Internal state
obj.hotkeys = {}
local managerMonitorsMac = require("common.managerMonitorsMac")

-- ========== CONFIGURAÇÕES ==========
obj.config = {
  maxAttempts = 5,
  positionDelay = 0.2,
  verificationDelay = 0.15,
  tolerance = 10
}

-- ========== MÉTODOS PRIVADOS (HELPERS) ==========
local lastCycledAppName = nil

-- Calcula o targetFrame baseado no tipo de resize e tela
local function calculateTargetFrame(screenFrame, resizeType, customValue)
  local targetFrame
  
  if resizeType == "monitor1_left_margin" then
    local topMargin = math.floor(screenFrame.h * 0.23)
    local leftMargin = math.floor(screenFrame.w * 0.043)
    local bottomMargin = math.floor(screenFrame.h * 0.02)

    targetFrame = {
      x = screenFrame.x + leftMargin,
      y = screenFrame.y + topMargin,
      w = screenFrame.w - leftMargin,
      h = screenFrame.h - topMargin - bottomMargin
    }
    
  elseif resizeType == "monitor2_left_margin" then
    local leftMargin = math.floor(screenFrame.w * 0.025)
    targetFrame = {
      x = screenFrame.x + leftMargin,
      y = screenFrame.y,
      w = screenFrame.w - leftMargin,
      h = screenFrame.h
    }
    
  elseif resizeType == "monitor3_left_margin" then
    local leftMargin = math.floor(screenFrame.w * 0.035)
    targetFrame = {
      x = screenFrame.x + leftMargin,
      y = screenFrame.y,
      w = screenFrame.w - leftMargin,
      h = screenFrame.h
    }
    
  elseif resizeType == "adjustedMax" then
    local topMarginPercent = customValue or 0.15
    local topMargin = math.floor(screenFrame.h * topMarginPercent)
    targetFrame = {
      x = screenFrame.x,
      y = screenFrame.y + topMargin,
      w = screenFrame.w,
      h = screenFrame.h - topMargin
    }
    
  elseif resizeType == "maximize" then
    targetFrame = screenFrame
  end
  
  return targetFrame
end

-- Verifica se a janela está na posição correta
local function isWindowInPosition(currentFrame, targetFrame, tolerance)
  local xOk = math.abs(currentFrame.x - targetFrame.x) <= tolerance
  local yOk = math.abs(currentFrame.y - targetFrame.y) <= tolerance
  local wOk = math.abs(currentFrame.w - targetFrame.w) <= tolerance
  local hOk = math.abs(currentFrame.h - targetFrame.h) <= tolerance
  
  return (xOk and yOk and wOk and hOk)
end

-- Função auxiliar para posicionar janela com retry
local function positionWindow(win, targetFrame, maxAttempts)
  maxAttempts = maxAttempts or 5
  local attempt = 1
  
  local function tryPosition()
    if attempt > maxAttempts then
      hs.notify.new({
        title="Hammerspoon", 
        informativeText="Falha após " .. maxAttempts .. " tentativas"
      }):send()
      return
    end
    
    win:focus()
    win:setFrame(targetFrame, 0)
    
    hs.timer.doAfter(0.15, function()
      local currentFrame = win:frame()
      
      if not isWindowInPosition(currentFrame, targetFrame, 10) then
        attempt = attempt + 1
        tryPosition()
      end
    end)
  end
  
  tryPosition()
end

-- Função aprimorada para mover janela para monitor específico e ajustar
local function moveWindowToMonitorAndResize(monitorIndex, resizeType, customValue)
  local win = hs.window.focusedWindow()
  if not win then 
    hs.notify.new({title="Hammerspoon", informativeText="Nenhuma janela em foco"}):send()
    return 
  end
  
  local targetScreen = managerMonitorsMac.getMonitorByIndex(monitorIndex)
  if not targetScreen then
    hs.notify.new({title="Erro", informativeText="Monitor " .. monitorIndex .. " não encontrado"}):send()
    return
  end
  
  local maxAttempts = 5
  local attempt = 1
  
  -- PASSO 1: Mover para o monitor correto primeiro
  local screenFrame = targetScreen:frame()
  local currentFrame = win:frame()
  
  local tempFrame = {
    x = screenFrame.x + (screenFrame.w - currentFrame.w) / 2,
    y = screenFrame.y + (screenFrame.h - currentFrame.h) / 2,
    w = currentFrame.w,
    h = currentFrame.h
  }
  
  win:setFrame(tempFrame, 0)
  
  -- PASSO 2: Aguarda e depois ajusta o tamanho
  hs.timer.doAfter(0.2, function()
    local function tryResize()
      if attempt > maxAttempts then
        hs.notify.new({
          title="Hammerspoon", 
          informativeText="Falha no redimensionamento após " .. maxAttempts .. " tentativas"
        }):send()
        return
      end
      
      win:focus()
      
      local monitorName = targetScreen:name() or ("Monitor " .. monitorIndex)
      local targetFrame = calculateTargetFrame(screenFrame, resizeType, customValue)
      
      if not targetFrame then
        hs.notify.new({title="Erro", informativeText="Tipo de resize inválido"}):send()
        return
      end
      
      win:setFrame(targetFrame, 0)
      
      hs.timer.doAfter(0.15, function()
        local currentFrame = win:frame()
        
        if not isWindowInPosition(currentFrame, targetFrame, 10) then
          attempt = attempt + 1
          print(string.format("Tentativa %d no %s: Current(%d,%d,%d,%d) Target(%d,%d,%d,%d)", 
                attempt-1, monitorName, currentFrame.x, currentFrame.y, currentFrame.w, currentFrame.h,
                targetFrame.x, targetFrame.y, targetFrame.w, targetFrame.h))
          tryResize()
        else
          print(string.format("Janela movida para %s e redimensionada com sucesso!", monitorName))
          hs.notify.new({
            title="Hammerspoon", 
            informativeText=string.format("Movida para %s", monitorName)
          }):send()
        end
      end)
    end
    
    tryResize()
  end)
end

-- ========== MÉTODOS PÚBLICOS ==========

function obj:init()
  hs.window.animationDuration = 0
  print("WindowManager Spoon: init() chamado")
  return self
end

-- Método para configurar todos os atalhos de teclado
function obj:setupHotkeys()
  print("WindowManager Spoon: Configurando atalhos...")
  
  -- Limpa hotkeys antigos
  for _, hk in ipairs(self.hotkeys) do
    hk:delete()
  end
  self.hotkeys = {}
  
  -- Alt+1: Move para Monitor Principal + Margem Superior (25%)
  table.insert(self.hotkeys, hs.hotkey.bind({"alt"}, "1", function()
    moveWindowToMonitorAndResize(1, "monitor1_left_margin")
  end))

  -- Alt+2: Move para Monitor Secundário + Margem Esquerda (2.5%)
  table.insert(self.hotkeys, hs.hotkey.bind({"alt"}, "2", function()
    moveWindowToMonitorAndResize(2, "monitor2_left_margin")
  end))

  -- Alt+3: Move para MacBook (terceiro monitor) + Margem Esquerda (3.5%)
  table.insert(self.hotkeys, hs.hotkey.bind({"alt"}, "3", function()
    moveWindowToMonitorAndResize(3, "monitor3_left_margin")
  end))

  -- Alt+': Ajustar no Monitor 1 com margem superior customizável (15%)
  table.insert(self.hotkeys, hs.hotkey.bind({"alt"}, "'", function()
    moveWindowToMonitorAndResize(1, "adjustedMax", 0.20)
  end))
  
  print("WindowManager Spoon: " .. #self.hotkeys .. " atalhos configurados!")
end

-- Método principal para iniciar o módulo
function obj:start()
  print("WindowManager Spoon: start() chamado")
  
  self:setupHotkeys()
  
  hs.notify.new({
    title="Hammerspoon", 
    informativeText="Window Manager carregado:\nalt+1/2/3: Mover para monitores\nalt+': Ajustar Monitor 1"
  }):send()
  
  print("Window Manager Spoon configurado com sucesso")
  return self
end

-- Método para parar e deletar todos os hotkeys
function obj:stop()
  print("WindowManager Spoon: stop() chamado")
  
  if self.hotkeys then
    for _, hk in ipairs(self.hotkeys) do
      hk:delete()
    end
    self.hotkeys = {}
    print("WindowManager Spoon: todos os hotkeys deletados")
  end
  return self
end

-- Métodos públicos opcionais para uso externo
function obj:moveToMonitor(monitorIndex, resizeType, customValue)
  moveWindowToMonitorAndResize(monitorIndex, resizeType, customValue)
  return self
end

function obj:maximizeCurrentWindow()
  local win = hs.window.focusedWindow()
  if not win then return self end
  local screen = win:screen()
  positionWindow(win, screen:frame())
  return self
end

function obj:getMonitorInfo()
  local info = "Monitores detectados:\n"
  
  for i = 1, 3 do
    local monitor = managerMonitorsMac.getMonitorByIndex(i)
    if monitor then
      local name = monitor:name() or "Monitor Desconhecido"
      local frame = monitor:frame()
      local config = ""
      if i == 1 then
        config = " (25% margem topo)"
      elseif i == 2 then
        config = " (2.5% margem esquerda)"
      elseif i == 3 then
        config = " (3.5% margem esquerda)"
      end
      info = info .. string.format("%d: %s (%dx%d)%s\n", i, name, frame.w, frame.h, config)
    else
      info = info .. string.format("%d: Não encontrado\n", i)
    end
  end
  
  return info
end

return obj
