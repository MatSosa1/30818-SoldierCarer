extends "res://scripts/KitMedico/item_medico.gd"
## RF-21: gesto de presion con la grapadora (cierra heridas profundas; el
## mas tecnico del kit). Cada ciclo apretar-y-soltar el grip cuenta como una
## grapa; se requieren grapas_requeridas seguidas para completar el gesto,
## exigiendo repeticion en vez de un solo apreton.
##
## Modo escritorio (sin headset): sin grip analogico, cada clic derecho
## (abajo->arriba) cuenta como una grapa, mismo umbral grapas_requeridas.

@export var grapas_requeridas: int = 3
@export var umbral_presion: float = 0.8
@export var umbral_liberado: float = 0.3

var _grapas_aplicadas: int = 0
var _presionado: bool = false

func procesar_gesto(_delta: float, mano_derecha: XRController3D, _objetivo: Node) -> bool:
	var presionado_ahora: bool
	if not get_viewport().use_xr:
		presionado_ahora = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	else:
		var presion := mano_derecha.get_float("grip")
		if _presionado:
			presionado_ahora = presion > umbral_liberado
		else:
			presionado_ahora = presion >= umbral_presion
	if presionado_ahora and not _presionado:
		_presionado = true
		_grapas_aplicadas += 1
	elif not presionado_ahora:
		_presionado = false
	if _grapas_aplicadas >= grapas_requeridas:
		reiniciar()
		return true
	return false

func progreso() -> float:
	return clampf(float(_grapas_aplicadas) / float(grapas_requeridas), 0.0, 1.0)

func reiniciar() -> void:
	_grapas_aplicadas = 0
	_presionado = false
