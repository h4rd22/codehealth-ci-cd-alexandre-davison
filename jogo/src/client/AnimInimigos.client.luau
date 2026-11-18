-- AnimInimigos: deixa o combate vivo na tela do jogador.
--   Levou golpe: tranco para trás, cabeça joga, braços balançam
--   Ataque:      prepara (inclina para trás, braço no alto) e dá o bote
--   Correndo:    corrida ninja (corpo inclinado, braços para trás)
--   Elite:       pose ameaçadora + rugido ao aparecer
--   Morte:       voa para trás girando / cai de costas / sobe rodopiando, e some num brilho
--   Chefe Pen:   flutua, inclina ao andar, poses de cada habilidade, entrada e morte épicas
-- O servidor avisa por atributos do modelo: Vida, Ataque, Correndo, Elite, Chefe, Pose, Movendo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animacoes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animacoes"))
local VFX = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"))

local player = Players.LocalPlayer
local pasta = workspace:WaitForChild("Monstros")
local clipe = Animacoes.clipe

local ROXO = Color3.fromRGB(180, 90, 255)
local BRANCO = Color3.new(1, 1, 1)

local function posHeroi()
	local char = player.Character
	local raiz = char and char:FindFirstChild("HumanoidRootPart")
	return raiz and raiz.Position
end

-- Direção (no espaço da raiz do inimigo) que aponta para longe do herói
local function longeDoHeroi(raiz)
	local h = posHeroi()
	local dir = h and (raiz.Position - h) * Vector3.new(1, 0, 1)
	if not dir or dir.Magnitude < 0.1 then
		dir = -raiz.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	if dir.Magnitude < 0.01 then
		dir = Vector3.zAxis
	end
	return raiz.CFrame:VectorToObjectSpace(dir.Unit), dir.Unit
end

------------------------------------------------------------------------
-- Clipes fixos
------------------------------------------------------------------------
local C = {}

C.ataque = clipe({
	{ 0, {} },
	{
		0.13,
		{
			raiz = { 10, 0, 0, 0, 0, 0.5 },
			ombroD = { 150, 0, 25 },
			ombroE = { 40, 0, -30 },
			pescoco = { -10, 0, 0 },
		},
		"sai",
	},
	{
		0.21,
		{
			raiz = { -20, 0, 0, 0, -0.2, -1.3 },
			ombroD = { 55, 0, -25 },
			ombroE = { -35, 0, -20 },
			pescoco = { 10, 0, 0 },
		},
		"entra",
	},
	{ 0.5, {}, "suave" },
})

C.rugido = clipe({
	{ 0, {} },
	{
		0.2,
		{ raiz = { 12, 0, 0 }, ombroD = { 40, 0, 100 }, ombroE = { 40, 0, -100 }, pescoco = { 28, 0, 0 } },
		"volta",
	},
	{
		0.9,
		{ raiz = { 14, 0, 0 }, ombroD = { 45, 0, 105 }, ombroE = { 45, 0, -105 }, pescoco = { 30, 0, 0 } },
		"linear",
	},
	{ 1.25, {}, "suave" },
})

