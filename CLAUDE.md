# CLAUDE.md — SoldierCarer

Guía operativa para Claude Code. Es el **punto de entrada**: léela antes de cualquier tarea.

## 1. Qué es SoldierCarer (una línea)

Juego **VR en primera persona** de **simulación médica de combate** ambientado en una ciudad en guerra en **2038**: el jugador es un médico de combate que **rescata soldados heridos** (el eje es la medicina, no el combate) mientras se defiende de la Oposición con recursos limitados. **Motor: Godot 4.6 (Forward+) + OpenXR**. Toda la lógica es GDScript; no hay C# pese al `[dotnet]` que trae `project.godot` por defecto.

## 2. Orden de lectura de la documentación (`docs/`)

Antes de programar, lee en este orden. **`docs/` es la fuente de verdad de diseño**; este archivo solo resume las reglas duras.

1. [docs/Contexto.md](docs/Contexto.md) — visión, alcance, estado del repo y **política de placeholders y reporte de faltantes** (§6–§7, obligatorio). Incluye discrepancias D1–D5 (§8).
2. [docs/Requisitos.md](docs/Requisitos.md) — RF y RNF con IDs trazables (`RF-XX`, `RNF-XX`).
3. [docs/Arquitectura.md](docs/Arquitectura.md) — estructura Godot, convenciones de nodos/scripts, autoloads (`EventBus`, `GestorJuego`, `GestorAudio`), señales y FSM.
4. [docs/Personajes.md](docs/Personajes.md) — jugador, heridos y enemigos: comportamientos, FSM, gestos.
5. [docs/UI_ART_Design.md](docs/UI_ART_Design.md) — menús, HUD diegético, escenarios, identidad visual y paleta.
6. [docs/Planificacion_Sprints.md](docs/Planificacion_Sprints.md) — roadmap Scrum (S0–S11), GitFlow y commits semánticos.
7. [docs/Elementos_Faltantes.md](docs/Elementos_Faltantes.md) — documento **vivo** de placeholders; actualizar al cierre de cada sprint.

## 3. Reglas duras (no negociables)

### 3.1 Placeholders (detalle en `Contexto.md §6`)
- Si falta cualquier asset (modelo, textura, audio, animación, sprite, fuente, icono, clip): **NO te detengas ni inventes el asset final**. Monta un **placeholder funcional** con primitivas de Godot (`CapsuleMesh`/`BoxMesh`/…) y `StandardMaterial3D` de color plano.
- Nodo raíz con prefijo **`PH_`** + `Label3D` cuando ayude. Comentario en código/escena: `# PLACEHOLDER: <qué falta y qué lo reemplaza>`.
- Principio **"swap sin refactor"**: misma jerarquía, nombres y señales que tendrá el asset final; el asset solo sustituye `Mesh`/`Texture`/`Stream`.

### 3.2 Reporte de faltantes
- Al **cerrar cada sprint** (y al introducir cualquier placeholder), actualiza `docs/Elementos_Faltantes.md` (formato `PH-###`). Las entradas resueltas se marcan `Resuelto`, no se borran.

### 3.3 Git — GitFlow (detalle en `Planificacion_Sprints.md §2`)
- Modelo: `main` (entregables/tags) ← `develop` (integración) ← `feature/*` (una por funcionalidad/sprint).
- **NUNCA** `git push`, ni `merge`/commit directo a `main`, ni borrar ramas. Eso lo hace el encargado a mano.
- Flujo por tarea: implementar → `git add <archivos concretos>` (nunca `git add .` a ciegas) → **entregar/ejecutar `git commit` semántico (sin push)** → dejar la rama `feature/…` **seleccionada** para revisión.
- **Commits semánticos** (Conventional Commits): `feat|fix|docs|refactor|test|chore|perf|style`. **Tipo en inglés, descripción en español**, imperativa, minúscula, sin punto final. Ej.: `feat: agregar locomoción por teletransporte con OpenXR`.

### 3.4 Convenciones de código
- **Nomenclatura en español**: nodos, scripts, variables, señales y estados de FSM (coherente con la demo: `AVANCE`, `ESQUIVA`, `NEUTRALIZADO`, señal `disparo_realizado`, `neutralizado`).
- Nodos `PascalCase`; scripts `snake_case.gd`; señales `snake_case`; FSM por `enum Estado {…}` + `match estado_actual:`.
- Estructura: `scripts/<Sistema>/<archivo>.gd`, escenas en `views/`. Un sistema = un directorio. Parámetros de balanceo con `@export`.
- **Comentarios y `print()` de depuración en español** — mantén esta convención al editar.

## 4. Estado real del repositorio (importante — difiere de lo que asumen los docs)

