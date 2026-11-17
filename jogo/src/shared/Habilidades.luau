-- Habilidades: dados da árvore de magias de cada classe (por enquanto só o Mago).
-- Como funciona (estilo idle, inspirado em TBH/WOG, mas com nomes e números próprios):
--   * a cada nível o herói ganha 1 ponto de habilidade (começa com 1 no nível 1);
--   * cada nível de habilidade custa 1 ponto;
--   * habilidades ATIVAS ficam na barra e são lançadas sozinhas quando a recarga acaba;
--   * PASSIVAS valem sempre que aprendidas;
--   * as de baixo pedem pontos gastos no mesmo ramo (pré-requisito), a SUPREMA pede 10.
-- Todos os números de balanceamento ficam aqui.

local Habilidades = {}

Habilidades.PontosIniciais = 1 -- pontos no nível 1
Habilidades.PontosPorNivel = 1
Habilidades.SlotsBarra = 5 -- quantas ativas cabem na barra
Habilidades.RecargaGlobal = 0.45 -- segundos entre uma magia e outra (para não sair tudo junto)
Habilidades.AlcanceMagia = 26 -- distância máxima do alvo das magias
Habilidades.Variacao = 0.15 -- dano das magias varia 15%
Habilidades.ReducaoRecargaMax = 0.6 -- a recarga nunca cai mais que 60%
Habilidades.CCChefe = 0.3 -- congelar/atordoar dura só 30% no chefe

-- Resetar todos os pontos custa ouro (cresce com o nível)
function Habilidades.CustoReset(nivel)
	return math.floor(30 * nivel)
end

Habilidades.Elementos = {
	gelo = { nome = "Gelo", icone = "❄️", cor = Color3.fromRGB(120, 215, 255) },
	raio = { nome = "Raio", icone = "⚡", cor = Color3.fromRGB(255, 232, 80) },
	fogo = { nome = "Fogo", icone = "🔥", cor = Color3.fromRGB(255, 120, 40) },
	queima = { nome = "Queimadura", icone = "🔥", cor = Color3.fromRGB(255, 160, 60) },
	arcano = { nome = "Arcano", icone = "🔮", cor = Color3.fromRGB(190, 120, 255) },
}

-- Valor de um campo num nível: base + porNivel * (nivel - 1)
-- Os campos de cada habilidade são tabelas {base, porNivel}.
function Habilidades.valor(hab, campo, nivel)
	local v = hab[campo]
	if type(v) ~= "table" then
		return v
	end
	return v[1] + (v[2] or 0) * math.max(0, (nivel or 1) - 1)
end

