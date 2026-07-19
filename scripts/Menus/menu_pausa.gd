extends Node3D
class_name MenuPausa
## Menu de pausa (RF-40): panel con estetica azul electrico. Al abrirse se
## posiciona UNA vez frente a la vista, a distancia de brazo
## (distancia_apertura), y queda anclado ahi - no sigue a la cabeza. Dos
## motivos: (a) un panel pegado a la camara se mueve con cada micro-giro y
## resulta incomodo/mareante en VR; (b) la seleccion es por proximidad de la
## mano derecha + gatillo (mismo patron que MapaMuneca/KitMedico), asi que
## el panel DEBE estar al alcance fisico del brazo (~0.45 m) - el jugador
## esta fijo (RF-03) y no puede caminar hacia el.
##
## Mapa tactico simplificado a la izquierda (heridos + jugador al centro,
## mismo color semaforico que MapaMuneca); REANUDAR/OPCIONES/SALIR a la
## derecha. El icono al alcance de la mano se resalta (hover) antes de
## confirmar con el gatillo.
##
## Se abre/cierra con el boton de menu de la mano izquierda
## (jugador.gd._al_presionar_boton_mano_izquierda). Pausa la simulacion via
## GestorEscenarios.pausar_activo() en vez de SceneTree.paused, para no
## tener que lidiar con el process_mode de los XRController3D solo para que
## este menu siga recibiendo el gatillo mientras esta abierto.
##
## PLACEHOLDER: el "fondo desenfocado" del diseno original
## (UI_ART_Design.md SS5.4) se simplifica a un panel oscuro solido, sin blur
## real (PH-016).

@export var radio_seleccion: float = 0.06
@export var distancia_apertura: float = 0.45
@export var escala_hover: float = 1.15

const HeridoScript := preload("res://scripts/Herido/herido.gd")
const COLOR_ESTABLE := Color(0.137, 0.545, 0.137)
const COLOR_CRITICO := Color(0.855, 0.647, 0.125)
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0)
const ESCALA_MAPA := 0.003
const RADIO_MAPA := 0.03

@onready var mano_derecha: XRController3D = get_node_or_null("../ManoDerecha")
@onready var camara: XRCamera3D = get_node_or_null("../Camera3D")
@onready var icono_reanudar: Node3D = $IconoReanudar
@onready var icono_opciones: Node3D = $IconoOpciones
@onready var etiqueta_opcion_actual: Label3D = $IconoOpciones/EtiquetaValor
@onready var icono_salir: Node3D = $IconoSalir
@onready var mapa_tactico: Node3D = $MapaTactico

var _iconos_heridos_mapa: Dictionary = {} # herido -> MeshInstance3D
var _malla_icono_herido := SphereMesh.new()
var _icono_hover: Node3D = null

func _ready() -> void:
	visible = false
	_malla_icono_herido.radius = 0.004
	_malla_icono_herido.height = 0.008
	_actualizar_etiqueta_opcion()

func _process(_delta: float) -> void:
	if not visible:
		return
	_actualizar_mapa_tactico()
	_actualizar_hover()

func alternar() -> void:
	visible = not visible
	if visible:
		_posicionar_frente_a_la_vista()
	var gestor := get_tree().get_first_node_in_group("gestor_escenarios")
	if gestor:
		gestor.pausar_activo(visible)

# Ancla el panel una vez al abrirse: frente a la camara (solo rumbo
# horizontal, sin heredar la inclinacion de la cabeza), a distancia de
# brazo, mirando al jugador.
func _posicionar_frente_a_la_vista() -> void:
	if not camara:
		return
	var adelante: Vector3 = -camara.global_transform.basis.z
	adelante.y = 0.0
	if adelante.length_squared() < 0.0001:
		adelante = Vector3.FORWARD
	adelante = adelante.normalized()
	global_position = camara.global_position + adelante * distancia_apertura
	look_at(camara.global_position, Vector3.UP)
	rotate_object_local(Vector3.UP, PI) # el QuadMesh mira hacia +Z; girarlo hacia el jugador

# Resalta el icono al alcance de la mano derecha (hover): asi el jugador
# sabe QUE va a seleccionar antes de apretar el gatillo. Pulso haptico
# suave al entrar en rango de un icono nuevo.
func _actualizar_hover() -> void:
	var candidato := _icono_en_rango()
	if candidato == _icono_hover:
		return
	if _icono_hover:
		_icono_hover.scale = Vector3.ONE
	_icono_hover = candidato
	if _icono_hover:
		_icono_hover.scale = Vector3.ONE * escala_hover
		if mano_derecha:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.05, 0.0)

func _icono_en_rango() -> Node3D:
	if not mano_derecha:
		return null
	var mas_cercano: Node3D = null
	var distancia_min := radio_seleccion
	for icono in [icono_reanudar, icono_opciones, icono_salir]:
		var d: float = mano_derecha.global_position.distance_to(icono.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = icono
	return mas_cercano

# Llamado desde jugador.gd al presionar el gatillo derecho mientras el menu
# esta abierto.
func confirmar_seleccion() -> void:
	if not visible:
		return
	var icono := _icono_en_rango()
	if not icono:
		return
	if mano_derecha:
		mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
	if icono == icono_reanudar:
		alternar()
	elif icono == icono_opciones:
		# RF-38 Accesibilidad: unica opcion funcional hoy es la intensidad
		# del fundido de teletransporte (RNF-05); Audio/Graficos/Controles
		# no tienen sistema que configurar todavia (ver Elementos_Faltantes).
		GestorOpciones.ciclar_intensidad_teletransporte()
		_actualizar_etiqueta_opcion()
	elif icono == icono_salir:
		get_tree().change_scene_to_file("res://views/main_menu.tscn")

func _actualizar_etiqueta_opcion() -> void:
	if etiqueta_opcion_actual:
		etiqueta_opcion_actual.text = "Teletransporte: %s" % GestorOpciones.nombre_intensidad_actual()

# Mini mapa 2D (RF-40) proyectado sobre el plano del panel: X del mundo -> X
# local; -Z del mundo (adelante del jugador) -> Y local (arriba del panel).
func _actualizar_mapa_tactico() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador")
	if not jugador:
		return
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido):
			continue
		var icono: MeshInstance3D = _iconos_heridos_mapa.get(herido)
		if not icono:
			icono = MeshInstance3D.new()
			icono.mesh = _malla_icono_herido
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			icono.material_override = material
			mapa_tactico.add_child(icono)
			_iconos_heridos_mapa[herido] = icono

		if herido.estado_salud == HeridoScript.EstadoSalud.MUERTO:
			icono.visible = false
			continue
		icono.visible = true
		var color := COLOR_ESTABLE
		if herido.estado_salud == HeridoScript.EstadoSalud.CRITICO:
			color = COLOR_CRITICO
		elif herido.estado_salud == HeridoScript.EstadoSalud.AGONIZANTE:
			color = COLOR_AGONIZANTE
		(icono.material_override as StandardMaterial3D).albedo_color = color

		var offset: Vector3 = herido.global_position - jugador.global_position
		var x: float = clamp(offset.x * ESCALA_MAPA, -RADIO_MAPA, RADIO_MAPA)
		var y: float = clamp(-offset.z * ESCALA_MAPA, -RADIO_MAPA, RADIO_MAPA)
		icono.position = Vector3(x, y, 0.001)
