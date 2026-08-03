-- src/shared/TimingConfig.luau
-- Reglas de tolerancia del timing. Vive en Shared porque el SERVIDOR las usa
-- para juzgar y el cliente para dibujar: si cada lado tuviera sus números,
-- el jugador vería una cosa y el servidor juzgaría otra.

local TimingConfig = {}

-- Ventanas de acierto, en segundos, medidas a CADA LADO del instante exacto
-- en que el balón toca abajo. Es decir, PerfectWindow = 0.10 significa que
-- tienes 0.10s antes + 0.10s después = 0.20s de margen total para el Perfect.
--
-- Súbelas para que el juego perdone más, bájalas para que sea más exigente.
TimingConfig.PerfectWindow = 0.10
TimingConfig.GoodWindow = 0.20

-- Segundos de cortesía al entrar en la partida, para que no te comas un fallo
-- mientras el juego todavía está cargando en tu pantalla.
TimingConfig.GracePeriod = 2

-- ANTITRAMPAS: cuánto puede el cliente afirmar que su pulsación es "del
-- pasado". Se usa para compensar el ping de la gente con mala conexión, pero
-- acotado, porque un tramposo podría mentir para acertar siempre.
TimingConfig.LatencyGrace = 0.05
TimingConfig.MaxInputLatency = 0.4

return TimingConfig
