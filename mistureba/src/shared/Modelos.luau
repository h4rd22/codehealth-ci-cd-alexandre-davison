--!strict
-- Monta os modelos 3D das Misturebas e dos ovos com peças simples.
-- Quando houver arte própria (modelos feitos no Studio), troque só este arquivo.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Especiais = require(ReplicatedStorage.Shared.Especiais)
local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Tracos = require(ReplicatedStorage.Shared.Tracos)
local Util = require(ReplicatedStorage.Shared.Util)

local Criaturas = {}

-- Bola de verdade no Roblox é sempre redonda; com malha de esfera ela vira oval.
local function oval(part: BasePart)
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = part
end

local function soldar(a: BasePart, b: BasePart)
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = a
	solda.Part1 = b
	solda.Parent = b
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

-- Pecinha redonda (oval) presa no corpo. pos/tam já em studs (sem escala).
local function oval3(
	pai: Instance,
	corpo: BasePart,
	cor: Color3,
	tam: Vector3,
	pos: Vector3,
	material: Enum.Material?,
	rot: CFrame?
): BasePart
	local p = Instance.new("Part")
	oval(p)
	p.Size = tam
	p.Color = cor
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = true
	p.Massless = true
	p.CastShadow = false
	p.CFrame = corpo.CFrame * CFrame.new(pos) * (rot or CFrame.identity)
	p.Parent = pai
	soldar(corpo, p)
	return p
end

-- Rosto fofo estilo boneco de vinil: olhões escuros e brilhantes, íris colorida
-- embaixo, dois pontos de brilho, bochechas e boquinha aberta.
-- Os nomes Olho/Pupila/BrilhoOlho são usados pela piscadinha no cliente.
local function rosto(modelo: Model, corpo: BasePart, e: number, iris: Color3)
	local z = -corpo.Size.Z / 2
	local escuro = iris:Lerp(Color3.fromRGB(20, 14, 40), 0.78)
	for _, lado in { -1, 1 } do
		local x = 0.64 * lado
		local olho =
			oval3(modelo, corpo, escuro, Vector3.new(0.92, 1.18, 0.45) * e, Vector3.new(x * e, 0.36 * e, z + 0.2 * e))
		olho.Name = "Olho"
		olho.Reflectance = 0.15
		-- íris colorida na metade de baixo do olho (dá profundidade)
		local pupila = oval3(
			modelo,
			corpo,
			iris:Lerp(Color3.new(1, 1, 1), 0.15),
			Vector3.new(0.62, 0.62, 0.3) * e,
			Vector3.new(x * e, 0.2 * e, z + 0.07 * e)
		)
		pupila.Name = "Pupila"
		local brilhoGrande = oval3(
			modelo,
			corpo,
			Color3.new(1, 1, 1),
			Vector3.new(0.34, 0.38, 0.12) * e,
			Vector3.new((x - 0.16) * e, 0.58 * e, z - 0.13 * e),
			Enum.Material.Neon
		)
		brilhoGrande.Name = "BrilhoOlho"
		local brilhoPequeno = oval3(
			modelo,
			corpo,
			Color3.new(1, 1, 1),
			Vector3.new(0.15, 0.15, 0.08) * e,
			Vector3.new((x + 0.2) * e, 0.08 * e, z - 0.1 * e),
			Enum.Material.Neon
		)
		brilhoPequeno.Name = "BrilhoOlho"
		local bochecha = oval3(
			modelo,
			corpo,
			Color3.fromRGB(255, 125, 165),
			Vector3.new(0.6, 0.32, 0.2) * e,
			Vector3.new(1.1 * lado * e, -0.12 * e, z + 0.42 * e)
		)
		bochecha.Name = "Rosto"
		bochecha.Transparency = 0.2
	end
	local boca = oval3(
		modelo,
		corpo,
		Color3.fromRGB(80, 22, 45),
		Vector3.new(0.42, 0.34, 0.2) * e,
		Vector3.new(0, -0.22 * e, z - 0.04 * e)
	)
	boca.Name = "Rosto"
	local lingua = oval3(
		modelo,
		corpo,
		Color3.fromRGB(255, 115, 140),
		Vector3.new(0.26, 0.14, 0.12) * e,
		Vector3.new(0, -0.31 * e, z - 0.1 * e)
	)
	lingua.Name = "Rosto"
end

-- Asa em leque: penas ovais saindo de um ponto nas costas.
local function asa(
	modelo: Model,
	corpo: BasePart,
	e: number,
	lado: number,
	penas: number,
	comprimento: number,
	cor: Color3,
	material: Enum.Material,
	transparencia: number
)
	local raiz = Vector3.new(corpo.Size.X * 0.36 * lado, 0.55 * e, corpo.Size.Z * 0.25)
	local virar = CFrame.Angles(0, math.rad(-35 * lado), 0)
	for k = 1, penas do
		local l = comprimento * (1 - 0.16 * (k - 1)) * e
		local abre = CFrame.Angles(0, 0, math.rad(-lado * (45 + 22 * (k - 1))))
		local pena = oval3(
			modelo,
			corpo,
			cor:Lerp(Color3.new(1, 1, 1), 0.12 * (k - 1)),
			Vector3.new(l * 0.5, l, 0.18 * e),
			raiz,
			material,
			virar * abre * CFrame.new(0, l * 0.45, 0.02 * k * e)
		)
		pena.Name = "Enfeite"
		pena.Transparency = transparencia
		pena.CanQuery = false
	end
