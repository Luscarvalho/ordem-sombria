# Prévia das direções

Abra `00_all_directions.tscn` na Godot e execute com F6. O seletor alterna entre
a caçadora, as espécies de inimigos, as variantes de aranha e os dois chefes.
Espaço pausa e continua a animação.

A cena tem raiz `Control`. Cada painel contém um rótulo da direção e um
`Node2D` de apoio com a instância real do personagem (`CharacterBody2D`).
Os corpos ficam parados para permitir comparar as poses; o controlador recebe
a velocidade base da cena para reproduzir o mesmo ritmo da partida. As
colisões da prévia são desativadas. A caçadora exibe oito direções; os inimigos,
quatro, incluindo a lateral espelhada.

Os GIFs e as imagens de referência ficam em `assets/previews/characters/`.
Para recriar os GIFs no macOS, com a renderização gráfica disponível:

```sh
godot --path . --audio-driver Dummy --rendering-driver opengl3 --resolution 720x480 --script res://tools/capture_character_gifs.gd
swift -module-cache-path /tmp/horda-swift-module-cache tools/encode_character_gifs.swift assets/previews/characters/manifest.json
```
