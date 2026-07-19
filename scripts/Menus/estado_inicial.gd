extends Node3D
## RF-39: pantalla de transicion narrativa ("documentos sobre la mesa")
## entre el menu principal y el inicio de la mision. Continua con clic (Area3D,
## mismo patron que los botones de MainMenu) o automaticamente pasados
## duracion_maxima segundos si el jugador no interactua.
##
## PLACEHOLDER: texto de briefing generico y prop de documento minimo; el
## arte final (mesa, documentos con logo/mapa) esta pendiente (PH- nuevo,
## ver Elementos_Faltantes.md).

@export var duracion_maxima: float = 6.0

@onready var area_continuar: Area3D = $AreaContinuar

var _continuado: bool = false

func _ready() -> void:
	if area_continuar:
		area_continuar.input_event.connect(_on_area_input_event)
	get_tree().create_timer(duracion_maxima).timeout.connect(_continuar)

func _on_area_input_event(_camara: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_continuar()

func _continuar() -> void:
	if _continuado:
		return
	_continuado = true
	get_tree().change_scene_to_file("res://views/Mision.tscn")