end

-- Aura das raras: quanto mais rara, mais coisa acontece em volta (poucas partículas: leve no celular)
-- Lendária: onda de luz saindo do chão. Mítica: + redemoinho e raios de luz.
-- Secreta: + segunda onda colorida e poeira de galáxia.
-- texturas da biblioteca do VFX Studio (anel, estrela, feixe de luz e brilho em cruz)
local TEX_ANEL = "rbxassetid://18391380989"
-- (a textura de estrela da biblioteca é uma folha de quadros e aparecia como grade de pontinhos)
local TEX_ESTRELA = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_FEIXE = "rbxassetid://74970414136395"
local TEX_CRUZ = "rbxasset://textures/particles/sparkles_main.dds" -- a cruz da biblioteca virava grade de pontinhos
local function auraRara(corpo: BasePart, aro: BasePart, nivel: number, cor: Color3, e: number)
	if nivel < 4 then
		return
	end
	local function onda(nome: string, c0: Color3, c1: Color3, atraso: number)
		local o = Instance.new("ParticleEmitter")
		o.Name = nome
		o.Texture = TEX_ANEL
		o.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		o.EmissionDirection = Enum.NormalId.Right -- o aro está deitado: Right aponta para cima
		o.Speed = NumberRange.new(0.05)
		o.Color = ColorSequence.new(c0, c1)
		o.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5 * e),
			NumberSequenceKeypoint.new(1, 7 * e),
		})
		o.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		o.Lifetime = NumberRange.new(1.3)
		o.Rate = 0.7
		o.LightEmission = 1
		o.LockedToPart = true
		o.TimeScale = 1
		o.Parent = aro
		if atraso > 0 then
			o.Enabled = false
			task.delay(atraso, function()
				o.Enabled = true
			end)
		end
	end
	onda("Onda", Color3.new(1, 1, 1), cor, 0)
	if nivel >= 5 then
		-- redemoinho em volta do corpo
		local giro = Instance.new("ParticleEmitter")
		giro.Name = "Redemoinho"
		giro.Texture = TEX_CRUZ
		giro.Color = ColorSequence.new(cor, Color3.new(1, 1, 1))
		giro.Shape = Enum.ParticleEmitterShape.Cylinder
		giro.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		giro.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		giro.EmissionDirection = Enum.NormalId.Top
		giro.Speed = NumberRange.new(2, 4)
		giro.Acceleration = Vector3.new(0, 4, 0)
		giro.Drag = 1
		giro.Size = NumberSequence.new(0.6 * e, 0)
		giro.Lifetime = NumberRange.new(1.2, 1.8)
		giro.Rate = 14
		giro.RotSpeed = NumberRange.new(-180, 180)
		giro.LightEmission = 1
		giro.Parent = corpo
		-- raios de luz atrás (um brilho grande e lento)
		local raios = Instance.new("ParticleEmitter")
		raios.Name = "Raios"
		raios.Texture = TEX_FEIXE
		raios.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.4))
		raios.Size = NumberSequence.new(7 * e)
		raios.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		raios.Lifetime = NumberRange.new(2.5)
		raios.Rate = 0.8
		raios.Speed = NumberRange.new(0)
		raios.Rotation = NumberRange.new(0, 360)
		raios.RotSpeed = NumberRange.new(-25, 25)
		raios.LightEmission = 1
		raios.ZOffset = -2
		raios.LockedToPart = true
		raios.Parent = corpo
	end
	if nivel >= 6 then
		onda("Onda2", Color3.fromRGB(255, 120, 230), Color3.fromRGB(120, 220, 255), 0.65)
		local galaxia = Instance.new("ParticleEmitter")
		galaxia.Name = "Galaxia"
		galaxia.Texture = TEX_ESTRELA
		galaxia.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 230)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 120, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 230, 255)),
		})
		galaxia.Shape = Enum.ParticleEmitterShape.Sphere
		galaxia.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		galaxia.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.5 * e),
			NumberSequenceKeypoint.new(1, 0),
		})
		galaxia.Lifetime = NumberRange.new(2, 3)
		galaxia.Speed = NumberRange.new(0.3, 0.8)
		galaxia.SpreadAngle = Vector2.new(180, 180)
		galaxia.Rate = 10
		galaxia.LightEmission = 1
		galaxia.Parent = corpo
	end
end

