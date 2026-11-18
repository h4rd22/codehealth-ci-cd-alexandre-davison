-- AnimHeroi: golpes do herói feitos em código, no ritmo dos ataques do servidor.
--   Guerreiro: corte diagonal, corte de volta e giro de espada (combo de 3), com rastro de luz
--   Caçador:   puxa o arco, solta (coice) e já puxa de novo; crítico = salto mortal atirando
--   Mago:      ergue o cajado, empurra a mão e abre um círculo mágico no chão
--   Magias:    cada habilidade da Maga tem pose própria (Animacoes.conjurar no servidor)
-- Também faz o herói se encolher quando apanha.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animacoes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animacoes"))
local VFX = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evDano = remotes:WaitForChild("Dano")

local player = Players.LocalPlayer
local clipe = Animacoes.clipe

local DOURADO = Color3.fromRGB(255, 215, 70)
local COR_ESPADA = Color3.fromRGB(255, 245, 225)
local COR_MAGIA = Color3.fromRGB(170, 100, 255)
local CORES = {
	gelo = Color3.fromRGB(150, 225, 255),
	raio = Color3.fromRGB(255, 235, 90),
	fogo = Color3.fromRGB(255, 120, 40),
}

------------------------------------------------------------------------
-- Clipes
------------------------------------------------------------------------
local C = {}

-- Guerreiro: 1) corte diagonal de cima para baixo
C.corte1 = clipe({
	{ 0, {} },
	{
		0.07,
		{
			ombroD = { 165, 0, 35 },
			cotoveloD = { 30, 0, 0 },
			ombroE = { 30, 0, -25 },
			tronco = { 6, -30, 0 },
			raiz = { 0, 0, 0, 0, 0, 0.3 },
		},
		"sai",
	},
	{
		0.15,
		{
			ombroD = { 55, 0, -40 },
			cotoveloD = { 5, 0, 0 },
			ombroE = { -20, 0, -35 },
			tronco = { -12, 40, 0 },
			raiz = { -6, 0, 0, 0, -0.2, -0.7 },
			pescoco = { -8, -15, 0 },
		},
		"entra",
	},
	{ 0.42, {}, "suave" },
})

-- 2) corte de volta (horizontal, da esquerda para a direita)
C.corte2 = clipe({
	{ 0, {} },
	{
		0.07,
		{
			ombroD = { 90, 55, -10 },
			cotoveloD = { 40, 0, 0 },
			tronco = { 0, 45, 0 },
			raiz = { 0, 0, 0, 0, -0.15, 0.2 },
		},
		"sai",
	},
	{
		0.16,
		{
			ombroD = { 95, -10, 75 },
			cotoveloD = { 5, 0, 0 },
			ombroE = { 40, 0, -30 },
			tronco = { -6, -45, 0 },
			raiz = { -4, 0, 0, 0, -0.2, -0.6 },
		},
		"entra",
	},
	{ 0.42, {}, "suave" },
})

-- 3) giro completo com a espada aberta
C.giro = clipe({
	{ 0, {} },
	{ 0.06, { ombroD = { 20, 0, 95 }, ombroE = { 20, 0, -80 }, raiz = { 0, 40, 0, 0, -0.5, 0 } }, "sai" },
	-- (cada quadro gira menos de meia-volta, senão o giro vai para o lado errado)
	{ 0.12, { ombroD = { 20, 0, 95 }, ombroE = { 20, 0, -80 }, raiz = { 0, -90, 0, 0, 0.2, 0 } }, "linear" },
	{ 0.18, { ombroD = { 20, 0, 95 }, ombroE = { 20, 0, -80 }, raiz = { 0, -200, 0, 0, 0.3, 0 } }, "linear" },
	{ 0.24, { ombroD = { 20, 0, 95 }, ombroE = { 20, 0, -80 }, raiz = { 0, -300, 0, 0, 0.2, 0 } }, "linear" },
	{ 0.3, { ombroD = { 20, 0, 95 }, ombroE = { 20, 0, -80 }, raiz = { 0, -360, 0, 0, 0, 0 } }, "linear" },
	{ 0.5, {}, "suave" },
})

