# CLAUDE.md — SoldierCarer

Guía operativa para Claude Code. Es el **punto de entrada**: léela antes de cualquier tarea.

## 1. Qué es SoldierCarer (una línea)

Juego **VR en primera persona** de **simulación médica de combate** ambientado en una ciudad en guerra en **2038**: el jugador es un médico de combate que **rescata soldados heridos** (el eje es la medicina, no el combate) mientras se defiende de la Oposición con recursos limitados. **Motor: Godot 4.7 (Forward+) + OpenXR (habilitado)**. Toda la lógica es GDScript; no hay C# pese al `[dotnet]` que trae `project.godot` por defecto.

## 2. Orden de lectura de la documentación (`docs/`)

Antes de programar, lee en este orden. **`docs/` es la fuente de verdad de diseño**; este archivo solo resume las reglas duras.

1. [docs/Contexto.md](docs/Contexto.md) — visión, alcance, estado del repo y **política de placeholders y reporte de faltantes** (§6–§7, obligatorio). Incluye discrepancias D1–D5 (§8).
2. [docs/Requisitos.md](docs/Requisitos.md) — RF y RNF con IDs trazables (`RF-XX`, `RNF-XX`).
3. [docs/Arquitectura.md](docs/Arquitectura.md) — estructura Godot, convenciones de nodos/scripts, autoloads (`EventBus`, `GestorJuego`, `GestorAudio`), señales y FSM.
4. [docs/Personajes.md](docs/Personajes.md) — jugador, heridos y enemigos: comportamientos, FSM, gestos.
5. [docs/UI_ART_Design.md](docs/UI_ART_Design.md) — menús, HUD diegético, escenarios, identidad visual y paleta.
6. [docs/Planificacion_Sprints.md](docs/Planificacion_Sprints.md) — roadmap Scrum (S0–S11), GitFlow y commits semánticos.
7. [docs/Elementos_Faltantes.md](docs/Elementos_Faltantes.md) — documento **vivo** de placeholders; actualizar al cierre de cada sprint.
8. [Controles.md](Controles.md) (raíz del repo, no en `docs/`) — referencia de controles VR y de escritorio (fallback sin headset): tabla de acciones por modo, detección automática de OpenXR en `jugador.gd._inicializar_openxr()`, y notas de casos borde (p. ej. el mouse deja de rotar la cámara con un ítem del kit equipado). Consulta antes de tocar input del jugador, gestos de tratamiento o el menú de pausa.

## 3. Reglas duras (no negociables)

### 3.1 Placeholders (detalle en `Contexto.md §6`)
- Si falta cualquier asset (modelo, textura, audio, animación, sprite, fuente, icono, clip): **NO te detengas ni inventes el asset final**. Monta un **placeholder funcional** con primitivas de Godot (`CapsuleMesh`/`BoxMesh`/…) y `StandardMaterial3D` de color plano.
- Nodo raíz con prefijo **`PH_`** + `Label3D` cuando ayude. Comentario en código/escena: `# PLACEHOLDER: <qué falta y qué lo reemplaza>`.
- Principio **"swap sin refactor"**: misma jerarquía, nombres y señales que tendrá el asset final; el asset solo sustituye `Mesh`/`Texture`/`Stream`.

### 3.2 Reporte de faltantes
- Al **cerrar cada sprint** (y al introducir cualquier placeholder), actualiza `docs/Elementos_Faltantes.md` (formato `PH-###`). Las entradas resueltas se marcan `Resuelto`, no se borran.

### 3.3 Git — GitFlow (detalle en `Planificacion_Sprints.md §2`; estado real en §4)
- Modelo documentado: `main` (entregables/tags) ← `develop` (integración) ← `feature/*` (una por funcionalidad/sprint). **En la práctica no existe `develop`** (ver §4): las `feature/*` se abren desde `main` y se integran de vuelta a `main` por PR. Sigue el flujo por tarea de abajo igual; solo cambia la rama base/destino.
- **NUNCA** `git push`, ni `merge`/commit directo a `main`, ni borrar ramas. Eso lo hace el encargado a mano.
- Flujo por tarea: implementar → `git add <archivos concretos>` (nunca `git add .` a ciegas) → **entregar/ejecutar `git commit` semántico (sin push)** → dejar la rama `feature/…` **seleccionada** para revisión.
- **Commits semánticos** (Conventional Commits): `feat|fix|docs|refactor|test|chore|perf|style`. **Tipo en inglés, descripción en español**, imperativa, minúscula, sin punto final. Ej.: `feat: agregar locomoción por teletransporte con OpenXR`.

