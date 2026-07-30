extends NotaMenu
## Nota adhesiva SALIR: cierra el juego. Hover y clic vienen de NotaMenu.

func _al_seleccionar() -> void:
	area_clic.input_ray_pickable = false
	print("Iniciando secuencia de salida...")

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(cerrar_aplicacion)

func cerrar_aplicacion():
	print("¡Cerrando el juego por completo!")
	get_tree().quit()
