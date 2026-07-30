extends Node3D
class_name PantallaDocumento
## Pantalla informativa de solo lectura del menu, con la estetica "documento
## clasificado" de UI_ART_Design.md (hojas sobre la mesa, igual que
## estado_inicial.gd): la usan Creditos.tscn y Controles.tscn, que solo cambian
## los textos de la escena y por eso comparten script.
##
## Un unico boton VOLVER AL MENU con el mismo patron Area3D + clic izquierdo que
## las notas del menu principal (ver CLAUDE.md SS6), mas ESC como atajo: la
## pantalla no tiene estado que perder y sin atajo un jugador que no encuentre
## el boton queda atrapado. Entra y sale con fundido a negro (RNF-03), igual que
## el resto de las transiciones entre escenas.

@export_file("*.tscn") var escena_volver: String = "res://views/main_menu.tscn"
@export var duracion_fundido: float = 0.4
@export var factor_hover: float = 1.12

@onready var area_volver: Area3D = $AreaVolver
@onready var etiqueta_volver: Label3D = $AreaVolver/Etiqueta
@onready var desvanecido: ColorRect = $UI/Desvanecido

var _escala_base_etiqueta: Vector3
var _volviendo: bool = false

func _ready() -> void:
	# RF-46: estas pantallas siguen siendo menu, la musica calma no se corta.
	GestorAudio.cambiar_estado(GestorAudio.EstadoMusica.MENU)
	_escala_base_etiqueta = etiqueta_volver.scale
	area_volver.input_event.connect(_al_recibir_input)
	area_volver.mouse_entered.connect(_al_entrar_hover)
	area_volver.mouse_exited.connect(_al_salir_hover)
	if desvanecido:
		create_tween().tween_property(desvanecido, "color:a", 0.0, duracion_fundido)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		volver_al_menu()

func _al_recibir_input(
	_camara: Node, evento: InputEvent, _posicion: Vector3, _normal: Vector3, _indice_forma: int
) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		volver_al_menu()

func _al_entrar_hover() -> void:
	if _volviendo:
		return
	var tween := create_tween()
	tween.tween_property(etiqueta_volver, "scale", _escala_base_etiqueta * factor_hover, 0.12)
	tween.set_trans(Tween.TRANS_SINE)

func _al_salir_hover() -> void:
	if _volviendo:
		return
	var tween := create_tween()
	tween.tween_property(etiqueta_volver, "scale", _escala_base_etiqueta, 0.12)
	tween.set_trans(Tween.TRANS_SINE)

func volver_al_menu() -> void:
	if _volviendo:
		return
	_volviendo = true
	area_volver.input_ray_pickable = false
	if desvanecido:
		var tween := create_tween()
		tween.tween_property(desvanecido, "color:a", 1.0, duracion_fundido)
		tween.tween_callback(func(): get_tree().change_scene_to_file(escena_volver))
	else:
		get_tree().change_scene_to_file(escena_volver)
