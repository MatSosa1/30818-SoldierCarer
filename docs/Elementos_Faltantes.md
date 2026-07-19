# Elementos Faltantes / Placeholders — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Documento:** Registro vivo de assets/elementos faltantes y sus placeholders
**Versión:** 1.0 (inicial)

> **Documento vivo.** Claude Code lo **actualiza al cierre de cada sprint** (y al introducir cualquier placeholder nuevo), según la política de `Contexto.md §6-§7`. Las entradas resueltas se marcan como `Resuelto`, no se borran (trazabilidad).
>
> Estados: `Pendiente` · `En producción` · `Resuelto`.
>
> **Convención de estados:** `En producción` = el modelo/asset ya existe en `assets/` (`.blend`, textura…) **pero aún no está integrado** en su escena de juego con el swap del placeholder. `Resuelto` = integrado y reemplazando al placeholder en la escena correspondiente.

---

## 1. Registro

> **Nota de reconciliación (2026-07-18):** el modelado va más avanzado que este registro. Los ítems marcados `En producción` **ya tienen `.blend` en `assets/`** pero aún **no están integrados** en su escena de juego (sigue vivo el placeholder). Al integrarlos (swap del placeholder) pasan a `Resuelto`.

| ID | Elemento | Tipo | Dónde se usa | Placeholder actual | Qué se necesita para reemplazar | Sprint | Responsable | Estado |
|---|---|---|---|---|---|---|---|---|
| PH-001 | Manos + uniforme del jugador VR | Modelo 3D + animación | Rig del jugador (`views/Jugador.tscn`) | **[S1]** `views/Jugador.tscn` ya formalizado como rig `XROrigin3D`/`XRController3D` con manos placeholder (`PH_Mano` + `PH_Manga`, `BoxMesh` planos, script `manos_vr.gd` tiñe según `grip`) en los anclajes finales | Existe `assets/3D/entities/medic/Medic.blend` + brazos (`MilitaryLeftArm.png`/`MilitaryRightArm.png`). Falta: verificar si sirve como mano/manga en primera persona o requiere rig dedicado; animaciones de gesto (vendaje, sutura, disparo); swap de `PH_Mano`/`PH_Manga` sin tocar `manos_vr.gd` | S1 | — | En producción |
| PH-002 | Modelo de soldado herido | Modelo 3D + audio | `SoldadoHerido.tscn` | `PH_` cápsula de Godot | Modelo base de soldado disponible (`entities/model.blend`). Falta: variante con heridas/vendajes, posturas de dolor, set de voz (gemidos, ayuda, confirmación) e integración | S4 | — | En producción |
| PH-003 | Modelo Opositor con pistola | Modelo 3D + animación | `views/EnemigoArma.tscn` | Cápsula naranja + `Label3D` | Existen `entities/enemies/Enemy.blend` + `weapons/pistol/pistol.blend`. Falta: animación de disparo e integración (swap de la cápsula) | S5 | — | En producción |
| PH-004 | Modelo Opositor con navaja | Modelo 3D + animación | `views/EnemigoCuchillo.tscn` | Cápsula roja + `Label3D` | Existen `entities/enemies/Enemy.blend` + `weapons/knife/knife.blend`. Falta: animación de embestida e integración | S5 | — | En producción |
| PH-005 | Ítems del kit médico | Modelos 3D | `KitMedico.tscn` | Por definir (primitivas) | Existen `bandage`, `alcohol`, `needle`, `pill`/`tablet`, `skin_stapler`, `kit` en `assets/3D/`. Falta: montarlos en `KitMedico.tscn` con sus gestos | S3 | — | En producción |
| PH-006 | Pistola del jugador | Modelo 3D | `views/Jugador.tscn` → `XROrigin3D/ManoDerecha/Arma` (nodo `Node3D` de anclaje ya creado en S1, sin malla) | Existe `assets/3D/weapons/pistol/pistol.blend`. Falta: funda de cadera + integración con la lógica de disparo/recarga (S5) | S5 | — | En producción |
| PH-007 | Escenario E1 (Calle) | Escenario + props | `Escenario_E1_Calle.tscn` | Piso/luz básicos (demo) | Existe `assets/Escenarios/Scene1/Scene1.blend` + props (`destroyed_car`, `door`, `sofa`, `tree`, `glass_shards`). Falta: montaje final, grafitis, iluminación por zona | S7 | — | En producción |
| PH-008 | Escenario E2 (Edificio) | Escenario + props | `Escenario_E2_Edificio.tscn` | Por crear | Sala rectangular, muebles volcados, vidrios, puertas, escalera, papeleo (reutilizar props de E1 donde aplique) | S7 | — | Pendiente |
| PH-009 | Focos de emergencia | Modelo + luz | E1 y E2 | Por definir | Modelo de foco + luz coloreable por estado (verde/amarillo/rojo) | S4/S7 | — | Pendiente |
| PH-010 | Fuente tipográfica UI | Fuente | Menús y HUD | Fuentes `Caveat`/`Lacquer` en `fonts/` (no son máquina de escribir) | Fuente de máquina de escribir / militar para la estética "documento clasificado" | S9 | — | Pendiente |
| PH-011 | Arte de UI (sticky notes, carpeta, mapa neón, fondo neón, grafiti) | Texturas/UI | Menús, mapa, pausa | `ColorRect`/`Panel` planos | Existen `assets/2D/folder` (+ `confidential.png`), `sticky_note`, `neon_background`. Falta: grafitis e integración final en menús | S9 | — | En producción |
| PH-012 | Música (3 partituras) | Audio | Menú / combate / crítico | Sin stream (nodos cableados) | Música original del equipo por estado | S8 | — | Pendiente |
| PH-013 | SFX (disparos, pasos, ambiente, kit, voz, confirmación) | Audio | Global | Sin stream / beep placeholder | SFX de librerías libres de derechos | S8 | — | Pendiente |
| PH-014 | Mapa 2D de muñeca (arte) | UI/textura | `MapaMuneca.tscn` | Formas planas + iconos simples | Existe `assets/2D/2D_neon_map` (`map.blend` + `final.png`). Falta: iconos de herido finales e integración | S2/S9 | — | En producción |

## 2. Decisiones a confirmar vinculadas (ver `Contexto.md §8`)
- **D1** duración de misión (10 vs 20 min) → parametrizada, confirmar valor.
- **D3** paleta cromática corregida (verde/gris con HEX erróneos) → confirmar con arte.

## 3. Cómo actualizar este archivo (recordatorio para Claude Code)
1. Al introducir un placeholder nuevo, agrega una fila `PH-###` correlativa.
2. Al integrar un asset final, cambia el `Estado` a `Resuelto` (no borres la fila).
3. Refleja el sprint en que se detectó/resolvió.
4. Deja los `Responsable` para que el equipo complete quién produce cada asset.
