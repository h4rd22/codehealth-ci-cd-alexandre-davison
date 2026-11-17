-- Config: todos os números de balanceamento do jogo ficam aqui.
-- Versão de TESTE: mundo 1 com as fases 1-1, 1-2 e 1-3 jogáveis.

local Config = {}

-- No jogo final serão 70 monstros por fase. No teste, 10 para ir rápido.
Config.MonstrosPorFase = 10
-- Quantos monstros ficam vivos no mapa ao mesmo tempo.
Config.MonstrosVivos = 5
-- Mapa pequeno: cada fase é uma arena redonda e compacta.
Config.RaioArena = 24 -- raio do chão da arena
Config.RaioMonstros = 19 -- até onde os monstros aparecem (dentro da arena)

Config.Heroi = {
	Dano = 12, -- dano base de cada golpe
	DanoPorNivel = 2, -- dano extra a cada nível
	Variacao = 0.25, -- o dano varia 25% para mais ou para menos
	ChanceCritico = 0.10, -- 10% de chance de crítico (o elmo aumenta)
	MultCritico = 2.5, -- crítico causa 2,5x o dano
	Alcance = 8, -- distância para conseguir bater
	Intervalo = 0.5, -- segundos entre golpes
	Velocidade = 16, -- velocidade de andar (as botas aumentam)
}

-- XP necessário para passar do nível N para o N+1
function Config.XPParaNivel(nivel)
	return math.floor(40 * nivel ^ 1.35)
end

-- Mundos e fases. Só as fases com "monstro" já existem; o resto aparece como "em breve".
Config.Mundos = {
	{ nome = "Campos Verdes", totalFases = 10 },
	{ nome = "Floresta Sombria", totalFases = 10 },
	{ nome = "Vale de Cristal", totalFases = 10 },
}

Config.Fases = {
	{
		mundo = 1,
		numero = 1,
		nome = "1-1",
		monstro = "Gosma Verde",
		forma = "bola",
		vida = 30,
		ouro = 2,
		xp = 6,
		tamanho = 3,
		cor = Color3.fromRGB(90, 210, 110),
		chao = Color3.fromRGB(105, 150, 85),
	},
	{
		mundo = 1,
		numero = 2,
		nome = "1-2",
		monstro = "Cogumelo Bravo",
		forma = "cogumelo",
		vida = 60,
		ouro = 4,
		xp = 10,
		tamanho = 3.6,
		cor = Color3.fromRGB(215, 95, 70),
		chao = Color3.fromRGB(125, 110, 80),
	},
	{
		mundo = 1,
		numero = 3,
		nome = "1-3",
		monstro = "Lobo de Pedra",
		forma = "bloco",
		vida = 110,
		ouro = 7,
		xp = 16,
		tamanho = 4.4,
		cor = Color3.fromRGB(140, 145, 170),
		chao = Color3.fromRGB(90, 92, 108),
	},
}

------------------------------------------------------------------------
-- Loot
------------------------------------------------------------------------
Config.ChanceDrop = 0.30 -- 30% dos monstros dropam um equipamento
Config.LimiteInventario = 40 -- passou disso, o item vira ouro automaticamente

Config.Raridades = {
	{
		id = "comum",
		nome = "Comum",
		peso = 60,
		mult = 1.0,
		cor = Color3.fromRGB(170, 170, 175),
		material = "de Madeira",
	},
	{
		id = "incomum",
		nome = "Incomum",
		peso = 25,
		mult = 1.6,
		cor = Color3.fromRGB(90, 200, 100),
		material = "de Ferro",
	},
	{
		id = "raro",
		nome = "Raro",
		peso = 10,
		mult = 2.5,
		cor = Color3.fromRGB(70, 150, 255),
		material = "de Cristal",
	},
	{
		id = "epico",
		nome = "Épico",
		peso = 4,
		mult = 4.0,
		cor = Color3.fromRGB(175, 90, 255),
		material = "das Estrelas",
	},
	{
		id = "lendario",
		nome = "Lendário",
		peso = 1,
		mult = 7.0,
		cor = Color3.fromRGB(255, 160, 40),
		material = "do Abismo",
	},
}

-- Cada parte do equipamento melhora uma coisa diferente.
Config.Slots = {
	{
		id = "arma",
		nome = "Arma",
		base = "Lâmina",
		icone = "⚔️",
		atributo = "dano",
		valor = 3,
		texto = "+%d de dano",
	},
	{
		id = "elmo",
		nome = "Elmo",
		base = "Elmo",
		icone = "⛑️",
		atributo = "critico",
		valor = 0.02,
		texto = "+%d%% de crítico",
	},
	{
		id = "armadura",
		nome = "Armadura",
		base = "Peitoral",
		icone = "🛡️",
		atributo = "ouro",
		valor = 0.06,
		texto = "+%d%% de ouro",
	},
	{
		id = "botas",
		nome = "Botas",
		base = "Botas",
		icone = "👢",
		atributo = "velocidade",
		valor = 1,
		texto = "+%d de velocidade",
	},
}

-- Forja: junta itens iguais em raridade para criar 1 item da raridade de cima.
Config.Forja = {
	Quantidade = 3, -- quantos itens entram
	Custo = { comum = 10, incomum = 30, raro = 90, epico = 250 }, -- ouro cobrado por forja
}

-- Quanto ouro um item vale ao vender
Config.ValorVenda = { comum = 3, incomum = 8, raro = 20, epico = 50, lendario = 150 }

return Config
