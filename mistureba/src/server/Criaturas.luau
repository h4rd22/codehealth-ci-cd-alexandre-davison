--!strict
-- Monta os modelos 3D das Misturebas e dos ovos com peças simples.
-- Quando houver arte própria (modelos feitos no Studio), troque só este arquivo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)

local Criaturas = {}

local FORMAS = {
	bloco = Enum.PartType.Block,
	cilindro = Enum.PartType.Cylinder,
}

-- Bola de verdade no Roblox é sempre redonda; com malha de esfera ela vira oval.
local function oval(part: BasePart)
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = part
end

local function peca(def: Config.Peca, escala: number): BasePart
	local p: BasePart
	if def.forma == "cunha" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		part.Shape = FORMAS[def.forma] or Enum.PartType.Block
		if def.forma == "bola" then
			oval(part)
		end
		p = part
	end
	p.Size = def.tamanho * escala
	p.Color = def.cor
	p.Material = if def.material then (Enum.Material :: any)[def.material] else Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	return p
end

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
end

local function olho(corpo: BasePart, lado: number, escala: number)
	local branco = Instance.new("Part")
	branco.Shape = Enum.PartType.Ball
	branco.Size = Vector3.new(0.7, 0.7, 0.7) * escala
	branco.Color = Color3.new(1, 1, 1)
	branco.Material = Enum.Material.SmoothPlastic
	branco.CanCollide = false
	branco.CanTouch = false
	branco.Massless = true
	local frente = corpo.Size.Z / 2
	branco.CFrame = corpo.CFrame * CFrame.new(0.45 * lado * escala, corpo.Size.Y * 0.2, -frente + 0.1)
	branco.Parent = corpo.Parent
	soldar(corpo, branco)

	local pupila = branco:Clone()
	pupila.Size = branco.Size * 0.5
	pupila.Color = Color3.new(0.05, 0.05, 0.08)
	pupila.CFrame = branco.CFrame * CFrame.new(0, 0, -branco.Size.Z * 0.35)
	pupila.Parent = corpo.Parent
	soldar(corpo, pupila)
end

local function placa(alvo: BasePart, linhas: { { texto: string, cor: Color3, tamanho: number } }, altura: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Placa"
	gui.Size = UDim2.fromScale(8, 1.1 * #linhas) -- em studs: diminui com a distância
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local lista = Instance.new("UIListLayout")
	lista.Parent = gui
	for i, linha in linhas do
		local rotulo = Instance.new("TextLabel")
		rotulo.LayoutOrder = i
		rotulo.BackgroundTransparency = 1
		rotulo.Font = Enum.Font.FredokaOne
		rotulo.TextScaled = true
		rotulo.Text = linha.texto
		rotulo.TextColor3 = linha.cor
		rotulo.TextStrokeTransparency = 0.2
		rotulo.Size = UDim2.fromScale(1, linha.tamanho / 26 / #linhas)
		rotulo.Parent = gui
	end
	gui.Parent = alvo
end

-- Cria o modelo de uma Mistureba. O corpo é a PrimaryPart e fica ancorado.
function Criaturas.modelo(id: string): Model
	local def = Config.PorId[id]
	assert(def, "Mistureba desconhecida: " .. tostring(id))
	local raridade = Config.Raridades[def.raridade]
	local escala = raridade.tamanho

	local modelo = Instance.new("Model")
	modelo.Name = def.nome
	modelo:SetAttribute("Criatura", id)

	local corpo = peca(def.corpo, escala)
	corpo.Name = "Corpo"
	corpo.Anchored = true
	corpo.CFrame = CFrame.new()
	corpo.Parent = modelo
	modelo.PrimaryPart = corpo

	for i, extra in def.extras do
		local p = peca(extra, escala)
		p.Name = "Extra" .. i
		p.CFrame = corpo.CFrame * CFrame.new((extra.posicao or Vector3.zero) * escala)
		p.Parent = modelo
		soldar(corpo, p)
	end

	olho(corpo, 1, escala)
	olho(corpo, -1, escala)

	if def.raridade ~= "comum" then
		local brilho = Instance.new("PointLight")
		brilho.Color = raridade.cor
		brilho.Range = 6 + escala * 4
		brilho.Brightness = 1.5
		brilho.Parent = corpo
	end
	if def.raridade == "mitico" or def.raridade == "secreto" or def.raridade == "lendario" then
		local brilhinhos = Instance.new("ParticleEmitter")
		brilhinhos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brilhinhos.Color = ColorSequence.new(raridade.cor)
		brilhinhos.Rate = 6
		brilhinhos.Lifetime = NumberRange.new(1, 1.6)
		brilhinhos.Speed = NumberRange.new(1, 2)
		brilhinhos.Size = NumberSequence.new(0.4)
		brilhinhos.Parent = corpo
	end

	local alturaPlaca = corpo.Size.Y / 2 + 2.5 * escala
	placa(corpo, {
		{ texto = def.nome, cor = Color3.new(1, 1, 1), tamanho = 26 },
		{ texto = raridade.nome, cor = raridade.cor, tamanho = 22 },
		{ texto = "+" .. Util.numero(def.renda) .. "/s", cor = Color3.fromRGB(120, 255, 120), tamanho = 22 },
	}, alturaPlaca)

	return modelo
end

-- Cria um ovo da raridade dada. Ovos lendários para cima são dourados.
function Criaturas.ovo(raridade: string): BasePart
	local info = Config.Raridades[raridade]
	local ovo = Instance.new("Part")
	ovo.Name = "Ovo"
	oval(ovo)
	ovo.Size = Vector3.new(2.2, 2.8, 2.2) * (0.85 + info.tamanho * 0.25)
	ovo.Color = info.cor
	ovo.Material = Enum.Material.Glass
	ovo.Transparency = 0.15
	ovo.Reflectance = 0.2
	ovo.CanCollide = true
	ovo:SetAttribute("Raridade", raridade)

	local luz = Instance.new("PointLight")
	luz.Color = info.cor
	luz.Range = 8
	luz.Brightness = 2
	luz.Parent = ovo

	placa(ovo, { { texto = "Ovo " .. info.nome, cor = info.cor, tamanho = 24 } }, 2.6)
	return ovo
end

return Criaturas
