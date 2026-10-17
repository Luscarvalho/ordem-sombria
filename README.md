# Horda Sombria

Primeiro protótipo em Godot 4.7, GDScript e renderizador Compatibility.

Abra `project.godot` e use **Executar projeto** (F5; no Mac pode ser Fn+F5).
Na tela inicial, clique em **Jogar** e escolha uma arma para começar.
O menu também oferece **Como jogar** e **Sair** (em aplicações nativas).
Use **Voltar** ou Esc para sair da seleção e das instruções. A pausa e a tela
de derrota oferecem **Menu principal**; uma nova partida começa do nível 1.

## Controles

- WASD ou setas: mover. A arma mira e dispara automaticamente em um inimigo próximo.
- Celular: arraste no lado esquerdo da tela para mover com o joystick virtual.
  O joystick flutuante usa contornos octogonais translúcidos, base com 10% de
  opacidade e cursor com 16% de preenchimento. Só aparece enquanto o dedo está
  controlando a personagem; o tamanho e a sensibilidade do movimento não mudam.
- P / Esc ou botão Pausar: pausar e continuar.
- R ou clique/toque no contador de munição: recarregar antes de esvaziar.
- Subida de nível: clique/toque em uma carta ou use 1, 2, 3.

## Conteúdo

- Uma caçadora e seis armas: revólver, escopeta, cajado, Lâmina do Retorno,
  Lança-granadas e Pistolas Gêmeas. A seleção tem duas páginas de três cartas,
  sem diminuir o tamanho no celular. Veja `docs/weapons.md` para as mecânicas.
- Seleção com arte ampliada em pixel art e atributos iniciais de cada arma:
  dano por projétil, disparos por segundo, alcance, munição, tempo de recarga,
  projéteis e perfuração (ou raio da explosão, no lança-granadas).
  Perfuração indica alvos adicionais por projétil; o cajado começa com +1.
- Munição e recarga: revólver com 6 tiros/1,2 s; escopeta com 2 salvas/1,6 s;
  cajado com 8 cargas/1,8 s; lâmina com 3 cargas/1 s; lança-granadas com
  3 granadas/1,65 s; pistolas com 20 tiros/1,5 s. Reserva ilimitada. Uma salva gasta uma munição,
  independentemente do número de projéteis. Recarrega ao esvaziar e após
  0,65 s sem alvo; R ou o contador de munição permite antecipar a recarga.
  A personagem continua andando, com barra de progresso no HUD e sob os pés.
  Recarga ágil aumenta a velocidade em 20% por nível; Bandoleira adiciona duas
  munições por nível. Ambos evoluem até III. Pausa e cartas congelam a recarga.
- Alcance máximo por arma, incluindo a distância até a ponta da arma:
  revólver 300, escopeta 160, cajado 240, lâmina 250, lança-granadas 280 e
  pistolas 230 unidades de mundo. A mira automática
  considera somente inimigos dentro do alcance. Perfuração e projéteis extras
  não ampliam essa distância. A explosão da granada alcança 60 unidades ao redor
  do impacto; a lâmina retorna à caçadora depois do trajeto de ida. Esses valores
  ficam em `game_data.gd`.
- Hordas por etapas: primeiro apenas aranhas, aumentando em quantidade; depois
  entram aranhas velozes, aranhas de carapaça, olhos que atiram, feras com
  arrancada e cuspidores de veneno. Os inimigos mantêm uma pequena separação
  entre si. Consulte `docs/encounters.md` para os tempos e comportamentos.
- Chefes a cada cinco minutos de partida: Colosso das Cinzas em 5:00 e
  Matriarca do Enxame em 10:00, alternando a partir daí. Ataques têm aviso
  antes de disparar; o HUD mostra a vida do chefe e o tempo até o próximo.
  Derrotar um chefe cura 20 de vida, reduz o ritmo da horda por oito segundos
  e deixa um baú dourado no chão. Aproxime-se para escolher um buff extra entre
  até três opções. A escolha pausa o combate e preserva nível, XP e seu próximo
  custo de melhoria. O baú concede uma melhoria e desaparece após aberto.
- Olhos e cuspidores mantêm distância e miram antes de lançar projéteis
  desviáveis. O número de atiradores simultâneos é limitado. Feras e colosso
  marcam a direção da arrancada no chão antes de avançar.
