extends CharacterBody3D
class_name EnemigoBase
## Base compartida por enemigo_arma.gd y enemigo_cuchillo.gd. Extraida en S5
## sin cambiar comportamiento observable (Arquitectura.md SS5): centraliza
## salud, dano, neutralizacion generica y la busqueda del jugador. Cada
## subclase mantiene su propio enum Estado y FSM en _physics_process(), y
## solo implementa los "ganchos" virtuales de mas abajo para conectar su
## estado con la neutralizacion y la etiqueta de depuracion.

signal neutralizado(enemigo: CharacterBody3D)

@export var salud_maxima: float = 20.0

var salud: float

@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
@onready var etiqueta_estado: Label3D = $EtiquetaEstado

func _ready() -> void:
	add_to_group("enemigos")
	salud = salud_maxima
	_actualizar_etiqueta()

func recibir_dano(cantidad: float) -> void:
	if _esta_neutralizado():
		return
	salud = max(salud - cantidad, 0.0)
	if salud <= 0.0:
		_neutralizar()

func _neutralizar() -> void:
	_marcar_neutralizado()
	collision_layer = 0
	collision_mask = 0
	visible = false
	set_physics_process(false)
	print("%s neutralizado" % name)
	neutralizado.emit(self)

# --- Ganchos a implementar por cada subclase (su propio enum Estado) ---

func _esta_neutralizado() -> bool:
	return false

func _marcar_neutralizado() -> void:
	pass

func _actualizar_etiqueta() -> void:
	pass
