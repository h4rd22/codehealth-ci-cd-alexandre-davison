--!strict
-- Todos os números do Mistureba ficam aqui. Mude aqui para balancear o jogo.

local Config = {}

------------------------------------------------------------------------
-- Raridades, da mais comum para a mais rara
------------------------------------------------------------------------
Config.OrdemRaridades = { "comum", "raro", "epico", "lendario", "mitico", "secreto" }

Config.Raridades = {
	comum = { nome = "Comum", cor = Color3.fromRGB(200, 200, 200), tamanho = 1.0 },
	raro = { nome = "Raro", cor = Color3.fromRGB(80, 170, 255), tamanho = 1.15 },
	epico = { nome = "Épico", cor = Color3.fromRGB(190, 90, 255), tamanho = 1.3 },
	lendario = { nome = "Lendário", cor = Color3.fromRGB(255, 190, 40), tamanho = 1.5 },
	mitico = { nome = "Mítico", cor = Color3.fromRGB(255, 70, 110), tamanho = 1.7 },
	secreto = { nome = "Secreto", cor = Color3.fromRGB(40, 255, 200), tamanho = 2.0 },
}

------------------------------------------------------------------------
-- As Misturebas: cada uma é a fusão de dois objetos do dia a dia.
-- renda = moedas por segundo enquanto ela está na sua base.
-- corpo/extra = peças simples usadas para montar o modelo (ver Criaturas.luau).
------------------------------------------------------------------------
export type Peca = {
	forma: string, -- "bola", "bloco", "cilindro", "cunha"
	cor: Color3,
	tamanho: Vector3,
	posicao: Vector3?, -- em relação ao centro do corpo
	material: string?,
}

export type Criatura = {
	id: string,
	nome: string,
	raridade: string,
	renda: number,
	descricao: string,
	corpo: Peca,
	extras: { Peca },
	base: string?, -- só nas mutadas: id da Mistureba normal
	mutacao: string?, -- só nas mutadas: id da mutação
}

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

