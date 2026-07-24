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
## Refuerzos por curacion (RF-31, curva de dificultad "facil"): en vez de
## encolar enemigos en CADA paso de tratamiento (viejo diseno — con una
## secuencia de 3-4 pasos por herida terminaba encolando mas enemigos de
## los que se podian abatir con la municion disponible, practicamente
## imposible curar sin estar ya bajo fuego), se dispara una oleada de
## enemigos_por_oleada (una pareja arma+cuchillo) cada vez que el progreso
## PONDERADO del herido avanza medio herida (0.5 / cantidad de heridas).
## Ponderado = fraccion_tratamiento() del herido (pasos hechos / pasos
## totales de TODAS sus heridas), no el % de una herida sola: si el
## jugador reparte el esfuerzo entre varias heridas a la vez, el progreso
## ponderado sube mas despacio que cualquiera de ellas por separado, asi
## que no se disparan varias oleadas de golpe solo por trabajar en paralelo.
## Con 2 heridas (minimo actual) esto da 4 oleadas en toda la curacion; con
## 3, seis. El goteo de patrullas por tiempo sigue constante (no se acelera
## con la curacion, para no sumar presion sobre la presion) — solo agrega
## enemigos si el jugador se demora mucho sin avanzar.

const ENEMIGO_ARMA := preload("res://views/EnemigoArma.tscn")
const ENEMIGO_CUCHILLO := preload("res://views/EnemigoCuchillo.tscn")

# Nombre del escenario que este director defiende (clave de GestorEscenarios).
@export var escenario: String = "E1_Calle"
@export var contenedor_enemigos_path: NodePath
# Gracia inicial: tiempo desde el despliegue hasta el primer enemigo, para
# poder orientarse y llegar al herido sin ser emboscado en el punto de entrada.
@export var retardo_primera_oleada: float = 15.0
# Goteo base de patrullas por tiempo, constante (ver docstring de la clase).
@export var intervalo_goteo: float = 30.0
@export var max_enemigos_simultaneos: int = 4
@export var max_cola: int = 8
# Tamano de cada oleada de refuerzo por curacion: una pareja arma+cuchillo.
@export var enemigos_por_oleada: int = 2
# Fraccion de UNA herida (0..1) que hay que avanzar, en progreso ponderado
# del herido completo, para disparar la siguiente oleada. 0.5 = una oleada
# cada medio avance de herida (ver docstring de la clase para el porque).
@export var avance_herida_por_oleada: float = 0.5
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
var _indice_entrada_debug: int = 0
# herido -> progreso ponderado (fraccion_tratamiento()) ya premiado con
# oleada; permite detectar cada cruce de umbral sin repetirlo ni perderlo.
var _progreso_premiado: Dictionary = {}

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
	# Goteo de patrullas por tiempo, constante (las oleadas por curacion ya
	# escalan la presion; acelerar esto tambien las hacia compuestas).
	_tiempo_goteo -= delta
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

# RF-31, curva de dificultad: dispara una oleada por cada avance_herida_por_
# oleada (0.5 = medio herida) de progreso PONDERADO del herido, no por cada
# paso de tratamiento individual (ver docstring de la clase). "Ponderado"
# = fraccion_tratamiento() del herido, que ya promedia pasos_hechos/pasos_
# totales de TODAS sus heridas; dividir el umbral por la cantidad de
# heridas hace que el numero de oleadas escale con cuantas tiene el herido
# (2 heridas -> 4 oleadas; 3 -> 6) sin premiar per-herida de forma
# independiente, que es lo que permitia que tratar varias en paralelo
# disparara todas sus oleadas de golpe al cruzar el 50% "al mismo tiempo".
func _al_progresar_tratamiento(herido: Node, fraccion: float) -> void:
	if not _armado or not ("escenario" in herido) or herido.escenario != escenario:
		return
	if not ("heridas" in herido) or herido.heridas.is_empty():
		return
	fraccion = clampf(fraccion, 0.0, 1.0)
	var umbral: float = avance_herida_por_oleada / float(herido.heridas.size())
	var premiado: float = _progreso_premiado.get(herido, 0.0)
	# while, no if: si un solo paso completa una fraccion grande del total
	# (herida corta, pocos pasos), puede cruzar mas de un umbral de una vez
	# y las oleadas pendientes no deben perderse.
	while premiado + umbral <= fraccion + 0.0001:
		premiado += umbral
		_encolar(enemigos_por_oleada)
		print("Refuerzos por curacion en %s: oleada al %d%% de progreso ponderado." % [
			escenario, roundi(premiado * 100.0),
		])
	_progreso_premiado[herido] = premiado

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

# Teclas de debug (solo procesan con el escenario activo): F5 encola un
# enemigo; F1-F4 spawnean inmediato en la entrada correspondiente. En F1-F5
# (no R/1-4) porque el modo escritorio ya usa R para recargar y 1-5 para
# elegir item del kit medico (jugador.gd/kit_medico.gd): con las teclas
# viejas, cada recarga o seleccion de item durante una prueba tambien
# disparaba estos atajos de debug sin querer.
func _unhandled_input(event: InputEvent) -> void:
	if not _armado or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F5:
			_encolar(1)
		KEY_F1, KEY_F2, KEY_F3, KEY_F4:
			var indice: int = event.keycode - KEY_F1
			if indice < entradas.size():
				_spawnear_en_entrada(entradas[indice])
