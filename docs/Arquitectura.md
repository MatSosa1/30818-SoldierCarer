# Arquitectura — SoldierCarer

**Proyecto:** SoldierCarer · Grupo 6
**Motor:** Godot 4.6.2 + OpenXR
**Documento:** Arquitectura técnica y convenciones de implementación
**Versión:** 1.0

> Esta arquitectura **extiende** lo ya construido en `feature/ia-enemigos-demo`. No reescribir lo existente: integrarse a sus convenciones.

---

## 1. Principios de arquitectura

1. **Modularidad por sistema.** Cada sistema (Jugador, Enemigos, KitMedico, Heridos, Navegacion, HUD, Audio, Menus, GameLoop) vive en su propio directorio de scripts y sus propias escenas.
2. **Comunicación por señales, no por acoplamiento directo.** Los sistemas se comunican preferentemente por `signal` y por un bus de eventos global (autoload `EventBus`), evitando que un nodo conozca la ruta interna de otro.
3. **Escenas componibles.** Todo elemento reusable es una escena `.tscn` instanciable (enemigos, heridos, ítems del kit, focos de emergencia).
4. **Datos fuera del código.** Parámetros de balanceo con `@export`; catálogos (heridas, ítems) como `Resource` (`.tres`) cuando aplique.
5. **VR-agnóstico donde se pueda.** La lógica de mecánicas no debe depender del hardware; la capa OpenXR se aísla en el rig del jugador.

## 2. Convenciones (coherentes con la demo)

- **Idioma:** nombres de nodos, scripts, variables, señales y estados de FSM **en español**.
- **Nodos:** `PascalCase` (`DirectorDeOleadas`, `KitMedico`). Instancias placeholder con prefijo `PH_`.
- **Scripts:** `snake_case.gd` (`director_de_oleadas.gd`).
- **Señales:** `snake_case`, en pasado o sustantivo de evento (`disparo_realizado`, `herido_estabilizado`, `enemigo_neutralizado`).
- **Estados FSM:** `enum Estado { AVANCE, ESQUIVA, EMBESTIDA, DISPARO, NEUTRALIZADO }` + `match estado_actual:`.
- **Grupos:** uso de grupos de Godot para búsquedas (`"jugador"`, `"enemigos"`, `"heridos"`).
- **Constantes/exports:** `@export` para todo lo ajustable (rangos, velocidades, tiempos, umbrales).

## 3. Estructura de carpetas objetivo

```
res://
├── project.godot
├── scripts/
│   ├── Autoloads/
│   │   ├── event_bus.gd            # bus de señales global
│   │   ├── gestor_juego.gd         # estado global de partida (score, tiempo, fin)
│   │   └── gestor_audio.gd         # buses y reproducción de música por estado
│   ├── Jugador/
│   │   ├── jugador.gd              # (existente) rig, rotación, disparo, salud
│   │   ├── manos_vr.gd             # gestos y agarre de controladores
│   │   └── locomocion_teletransporte.gd
│   ├── Enemigos/
│   │   ├── enemigo_base.gd         # FSM y utilidades compartidas (a extraer)
│   │   ├── enemigo_arma.gd         # (existente)
│   │   └── enemigo_cuchillo.gd     # (existente)
│   ├── DirectorDeOleadas/
│   │   └── director_de_oleadas.gd  # (existente)
│   ├── Heridos/
│   │   ├── herido.gd               # (existente, placeholder) → sistema real
│   │   └── estado_herido.gd        # decaimiento de salud por temporizador
│   ├── KitMedico/
│   │   ├── kit_medico.gd           # apertura/gestión de ítems
│   │   ├── item_medico.gd          # base de ítem
│   │   ├── vendas.gd / morfina.gd / alcohol.gd / suturas.gd / analgesicos.gd
│   │   └── secuencia_tratamiento.gd
│   ├── Navegacion/
│   │   └── mapa_muneca.gd          # mapa 2D, iconos, selección y teletransporte
│   ├── Arma/
│   │   └── pistola.gd              # holster, munición, disparo, recarga
│   ├── HUD/
│   │   ├── hud_mision.gd           # temporizador, cargador, confirmación
│   │   └── pantalla_dano.gd        # tinte rojo de salud
│   ├── Menus/
│   │   ├── menu_principal.gd
│   │   ├── menu_opciones.gd
│   │   ├── menu_pausa.gd
│   │   └── MainMenu/btn_play.gd    # (existente, modificado)
│   └── Escenarios/
│       └── gestor_escenarios.gd    # carga/activa E1 y E2
├── views/                          # escenas (.tscn) — nomenclatura existente
│   ├── Mision.tscn                 # (existente)
│   ├── EnemigoArma.tscn            # (existente)
│   ├── EnemigoCuchillo.tscn        # (existente)
│   ├── Jugador.tscn                # rig VR (a formalizar)
│   ├── KitMedico.tscn
│   ├── SoldadoHerido.tscn
│   ├── MapaMuneca.tscn
│   ├── Pistola.tscn
│   ├── Escenario_E1_Calle.tscn
│   ├── Escenario_E2_Edificio.tscn
│   └── Menus/ (MenuPrincipal.tscn, MenuOpciones.tscn, MenuPausa.tscn)
├── recursos/                       # .tres (catálogos, perfiles de herida, config)
├── assets/                         # modelos, texturas, audio finales
│   ├── modelos/  texturas/  audio/  fuentes/  ui/
└── placeholders/                   # geometría/marcadores temporales reutilizables
```

> **Nota:** la demo usa `scripts/<Sistema>/` y `views/` para escenas. Se mantiene esa convención. No mover archivos existentes sin necesidad; agregar los nuevos siguiendo el patrón.

## 4. Autoloads (singletons)

