-- Config: todos os números de balanceamento do jogo ficam aqui.
-- Versão de TESTE: mundo 1 com as fases 1-1, 1-2 e 1-3 jogáveis.

local Config = {}

-- 70 inimigos por fase (como no conceito). Balanceado por simulação: Ato 1 ~4h15 de farm.
Config.MonstrosPorFase = 70
-- Quantos monstros ficam vivos no mapa ao mesmo tempo.
Config.MonstrosVivos = 5
-- Mapa pequeno: cada fase é uma arena redonda e compacta.
Config.RaioArena = 24 -- raio do chão da arena
Config.RaioMonstros = 19 -- até onde os monstros aparecem (dentro da arena)

Config.Heroi = {
	Dano = 10, -- dano base de cada golpe
	DanoPorNivel = 1.0, -- dano extra a cada nível (pouco: o que importa é o equipamento e o treino)
	Variacao = 0.25, -- o dano varia 25% para mais ou para menos
	ChanceCritico = 0.10, -- 10% de chance de crítico (o elmo aumenta)
	MultCritico = 2.5, -- crítico causa 2,5x o dano
	Alcance = 8, -- distância para conseguir bater
	AlcanceChefe = 12, -- o chefe é grande: dá para bater nele de mais longe
	Intervalo = 0.5, -- segundos entre golpes
	Velocidade = 16, -- velocidade de andar (as botas aumentam)
	Vida = 120, -- vida no nível 1 (a armadura aumenta)
	VidaPorNivel = 16, -- vida extra a cada nível
	Regeneracao = 0.04, -- recupera 4% da vida por segundo quando não apanha há 2 segundos
}

-- XP necessário para passar do nível N para o N+1
function Config.XPParaNivel(nivel)
	return math.floor(40 * nivel ^ 1.35)
end

-- Mundos e fases. As fases sem dados aparecem como "em breve" no portal.
Config.Mundos = {
	{ nome = "Vila Oculta do Bambu", totalFases = 10 },
	{ nome = "Floresta Sombria", totalFases = 10 },
	{ nome = "Vale de Cristal", totalFases = 10 },
}

-- tema = cenário e iluminação (ver src/server/Cenario.luau)
-- modelo = visual do inimigo (ver src/server/Modelos.luau)
-- chefe = true: só 1 inimigo grande, com barra de vida no topo e baú especial
local function fase(numero, tema, modelo, monstro, nivel, ouro, xp, extra)
	local f = {
		mundo = 1,
		numero = numero,
		nome = "1-" .. numero,
		tema = tema,
		modelo = modelo,
		monstro = monstro,
		nivel = nivel, -- nível do inimigo: aumenta vida e dano (ver Config.Inimigo)
		ouro = ouro,
		xp = xp,
	}
	for k, v in pairs(extra or {}) do
		f[k] = v
	end
	return f
end

Config.Fases = {
	-- Vila: ninjas fraquinhos
	fase(1, "vila", "novato", "Ninja Novato", 1, 2, 6),
	fase(2, "vila", "mascarado", "Ninja Mascarado", 3, 4, 10),
	fase(3, "vila", "elite", "Ninja de Elite", 5, 7, 16),
	-- Covil da cobra: a galera do Dorochimaru
	fase(4, "pantano", "discipulo", "Discípulo do Dorochimaru", 7, 10, 22),
	fase(5, "pantano", "cloneDoro", "Clone do Dorochimaru", 9, 14, 30),
	fase(6, "pantano", "dorochimaru", "Dorochimaru", 11, 19, 40),
	-- Crepúsculo: a galera da Katsuki
	fase(7, "crepusculo", "recrutaKatsuki", "Recruta da Katsuki", 13, 25, 52),
	fase(8, "crepusculo", "itachu", "Itachu da Katsuki", 15, 32, 66),
	fase(9, "crepusculo", "caminhoPen", "Caminho do Pen", 17, 40, 82),
	-- Chefe final do mundo 1
	fase(10, "chefe", "pen", "Pen", 20, 400, 600, { chefe = true }),
}

