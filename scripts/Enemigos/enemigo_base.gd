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
# RNF-01: los NEUTRALIZADO se liberan tras este retardo en vez de quedar
# invisibles para siempre en el arbol (fuga de nodos: en una mision larga
# con escalado de dificultad, DirectorDeOleadas puede llegar a instanciar
# decenas de parejas). El retardo (no queue_free inmediato) deja tiempo a
# que el disparo/animacion que causo la baja termine de reproducirse.
@export var retardo_liberacion: float = 2.0
# Correccion si el modelo queda mirando al reves tras _orientar_hacia() (el
# .blend fuente no siempre trae el "frente" alineado con el -Z de Godot);
# ajustar a ojo en el editor, en pasos de 180 si queda invertido.
@export_range(-180, 180, 1) var offset_rotacion_visual_grados: float = 0.0

var salud: float

@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var sonido_pasos: AudioStreamPlayer3D = $SonidoPasos

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
	if sonido_pasos:
		sonido_pasos.stop()
	print("%s neutralizado" % name)
	neutralizado.emit(self)
	get_tree().create_timer(retardo_liberacion).timeout.connect(queue_free)

# RF-33/RF-45: audio espacial de pasos mientras avanza, para que el jugador
# perciba la direccion del enemigo antes de verlo. No repite el play() si ya
# esta sonando (evita reiniciar el loop en cada frame de AVANCE).
func _reproducir_pasos() -> void:
	if sonido_pasos and not sonido_pasos.playing:
		sonido_pasos.play()

func _detener_pasos() -> void:
	if sonido_pasos:
		sonido_pasos.stop()

# Orienta el cuerpo (solo en el plano horizontal, sin inclinarse) hacia un
# punto del mundo. Sin esto el enemigo conserva para siempre la rotacion de
# reposo del .tscn sin importar por donde entre o hacia donde se mueva —
# spawneado por DirectorDeOleadas, que solo asigna global_position.
func _orientar_hacia(punto_global: Vector3) -> void:
	var destino := Vector3(punto_global.x, global_position.y, punto_global.z)
	if destino.is_equal_approx(global_position):
		return
	look_at(destino, Vector3.UP)
	if offset_rotacion_visual_grados != 0.0:
		rotate_object_local(Vector3.UP, deg_to_rad(offset_rotacion_visual_grados))

# --- Ganchos a implementar por cada subclase (su propio enum Estado) ---

func _esta_neutralizado() -> bool:
	return false

func _marcar_neutralizado() -> void:
	pass

func _actualizar_etiqueta() -> void:
	pass
