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
@onready var pistola: Node3D = $XROrigin3D/ManoDerecha/Pistola
@onready var mapa_muneca: Node3D = $XROrigin3D/ManoIzquierda/MapaMuneca
@onready var kit_medico: Node3D = $XROrigin3D/KitMedico
@onready var pantalla_danio: ColorRect = $UI/PantallaDanio
@onready var etiqueta_salud: Label = $UI/EtiquetaSalud
@onready var etiqueta_rescate: Label = $UI/EtiquetaRescate
@onready var trazador_disparo: MeshInstance3D = get_node_or_null(trazador_disparo_path)

var salud: float

func _ready() -> void:
	add_to_group("jugador")
	_inicializar_openxr()
	mano_derecha.button_pressed.connect(_al_presionar_boton_mano)
	EventBus.herido_estabilizado.connect(_al_estabilizar_herido)
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

# El gatillo derecho dispara el arma por defecto. Si el mapa de muneca esta
# abierto, confirma su seleccion (RF-08) en su lugar; si no, y el kit medico
# esta abierto, confirma la seleccion/aplicacion de item (RF-17..RF-24).
# Ambos paneles se abren con gestos de la mano izquierda mutuamente
# excluyentes (altura vs. proximidad a la mochila), asi que no compiten
# entre si por el gatillo.
func _al_presionar_boton_mano(nombre_boton: String) -> void:
	if nombre_boton != "trigger_click":
		return
	if mapa_muneca and mapa_muneca.visible:
		mapa_muneca.confirmar_seleccion()
	elif kit_medico and kit_medico.visible:
		kit_medico.confirmar_seleccion()
	else:
		disparar()

# RF-25/RF-26: solo dispara si la pistola esta desenfundada y con balas;
# pistola.gd decide eso y devuelve el RayCast3D usado, o null si no disparo
# (sin funda, sin balas). Sin tiro real no hay disparo_realizado: la esquiva
# reactiva del enemigo cuchillo solo debe reaccionar a balas de verdad.
func disparar() -> void:
	var rayo: RayCast3D = pistola.intentar_disparar()
	if not rayo:
		return
	disparo_realizado.emit(rayo)

	var origen := rayo.global_position
	var destino := origen
	if rayo.is_colliding():
		destino = rayo.get_collision_point()
	else:
		destino = rayo.global_transform * rayo.target_position
	_mostrar_trazador(origen, destino)

	if rayo.is_colliding():
		var objetivo := rayo.get_collider()
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

# RF-16: confirmacion breve "+RESCATE" al estabilizar un herido.
func _al_estabilizar_herido(_herido: Node) -> void:
	if not etiqueta_rescate:
		return
	etiqueta_rescate.visible = true
	get_tree().create_timer(1.5).timeout.connect(func(): etiqueta_rescate.visible = false)
