# Ciclo de vida de Knit

Cómo arranca Knit y por qué tiene dos fases. Entender esto es clave para no tener bugs raros de "un servicio usa otro que aún no existe".

## Las dos mitades

- **Services** → lado **servidor** (`src/server/Services/`). Lógica de autoridad.
- **Controllers** → lado **cliente** (`src/client/Controllers/`). Input y presentación.

Son espejo: la estructura es la misma, cambia el lado en el que corren.

## El arranque

En cada lado hace falta un script que:
1. Cargue Knit: `require(game:GetService("ReplicatedStorage").Packages.Knit)`.
2. Cargue todos los Services/Controllers: `Knit.AddServices(...)` / `Knit.AddControllers(...)`.
3. Arranque Knit: `Knit.Start()` (devuelve una Promise).

## Las dos fases (LO IMPORTANTE)

Cuando llamas a `Knit.Start()`, pasa en dos fases sobre TODOS los servicios/controladores:

1. **`KnitInit`** — se ejecuta primero, en todos. Aquí preparas cosas, pero **NO asumas que otros servicios ya están listos** (puede que su Init aún no haya corrido).
2. **`KnitStart`** — se ejecuta después de que TODOS hicieron su Init. Aquí **ya puedes usar otros servicios con seguridad**.

Es como el montaje de componentes: primero todo se "inicializa", luego todo "arranca". Esta separación evita el caos de dependencias.

## Ejemplo de orden de salida

Con un Service y un Controller de prueba, el Output muestra (Init de todos primero, Start después):

```
TestService: KnitInit
TestService: KnitStart
Knit arrancado en el SERVIDOR
TestController: KnitInit
TestController: KnitStart
Knit arrancado en el CLIENTE
```

## Comunicación cliente↔servidor

Un Service expone métodos al cliente a través de su tabla `Client`. Knit gestiona los RemoteEvents por debajo. Esa es la gracia de Knit: te quita el boilerplate de networking. Ver [[Cliente vs Servidor]].

## Nota sobre utilidades

La versión de Knit por Wally viene "adelgazada" (utilidades como Signal, Timer reducidas). Si hace falta alguna, se instala como paquete Wally aparte.