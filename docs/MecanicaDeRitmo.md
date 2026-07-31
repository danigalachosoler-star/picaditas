# Mecánica de ritmo

El corazón del juego. Es un juego de **timing/precisión**, no de aguantar un botón (esto ya se decidió, ver [[Registro de decisiones]]).

## Cómo funciona

- Hay una **barra con un indicador que oscila** de un lado a otro.
- El jugador pulsa **espacio** para intentar dar en el momento justo.
- Según dónde caiga el indicador al pulsar, hay tres resultados:

| Zona | Resultado | Efecto |
|------|-----------|--------|
| 🟢 Verde | **Perfect** | Picadita perfecta + sube el combo + dispara skill épica + máximo de monedas |
| 🟡 Amarilla | **Good** | Picadita válida, mantiene el combo pero no da el máximo |
| 🔴 Roja | **Miss** | Fallo → se pierde el combo (ver [[Sistema de combos]]) |

## Dificultad creciente

A más combo, el juego se pone más difícil (esto crea la tensión que engancha):

- **Aceleración:** el indicador va más rápido conforme sube el combo. (Empezar solo con esto, es más fácil de balancear.)
- **Encogimiento de la zona verde:** opción para más adelante, la zona verde se hace más pequeña a combos altos.

## Dónde vive en el código

- **Cliente (Controller):** la barra oscilante y la captura del input van en el cliente, para que sea instantáneo sin lag. Ej: `InputController`.
- **Servidor (Service):** valida y guarda el resultado (combo, monedas). Ej: `ComboService`. Ver [[Cliente vs Servidor]] para por qué esta separación es obligatoria.

## Gancho visual

Las **skills épicas salen solas en los Perfect** y escalan con el combo (a más combo, más espectacular). El jugador no las controla, las gana acertando. Esto es lo pensado para viralizar (clips de TikTok).

Progresión visual aproximada:
- Combo 1-5: toques normales.
- Combo 5-15: trucos sencillos.
- Combo 15-30: skills medias.
- Combo 30+: skills legendarias con partículas, cámara lenta, brillo.

## Pendiente de decidir / implementar

- Velocidad inicial del indicador y curva exacta de aceleración (balance).
- Tamaño de cada zona (verde/amarilla/roja) y si la verde se encoge.
- Feedback visual y sonoro de cada tipo de golpe.