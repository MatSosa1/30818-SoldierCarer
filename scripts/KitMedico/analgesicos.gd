extends "res://scripts/KitMedico/item_medico.gd"
## RF-22: acercar la pastilla al paciente. Uso simple, igual que morfina:
## acercar la mano al herido y confirmar con el gatillo derecho. No forma
## parte de las secuencias de herida: aplica un alivio moderado del dolor
## (herido.gd), alternativa suave a la morfina.

func requiere_confirmacion_manual() -> bool:
	return true
