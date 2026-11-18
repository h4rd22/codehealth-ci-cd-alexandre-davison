-- Combo: conta os inimigos derrotados em sequência e mostra "COMBO x12" na tela.
-- Quanto maior o combo, maior o número e mais quente a cor (branco → amarelo → laranja → vermelho → roxo).
-- Marcos (10, 25, 50, 100...) soltam uma frase de anime, flash e tremida.
-- Escuta o evento "morte" do servidor; não mexe na tela de ninguém.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evDano = remotes:WaitForChild("Dano")

local JANELA = 2.6 -- segundos sem matar para o combo acabar
local MARCOS = {
	[10] = "INCRÍVEL!",
	[25] = "DEVASTADOR!",
	[50] = "IMPARÁVEL!",
	[100] = "LENDÁRIO!!",
	[200] = "DIVINO!!!",
}
local CORES = {
	{ 0, Color3.fromRGB(255, 255, 255) },
	{ 5, Color3.fromRGB(255, 230, 90) },
	{ 15, Color3.fromRGB(255, 150, 40) },
	{ 30, Color3.fromRGB(255, 60, 60) },
	{ 60, Color3.fromRGB(200, 90, 255) },
	{ 120, Color3.fromRGB(80, 230, 255) },
}

local function corDo(n)
	local c = CORES[1][2]
	for _, par in ipairs(CORES) do
		if n >= par[1] then
			c = par[2]
		end
	end
	return c
end