| Autoload | Responsabilidad | Notas |
|---|---|---|
| `EventBus` | Señales globales desacopladas entre sistemas. | **Creado en S2** (`scripts/Autoloads/event_bus.gd`, registrado en `project.godot`) con `solicitar_teletransporte(punto_destino, escenario)` y `escenario_activado(escenario)`. **S4** sumó `herido_estabilizado(herido: Node)` (payload es el nodo, no un `id` dedicado). `herido_muerto(id)` y `mision_terminada(resultado)` se agregan cuando tengan consumidor real (S10). |
| `GestorJuego` | Estado de partida: score, tiempo restante, condición de fin, escenario activo. | **Creado en S10** (`scripts/Autoloads/gestor_juego.gd`) — era el último autoload documentado que faltaba. `tiempo_restante`/`rescates`/`mision_activa`; señales `tiempo_actualizado(segundos)` y `mision_finalizada(resultado, rescates)`. Escenario activo lo sigue llevando `GestorEscenarios` (no duplicado aquí); `GestorJuego` solo pausa su simulación al terminar la misión, vía `pausar_activo()`. |
| `GestorAudio` | Buses, música por estado (menú/combate/crítico), disparo de SFX. | **Creado en S8** (`scripts/Autoloads/gestor_audio.gd`) con `cambiar_estado(EstadoMusica)` y un único `AudioStreamPlayer`. Solo centraliza la **música** (única/global por naturaleza); los SFX puntuales (disparos, pasos, kit, heridos) usan su propio `AudioStreamPlayer3D` cableado localmente en cada escena para conservar su posición 3D — no pasan por este autoload. Sin buses de audio personalizados todavía (usa el bus `Master` por defecto). |
| `GestorOpciones` | Ajustes de accesibilidad/confort VR y audio general (RNF-05, RF-38). | **No estaba en la lista original**; se agregó en **S9** (`scripts/Autoloads/gestor_opciones.gd`) porque la opción de Accesibilidad "intensidad de teletransporte" necesitaba un efecto real, no solo un rótulo. Expone `intensidad_teletransporte` (afecta el fundido a negro del teletransporte, ver §8) y `volumen_master` (bus `Master`). Audio/Gráficos/Controles del menú de opciones siguen sin sistema que configurar (`PH-015`). |

## 5. Inventario del código existente (demo) y cómo integrarse

De `IA_SoldierCarer_Resumen_Implementacion.md`:

**Archivos nuevos de la demo**
- `scripts/Jugador/jugador.gd` — `CharacterBody3D` fijo en el origen; rota en yaw con mouse; dispara con clic izquierdo (raycast propio), emite `disparo_realizado(rayo)` y aplica daño vía `recibir_dano()`; expone su propio `recibir_dano()`, barra de salud simple, feedback rojo (`ColorRect` + `Tween`), mira central y trazador visual.
- `scripts/Enemigos/enemigo_cuchillo.gd` y `enemigo_arma.gd` — FSM `enum` + `match`; estados `AVANCE/ESQUIVA/EMBESTIDA/DISPARO/NEUTRALIZADO`; cada uno expone `recibir_dano()` y señal `neutralizado`; `Label3D` de estado en vivo.
- `scripts/DirectorDeOleadas/director_de_oleadas.gd` — instancia parejas en `Marker3D` por carril; mantiene `enemigos_activos` y `score`; escala dificultad cada 3 bajas (`umbral_escalado`).
- `scripts/Herido/herido.gd` — **placeholder**: cápsula con curación rudimentaria condicionada a zona despejada (`enemigos_activos == 0`) y a que el jugador lo enfoque (comparación de rumbo **horizontal**, ignorando eje Y porque el jugador solo rota en yaw).
- `views/Mision.tscn`, `views/EnemigoArma.tscn`, `views/EnemigoCuchillo.tscn` — primitivas, sin assets finales.

**Archivo modificado**
- `scripts/MainMenu/btn_play.gd` — botón "Play" enlazado a `res://views/Mision.tscn`.

**Señales/contratos ya existentes a respetar**
- `disparo_realizado(rayo)` (jugador → enemigos cuchillo para esquiva reactiva).
- `neutralizado` (enemigo → `DirectorDeOleadas` para score y conteo).
- Búsqueda por grupo `get_first_node_in_group("jugador")`.

**Deuda técnica conocida a atender**
- ~~El jugador de la demo es no-VR (rota con mouse). En S1 se debe evolucionar a rig OpenXR conservando el contrato de disparo.~~ **Resuelto en S1** (rama `feature/vr-core`, pendiente de commit manual): `views/Jugador.tscn` ahora es un rig `CharacterBody3D` → `XROrigin3D` → `XRCamera3D` + `XRController3D` (izq./der.) formalizado como escena propia e instanciado en `Mision.tscn`. Contratos preservados: señal `disparo_realizado(rayo)`, `recibir_dano()`, grupo `"jugador"`. El disparo pasa de clic de mouse a `trigger_click` del controlador derecho (`scripts/Jugador/jugador.gd`); las manos VR usan `scripts/Jugador/manos_vr.gd` con malla placeholder `PH_Mano`/`PH_Manga` que reacciona al `grip`. **Cambio de contrato no cubierto por la nota original:** `scripts/Herido/herido.gd` accedía a `jugador.get_node("Camera3D")`; se actualizó a `jugador.get_node("XROrigin3D/Camera3D")` porque la cámara ahora vive bajo el nuevo `XROrigin3D`. OpenXR habilitado en `project.godot` (`[xr] openxr/enabled=true`). **Sin verificar en headset real** (sin hardware VR disponible durante la implementación); revisar en el editor Godot 4.6/4.7 con runtime OpenXR antes de dar por cerrado el sprint.
- Orden de nodos en escena importa (`_ready()` por orden de hermanos): `Jugador` antes que `Herido`. Mantener este orden al recomponer `Mision.tscn` (se mantuvo al instanciar `Jugador.tscn`).
- ~~Extraer un `enemigo_base.gd` común para no duplicar la FSM entre arma y cuchillo (refactor en S5, sin cambiar comportamiento observable).~~ **Resuelto en S5**, ver más abajo.

