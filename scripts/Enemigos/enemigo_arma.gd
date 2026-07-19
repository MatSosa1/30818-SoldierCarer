extends CharacterBody3D
## Enemigo a distancia. FSM: AVANCE -> DISPARO (a rango medio) -> NEUTRALIZADO.

signal neutralizado(enemigo: CharacterBody3D)

enum Estado {AVANCE, DISPARO, NEUTRALIZADO}
var estado: Estado = Estado.AVANCE

@export var velocidad_avance: float = 2.5
@export var rango_disparo: float = 6.0
@export var salud_maxima: float = 25.0
@export var dano_disparo: float = 5.0
@export var cadencia_disparo: float = 1.2

var salud: float
var _cooldown_disparo: float = 0.0

@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
@onready var etiqueta_estado: Label3D = $EtiquetaEstado

func _ready() -> void:
	add_to_group("enemigos")
	salud = salud_maxima
	_actualizar_etiqueta()

func _physics_process(delta: float) -> void:
	if not jugador or estado == Estado.NEUTRALIZADO:
		return

	var distancia := global_position.distance_to(jugador.global_position)
	match estado:
		Estado.AVANCE:
			var dir := (jugador.global_position - global_position).normalized()
			velocity = dir * velocidad_avance
			move_and_slide()
			if distancia <= rango_disparo:
				_cambiar_estado(Estado.DISPARO)
		Estado.DISPARO:
			velocity = Vector3.ZERO
			if distancia > rango_disparo * 1.2:
				_cambiar_estado(Estado.AVANCE)
				return
			_cooldown_disparo -= delta
			if _cooldown_disparo <= 0.0:
				_disparar_rafaga()

func _disparar_rafaga() -> void:
	_cooldown_disparo = cadencia_disparo
	print("%s dispara una rafaga al jugador" % name)
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano_disparo)

func recibir_dano(cantidad: float) -> void:
	if estado == Estado.NEUTRALIZADO:
		return
	salud = max(salud - cantidad, 0.0)
	if salud <= 0.0:
		_neutralizar()

func _neutralizar() -> void:
	_cambiar_estado(Estado.NEUTRALIZADO)
	collision_layer = 0
	collision_mask = 0
	visible = false
	set_physics_process(false)
	print("%s neutralizado" % name)
	neutralizado.emit(self)

func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	_actualizar_etiqueta()

func _actualizar_etiqueta() -> void:
	if etiqueta_estado:
		etiqueta_estado.text = Estado.keys()[estado]
