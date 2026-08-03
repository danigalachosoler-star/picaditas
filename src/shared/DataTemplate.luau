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

	-- Colecciones desbloqueadas. Tablas indexadas por id: { ["balon_oro"] = true }.
	-- Se usan claves de texto en vez de listas numeradas a propósito: así
	-- comprobar si algo está desbloqueado es directo y no se corrompe el orden.
	Unlocked = {
		Characters = {},
		Skills = {},
		Balls = {},
		Stadiums = {},
	},

	-- Contadores acumulados, para misiones y estadísticas.
	Stats = {
		TotalPicaditas = 0,
		TotalPerfects = 0,
	},
}

return DataTemplate