**Implementado en S5** (rama `feature/combate-pistola`, pendiente de commit manual) — combate y arma (RF-25..RF-28) + refactor de enemigos:
- `scripts/Enemigos/enemigo_base.gd` (`class_name EnemigoBase`, `extends CharacterBody3D`) — centraliza `signal neutralizado`, `salud`/`salud_maxima`, `jugador`/`etiqueta_estado` (`@onready`), `_ready()`, `recibir_dano()` y `_neutralizar()` (parte genérica: colisión off, invisible, `set_physics_process(false)`, emitir señal). Cada subclase (`enemigo_arma.gd`, `enemigo_cuchillo.gd`) conserva **su propio** `enum Estado` (distinto entre ambas) y el `match` de `_physics_process()` intacto; solo implementan los ganchos virtuales `_esta_neutralizado()`, `_marcar_neutralizado()` y `_actualizar_etiqueta()`. `enemigo_cuchillo.gd` llama `super._ready()` (único caso que sobreescribe `_ready()`, para sumar la conexión a `disparo_realizado`). **Sin cambios de comportamiento observable** — mismos umbrales, mismas transiciones, mismas señales; solo reordena una línea (`_actualizar_etiqueta()` antes de la conexión a `disparo_realizado` en vez de después, sin efecto porque no hay dependencia entre ambas).
- `scripts/Arma/pistola.gd` + nodos en `Jugador.tscn` bajo `XROrigin3D/ManoDerecha/Pistola` — extracción (RF-25) por proximidad de la mano derecha a `PuntoFunda` (`Marker3D`, hermano fijo de `ManoDerecha` bajo `XROrigin3D`, cadera derecha; mismo patrón que `KitMedico`/mochila en S3 pero en el lado derecho, así que no compiten). Alternancia por **flanco** (edge-triggered: solo togglea `en_mano` al *entrar* al radio, no mientras la mano permanece cerca) para no destellar. Munición 7/cargador × 3 cargadores (RF-26); recarga (RF-28) con el botón `ax_button` de la mano izquierda, solo con la pistola en mano. Indicador `Label3D` de cargador visible solo con `en_mano == true` (RF-27).
- **`jugador.gd`** ya no posee el `RayCast3D` del arma directamente: `disparar()` delega en `pistola.intentar_disparar()`, que devuelve el `RayCast3D` si hubo tiro real (pistola en mano y con balas) o `null` si no. **Refinamiento de contrato:** `disparo_realizado(rayo)` ahora solo se emite en tiros reales, no en cada pulsación del gatillo (antes, sin sistema de munición/funda, cualquier click disparaba). Esto es correcto respecto a RF-25/RF-26, pero cambia cuándo el cuchillo recibe su oportunidad de esquivar (solo balas de verdad, no gatillazos en vacío/sin desenfundar).
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores).

## 6. Máquina de estados (patrón estándar del proyecto)

Todos los agentes con comportamiento usan el mismo patrón:

```gdscript
enum Estado { AVANCE, ESQUIVA, EMBESTIDA, DISPARO, NEUTRALIZADO }
var estado_actual: Estado = Estado.AVANCE

func _physics_process(delta: float) -> void:
    match estado_actual:
        Estado.AVANCE:      _procesar_avance(delta)
        Estado.DISPARO:     _procesar_disparo(delta)
        Estado.ESQUIVA:     _procesar_esquiva(delta)
        Estado.EMBESTIDA:   _procesar_embestida(delta)
        Estado.NEUTRALIZADO: pass  # inerte

func _cambiar_estado(nuevo: Estado) -> void:
    estado_actual = nuevo
    # actualizar Label3D de depuración
```

El **sistema de heridos** y la **secuencia de tratamiento** usan también FSM (p.ej. `ESTABLE → CRITICO → AGONIZANTE → MUERTO` para el herido; `SIN_ATENDER → LIMPIANDO → SUTURANDO → VENDANDO → ESTABILIZADO` para el tratamiento).

## 7. Flujo de escenas

```
MenuPrincipal.tscn ──(Jugar: fade a negro)──► Mision.tscn
        ▲                                          │
        │◄──────(Pausa → Salir)────────── MenuPausa (overlay flotante)
        │                                          │
MenuOpciones (overlay, misma escena)        GestorEscenarios activa
                                            E1_Calle / E2_Edificio
                                            según selección del mapa
```

- `Mision.tscn` es la escena raíz de juego; contiene `Jugador` (rig VR), `GestorEscenarios`, `DirectorDeOleadas`, contenedor `Enemigos`, `Heridos`, HUD y audio.
- Los escenarios E1/E2 se cargan/activan por `GestorEscenarios`; el teletransporte del mapa reposiciona al jugador y activa el escenario destino.

**Implementado en S6** (rama `feature/hud-mision`, pendiente de commit manual) — HUD y feedback (RF-05, RF-34, RF-35, RF-36; RF-27 ya cubierto en S5):
- `scripts/HUD/pantalla_dano.gd` (`class_name PantallaDano`, `extends ColorRect`) — se adjunta directamente a `UI/PantallaDanio`; `jugador.gd.recibir_dano()` ahora solo llama `pantalla_danio.mostrar_dano()` en vez de manipular el `Tween`/color a mano. RF-05: la comunicación real de daño es este tinte, **sin barra numérica**; `UI/EtiquetaSalud` se conserva pero documentada como ayuda de debug, no como el feedback exigido por el requisito.
- `scripts/HUD/hud_mision.gd` — temporizador de misión (RF-34) con parpadeo rojo en el último minuto; confirmación "+RESCATE" (RF-35, escucha `EventBus.herido_estabilizado` directo; el sonido reutiliza `Herido/SonidoRescate`, cableado en S4). **Actualizado en S9 (UX) y S10**: pasó de `Control`/`CanvasLayer` a `Node3D` (el HUD 2D no se renderiza en el headset con `use_xr`, ver `§9.3`) y el temporizador dejó de llevar su propio reloj — ahora solo escucha `GestorJuego.tiempo_actualizado`, que es quien lleva el tiempo real (S10, ver `§9.4`).
- **RF-36** (HUD mínimo, nada agresivo durante el tratamiento): no se agregó ningún elemento 2D nuevo condicionado al kit médico abierto; el HUD se mantiene igual de discreto que antes (solo temporizador + confirmación puntual).
- **Corrección de tipado transversal** (no exigida por ningún RF puntual, pero necesaria para que el código compile de forma estricta): varias variables introducidas en S2-S5 estaban tipadas como `Node`/`Node3D` genérico pero llamaban métodos definidos solo en el script concreto adjunto (p. ej. `kit_medico: Node3D` seguido de `kit_medico.confirmar_seleccion()`), algo que el analizador estático de GDScript puede marcar como llamada inválida. Se agregó `class_name` a `MapaMuneca`, `KitMedico`, `Pistola`, `Herido` y `PantallaDano`, y se retiparon las variables (`jugador.gd`, `kit_medico._herido_en_rango()`, los `for herido in get_nodes_in_group("heridos")` de `mapa_muneca.gd`/`kit_medico.gd`) para usar esos tipos concretos en vez de `Node`/`Node3D`. **No se tocó código de la demo S0** (`enemigo_arma.gd`/`enemigo_cuchillo.gd`'s `jugador.recibir_dano()`, `director_de_oleadas.gd`, `btn_*.gd`) que tiene el mismo patrón: ya está probado/validado (ver `IA_SoldierCarer_Resumen_Implementacion.md §1`), así que a lo sumo genera advertencias del editor, no errores de compilación; queda fuera de alcance de este sprint tocarlo.
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores) — la corrección de tipado en particular debería confirmarse abriendo el proyecto en el editor (el panel de errores de script lo señala de inmediato si algo quedó mal).