Config.Criaturas = {
	-- Comuns
	{
		id = "chaleiruga",
		nome = "Chaleiruga",
		raridade = "comum",
		renda = 1,
		descricao = "Metade chaleira, metade tartaruga. Apita quando está feliz.",
		corpo = { forma = "bola", cor = c(90, 160, 90), tamanho = Vector3.new(3, 2, 3) },
		extras = {
			{
				forma = "cilindro",
				cor = c(190, 190, 200),
				tamanho = Vector3.new(1.4, 2.2, 2.2),
				posicao = Vector3.new(0, 1.3, 0),
				material = "Metal",
			},
			{
				forma = "cilindro",
				cor = c(190, 190, 200),
				tamanho = Vector3.new(1.6, 0.4, 0.4),
				posicao = Vector3.new(1.4, 1.4, 0),
				material = "Metal",
			},
		},
	},
	{
		id = "tubarone",
		nome = "Tubarone",
		raridade = "comum",
		renda = 2,
		descricao = "Um tubarão que virou tênis de corrida. Muito rápido, pouco nadador.",
		corpo = { forma = "bloco", cor = c(240, 240, 240), tamanho = Vector3.new(3.2, 1.2, 1.6) },
		extras = {
			{
				forma = "cunha",
				cor = c(110, 130, 160),
				tamanho = Vector3.new(0.4, 1.4, 1.2),
				posicao = Vector3.new(0, 1.2, 0),
			},
			{
				forma = "bloco",
				cor = c(255, 60, 60),
				tamanho = Vector3.new(3.3, 0.3, 1.7),
				posicao = Vector3.new(0, -0.7, 0),
			},
		},
	},
	{
		id = "meiaranha",
		nome = "Meiaranha",
		raridade = "comum",
		renda = 2,
		descricao = "Uma meia listrada com oito pernas. Some sempre que você precisa dela.",
		corpo = { forma = "cilindro", cor = c(255, 120, 170), tamanho = Vector3.new(2.6, 1.4, 1.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(0.2, 0.2, 3.6),
				posicao = Vector3.new(0.6, -0.6, 0),
			},
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(0.2, 0.2, 3.6),
				posicao = Vector3.new(-0.6, -0.6, 0),
			},
		},
	},
	{
		id = "pastelossauro",
		nome = "Pastelossauro",
		raridade = "comum",
		renda = 3,
		descricao = "Um dinossauro crocante recheado de queijo.",
		corpo = { forma = "cunha", cor = c(230, 180, 90), tamanho = Vector3.new(2, 1.4, 3) },
		extras = {
			{
				forma = "bloco",
				cor = c(230, 180, 90),
				tamanho = Vector3.new(0.8, 1.6, 0.8),
				posicao = Vector3.new(0, 1.2, 1.2),
			},
		},
	},
	{
		id = "torracoelho",
		nome = "Torracoelho",
		raridade = "comum",
		renda = 4,
		descricao = "Uma torradeira com orelhas. Pula junto com o pão.",
		corpo = { forma = "bloco", cor = c(200, 200, 210), tamanho = Vector3.new(2.4, 2, 1.6), material = "Metal" },
		extras = {
			{
				forma = "bloco",
				cor = c(255, 230, 240),
				tamanho = Vector3.new(0.4, 1.6, 0.3),
				posicao = Vector3.new(0.5, 1.8, 0),
			},
			{
				forma = "bloco",
				cor = c(255, 230, 240),
				tamanho = Vector3.new(0.4, 1.6, 0.3),
				posicao = Vector3.new(-0.5, 1.8, 0),
			},
		},
	},
	-- Raras
	{
		id = "abacataoninja",
		nome = "Abacatão Ninja",
		raridade = "raro",
		renda = 12,
		descricao = "Treinou a vida toda para nunca virar guacamole.",
		corpo = { forma = "bola", cor = c(80, 140, 40), tamanho = Vector3.new(2.2, 3, 2.2) },
		extras = {
			{
				forma = "bola",
				cor = c(120, 70, 30),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(0, -0.2, -0.7),
			},
			{
				forma = "bloco",
				cor = c(20, 20, 20),
				tamanho = Vector3.new(2.3, 0.4, 2.3),
				posicao = Vector3.new(0, 0.7, 0),
			},
		},
	},
	{
		id = "geladeirapirata",
		nome = "Geladeira Pirata",
		raridade = "raro",
		renda = 15,
		descricao = "Guarda tesouros gelados e nunca devolve o pudim.",
		corpo = { forma = "bloco", cor = c(235, 245, 255), tamanho = Vector3.new(2, 3.4, 1.8) },
		extras = {
			{
				forma = "cunha",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(2.6, 0.8, 1.2),
				posicao = Vector3.new(0, 2.1, 0),
			},
			{
				forma = "bola",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(0.6, 0.6, 0.2),
				posicao = Vector3.new(0.4, 0.8, -0.95),
			},
		},
	},
	{
		id = "polvonete",
		nome = "Polvonete",
		raridade = "raro",
		renda = 18,
		descricao = "Um polvo que é também um patinete. Oito rodinhas!",
		corpo = { forma = "bola", cor = c(200, 80, 200), tamanho = Vector3.new(2.4, 2.2, 2.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(3.4, 0.3, 1),
				posicao = Vector3.new(0, -1.3, 0),
			},
			{
				forma = "cilindro",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(0.3, 2.4, 0.3),
				posicao = Vector3.new(1.5, 0, 0),
			},
		},
	},
	{
		id = "escovadragao",
		nome = "Escovadragão",
		raridade = "raro",
		renda = 20,
		descricao = "Cospe pasta de dente em vez de fogo. Hálito de menta garantido.",
		corpo = { forma = "bloco", cor = c(60, 180, 255), tamanho = Vector3.new(3.6, 0.8, 0.8) },
		extras = {
			{
				forma = "bloco",
				cor = c(255, 255, 255),
				tamanho = Vector3.new(1.2, 1, 0.9),
				posicao = Vector3.new(1.4, 0.8, 0),
			},
			{
				forma = "cunha",
				cor = c(40, 120, 220),
				tamanho = Vector3.new(0.3, 1.4, 1.6),
				posicao = Vector3.new(-0.6, 0.9, 0),
			},
		},
	},
	-- Épicas
	{
		id = "sofassauro",
		nome = "Sofássauro",
		raridade = "epico",
		renda = 60,
		descricao = "Um T-rex em forma de sofá. Confortável, mas morde se você sentar errado.",
		corpo = { forma = "bloco", cor = c(170, 60, 50), tamanho = Vector3.new(3.4, 1.2, 1.8), material = "Fabric" },
		extras = {
			{
				forma = "bloco",
				cor = c(170, 60, 50),
				tamanho = Vector3.new(3.4, 1.6, 0.5),
				posicao = Vector3.new(0, 1.2, 0.7),
				material = "Fabric",
			},
			{
				forma = "cunha",
				cor = c(80, 160, 70),
				tamanho = Vector3.new(1, 1.2, 1.4),
				posicao = Vector3.new(1.9, 1.4, 0),
			},
		},
	},
	{
		id = "pianoceronte",
		nome = "Pianoceronte",
		raridade = "epico",
		renda = 75,
		descricao = "Toca uma nota grave a cada passo. O chão treme no ritmo.",
		corpo = { forma = "bloco", cor = c(25, 25, 30), tamanho = Vector3.new(3.4, 2, 2), material = "SmoothPlastic" },
		extras = {
			{
				forma = "bloco",
				cor = c(250, 250, 250),
				tamanho = Vector3.new(3, 0.3, 0.6),
				posicao = Vector3.new(0, 0.4, -1.2),
			},
			{
				forma = "cunha",
				cor = c(220, 220, 200),
				tamanho = Vector3.new(0.5, 1.2, 0.8),
				posicao = Vector3.new(0, 1.4, -1.1),
			},
		},
	},
	{
		id = "guardachuvalo",
		nome = "Guarda-Chuvalo",
		raridade = "epico",
		renda = 80,
		descricao = "Um cavalo que abre quando chove. Ótimo para passeios molhados.",
		corpo = { forma = "bloco", cor = c(150, 100, 60), tamanho = Vector3.new(3, 1.6, 1.2) },
		extras = {
			{
				forma = "cilindro",
				cor = c(80, 80, 255),
				tamanho = Vector3.new(0.4, 4, 4),
				posicao = Vector3.new(0, 2.4, 0),
			},
			{
				forma = "cilindro",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(2, 0.2, 0.2),
				posicao = Vector3.new(0, 1.4, 0),
			},
		},
	},
	{
		id = "liquidificorvo",
		nome = "Liquidificorvo",
		raridade = "epico",
		renda = 90,
		descricao = "Bate vitamina e dá conselhos misteriosos. Croc-croc-vrrrum!",
		corpo = { forma = "cilindro", cor = c(180, 230, 255), tamanho = Vector3.new(2.8, 1.8, 1.8), material = "Glass" },
		extras = {
			{
				forma = "bola",
				cor = c(30, 30, 40),
				tamanho = Vector3.new(1.6, 1.6, 1.6),
				posicao = Vector3.new(0, 1.9, 0),
			},
			{
				forma = "cunha",
				cor = c(255, 200, 40),
				tamanho = Vector3.new(0.4, 0.5, 0.9),
				posicao = Vector3.new(0, 1.9, -1.1),
			},
		},
	},
	-- Lendárias
	{
		id = "microleao",
		nome = "Micro-Leão",
		raridade = "lendario",
		renda = 300,
		descricao = "Um leão-micro-ondas. Esquenta a comida com um rugido de 30 segundos.",
		corpo = { forma = "bloco", cor = c(220, 220, 230), tamanho = Vector3.new(3, 2, 2), material = "Metal" },
		extras = {
			{
				forma = "bola",
				cor = c(230, 140, 30),
				tamanho = Vector3.new(3.4, 3.4, 1),
				posicao = Vector3.new(0, 0.6, -1),
			},
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(1.6, 1.2, 0.2),
				posicao = Vector3.new(0, 0, -1.6),
				material = "Glass",
			},
		},
	},
	{
		id = "baleiastelo",
		nome = "Baleiastelo",
		raridade = "lendario",
		renda = 400,
		descricao = "Uma baleia que carrega um castelo de areia nas costas. A maré nunca o derruba.",
		corpo = { forma = "bola", cor = c(60, 100, 200), tamanho = Vector3.new(4, 2.2, 2.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(240, 210, 140),
				tamanho = Vector3.new(1.6, 1.8, 1.6),
				posicao = Vector3.new(0, 1.8, 0),
				material = "Sand",
			},
			{
				forma = "cunha",
				cor = c(240, 210, 140),
				tamanho = Vector3.new(1.6, 0.8, 1.6),
				posicao = Vector3.new(0, 3.1, 0),
				material = "Sand",
			},
		},
	},
	{
		id = "girafatrem",
		nome = "Girafatrem",
		raridade = "lendario",
		renda = 500,
		descricao = "Pescoço de girafa, corpo de trem. Sempre chega na hora, e vê tudo de cima.",
		corpo = { forma = "bloco", cor = c(240, 200, 60), tamanho = Vector3.new(3.6, 1.6, 1.6) },
		extras = {
			{
				forma = "bloco",
				cor = c(240, 200, 60),
				tamanho = Vector3.new(0.6, 3.4, 0.6),
				posicao = Vector3.new(1.4, 2.4, 0),
			},
			{
				forma = "cilindro",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(0.4, 1.2, 1.2),
				posicao = Vector3.new(-1, -0.8, 0.85),
			},
		},
	},
	-- Míticas
	{
		id = "pinguivulcao",
		nome = "Pinguivulcão",
		raridade = "mitico",
		renda = 2000,
		descricao = "Um pinguim com um vulcão na cabeça. Gelado por fora, fervendo por dentro.",
		corpo = { forma = "bola", cor = c(30, 30, 40), tamanho = Vector3.new(2.4, 3.2, 2.4) },
		extras = {
			{
				forma = "bola",
				cor = c(250, 250, 250),
				tamanho = Vector3.new(1.8, 2.4, 0.8),
				posicao = Vector3.new(0, -0.2, -0.9),
			},
			{
				forma = "cunha",
				cor = c(255, 90, 20),
				tamanho = Vector3.new(1.6, 1.4, 1.6),
				posicao = Vector3.new(0, 2.2, 0),
				material = "Neon",
			},
		},
	},
	{
		id = "nuvemcornio",
		nome = "Nuvemcórnio",
		raridade = "mitico",
		renda = 2500,
		descricao = "Uma nuvem de chifre brilhante. Chove purpurina onde passa.",
		corpo = { forma = "bola", cor = c(250, 250, 255), tamanho = Vector3.new(4, 2.4, 2.6) },
		extras = {
			{
				forma = "cunha",
				cor = c(255, 120, 220),
				tamanho = Vector3.new(0.5, 1.8, 0.5),
				posicao = Vector3.new(0, 1.8, -0.8),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(220, 230, 255),
				tamanho = Vector3.new(2, 1.6, 2),
				posicao = Vector3.new(1.4, 0.4, 0),
			},
		},
	},
	-- Secretas (só por receita de fusão)
	{
		id = "reimistureba",
		nome = "Rei Mistureba",
		raridade = "secreto",
		renda = 10000,
		descricao = "O rei de todas as misturas. Ninguém sabe do que ele é feito.",
		corpo = { forma = "bola", cor = c(255, 210, 40), tamanho = Vector3.new(3.2, 3.2, 3.2), material = "Neon" },
		extras = {
			{
				forma = "cilindro",
				cor = c(255, 230, 80),
				tamanho = Vector3.new(1, 2.6, 2.6),
				posicao = Vector3.new(0, 2.2, 0),
				material = "Metal",
			},
			{
				forma = "bola",
				cor = c(255, 40, 80),
				tamanho = Vector3.new(0.6, 0.6, 0.6),
				posicao = Vector3.new(0, 2.8, -1),
				material = "Neon",
			},
		},
	},
	{
		id = "bugigangacosmica",
		nome = "Bugiganga Cósmica",
		raridade = "secreto",
		renda = 15000,
		descricao = "Uma caixinha de peças que brilha como uma galáxia. Ainda está se montando.",
		corpo = { forma = "bloco", cor = c(40, 20, 90), tamanho = Vector3.new(3, 3, 3), material = "Neon" },
		extras = {
			{
				forma = "bola",
				cor = c(120, 220, 255),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(1.8, 1.8, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 120, 255),
				tamanho = Vector3.new(1, 1, 1),
				posicao = Vector3.new(-1.8, 1.8, 0),
				material = "Neon",
			},
		},
	},
	{
		id = "lapisquilo",
		nome = "Lapisquilo",
		raridade = "comum",
		renda = 3,
		descricao = "Um esquilo que é um lápis. Escreve recados nas árvores.",
		corpo = { forma = "cilindro", cor = c(250, 200, 60), tamanho = Vector3.new(3, 1.2, 1.2) },
		extras = {
			{
				forma = "cunha",
				cor = c(240, 200, 160),
				tamanho = Vector3.new(0.8, 0.8, 1),
				posicao = Vector3.new(0, 0, -1.8),
			},
			{
				forma = "bola",
				cor = c(160, 100, 60),
				tamanho = Vector3.new(1.2, 1.8, 1.2),
				posicao = Vector3.new(0, 1, 1.4),
			},
		},
	},
	{
		id = "bolachorro",
		nome = "Bolachorro",
		raridade = "comum",
		renda = 3,
		descricao = "Um cachorro de bolacha recheada. Late quando alguém come farelo.",
		corpo = { forma = "cilindro", cor = c(190, 120, 70), tamanho = Vector3.new(0.9, 2.6, 2.6) },
		extras = {
			{ forma = "cilindro", cor = c(255, 250, 240), tamanho = Vector3.new(0.95, 2.2, 2.2) },
			{
				forma = "bola",
				cor = c(150, 90, 50),
				tamanho = Vector3.new(0.6, 1, 0.4),
				posicao = Vector3.new(1, 1.1, 0),
			},
			{
				forma = "bola",
				cor = c(150, 90, 50),
				tamanho = Vector3.new(0.6, 1, 0.4),
				posicao = Vector3.new(-1, 1.1, 0),
			},
		},
	},
	{
		id = "chinelefante",
		nome = "Chinelefante",
		raridade = "comum",
		renda = 4,
		descricao = "Um elefante que virou chinelo. Faz plof plof quando anda.",
		corpo = { forma = "bloco", cor = c(120, 190, 255), tamanho = Vector3.new(1.8, 0.5, 3.4) },
		extras = {
			{
				forma = "bola",
				cor = c(170, 170, 190),
				tamanho = Vector3.new(2, 1.8, 1.8),
				posicao = Vector3.new(0, 1.1, 0),
			},
			{
				forma = "cilindro",
				cor = c(170, 170, 190),
				tamanho = Vector3.new(1.6, 0.5, 0.5),
				posicao = Vector3.new(0, 0.8, -1.2),
			},
		},
	},
	{
		id = "cenourato",
		nome = "Cenourato",
		raridade = "comum",
		renda = 4,
		descricao = "Um ratinho cenoura que guarda tudo debaixo da terra.",
		corpo = { forma = "cunha", cor = c(255, 140, 40), tamanho = Vector3.new(1.6, 1.6, 2.6) },
		extras = {
			{
				forma = "bola",
				cor = c(80, 200, 80),
				tamanho = Vector3.new(1, 1.2, 1),
				posicao = Vector3.new(0, 1.2, 0.8),
			},
			{
				forma = "bola",
				cor = c(230, 230, 230),
				tamanho = Vector3.new(0.8, 0.8, 0.3),
				posicao = Vector3.new(0.6, 1, -0.6),
			},
			{
				forma = "bola",
				cor = c(230, 230, 230),
				tamanho = Vector3.new(0.8, 0.8, 0.3),
				posicao = Vector3.new(-0.6, 1, -0.6),
			},
		},
	},
	{
		id = "abajurubu",
		nome = "Abajurubu",
		raridade = "comum",
		renda = 5,
		descricao = "Um urubu abajur que acende quando fica com medo do escuro.",
		corpo = { forma = "bola", cor = c(60, 60, 70), tamanho = Vector3.new(2.2, 2, 2.2) },
		extras = {
			{
				forma = "cilindro",
				cor = c(255, 240, 150),
				tamanho = Vector3.new(1.6, 2, 2),
				posicao = Vector3.new(0, 1.6, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 200, 80),
				tamanho = Vector3.new(0.5, 0.4, 0.6),
				posicao = Vector3.new(0, 0.2, -1.2),
			},
		},
	},
	{
		id = "sorvetigre",
		nome = "Sorvetigre",
		raridade = "raro",
		renda = 22,
		descricao = "Um tigre de sorvete de três sabores. Ruge e derrete.",
		corpo = { forma = "cunha", cor = c(230, 190, 120), tamanho = Vector3.new(1.6, 2.4, 1.6) },
		extras = {
			{
				forma = "bola",
				cor = c(255, 170, 60),
				tamanho = Vector3.new(2, 1.8, 2),
				posicao = Vector3.new(0, 1.6, 0),
			},
			{
				forma = "bola",
				cor = c(255, 220, 240),
				tamanho = Vector3.new(1.6, 1.4, 1.6),
				posicao = Vector3.new(0, 2.8, 0),
			},
			{
				forma = "bola",
				cor = c(140, 90, 60),
				tamanho = Vector3.new(1.2, 1, 1.2),
				posicao = Vector3.new(0, 3.7, 0),
			},
		},
	},
	{
		id = "relocoruja",
		nome = "Relocoruja",
		raridade = "raro",
		renda = 25,
		descricao = "Uma coruja relógio que nunca deixa você perder a hora do lanche.",
		corpo = { forma = "bola", cor = c(140, 100, 70), tamanho = Vector3.new(2.4, 2.6, 2) },
		extras = {
			{
				forma = "cilindro",
				cor = c(255, 255, 240),
				tamanho = Vector3.new(0.3, 1.8, 1.8),
				posicao = Vector3.new(0, 0.3, -1),
			},
			{
				forma = "bloco",
				cor = c(140, 100, 70),
				tamanho = Vector3.new(0.4, 0.8, 0.4),
				posicao = Vector3.new(0.7, 1.5, 0),
			},
			{
				forma = "bloco",
				cor = c(140, 100, 70),
				tamanho = Vector3.new(0.4, 0.8, 0.4),
				posicao = Vector3.new(-0.7, 1.5, 0),
			},
		},
	},
	{
		id = "mochilontra",
		nome = "Mochilontra",
		raridade = "raro",
		renda = 28,
		descricao = "Uma lontra mochila. Leva seus lanches e boia na piscina.",
		corpo = { forma = "bloco", cor = c(60, 140, 255), tamanho = Vector3.new(2.2, 2.6, 1.4) },
		extras = {
			{
				forma = "bola",
				cor = c(150, 100, 60),
				tamanho = Vector3.new(1.6, 1.4, 1.4),
				posicao = Vector3.new(0, 1.8, 0),
			},
			{
				forma = "bloco",
				cor = c(255, 200, 50),
				tamanho = Vector3.new(1.6, 0.8, 0.3),
				posicao = Vector3.new(0, -0.3, -0.8),
			},
		},
	},
	{
		id = "patinepato",
		nome = "Patinepato",
		raridade = "raro",
		renda = 30,
		descricao = "Um pato de patinete que buzina quac pelas ruas.",
		corpo = { forma = "bola", cor = c(255, 230, 60), tamanho = Vector3.new(2, 1.8, 2) },
		extras = {
			{
				forma = "cunha",
				cor = c(255, 140, 30),
				tamanho = Vector3.new(0.8, 0.4, 0.8),
				posicao = Vector3.new(0, 0.2, -1.3),
			},
			{
				forma = "bloco",
				cor = c(200, 60, 60),
				tamanho = Vector3.new(0.6, 0.3, 3.6),
				posicao = Vector3.new(0, -1.2, 0),
			},
			{
				forma = "cilindro",
				cor = c(80, 80, 80),
				tamanho = Vector3.new(0.4, 2.4, 0.4),
				posicao = Vector3.new(0, 0.4, -1.6),
			},
		},
	},
	{
		id = "cupcameleao",
		nome = "Cupcameleão",
		raridade = "raro",
		renda = 35,
		descricao = "Um camaleão cupcake que muda a cor da cobertura.",
		corpo = { forma = "cilindro", cor = c(255, 120, 170), tamanho = Vector3.new(1.6, 2.2, 2.2) },
		extras = {
			{
				forma = "bola",
				cor = c(120, 230, 140),
				tamanho = Vector3.new(2.4, 1.6, 2.4),
				posicao = Vector3.new(0, 1.4, 0),
			},
			{
				forma = "bola",
				cor = c(255, 60, 60),
				tamanho = Vector3.new(0.6, 0.6, 0.6),
				posicao = Vector3.new(0, 2.4, 0),
			},
		},
	},
	{
		id = "robelha",
		nome = "Robelha",
		raridade = "epico",
		renda = 100,
		descricao = "Uma abelha robô que faz mel de óleo... e de chocolate.",
		corpo = { forma = "bola", cor = c(255, 210, 40), tamanho = Vector3.new(2.4, 2.2, 2.8), material = "Metal" },
		extras = {
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(2.5, 0.4, 2.9),
				posicao = Vector3.new(0, 0, 0),
			},
			{
				forma = "bloco",
				cor = c(190, 230, 255),
				tamanho = Vector3.new(0.2, 1.4, 1.6),
				posicao = Vector3.new(1.3, 1.2, 0),
				material = "Glass",
			},
			{
				forma = "bloco",
				cor = c(190, 230, 255),
				tamanho = Vector3.new(0.2, 1.4, 1.6),
				posicao = Vector3.new(-1.3, 1.2, 0),
				material = "Glass",
			},
		},
	},
	{
		id = "televisapo",
		nome = "Televisapo",
		raridade = "epico",
		renda = 115,
		descricao = "Um sapo televisão que só passa desenho.",
		corpo = { forma = "bloco", cor = c(60, 60, 70), tamanho = Vector3.new(3, 2.2, 1.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(120, 255, 160),
				tamanho = Vector3.new(2.4, 1.6, 0.2),
				posicao = Vector3.new(0, 0, -0.7),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(80, 200, 90),
				tamanho = Vector3.new(0.9, 0.9, 0.9),
				posicao = Vector3.new(0.8, 1.4, -0.2),
			},
			{
				forma = "bola",
				cor = c(80, 200, 90),
				tamanho = Vector3.new(0.9, 0.9, 0.9),
				posicao = Vector3.new(-0.8, 1.4, -0.2),
			},
		},
	},
	{
		id = "foguetucano",
		nome = "Foguetucano",
		raridade = "epico",
		renda = 130,
		descricao = "Um tucano foguete que vai e volta da Lua no recreio.",
		corpo = { forma = "cilindro", cor = c(240, 240, 250), tamanho = Vector3.new(3.2, 1.6, 1.6), material = "Metal" },
		extras = {
			{
				forma = "cunha",
				cor = c(255, 150, 30),
				tamanho = Vector3.new(1, 1, 1.8),
				posicao = Vector3.new(0, 0, -2),
			},
			{
				forma = "bola",
				cor = c(255, 90, 40),
				tamanho = Vector3.new(0.8, 0.8, 0.8),
				posicao = Vector3.new(0, 0, 2),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 60, 60),
				tamanho = Vector3.new(0.2, 1.2, 1),
				posicao = Vector3.new(0, 1.1, 1),
			},
		},
	},
	{
		id = "pipocavalo",
		nome = "Pipocavalo",
		raridade = "epico",
		renda = 150,
		descricao = "Um cavalo de pipoca. Cada galope faz um poc!",
		corpo = { forma = "bloco", cor = c(220, 60, 60), tamanho = Vector3.new(1.8, 2, 2.6) },
		extras = {
			{
				forma = "bola",
				cor = c(255, 250, 220),
				tamanho = Vector3.new(2.2, 1.2, 2.8),
				posicao = Vector3.new(0, 1.5, 0),
			},
			{
				forma = "bola",
				cor = c(255, 250, 220),
				tamanho = Vector3.new(1.2, 1.4, 1.4),
				posicao = Vector3.new(0, 2.2, -1.4),
			},
		},
	},
	{
		id = "castelobo",
		nome = "Castelobo",
		raridade = "lendario",
		renda = 650,
		descricao = "Um lobo castelo que uiva para proteger a vila.",
		corpo = { forma = "bloco", cor = c(180, 180, 190), tamanho = Vector3.new(3, 3, 3), material = "Slate" },
		extras = {
			{
				forma = "bloco",
				cor = c(180, 180, 190),
				tamanho = Vector3.new(1, 1.6, 1),
				posicao = Vector3.new(1, 2.2, 1),
				material = "Slate",
			},
			{
				forma = "bloco",
				cor = c(180, 180, 190),
				tamanho = Vector3.new(1, 1.6, 1),
				posicao = Vector3.new(-1, 2.2, 1),
				material = "Slate",
			},
			{
				forma = "cunha",
				cor = c(90, 90, 110),
				tamanho = Vector3.new(0.8, 1.2, 0.6),
				posicao = Vector3.new(0.8, 2, -1.2),
			},
			{
				forma = "cunha",
				cor = c(90, 90, 110),
				tamanho = Vector3.new(0.8, 1.2, 0.6),
				posicao = Vector3.new(-0.8, 2, -1.2),
			},
		},
	},
	{
		id = "trovanguru",
		nome = "Trovanguru",
		raridade = "lendario",
		renda = 750,
		descricao = "Um canguru de trovão. Pula e faz o céu brilhar.",
		corpo = { forma = "bola", cor = c(255, 220, 60), tamanho = Vector3.new(2.4, 3, 2.2) },
		extras = {
			{
				forma = "cunha",
				cor = c(255, 255, 120),
				tamanho = Vector3.new(0.6, 2, 1),
				posicao = Vector3.new(1.4, 1.4, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 255, 120),
				tamanho = Vector3.new(0.6, 2, 1),
				posicao = Vector3.new(-1.4, 1.4, 0),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(255, 240, 180),
				tamanho = Vector3.new(1.4, 1.2, 0.8),
				posicao = Vector3.new(0, -0.2, -0.9),
			},
		},
	},
	{
		id = "aquariorca",
		nome = "Aquariorca",
		raridade = "lendario",
		renda = 900,
		descricao = "Uma orca que mora dentro de um aquário... que é ela mesma.",
		corpo = { forma = "bloco", cor = c(150, 220, 255), tamanho = Vector3.new(3.6, 2.4, 2), material = "Glass" },
		extras = {
			{ forma = "bola", cor = c(30, 30, 40), tamanho = Vector3.new(2.6, 1.6, 1.4) },
			{
				forma = "bola",
				cor = c(255, 255, 255),
				tamanho = Vector3.new(1, 0.6, 0.5),
				posicao = Vector3.new(0.6, 0.2, -0.6),
			},
			{
				forma = "cunha",
				cor = c(30, 30, 40),
				tamanho = Vector3.new(0.3, 1.4, 1),
				posicao = Vector3.new(0, 1.6, 0),
			},
		},
	},
	{
		id = "fenixicara",
		nome = "Fenixícara",
		raridade = "mitico",
		renda = 3500,
		descricao = "Uma fênix que nasceu de uma xícara de chocolate quente.",
		corpo = { forma = "cilindro", cor = c(255, 255, 255), tamanho = Vector3.new(1.6, 2.4, 2.4) },
		extras = {
			{
				forma = "bola",
				cor = c(255, 120, 40),
				tamanho = Vector3.new(2.2, 2, 2.2),
				posicao = Vector3.new(0, 1.6, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 200, 40),
				tamanho = Vector3.new(0.3, 2, 1.6),
				posicao = Vector3.new(1.6, 1.8, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 200, 40),
				tamanho = Vector3.new(0.3, 2, 1.6),
				posicao = Vector3.new(-1.6, 1.8, 0),
				material = "Neon",
			},
		},
	},
	{
		id = "dragalaxia",
		nome = "Dragaláxia",
		raridade = "mitico",
		renda = 4500,
		descricao = "Um dragão feito de estrelas. Cada escama é um planetinha.",
		corpo = { forma = "bola", cor = c(70, 40, 140), tamanho = Vector3.new(3, 2.6, 3.6), material = "Neon" },
		extras = {
			{
				forma = "bola",
				cor = c(255, 255, 255),
				tamanho = Vector3.new(0.5, 0.5, 0.5),
				posicao = Vector3.new(1, 1, 0),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(255, 220, 120),
				tamanho = Vector3.new(0.6, 0.6, 0.6),
				posicao = Vector3.new(-1, 0.6, 1),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(140, 90, 255),
				tamanho = Vector3.new(0.3, 2.2, 2),
				posicao = Vector3.new(1.8, 1.4, 0),
			},
			{
				forma = "cunha",
				cor = c(140, 90, 255),
				tamanho = Vector3.new(0.3, 2.2, 2),
				posicao = Vector3.new(-1.8, 1.4, 0),
			},
		},
	},
	{
		id = "misturebasuprema",
		nome = "Mistureba Suprema",
		raridade = "secreto",
		renda = 25000,
		descricao = "Só nasce da fusão de Fenixícara com Dragaláxia. Ninguém sabe do que ela é feita.",
		corpo = { forma = "bola", cor = c(255, 255, 255), tamanho = Vector3.new(3.6, 3.6, 3.6), material = "Neon" },
		extras = {
			{
				forma = "bola",
				cor = c(255, 120, 230),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(2.2, 1.6, 0),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(120, 230, 255),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(-2.2, 1.6, 0),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(255, 230, 90),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(0, 2.6, 0),
				material = "Neon",
			},
		},
	},
} :: { Criatura }

