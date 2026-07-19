extends Node3D
class_name MapaDespliegue
## Mapa de la ciudad en el puesto de mando (fase DESPLIEGUE). Antes de entrar
## en combate, el jugador elige aca a que punto de la ciudad dirigirse a
## rescatar heridos (RF-08/RF-39): cada icono representa un escenario (E1
## Calle / E2 Edificio) y muestra el color semaforico del herido que hay en
## el (RF-13). Al confirmar, GestorEscenarios teletransporta al punto de
## despliegue del escenario (su entrada, no encima del herido) y GestorJuego
## arranca el reloj de mision.
##
## Seleccion doble, coherente con el resto del proyecto:
## - Escritorio: clic izquierdo sobre el Area3D del icono (patron MainMenu).
## - VR: acercar la mano derecha al icono y presionar el gatillo (arbitrado
##   en jugador.gd, mismo patron que MapaMuneca).
##
## PLACEHOLDER: plano de ciudad y iconos con primitivas de Godot (PH-020);
## el arte 2D de mapa neon existe en assets/2D/2D_neon_map.

@export var radio_seleccion: float = 0.08
@export var escala_hover: float = 1.25

const COLOR_ESTABLE := Color(0.137, 0.545, 0.137) # #228B22
const COLOR_CRITICO := Color(0.855, 0.647, 0.125) # #DAA520
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0) # #CC0000
const COLOR_MUERTO := Color(0.25, 0.25, 0.25)

@onready var icono_e1: Node3D = $IconoE1
@onready var icono_e2: Node3D = $IconoE2
@onready var etiqueta_titulo: Label3D = $EtiquetaTitulo

var _escenario_por_icono: Dictionary = {}
var _icono_hover: Node3D = null
var _mano_derecha: XRController3D

func _ready() -> void:
	add_to_group("mapa_despliegue") # para el arbitraje del gatillo en jugador.gd
	_escenario_por_icono = {icono_e1: "E1_Calle", icono_e2: "E2_Edificio"}
	for icono: Node3D in _escenario_por_icono.keys():
		var area: Area3D = icono.get_node_or_null("Area3D")
		if area:
			area.input_event.connect(_al_input_de_icono.bind(icono))

func _process(_delta: float) -> void:
	var activo := GestorJuego.fase == GestorJuego.Fase.DESPLIEGUE
	for icono: Node3D in _escenario_por_icono.keys():
		_actualizar_color_icono(icono, activo)
	if not activo:
		etiqueta_titulo.text = "DESPLIEGUE CONFIRMADO"
		return
	etiqueta_titulo.text = "SELECCIONA PUNTO DE DESPLIEGUE"
	_actualizar_hover()

# El color del icono refleja el peor herido pendiente de ese escenario, igual
# que el mapa de muneca: la decision de a donde ir primero es informada.
func _actualizar_color_icono(icono: Node3D, activo: bool) -> void:
	var malla: MeshInstance3D = icono.get_node_or_null("Malla")
	if not malla or not malla.material_override is StandardMaterial3D:
		return
	var color := _color_heridos_de(_escenario_por_icono[icono])
	if not activo:
		color = color.darkened(0.6)
	var material := malla.material_override as StandardMaterial3D
	material.albedo_color = color
	material.emission = color

func _color_heridos_de(escenario: String) -> Color:
	var peor := -1
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido) or herido.escenario != escenario:
			continue
		if herido.curado_completo:
			continue
		peor = max(peor, herido.estado_salud)
	match peor:
		Herido.EstadoSalud.CRITICO:
			return COLOR_CRITICO
		Herido.EstadoSalud.AGONIZANTE:
			return COLOR_AGONIZANTE
		Herido.EstadoSalud.MUERTO:
			return COLOR_MUERTO
		-1: # sin heridos pendientes (todos estabilizados)
			return COLOR_MUERTO
		_:
			return COLOR_ESTABLE

func _al_input_de_icono(_camara: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int, icono: Node3D) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_seleccionar(icono)

# Resalta el icono al alcance de la mano derecha antes de confirmar con el
# gatillo, con pulso haptico suave al entrar en rango (patron MapaMuneca).
func _actualizar_hover() -> void:
	var candidato := _icono_en_rango()
	if candidato == _icono_hover:
		return
	if is_instance_valid(_icono_hover):
		_icono_hover.scale = Vector3.ONE
	_icono_hover = candidato
	if _icono_hover:
		_icono_hover.scale = Vector3.ONE * escala_hover
		if _mano_derecha:
			_mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.05, 0.0)

func _icono_en_rango() -> Node3D:
	if not _mano_derecha:
		var jugador := get_tree().get_first_node_in_group("jugador")
		if jugador:
			_mano_derecha = jugador.get_node_or_null("XROrigin3D/ManoDerecha")
		if not _mano_derecha:
			return null
	var mas_cercano: Node3D = null
	var distancia_min := radio_seleccion
	for icono: Node3D in _escenario_por_icono.keys():
		var d: float = _mano_derecha.global_position.distance_to(icono.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = icono
	return mas_cercano

# Llamado desde jugador.gd al presionar el gatillo derecho durante la fase
# de despliegue.
func confirmar_seleccion() -> void:
	var icono := _icono_en_rango()
	if not icono:
		return
	if _mano_derecha:
		_mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.6, 0.15, 0.0)
	_seleccionar(icono)

func _seleccionar(icono: Node3D) -> void:
	if GestorJuego.fase != GestorJuego.Fase.DESPLIEGUE:
		return
	var escenario: String = _escenario_por_icono[icono]
	# Vector3.ZERO = centinela "usar el PuntoDespliegue del escenario" (la
	# entrada del escenario, no la posicion del herido): el jugador llega a la
	# zona y navega hasta el herido con el mapa de muneca.
	EventBus.solicitar_teletransporte.emit(Vector3.ZERO, escenario)
	GestorJuego.iniciar_mision(escenario)
