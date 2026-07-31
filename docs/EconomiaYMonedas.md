# Economía y monedas

Cómo se ganan y gastan las monedas del juego. Esto es lo que hace que el jugador quiera seguir jugando y desbloquear cosas. Nota: son monedas del JUEGO (moneda blanda), distinto de Robux (dinero real, ver [[Monetización]]).

## Cómo se ganan

- Cada picadita da monedas. Un **Perfect** da más que un **Good**.
- El **combo multiplica** las monedas (ver [[Sistema de combos]]): a más combo, más monedas por picadita.
- Fórmula base a definir. Ejemplo de partida:
  - Good = 1 moneda × multiplicador.
  - Perfect = 3 monedas × multiplicador.
  - Multiplicador = f(combo), p. ej. crece cada X combos.

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

- Definir fórmula exacta de monedas por golpe y multiplicador.
- Lista de precios de personajes/skills/estadios.
- Decidir si hay una segunda moneda premium (comprable con Robux) o solo Robux directo.