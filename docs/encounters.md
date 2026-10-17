# Hordas e chefes

Os tempos usam o relógio ativo da partida. Pausa, aura de nível e escolha de
cartas congelam as hordas e os projéteis. A progressão inicial custa
18, 29, 42, 59 XP… Aranhas comuns e velozes concedem 3 XP; olhos 6,
aranhas de carapaça 8, feras 9 e cuspidores 10.

| Tempo | Introdução | Limite da horda comum |
| --- | --- | --- |
| 0:00 | Aranhas comuns, uma por onda | 20 |
| 0:30 | Mais aranhas, duas por onda | 30 |
| 1:00 | Aranhas velozes, menores e mais frágeis | 40 |
| 1:45 | Aranhas de carapaça, maiores e resistentes | 48 |
| 2:00 | Olhos vigias, primeiros atiradores | 54 |
| 3:00 | Feras com arrancada | 64 |
| 4:00 | Cuspidores de veneno, tiro em leque | 72 |
| 5:00 em diante | Mistura completa; chefes a cada cinco minutos | 84 |

As aranhas continuam sendo a maioria. Cada etapa libera espécies para o sorteio;
não garante que todas apareçam imediatamente. Cada nascimento usa um dos oito
setores ao redor da personagem, em ordem embaralhada, cobrindo todos antes de
repetir. A distância considera a borda real da tela, mais uma margem de 72
unidades e o raio do inimigo; o terreno ajusta a posição para uma área livre.
Inimigos reciclados por distância também usam essa distribuição.

As ondas têm um membro no início, dois de 0:30 a 1:59 e três a partir de 2:00,
distribuídos pelo perímetro em vez de um grupo no mesmo ângulo. A frequência
cresce gradualmente dentro de cada etapa. Vida e velocidade também crescem
lentamente, com limites, sem alterar os requisitos de XP.

Se houver pelo menos 18 inimigos comuns vivos a menos de 240 unidades da
personagem, novas ondas aguardam e reavaliam a pressão a cada 0,8 s. Os que já
estão vivos continuam atacando normalmente. A separação começa 12 unidades além
da soma dos raios, usa uma grade de células de 96 unidades e altera apenas a
velocidade desejada; a física nativa continua responsável por movimento e colisões.

Os atiradores começam limitados a dois simultâneos, ganham uma vaga a cada dois
minutos e chegam ao máximo de oito. Aproximam-se, recuam se necessário e se movem
lateralmente. Só iniciam tiros visíveis na tela e a menos de 310 unidades. A mira
fica marcada por 0,55 s no olho e 0,65 s no cuspidor; depois dispara para o ponto
marcado. Os projéteis não perseguem o jogador. Veneno é o tema do tiro do cuspidor;
ele causa dano direto, sem efeito de dano contínuo no jogador.

## Chefes

A primeira chegada é em 5:00, a segunda em 10:00, a terceira em 15:00, e assim por diante. Se o anterior
ainda estiver vivo, o próximo chega mesmo assim. A barra mostra o primeiro chefe
vivo; passa ao seguinte quando ele é derrotado.

Cinco segundos antes, o aviso atrai todo o XP já derrubado e suspende novas ondas
comuns por cinco segundos. A chegada atrai também as almas dos abates recentes.
Somente o XP coletado é creditado, sem presentear níveis nem enfraquecer o chefe.

- **Colosso das Cinzas:** trava a direção por 0,9 s, avança em linha reta e emite
  um anel de projéteis. Abaixo de metade da vida, ataca mais frequentemente e o
  anel passa de oito para dez projéteis.
- **Matriarca do Enxame:** prepara o ataque por 0,9 s, dispara cinco projéteis
  em leque e invoca quatro aranhas velozes. Abaixo de metade da vida, dispara
  sete projéteis, invoca seis aranhas e reduz o intervalo dos ataques.

Os dois se alternam e ganham vida e dano a cada chegada. Durante a presença de
um chefe, as ondas comuns têm apenas um membro, intervalo multiplicado por 2,2
e deixam de reforçar a horda quando há 24 inimigos comuns vivos. Os excedentes
que já estavam na partida não são removidos. A derrota limpa os
projéteis inimigos, cura 20 de vida, concede XP e reduz as novas aparições por
oito segundos. Invocações respeitam 180 inimigos; tiros inimigos têm limite de
120 projéteis simultâneos. A separação usa uma grade espacial para evitar
comparar todo inimigo com todos os outros a cada atualização.

O cronograma, os pesos e os limites ficam em `scripts/encounter_data.gd`;
os atributos editáveis ficam nas cenas em `scenes/characters/enemies/`, com
catálogo correspondente em `scripts/game_data.gd`; comportamentos e chefes em
`scripts/encounters.gd`.

## Obstáculos do terreno

Pedras, tocos e colunas quebradas bloqueiam movimento e projéteis. A área
inicial fica livre; o mundo usa células de 240 unidades, com 36% de chance de
conter um obstáculo em cada uma (antes, 76%). Isso reduz a quantidade esperada
em cerca de 53%, sem diminuir o tamanho dos objetos nem mudar as posições dos
que permanecem. Os inimigos contornam as bases, as arrancadas colidem com
elas e todas as formas de nascimento buscam uma posição livre. A mira
automática considera apenas alvos com linha de tiro desobstruída; atiradores
inimigos avançam para procurar uma abertura quando a cobertura bloqueia o alvo.
Os objetos compartilham a ordenação por profundidade dos personagens.

Cada chefe derrotado também deixa um baú no local da queda, reposicionado se
necessário para ficar fora de obstáculos. Ao chegar perto, a caçadora recebe
uma seleção de buff extra, independente das melhorias por experiência.

## Arena dos chefes

A chegada do primeiro chefe fecha uma barreira circular de raio 400 no local
atual da caçadora. O centro permanece fixo no mundo; a câmera continua seguindo
a personagem na escala normal, sem zoom automático. O chefe nasce dentro da
arena, longe da personagem e fora dos obstáculos. A caçadora e os chefes colidem com a borda,
inclusive em arrancadas; o movimento pode deslizar por ela. Os objetos do
terreno continuam bloqueando normalmente, inclusive quando cruzam a borda.

As hordas que já estão fora podem entrar na barreira; depois de entrar, não
atravessam a borda para fora. Os ataques continuam sujeitos aos obstáculos do
terreno. A barreira contém os corpos e não bloqueia projéteis.

Se outro chefe surgir antes da vitória, ele usa a mesma arena, com o mesmo
centro. Só a derrota do último chefe vivo libera a passagem. Os baús continuam
caindo para cada chefe derrotado. Pausa, cartas e aura de nível congelam a arena;
reinício e retorno ao menu removem o confinamento.
