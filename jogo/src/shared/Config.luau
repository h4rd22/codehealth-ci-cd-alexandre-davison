-- Config: todos os números de balanceamento do jogo ficam aqui.
-- Versão de TESTE: mundo 1 com as fases 1-1, 1-2 e 1-3 jogáveis.

local Config = {}

-- 70 inimigos por fase (como no conceito). Balanceado por simulação: Ato 1 ~4h15 de farm.
Config.MonstrosPorFase = 70
-- Quantos monstros ficam vivos no mapa ao mesmo tempo.
-- Mapa: "linear" = estrada reta, o herói anda para frente e enfrenta hordas no caminho (estilo TBH).
-- "arena" = mapa redondo antigo.
Config.Mapa = {
	Modo = "linear",
	Comprimento = 420, -- tamanho da estrada (studs)
	Largura = 20, -- largura da estrada
	HordaTamanho = 7, -- inimigos por horda (10 hordas = 70 inimigos)
	-- no começo do jogo (Normal, Ato 1) as hordas são menores: 3 inimigos na 1-1 até 7 na 1-9
	HordaInicio = { 3, 3, 4, 4, 5, 5, 6, 6, 7 },
	DistanciaHorda = 34, -- a próxima horda aparece esta distância à frente do herói
	Aggro = 26, -- os inimigos veem o herói desta distância e correm para atacar
	VelocidadeInimigo = 11, -- velocidade dos inimigos correndo
	DanoHorda = 0.6, -- na horda todos batem juntos: cada um bate 60% do normal
	CuraHorda = 0.25, -- vencer uma horda recupera 25% da vida
}
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
	CriticoMaximo = 0.75, -- a chance de crítico nunca passa de 75%
	Alcance = 8, -- distância para conseguir bater
	AlcanceChefe = 12, -- o chefe é grande: dá para bater nele de mais longe
	Intervalo = 0.5, -- segundos entre golpes
	Velocidade = 16, -- velocidade de andar (as botas aumentam)
	Vida = 120, -- vida no nível 1 (a armadura aumenta)
	VidaPorNivel = 16, -- vida extra a cada nível
	Regeneracao = 0.04, -- recupera 4% da vida por segundo quando não apanha há 2 segundos
}

-- XP necessário para passar do nível N para o N+1
-- XP que um inimigo dá (cresce 6% por nível do inimigo)
function Config.XPInimigo(nivel)
	return math.max(1, math.floor(5 * 1.06 ^ (nivel - 1) + 0.5))
end
-- XP para passar de nível: uns 90 inimigos do seu nível no começo, ~300 no nível 100.
-- O jogo termina lá pelo nível 105-110 (ver simulação no painel).
function Config.XPParaNivel(nivel)
	-- primeiros níveis rápidos (nível 2 com ~23 inimigos), depois ~90 a ~300 inimigos por nível
	return math.floor(Config.XPInimigo(nivel) * math.min(90 + 2 * nivel, 15 + 8 * nivel))
end
-- Inimigo muito mais fraco que você dá pouco XP: o nível acompanha o conteúdo
function Config.MultXP(nivelHeroi, nivelInimigo)
	local d = nivelHeroi - nivelInimigo
	return math.clamp(1 - 0.2 * math.max(0, d - 2), 0.05, 1)
end
-- Ouro de um inimigo (cresce junto com os preços)
function Config.OuroInimigo(nivel)
	return math.max(1, math.floor(2 * 1.065 ^ (nivel - 1) + 0.5))
end

-- Mundos e fases. As fases sem dados aparecem como "em breve" no portal.
-- Progressão estilo Task Bar Hero: 4 dificuldades, cada uma com 3 atos de 10 fases (120 fases).
-- Termina lá pelo nível 105-110. Vencer uma fase libera a próxima (Normal Ato 1 -> ... -> Tormento Ato 3).
Config.Dificuldades = {
	{
		id = "normal",
		nome = "Normal",
		cor = Color3.fromRGB(120, 210, 120),
		nivel = { 1, 34 }, -- nível dos inimigos da primeira à última fase
		-- chance de cada raridade nos drops (Comum ... Secreto). Bem raro: o forte vem da síntese.
		pesos = { 78, 18, 3.4, 0.55, 0.05, 0, 0, 0, 0 },
	},
	{
		id = "pesadelo",
		nome = "Pesadelo",
		trancada = true, -- outro anime, com outros chefes (em breve)
		cor = Color3.fromRGB(170, 110, 255),
		nivel = { 36, 60 },
		pesos = { 65, 26, 7, 1.7, 0.28, 0.02, 0, 0, 0 },
	},
	{
		id = "inferno",
		nome = "Inferno",
		trancada = true, -- outro anime, com outros chefes (em breve)
		cor = Color3.fromRGB(255, 110, 50),
		nivel = { 62, 84 },
		pesos = { 55, 30, 11, 3.3, 0.6, 0.09, 0.008, 0, 0 },
	},
	{
		id = "tormento",
		nome = "Tormento",
		trancada = true, -- outro anime, com outros chefes (em breve)
		cor = Color3.fromRGB(230, 40, 60),
		nivel = { 86, 104 },
		pesos = { 45, 33, 15, 5.5, 1.2, 0.25, 0.03, 0, 0 },
	},
}

