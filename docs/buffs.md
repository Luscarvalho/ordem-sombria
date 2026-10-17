# Buffs e níveis

Uma escolha aumenta em um nível o buff da carta. Os níveis pertencem à partida
atual e são zerados ao iniciar outra caçada. A carta mostra nível atual, próximo
nível, limite e valores antes/depois, com um sprite próprio e cores por efeito.
Cartas de buffs já adquiridos têm fundo e borda azulados, a indicação
**EVOLUÇÃO** e a passagem de nível. Cartas inéditas mantêm o fundo original e
a indicação **NOVO**. A diferença permanece no hover, no foco e ao pressionar,
tanto nas melhorias por XP quanto nos baús; as cores dos sprites continuam
identificando cada poder.

Antes de abrir a seleção, a personagem recebe uma aura de 0,55 s com anéis,
faíscas, texto do novo nível e um arpejo curto. Todo o combate fica congelado
durante esse intervalo. Depois, as cartas entram com um fade de 0,12 s.

| Buff | Limite | Evolução por nível |
| --- | --- | --- |
| Recarga ágil | III | Velocidade de recarga +20%, +40%, +60%; tempo base dividido por 1,2 / 1,4 / 1,6. |
| Bandoleira | III | Capacidade +2, +4 ou +6 munições; as novas posições são preenchidas ao evoluir. |
| Pólvora sombria | V | +25 pontos percentuais de dano: +25%, +50%, +75%, +100%, +125%. |
| Mãos ligeiras | V | Cadência ×1,15 por nível, cumulativa. |
| Passo fantasma | III | Movimento ×1,12 por nível, cumulativo. |
| Disparo duplo | III | +1, +2 ou +3 projéteis por disparo. |
| Atravessar | III | +1, +2 ou +3 alvos perfurados por projétil. |
| Sangue novo | III | +20, +40 ou +60 de vida base máxima; cura 30 ao escolher. |
| Colheita de almas | III | Raio de coleta ×1,45 por nível, cumulativo. |
| Brasa viva | III | 9, 18 ou 27 de dano/s durante 3 s. |
| Ponto fraco | III | 15%, 30% ou 45% de chance de dano dobrado por impacto de projétil. |
| Ricochete | III | 1, 2 ou 3 saltos; cada salto conserva 50% do dano anterior. |
| Último suspiro | III | Dano triplo a cada 8, 6 ou 4 disparos. Uma salva de escopeta conta como um disparo. |
| Toque gelado | III | Inimigos 30%, 40% ou 50% mais lentos durante 2 s. |
| Veneno sombrio | III | 6, 12 ou 18 de dano/s durante 4 s. |
| Cadáver explosivo | III | 20%, 30% ou 40% de chance ao matar; 35, 55 ou 75 de dano num raio de 70. |
| Corrente elétrica | III | A cada 5 disparos, atinge até 3, 4 ou 5 inimigos; dano 20, 28 ou 36. |
| Orbes protetores | III | 2, 3 ou 4 esferas; dano 14, 20 ou 26 por contato, com intervalo de 0,55 s por inimigo. |
| Barreira sombria | III | Bloqueia um golpe e recarrega em 20, 16 ou 12 s. Pronta ao adquirir o primeiro nível. |
| Sede de sangue | III | Cura 2, 4 ou 6 de vida a cada 10 abates. |
| Vingança | III | Ao sofrer dano, empurra os inimigos num raio de 100 e causa 15, 30 ou 45 de dano. |
| Pacto sombrio | III | +40%, +80% ou +120% de dano; vida máxima ×0,75 por nível. |

Os bônus de dano de Pólvora e Pacto são somados. O custo de vida do Pacto também
afeta a vida base concedida por Sangue novo, independentemente da ordem em que
as cartas são adquiridas. Os valores de dano elemental/orbital são fixos conforme
o nível da própria carta. Fogo e veneno coexistem; impactos renovam a duração,
sem criar pilhas adicionais do mesmo efeito no mesmo inimigo.

A carta Pacto mostra valores concretos conforme a arma e os buffs atuais:
por exemplo, com revólver sem outros bônus, **dano por projétil 24 → 34**
(arredondado na interface) e **vida máxima 100 → 75** no primeiro nível.
O texto explicita a troca de vida por dano e que ela vale durante toda a caçada.

Ricochetes buscam um alvo ainda não atingido a até 140 unidades. Não aumentam
o alcance original da arma nem a distância total restante do projétil. Raios
saltam entre alvos a até 130 unidades entre si. Explosões podem gerar outras
explosões ao matar. Escudo e orbes têm efeitos visuais próprios na partida.

## Sorteio e experiência

- Primeira carta: 18 XP (seis aranhas comuns de 3 XP).
- Próximos custos: 29, 42 e 59 XP; fórmula `round(custo × 1,25 + 6)`.
- XP excedente é preservado. Não há temporizador artificial para subir de nível.
- Raio básico de coleta: 110 unidades, multiplicado por Colheita de almas.
  As almas atraídas continuam perseguindo a personagem, a pelo menos 560 unidades/s
  e sempre mais rápido que ela. O limite de 240 orbes preserva todo o XP,
  juntando novos valores ao orbe mais próximo do abate.
- Cinco segundos antes de cada chefe, todas as almas no chão são atraídas,
  inclusive as distantes. O XP só é creditado ao chegar à personagem; não há XP
  gratuito. A chegada do chefe repete a atração para incluir os abates recentes.
