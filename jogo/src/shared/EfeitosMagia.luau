-- EfeitosMagia: o visual das magias da Maga (gelo, raio e fogo), estilo anime e cheio de brilho.
-- Quem lança é o servidor (Habilidades do Jorge). Ele manda os dados pelo evento "magia" e o
-- Habilidades.client chama EfeitosMagia.tocar(id, dados) aqui. Roda só na tela do jogador.
--
--   Gelo:  lança de cristal com rastro de neve, explosão de cristais, nevasca com vórtice
--   Raio:  correntes elétricas saltando, raios do céu com estalos no chão, tempestade escura
--   Fogo:  bola de fogo com fumaça, onda de chamas, meteoro gigante com cratera
-- Tudo com partículas, trilhas, Beams, tremida de câmera e flash de tela.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local Animacoes = require(script.Parent:WaitForChild("Animacoes"))

local EfeitosMagia = {}

local pecaFx = Animacoes.pecaFx
local BRANCO = Color3.new(1, 1, 1)

local GELO = Color3.fromRGB(120, 215, 255)
local GELO_CLARO = Color3.fromRGB(215, 248, 255)
local GELO_FUNDO = Color3.fromRGB(40, 120, 230)
local RAIO = Color3.fromRGB(255, 232, 80)
local RAIO_CLARO = Color3.fromRGB(255, 255, 215)
local RAIO_AZUL = Color3.fromRGB(150, 210, 255)
local FOGO = Color3.fromRGB(255, 120, 40)
local FOGO_CLARO = Color3.fromRGB(255, 225, 110)
local FOGO_FUNDO = Color3.fromRGB(200, 40, 10)
local FUMACA = Color3.fromRGB(55, 45, 45)

-- Texturas que já vêm com o Roblox (não precisam ser enviadas)
local TEX = {
	faisca = "rbxasset://textures/particles/sparkles_main.dds",
	fogo = "rbxasset://textures/particles/fire_main.dds",
	fumaca = "rbxasset://textures/particles/smoke_main.dds",
}

------------------------------------------------------------------------
-- Ajudantes
------------------------------------------------------------------------
local function tw(o, tempo, props, estilo, direcao)
	local t = TweenService:Create(
		o,
		TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad, direcao or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function pasta()
	return Animacoes.pastaFx()
end

local function peca(tam, cor, forma, material)
	local p = pecaFx(tam, cor, forma)
	if material then
		p.Material = material
	end
	p.Parent = pasta()
	return p
end

local function luz(parte, cor, alcance, brilho)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance
	l.Brightness = brilho or 3
	l.Parent = parte
	return l
end

local function seq(...)
	local v = { ... }
	local pts = {}
	for i = 1, #v, 2 do
		table.insert(pts, NumberSequenceKeypoint.new(v[i], v[i + 1]))
	end
	return NumberSequence.new(pts)
end

local function emissor(pai, props)
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = pai
	return e
end

-- Um ponto solto no mundo para pendurar partículas e Beams
local function ponto(pos)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	return a
end

-- Jorrada de partículas num lugar
local function jorrar(pos, n, props, vida)
	local a = ponto(pos)
	local e = emissor(a, props)
	e.Enabled = false
	e:Emit(n)
	Debris:AddItem(a, vida or 2)
	return e
end

local function rastro(parte, cor, largura, vida, cor2)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, largura / 2, 0)
	a0.Parent = parte
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -largura / 2, 0)
	a1.Parent = parte
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(cor2 or cor:Lerp(BRANCO, 0.6), cor)
	t.Transparency = seq(0, 0.05, 1, 1)
	t.WidthScale = seq(0, 1, 1, 0.1)
	t.LightEmission = 1
	t.Lifetime = vida
	t.FaceCamera = true
	t.Parent = parte
	return t
end

local function chao(pos)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	local lista = { pasta() }
	for _, nome in ipairs({ "Monstros", "FxMagias", "EfeitosAnim" }) do
		local f = workspace:FindFirstChild(nome)
		if f then
			table.insert(lista, f)
		end
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	if char then
		table.insert(lista, char)
	end
	filtro.FilterDescendantsInstances = lista
	local r = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), filtro)
	return r and r.Position or pos - Vector3.new(0, 2.5, 0)
end

