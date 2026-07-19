extends Node3D
## Apertura del kit (RF-17) y aplicacion de items sobre heridos cercanos
## (RF-18..RF-24). Se abre acercando la mano izquierda a la posicion de este
## nodo, que representa la mochila colgada a la altura de la cadera (ver
## Jugador.tscn; posicion distinta del gesto de "levantar mano" que abre
## MapaMuneca, para no disparar ambos a la vez).
##
## Seleccion de item y aplicacion de items de confirmacion manual
## (morfina/analgesicos) comparten el gatillo derecho con el mapa y el arma;
## jugador.gd arbitra el orden llamando a confirmar_seleccion().

@export var radio_apertura: float = 0.15
@export var radio_seleccion: float = 0.05
@export var rango_tratamiento: float = 1.5

@onready var mano_izquierda: XRController3D = get_node_or_null("../ManoIzquierda")
@onready var mano_derecha: XRController3D = get_node_or_null("../ManoDerecha")
@onready var etiqueta_equipado: Label3D = $EtiquetaEquipado
@onready var etiqueta_feedback: Label3D = $EtiquetaFeedback
@onready var sonido_feedback: AudioStreamPlayer3D = $SonidoFeedback

var item_equipado: ItemMedico = null
var _items: Array[ItemMedico] = []

func _ready() -> void:
	visible = false
	etiqueta_feedback.visible = false
	for hijo in get_children():
		if hijo is ItemMedico:
			_items.append(hijo)

func _process(delta: float) -> void:
	if not mano_izquierda:
		return
	visible = mano_izquierda.position.distance_to(position) <= radio_apertura
	if not visible:
		return

	for item in _items:
		item.visible = item != item_equipado

	if not item_equipado:
		etiqueta_equipado.text = ""
		return

	etiqueta_equipado.text = "Equipado: %s" % item_equipado.nombre_item
	if item_equipado.requiere_confirmacion_manual():
		return
	var herido := _herido_en_rango()
	if herido and item_equipado.procesar_gesto(delta, mano_derecha, herido):
		var exito: bool = herido.aplicar_tratamiento(item_equipado.tipo)
		_completar_aplicacion(exito)

# Llamado desde jugador.gd al presionar el gatillo derecho mientras el kit
# esta abierto: sin item equipado, intenta seleccionar uno por proximidad;
# con un item de confirmacion manual equipado, lo aplica si hay un herido
# en rango.
func confirmar_seleccion() -> void:
	if not visible or not mano_derecha:
		return
	if not item_equipado:
		for item in _items:
			if mano_derecha.global_position.distance_to(item.global_position) <= radio_seleccion:
				item_equipado = item
				item.reiniciar()
				return
		return
	if item_equipado.requiere_confirmacion_manual():
		var herido := _herido_en_rango()
		if herido:
			var exito: bool = herido.aplicar_tratamiento(item_equipado.tipo)
			_completar_aplicacion(exito)

func _completar_aplicacion(exito: bool) -> void:
	_dar_feedback(exito)
	if item_equipado:
		item_equipado.reiniciar()
	item_equipado = null

# RF-24: feedback visual + sonoro por gesto. El AudioStreamPlayer3D queda
# cableado sin stream (PLACEHOLDER de audio, ver Contexto.md SS6.2); .play()
# es un no-op seguro hasta que S8 asigne el clip final.
func _dar_feedback(exito: bool) -> void:
	etiqueta_feedback.text = "OK" if exito else "FALLO: orden incorrecto"
	etiqueta_feedback.modulate = Color(0.2, 0.8, 0.3) if exito else Color(0.9, 0.2, 0.2)
	etiqueta_feedback.visible = true
	if sonido_feedback:
		sonido_feedback.play()
	get_tree().create_timer(1.0).timeout.connect(func(): etiqueta_feedback.visible = false)

func _herido_en_rango() -> Node:
	var mas_cercano: Node = null
	var distancia_min := rango_tratamiento
	for herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido):
			continue
		var d: float = mano_derecha.global_position.distance_to(herido.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = herido
	return mas_cercano