- Ao aparecer um chefe, uma barreira fecha uma arena circular fixa no local
  da personagem, com raio de 400 unidades. A caçadora e os chefes não atravessam
  a borda; os obstáculos continuam sólidos e as hordas podem entrar. A câmera
  continua acompanhando a personagem na escala normal, sem zoom automático.
  A barreira só desaparece quando o último chefe vivo é derrotado. Pausa e cartas
  congelam os efeitos da arena. Reiniciar ou voltar ao menu remove a barreira.
- Vinte e dois buffs: os oito originais, recarga/capacidade e doze efeitos (crítico, ricochete, tiro poderoso,
  gelo, veneno, explosão, raio, orbes, escudo, cura por abates, vingança e pacto).
  Cada carta tem sprite próprio em pixel art, nível atual, próximo nível e
  comparação do efeito. A maioria evolui até III; dano e cadência até V.
  Buffs no máximo saem do sorteio. Com opções suficientes, a próxima seleção
  evita repetir as cartas anteriores e oferece uma evolução já adquirida quando
  disponível. Evoluções têm fundo/borda azulados e o rótulo EVOLUÇÃO; cartas
  inéditas mantêm o fundo original e o rótulo NOVO, inclusive nos baús.
  Consulte `docs/buffs.md` para os valores e a cobertura de validação.
- Progressão inicial mais rápida: a primeira melhoria exige 18 XP (seis aranhas);
  os próximos custos são 29, 42 e 59 XP, crescendo em 25% mais 6 XP.
  Até o nível 5, o sorteio inclui uma melhoria de combate quando disponível.
  O excedente é preservado e o raio básico de coleta é de 110 unidades.
  Cinco segundos antes do chefe, as almas já derrubadas são atraídas e novas
  ondas comuns aguardam. O ajuste fica nas constantes em `game_data.gd`.
- Nascimentos distribuídos entre oito setores ao redor da tela, sem repetir um
  setor antes de passar pelos demais. A separação maior e os limites menores
  evitam blocos compactos; novas ondas aguardam quando há muitos monstros perto.
- Caçadora redesenhada em uma única folha, `assets/animations/hunter-final-v8.png`.
  Oito quadros por caminhada, com poses paradas, proporções e paleta uniformes.
  Cinco vistas desenhadas e três espelhadas cobrem as oito direções.
  As pernas trocam de posição entre os contatos opostos e alternam o balanço.
  Corpo, capa e pés são quadros da folha; o ator não usa o antigo rig de pernas.
- A caminhada acompanha a velocidade real, com o mesmo período de 1 s em
  todas as direções na velocidade base, e congela na pausa e nas melhorias.
  As viradas passam pelas vistas intermediárias, preservando a fase do passo.
  A caçadora mira no alvo durante o combate e pode caminhar de costas;
  sem alvo, olha para onde anda. Parada, sua silhueta permanece estável.
- Arrancada e parada curtas, com interpolação visual entre atualizações físicas.
  A mira mantém o alvo para evitar viradas por pequenas diferenças de distância;
  um inimigo 25% mais próximo ganha prioridade. Alvos mortos ou fora de alcance
  são liberados imediatamente. Os monstros preservam seus seis quadros e
  ritmos próprios, respiração parada e flutuação do olho.
- Inimigos com quatro direções: direita/esquerda, frente e costas. Cada família
  tem uma folha transparente própria; variantes de aranha e Matriarca compartilham
  a folha da família. Viradas preservam a fase dos passos, e a pose parada mantém
  a última direção. A caçadora continua com suas oito direções.
- A regressão examina os pixels das duas pernas nos contatos e nas passagens,
  além da reprodução, das solas e dos encaixes das armas. A folha v4 rejeitada
  continua falhando no teste de troca das pernas.
- Pedras, tocos e colunas quebradas distribuídos pelo terreno, com a área de
  nascimento livre e passagens entre os objetos. Cada célula de 240 unidades tem
  36% de chance de conter um obstáculo, cerca de 53% menos que antes.
  A disposição permanece fixa
  ao explorar e retornar ao mesmo lugar. Personagem e inimigos colidem e
  deslizam pelas bordas; inimigos contornam os obstáculos. Os objetos também
  bloqueiam projéteis dos dois lados e ocultam alvos da mira automática.
  A profundidade acompanha os pés dos personagens, e novos inimigos e chefes
  são posicionados fora dos obstáculos.
- Ao subir de nível, o combate congela e uma aura pixelada de 0,55 s envolve
  a caçadora, com anéis no chão, faíscas, texto do nível e som curto.
  Só depois aparecem as cartas, com entrada suave. Pausar interrompe a aura
  e continuar retoma de onde parou, sem adiantar o combate.
