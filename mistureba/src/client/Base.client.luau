--!strict
-- Ajustes que só valem para quem está jogando:
-- - o dono passa pela própria porta trancada (os outros batem nela);
-- - o botão "Roubar" não aparece nas suas próprias Misturebas;
-- - o botão "Trancar" só aparece na sua base;
-- - as Misturebas das bases ficam pulando de leve (só na tela, não pesa no servidor).
-- O servidor confere tudo de novo, isto é só para a tela ficar certa.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jogador = Players.LocalPlayer
local mapa = workspace:WaitForChild("Mapa")

-- modelo -> posição original e um atraso para cada uma pular num ritmo diferente
local animadas: { [Model]: { origem: CFrame, fase: number } } = setmetatable({}, { __mode = "k" }) :: any

local function ajustar()
	for _, obj in mapa:GetDescendants() do
		if obj:IsA("ProximityPrompt") then
			local dono = obj:GetAttribute("Dono")
			if obj.Name == "Roubar" then
				obj.Enabled = dono ~= jogador.UserId
			elseif obj.Name == "Cadeado" then
				obj.Enabled = dono == jogador.UserId
			end
		elseif obj:IsA("BasePart") and obj.Name == "Porta" then
			if obj:GetAttribute("Dono") == jogador.UserId then
				obj.CanCollide = false
				obj.LocalTransparencyModifier = 0.5
			end
		elseif obj:IsA("Model") and obj:GetAttribute("Criatura") and not animadas[obj] then
			animadas[obj] = { origem = obj:GetPivot(), fase = math.random() * math.pi * 2 }
		end
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for modelo, info in animadas do
		if modelo.Parent then
			local pulo = math.abs(math.sin(t * 2.2 + info.fase)) * 0.6
			local giro = math.sin(t * 0.8 + info.fase) * 0.25
			modelo:PivotTo(info.origem * CFrame.new(0, pulo, 0) * CFrame.Angles(0, giro, 0))
		end
	end
end)

while true do
	ajustar()
	task.wait(0.4)
end