## 8. Sistema de teletransporte y navegación

- El **mapa de muñeca** (`MapaMuneca`) presenta iconos de heridos con color de urgencia y un cursor de selección VR.
- Al confirmar destino: `EventBus.solicitar_teletransporte(punto_destino, escenario)` → `GestorEscenarios` asegura el escenario activo → reposiciona el `XROrigin3D` del jugador → cierra el mapa.
- No hay locomoción continua (RNF-04). El "tiempo por distancia" (RF-42) se calcula al confirmar el salto.

**Implementado en S2** (rama `feature/mapa-navegacion`, pendiente de commit manual):
- `scripts/Navegacion/mapa_muneca.gd` + `views/MapaMuneca.tscn`, instanciado bajo `Jugador.tscn` → `XROrigin3D/ManoIzquierda`. Activación: se muestra mientras la mano izquierda está por encima de `altura_activacion` (RF-06). Muestra un icono por nodo del grupo `"heridos"` (posicionado relativo al jugador, que queda fijo al centro del mapa) más dos iconos fijos `E1`/`E2` para saltar directo de escenario (RF-07/RF-09).
- Selección (RF-08): el gatillo derecho normalmente dispara (`jugador.gd:disparar()`), pero si el mapa está visible, en su lugar llama `MapaMuneca.confirmar_seleccion()`, que compara la posición de `ManoDerecha` contra cada icono (radio de tolerancia `radio_seleccion`, RNF-06) y emite `EventBus.solicitar_teletransporte`.
- `scripts/Escenarios/gestor_escenarios.gd`, instanciado en `Mision.tscn`: escucha esa señal, activa/desactiva el contenedor de escenario correcto vía `Node.process_mode = PROCESS_MODE_DISABLED` (pausa recursiva de toda la subrama) y reposiciona al jugador (`jugador.global_position`) al punto recibido, o al `Marker3D PuntoDespliegue` del escenario si el punto es `Vector3.ZERO` (selección directa de escenario, sin herido puntual).
- `Mision.tscn` reestructurada: `Piso`, `Herido`, `DirectorDeOleadas`, `Enemigos` ahora viven dentro de `Escenario_E1_Calle`; se agregó `Escenario_E2_Edificio` con piso + `PuntoDespliegue` placeholder (sin contenido de S7 todavía). `Jugador`, luces y `TrazadorDisparo` siguen siendo globales (fuera de ambos contenedores), ya que el rig del jugador es compartido entre escenarios.
- `herido.gd` ahora hace `add_to_group("heridos")` (grupo documentado en §2 pero no implementado hasta ahora).
- **Bug de orden evitado:** `MapaMuneca` es descendiente de `Jugador` (no hermano); Godot llama `_ready()` de abajo hacia arriba, así que una búsqueda por grupo `get_first_node_in_group("jugador")` dentro de `mapa_muneca.gd` resolvería `null` (el `add_to_group` de `Jugador._ready()` corre después). Se resolvió con una referencia directa por ruta relativa (`get_node_or_null("../../..")`) en vez de por grupo.
- Color de urgencia de los iconos de herido: **gris placeholder** (no hay FSM de salud real todavía, ver `PH-014`); pasa a verde solo si `herido.curado_completo == true`. La urgencia real (verde/amarillo/rojo) llega con el sistema de heridos de S4.
- **Sin verificar en headset real** (mismo motivo que S1, sin hardware VR disponible durante la implementación).

