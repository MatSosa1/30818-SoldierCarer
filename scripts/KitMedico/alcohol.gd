extends "res://scripts/KitMedico/item_medico.gd"
## RF-20: gesto de inclinacion para volcar el frasco sobre la herida
## (desinfecta; requerido antes de suturar). Se considera aplicado cuando el
## eje "arriba" de la mano derecha permanece inclinado mas de umbral_grados
## respecto al mundo-arriba durante duracion_sostenida segundos seguidos
## (evita que una rotacion breve/accidental cuente como gesto).

@export var umbral_grados: float = 100.0
@export var duracion_sostenida: float = 0.4

var _tiempo_inclinado: float = 0.0

func procesar_gesto(delta: float, mano_derecha: XRController3D, _herido: Node) -> bool:
	var arriba: Vector3 = mano_derecha.global_transform.basis.y
	var angulo := rad_to_deg(arriba.angle_to(Vector3.UP))
	_tiempo_inclinado = _tiempo_inclinado + delta if angulo >= umbral_grados else 0.0
	if _tiempo_inclinado >= duracion_sostenida:
		reiniciar()
		return true
	return false

func reiniciar() -> void:
	_tiempo_inclinado = 0.0