-- Atalho: Config.PorId["chaleiruga"]
local normais: { [string]: Criatura } = {}
for _, criatura in Config.Criaturas do
	normais[criatura.id] = criatura
end

------------------------------------------------------------------------
-- Mutações: ao chocar um ovo, a Mistureba pode nascer especial e render mais.
-- As chances aparecem na tela (painel de ovos e loja).
-- Guardada no perfil como "id*mutacao", ex.: "tubarone*dourada".
------------------------------------------------------------------------
export type Mutacao = {
	id: string,
	nome: string,
	multiplicador: number,
	chance: number, -- em %, por ovo chocado
	cor: Color3,
	material: string,
}

Config.Mutacoes = {
	{
		id = "dourada",
		nome = "Dourada",
		multiplicador = 2,
		chance = 6,
		cor = c(255, 205, 50),
		material = "Foil",
	},
	{
		id = "diamante",
		nome = "Diamante",
		multiplicador = 3,
		chance = 2,
		cor = c(140, 230, 255),
		material = "Glass",
	},
	{
		id = "arcoiris",
		nome = "Arco-íris",
		multiplicador = 5,
		chance = 0.5,
		cor = c(255, 120, 230),
		material = "Neon",
	},
} :: { Mutacao }

Config.MutacaoPorId = {} :: { [string]: Mutacao }
for _, m in Config.Mutacoes do
	Config.MutacaoPorId[m.id] = m
