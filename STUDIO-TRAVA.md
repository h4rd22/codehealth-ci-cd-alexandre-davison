# Trava do Roblox Studio (todas as sessões)

Só UMA sessão pode usar o Studio em Play por vez.

1. Antes de dar Play/Stop, leia o arquivo `.studio-trava` nesta pasta.
   - Se existir e tiver menos de 15 minutos (veja a hora escrita nele), o Studio está ocupado: espere e faça outra coisa (código, lint).
   - Se não existir (ou estiver velho, mais de 15 min), crie/sobrescreva com: `nome-da-sessao hora-ISO` (ex.: `jorge 2026-11-17T18:30`).
2. Use o Studio (máximo ~10 minutos por vez).
3. Ao terminar: dê Stop e APAGUE o arquivo `.studio-trava`.

Nunca dê Stop num Play que você não começou se a trava for de outra sessão.