**Implementado en S7** (rama `feature/escenarios`, pendiente de commit manual) — escenarios y ambientación (soporte a RF-09/RF-11 · RNF-01/02):
- **`views/SoldadoHerido.tscn`** (nuevo) — se extrajo el subárbol de `Herido` (que vivía inline en `Mision.tscn` desde S0) a una escena reutilizable, tal como marcaba `Arquitectura.md §3` como pendiente ("a formalizar"). `herido.gd` suma `@export var escenario: String = "E1_Calle"` para que cada instancia declare a qué escenario pertenece.
- **Segundo `SoldadoHerido` en E2** (`escenario = "E2_Edificio"`) — antes E2 estaba vacío (solo plumbing de navegación de S2). `mapa_muneca.gd` ya no fija `"E1_Calle"` a mano para el destino de cada icono de herido (era un `PLACEHOLDER` explícito de S2/S3): ahora lee `herido.escenario`, así que seleccionar el herido de E2 en el mapa activa el escenario correcto.
- **`Escenario_E1_Calle/Ambientacion`** — props de calle (vehículos volcados, bloques de "edificio lateral", grafiti, árboles, escombros), **todas sin `CollisionShape3D`** y posicionadas fuera de los 4 carriles de spawn de `DirectorDeOleadas` (ejes x≈0/z≈0) a propósito, para no interferir con el `move_and_slide()` de los enemigos (que no tienen pathfinding/evasión de obstáculos).
- **`Escenario_E2_Edificio/Estructura`** — caja interior (4 paredes + techo) que bloquea la luz direccional exterior **por sombra** (`cast_shadow` de cada `MeshInstance3D`, sin necesitar colisión), logrando la "baja visibilidad" del diseño sin luces dinámicas extra (cumple RNF-01/02). Piso reescalado a 20×20 (transform, mismo `PlaneMesh` que E1) para el tamaño "sala rectangular" en vez del bloque de calle de 40×40. Mobiliario, puertas y escalera decorativa (no accesible) con primitivas, también sin colisión.
- **Decisión a confirmar (no resuelta en este sprint):** al activar un escenario, `GestorEscenarios` pone `process_mode = PROCESS_MODE_DISABLED` en el contenedor inactivo (mecanismo de S2, pensado originalmente para pausar `DirectorDeOleadas`/enemigos). Ahora que **ambos** escenarios tienen un `SoldadoHerido`, este mismo mecanismo también **congela el temporizador de decaimiento del herido inactivo** (RF-12) mientras el jugador está en el otro escenario — se podría usar para "pausar" a un herido crítico yendo al otro lado del mapa, lo cual podría debilitar la tensión de triaje del pilar 4 (`Contexto.md §2`). Si esto no es el comportamiento deseado, la corrección (decaimiento en tiempo real para heridos fuera de pantalla) es una decisión de balance para S10/S11, no de este sprint.
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores).

**Implementado en S9** — fundido de teletransporte (RNF-05): `GestorEscenarios._al_solicitar_teletransporte` llama `jugador.fundido_teletransporte()` justo después de reposicionar. Ese método (`jugador.gd`) pone `UI/Desvanecido` (nuevo `ColorRect` negro) a alfa 1 instantáneo y lo desvanece con un `Tween` en `GestorOpciones.duracion_fundido()` segundos — oculta el "salto" instantáneo del teletransporte detrás de un flash negro breve, la técnica de confort VR más simple para este problema. `INSTANTANEO` (duración 0) se salta el fundido por completo.

## 9. Sistema del kit médico (resumen técnico)

- `KitMedico` gestiona el inventario de `ItemMedico` (vendas, morfina, alcohol, suturas, analgésicos).
- Cada `ItemMedico` define su **gesto** (patrón de movimiento del controlador) y su **efecto**.
- `SecuenciaTratamiento` valida el orden requerido por la herida (p.ej. alcohol → sutura; vendas como paso base) y emite su propia señal local `estabilizado`; `herido.gd` la escucha y re-emite `EventBus.herido_estabilizado(herido)` al completarse (implementado en S4, ver más abajo).
- Feedback por ítem (RF-24) vía `GestorAudio` + señal visual.

**Implementado en S3** (rama `feature/kit-medico`, pendiente de commit manual):
- `scripts/KitMedico/item_medico.gd` (`class_name ItemMedico`, `extends Node3D`) — base con `enum TipoItem`, `procesar_gesto(delta, mano_derecha, herido) -> bool` (virtual) y `requiere_confirmacion_manual() -> bool`. Cinco subclases por herencia de ruta (`extends "res://scripts/KitMedico/item_medico.gd"`): `vendas.gd` (gira alrededor de la herida, acumula ángulo ≥320°), `alcohol.gd` (inclina la mano >100° sostenido 0.4s), `suturas.gd` (aprieta/suelta el `grip` 3 veces), `morfina.gd`/`analgesicos.gd` (`requiere_confirmacion_manual() == true`: proximidad al herido + gatillo).
- `scripts/KitMedico/secuencia_tratamiento.gd` (`class_name SecuenciaTratamiento`) — FSM `SIN_ATENDER → LIMPIANDO → SUTURANDO → ESTABILIZADO` (nombres tal como los define `Personajes.md §2.4`); morfina/analgésicos no forman parte de la secuencia obligatoria (`aplicar()` siempre devuelve `true` para esos tipos). Se instancia **una por herido** (`herido.gd` la crea como hijo en `_ready()`), no como recurso compartido.
- `scripts/KitMedico/kit_medico.gd` + `views/KitMedico.tscn`, instanciado en `Jugador.tscn` bajo `XROrigin3D` (anclado a la cadera izquierda, posición fija que representa la mochila — **distinta** de `ManoIzquierda`, para no competir con el gesto de "levantar mano" que abre `MapaMuneca`; por construcción geométrica ambos gestos son mutuamente excluyentes, ver comentario en `jugador.gd`). Se abre por proximidad de la mano izquierda; selección de ítem y aplicación de ítems de confirmación manual comparten el gatillo derecho con el mapa y el arma (arbitrados en `jugador.gd._al_presionar_boton_mano`, orden: mapa → kit → disparo).
- **`herido.gd` reescrito**: se retiró la mecánica rudimentaria de la demo S0 (teclas `E`/`T`, "mirar al herido", "zona despejada sin enemigos") — no eran requisitos documentados, solo un hack del prototipo S0. `Herido.aplicar_tratamiento(tipo)` delega en su propia instancia de `SecuenciaTratamiento`; `curado_completo` (contrato ya consumido por `MapaMuneca` desde S2) se actualiza al recibir la señal `estabilizado`. Ya no depende de `DirectorDeOleadas` ni de la cámara del jugador.
- **Sin verificar en editor/headset real** (mismo motivo que S1/S2).

