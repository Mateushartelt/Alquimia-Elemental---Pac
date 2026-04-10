# Handoff — Alquimia Elemental (Level 01)

Este documento descreve tudo que foi implementado/modificado no projeto para continuidade por outro Claude.

---

## Visão Geral do Jogo

Metroidvania 2D educativo em **Godot 4.6 + GDScript**. Ensina química para alunos do 6º ao 3º EM.  
Viewport: 320×180 × escala 4 → display 1280×720. Camera zoom = Vector2(3,3).  
Autoloads: `GameState`, `ElementDatabase`, `SaveManager`.

---

## Sistema de Fogo (Level 01) — o mais complexo

### Arquivos
- `scenes/levels/level_01.gd` — lógica principal
- `scenes/world/fire_wall.gd` — obstáculo estático central (visual apenas)

### Como funciona
O fogo é um conjunto de segmentos dinâmicos (`Node2D` criados em código), cada um com:
- `CPUParticles2D` para visual de chamas
- `Area2D` chamado `"FireDmg"` com `collision_layer=32, collision_mask=1|16`

**Variáveis-chave em `level_01.gd`:**
```gdscript
const FIRE_SPREAD_INTERVAL := 3.5    # segundos entre expansões
const FIRE_STOP_X          := 450.0  # limite esquerdo (portal)
const FIRE_STOP_RIGHT_X    := 1750.0 # limite direito (antes dos inimigos)
const FIRE_SEG_W           := 48     # largura de cada segmento
const FIRE_ORIGIN_X        := 1352.0 # onde o fogo nasce
var _fire_segments    : Array = []   # segmentos ativos
var _fire_occupied    : Dictionary = {} # float(x) → true
var _player_fire_count: int = 0      # quantos segmentos o player está tocando
```

**Expansão por adjacência** (em `_process`):
- Coleta posições adjacentes a fogos existentes que estejam livres
- Prioridade: **lacunas** (posição com fogo dos dois lados) → preenche todas
- Senão: expande a posição mais à esquerda E mais à direita simultaneamente
- Ao apagar um segmento: `_fire_timer = 0.0` (reseta o intervalo, dá respiro ao jogador)

**Dano:**
- `body_entered` → `receive_damage(25)` (ativa hurt animation)
- Timer periódico a cada 0.5s → `GameState.take_damage(25)` **bypassa invencibilidade**
- Velocidade do player limitada a ±50px/s enquanto em contato com fogo

**Conclusão da fase:**
- `_extinguish_segment()` remove segmento e verifica `_fire_segments.is_empty()`
- Se vazio e `not _fire_cleared` → chama `_on_fire_extinguished()`
- O `FireWall` (nó estático em x=1400) **não** está conectado ao `_on_fire_extinguished` — foi desconectado intencionalmente. Ele apenas desaparece visualmente ao receber H2O.

**Persistência entre cenas** (ao ir para tutorial e voltar):
- `GameState.fire_next_x` guarda a fronteira esquerda mais baixa
- Na restauração (`_came_from_tutorial`): rebuild do fogo de FIRE_ORIGIN_X para fora até atingir `target_x`
- **IMPORTANTE**: salvar `target_x` em variável local ANTES de chamar `_spawn_fire_segment`, pois cada chamada atualiza `GameState.fire_next_x`

**Câmera e fogo:**
- `limit_right` começa em `FIRE_ORIGIN_X + FIRE_SEG_W` (1400)
- A cada `_spawn_fire_segment(at_x)`: `limit_right = max(limit_right, at_x + FIRE_SEG_W)`
- Ao apagar tudo (`_run_portal_explosion`): `limit_right = 3200`

---

## Cinemática de Abertura

`_run_opening_cinematic()` em `level_01.gd`:
1. Camera faz pan para o fogo em x=1400
2. Spawna 4 segmentos em posições explícitas:
   - `FIRE_ORIGIN_X` (1352) e `FIRE_ORIGIN_X + FIRE_SEG_W` (1400)
   - `FIRE_ORIGIN_X - FIRE_SEG_W` (1304) e `FIRE_ORIGIN_X + 2*FIRE_SEG_W` (1448)
3. Camera volta ao player