end

-- Config.PorId["tubarone"] é a normal; Config.PorId["tubarone*dourada"] é montada
-- na hora (e guardada) com nome e renda da mutação.
Config.PorId = setmetatable({}, {
	__index = function(cache: any, chave: any): Criatura?
		if type(chave) ~= "string" then
			return nil
		end
		local normal = normais[chave]
		if normal then
			return normal
		end
		local idBase, idMut = string.match(chave, "^([%w_]+)%*([%w_]+)$")
		local def = idBase and normais[idBase]
		local mut = idMut and Config.MutacaoPorId[idMut]
		if not def or not mut then
			return nil
		end
		local mutada: Criatura = {
			id = chave,
			nome = def.nome .. " " .. mut.nome,
			raridade = def.raridade,
			renda = def.renda * mut.multiplicador,
			descricao = def.descricao,
			corpo = def.corpo,
			extras = def.extras,
			base = def.id,
			mutacao = mut.id,
		}
		rawset(cache, chave, mutada)
		return mutada
	end,
}) :: any

------------------------------------------------------------------------
-- Chuva de ovos no centro do mapa
------------------------------------------------------------------------
Config.Chuva = {
	intervalo = 20, -- segundos entre uma onda e outra
	ovosPorOnda = 8,
	maxOvosNoChao = 20,
	tempoNoChao = 60, -- segundos até o ovo sumir se ninguém pegar
	pesos = { comum = 70, raro = 22, epico = 6.5, lendario = 1.3, mitico = 0.2 },
	anunciarAPartirDe = "lendario", -- ovos desta raridade em diante viram ovo dourado com anúncio
}

