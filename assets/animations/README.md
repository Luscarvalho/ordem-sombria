# Animações dos personagens

## Caçadora ativa: folha única redesenhada v8

`hunter-final-v8.png` é a única imagem usada pela caçadora na partida, no menu
e nas prévias atuais. Foi redesenhada com o ImageGen integrado a partir da
identidade original. Contém cinco linhas (direita, baixo/direita, baixo,
cima/direita e cima) e nove colunas: uma pose parada e oito quadros de caminhada.
As vistas à esquerda são espelhadas. `hunter-final-v8.tres` contém as regiões,
margens e encaixes da mão; não contém imagens duplicadas.

Todas as caminhadas têm oito quadros a 8 quadros/s na velocidade base.
O alinhamento usa uma linha comum por vista, preservando o balanço desenhado;
não reposiciona cada quadro pela ponta da bota. Não há deformação ou rig de
pernas no ator. As duas pernas alternam os contatos e as passagens na própria arte.

O prompt completo, as tentativas e a edição final de paleta estão em
`hunter-final-generation.json`; as regiões e os encaixes em
`hunter-final-frames.json`. O guia anatômico é
`work/hunter-final-pose-guide.png`, gerado por `work/hunter_final_pose_guide.gd`.
A folha final foi preservada exatamente como retornada pela ferramenta,
com seu canal alpha. Para reconstruir apenas o recurso:

```sh
godot --headless --path . --script res://work/build_final_hunter.gd
```

`tests/hunter_stride.gd` observa os pixels de couro claro/ocluído das pernas:
verifica a troca da ordem dos pés entre os contatos e o levantamento alternado
nas passagens, em todas as direções. O controle negativo `-- --rejected-sheet`
reprova a folha v4. `tests/grounded_diagonal.gd` verifica a fonte única, as
margens, as solas, o alpha, as poses paradas e os encaixes das mãos.
A antiga verificação geométrica do rig v7 foi removida porque ele não é mais usado.

As onze cenas de `scenes/preview/cacadora/` usam o mesmo ator da partida.
`00_todas_direcoes.tscn` mostra as oito direções e
`10_caminhada_com_deslocamento.tscn` permite observar o deslocamento contra
um chão fixo. A comparação mostra a v6 histórica em cima e a folha v8 embaixo.
`work/hunter-final-directions.gif` mostra os ciclos da nova folha; é reproduzível
com `work/capture_final_hunter.gd` e `work/assemble_hunter_preview.swift`.

As folhas e recursos anteriores estão preservados como histórico. Os antigos
construtores v4–v7 e o script `hunter_diagonal_gait.gd` não alteram nem integram
o recurso ativo v8.

## Fontes anteriores e monstros

Folhas geradas pela ferramenta integrada `image_gen.imagegen`, usando a prévia
aprovada em `../characters-preview.png` como referência visual. Os prompts
completos de geração e de refinamento estão em `generation.json`.

- `hunter-walk-v1.png`: 8 poses de caminhada da caçadora, mãos vazias, com passos
  e movimentos da capa e do cachecol. Recurso `hunter.tres`, 12 quadros/s na
  velocidade base.
- `hunter-vertical-v1.png`: 6 poses de frente para descer e 6 de costas para
  subir, geradas com ImageGen a partir da identidade da caçadora lateral.
  Prompt em `hunter-vertical-generation.json` e regiões em
  `hunter-vertical-frames.json`. O recurso anterior `hunter-directions-v1.tres`
  combina as quatro direções: 8 quadros laterais e 6 por direção vertical,
  com poses paradas correspondentes. O recurso lateral original é preservado.
- `hunter-diagonal-v1.png`: 6 poses para cima/direita e 6 para baixo/direita,
  espelhadas para as diagonais à esquerda. Prompt ImageGen em
  `hunter-diagonal-generation.json` e regiões em `hunter-diagonal-frames.json`.
  O recurso anterior `hunter-directions-v2.tres` reúne as oito direções com
  caminhada e poses paradas. Os recursos anteriores foram preservados.
- `monsters-walk-v1.png`: 6 poses por monstro. Recursos `crawler.tres` (13 q/s),
  `eye.tres` (8 q/s), `beast.tres` (12 q/s) e `colossus.tres` (7 q/s).