- **Rama actual: `main`.** `develop` **todavía no existe**.
- Existen **dos líneas de trabajo**, y la relación es limpia (sin divergencia):
  - `main` contiene el **menú principal** y el **trabajo de arte** (modelos `.blend`, escenario, entidades, armas, colores).
  - `feature/ia-enemigos-demo` = `main` **+ 6 commits de gameplay** (demo de IA). Es un **fast-forward** sobre `main`; incluye `scripts/{Jugador,Enemigos,DirectorDeOleadas,Herido}/` y `views/{Mision,EnemigoArma,EnemigoCuchillo}.tscn`.
- ⚠️ **La demo de gameplay NO está en el working tree de `main`.** Para continuar el desarrollo hay que partir de `feature/ia-enemigos-demo` (ver decisión de arranque GitFlow en §6).
- Los documentos de `docs/`, este `CLAUDE.md` y `IA_SoldierCarer_Resumen_Implementacion.md` están **sin commitear** (untracked).
- `project.godot`: `config/name="New Game Project"` (pendiente renombrar a SoldierCarer); features `("4.6","Forward Plus")`; Jolt Physics; **OpenXR aún NO habilitado** (es trabajo de S1). Escena principal = [views/main_menu.tscn](views/main_menu.tscn) (`uid://bmorjhsg5xpq2`).

## 5. Cómo trabajar el proyecto Godot

- Es un proyecto Godot 4.6: gran parte del "código fuente" son escenas `.tscn` y recursos, no solo scripts. Para entender una feature, lee el `.tscn` junto a sus `.gd` (estructura de nodos, propiedades exportadas y conexiones de señal viven en la escena).
- **No hay pipeline CLI de build/test/lint.** El desarrollo ocurre en el editor de Godot 4.6 (abrir vía `project.godot`, ejecutar la escena principal). GDScript se valida al parsear/ejecutar en el editor.
- Los `.blend` se importan directamente como `PackedScene` (importador Blender de Godot); no hay export/bake aparte en el repo. Los `.import` son metadatos generados — **no editar a mano**; se regeneran solos.
- `*.blend1` (backups Blender), `.godot/` y `/android/` están gitignored. Finales de línea LF vía `.gitattributes`.
- **Menú principal (patrón existente a respetar):** los botones 3D (`scripts/MainMenu/btn_play.gd`, `btn_options.gd`, `btn_exit.gd`) son `Area3D` que conectan `input_event`, detectan clic izquierdo (`InputEventMouseButton`) y animan con la API `Tween` (`tween_property`/`tween_callback`, `set_parallel`) — **no** `AnimationPlayer`. La coordinación entre botones es por búsqueda directa de nodos hermanos (sin autoloads todavía). Al añadir elementos interactivos similares, sigue este patrón Area3D + Tween. En VR (S1) migrará a apuntar+seleccionar con controlador.
- Arte y paleta documentados en [assets/README.md](assets/README.md); assets por dimensionalidad en `assets/2D`, `assets/3D`, `assets/Escenarios`, `assets/Fondos`.

## 6. Decisiones pendientes de confirmar (bloquean/orientan el arranque)

Estas discrepancias entre los docs y el repo real deben resolverse con el encargado (ver también `Contexto.md §8`):

- **Arranque GitFlow.** No hay `develop` y `feature/ia-enemigos-demo` no está integrada. Los docs piden mergear la demo a `develop` como primer paso. Propuesta: crear `develop` desde `feature/ia-enemigos-demo` (fast-forward, arrastra arte + gameplay) y abrir las features de S1+ desde `develop`. **Confirmar antes de crear ramas.**
- **Prioridad del roadmap.** Orden sugerido S1→S2→S3/S4→…→S11 (`Planificacion_Sprints.md §3`). S1 (núcleo VR/OpenXR) es prerequisito de casi todo lo demás.
- **D1 duración de misión:** 20 min (Concepto) vs 10 min (HUD). Implementar `@export` parametrizable (base 10 min), confirmar valor.
- **D2 número de escenarios:** trabajar con **2** (E1 Calle, E2 Edificio); "tres" se toma como error de redacción.
- **D3 paleta ambiental:** HEX no coinciden con etiquetas en el doc de arte; usar paleta corregida de `UI_ART_Design.md §2`. Confirmar con arte. (La paleta **funcional** semafórica rojo/amarillo/verde/azul es correcta y no se toca.)
- **D4 dos amarillos por función:** `#F0C040` sticky notes, `#DAA520` HUD crítico. Intencional, no unificar.
- **Assets ya existentes vs `Elementos_Faltantes.md`:** varios ítems marcados "Pendiente/por definir" ya tienen modelo `.blend` en el repo (kit médico: `bandage`, `alcohol`, `needle`, `pill/tablet`, `skin_stapler`, `kit`; `entities`; `Scene1`; UI 2D: `folder`, `sticky_note`, `neon_background`, `2D_neon_map`). Reconciliar el estado de esas filas al integrar cada asset.

## 7. Prioridad de diseño

El eje es la **medicina, no el combate**. Ante decisiones de alcance o pulido, prioriza que las **mecánicas médicas** y la **navegación VR sin mareo** (teletransporte, RNF-04) funcionen y se sientan bien, por encima del combate, que es un recurso secundario.
