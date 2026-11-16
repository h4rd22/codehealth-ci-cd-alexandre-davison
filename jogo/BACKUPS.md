# Backups do jogo

Todo o código do jogo fica nesta pasta (`jogo/`), guardado no Git e no GitHub.

## Como funciona
- **Cada mudança vira um commit.** Um commit é um ponto de restauração com data e descrição do que mudou.
- **Antes de qualquer mudança grande** é criada uma marca (tag) `backup-AAAA-MM-DD-descricao`. Dá pra voltar o jogo inteiro para ela.
- **Cada versão publicada no Roblox** ganha uma tag `versao-X.Y`, igual ao que está no ar.
- **O Roblox também guarda versões:** no Roblox Studio, em *File → Game Settings* ou no Creator Hub, em *Version History*, dá pra restaurar uma versão antiga publicada.
- **Os dados dos jogadores (DataStore)** usam uma chave com versão. Mudanças no formato do save nunca apagam o save antigo.

## Para voltar atrás
É só pedir: "volta o jogo para antes de tal mudança". Eu restauro a partir do commit ou da tag certa.
