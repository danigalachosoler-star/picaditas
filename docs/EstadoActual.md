# Estado actual

Dónde estamos ahora mismo. Actualizar esta nota cuando cambie algo importante.

**Última actualización:** 31 de julio de 2026.

## ✅ Hecho

- Entorno de desarrollo montado y funcionando en ambas máquinas (Rojo + Rokit + Wally + StyLua + Knit).
- Estructura de carpetas `src/client`, `src/server`, `src/shared` creada.
- Knit instalado vía Wally y mapeado en `ReplicatedStorage/Packages`.
- Plugin de Rojo en Studio, conexión probada (se ven las carpetas en el Explorer).
- Repo en GitHub: https://github.com/danigalachosoler-star/picaditas
- Documentación: vault de Obsidian en `docs/` + `CLAUDE.md` en la raíz.

## 🔜 Siguiente paso inmediato

Escribir el **"Hola mundo" de Knit** (4 archivos) para verificar que el framework arranca en ambos lados:
1. `src/server/Services/TestService.luau`
2. `src/server/init.server.luau` (arranque servidor)
3. `src/client/Controllers/TestController.luau`
4. `src/client/init.client.luau` (arranque cliente)

Al darle a Play, deben salir 6 mensajes en el Output (Init de todos primero, Start después). Ver [[Ciclo de vida de Knit]].

## 🎯 Después de eso

Empezar la [[Mecánica de ritmo]] (el core del juego). Arquitectura: `InputController` (cliente, la barra + input) ↔ `ComboService` (servidor, valida y guarda). Ver [[Cliente vs Servidor]].

## Alcance del MVP (recordatorio)

Solo: barra de ritmo + input + combo + monedas + 1 personaje básico + guardado. Todo lo demás es fase posterior (ver [[Backlog]]).