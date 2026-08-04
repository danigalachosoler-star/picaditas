# Registro de decisiones

Bitácora de decisiones importantes con fecha. Cuando toméis una decisión de diseño o técnica que no queréis rediscutir, apuntadla aquí en una línea.

## Julio 2026

- **[30/07] Stack: Luau puro + Knit.** Descartado roblox-ts para el primer juego. Detalle en [[Por qué Luau y Knit]].
- **[30/07] Mecánica: timing con zonas verde/amarilla/roja.** Descartado el "aguantar el botón" por pasivo. Es un juego de ritmo/precisión. Detalle en [[Mecánica de ritmo]].
- **[30/07] Personajes básicos en el MVP, brainrot descartado (por ahora).** Motivos: riesgo legal/copyright de los diseños brainrot (tienen autores identificables que empiezan a registrar marcas) y menos trabajo de arte. El brainrot queda como posible añadido futuro si el juego funciona.
- **[30/07] Monetización solo cosmética, nada de pay-to-win.** Detalle en [[Monetización]].
- **[30/07] Entorno montado y subido a GitHub.** Rojo + Wally + Knit funcionando en ambas máquinas.
- **[31/07] Adoptado Obsidian para documentación + CLAUDE.md para Claude Code.** El vault vive en `docs/` dentro del repo.
- **[31/07] Knit verificado.** El "hola mundo" de Knit arranca en servidor y cliente (6 mensajes en orden correcto). Entorno 100% funcional.
- **[31/07] Mecánica rediseñada a DOS CAPAS.** Capa 1: picadita normal = pulsar espacio en el momento justo cuando el balón cae (timing puro, sin barra), con aceleración por combo. Capa 2: skill épica = la barra horizontal con zona verde, aparece cada X combo. Motivo: separa el bucle fluido de los picos de emoción, evita monotonía. Detalle en [[Mecánica de ritmo]].
- **[31/07] Timing por balón + ayuda de sonido.** El jugador se guía por el balón (visual) y por señales de audio (ritmo). Sin música completa al principio.
- **[31/07] Sonido con pitch ascendente por combo.** El tono del golpe sube con el combo formando una melodía; al fallar vuelve al tono base. El audio es cliente (no se valida en servidor).
- **[31/07] Curva de dificultad larga y tolerante.** La picadita normal debe ser fácil de mantener (ventana de acierto generosa, aceleración lenta con techo) para que la gente encadene combos largos y se enganche. El fallo real vive más en las skills (capa 2) y en el rebirth.
- **[31/07] Modo AFK planificado.** El juego podrá hacer picaditas solo para generar dinero y que la gente pase tiempo. IMPLICACIÓN: la generación de dinero AFK la controla el SERVIDOR sí o sí (si no, trampas). Fase 2, pero el ComboService se diseña con esto en mente.
- **[31/07] Fallo = combo a cero + mensaje.** Pulsar fuera de la ventana → combo a cero. Dejar pasar el ciclo sin golpear → mensaje "se te ha escapado la pelota" + combo a cero. Ambas formas cuentan como fallo.
- **[31/07] Visión: hub social + parcelas, construido por fases.** Meta a largo plazo = mundo abierto social con tienda + zona de picaditas con parcela asignada, gente visible. Se construye por fases (MVP solo → economía → hub social → replicación fina). El código se diseña desde ya asociando el balón a "jugador + parcela". Detalle en [[Visión y fases]].

## Agosto 2026

- **[03/08] El ritmo lo ancla el SERVIDOR, no el cliente.** El servidor guarda cuándo arrancó el ciclo de cada jugador (`cycleStart`) y calcula él mismo dónde está el balón en cualquier instante; el cliente dibuja la misma fórmula con el reloj sincronizado (`Workspace:GetServerTimeNow()`). Es lo que permite validar el timing sin fiarse del cliente y sin que las dos máquinas se desincronicen. Ver [[Cliente vs Servidor]].
- **[03/08] Al fallar se sigue jugando (opción 2).** Confirma el pendiente de [[Sistema de combos]]: combo a cero pero la partida no termina.
- **[03/08] Good suma combo igual que Perfect.** La diferencia entre ambos se reserva para las monedas y los efectos, no para la racha. Un toque válido continúa la racha.
- **[03/08] Una pulsación consume su toque, acierte o falle.** No hay segundos intentos sobre el mismo bote. Es lo que impide que machacar la tecla sea una estrategia válida.
- **[03/08] La racha no arranca hasta el primer acierto.** Estando quieto no se acumulan mensajes de "se te ha escapado la pelota"; el jugador está calentando.

