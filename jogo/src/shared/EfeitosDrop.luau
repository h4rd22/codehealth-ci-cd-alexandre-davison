-- EfeitosDrop: o show do item que caiu (só na tela do jogador).
--   1) coluna de luz na cor da raridade + anel no chão (quanto mais raro, mais alta e mais efeitos)
--   2) o item 3D pula do inimigo girando, com raios de luz atrás dele
--   3) ele vira um ícone e voa até o botão da Mochila, que pisca ao receber
-- Lendário+ ganha explosão, flash e tremida; Divino é dourado com sol atrás; Secreto implode em preto e branco.
-- O GameClient chama EfeitosDrop.tocar(pos, item, ri, cor); se der erro, ele usa o efeito antigo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Animacoes = require(Shared:WaitForChild("Animacoes"))
local VFX = require(Shared:WaitForChild("VFX"))
local ItemArte = require(Shared:WaitForChild("ItemArte"))

local EfeitosDrop = {}

local BRANCO = Color3.new(1, 1, 1)
local PRETO = Color3.fromRGB(15, 12, 20)
local DOURADO = Color3.fromRGB(255, 215, 70)

-- Quanto mais raro, mais show (ri: 1 Comum ... 5 Lendário ... 8 Divino, 9 Secreto)
local NIVEL = {
	[1] = { coluna = 9, largura = 0.8, raios = 0, segura = 0.45, brilhos = 8 },
	[2] = { coluna = 12, largura = 1, raios = 0, segura = 0.5, brilhos = 12 },
	[3] = { coluna = 18, largura = 1.4, raios = 4, segura = 0.6, brilhos = 18 },
	[4] = { coluna = 24, largura = 1.8, raios = 6, segura = 0.75, brilhos = 26 },
	[5] = { coluna = 40, largura = 2.6, raios = 8, segura = 1.1, brilhos = 45, explode = true },
	[6] = { coluna = 45, largura = 2.8, raios = 10, segura = 1.2, brilhos = 55, explode = true },
	[7] = { coluna = 50, largura = 3, raios = 10, segura = 1.3, brilhos = 60, explode = true },
	[8] = { coluna = 70, largura = 2.8, raios = 14, segura = 1.6, brilhos = 90, explode = true, sol = true },
	[9] = { coluna = 70, largura = 2.8, raios = 14, segura = 1.6, brilhos = 90, explode = true, secreto = true },
}

local function tw(o, tempo, props, estilo, direcao)
	local t = TweenService:Create(
		o,
		TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad, direcao or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function ponto(pos)
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	return a
end

local function seq(...)
	local v = { ... }
	local pts = {}
	for i = 1, #v, 2 do
		table.insert(pts, NumberSequenceKeypoint.new(v[i], v[i + 1]))
	end
	return NumberSequence.new(pts)
end

local function chao(pos)
	local filtro = RaycastParams.new()
	filtro.FilterType = Enum.RaycastFilterType.Exclude
	local lista = {}
	for _, nome in ipairs({ "Monstros", "FxMagias", "EfeitosAnim" }) do
		local f = workspace:FindFirstChild(nome)
		if f then
			table.insert(lista, f)
		end
	end
	local char = Players.LocalPlayer.Character
	if char then
		table.insert(lista, char)
	end
	filtro.FilterDescendantsInstances = lista
	local r = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), filtro)
	return r and r.Position or pos - Vector3.new(0, 2.5, 0)
end

-- Coluna de luz (Beams verticais que somem para cima)
local function coluna(base, altura, largura, cor, tempo)
	local a0 = ponto(base)
	local a1 = ponto(base + Vector3.new(0, altura, 0))
	local function feixe(w, c, transp)
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Color = ColorSequence.new(c)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Width0 = w
		b.Width1 = w * 0.55
		b.Transparency = seq(0, transp, 0.6, math.min(1, transp + 0.35), 1, 1)
		b.Parent = a0
		return b
	end
	local fora = feixe(largura * 1.7, cor, 0.6)
	local meio = feixe(largura, cor:Lerp(BRANCO, 0.35), 0.15)
	local miolo = feixe(largura * 0.35, BRANCO, 0)
	-- abre de fino para grosso
	local larguras = { { fora, largura * 1.7 }, { meio, largura }, { miolo, largura * 0.35 } }
	Animacoes.durante(tempo, function(a)
		local abre = math.min(1, a * 6)
		local fecha = a > 0.7 and (1 - (a - 0.7) / 0.3) or 1
		for _, par in ipairs(larguras) do
			par[1].Width0 = par[2] * abre * fecha
			par[1].Width1 = par[2] * 0.55 * abre * fecha
		end
	end, function()
		a0:Destroy()
		a1:Destroy()
	end)
	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = 10 + altura * 0.3
	luz.Brightness = 3
	luz.Parent = a0