-- Disco plano no chão (geada, queimado, mira...)
local function disco(base, raio, cor, transp, material)
	local p = peca(Vector3.new(0.12, raio * 2, raio * 2), cor, Enum.PartType.Cylinder, material)
	p.CFrame = CFrame.new(base + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Transparency = transp or 0.4
	return p
end

------------------------------------------------------------------------
-- Tela: flash, tremida e cor do céu
------------------------------------------------------------------------
local telaFlash
local function flash(cor, forca, tempo)
	local player = Players.LocalPlayer
	if not player then
		return
	end
	if not telaFlash or not telaFlash.Parent then
		local gui = Instance.new("ScreenGui")
		gui.Name = "FlashMagia"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 3
		gui.Parent = player:WaitForChild("PlayerGui")
		telaFlash = Instance.new("Frame")
		telaFlash.Size = UDim2.fromScale(1, 1)
		telaFlash.BorderSizePixel = 0
		telaFlash.BackgroundTransparency = 1
		telaFlash.Parent = gui
	end
	telaFlash.BackgroundColor3 = cor
	telaFlash.BackgroundTransparency = 1 - forca
	tw(telaFlash, tempo or 0.35, { BackgroundTransparency = 1 })
end

local tremorForca, tremorFim, tremorDur = 0, 0, 1
local tremorLigado = false
local function tremer(forca, duracao)
	local agora = os.clock()
	local restante = math.max(0, tremorFim - agora)
	if forca * duracao >= tremorForca * restante then
		tremorForca, tremorFim, tremorDur = forca, agora + duracao, duracao
	end
	if tremorLigado then
		return
	end
	tremorLigado = true
	-- roda depois da câmera do Roblox: só soma um sacolejo por cima, sem brigar com ela
	RunService:BindToRenderStep("TremerMagia", Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock()
		if t >= tremorFim then
			return
		end
		local f = tremorForca * ((tremorFim - t) / tremorDur)
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame
			* CFrame.new((math.random() - 0.5) * f, (math.random() - 0.5) * f, 0)
			* CFrame.Angles(0, 0, (math.random() - 0.5) * f * 0.03)
	end)
end

-- Muda a cor do mundo por um tempo (céu escuro da tempestade, frio da nevasca...)
local function corDoMundo(props, duracao, entrada)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CorMagia"
	cc.Parent = Lighting
	tw(cc, entrada or 0.35, props)
	task.delay(duracao, function()
		tw(cc, 0.6, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = BRANCO })
		Debris:AddItem(cc, 0.7)
	end)
	return cc
end

------------------------------------------------------------------------
-- Peças de efeito reaproveitadas
------------------------------------------------------------------------

-- Pedacinhos voando com gravidade e girando
local function estilhacos(pos, cor, qtd, forca, material, tamanho)
	for _ = 1, qtd do
		local s = peca(Vector3.one * (tamanho or 0.4) * (0.6 + math.random() * 0.8), cor, nil, material)
		local vel = Vector3.new(math.random() - 0.5, 0.6 + math.random() * 0.8, math.random() - 0.5).Unit
			* forca
			* (0.6 + math.random() * 0.6)
		local giro = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 20
		local vida = 0.6 + math.random() * 0.3
		local cf0 = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		Animacoes.durante(vida, function(a)
			local t = a * vida
			local p = pos + vel * t + Vector3.new(0, -40 * t * t, 0)
			s.CFrame = CFrame.new(p) * cf0.Rotation * CFrame.Angles(giro.X * t, giro.Y * t, giro.Z * t)
			s.Transparency = a > 0.6 and (a - 0.6) / 0.4 or 0
		end, function()
			s:Destroy()
		end)
	end
end

-- Cristal de gelo brotando do chão. base = CFrame no chão, apontando para cima (UpVector)
local function cristal(base, altura, largura, atraso, vida)
	local corpo = peca(Vector3.new(largura, 0.1, largura), GELO_CLARO, nil, Enum.Material.Glass)
	corpo.Transparency = 0.25
	local miolo = peca(Vector3.new(largura * 0.45, 0.1, largura * 0.45), GELO)
	miolo.Transparency = 0.2
	local ponta = peca(Vector3.new(largura * 0.7, 0.1, largura * 0.7), BRANCO)
	ponta.Transparency = 1
	local giro = CFrame.Angles(0, math.rad(45), 0)
	local partes = { corpo, miolo, ponta }
	for _, p in ipairs(partes) do
		p.CFrame = base * giro
	end
	task.delay(atraso or 0, function()
		Animacoes.durante(0.16, function(a)
			local e = 1 + 2.70158 * (a - 1) ^ 3 + 1.70158 * (a - 1) ^ 2 -- mola
			local h = math.max(0.1, altura * e)
			corpo.Size = Vector3.new(largura, h, largura)
			corpo.CFrame = base * CFrame.new(0, h / 2, 0) * giro
			miolo.Size = Vector3.new(largura * 0.45, h * 0.9, largura * 0.45)
			miolo.CFrame = corpo.CFrame
			ponta.Size = Vector3.new(largura * 0.7, largura * 0.7, largura * 0.7)
			ponta.CFrame = base * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0)
			ponta.Transparency = 0.1
		end)
		jorrar(base.Position, 4, {
			Texture = TEX.faisca,
			Color = ColorSequence.new(BRANCO, GELO),
			LightEmission = 1,
			Size = seq(0, 0.8, 1, 0),
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(4, 9),
			SpreadAngle = Vector2.new(60, 60),
		}, 1)
	end)
	task.delay((atraso or 0) + (vida or 1.2), function()
		-- quebra em cacos
		if corpo.Parent then
			estilhacos(corpo.Position, GELO_CLARO, 4, 14, Enum.Material.Glass, largura * 0.4)
		end
		for _, p in ipairs(partes) do
			tw(p, 0.15, { Transparency = 1 })
			Debris:AddItem(p, 0.2)
		end
	end)
	return corpo
end