------------------------------------------------------------------------
-- Pen: poses das habilidades
------------------------------------------------------------------------
local P = {}
P.entrada = clipe({
	{ 0, { ombroD = { 15, 0, 35 }, ombroE = { 15, 0, -35 }, pescoco = { -20, 0, 0 }, raiz = { -8, 0, 0 } } },
	{ 1, { ombroD = { 20, 0, 40 }, ombroE = { 20, 0, -40 }, pescoco = { -25, 0, 0 }, raiz = { -10, 0, 0 } }, "linear" },
	{ 1.2, {}, "suave" },
})
P.rugido = clipe({
	{ 0, {} },
	{
		0.25,
		{ raiz = { 18, 0, 0 }, ombroD = { 30, 0, 115 }, ombroE = { 30, 0, -115 }, pescoco = { 35, 0, 0 } },
		"volta",
	},
	{
		1.3,
		{ raiz = { 20, 0, 0 }, ombroD = { 35, 0, 120 }, ombroE = { 35, 0, -120 }, pescoco = { 38, 0, 0 } },
		"linear",
	},
	{ 1.7, {}, "suave" },
})
local CARGA = { raiz = { -22, 0, 0 }, ombroD = { 75, 0, -55 }, ombroE = { 75, 0, 55 }, pescoco = { -22, 0, 0 } }
P.repulsao = clipe({
	{ 0, {} },
	{ 0.3, CARGA, "sai" },
	{ 0.5, { raiz = { -24, 0, 2 }, ombroD = { 78, 0, -52 }, ombroE = { 72, 0, 58 }, pescoco = { -22, 0, 0 } } },
	{ 0.7, { raiz = { -22, 0, -2 }, ombroD = { 72, 0, -58 }, ombroE = { 78, 0, 52 }, pescoco = { -24, 0, 0 } } },
	{ 0.9, { raiz = { -25, 0, 2 }, ombroD = { 80, 0, -50 }, ombroE = { 72, 0, 56 }, pescoco = { -22, 0, 0 } } },
	{ 1.1, { raiz = { -22, 0, -2 }, ombroD = { 72, 0, -56 }, ombroE = { 80, 0, 50 }, pescoco = { -25, 0, 0 } } },
	{ 1.6, CARGA, "linear" },
	{ 1.9, {}, "suave" },
})
P.repulsaoSolta = clipe({
	{ 0, CARGA },
	{
		0.08,
		{ raiz = { 22, 0, 0 }, ombroD = { 20, 0, 125 }, ombroE = { 20, 0, -125 }, pescoco = { 30, 0, 0 } },
		"sai",
	},
	{
		0.55,
		{ raiz = { 18, 0, 0 }, ombroD = { 25, 0, 120 }, ombroE = { 25, 0, -120 }, pescoco = { 25, 0, 0 } },
		"linear",
	},
	{ 0.95, {}, "suave" },
})
P.esferas = clipe({
	{ 0, {} },
	{
		0.12,
		{ ombroD = { 150, 0, 30 }, ombroE = { 160, 0, -25 }, raiz = { 8, -25, 0 }, pescoco = { 10, 0, 0 } },
		"sai",
	},
	{
		0.22,
		{ ombroD = { 95, 0, 0 }, ombroE = { 150, 0, -30 }, raiz = { -12, 20, 0, 0, 0, -0.6 }, pescoco = { -5, 0, 0 } },
		"entra",
	},
	{ 0.45, { ombroD = { 92, 0, 0 }, ombroE = { 140, 0, -30 }, raiz = { -8, 15, 0 } }, "linear" },
	{ 0.7, {}, "suave" },
})
local CEU = { ombroD = { 175, 0, 20 }, ombroE = { 175, 0, -20 }, pescoco = { 35, 0, 0 }, raiz = { 10, 0, 0 } }
P.pregos = clipe({
	{ 0, {} },
	{ 0.3, CEU, "volta" },
	{ 0.6, { ombroD = { 178, 0, 22 }, ombroE = { 172, 0, -18 }, pescoco = { 38, 0, 0 }, raiz = { 11, 0, 0 } } },
	{ 0.9, { ombroD = { 172, 0, 18 }, ombroE = { 178, 0, -22 }, pescoco = { 35, 0, 0 }, raiz = { 10, 0, 0 } } },
	{ 1.4, CEU, "linear" },
	{ 1.6, {}, "suave" },
})
P.pregosSolta = clipe({
	{ 0, CEU },
	{
		0.12,
		{ ombroD = { 60, 0, 15 }, ombroE = { 60, 0, -15 }, raiz = { -28, 0, 0, 0, -0.5, 0 }, pescoco = { -15, 0, 0 } },
		"entra",
	},
	{ 0.5, { ombroD = { 55, 0, 15 }, ombroE = { 55, 0, -15 }, raiz = { -22, 0, 0 } }, "linear" },
	{ 0.85, {}, "suave" },
})
P.sumir = clipe({
	{ 0, {} },
	{
		0.25,
		{
			raiz = { -30, 170, 0, 0, -1, 0 },
			ombroD = { 120, 0, -60 },
			ombroE = { 120, 0, 60 },
			pescoco = { -25, 0, 0 },
		},
		"entra",
	},
	{ 0.35, {}, "linear" },
})
P.surgir = clipe({
	{ 0, { raiz = { 0, -170, 0, 0, -1, 0 } } },
	{
		0.25,
		{ raiz = { 12, 0, 0, 0, 0.3, 0 }, ombroD = { 30, 0, 90 }, ombroE = { 30, 0, -90 }, pescoco = { 15, 0, 0 } },
		"volta",
	},
	{ 0.7, {}, "suave" },
})