------------------------------------------------------------------------
-- Árvore do Mago: 3 ramos elementais + Arcano (passivas que ajudam todas)
-- tipo: "ativa", "passiva" ou "suprema" (suprema = ativa grande do fim do ramo)
-- dano = % do Poder Mágico (o dano do herói com arma, treino e conjunto)
-- linha = posição na tela da árvore (1 em cima, 4 embaixo)
-- requer = pontos que precisam estar gastos neste ramo
------------------------------------------------------------------------
local mago = {
	ramos = {
		{ id = "gelo", nome = "Gelo", icone = "❄️", cor = Color3.fromRGB(120, 215, 255) },
		{ id = "raio", nome = "Raio", icone = "⚡", cor = Color3.fromRGB(255, 232, 80) },
		{ id = "fogo", nome = "Fogo", icone = "🔥", cor = Color3.fromRGB(255, 120, 40) },
		{ id = "arcano", nome = "Arcano", icone = "🔮", cor = Color3.fromRGB(190, 120, 255) },
	},
	lista = {
		-------------------------------------------------------------- GELO
		{
			id = "lancaGelo",
			ramo = "gelo",
			linha = 1,
			tipo = "ativa",
			nome = "Lança de Gelo",
			icone = "🧊",
			max = 10,
			requer = 0,
			recarga = { 4, -0.12 },
			dano = { 150, 22 },
			perfura = { 3, 0.25 }, -- inimigos atravessados na linha
			lentidao = 0.45, -- inimigo anda 45% mais devagar
			tempoLento = { 2.5, 0.1 },
			texto = "Atira uma lança que atravessa %perfura% inimigos em linha: %dano% de dano de gelo e deixa lento.",
		},
		{
			id = "frioCortante",
			ramo = "gelo",
			linha = 2,
			tipo = "passiva",
			nome = "Frio Cortante",
			icone = "🌨️",
			max = 10,
			requer = 2,
			bonusElem = { 0.08, 0.08 }, -- +% dano de gelo
			estilhacar = { 0.04, 0.04 }, -- +% dano de TODAS as magias em inimigo lento ou congelado
			texto = "+%bonusElem% de dano de gelo. Inimigos lentos ou congelados levam +%estilhacar% de dano de todas as magias.",
		},
		{
			id = "novaGelo",
			ramo = "gelo",
			linha = 3,
			tipo = "ativa",
			nome = "Nova Congelante",
			icone = "💠",
			max = 10,
			requer = 5,
			recarga = { 12, -0.3 },
			dano = { 130, 18 },
			raio = 11,
			congelar = { 1.5, 0.1 }, -- segundos parado (não anda nem ataca)
			texto = "Explosão de gelo em volta do herói: %dano% de dano e congela todos por %congelar%s.",
		},
		{
			id = "nevasca",
			ramo = "gelo",
			linha = 4,
			tipo = "suprema",
			nome = "Nevasca Eterna",
			icone = "🌀",
			max = 5,
			requer = 10,
			recarga = { 30, -1.5 },
			dano = { 70, 15 }, -- por pulso
			pulsos = 7,
			raio = 13,
			congelar = { 2, 0.3 },
			texto = "SUPREMA: tempestade de neve gigante com 7 golpes de %dano% e congela tudo por %congelar%s no fim.",
		},
		-------------------------------------------------------------- RAIO
		{
			id = "correnteRaio",
			ramo = "raio",
			linha = 1,
			tipo = "ativa",
			nome = "Corrente de Raio",
			icone = "⚡",
			max = 10,
			requer = 0,
			recarga = { 3.5, -0.1 },
			dano = { 120, 16 },
			saltos = { 3, 0.34 }, -- quantos inimigos o raio pula
			perdaSalto = 0.12, -- cada salto tira 12% do dano
			atordoar = { 0.12, 0.01 }, -- chance de atordoar
			tempoAtordoar = 1,
			texto = "Raio que salta entre %saltos% inimigos: %dano% de dano e %atordoar% de chance de atordoar.",
		},
		{
			id = "sobrecarga",
			ramo = "raio",
			linha = 2,
			tipo = "passiva",
			nome = "Sobrecarga",
			icone = "🔋",
			max = 10,
			requer = 2,
			bonusElem = { 0.08, 0.08 },
			critMagia = { 0.02, 0.02 }, -- +% chance de crítico das magias de raio
			texto = "+%bonusElem% de dano de raio e +%critMagia% de chance de crítico nas magias de raio.",
		},
		{
			id = "furiaTrovao",
			ramo = "raio",
			linha = 3,
			tipo = "ativa",
			nome = "Fúria do Trovão",
			icone = "🌩️",
			max = 10,
			requer = 5,
			recarga = { 9, -0.25 },
			dano = { 200, 26 },
			alvos = { 3, 0.5 },
			atordoar = { 1, 0 }, -- sempre atordoa
			tempoAtordoar = 0.8,
			texto = "Raios caem do céu em %alvos% inimigos: %dano% de dano e atordoa.",
		},
		{
			id = "tempestade",
			ramo = "raio",
			linha = 4,
			tipo = "suprema",
			nome = "Tempestade Divina",
			icone = "⛈️",
			max = 5,
			requer = 10,
			recarga = { 28, -1.5 },
			dano = { 85, 18 },
			golpes = { 16, 2 }, -- raios no total (4 por segundo)
			atordoar = { 0.25, 0.05 },
			tempoAtordoar = 0.6,
			texto = "SUPREMA: %golpes% raios caem sem parar por alguns segundos, cada um com %dano% de dano.",
		},
		-------------------------------------------------------------- FOGO
		{
			id = "bolaFogo",
			ramo = "fogo",
			linha = 1,
			tipo = "ativa",
			nome = "Bola de Fogo",
			icone = "🔥",
			max = 10,
			requer = 0,
			recarga = { 3.5, -0.1 },
			dano = { 170, 22 },
			raio = 6,
			danoArea = 0.6, -- quem está perto do alvo leva 60%
			queima = { 15, 3 }, -- % do Poder Mágico por segundo
			tempoQueima = 3,
			texto = "Explode no alvo: %dano% de dano em área e queima por %queima% por segundo.",
		},
		{
			id = "combustao",
			ramo = "fogo",
			linha = 2,
			tipo = "passiva",
			nome = "Combustão",
			icone = "💥",
			max = 10,
			requer = 2,
			bonusElem = { 0.08, 0.08 },
			explodir = { 40, 10 }, -- inimigo que morre queimando explode (% do Poder Mágico)
			texto = "+%bonusElem% de dano de fogo e queimadura. Inimigo que morre queimando EXPLODE: %explodir% em volta.",
		},
		{
			id = "anelChamas",
			ramo = "fogo",
			linha = 3,
			tipo = "ativa",
			nome = "Anel de Chamas",
			icone = "⭕",
			max = 10,
			requer = 5,
			recarga = { 10, -0.25 },
			dano = { 150, 20 },
			raio = 12,
			queima = { 30, 5 },
			tempoQueima = 4,
			texto = "Onda de fogo em volta do herói: %dano% de dano e queimadura forte de %queima% por segundo.",
		},
		{
			id = "meteoro",
			ramo = "fogo",
			linha = 4,
			tipo = "suprema",
			nome = "Meteoro Infernal",
			icone = "☄️",
			max = 5,
			requer = 10,
			recarga = { 25, -1.25 },
			dano = { 900, 180 },
			raio = 10,
			danoArea = 0.5,
			queima = { 50, 10 },
			tempoQueima = 4,
			texto = "SUPREMA: um meteoro gigante cai no alvo: %dano% de dano, explosão enorme e queimadura.",
		},
		-------------------------------------------------------------- ARCANO
		{
			id = "poderArcano",
			ramo = "arcano",
			linha = 1,
			tipo = "passiva",
			nome = "Poder Arcano",
			icone = "🔮",
			max = 10,
			requer = 0,
			poder = { 0.06, 0.06 }, -- +% dano de todas as magias
			texto = "+%poder% de dano de todas as magias.",
		},
		{
			id = "menteRapida",
			ramo = "arcano",
			linha = 2,
			tipo = "passiva",
			nome = "Mente Rápida",
			icone = "⏳",
			max = 10,
			requer = 0,
			reducao = { 0.03, 0.03 }, -- -% recarga de todas as magias
			texto = "Todas as magias recarregam %reducao% mais rápido.",
		},
		{
			id = "ecoArcano",
			ramo = "arcano",
			linha = 3,
			tipo = "passiva",
			nome = "Eco Arcano",
			icone = "✨",
			max = 5,
			requer = 0,
			requerTotal = 12, -- pontos gastos na árvore inteira
			eco = { 0.06, 0.04 }, -- chance da magia sair de novo, de graça
			texto = "%eco% de chance de lançar a magia DE NOVO na hora, de graça. Pede 12 pontos gastos na árvore.",
		},
		{
			id = "maestria",
			ramo = "arcano",
			linha = 4,
			tipo = "passiva",
			nome = "Maestria Elemental",
			icone = "🌈",
			max = 5,
			requer = 0,
			requerTotal = 20,
			critMagia = { 0.03, 0.02 }, -- crítico de todas as magias
			danoCritico = { 0.2, 0.15 }, -- crítico das magias causa mais
			texto = "+%critMagia% de crítico em todas as magias e críticos de magia causam +%danoCritico%. Pede 20 pontos.",
		},
	},
}

