extends "res://scripts/KitMedico/item_medico.gd"
## RF-20: gesto de inclinacion para volcar el frasco sobre la herida
## (desinfecta; requerido antes de suturar). Se considera aplicado cuando el
## eje "arriba" de la mano derecha permanece inclinado mas de umbral_grados
## respecto al mundo-arriba durante duracion_sostenida segundos seguidos
## (evita que una rotacion breve/accidental cuente como gesto).
##
## Modo escritorio (sin headset): no hay muneca que inclinar, asi que se
## sostiene el clic derecho durante duracion_sostenida segundos (el clic
## izquierdo ya es "guardar item", ver kit_medico.gd/jugador.gd).

@export var umbral_grados: float = 100.0
@export var duracion_sostenida: float = 0.4

var _tiempo_inclinado: float = 0.0

func procesar_gesto(delta: float, mano_derecha: XRController3D, _objetivo: Node) -> bool:
	var sostenido: bool
	if not get_viewport().use_xr:
		sostenido = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	else:
		var arriba: Vector3 = mano_derecha.global_transform.basis.y
		sostenido = rad_to_deg(arriba.angle_to(Vector3.UP)) >= umbral_grados
	_tiempo_inclinado = _tiempo_inclinado + delta if sostenido else 0.0
	if _tiempo_inclinado >= duracion_sostenida:
		reiniciar()
		return true
	return false

func progreso() -> float:
	return clampf(_tiempo_inclinado / duracion_sostenida, 0.0, 1.0)

func reiniciar() -> void:
	_tiempo_inclinado = 0.0