-- Dificuldades trancadas ainda não podem ser jogadas (cada uma vai ser de outro anime)
Config.UltimaFaseJogavel = 0
for d, dif in ipairs(Config.Dificuldades) do
	if not dif.trancada then
		Config.UltimaFaseJogavel = d * 30
	end
end

-- Os 3 atos (iguais em toda dificuldade, só que mais fortes)
Config.Mundos = {
	{ nome = "Vila Oculta do Bambu", totalFases = 10 },
	{ nome = "Floresta Sombria", totalFases = 10 },
	{ nome = "Vale de Cristal", totalFases = 10 },
}
Config.Atos = Config.Mundos

-- inimigos de cada ato: { tema, modelo, nome }
local INIMIGOS_ATO = {
	{
		{ "vila", "novato", "Ninja Novato" },
		{ "vila", "mascarado", "Ninja Mascarado" },
		{ "vila", "elite", "Ninja de Elite" },
		{ "pantano", "discipulo", "Discípulo do Dorochimaru" },
		{ "pantano", "cloneDoro", "Clone do Dorochimaru" },
		{ "pantano", "dorochimaru", "Dorochimaru" },
		{ "crepusculo", "recrutaKatsuki", "Recruta da Katsuki" },
		{ "crepusculo", "itachu", "Itachu da Katsuki" },
		{ "crepusculo", "caminhoPen", "Caminho do Pen" },
		{ "chefe", "pen", "Pen" },
	},
	{
		{ "pantano", "neji", "Guardião Hyugo" },
		{ "pantano", "rockLee", "Rocky Li" },
		{ "pantano", "mascarado", "ANBU Renegado" },
		{ "pantano", "discipulo", "Espião do Som" },
		{ "pantano", "cloneDoro", "Experimento da Cobra" },
		{ "crepusculo", "sasori", "Sasoru das Marionetes" },
		{ "crepusculo", "recrutaKatsuki", "Sentinela da Katsuki" },
		{ "crepusculo", "elite", "Caçador Ninja" },
		{ "crepusculo", "itachu", "Sombra do Itachu" },
		{ "chefe", "deidara", "Deidaro, o Explosivo" },
	},
	{
		{ "crepusculo", "neji", "Hyugo Desperto" },
		{ "crepusculo", "rockLee", "Rocky Li dos Oito Portões" },
		{ "crepusculo", "sasori", "Marionete Viva" },
		{ "crepusculo", "dorochimaru", "Dorochimaru Imortal" },
		{ "crepusculo", "deidara", "Deidaro de Argila" },
		{ "chefe", "itachu", "Itachu do Sharingan" },
		{ "chefe", "caminhoPen", "Caminho Asura" },
		{ "chefe", "recrutaKatsuki", "Elite da Katsuki" },
		{ "chefe", "caminhoPen", "Caminho Preta" },
		{ "chefe", "madaro", "Madaro, o Fantasma Uchira" },
	},
}

Config.Fases = {}
for d, dif in ipairs(Config.Dificuldades) do
	for ato = 1, 3 do
		for numero = 1, 10 do
			local ini = INIMIGOS_ATO[ato][numero]
			local s = (ato - 1) * 10 + numero - 1 -- 0 a 29 dentro da dificuldade
			local chefe = numero == 10
			local nivel = math.floor(dif.nivel[1] + (dif.nivel[2] - dif.nivel[1]) * s / 29 + 0.5) + (chefe and 2 or 0)
			table.insert(Config.Fases, {
				dificuldade = d,
				mundo = ato, -- (nome antigo de "ato")
				ato = ato,
				numero = numero,
				nome = ato .. "-" .. numero,
				tema = ini[1],
				modelo = ini[2],
				monstro = ini[3],
				nivel = nivel, -- nível do inimigo: aumenta vida e dano (ver Config.Inimigo)
				ouro = Config.OuroInimigo(nivel) * (chefe and 200 or 1),
				xp = Config.XPInimigo(nivel) * (chefe and 25 or 1),
				chefe = chefe or nil,
				-- avatar: por enquanto só dos inimigos do Ato 1 (número da fase 1 a 10)
				avatar = ato == 1 and numero or nil,
			})
		end
	end
end
-- Nome completo de uma fase, ex.: "Pesadelo · Ato 2 · 2-7"
function Config.NomeFase(idx)
	local f = Config.Fases[idx]
	if not f then
		return "?"
	end
	return Config.Dificuldades[f.dificuldade].nome .. " · Ato " .. f.ato .. " · " .. f.nome
end
-- Itens especiais que o chefe desta fase pode soltar
function Config.EspeciaisDaFase(idx)
	local lista = {}
	for _, esp in ipairs(Config.DropsChefe.Especiais) do
		if not esp.soFase or esp.soFase == idx then
			table.insert(lista, esp)
		end
	end
	return lista
end

-- Índice da fase pela dificuldade, ato e número
function Config.IndiceFase(dificuldade, ato, numero)
	return (dificuldade - 1) * 30 + (ato - 1) * 10 + numero
end