-- Caçador: pose de arco armado (corpo de lado, braço do arco esticado, mão da corda no queixo)
local MIRAR = {
	tronco = { 0, -55, 0 },
	ombroE = { 0, -30, -88 },
	cotoveloE = { 0, 0, 0 },
	ombroD = { 92, 35, 0 },
	cotoveloD = { 0, 0, 0, 0, 0, 0 },
	pescoco = { 0, 50, 0 },
}
C.soltar = clipe({
	{ 0, MIRAR },
	{
		0.06,
		{
			tronco = { 6, -55, 0 },
			ombroE = { 8, -30, -88 },
			ombroD = { 60, -35, 25 },
			pescoco = { 4, 50, 0 },
			raiz = { 3, 0, 0, 0, 0, 0.35 },
		},
		"sai",
	},
	{ 0.12, MIRAR, "suave" },
	{ 0.45, MIRAR, "linear" },
	{ 0.9, {}, "suave" },
})
C.saltoMortal = clipe({
	{ 0, {} },
	{ 0.08, { raiz = { -15, 0, 0, 0, -0.8, 0 }, ombroE = { 0, -30, -88 }, ombroD = { 92, 35, 0 } }, "sai" },
	{ 0.2, { raiz = { 100, 0, 0, 0, 2.5, 0.8 }, ombroE = { 0, -30, -88 }, ombroD = { 92, 35, 0 } }, "linear" },
	{ 0.32, { raiz = { 220, 0, 0, 0, 3, 1.4 }, ombroE = { 0, -30, -88 }, ombroD = { 92, 35, 0 } }, "linear" },
	{ 0.5, { raiz = { 360, 0, 0, 0, 0.3, 2 }, ombroE = { 0, -30, -88 }, ombroD = { 60, -35, 25 } }, "linear" },
	{ 0.62, { raiz = { 360, 0, 0, 0, -0.4, 2 } }, "sai" },
	{ 0.85, {}, "suave" },
})

-- Mago: ergue o cajado e empurra a mão livre
C.magia = clipe({
	{ 0, {} },
	{
		0.1,
		{
			ombroD = { 170, 0, 15 },
			ombroE = { 70, 0, -20 },
			tronco = { 10, -10, 0 },
			pescoco = { 12, 0, 0 },
			raiz = { 0, 0, 0, 0, 0.15, 0.2 },
		},
		"sai",
	},
	{
		0.2,
		{
			ombroD = { 110, 0, 5 },
			ombroE = { 95, -10, 0 },
			cotoveloE = { 0, 0, 0 },
			tronco = { -10, 10, 0 },
			raiz = { -6, 0, 0, 0, 0, -0.45 },
		},
		"entra",
	},
	{ 0.4, { ombroD = { 100, 0, 5 }, ombroE = { 90, -10, 0 }, tronco = { -6, 10, 0 } }, "linear" },
	{ 0.75, {}, "suave" },
})

-- Apanhou: tranco para trás
C.apanhou = clipe({
	{ 0, {} },
	{
		0.05,
		{
			raiz = { 10, 0, 6, 0, 0, 0.45 },
			pescoco = { 18, 0, 0 },
			ombroD = { -15, 0, 20 },
			ombroE = { -15, 0, -20 },
		},
		"sai",
	},
	{ 0.3, {}, "suave" },
})

------------------------------------------------------------------------
-- Magias (ids do Jorge). Cada uma: clipe, cor, quando sai (s), canalização (s)
------------------------------------------------------------------------
local function canalizar(pose, dur)
	-- segura a pose por "dur" segundos, tremendo um pouco
	local q = { { 0, {} }, { 0.18, pose, "sai" } }
	local t = 0.18
	local i = 0
	while t < dur - 0.25 do
		t += 0.12
		i += 1
		local trem = {}
		for k, v in pairs(pose) do
			trem[k] = { v[1] + (i % 2 == 0 and 2 or -2), v[2] or 0, v[3] or 0, v[4] or 0, v[5] or 0, v[6] or 0 }
		end
		table.insert(q, { t, trem, "suave" })
	end
	table.insert(q, { dur, {}, "suave" })
	return clipe(q)
