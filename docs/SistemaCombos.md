# Sistema de combos

El combo es la racha de picaditas acertadas seguidas. Es lo que da tensión y lo que multiplica las recompensas. Va de la mano de la [[Mecánica de ritmo]].

## Cómo sube y baja

- **Perfect (verde):** suma al combo (+1) y da el máximo de recompensa.
- **Good (amarilla):** mantiene el combo pero no lo sube al máximo o da menos. Es la "salvación" para no perder la racha.
- **Miss (roja):** rompe la racha.

## Qué pasa al fallar (pendiente de confirmar)

Opciones barajadas, de más dura a más suave:
1. Combo a cero y termina la partida (hardcore, máxima tensión).
2. Combo a cero pero sigues jugando.
3. Pierdes solo la mitad del combo (más perdón).

**Preferencia actual (por confirmar en implementación):** opción 2 (combo a cero pero sigues jugando), porque el público de Roblox es joven y menos frustración = más retención. Idea añadida: un "escudo" que perdona un fallo, comprable o ganable.

## Hitos de combo

Que a ciertos combos pasen cosas, para dar metas cortas ("llego a 10 y desbloqueo X"):
- Combo 10 → nueva skill.
- Combo 25 → cambia el estadio de fondo.
- Combo 50 → efecto de fuego en el personaje.

(Números de ejemplo, hay que balancearlos.)

## Multiplicador

El combo actúa de multiplicador de monedas (ver [[Economía y monedas]]): a más combo, más monedas por picadita. Mostrar el multiplicador en pantalla bien visible (x2, x5, x10...) para que el jugador sienta lo que se juega.

## Regla técnica

El combo se valida y guarda en el **servidor**, nunca en el cliente (si no, habría trampas en el leaderboard). Ver [[Cliente vs Servidor]].