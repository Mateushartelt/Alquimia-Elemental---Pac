# PRD — Alquimia Elemental
> Última atualização: 2026-03-21

## Visão geral
Jogo 2D educativo (plataformer + batalha por turno) que ensina química para alunos do 6º EM ao 3º EM.
Desenvolvido em Godot 4.6 + GDScript. PAC IV — Católica de Santa Catarina.

---

## Estado atual (Sprint N1 — deadline 03/04/2026)

### Sistemas implementados e funcionando
| Sistema | Descrição |
|---------|-----------|
| Plataformer | Movimento, pulo, coyote time (0.12s), jump buffer (0.12s) |
| Inventário | Coleta de elementos → GameState → HUD atualiza via sinais |
| Alquimia | Painel Q com 3 slots, tutorial guiado H2O |
| Projéteis | Ataque J/click, dispara composto ativo |
| Inimigos | SlimeSodio — patrulha, chase, fraqueza a H2O, dropa Na |
| Checkpoint | Salva posição, dialog de Elara |
| HUD | Barra de vida + inventário de elementos + composto ativo |
| Tabela Periódica | Tecla TAB, posições reais período/grupo, desbloqueio visual |
| Tutorial | Legendas sequenciais guiando o jogador (movimento → alquimia → ataque) |
| Menu Principal | Tela de título com botão Jogar |
| Game Over | Tela de morte com reinício |
| Tilemap | LevelTileMap procedural — 500 tiles (8000px), 30 plataformas em 4 seções |
| **Batalha de Boss** | **Combate estilo Pokémon contra Lesma Gigante (NaCl)** |
| **Level 01 Metroidvania** | **Salas fechadas, shaft vertical wall jump, dark areas, transição para L02** |
| **Level 02** | **Template "Caldeira Vulcânica" — S, Si, O, bg laranja** |
| **Wall Jump** | **WALL_SLIDE state, wall jump com impulso lateral, tint azul** |

### Batalha de Boss — detalhes
- Boss: Lesma Gigante, 6 HP, contra-ataca com 15 de dano
- Fluxo: chega no x=1700 → tela de batalha abre → compostos já criados aparecem como botões → clica no composto → "Atacar com X" → reação visível → próximo turno
- Painel de Mistura colapsível (botão "Misturar ▼"): só abre quando o jogador precisa craftar algo novo durante a batalha
- Botão ℹ abre popup com dica educativa sobre o boss

**Sistema de Reações (educativo):**
| Composto | Dano | Efeito | Ensinamento |
|----------|------|--------|-------------|
| NaCl | -2 HP | — | Osmose resseca o muco (fraqueza principal) |
| H2O | +1 HP (cura boss) | heal | Lesmas adoram umidade! Escolha errada = aprendizado |
| HCl | -1 HP | — | Ácido corrói matéria orgânica |
| SO2 | -1 HP | stun (pula próximo ataque) | Gás tóxico atordoa |
| CO2 | -1 HP | — | Resfria o muco |
| NaOH | -1 HP | — | Base forte reage com muco ácido |

- Pickups antes do boss: 3×Na, 3×Cl, 4×H, 3×O, 1×C — material para todas as receitas

### Corrigido nesta sessão
- **UI cortada no boss**: Substituído `ColorRect + MarginContainer(FULL_RECT)` por `PanelContainer` no painel de ação — agora auto-dimensiona quando o painel de mistura expande
- **Boss dropa elementos**: Quando a lesma toma dano (dmg > 0), solta aleatoriamente Na ou Cl via `GameState.collect_element()` — elemento aparece no próximo turno para o player poder craftar mais NaCl

### Removido nesta sessão
- **QuizModal** removido (professor pediu foco na mecânica de mistura, não quiz separado)
  - Arquivos deletados: `quiz_modal.gd`, `quiz_modal.tscn`
  - Referências removidas de `level_01.gd` e `level_01.tscn`

---

## Elementos (7 implementados)
H, O, Na, S, Cl, C, Si — todos em `data/elements.json`

## Receitas (6 implementadas)
H2O, SO2, HCl, CO2, NaCl, NaOH — todas em `data/recipes.json`

---

## Próximos passos (N1 — até 03/04/2026)

- [ ] AnimationPlayer no player (idle, walk, jump sprites)
- [ ] Segundo inimigo: `golem_enxofre.gd` (fraco a H2O e CO2)
- [ ] Level 02 (Caldeira) com Na, S como elementos principais
- [ ] Sprite real da Lesma para a batalha de boss (substituir ColorRect)
- [ ] Animação de morte da Lesma na batalha

## N2 (22/05/2026)
- 14 elementos + 10 receitas
- Puzzles ambientais nos levels 2–3
- Segundo boss com fraqueza diferente

## N3 (03/07/2026)
- 20 elementos
- Level 04
- Polimento geral
