# Estado actual

Dónde estamos ahora mismo. Actualizar esta nota cuando cambie algo importante.

**Última actualización:** 3 de agosto de 2026.

## ✅ Hecho

- Entorno de desarrollo montado y funcionando en ambas máquinas (Rojo + Rokit + Wally + StyLua + Knit).
- Estructura de carpetas `src/client`, `src/server`, `src/shared` creada.
- Knit instalado vía Wally y mapeado en `ReplicatedStorage/Packages`.
- Plugin de Rojo en Studio, conexión probada (se ven las carpetas en el Explorer).
- Repo en GitHub: https://github.com/danigalachosoler-star/picaditas
- Documentación: vault de Obsidian en `docs/` + `CLAUDE.md` en la raíz.
- **"Hola mundo" de Knit verificado:** arranca en servidor y cliente (`TestService` + `TestController`).
- **Paso 1 de la mecánica:** ciclo visual del balón (`BallController` + `BallConfig`).
- **Paso 2 de la mecánica (capa 1 completa):** input, timing, validación en servidor y combo.
  - `TimingConfig` + `RhythmMath` (Shared): ventanas de tolerancia y cuentas del ritmo, compartidas por ambos lados.
  - `ComboService` (servidor): ancla el ciclo, juzga Perfect/Good/Miss, lleva el combo **por jugador** y detecta balones escapados.
  - `InputController` (cliente): captura espacio vía ContextActionService (botón táctil en móvil incluido).
  - `ComboHudController` (cliente): número de combo + mensajes de feedback.
  - El balón ya no lleva contador propio: se dibuja desde el reloj sincronizado del servidor.
- **Paso 3: aceleración por combo.** `SpeedConfig` (curva) + re-anclaje del ciclo en el servidor. El ciclo va de 0.8s a 0.35s a lo largo de 175 de combo, con curva smoothstep. Al fallar vuelve a la velocidad base. HUD muestra el ciclo actual en Studio para afinar.

- **Paso 4: monedas.** `EconomyConfig` + `CurrencyService`. Cada acierto paga según el tipo de golpe y el combo. Contador en el HUD y el "+N" cobrado junto al veredicto. ⚠️ Solo en memoria: al salir se pierde.

## 🔜 Siguiente paso inmediato

**Persistencia (DataStore):** guardar el saldo de monedas y el récord de combo. Todo el sitio donde tocar ya está aislado en `CurrencyService`. Ver [[Cliente vs Servidor]].

## 🎯 Después de eso

Animación de picadita del personaje y la capa 2 (barra de skill épica).

## Alcance del MVP (recordatorio)

Solo: barra de ritmo + input + combo + monedas + 1 personaje básico + guardado. Todo lo demás es fase posterior (ver [[Backlog]]).