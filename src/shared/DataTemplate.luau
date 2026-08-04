-- src/shared/DataTemplate.luau
-- La forma de los datos guardados de un jugador. Todo jugador nuevo empieza
-- con una copia exacta de esto.
--
-- CÓMO AÑADIR UN CAMPO NUEVO SIN ROMPER A NADIE:
-- Añádelo aquí y ya está. Al cargar, el DataService llama a `Profile:Reconcile()`,
-- que rellena en los perfiles VIEJOS cualquier clave que falte, con el valor
-- por defecto de esta plantilla. Un jugador de hace seis meses recibirá el
-- campo nuevo la próxima vez que entre, sin perder nada de lo que ya tenía.
--
-- REGLAS DE PROFILESTORE para lo que metas aquí (romperlas da error al guardar):
--   · Nada de Instances, ni Vector3/Color3/CFrame, ni funciones.
--   · Nada de tablas con huecos numéricos, ni mezclar índices numéricos y de texto.
--   · Solo números, textos, booleanos y tablas de esos.

local Catalog = require(script.Parent.Catalog)

local DataTemplate = {
	-- Sube esto solo si algún día hay que hacer una migración destructiva
	-- (renombrar o reinterpretar un campo). Para añadir campos NO hace falta:
	-- de eso ya se encarga Reconcile.
	Version = 1,

	-- ---- En uso ahora mismo ----
	Coins = 0,

	-- ---- Preparado, todavía sin usar ----
	-- Estos campos ya viajan en el perfil aunque nada los escriba aún. Están
	-- aquí para que la estructura no tenga que cambiar de forma más adelante.
	-- Ver ProgresionYRetencion.md y VisionYFases.md.

	-- Récord de combo, para el leaderboard global (fase 2).
	BestCombo = 0,

	-- Rebirths hechos y el multiplicador permanente que dan.
	Rebirths = 0,

	-- ---- Inventario (se rellena abajo desde el catálogo) ----
	-- Inventory[categoría][idDelItem] = true  → lo que tiene desbloqueado.
	-- Equipped[categoría] = idDelItem         → lo que lleva puesto.
	--
	-- Se usan claves de texto en vez de listas numeradas a propósito: así
	-- comprobar si algo está desbloqueado es directo y no se corrompe el orden.
	Inventory = {},
	Equipped = {},

	-- Contadores acumulados, para misiones y estadísticas.
	Stats = {
		TotalPicaditas = 0,
		TotalPerfects = 0,
	},
}

-- Los huecos del inventario salen del catálogo, no están escritos a mano. Al
-- añadir una categoría nueva en Catalog.luau, aparece aquí sola, y Reconcile
-- se la da a los jugadores que ya existían sin que pierdan nada.
for _, category in Catalog.Categories do
	DataTemplate.Inventory[category.id] = {}

	-- Cadena vacía = no lleva nada equipado. NO se usa nil a propósito: el
	-- DataStore descarta los nil, así que un campo a nil desaparecería del
	-- guardado y Reconcile tendría que recrearlo en cada carga.
	DataTemplate.Equipped[category.id] = ""
end

return DataTemplate
