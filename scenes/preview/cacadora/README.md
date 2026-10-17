# Cenas de animação da caçadora

Abra uma destas cenas no Godot e use **Executar cena atual (F6)**.
No Mac, pode ser necessário **Fn + F6**. Elas funcionam independentemente do
menu e da partida, e continuam rodando até você encerrar a execução.

| Arquivo | Prévia |
| --- | --- |
| `00_todas_direcoes.tscn` | As oito direções da nova folha, juntas |
| `01_direita.tscn` | Direita |
| `02_baixo_direita.tscn` | Diagonal para baixo e direita |
| `03_baixo.tscn` | Frente / baixo |
| `04_baixo_esquerda.tscn` | Diagonal para baixo e esquerda |
| `05_esquerda.tscn` | Esquerda |
| `06_cima_esquerda.tscn` | Diagonal para cima e esquerda |
| `07_cima.tscn` | Costas / cima |
| `08_cima_direita.tscn` | Diagonal para cima e direita |
| `09_antes_depois.tscn` | Comparação: v6 anterior em cima, nova folha v8 embaixo |
| `10_caminhada_com_deslocamento.tscn` | Caminhada para baixo/direita atravessando um chão fixo |

Cada cena começa com a caminhada completa em loop, na velocidade da partida.
O contador permite acompanhar os oito quadros de cada caminhada da nova folha.
As oito direções têm o mesmo ritmo; esquerda e diagonais à esquerda espelham
as vistas correspondentes. A comparação preserva a v6 histórica em cima,
com seus antigos números de quadros, e mostra a folha única v8 embaixo.
A personagem e todas as pernas são reproduzidas diretamente do mesmo PNG.

- **Deslocar / No lugar** alterna entre atravessar a cena e caminhar no mesmo ponto.
- **Pausar / Continuar** ou **Espaço** congela e retoma a animação.
- **+1 quadro** ou **seta direita** pausa e avança exatamente um quadro.
- **Ver parada / Ver caminhada** alterna entre a pose parada e o ciclo completo.
- **Reiniciar** ou **R** volta ao primeiro quadro, mantendo direção, arma e velocidade.
- O seletor de velocidade permite 0,25x, 0,5x, 1x, 1,5x e 2x.
- O seletor de arma permite revólver, escopeta, cajado e sem arma.

As prévias usam `scripts/actor.gd`: a arte, os encaixes e a reprodução são os
mesmos da partida. As cenas 00–09 começam com a personagem no mesmo ponto; a cena 10 começa com deslocamento.
Não existe uma ação de corrida separada no jogo; a prévia mostra o ciclo de
movimento existente, completo. O script compartilhado é `scripts/hunter_preview.gd`.

Também é possível executar uma cena pelo terminal, a partir da raiz do projeto:

```sh
godot --path . res://scenes/preview/cacadora/00_todas_direcoes.tscn
```