### 3.4 Convenciones de código
- **Nomenclatura en español**: nodos, scripts, variables, señales y estados de FSM (coherente con la demo: `AVANCE`, `ESQUIVA`, `NEUTRALIZADO`, señal `disparo_realizado`, `neutralizado`).
- Nodos `PascalCase`; scripts `snake_case.gd`; señales `snake_case`; FSM por `enum Estado {…}` + `match estado_actual:`.
- Estructura: `scripts/<Sistema>/<archivo>.gd`, escenas en `views/`. Un sistema = un directorio. Parámetros de balanceo con `@export`.
- **Comentarios y `print()` de depuración en español** — mantén esta convención al editar.

## 4. Estado real del repositorio (importante — difiere de lo que asumen los docs)

- **Rama actual: `main`.** `develop` **nunca se creó**: en la práctica, cada `feature/<sistema>` se abrió desde `main` y se integró de vuelta a `main` por Pull Request (`git log --merges` muestra `Merge pull request #N from .../feature/...` directo a `main`). Sigue esta convención real, no el modelo `main ← develop ← feature/*` que describe `Planificacion_Sprints.md §2.1`, salvo que el encargado indique lo contrario.
- `main` ya contiene **todo el gameplay**, no solo menú y arte: los sprints **S0–S10** del roadmap (`Planificacion_Sprints.md §3`) están implementados (rig VR/OpenXR, mapa de muñeca, kit médico, sistema de heridos, combate/pistola, HUD, escenarios E1/E2, audio, menús, game loop y puntuación). Falta **S11 (pulido, balanceo y rendimiento)**. Antes de asumir que algo "no existe todavía", revisa `docs/Elementos_Faltantes.md` (estado `Resuelto`/`En producción`/`Pendiente` por ítem) y `docs/Arquitectura.md §5` (bitácora de qué se implementó en cada sprint y qué contratos/señales preservar).
- `project.godot`: `config/name="SoldierCarer"` (ya renombrado); `config/features=("4.7","Forward Plus")`; Jolt Physics; **`[xr] openxr/enabled=true`** (pero **sin verificar en headset real** — se implementó y probó solo en editor, sin hardware VR disponible; revisar antes de dar por cerrado cualquier sprint que lo toque). Escena principal = [views/main_menu.tscn](views/main_menu.tscn) (`uid://bmorjhsg5xpq2`).
- Autoloads registrados: `EventBus`, `GestorAudio`, `GestorOpciones`, `GestorJuego` (`project.godot [autoload]`) — ver contratos de señales/propiedades en `docs/Arquitectura.md §4`.
- Herramientas de calidad agregadas (`chore: agregar gdtoolkit y GUT`, commit `e146fa1`): linter `gdlint` (config `.gdlintrc`) y framework de tests `GUT` (`addons/gut/`, config `.gutconfig.json`, tests en `test/unit/`). Ver §5 para cómo correrlos.

## 5. Comandos

No hay build (Godot no compila un binario propio del proyecto); estos son los comandos reales disponibles en este entorno (`godot` en `PATH`, versión `4.7.stable`):

- **Correr el juego (headless-incompatible, requiere entorno gráfico):** `godot --path .` desde la raíz del repo, o abrir `project.godot` en el editor y ejecutar la escena principal.
- **Lint (`gdlint`, gdtoolkit — no vendorizado, instalar con `pip install gdtoolkit` si falta):**
  ```bash
  gdlint scripts/
  ```
  Reglas en `.gdlintrc` (orden de declaraciones, `snake_case`/`PascalCase`, límite de 100 columnas y 1000 líneas por archivo, etc.). No hay `gdformat` configurado como obligatorio; úsalo solo si el encargado lo pide.
