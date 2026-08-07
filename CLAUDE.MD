# Picaditas — Juego de Roblox

Juego de ritmo/precisión con temática de fútbol. El jugador hace "picaditas" (toques al balón) dando en la zona verde de una barra oscilante. Desarrollado por 2 personas que aprenden Roblox/Luau desde cero (vienen de desarrollo web con TypeScript/React). Es su primer juego en la plataforma.

## Stack

- **Lenguaje:** Luau puro (NO roblox-ts).
- **Framework:** Knit (de Sleitnick). Services en el servidor, Controllers en el cliente.
- **Sync disco↔Studio:** Rojo 7.7.0.
- **Herramientas:** Rokit 1.2.0 (gestor de versiones), Wally 0.3.2 (paquetes), StyLua 2.5.2 (formateo).
- **Editor:** VS Code. **Control de versiones:** Git + GitHub.

## Estructura del proyecto

- `src/server/` → `ServerScriptService/Server`. Lógica de autoridad. Los Services de Knit van en `src/server/Services/`.
- `src/client/` → `StarterPlayer/StarterPlayerScripts/Client`. Input, UI, cámara, efectos. Los Controllers de Knit van en `src/client/Controllers/`.
- `src/shared/` → `ReplicatedStorage/Shared`. Código compartido: tipos, config, constantes.
- `Packages/` → `ReplicatedStorage/Packages`. Dependencias de Wally (Knit). NO se versiona (está en .gitignore).
- `docs/` → Vault de Obsidian con el diseño completo del juego. Consultar ahí para reglas de gameplay, economía y decisiones.

## Reglas de arquitectura (IMPORTANTES)

- **El servidor es la autoridad.** Toda lógica puntuable (combo, monedas, récord, compras) se valida y guarda en el SERVIDOR. NUNCA confiar en el cliente para nada que se pueda usar para hacer trampas.
- **El cliente solo maneja lo instantáneo:** la barra oscilante y la captura del input (espacio) van en el cliente para que no haya lag. Pero el resultado lo confirma el servidor.
- Comunicación cliente↔servidor a través de Knit (tabla `Client` de los Services), no RemoteEvents a pelo salvo que haya razón.
- Datos del jugador (progreso, monedas) persistidos con DataStore desde un Service dedicado.

## Convenciones de código

- Nombres de archivo Rojo: `algo.server.luau` (Script servidor), `algo.client.luau` (LocalScript cliente), `algo.luau` (ModuleScript), `init.luau` (convierte carpeta en módulo).
- Formatear siempre con StyLua antes de commit.
- Require de Knit: `require(game:GetService("ReplicatedStorage").Packages.Knit)`.
- Un Service/Controller por archivo, con nombre igual al del archivo (ej. `ComboService.luau` → `Name = "ComboService"`).
- Ciclo de vida Knit: usar `KnitInit` para preparar (sin asumir que otros servicios existen aún) y `KnitStart` para lógica que usa otros servicios.

## Decisiones ya tomadas (no rediscutir sin motivo)

- Luau + Knit (no roblox-ts). Personajes básicos para el MVP (nada de brainrot por ahora). Mecánica de timing con zonas verde (Perfect) / amarilla (Good) / roja (Miss). Monetización solo cosmética (no pay-to-win).

## Alcance del MVP

Solo esto en la primera versión: barra de ritmo + input + sistema de combo + monedas + 1 personaje básico + guardado de datos. Todo lo demás (rebirth, leaderboard, tienda, más personajes, skins, eventos) es fase POSTERIOR. No implementar features fuera del MVP salvo petición explícita.

## Flujo de trabajo

- Cada dev corre su propio `rojo serve` local y conecta su Studio. Git/GitHub es lo que sincroniza a los dos (no Rojo).
- Trabajar con ramas para no pisarse. El `.rbxl` no se versiona (Rojo lo reconstruye).

## Cómo trabajar conmigo (para los devs)

- Explica los conceptos, no solo des código: estamos aprendiendo Roblox/Luau.
- Cuando corrijamos algo que debería ser permanente, proponnos actualizar este CLAUDE.md.
No edites, crees ni actualices archivos de docs/ (vault de Obsidian). La documentación la mantiene el usuario a mano. No leas docs/ salvo que se te pida explícitamente.