------------------------------------------------------------------------
-- Camadas contínuas
------------------------------------------------------------------------
local CORRIDA = Animacoes.pose({
	raiz = { -16, 0, 0 },
	ombroD = { -60, 0, 12 },
	ombroE = { -60, 0, -12 },
	pescoco = { 12, 0, 0 },
})
local function corrida()
	return CORRIDA
end

local function ameaca(t)
	local resp = math.sin(t * 2.2)
	return Animacoes.pose({
		raiz = { 6 + resp * 1.5, 0, 0, 0, resp * 0.06, 0 },
		pescoco = { -14, 0, 0 },
		ombroD = { 4, 0, 16 + resp * 3 },
		ombroE = { 4, 0, -16 - resp * 3 },
	})
end

-- Pen flutuando (balanço suave, pernas soltas, olhar de cima); inclina quando anda
local function flutuarPen(m)
	return function(t)
		local andando = m:GetAttribute("Movendo") == true
		local s = math.sin(t * 1.8)
		local incl = andando and -14 or 0
		return Animacoes.pose({
			raiz = { incl + math.sin(t * 0.9) * 2, 0, math.sin(t * 0.7) * 3, 0, s * 0.35, 0 },
			pescoco = { -12, math.sin(t * 0.5) * 6, 0 },
			ombroD = { (andando and -25 or 10) + s * 4, 0, 22 + s * 4 },
			ombroE = { (andando and -25 or 10) + s * 4, 0, -22 - s * 4 },
			quadrilD = { -8 + math.sin(t * 1.8 + 0.6) * 6, 0, 4 },
			quadrilE = { 6 + math.sin(t * 1.8 + 1.4) * 6, 0, -4 },
		})
	end
end

------------------------------------------------------------------------
-- Morte: clona o inimigo só nesta tela e faz o corpo voar
------------------------------------------------------------------------
local mortos = setmetatable({}, { __mode = "k" })

local function esconder(m)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		elseif d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("ParticleEmitter") or d:IsA("Light") then
			d.Enabled = false
		end
	end
end

local function clonar(m)
	m.Archivable = true
	local ok, c = pcall(function()
		return m:Clone()
	end)
	if not ok or not c then
		return nil
	end
	for _, d in ipairs(c:GetDescendants()) do
		if
			d:IsA("BillboardGui")
			or d:IsA("Highlight")
			or d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("Animator")
		then
			d:Destroy()
		elseif d:IsA("BasePart") or d:IsA("Decal") then
			-- volta a transparência de quando ele nasceu (o servidor já começou a apagá-lo)
			local t0 = d:GetAttribute("T0")
			if typeof(t0) == "number" then
				d.Transparency = t0
			end
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 0
			end
		end
	end
	c.Name = m.Name .. "_Morte"
	c.Parent = Animacoes.pastaFx()
	return c
end

-- Some num brilho: fica branco, encolhe e espirra estrelinhas
local function sumirComBrilho(c, cor, grande)
	local raiz = c.PrimaryPart
	if not raiz then
		c:Destroy()
		return
	end
	local h = Instance.new("Highlight")
	h.FillColor = BRANCO
	h.OutlineColor = cor
	h.FillTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = c
	local pos = raiz.Position
	Animacoes.esquecer(c) -- congela a pose; daqui em diante só encolhe
	local escala0 = c:GetScale()
	local tempo = grande and 0.45 or 0.18
	Animacoes.durante(tempo, function(a)
		h.FillTransparency = 1 - math.min(1, a * 2.5)
		c:ScaleTo(math.max(0.02, escala0 * (1 - a * a)))
	end, function()
		pos = raiz.Position
		c:Destroy()
		Animacoes.clarao(pos, BRANCO, grande and 16 or 5, grande and 0.5 or 0.25, grande and 40 or 12)
		Animacoes.brilhos(pos, cor, grande and 60 or 18, grande and 30 or 16)
		Animacoes.anel(pos, cor, grande and 22 or 6, grande and 0.6 or 0.35, grande and 1.5 or 0.6)
	end)