end

-- Raios de luz girando atrás do item, virados para a câmera
local function raiosDeLuz(alvoFn, n, cor, comprimento, tempo)
	local centro = ponto(alvoFn())
	local pontas, feixes = {}, {}
	for i = 1, n do
		local a = ponto(alvoFn())
		local b = Instance.new("Beam")
		b.Attachment0 = centro
		b.Attachment1 = a
		b.Color = ColorSequence.new(BRANCO, cor)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Width0 = 0.15
		b.Width1 = comprimento * 0.28
		b.Transparency = seq(0, 0.2, 1, 1)
		b.Parent = centro
		pontas[i] = a
		feixes[i] = b
	end
	Animacoes.durante(tempo, function(a)
		local c = alvoFn()
		local cam = workspace.CurrentCamera
		local dir = (c - cam.CFrame.Position).Unit
		-- dois eixos no plano de frente para a câmera
		local lado = dir:Cross(Vector3.yAxis)
		lado = lado.Magnitude > 0.01 and lado.Unit or Vector3.xAxis
		local cima = lado:Cross(dir).Unit
		local abre = math.min(1, a * 5) * (a > 0.8 and (1 - (a - 0.8) / 0.2) or 1)
		centro.WorldPosition = c + dir * 0.5
		for i, p in ipairs(pontas) do
			local ang = i / n * math.pi * 2 + a * tempo * 1.4
			local comp = comprimento * abre * (i % 2 == 0 and 1 or 0.7)
			p.WorldPosition = c + dir * 0.5 + (lado * math.cos(ang) + cima * math.sin(ang)) * comp
		end
	end, function()
		for _, p in ipairs(pontas) do
			p:Destroy()
		end
		centro:Destroy()
	end)
end

-- Monta o item 3D do tamanho certo, sem física
local function item3D(item, ri, cor, tamanho)
	local ok, m = pcall(ItemArte.criar, item.slot, ri, cor, item.conjunto, item.classe)
	if not ok or not m then
		return nil
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	local _, tam = m:GetBoundingBox()
	local maior = math.max(tam.X, tam.Y, tam.Z, 0.1)
	m:ScaleTo(m:GetScale() * tamanho / maior)
	m.Parent = Animacoes.pastaFx()
	return m
end

------------------------------------------------------------------------
-- Ícone voando até a Mochila
------------------------------------------------------------------------
local guiVoo
local function telaVoo()
	if not guiVoo or not guiVoo.Parent then
		guiVoo = Instance.new("ScreenGui")
		guiVoo.Name = "DropVoando"
		guiVoo.IgnoreGuiInset = true
		guiVoo.ResetOnSpawn = false
		guiVoo.DisplayOrder = 6
		guiVoo.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	return guiVoo
end

local function botaoMochila()
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local b = pg and pg:FindFirstChild("Menu_mochila", true)
	if b and b:IsA("GuiObject") and b.Visible and b.AbsoluteSize.X > 0 then
		return b
	end
	return nil
end

