--!strict
-- Funções pequenas usadas pelo servidor e pela tela.

local Config = require(script.Parent.Config)

local Util = {}

-- Sorteia uma chave de uma tabela de pesos. Ex.: { comum = 70, raro = 30 }
function Util.sortearPeso(pesos: { [string]: number }, rng: Random?): string
	local gerador = rng or Random.new()
	local total = 0
	-- percorre na ordem das raridades para o resultado não depender da ordem da tabela
	local ordem = {}
	for _, raridade in Config.OrdemRaridades do
		local peso = pesos[raridade]
		if peso and peso > 0 then
			table.insert(ordem, raridade)
			total += peso
		end
	end
	local alvo = gerador:NextNumber() * total
	for _, raridade in ordem do
		alvo -= pesos[raridade]
		if alvo <= 0 then
			return raridade
		end
	end
	return ordem[#ordem]
end

-- Chances em porcentagem, na ordem das raridades, para mostrar na tela.
function Util.chances(pesos: { [string]: number }): { { raridade: string, porcento: number } }
	local total = 0
	for _, peso in pesos do
		total += peso
	end
	local lista = {}
	for _, raridade in Config.OrdemRaridades do
		local peso = pesos[raridade]
		if peso and peso > 0 then
			table.insert(lista, { raridade = raridade, porcento = peso / total * 100 })
		end
	end
	return lista
end

function Util.criaturasDaRaridade(raridade: string): { Config.Criatura }
	local lista = {}
	for _, criatura in Config.Criaturas do
		if criatura.raridade == raridade then
			table.insert(lista, criatura)
		end
	end
	return lista
end

function Util.proximaRaridade(raridade: string): string?
	for i, r in Config.OrdemRaridades do
		if r == raridade then
			return Config.OrdemRaridades[i + 1]
		end
	end
	return nil
end

-- Id da Mistureba sem a mutação ("tubarone*dourada" -> "tubarone").
function Util.idBase(id: string): string
	return (string.match(id, "^[^*]+") or id)
end

-- Sorteia a mutação de um ovo chocado (ou nada). mult aumenta as chances (Sorte Dupla).
function Util.clima(id: string?): Config.Clima?
	for _, cl in Config.Climas.lista do
		if cl.id == id then
			return cl
		end
	end
	return nil
end

-- clima: id do clima que está acontecendo agora (ou nil)
function Util.sortearMutacao(rng: Random, mult: number?, clima: string?): string?
	local x = rng:NextNumber() * 100
	local soma = 0
	local def = Util.clima(clima)
	for _, m in Config.Mutacoes do
		if m.soClima and m.soClima ~= clima then
			continue
		end
		local extra = if def and def.mutacao then def.mutacao[m.id] or 1 else 1
		soma += m.chance * (mult or 1) * extra
		if x < soma then
			return m.id
		end
	end
	return nil
end

-- Melhorias compradas com moedas
function Util.upgrade(id: string): Config.Upgrade?
	for _, u in Config.Upgrades do
		if u.id == id then
			return u
		end
	end
	return nil
end

function Util.precoUpgrade(u: Config.Upgrade, nivel: number): number
	return math.floor(u.precoBase * u.crescimento ^ nivel)
end

-- Quanto a melhoria dá no nível atual (ex.: renda nível 3 = 0.3)
function Util.efeitoUpgrade(upgrades: { [string]: number }?, id: string): number
	local u = Util.upgrade(id)
	if not u or not upgrades then
		return 0
	end
	return (upgrades[id] or 0) * u.porNivel
end

-- Bônus de renda da Misturedex (0.25 = +25%) e o próximo marco.
function Util.bonusDex(achadas: number): (number, { achadas: number, bonus: number }?)
	local bonus = 0
	local proximo = nil
	for _, marco in Config.MarcosDex do
		if achadas >= marco.achadas then
			bonus = marco.bonus
		elseif not proximo then
			proximo = marco
		end
	end
	return bonus, proximo
end

function Util.receita(a: string, b: string): string?
	a, b = Util.idBase(a), Util.idBase(b)
	for _, receita in Config.Receitas do
		if (receita.a == a and receita.b == b) or (receita.a == b and receita.b == a) then
			return receita.resultado
		end
	end
	return nil
end

-- 1234567 -> "1,2 mi"
function Util.numero(n: number): string
	local sufixos = { { 1e12, " tri" }, { 1e9, " bi" }, { 1e6, " mi" }, { 1e3, " mil" } }
	for _, s in sufixos do
		if n >= s[1] then
			local texto = string.format("%.1f", n / s[1]):gsub("%.0$", ""):gsub("%.", ",")
			return texto .. s[2]
		end
	end
	return tostring(math.floor(n))
end

-- Chance REAL de tirar essa Mistureba num ovo da chuva, no formato "1 em X".
-- Usa as chances da chuva (raridade), quantas Misturebas tem na raridade e a
-- chance da mutação. Secretas só saem por receita, então devolvem nil.
local cacheUmEm: { [string]: number } = {}
function Util.umEm(id: string): number?
	if cacheUmEm[id] then
		return cacheUmEm[id]
	end
	local def = Config.PorId[id]
	if not def then
		return nil
	end
	local pesos = Config.Chuva.pesos
	local total = 0
	for _, peso in pesos do
		total += peso
	end
	local peso = pesos[def.raridade]
	if not peso or peso <= 0 then
		return nil
	end
	local p = peso / total / #Util.criaturasDaRaridade(def.raridade)
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	if mut then
		p *= mut.chance / 100
	end
	local x = math.max(1, math.floor(1 / p + 0.5))
	cacheUmEm[id] = x
	return x
end

-- "1 em 37", "1 em 2,4 mil", ou "Receita secreta"
function Util.textoUmEm(id: string): string
	local x = Util.umEm(id)
	if not x then
		return "Receita secreta"
	end
	return "1 em " .. Util.numero(x)
end

-- cor do "1 em X": quanto mais difícil, mais quente
function Util.corUmEm(id: string): Color3
	local x = Util.umEm(id) or 1e9
	if x >= 100000 then
		return Color3.fromRGB(255, 90, 200)
	elseif x >= 10000 then
		return Color3.fromRGB(255, 120, 80)
	elseif x >= 1000 then
		return Color3.fromRGB(255, 205, 60)
	elseif x >= 100 then
		return Color3.fromRGB(150, 220, 255)
	end
	return Color3.fromRGB(220, 220, 230)
end

return Util