**Implementado en S4** (rama `feature/sistema-heridos`, pendiente de commit manual) — sistema de heridos (RF-11..RF-16), corre en paralelo a la secuencia de tratamiento de S3 sin gatearla:
- `herido.gd` suma `enum EstadoSalud {ESTABLE, CRITICO, AGONIZANTE, MUERTO, ESTABILIZADO}` con decaimiento por temporizador (`@export duracion_estable/critico/agonizante`, RNF-12) independiente de `SecuenciaTratamiento`: el jugador debe completar el tratamiento **antes** de que el temporizador llegue a `MUERTO`, que es la tensión de triaje del pilar 4 de `Contexto.md §2`. `MUERTO` y `ESTABILIZADO` son terminales: `aplicar_tratamiento()` devuelve `false` en ambos (RF-14, ya no rescatable).
- **Foco de emergencia** (RF-11): nodo `Foco` (hijo de `Herido`) con `OmniLight3D` + `SphereMesh` emisivo; color y `light_energy` (parpadeo sinusoidal en `AGONIZANTE`) sincronizados cada frame con `estado_salud`; ambos se ocultan al morir.
- **`EventBus.herido_estabilizado(herido: Node)`** — segunda señal de `EventBus` en implementarse (después de `solicitar_teletransporte` en S2), antes diferida por falta de consumidor real. Payload es el nodo `Herido` mismo, no un `id` numérico dedicado (no existe todavía un esquema de IDs). Consumida por `jugador.gd` para el flash "+RESCATE" (RF-16, nuevo `Label UI/EtiquetaRescate` en `Jugador.tscn`).
- **`mapa_muneca.gd`** deja de usar el color gris placeholder: ahora hace `preload("res://scripts/Herido/herido.gd")` para leer `HeridoScript.EstadoSalud` por reflexión (`herido.get("estado_salud")`, mismo patrón duck-typed que ya usaba para `curado_completo`) y pinta verde/amarillo/rojo real; oculta el icono si `estado_salud == MUERTO` (RF-10).
- ~~Puntuación/pantalla de resultados por rescates (RF-16 parte "S10", RF-44) sigue fuera de alcance: no se creó `GestorJuego` todavía.~~ **Resuelto en S10**, ver `§9.4`.
- **Sin verificar en editor/headset real** (mismo motivo que S1/S2/S3).

## 9.1 Sistema de audio (resumen técnico)

**Implementado en S8** (rama `feature/audio`, pendiente de commit manual) — RF-33, RF-45, RF-46, RF-47 · RNF-15, RNF-16:
- **Música por estado (RF-46):** `GestorAudio.cambiar_estado(EstadoMusica.MENU/COMBATE/CRITICO)`. `jugador.gd` llama `COMBATE` al entrar a `Mision.tscn` y alterna a `CRITICO`/`COMBATE` según `salud <= salud_maxima * umbral_salud_critica` (nuevo `@export`, default 30%) en cada `recibir_dano()`. `scripts/Menus/menu_principal.gd` (nuevo, adjunto al root de `views/main_menu.tscn`) llama `MENU` en `_ready()` — único cambio en ese archivo, que ya tenía props 3D reales integradas por el equipo de arte; no se tocó nada más de su contenido.
- **Audio espacial de enemigos (RF-33/RF-45):** `enemigo_base.gd` suma `SonidoPasos` (`AudioStreamPlayer3D`) con helpers `_reproducir_pasos()`/`_detener_pasos()` (evita reiniciar el loop si ya está sonando); cada subclase los llama en su rama `AVANCE`/no-`AVANCE`. `enemigo_arma.gd` suma `SonidoDisparo` (en `_disparar_rafaga()`), `enemigo_cuchillo.gd` suma `SonidoEmbestida` (en `_atacar_cuerpo_a_cuerpo()`).
- **Disparo/recarga del jugador:** `pistola.gd` suma `SonidoDisparo`/`SonidoRecarga`, reproducidos en `intentar_disparar()`/`recargar()`.
- **Ambiente (RF-47):** `SonidoAmbiente` (`AudioStreamPlayer3D`, `autoplay=true`) en cada contenedor de escenario (`Escenario_E1_Calle`, `Escenario_E2_Edificio`) — no necesita script propio, cubre genéricamente "ambiente urbano"/"explosiones lejanas" hasta que un sprint de pulido (S11) agregue disparo aleatorio de eventos puntuales.
- **RNF-16 (`AudioListener3D`):** no se agregó un nodo `AudioListener3D` explícito. `XRCamera3D` (`Jugador.tscn`) ya tiene `current = true`, y en Godot 4 la cámara 3D activa actúa como listener de audio por defecto — cumple el requisito sin duplicar responsabilidad; agregar un `AudioListener3D` aparte solo tendría sentido si se quisiera desacoplar la posición de escucha de la cabeza del jugador, lo cual no aplica aquí.
- **Sin streams reales todavía** (PH-012/PH-013): todo `AudioStreamPlayer`/`AudioStreamPlayer3D` queda cableado y disparado en el momento correcto, pero sin asset de audio asignado — `.play()` sobre un stream nulo es un no-op seguro (mismo patrón ya usado desde S3).
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores).

## 9.2 Menús y UI (resumen técnico)

