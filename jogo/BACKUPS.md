# Backups do jogo

Todo o código do jogo fica nesta pasta (`jogo/`), guardado no Git e no GitHub.

## Como funciona
- **Cada mudança vira um commit.** Um commit é um ponto de restauração com data e descrição do que mudou.
- **Antes de qualquer mudança grande** é feito um commit de backup com a mensagem `BACKUP: <descrição>`, e ele é anotado na lista abaixo. Dá pra voltar o jogo inteiro para ele.
- **Cada versão publicada no Roblox** também entra na lista abaixo, com o commit do que está no ar.
- **O Roblox também guarda versões:** no Roblox Studio, em *File → Game Settings* ou no Creator Hub, em *Version History*, dá pra restaurar uma versão antiga publicada.
- **Os dados dos jogadores (DataStore)** usam uma chave com versão. Mudanças no formato do save nunca apagam o save antigo.

## Para voltar atrás
É só pedir: "volta o jogo para antes de tal mudança". Eu restauro a partir do commit certo.

## Lista de pontos de restauração
| Data | O que | Commit |
|---|---|---|
| 2026-11-16 | Início do projeto | primeiro commit desta pasta |
