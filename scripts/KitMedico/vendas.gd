extends "res://scripts/KitMedico/item_medico.gd"
## RF-18: gesto circular alrededor de la herida (paso base del tratamiento).
## Se acumula el angulo barrido por la mano derecha alrededor del centro de
## la HERIDA concreta (plano horizontal); al superar grados_requeridos en
## cualquier sentido se considera el vendaje aplicado.
##
## Modo escritorio (sin headset, jugador.gd._modo_vr): no hay mano que
## orbite la herida, asi que el gesto se sustituye por "mover el mouse
## mientras el item esta equipado" hasta acumular pixeles_requeridos_mouse
## (aprox. la distancia de un par de vueltas de raton sobre el mousepad).

@export var grados_requeridos: float = 320.0
@export var pixeles_requeridos_mouse: float = 4000.0

var _angulo_acumulado: float = 0.0
var _angulo_anterior: float = 0.0
var _tiene_angulo_anterior: bool = false
var _distancia_acumulada_mouse: float = 0.0

func procesar_gesto(delta: float, mano_derecha: XRController3D, objetivo: Node) -> bool:
	if not get_viewport().use_xr:
		return _procesar_gesto_escritorio(delta)
	var offset: Vector3 = mano_derecha.global_position - objetivo.global_position
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

func _procesar_gesto_escritorio(delta: float) -> bool:
	_distancia_acumulada_mouse += Input.get_last_mouse_velocity().length() * delta
	if _distancia_acumulada_mouse >= pixeles_requeridos_mouse:
		reiniciar()
		return true
	return false

func progreso() -> float:
	if not get_viewport().use_xr:
		return clampf(_distancia_acumulada_mouse / pixeles_requeridos_mouse, 0.0, 1.0)
	return clampf(_angulo_acumulado / deg_to_rad(grados_requeridos), 0.0, 1.0)

func reiniciar() -> void:
	_angulo_acumulado = 0.0
	_tiene_angulo_anterior = false
	_distancia_acumulada_mouse = 0.0
