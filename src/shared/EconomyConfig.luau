-- src/shared/EconomyConfig.luau
-- Cuántas monedas da cada picadita. Los números de balance van aquí para
-- poder trastearlos sin buscar por el código (ver EconomiaYMonedas.md).

local EconomyConfig = {}

-- Monedas base por golpe, ANTES de aplicar el multiplicador de combo.
-- La proporción 1:3 entre Good y Perfect es la que dice el doc de economía;
-- van multiplicadas por 10 para que al redondear a números enteros no se
-- pierda tanto (con Good = 1, la mitad del ajuste fino se iría en el redondeo).
EconomyConfig.GoodReward = 10
EconomyConfig.PerfectReward = 30

-- Cuánto multiplica cada punto de combo. La fórmula es:
--     monedas = base × (1 + combo × ComboFactor) × multiplicadorDelJugador
--
-- Es una recta, sin tramos ni saltos: cada acierto sube el multiplicador
-- exactamente lo mismo, así que no hay escalones raros.
--   0.10 → con combo 175 vas a ×18.5
--   0.05 → con combo 175 vas a ×9.75  (progresión más plana)
--   0.20 → con combo 175 vas a ×36    (premia muchísimo las rachas largas)
EconomyConfig.ComboFactor = 0.1

-- Suelo: un acierto nunca da 0 monedas, por feo que salga el redondeo.
EconomyConfig.MinReward = 1

return EconomyConfig