**Implementado en S9** (rama `feature/menus-ui`, pendiente de commit manual) — RF-37..RF-40 · RNF-05, RNF-17:
- **RF-37 (menú principal):** ya estaba prácticamente resuelto por el equipo de arte antes de este sprint — carpeta CONFIDENTIAL, notas adhesivas JUGAR/OPCIONES/SALIR, animaciones de apertura/cierre con `Tween` (`btn_play.gd`, `btn_options.gd`, `btn_exit.gd`), interacción por apuntar+clic (`Area3D.input_event`, todavía en mouse, no puntero VR). **No se reconstruyó nada de esto.** Único cambio: `btn_play.gd:cambiar_de_escena()` apunta a `views/EstadoInicial.tscn` en vez de `Mision.tscn` directo (una línea, para intercalar RF-39).
- **RF-38 (opciones — Accesibilidad):** `Contenedor_Opciones` (dentro de `folder`) ya tenía la animación de apertura y el botón `Volver` armados por el equipo; **no se agregaron botones 3D nuevos ahí** — hacerlo a ciegas, sin poder previsualizar en el editor, arriesgaba desalinear la escena ya afinada con arte real (`PH-015`). En su lugar se construyó el *sistema* detrás de la opción con contenido real: `GestorOpciones` (autoload nuevo) con `intensidad_teletransporte` (afecta el fundido de teletransporte, §8) y `volumen_master` (bus `Master`). Audio/Gráficos/Controles quedan sin sistema que configurar todavía (no hay calidad gráfica ni rebinding de controles que ajustar).
- **RF-39 (pantalla de estado inicial):** `views/EstadoInicial.tscn` + `scripts/Menus/estado_inicial.gd`, nuevos. Escena aparte (no VR: usa `Camera3D` plano igual que `main_menu.tscn`, no `XROrigin3D`) con un "documento" placeholder (`BoxMesh` beige + `Label3D` de briefing) y una `Area3D` de continuar (clic, mismo patrón que los botones del menú) con avance automático a los `duracion_maxima` segundos si el jugador no interactúa. Al continuar, carga `Mision.tscn` (que sí trae su propio `Jugador.tscn` con inicialización OpenXR — la transición entre escenas no VR → VR es segura porque cada escena activa `use_xr` en su propio `_ready()`).
- **RF-40 (menú de pausa):** `views/MenuPausa.tscn` + `scripts/Menus/menu_pausa.gd`, instanciado bajo `XROrigin3D/Camera3D` (panel "flotante centrado" que sigue la vista). Se abre/cierra con el botón de menú (`menu_button`) de la mano izquierda (nuevo listener en `jugador.gd`, independiente del que ya usa `pistola.gd` para `ax_button` — mismo patrón de múltiples listeners sobre la misma señal ya usado en el proyecto). **No usa `SceneTree.paused`**: en su lugar llama `GestorEscenarios.pausar_activo(bool)` (nuevo método, mismo mecanismo de `process_mode` que ya pausaba escenarios inactivos desde S2), pausando solo el escenario activo (enemigos/heridos) mientras el rig del jugador —y el propio menú— siguen procesando con normalidad. Esto evita tener que poner `process_mode = PROCESS_MODE_ALWAYS` en cada `XRController3D` solo para que el menú siga recibiendo el gatillo mientras el juego está "pausado". Selección por el mismo patrón proximidad+gatillo de `MapaMuneca`/`KitMedico`. Incluye un mini mapa táctico (posiciones de heridos relativas al jugador, mismo color semafórico) y el botón OPCIONES cicla `GestorOpciones.intensidad_teletransporte` directamente (sin sub-menú separado). El "fondo desenfocado" del diseño original se simplificó a un panel oscuro sólido, sin blur real (`PH-016`).
- **Tipado:** único `class_name` nuevo de S9 es `Jugador` (en `jugador.gd`), necesario para que `gestor_escenarios.gd` pudiera tipar su referencia y llamar `jugador.fundido_teletransporte()` sin recaer en el mismo problema de tipado genérico corregido en S6.
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores) — particularmente relevante para el menú de pausa (posición del panel frente a la cámara, tamaño de los iconos) y la pantalla de estado inicial (encuadre de cámara), que no pude previsualizar visualmente.

## 9.3 Pase de UX VR (revisión de menús/UI)

**Implementado en rama `feature/ux-vr`** (pendiente de commit manual) — revisión de UX posterior a S9, con dos hallazgos **P0** y una capa de intuitividad/pulido:

**P0 — Hallazgos que rompían la experiencia en headset:**
- **El HUD 2D era invisible en el HMD.** En Godot 4 con `use_xr`, los `CanvasLayer`/`Control` **no se renderizan en el headset** — solo en la ventana espejo de escritorio (limitación documentada de XR en Godot; existe el tutorial oficial "2D in 3D" para esto). Afectaba a: tinte de daño (RF-05), temporizador (RF-34), "+RESCATE" (RF-35) y el fundido de teletransporte (RNF-05). **Solución (además más diegética, pilar 2):** `pantalla_dano.gd` ahora extiende `MeshInstance3D` — quad rojo frente a `XRCamera3D` (`VignetteDanio`, `no_depth_test`, `render_priority 100`); el fundido es otro quad negro (`Desvanecido3D`, prioridad 110); el temporizador es un **reloj Label3D en la muñeca izquierda** (`RelojMuneca`, junto al mapa); "+RESCATE" es un `Label3D` verde breve frente a la vista (`HudMision/EtiquetaRescate`, hijo de la cámara). `hud_mision.gd` pasó de `Control` a `Node3D`. El `CanvasLayer` **se conserva solo con `EtiquetaSalud`**: al ser invisible en el HMD funciona como consola de debug del encargado en el espejo de escritorio (con `@export mostrar_debug_salud` para apagarla).
- **El menú de pausa era físicamente inalcanzable.** Estaba a 1.2 m de la cámara con selección por proximidad de mano (radio 6 cm) y el jugador fijo (RF-03): ningún botón se podía tocar. Ahora `MenuPausa` es hijo de `XROrigin3D` (no de la cámara) y al abrirse se posiciona **una sola vez** frente a la vista a `distancia_apertura` (0.45 m, alcance de brazo) mirando al jugador, y queda **anclado al mundo** — un panel pegado a la cabeza se mueve con cada micro-giro y resulta incómodo/mareante (estándar moderno: anclar o *lazy-follow*).

**P1 — Intuitividad:**
- **Hover states** en todo lo seleccionable por proximidad (`MapaMuneca`, `KitMedico`, `MenuPausa`): el icono/ítem al alcance de la mano derecha se escala (~1.15-1.3×) con un pulso háptico suave al entrar en rango — el jugador sabe *qué* va a seleccionar antes de apretar el gatillo. `confirmar_seleccion()` de los tres ahora reutiliza el mismo `_icono_en_rango()` del hover (una sola fuente de verdad de "qué está al alcance").
- **Háptica** (`XRController3D.trigger_haptic_pulse`, acción `"haptic"` del action map OpenXR por defecto): hover suave (0.2), selección (0.4-0.6), disparo (0.7, retroceso), recarga (0.4 mano izq.), gesto médico éxito/fallo (corto-firme vs. largo-suave, distinguibles sin mirar — RF-24 háptico), daño recibido (0.5 ambas manos), teletransporte (0.6).
- **Mapa de muñeca *forward-up***: los offsets de los iconos ahora se rotan por el yaw de la cámara — "adelante del jugador" es siempre "arriba del mapa". Antes quedaban en coordenadas de mundo y el mapa "mentía" apenas el jugador giraba el cuerpo.
- **Ítem del kit visible en mano**: al equipar, el ítem sigue a la mano derecha (antes desaparecía) y vuelve a su lugar del kit al soltarse. Además el kit **permanece abierto mientras haya un ítem equipado** (antes, alejar la mano izquierda de la mochila cerraba el kit y congelaba el gesto en curso, porque los gestos se procesan en `kit_medico._process` gateado por `visible`).

