-- src/shared/Catalog.luau
-- Todo lo que existe en la tienda. Esta es la ÚNICA lista: el perfil del
-- jugador, la plantilla de datos y (más adelante) la UI se construyen a partir
-- de aquí. Añadir contenido es editar este archivo, nada más.
--
-- CÓMO AÑADIR UN ITEM: mételo en Catalog.Items con un id único.
-- CÓMO AÑADIR UNA CATEGORÍA NUEVA (personajes, estadios, celebraciones...):
--   1. Añádela a Catalog.Categories.
--   2. Añade items con esa `category`.
--   Y ya está: DataTemplate genera solo los huecos en el perfil, y Reconcile
--   se los da a los jugadores que ya existían. No hay que tocar código.

local Catalog = {}

export type Category = {
	id: string,
	name: string,
}

export type Item = {
	id: string,
	name: string,
	category: string,
	price: number,
	-- Solo mascotas: fracción de monedas extra mientras está equipada.
	-- 0.05 = +5%. Se suma al multiplicador del CurrencyService.
	coinBonus: number?,
	-- Solo skins de pelota: color del balón. TODAVÍA NO ESTÁ ENCHUFADO a nada
	-- visual; es el dato listo para cuando se pinte el balón equipado.
	color: Color3?,
}

-- De cada categoría se puede llevar UNA cosa equipada a la vez.
Catalog.Categories = {
	{ id = "pet", name = "Mascotas" },
	-- `name` es lo que se lee en la pestaña de la tienda: que sea corto.
	{ id = "ballskin", name = "Pelotas" },
} :: { Category }

-- Precios de referencia: una racha perfecta de 175 da ~51.000 monedas
-- (ver EconomiaYMonedas.md). Están sin balancear, tocadlos a gusto.
Catalog.Items = {
	-- ---- Mascotas ----
	{ id = "pet_perrito", name = "Perrito", category = "pet", price = 2000, coinBonus = 0.05 },
	{ id = "pet_gatito", name = "Gatito", category = "pet", price = 12000, coinBonus = 0.12 },
	{ id = "pet_dragon", name = "Dragón", category = "pet", price = 60000, coinBonus = 0.3 },

	-- ---- Skins de pelota (solo estéticas, sin efecto de juego) ----
	{
		id = "ball_clasico",
		name = "Clásico",
		category = "ballskin",
		price = 1500,
		color = Color3.fromRGB(245, 245, 245),
	},
	{
		id = "ball_fuego",
		name = "Balón de fuego",
		category = "ballskin",
		price = 15000,
		color = Color3.fromRGB(255, 110, 40),
	},
	{
		id = "ball_oro",
		name = "Balón de oro",
		category = "ballskin",
		price = 75000,
		color = Color3.fromRGB(255, 205, 60),
	},
} :: { Item }

-- SOLO PRUEBAS: ids que se desbloquean y equipan solos al entrar en Studio.
-- Sirve para probar el inventario sin tener sistema de compra todavía.
-- Se IGNORA fuera de Studio. Ejemplo: { "pet_perrito", "ball_fuego" }
Catalog.DebugUnlocked = {}

----- Índices y validación (se construyen al cargar el módulo) -----

local itemsById: { [string]: Item } = {}
local itemsByCategory: { [string]: { Item } } = {}
local categoriesById: { [string]: Category } = {}

for _, category in Catalog.Categories do
	assert(categoriesById[category.id] == nil, `Catalog: categoría duplicada "{category.id}"`)
	categoriesById[category.id] = category
	itemsByCategory[category.id] = {}
end

for _, item in Catalog.Items do
	assert(item.id ~= "", "Catalog: hay un item con id vacío")
	assert(itemsById[item.id] == nil, `Catalog: id duplicado "{item.id}"`)
	assert(
		categoriesById[item.category] ~= nil,
		`Catalog: el item "{item.id}" usa una categoría que no existe: "{item.category}"`
	)
	itemsById[item.id] = item
	table.insert(itemsByCategory[item.category], item)
end

----- Consultas -----

-- Devuelve el item, o nil si el id no existe. Acepta "" (nada equipado) y los
-- ids de items borrados del catálogo, así que es seguro llamarla con lo que
-- venga guardado en un perfil antiguo.
function Catalog.GetItem(itemId: string?): Item?
	if itemId == nil or itemId == "" then
		return nil
	end
	return itemsById[itemId]
end

function Catalog.GetCategory(categoryId: string): Category?
	return categoriesById[categoryId]
end

-- Todos los items de una categoría, en el orden en que están escritos arriba
-- (el orden importa: será el de la tienda).
function Catalog.GetItems(categoryId: string): { Item }
	return itemsByCategory[categoryId] or {}
end

-- Suma el coinBonus de todo lo que el jugador lleve equipado.
-- Función pura sobre la tabla `Equipped` del perfil: así el CurrencyService
-- aplica el bonus sin depender del servicio de inventario.
function Catalog.GetCoinBonus(equipped: { [string]: string }?): number
	if equipped == nil then
		return 0
	end

	local bonus = 0
	for _, itemId in equipped do
		local item = Catalog.GetItem(itemId)
		if item and item.coinBonus then
			bonus += item.coinBonus
		end
	end
	return bonus
end

return Catalog
