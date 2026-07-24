extends Node3D
class_name Pistola
## Pistola VR: extraccion de la funda de la cadera derecha (RF-25), disparo
## por raycast con municion limitada (RF-26) y recarga (RF-28). El indicador
## de cargador solo es visible con la pistola en mano (RF-27).
##
## Este nodo es hijo de ManoDerecha (el modelo/raycast siguen a la mano una
## vez desenfundada), pero el gesto de desenfundar compara la posicion de la
## mano contra PuntoFunda, un punto FIJO en la cadera (hermano de
## ManoDerecha bajo XROrigin3D) - mismo patron que kit_medico.gd con la
## mochila, en el lado derecho, asi que no compiten entre si.

@export var radio_funda: float = 0.15
@export var balas_por_cargador: int = 7
@export var cargadores_totales: int = 3

@onready var mano_derecha: XRController3D = get_parent()
@onready var punto_funda: Marker3D = get_node_or_null("../../PuntoFunda")
@onready var mano_izquierda: XRController3D = get_node_or_null("../../ManoIzquierda")
@onready var camara: XRCamera3D = get_node_or_null("../../Camera3D")
@onready var modelo: Node3D = $PH_Pistola
@onready var etiqueta_cargador: Label3D = $EtiquetaCargador
@onready var raycast: RayCast3D = $RayCast3D
@onready var sonido_disparo: AudioStreamPlayer3D = $SonidoDisparo
@onready var sonido_recarga: AudioStreamPlayer3D = $SonidoRecarga

var en_mano: bool = false
var municion_actual: int
var cargadores_restantes: int

var _dentro_funda_anterior: bool = false

func _ready() -> void:
	municion_actual = balas_por_cargador
	cargadores_restantes = cargadores_totales - 1
	_actualizar_visual()
	if mano_izquierda:
		mano_izquierda.button_pressed.connect(_al_presionar_boton_mano_izquierda)

func _process(_delta: float) -> void:
	# Modo escritorio (sin headset, ver jugador.gd._modo_vr): no hay mano
	# real que gesticular contra la funda, asi que la pistola queda
	# desenfundada de forma permanente en vez de quedar inutilizable.
	if not get_viewport().use_xr:
		if not en_mano:
			en_mano = true
			_actualizar_visual()
		return
	if not mano_derecha or not punto_funda:
		return
	var dentro: bool = mano_derecha.position.distance_to(punto_funda.position) <= radio_funda
	if dentro and not _dentro_funda_anterior:
		en_mano = not en_mano
		_actualizar_visual()
	_dentro_funda_anterior = dentro

# RF-28: recarga con un boton de la mano izquierda (X/A del mapa de accion
# OpenXR por defecto), solo tiene efecto con la pistola desenfundada.
func _al_presionar_boton_mano_izquierda(nombre_boton: String) -> void:
	if nombre_boton == "ax_button" and en_mano:
		recargar()

# Llamado desde jugador.gd al presionar el gatillo derecho. Devuelve el
# RayCast3D si disparo (para que jugador.gd emita disparo_realizado y
# muestre el trazador), o null si la pistola no esta en mano o sin balas.
func intentar_disparar() -> RayCast3D:
	if not en_mano:
		return null
	if municion_actual <= 0:
		print("Pistola sin balas: recargar (boton X/A en mano izquierda).")
		return null
	municion_actual -= 1
	if not get_viewport().use_xr:
		_apuntar_camara_escritorio()
	raycast.force_raycast_update()
	if sonido_disparo:
		sonido_disparo.play()
	# Retroceso haptico: pulso corto y fuerte en la mano que dispara.
	mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.7, 0.1, 0.0)
	_actualizar_visual()
	return raycast

# Modo escritorio: el RayCast3D cuelga de la mano, que solo gira en yaw
# junto con el resto del rig (jugador.gd rota TODO XROrigin3D con el mouse
# X); el pitch del mouse-look solo se aplica a la camara (mouse Y), asi que
# sin esto el disparo siempre salia nivelado al horizonte sin importar
# hacia donde mirara la mira en pantalla. Se re-apunta el raycast a la
# direccion exacta de la camara (mismo origen fisico, en la mano) justo
# antes de cada tiro, para que "mira" y "disparo" coincidan.
func _apuntar_camara_escritorio() -> void:
	if not camara:
		return
	var t := raycast.global_transform
	t.basis = camara.global_transform.basis
	raycast.global_transform = t

func recargar() -> void:
	if cargadores_restantes <= 0:
		print("Sin cargadores de repuesto.")
		return
	cargadores_restantes -= 1
	municion_actual = balas_por_cargador
	if sonido_recarga:
		sonido_recarga.play()
	if mano_izquierda:
		mano_izquierda.trigger_haptic_pulse("haptic", 0.0, 0.4, 0.15, 0.0)
	_actualizar_visual()
	print("Cargador recargado. Cargadores restantes: %s" % cargadores_restantes)

func _actualizar_visual() -> void:
	if modelo:
		modelo.visible = en_mano
	if etiqueta_cargador:
		etiqueta_cargador.visible = en_mano
		etiqueta_cargador.text = "%d/%d" % [municion_actual, balas_por_cargador]