end

local POSE_VOANDO = Animacoes.pose({
	ombroD = { 150, 0, 40 },
	ombroE = { 150, 0, -40 },
	quadrilD = { 25, 0, 20 },
	quadrilE = { -15, 0, -20 },
	pescoco = { 30, 0, 0 },
})
local POSE_CAIDO = Animacoes.pose({
	ombroD = { 30, 0, 80 },
	ombroE = { 30, 0, -80 },
	quadrilD = { 10, 0, 15 },
	quadrilE = { 10, 0, -15 },
	pescoco = { 25, 0, 0 },
})

local function morteComum(m, cor)
	local raiz = m.PrimaryPart
	if not raiz then
		return
	end
	VFX.estouro("Golpes/BasicHit", raiz.Position, { anexo = "KnockbackParticle" })
	local c = clonar(m)
	esconder(m)
	if not c or not c.PrimaryPart then
		if c then
			c:Destroy()
		end
		return
	end
	local craiz = c.PrimaryPart
	local desvio = craiz.CFrame:ToObjectSpace(c:GetPivot())
	local cf0 = craiz.CFrame
	local _, dirMundo = longeDoHeroi(raiz)
	local olhar = CFrame.lookAt(cf0.Position, cf0.Position - dirMundo) -- de frente para o herói
	-- impacto: o corpo "congela" branco por um instante antes de voar (sensação de golpe forte)
	local branco = Instance.new("Highlight")
	branco.FillColor = BRANCO
	branco.FillTransparency = 0
	branco.OutlineColor = cor
	branco.DepthMode = Enum.HighlightDepthMode.Occluded
	branco.Parent = c
	Animacoes.clarao(cf0.Position, BRANCO, 5, 0.18, 14)
	Animacoes.anel(
		CFrame.lookAt(cf0.Position, cf0.Position + dirMundo) * CFrame.Angles(-math.pi / 2, 0, 0),
		cor,
		6,
		0.3,
		0.6
	)
	task.wait(0.07)
	branco:Destroy()
	if not c.Parent then
		return
	end
	local tipo = math.random(3)
	if Animacoes.rig(c) then
		Animacoes.manter(c, "morte", function()
			return tipo == 2 and POSE_CAIDO or POSE_VOANDO
		end, 25)
	end
	local tam = c:GetExtentsSize().Y
	if tipo == 1 then
		-- voa para trás girando de costas
		local dist = 9 + math.random() * 5
		local alto = 3.5 + math.random() * 2
		Animacoes.durante(0.55, function(a)
			local pos = cf0.Position + dirMundo * dist * a + Vector3.new(0, math.sin(a * math.pi) * alto, 0)
			local cf = CFrame.new(pos) * olhar.Rotation * CFrame.Angles(math.rad(a * 540), 0, 0)
			c:PivotTo(cf * desvio)
		end, function()
			sumirComBrilho(c, cor)
		end)
	elseif tipo == 2 then
		-- cai de costas, quica e some
		local dist = 3 + math.random() * 2
		Animacoes.durante(0.6, function(a)
			local queda = math.min(1, a / 0.55)
			local ang = 90 * (queda * queda)
			local quique = a > 0.55 and math.sin((a - 0.55) / 0.45 * math.pi) * 0.6 or 0
			local pos = cf0.Position + dirMundo * dist * queda + Vector3.new(0, -tam * 0.32 * queda + quique, 0)
			local cf = CFrame.new(pos) * olhar.Rotation * CFrame.Angles(math.rad(ang), 0, 0)
			c:PivotTo(cf * desvio)
		end, function()
			task.delay(0.12, function()
				if c.Parent then
					sumirComBrilho(c, cor)
				end
			end)
		end)
	else
		-- sobe rodopiando e explode no ar
		local alto = 6 + math.random() * 3
		Animacoes.durante(0.5, function(a)
			local e = 1 - (1 - a) * (1 - a)
			local pos = cf0.Position + dirMundo * 3 * a + Vector3.new(0, e * alto, 0)
			local cf = CFrame.new(pos) * olhar.Rotation * CFrame.Angles(0, math.rad(a * 900), math.rad(a * 40))
			c:PivotTo(cf * desvio)
		end, function()
			sumirComBrilho(c, cor)
		end)
	end
