# Armas da caçadora

A partida começa com uma arma escolhida no menu. São duas páginas de três
cartas, com botões Anteriores e Próximas; nenhum novo buff foi adicionado.
As seis armas usam mira automática, carregador com reserva ilimitada e os
mesmos 22 buffs existentes.

| Arma | Dano base | Intervalo | Carregador | Recarga | Alcance do disparo |
| --- | --- | --- | --- | --- | --- |
| Revólver | 24 | 0,48 s | 6 | 1,2 s | 300 |
| Escopeta | 12 por projétil; cinco por salva | 0,95 s | 2 | 1,6 s | 160 |
| Cajado | 15 | 0,34 s | 8 | 1,8 s | 240 |
| Lâmina do Retorno | 20 por alvo/trecho | 0,75 s | 3 | 1 s | 250 na ida |
| Lança-granadas | 52 por alvo atingido pela explosão | 1,15 s | 3 | 1,65 s | 280 + explosão de raio 60 |
| Pistolas Gêmeas | 9 | 0,14 s | 20 | 1,5 s | 230 |

## Lâmina do Retorno

Atravessa até dois alvos na ida e volta em direção à posição atual da caçadora.
Pode atingir os mesmos alvos novamente na volta, mas apenas uma vez por trecho.
Mover-se muda o caminho de retorno e permite alinhar outro grupo.

Perfuração acrescenta alvos em cada trecho. Ricochetes podem redirecionar a ida,
respeitando o alcance e reduzindo o dano como nos projéteis comuns; o retorno
mantém o dano restante. A lâmina volta ao acabar o alcance, o limite de impactos
ou ao encontrar um obstáculo. No retorno, obstáculos também bloqueiam a lâmina.
Ela desaparece ao chegar perto da caçadora ou após 3,5 s, evitando órfãos no mapa.
Recarga e novas cargas não dependem de esperar a lâmina anterior voltar.

## Lança-granadas

A granada explode ao atingir um inimigo, um obstáculo, o limite de alcance ou
o fim do pavio de 1 s. A explosão usa uma área nativa de raio 60, nunca atinge
a caçadora e aplica dano uma única vez por alvo e por granada. O impacto direto
não soma uma segunda cópia do dano da explosão.

Perfuração permite continuar após impactos, gerando explosões em outros grupos.
Ricochete busca um alvo ainda não atingido e reduz pela metade o dano restante.
Acertos da mesma granada, inclusive áreas sobrepostas, não repetem dano.
Críticos, fogo, gelo e veneno são aplicados aos inimigos da explosão; as mortes
continuam acionando cura por abates e Cadáver explosivo normalmente.

## Pistolas Gêmeas

Os tiros alternam entre os dois canos da arte, com origens próprias presas ao
mesmo encaixe da arma na mão. Cada tiro consome uma munição e conta uma vez para
Corrente elétrica e Último suspiro. Disparo duplo adiciona projéteis àquele tiro,
sem consumir munição extra nem disparar os efeitos passivos duas vezes.

## Arquitetura e validação

A caçadora continua em `scenes/characters/hunter.tscn`, com raiz CharacterBody2D
e movimento por `move_and_slide()`. As novas armas usam o Sprite2D já preso ao
WeaponPivot e os encaixes em `scripts/weapon_mount.gd`.

As cenas em `scenes/projectiles/` têm raiz Area2D, CollisionShape2D com cápsula
e Sprite2D. A granada também usa a área Blast/CollisionShape2D. As consultas de
colisão usam essas formas nativas contra as hurtboxes dos inimigos; o trajeto
rápido usa uma cápsula varrida, evitando saltar sobre alvos entre atualizações.
Somente os projéteis têm posição atualizada pelo simulador de disparos; o corpo
da personagem continua seguindo exclusivamente a física nativa.

Pausa e cartas congelam vida útil, retorno e pavio. Reiniciar ou voltar ao menu
remove os dados e as instâncias dos projéteis especiais. Arte e sons próprios
seguem as máscaras em `scripts/pixel_icon.gd` e `tools/compose_sfx.py`.

Execute `tests/new_weapons.gd`, `tests/buff_audit.gd`, `tests/weapon_mount.gd`,
`tests/weapon_reload.gd`, `tests/aim_facing.gd` e `tests/combat_audio.gd` para
validar comportamentos, os buffs, encaixes nas oito direções, recarga e áudio.

Os comportamentos são adaptações próprias inspiradas nos projéteis de retorno
de Megabonk e nas armas de tiro rápido/explosivas de 20 Minutes Till Dawn, sem
reutilizar arte, sons ou valores de balanceamento desses jogos.