end

local MAGIAS = {}
-- GELO
MAGIAS.lancaGelo = {
	elemento = "gelo",
	sai = 0.14,
	clipe = clipe({
		{ 0, {} },
		{
			0.1,
			{ ombroD = { 40, 0, 40 }, ombroE = { 60, 0, -10 }, tronco = { 5, -35, 0 }, raiz = { 0, 0, 0, 0, 0, 0.3 } },
			"sai",
		},
		{
			0.2,
			{
				ombroD = { 95, 15, 0 },
				ombroE = { 30, 0, -40 },
				tronco = { -10, 25, 0 },
				raiz = { -8, 0, 0, 0, 0, -0.6 },
			},
			"entra",
		},
		{ 0.6, {}, "suave" },
	}),
}
MAGIAS.novaGelo = {
	elemento = "gelo",
	sai = 0.22,
	raioCirculo = 11,
	clipe = clipe({
		{ 0, {} },
		{
			0.12,
			{
				ombroD = { 170, 0, 20 },
				ombroE = { 170, 0, -20 },
				raiz = { 0, 0, 0, 0, 0.6, 0 },
				pescoco = { 20, 0, 0 },
			},
			"sai",
		},
		{
			0.24,
			{
				ombroD = { 30, 0, 75 },
				ombroE = { 30, 0, -75 },
				raiz = { -18, 0, 0, 0, -1, 0 },
				quadrilD = { 30, 0, 15 },
				quadrilE = { 30, 0, -15 },
				pescoco = { -15, 0, 0 },
			},
			"entra",
		},
		{ 0.45, { ombroD = { 30, 0, 80 }, ombroE = { 30, 0, -80 }, raiz = { -12, 0, 0, 0, -0.7, 0 } }, "linear" },
		{ 0.8, {}, "suave" },
	}),
}
MAGIAS.nevasca = {
	elemento = "gelo",
	sai = 0.2,
	canal = 3,
	raioCirculo = 13,
	clipe = canalizar(
		{ ombroD = { 178, 0, 8 }, ombroE = { 110, 0, -55 }, pescoco = { 22, 0, 0 }, raiz = { 6, 0, 0 } },
		3.2
	),
}
-- RAIO
MAGIAS.correnteRaio = {
	elemento = "raio",
	sai = 0.12,
	maoRaio = "frente",
	clipe = clipe({
		{ 0, {} },
		{ 0.08, { ombroD = { 60, 0, 60 }, tronco = { 0, -30, 0 } }, "sai" },
		{
			0.16,
			{
				ombroD = { 92, 10, 0 },
				ombroE = { 20, 0, -35 },
				tronco = { -6, 20, 0 },
				raiz = { -5, 0, 0, 0, 0, -0.4 },
			},
			"entra",
		},
		{ 0.5, { ombroD = { 90, 10, 0 }, tronco = { -4, 20, 0 } }, "linear" },
		{ 0.75, {}, "suave" },
	}),
}
MAGIAS.furiaTrovao = {
	elemento = "raio",
	sai = 0.2,
	maoRaio = "ceu",
	clipe = clipe({
		{ 0, {} },
		{ 0.12, { ombroD = { 60, 0, 30 }, raiz = { 0, 0, 0, 0, -0.5, 0 }, pescoco = { -10, 0, 0 } }, "sai" },
		{
			0.22,
			{ ombroD = { 180, 0, 0 }, ombroE = { 40, 0, -60 }, raiz = { 8, 0, 0, 0, 0.4, 0 }, pescoco = { 30, 0, 0 } },
			"volta",
		},
		{ 0.65, { ombroD = { 178, 0, 0 }, ombroE = { 40, 0, -60 }, pescoco = { 25, 0, 0 } }, "linear" },
		{ 0.95, {}, "suave" },
	}),
}
MAGIAS.tempestade = {
	elemento = "raio",
	sai = 0.2,
	canal = 4,
	maoRaio = "ceu",
	raioCirculo = 12,
	clipe = canalizar(
		{ ombroD = { 175, 0, 25 }, ombroE = { 175, 0, -25 }, pescoco = { 30, 0, 0 }, raiz = { 8, 0, 0 } },
		4.2
	),
}
-- FOGO
MAGIAS.bolaFogo = {
	elemento = "fogo",
	sai = 0.16,
	clipe = clipe({
		{ 0, {} },
		{
			0.1,
			{ ombroD = { -40, 0, 30 }, ombroE = { 70, 0, -20 }, tronco = { 5, -50, 0 }, raiz = { 0, 0, 0, 0, 0, 0.4 } },
			"sai",
		},
		{
			0.2,
			{
				ombroD = { 110, -20, -10 },
				ombroE = { -20, 0, -30 },
				tronco = { -14, 35, 0 },
				raiz = { -8, 0, 0, 0, 0, -0.7 },
			},
			"entra",
		},
		{ 0.6, {}, "suave" },
	}),
}
MAGIAS.anelChamas = {
	elemento = "fogo",
	sai = 0.25,
	raioCirculo = 12,
	clipe = clipe({
		{ 0, {} },
		{ 0.08, { ombroD = { 20, 0, 90 }, ombroE = { 20, 0, -90 }, raiz = { 0, 30, 0, 0, -0.4, 0 } }, "sai" },
		{ 0.16, { ombroD = { 20, 0, 90 }, ombroE = { 20, 0, -90 }, raiz = { 0, -90, 0, 0, 0.3, 0 } }, "linear" },
		{ 0.24, { ombroD = { 20, 0, 90 }, ombroE = { 20, 0, -90 }, raiz = { 0, -210, 0, 0, 0.5, 0 } }, "linear" },
		{ 0.32, { ombroD = { 20, 0, 90 }, ombroE = { 20, 0, -90 }, raiz = { 0, -320, 0, 0, 0.3, 0 } }, "linear" },
		{ 0.4, { ombroD = { 20, 0, 90 }, ombroE = { 20, 0, -90 }, raiz = { 0, -360, 0, 0, 0, 0 } }, "linear" },
		{ 0.65, {}, "suave" },
	}),
}
MAGIAS.meteoro = {
	elemento = "fogo",
	sai = 0.5,
	raioCirculo = 9,
	clipe = clipe({
		{ 0, {} },
		{
			0.35,
			{
				ombroD = { 175, 0, 20 },
				ombroE = { 175, 0, -20 },
				raiz = { 10, 0, 0, 0, 0.4, 0 },
				pescoco = { 35, 0, 0 },
			},
			"sai",
		},
		{
			0.45,
			{
				ombroD = { 178, 0, 15 },
				ombroE = { 178, 0, -15 },
				raiz = { 12, 0, 0, 0, 0.5, 0 },
				pescoco = { 35, 0, 0 },
			},
			"linear",
		},
		{
			0.55,
			{
				ombroD = { 70, 0, 10 },
				ombroE = { 70, 0, -10 },
				raiz = { -25, 0, 0, 0, -0.8, -0.3 },
				pescoco = { -10, 0, 0 },
			},
			"entra",
		},
		{ 0.85, { ombroD = { 60, 0, 10 }, ombroE = { 60, 0, -10 }, raiz = { -18, 0, 0, 0, -0.6, -0.3 } }, "linear" },
		{ 1.2, {}, "suave" },
	}),
}
-- Elementos sozinhos (se vier só "gelo", "raio" ou "fogo")
MAGIAS.gelo = MAGIAS.lancaGelo
MAGIAS.raio = MAGIAS.correnteRaio
MAGIAS.fogo = MAGIAS.bolaFogo