-- Faísca elétrica com Beam torto que fica tremendo
local function arcoEletrico(de, ate, cor, largura, tempo)
	local a0, a1 = ponto(de), ponto(ate)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = ColorSequence.new(BRANCO, cor)
	b.LightEmission = 1
	b.LightInfluence = 0
	b.FaceCamera = true
	b.Segments = 24
	b.Width0 = largura
	b.Width1 = largura * 0.6
	b.Transparency = seq(0, 0, 0.5, 0.05, 1, 0.2)
	b.Parent = a0
	local dist = (ate - de).Magnitude
	local proxima = 0
	Animacoes.durante(tempo, function(a)
		local t = a * tempo
		if t >= proxima then
			proxima = t + 0.04
			b.CurveSize0 = (math.random() - 0.5) * dist * 0.9
			b.CurveSize1 = (math.random() - 0.5) * dist * 0.9
		end
		b.Transparency = seq(0, a, 0.5, math.min(1, a + 0.05), 1, math.min(1, a + 0.2))
	end, function()
		a0:Destroy()
		a1:Destroy()
	end)
end

local function faiscasEletricas(pos, n, forca)
	jorrar(pos, n, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(BRANCO, RAIO),
		LightEmission = 1,
		Size = seq(0, 1, 1, 0),
		Lifetime = NumberRange.new(0.2, 0.45),
		Speed = NumberRange.new(forca * 0.5, forca),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 6,
	}, 1)
end

-- Raio caindo do céu num ponto
local function raioDoCeu(pos, grosso)
	local base = chao(pos)
	local topo = base + Vector3.new(math.random(-6, 6), 55, math.random(-6, 6))
	local e = grosso and 1 or 0.6
	Animacoes.relampago(topo, base, RAIO, 0.28, 1.1 * e)
	Animacoes.relampago(topo, base, BRANCO, 0.18, 0.45 * e)
	arcoEletrico(topo, base, RAIO, 1.6 * e, 0.25)
	-- galhos do raio
	for _ = 1, grosso and 3 or 1 do
		local meio = topo:Lerp(base, 0.3 + math.random() * 0.4)
		local fim = meio + Vector3.new(math.random(-8, 8), -math.random(4, 10), math.random(-8, 8))
		Animacoes.relampago(meio, fim, RAIO, 0.2, 0.35 * e)
	end
	Animacoes.clarao(base + Vector3.new(0, 1, 0), BRANCO, 8 * e, 0.3, 30)
	Animacoes.anel(base + Vector3.new(0, 0.2, 0), RAIO, 7 * e, 0.4, 0.8)
	faiscasEletricas(base + Vector3.new(0, 0.5, 0), grosso and 30 or 14, 26)
	-- estalos correndo pelo chão
	for i = 1, grosso and 5 or 3 do
		local ang = (i / (grosso and 5 or 3)) * math.pi * 2 + math.random()
		local fim = base + Vector3.new(math.cos(ang), 0, math.sin(ang)) * (4 + math.random() * 3) * e
		task.delay(0.03 * i, function()
			Animacoes.relampago(base + Vector3.new(0, 0.3, 0), fim + Vector3.new(0, 0.3, 0), RAIO_AZUL, 0.2, 0.18)
		end)
	end
	local queimado = disco(base, 2.6 * e, Color3.fromRGB(30, 25, 35), 0.35, Enum.Material.SmoothPlastic)
	tw(queimado, 1.6, { Transparency = 1 }, Enum.EasingStyle.Linear)
	Debris:AddItem(queimado, 1.7)
end

-- Explosão de fogo (bola de fogo, meteoro, morte em chamas)
local function explosaoFogo(pos, raio, forte)
	local base = chao(pos)
	local centro = base + Vector3.new(0, raio * 0.35, 0)
	Animacoes.clarao(centro, FOGO_CLARO, raio * 1.2, 0.22, raio * 3)
	local bola = peca(Vector3.one * 2, FOGO, Enum.PartType.Ball)
	bola.Position = centro
	bola.Transparency = 0.05
	tw(bola, forte and 0.5 or 0.35, { Size = Vector3.one * raio * 2.1, Transparency = 1 })
	Debris:AddItem(bola, 0.55)
	local casca = peca(Vector3.one * 2, FOGO_FUNDO, Enum.PartType.Ball, Enum.Material.ForceField)
	casca.Position = centro
	tw(casca, forte and 0.6 or 0.4, { Size = Vector3.one * raio * 2.6, Transparency = 1 })
	Debris:AddItem(casca, 0.65)
	Animacoes.anel(base + Vector3.new(0, 0.3, 0), FOGO, raio * 1.4, 0.45, forte and 2 or 1)
	jorrar(centro, forte and 45 or 22, {
		Texture = TEX.fogo,
		Color = ColorSequence.new(FOGO_CLARO, FOGO_FUNDO),
		LightEmission = 1,
		Size = seq(0, raio * 0.5, 1, raio * 0.9),
		Transparency = seq(0, 0, 0.7, 0.4, 1, 1),
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(raio * 2, raio * 4.5),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 5,
		RotSpeed = NumberRange.new(-180, 180),
		Rotation = NumberRange.new(0, 360),
	}, 1.5)
	jorrar(centro, forte and 40 or 16, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(FOGO_CLARO, FOGO),
		LightEmission = 1,
		Size = seq(0, 0.5, 1, 0),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(raio * 3, raio * 6),
		SpreadAngle = Vector2.new(70, 70),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -30, 0),
	}, 2)
	jorrar(centro + Vector3.new(0, 1, 0), forte and 14 or 6, {
		Texture = TEX.fumaca,
		Color = ColorSequence.new(FUMACA),
		LightEmission = 0,
		Size = seq(0, raio * 0.6, 1, raio * 1.4),
		Transparency = seq(0, 0.3, 1, 1),
		Lifetime = NumberRange.new(0.9, 1.5),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(50, 50),
		EmissionDirection = Enum.NormalId.Top,
		RotSpeed = NumberRange.new(-40, 40),
	}, 2.5)
	local queimado = disco(base, raio * 0.8, Color3.fromRGB(35, 22, 18), 0.25, Enum.Material.SmoothPlastic)
	local brasa = disco(base + Vector3.new(0, 0.03, 0), raio * 0.5, FOGO, 0.3)
	tw(brasa, 1.2, { Transparency = 1 }, Enum.EasingStyle.Linear)
	tw(queimado, 2.2, { Transparency = 1 }, Enum.EasingStyle.Linear)
	Debris:AddItem(brasa, 1.3)
	Debris:AddItem(queimado, 2.3)
