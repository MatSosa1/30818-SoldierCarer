extends Node3D
## Director de oleadas de UN escenario (hay una instancia por contenedor de
## escenario). Ya no spawnea parejas encima del jugador al cargar la escena:
## se arma al confirmar el despliegue (EventBus.mision_desplegada) o al
## entrar al escenario con la mision ya activa, respeta un periodo de gracia
## para llegar hasta el herido, y luego los enemigos entran DE A UNO por las
## entradas del escenario ($Entradas, en los bordes: extremos de la calle en
## E1, puertas y escalera en E2), avanzando desde la lejania (RF-33: los
## pasos espaciales anticipan la direccion).
##
## La presion escala con la curacion: cada paso de tratamiento completado
## (EventBus.tratamiento_progresado) encola refuerzos y acelera el goteo —
## la Oposicion converge al detectar actividad del medico. Sin curar, solo
## llega un goteo lento de patrullas.

const ENEMIGO_ARMA := preload("res://views/EnemigoArma.tscn")
const ENEMIGO_CUCHILLO := preload("res://views/EnemigoCuchillo.tscn")

# Nombre del escenario que este director defiende (clave de GestorEscenarios).
@export var escenario: String = "E1_Calle"
@export var contenedor_enemigos_path: NodePath
# Gracia inicial: tiempo desde el despliegue hasta el primer enemigo, para
# poder orientarse y llegar al herido sin ser emboscado en el punto de entrada.
@export var retardo_primera_oleada: float = 15.0
# Goteo base de patrullas por tiempo (se acelera con la presion de curacion).
@export var intervalo_goteo: float = 30.0
@export var max_enemigos_simultaneos: int = 4
@export var max_cola: int = 8
# Refuerzos encolados por cada paso de curacion completado.
@export var enemigos_por_avance_curacion: int = 1
# Separacion aleatoria entre entradas consecutivas: los enemigos aparecen
# "poco a poco", nunca en parejas instantaneas.
@export var retardo_spawn_min: float = 2.0
@export var retardo_spawn_max: float = 5.0
# Las entradas a menos de esta distancia del jugador se descartan al elegir
# por donde entra un enemigo: nadie debe aparecer "en la cara" del medico
# (p.ej. la entrada sur de E1 esta a 2 m del punto de despliegue).
@export var distancia_minima_al_jugador: float = 8.0

var score: int = 0
var enemigos_activos: int = 0

var _armado: bool = false
var _pendientes: int = 0
var _tiempo_gracia: float = 0.0
var _tiempo_goteo: float = 0.0
var _tiempo_spawn: float = 0.0
var _alternar_cuchillo: bool = false
var _presion: float = 0.0 # 0..1 segun el progreso de curacion del herido local
var _indice_entrada_debug: int = 0

@onready var contenedor_enemigos: Node3D = get_node(contenedor_enemigos_path)
@onready var entradas: Array[Node] = $Entradas.get_children()

func _ready() -> void:
	EventBus.mision_desplegada.connect(_al_desplegar)
	EventBus.escenario_activado.connect(_al_activar_escenario)
	EventBus.tratamiento_progresado.connect(_al_progresar_tratamiento)

func _al_desplegar(nombre: String) -> void:
	if nombre == escenario:
		_armar()

# Cambio de escenario a mitad de mision (teletransporte por mapa de muneca):
# el director del escenario recien visitado se arma la primera vez, tambien
# con su periodo de gracia.
func _al_activar_escenario(nombre: String) -> void:
	if nombre == escenario and GestorJuego.mision_activa and not _armado:
		_armar()

func _armar() -> void:
	_armado = true
	_tiempo_gracia = retardo_primera_oleada
	_tiempo_goteo = intervalo_goteo
	print("Director %s armado: primera oleada en %.0fs." % [escenario, retardo_primera_oleada])