-- peças que não contam para achar o topo da cabeça (coroa e auréola ficam em cima do resto)
local FORA_DO_TOPO = { Rabo = true, Capa = true, Cubo = true, Nuvem = true, Jato = true, Pata = true }

-- Enfeites que mostram a raridade de longe:
-- Raro orelhas (no corpo), Épico asinhas brancas, Lendário coroa com joias,
-- Mítico asas grandes brilhando + auréola, Secreto tudo isso e um cristal flutuando.
local function enfeites(modelo: Model, corpo: BasePart, e: number, nivel: number, cor: Color3)
	-- ponto mais alto da Mistureba (a fantasia costuma ficar em cima da cabeça)
	local topo = 1.3 * e
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and not FORA_DO_TOPO[p.Name] then
			local y = corpo.CFrame:PointToObjectSpace(p.Position).Y + math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2
			topo = math.max(topo, y)
		end
	end
	local temCoroa = nivel == 4 or nivel == 6
	if nivel >= 5 then
		for _, lado in { -1, 1 } do
			asa(modelo, corpo, e, lado, 4, 2.7, cor:Lerp(Color3.new(1, 1, 1), 0.25), Enum.Material.Neon, 0.4)
		end
	elseif nivel >= 3 then
		for _, lado in { -1, 1 } do
			asa(modelo, corpo, e, lado, 3, 1.75, Color3.fromRGB(252, 250, 255), Enum.Material.SmoothPlastic, 0)
		end
	end
	if temCoroa then
		-- coroa dourada torta, com pontas e joias
		local ouro = Color3.fromRGB(255, 200, 40)
		local inclina = CFrame.Angles(math.rad(-8), 0, math.rad(12))
		local lugar = CFrame.new(0, topo + 0.05 * e, 0.1 * e)
		local base = Instance.new("Part")
		base.Name = "Enfeite"
		base.Shape = Enum.PartType.Cylinder
		base.Size = Vector3.new(0.4, 1.25, 1.25) * e
		base.Color = ouro
		base.Material = Enum.Material.SmoothPlastic
		base.Reflectance = 0.15
		base.CanCollide = false
		base.CanTouch = false
		base.CanQuery = false
		base.Massless = true
		base.CastShadow = false
		base.CFrame = corpo.CFrame * lugar * inclina * CFrame.Angles(0, 0, math.pi / 2)
		base.Parent = modelo
		soldar(corpo, base)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2 + math.pi / 2
			oval3(
				modelo,
				corpo,
				ouro,
				Vector3.new(0.26, 0.55, 0.26) * e,
				Vector3.zero,
				Enum.Material.SmoothPlastic,
				lugar * inclina * CFrame.new(math.cos(a) * 0.5 * e, 0.38 * e, math.sin(a) * 0.5 * e)
			).Name =
				"Enfeite"
			-- bolinha brilhante na ponta
			oval3(
				modelo,
				corpo,
				Color3.fromRGB(255, 245, 190),
				Vector3.new(0.16, 0.16, 0.16) * e,
				Vector3.zero,
				Enum.Material.Neon,
				lugar * inclina * CFrame.new(math.cos(a) * 0.5 * e, 0.68 * e, math.sin(a) * 0.5 * e)
			).Name =
				"Enfeite"
		end
		-- joias na faixa da coroa: vermelha na frente, azuis dos lados
		for _, j in
			{
				{ ang = -math.pi / 2, cor = Color3.fromRGB(255, 50, 90) },
				{ ang = -math.pi / 2 + 1.1, cor = Color3.fromRGB(60, 160, 255) },
				{ ang = -math.pi / 2 - 1.1, cor = Color3.fromRGB(60, 160, 255) },
			}
		do
			local joia = oval3(
				modelo,
				corpo,
				j.cor,
				Vector3.new(0.22, 0.26, 0.12) * e,
				Vector3.zero,
				Enum.Material.Glass,
				lugar
					* inclina
					* CFrame.new(math.cos(j.ang) * 0.63 * e, 0, math.sin(j.ang) * 0.63 * e)
					* CFrame.Angles(0, -j.ang - math.pi / 2, 0)
			)
			joia.Name = "Enfeite"
			joia.Reflectance = 0.3
		end
	end
	if nivel >= 5 then
		-- auréola: anel de bolinhas brilhando acima de tudo
		local alturaAureola = topo + (if temCoroa then 1.2 else 0.5) * e
		for i = 0, 13 do
			local a = i / 14 * math.pi * 2
			oval3(
				modelo,
				corpo,
				Color3.fromRGB(255, 245, 170),
				Vector3.new(0.26, 0.2, 0.26) * e,
				Vector3.new(math.cos(a) * 0.85 * e, alturaAureola, (math.sin(a) * 0.85 + 0.2) * e),
				Enum.Material.Neon
			).Name =
				"Aureola"
		end
	end
	if nivel >= 6 then
		-- Secreta: cristal brilhando em cima de tudo
		local cristal = Instance.new("Part")
		cristal.Name = "Cristal"
		cristal.Size = Vector3.new(0.55, 0.55, 0.55) * e
		cristal.Color = cor
		cristal.Material = Enum.Material.Neon
		cristal.CanCollide = false
		cristal.CanTouch = false
		cristal.CanQuery = false
		cristal.Massless = true
		cristal.CastShadow = false
		cristal.CFrame = corpo.CFrame
			* CFrame.new(0, topo + 2.1 * e, 0.2 * e)
			* CFrame.Angles(math.rad(45), 0, math.rad(45))
		cristal.Parent = modelo
		soldar(corpo, cristal)
		local faisca = Instance.new("ParticleEmitter")
		faisca.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		faisca.Color = ColorSequence.new(cor, Color3.new(1, 1, 1))
		faisca.Rate = 4
		faisca.Lifetime = NumberRange.new(0.6, 1)
		faisca.Speed = NumberRange.new(0.5, 1)
		faisca.SpreadAngle = Vector2.new(180, 180)
		faisca.Size = NumberSequence.new(0.5 * e, 0)
		faisca.LightEmission = 1
		faisca.Parent = cristal
	end
