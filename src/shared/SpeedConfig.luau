-- src/shared/SpeedConfig.luau
-- La curva de aceleración: cómo se acorta el ciclo del balón según el combo.
-- Vive en Shared porque el servidor la aplica y el cliente necesita los mismos
-- números para dibujar el balón exactamente igual.
--
-- Estos son LOS TRES BOTONES que tocas para encontrar el punto dulce.

local SpeedConfig = {}

-- 1) VELOCIDAD INICIAL. Duración del ciclo con combo 0, en segundos.
--    Más alto = arranque más lento y fácil.
SpeedConfig.BaseCycleDuration = 0.8

-- 2) TECHO. Duración mínima: por debajo de esto no acelera nunca más.
--    Más bajo = el juego llega a ser más frenético.
--
--    ⚠️ OJO: la ventana de acierto tiene que caber dentro del ciclo. Si bajas
--    esto por debajo de GoodWindow * 2 (ahora 0.40), la ventana se comprime
--    sola para que siga cabiendo. Ver MaxWindowFraction en TimingConfig.
SpeedConfig.MinCycleDuration = 0.35

-- 3) LONGITUD DE LA CURVA. Con qué combo se alcanza el techo.
--    Más alto = curva más larga y tolerante, se tarda más en llegar al máximo.
SpeedConfig.ComboAtMaxSpeed = 175

-- Ajuste fino de la FORMA de la curva (opcional, deja 1 si no quieres liarte).
--   1.0  → la aceleración se concentra en la mitad de la curva (recomendado).
--   <1   (ej. 0.6) → acelera antes, se nota ya con combos bajos.
--   >1   (ej. 1.6) → los combos bajos van casi igual, todo se juega al final.
SpeedConfig.CurveExponent = 1.0

-- SOLO PRUEBAS: combo con el que arrancas para ver la velocidad máxima sin
-- encadenar 175 aciertos a mano. 0 = desactivado.
-- Se IGNORA fuera de Studio, así que no puede colarse en el juego publicado.
SpeedConfig.DebugStartCombo = 0

return SpeedConfig
