extends "res://scripts/KitMedico/item_medico.gd"
## RF-18: gesto circular alrededor de la herida (paso base del tratamiento).
## Se acumula el angulo barrido por la mano derecha alrededor del centro del
## herido (plano horizontal); al superar grados_requeridos en cualquier
## sentido se considera el vendaje aplicado.

@export var grados_requeridos: float = 320.0

var _angulo_acumulado: float = 0.0
var _angulo_anterior: float = 0.0
var _tiene_angulo_anterior: bool = false

func procesar_gesto(_delta: float, mano_derecha: XRController3D, herido: Node) -> bool:
	var offset: Vector3 = mano_derecha.global_position - herido.global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		return false
	var angulo := atan2(offset.z, offset.x)
	if _tiene_angulo_anterior:
		_angulo_acumulado += abs(wrapf(angulo - _angulo_anterior, -PI, PI))
	_angulo_anterior = angulo
	_tiene_angulo_anterior = true
	if _angulo_acumulado >= deg_to_rad(grados_requeridos):
		reiniciar()
		return true
	return false

func reiniciar() -> void:
	_angulo_acumulado = 0.0
	_tiene_angulo_anterior = false