------------------------------------------------------------------------
-- Ajudantes
------------------------------------------------------------------------
local function corpo()
	local char = player.Character
	local raiz = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not raiz or not hum or hum.Health <= 0 then
		return nil
	end
	return char, raiz, hum
end

local function chao(raiz, hum)
	local altura = hum.HipHeight + raiz.Size.Y / 2
	if hum.RigType == Enum.HumanoidRigType.R6 then
		altura = raiz.Size.Y / 2 + 2
	end
	return raiz.Position - Vector3.new(0, altura - 0.08, 0)
end

-- Ponta da mão direita (onde fica a arma)
local function maoDireita(char)
	local mao = char:FindFirstChild("RightHand")
	if mao then
		return mao.Position
	end
	local braco = char:FindFirstChild("Right Arm")
	if braco then
		return (braco.CFrame * CFrame.new(0, -1, 0)).Position
	end
	return nil
end

-- Vira o herói para o alvo quando ele está parado atacando
local function virarPara(raiz, hum, alvo)
	if typeof(alvo) ~= "Vector3" or hum.MoveDirection.Magnitude > 0.1 then
		return
	end
	local plano = Vector3.new(alvo.X, raiz.Position.Y, alvo.Z)
	if (plano - raiz.Position).Magnitude > 0.5 then
		raiz.CFrame = CFrame.lookAt(raiz.Position, plano)
	end
