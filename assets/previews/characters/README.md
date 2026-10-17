# GIFs dos personagens

Cada GIF mostra simultaneamente as direções disponíveis, com os recursos e o
controlador usados na partida. A caçadora tem oito direções; todos os inimigos,
quatro. A ampliação facilita inspecionar os desenhos, sem alterar o tamanho
dos personagens no jogo. O ritmo usa a velocidade base e o multiplicador de
passos de cada cena; os GIFs são capturados em ciclos completos.

- `cacadora.gif`: protagonista original, oito direções.
- `aranha.gif`: aranha básica.
- `aranha-veloz.gif`: variante rápida, de cor quente.
- `aranha-carapaca.gif`: variante resistente, com carapaça.
- `olho-vigia.gif`: olho flutuante.
- `fera.gif`: fera com arrancada.
- `cuspidor.gif`: cuspidor de veneno.
- `colosso.gif`: Colosso das Cinzas.
- `matriarca.gif`: Matriarca do Enxame.

Os PNGs são o primeiro quadro de cada GIF. `manifest.json` registra as durações,
as pastas temporárias de captura e os destinos dos GIFs. Para recriar a captura,
consulte `scenes/preview/enemies/README.md`.

As cinco folhas dos inimigos foram geradas com a ferramenta integrada
`image_gen.imagegen`. Os prompts e as referências completos estão em
`assets/animations/enemy-directions-generation-v1.json`. As artes originais
anteriores foram preservadas, e as variantes de aranha compartilham a mesma
folha de família.

Este diretório é excluído das exportações do jogo.
