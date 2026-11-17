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
	fase(7, "crepusculo", "recrutaKatsuki", "Recruta da Katsuki", 14, 25, 52),
	fase(8, "crepusculo", "itachu", "Itachu da Katsuki", 17, 32, 66),
	fase(9, "crepusculo", "caminhoPen", "Caminho do Pen", 20, 40, 82),
	-- Chefe final do mundo 1
	fase(10, "chefe", "pen", "Pen", 24, 400, 600, { chefe = true }),
}

-- Inimigos: vida e dano crescem com o nível (fórmula provisória, ver Quadro de Avisos)
Config.Inimigo = {
	VidaBase = 30, -- vida no nível 1
	VidaCrescimento = 1.18, -- cada nível multiplica a vida por isto
	DanoBase = 4, -- dano no nível 1 (os inimigos ainda não atacam o herói)
	DanoPorNivel = 1.5,
	MultChefe = 12, -- o chefe tem 12x a vida de um inimigo do mesmo nível
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
Config.BauChefe = {
	Ouro = 150,
	ChanceLendario = 0.25, -- senão vem um Épico
	ChanceOlho = 0.20, -- 20% de chance de vir também o Olho do Além-Ciclo
}

-- O olho raro que só o chefe Pen dropa ("além do Rinnegan")
Config.OlhoChefe = {
	nome = "Olho do Além-Ciclo",
	raridade = "mitico",
	danoMult = 0.5, -- +50% de dano
}
------------------------------------------------------------------------
-- Loot
------------------------------------------------------------------------
Config.ChanceDrop = 0.07 -- 7% dos monstros dropam um equipamento (item é raro!)

-- Nível do item que cai: mistura o nível do inimigo com o do herói, com variação.
-- Fórmula provisória, ver Quadro de Avisos.
Config.ItemNivel = {
	PesoInimigo = 0.7, -- 70% do nível do inimigo
	PesoHeroi = 0.3, -- 30% do nível do herói
	Variacao = 2, -- até 2 níveis para mais ou para menos
	CrescimentoPorNivel = 0.12, -- cada nível deixa o item 12% mais forte
}
Config.LimiteInventario = 40 -- passou disso, o item vira ouro automaticamente

Config.Raridades = {
	{
		id = "comum",
		nome = "Comum",
		peso = 50,
		mult = 1.0,
		cor = Color3.fromRGB(170, 170, 175),
		material = "de Madeira",
	},
	{
		id = "incomum",
		nome = "Incomum",
		peso = 30,
		mult = 1.6,
		cor = Color3.fromRGB(90, 200, 100),
		material = "de Ferro",
	},
	{
		id = "raro",
		nome = "Raro",
		peso = 14,
		mult = 2.5,
		cor = Color3.fromRGB(70, 150, 255),
		material = "de Cristal",
	},
	{
		id = "epico",
		nome = "Épico",
		peso = 5,
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
		forjavel = false, -- o Lendário não vira nada na forja
	},
	{
		id = "mitico",
		nome = "Mítico",
		peso = 0, -- não cai de monstro comum: só do baú do chefe
		mult = 12.0,
		cor = Color3.fromRGB(255, 70, 110),
		material = "",
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
	{
		id = "olho",
		nome = "Olho",
		base = "Olho",
		icone = "👁️",
		atributo = "danoMult",
		valor = 0.5,
		texto = "+%d%% de dano",
		especial = true, -- não cai aleatório: só o Olho do Além-Ciclo do chefe
	},
}

-- Forja: junta itens iguais em raridade para criar 1 item da raridade de cima.
Config.Forja = {
	Quantidade = 3, -- quantos itens entram
	Custo = { comum = 10, incomum = 30, raro = 90, epico = 250 }, -- ouro cobrado por forja
}

-- Quanto ouro um item vale ao vender
Config.ValorVenda = { comum = 3, incomum = 8, raro = 20, epico = 50, lendario = 150, mitico = 1000 }

return Config