local function tw(o, tempo, props, estilo)
	local t = TweenService:Create(o, TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

-- Tela
local gui = Instance.new("ScreenGui")
gui.Name = "Combo"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local caixa = Instance.new("Frame")
caixa.AnchorPoint = Vector2.new(1, 0.5)
caixa.Position = UDim2.new(1, -24, 0.42, 0)
caixa.Size = UDim2.fromOffset(260, 110)
caixa.BackgroundTransparency = 1
caixa.Visible = false
caixa.Parent = gui

local escala = Instance.new("UIScale")
escala.Parent = caixa

local numero = Instance.new("TextLabel")
numero.BackgroundTransparency = 1
numero.Size = UDim2.new(1, 0, 0, 70)
numero.Font = Enum.Font.FredokaOne
numero.TextScaled = true
numero.TextXAlignment = Enum.TextXAlignment.Right
numero.Text = "x0"
numero.TextColor3 = Color3.new(1, 1, 1)
numero.Rotation = -6
numero.Parent = caixa
local borda = Instance.new("UIStroke")
borda.Thickness = 4
borda.Color = Color3.fromRGB(30, 12, 8)
borda.Parent = numero
local degrade = Instance.new("UIGradient")
degrade.Rotation = 90
degrade.Parent = numero

local titulo = Instance.new("TextLabel")
titulo.BackgroundTransparency = 1
titulo.Position = UDim2.fromOffset(0, 66)
titulo.Size = UDim2.new(1, 0, 0, 26)
titulo.Font = Enum.Font.FredokaOne
titulo.TextSize = 24
titulo.TextXAlignment = Enum.TextXAlignment.Right
titulo.Text = "COMBO"
titulo.TextColor3 = Color3.new(1, 1, 1)
titulo.Rotation = -6
titulo.Parent = caixa
local bordaT = Instance.new("UIStroke")
bordaT.Thickness = 3
bordaT.Color = Color3.fromRGB(30, 12, 8)
bordaT.Parent = titulo

-- barrinha que esvazia: quanto tempo falta para o combo acabar
local fundoBarra = Instance.new("Frame")
fundoBarra.AnchorPoint = Vector2.new(1, 0)
fundoBarra.Position = UDim2.new(1, 0, 0, 96)
fundoBarra.Size = UDim2.fromOffset(150, 7)
fundoBarra.BackgroundColor3 = Color3.fromRGB(30, 18, 14)
fundoBarra.BorderSizePixel = 0
fundoBarra.Parent = caixa
Instance.new("UICorner", fundoBarra).CornerRadius = UDim.new(1, 0)
local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(1, 0)
barra.Position = UDim2.fromScale(1, 0)
barra.Size = UDim2.fromScale(1, 1)
barra.BorderSizePixel = 0
barra.Parent = fundoBarra
Instance.new("UICorner", barra).CornerRadius = UDim.new(1, 0)

-- Frase grande no meio da tela nos marcos
local frase = Instance.new("TextLabel")
frase.AnchorPoint = Vector2.new(0.5, 0.5)
frase.Position = UDim2.fromScale(0.5, 0.33)
frase.Size = UDim2.new(0.7, 0, 0, 70)
frase.BackgroundTransparency = 1
frase.Font = Enum.Font.FredokaOne
frase.TextScaled = true
frase.TextTransparency = 1
frase.Parent = gui
local bordaF = Instance.new("UIStroke")
bordaF.Thickness = 4
bordaF.Transparency = 1
bordaF.Parent = frase
local escalaF = Instance.new("UIScale")
escalaF.Parent = frase

local combo = 0
local ultimo = 0
local barraTween

local function efeitosExtras(n)
	local ok, EM = pcall(require, ReplicatedStorage.Shared:FindFirstChild("EfeitosMagia"))
	if ok and EM then
		EM.flash(corDo(n), 0.25, 0.35)
		EM.tremer(0.5 + math.min(n, 200) / 200, 0.3)
	end
end

local function marco(n, texto)
	local cor = corDo(n)
	frase.Text = "COMBO x" .. n .. " — " .. texto
	frase.TextColor3 = cor
	bordaF.Color = cor:Lerp(Color3.new(0, 0, 0), 0.75)
	frase.TextTransparency = 0
	bordaF.Transparency = 0
	escalaF.Scale = 2.2
	frase.Rotation = -5
	tw(escalaF, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	tw(frase, 0.35, { Rotation = 0 }, Enum.EasingStyle.Back)
	task.delay(1.3, function()
		if frase.Text:find(texto, 1, true) then
			tw(frase, 0.4, { TextTransparency = 1 })
			tw(bordaF, 0.4, { Transparency = 1 })
		end
	end)
	efeitosExtras(n)
end

local function contar()
	local agora = os.clock()
	if agora - ultimo > JANELA then
		combo = 0
	end
	ultimo = agora
	combo += 1
	if combo < 2 then
		return -- combo começa a aparecer no segundo inimigo
	end
	local cor = corDo(combo)
	caixa.Visible = true
	numero.Text = "x" .. combo
	degrade.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.6), cor)
	titulo.TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.4)
	barra.BackgroundColor3 = cor
	-- pulo: maior quanto maior o combo
	escala.Scale = 1.5 + math.min(combo, 100) / 100
	tw(escala, 0.25, { Scale = 1 + math.min(combo, 100) / 250 }, Enum.EasingStyle.Back)
	numero.Rotation = -6 + (combo % 2 == 0 and 4 or -4)
	tw(numero, 0.2, { Rotation = -6 })
	if barraTween then
		barraTween:Cancel()
	end
	barra.Size = UDim2.fromScale(1, 1)
	barraTween = tw(barra, JANELA, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
	local texto = MARCOS[combo]
	if texto then
		marco(combo, texto)
	elseif combo > 200 and combo % 100 == 0 then
		marco(combo, "DIVINO!!!")
	end
	local este = combo
	task.delay(JANELA + 0.05, function()
		if combo == este and os.clock() - ultimo >= JANELA then
			-- fim do combo: some girando
			tw(escala, 0.3, { Scale = 0 }, Enum.EasingStyle.Back)
			task.delay(0.32, function()
				if combo == este then
					caixa.Visible = false
					combo = 0
				end
			end)
		end
	end)
end

evDano.OnClientEvent:Connect(function(tipo)
	if tipo == "morte" then
		contar()
	end
end)
