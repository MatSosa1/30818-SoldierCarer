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
| `EventBus` | Señales globales desacopladas entre sistemas. | Ej.: `herido_muerto(id)`, `herido_estabilizado(id)`, `mision_terminada(resultado)`. |
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
- Extraer un `enemigo_base.gd` común para no duplicar la FSM entre arma y cuchillo (refactor en S5, sin cambiar comportamiento observable).

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

## 8. Sistema de teletransporte y navegación

- El **mapa de muñeca** (`MapaMuneca`) presenta iconos de heridos con color de urgencia y un cursor de selección VR.
- Al confirmar destino: `EventBus.solicitar_teletransporte(punto_destino, escenario)` → `GestorEscenarios` asegura el escenario activo → reposiciona el `XROrigin3D` del jugador → cierra el mapa.
- No hay locomoción continua (RNF-04). El "tiempo por distancia" (RF-42) se calcula al confirmar el salto.

## 9. Sistema del kit médico (resumen técnico)

- `KitMedico` gestiona el inventario de `ItemMedico` (vendas, morfina, alcohol, suturas, analgésicos).
- Cada `ItemMedico` define su **gesto** (patrón de movimiento del controlador) y su **efecto**.
- `SecuenciaTratamiento` valida el orden requerido por la herida (p.ej. alcohol → sutura; vendas como paso base) y emite `herido_estabilizado(id)` al completarse.
- Feedback por ítem (RF-24) vía `GestorAudio` + señal visual.

## 10. Rendimiento (guías para cumplir RNF-01/02)

- Low-poly + `StandardMaterial3D` simples; evitar transparencias y luces dinámicas innecesarias.
- Instanciar/liberar enemigos por oleada; no dejar nodos inertes acumulándose (los `NEUTRALIZADO` se liberan tras un breve retardo).
- Perfilar con el monitor de Godot al cierre de cada sprint; registrar FPS por escenario.
- Reutilizar materiales y mallas entre placeholders.

## 11. Convenciones de placeholders en escena

- Nodo raíz `PH_<Nombre>`, comentario `# PLACEHOLDER: …`.
- Misma jerarquía y señales que tendrá el asset final (principio de "swap sin refactor", `Contexto.md §6.3`).
- Registrar en `Elementos_Faltantes.md` al cierre del sprint.
