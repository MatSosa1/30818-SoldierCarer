extends NotaMenu
## Nota adhesiva que abre una pantalla informativa del menu (CONTROLES,
## CREDITOS). La escena destino se configura con @export desde main_menu.tscn,
## asi que una sola clase sirve para todas las notas de este tipo en vez de un
## script por boton.
##
## Transicion deliberadamente corta (solo se achican las notas, la carpeta no se
## cierra ni se acuesta como en btn_play.gd): estas pantallas son consultas
## rapidas de las que se vuelve al menu, no la entrada a la mision.

@export_file("*.tscn") var escena_destino: String = ""

func _al_seleccionar() -> void:
	if escena_destino.is_empty():
		push_warning("NotaMenu sin escena_destino: %s" % name)
		return
	fijar_colisiones_notas(false)
	var tween := create_tween()
	tween.set_parallel(true)
	ocultar_notas(tween)
	tween.set_parallel(false)
	tween.tween_callback(_cambiar_de_escena)

func _cambiar_de_escena() -> void:
	print("Abriendo pantalla informativa: %s" % escena_destino)
	get_tree().change_scene_to_file(escena_destino)