end

------------------------------------------------------------------------
-- Magias
------------------------------------------------------------------------
local E = {}

-- GELO ----------------------------------------------------------------
function E.lancaGelo(d)
	local de = d.de + Vector3.new(0, 1.2, 0)
	local para = d.para + Vector3.new(0, 1.2, 0)
	local dir = para - de
	local dist = dir.Magnitude
	if dist < 0.5 then
		return
	end
	local u = dir.Unit
	-- anel de gelo na saída
	Animacoes.anel(CFrame.lookAt(de, para) * CFrame.Angles(-math.pi / 2, 0, 0), GELO, 3, 0.3, 0.6)
	local corpo = peca(Vector3.new(0.85, 0.85, 4.6), GELO_CLARO, nil, Enum.Material.Glass)
	corpo.Transparency = 0.15
	local nucleo = peca(Vector3.new(0.35, 0.35, 5.4), BRANCO)
	local ponta = peca(Vector3.new(0.6, 0.6, 0.6), BRANCO)
	luz(corpo, GELO, 14, 5)
	rastro(corpo, GELO, 1.6, 0.3)
	local neve = emissor(corpo, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(BRANCO, GELO),
		LightEmission = 1,
		Size = seq(0, 0.6, 1, 0),
		Lifetime = NumberRange.new(0.3, 0.6),
		Rate = 90,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
	})
	local tempo = math.max(0.08, dist / 70)
	Animacoes.durante(tempo, function(a)
		local p = de:Lerp(para, a)
		local cf = CFrame.lookAt(p, p + u) * CFrame.Angles(0, 0, a * 12)
		corpo.CFrame = cf
		nucleo.CFrame = cf
		ponta.CFrame = cf * CFrame.new(0, 0, -2.6) * CFrame.Angles(0, 0, math.rad(45))
	end, function()
		neve.Enabled = false
		corpo:Destroy()
		nucleo:Destroy()
		ponta:Destroy()
		-- impacto: cristais espetando para fora
		local base = chao(para)
		Animacoes.clarao(para, GELO_CLARO, 5, 0.25, 16)
		Animacoes.anel(base + Vector3.new(0, 0.2, 0), GELO, 5, 0.35, 0.7)
		for i = 1, 5 do
			local ang = i / 5 * math.pi * 2 + math.random()
			local fora = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local cf = CFrame.lookAt(base, base + fora) * CFrame.Angles(math.rad(-55), 0, 0)
			cristal(cf, 1.6 + math.random() * 1.4, 0.55, 0, 0.5)
		end
		estilhacos(para, GELO_CLARO, 8, 16, Enum.Material.Glass, 0.35)
		jorrar(para, 16, {
			Texture = TEX.faisca,
			Color = ColorSequence.new(BRANCO, GELO),
			LightEmission = 1,
			Size = seq(0, 1, 1, 0),
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 6,
		}, 1)
		tremer(0.25, 0.12)
	end)
end

function E.novaGelo(d)
	local base = chao(d.centro)
	local raio = d.raio or 11
	flash(GELO_CLARO, 0.35, 0.35)
	tremer(0.7, 0.3)
	Animacoes.clarao(base + Vector3.new(0, 1.5, 0), BRANCO, 6, 0.25, raio * 2)
	Animacoes.anel(base + Vector3.new(0, 0.3, 0), BRANCO, raio * 1.1, 0.35, 1)
	task.delay(0.08, function()
		Animacoes.anel(base + Vector3.new(0, 0.5, 0), GELO, raio * 1.3, 0.5, 1.6)
	end)
	-- chão congelando
	local geada = disco(base, 1, GELO, 0.35, Enum.Material.Ice)
	tw(geada, 0.35, { Size = Vector3.new(0.12, raio * 2, raio * 2) }, Enum.EasingStyle.Quart)
	task.delay(1.4, function()
		tw(geada, 0.5, { Transparency = 1 })
	end)
	Debris:AddItem(geada, 2)
	-- onda de cristais nascendo do centro para fora
	for anelN = 1, 3 do
		local qtd = 6 + anelN * 4
		local r = raio * (0.3 + anelN * 0.22)
		for i = 1, qtd do
			local ang = i / qtd * math.pi * 2 + anelN * 0.4 + math.random() * 0.2
			local fora = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local pos = base + fora * r
			local cf = CFrame.lookAt(pos, pos + fora) * CFrame.Angles(math.rad(-70 + math.random(-10, 10)), 0, 0)
			cristal(cf, 2 + anelN * 0.9 + math.random() * 1.5, 0.7 + anelN * 0.15, anelN * 0.06, 1.1)
		end
	end
	-- neve explodindo para cima
	jorrar(base + Vector3.new(0, 1, 0), 60, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(BRANCO, GELO),
		LightEmission = 1,
		Size = seq(0, 1.2, 1, 0),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(raio, raio * 2.2),
		SpreadAngle = Vector2.new(80, 80),
		EmissionDirection = Enum.NormalId.Top,
		Drag = 3,
		Acceleration = Vector3.new(0, -8, 0),
	}, 2)
