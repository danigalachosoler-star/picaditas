# Por qué Luau y Knit

Registro del razonamiento detrás del stack elegido, para no rediscutirlo.

## Luau puro (en vez de roblox-ts)

Los dos desarrolladores vienen de TypeScript/React, así que roblox-ts (escribir TS que compila a Luau) era tentador. Se descartó para el primer juego por:

- Aprender **Roblox "de verdad"**: todos los tutoriales y la documentación están en Luau. Con roblox-ts habría que traducir mentalmente todo.
- Evitar depurar **dos capas a la vez** (Roblox + la capa de compilación de roblox-ts) siendo novatos en la plataforma.
- Que **ambos colaboren en igualdad** sin depender de saber TS.

Si en un futuro se hace un proyecto más serio y ya se domina la plataforma, se podría valorar roblox-ts con criterio.

## Knit (framework)

Se eligió Knit (de Sleitnick) porque:
- Organiza el código en **Services (servidor)** y **Controllers (cliente)**, un modelo claro.
- **Abstrae el networking** cliente-servidor (los RemoteEvents), que es de lo más tedioso a mano.
- Está muy documentado y usado en la comunidad.

Ver [[Ciclo de vida de Knit]] para cómo funciona por dentro.

## Herramientas de entorno

- **Rojo:** escribir en VS Code + Git en vez de dentro de Studio.
- **Rokit:** fijar versiones de herramientas para que ambos tengan lo mismo (tipo nvm).
- **Wally:** gestor de paquetes (instala Knit; tipo npm).
- **StyLua:** formateo consistente.

Estas cuatro juntas dan un flujo profesional con control de versiones, que es la forma correcta de trabajar dos personas.