extends CharacterBody3D
## Jugador fijo en posicion: solo rota sobre su eje Y (yaw) para vigilar los 4 carriles.
## Control desktop (mouse) como placeholder de la rotacion de cabeza en VR.

signal disparo_realizado(rayo: RayCast3D)

@export var sensibilidad_mouse: float = 0.0035
@export var salud_maxima: float = 100.0
@export var dano_disparo: float = 10.0

@export var trazador_disparo_path: NodePath

@onready var arma_raycast: RayCast3D = $Camera3D/Arma/RayCast3D
@onready var pantalla_danio: ColorRect = $UI/PantallaDanio
@onready var etiqueta_salud: Label = $UI/EtiquetaSalud
@onready var trazador_disparo: MeshInstance3D = get_node_or_null(trazador_disparo_path)

var salud: float

func _ready() -> void:
	add_to_group("jugador")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	salud = salud_maxima
	_actualizar_etiqueta_salud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		disparar()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

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