end

-- Morte do chefe: treme, sobe de braços abertos com raios de luz e implode
local POSE_AGONIA = Animacoes.pose({
	raiz = { -15, 0, 0 },
	ombroD = { 70, 0, -40 },
	ombroE = { 70, 0, 40 },
	pescoco = { -25, 0, 0 },
})
local POSE_ASCENSAO = Animacoes.pose({
	raiz = { 20, 0, 0 },
	ombroD = { 30, 0, 130 },
	ombroE = { 30, 0, -130 },
	pescoco = { 40, 0, 0 },
	quadrilD = { -10, 0, 10 },
	quadrilE = { -10, 0, -10 },
})

local function morteChefe(m, cor)
	local raiz = m.PrimaryPart
	if not raiz then
		return
	end
	local c = clonar(m)
	esconder(m)
	if not c or not c.PrimaryPart then
		if c then
			c:Destroy()
		end
		return
	end
	cor = cor or ROXO
	local craiz = c.PrimaryPart
	local desvio = craiz.CFrame:ToObjectSpace(c:GetPivot())
	local cf0 = craiz.CFrame
	local fase = "agonia"
	if Animacoes.rig(c) then
		Animacoes.manter(c, "morte", function()
			return fase == "agonia" and POSE_AGONIA or POSE_ASCENSAO
		end, 6)
	end
	local h = Instance.new("Highlight")
	h.FillColor = BRANCO
	h.OutlineColor = cor
	h.FillTransparency = 1
	h.OutlineTransparency = 0
	h.Parent = c

	-- raios de luz saindo do corpo
	local raios = {}
	for i = 1, 10 do
		local p = Animacoes.pecaFx(Vector3.new(0.5, 0.5, 1), i % 2 == 0 and BRANCO or cor)
		p.Transparency = 1
		p.Parent = Animacoes.pastaFx()
		raios[i] = { p = p, giro = CFrame.Angles(math.random() * 6.28, math.random() * 6.28, 0) }
	end

	local proximoEstouro = 0
	Animacoes.durante(2.4, function(a)
		local t = a * 2.4
		local pos
		if t < 0.9 then
			-- tremendo de dor, piscando
			fase = "agonia"
			local tr = 0.35 * (1 - t / 0.9 * 0.3)
			pos = cf0.Position
				+ Vector3.new((math.random() - 0.5) * tr, (math.random() - 0.5) * tr, (math.random() - 0.5) * tr)
			h.FillTransparency = (math.floor(t * 12) % 2 == 0) and 0.4 or 1
			if t > proximoEstouro then
				proximoEstouro = t + 0.18
				local ext = c:GetExtentsSize()
				local p = pos
					+ Vector3.new(
							(math.random() - 0.5) * ext.X,
							(math.random() - 0.5) * ext.Y,
							(math.random() - 0.5) * ext.Z
						)
						* 0.6
				Animacoes.clarao(p, cor, 4, 0.25, 10)
				Animacoes.brilhos(p, cor, 10, 14)
			end
		else
			-- sobe de braços abertos, com raios girando
			fase = "ascensao"
			local s = math.min(1, (t - 0.9) / 1.1)
			pos = cf0.Position + Vector3.new(0, (1 - (1 - s) ^ 2) * 7, 0)
			h.FillTransparency = 1 - s * 0.8
			for i, r in ipairs(raios) do
				local comp = 4 + s * 26
				local giro = CFrame.Angles(0, t * 1.5 + i, 0) * r.giro
				r.p.Size = Vector3.new(0.35 + s * 0.6, 0.35 + s * 0.6, comp)
				r.p.CFrame = CFrame.new(pos) * giro * CFrame.new(0, 0, -comp / 2)
				r.p.Transparency = 0.1 + (1 - s) * 0.5
			end
			if t > 2.0 then
				Animacoes.esquecer(c)
				local f = (t - 2) / 0.4
				c:ScaleTo(math.max(0.02, (c:GetAttribute("EscalaMorte") or c:GetScale()) * (1 - f)))
			else
				c:SetAttribute("EscalaMorte", c:GetScale())
			end
		end
		c:PivotTo(CFrame.new(pos) * cf0.Rotation * desvio)
	end, function()
		local pos = craiz.Parent and craiz.Position or cf0.Position + Vector3.new(0, 7, 0)
		for _, r in ipairs(raios) do
			r.p:Destroy()
		end
		c:Destroy()
		-- explosão final enorme
		Animacoes.clarao(pos, BRANCO, 30, 0.7, 80)
		VFX.estouro("Golpes/GiganticCrush", pos, { escala = 3 })
		Animacoes.clarao(pos, cor, 22, 0.9)
		Animacoes.brilhos(pos, cor, 120, 45)
		Animacoes.brilhos(pos, BRANCO, 60, 30)
		Animacoes.anel(pos, cor, 40, 0.8, 2)
		Animacoes.anel(pos, BRANCO, 28, 0.6, 1)
		task.delay(0.15, function()
			Animacoes.anel(CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, 0), cor, 30, 0.7, 1.5)
		end)
	end)
