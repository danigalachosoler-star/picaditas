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

- **Paso 4: monedas.** `EconomyConfig` + `CurrencyService`. Cada acierto paga según el tipo de golpe y el combo. Contador en el HUD y el "+N" cobrado junto al veredicto.
- **Paso 5: persistencia.** `DataService` + `DataTemplate` con ProfileStore (Wally, realm server). Las monedas se guardan entre sesiones: carga al entrar, guardado periódico cada 5 min, y guardado al salir con cierre de sesión. Perfil diseñado para crecer (personajes, skills, rebirth, stats).

### Cómo probar el guardado en local

- **Studio tal cual:** ProfileStore detecta que no hay acceso a la API y usa un almacén FALSO en memoria. Todo funciona igual, pero el progreso se pierde al parar. El Output avisa de en qué modo estás.
- **Guardado de verdad en Studio:** publica el place (puede ser privado) y activa *Game Settings → Security → Enable Studio Access to API Services*. A partir de ahí las monedas sobreviven entre sesiones de Studio.

- **Paso 6a: cimientos de tienda/inventario.** `Catalog` (categorías + items) e `InventoryService` (solo lectura). El perfil guarda qué tiene desbloqueado y qué lleva equipado por categoría. El bonus de monedas de las mascotas ya está enchufado al multiplicador. Sin UI ni compra todavía.

- **Paso 6b: comprar y equipar.** `InventoryService:Purchase` / `:Equip`, validados en servidor y expuestos al cliente por Knit. `CurrencyService:TrySpend` cobra de forma atómica.

- **Paso 6c: UI de la tienda.** `ShopController`: botón 🛒 arriba a la izquierda, pestañas generadas desde `Catalog.Categories`, y por item nombre / precio / bonus / hueco de imagen y un botón que cambia según el estado (Comprar · Equipar · EQUIPADO). Se refresca sola tras cada acción y enseña el `message` del servidor. Retirado el panel de debug del 6b.

- **Paso 7: skills épicas (capa 2).** `SkillConfig` + `SkillMath` + `SkillController`. Cada cierto combo (5, 13, 24, 39, 59, 86...) aparece una barra con una zona sorteada; pararla dentro da un premio ~50x, fallarla cuesta el combo. Durante la skill el ritmo se pausa y al terminar se re-ancla. El efecto épico es un placeholder marcado en el código.

- **Animaciones del personaje.** `AnimationConfig` + `CharacterAnimationController`. Al acertar una picadita se reproduce toque normal (80%) o de rodilla (20%), acelerada con el mismo factor que el balón. Al clavar una skill, la vuelta al mundo a velocidad normal. El contacto pie-balón se detecta con el marker `Contacto`. Ver [[IDs de animaciones]].

## 🔜 Siguiente paso inmediato

**Comprobar que las animaciones cargan de verdad** — Roblox solo permite las que pertenezcan a la cuenta o grupo dueño del juego, y estas son de Costa Studios. Si fallan, hay que republicarlas desde la cuenta del juego.

Después, el resto del espectáculo: partículas, sonido y cámara. Los dos puntos de conexión están marcados en el código (`SkillController:_playEpicPlaceholder` y `CharacterAnimationController:_onContact`).

Pendientes menores:
- Imágenes de los items (el `ImageLabel` ya está en cada fila, falta darle `Image`).

## Alcance del MVP (recordatorio)

Solo: barra de ritmo + input + combo + monedas + 1 personaje básico + guardado. Todo lo demás es fase posterior (ver [[Backlog]]).