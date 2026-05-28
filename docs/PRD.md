# PRD — Alquimia Elemental
> Última atualização: 2026-05-08

## Visão geral
Jogo 2D educativo (plataformer + batalha por turno) que ensina química para alunos do 6º EM ao 3º EM.
Desenvolvido em Godot 4.6 + GDScript. PAC IV — Católica de Santa Catarina.

---

## Estado atual (Sprint N2 — deadline 22/05/2026)

### Sistemas implementados e funcionando
| Sistema | Descrição |
|---------|-----------|
| Plataformer | Movimento, pulo, coyote time (0.12s), jump buffer (0.12s) |
| Wall Jump | WALL_SLIDE state, wall jump com impulso lateral, tint azul |
| Inventário | Coleta de elementos → GameState → HUD atualiza via sinais |
| Alquimia | Painel Q com 3 slots, tutorial guiado H2O |
| Projéteis | Ataque J/click, dispara composto ativo |
| Inimigo 1 | SlimeSodio — patrulha, chase, fraco a H2O, dropa Na |
| Inimigo 2 | **GolemEnxofre** — patrulha, chase, fraco a H2O e CO2, imune a SO2, dropa S |
| Checkpoint | Salva posição, dialog de Elara |
| HUD | Barra de vida + inventário de elementos + composto ativo |
| Tabela Periódica | Tecla TAB, posições reais período/grupo, desbloqueio visual |
| Tutorial | Legendas sequenciais guiando o jogador (movimento → alquimia → ataque) |
| Menu Principal | Tela de título com botão Jogar |
| Game Over | Tela de morte com reinício |
| **Boss 1** | Lesma Gigante (NaCl fraqueza, H2O cura) — Level 01 |
| **Boss 2** | **Golem de Lava** (H2O×3, CO2×2+stun, SO2 cura) — Level 02 |
| **Level 01** | Metroidvania completo: salas fechadas, shaft wall jump, dark areas, fogo, transição L02 |
| **Level 02** | **Caldeira Vulcânica — implementado nesta sessão (ver abaixo)** |

---

## Level 02 — Caldeira Vulcânica (implementado em 2026-05-08)

### Arquivos criados/modificados
| Arquivo | O que é |
|---------|---------|
| `scenes/world/level_02_tilemap.gd` | Tilemap próprio do Level 02 — **não usa o level_tilemap.gd do L01** |
| `scenes/world/level_02_tilemap.tscn` | Cena instanciável do tilemap (uid: `uid://lvl02tilemap`) |
| `scenes/enemies/golem_enxofre.gd` | Novo inimigo GolemEnxofre |
| `scenes/enemies/golem_enxofre.tscn` | Cena do Golem (uid: `uid://golem001`) |
| `scenes/ui/boss_battle.gd` | Adicionado boss `"golem"` ao dict BOSSES + fix visual sem sprite |
| `scenes/levels/level_02.gd` | Reescrito — lógica completa |
| `scenes/levels/level_02.tscn` | Reescrito — usa tilemap próprio, Golems, fog, BossTrigger |

### Layout das salas (tilemap level_02_tilemap.gd)
```
SALA ALTA (x:0-1600, y:-320→-160)   ← boss trigger em x≈120, dark fog
     ↑ SHAFT 80px (x:224-304) — wall jump obrigatório
HUB/SPAWN (x:0-1600, y:112→368) ←→ CORREDOR (x:1600-2400, y:112→368)
```
- Spawn: Vector2(80, 300)
- 8 plataformas no hub/corredor alternando y=240/256/272/288
- 6 plataformas na sala alta
- Teto hub: y=112 (com gap shaft em x:224-304)
- Chão: y=368 (contínuo x:0-2400)
- Parede esq total: x=-16, y=-320→480
- Parede dir: x=2400, y:112-400
- Cores: C_ROCK = Color(0.18,0.10,0.05) / C_ACCENT = Color(0.65,0.30,0.05)

### Elemento novo introduzido
- **Si (Silício)** — 2 pickups na sala alta (plat J e plat L), só acessível via wall jump

### Distribuição de pickups no level_02.tscn
| Node | Posição | Elemento |
|------|---------|---------|
| S_01 | (540, 350) | S |
| S_02 | (800, 225) | S |
| S_03 | (1360, 225) | S |
| O_01 | (480, 273) | O |
| O_02 | (1040, 273) | O |
| O_03 | (1680, 273) | O |
| Si_01 | (400, -270) | Si |
| Si_02 | (960, -285) | Si |

### Inimigos no level_02.tscn
| Node | Posição | Tipo |
|------|---------|------|
| Golem01 | (800, 355) | GolemEnxofre |
| Golem02 | (1600, 355) | GolemEnxofre |

### GolemEnxofre (golem_enxofre.gd)
- HP: 40 | Speed: 30 | Patrol: 60 | Dano toque: 12
- Fraco a: H2O (×2), CO2 (×2)
- Imune a: SO2
- Dropa: S (1 unidade)
- Visual: draw procedural — corpo rochoso angular laranja/marrom, fissuras de lava pulsando, olhos brilhantes
- Mensagem ao morrer: "S + H₂O → H₂SO₄!"
- Collision body: 14×16px | Detect area: 100×35px

