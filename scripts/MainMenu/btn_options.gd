extends NotaMenu
## Nota adhesiva OPCIONES: cierra y reabre la carpeta para "cambiar de hoja" y
## muestra el panel de audio (RF-38) sobre el documento. Hover, ocultado y
## restaurado de las notas vienen de NotaMenu.

# REFERENCIAS DE OBJETOS ANIMADOS
@onready var tapa: MeshInstance3D = $"../folder/Folder_001"
@onready var carpeta_completa: Node3D = $"../folder"
@onready var contenedor_opciones: Node3D = $"../folder/Contenedor_Opciones"
@onready var area_clic_volver: Area3D = $"../folder/Contenedor_Opciones/btn_volver"
# RF-38: controles de volumen (mismo bug ya documentado en menu_pausa.gd -
# ocultar Contenedor_Opciones con visible=false no desactiva la colision de
# sus Area3D hijos, hay que apagar input_ray_pickable a mano).
@onready var controles_volumen: Array[Area3D] = [
	$"../folder/Contenedor_Opciones/ControlVolumenMaster",
	$"../folder/Contenedor_Opciones/ControlVolumenMusica",
	$"../folder/Contenedor_Opciones/ControlVolumenSFX",
]

# REFERENCIAS DE OBJETOS A OCULTAR
@onready var paper: MeshInstance3D = $"../folder/Paper"
@onready var paper_001: MeshInstance3D = $"../folder/Paper_001"
@onready var paper_002: MeshInstance3D = $"../folder/Paper_002"
@onready var paper_003: MeshInstance3D = $"../folder/Paper_003"

# Variables globales para guardar los estados originales
var angulo_original_tapa: float
var escala_original_papeles: Vector3

func _ready() -> void:
	super()
	# area_clic_volver.input_event ya esta cableado desde main_menu.tscn
	# ([connection] a _on_btn_volver_input_event) - conectarlo tambien aca
	# duplicaba la conexion y tiraba un error en cada arranque del juego.
	if area_clic_volver:
		# Contenedor_Opciones arranca oculto (visible=false), pero eso no
		# desactiva la colision de sus Area3D hijos (mismo bug ya resuelto en
		# menu_pausa.gd) - sin la tapa cerrada tapando esta zona, area_clic_volver
		# y los controles de volumen quedarian clickeables desde el menu principal.
		area_clic_volver.input_ray_pickable = false
	for control in controles_volumen:
		control.input_ray_pickable = false

func _al_seleccionar() -> void:
	comenzar_animacion_opciones()

func _on_btn_volver_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		animacion_volver_menu()

func comenzar_animacion_opciones():
	fijar_colisiones_notas(false)

	angulo_original_tapa = tapa.rotation.z
	if paper_001:
		escala_original_papeles = paper_001.scale
	else:
		escala_original_papeles = Vector3(1, 1, 1)

	var tween = create_tween()

	# Desaparecer las sticky notes
	tween.set_parallel(true)
	ocultar_notas(tween)

	# Cerrar la tapa
	tween.set_parallel(false)
	var angulo_cierre = deg_to_rad(-130)
	tween.tween_property(tapa, "rotation:z", angulo_cierre, 0.4).set_trans(Tween.TRANS_SINE)

	tween.set_parallel(true)
	if paper_003: tween.tween_property(paper_003, "scale", Vector3.ZERO, 0.8)

	var escala_reducida = escala_original_papeles * 0.25
	if paper_001: tween.tween_property(paper_001, "scale", escala_reducida, 0.5)
	if paper_002: tween.tween_property(paper_002, "scale", escala_reducida, 0.5)
	if paper: tween.tween_property(paper, "scale", escala_reducida, 0.2)

	# Abrir la tapa y restaurar las hojas
	tween.set_parallel(false)
	tween.tween_interval(0.1)

	tween.set_parallel(true)
	tween.tween_property(tapa, "rotation:z", angulo_original_tapa, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if paper_001: tween.tween_property(paper_001, "scale", escala_original_papeles, 0.6).set_trans(Tween.TRANS_SINE)
	if paper_002: tween.tween_property(paper_002, "scale", escala_original_papeles, 0.6).set_trans(Tween.TRANS_SINE)
	if paper: tween.tween_property(paper, "scale", escala_original_papeles, 0.6).set_trans(Tween.TRANS_SINE)

	# Mostrar la nueva UI
	tween.set_parallel(false)
	tween.tween_callback(mostrar_menu_opciones)

func mostrar_menu_opciones():
	contenedor_opciones.visible = true
	var tween = create_tween()
	tween.set_parallel(true)

	# Todas las opciones entran con la misma escala: ya no queda ningun Sprite3D
	# (el placeholder "Opciones_extra" se reemplazo por las filas de volumen).
	for opcion in contenedor_opciones.get_children():
		opcion.scale = Vector3.ZERO
		tween.tween_property(opcion, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.set_parallel(false)
	tween.tween_callback(reactivar_colisiones_opciones)

func reactivar_colisiones_opciones():

	if area_clic_volver:
		area_clic_volver.input_ray_pickable = true
	for control in controles_volumen:
		control.input_ray_pickable = true

# ANIMACIÓN DE VUELTA
func animacion_volver_menu():
	if area_clic_volver:
		area_clic_volver.input_ray_pickable = false
	for control in controles_volumen:
		control.input_ray_pickable = false

	var tween = create_tween()

	# Ocultar los botones de opciones
	tween.set_parallel(true)
	for opcion in contenedor_opciones.get_children():
		tween.tween_property(opcion, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)

	# Cerrar la tapa
	tween.set_parallel(false)
	tween.tween_callback(func(): contenedor_opciones.visible = false)

	var angulo_cierre = deg_to_rad(-130)
	tween.tween_property(tapa, "rotation:z", angulo_cierre, 0.4).set_trans(Tween.TRANS_SINE)

	# Restaurar el sello Confidencial
	tween.set_parallel(true)
	if paper_003: tween.tween_property(paper_003, "scale", escala_original_papeles, 0.8)

	# Abrir la tapa a su estado original
	tween.set_parallel(false)
	tween.tween_interval(0.1)

	tween.set_parallel(true)
	tween.tween_property(tapa, "rotation:z", angulo_original_tapa, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Reaparecer las sticky notes del menú principal
	restaurar_notas(tween, 1.5)

	# Reactivar el menú
	tween.set_parallel(false)
	tween.tween_callback(reactivar_menu_principal)

func reactivar_menu_principal():
	print("¡De vuelta a la pantalla de inicio!")

	# Reactivamos las colisiones de TODAS las notas del menu
	fijar_colisiones_notas(true)