local function voarParaMochila(posMundo, item, ri, cor)
	local cam = workspace.CurrentCamera
	local tela, naFrente = cam:WorldToViewportPoint(posMundo)
	if not naFrente then
		return
	end
	local gui = telaVoo()
	local inset = game:GetService("GuiService"):GetGuiInset()
	local inicio = Vector2.new(tela.X, tela.Y)
	local botao = botaoMochila()
	local fim = botao and (botao.AbsolutePosition + botao.AbsoluteSize / 2 + inset) or Vector2.new(inicio.X, -80)
	local tamanho = ri >= 5 and 110 or 80
	local vp = Instance.new("ViewportFrame")
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromOffset(tamanho, tamanho)
	vp.Position = UDim2.fromOffset(inicio.X, inicio.Y)
	vp.Parent = gui
	pcall(ItemArte.mostrar, vp, item.slot, ri, cor, item.conjunto, item.classe)
	local brilho = Instance.new("UIStroke")
	brilho.Color = cor
	brilho.Thickness = 0
	brilho.Parent = vp
	local escala = Instance.new("UIScale")
	escala.Parent = vp
	-- rastro de estrelinhas atrás do ícone
	local tempo = 0.55
	local meio = (inicio + fim) / 2 + Vector2.new(-140, -120)
	Animacoes.durante(tempo, function(a)
		local e = a * a * (3 - 2 * a)
		local p = (1 - e) ^ 2 * inicio + 2 * (1 - e) * e * meio + e ^ 2 * fim
		vp.Position = UDim2.fromOffset(p.X, p.Y)
		vp.Rotation = e * 360
		escala.Scale = 1 - e * 0.65
		if math.random() < 0.5 then
			local s = Instance.new("Frame")
			s.AnchorPoint = Vector2.new(0.5, 0.5)
			s.Size = UDim2.fromOffset(10, 10)
			s.Position = vp.Position
			s.BackgroundColor3 = cor:Lerp(BRANCO, 0.5)
			s.Rotation = 45
			s.BorderSizePixel = 0
			s.Parent = gui
			tw(s, 0.35, { Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1 })
			Debris:AddItem(s, 0.4)
		end
	end, function()
		vp:Destroy()
		-- a mochila "come" o item: anel de luz e o botão pula
		local anel = Instance.new("Frame")
		anel.AnchorPoint = Vector2.new(0.5, 0.5)
		anel.Position = UDim2.fromOffset(fim.X, fim.Y)
		anel.Size = UDim2.fromOffset(40, 40)
		anel.BackgroundTransparency = 1
		anel.Parent = gui
		Instance.new("UICorner", anel).CornerRadius = UDim.new(1, 0)
		local borda = Instance.new("UIStroke")
		borda.Color = cor:Lerp(BRANCO, 0.3)
		borda.Thickness = 6
		borda.Parent = anel
		tw(anel, 0.35, { Size = UDim2.fromOffset(130, 130) })
		tw(borda, 0.35, { Transparency = 1, Thickness = 1 })
		Debris:AddItem(anel, 0.4)
		if botao then
			local e = botao:FindFirstChild("PuloDrop") or Instance.new("UIScale")
			e.Name = "PuloDrop"
			e.Parent = botao
			e.Scale = 1.35
			tw(e, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
end

------------------------------------------------------------------------
-- Efeito completo
------------------------------------------------------------------------
function EfeitosDrop.tocar(pos, item, ri, cor)
	if typeof(pos) ~= "Vector3" or type(item) ~= "table" then
		return false
	end
	ri = math.clamp(ri or 1, 1, 9)
	local n = NIVEL[ri]
	local corLuz = cor
	if n.secreto then
		corLuz = Color3.fromRGB(235, 235, 255)
	end
	local base = chao(pos)
	local total = 0.5 + n.segura

	-- coluna de luz e anel no chão
	coluna(base, n.coluna, n.largura, n.secreto and PRETO or corLuz, total + 0.3)
	Animacoes.anel(base + Vector3.new(0, 0.2, 0), corLuz, 3 + ri * 0.8, 0.5, 0.5 + ri * 0.1)
	local disco = Animacoes.pecaFx(Vector3.new(0.1, 1, 1), corLuz, Enum.PartType.Cylinder)
	disco.CFrame = CFrame.new(base + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disco.Transparency = 0.35
	disco.Parent = Animacoes.pastaFx()
	tw(disco, 0.3, { Size = Vector3.new(0.1, 2 + ri * 0.6, 2 + ri * 0.6) }, Enum.EasingStyle.Back)
	task.delay(total, function()
		tw(disco, 0.3, { Transparency = 1 })
	end)
	Debris:AddItem(disco, total + 0.35)

	-- raridade alta: explosão de luz, flash e tremida
	if n.explode then
		Animacoes.clarao(pos + Vector3.new(0, 1, 0), BRANCO, 6 + ri, 0.35, 30)
		Animacoes.anel(base + Vector3.new(0, 0.4, 0), BRANCO, 10 + ri * 2, 0.6, 1.5)
		task.delay(0.1, function()
			Animacoes.anel(base + Vector3.new(0, 0.6, 0), corLuz, 14 + ri * 2.5, 0.7, 2)
		end)
		VFX.estouro("Golpes/GiganticCrush", pos + Vector3.new(0, 1, 0), { escala = 0.4 + ri * 0.1, cor = corLuz })
		local ok, EM = pcall(require, Shared:FindFirstChild("EfeitosMagia"))
		if ok and EM then
			EM.flash(n.secreto and BRANCO or corLuz:Lerp(BRANCO, 0.5), 0.15 + ri * 0.04, 0.4)
			EM.tremer(0.3 + ri * 0.12, 0.25 + ri * 0.03)
		end
	end
	if n.secreto then
		-- implode em preto e estoura em branco
		local bola = Animacoes.pecaFx(Vector3.one * 9, PRETO, Enum.PartType.Ball)
		bola.Position = pos + Vector3.new(0, 2, 0)
		bola.Transparency = 0.1
		bola.Parent = Animacoes.pastaFx()
		tw(bola, 0.3, { Size = Vector3.one * 0.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Debris:AddItem(bola, 0.32)
		task.delay(0.3, function()
			Animacoes.clarao(pos + Vector3.new(0, 2, 0), BRANCO, 20, 0.5, 50)
			Animacoes.brilhos(pos + Vector3.new(0, 2, 0), BRANCO, 60, 30)
		end)
	end

	-- o item 3D pula girando
	local tamanho = ri >= 5 and 3.2 or 2.4
	local m = item3D(item, ri, cor, tamanho)
	local topo = base + Vector3.new(0, 4.2 + math.min(ri, 6) * 0.15, 0)
	local inicio = pos + Vector3.new(0, 0.5, 0)
	local atual = inicio
	if m then
		local h = Instance.new("Highlight")
		h.FillTransparency = 1
		h.OutlineColor = corLuz
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = m
	end
	local desvio = m and (m:GetPivot():Inverse() * (select(1, m:GetBoundingBox()))) or CFrame.identity
	Animacoes.durante(total, function(a)
		local t = a * total
		if t < 0.45 then
			local s = t / 0.45
			local e = 1 + 2.70158 * (s - 1) ^ 3 + 1.70158 * (s - 1) ^ 2 -- pula e passa um pouquinho
			atual = inicio:Lerp(topo, e) + Vector3.new(0, math.sin(s * math.pi) * 1.5, 0)
		else
			atual = topo + Vector3.new(0, math.sin((t - 0.45) * 4) * 0.25, 0)
		end
		if m then
			local giro = t < 0.45 and (t * 25) or (0.45 * 25 + (t - 0.45) * 2.5)
			m:PivotTo(CFrame.new(atual) * CFrame.Angles(0, giro, math.rad(12)) * desvio:Inverse())
		end
	end, function()
		if m then
			m:Destroy()
		end
		Animacoes.brilhos(atual, corLuz, 10, 10)
		voarParaMochila(atual, item, ri, cor)
	end)
	if n.raios > 0 then
		raiosDeLuz(function()
			return atual
		end, n.raios, n.secreto and BRANCO or corLuz, 2.5 + ri * 0.5, total)
	end
	if n.sol then
		-- sol dourado atrás do item (Divino)
		local sol = Animacoes.pecaFx(Vector3.one, DOURADO, Enum.PartType.Ball)
		sol.Material = Enum.Material.ForceField
		sol.Transparency = 0.6
		sol.Parent = Animacoes.pastaFx()
		Animacoes.durante(total, function(a)
			-- fica atrás do item (do ponto de vista da câmera) para não cobri-lo
			local cam = workspace.CurrentCamera
			sol.Position = atual + (atual - cam.CFrame.Position).Unit * 2.5
			sol.Size = Vector3.one * (2 + math.min(1, a * 4) * 2.5 + math.sin(a * 20) * 0.2)
		end, function()
			sol:Destroy()
		end)
	end
	-- estrelinhas subindo pela coluna
	local a = ponto(base + Vector3.new(0, 0.5, 0))
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(BRANCO, corLuz)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = seq(0, 0.5 + ri * 0.05, 1, 0)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(6, 6 + ri * 2)
	e.SpreadAngle = Vector2.new(12, 12)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = n.brilhos
	e.Parent = a
	Animacoes.brilhos(pos + Vector3.new(0, 1, 0), corLuz, n.brilhos, 12 + ri * 2)
	task.delay(total, function()
		e.Enabled = false
	end)
	Debris:AddItem(a, total + 1.3)
	return true
end

return EfeitosDrop
