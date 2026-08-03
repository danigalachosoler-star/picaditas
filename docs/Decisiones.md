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

## Pendientes de decidir

- Fórmula de monedas y multiplicador. Ver [[Economía y monedas]].
- Velocidad/curva de aceleración de la barra. Ver [[Mecánica de ritmo]].

<!-- Plantilla para nuevas entradas:
- **[DD/MM] Título corto de la decisión.** Motivo breve. Detalle en [[nota]].
-->