extends CharacterBody3D
## Rig VR del jugador (OpenXR). Fijo en posicion (RF-03): la unica rotacion de
## "cabeza" viene del tracking real del headset via XRCamera3D, no de script.
## Conserva el contrato de la demo no-VR: senial disparo_realizado(rayo) y
## metodo recibir_dano(), de los que depende la IA de enemigos existente
## (ver Arquitectura.md SS5).

signal disparo_realizado(rayo: RayCast3D)

@export var salud_maxima: float = 100.0
@export var dano_disparo: float = 10.0

@export var trazador_disparo_path: NodePath

@onready var mano_derecha: XRController3D = $XROrigin3D/ManoDerecha
@onready var arma_raycast: RayCast3D = $XROrigin3D/ManoDerecha/Arma/RayCast3D
@onready var mapa_muneca: Node3D = $XROrigin3D/ManoIzquierda/MapaMuneca
@onready var pantalla_danio: ColorRect = $UI/PantallaDanio
@onready var etiqueta_salud: Label = $UI/EtiquetaSalud
@onready var trazador_disparo: MeshInstance3D = get_node_or_null(trazador_disparo_path)

var salud: float

func _ready() -> void:
	add_to_group("jugador")
	_inicializar_openxr()
	mano_derecha.button_pressed.connect(_al_presionar_boton_mano)
	salud = salud_maxima
	_actualizar_etiqueta_salud()

# RF-01: inicializa OpenXR y activa el viewport en modo XR si detecta headset
# y controladores. Si no hay runtime/headset disponible, el juego sigue
# funcionando sin XR activo (util para revisar la escena en el editor).
func _inicializar_openxr() -> void:
	var interfaz := XRServer.find_interface("OpenXR")
	if interfaz and interfaz.is_initialized():
		get_viewport().use_xr = true
		print("OpenXR inicializado: headset y controladores detectados.")
	else:
		print("OpenXR no disponible: ejecutando sin XR activo (revisa el runtime/headset).")

# El gatillo derecho dispara el arma, salvo que el mapa de muneca este
# abierto: en ese caso confirma la seleccion del mapa (RF-08) en su lugar.
func _al_presionar_boton_mano(nombre_boton: String) -> void:
	if nombre_boton != "trigger_click":
		return
	if mapa_muneca and mapa_muneca.visible:
		mapa_muneca.confirmar_seleccion()
	else:
		disparar()

func disparar() -> void:
	arma_raycast.force_raycast_update()
	disparo_realizado.emit(arma_raycast)

	var origen := arma_raycast.global_position
	var destino := origen
	if arma_raycast.is_colliding():
		destino = arma_raycast.get_collision_point()
	else:
		destino = arma_raycast.global_transform * arma_raycast.target_position
	_mostrar_trazador(origen, destino)

	if arma_raycast.is_colliding():
		var objetivo := arma_raycast.get_collider()
		if objetivo and objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano_disparo)

# Dibuja brevemente la trayectoria del disparo: el RayCast3D en si es invisible
# en juego, esta linea es solo para poder confirmar visualmente el impacto.
func _mostrar_trazador(origen: Vector3, destino: Vector3) -> void:
	if not trazador_disparo:
		return
	var malla := trazador_disparo.mesh as ImmediateMesh
	malla.clear_surfaces()
	malla.surface_begin(Mesh.PRIMITIVE_LINES)
	malla.surface_add_vertex(origen)
	malla.surface_add_vertex(destino)
	malla.surface_end()
	trazador_disparo.visible = true
	get_tree().create_timer(0.08).timeout.connect(func(): trazador_disparo.visible = false)

func recibir_dano(cantidad: float) -> void:
	salud = max(salud - cantidad, 0.0)
	_actualizar_etiqueta_salud()
	if pantalla_danio:
		pantalla_danio.color.a = min(pantalla_danio.color.a + 0.25, 0.6)
		var tween := create_tween()
		tween.tween_property(pantalla_danio, "color:a", 0.0, 0.6)
	print("Jugador recibio %s de dano. Salud: %s" % [cantidad, salud])

func _actualizar_etiqueta_salud() -> void:
	if etiqueta_salud:
		etiqueta_salud.text = "Salud: %d" % salud