- **[03/08] Curva de aceleración: smoothstep, 0.8s → 0.35s en 175 de combo.** Curva en S: plana al principio (no castiga al que empieza), acelera en el tramo medio y se aplana al llegar al techo (no hay golpe seco al topar con el límite). El cambio más agresivo es de ~4ms por acierto, imperceptible de uno en uno. Números en `SpeedConfig.luau`.
- **[03/08] El ciclo se re-ancla en un instante absoluto acordado, nunca en "ahora".** Al cambiar de velocidad, el origen nuevo del ciclo se expresa como un instante concreto (el toque que se acaba de acertar, o una posición calculada hacia atrás al fallar). Así el retraso de red no produce ni saltos del balón ni desincronización.
- **[03/08] Las ventanas de acierto se recortan solas si no caben en el ciclo.** No es un ajuste de dificultad, es geometría: en un ciclo de 0.35s no cabe una ventana de ±0.20s sin que dos botes seguidos se solapen. `MaxWindowFraction` (0.45) lo impide. Con el techo actual la Good pasa de ±0.20 a ±0.1575 solo a velocidad máxima.

- **[03/08] Monedas: `base × (1 + combo × 0.1) × multiplicadorJugador`.** Good = 10, Perfect = 30. Multiplicador lineal, sin tramos. El `multiplicadorJugador` es el hueco del Game Pass x2 y hoy vale 1. Ver [[Economía y monedas]].
- **[03/08] `CurrencyService` aparte del `ComboService`.** El monedero vive en su propio Service porque es lo que se persistirá con DataStore, como pide CLAUDE.md. El ComboService le pide que pague; no lleva él las cuentas.
- **[03/08] Fallar no quita monedas ya ganadas, solo el multiplicador.** Lo que se pierde es el sueldo futuro por golpe (de combo 100 a 0, el Perfect cae de 330 a 33).

- **[03/08] Persistencia con ProfileStore (fork `ddashdev/profilestore@1.1.0`), no DataStore a mano.** Resuelve session-locking, reintentos, guardado periódico y guardado al cerrar el servidor. No hay ProfileStore oficial en Wally (loleris no publica ahí), así que se usa un fork **verificado a mano contra el original**: 98% de tokens idénticos y las únicas diferencias son anotaciones de tipos. Instalado como `[server-dependencies]` → no se replica al cliente.
- **[03/08] `DataService` separado del `CurrencyService`.** El DataService custodia el perfil entero sin saber qué significa; el CurrencyService es el único que toca `Coins`. Cuando lleguen personajes/skills/rebirth pedirán su perfil al DataService en vez de pasar por el monedero.
- **[03/08] Campos nuevos se añaden con `Profile:Reconcile()`.** Basta con añadirlos a `DataTemplate.luau`; los perfiles viejos los reciben al entrar, sin perder nada. Renombrar o reinterpretar un campo sí necesita migración manual: para eso está `Version` en la plantilla.

## Agosto 2026 (cont.)

- **[04/08] El catálogo dirige la estructura del perfil.** `Catalog.luau` define categorías e items; `DataTemplate` genera desde ahí los huecos de `Inventory` y `Equipped`. Añadir una categoría nueva (personajes, estadios...) es editar el catálogo: el perfil crece solo y Reconcile se lo da a los jugadores existentes. Cero código que tocar.
- **[04/08] "Nada equipado" se guarda como `""`, no como `nil`.** El DataStore descarta los nil, así que un campo a nil desaparecería del guardado y habría que recrearlo en cada carga.
- **[04/08] El bonus de mascota se resuelve con `Catalog.GetCoinBonus(Equipped)`, función pura.** El CurrencyService la llama sin depender del InventoryService, para que en el 6b el inventario pueda cobrar compras a través del monedero sin dependencia circular.
- **[04/08] Retirado el campo `Unlocked` de la plantilla del paso 5.** Era un placeholder especulativo; lo sustituye `Inventory`, que sí viene del catálogo. Los perfiles de prueba que ya existan conservarán un `Unlocked` vestigial sin usar (Reconcile no borra campos).

## Pendientes de decidir
- Si la ventana de acierto debe encogerse con el combo como palanca de dificultad *deliberada* (aparte del recorte geométrico que ya existe). Ver [[Mecánica de ritmo]].

<!-- Plantilla para nuevas entradas:
- **[DD/MM] Título corto de la decisión.** Motivo breve. Detalle en [[nota]].
-->