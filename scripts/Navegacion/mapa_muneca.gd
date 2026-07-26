extends Node3D
class_name MapaMuneca
## Mapa 2D diegetico en la muneca izquierda (RF-06..RF-10). Se activa al
## levantar la mano izquierda por encima de un umbral de altura; muestra la
## posicion del jugador (centro fijo del mapa), un icono por cada nodo del
## grupo "heridos" con el color semaforico real de Herido.EstadoSalud
## (RF-13, desde S4) y dos iconos fijos para saltar de escenario. Un herido
## MUERTO atenua/oculta su icono (RF-10). Seleccion: acercar la mano derecha
## a un icono y presionar el gatillo (arbitrado en jugador.gd).
##
## Fondo: textura holografica real (assets/2D/2D_neon_map/final.png),
## integrada 2026-07-26 (PH-014). Iconos siguen siendo primitivas de Godot:
## no existe asset propio para el jugador/heridos/E1-E2 todavia.

@export var altura_activacion: float = 1.1
@export var escala_mapa: float = 0.004
@export var radio_mapa: float = 0.07
@export var radio_seleccion: float = 0.03
@export var escala_hover: float = 1.3

const COLOR_ESTABLE := Color(0.137, 0.545, 0.137) # #228B22
const COLOR_CRITICO := Color(0.855, 0.647, 0.125) # #DAA520
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0) # #CC0000
const COLOR_MUERTO := Color(0.25, 0.25, 0.25)

@onready var mano_izquierda: XRController3D = get_parent()
# No se usa get_tree().get_first_node_in_group("jugador"): MapaMuneca es
# DESCENDIENTE de Jugador (Jugador/XROrigin3D/ManoIzquierda/MapaMuneca), y
# Godot llama _ready() de abajo hacia arriba, asi que Jugador._ready() (que
# recien ahi hace add_to_group("jugador")) todavia no corrio cuando este
# _ready() se ejecuta. La ruta relativa evita depender de ese orden.
@onready var jugador: Node3D = get_node_or_null("../../..")
@onready var icono_e1: Node3D = $IconoE1
@onready var icono_e2: Node3D = $IconoE2

var mano_derecha: XRController3D
var camara: XRCamera3D
var _malla_icono_herido := SphereMesh.new()
var _iconos_heridos: Dictionary = {} # herido -> MeshInstance3D
var _destinos: Dictionary = {} # icono -> {"punto": Vector3, "escenario": String}
var _icono_hover: Node3D = null
var _abierto_manual: bool = false
var _indice_hover_escritorio: int = 0

func _ready() -> void:
	visible = false
	_malla_icono_herido.radius = 0.006
	_malla_icono_herido.height = 0.012
	_destinos[icono_e1] = {"punto": Vector3.ZERO, "escenario": "E1_Calle"}
	_destinos[icono_e2] = {"punto": Vector3.ZERO, "escenario": "E2_Edificio"}
	if jugador:
		mano_derecha = jugador.get_node_or_null("XROrigin3D/ManoDerecha")
		camara = jugador.get_node_or_null("XROrigin3D/Camera3D")

# Modo escritorio (sin headset): no hay mano que levantar, asi que la tecla
# M (jugador.gd) alterna esta bandera en vez del gesto de altura.
func alternar_manual() -> void:
	_abierto_manual = not _abierto_manual

func _process(_delta: float) -> void:
	if not mano_izquierda:
		return
	# Solo opera en mision y sin pausa: en el puesto de mando (DESPLIEGUE) la
	# navegacion pasa por el mapa de la ciudad, no por la muneca.
	if not get_viewport().use_xr:
		visible = (
			_abierto_manual
			and GestorJuego.fase == GestorJuego.Fase.MISION
			and not GestorJuego.en_pausa
		)
	else:
		visible = (
			mano_izquierda.position.y >= altura_activacion
			and GestorJuego.fase == GestorJuego.Fase.MISION
			and not GestorJuego.en_pausa
		)
	if visible:
		_actualizar_iconos_heridos()
		_actualizar_hover()