-- Inimigos: vida e dano crescem com o nível (fórmula provisória, ver Quadro de Avisos)
Config.Inimigo = {
	VidaBase = 30, -- vida no nível 1
	VidaCrescimento = 1.22, -- cada nível multiplica a vida por isto (jogo difícil!)
	DanoBase = 2, -- dano de cada golpe no nível 1
	DanoPorNivel = 1.1, -- dano extra a cada nível do inimigo
	MultChefe = 14, -- o chefe tem 14x a vida de um inimigo do mesmo nível
	AtaqueIntervalo = 1.6, -- segundos entre os golpes de cada inimigo
	AtaqueAlcance = 5.5, -- distância para o inimigo conseguir bater no herói
	DanoChefeGolpe = 1.3, -- o golpe normal do chefe dá 1,3x o dano do nível dele
}

function Config.VidaInimigo(nivel, chefe)
	local v = Config.Inimigo.VidaBase * Config.Inimigo.VidaCrescimento ^ (nivel - 1)
	if chefe then
		v *= Config.Inimigo.MultChefe
	end
	return math.floor(v + 0.5)
end

function Config.DanoInimigo(nivel)
	return math.floor(Config.Inimigo.DanoBase + Config.Inimigo.DanoPorNivel * (nivel - 1) + 0.5)
end
-- Baú especial que o chefe dropa
-- Treinamento: gasta ouro para subir atributos permanentes.
-- custo do próximo nível = custoBase * crescimento ^ nível atual
Config.Treino = {
	{
		id = "forca",
		nome = "Força",
		icone = "💪",
		texto = "+%d de dano por nível",
		valor = 1.5,
		custoBase = 25,
		crescimento = 1.2,
		max = 200,
	},
	{
		id = "vitalidade",
		nome = "Vitalidade",
		icone = "❤️",
		texto = "+%d de vida por nível",
		valor = 14,
		custoBase = 25,
		crescimento = 1.2,
		max = 200,
	},
	{
		id = "precisao",
		nome = "Precisão",
		icone = "🎯",
		texto = "+0,5% de crítico por nível",
		valor = 0.005,
		custoBase = 40,
		crescimento = 1.22,
		max = 60,
	},
	{
		id = "ganancia",
		nome = "Ganância",
		icone = "💰",
		texto = "+3% de ouro por nível",
		valor = 0.03,
		custoBase = 60,
		crescimento = 1.25,
		max = 50,
	},
}

function Config.CustoTreino(t, nivel)
	return math.floor(t.custoBase * t.crescimento ^ nivel + 0.5)
end

-- Tempo para derrotar o chefe. Se acabar, o herói volta uma fase (regra do CONTEXTO.md).
Config.ChefeTempo = 90

-- Nomes dos equipamentos por categoria e tier (T1 = Comum ... T5 = Lendário)
Config.NomesItens = {
	arma = {
		"Kunai Enferrujada",
		"Kunai de Aço",
		"Katana Afiada",
		"Lâmina das Sombras",
		"Espada do Trovão",
		"Lâmina do Dragão",
		"Espada dos Seis Caminhos",
		"Lâmina do Vazio",
	},
	elmo = {
		"Bandana de Pano",
		"Bandana Reforçada",
		"Máscara ANBU",
		"Elmo do Crepúsculo",
		"Coroa do Sábio",
		"Máscara do Dragão",
		"Coroa dos Seis Caminhos",
		"Máscara do Vazio",
	},
	armadura = {
		"Colete de Treino",
		"Colete de Chunin",
		"Armadura ANBU",
		"Manto da Katsuki",
		"Manto do Sábio",
		"Armadura do Dragão",
		"Manto dos Seis Caminhos",
		"Manto do Vazio",
	},
	botas = {
		"Sandálias Gastas",
		"Sandálias Ninja",
		"Botas Silenciosas",
		"Botas do Vento",
		"Botas do Relâmpago",
		"Botas do Dragão",
		"Botas dos Seis Caminhos",
		"Botas do Vazio",
	},
}

