# Economía y monedas

Cómo se ganan y gastan las monedas del juego. Esto es lo que hace que el jugador quiera seguir jugando y desbloquear cosas. Nota: son monedas del JUEGO (moneda blanda), distinto de Robux (dinero real, ver [[Monetización]]).

## Cómo se ganan

- Cada picadita da monedas. Un **Perfect** da más que un **Good**.
- El **combo multiplica** las monedas (ver [[Sistema de combos]]): a más combo, más monedas por picadita.
- **Fórmula implementada** (números en `src/shared/EconomyConfig.luau`):

  ```
  monedas = base × (1 + combo × ComboFactor) × multiplicadorDelJugador
  ```

  - `base`: Good = 10, Perfect = 30 (la proporción 1:3 de siempre, ×10 para que el redondeo a enteros no se coma el ajuste fino).
  - `ComboFactor` = 0.1 → el multiplicador es una recta, sin tramos ni escalones. Con combo 175 vas a ×18.5.
  - `multiplicadorDelJugador`: hoy siempre 1. Es el hueco para el Game Pass x2 (ver [[Monetización]]); se aplica ANTES de redondear.
  - Suelo de 1 moneda: un acierto nunca paga 0.

- **Perder el combo también baja el sueldo por golpe**, no solo el número: de combo 100 a combo 1 el Perfect cae de 330 a 33 monedas.
- Una racha perfecta de 175 da ~51.400 monedas. Referencia para poner precios.

## En qué se gastan

- Desbloquear **personajes** (empezamos con básicos, ver [[Registro de decisiones]]).
- Desbloquear **skills** de celebración.
- Desbloquear **balones** con skins.
- Desbloquear **estadios/zonas**.

## Balance (lo importante y difícil)

El reto es que no sea ni demasiado lento (aburre) ni demasiado rápido (se acaba el contenido). Esto se ajusta con pruebas. Por ahora dejar los números en un archivo de config compartido (`src/shared/`) para tocarlos fácil sin buscar por el código.

## Relación con el rebirth

El [[Progresión y retención|rebirth]] reinicia el progreso a cambio de un multiplicador permanente. La economía tiene que estar pensada para que el rebirth tenga sentido (que llegar al rebirth cueste, pero que el multiplicador compense). Esto es fase posterior al MVP.

## Pendiente

- Balancear los números de la fórmula (la estructura ya está, faltan las pruebas de juego).
- Lista de precios de personajes/skills/estadios.
- Decidir si hay una segunda moneda premium (comprable con Robux) o solo Robux directo.