--!strict
-- Monta o mapa: campo da chuva de ovos no meio e 8 bases em volta.
-- Tudo é criado por código para o jogo funcionar direto do Rojo.

local Lighting = game:GetService("Lighting")

local Mapa = {}

export type Base = {
	indice: number,
	modelo: Model,
	centro: CFrame, -- olhando para o meio do mapa
	tamanho: Vector3,
	vagas: { CFrame }, -- onde cada Mistureba fica
	pedestais: { BasePart },
	porta: BasePart,
	botao: BasePart,
	placa: TextLabel,
}

Mapa.NUM_BASES = 8
Mapa.RAIO_BASES = 115
Mapa.RAIO_CAMPO = 48
Mapa.TAMANHO_BASE = Vector3.new(46, 0, 50)
Mapa.MAX_VAGAS = 20

local function bloco(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	return p
end

local function texto(pai: Instance, conteudo: string, cor: Color3, tamanhoGui: UDim2, offset: Vector3): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = tamanhoGui
	gui.StudsOffsetWorldSpace = offset
	gui.LightInfluence = 0
	gui.MaxDistance = 250
	local rotulo = Instance.new("TextLabel")
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Font = Enum.Font.FredokaOne
	rotulo.TextScaled = true
	rotulo.TextColor3 = cor
	rotulo.TextStrokeTransparency = 0
	rotulo.Text = conteudo
	rotulo.Parent = gui
	gui.Parent = pai
	return rotulo
end

local CORES_BASE = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 180, 90),
	Color3.fromRGB(250, 230, 100),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(100, 200, 255),
	Color3.fromRGB(150, 130, 255),
	Color3.fromRGB(240, 130, 220),
	Color3.fromRGB(160, 240, 220),
}

local function criarBase(indice: number, pasta: Folder): Base
	local angulo = (indice - 1) / Mapa.NUM_BASES * math.pi * 2
	local posicao = Vector3.new(math.cos(angulo), 0, math.sin(angulo)) * Mapa.RAIO_BASES
	-- a frente da base (-Z do CFrame) aponta para o meio
	local centro = CFrame.lookAt(posicao, Vector3.zero)
	local cor = CORES_BASE[indice]
	local largura, fundo = Mapa.TAMANHO_BASE.X, Mapa.TAMANHO_BASE.Z

	local modelo = Instance.new("Model")
	modelo.Name = "Base" .. indice

	bloco({
		Name = "Chao",
		Size = Vector3.new(largura, 1, fundo),
		CFrame = centro * CFrame.new(0, 0.5, 0),
		Color = cor:Lerp(Color3.new(1, 1, 1), 0.55),
		Parent = modelo,
	})

	-- paredes: fundo e laterais; a frente tem a porta
	local alturaParede = 9
	local function parede(tamanho: Vector3, deslocamento: Vector3)
		bloco({
			Name = "Parede",
			Size = tamanho,
			CFrame = centro * CFrame.new(deslocamento),
			Color = cor,
			Parent = modelo,
		})
	end
	-- faixa brilhante em volta do chão, na cor da base
	bloco({
		Name = "Faixa",
		Size = Vector3.new(largura + 2, 0.4, fundo + 2),
		CFrame = centro * CFrame.new(0, 0.25, 0),
		Color = cor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = modelo,
	})
	parede(Vector3.new(largura, alturaParede, 1), Vector3.new(0, alturaParede / 2 + 1, fundo / 2))
	parede(Vector3.new(1, alturaParede, fundo), Vector3.new(largura / 2, alturaParede / 2 + 1, 0))
	parede(Vector3.new(1, alturaParede, fundo), Vector3.new(-largura / 2, alturaParede / 2 + 1, 0))
	local larguraPorta = 14
	local ladoFrente = (largura - larguraPorta) / 2
	parede(
		Vector3.new(ladoFrente, alturaParede, 1),
		Vector3.new(-(larguraPorta + ladoFrente) / 2, alturaParede / 2 + 1, -fundo / 2)
	)
	parede(
		Vector3.new(ladoFrente, alturaParede, 1),
		Vector3.new((larguraPorta + ladoFrente) / 2, alturaParede / 2 + 1, -fundo / 2)
	)

	local porta = bloco({
		Name = "Porta",
		Size = Vector3.new(larguraPorta, alturaParede, 0.6),
		CFrame = centro * CFrame.new(0, alturaParede / 2 + 1, -fundo / 2),
		Color = Color3.fromRGB(255, 60, 60),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})

	-- botão do cadeado, do lado de dentro, perto da porta
	local botao = bloco({
		Name = "BotaoCadeado",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 3.4, 3.4),
		CFrame = centro * CFrame.new(largura / 2 - 5, 1.5, -fundo / 2 + 5) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(230, 40, 40),
		Material = Enum.Material.Neon,
		Parent = modelo,
	})
	texto(botao, "CADEADO", Color3.new(1, 1, 1), UDim2.fromScale(6, 1.5), Vector3.new(0, 2.5, 0))

	-- vagas: 5 colunas x 4 linhas, do fundo para a frente
	local vagas = {}
	local pedestais = {}
	local colunas, linhas = 5, 4
	local espacoX, espacoZ = 8, 8.5
	for linha = 1, linhas do
		for coluna = 1, colunas do
			local x = (coluna - (colunas + 1) / 2) * espacoX
			local z = fundo / 2 - 7 - (linha - 1) * espacoZ
			local cfPedestal = centro * CFrame.new(x, 1.5, z)
			local pedestal = bloco({
				Name = "Pedestal",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1, 5.5, 5.5),
				CFrame = cfPedestal * CFrame.Angles(0, 0, math.rad(90)),
				Color = cor:Lerp(Color3.new(0, 0, 0), 0.15),
				Material = Enum.Material.Marble,
				Transparency = 1,
				CanCollide = false,
				Parent = modelo,
			})
			table.insert(pedestais, pedestal)
			-- a Mistureba olha para a porta
			table.insert(vagas, cfPedestal * CFrame.new(0, 0.5, 0))
		end
	end

	-- placa com o nome do dono, em cima da parede do fundo
	local suporte = bloco({
		Name = "Placa",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = centro * CFrame.new(0, alturaParede + 6, fundo / 2),
		Parent = modelo,
	})
	local placa = texto(suporte, "Base livre", Color3.new(1, 1, 1), UDim2.fromScale(28, 5), Vector3.zero)

	modelo.PrimaryPart = modelo:FindFirstChild("Chao") :: BasePart
	modelo.Parent = pasta

	return {
		indice = indice,
		modelo = modelo,
		centro = centro,
		tamanho = Vector3.new(largura, alturaParede, fundo),
		vagas = vagas,
		pedestais = pedestais,
		porta = porta,
		botao = botao,
		placa = placa,
	}
