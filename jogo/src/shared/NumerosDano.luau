-- Números de dano: saem do inimigo que levou o golpe, dão um "pop" e caem em arco.
-- Cores: branco = normal, amarelo = crítico, azul-claro = gelo, laranja = fogo,
-- roxo = raio, verde = veneno, vermelho = dano que o herói levou.
local RunService = game:GetService("RunService")

local NumerosDano = {}

NumerosDano.Cores = {
	normal = Color3.fromRGB(255, 255, 255),
	critico = Color3.fromRGB(255, 214, 40),
	gelo = Color3.fromRGB(140, 220, 255),
	fogo = Color3.fromRGB(255, 140, 50),
	queima = Color3.fromRGB(255, 140, 50),
	raio = Color3.fromRGB(196, 140, 255),
	veneno = Color3.fromRGB(120, 230, 90),
	arcano = Color3.fromRGB(255, 120, 220),
	heroi = Color3.fromRGB(255, 70, 70),
	cura = Color3.fromRGB(90, 240, 130),
}

local CONTORNO = Color3.fromRGB(18, 10, 24)
local MAXIMO = 45 -- números na tela ao mesmo tempo (o mais velho some antes)
local vivos = {}

local function abreviar(n)
	n = math.floor(n + 0.5)
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end
NumerosDano.abreviar = abreviar

-- pos: posição do inimigo; valor: número; tipo: "normal", "critico", "gelo", "fogo", "raio"...
-- opcoes: { critico = true (elemental crítico), menor = true (dano contínuo), prefixo = "-" }
function NumerosDano.mostrar(pos, valor, tipo, opcoes)
	opcoes = opcoes or {}
	local cor = NumerosDano.Cores[tipo] or NumerosDano.Cores.normal
	local critico = tipo == "critico" or opcoes.critico == true
	local tamanho = opcoes.menor and 18 or (critico and 36 or 24)

	if #vivos >= MAXIMO then
		local velho = table.remove(vivos, 1)
		if velho then
			velho:Destroy()
		end
	end

	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.one * 0.2
	ancora.Position = pos + Vector3.new(0, 2.2, 0) -- sai da cabeça do boneco
	ancora.Parent = workspace
	table.insert(vivos, ancora)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 140
	bb.Adornee = ancora
	bb.Parent = ancora

	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextSize = tamanho
	t.TextColor3 = cor
	t.Text = (opcoes.prefixo or "") .. abreviar(valor) .. (critico and "!" or "")
	t.Rotation = critico and math.random(-8, 8) or 0
	t.Parent = bb
	local traco = Instance.new("UIStroke")
	traco.Color = (critico and tipo ~= "critico") and Color3.fromRGB(120, 70, 0) or CONTORNO
	traco.Thickness = critico and 3.5 or 2.5
	traco.Parent = t
	-- leve brilho de cima para baixo (claro em cima, cor cheia embaixo)
	local degrade = Instance.new("UIGradient")
	degrade.Rotation = 90
	degrade.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.45), cor)
	degrade.Parent = t
	t.TextColor3 = Color3.new(1, 1, 1)
	local escala = Instance.new("UIScale")
	escala.Scale = 0.3
	escala.Parent = t

	-- arco: sobe e vai para um lado, depois cai um pouco enquanto some
	local lado = (math.random() < 0.5 and -1 or 1) * (0.8 + math.random() * 1.4)
	local subida = critico and 4.2 or 3.2
	local vida = critico and 1.05 or 0.8
	local inicio = os.clock()
	local con
	con = RunService.RenderStepped:Connect(function()
		local a = (os.clock() - inicio) / vida
		if a >= 1 or not ancora.Parent then
			con:Disconnect()
			local i = table.find(vivos, ancora)
			if i then
				table.remove(vivos, i)
			end
			ancora:Destroy()
			return
		end
		-- pop: 0.3 -> 1.35 -> 1 nos primeiros 18% da vida
		if a < 0.1 then
			escala.Scale = 0.3 + (a / 0.1) * 1.05
		elseif a < 0.18 then
			escala.Scale = 1.35 - ((a - 0.1) / 0.08) * 0.35
		else
			escala.Scale = 1 - math.max(0, a - 0.75) * 0.8
		end
		-- parábola: sobe rápido e desce no fim
		local y = subida * (4 * a * (1 - a)) + a * 0.6
		bb.StudsOffset = Vector3.new(lado * a, y, 0) -- relativo à câmera: sempre de lado na tela
		local fade = a > 0.65 and (a - 0.65) / 0.35 or 0
		t.TextTransparency = fade
		traco.Transparency = fade
	end)
end

return NumerosDano