------------------------------------------------------------------------
-- Ovos da loja de moedas. As chances aparecem na tela antes de comprar.
------------------------------------------------------------------------
export type OvoLoja = {
	id: string,
	nome: string,
	preco: number,
	pesos: { [string]: number },
}

Config.OvosLoja = {
	{ id = "basico", nome = "Ovo Básico", preco = 300, pesos = { comum = 75, raro = 22, epico = 3 } },
	{ id = "doce", nome = "Ovo Doce", preco = 2500, pesos = { comum = 45, raro = 45, epico = 10 } },
	{ id = "brilhante", nome = "Ovo Brilhante", preco = 15000, pesos = { raro = 60, epico = 35, lendario = 5 } },
	{ id = "estelar", nome = "Ovo Estelar", preco = 750000, pesos = { epico = 60, lendario = 35, mitico = 5 } },
	{ id = "cosmico", nome = "Ovo Cósmico", preco = 10000000, pesos = { lendario = 70, mitico = 30 } },
} :: { OvoLoja }

------------------------------------------------------------------------
-- Fusão: duas Misturebas da mesma raridade viram uma da raridade seguinte.
-- As secretas só saem por receita.
------------------------------------------------------------------------
Config.CustoFusao = { comum = 100, raro = 5000, epico = 60000, lendario = 2000000, mitico = 8000000 }