end

-- Céu, cores mais vivas e um brilho leve: o mapa tem que chamar atenção na miniatura.
local function iluminar()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 3
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 160, 200)
	Lighting.GlobalShadows = true
	for _, efeito in Lighting:GetChildren() do
		if efeito:IsA("PostEffect") or efeito:IsA("Atmosphere") then
			efeito:Destroy()
		end
	end
	local atmosfera = Instance.new("Atmosphere")
	atmosfera.Density = 0.28
	atmosfera.Haze = 1.2
	atmosfera.Color = Color3.fromRGB(255, 220, 245)
	atmosfera.Decay = Color3.fromRGB(150, 120, 255)
	atmosfera.Glare = 0.4
	atmosfera.Parent = Lighting
	local cor = Instance.new("ColorCorrectionEffect")
	cor.Saturation = 0.35
	cor.Contrast = 0.08
	cor.Brightness = 0.03
	cor.Parent = Lighting
	local brilho = Instance.new("BloomEffect")
	brilho.Intensity = 0.6
	brilho.Size = 28
	brilho.Threshold = 1.6
	brilho.Parent = Lighting
end

-- Arco-íris por cima do campo, árvores de bala e cogumelos gigantes em volta.
local CORES_ARCO = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 170, 255),
	Color3.fromRGB(150, 90, 255),
}