end

-- Cria o modelo de uma Mistureba: um bichinho gordinho e redondo da cor dela,
-- com barriga, pezinhos e bracinhos, usando as peças da fantasia (Config) por cima.
-- O corpo é a PrimaryPart e fica ancorado.
function Criaturas.modelo(id: string): Model
	local def = Config.PorId[id]
	assert(def, "Mistureba desconhecida: " .. tostring(id))
	local raridade = Config.Raridades[def.raridade]
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	-- Mini e Gigante só mudam o tamanho
	-- (com limite para a Gigante não invadir a vaga do lado)
	local escala = math.min(raridade.tamanho * (if mut and mut.tamanho then mut.tamanho else 1), 2.5)
	local e = escala

	local modelo = Instance.new("Model")
	modelo.Name = def.nome
	modelo:SetAttribute("Criatura", id)

	-- cor vem da família (paleta única para o jogo todo ficar com a mesma cara)
	local visual, familia = Estilo.de(def.base or def.id)
	local cor = familia.cores[visual.tom] or familia.cores[1]
	-- as mais raras têm visual só delas (Especiais.luau)
	local especial = Especiais.de(def.base or def.id)
	if especial then
		cor = especial.corpo
	end
	local ficha: Tracos.Ficha = Tracos.Fichas[def.base or def.id] or {}
	-- formato do corpo de cada bicho (nunca menor que o padrão: pés e braços ficam no lugar)
	local forma = ficha.forma or Vector3.one
	forma = Vector3.new(math.max(forma.X, 1), math.max(forma.Y, 1), math.max(forma.Z, 1))
	local corpo = Instance.new("Part")
	oval(corpo)
	corpo.Name = "Corpo"
	corpo.Size = Vector3.new(3.2, 2.9, 3) * forma * e
	corpo.Color = cor
	corpo.Material = Enum.Material.SmoothPlastic
	corpo.Reflectance = if especial and especial.brilho then especial.brilho else familia.brilho
	corpo.CanCollide = false
	corpo.CanTouch = false
	corpo.CanQuery = true
	corpo.Anchored = true
	corpo.CFrame = CFrame.new()
	corpo.Parent = modelo
	modelo.PrimaryPart = corpo

	local clara = if especial then especial.barriga else familia.barriga
	-- segunda cor: o corpo puxado para o tom de destaque da família (pés, cauda, juba...)
	local segunda = if especial
		then cor:Lerp(Color3.new(0, 0, 0), 0.22)
		else cor:Lerp(familia.acento, 0.35):Lerp(Color3.new(0, 0, 0), 0.08)
	oval3(modelo, corpo, clara, Vector3.new(2.1, 1.7, 0.7) * e, Vector3.new(0, -0.45 * e, -corpo.Size.Z / 2 + 0.3 * e)).Name =
		"Barriga"
	local nivel = table.find(Config.OrdemRaridades, def.raridade) or 1
	for _, lado in { -1, 1 } do
		oval3(modelo, corpo, segunda, Vector3.new(1.1, 0.6, 1.4) * e, Vector3.new(0.8 * lado, -1.45, -0.25) * e).Name =
			"Pe"
		-- três dedinhos na ponta do pé
		for d = -1, 1 do
			oval3(
				modelo,
				corpo,
				segunda:Lerp(Color3.new(1, 1, 1), 0.25),
				Vector3.new(0.32, 0.3, 0.32) * e,
				Vector3.new(0.8 * lado + d * 0.3, -1.52, -0.9 + math.abs(d) * 0.08) * e
			).Name =
				"Pe"
		end
		oval3(
			modelo,
			corpo,
			cor,
			Vector3.new(0.6, 1.1, 0.6) * e,
			Vector3.new(1.55 * forma.X * lado, -0.25, -0.3) * e,
			nil,
			CFrame.Angles(0, 0, math.rad(25 * lado))
		).Name =
			"Braco"
	end

	-- o bicho: orelhas, focinho, chifres, cauda, costas e padrão (Tracos.luau)
	Tracos.aplicar({
		modelo = modelo,
		corpo = corpo,
		e = e,
		cor = cor,
		segunda = segunda,
		clara = clara,
	}, ficha)
	-- o acessório que lembra o objeto da mistura (Estilo.luau)
	if not (especial and especial.semAcessorio) then
		Estilo.acessorio({
			modelo = modelo,
			corpo = corpo,
			e = e,
			cor = cor,
			acento = familia.acento,
			familia = familia,
		}, visual.acessorio, visual.corAcessorio)
	end
	if especial then
		especial.montar({ modelo = modelo, corpo = corpo, e = e })
	end

	-- pezinho de enfeite embaixo dos pés: disco claro com borda brilhante da cor da raridade
	-- (fica no nível dos pés para o modelo não flutuar)
	local aro = Instance.new("Part")
	aro.Name = "Aro"
	aro.Shape = Enum.PartType.Cylinder
	local largura = math.max(forma.X, forma.Z)
	aro.Size = Vector3.new(0.1, 4.3 * e * largura, 4.3 * e * largura)
	aro.Color = raridade.cor
	aro.Material = Enum.Material.Neon
	aro.Transparency = 0.15
	aro.CanCollide = false
	aro.CanTouch = false
	aro.CanQuery = false
	aro.Massless = true
	aro.CastShadow = false
	aro.CFrame = corpo.CFrame * CFrame.new(0, -1.74 * e, 0) * CFrame.Angles(0, 0, math.rad(90))
	aro.Parent = modelo
	soldar(corpo, aro)
	local disco = Instance.new("Part")
	disco.Name = "Aro"
	disco.Shape = Enum.PartType.Cylinder
	disco.Size = Vector3.new(0.14, 3.75 * e * largura, 3.75 * e * largura)
	disco.Color = familia.pedestal
	disco.Material = Enum.Material.SmoothPlastic
	disco.CanCollide = false
	disco.CanTouch = false
	disco.CanQuery = false
	disco.Massless = true
	disco.CastShadow = false
	disco.CFrame = corpo.CFrame * CFrame.new(0, -1.73 * e, 0) * CFrame.Angles(0, 0, math.rad(90))
	disco.Parent = modelo
	soldar(corpo, disco)
	-- Lendária para cima: coluna de brilho subindo do aro, para achar de longe
	if (table.find(Config.OrdemRaridades, def.raridade) or 1) >= 4 then
		local coluna = Instance.new("ParticleEmitter")
		coluna.Name = "Coluna"
		coluna.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		coluna.Color = ColorSequence.new(raridade.cor, Color3.new(1, 1, 1))
		coluna.EmissionDirection = Enum.NormalId.Right -- o cilindro está deitado: Right aponta para cima
		coluna.Shape = Enum.ParticleEmitterShape.Disc
		coluna.Rate = 8
		coluna.Lifetime = NumberRange.new(1.2, 1.8)
		coluna.Speed = NumberRange.new(3, 5)
		coluna.Size = NumberSequence.new(0.5 * e, 0)
		coluna.Transparency = NumberSequence.new(0.2, 1)
		coluna.LightEmission = 1
		coluna.Parent = aro
	end

	-- mutação: muda a cor/material de todas as peças do corpo (antes dos olhos)
	if mut and mut.tamanho then
		-- brilho leve para destacar o tamanho diferente
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = ColorSequence.new(mut.cor, Color3.new(1, 1, 1))
		aura.Rate = 5
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1, 2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.4 * e, 0)
		aura.LightEmission = 1
		aura.Parent = corpo
	elseif mut then
		-- altura de cada peça (0 = pés, 1 = topo) para o degradê do arco-íris
		local baixo, alto = -1.8 * e, 2.6 * e
		for _, parte in modelo:GetDescendants() do
			if parte:IsA("BasePart") and parte.Name ~= "Aro" then
				if mut.id == "arcoiris" then
					-- degradê pastel de baixo para cima; o cliente faz as cores andarem
					local rel = corpo.CFrame:PointToObjectSpace(parte.Position)
					local altura = math.clamp((rel.Y - baixo) / (alto - baixo), 0, 1)
					local volta = (math.atan2(rel.X, rel.Z) / (2 * math.pi)) % 1
					local matiz = (altura * 0.6 + volta * 0.5) % 1
					parte:SetAttribute("Matiz", matiz)
					parte.Color = Color3.fromHSV(matiz, 0.6, 1)
					parte.Material = Enum.Material.SmoothPlastic
					parte.Reflectance = 0.1
				else
					parte.Material = if mut.id == "dourada"
						then Enum.Material.SmoothPlastic
						else (Enum.Material :: any)[mut.material]
					parte.Color = if mut.id == "dourada"
						then parte.Color:Lerp(Color3.fromRGB(240, 165, 20), 0.94)
						else parte.Color:Lerp(mut.cor, 0.7)
				end
				if mut.id == "dourada" then
					parte.Reflectance = 0.08
				elseif mut.id == "diamante" then
					parte.Reflectance = 0.35
					parte.Transparency = 0.1
				end
			end
		end
		if mut.id == "arcoiris" then
			CollectionService:AddTag(modelo, "Arcoiris")
			-- arco-íris de verdade atrás da cabeça: 3 faixas de bolinhas
			local faixas = {
				{ raio = 1.75, cor = Color3.fromRGB(255, 95, 110) },
				{ raio = 1.5, cor = Color3.fromRGB(255, 225, 90) },
				{ raio = 1.25, cor = Color3.fromRGB(95, 200, 255) },
			}
			for _, faixa in faixas do
				for k = 0, 8 do
					local a = k / 8 * math.pi
					local bolinha = oval3(
						modelo,
						corpo,
						faixa.cor,
						Vector3.new(0.34, 0.34, 0.2) * e,
						Vector3.new(math.cos(a) * faixa.raio, 0.55 + math.sin(a) * faixa.raio, 0.9) * e,
						Enum.Material.Neon
					)
					bolinha.Name = "ArcoIris"
					bolinha.CanQuery = false
				end
			end
		end
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = if mut.id == "arcoiris"
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 240, 120)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(120, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 140, 255)),
			})
			else ColorSequence.new(mut.cor, Color3.new(1, 1, 1))
		aura.Rate = 10
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1.5, 3)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.5, 0)
		aura.LightEmission = 1
		aura.Parent = corpo
		-- mutações de clima ganham enfeite próprio
		if mut.id == "acucarada" then
			-- granulado colorido espalhado pelo corpo
			local granulado = {
				Color3.fromRGB(255, 90, 90),
				Color3.fromRGB(255, 230, 80),
				Color3.fromRGB(90, 220, 255),
				Color3.fromRGB(140, 255, 120),
				Color3.new(1, 1, 1),
			}
			for k = 1, 14 do
				local g = Instance.new("Part")
				g.Name = "Granulado"
				g.Shape = Enum.PartType.Cylinder
				g.Size = Vector3.new(0.75, 0.26, 0.26) * e
				g.Color = granulado[(k - 1) % #granulado + 1]
				g.Material = Enum.Material.SmoothPlastic
				g.CanCollide = false
				g.CanTouch = false
				g.CastShadow = false
				g.Massless = true
				local dir = Vector3.new(
					math.cos(k * 2.4) * math.sin(0.4 + k * 0.2),
					math.cos(0.4 + k * 0.2),
					math.sin(k * 2.4) * math.sin(0.4 + k * 0.2)
				).Unit
				local ponto = dir * Vector3.new(corpo.Size.X / 2, corpo.Size.Y / 2, corpo.Size.Z / 2) * 0.97
				g.CFrame = corpo.CFrame * CFrame.lookAt(ponto, ponto * 2) * CFrame.Angles(0, 0, k)
				g.Parent = modelo
				soldar(corpo, g)
			end
		elseif mut.id == "estelar" then
			-- estrelinhas brilhando em volta
			for k = 1, 3 do
				local estrela = Instance.new("Part")
				estrela.Name = "Estrela"
				estrela.Shape = Enum.PartType.Ball
				estrela.Size = Vector3.one * 0.55 * e
				estrela.Color = Color3.fromRGB(255, 250, 200)
				estrela.Material = Enum.Material.Neon
				estrela.CanCollide = false
				estrela.CanTouch = false
				estrela.CastShadow = false
				estrela.Massless = true
				local ang = k * math.pi * 2 / 3
				estrela.CFrame = corpo.CFrame
					* CFrame.new(math.cos(ang) * 2.3 * e, 0.6 * e + k * 0.25 * e, math.sin(ang) * 2.3 * e)
				estrela.Parent = modelo
				soldar(corpo, estrela)
			end
			local poeira = Instance.new("ParticleEmitter")
			poeira.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			poeira.Color = ColorSequence.new(Color3.fromRGB(180, 160, 255), Color3.fromRGB(255, 250, 200))
			poeira.Rate = 6
			poeira.Lifetime = NumberRange.new(1.5, 2.5)
			poeira.Speed = NumberRange.new(0.3, 0.8)
			poeira.Size = NumberSequence.new(0.8, 0)
			poeira.LightEmission = 1
			poeira.Parent = corpo
		end
	end

	-- brilho de boneco de vinil: reflexo branco no alto da cabeça, do lado da luz
	local reflexo = oval3(
		modelo,
		corpo,
		Color3.new(1, 1, 1),
		Vector3.new(0.75, 0.45, 0.3) * e,
		Vector3.new(-0.75, 1.05, -0.85) * e,
		Enum.Material.Neon,
		CFrame.Angles(math.rad(-40), math.rad(25), math.rad(25))
	)
	reflexo.Name = "Reflexo"
	reflexo.Transparency = 0.55
	reflexo.CanQuery = false
	rosto(
		modelo,
		corpo,
		e,
		if especial then especial.iris elseif nivel >= 2 then raridade.cor else Color3.fromRGB(150, 95, 60)
	)
	-- as especiais já têm asas/coroa próprias; os enfeites de raridade são para as outras
	if not especial then
		enfeites(modelo, corpo, e, nivel, raridade.cor)
	end
	local corAura = if especial then especial.aura else raridade.cor

	if def.raridade ~= "comum" then
		local brilho = Instance.new("PointLight")
		brilho.Color = corAura
		brilho.Range = 6 + escala * 4
		brilho.Brightness = 1.5
		brilho.Parent = corpo
	end
	if def.raridade == "mitico" or def.raridade == "secreto" or def.raridade == "lendario" then
		local brilhinhos = Instance.new("ParticleEmitter")
		brilhinhos.Texture = TEX_ESTRELA
		brilhinhos.Color = ColorSequence.new(corAura)
		brilhinhos.Rate = 6
		brilhinhos.Lifetime = NumberRange.new(1, 1.6)
		brilhinhos.Speed = NumberRange.new(1, 2)
		brilhinhos.Size = NumberSequence.new(0.4)
		brilhinhos.Parent = corpo
	end
	auraRara(corpo, aro, nivel, corAura, e)

	-- a placa fica acima da peça mais alta (fantasia, coroa ou auréola)
	local topoModelo = 0
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			topoModelo = math.max(topoModelo, corpo.CFrame:PointToObjectSpace(p.Position).Y + p.Size.Y / 2)
		end
	end
	local alturaPlaca = math.max(corpo.Size.Y / 2 + 3.2 * escala, topoModelo + 2)
	placa(corpo, {
		{ texto = def.nome, cor = Color3.new(1, 1, 1), tamanho = 26 },
		{
			texto = if mut then raridade.nome .. " · " .. mut.nome .. " x" .. mut.multiplicador else raridade.nome,
			cor = if mut then mut.cor else raridade.cor,
			tamanho = 22,
		},
		{ texto = "+" .. Util.numero(def.renda) .. "/s", cor = Color3.fromRGB(120, 255, 120), tamanho = 22 },
		{ texto = Util.textoUmEm(id), cor = Util.corUmEm(id), tamanho = 20 },
	}, alturaPlaca)

	return modelo
end

-- Versão para carregar na cabeça (roubo): menor, sem pedestal, placa, luzes nem partículas,
-- para não virar um bolo de efeitos em cima do jogador.
function Criaturas.modeloCarregar(id: string): Model
	local modelo = Criaturas.modelo(id)
	for _, d in modelo:GetDescendants() do
		if
			d:IsA("BillboardGui")
			or d:IsA("ParticleEmitter")
			or d:IsA("Light")
			or (d:IsA("BasePart") and d.Name == "Aro")
		then
			d:Destroy()
		end
	end
	modelo:ScaleTo(0.6)
	-- o servidor põe o pivô a 2,5 + meia altura do corpo acima da cabeça; deslocamos o pivô
	-- para os pés ficarem logo em cima da cabeça, sem a bichinha flutuar longe
	local corpo = modelo.PrimaryPart
	if corpo then
		local caixa, tamanho = modelo:GetBoundingBox()
		local fundo = caixa.Position.Y - tamanho.Y / 2 - corpo.Position.Y
		corpo.PivotOffset = CFrame.new(0, 1.8 + corpo.Size.Y / 2 + fundo, 0)
	end
	return modelo
end

-- Move o ovo junto com os enfeites. Fora do workspace a solda ainda não
-- arrasta as peças, então movemos cada uma mantendo a posição relativa.
function Criaturas.moverOvo(ovo: BasePart, cf: CFrame)
	local delta = cf * ovo.CFrame:Inverse()
	for _, p in ovo:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = delta * p.CFrame
		end
	end
	ovo.CFrame = cf
end

-- Cria um ovo da raridade dada. Ovos lendários para cima são dourados.
function Criaturas.ovo(raridade: string): BasePart
	local info = Config.Raridades[raridade]
	local ovo = Instance.new("Part")
	ovo.Name = "Ovo"
	oval(ovo)
	ovo.Size = Vector3.new(2.2, 2.8, 2.2) * (0.85 + info.tamanho * 0.25)
	-- o ovo comum é cinza; fica bem mais bonito como ovo de páscoa creme
	local corFaixa = info.cor:Lerp(Color3.new(0, 0, 0), 0.3)
	local corBolinha = info.cor:Lerp(Color3.new(1, 1, 1), 0.75)
	if raridade == "comum" then
		ovo.Color = Color3.fromRGB(255, 240, 215)
		corFaixa = Color3.fromRGB(120, 205, 120)
		corBolinha = Color3.fromRGB(255, 170, 90)
	else
		ovo.Color = info.cor:Lerp(Color3.new(1, 1, 1), 0.12)
	end
	ovo.Material = Enum.Material.SmoothPlastic
	ovo.Reflectance = 0.08
	ovo.CanCollide = true
	ovo:SetAttribute("Raridade", raridade)

	-- enfeites de ovo de páscoa: faixa no meio, bolinhas e um brilho no topo
	local nivelOvo = table.find(Config.OrdemRaridades, raridade) or 1
	local s = ovo.Size
	local faixa = Instance.new("Part")
	faixa.Shape = Enum.PartType.Cylinder
	faixa.Size = Vector3.new(0.35 * s.Y / 2.8, s.X + 0.06, s.Z + 0.06)
	faixa.Color = corFaixa
	faixa.Material = if nivelOvo >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	faixa.CanCollide = false
	faixa.CanTouch = false
	faixa.Massless = true
	faixa.CastShadow = false
	faixa.CFrame = ovo.CFrame * CFrame.new(0, -s.Y * 0.04, 0) * CFrame.Angles(0, 0, math.pi / 2)
	faixa.Parent = ovo
	soldar(ovo, faixa)

	local a, b, c = s.X / 2, s.Y / 2, s.Z / 2
	for i = 0, 5 do
		local ang = i * math.pi / 3 + 0.4
		local alt = if i % 2 == 0 then 0.45 else -0.4
		local d = Vector3.new(math.cos(ang), alt, math.sin(ang)).Unit
		local t = 1 / math.sqrt((d.X / a) ^ 2 + (d.Y / b) ^ 2 + (d.Z / c) ^ 2)
		local ponto = d * t
		local normal = Vector3.new(ponto.X / (a * a), ponto.Y / (b * b), ponto.Z / (c * c)).Unit
		local tam = s.X * 0.22
		oval3(
			ovo,
			ovo,
			corBolinha,
			Vector3.new(tam, tam, 0.12),
			Vector3.zero,
			Enum.Material.SmoothPlastic,
			CFrame.lookAt(ponto - normal * 0.03, ponto + normal)
		)
	end
	-- brilho de "plástico novo" no alto, do lado da frente
	local dBrilho = Vector3.new(-0.35, 0.75, -0.55).Unit
	local tB = 1 / math.sqrt((dBrilho.X / a) ^ 2 + (dBrilho.Y / b) ^ 2 + (dBrilho.Z / c) ^ 2)
	local pB = dBrilho * tB
	local nB = Vector3.new(pB.X / (a * a), pB.Y / (b * b), pB.Z / (c * c)).Unit
	local brilho = oval3(
		ovo,
		ovo,
		Color3.new(1, 1, 1),
		Vector3.new(s.X * 0.16, s.X * 0.26, 0.08),
		Vector3.zero,
		Enum.Material.Neon,
		CFrame.lookAt(pB - nB * 0.02, pB + nB)
	)
	brilho.Transparency = 0.25
	brilho.Name = "Brilho"

	local luz = Instance.new("PointLight")
	luz.Color = info.cor
	luz.Range = 8
	luz.Brightness = 2
	luz.Parent = ovo

	-- quanto mais raro, mais o ovo chama atenção: brilhos a partir de épico,
	-- coluna de luz subindo a partir de lendário
	local nivel = table.find(Config.OrdemRaridades, raridade) or 1
	if nivel >= 3 then
		local brilhos = Instance.new("ParticleEmitter")
		brilhos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brilhos.Color = ColorSequence.new(info.cor, Color3.new(1, 1, 1))
		brilhos.Size = NumberSequence.new(0.6, 0)
		brilhos.Lifetime = NumberRange.new(0.6, 1.2)
		brilhos.Rate = 6 + nivel * 4
		brilhos.Speed = NumberRange.new(2, 4)
		brilhos.SpreadAngle = Vector2.new(180, 180)
		brilhos.LightEmission = 1
		brilhos.Parent = ovo
		luz.Range = 14
	end
	if nivel >= 4 then
		local coluna = Instance.new("ParticleEmitter")
		coluna.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		coluna.Color = ColorSequence.new(info.cor)
		coluna.Size = NumberSequence.new(2.5, 0.5)
		coluna.Transparency = NumberSequence.new(0.2, 1)
		coluna.Lifetime = NumberRange.new(2, 2.5)
		coluna.Rate = 25
		coluna.Speed = NumberRange.new(14, 18)
		coluna.EmissionDirection = Enum.NormalId.Top
		coluna.SpreadAngle = Vector2.new(3, 3)
		coluna.LightEmission = 1
		coluna.LockedToPart = false
		coluna.Parent = ovo
		luz.Range = 20
		luz.Brightness = 4
	end

	placa(ovo, { { texto = "Ovo " .. info.nome, cor = info.cor, tamanho = 24 } }, 2.6)
	return ovo
end

return Criaturas
