# Resumen de implementacion — Demo de IA de enemigos (SoldierCarer)

Rama: `feature/ia-enemigos-demo` (no mergeada a `main`).
Base: `IA_SoldierCarer_Implementacion.md` (documento de diseno original de la tarea).

Este documento resume que se construyo, en que se aparta de la propuesta
original y por que, y como se valido cada pieza.

---

## 1. Checklist frente a los criterios de exito originales

Los 7 puntos obligatorios de la seccion 0 del documento original, mas el
punto opcional 8, quedaron implementados y verificados:

| # | Criterio original | Estado | Donde |
|---|---|---|---|
| 1 | Jugador fijo, solo rota yaw | Hecho | `Jugador` en `views/Mision.tscn` + `scripts/Jugador/jugador.gd` |
| 2 | 4 carriles (Adelante/Atras/Izquierda/Derecha) | Hecho | `DirectorDeOleadas/PuntosDeSpawn` (4 `Marker3D`) |
| 3 | Spawnear pareja arma+cuchillo por carril | Hecho | `DirectorDeOleadas.activar_carril()`, se dispara al iniciar la escena y con teclas de debug |
| 4 | Ambos avanzan en linea recta hacia el jugador | Hecho | Estado `AVANCE` en ambas FSM |
| 5 | Arma se detiene a rango medio y dispara | Hecho | FSM `EnemigoArma`: `AVANCE -> DISPARO` |
| 6 | Cuchillo esquiva de forma reactiva al ser apuntado/impactado | Hecho | `EnemigoCuchillo._al_recibir_disparo()`, valida `rayo.get_collider() == self` |
| 7 | Salud 0 -> Neutralizado y se desactiva | Hecho | `recibir_dano()` / `_neutralizar()` en ambos enemigos |
| 8 (opcional) | Escalado de dificultad activando mas carriles | Hecho | `DirectorDeOleadas`: cada 3 bajas (`umbral_escalado`) activa un carril nuevo |

Los 7 puntos obligatorios se probaron con el editor de Godot en modo
headless (`godot --headless --script ...`), instanciando `Mision.tscn`,
disparando programaticamente al enemigo cuchillo y aplicando dano letal,
sin intervencion manual. El resultado de esas corridas esta documentado en
la conversacion de implementacion; no quedaron como archivos en el repo
(eran scripts de prueba temporales, borrados despues de cada verificacion).

---

## 2. Archivos nuevos

```
scripts/Jugador/jugador.gd
scripts/Enemigos/enemigo_cuchillo.gd
scripts/Enemigos/enemigo_arma.gd
scripts/DirectorDeOleadas/director_de_oleadas.gd
scripts/Herido/herido.gd
views/Mision.tscn
views/EnemigoArma.tscn
views/EnemigoCuchillo.tscn
```

### `scripts/Jugador/jugador.gd`
`CharacterBody3D` fijo en el origen. Solo rota en Y con el mouse
(`rotate_y`, sensibilidad configurable). Dispara con clic izquierdo:
actualiza un `RayCast3D` propio, emite la senal `disparo_realizado(rayo)`
(de la que dependen los `EnemigoCuchillo` para esquivar) y, si el rayo
impacta algo con metodo `recibir_dano()`, le aplica dano directamente — asi
un mismo disparo dispara la esquiva reactiva Y hace dano, sin necesitar dos
sistemas separados. Tambien expone `recibir_dano()` propio (usado por los
enemigos), una barra de salud simple en pantalla, feedback rojo de dano
(`ColorRect` + `Tween`), una mira central y un trazador visual del disparo.

### `scripts/Enemigos/enemigo_cuchillo.gd` y `enemigo_arma.gd`
FSM por `enum` + `match`, calcada del esqueleto de referencia del
documento original, con los nombres de estado en espanol pedidos ahi
(`AVANCE`, `ESQUIVA`, `EMBESTIDA`, `DISPARO`, `NEUTRALIZADO`). Cada
enemigo expone `recibir_dano()` y una senal `neutralizado` que consume
`DirectorDeOleadas` para llevar el score y el conteo de enemigos activos.
Un `Label3D` sobre cada capsula muestra el estado actual en vivo.

### `scripts/DirectorDeOleadas/director_de_oleadas.gd`
Instancia `EnemigoArma.tscn` + `EnemigoCuchillo.tscn` en el `Marker3D` del
carril pedido, separados perpendicularmente a la linea carril-jugador
(calculado en el momento, no depende de la orientacion del marcador).
Activa "Adelante" al iniciar la escena. Mantiene `enemigos_activos` y
`score`, y escala dificultad activando un carril nuevo cada 3 bajas.

### `scripts/Herido/herido.gd`
Agregado fuera del alcance original (ver seccion 4) a pedido explicito
durante la implementacion. Capsula placeholder a los pies del jugador con
curacion rudimentaria condicionada a que la zona este despejada de
enemigos y a que el jugador este enfocandolo.

### `views/Mision.tscn`
Escena jugable: `Jugador`, `DirectorDeOleadas` (con sus 4 `Marker3D`),
`Enemigos` (contenedor vacio en tiempo de diseno, se llena en runtime),
`Herido`, `TrazadorDisparo`, piso y luz basicos, `WorldEnvironment` con
cielo procedural simple. Todo con primitivas de Godot, sin assets
finales, tal como pide el documento original.

