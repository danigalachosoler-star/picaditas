# Cliente vs Servidor

El concepto que más despista viniendo de web, y el más importante de Roblox. Grabároslo bien.

## El modelo

Roblox es siempre **cliente-servidor**:

- **Servidor:** una máquina (de Roblox) que gestiona la partida para todos los jugadores. Es la **autoridad**: física real, datos, lógica sensible. Los jugadores no pueden ver ni modificar su código.
- **Cliente:** la máquina de cada jugador. Ejecuta su input, su interfaz, sus efectos visuales. **Un jugador puede hacer trampas modificando su cliente.**

## La regla de oro

**Nunca confíes en el cliente para nada que se pueda usar para hacer trampas.**

Ejemplo en nuestro juego: "he metido un Perfect y tengo combo 500" NO lo decide el cliente. El cliente dice "el jugador pulsó espacio en el momento X", y el **servidor valida** si eso es un Perfect y actualiza el combo. Si dejáramos que el cliente reportara el combo directamente, el leaderboard se llenaría de tramposos con combo infinito.

## Cómo lo aplicamos (ver [[Mecánica de ritmo]])

- **Cliente (Controller):** la barra oscilante y la captura del espacio. Va en el cliente para que sea **instantáneo, sin lag**.
- **Servidor (Service):** recibe el input, valida el resultado, actualiza combo/monedas/récord y los guarda.

## Dónde va cada carpeta (ver [[Convenciones de Rojo]])

- `src/server/` → solo lo ve el servidor. Lógica de autoridad.
- `src/client/` → se copia a cada jugador. Input, UI, efectos.
- `src/shared/` → lo ven ambos. Config, tipos, constantes.

## Servicios de Roblox relacionados

- **ReplicatedStorage:** se replica a todos (cliente y servidor). Aquí va lo compartido y los Packages (Knit).
- **ServerScriptService / ServerStorage:** solo servidor. Nada de esto llega al cliente.
- **StarterPlayer/StarterPlayerScripts:** se copia a cada jugador al entrar.