end

------------------------------------------------------------------------
-- Ataques básicos
------------------------------------------------------------------------
local combo = 0
local ultimoGolpe = 0

local function golpeGuerreiro(alvo, critico)
	local char, raiz, hum = corpo()
	if not char then
		return
	end
	local agora = os.clock()
	if agora - ultimoGolpe < 0.2 then
		return
	end
	if agora - ultimoGolpe > 1.4 then
		combo = 0
	end
	ultimoGolpe = agora
	combo = combo % 3 + 1
	virarPara(raiz, hum, alvo)
	local cor = critico and DOURADO or COR_ESPADA
	local largura = critico and 2.4 or 1.6
	if combo == 1 then
		Animacoes.tocar(char, C.corte1, "ataque")
		task.delay(0.06, function()
			local base = raiz.CFrame * CFrame.new(0, 0.6, -0.5) * CFrame.Angles(0, 0, math.rad(-50))
			Animacoes.arco(base, 5, -80, 85, cor, largura, 0.3)
		end)
	elseif combo == 2 then
		Animacoes.tocar(char, C.corte2, "ataque")
		task.delay(0.06, function()
			local base = raiz.CFrame * CFrame.new(0, 0.2, -0.5) * CFrame.Angles(0, 0, math.rad(8))
			Animacoes.arco(base, 5.2, -95, 95, cor, largura, 0.3)
		end)
	else
		Animacoes.tocar(char, C.giro, "ataque")
		task.delay(0.07, function()
			local base = raiz.CFrame * CFrame.new(0, -0.3, 0)
			Animacoes.arco(base, 5.5, 0, -350, cor, largura * 1.2, 0.36)
			Animacoes.anel(chao(raiz, hum) + Vector3.new(0, 0.2, 0), cor, 9, 0.4, 0.6)
		end)
	end
	if typeof(alvo) == "Vector3" then
		task.delay(0.08, function()
			local olhar = CFrame.lookAt(alvo, raiz.Position)
			if critico then
				VFX.estouro("Golpes/HEAVYPunchGenshinpack", olhar, { anexo = "ParticleA", mult = 0.3 })
				VFX.estouro("Golpes/GiganticCrush", olhar, { escala = 0.6 })
			else
				VFX.estouro("Golpes/SlashGenshinPack", olhar, { anexo = "ParticleA", mult = 2 })
			end
		end)
	end
	if critico then
		task.delay(0.1, function()
			if typeof(alvo) == "Vector3" then
				Animacoes.brilhos(alvo, DOURADO, 25, 20)
			end
		end)
	end
end

