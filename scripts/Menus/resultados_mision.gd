extends Node3D
class_name ResultadosMision
## RF-44: pantalla de resultados al terminar la mision (RF-43: tiempo
## agotado o jugador eliminado). Aparece automaticamente al recibir
## GestorJuego.mision_finalizada; se ancla al mundo frente a la vista igual
## que MenuPausa (mismo motivo: el jugador esta fijo - RF-03 - y la
## seleccion es por proximidad de mano, asi que el panel tiene que quedar
## al alcance del brazo, no seguir pegado a la camara). Cierra cualquier
## otro panel abierto (mapa/kit/pausa) para no superponer UI.
##
## Un solo boton (VOLVER AL MENU) por proximidad+gatillo, mismo patron que
## el resto del proyecto.

@export var distancia_apertura: float = 0.5
@export var radio_seleccion: float = 0.07

@onready var camara: XRCamera3D = get_node_or_null("../Camera3D")
@onready var mano_derecha: XRController3D = get_node_or_null("../ManoDerecha")
@onready var menu_pausa: MenuPausa = get_node_or_null("../MenuPausa")
@onready var mapa_muneca: MapaMuneca = get_node_or_null("../ManoIzquierda/MapaMuneca")
@onready var kit_medico: KitMedico = get_node_or_null("../KitMedico")
@onready var etiqueta_resultado: Label3D = $EtiquetaResultado
@onready var etiqueta_rescates: Label3D = $EtiquetaRescates
@onready var icono_volver: Node3D = $IconoVolver

func _ready() -> void:
	visible = false
	GestorJuego.mision_finalizada.connect(_al_finalizar_mision)

func _al_finalizar_mision(resultado: String, rescates: int) -> void:
	var nombres := {"tiempo_agotado": "TIEMPO AGOTADO", "eliminado": "HAS CAIDO"}
	etiqueta_resultado.text = nombres.get(resultado, resultado.to_upper())
	etiqueta_rescates.text = "Soldados rescatados: %d" % rescates
	if menu_pausa:
		menu_pausa.visible = false
	if mapa_muneca:
		mapa_muneca.visible = false
	if kit_medico:
		kit_medico.visible = false
	visible = true
	_posicionar_frente_a_la_vista()

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

func confirmar_seleccion() -> void:
	if not visible or not mano_derecha:
		return
	if mano_derecha.global_position.distance_to(icono_volver.global_position) <= radio_seleccion:
		mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
		get_tree().change_scene_to_file("res://views/main_menu.tscn")