Habilidades.Arvores = { mago = mago }

-- índice por id
Habilidades.PorId = {}
for classeId, arvore in pairs(Habilidades.Arvores) do
	arvore.classe = classeId
	for ordem, h in ipairs(arvore.lista) do
		h.ordem = ordem
		h.classe = classeId
		Habilidades.PorId[h.id] = h
	end
end

function Habilidades.arvoreDe(classeId)
	return Habilidades.Arvores[classeId or ""]
end

function Habilidades.eAtiva(hab)
	return hab.tipo == "ativa" or hab.tipo == "suprema"
end

-- Pontos gastos num ramo (ou na árvore toda, se ramo = nil)
function Habilidades.gastos(niveis, ramo)
	local total = 0
	for id, n in pairs(niveis or {}) do
		local h = Habilidades.PorId[id]
		if h and (ramo == nil or h.ramo == ramo) then
			total += n
		end
	end
	return total
end

-- Pode aprender mais 1 nível? Devolve true ou false + motivo
function Habilidades.podeAprender(niveis, pontos, classeId, id)
	local h = Habilidades.PorId[id]
	if not h or h.classe ~= classeId then
		return false, "Habilidade de outra classe"
	end
	local n = (niveis or {})[id] or 0
	if n >= h.max then
		return false, "Nível máximo"
	end
	if (pontos or 0) < 1 then
		return false, "Sem pontos"
	end
	if h.requer > 0 and Habilidades.gastos(niveis, h.ramo) < h.requer then
		return false, string.format("Gaste %d pontos em %s", h.requer, h.ramo)
	end
	if h.requerTotal and Habilidades.gastos(niveis) < h.requerTotal then
		return false, string.format("Gaste %d pontos na árvore", h.requerTotal)
	end
	return true
end

-- Texto da descrição com os números do nível pedido
local CAMPOS_PCT = {
	bonusElem = true,
	estilhacar = true,
	atordoar = true,
	critMagia = true,
	poder = true,
	reducao = true,
	eco = true,
	danoCritico = true,
}
function Habilidades.descricao(hab, nivel)
	nivel = math.max(1, nivel or 1)
	return (
		string.gsub(hab.texto, "%%(%a+)%%", function(campo)
			local v = Habilidades.valor(hab, campo, nivel)
			if v == nil then
				return campo
			end
			if campo == "dano" or campo == "queima" or campo == "explodir" then
				return string.format("%d%%", math.floor(v + 0.5))
			elseif CAMPOS_PCT[campo] then
				return string.format("%d%%", math.floor(v * 100 + 0.5))
			elseif campo == "perfura" or campo == "saltos" or campo == "alvos" or campo == "golpes" then
				return tostring(math.floor(v))
			end
			return (string.gsub(string.format("%.1f", v), "%.0$", ""))
		end)
	)
end

return Habilidades
