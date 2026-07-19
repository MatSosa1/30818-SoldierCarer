extends "res://scripts/KitMedico/item_medico.gd"
## RF-19: sacar la jeringa y aplicarla en el brazo. Gesto simple: acercar la
## mano al herido y confirmar con el gatillo derecho (kit_medico.gd,
## arbitrado en jugador.gd). No forma parte de la secuencia obligatoria de
## SecuenciaTratamiento: siempre "aplica". Reduccion real del tiempo de
## estabilizacion pendiente de S4 (todavia no hay temporizador de herido).

func requiere_confirmacion_manual() -> bool:
	return true