end

function E.nevasca(d)
	local base = chao(d.centro)
	local raio = d.raio or 13
	local duracao = d.duracao or 3
	flash(GELO_CLARO, 0.45, 0.5)
	tremer(0.5, 0.3)
	corDoMundo({ TintColor = Color3.fromRGB(200, 230, 255), Brightness = 0.05, Saturation = -0.25 }, duracao)
	local geada = disco(base, raio, GELO, 0.4, Enum.Material.Ice)
	Animacoes.circuloMagico(CFrame.new(base + Vector3.new(0, 0.15, 0)), GELO, raio * 0.9, duracao + 0.3)
	-- nuvem de neve caindo
	local nuvem = peca(Vector3.new(raio * 2, 1, raio * 2), BRANCO)
	nuvem.Transparency = 1
	nuvem.Position = base + Vector3.new(0, 18, 0)
	local neve = emissor(nuvem, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(BRANCO, GELO_CLARO),
		LightEmission = 0.8,
		Size = seq(0, 0.6, 1, 0.3),
		Lifetime = NumberRange.new(1, 1.4),
		Rate = 260,
		Speed = NumberRange.new(16, 24),
		SpreadAngle = Vector2.new(15, 15),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(10, 0, 4),
	})
	-- vórtice: 3 braços de vento girando com trilha e neve
	local eixo = peca(Vector3.one * 0.2, BRANCO)
	eixo.Transparency = 1
	local bracos = {}
	for i = 1, 3 do
		local b = peca(Vector3.one * 0.6, GELO_CLARO, Enum.PartType.Ball)
		b.Transparency = 0.2
		rastro(b, GELO, 1.8, 0.45, BRANCO)
		emissor(b, {
			Texture = TEX.faisca,
			Color = ColorSequence.new(BRANCO, GELO),
			LightEmission = 1,
			Size = seq(0, 0.8, 1, 0),
			Lifetime = NumberRange.new(0.4, 0.8),
			Rate = 40,
			Speed = NumberRange.new(0.5, 2),
			SpreadAngle = Vector2.new(180, 180),
		})
		bracos[i] = b
	end
	luz(eixo, GELO, raio * 2.5, 3)
	local proximoCaco = 0
	Animacoes.durante(duracao, function(a)
		local t = a * duracao
		eixo.Position = base + Vector3.new(0, 3, 0)
		for i, b in ipairs(bracos) do
			local ang = t * 5 + i * (math.pi * 2 / 3)
			local r = raio * (0.35 + 0.5 * ((t * 0.7 + i * 0.33) % 1))
			b.Position = base + Vector3.new(math.cos(ang) * r, 1 + ((t * 2 + i) % 3), math.sin(ang) * r)
		end
		-- cacos de gelo caindo do céu
		if t >= proximoCaco then
			proximoCaco = t + 0.12
			local ang = math.random() * math.pi * 2
			local r = math.sqrt(math.random()) * raio
			local alvo = base + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
			local caco = peca(Vector3.new(0.5, 2.4, 0.5), GELO_CLARO, nil, Enum.Material.Glass)
			caco.Transparency = 0.1
			local inicio = alvo + Vector3.new(-6, 22, -3)
			Animacoes.durante(0.3, function(q)
				caco.CFrame = CFrame.lookAt(inicio:Lerp(alvo, q * q), alvo) * CFrame.Angles(math.rad(90), 0, 0)
			end, function()
				caco:Destroy()
				estilhacos(alvo + Vector3.new(0, 0.3, 0), GELO_CLARO, 3, 10, Enum.Material.Glass, 0.3)
				Animacoes.anel(alvo + Vector3.new(0, 0.2, 0), GELO, 2.5, 0.25, 0.4)
			end)
		end
	end, function()
		neve.Enabled = false
		Debris:AddItem(nuvem, 1.5)
		eixo:Destroy()
		for _, b in ipairs(bracos) do
			b:Destroy()
		end
		-- final: tudo congela e estoura
		flash(BRANCO, 0.5, 0.45)
		tremer(1.1, 0.4)
		Animacoes.clarao(base + Vector3.new(0, 2, 0), GELO_CLARO, raio * 1.4, 0.4, raio * 3)
		Animacoes.anel(base + Vector3.new(0, 0.4, 0), BRANCO, raio * 1.5, 0.5, 2)
		for i = 1, 16 do
			local ang = i / 16 * math.pi * 2
			local r = raio * (0.4 + math.random() * 0.55)
			local pos = base + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
			local fora = (pos - base).Unit
			cristal(
				CFrame.lookAt(pos, pos + fora) * CFrame.Angles(math.rad(-75), 0, 0),
				3 + math.random() * 3,
				1,
				math.random() * 0.1,
				0.6
			)
		end
		tw(geada, 0.8, { Transparency = 1 })
		Debris:AddItem(geada, 0.9)
	end)
