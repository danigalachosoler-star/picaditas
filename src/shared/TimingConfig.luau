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
TimingConfig.PerfectWindow = 0.05
TimingConfig.GoodWindow = 0.13

-- TOPE DE SEGURIDAD, no es un ajuste de dificultad.
-- Las ventanas de dos botes seguidos no pueden solaparse: si lo hicieran,
-- cualquier tecleo caería siempre dentro de alguna y TODO sería acierto.
-- Por eso ninguna ventana puede pasar de esta fracción del ciclo.
--
-- Solo entra en juego a mucha velocidad: con un ciclo de 0.8s no hace nada,
-- pero con uno de 0.35s la GoodWindow se recorta sola de 0.20 a 0.1575.
-- Si quieres que la ventana NUNCA se toque, sube MinCycleDuration por encima
-- de GoodWindow / MaxWindowFraction (ahora 0.44s).
TimingConfig.MaxWindowFraction = 0.45

-- Segundos de cortesía al entrar en la partida, para que no te comas un fallo
-- mientras el juego todavía está cargando en tu pantalla.
TimingConfig.GracePeriod = 2

-- ANTITRAMPAS: cuánto puede el cliente afirmar que su pulsación es "del
-- pasado". Se usa para compensar el ping de la gente con mala conexión, pero
-- acotado, porque un tramposo podría mentir para acertar siempre.
TimingConfig.LatencyGrace = 0.05
TimingConfig.MaxInputLatency = 0.4

return TimingConfig
