-- src/shared/SkillConfig.luau
-- La capa 2: los momentos de skill épica (ver MecanicaDeRitmo.md).
-- Mientras haces picaditas, cada cierto combo aparece una barra horizontal con
-- un indicador que la recorre, y hay que pararlo dentro de la zona verde.

local SkillConfig = {}

----- Cada cuánto aparecen -----

-- Combo en el que sale la PRIMERA skill.
SkillConfig.FirstCombo = 5

-- Hueco hasta la segunda. A partir de ahí cada hueco es mayor que el anterior.
SkillConfig.FirstGap = 8

-- Cuánto crece cada hueco respecto al anterior. 1.35 = un 35% más largo.
--   Más alto → las skills se espacian antes (se vuelven raras enseguida).
--   1.0      → hueco fijo, todas igual de separadas.
SkillConfig.GapGrowth = 1.35

-- Techo del hueco: por mucho que suba el combo, nunca pasarán más de estos
-- aciertos entre dos skills. Sin esto acabarían desapareciendo del todo.
SkillConfig.MaxGap = 60

----- Dificultad -----

-- Cuántas pasadas da el indicador antes de darse por fallada la skill.
--   2 = va hasta el final, REBOTA y vuelve una vez. Si en esa segunda pasada
--       tampoco pulsas, fallo por tiempo.
--   1 = una sola pasada, sin rebote.
--   3 = ida, vuelta y otra ida.
--
-- El rebote existe para que el cambio de dirección pille desprevenido. El
-- límite existe para que no se pueda esperar indefinidamente a que la zona
-- pase por delante: sigue habiendo riesgo real.
SkillConfig.Sweeps = 2

-- Segundos que tarda el indicador en UNA pasada (de un extremo al otro), con
-- combo 0. El tiempo total disponible es esto por Sweeps.
SkillConfig.BaseSweepDuration = 2.2

-- Lo más rápido que llega a ir una pasada. Por debajo de esto no acelera.
SkillConfig.MinSweepDuration = 0.9

-- Combo al que se alcanza la velocidad máxima. Misma curva suave (smoothstep)
-- que usa el balón, para que las dos dificultades escalen igual.
SkillConfig.ComboAtMaxDifficulty = 175

-- Media anchura de la zona de acierto, en fracción de la barra.
-- 0.11 = la zona ocupa el 22% de la barra.
--
-- Hoy NO escala con el combo: solo escala la velocidad. Si algún día queréis
-- que también se encoja, ese es el sitio (ver SkillMath.GetZoneHalfWidth).
SkillConfig.ZoneHalfWidth = 0.11

-- La zona nunca toca los extremos de la barra: pararse justo al principio o
-- al final por accidente no debería ser un acierto.
SkillConfig.EdgeMargin = 0.06

----- Ritmo del momento -----

-- Segundos entre que aparece la barra y el indicador empieza a moverse. Da
-- tiempo a ver dónde está la zona (y absorbe el retraso de red del aviso).
SkillConfig.LeadIn = 0.5

-- Coreografía del balón al clavar una skill (ver SkillTrajectories.luau).
-- Hoy hay una sola, así que siempre sale la misma. Cuando haya más, aquí es
-- donde se elegirá cuál toca (por combo, aleatoria, por personaje...).
SkillConfig.DefaultTrajectory = "vuelta_al_mundo"

return SkillConfig