---

## Progressão de Elementos e Inimigos

### Visíveis desde o início (perto do portal em x≈250):
- `Cave_Na` (150, 340) e `Cave_Cl` (100, 340)

### Ocultos até o fogo ser apagado:
- Todos os outros pickups (Rwd_*, Cor_*, Alta_*, Sec_*, UG_*, Hub_*)
- Todos os FireSpirits (Fire01–Fire06)

### Ativação após fogo apagado:
Em `_on_fire_extinguished()`:
```gdscript
for pickup in $Pickups.get_children():
    pickup.visible = true
```

Em `_process` (quando `_fire_cleared`):
```gdscript
for enemy in $Enemies.get_children():
    if not enemy.visible and is_instance_valid(enemy):
        if enemy.global_position.distance_to(player.global_position) < 300.0:
            enemy.visible = true
            enemy.process_mode = Node.PROCESS_MODE_INHERIT
```

FireSpirits no tscn: `visible = false` + `process_mode = 4` (DISABLED).

---

## Portal do Boss

Portal azul em `Vector2(3150, 328)` no final do corredor direito.  
Nó: `DoorBoss` (Area2D) em `level_01.tscn`.  
Conectado a `_on_boss_trigger_entered` → `_boss_battle.show_battle("snail")`.  
Acessível apenas após fogo apagado (além de `FIRE_STOP_RIGHT_X = 1750`).

---

## Boss Battle (boss_battle.gd)

### Sprite da Lesma
- Arquivo: `res://scenes/enemies/assets/snail/idle snail.jpg`  
  **⚠ Precisa ser salvo como PNG** para ter fundo transparente.
- Grid: 4 colunas × 2 linhas = 8 frames
- Sistema: `_start_boss_animation(path, cols, rows)` cria `AtlasTexture` por frame, Timer a cada 0.18s
- `_boss_sprite` é `TextureRect` (substitui o `ColorRect` anterior)

### Estrutura do BOSSES dict
```gdscript
"snail": {
    "sprite":      "res://scenes/enemies/assets/snail/idle snail.jpg",
    "sprite_cols": 4,
    "sprite_rows": 2,
    # ... resto dos campos
}
```

### Layout HP bars
- **Esquerda**: Kael (verde) — alinhado com player sprite no campo (bottom-left)
- **Direita**: Lesma (vermelho) — alinhado com boss sprite no campo (top-right)

### Sprite do Player na batalha
- Ainda é um `ColorRect` azul (placeholder)
- Não existe sprite do Kael ainda — pendente de criação

---

## Câmera (level_01.gd)

| Situação | limit_left | limit_right | zoom |
|---|---|---|---|
| Início (hub) | 800 | dinâmico (fogo) | 3,3 |
| Veio do tutorial | 226 | dinâmico (fogo) | 4,4 |
| No túnel | 0 | dinâmico/3200 | variável |
| Após portal explodir | 0 | 3200 | 3,3 |

---

## Pendências Conhecidas

- [ ] Sprite do Kael para a batalha de boss (apenas ColorRect azul atualmente)
- [ ] Salvar `idle snail.jpg` como **PNG** para remover fundo branco
- [ ] DoorIn (portal azul em x=250) sempre teleporta — deveria só teleportar se H2O não descoberto
- [ ] Camera `limit_left` ainda depende de `_portal_exploded` em alguns lugares

---

## Arquivos Mais Importantes

| Arquivo | Descrição |
|---|---|
| `scenes/levels/level_01.gd` | Lógica do level: fogo, câmera, progressão, boss |
| `scenes/levels/level_01.tscn` | Cena: pickups, enemies, portais, FireWall |
| `scenes/world/fire_wall.gd` | FireWall estático — visual apenas, sem lógica de conclusão |
| `scenes/ui/boss_battle.gd` | UI da batalha Pokémon, sprite da lesma, HP bars |
| `scenes/ui/game_over.gd/.tscn` | Game Over — painel 160→560px |
| `scripts/autoload/game_state.gd` | `fire_next_x` persiste estado do fogo entre cenas |
| `scenes/enemies/assets/snail/` | Sprites da lesma (atualmente JPG, deve ser PNG) |