func _process(delta: float) -> void:
	if not _armado or not GestorJuego.mision_activa:
		return
	if _tiempo_gracia > 0.0:
		_tiempo_gracia -= delta
		if _tiempo_gracia <= 0.0:
			_encolar(1) # explorador inicial: un unico enemigo de reconocimiento
		return
	# Goteo de patrullas por tiempo; la presion de curacion lo acelera.
	_tiempo_goteo -= delta * (1.0 + _presion)
	if _tiempo_goteo <= 0.0:
		_tiempo_goteo = intervalo_goteo
		_encolar(1)
	# La cola se vacia de a un enemigo, con pausa aleatoria entre entradas.
	if _pendientes > 0 and enemigos_activos < max_enemigos_simultaneos:
		_tiempo_spawn -= delta
		if _tiempo_spawn <= 0.0:
			_tiempo_spawn = randf_range(retardo_spawn_min, retardo_spawn_max)
			_pendientes -= 1
			_spawnear_en_entrada(_elegir_entrada())

# Entrada aleatoria entre las que estan lejos del jugador; si todas estan
# cerca (escenario chico), la mas lejana.
func _elegir_entrada() -> Node3D:
	var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		return entradas.pick_random()
	var lejanas := entradas.filter(
		func(e: Node3D) -> bool:
			return e.global_position.distance_to(jugador.global_position) >= distancia_minima_al_jugador
	)
	if not lejanas.is_empty():
		return lejanas.pick_random()
	var mas_lejana: Node3D = entradas[0]
	for entrada: Node3D in entradas:
		if entrada.global_position.distance_to(jugador.global_position) > mas_lejana.global_position.distance_to(jugador.global_position):
			mas_lejana = entrada
	return mas_lejana

func _al_progresar_tratamiento(herido: Node, fraccion: float) -> void:
	if not _armado or not ("escenario" in herido) or herido.escenario != escenario:
		return
	_presion = clampf(fraccion, 0.0, 1.0)
	# Mas cerca de estabilizar = refuerzos mas numerosos: defender al herido
	# se vuelve progresivamente mas tenso (RF-31).
	_encolar(enemigos_por_avance_curacion + int(fraccion * 2.0))

func _encolar(cantidad: int) -> void:
	_pendientes = min(_pendientes + cantidad, max_cola)

func _spawnear_en_entrada(entrada: Node3D) -> void:
	var escena := ENEMIGO_CUCHILLO if _alternar_cuchillo else ENEMIGO_ARMA
	_alternar_cuchillo = not _alternar_cuchillo
	var enemigo := escena.instantiate()
	contenedor_enemigos.add_child(enemigo)
	# Pequeno desvio lateral para que dos enemigos de la misma entrada no
	# aparezcan exactamente en el mismo punto.
	var desvio := Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
	enemigo.global_position = entrada.global_position + desvio
	enemigo.neutralizado.connect(_al_neutralizar_enemigo)
	enemigos_activos += 1
	print("Enemigo entra por %s (%s) | activos: %s | en cola: %s" % [entrada.name, escenario, enemigos_activos, _pendientes])

func _al_neutralizar_enemigo(_enemigo: CharacterBody3D) -> void:
	score += 1
	enemigos_activos = max(enemigos_activos - 1, 0)
	print("Score: %s | Enemigos activos: %s" % [score, enemigos_activos])

# Usado por sistemas que necesitan saber si la zona esta despejada.
func hay_enemigos_activos() -> bool:
	return enemigos_activos > 0

# Teclas de debug (solo procesan con el escenario activo): R encola un
# enemigo; 1-4 spawnean inmediato en la entrada correspondiente.
func _unhandled_input(event: InputEvent) -> void:
	if not _armado or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_R:
			_encolar(1)
		KEY_1, KEY_2, KEY_3, KEY_4:
			var indice: int = event.keycode - KEY_1
			if indice < entradas.size():
				_spawnear_en_entrada(entradas[indice])
