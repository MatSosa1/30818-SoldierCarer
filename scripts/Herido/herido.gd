extends Node3D
## Placeholder del herido a los pies del jugador. Curacion rudimentaria: solo
## para demostrar que la zona despejada (sin enemigos activos) Y estar
## enfocando al herido son las condiciones para curar. El sistema de kit
## medico real esta fuera de alcance de esta demo (ver
## IA_SoldierCarer_Implementacion.md).
##
## E: inicia el intento de curacion. Mientras este activo, el progreso solo
## avanza si el jugador esta mirando al herido y no hay enemigos activos; si
## deja de mirar o aparecen enemigos, el progreso se congela donde quedo (no
## se pierde). T: reinicia el progreso a 0.

signal curado

@export var tiempo_curacion: float = 6.0
@export var angulo_mirada_grados: float = 20.0
@export var director_oleadas_path: NodePath

@onready var director: Node = get_node_or_null(director_oleadas_path)
@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")
@onready var camara: Camera3D = jugador.get_node("XROrigin3D/Camera3D") if jugador else null
@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var malla: MeshInstance3D = $Malla

var _intentando_curar: bool = false
var _progreso: float = 0.0
var curado_completo: bool = false

func _ready() -> void:
	add_to_group("heridos")
	_actualizar_etiqueta(false, false, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_iniciar_intento_curar()
		elif event.keycode == KEY_T:
			_reiniciar_progreso()

func _process(delta: float) -> void:
	if curado_completo:
		return

	var enemigos_bloquean := _hay_enemigos_activos()
	var mirando := _esta_mirando_al_herido()
	var curando_ahora := _intentando_curar and mirando and not enemigos_bloquean

	if curando_ahora:
		_progreso = min(_progreso + delta, tiempo_curacion)
		if _progreso >= tiempo_curacion:
			_completar_curacion()

	_actualizar_etiqueta(enemigos_bloquean, mirando, curando_ahora)

func _iniciar_intento_curar() -> void:
	if curado_completo:
		return
	_intentando_curar = true
	print("Intentando curar al herido (mantene la mira sobre el y la zona despejada)...")

func _reiniciar_progreso() -> void:
	if curado_completo:
		return
	_progreso = 0.0
	print("Progreso de curacion reiniciado a 0.")

func _hay_enemigos_activos() -> bool:
	return director and director.has_method("hay_enemigos_activos") and director.hay_enemigos_activos()

# Solo compara el rumbo horizontal (yaw), ignorando la inclinacion real del
# headset: asi "enfocar" al herido significa girar el cuerpo hacia el, sin
# forzar al jugador a inclinar la cabeza con incomodidad para mirar algo a
# ras de piso.
func _esta_mirando_al_herido() -> bool:
	if not camara:
		return false
	var direccion_camara := -camara.global_transform.basis.z
	var direccion_al_herido := global_position - camara.global_position
	direccion_camara.y = 0.0
	direccion_al_herido.y = 0.0
	if direccion_camara.length_squared() < 0.0001 or direccion_al_herido.length_squared() < 0.0001:
		return false
	var coseno_umbral := cos(deg_to_rad(angulo_mirada_grados))
	return direccion_camara.normalized().dot(direccion_al_herido.normalized()) >= coseno_umbral

func _completar_curacion() -> void:
	curado_completo = true
	print("Herido curado y estabilizado.")
	if malla:
		var material := malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = Color(0.25, 0.8, 0.3)
	curado.emit()

func _actualizar_etiqueta(enemigos_bloquean: bool, mirando: bool, curando_ahora: bool) -> void:
	if not etiqueta_estado:
		return
	if curado_completo:
		etiqueta_estado.text = "CURADO"
		return

	var porcentaje := int((_progreso / tiempo_curacion) * 100.0)
	if not _intentando_curar:
		etiqueta_estado.text = "HERIDO %d%% (E para curar)" % porcentaje
	elif curando_ahora:
		etiqueta_estado.text = "CURANDO... %d%%" % porcentaje
	elif enemigos_bloquean:
		etiqueta_estado.text = "HERIDO %d%% (despeja la zona)" % porcentaje
	elif not mirando:
		etiqueta_estado.text = "HERIDO %d%% (mira al herido)" % porcentaje