-- Inimigos: vida e dano crescem com o nível (fórmula provisória, ver Quadro de Avisos)
Config.Inimigo = {
	VidaBase = 30, -- vida no nível 1
	VidaCrescimento = 1.09, -- cada nível multiplica a vida por 1,09 (os itens crescem só 1,06: precisa de síntese)
	DanoBase = 2, -- dano de cada golpe no nível 1
	DanoCrescimento = 1.065, -- cada nível multiplica o dano por isto
	MultChefe = 14, -- o chefe tem 14x a vida de um inimigo do mesmo nível
	AtaqueIntervalo = 1.6, -- segundos entre os golpes de cada inimigo
	AtaqueAlcance = 5.5, -- distância para o inimigo conseguir bater no herói
	DanoChefeGolpe = 1.3, -- o golpe normal do chefe dá 1,3x o dano do nível dele
	-- Reforço do começo: o Ato 1 dura pelo menos ~1 hora. Os inimigos têm vida extra (5x) até o
	-- nível 14 (todo o Ato 1 do Normal); depois ela vai sumindo até o nível 30.
	ReforcoInicio = 4.0, -- vida extra no nível 1 (4.0 = +400%, ou seja 5x)
	ReforcoRampa = 0.2, -- o reforço cresce por nível até o platô (5x na 1-1, ~15x no fim do Ato 1)
	ReforcoPlatoAte = 14,
	ReforcoAteNivel = 50, -- depois do platô some aos poucos (a vida dos inimigos nunca diminui de uma fase para a outra)
}

function Config.VidaInimigo(nivel, chefe)
	local ini = Config.Inimigo
	local v = ini.VidaBase * ini.VidaCrescimento ^ (nivel - 1)
	local plato = ini.ReforcoPlatoAte
	local pico = 1 + ini.ReforcoInicio * (1 + ini.ReforcoRampa * (plato - 1))
	if nivel <= plato then
		v *= 1 + ini.ReforcoInicio * (1 + ini.ReforcoRampa * (nivel - 1))
	elseif nivel < ini.ReforcoAteNivel then
		v *= pico ^ (1 - (nivel - plato) / (ini.ReforcoAteNivel - plato))
	end
	if chefe then
		v *= Config.Inimigo.MultChefe
	end
	return math.floor(v + 0.5)
end

function Config.DanoInimigo(nivel)
	return math.floor(Config.Inimigo.DanoBase * Config.Inimigo.DanoCrescimento ^ (nivel - 1) + 0.5)
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
Config.ChefeTempo = 120 -- segundos para vencer o chefe (o Pen do Ato 1 é um muro: pede farmar e fazer síntese)

