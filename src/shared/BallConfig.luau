-- src/shared/BallConfig.luau
-- Ajustes del ciclo visual del balón.
-- Vive en Shared porque más adelante el servidor necesitará conocer la duración
-- del ciclo para validar el timing del jugador (ver ClienteYServidor.md).

local BallConfig = {}

-- ¿Buscas la velocidad del balón? Ya no está aquí: ahora depende del combo.
-- Mírala en SpeedConfig.luau (BaseCycleDuration es la de combo 0).

-- PUNTO DE CONTACTO: dónde está el centro del balón cuando toca el pie, medido
-- DESDE EL PERSONAJE (no desde el mundo). Al ir pegado al jugador, el balón le
-- sigue si se mueve o gira, y esto ya funciona igual cuando cada jugador tenga
-- su parcela (ver VisionYFases.md).
--
-- Los tres números, en studs y en el sistema del personaje:
--   X  lateral. 0 = centrado. Positivo lo mueve a su derecha.
--   Y  altura respecto al CENTRO del torso (HumanoidRootPart), que está a unos
--      3 studs del suelo. Por eso es negativo: -1.5 deja el balón a ~1.5 del
--      suelo, a la altura del pie/rodilla en el momento del toque.
--      MÁS NEGATIVO = el balón baja más.
--   Z  distancia hacia delante. NEGATIVO es "delante" en Roblox.
--      MÁS NEGATIVO = más lejos del cuerpo.
BallConfig.ContactOffset = Vector3.new(0, -1.5, -2)

-- Cuánto sube el balón por encima del punto de contacto, en studs.
-- El personaje mide unos 5 studs, así que 3 lo deja subiendo hasta el pecho.
-- Súbelo para picaditas más lucidas, bájalo para toques más rasos.
BallConfig.BounceHeight = 3

-- Radio de la esfera en studs.
BallConfig.Radius = 0.7

BallConfig.Color = Color3.fromRGB(245, 245, 245)

return BallConfig
