extends "res://scripts/KitMedico/item_medico.gd"
## RF-19: sacar la jeringa y aplicarla en el brazo. Gesto simple: acercar la
## mano al herido y confirmar con el gatillo derecho (kit_medico.gd,
## arbitrado en jugador.gd). No forma parte de las secuencias de herida:
## aplica un alivio fuerte e inmediato del dolor (herido.gd), necesario
## cuando el dolor bloquea el tratamiento.

func requiere_confirmacion_manual() -> bool:
	return true
