extends Node3D
## Decide que carriles activar y spawnea la pareja arma+cuchillo en cada uno.
## Reutiliza la misma FSM para escalar dificultad: activa mas carriles con el score,
## no requiere una IA distinta.

const ENEMIGO_ARMA := preload("res://views/EnemigoArma.tscn")
const ENEMIGO_CUCHILLO := preload("res://views/EnemigoCuchillo.tscn")

@export var contenedor_enemigos_path: NodePath
@export var activar_carril_inicial: bool = true
@export var carril_inicial: String = "Adelante"
@export var umbral_escalado: int = 3

var score: int = 0
var _carriles_activos: Dictionary = {}

@onready var contenedor_enemigos: Node3D = get_node(contenedor_enemigos_path)
@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
@onready var marcadores: Dictionary = {
	"Adelante": $PuntosDeSpawn/Adelante,
	"Atras": $PuntosDeSpawn/Atras,
	"Izquierda": $PuntosDeSpawn/Izquierda,
	"Derecha": $PuntosDeSpawn/Derecha,
}

func _ready() -> void:
	if activar_carril_inicial:
		activar_carril(carril_inicial)

# Teclas de debug 1-4 para activar cada carril manualmente durante la demo.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: activar_carril("Adelante")
			KEY_2: activar_carril("Atras")
			KEY_3: activar_carril("Izquierda")
			KEY_4: activar_carril("Derecha")

func activar_carril(nombre_carril: String) -> void:
	var marcador: Marker3D = marcadores.get(nombre_carril)
	if not marcador:
		push_warning("Carril desconocido: %s" % nombre_carril)
		return

	var lateral := Vector3.RIGHT
	if jugador:
		var hacia_jugador := (jugador.global_position - marcador.global_position).normalized()
		lateral = hacia_jugador.cross(Vector3.UP).normalized()

	var arma := ENEMIGO_ARMA.instantiate()
	var cuchillo := ENEMIGO_CUCHILLO.instantiate()
	contenedor_enemigos.add_child(arma)
	contenedor_enemigos.add_child(cuchillo)
	arma.global_position = marcador.global_position + lateral * 0.75
	cuchillo.global_position = marcador.global_position - lateral * 0.75
	arma.neutralizado.connect(_al_neutralizar_enemigo)
	cuchillo.neutralizado.connect(_al_neutralizar_enemigo)

	_carriles_activos[nombre_carril] = true
	print("Carril activado: %s" % nombre_carril)

func _al_neutralizar_enemigo(_enemigo: CharacterBody3D) -> void:
	score += 1
	print("Score: %s" % score)
	if score % umbral_escalado == 0:
		_activar_carril_extra()

# Escalado simple: al cruzar el umbral, activa el siguiente carril aun inactivo.
func _activar_carril_extra() -> void:
	for nombre_carril in marcadores.keys():
		if not _carriles_activos.get(nombre_carril, false):
			activar_carril(nombre_carril)
			return