end

------------------------------------------------------------------------
-- Reação ao golpe
------------------------------------------------------------------------
local function apanhou(m, chefe, forte)
	local raiz = m.PrimaryPart
	if not raiz or not Animacoes.rig(m) then
		return
	end
	local d = longeDoHeroi(raiz)
	local forca = (chefe and 0.35 or 1) * (forte and 1.5 or 1)
	local eixo = Vector3.new(0, 1, 0):Cross(d)
	local inclina = eixo.Magnitude > 0.01 and CFrame.fromAxisAngle(eixo.Unit, math.rad(22 * forca)) or CFrame.identity
	local tranco = CFrame.new(d * 0.9 * forca) * inclina
	local lado = math.random() < 0.5 and -1 or 1
	local cl = clipe({
		{ 0, {} },
		{
			0.05,
			{
				raiz = tranco,
				pescoco = { 28 * forca, 12 * lado, 0 },
				ombroD = { -25 * forca, 0, 35 * forca },
				ombroE = { -25 * forca, 0, -35 * forca },
			},
			"sai",
		},
		{ 0.32, {}, "volta" },
	})
	Animacoes.tocar(m, cl, "apanhou")
	-- impacto pronto (estilo anime) no peito do inimigo
	VFX.estouro(
		"Golpes/BasicHit",
		raiz.Position,
		{ anexo = forte and "AttachmentBig" or "Attachment", escala = chefe and 2 or 1 }
	)
end

------------------------------------------------------------------------
-- Liga cada inimigo que aparece
------------------------------------------------------------------------
local function poseChefe(m, valor)
	local nome = typeof(valor) == "string" and string.match(valor, "^([^#]+)") or nil
	local cl = nome and P[nome]
	if not cl then
		return
	end
	Animacoes.tocar(m, cl, "pose")
	local raiz = m.PrimaryPart
	if not raiz then
		return
	end
	local pos = raiz.Position
	if nome == "rugido" then
		VFX.estouro("Golpes/GiganticCrush", pos, { escala = 2, cor = ROXO })
		for i = 0, 2 do
			task.delay(i * 0.18, function()
				Animacoes.anel(pos - Vector3.new(0, 3, 0), ROXO, 18 + i * 6, 0.6, 1.2)
			end)
		end
		Animacoes.clarao(pos, ROXO, 14, 0.5, 40)
		Animacoes.brilhos(pos, ROXO, 50, 30)
	elseif nome == "repulsao" then
		Animacoes.brilhos(pos, ROXO, 20, 6)
	elseif nome == "repulsaoSolta" then
		VFX.estouro("Golpes/GiganticCrush", pos, { escala = 2.5, cor = ROXO })
		Animacoes.clarao(pos, BRANCO, 10, 0.3, 40)
		Animacoes.anel(CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, 0), ROXO, 16, 0.4, 1)
	elseif nome == "esferas" then
		Animacoes.brilhos(pos + raiz.CFrame.LookVector * 3, ROXO, 12, 10)
	elseif nome == "pregos" then
		Animacoes.relampago(
			pos + Vector3.new(0, 3, 0),
			pos + Vector3.new(0, 30, 0),
			Color3.fromRGB(255, 80, 90),
			0.3,
			0.4
		)
	elseif nome == "pregosSolta" then
		Animacoes.anel(pos - Vector3.new(0, 3, 0), Color3.fromRGB(255, 70, 80), 12, 0.4, 1)
	elseif nome == "sumir" then
		Animacoes.brilhos(pos, Color3.fromRGB(80, 50, 110), 30, 12)
	elseif nome == "surgir" then
		Animacoes.anel(pos - Vector3.new(0, 3, 0), ROXO, 14, 0.5, 1)
		Animacoes.clarao(pos, ROXO, 9, 0.35, 25)
		Animacoes.brilhos(pos, ROXO, 30, 18)
	end
