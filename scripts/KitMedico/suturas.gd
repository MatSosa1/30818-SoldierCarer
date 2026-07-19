extends "res://scripts/KitMedico/item_medico.gd"
## RF-21: gesto de presion con la grapadora (cierra heridas profundas; el
## mas tecnico del kit). Cada ciclo apretar-y-soltar el grip cuenta como una
## grapa; se requieren grapas_requeridas seguidas para completar el gesto,
## exigiendo repeticion en vez de un solo apreton.

@export var grapas_requeridas: int = 3
@export var umbral_presion: float = 0.8
@export var umbral_liberado: float = 0.3

var _grapas_aplicadas: int = 0
var _presionado: bool = false

func procesar_gesto(_delta: float, mano_derecha: XRController3D, _herido: Node) -> bool:
	var presion := mano_derecha.get_float("grip")
	if not _presionado and presion >= umbral_presion:
		_presionado = true
		_grapas_aplicadas += 1
	elif _presionado and presion <= umbral_liberado:
		_presionado = false
	if _grapas_aplicadas >= grapas_requeridas:
		reiniciar()
		return true
	return false

func reiniciar() -> void:
	_grapas_aplicadas = 0
	_presionado = false
