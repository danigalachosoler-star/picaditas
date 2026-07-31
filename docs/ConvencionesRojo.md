# Convenciones de Rojo

Cómo Rojo mapea los archivos del disco al árbol de Roblox, y las reglas de nombres de archivo.

## Mapeo de carpetas (definido en `default.project.json`)

| Carpeta en disco | Dónde acaba en Roblox | Para qué |
|------------------|----------------------|----------|
| `src/server/` | `ServerScriptService/Server` | Lógica de servidor (autoridad) |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/Client` | Input, UI, efectos (cliente) |
| `src/shared/` | `ReplicatedStorage/Shared` | Compartido: tipos, config, constantes |
| `Packages/` | `ReplicatedStorage/Packages` | Dependencias de Wally (Knit) |

Ver [[Cliente vs Servidor]] para qué implica cada lado.

## Nombres de archivo (IMPORTANTE)

La extensión del archivo le dice a Rojo qué tipo de instancia crear:

- `algo.server.luau` → **Script** (corre en servidor automáticamente).
- `algo.client.luau` → **LocalScript** (corre en cliente automáticamente).
- `algo.luau` (a secas) → **ModuleScript** (un módulo que otros importan con `require`). La mayoría del código es esto.
- `init.luau` dentro de una carpeta → convierte esa **carpeta en el módulo** (útil para organizar paquetes).

## Flujo de trabajo

1. `rojo serve` en la terminal (servidor local, personal de cada dev).
2. En Studio, plugin de Rojo → **Connect**.
3. Editar en VS Code → se refleja en Studio al guardar.
4. Probar en Studio (Play / F5).
5. Commit + push a GitHub.

## Qué NO se versiona

- El `.rbxl` (binario de Studio): Rojo lo reconstruye desde el código.
- La carpeta `Packages/`: `wally install` la regenera.
- `.DS_Store` (basura de macOS).

Todo esto está en el `.gitignore`.

## Recordatorio clave

`rojo serve` es **local y personal** de cada desarrollador (conecta su disco con su Studio). NO es un servidor compartido. Lo que sincroniza a los dos devs es **Git/GitHub** (push/pull).