### `views/EnemigoArma.tscn` / `views/EnemigoCuchillo.tscn`
`CharacterBody3D` + `CapsuleMesh` de color plano (naranja / rojo) +
`Label3D` de estado. Sin animaciones, sin materiales custom.

## Archivos modificados

- `scripts/MainMenu/btn_play.gd`: el boton "Play" del menu principal
  quedo enlazado a `res://views/Mision.tscn` (antes apuntaba, comentado, a
  una ruta que ya no existia).

---

## 3. Controles de la demo

| Input | Accion |
|---|---|
| Mouse (capturado) | Rotar el jugador en yaw |
| Clic izquierdo | Disparar (rayo instantaneo + trazador visual 0.08s) |
| Escape | Alternar captura del mouse |
| `1` / `2` / `3` / `4` | Activar carril Adelante / Atras / Izquierda / Derecha |
| `R` | Spawnear otra pareja, rotando de carril en cada pulsacion (Adelante -> Derecha -> Atras -> Izquierda) |
| `E` | Iniciar intento de curar al herido |
| `T` | Reiniciar a 0 el progreso de curacion |

---

## 4. Ajustes respecto a la propuesta original

### 4.1 Agregados que el documento no pedia (pero no contradicen el alcance)

- **Mira central y trazador visual del disparo**: el `RayCast3D` es
  invisible en juego; sin estos dos elementos no habia forma de confirmar
  hacia donde apuntaba la camara ni ver el impacto de un tiro. El
  documento ya sugeria "una linea de depuracion... en vez de un modelo de
  bala" como placeholder recomendado (seccion 7); esto es esa sugerencia
  implementada.
- **Dano en el disparo unificado con la deteccion reactiva**: el
  documento proponia una tecla de debug que hiciera `salud = 0` para
  poder probar la transicion a `NEUTRALIZADO` (seccion 8, punto 6). En vez
  de eso, el mismo disparo que dispara la esquiva tambien resta salud
  (via `recibir_dano()`), asi que disparando varias veces al mismo
  enemigo se lo neutraliza sin necesitar una tecla aparte.
- **Tecla `R` (spawn rotando de carril)**: no estaba en el documento.
  Se agrego porque los enemigos neutralizados no reaparecen solos, y sin
  esto no habia forma rapida de seguir probando la FSM sin recordar que
  tecla 1-4 corresponde a cada carril.
- **Escalado de dificultad (punto 8, opcional)**: se implemento el
  escalado simple que el documento marcaba como "si el tiempo alcanza".

### 4.2 Agregado fuera del alcance explicito original

El documento original (seccion 9) excluye expresamente "sistema de kit
medico, curacion, mecanicas de estabilizacion de heridos". Durante la
implementacion se pidio explicitamente agregar un placeholder del herido
con una funcion de curar rudimentaria, para demostrar visualmente el
motivo de disenio completo del juego (despejar la zona = momento de
curar). Se implemento con el mismo criterio de "placeholder minimo" que
el resto de la demo:

- Capsula de Godot, sin modelo ni animacion.
- La condicion de "zona despejada" reutiliza el mismo estado que ya
  llevaba `DirectorDeOleadas` (`enemigos_activos`), sin agregar un
  sistema nuevo de deteccion.
- No hay inventario, items, ni integracion con ningun kit medico real:
  es solo una barra de progreso por tiempo, gateada por dos condiciones.

### 4.3 Correccion de diseno encontrada durante la implementacion

El primer intento de "debe estar mirando al herido para curar" comparaba
la direccion 3D completa camara -> herido, incluyendo el eje vertical.
Como el jugador **solo rota en yaw** (sin pitch, tal como pide el
documento original en el punto 1), la camara nunca puede inclinarse hacia
abajo para "apuntar" con precision a algo en el piso a sus pies — el
chequeo original nunca daba verdadero. Se corrigio comparando solo el
rumbo horizontal (se ignora la componente Y de ambos vectores antes de
normalizar y comparar), consistente con que en este control scheme
"enfocar" algo solo puede significar "girar hacia", no "apuntar en 3D".

Tambien se encontro y corrigio un bug de orden de inicializacion: el nodo
`Herido` quedo, en un primer momento, como hermano anterior a `Jugador`
en el arbol de `Mision.tscn`. Godot llama `_ready()` a los hermanos en el
orden en que aparecen en el archivo, asi que `Herido._ready()` corria
antes que `Jugador._ready()` y la busqueda del jugador por grupo
(`get_first_node_in_group("jugador")`) devolvia `null` de forma
silenciosa, dejando la referencia a la camara sin resolver. Se solucionó
reordenando `Herido` para que aparezca despues de `Jugador` en la escena.

---

## 5. Sigue fuera de alcance (sin cambios respecto al documento original)

Tal como marca la seccion 9 del documento original: assets 3D finales,
animaciones custom, sonido, VFX, HUD final, balanceo fino, iluminacion de
escenario, integracion con el mapa 2D de teletransporte, y — mas alla del
placeholder agregado — cualquier sistema real de kit medico o
estabilizacion de heridos.

---

## 6. Commits de la rama

```
75327e9 feat: Demo funcional de IA de enemigos con FSM reactiva
18388a9 feat: Enlazar boton Play a la escena de demo de IA
844f79d feat: Agregar mira y trazador visual del disparo
c063831 feat: Agregar tecla R para spawnear pareja rotando de carril
ad8944b feat: Agregar placeholder de Herido con curacion rudimentaria
ad7b50a feat: Curacion del herido requiere enfocarlo y agrega tecla de reinicio
```