-- Nomes dos equipamentos por categoria e tier (T1 = Comum ... T5 = Lendário)
Config.NomesItens = {
	anel = {
		"Anel de Cobre",
		"Anel de Prata",
		"Anel de Safira",
		"Anel das Sombras",
		"Anel do Trovão",
		"Anel do Dragão",
		"Anel dos Seis Caminhos",
		"Anel do Vazio",
	},
	brinco = {
		"Brinco de Osso",
		"Brinco de Prata",
		"Brinco de Jade",
		"Brinco das Sombras",
		"Brinco do Trovão",
		"Brinco do Dragão",
		"Brinco dos Seis Caminhos",
		"Brinco do Vazio",
	},
	colar = {
		"Colar de Contas",
		"Colar de Prata",
		"Colar de Jade",
		"Colar das Sombras",
		"Colar do Sábio",
		"Colar do Dragão",
		"Colar dos Seis Caminhos",
		"Colar do Vazio",
	},
	bracelete = {
		"Bracelete de Couro",
		"Bracelete de Ferro",
		"Bracelete de Jade",
		"Bracelete das Sombras",
		"Bracelete do Trovão",
		"Bracelete do Dragão",
		"Bracelete dos Seis Caminhos",
		"Bracelete do Vazio",
	},
	cinto = {
		"Faixa de Pano",
		"Cinto de Couro",
		"Cinto Ninja",
		"Cinto das Sombras",
		"Cinto do Trovão",
		"Cinto do Dragão",
		"Cinto dos Seis Caminhos",
		"Cinto do Vazio",
	},
	broche = {
		"Broche de Madeira",
		"Broche de Bronze",
		"Broche de Jade",
		"Broche das Sombras",
		"Broche do Sábio",
		"Broche do Dragão",
		"Broche dos Seis Caminhos",
		"Broche do Vazio",
	},
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
		fases = { 1, 5 }, -- cai nas fases 1-1 a 1-5 (Ato 1, qualquer dificuldade)
		chance = 0.30, -- 30% dos drops dessas fases são peças do conjunto
		pecas = {
			arma = "Kunai da Vila",
			armaClasse = { guerreiro = "Espada da Vila", cacador = "Arco da Vila", mago = "Cajado da Vila" },
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
			armaClasse = { guerreiro = "Lâmina da Katsuki", cacador = "Arco da Katsuki", mago = "Cajado da Katsuki" },
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

-- Classes (estilo Task Bar Hero): escolhidas no menu inicial.
-- Arma, elmo e armadura são exclusivos de cada classe; botas e olho servem para todas.
-- Na síntese a classe não importa: junta qualquer item da mesma raridade e categoria.
Config.Classes = {
	{
		id = "guerreiro",
		nome = "Guerreiro",
		icone = "⚔️",
		cor = Color3.fromRGB(225, 70, 55),
		estilo = "Corpo a corpo",
		descricao = "Aguenta muita pancada e bate firme de perto. Bom para quem está começando.",
		dano = 1.0, -- multiplica o dano
		vida = 1.35, -- multiplica a vida
		critico = 0, -- soma na chance de crítico
		alcance = 8, -- distância do golpe
		intervalo = 0.55, -- segundos entre golpes
		regeneracao = 0.06, -- recupera 6% da vida por segundo fora de combate
		notas = { vida = 5, dano = 3, alcance = 1, velocidade = 3 }, -- estrelas no menu
	},
	{
		id = "cacador",
		nome = "Caçador",
		icone = "🏹",
		cor = Color3.fromRGB(90, 200, 90),
		estilo = "À distância",
		descricao = "Flechas rápidas de longe e muitos críticos, mas tem pouca vida.",
		dano = 0.8,
		vida = 0.85,
		critico = 0.08,
		alcance = 22,
		intervalo = 0.4,
		projetil = true,
		notas = { vida = 2, dano = 3, alcance = 5, velocidade = 5 },
	},
	{
		id = "mago",
		nome = "Mago",
		icone = "🔮",
		cor = Color3.fromRGB(150, 90, 240),
		estilo = "Magias elementais",
		descricao = "Ataque básico fraco, mas magias de gelo, raio e fogo saem sozinhas e arrasam hordas. Frágil.",
		dano = 1.15, -- Poder Mágico: as magias usam este dano (ver Habilidades.luau)
		danoBasico = 0.5, -- o ataque básico causa só 50% do dano (fraco de propósito; a força são as magias)
		vida = 0.8,
		critico = 0,
		alcance = 16,
		intervalo = 0.8,
		projetil = true,
		area = 7, -- raio da explosão em volta do alvo
		danoArea = 0.5, -- os outros inimigos na explosão levam 50% do dano do básico
		notas = { vida = 1, dano = 5, alcance = 4, velocidade = 2 },
	},
}
function Config.ClassePorId(id)
	for _, c in ipairs(Config.Classes) do
		if c.id == id then
			return c
		end
	end
	return nil
end
Config.SlotsDeClasse = { arma = true, armaSec = true, elmo = true, armadura = true, luvas = true, calca = true }
Config.ChanceClassePropria = 0.6 -- 60% dos drops são da sua classe; o resto é de outra (serve para síntese)

-- Nome dos itens exclusivos de cada classe (do tier 1 ao 8)
Config.NomesClasse = {
	guerreiro = {
		armaSec = {
			"Escudo de Madeira",
			"Escudo de Ferro",
			"Escudo ANBU",
			"Escudo das Sombras",
			"Escudo do Trovão",
			"Escudo do Dragão",
			"Escudo dos Seis Caminhos",
			"Escudo do Vazio",
		},
		luvas = {
			"Luvas de Pano",
			"Manoplas de Ferro",
			"Manoplas ANBU",
			"Manoplas do Crepúsculo",
			"Manoplas do Trovão",
			"Manoplas do Dragão",
			"Manoplas dos Seis Caminhos",
			"Manoplas do Vazio",
		},
		calca = {
			"Calça de Treino",
			"Grevas de Ferro",
			"Grevas ANBU",
			"Grevas do Crepúsculo",
			"Grevas do Trovão",
			"Grevas do Dragão",
			"Grevas dos Seis Caminhos",
			"Grevas do Vazio",
		},
		arma = {
			"Espada Enferrujada",
			"Espada de Aço",
			"Katana Afiada",
			"Lâmina das Sombras",
			"Espada do Trovão",
			"Lâmina do Dragão",
			"Espada dos Seis Caminhos",
			"Lâmina do Vazio",
		},
		elmo = {
			"Bandana de Pano",
			"Elmo de Ferro",
			"Elmo ANBU",
			"Elmo do Crepúsculo",
			"Elmo do Trovão",
			"Elmo do Dragão",
			"Elmo dos Seis Caminhos",
			"Elmo do Vazio",
		},
		armadura = {
			"Colete de Treino",
			"Peitoral de Ferro",
			"Armadura ANBU",
			"Armadura do Crepúsculo",
			"Armadura do Trovão",
			"Armadura do Dragão",
			"Armadura dos Seis Caminhos",
			"Armadura do Vazio",
		},
	},
	cacador = {
		armaSec = {
			"Aljava de Bambu",
			"Aljava de Couro",
			"Aljava do Caçador",
			"Aljava das Sombras",
			"Aljava do Vento",
			"Aljava do Dragão",
			"Aljava dos Seis Caminhos",
			"Aljava do Vazio",
		},
		luvas = {
			"Luvas de Pano",
			"Luvas de Couro",
			"Luvas do Caçador",
			"Luvas do Crepúsculo",
			"Luvas do Vento",
			"Luvas do Dragão",
			"Luvas dos Seis Caminhos",
			"Luvas do Vazio",
		},
		calca = {
			"Calça de Pano",
			"Calça de Couro",
			"Calça do Caçador",
			"Calça do Crepúsculo",
			"Calça do Vento",
			"Calça do Dragão",
			"Calça dos Seis Caminhos",
			"Calça do Vazio",
		},
		arma = {
			"Arco de Bambu",
			"Arco Curto",
			"Arco Longo",
			"Arco das Sombras",
			"Arco do Vento",
			"Arco do Dragão",
			"Arco dos Seis Caminhos",
			"Arco do Vazio",
		},
		elmo = {
			"Capuz de Pano",
			"Capuz de Couro",
			"Máscara do Caçador",
			"Capuz do Crepúsculo",
			"Capuz do Vento",
			"Máscara do Dragão",
			"Capuz dos Seis Caminhos",
			"Máscara do Vazio",
		},
		armadura = {
			"Gibão de Pano",
			"Colete de Couro",
			"Couraça do Caçador",
			"Manto do Crepúsculo",
			"Manto do Vento",
			"Couraça do Dragão",
			"Manto dos Seis Caminhos",
			"Couraça do Vazio",
		},
	},
	mago = {
		armaSec = {
			"Pergaminho Velho",
			"Grimório de Aprendiz",
			"Orbe de Chakra",
			"Grimório das Sombras",
			"Orbe do Trovão",
			"Grimório do Dragão",
			"Orbe dos Seis Caminhos",
			"Grimório do Vazio",
		},
		luvas = {
			"Luvas de Seda",
			"Luvas de Aprendiz",
			"Luvas de Chakra",
			"Luvas do Crepúsculo",
			"Luvas do Sábio",
			"Luvas do Dragão",
			"Luvas dos Seis Caminhos",
			"Luvas do Vazio",
		},
		calca = {
			"Calça de Seda",
			"Calça de Aprendiz",
			"Saia de Chakra",
			"Calça do Crepúsculo",
			"Calça do Sábio",
			"Calça do Dragão",
			"Calça dos Seis Caminhos",
			"Calça do Vazio",
		},
		arma = {
			"Cajado de Bambu",
			"Cajado de Carvalho",
			"Cajado de Chakra",
			"Cetro das Sombras",
			"Cajado do Trovão",
			"Cetro do Dragão",
			"Cajado dos Seis Caminhos",
			"Cetro do Vazio",
		},
		elmo = {
			"Chapéu de Aprendiz",
			"Chapéu de Seda",
			"Tiara de Chakra",
			"Chapéu do Crepúsculo",
			"Coroa do Sábio",
			"Tiara do Dragão",
			"Coroa dos Seis Caminhos",
			"Coroa do Vazio",
		},
		armadura = {
			"Túnica de Aprendiz",
			"Túnica de Seda",
			"Manto de Chakra",
			"Manto do Crepúsculo",
			"Manto do Sábio",
			"Manto do Dragão",
			"Manto dos Seis Caminhos",
			"Manto do Vazio",
		},
	},
}

-- Joias (estilo TBH / WOG): encaixam nos equipamentos (menos no olho).
-- Caem raramente; 3 joias iguais do mesmo nível viram 1 do nível de cima (síntese de joias).
Config.Joias = {
	ChanceDrop = 0.006, -- 0,6% dos inimigos soltam uma joia
	CustoFundir = { 50, 200, 800, 3000 }, -- ouro para fundir 3 joias do nível 1, 2, 3, 4
	Niveis = { "Lascada", "Comum", "Polida", "Perfeita", "Radiante" },
	-- valor = quanto cada nível dá (nível 1 a 5)
	Tipos = {
		{
			id = "rubi",
			nome = "Rubi",
			cor = Color3.fromRGB(235, 50, 70),
			atributo = "danoPct",
			valores = { 0.02, 0.04, 0.07, 0.11, 0.16 },
			texto = "+%d%% de dano",
		},
		{
			id = "safira",
			nome = "Safira",
			cor = Color3.fromRGB(60, 120, 255),
			atributo = "vidaPct",
			valores = { 0.02, 0.04, 0.07, 0.11, 0.16 },
			texto = "+%d%% de vida",
		},
		{
			id = "esmeralda",
			nome = "Esmeralda",
			cor = Color3.fromRGB(40, 210, 110),
			atributo = "critico",
			valores = { 0.005, 0.01, 0.017, 0.025, 0.035 },
			texto = "+%d%% de crítico",
		},
		{
			id = "ametista",
			nome = "Ametista",
			cor = Color3.fromRGB(170, 80, 240),
			atributo = "critDano",
			valores = { 0.04, 0.08, 0.14, 0.22, 0.32 },
			texto = "+%d%% de dano crítico",
		},
		{
			id = "topazio",
			nome = "Topázio",
			cor = Color3.fromRGB(255, 200, 40),
			atributo = "ouro",
			valores = { 0.03, 0.06, 0.1, 0.15, 0.22 },
			texto = "+%d%% de ouro",
		},
		{
			id = "diamante",
			nome = "Diamante",
			cor = Color3.fromRGB(220, 240, 255),
			atributo = "armaduraPct",
			valores = { 0.03, 0.06, 0.1, 0.15, 0.22 },
			texto = "+%d%% de armadura",
		},
		{
			id = "onix",
			nome = "Ônix",
			cor = Color3.fromRGB(60, 50, 70),
			atributo = "resistencia",
			valores = { 0.02, 0.04, 0.06, 0.09, 0.13 },
			texto = "+%d%% de resistência",
		},
	},
}
function Config.JoiaPorId(id)
	for _, j in ipairs(Config.Joias.Tipos) do
		if j.id == id then
			return j
		end
	end
	return nil
end
-- chave de joia no inventário: "rubi:2" = Rubi nível 2
function Config.LerJoia(chave)
	local tipo, nivel = string.match(chave or "", "^(%a+):(%d)$")
	local j = tipo and Config.JoiaPorId(tipo)
	nivel = tonumber(nivel)
	if j and nivel and nivel >= 1 and nivel <= #Config.Joias.Niveis then
		return j, nivel
	end
	return nil
end
-- Defesa: a armadura reduz o dano recebido (no máximo 75%)
function Config.ReducaoArmadura(armadura, nivelInimigo)
	local k = 10 * Config.DanoInimigo(nivelInimigo or 1) + 20
	return math.min(0.75, armadura / (armadura + k))
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
	-- (o equipamento garantido usa as chances da dificuldade, uma raridade acima)
	Equipamento = { { "epico", 0.75 }, { "lendario", 0.22 }, { "mitico", 0.03 } },
	-- itens especiais com chance própria
	Especiais = {
		{ nome = "Lâmina de Chakra Negro", slot = "arma", raridade = "mitico", chance = 0.004, icone = "🗡️" },
		-- Secretos (preto): 1 por chefe, só na fase dele (soFase). O nome aparece "???" até dropar.
		{
			nome = "Rinnegan",
			slot = "olho",
			raridade = "secreto",
			chance = 0.0005, -- 1 em 2.000 vitórias
			icone = "👁️",
			valor = 1.0,
			soFase = 10, -- Normal · Ato 1 · 1-10 (Pen)
		},
		{
			nome = "Mãos de Argila Viva",
			slot = "luvas",
			raridade = "secreto",
			chance = 0.0005,
			soFase = 20, -- Normal · Ato 2 · 2-10 (Deidaro)
		},
		{
			nome = "Leque de Guerra Uchira",
			slot = "arma",
			raridade = "secreto",
			chance = 0.0005,
			soFase = 30, -- Normal · Ato 3 · 3-10 (Madaro)
		},
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
	Crescimento = 1.06, -- cada nível do item multiplica a força por 1,06
}
Config.LimiteInventario = 40 -- passou disso, o item vira ouro automaticamente

Config.Raridades = {
	{
		id = "comum",
		encaixes = 0, -- quantas joias cabem
		nome = "Comum",
		peso = 78, -- (as chances de verdade estão em Config.Dificuldades)
		mult = 1.0,
		cor = Color3.fromRGB(170, 170, 175),
		material = "de Madeira",
	},
	{
		id = "incomum",
		encaixes = 1, -- quantas joias cabem
		nome = "Incomum",
		peso = 26,
		mult = 1.6,
		cor = Color3.fromRGB(90, 200, 100),
		material = "de Ferro",
	},
	{
		id = "raro",
		encaixes = 1, -- quantas joias cabem
		nome = "Raro",
		peso = 9,
		mult = 2.5,
		cor = Color3.fromRGB(70, 150, 255),
		material = "de Cristal",
	},
	{
		id = "epico",
		encaixes = 2, -- quantas joias cabem
		nome = "Épico",
		peso = 2.5,
		mult = 4.0,
		cor = Color3.fromRGB(175, 90, 255),
		material = "das Estrelas",
	},
	{
		id = "lendario",
		encaixes = 2, -- quantas joias cabem
		nome = "Lendário",
		peso = 0.5,
		mult = 7.0,
		cor = Color3.fromRGB(255, 160, 40),
		material = "do Abismo",
	},
	{
		id = "mitico",
		encaixes = 3, -- quantas joias cabem
		nome = "Mítico",
		peso = 0, -- não cai de monstro comum: só do chefe ou da forja
		mult = 12.0,
		cor = Color3.fromRGB(255, 70, 110),
		material = "Mítico",
	},
	{
		id = "imortal",
		encaixes = 3, -- quantas joias cabem
		nome = "Imortal",
		peso = 0, -- só da forja (3 Míticos). Chance de cair: a decidir (Quadro de Avisos)
		mult = 20.0,
		cor = Color3.fromRGB(40, 225, 210), -- turquesa brilhante
		material = "Imortal",
		forjavel = false, -- o Imortal não vira Divino na forja
	},
	{
		id = "divino",
		encaixes = 4, -- quantas joias cabem
		nome = "Divino",
		peso = 0, -- só itens especiais de chefe, MUITO raros
		mult = 30.0,
		cor = Color3.fromRGB(255, 210, 40), -- amarelo dourado
		corBorda = Color3.fromRGB(255, 250, 200),
		material = "Divino",
		forjavel = false,
	},
	{
		id = "secreto",
		encaixes = 4, -- quantas joias cabem
		nome = "Secreto",
		peso = 0, -- só o item Secreto de cada chefe (ver Config.DropsChefe.Especiais)
		mult = 50.0,
		cor = Color3.fromRGB(20, 18, 24), -- item preto
		corBorda = Color3.fromRGB(235, 235, 255),
		material = "Secreto",
		forjavel = false,
	},
}

-- Cada parte do equipamento melhora uma coisa diferente.
-- Espaços de equipamento (estilo TBH / WOG): armas, armadura completa e 6 acessórios.
-- grupo: "arma", "armadura" ou "acessorio". Todos aceitam joias (menos o olho).
Config.Slots = {
	{
		id = "arma",
		nome = "Arma",
		grupo = "arma",
		base = "Lâmina",
		icone = "⚔️",
		atributo = "dano",
		valor = 3,
		texto = "+%d de dano",
	},
	{
		id = "armaSec",
		nome = "Arma secundária",
		grupo = "arma",
		base = "Adaga",
		icone = "🗡️",
		atributo = "dano",
		valor = 1.5,
		texto = "+%d de dano",
	},
	{
		id = "elmo",
		nome = "Elmo",
		grupo = "armadura",
		base = "Elmo",
		icone = "⛑️",
		atributo = "critico",
		valor = 0.02,
		texto = "+%d%% de crítico",
	},
	{
		id = "armadura",
		nome = "Armadura",
		grupo = "armadura",
		base = "Peitoral",
		icone = "🛡️",
		atributo = "vida",
		valor = 15,
		texto = "+%d de vida",
	},
	{
		id = "luvas",
		nome = "Luvas",
		grupo = "armadura",
		base = "Luvas",
		icone = "🧤",
		atributo = "velAtaque",
		valor = 0.02,
		texto = "+%d%% de velocidade de ataque",
	},
	{
		id = "calca",
		nome = "Calça",
		grupo = "armadura",
		base = "Calça",
		icone = "👖",
		atributo = "armadura",
		valor = 6,
		texto = "+%d de armadura",
	},
	{
		id = "botas",
		nome = "Botas",
		grupo = "armadura",
		base = "Botas",
		icone = "👢",
		atributo = "velocidade",
		valor = 1,
		texto = "+%d de velocidade",
	},
	{
		id = "anel",
		nome = "Anel",
		grupo = "acessorio",
		base = "Anel",
		icone = "💍",
		atributo = "danoPct",
		valor = 0.03,
		texto = "+%d%% de dano",
	},
	{
		id = "brinco",
		nome = "Brinco",
		grupo = "acessorio",
		base = "Brinco",
		icone = "✨",
		atributo = "critDano",
		valor = 0.08,
		texto = "+%d%% de dano crítico",
	},
	{
		id = "colar",
		nome = "Colar",
		grupo = "acessorio",
		base = "Colar",
		icone = "📿",
		atributo = "vidaPct",
		valor = 0.03,
		texto = "+%d%% de vida",
	},
	{
		id = "bracelete",
		nome = "Bracelete",
		grupo = "acessorio",
		base = "Bracelete",
		icone = "⭕",
		atributo = "velAtaque",
		valor = 0.015,
		texto = "+%d%% de velocidade de ataque",
	},
	{
		id = "cinto",
		nome = "Cinto",
		grupo = "acessorio",
		base = "Cinto",
		icone = "🎗️",
		atributo = "armadura",
		valor = 5,
		texto = "+%d de armadura",
	},
	{
		id = "broche",
		nome = "Broche",
		grupo = "acessorio",
		base = "Broche",
		icone = "🏵️",
		atributo = "resistencia",
		valor = 0.02,
		texto = "+%d%% de resistência (fogo, gelo, raio, veneno)",
	},
	{
		id = "olho",
		nome = "Olho",
		grupo = "especial",
		base = "Olho",
		icone = "👁️",
		atributo = "danoMult",
		valor = 0.5,
		texto = "+%d%% de dano",
		especial = true, -- não cai aleatório: só o Rinnegan do chefe
		semJoia = true,
	},
}

-- Forja: junta itens iguais em raridade para criar 1 item da raridade de cima.
Config.Forja = {
	Quantidade = 3, -- quantos itens entram
	Custo = { comum = 10, incomum = 30, raro = 90, epico = 250, lendario = 700, mitico = 2000 }, -- ouro por forja (nível 1)
	CustoCrescimento = 1.06, -- o preço multiplica por isto a cada nível do item
	-- Síntese com sorte (estilo TBH): o resultado pode pular raridades ou até cair uma
	Sorte = {
		{ salto = 2, peso = 8, texto = "SUPER SÍNTESE! +2" },
		{ salto = 1, peso = 70, texto = "Síntese!" },
		{ salto = 0, peso = 20, texto = "Mesma raridade..." },
		{ salto = -1, peso = 2, texto = "Ops! Caiu uma raridade" },
	},
	MaxResultado = "imortal", -- a síntese nunca passa do Imortal (Divino e Secreto só de drop)
}
-- Preço de uma síntese: depende da raridade e do nível do item mais alto
function Config.CustoForja(raridadeId, nivel)
	local base = Config.Forja.Custo[raridadeId] or 0
	return math.floor(base * Config.Forja.CustoCrescimento ^ ((nivel or 1) - 1) + 0.5)
end

-- Gravação de atributos: cada item ganha até 2 linhas extras sorteadas.
-- Custa ouro + Pergaminhos de Gravação (drop raro de monstro, certo no baú do chefe e da Alquimia).
Config.Gravacao = {
	Linhas = 2,
	RaridadeMinima = 7, -- só itens Imortal ou acima podem ser gravados
	ChanceDropPergaminho = 0.01, -- por monstro comum
	PergaminhosChefe = { 2, 4 }, -- baú do chefe dá entre 2 e 4
	PergaminhosAlquimia = { raro = 1, epico = 1, lendario = 2, mitico = 3, imortal = 5, divino = 8, secreto = 10 },
	CustoPergaminhos = 1, -- por gravação (regravar custa o dobro)
	-- grupo de cada slot e os atributos possíveis (valor base de uma gravação "Boa" num item Comum)
	GrupoDoSlot = {
		arma = "arma",
		armaSec = "arma",
		elmo = "armadura",
		armadura = "armadura",
		luvas = "armadura",
		calca = "armadura",
		botas = "armadura",
		anel = "acessorio",
		brinco = "acessorio",
		colar = "acessorio",
		bracelete = "acessorio",
		cinto = "acessorio",
		broche = "acessorio",
		olho = "acessorio",
	},
	Grupos = {
		arma = {
			{ atributo = "danoPct", base = 0.06 },
			{ atributo = "critico", base = 0.02 },
			{ atributo = "critDano", base = 0.12 },
			{ atributo = "velAtaque", base = 0.05 },
			{ atributo = "danoChefe", base = 0.10 },
			{ atributo = "ouro", base = 0.06 },
		},
		armadura = {
			{ atributo = "vidaPct", base = 0.06 },
			{ atributo = "armaduraPct", base = 0.08 },
			{ atributo = "resistencia", base = 0.04 },
			{ atributo = "regen", base = 0.01 },
			{ atributo = "velocidade", base = 1.5 },
		},
		acessorio = {
			{ atributo = "danoPct", base = 0.04 },
			{ atributo = "critico", base = 0.015 },
			{ atributo = "critDano", base = 0.10 },
			{ atributo = "ouro", base = 0.08 },
			{ atributo = "xp", base = 0.05 },
			{ atributo = "vidaPct", base = 0.04 },
		},
	},
	Qualidades = {
		{ id = "fraca", nome = "Fraca", mult = 0.5, peso = 40, cor = Color3.fromRGB(160, 160, 165) },
		{ id = "boa", nome = "Boa", mult = 0.8, peso = 30, cor = Color3.fromRGB(110, 210, 120) },
		{ id = "otima", nome = "Ótima", mult = 1.1, peso = 18, cor = Color3.fromRGB(80, 160, 255) },
		{ id = "perfeita", nome = "Perfeita", mult = 1.5, peso = 9, cor = Color3.fromRGB(190, 100, 255) },
		{ id = "lendaria", nome = "Lendária", mult = 2.2, peso = 3, cor = Color3.fromRGB(255, 170, 40) },
	},
	NomesAtributo = {
		danoPct = "Dano",
		critico = "Chance de Crítico",
		critDano = "Dano Crítico",
		velAtaque = "Velocidade de Ataque",
		danoChefe = "Dano contra Chefes",
		ouro = "Ouro",
		vidaPct = "Vida",
		armaduraPct = "Armadura",
		resistencia = "Resistências",
		regen = "Regeneração",
		velocidade = "Velocidade",
		xp = "Experiência",
	},
}
function Config.QualidadeGravacao(id)
	for _, q in ipairs(Config.Gravacao.Qualidades) do
		if q.id == id then
			return q
		end
	end
	return nil
end
-- valor final da linha: base x qualidade x bônus da raridade do item (índice 1..9)
function Config.ValorGravacao(base, qualidadeMult, raridadeIndice)
	return base * qualidadeMult * (1 + 0.15 * ((raridadeIndice or 1) - 1))
end
-- ouro por gravação (regravar uma linha já gravada custa o dobro)
function Config.CustoGravacao(nivel, raridadeIndice, regravar)
	local c = 50 * 1.06 ^ ((nivel or 1) - 1) * (1 + 0.5 * ((raridadeIndice or 1) - 1))
	return math.floor(c * (regravar and 2 or 1) + 0.5)
end
-- texto curto de uma linha gravada, ex.: "+12% Dano" ou "+3 Velocidade"
function Config.TextoGravacao(g)
	local nome = Config.Gravacao.NomesAtributo[g.atributo] or g.atributo
	if g.atributo == "velocidade" then
		return string.format("+%.1f %s", g.valor, nome)
	end
	return string.format("+%.1f%% %s", g.valor * 100, nome)
end

-- Quanto ouro um item vale ao vender
Config.ValorVenda = {
	comum = 3,
	incomum = 8,
	raro = 20,
	epico = 50,
	lendario = 150,
	mitico = 400,
	imortal = 1200,
	divino = 4000,
	secreto = 8000,
}

return Config
