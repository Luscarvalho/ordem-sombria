# Hordas e chefes

Os tempos usam o relógio ativo da partida. Pausa, aura de nível e escolha de
cartas congelam as hordas e os projéteis. O custo de XP foi mantido:
40, 64, 96, 140… A variedade entra pela composição e pelo comportamento.

| Tempo | Introdução | Limite da horda comum |
| --- | --- | --- |
| 0:00 | Aranhas comuns, uma por grupo | 28 |
| 0:30 | Mais aranhas, duas por grupo | 44 |
| 1:00 | Aranhas velozes, menores e mais frágeis | 62 |
| 1:45 | Aranhas de carapaça, maiores e resistentes | 80 |
| 2:00 | Olhos vigias, primeiros atiradores | 88 |
| 3:00 | Feras com arrancada | 108 |
| 4:00 | Cuspidores de veneno, tiro em leque | 128 |
| 5:00 em diante | Mistura completa; chefes a cada cinco minutos | 144 |

As aranhas continuam sendo a maioria. Cada etapa libera espécies para o sorteio;
não garante que todas apareçam imediatamente. Os grupos se aproximam de fora
da tela. A frequência cresce gradualmente dentro de cada etapa. Vida e velocidade
também crescem lentamente, com limites, sem alterar os requisitos de XP.

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

- **Colosso das Cinzas:** trava a direção por 0,9 s, avança em linha reta e emite
  um anel de projéteis. Abaixo de metade da vida, ataca mais frequentemente e o
  anel passa de oito para dez projéteis.
- **Matriarca do Enxame:** prepara o ataque por 0,9 s, dispara cinco projéteis
  em leque e invoca quatro aranhas velozes. Abaixo de metade da vida, dispara
  sete projéteis, invoca seis aranhas e reduz o intervalo dos ataques.

Os dois se alternam e ganham vida e dano a cada chegada. Durante a presença de
um chefe, os grupos comuns ficam menores e mais espaçados. A derrota limpa os
projéteis inimigos, cura 20 de vida, concede XP e reduz as novas aparições por
oito segundos. Invocações respeitam 180 inimigos; tiros inimigos têm limite de
120 projéteis simultâneos. A separação usa uma grade espacial para evitar
comparar todo inimigo com todos os outros a cada atualização.

O cronograma e os pesos ficam em `scripts/encounter_data.gd`; atributos em
`scripts/game_data.gd`; comportamentos e chefes em `scripts/encounters.gd`.

## Obstáculos do terreno

Pedras, tocos e colunas quebradas bloqueiam movimento e projéteis. A área
inicial fica livre; o mundo usa uma distribuição fixa por célula, com espaço
entre os objetos. Os inimigos contornam as bases, as arrancadas colidem com
elas e todas as formas de nascimento buscam uma posição livre. A mira
automática considera apenas alvos com linha de tiro desobstruída; atiradores
inimigos avançam para procurar uma abertura quando a cobertura bloqueia o alvo.
Os objetos compartilham a ordenação por profundidade dos personagens.

Cada chefe derrotado também deixa um baú no local da queda, reposicionado se
necessário para ficar fora de obstáculos. Ao chegar perto, a caçadora recebe
uma seleção de buff extra, independente das melhorias por experiência.

## Arena dos chefes

A chegada do primeiro chefe fecha uma barreira circular de raio 260 no local
atual da caçadora. O centro permanece fixo no mundo e a câmera enquadra o
círculo inteiro abaixo do HUD. O chefe nasce dentro da arena, longe da
personagem e fora dos obstáculos. A caçadora e os chefes colidem com a borda,
inclusive em arrancadas; o movimento pode deslizar por ela. Os objetos do
terreno continuam bloqueando normalmente, inclusive quando cruzam a borda.

As hordas que já estão fora podem entrar na barreira; depois de entrar, não
atravessam a borda para fora. Os ataques continuam sujeitos aos obstáculos do
terreno. A barreira contém os corpos e não bloqueia projéteis.

Se outro chefe surgir antes da vitória, ele usa a mesma arena, com o mesmo
centro. Só a derrota do último chefe vivo libera a passagem e restaura a câmera
normal. Os baús continuam caindo para cada chefe derrotado. Pausa, cartas e aura
de nível congelam a arena; reinício e retorno ao menu removem o confinamento.
