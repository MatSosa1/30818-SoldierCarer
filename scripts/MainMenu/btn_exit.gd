extends Node3D

# Hover: la sticky note crece levemente al pasar el puntero (ver btn_play.gd).
var _escala_base_hover: Vector3

func _ready() -> void:
	_escala_base_hover = scale
	$Area3D.mouse_entered.connect(_al_entrar_hover)
	$Area3D.mouse_exited.connect(_al_salir_hover)

func _al_entrar_hover() -> void:
	if $Area3D.input_ray_pickable:
		create_tween().tween_property(self, "scale", _escala_base_hover * 1.08, 0.12).set_trans(Tween.TRANS_SINE)

func _al_salir_hover() -> void:
	if $Area3D.input_ray_pickable:
		create_tween().tween_property(self, "scale", _escala_base_hover, 0.12).set_trans(Tween.TRANS_SINE)

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
