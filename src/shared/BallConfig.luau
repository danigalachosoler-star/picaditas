-- src/shared/BallConfig.luau
-- Ajustes del ciclo visual del balón.
-- Vive en Shared porque más adelante el servidor necesitará conocer la duración
-- del ciclo para validar el timing del jugador (ver ClienteYServidor.md).

local BallConfig = {}

-- ¿Buscas la velocidad del balón? Ya no está aquí: ahora depende del combo.
-- Mírala en SpeedConfig.luau (BaseCycleDuration es la de combo 0).

-- Altura máxima que alcanza el balón por encima de su posición base, en studs.
BallConfig.BounceHeight = 4

-- Punto más bajo del ciclo: el centro del balón cuando "toca" el pie.
-- Es el momento en el que luego habrá que pulsar espacio.
BallConfig.Origin = Vector3.new(0, 2, -8)

-- Radio de la esfera en studs.
BallConfig.Radius = 0.7

BallConfig.Color = Color3.fromRGB(245, 245, 245)

return BallConfig
