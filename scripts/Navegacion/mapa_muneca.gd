extends Node3D
## Mapa 2D diegetico en la muneca izquierda (RF-06..RF-10). Se activa al
## levantar la mano izquierda por encima de un umbral de altura; muestra la
## posicion del jugador (centro fijo del mapa), un icono por cada nodo del
## grupo "heridos" con el color semaforico real de Herido.EstadoSalud
## (RF-13, desde S4) y dos iconos fijos para saltar de escenario. Un herido
## MUERTO atenua/oculta su icono (RF-10). Seleccion: acercar la mano derecha
## a un icono y presionar el gatillo (arbitrado en jugador.gd).
##
## PLACEHOLDER: fondo y iconos son primitivas de Godot (PH-014). El arte de
## mapa holografico final ya existe en assets/2D/2D_neon_map/.

@export var altura_activacion: float = 1.1
@export var escala_mapa: float = 0.004
@export var radio_mapa: float = 0.07
@export var radio_seleccion: float = 0.03

const HeridoScript := preload("res://scripts/Herido/herido.gd")

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
var _malla_icono_herido := SphereMesh.new()
var _iconos_heridos: Dictionary = {} # herido -> MeshInstance3D
var _destinos: Dictionary = {} # icono -> {"punto": Vector3, "escenario": String}

func _ready() -> void:
	visible = false
	_malla_icono_herido.radius = 0.006
	_malla_icono_herido.height = 0.012
	_destinos[icono_e1] = {"punto": Vector3.ZERO, "escenario": "E1_Calle"}
	_destinos[icono_e2] = {"punto": Vector3.ZERO, "escenario": "E2_Edificio"}
	if jugador:
		mano_derecha = jugador.get_node_or_null("XROrigin3D/ManoDerecha")

func _process(_delta: float) -> void:
	if not mano_izquierda:
		return
	visible = mano_izquierda.position.y >= altura_activacion
	if visible:
		_actualizar_iconos_heridos()

# Plotea cada herido activo en coordenadas locales del mapa, relativas a la
# posicion del jugador (que siempre queda al centro, en el origen local).
func _actualizar_iconos_heridos() -> void:
	if not jugador:
		return
	for herido in get_tree().get_nodes_in_group("heridos"):
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

		var estado = herido.get("estado_salud")
		var oculto_por_muerte := false
		var color: Color
		match estado:
			HeridoScript.EstadoSalud.CRITICO:
				color = COLOR_CRITICO
			HeridoScript.EstadoSalud.AGONIZANTE:
				color = COLOR_AGONIZANTE
			HeridoScript.EstadoSalud.MUERTO:
				color = COLOR_MUERTO
				oculto_por_muerte = true
			_: # ESTABLE o ESTABILIZADO
				color = COLOR_ESTABLE
		icono.visible = not oculto_por_muerte
		(icono.material_override as StandardMaterial3D).albedo_color = color

		var offset: Vector3 = herido.global_position - jugador.global_position
		var local_pos := Vector3(offset.x, 0.01, offset.z) * escala_mapa
		local_pos.x = clamp(local_pos.x, -radio_mapa, radio_mapa)
		local_pos.z = clamp(local_pos.z, -radio_mapa, radio_mapa)
		icono.position = local_pos

		var punto_frente: Vector3 = herido.global_position
		punto_frente += (jugador.global_position - herido.global_position).normalized()
		# PLACEHOLDER: escenario fijo a "E1_Calle" porque hoy solo existe un
		# herido y vive ahi. Cuando S4 agregue heridos en E2, resolver el
		# escenario real del herido en vez de fijarlo aqui.
		_destinos[icono] = {"punto": punto_frente, "escenario": "E1_Calle"}

# Llamado desde jugador.gd cuando se presiona el gatillo derecho mientras el
# mapa esta visible (en vez de disparar el arma).
func confirmar_seleccion() -> void:
	if not visible or not mano_derecha:
		return
	for icono in _destinos.keys():
		if not is_instance_valid(icono):
			continue
		if mano_derecha.global_position.distance_to(icono.global_position) <= radio_seleccion:
			var destino: Dictionary = _destinos[icono]
			EventBus.solicitar_teletransporte.emit(destino["punto"], destino["escenario"])
			return