# Modo escritorio: sin mano que acercar a un icono, la rueda del mouse o
# Tab/Shift+Tab ciclan cual icono esta "en rango" (_icono_en_rango lo usa
# igual que el hover por proximidad de VR); el clic izquierdo confirma el
# que este resaltado (jugador.gd -> confirmar_seleccion, sin cambios).
func _unhandled_input(event: InputEvent) -> void:
	if not visible or get_viewport().use_xr:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_ciclar_hover_escritorio(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_ciclar_hover_escritorio(1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_ciclar_hover_escritorio(-1 if event.shift_pressed else 1)

func _ciclar_hover_escritorio(paso: int) -> void:
	var iconos := _iconos_validos()
	if iconos.is_empty():
		return
	_indice_hover_escritorio = wrapi(_indice_hover_escritorio + paso, 0, iconos.size())

func _iconos_validos() -> Array:
	return _destinos.keys().filter(func(icono): return is_instance_valid(icono))

# Plotea cada herido activo en coordenadas locales del mapa, relativas a la
# posicion del jugador (que siempre queda al centro, en el origen local).
func _actualizar_iconos_heridos() -> void:
	if not jugador:
		return
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido):
			continue
		var icono: MeshInstance3D = _iconos_heridos.get(herido)
		if not icono:
			icono = MeshInstance3D.new()
			icono.mesh = _malla_icono_herido
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			icono.material_override = material
			add_child(icono)
			_iconos_heridos[herido] = icono

		var oculto_por_muerte := false
		var color: Color
		match herido.estado_salud:
			Herido.EstadoSalud.CRITICO:
				color = COLOR_CRITICO
			Herido.EstadoSalud.AGONIZANTE:
				color = COLOR_AGONIZANTE
			Herido.EstadoSalud.MUERTO:
				color = COLOR_MUERTO
				oculto_por_muerte = true
			_: # ESTABLE o ESTABILIZADO
				color = COLOR_ESTABLE
		icono.visible = not oculto_por_muerte
		(icono.material_override as StandardMaterial3D).albedo_color = color

		var offset: Vector3 = herido.global_position - jugador.global_position
		# Mapa "forward-up": el offset se rota por el yaw de la cabeza para
		# que "adelante del jugador" sea siempre "arriba del mapa". Sin esta
		# rotacion los iconos quedan en coordenadas de mundo y el mapa
		# "miente" apenas el jugador gira el cuerpo.
		if camara:
			offset = offset.rotated(Vector3.UP, -camara.global_rotation.y)
		var local_pos := Vector3(offset.x, 0.01, offset.z) * escala_mapa
		local_pos.x = clamp(local_pos.x, -radio_mapa, radio_mapa)
		local_pos.z = clamp(local_pos.z, -radio_mapa, radio_mapa)
		icono.position = local_pos

		var punto_frente: Vector3 = herido.global_position
		punto_frente += (jugador.global_position - herido.global_position).normalized()
		_destinos[icono] = {"punto": punto_frente, "escenario": herido.escenario}

# Resalta el icono al alcance de la mano derecha (hover) antes de confirmar
# con el gatillo, con un pulso haptico suave al entrar en rango.
func _actualizar_hover() -> void:
	var candidato := _icono_en_rango()
	if candidato == _icono_hover:
		return
	if is_instance_valid(_icono_hover):
		_icono_hover.scale = Vector3.ONE
	_icono_hover = candidato
	if _icono_hover:
		_icono_hover.scale = Vector3.ONE * escala_hover
		if mano_derecha:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.05, 0.0)

func _icono_en_rango() -> Node3D:
	if not get_viewport().use_xr:
		var iconos := _iconos_validos()
		if iconos.is_empty():
			return null
		_indice_hover_escritorio = clampi(_indice_hover_escritorio, 0, iconos.size() - 1)
		return iconos[_indice_hover_escritorio]
	if not mano_derecha:
		return null
	var mas_cercano: Node3D = null
	var distancia_min := radio_seleccion
	for icono in _destinos.keys():
		if not is_instance_valid(icono):
			continue
		var d: float = mano_derecha.global_position.distance_to(icono.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = icono
	return mas_cercano

# Llamado desde jugador.gd cuando se presiona el gatillo derecho mientras el
# mapa esta visible (en vez de disparar el arma).
func confirmar_seleccion() -> void:
	if not visible:
		return
	var icono := _icono_en_rango()
	if not icono:
		return
	if mano_derecha:
		mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.6, 0.15, 0.0)
	var destino: Dictionary = _destinos[icono]
	EventBus.solicitar_teletransporte.emit(destino["punto"], destino["escenario"])
