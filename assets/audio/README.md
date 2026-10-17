# Trilha original de Horda Sombria

- `menu_theme.wav`: **Antes da noite**, 92 BPM, 16 compassos, cerca de 42 s.
- `game_theme.wav`: **Caçada**, 132 BPM, 16 compassos, cerca de 29 s.

Composições instrumentais criadas para este projeto, com síntese chiptune:
melodia, arpejos, baixo, acordes e percussão. Não usam gravações, samples ou
composições de terceiros. Podem ser usadas e modificadas com o jogo.

O código-fonte das duas composições está em `tools/compose_music.py`.
Para recriar os WAVs, execute `python3 tools/compose_music.py` (biblioteca padrão).
PCM mono, 16 bits, 22050 Hz. Os ecos atravessam a fronteira do loop; o player
repete a faixa inteira e faz transição suave entre menu e partida.

## Efeitos de combate

`revolver.wav`, `shotgun.wav` e `wand.wav` têm timbres distintos para cada arma.
`return_blade.wav`, `grenade_launcher.wav` e `dual_pistols.wav` acrescentam,
respectivamente, um sopro metálico, uma ejeção grave e um disparo curto.
`grenade_blast.wav` é a explosão de 380 ms das granadas. Todos usam a mesma
síntese original, o pool de vozes e o controle de volume dos efeitos.
`enemy_hit.wav` é o impacto curto nos inimigos; `player_hurt.wav` indica dano
sofrido; `shield_block.wav` é o bloqueio cristalino do escudo. Durações de 85 a
320 ms, PCM mono de 16 bits a 22050 Hz, sem loop.

Todos são síntese original do projeto, sem gravações ou samples externos. O
código está em `tools/compose_sfx.py`; execute `python3 tools/compose_sfx.py`
para recriar os arquivos. O volume é independente das músicas. O player usa
até oito vozes e limita impactos de inimigos a um por 75 ms.

`level_up.wav` acrescenta um arpejo curto de 0,55 s à subida de nível, antes
das cartas. Usa a mesma síntese original e obedece ao volume de efeitos.

`reload_start.wav` (160 ms) e `reload_end.wav` (200 ms) são cliques originais de
recarga, sintetizados por `tools/compose_sfx.py` sem samples externos. Usam o
mesmo pool de vozes e o volume de efeitos do combate.