end

-- RAIO ----------------------------------------------------------------
function E.correnteRaio(d)
	local anterior = d.de + Vector3.new(0, 1.5, 0)
	flash(RAIO_CLARO, 0.2, 0.25)
	tremer(0.3, 0.15)
	for i, p in ipairs(d.pontos or {}) do
		local a = anterior
		task.delay((i - 1) * 0.07, function()
			arcoEletrico(a, p, RAIO, 0.9, 0.28)
			arcoEletrico(a, p, RAIO_AZUL, 0.4, 0.2)
			Animacoes.relampago(a, p, BRANCO, 0.16, 0.22)
			Animacoes.clarao(p, BRANCO, 4, 0.2, 14)
			Animacoes.anel(CFrame.lookAt(p, a) * CFrame.Angles(-math.pi / 2, 0, 0), RAIO, 3, 0.25, 0.5)
			faiscasEletricas(p, 16, 22)
		end)
		anterior = p
	end
end

function E.furiaTrovao(d)
	for i, p in ipairs(d.pontos or {}) do
		local base = chao(p)
		Animacoes.circuloMagico(CFrame.new(base + Vector3.new(0, 0.1, 0)), RAIO, 2.6, 0.45)
		task.delay(0.2 + (i - 1) * 0.04, function()
			raioDoCeu(p, true)
		end)
	end
	task.delay(0.2, function()
		flash(BRANCO, 0.45, 0.3)
		tremer(0.8, 0.25)
	end)
end

function E.tempestade(d)
	local duracao = d.duracao or 4
	local player = Players.LocalPlayer
	local char = player and player.Character
	local raiz = char and char:FindFirstChild("HumanoidRootPart")
	corDoMundo(
		{ Brightness = -0.15, Contrast = 0.2, Saturation = -0.3, TintColor = Color3.fromRGB(185, 190, 255) },
		duracao
	)
	flash(BRANCO, 0.4, 0.35)
	if not raiz then
		return
	end
	-- nuvem escura em cima, com relâmpagos dentro
	local centro = raiz.Position + Vector3.new(0, 26, 0)
	local nuvem = peca(Vector3.new(30, 2, 30), FUMACA)
	nuvem.Transparency = 1
	nuvem.Position = centro
	local fumaca = emissor(nuvem, {
		Texture = TEX.fumaca,
		Color = ColorSequence.new(Color3.fromRGB(40, 38, 60), Color3.fromRGB(20, 20, 30)),
		LightEmission = 0,
		Size = seq(0, 10, 1, 16),
		Transparency = seq(0, 1, 0.2, 0.3, 0.8, 0.4, 1, 1),
		Lifetime = NumberRange.new(2, 3),
		Rate = 30,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 20),
		RotSpeed = NumberRange.new(-20, 20),
		Rotation = NumberRange.new(0, 360),
	})
	local brilhoNuvem = luz(nuvem, RAIO_AZUL, 60, 0)
	local proximo = 0
	Animacoes.durante(duracao, function(a)
		local t = a * duracao
		if t >= proximo then
			proximo = t + 0.25 + math.random() * 0.35
			local p1 = centro + Vector3.new(math.random(-12, 12), math.random(-1, 1), math.random(-12, 12))
			local p2 = p1 + Vector3.new(math.random(-9, 9), math.random(-2, 1), math.random(-9, 9))
			Animacoes.relampago(p1, p2, RAIO_AZUL, 0.15, 0.35)
			brilhoNuvem.Brightness = 6
			tw(brilhoNuvem, 0.2, { Brightness = 0 })
			if math.random() < 0.4 then
				flash(Color3.fromRGB(220, 225, 255), 0.18, 0.2)
			end
		end
	end, function()
		fumaca.Enabled = false
		Debris:AddItem(nuvem, 3)
	end)
end

function E.tempestadeGolpe(d)
	raioDoCeu(d.pos, false)
	tremer(0.35, 0.1)
end

-- FOGO ----------------------------------------------------------------
local function bolaDeFogo(tamanho)
	local nucleo = peca(Vector3.one * tamanho * 0.55, FOGO_CLARO, Enum.PartType.Ball)
	local casca = peca(Vector3.one * tamanho, FOGO, Enum.PartType.Ball)
	casca.Transparency = 0.35
	luz(nucleo, FOGO, tamanho * 8, 5)
	rastro(casca, FOGO, tamanho * 0.9, 0.35, FOGO_CLARO)
	local chamas = emissor(casca, {
		Texture = TEX.fogo,
		Color = ColorSequence.new(FOGO_CLARO, FOGO_FUNDO),
		LightEmission = 1,
		Size = seq(0, tamanho * 0.9, 1, tamanho * 0.2),
		Transparency = seq(0, 0.1, 1, 1),
		Lifetime = NumberRange.new(0.25, 0.45),
		Rate = 120,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		RotSpeed = NumberRange.new(-200, 200),
		Rotation = NumberRange.new(0, 360),
	})
	local fumaca = emissor(casca, {
		Texture = TEX.fumaca,
		Color = ColorSequence.new(FUMACA),
		Size = seq(0, tamanho * 0.5, 1, tamanho * 1.4),
		Transparency = seq(0, 0.5, 1, 1),
		Lifetime = NumberRange.new(0.5, 0.9),
		Rate = 30,
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
	})
	return nucleo, casca, chamas, fumaca