end

local function ligar(m)
	if not m:IsA("Model") or mortos[m] ~= nil then
		return
	end
	mortos[m] = false
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d:SetAttribute("T0", d.Transparency) -- só nesta tela; usado no clone da morte
		end
	end
	local chefe = m:GetAttribute("Chefe") == true
	local vidaAntes = m:GetAttribute("Vida") or 0
	local temRig = m:FindFirstChildWhichIsA("Humanoid", true) ~= nil and Animacoes.rig(m) ~= nil

	m.AttributeChanged:Connect(function(atributo)
		if mortos[m] then
			return
		end
		if atributo == "Vida" then
			local vida = m:GetAttribute("Vida") or 0
			local caiu = vidaAntes - vida
			vidaAntes = vida
			if vida <= 0 then
				mortos[m] = true
				local raiz = m.PrimaryPart
				local cor = raiz and raiz:GetAttribute("CorOriginal") or BRANCO
				if typeof(cor) ~= "Color3" then
					cor = BRANCO
				end
				if m:GetAttribute("Chefe") then
					morteChefe(m, cor)
				else
					morteComum(m, cor)
				end
			elseif caiu > 0 and temRig then
				local max = m:GetAttribute("VidaMax") or 1
				apanhou(m, m:GetAttribute("Chefe") == true, caiu >= max * 0.25)
			end
		elseif not temRig then
			return
		elseif atributo == "Ataque" then
			Animacoes.tocar(m, C.ataque, "ataque", m:GetAttribute("Chefe") and 0.6 or 1)
		elseif atributo == "Correndo" then
			if m:GetAttribute("Correndo") then
				Animacoes.manter(m, "correr", corrida, 10)
			else
				Animacoes.soltar(m, "correr")
			end
		elseif atributo == "Pose" then
			poseChefe(m, m:GetAttribute("Pose"))
		end
	end)

	if not temRig then
		return
	end
	if chefe then
		Animacoes.manter(m, "flutuar", flutuarPen(m), 3)
		poseChefe(m, m:GetAttribute("Pose"))
	elseif m:GetAttribute("Elite") then
		Animacoes.manter(m, "ameaca", ameaca, 3)
		task.delay(0.35, function()
			if m.Parent and not mortos[m] then
				Animacoes.tocar(m, C.rugido, "pose")
				local raiz = m.PrimaryPart
				if raiz then
					Animacoes.anel(raiz.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 80, 60), 9, 0.5, 0.8)
					Animacoes.brilhos(raiz.Position, Color3.fromRGB(255, 90, 60), 18, 14)
				end
			end
		end)
	end
	if m:GetAttribute("Correndo") then
		Animacoes.manter(m, "correr", corrida, 10)
	end
end

pasta.ChildAdded:Connect(function(m)
	-- espera o servidor terminar de montar (atributos e peças)
	task.defer(function()
		task.wait()
		if m.Parent then
			ligar(m)
		end
	end)
end)
for _, m in ipairs(pasta:GetChildren()) do
	ligar(m)
end
