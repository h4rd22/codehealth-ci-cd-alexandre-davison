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
function Util.sortearMutacao(rng: Random, mult: number?): string?
	local x = rng:NextNumber() * 100
	local soma = 0
	for _, m in Config.Mutacoes do
		soma += m.chance * (mult or 1)
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

return Util
