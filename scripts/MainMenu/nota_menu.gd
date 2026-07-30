extends Node3D
class_name NotaMenu
## Base de las notas adhesivas del menu principal (JUGAR, CONTROLES, OPCIONES,
## CREDITOS, SALIR): hover con Tween, ocultado/restaurado en bloque y
## descubrimiento de las notas hermanas. Mismo patron base + ganchos que
## enemigo_base.gd (ver CLAUDE.md SS6): cada nota concreta solo implementa
## _al_seleccionar().
##
## Las notas se buscan por el grupo "notas_menu" y no por nombre: cuando
## btn_play/btn_options las listaban a mano (btn_options, btn_exit...), agregar
## una nota nueva la dejaba fuera del ocultado y del apagado de colisiones, que
## es justo lo que causaba el bug de "notas pegadas" ya documentado en
## btn_play.gd (un hover a medio camino sobrescribia el tween de achicado).

const GRUPO := "notas_menu"
const FACTOR_HOVER := 1.08
const DURACION_HOVER := 0.12
const DURACION_OCULTADO := 0.2

var escala_base: Vector3

@onready var area_clic: Area3D = $Area3D

func _ready() -> void:
	escala_base = scale
	area_clic.mouse_entered.connect(_al_entrar_hover)
	area_clic.mouse_exited.connect(_al_salir_hover)

## Gancho virtual: que hace la nota al recibir el clic. Las subclases lo
## sobreescriben (abrir la carpeta, cambiar de escena, cerrar el juego...).
func _al_seleccionar() -> void:
	pass

# Cableado desde main_menu.tscn ([connection] input_event -> este metodo).
func _on_area_3d_input_event(
	_camara: Node, evento: InputEvent, _posicion: Vector3, _normal: Vector3, _indice_forma: int
) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		_al_seleccionar()

func _al_entrar_hover() -> void:
	if area_clic.input_ray_pickable:
		var tween := create_tween()
		tween.tween_property(self, "scale", escala_base * FACTOR_HOVER, DURACION_HOVER)
		tween.set_trans(Tween.TRANS_SINE)

func _al_salir_hover() -> void:
	if area_clic.input_ray_pickable:
		var tween := create_tween()
		tween.tween_property(self, "scale", escala_base, DURACION_HOVER)
		tween.set_trans(Tween.TRANS_SINE)

## Todas las notas del menu, la propia incluida.
func notas_del_menu() -> Array[NotaMenu]:
	var notas: Array[NotaMenu] = []
	for nodo in get_tree().get_nodes_in_group(GRUPO):
		if nodo is NotaMenu:
			notas.append(nodo)
	return notas

## Apaga/enciende el picking de todas las notas a la vez. Hay que hacerlo antes
## de cualquier animacion: mientras las notas se achican, un hover suelto vuelve
## a crear un tween sobre la misma propiedad "scale" y las deja visibles.
func fijar_colisiones_notas(activas: bool) -> void:
	for nota in notas_del_menu():
		if nota.area_clic:
			nota.area_clic.input_ray_pickable = activas

## Achica todas las notas hasta desaparecer, dentro del tween recibido (el
## llamador decide si va en paralelo con el resto de la animacion).
func ocultar_notas(tween: Tween) -> void:
	for nota in notas_del_menu():
		var animacion := tween.tween_property(nota, "scale", Vector3.ZERO, DURACION_OCULTADO)
		animacion.set_trans(Tween.TRANS_SINE)

## Devuelve las notas a su escala original (usado al cerrar un panel y volver
## al menu principal).
func restaurar_notas(tween: Tween, duracion: float) -> void:
	for nota in notas_del_menu():
		var animacion := tween.tween_property(nota, "scale", nota.escala_base, duracion)
		animacion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
