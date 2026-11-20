-- Rinnegan no rosto do herói: um olho lilás com anéis concêntricos escuros,
-- pupila pequena e brilho de vidro. Feito com SurfaceGui (sem imagem para subir),
-- então fica nítido de perto e não depende de textura.
local Rinnegan = {}

local LILAS_CLARO = Color3.fromRGB(232, 214, 255)
local LILAS = Color3.fromRGB(176, 136, 236)
local LILAS_FUNDO = Color3.fromRGB(118, 78, 196)
local ANEL = Color3.fromRGB(38, 16, 62)
local BRILHO = Color3.fromRGB(196, 120, 255)

local function circulo(pai, escala, cor, transparencia)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(escala, escala)
	f.BackgroundColor3 = cor or Color3.new()
	f.BackgroundTransparency = transparencia or 0
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	f.Parent = pai
	return f
end

local function contorno(f, cor, espessura, transparencia)
	local s = Instance.new("UIStroke")
	s.Color = cor
	s.Thickness = espessura
	s.Transparency = transparencia or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end

-- Desenha um olho dentro de uma peça (a face da frente da peça é o olho)
local function desenharOlho(peca)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Rinnegan"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(256, 256)
	sg.LightInfluence = 0
	sg.Brightness = 1.6
	sg.AlwaysOnTop = false
	sg.Parent = peca

	-- halo roxo suave em volta (dá o "brilho" do olho)
	local halo = circulo(sg, 1, BRILHO, 0.55)
	local hg = Instance.new("UIGradient")
	hg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	hg.Parent = halo

	-- íris: lilás, mais clara em cima e mais funda embaixo
	local iris = circulo(sg, 0.86, LILAS)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, LILAS_CLARO),
		ColorSequenceKeypoint.new(0.55, LILAS),
		ColorSequenceKeypoint.new(1, LILAS_FUNDO),
	})
	g.Parent = iris
	contorno(iris, ANEL, 9)

	-- anéis concêntricos (a marca do Rinnegan)
	for _, escala in ipairs({ 0.72, 0.52, 0.32 }) do
		local anel = circulo(iris, escala / 0.86, Color3.new(), 1)
		contorno(anel, ANEL, 7, 0.05)
	end

	-- pupila
	local pupila = circulo(iris, 0.16 / 0.86, Color3.fromRGB(22, 8, 34))
	contorno(pupila, BRILHO, 2, 0.4)

	-- reflexos de vidro (deixa o olho "vivo")
	local reflexo = circulo(iris, 0.16, Color3.new(1, 1, 1), 0.15)
	reflexo.Position = UDim2.fromScale(0.33, 0.28)
	local reflexo2 = circulo(iris, 0.07, Color3.new(1, 1, 1), 0.45)
	reflexo2.Position = UDim2.fromScale(0.66, 0.68)
end

-- Põe os dois olhos no rosto. 'grudar' é a função do servidor que solda peças ao corpo.
-- opcoes: { x = distância do meio, y = altura, tamanho = diâmetro } (studs, relativos à cabeça)
function Rinnegan.vestir(pastaEq, cabeca, grudar, opcoes)
	opcoes = opcoes or {}
	local tamanho = opcoes.tamanho or 0.27
	local x = opcoes.x or 0.2
	local y = opcoes.y or 0.12
	for _, lado in ipairs({ -1, 1 }) do
		local p = grudar(
			pastaEq,
			cabeca,
			Vector3.new(tamanho, tamanho, 0.02),
			CFrame.new(x * lado, y, -cabeca.Size.Z / 2 - 0.012),
			LILAS,
			Enum.Material.SmoothPlastic,
			false
		)
		p.Name = "OlhoRinnegan"
		p.Transparency = 1
		p.CastShadow = false
		desenharOlho(p)
	end
	-- leve luz roxa no rosto
	local luz = Instance.new("PointLight")
	luz.Name = "LuzRinnegan"
	luz.Color = BRILHO
	luz.Range = 4
	luz.Brightness = 0.8
	luz.Parent = pastaEq:FindFirstChild("OlhoRinnegan") or cabeca
end

return Rinnegan