Config.Receitas = {
	{ a = "pinguivulcao", b = "nuvemcornio", resultado = "reimistureba" },
	{ a = "baleiastelo", b = "girafatrem", resultado = "bugigangacosmica" },
	{ a = "fenixicara", b = "dragalaxia", resultado = "misturebasuprema" },
}

------------------------------------------------------------------------
-- Base, cadeado e roubo
------------------------------------------------------------------------
Config.Base = {
	vagasIniciais = 8,
	vagasMaximo = 16, -- sem contar o gamepass
	melhorias = { 1000, 10000, 100000, 1000000 }, -- cada uma dá +2 vagas
	vagasPorMelhoria = 2,
	cadeadoSegundos = 60,
	cadeadoEsperaSegundos = 45, -- depois que abre, quanto tempo até poder trancar de novo
	protecaoNovatoSegundos = 120, -- quem acabou de entrar não pode ser roubado
	minimoParaSerRoubado = 3, -- quem tem menos que isso não pode ser roubado
}

Config.Jogador = {
	velocidade = 18,
	velocidadeCarregando = 12,
	alcanceTapa = 9,
	esperaTapa = 1.2, -- espera entre uma bolha e outra
	tempoNaBolha = 1.5, -- quanto tempo o alvo fica preso na bolha
	imuneDepoisDaBolha = 2.5, -- depois de sair da bolha, não pode ser preso de novo por este tempo
	tempoParaRoubar = 1.5, -- segurar o botão
}