- `hunter-up-diagonal-v2.png`: correção das poses de costas em diagonal,
  com seis quadros em grade 3×2 e solas apoiadas no chão, gerada com o
  ImageGen integrado. Substitui apenas as diagonais para cima no recurso
  anterior `hunter-directions-v3.tres`; as demais direções usam a arte anterior.
  A vista esquerda é espelhada. Prompts completos e refinamento em
  `hunter-up-diagonal-generation.json`; regiões, canvas e mãos em
  `hunter-up-diagonal-frames.json`. Os arquivos anteriores foram preservados.
- `frames.json`: regiões e dimensões de alinhamento de cada ciclo.
- `spitter-walk-v1.png`: seis quadros de um cuspidor de veneno, em grade 3×2,
  gerados com o ImageGen integrado a partir da folha dos monstros. O recurso
  `spitter.tres` alinha os pés e reproduz a caminhada a 7 quadros/s; regiões
  e margens estão em `spitter-frames.json`. Prompt completo e origem em
  `spitter-generation.json`. O PNG retornado foi preservado sem alterações.

As aranhas velozes e de carapaça compartilham os quadros da aranha original,
com tamanhos e cores próprios. A Matriarca usa a mesma família de animações,
ampliada e com ritmo mais lento, cor roxa e coroa desenhada em código.

Os PNGs foram preservados como retornados pela geração. Os recursos `.tres`
usam `AtlasTexture.region` e `margin` para dar aos quadros o mesmo tamanho e
alinhar os pontos de apoio, sem salvar novas imagens recortadas. As margens
foram verificadas na Godot, incluindo a posição dos chifres do colosso.

As animações são controladas por `scripts/actor.gd`: a caçadora e os monstros
terrestres caminham de acordo com a velocidade; o olho flutua continuamente.
Parados, os monstros respiram levemente; a caçadora usa uma pose estável. Pausa, melhorias e morte congelam
os quadros. As armas ficam separadas e usam os mesmos desenhos em pixels da
seleção, com recuo e clarão de disparo.

`scripts/weapon_mount.gd` registra o centro da mão nos pixels originais de cada
quadro. O cabo de cada arma coincide com esse ponto, espelhado junto com o corpo.
Uma região da própria mão é redesenhada por cima do cabo nas vistas de frente;
nas vistas de costas, a arma fica atrás da capa. A vista diretamente de costas
usa um ponto de apoio oculto sob a capa, alinhado ao canvas. O recuo gira ao
redor do pulso sem afastar o cabo. Não são necessárias folhas da personagem
duplicadas para cada arma. Nenhum PNG foi alterado para fazer esse encaixe.

A caçadora tem oito direções: frente, costas, lados e quatro diagonais.
As vistas à esquerda usam espelhamento. Com alvo ao alcance, corpo e arma acompanham a mira continuamente,
inclusive entre disparos; ao andar no sentido oposto, o ciclo de passos é
reproduzido ao contrário. Sem alvo, o movimento decide a pose após um breve
intervalo de 0,18 s do último tiro. Ao parar, a última direção é mantida.
As direções ocupam setores de 45 graus, com histerese angular de 5 graus
para evitar oscilações na divisão entre poses.
Os monstros continuam com os ciclos aprovados.
Ainda não há ciclos próprios de morte.

### Ajuste de movimento

Na caçadora ativa, todas as vistas usam oito quadros a 8 quadros/s, resultando em ciclos de 1 s. A fera usa 8 quadros/s e o colosso 4,5 quadros/s. Rastejante e olho
mantêm seus ritmos anteriores. A reprodução acompanha a velocidade real, sem
impor uma velocidade mínima de pernas, e para quando o movimento cessa.

O corpo da caçadora gira até 900 graus/s através das poses existentes, com a
mesma histerese angular. A fase do passo é preservada e o sentido do ciclo
é invertido na mesma fase ao passar a andar de costas, sem uma pausa extra nas pernas. Monstros têm uma zona neutra
horizontal e um intervalo mínimo entre espelhamentos para evitar tremores ao
perseguir um alvo quase acima ou abaixo. Os PNGs originais foram preservados; os encaixes atuais estão nos metadados dos quadros.