end

function E.bolaFogo(d)
	local de = d.de + Vector3.new(0, 1.6, 0)
	local para = d.para
	local dist = (para - de).Magnitude
	local tempo = d.tempo or 0.4
	Animacoes.anel(CFrame.lookAt(de, para) * CFrame.Angles(-math.pi / 2, 0, 0), FOGO, 3, 0.3, 0.6)
	local nucleo, casca, chamas, fumaca = bolaDeFogo(2)
	Animacoes.durante(tempo, function(a)
		local p = de:Lerp(para, a) + Vector3.new(0, math.sin(a * math.pi) * dist * 0.15, 0)
		nucleo.Position = p
		casca.CFrame = CFrame.new(p) * CFrame.Angles(a * 9, a * 6, 0)
	end, function()
		chamas.Enabled = false
		fumaca.Enabled = false
		nucleo:Destroy()
		Debris:AddItem(casca, 0.05)
		explosaoFogo(para, d.raio or 5, false)
		flash(FOGO_CLARO, 0.15, 0.25)
		tremer(0.4, 0.15)
	end)
end

function E.anelChamas(d)
	local base = chao(d.centro)
	local raio = d.raio or 12
	flash(FOGO_CLARO, 0.25, 0.3)
	tremer(0.6, 0.25)
	Animacoes.clarao(base + Vector3.new(0, 1.5, 0), FOGO_CLARO, 7, 0.3, raio * 2)
	Animacoes.anel(base + Vector3.new(0, 0.3, 0), FOGO, raio * 1.1, 0.45, 1.4)
	task.delay(0.06, function()
		Animacoes.anel(base + Vector3.new(0, 0.6, 0), FOGO_CLARO, raio * 0.95, 0.4, 0.8)
	end)
	-- chão em brasa
	local brasa = disco(base, 1, FOGO, 0.45)
	tw(brasa, 0.4, { Size = Vector3.new(0.12, raio * 2, raio * 2) }, Enum.EasingStyle.Quart)
	tw(brasa, 1.4, { Transparency = 1 }, Enum.EasingStyle.Linear)
	Debris:AddItem(brasa, 1.5)
	-- labaredas correndo para fora, girando
	local n = 22
	for i = 1, n do
		local ang0 = i / n * math.pi * 2
		local chama = peca(Vector3.new(1.4, 3, 1.4), i % 2 == 0 and FOGO or FOGO_CLARO)
		chama.Transparency = 0.15
		local e = emissor(chama, {
			Texture = TEX.fogo,
			Color = ColorSequence.new(FOGO_CLARO, FOGO_FUNDO),
			LightEmission = 1,
			Size = seq(0, 2.2, 1, 0.4),
			Transparency = seq(0, 0.1, 1, 1),
			Lifetime = NumberRange.new(0.25, 0.5),
			Rate = 45,
			Speed = NumberRange.new(3, 7),
			SpreadAngle = Vector2.new(20, 20),
			EmissionDirection = Enum.NormalId.Top,
		})
		Animacoes.durante(0.5, function(a)
			local ease = 1 - (1 - a) ^ 2
			local ang = ang0 + a * 1.2
			local r = 1.5 + (raio - 1.5) * ease
			local p = base + Vector3.new(math.cos(ang) * r, 1.4, math.sin(ang) * r)
			chama.CFrame = CFrame.new(p) * CFrame.Angles(0, -ang, math.rad(20))
			chama.Size = Vector3.new(1.4 - a, 3 + a * 2, 1.4 - a)
			chama.Transparency = 0.15 + a * 0.85
		end, function()
			e.Enabled = false
			Debris:AddItem(chama, 0.5)
		end)
	end
	jorrar(base + Vector3.new(0, 0.5, 0), 40, {
		Texture = TEX.faisca,
		Color = ColorSequence.new(FOGO_CLARO, FOGO),
		LightEmission = 1,
		Size = seq(0, 0.6, 1, 0),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(10, 22),
		SpreadAngle = Vector2.new(60, 60),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -25, 0),
	}, 2)
end