- **Tests (GUT, headless):**
  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
  ```
  Directorio de tests: `test/unit/` (config en `.gutconfig.json`). Solo existe `test/unit/test_ejemplo.gd` (placeholder marcado explícitamente para reemplazar al escribir los primeros tests reales de gameplay) — no hay suite real todavía.
- No hay pipeline de CI (`.github/` no existe en este repo); lint y tests son manuales.

## 6. Cómo trabajar el proyecto Godot

- Es un proyecto Godot 4.7: gran parte del "código fuente" son escenas `.tscn` y recursos, no solo scripts. Para entender una feature, lee el `.tscn` junto a sus `.gd` (estructura de nodos, propiedades exportadas y conexiones de señal viven en la escena).
- GDScript se valida al parsear/ejecutar en el editor o vía `gdlint` (§5); no hay compilación separada.
- Los `.blend` se importan directamente como `PackedScene` (importador Blender de Godot); no hay export/bake aparte en el repo. Los `.import` son metadatos generados — **no editar a mano**; se regeneran solos.
- `.godot/` y `/android/` están gitignored (`.gitattributes` fuerza LF). `*.blend1` (backups Blender) **no** están gitignored pese a lo que asumen otros docs: hay ~11 trackeados en `assets/` — no es un descuido para limpiar, revisa con el encargado antes de borrarlos o agregar la regla.
- **Menú principal (patrón existente a respetar):** los botones 3D (`scripts/MainMenu/btn_play.gd`, `btn_options.gd`, `btn_exit.gd`) son `Area3D` que conectan `input_event`, detectan clic izquierdo (`InputEventMouseButton`) y animan con la API `Tween` (`tween_property`/`tween_callback`, `set_parallel`) — **no** `AnimationPlayer`. La coordinación entre botones es por búsqueda directa de nodos hermanos. Al añadir elementos interactivos similares fuera de VR, sigue este patrón Area3D + Tween; dentro de la misión (VR), el patrón equivalente es apuntar+seleccionar con el controlador por proximidad (ver `mapa_muneca.gd`, `kit_medico.gd`).
- **Patrón de FSM (todo agente con comportamiento):** `enum Estado {…}` + `var estado_actual` + `match estado_actual:` en `_physics_process`, con un método `_cambiar_estado()` que también actualiza el `Label3D` de depuración. `enemigo_base.gd` (`class_name EnemigoBase`) centraliza lo común entre `enemigo_arma.gd`/`enemigo_cuchillo.gd` (salud, `recibir_dano()`, señal `neutralizado`); cada subclase mantiene su propio `enum Estado` y solo implementa los ganchos virtuales. Sigue este patrón (base + ganchos) al agregar un nuevo tipo de agente en vez de duplicar la FSM.
- **Comunicación entre sistemas:** por señales locales (`disparo_realizado(rayo)`, `neutralizado`, `herido_estabilizado(herido)`) o por el autoload `EventBus`; evita que un nodo busque la ruta interna de otro. Búsqueda de nodos por grupo (`"jugador"`, `"enemigos"`, `"heridos"`), no por `get_node()` con ruta absoluta entre sistemas distintos.
- Arte y paleta documentados en [assets/README.md](assets/README.md); assets por dimensionalidad en `assets/2D`, `assets/3D`, `assets/Escenarios`, `assets/Fondos`.

## 7. Decisiones aún abiertas

Confirmadas o no-bloqueantes: **D2** (2 escenarios, ya implementado), **D4** (dos amarillos, intencional), **arranque GitFlow** (ver §4 — en la práctica ya se resolvió trabajando directo contra `main`). Quedan abiertas (`Contexto.md §8`, `Elementos_Faltantes.md §2`):

- **D1 duración de misión:** implementado como `@export` parametrizable con base **10 min**; confirmar valor final con el encargado.
- **D3 paleta ambiental:** los HEX de `Requisitos`/Concepto no coinciden con sus etiquetas; se usa la paleta corregida de `UI_ART_Design.md §2`. Confirmar con arte antes de dar la paleta por definitiva. (La paleta **funcional** semafórica rojo/amarillo/verde/azul de heridos/HUD es correcta y no se toca.)

## 8. Prioridad de diseño

El eje es la **medicina, no el combate**. Ante decisiones de alcance o pulido, prioriza que las **mecánicas médicas** y la **navegación VR sin mareo** (teletransporte, RNF-04) funcionen y se sientan bien, por encima del combate, que es un recurso secundario.