- Armas separadas, presas à mão por quadro e direção. O cabo acompanha os passos; o recuo gira no pulso. A mão cobre o cabo e a capa encobre a
  arma nas vistas de costas. Tiros e clarões saem da ponta de cada arma.
- Duas trilhas chiptune originais em loop: menu mais calmo e partida com mais
  ritmo, com transição suave entre elas.
- Efeitos originais para revólver, escopeta, cajado, impactos, dano recebido e
  bloqueio do escudo. Impactos simultâneos têm limite de frequência e as armas
  emitem um som por salva, evitando sobreposição excessiva.
- **Configurações**, no menu principal ou em **Pausar > Configurações**, permite
  ligar/desligar a música e ajustar separadamente os volumes do menu e da
  partida. As alterações são imediatas e salvas para a próxima abertura.
  A partida permanece pausada enquanto você ajusta o som. Esc volta à pausa.
- **Efeitos sonoros** tem volume separado das músicas, inclusive para silenciar
  apenas os efeitos. **Testar som** permite ouvir o ajuste dentro das configurações.
- O progresso da partida ainda não é salvo permanentemente.
- HUD minimalista: XP em uma faixa de 4 pixels no topo, vida e munição à
  esquerda, tempo centralizado e nível/pausa à direita. A munição continua
  clicável para recarregar. Arma, alcance, abates, fase, vida máxima e tempo
  até o chefe ficam na pausa, junto dos controles. Chefes usam uma barra fina
  separada, exibida somente durante a luta; os botões preservam áreas de toque
  confortáveis sem ocupar a tela com painéis grandes.
  Em celulares, apenas o HUD é ampliado em 50%, sem mudar câmera, cenário ou
  menus. A pausa usa duas barras desenhadas e fundo contrastante, com área de
  toque de 66×66 unidades na escala normal do perfil mobile. Em janelas muito
  estreitas, a ampliação diminui para manter os grupos separados.

## Organização

- `scripts/game.gd`: partida, combate e progressão.
- `scripts/game_data.gd`: armas, catálogo de monstros, melhorias e regiões dos sprites.
- `scenes/characters/hunter.tscn`: cena editável da caçadora, incluindo corpo, colisão, animações, hurtbox e arma.
- `scenes/characters/enemies/`: cenas editáveis das sete espécies de inimigos e da Matriarca.
- `scripts/encounter_data.gd`: cronograma, composição e limites das hordas.
- `scripts/encounters.gd`: comportamentos, tiros inimigos, chefes e avisos.
- `scripts/buffs.gd`: efeitos, recargas, dano elemental, escudo e orbes dos buffs.
- `scripts/buff_icon.gd`: os 22 sprites de buffs em pixels, desenhados na interface.
- `scripts/level_up_aura.gd`: breve celebração de nível antes da escolha de cartas.
- `scripts/boss_chest.gd`: baú em pixels deixado pelos chefes, com coleta por proximidade.
- `scripts/boss_arena.gd`: barreira fixa da luta e limite circular.
- `scripts/actor.gd`: corpo físico compartilhado, movimentação nativa, hitboxes, animações e armas.
- `scripts/weapon_cycle.gd`: munição, recarga automática/manual e melhorias do carregador.
- `scripts/weapon_mount.gd`: pontos da mão por quadro e encaixe de cada arma.
- `scripts/player_projectile.gd` e `scenes/projectiles/`: áreas, formas nativas
  e sprites dos projéteis de retorno e das granadas.
- `scripts/arena.gd`: chão procedural decorativo.
- `scripts/terrain_obstacles.gd`: obstáculos em pixels, colisão, cobertura e distribuição pelo mundo.
- `scripts/interface.gd`: menus, HUD, cartas e joystick.
- `scripts/music.gd`: reprodução, transições e preferências de música.
- `scripts/pixel_*.gd`: fonte, molduras, ícones e barras da interface pixelada.
- `assets/characters-preview.png`: referência visual original preservada.
- `assets/animations/`: folhas de caminhada, recursos SpriteFrames e prompts.
- `assets/audio/`: trilhas originais e informações das composições.
- `tools/compose_music.py`: fonte das músicas; recria os WAVs com Python 3.
- `tools/compose_sfx.py`: fonte dos efeitos de combate e recarga, sem samples externos.

Os atlas são referenciados por regiões e margens de alinhamento; os PNGs originais
não foram recortados ou reamostrados.
As armas são desenhos separados para permitir trocas sem mudar o personagem.

