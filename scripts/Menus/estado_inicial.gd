extends Node3D
## RF-39: pantalla de transicion narrativa ("documentos sobre la mesa")
## entre el menu principal y el inicio de la mision. El briefing se revela
## letra por letra (efecto maquina de escribir, coherente con la identidad
## "documento clasificado" de UI_ART_Design.md SS1). Continua con clic
## (Area3D, mismo patron que los botones de MainMenu) o automaticamente al
## agotarse duracion_maxima; el tiempo restante se muestra junto al "clic
## para continuar" para que el auto-avance no tome por sorpresa.
##
## PLACEHOLDER: texto de briefing generico y prop de documento minimo; el
## arte final (mesa, documentos con logo/mapa) esta pendiente (PH-017).

@export var duracion_maxima: float = 8.0
@export var caracteres_por_segundo: float = 35.0
@export var duracion_fundido: float = 0.5 # RNF-03: fundido a negro entre menu y mision

@onready var area_continuar: Area3D = $AreaContinuar
@onready var texto_briefing: Label3D = $Documento/TextoBriefing
@onready var etiqueta_continuar: Label3D = $EtiquetaContinuar
@onready var sonido_tecleo: AudioStreamPlayer = $SonidoTecleo
@onready var desvanecido: ColorRect = $UI/Desvanecido

var _texto_completo: String
var _caracteres_visibles: float = 0.0
var _tiempo_restante: float
var _continuado: bool = false

func _ready() -> void:
	_tiempo_restante = duracion_maxima
	_texto_completo = texto_briefing.text
	texto_briefing.text = ""
	if area_continuar:
		area_continuar.input_event.connect(_on_area_input_event)
	if desvanecido:
		create_tween().tween_property(desvanecido, "color:a", 0.0, duracion_fundido)

func _process(delta: float) -> void:
	if _continuado:
		return

	# Efecto maquina de escribir: Label3D no tiene visible_characters (eso
	# es de Label/RichTextLabel), asi que se revela por substring.
	if _caracteres_visibles < _texto_completo.length():
		var anteriores := int(_caracteres_visibles)
		_caracteres_visibles = min(_caracteres_visibles + caracteres_por_segundo * delta, _texto_completo.length())
		if int(_caracteres_visibles) != anteriores:
			texto_briefing.text = _texto_completo.substr(0, int(_caracteres_visibles))
			if sonido_tecleo and not sonido_tecleo.playing:
				sonido_tecleo.play() # PLACEHOLDER: sin stream (tic de tecleo, PH-013)

	_tiempo_restante -= delta
	if etiqueta_continuar:
		etiqueta_continuar.text = "(clic para continuar — %d)" % ceil(max(_tiempo_restante, 0.0))
	if _tiempo_restante <= 0.0:
		_continuar()

func _on_area_input_event(_camara: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Primer clic con el texto a medio revelar: completa el texto.
		# Segundo clic (o primero con el texto ya completo): continua.
		if _caracteres_visibles < _texto_completo.length():
			_caracteres_visibles = _texto_completo.length()
			texto_briefing.text = _texto_completo
		else:
			_continuar()

func _continuar() -> void:
	if _continuado:
		return
	_continuado = true
	if desvanecido:
		var tween := create_tween()
		tween.tween_property(desvanecido, "color:a", 1.0, duracion_fundido)
		tween.tween_callback(func(): get_tree().change_scene_to_file("res://views/Mision.tscn"))
	else:
		get_tree().change_scene_to_file("res://views/Mision.tscn")