- São até três opções distintas por seleção, sem buffs já no nível máximo.
- Se houver três alternativas disponíveis, as cartas da seleção anterior ficam
  fora da próxima seleção. Entre as opções restantes, uma evolução de buff já
  adquirido é garantida quando existir.
- Até o nível 5, também há uma opção de combate quando disponível no conjunto
  elegível: dano, cadência, projéteis extras, perfuração, brasa, veneno, raio,
  orbes ou ricochete. Ela pode ser a própria evolução já garantida.
- Se só restarem uma ou duas cartas evoluíveis, elas continuam disponíveis.
  Ao maximizar todos os buffs, os níveis seguintes não abrem uma tela vazia.
- Pausa, cartas e configurações congelam recargas, órbitas e efeitos de combate.

Os sprites em `scripts/buff_icon.gd` seguem o sistema de arte da interface:
máscaras próprias de 16×16 pixels, paleta restrita e ampliação inteira sem filtro.
Não usam desenhos ou fontes de ícones externos.

## Baús de chefe

Cada chefe derrotado deixa um baú dourado, além de seu XP e da cura já concedida
pela vitória. O baú permanece no chão e abre ao se aproximar, depois de um breve
intervalo de 0,35 s para apresentar o drop. A escolha pausa todo o combate e
oferece até três buffs distintos: adquirir um novo ou evoluir um já obtido,
respeitando os mesmos limites das cartas normais.

Cada baú concede exatamente uma melhoria extra para a partida atual. Não gasta
XP, não aumenta o nível da personagem e não altera o custo da próxima melhoria.
Se houver XP para subir de nível ao mesmo tempo, cada seleção é apresentada
separadamente. Outros baús no chão aguardam a escolha atual. O baú aberto some
após a coleta; voltar ao menu ou reiniciar limpa o loot restante. Quando todos
os buffs já estão no máximo, o baú restaura a vida em vez de abrir cartas vazias.

## Munição e recarga das armas

A reserva é ilimitada, mas o carregador esvazia: revólver 6 tiros e 1,2 s de
recarga, escopeta 2 salvas e 1,6 s, cajado 8 cargas e 1,8 s, lâmina 3 cargas e
1 s, lança-granadas 3 cargas e 1,65 s, pistolas 20 tiros e 1,5 s. Cada disparo/salva
consome uma munição, inclusive com Disparo duplo, escopeta e perfuração.
Recarga ágil afeta a recarga; Mãos ligeiras afeta apenas a cadência.

Esvaziar inicia a recarga automaticamente. Também é possível antecipá-la com
R, clicando na munição ou pelo botão Recarregar no celular. Sem alvo por 0,65 s,
a caçadora aproveita a abertura para repor um carregador parcial. Uma recarga
iniciada precisa terminar antes de disparar; apertar R repetidamente não a
reinicia nem completa instantaneamente. Movimento, efeitos passivos e inimigos
continuam ativos. Pausa, aura, cartas por XP e baús congelam seu progresso.

O HUD mostra munição/capacidade ou o tempo restante, com uma barra de progresso.
A arma gira discretamente no pulso e aparece uma barra sob os pés durante a
recarga. Os sons de início/fim respeitam o volume dos efeitos. As cartas mostram
a capacidade e o tempo reais da arma escolhida. Se Recarga ágil for escolhida
durante uma recarga, a porcentagem já completada é preservada. Novas partidas
começam com o carregador completo e os valores básicos da arma selecionada.

A referência de design foi o sistema de munição e tempo de recarga por arma de
[20 Minutes Till Dawn](https://20-minutes-till-dawn.fandom.com/wiki/Weapons).
Os valores acima são o balanceamento inicial de Horda Sombria.

## Validação dos poderes

`tests/buff_audit.gd` verifica os 22 buffs em todos os níveis e monta builds com
todos os buffs no máximo para as seis armas. Os testes conferem:

- Dano, cadência, projéteis extras, perfuração, capacidade e tempo de recarga.
- Críticos e explosões com sequências aleatórias reproduzíveis.
- Dano triplo por disparo/salva, ricochetes e limites da corrente elétrica.
- Fogo/veneno simultâneos, renovação sem acumular pilhas e expiração da lentidão.
- Quantidade, dano e intervalo de contato dos orbes.
- Velocidade, coleta real de almas, cura por aquisição e por abates, limites de
  vida, bloqueio/recarga do escudo e dano/empurrão da vingança.
- Pacto somado ao dano, custo de vida, combinações entre poderes, pausa e
  recompensas únicas de mortes em cadeia por explosões.

A regressão de perfuração cria os alvos em ordem inversa à trajetória: o tiro
deve atingir os mais próximos primeiro, independentemente da ordem de criação.
As colisões continuam sendo verificadas pelas formas nativas das hurtboxes.
`tests/new_weapons.gd` cobre os comportamentos próprios da lâmina, das granadas
e das pistolas. A lâmina pode atingir um alvo uma vez na ida e uma vez na volta;
perfuração aumenta o número de alvos em cada trecho. Granadas aplicam os efeitos
de impacto em área, sem repetir dano no mesmo alvo para a mesma granada;
perfuração permite continuar e ricochetes reduzem o dano das próximas explosões.
Cada tiro alternado das pistolas conta como um disparo, sem duplicar gatilhos.
`tests/upgrade_cards.gd` verifica as cores e os rótulos das cartas de todos os
buffs, em cada evolução, e as escolhas reais por XP e por baús.

Essas verificações validam regras e efeitos de combate; a sensação e o
balanceamento no celular ainda dependem de partidas de teste.
