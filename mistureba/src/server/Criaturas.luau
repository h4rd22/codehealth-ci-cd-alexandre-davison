--!strict
-- Os modelos agora ficam em ReplicatedStorage.Shared.Modelos (o cliente também usa,
-- para mostrar a Mistureba em 3D na chocagem). Este arquivo só repassa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return require(ReplicatedStorage.Shared.Modelos)
