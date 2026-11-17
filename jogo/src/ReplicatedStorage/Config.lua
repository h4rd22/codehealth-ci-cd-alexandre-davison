-- Config: todos os números de balanceamento do jogo ficam aqui.
-- Versão de TESTE: só as fases 1-1, 1-2 e 1-3.

local Config = {}

-- No jogo final serão 70 monstros por fase. No teste, 10 para ir rápido.
Config.MonstrosPorFase = 10
-- Quantos monstros ficam vivos no mapa ao mesmo tempo.
Config.MonstrosVivos = 5
-- Distância máxima do centro onde os monstros aparecem.
Config.RaioArena = 45

Config.Heroi = {
	Dano = 12,            -- dano base de cada golpe
	Variacao = 0.25,      -- o dano varia 25% para mais ou para menos
	ChanceCritico = 0.15, -- 15% de chance de crítico
	MultCritico = 2.5,    -- crítico causa 2,5x o dano
	Alcance = 8,          -- distância para conseguir bater
	Intervalo = 0.5,      -- segundos entre golpes
}

Config.Fases = {
	{
		nome = "1-1", monstro = "Gosma Verde", forma = "bola",
		vida = 30, ouro = 2, tamanho = 3,
		cor = Color3.fromRGB(90, 210, 110), chao = Color3.fromRGB(105, 150, 85),
	},
	{
		nome = "1-2", monstro = "Cogumelo Bravo", forma = "cogumelo",
		vida = 60, ouro = 4, tamanho = 3.6,
		cor = Color3.fromRGB(215, 95, 70), chao = Color3.fromRGB(125, 110, 80),
	},
	{
		nome = "1-3", monstro = "Lobo de Pedra", forma = "bloco",
		vida = 110, ouro = 7, tamanho = 4.4,
		cor = Color3.fromRGB(140, 145, 170), chao = Color3.fromRGB(90, 92, 108),
	},
}

return Config
