extends Node3D
class_name ItemMedico
## Base de los items del kit medico (RF-18..RF-22). Cada item concreto
## (vendas.gd, morfina.gd, alcohol.gd, suturas.gd, analgesicos.gd)
## sobreescribe procesar_gesto() con su patron propio; devuelve true la
## unica vez que el gesto se completa. Los items de "confirmacion manual"
## (morfina, analgesicos) no detectan movimiento: esperan el gatillo
## derecho, arbitrado en jugador.gd/kit_medico.gd.

enum TipoItem {VENDAS, MORFINA, ALCOHOL, SUTURAS, ANALGESICOS}

@export var tipo: TipoItem
@export var nombre_item: String = "Item"

func requiere_confirmacion_manual() -> bool:
	return false

func procesar_gesto(_delta: float, _mano_derecha: XRController3D, _herido: Node) -> bool:
	return false

func reiniciar() -> void:
	pass