### Boss 2 — Golem de Lava (em boss_battle.gd, id: "golem")
| Composto | Dano | Efeito | Ensinamento |
|----------|------|--------|-------------|
| H2O | -3 HP | — | Água solidifica lava (reação endotérmica) |
| CO2 | -2 HP | stun | Remove O₂ que alimenta as chamas |
| SO2 | **+1 HP** | heal | Enxofre é componente do magma — errado = aprendizado! |
| NaCl | -1 HP | — | Reage com minerais basálticos |
| HCl | -1 HP | — | Ácido corrói rocha |
| NaOH | -1 HP | — | Base reage com óxidos metálicos |

- HP: 8 | Ataque: 20 dano | Cor: Color(0.75, 0.28, 0.03)
- Sem sprite (gera textura 1×1 branca com modulate da cor do boss)
- Drops: S ou Si aleatório ao tomar dano

### Lógica do level_02.gd
- Fade preto de entrada ao carregar a cena
- Intro dialog (3 linhas da Elara sobre a Caldeira Vulcânica)
- Câmera: zoom 3x no hub → 4x na sala alta (transição suave 0.6s)
  - Hub: limit_left=0, limit_top=60, limit_right=2400, limit_bottom=450
  - Sala Alta: limit_left=0, limit_top=-400, limit_right=1650, limit_bottom=-80
- Dark fog: `$DarkAreas/SalaAltaFog` (ColorRect preto z=5) cobre sala alta — some em 1.2s quando player entra (via FogTrigger Area2D)
- Boss trigger: Area2D em (120, -240), shape 160×120px — dispara show_battle("golem")
- Ao vencer: dialog + complete_level(2) + fade → recarrega level_02 (placeholder até level_03 existir)
- Ao perder: dialog sugerindo compostos corretos
- Encyclopedia: primeiro pickup de cada elemento mostra dialog com name/desc/curiosity
- Kill plane: y=620

### Fix feito em boss_battle.gd
Quando boss não tem sprite (campo "sprite" vazio), agora gera uma `ImageTexture` de 1×1 pixel branco e aplica `modulate` com a cor do boss — antes ficava invisível.

---

## Elementos (7 implementados)
H, O, Na, S, Cl, C, Si — todos em `data/elements.json`

## Receitas (6 implementadas)
H2O, SO2, HCl, CO2, NaCl, NaOH — todas em `data/recipes.json`

---

## Batalha de Boss — sistema de reações educativo

### Boss 1 — Lesma Gigante (Level 01, id: "snail")
| Composto | Dano | Efeito | Ensinamento |
|----------|------|--------|-------------|
| NaCl | -2 HP | — | Osmose resseca o muco (fraqueza principal) |
| H2O | +1 HP | heal | Lesmas adoram umidade! |
| HCl | -1 HP | — | Ácido corrói matéria orgânica |
| SO2 | -1 HP | stun | Gás tóxico atordoa |
| CO2 | -1 HP | — | Resfria o muco |
| NaOH | -1 HP | — | Base reage com muco ácido |

### Boss 2 — Golem de Lava (Level 02, id: "golem")
Ver tabela acima.

---

## Próximos passos (N2 — até 22/05/2026)

- [ ] Testar Level 02 no editor (F6 com level_02.tscn aberto) após reimport dos arquivos novos
- [ ] Ajustar posições de pickups e plataformas se necessário após teste
- [ ] Sprite real para o Golem de Lava na batalha de boss (substituir ColorRect 1×1)
- [ ] Level 03 (Complexo Subaquático) — placeholder atual recarrega L02
- [ ] 14 elementos + 10 receitas (pendente)
- [ ] Puzzles ambientais (porta que exige composto específico)

## N3 (03/07/2026)
- 20 elementos
- Level 04
- Boss Level 03: Hidra Ácida (3 cabeças, fraquezas diferentes)
- Polimento geral

---

## Notas técnicas importantes

### Tilemap Level 02 — como funciona
`level_02_tilemap.gd` usa array `TILES: Array` com entradas `[col, row, w, h]` idêntico ao `level_tilemap.gd` do Level 01. Cada entrada gera um `StaticBody2D` com `CollisionShape2D` + `ColorRect` visual. TILE=16px.

### UIDs dos novos arquivos
- `level_02_tilemap.tscn` → `uid://lvl02tilemap`
- `golem_enxofre.tscn` → `uid://golem001`

**ATENÇÃO**: após criar esses arquivos externamente ao editor, é necessário fazer **Project → Reimport All** (ou clicar no 🔄 do FileSystem panel) para o Godot registrar os UIDs no cache. Sem isso, o level_02.tscn não encontra o tilemap correto.

### Câmera Level 02
O `level_02.gd` gerencia a câmera diretamente via `_update_camera()` chamado em `_process()`. A variável `_in_sala_alta` rastreia a zona atual. Transição acontece quando `player.global_position.y < -80.0`.
