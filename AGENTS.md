# Diretrizes do projeto Horda Sombria

Estas instruções se aplicam a todo o repositório e devem orientar a criação e a alteração de elementos, cenas e personagens do jogo 2D em Godot 4.x.

## Hierarquia antes do código

- Antes de criar algo novo, explique ao usuário a hierarquia de nós da cena, a função de cada nó e seus relacionamentos.
- Apresente essa explicação antes de mostrar o código do script.
- Para personagens jogáveis e inimigos, use como estrutura básica:

```text
Personagem (CharacterBody2D)
├── CollisionShape2D
├── AnimatedSprite2D ou Sprite2D
└── Hitbox ou Gatilho (Area2D, quando necessário)
    └── CollisionShape2D
```

## Nós nativos obrigatórios

- Personagens jogáveis e inimigos devem sempre usar `CharacterBody2D` como nó raiz da cena.
- Colisões devem usar `CollisionShape2D` com `CapsuleShape2D` ou `RectangleShape2D`, conforme o formato adequado ao elemento.
- Gráficos e animações devem usar `AnimatedSprite2D` ou `Sprite2D`.
- A caçadora mantém oito direções; inimigos e chefes usam quatro: cima, baixo, esquerda e direita. Preserve as vistas próprias de frente e costas e use espelhamento para a lateral oposta.
- Organize uma folha de sprites por família de inimigos. Variantes da mesma família podem compartilhar a folha, mantendo seus atributos, cores, tamanhos e ritmos nas cenas.
- Áreas de gatilho e hitboxes devem usar `Area2D` com um filho `CollisionShape2D`.
- Não substitua o corpo físico dos personagens ou suas colisões por cálculos manuais de deslocamento e sobreposição.

## Código e movimentação

- Escreva scripts limpos e estruturados em GDScript compatível com Godot 4.x.
- Nunca mova personagens alterando diretamente `position` ou `global_position`, inclusive por incrementos, interpolação ou tweens dessas propriedades.
- Controle o movimento pela propriedade `velocity` do `CharacterBody2D` e execute `move_and_slide()` dentro desse corpo, durante a atualização de física (`_physics_process`).
- Use `move_and_slide()` também para movimentos especiais, como arrancadas e recuos por impacto, preservando a física e as colisões nativas.
- Respeite o funcionamento de Godot 4.x: `velocity` é expressa em unidades por segundo; `move_and_slide()` usa essa propriedade e não recebe `delta` como argumento.
- Ajustes locais dos nós visuais não devem ser usados para deslocar o corpo físico do personagem.

## Verificação das alterações

- Use `scenes/characters/hunter.tscn` e as cenas em `scenes/characters/enemies/` para instanciar personagens; não recrie suas hierarquias com `Actor.new()`.
- Mantenha os atributos básicos e os recursos visuais editáveis nas cenas. Preserve a herança de `actor.tscn` e `enemy.tscn` ao criar variantes.

- Confira a hierarquia de nós, os formatos de colisão e o uso de `velocity` e `move_and_slide()` nas cenas e scripts alterados.
- Preserve os comportamentos existentes de animação, combate e pausa ao alterar personagens.
- Execute as verificações pertinentes à alteração e informe ao usuário o que foi validado e qualquer limitação encontrada.
