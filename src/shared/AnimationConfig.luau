-- src/shared/AnimationConfig.luau
-- Las animaciones del personaje y cuándo se usa cada una.
--
-- ⚠️ AVISO IMPORTANTE SOBRE LOS IDs:
-- Roblox solo deja reproducir animaciones que pertenezcan al dueño del juego
-- (tu cuenta, o el grupo bajo el que esté publicado el place). Una animación
-- publicada por OTRA cuenta suele fallar al cargar aunque el id sea correcto,
-- con un error del tipo "failed to load animation... not owned".
--
-- Si al probar el personaje no se mueve, mira el Output: el
-- CharacterAnimationController avisa con un mensaje claro. La solución es
-- reimportar/republicar las animaciones desde la cuenta o grupo del juego.

local AnimationConfig = {}

export type Entry = {
	id: number,
	-- Duración aproximada en segundos, a velocidad normal. Solo informativa:
	-- el código NO se apoya en este número para sincronizar nada (para eso
	-- está el marker, ver más abajo).
	length: number,
}

-- Marker colocado en el fotograma exacto en que el pie toca el balón.
-- Tiene que llamarse igual en las tres animaciones del editor de Roblox.
AnimationConfig.ContactMarker = "Contacto"

-- Picadita normal. Se sortea una de las dos en cada acierto.
AnimationConfig.Touches = {
	normal = { id = 123770559420710, length = 0.3 },
	knee = { id = 129821051355554, length = 0.3 },
}

-- Probabilidad de que salga el toque de rodilla. El resto de veces, el normal.
--   0.2  → 1 de cada 5 (el normal predomina claramente)
--   0    → nunca sale la rodilla
--   0.5  → mitad y mitad
AnimationConfig.KneeChance = 0.2

-- Celebración tras clavar una skill épica. No se acelera con el combo: es un
-- momento de lucimiento y debe verse entero.
AnimationConfig.SkillCelebration = { id = 122240671057322, length = 1 }

-- Segundos de mezcla al arrancar y parar una animación. Un pelín de fundido
-- evita el tirón de pasar de golpe de una pose a otra.
AnimationConfig.FadeTime = 0.08

return AnimationConfig
