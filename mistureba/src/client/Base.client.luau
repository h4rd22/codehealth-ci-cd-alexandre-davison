--!strict
-- Ajustes que só valem para quem está jogando:
-- - o dono passa pela própria porta trancada (os outros batem nela);
-- - o botão "Roubar" não aparece nas suas próprias Misturebas;
-- - o botão "Trancar" só aparece na sua base.
-- O servidor confere tudo de novo, isto é só para a tela ficar certa.

local Players = game:GetService("Players")

local jogador = Players.LocalPlayer
local mapa = workspace:WaitForChild("Mapa")

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
		end
	end
end

while true do
	ajustar()
	task.wait(0.4)
end
