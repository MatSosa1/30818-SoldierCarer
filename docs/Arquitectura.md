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
| `GestorJuego` | Estado de partida: score, tiempo restante, condición de fin, escenario activo. | Fuente única de verdad del game loop. |
| `GestorAudio` | Buses, música por estado (menú/combate/crítico), disparo de SFX. | Aísla la reproducción del resto de sistemas. |

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
- `scripts/HUD/hud_mision.gd` (`extends Control`) — nuevo nodo `UI/HudMision` en `Jugador.tscn`: temporizador de misión (RF-34, `@export var duracion_mision: float = 600.0`, valor base de la discrepancia D1 en `Contexto.md §8`, **a confirmar**) en la esquina superior derecha, con parpadeo rojo en el último minuto; confirmación "+RESCATE" (RF-35, antes vivía en `jugador.gd`, se movió aquí y se escucha directo de `EventBus.herido_estabilizado` en vez de por un paso intermedio en el jugador — el sonido de la confirmación reutiliza `Herido/SonidoRescate`, ya cableado en S4). RF-43 (fin de misión por tiempo agotado) **no** se implementa aquí — es de `GestorJuego`/S10; el temporizador solo se detiene visualmente en 0 con "TIEMPO AGOTADO".
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
- Puntuación/pantalla de resultados por rescates (RF-16 parte "S10", RF-44) sigue **fuera de alcance**: no se creó `GestorJuego` todavía, es territorio de S10.
- **Sin verificar en editor/headset real** (mismo motivo que S1/S2/S3).

## 10. Rendimiento (guías para cumplir RNF-01/02)

- Low-poly + `StandardMaterial3D` simples; evitar transparencias y luces dinámicas innecesarias.
- Instanciar/liberar enemigos por oleada; no dejar nodos inertes acumulándose (los `NEUTRALIZADO` se liberan tras un breve retardo).
- Perfilar con el monitor de Godot al cierre de cada sprint; registrar FPS por escenario.
- Reutilizar materiales y mallas entre placeholders.

## 11. Convenciones de placeholders en escena

- Nodo raíz `PH_<Nombre>`, comentario `# PLACEHOLDER: …`.
- Misma jerarquía y señales que tendrá el asset final (principio de "swap sin refactor", `Contexto.md §6.3`).
- Registrar en `Elementos_Faltantes.md` al cierre del sprint.
