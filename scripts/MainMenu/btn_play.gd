extends NotaMenu
## Nota adhesiva JUGAR: cierra la carpeta, la acuesta sobre la mesa y entra a la
## pantalla de estado inicial (RF-39). Hover y ocultado de notas vienen de
## NotaMenu.

# REFERENCIAS DE OBJETOS ANIMADOS
@onready var tapa: MeshInstance3D = $"../folder/Folder_001"
@onready var carpeta_completa: Node3D = $"../folder"

# REFERENCIAS DE OBJETOS A OCULTAR
@onready var paper: MeshInstance3D = $"../folder/Paper"
@onready var paper_001: MeshInstance3D = $"../folder/Paper_001"
@onready var paper_002: MeshInstance3D = $"../folder/Paper_002"
@onready var paper_003: MeshInstance3D = $"../folder/Paper_003"

func _al_seleccionar() -> void:
	comenzar_animacion_menu()

func comenzar_animacion_menu():
	# Se apaga el picking de TODAS las notas, no solo de la propia: mientras se
	# achican (~2s de animacion), si el mouse roza una nota su hover crea otro
	# tween sobre la misma propiedad "scale" y, si termina despues, la deja
	# pegada visible en vez de desaparecer (bug reportado: "se quedan algunos
	# sticky notes, a veces uno o dos").
	fijar_colisiones_notas(false)

	var tween = create_tween()

	# Desaparecemos las sticky notes
	tween.set_parallel(true)
	ocultar_notas(tween)

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