------------------------------------------------------------------------
-- Robux. Os IDs ficam 0 até serem criados no Creator Hub (é grátis criar).
-- Com ID 0 o botão aparece como "em breve".
------------------------------------------------------------------------
Config.Gamepasses = {
	vip = {
		id = 2092768901,
		nome = "VIP",
		preco = 299,
		descricao = "Dobro de moedas para sempre e nome dourado.",
	},
	cadeado = {
		id = 2094556849,
		nome = "Cadeado Reforçado",
		preco = 149,
		descricao = "Sua porta fica trancada 90 segundos em vez de 60.",
	},
	mochila = {
		id = 2097130741,
		nome = "Mochila Dupla",
		preco = 199,
		descricao = "Carregue 2 ovos da chuva de uma vez.",
	},
	basegrande = {
		id = 2092240913,
		nome = "Base Grande",
		preco = 149,
		descricao = "+4 vagas na sua base.",
	},
	sortedupla = {
		id = 2093243022,
		nome = "Sorte Dupla",
		preco = 249,
		descricao = "Mutações saem 2x mais nos ovos que VOCÊ choca.",
	},
	rapido = {
		id = 2092673039,
		nome = "Super Velocidade",
		preco = 99,
		descricao = "Corre 40% mais rápido, até carregando ovos.",
	},
}