**P2 — Pulido:**
- Iconos del menú de pausa con color semántico (REANUDAR verde, OPCIONES azul, SALIR rojo tenue); ítems del kit con color propio (venda blanca, morfina celeste, alcohol claro, suturas metálicas, analgésicos naranja).
- `GestorOpciones.nombre_intensidad_actual()` devuelve nombres legibles ("Suave") en vez del identificador crudo del enum ("DESVANECIDO_SUAVE").
- `EstadoInicial`: briefing con **efecto máquina de escribir** (revelado por substring — `Label3D` no tiene `visible_characters`) + tic de tecleo cableado sin stream; primer clic completa el texto, segundo continúa; contador visible del auto-avance para que no tome por sorpresa.
- Sticky notes del menú principal con **hover** (escala 1.08× vía Tween al `mouse_entered` del `Area3D`, sin tocar la escena del equipo — solo los scripts ya adjuntos); `btn_options` deshace el hover antes de capturar sus escalas originales para no ensuciar las animaciones existentes.
- **Sin verificar en editor/headset real** — este pase toca exactamente lo que más necesita validación visual/física (alcances, escalas de hover, posición del reloj en muñeca, cobertura del quad de vignette en el FOV del headset).

## 9.4 Game loop y puntuación (resumen técnico)

**Implementado en S10** (rama `feature/game-loop`, pendiente de commit manual) — RF-16, RF-32, RF-41..RF-44:
- **`GestorJuego`** (autoload nuevo, único que faltaba de los documentados en `§4`): `tiempo_restante` es ahora la **fuente única** del reloj de misión — `hud_mision.gd` dejó de llevar su propio contador local (S6/S9) y solo escucha `tiempo_actualizado`. `rescates` se incrementa escuchando `EventBus.herido_estabilizado` (RF-16 "suma puntuación", la parte visual "+RESCATE" ya estaba desde S4/S6).
- **RF-41 (despliegue inicial):** ya estaba satisfecho estructuralmente desde S2/S7 — `Jugador` nace en `Mision.tscn` en el origen (0,0,0), que coincide con el `PuntoDespliegue` de `Escenario_E1_Calle` (la "zona de combate"), activo por defecto (`GestorEscenarios.escenario_inicial = "E1_Calle"`). No requirió código nuevo.
- **RF-42 (tiempo diferenciado):** dos mecanismos nuevos en `GestorJuego`. (a) *Frente a un herido*: mientras `KitMedico.visible` (kit abierto, tratamiento en curso) el tiempo corre a `factor_tiempo_tratando` (0.5× por defecto) — `kit_medico.gd` llama `GestorJuego.marcar_tratando(visible)` cada frame; refuerza el pilar 1 de `Contexto.md §2` (la medicina no se penaliza). (b) *Por distancia al desplazarse*: `gestor_escenarios.gd._al_solicitar_teletransporte` calcula la distancia entre la posición actual del jugador y el destino **antes** de reposicionar, y llama `GestorJuego.consumir_tiempo_por_distancia()` (`segundos_por_metro`, 0.3 por defecto).
- **RF-43 (fin de misión):** `GestorJuego.terminar_mision(resultado)` se dispara por dos caminos — tiempo agotado (dentro del propio `_process`/`consumir_tiempo_por_distancia` de `GestorJuego`) o `jugador.gd.recibir_dano()` cuando `salud <= 0.0` (`"eliminado"`). Reutiliza el mecanismo de pausa de S9 (`GestorEscenarios.pausar_activo(true)`, encontrado por grupo `"gestor_escenarios"`) en vez de `SceneTree.paused`, consistente con `MenuPausa`.
- **RF-44 (pantalla de resultados):** `views/ResultadosMision.tscn` + `scripts/Menus/resultados_mision.gd`, mismo patrón visual y de anclaje-al-mundo que `MenuPausa` (§9.3) — panel a distancia de brazo frente a la vista, un único botón "VOLVER AL MENÚ" por proximidad+gatillo. Se muestra sola al recibir `GestorJuego.mision_finalizada`; oculta cualquier otro panel abierto (pausa/mapa/kit) para no superponer UI, y tiene **prioridad máxima** en la arbitración del gatillo de `jugador.gd` (por encima incluso del menú de pausa).
- **RF-32 (escalado de dificultad):** ya implementado desde S0 y sin cambios — se confirma que sigue integrado correctamente con el mecanismo de pausa por escenario, ya que `DirectorDeOleadas` vive dentro de `Escenario_E1_Calle` y hereda su `process_mode`.
- **Sin verificar en editor/headset real** (mismo motivo que sprints anteriores).

## 10. Rendimiento (guías para cumplir RNF-01/02)

- Low-poly + `StandardMaterial3D` simples; evitar transparencias y luces dinámicas innecesarias.
- Instanciar/liberar enemigos por oleada; no dejar nodos inertes acumulándose (los `NEUTRALIZADO` se liberan tras un breve retardo).
- Perfilar con el monitor de Godot al cierre de cada sprint; registrar FPS por escenario.
- Reutilizar materiales y mallas entre placeholders.

## 11. Convenciones de placeholders en escena

- Nodo raíz `PH_<Nombre>`, comentario `# PLACEHOLDER: …`.
- Misma jerarquía y señales que tendrá el asset final (principio de "swap sin refactor", `Contexto.md §6.3`).
- Registrar en `Elementos_Faltantes.md` al cierre del sprint.