A UI usa a fonte Silkscreen, distribuída sob a SIL Open Font License. O arquivo
de licença acompanha a fonte em `assets/fonts/OFL-Silkscreen.txt`. Os ícones e as
molduras são desenhados em código sobre uma grade de pixels; não exigem conexão.

## Cenas para inspecionar a caçadora

Para editar a personagem usada na partida, abra `scenes/characters/hunter.tscn`.
`main.tscn` já contém uma instância dela em `Actors/Hunter`. As cenas em
`scenes/characters/enemies/` são instanciadas pelas hordas, chefes e invocações.
Vida, velocidade, dano, XP e ajustes visuais básicos ficam exportados no
Inspector de cada cena; o jogo aplica os multiplicadores de progressão ao nascer.

Todas herdam de `scenes/characters/actor.tscn`, com raiz `CharacterBody2D`,
`CollisionShape2D`, `AnimatedSprite2D` e `Hurtbox` (`Area2D` com
`CollisionShape2D`). A caçadora acrescenta `WeaponPivot/HeldWeapon` e
`GrippingHand`; os inimigos herdam também `ContactHitbox` de `enemy.tscn`.
As cápsulas representam a área no chão, preservando as dimensões anteriores.
Ao editar o tamanho da colisão, mantenha o atributo `radius` coerente com a
área ocupada para orientar a IA e o posicionamento inicial fora dos obstáculos.

Durante `_physics_process`, o controlador calcula a velocidade e chama
`move_with_velocity()` no personagem. Esse método define `velocity`, executa
`move_and_slide()` e usa a velocidade real para sincronizar os passos.
Arrancadas e recuos seguem esse mesmo caminho. Obstáculos usam `StaticBody2D`
com cápsulas e a barreira dos chefes usa um `StaticBody2D` com retângulos.
As camadas físicas estão nomeadas nas configurações do projeto.

A posição de um inimigo só é definida para seu nascimento, antes de adicioná-lo
à árvore. Reiniciar recria a caçadora na origem; inimigos muito distantes são
substituídos por novas instâncias, preservando vida e efeitos. O deslocamento
dos personagens, incluindo o das prévias, usa exclusivamente a física nativa.

Abra `scenes/preview/cacadora/00_todas_direcoes.tscn` e use **F6** para ver as
animações completas das oito direções em loop. A pasta também tem uma cena
individual por direção (`01_direita.tscn` até `08_cima_direita.tscn`) e
`09_antes_depois.tscn`, com a comparação anterior/revisada da captura.

A cena `10_caminhada_com_deslocamento.tscn` mostra a personagem atravessando
um chão quadriculado fixo. O botão **Deslocar / No lugar** alterna esse modo nas
prévias. Os botões também permitem pausar, avançar uma pose, ver a pose parada,
trocar a arma e reduzir ou aumentar a velocidade. **Espaço** pausa, **seta direita** avança
um quadro e **R** reinicia. No Mac, F6 pode exigir Fn. Veja a lista completa em
`scenes/preview/cacadora/README.md`.

## Verificação

Folhas dos inimigos, quatro direções, espelhamento, poses paradas e continuidade
dos passos nas viradas:

```sh
godot --headless --path . --script res://tests/enemy_directions.gd
```

Cenas nativas dos personagens, hitboxes editáveis, barreiras físicas e colisão
em alta velocidade:

```sh
godot --headless --path . --script res://tests/native_characters.gd
```

Etapas da horda, limites, tiros anunciados, chefes a cada cinco minutos e pausa:

```sh
godot --headless --path . --script res://tests/encounters.gd
```

Progressão inicial, opções de combate, distribuição dos nascimentos, alívio de
aglomerações e coleta de XP antes dos chefes:

```sh
godot --headless --path . --script res://tests/progression.gd
```

HUD minimalista: limites em quatro resoluções, valores de XP/vida/munição,
recarga por clique, pausa com estatísticas e barra contextual dos chefes:

```sh
godot --headless --path . --script res://tests/minimal_hud.gd
godot --headless --path . --script res://tests/mobile_hud.gd
```

Simulação reproduzível de cinco minutos com um bot que coleta almas e prioriza
melhorias ofensivas (troque `revolver` por `shotgun` ou `wand`):

```sh
godot --headless --fixed-fps 60 --path . --script res://tools/simulate_progression.gd -- revolver /tmp/horda-progression.json
```

