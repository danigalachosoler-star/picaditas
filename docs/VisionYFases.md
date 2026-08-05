# Visión y fases del juego

La visión a largo plazo y el orden en que se construye. La meta grande está clara; se construye por capas para no bloquearse.

## La visión completa (a dónde va el juego)

Un **hub social + zonas de juego**, el patrón de los mejores juegos de Roblox:

1. **Hub / mundo abierto:** entras a un espacio grande y social. Ves a otra gente, la tienda, lo que puedes comprar, escaparates de skins/personajes, leaderboard gigante con los mejores. Es el escaparate y el punto de encuentro que incita a jugar y a comprar.
2. **Campo de fútbol / zona de picaditas:** desde el hub entras a jugar y se te asigna **tu parcela** para hacer tus picaditas.

**Por qué esto importa:** ver a otros es lo que da vida al juego. Ver a alguien con una skin épica haciendo una skill brutal es el mejor anuncio de la tienda. Picarse por el nº1 del leaderboard hace que la gente eche horas. El componente social es motor de retención y de monetización.

## Las fases (orden de construcción)

**Fase 1 — MVP (AHORA):** una parcela, un jugador (tú), tu balón. La mecánica de picaditas funcionando y divertida. Sin hub, sin multijugador. Objetivo: que el core enganche estando solo. Si engancha solo, con multijugador será una bomba; si no engancha solo, el multijugador no lo salva.

**Fase 2 — Progresión y economía:** monedas, tienda, personajes/skins, rebirth, modo AFK. Funciona igual solo o acompañado, así que va antes del multijugador. Objetivo: razones para volver y para gastar. Ver [[Progresión y retención]] y [[Economía y monedas]].

**Fase 3 — Hub social y verse:** el mundo abierto, parcelas asignadas, varios jugadores en la misma partida viéndose los avatares, tienda física, leaderboard gigante. Objetivo: la vida social. Como el core y la economía ya funcionan, "verse" multiplica en vez de bloquear.

**Fase 4 (opcional) — Replicación fina:** sincronizar el balón/skills de cada uno para todos (el caso caro). Puede que con la Fase 3 (ver avatares ejecutando animaciones de skills) ya se tenga el 90% del efecto "wow" sin pagar este coste. Evaluar si merece la pena.

## Los dos niveles de "verse" (importante no confundir)

- **Nivel 1 (fácil, estándar en Roblox):** varios jugadores en la misma partida se ven los AVATARES por defecto. Es lo que da la sensación de mundo poblado. Esto es la Fase 3.
- **Nivel 2 (caro):** sincronizar la física del balón de cada uno para todos los clientes. Esto es la Fase 4, opcional.

Lo que da vida (ver gente, ver skills) se consigue mayormente con el Nivel 1. El Nivel 2 es un extra.

## Implicación para el código desde YA

Aunque en el MVP solo haya una parcela y un jugador, el código se diseña **asociando el balón y la lógica de picaditas a "un jugador y su parcela"**, no como algo global. Así, ampliar a muchas parcelas en la Fase 3 es natural y no hay que rehacer. Diseñar con visión de futuro sin construir el futuro todavía.