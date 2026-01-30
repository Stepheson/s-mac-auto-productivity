<p align="right"><code>Language:</code>
    <a href="README.md"><img src="https://hatscripts.github.io/circle-flags/flags/gb.svg" width="20" alt="England" valign="middle"></a>
</p>

# s-MAC-Auto-Productivity

Uma suíte de automação modular, robusta e limpa para macOS usando [Hammerspoon](https://www.hammerspoon.org/).

> **Compatibilidade**: Testado no macOS **Sequoia** e **Tahoe**.

## 🚀 Overview

Este projeto é construído em torno de "Spoons" (módulos) independentes adaptados para este projeto que podem ser facilmente expandidos para futuros Spoons ou Spoons existentes. Ele permite:

- **Gerenciamento Independente**: Gerenciar Spoons de forma independente, facilitando o trabalho com diversos outros módulos com atalhos organizados.
- **Produtividade Ágil**: As atuais Spoons permitem fácil troca de janelas de apps entre monitores por atalho com dimensões pré-configuradas e chamadas de configurações rápidas do sistema macOS. E mais que serão implementadas.

## 📑 Índice

**🥄 Spoons (Módulos de Ação)**

- [MonitorWindowApp.spoon](#-monitorwindowappspoon)
- [AppCycler.spoon](#-appcyclerspoon)
- [SpeedMacosCustomConfigs.spoon](#-speedmacoscustomconfigsspoon)
- [AutomationControl.spoon](#-automationcontrolspoon)

**🗜️ Recursos Comuns (Ferramentas de Gerenciamento)**

- [Advanced: Left vs Right Modifiers (SideHotkey)](#-advanced-left-vs-right-modifiers-sidehotkey)

---

---

## 🥄 SPOONS LIST

### 🎯 `MonitorWindowApp.spoon`

**Objetivo**: Por meio de atalhos do teclado, mover rapidamente janelas entre monitores instalados no Mac. Ao se mover para um monitor, a janela é identificada e ajustada para a dimensão pré-configurada para os apps naquele monitor. É possível configurar mais de um atalho para o mesmo monitor.

Os posicionamentos são salvos de forma que permite recuperar o layout se as janelas saírem do lugar (por bloqueio de máquina ou remoção de monitor). Os posicionamentos são salvos por **grupos de números de monitores** (ex: uma configuração para "1 monitor" e outra para "2 monitores" são salvas independentemente).

#### Configuração

1.  **Definir Dimensões de Janelas (`MonitorWindowAppSettings.json`)**:
    Crie ou edite o arquivo `MonitorWindowAppSettings.json` na raiz.
    - `monitorName`: Nome como é reconhecido o monitor pelo sistema operacional macOS. (Vá nas configurações de display do macOS ou ative o modo debug `Right Alt + Right Shift + m` do projeto e olhe no console).
    - `margins`: Margens suportadas: `left`, `right`, `top`, `bottom`.

    ```json
    [
      {
        "positionID": "monitor_MX279_margin_spaceleft_top",
        "monitorName": "MX279",
        "margins": { "left": 0.025, "top": 0.23 }
      },
      {
        "positionID": "builtin_standard",
        "monitorName": "Built-in Retina Display",
        "margins": { "left": 0.035 }
      }
    ]
    ```

2.  **Vincular Atalhos (`init.lua`)**:
    Vincule uma tecla para mover a janela atual para a posição definida.

    ```lua
    -- Mover para a posição "builtin_standard"
    table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "3", function()
      spoon.MonitorWindowApp:moveToMonitor("builtin_standard", true)
    end))
    ```

---

### 🎯 `AppCycler.spoon`

**Objetivo**: Um alternador de janelas inteligente restrito ao **monitor atual**. Evita o caos de pular entre telas quando você quer apenas alternar o contexto localmente.

- **Modo 0 (Padrão)**: Alterna todas as janelas mesmo se há mais de uma instância de um mesmo app aberto na janela.
- **Modo 1**: Alterna janelas somente entre diferentes apps.
- **Modo 2**: Alterna instâncias apenas entre instâncias de um mesmo app, o atual na tela.

#### Uso

Utilize a função `spoon.AppCycler:cycle({Modo})` no seu atalho.

```lua
-- Alternar janelas no monitor atual (Alt + Tab)
table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "tab", function()
    spoon.AppCycler:cycle(0)
end))
```

---

### 🎯 `SpeedMacosCustomConfigs.spoon`

**Objetivo**: Um menu de acesso rápido para configurações úteis do sistema macOS.

Este Spoon é dividido em módulos internos:

1.  **Finder**: Mostrar ou ocultar arquivos ocultos (mesmo que o atalho `cmd+shift+.` do macOS).
2.  **Screenshot**: Escolher o formato da captura (PNG, JPG).
3.  **Dock**: Ativar/Desativar o ocultamento automático do Dock.

#### Uso

Acione o menu com um atalho (Padrão: `Alt + 7`):

```lua
table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "7", function()
  spoon.SpeedMacosCustomConfigs:showMenu()
end))
```

---

### 🎯 `AutomationControl.spoon`

**Objetivo**: O gerenciador central. Ele controla o ciclo de vida (Iniciar/Parar) das outras Spoons e atalhos. Útil para desativar toda a automação temporariamente.

- **Visual Feedback**: Mostra alertas quando Paused (🔴) ou Resumed (🟢).

#### Configuração

Para que o gerenciador funcione, você precisa **registrar** as Spoons e a tabela de hotkeys no `init.lua`.

**Atalhos Pré-configurados (Exemplo):**

- Desativar: `Right Alt` + `Right Shift` + `0`
- Ligar: `Right Alt` + `Right Shift` + `1`

```lua
if spoon.AutomationControl then
    -- Registrar Spoons para controle
    spoon.AutomationControl:registerSpoon(spoon.MonitorWindowApp)
    spoon.AutomationControl:registerSpoon(spoon.AppCycler)

    -- Registrar a tabela de atalhos
    spoon.AutomationControl:registerHotkeys(hotkeys)

    -- Iniciar o sistema
    spoon.AutomationControl:start()
end
```

---

## 🗜️ Recursos Comuns

### 🎯 `Advanced: Left vs Right Modifiers (`SideHotkey`)`

Esta é uma extensão que pertence aos recursos `common/SideHotkey.lua`, para distinguir entre as teclas modificadoras da esquerda e da direita (Alt/Option, Cmd, Shift).

Isso permite que você use a tecla **Alt Esquerda** para suas automações personalizadas, mantendo a tecla **Alt Direita** livre para os atalhos padrão do macOS (ou vice-versa). Se o atalho não utilizar este recurso, a tecla predefinida será acionada independentemente do lado do teclado.

Supported modifiers: `leftAlt`, `rightAlt`, `leftCmd`, `rightCmd`, `leftShift`, `rightShift`, `leftCtrl`, `rightCtrl`.

#### Uso

**SEM SideHotkey (Comportamento Padrão):**
Qualquer tecla Alt acionará o comando.

```lua
hs.hotkey.bind({"alt"}, "1", function() ... end)
```

**COM SideHotkey (Diferenciação de Lado):**
Apenas a tecla Alt ESQUERDA acionará.

```lua
local SideHotkey = require("common.SideHotkey")

-- Dispara apenas com Left Alt
SideHotkey.bind({"leftAlt"}, "1", function() ... end)
```

> **TIP**: É possível utilizar atalhos misturados, alguns usando `hs.hotkey` (ambos os lados) e outros usando `SideHotkey` (lado específico) no mesmo arquivo `init.lua`.

---

---

## 📂 Estrutura do Projeto

```
├── init.lua                   # Ponto de entrada (configuração principal)
├── MonitorWindowAppSettings.json # Configuração de posições do usuário
├── common/                    # Recursos Comuns
│   ├── SideHotkey.lua         # Diferenciação de teclas Left/Right
│   ├── managerMonitorsMac.lua # Detecção de monitores
│   └── ...
├── storage/                   # Arquivos que salvam configurações por Spoons
│   └── ...
└── Spoons/                    # Módulos Independentes (Ações)
    ├── MonitorWindowApp.spoon # Gerenciamento de Janelas
    ├── AppCycler.spoon        # Alternador de Apps
    ├── AutomationControl.spoon# Gerenciador de Ciclo de Vida
    └── SpeedMacosCustomConfigs.spoon # Ferramentas do Sistema
        └── modules/           # (finder, screenshot, dock)
```

## 🛠️ Debugging

- **List Monitors**: `Right Alt + Right Shift + M` (Imprime nomes/IDs dos monitores no Console).
- **Console**: Verifique o Console do Hammerspoon se algo não estiver funcionando.

---

> [!NOTE]
> As teclas de nomeclatura "Alt" são as mesmas teclas Options do Mac.
