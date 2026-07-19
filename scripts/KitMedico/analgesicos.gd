extends "res://scripts/KitMedico/item_medico.gd"
## RF-22: acercar la pastilla al paciente. Uso simple, igual que morfina:
## acercar la mano al herido y confirmar con el gatillo derecho. No forma
## parte de la secuencia obligatoria; alivio real del dolor pendiente de S4
## (todavia no hay un atributo de dolor en el herido).

func requiere_confirmacion_manual() -> bool:
	return true