Por padrão, o bot é invulnerável para medir XP e densidade sem interromper a
amostra por morte; isso não estima a sobrevivência de um jogador. Acrescente
`mortal` depois do caminho de saída para ativar o dano normal.

Regressão de alcance (mira, limite exato, dispersão, velocidade e perfuração):

```sh
godot --headless --path . --script res://tests/weapon_range.gd
```

Armas novas: seleção paginada, lâmina na ida/volta, explosões, terreno,
formas nativas, pistolas alternadas, pausa e remoção dos projéteis:

```sh
godot --headless --path . --script res://tests/new_weapons.gd
```

Ciclos de animação, alinhamento, recuo, pausa e movimento em diferentes taxas:

```sh
godot --headless --path . --script res://tests/actor_animation.gd
```

Mira e movimento independentes, inclusive entre disparos de armas lentas:

```sh
godot --headless --path . --script res://tests/aim_facing.gd
```

Troca das pernas, folha única, apoio dos pés, pose parada e encaixes:

```sh
godot --headless --path . --script res://tests/grounded_diagonal.gd
godot --headless --path . --script res://tests/hunter_stride.gd
```

Encaixe na mão, espelhamento, recuo, camadas e origem dos tiros:

```sh
godot --headless --path . --script res://tests/weapon_mount.gd
```

Trilhas, transições, volumes, silêncio, persistência e configurações na pausa:

```sh
godot --headless --path . --script res://tests/audio_settings.gd
```

Níveis, limites, sorteio, ritmo de XP, sprites e efeitos reais dos 22 buffs:

```sh
godot --headless --path . --script res://tests/buffs.gd
godot --headless --path . --script res://tests/buff_audit.gd
godot --headless --path . --script res://tests/upgrade_cards.gd
```

Ritmo dos passos, viradas graduais, continuidade da animação e estabilidade da mira:

```sh
godot --headless --path . --script res://tests/movement_feedback.gd
```

Sons de combate, limite de impactos, volume independente e preferências anteriores:

```sh
godot --headless --path . --script res://tests/combat_audio.gd
```

Apoio dos pés nas novas diagonais e sequência da aura antes das cartas:

```sh
godot --headless --path . --script res://tests/grounded_diagonal.gd
godot --headless --path . --script res://tests/level_up_sequence.gd
```

Obstáculos: colisão contínua, deslizamento, perseguição, cobertura, nascimento
livre, distribuição determinística e carregamento limitado ao entorno:

```sh
godot --headless --path . --script res://tests/terrain_obstacles.gd
```

Baús dos chefes: drop único, coleta, buff extra, XP simultâneo, limites e reinício:

```sh
godot --headless --path . --script res://tests/boss_chests.gd
```

Arena de chefe: limite fixo, colisão com borda/obstáculos, câmera, pausa,
chefes simultâneos e liberação após a vitória:

```sh
godot --headless --path . --script res://tests/boss_arena.gd
```

Munição/recarga: salvas, controles, retomada, progressão das cartas e pausa:

```sh
godot --headless --path . --script res://tests/weapon_reload.gd
```

## Próximas etapas

Testar sensação dos tiros e ritmo das hordas; refinar quadros de animação e ampliar ações;
ajustar balanceamento; testar aparelhos reais e navegadores.

Os alvos são Android e Web. O projeto está configurado em paisagem e usa GDScript
e Compatibility. A build Web ainda não foi configurada.

## Build Android

O preset **Android** (`export_presets.cfg`) gera um APK de depuração em
`builds/android/horda-sombria.apk`, sem `tests/`, `work/`, `scenes/preview/`,
`assets/previews/` e `tools/`.
Primeira vez no editor:

1. **Editor > Gerenciar Modelos de Exportação > Baixar e Instalar** (4.7.2).
2. **Configurações do Editor > Exportar > Android**: Java SDK Path com um JDK 17+
   (ex.: `/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home`) e
   Android SDK Path (`~/Library/Android/sdk`). O keystore de depuração é criado
   automaticamente.

Depois, **Projeto > Exportar > Android > Exportar Projeto** ou:

```sh
mkdir -p builds/android
godot --headless --path . --export-debug "Android" builds/android/horda-sombria.apk
adb install -r builds/android/horda-sombria.apk
```

Com o celular conectado por USB (depuração USB ativa), o botão Android no canto
superior direito do editor instala e executa direto no aparelho. Para a Play Store
é preciso AAB (build Gradle) e keystore de release.

Antes de distribuir, incluir os avisos de licença da Godot e suas dependências.
