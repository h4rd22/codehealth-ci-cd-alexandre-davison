--!strict
-- Efeitos só de tela nas Misturebas (não pesa no servidor):
-- - Arco-íris: as cores do degradê ficam andando devagar.
-- Só atualiza as que estão perto da câmera e no máximo 12 vezes por segundo.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local DISTANCIA = 80
local INTERVALO = 1 / 12

type Info = { corpo: BasePart?, partes: { { parte: BasePart, matiz: number } } }
local arcoiris: { [Instance]: Info } = {}

local function adicionar(modelo: Instance)
	if not modelo:IsA("Model") then
		return
	end
	local info: Info = { corpo = modelo.PrimaryPart, partes = {} }
	for _, p in modelo:GetDescendants() do
		local m = p:GetAttribute("Matiz")
		if p:IsA("BasePart") and type(m) == "number" then
			table.insert(info.partes, { parte = p, matiz = m })
		end
	end
	arcoiris[modelo] = info
end

CollectionService:GetInstanceAddedSignal("Arcoiris"):Connect(adicionar)
CollectionService:GetInstanceRemovedSignal("Arcoiris"):Connect(function(modelo)
	arcoiris[modelo] = nil
end)
for _, modelo in CollectionService:GetTagged("Arcoiris") do
	adicionar(modelo)
end

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < INTERVALO then
		return
	end
	acumulado = 0
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local deslocamento = (os.clock() * 0.15) % 1
	local olho = camera.CFrame.Position
	for _, info in arcoiris do
		local corpo = info.corpo
		if #info.partes == 0 and corpo and corpo.Parent then
			adicionar(corpo.Parent) -- peças ainda chegando (streaming)
			continue
		end
		if corpo and corpo.Parent and (corpo.Position - olho).Magnitude < DISTANCIA then
			for _, item in info.partes do
				item.parte.Color = Color3.fromHSV((item.matiz + deslocamento) % 1, 0.5, 1)
			end
		end
	end
end)