local disparos = 0
local function tiroCacador(origem, alvo, critico)
	local char, raiz, hum = corpo()
	if not char then
		return
	end
	virarPara(raiz, hum, alvo)
	disparos += 1
	if critico then
		Animacoes.tocar(char, C.saltoMortal, "ataque")
		task.delay(0.3, function()
			Animacoes.anel(raiz.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(90), 0, 0), DOURADO, 4, 0.3, 0.5)
		end)
	else
		Animacoes.tocar(char, C.soltar, "ataque")
	end
	-- estalo da corda: anel de vento em pé na frente do arco
	local frente = raiz.CFrame * CFrame.new(-0.4, 0.6, -1.6)
	Animacoes.anel(
		frente * CFrame.Angles(math.rad(90), 0, 0),
		critico and DOURADO or Color3.fromRGB(200, 255, 200),
		2.2,
		0.22,
		0.4
	)
	if origem then
		Animacoes.brilhos(frente.Position, Color3.fromRGB(180, 255, 160), 6, 8)
	end
end

local function feiticoMago(alvo, critico)
	local char, raiz, hum = corpo()
	if not char then
		return
	end
	virarPara(raiz, hum, alvo)
	Animacoes.tocar(char, C.magia, "ataque")
	local cor = critico and DOURADO or COR_MAGIA
	Animacoes.circuloMagico(CFrame.new(chao(raiz, hum)), cor, 3.4, 0.75)
	task.delay(0.12, function()
		local mao = maoDireita(char)
		if mao then
			Animacoes.clarao(mao, cor, 3, 0.25, 10)
			Animacoes.brilhos(mao, cor, 10, 10)
			VFX.estouro("Golpes/Parryburst", mao, { escala = 0.5, cor = cor })
		end
	end)
end

------------------------------------------------------------------------
-- Magias da Maga
------------------------------------------------------------------------
local function conjurar(id, alvo)
	local char, raiz, hum = corpo()
	if not char then
		return
	end
	local m = MAGIAS[id]
	local elemento = m and m.elemento or (CORES[id] and id) or nil
	if not m then
		m = MAGIAS[elemento or "fogo"]
	end
	local cor = CORES[elemento] or COR_MAGIA
	virarPara(raiz, hum, alvo)
	Animacoes.tocar(char, m.clipe, "ataque")

	local raioC = m.raioCirculo or 4
	local pes = chao(raiz, hum)
	Animacoes.circuloMagico(CFrame.new(pes), cor, math.min(raioC, 6), (m.canal or 0) + 0.8)
	if m.raioCirculo then
		task.delay(m.sai, function()
			Animacoes.circuloMagico(CFrame.new(pes), cor, raioC, 0.6)
			Animacoes.anel(pes + Vector3.new(0, 0.3, 0), cor, raioC, 0.45, 1)
		end)
	end
	-- brilho na mão no momento em que a magia sai
	task.delay(m.sai, function()
		local mao = maoDireita(char)
		if not mao then
			return
		end
		Animacoes.clarao(mao, cor, 4, 0.3, 14)
		Animacoes.brilhos(mao, cor, 14, 12)
		if m.maoRaio == "ceu" then
			Animacoes.relampago(mao, mao + Vector3.new(math.random(-2, 2), 16, math.random(-2, 2)), cor, 0.2, 0.3)
		elseif m.maoRaio == "frente" then
			Animacoes.relampago(mao, mao + raiz.CFrame.LookVector * 6, cor, 0.15, 0.2)
		end
	end)
	-- supremas: aura de poder em volta do herói
	local AURAS = { nevasca = "Auras/Mystic", tempestade = "Auras/SSJ", meteoro = "Auras/Kaioken" }
	if AURAS[id] then
		VFX.grudar(AURAS[id], raiz, (m.canal or 0.6) + 0.6, { deslocamento = Vector3.new(0, -1, 0) })
		VFX.estouro("Auras/SSJCharge", raiz.Position, { mult = 1.5 })
	end
	-- canalização longa: pulsos de energia enquanto segura a pose
	if m.canal then
		task.spawn(function()
			local fim = os.clock() + m.canal
			while os.clock() < fim and char.Parent do
				task.wait(0.35)
				local mao = maoDireita(char)
				if mao then
					Animacoes.brilhos(mao, cor, 8, 9)
					if m.maoRaio then
						Animacoes.relampago(
							mao,
							mao + Vector3.new(math.random(-3, 3), 14, math.random(-3, 3)),
							cor,
							0.15,
							0.22
						)
					end
				end
				Animacoes.anel(chao(raiz, hum) + Vector3.new(0, 0.2, 0), cor, raioC * 0.6, 0.4, 0.5)
			end
		end)
	end