local function decorar(pasta: Folder)
	local deco = Instance.new("Folder")
	deco.Name = "Decoracao"
	deco.Parent = pasta

	-- arco-íris: 6 faixas em meia volta, por cima do campo
	local raio0 = Mapa.RAIO_CAMPO + 4
	local pedacos = 28
	for faixa, cor in CORES_ARCO do
		local raio = raio0 - (faixa - 1) * 2.2
		for i = 0, pedacos - 1 do
			local a0 = i / pedacos * math.pi
			local a1 = (i + 1) / pedacos * math.pi
			local p0 = Vector3.new(math.cos(a0) * raio, math.sin(a0) * raio * 0.75, -6)
			local p1 = Vector3.new(math.cos(a1) * raio, math.sin(a1) * raio * 0.75, -6)
			bloco({
				Name = "Arco",
				Size = Vector3.new(2.2, 1.4, (p1 - p0).Magnitude + 0.3),
				CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
				Color = cor,
				Material = Enum.Material.Neon,
				Transparency = 0.15,
				CanCollide = false,
				CastShadow = false,
				Parent = deco,
			})
		end
	end

	-- anel brilhante marcando a borda do campo
	local segmentos = 48
	for i = 0, segmentos - 1 do
		local a = i / segmentos * math.pi * 2
		local cor = CORES_ARCO[i % #CORES_ARCO + 1]
		bloco({
			Name = "Anel",
			Size = Vector3.new(1.2, 0.6, Mapa.RAIO_CAMPO * 2 * math.pi / segmentos + 0.2),
			CFrame = CFrame.new(math.cos(a) * Mapa.RAIO_CAMPO, 0.5, math.sin(a) * Mapa.RAIO_CAMPO)
				* CFrame.Angles(0, -a, 0),
			Color = cor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
			Parent = deco,
		})
	end

	-- árvores de bala e cogumelos entre as bases e na borda do mapa
	local aleatorio = Random.new(7)
	local function arvore(posicao: Vector3, escala: number)
		bloco({
			Name = "Tronco",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 1.6, 1.6) * escala,
			CFrame = CFrame.new(posicao + Vector3.new(0, 5 * escala, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 250, 250),
			Parent = deco,
		})
		local copa = bloco({
			Name = "Bala",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9, 9, 9) * escala,
			CFrame = CFrame.new(posicao + Vector3.new(0, 12 * escala, 0)),
			Color = CORES_ARCO[aleatorio:NextInteger(1, #CORES_ARCO)],
			Parent = deco,
		})
		copa.Material = Enum.Material.Glass
		copa.Reflectance = 0.15
	end
	local function cogumelo(posicao: Vector3, escala: number)
		bloco({
			Name = "Pe",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 3, 3) * escala,
			CFrame = CFrame.new(posicao + Vector3.new(0, 3 * escala, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 240, 220),
			Parent = deco,
		})
		local chapeu = bloco({
			Name = "Chapeu",
			Size = Vector3.new(10, 4, 10) * escala,
			CFrame = CFrame.new(posicao + Vector3.new(0, 7 * escala, 0)),
			Color = Color3.fromRGB(255, 80, 150),
			Parent = deco,
		})
		local malha = Instance.new("SpecialMesh")
		malha.MeshType = Enum.MeshType.Sphere
		malha.Parent = chapeu
	end
	for i = 1, Mapa.NUM_BASES do
		-- entre duas bases vizinhas
		local a = (i - 0.5) / Mapa.NUM_BASES * math.pi * 2
		local p = Vector3.new(math.cos(a), 0, math.sin(a)) * Mapa.RAIO_BASES
		if i % 2 == 0 then
			arvore(p, 1.3)
		else
			cogumelo(p, 1.4)
		end
	end
	for i = 1, 24 do
		local a = i / 24 * math.pi * 2 + aleatorio:NextNumber(-0.1, 0.1)
		local r = aleatorio:NextNumber(165, 195)
		local p = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if aleatorio:NextNumber() < 0.5 then
			arvore(p, aleatorio:NextNumber(1, 1.8))
		else
			cogumelo(p, aleatorio:NextNumber(1, 1.8))
		end
	end
end

function Mapa.construir(): { Base }
	iluminar()

	local antigo = workspace:FindFirstChild("Mapa")
	if antigo then
		antigo:Destroy()
	end
	-- tira a placa de base e os pontos de nascer do modelo padrão do Studio
	for _, obj in workspace:GetChildren() do
		if obj.Name == "Baseplate" or obj:IsA("SpawnLocation") then
			obj:Destroy()
		end
	end

	local pasta = Instance.new("Folder")
	pasta.Name = "Mapa"
	pasta.Parent = workspace

	bloco({
		Name = "Grama",
		Size = Vector3.new(420, 4, 420),
		CFrame = CFrame.new(0, -2, 0),
		Color = Color3.fromRGB(110, 200, 90),
		Material = Enum.Material.Grass,
		Parent = pasta,
	})

	local campo = bloco({
		Name = "CampoDosOvos",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, Mapa.RAIO_CAMPO * 2, Mapa.RAIO_CAMPO * 2),
		CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 225, 160),
		Material = Enum.Material.Sand,
		Parent = pasta,
	})
	local placaCampo = bloco({
		Name = "PlacaCampo",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = CFrame.new(0, 28, 0),
		Parent = pasta,
	})
	texto(placaCampo, "CHUVA DE OVOS", Color3.fromRGB(255, 240, 120), UDim2.fromScale(44, 7), Vector3.zero)
	campo:SetAttribute("Raio", Mapa.RAIO_CAMPO)

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.6, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = pasta

	decorar(pasta)

	local bases = {}
	for i = 1, Mapa.NUM_BASES do
		table.insert(bases, criarBase(i, pasta))
	end
	return bases
end

-- Está dentro da base? (só no plano, ignora altura)
function Mapa.dentro(base: Base, posicao: Vector3): boolean
	local local_ = base.centro:PointToObjectSpace(posicao)
	return math.abs(local_.X) <= base.tamanho.X / 2 and math.abs(local_.Z) <= base.tamanho.Z / 2 and local_.Y < 20
end

return Mapa
