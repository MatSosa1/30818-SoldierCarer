extends Node3D

# REFERENCIAS DE OBJETOS ANIMADOS
@onready var tapa: MeshInstance3D = $"../folder/Folder_001"
@onready var carpeta_completa: Node3D = $"../folder"
@onready var area_clic: Area3D = $Area3D

# REFERENCIAS DE OBJETOS A OCULTAR
@onready var btn_play: Node3D = $"."
@onready var btn_options: Node3D = $"../btn_options"
@onready var btn_exit: Node3D = $"../btn_exit"
@onready var paper: MeshInstance3D = $"../folder/Paper"
@onready var paper_001: MeshInstance3D = $"../folder/Paper_001"
@onready var paper_002: MeshInstance3D = $"../folder/Paper_002"
@onready var paper_003: MeshInstance3D = $"../folder/Paper_003"


# Hover: la sticky note crece levemente al pasar el puntero, para que se
# sienta interactiva antes del clic (feedback previo a la accion).
var _escala_base_hover: Vector3

func _ready() -> void:
	_escala_base_hover = scale
	area_clic.mouse_entered.connect(_al_entrar_hover)
	area_clic.mouse_exited.connect(_al_salir_hover)

func _al_entrar_hover() -> void:
	if area_clic.input_ray_pickable:
		create_tween().tween_property(self, "scale", _escala_base_hover * 1.08, 0.12).set_trans(Tween.TRANS_SINE)

func _al_salir_hover() -> void:
	if area_clic.input_ray_pickable:
		create_tween().tween_property(self, "scale", _escala_base_hover, 0.12).set_trans(Tween.TRANS_SINE)


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#Por ahora solo filtro para que interactue con mouse
	if event is InputEventMouseButton:
		# Reviso si fue un click izquierdo
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			comenzar_animacion_menu()

func comenzar_animacion_menu():
	# Desactivo la colision para evitar doble clic
	area_clic.input_ray_pickable = false
	
	var tween = create_tween()

	# Desaparecemos las sticky notes 
	tween.set_parallel(true)
	tween.tween_property(btn_play, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
	if btn_options: 
		tween.tween_property(btn_options, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
	if btn_exit: 
		tween.tween_property(btn_exit, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Cerramos la tapa
	tween.set_parallel(false) 
	
	var angulo_cierre = deg_to_rad(-150)
	tween.tween_property(tapa, "rotation:z", angulo_cierre, 0.8).set_trans(Tween.TRANS_SINE)
	
	# Acostamos la carpeta Y la movemos al mismo tiempo
	tween.set_parallel(true)
	
	var angulo_caida = deg_to_rad(-5)
	tween.tween_property(carpeta_completa, "rotation:x", angulo_caida, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var posicion_final_mesa = Vector3(-5.762, 2.425, 0.30)
	tween.tween_property(carpeta_completa, "position", posicion_final_mesa, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var hojas = [paper, paper_001, paper_002, paper_003]
	
	var ajuste_altura = -0.15 
	
	for hoja in hojas:
		if hoja:
			var altura_final = hoja.position.y + ajuste_altura
			tween.tween_property(hoja, "position:y", altura_final, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_callback(cambiar_de_escena)

func cambiar_de_escena():
	print("Carpeta cerrada. Iniciando el nivel de juego...")
	# RF-39: pasa por la pantalla de transicion narrativa antes de la mision.
	get_tree().change_scene_to_file("res://views/EstadoInicial.tscn")