end

player:GetAttributeChangedSignal("AnimConjurar"):Connect(function()
	local v = player:GetAttribute("AnimConjurar")
	if typeof(v) ~= "string" then
		return
	end
	local id = string.match(v, "^([^|]+)")
	conjurar(id, player:GetAttribute("AnimConjurarAlvo"))
end)

------------------------------------------------------------------------
-- Eventos do servidor
------------------------------------------------------------------------
local ultimoApanhou = 0
evDano.OnClientEvent:Connect(function(tipo, pos, valor, extra, xp)
	local classe = player:GetAttribute("Classe")
	if tipo == "projetil" then
		-- pos = origem, valor = destino, extra = classe, xp = crítico
		if extra == "mago" then
			feiticoMago(valor, xp)
		else
			tiroCacador(pos, valor, xp)
		end
	elseif tipo == "dano" then
		if classe ~= "cacador" and classe ~= "mago" then
			golpeGuerreiro(pos, extra)
		end
	elseif tipo == "heroi" then
		local agora = os.clock()
		local char = corpo()
		if char and agora - ultimoApanhou > 0.35 and not Animacoes.tocando(char, "ataque") then
			ultimoApanhou = agora
			Animacoes.tocar(char, C.apanhou, "apanhou", 0.8)
		end
	end
end)

------------------------------------------------------------------------
-- Postura de combate quando o herói está parado (o equipamento aparece bem):
--   Guerreiro: espada pronta na frente · Caçador: arco meio erguido · Mago: cajado à frente
------------------------------------------------------------------------
local POSTURAS = {
	guerreiro = {
		ombroD = { 38, 0, 14 },
		cotoveloD = { 28, 0, 0 },
		ombroE = { 22, 0, -22 },
		tronco = { 0, -12, 0 },
		raiz = { -5, 0, 0 },
	},
	cacador = {
		ombroE = { 28, -12, -16 },
		cotoveloE = { 10, 0, 0 },
		ombroD = { 12, 0, 12 },
		tronco = { 0, -18, 0 },
		pescoco = { 0, 12, 0 },
	},
	mago = { ombroD = { 32, 0, 10 }, cotoveloD = { 32, 0, 0 }, ombroE = { 18, 0, -28 }, pescoco = { -5, 0, 0 } },
}
local posturaPronta = {}
for nome, p in pairs(POSTURAS) do
	posturaPronta[nome] = Animacoes.pose(p)
end

local function postura(t)
	local classe = player:GetAttribute("Classe")
	local base = posturaPronta[classe] or posturaPronta.guerreiro
	-- respiração: sobe e desce de leve
	local resp = math.sin(t * 2.4)
	local p = table.clone(base)
	p.raiz = (p.raiz or CFrame.identity) * CFrame.new(0, resp * 0.05, 0)
	p.pescoco = (p.pescoco or CFrame.identity) * CFrame.Angles(math.rad(resp * 1.5), 0, 0)
	return p
end

task.spawn(function()
	local parado = false
	while true do
		task.wait(0.15)
		local char, _, hum = corpo()
		if char then
			local agoraParado = hum.MoveDirection.Magnitude < 0.1 and hum.FloorMaterial ~= Enum.Material.Air
			if agoraParado ~= parado or (agoraParado and not Animacoes.tocando(char, "postura")) then
				parado = agoraParado
				if parado then
					Animacoes.manter(char, "postura", postura, 6)
				else
					Animacoes.soltar(char, "postura")
				end
			end
		end
	end
end)
