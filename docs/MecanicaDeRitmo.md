# Mecánica de ritmo

El corazón del juego. Es un juego de **timing/precisión**, no de aguantar un botón (esto ya se decidió, ver [[Registro de decisiones]]).

Está montado en **DOS CAPAS**, decidido el 31/07. Separa el bucle fluido de los picos de emoción y evita la monotonía.

## Capa 1 — la picadita normal (el bucle)

Un **balón que bota** en bucle. Se pulsa **espacio** cuando toca abajo. Sin barra: la referencia es el propio balón.

| Precisión | Resultado | Efecto |
|-----------|-----------|--------|
| 🟢 ±0.05s | **Perfect** | Sube el combo + máximo de monedas |
| 🟡 ±0.13s | **Good** | Sube el combo igual, pero paga menos |
| 🔴 fuera | **Miss** | Combo a cero (se sigue jugando) |

Dejar pasar el bote sin pulsar también es fallo: *"se te ha escapado la pelota"*.

**Dificultad:** el ciclo del balón se acorta con el combo, de 0.8s a 0.35s a lo largo de 175 de combo, con curva suave (smoothstep). La ventana de acierto NO se encoge: la dificultad sube por ritmo, no por precisión.

## Capa 2 — la skill épica (los picos)

Cada cierto combo se interrumpe el bucle y aparece una **barra horizontal con un indicador**. Hay que pararlo dentro de la zona verde, que se sortea en un sitio distinto cada vez.

El indicador **rebota una vez**: recorre la barra, cambia de dirección en el extremo y vuelve. Si tampoco pulsas en esa segunda pasada, fallo por tiempo. El rebote está para que el cambio de dirección pille desprevenido; el límite de dos pasadas está para que no se pueda esperar indefinidamente a que la zona pase por delante.

- **Aciertas:** skill épica + un premio gordo (~50 veces una picadita).
- **Fallas o dejas pasar la barra:** combo a cero. Es el momento de riesgo real.

**Cada cuánto:** huecos crecientes — combo 5, 13, 24, 39, 59, 86, 122, 170... con techo de 60 de hueco. Frecuentes al empezar, raras y valiosas después.

**Dificultad:** el recorrido se acelera de 2.2s a 0.9s con el combo. El tamaño de la zona está en config pero de momento no escala.

**Mientras la barra está activa el ritmo de picaditas se pausa por completo**: el balón se congela en el pie y no se puede escapar.

Al **acertar**, el balón no vuelve a botar de inmediato: sigue una **coreografía** que acompaña a la animación de celebración (ver `SkillTrajectories.luau`). El ritmo normal no se reanuda hasta que termina, y como toda coreografía acaba en el punto de contacto del pie, el empalme es invisible.

⚠️ **La vuelta al mundo no es una chilena.** Es un truco de freestyle a ras de suelo: el jugador pasa la pierna por encima del balón mientras sigue haciendo picaditas. El balón se mantiene **bajo, cerca del pie** — en esencia una picadita normal (misma parábola, un 15% más alta) pero con más tiempo en el aire para que quepa el gesto.

Al **fallar**, el ciclo se re-ancla al momento y el balón arranca desde abajo, dando un ciclo entero para recolocarse.

## Dónde vive en el código

- **Cliente:** `BallController` (balón), `InputController` (espacio), `SkillController` (barra). Van en el cliente para que sea instantáneo, sin lag.
- **Servidor:** `ComboService` valida las dos capas y lleva el combo. Ver [[Cliente vs Servidor]].
- **Config:** `SpeedConfig` (velocidad del balón), `TimingConfig` (ventanas), `SkillConfig` (skills).

Lo que hace posible validar sin fiarse del cliente: **el servidor ancla el reloj**. Guarda cuándo arrancó el ciclo (y cuándo la barra), así que calcula él mismo dónde está el balón o el indicador en cualquier instante. El cliente solo dice *cuándo* pulsó.

## Gancho visual

Las **skills épicas salen solas en los Perfect** y escalan con el combo (a más combo, más espectacular). El jugador no las controla, las gana acertando. Esto es lo pensado para viralizar (clips de TikTok).

Progresión visual aproximada:
- Combo 1-5: toques normales.
- Combo 5-15: trucos sencillos.
- Combo 15-30: skills medias.
- Combo 30+: skills legendarias con partículas, cámara lenta, brillo.

## Pendiente de decidir / implementar

- **Balance de los números.** La estructura está; los valores concretos (huecos entre skills, velocidades, tamaño de la zona) piden pruebas de juego.
- **El efecto épico de verdad.** Hoy la skill acertada solo saca un texto. El punto de conexión está marcado en `SkillController:_playEpicPlaceholder`, y recibe `combo` (para escalar el espectáculo) y `earned` (para la lluvia de monedas).
- Si la ventana de acierto debe encogerse con el combo, además de la aceleración.
- Feedback sonoro de cada tipo de golpe (pitch ascendente por combo, ya decidido).