-- Drops do chefe Pen (aparecem embaixo da barra de vida dele e no portal)
-- Conjuntos (sets) do Ato 1: peças especiais com bônus ao vestir 2 e 4 do mesmo conjunto
Config.Conjuntos = {
	{
		id = "vila",
		nome = "Conjunto da Vila Oculta",
		cor = Color3.fromRGB(110, 210, 90),
		fases = { 1, 5 }, -- cai nas fases 1-1 a 1-5
		chance = 0.30, -- 30% dos drops dessas fases são peças do conjunto
		pecas = {
			arma = "Kunai da Vila",
			elmo = "Bandana da Vila",
			armadura = "Colete da Vila",
			botas = "Sandálias da Vila",
		},
		bonus = {
			[2] = { danoPct = 0.10, texto = "2 peças: +10% de dano" },
			[4] = { vidaPct = 0.20, critico = 0.05, texto = "4 peças: +20% de vida e +5% de crítico" },
		},
	},
	{
		id = "katsuki",
		nome = "Conjunto da Katsuki",
		cor = Color3.fromRGB(225, 55, 65),
		fases = { 6, 10 },
		chance = 0.30,
		pecas = {
			arma = "Lâmina da Katsuki",
			elmo = "Chapéu da Katsuki",
			armadura = "Manto da Katsuki",
			botas = "Sandálias da Katsuki",
		},
		bonus = {
			[2] = { critico = 0.08, texto = "2 peças: +8% de crítico" },
			[4] = { danoPct = 0.30, vidaPct = 0.15, texto = "4 peças: +30% de dano e +15% de vida" },
		},
	},
}

function Config.ConjuntoPorId(id)
	for _, c in ipairs(Config.Conjuntos) do
		if c.id == id then
			return c
		end
	end
end

-- Avatares: chance mínima de dropar a "skin" do inimigo da fase. Troca o corpo do herói e dá buff.
Config.Avatares = {
	ChanceNormal = 0.0015, -- 0,15% por inimigo derrotado
	ChanceChefe = 0.01, -- 1% por vitória contra o Pen
	OuroRepetido = 50, -- se já tiver o avatar, vira ouro (x nível da fase)
	-- raridade do avatar de cada fase (1-1 até 1-10)
	Raridade = { "comum", "comum", "comum", "incomum", "incomum", "raro", "raro", "epico", "lendario", "secreto" },
	-- buff do avatar em uso, pela raridade
	Buff = {
		comum = { danoPct = 0.02, texto = "+2% de dano" },
		incomum = { danoPct = 0.04, vidaPct = 0.02, texto = "+4% dano +2% vida" },
		raro = { danoPct = 0.06, vidaPct = 0.05, texto = "+6% dano +5% vida" },
		epico = { danoPct = 0.10, vidaPct = 0.08, critico = 0.02, texto = "+10% dano +8% vida +2% crít." },
		lendario = {
			danoPct = 0.15,
			vidaPct = 0.12,
			critico = 0.04,
			texto = "+15% dano +12% vida +4% crít.",
		},
		secreto = {
			danoPct = 0.30,
			vidaPct = 0.25,
			critico = 0.08,
			texto = "+30% dano +25% vida +8% crít.",
		},
	},
	-- modelo de roupa usado para trocar o corpo (o Pen grandão é de malha; usa a roupa do Caminho do Pen)
	Roupa = { pen = "caminhoPen" },
}

-- Baú de estágio (estilo TBH): toda fase vencida dá um baú
Config.BauEstagio = {
	OuroMult = 6, -- ouro = ouro do inimigo da fase x 6
	ChanceItem = 0.25, -- 25% de chance de vir um equipamento
}

-- Venda automática: itens dessas raridades (e abaixo) viram ouro na hora (fora de conjuntos)
Config.AutoVendaOpcoes = { "nada", "comum", "incomum", "raro" }