function E.meteoro(d)
	local base = chao(d.centro)
	local raio = d.raio or 9
	local tempo = d.tempo or 0.9
	corDoMundo({ TintColor = Color3.fromRGB(255, 205, 180), Contrast = 0.15, Brightness = -0.05 }, tempo + 0.8)
	-- mira no chão: círculo vermelho piscando
	Animacoes.circuloMagico(CFrame.new(base + Vector3.new(0, 0.1, 0)), Color3.fromRGB(255, 60, 30), raio, tempo + 0.15)
	local mira = disco(base, raio, Color3.fromRGB(255, 50, 30), 0.65)
	TweenService:Create(
		mira,
		TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.3 }
	):Play()
	Debris:AddItem(mira, tempo)
	-- a pedra em chamas
	local inicio = base + Vector3.new(-30, 70, 24)
	local pedra = peca(Vector3.one * 6.5, Color3.fromRGB(70, 35, 25), Enum.PartType.Ball, Enum.Material.Basalt)
	local nucleo, casca, chamas, fumaca = bolaDeFogo(8)
	casca.Material = Enum.Material.ForceField
	casca.Transparency = 0.1
	local fogoGrande = emissor(pedra, {
		Texture = TEX.fogo,
		Color = ColorSequence.new(FOGO_CLARO, FOGO_FUNDO),
		LightEmission = 1,
		Size = seq(0, 8, 1, 2),
		Transparency = seq(0, 0, 1, 1),
		Lifetime = NumberRange.new(0.4, 0.7),
		Rate = 140,
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(35, 35),
		EmissionDirection = Enum.NormalId.Top,
		RotSpeed = NumberRange.new(-120, 120),
	})
	rastro(pedra, FOGO, 7, 0.7, FOGO_CLARO)
	local rumo = (base - inicio).Unit
	Animacoes.durante(tempo, function(a)
		local p = inicio:Lerp(base + Vector3.new(0, 2.5, 0), a * a)
		-- as chamas apontam para trás (o fogo "escorre" pelo caminho)
		pedra.CFrame = CFrame.lookAt(p, p - rumo) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, a * 6, 0)
		nucleo.Position = p
		casca.CFrame = CFrame.new(p) * CFrame.Angles(a * 7, a * 4, 0)
	end, function()
		chamas.Enabled = false
		fumaca.Enabled = false
		fogoGrande.Enabled = false
		pedra:Destroy()
		nucleo:Destroy()
		Debris:AddItem(casca, 0.05)
		-- IMPACTO
		flash(BRANCO, 0.75, 0.6)
		tremer(2.4, 0.7)
		explosaoFogo(base + Vector3.new(0, 1, 0), raio, true)
		local cupula = peca(Vector3.one * 3, FOGO_CLARO, Enum.PartType.Ball)
		cupula.Position = base
		cupula.Transparency = 0
		tw(cupula, 0.55, { Size = Vector3.one * raio * 3, Transparency = 1 })
		Debris:AddItem(cupula, 0.6)
		Animacoes.anel(base + Vector3.new(0, 0.4, 0), BRANCO, raio * 2.4, 0.6, 2.5)
		task.delay(0.1, function()
			Animacoes.anel(base + Vector3.new(0, 0.6, 0), FOGO, raio * 3, 0.8, 3)
		end)
		-- pedras voando
		estilhacos(base + Vector3.new(0, 1, 0), Color3.fromRGB(80, 45, 30), 12, 34, Enum.Material.Basalt, 1.1)
		estilhacos(base + Vector3.new(0, 1, 0), FOGO_CLARO, 10, 30, nil, 0.5)
		-- cratera em brasa com chamas na borda
		local cratera = disco(base, raio * 0.75, FOGO, 0.15)
		tw(cratera, 2.5, { Transparency = 1, Color = FOGO_FUNDO }, Enum.EasingStyle.Linear)
		Debris:AddItem(cratera, 2.6)
		for i = 1, 8 do
			local ang = i / 8 * math.pi * 2
			local a = ponto(base + Vector3.new(math.cos(ang) * raio * 0.75, 0.3, math.sin(ang) * raio * 0.75))
			local e = emissor(a, {
				Texture = TEX.fogo,
				Color = ColorSequence.new(FOGO_CLARO, FOGO_FUNDO),
				LightEmission = 1,
				Size = seq(0, 2.5, 1, 0.5),
				Transparency = seq(0, 0.2, 1, 1),
				Lifetime = NumberRange.new(0.5, 0.9),
				Rate = 25,
				Speed = NumberRange.new(2, 5),
				SpreadAngle = Vector2.new(15, 15),
				EmissionDirection = Enum.NormalId.Top,
			})
			task.delay(2, function()
				e.Enabled = false
			end)
			Debris:AddItem(a, 3)
		end
		-- coluna de fumaça
		local col = ponto(base + Vector3.new(0, 1, 0))
		local fum = emissor(col, {
			Texture = TEX.fumaca,
			Color = ColorSequence.new(Color3.fromRGB(70, 55, 50), Color3.fromRGB(30, 25, 25)),
			Size = seq(0, 4, 1, 12),
			Transparency = seq(0, 0.3, 1, 1),
			Lifetime = NumberRange.new(1.5, 2.2),
			Rate = 25,
			Speed = NumberRange.new(8, 14),
			SpreadAngle = Vector2.new(15, 15),
			EmissionDirection = Enum.NormalId.Top,
			RotSpeed = NumberRange.new(-30, 30),
		})
		task.delay(1.4, function()
			fum.Enabled = false
		end)
		Debris:AddItem(col, 4)
	end)
end

function E.explosaoMorte(d)
	explosaoFogo(d.centro, (d.raio or 6) * 0.7, false)
end

------------------------------------------------------------------------
-- Entrada única. Retorna true se desenhou o efeito (senão o Habilidades usa o antigo).
------------------------------------------------------------------------
function EfeitosMagia.tocar(id, d)
	local f = E[id]
	if not f or type(d) ~= "table" or not RunService:IsClient() then
		return false
	end
	local ok, erro = pcall(f, d)
	if not ok then
		warn("[EfeitosMagia] " .. tostring(id) .. ": " .. tostring(erro))
	end
	return ok
end

-- Para testes e para outras partes do jogo
EfeitosMagia.tremer = tremer
EfeitosMagia.flash = flash

return EfeitosMagia