Config.VipMultiplicador = 2
Config.CadeadoReforcadoSegundos = 90
Config.BaseGrandeVagas = 4
Config.SorteDuplaMutacao = 2
Config.RapidoMultiplicador = 1.4

Config.Produtos = {
	sorte = {
		id = 3733959362,
		nome = "Sorte do Servidor",
		preco = 79,
		descricao = "Ovos raros caem 2x mais para TODO o servidor por 15 minutos.",
	},
	ovoarcoiris = {
		id = 3733959440,
		nome = "Ovo Arco-íris",
		preco = 49,
		descricao = "Um ovo pago. As chances estão logo abaixo.",
	},
	moedas = {
		id = 3733959502,
		nome = "Saco de Moedas",
		preco = 25,
		descricao = "Ganha 10 minutos da sua renda atual (mínimo 500 moedas).",
	},
	presente = {
		id = 3733965774,
		nome = "Presente Agora",
		preco = 19,
		descricao = "Abre agora o seu próximo presente por tempo jogando.",
	},
}

-- Presente por tempo jogando: um ovo de graça a cada 5 minutos online,
-- e a cada 3 presentes vem um Ovo Brilhante.
Config.PresenteTempo = {
	intervalo = 300,
	ovo = "basico",
	especialACada = 3,
	ovoEspecial = "brilhante",
}

Config.SorteMinutos = 15
Config.SorteMultiplicadorRaros = 2
Config.OvoArcoIrisPesos = { epico = 55, lendario = 38, mitico = 7 }
Config.SacoMoedasMinutos = 10
Config.SacoMoedasMinimo = 500

------------------------------------------------------------------------
-- Coisas que fazem voltar todo dia
------------------------------------------------------------------------
-- Renascer: zera moedas e Misturebas, mas a renda fica maior para sempre.
Config.Renascer = {
	precoBase = 100000000, -- moedas para o 1º renascimento
	crescimento = 4, -- cada renascimento custa 4x o anterior
	bonusPorRenascimento = 0.5, -- +50% de renda por renascimento
}

-- Ganhos enquanto está fora do jogo
Config.Offline = { maxHoras = 2, porcento = 0.3 }

-- Prêmio por dias seguidos entrando (depois do 7º dia, recomeça no 1º)
Config.PremioDiario = {
	{ moedas = 300 },
	{ moedas = 800 },
	{ moedas = 2000 },
	{ ovo = "basico" },
	{ moedas = 6000 },
	{ moedas = 12000 },
	{ ovo = "brilhante" },
}

-- Misturedex: achar uma Mistureba nova pela primeira vez dá este tanto de segundos da renda dela
Config.PremioDescobertaSegundos = 120

-- Marcos da Misturedex: quanto mais Misturebas diferentes, mais renda para sempre.
-- Vale o maior marco alcançado.
Config.MarcosDex = {
	{ achadas = 5, bonus = 0.1 },
	{ achadas = 10, bonus = 0.25 },
	{ achadas = 20, bonus = 0.5 },
	{ achadas = 30, bonus = 0.75 },
	{ achadas = 40, bonus = 1 },
}

-- Vender uma Mistureba dá este tanto de segundos da renda dela.
-- Tem que ser bem menos que o preço do ovo, senão comprar e vender vira máquina de moedas.
Config.VendaSegundos = 15

-- Roleta grátis: um giro a cada 10 minutos jogando. As chances aparecem na tela.
export type PremioRoleta = {
	nome: string,
	peso: number,
	cor: Color3,
	segundos: number?, -- prêmio em moedas = segundos da sua renda
	minimo: number?,
	ovo: string?, -- ou um ovo da loja
}
Config.Roleta = {
	intervalo = 600,
	premios = {
		{ nome = "1 min de moedas", segundos = 60, minimo = 300, peso = 30, cor = c(255, 220, 80) },
		{ nome = "Ovo Básico", ovo = "basico", peso = 20, cor = c(200, 200, 200) },
		{ nome = "3 min de moedas", segundos = 180, minimo = 800, peso = 18, cor = c(255, 170, 60) },
		{ nome = "Ovo Doce", ovo = "doce", peso = 15, cor = c(255, 140, 200) },
		{ nome = "Ovo Brilhante", ovo = "brilhante", peso = 9, cor = c(80, 170, 255) },
		{ nome = "10 min de moedas", segundos = 600, minimo = 3000, peso = 6, cor = c(120, 255, 120) },
		{ nome = "Ovo Estelar", ovo = "estelar", peso = 2, cor = c(190, 90, 255) },
	} :: { PremioRoleta },
}

-- Missões diárias: 3 por dia (iguais para todo o servidor), trocam à meia-noite UTC.
export type Missao = { tipo: string, meta: number, texto: string }
Config.Missoes = {
	porDia = 3,
	premioSegundos = 180, -- prêmio de cada missão = 3 minutos da sua renda
	premioMinimo = 500,
	ovoFinal = "brilhante", -- completar as 3 dá este ovo
	lista = {
		{ tipo = "ovos", meta = 10, texto = "Choque %d ovos" },
		{ tipo = "ovos", meta = 30, texto = "Choque %d ovos" },
		{ tipo = "chuva", meta = 15, texto = "Pegue %d ovos da chuva" },
		{ tipo = "fusoes", meta = 3, texto = "Faça %d fusões" },
		{ tipo = "roubos", meta = 2, texto = "Roube %d Misturebas" },
		{ tipo = "bolhas", meta = 5, texto = "Prenda %d ladrões numa bolha" },
		{ tipo = "minutos", meta = 15, texto = "Jogue %d minutos" },
		{ tipo = "trancar", meta = 5, texto = "Tranque sua base %d vezes" },
	} :: { Missao },
}

return Config