Config.DropsChefe = {
	Ouro = 150,
	-- sempre cai 1 equipamento, sorteado por estas chances
	Equipamento = { { "epico", 0.75 }, { "lendario", 0.22 }, { "mitico", 0.03 } },
	-- itens especiais com chance própria
	Especiais = {
		{ nome = "Lâmina de Chakra Negro", slot = "arma", raridade = "mitico", chance = 0.04, icone = "🗡️" },
		-- Secreto (preto): por enquanto só o Rinnegan, só do Pen e bem raro
		{ nome = "Rinnegan", slot = "olho", raridade = "secreto", chance = 0.01, icone = "👁️", valor = 1.0 },
	},
}
------------------------------------------------------------------------
-- Loot
------------------------------------------------------------------------
Config.ChanceDrop = 0.03 -- 3% dos monstros dropam um equipamento (item é raro!)

-- Nível do item que cai: mistura o nível do inimigo com o do herói, com variação.
-- Fórmula provisória, ver Quadro de Avisos.
Config.ItemNivel = {
	PesoInimigo = 0.7, -- 70% do nível do inimigo
	PesoHeroi = 0.3, -- 30% do nível do herói
	Variacao = 2, -- até 2 níveis para mais ou para menos
	CrescimentoPorNivel = 0.15, -- cada nível deixa o item 15% mais forte
}
Config.LimiteInventario = 40 -- passou disso, o item vira ouro automaticamente

Config.Raridades = {
	{
		id = "comum",
		nome = "Comum",
		peso = 62,
		mult = 1.0,
		cor = Color3.fromRGB(170, 170, 175),
		material = "de Madeira",
	},
	{
		id = "incomum",
		nome = "Incomum",
		peso = 26,
		mult = 1.6,
		cor = Color3.fromRGB(90, 200, 100),
		material = "de Ferro",
	},
	{
		id = "raro",
		nome = "Raro",
		peso = 9,
		mult = 2.5,
		cor = Color3.fromRGB(70, 150, 255),
		material = "de Cristal",
	},
	{
		id = "epico",
		nome = "Épico",
		peso = 2.5,
		mult = 4.0,
		cor = Color3.fromRGB(175, 90, 255),
		material = "das Estrelas",
	},
	{
		id = "lendario",
		nome = "Lendário",
		peso = 0.5,
		mult = 7.0,
		cor = Color3.fromRGB(255, 160, 40),
		material = "do Abismo",
	},
	{
		id = "mitico",
		nome = "Mítico",
		peso = 0, -- não cai de monstro comum: só do chefe ou da forja
		mult = 12.0,
		cor = Color3.fromRGB(255, 70, 110),
		material = "Mítico",
	},
	{
		id = "imortal",
		nome = "Imortal",
		peso = 0, -- só da forja (3 Míticos). Chance de cair: a decidir (Quadro de Avisos)
		mult = 20.0,
		cor = Color3.fromRGB(255, 235, 110),
		material = "Imortal",
		forjavel = false, -- por enquanto o Imortal não vira Secreto na forja
	},
	{
		id = "secreto",
		nome = "Secreto",
		peso = 0, -- por enquanto só o Rinnegan do chefe Pen
		mult = 35.0,
		cor = Color3.fromRGB(20, 18, 24), -- item preto
		corBorda = Color3.fromRGB(235, 235, 255),
		material = "Secreto",
		forjavel = false,
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
		atributo = "vida",
		valor = 15,
		texto = "+%d de vida",
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
	{
		id = "olho",
		nome = "Olho",
		base = "Olho",
		icone = "👁️",
		atributo = "danoMult",
		valor = 0.5,
		texto = "+%d%% de dano",
		especial = true, -- não cai aleatório: só o Rinnegan do chefe
	},
}

-- Forja: junta itens iguais em raridade para criar 1 item da raridade de cima.
Config.Forja = {
	Quantidade = 3, -- quantos itens entram
	Custo = { comum = 10, incomum = 30, raro = 90, epico = 250, lendario = 700, mitico = 2000 }, -- ouro por forja
}

-- Quanto ouro um item vale ao vender
Config.ValorVenda =
	{ comum = 3, incomum = 8, raro = 20, epico = 50, lendario = 150, mitico = 400, imortal = 1200, secreto = 5000 }

return Config
