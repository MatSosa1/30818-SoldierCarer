extends Node3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$Area3D.input_ray_pickable = false
			print("Iniciando secuencia de salida...")
			
			var tween = create_tween()
			
			tween.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE)

			tween.tween_callback(cerrar_aplicacion)

func cerrar_aplicacion():
	print("¡Cerrando el juego por completo!")
	get_tree().quit()
