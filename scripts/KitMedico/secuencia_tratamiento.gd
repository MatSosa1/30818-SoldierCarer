extends Node
class_name SecuenciaTratamiento
## FSM de tratamiento de un herido (RF-23, Personajes.md SS2.4):
## SIN_ATENDER -vendas-> LIMPIANDO -alcohol-> SUTURANDO -suturas-> ESTABILIZADO.
## Morfina y analgesicos no forman parte de la secuencia obligatoria: siempre
## "aplican" (S4 les da efecto real sobre el temporizador de decaimiento /
## el dolor, que todavia no existen).

enum Estado {SIN_ATENDER, LIMPIANDO, SUTURANDO, ESTABILIZADO}

signal fallo_orden(estado_actual: Estado)
signal estabilizado

var estado: Estado = Estado.SIN_ATENDER

func aplicar(tipo: ItemMedico.TipoItem) -> bool:
	match tipo:
		ItemMedico.TipoItem.VENDAS:
			return _avanzar(Estado.SIN_ATENDER, Estado.LIMPIANDO)
		ItemMedico.TipoItem.ALCOHOL:
			return _avanzar(Estado.LIMPIANDO, Estado.SUTURANDO)
		ItemMedico.TipoItem.SUTURAS:
			return _avanzar(Estado.SUTURANDO, Estado.ESTABILIZADO)
		ItemMedico.TipoItem.MORFINA, ItemMedico.TipoItem.ANALGESICOS:
			return true
	return false

func _avanzar(desde: Estado, hacia: Estado) -> bool:
	if estado != desde:
		fallo_orden.emit(estado)
		return false
	estado = hacia
	if estado == Estado.ESTABILIZADO:
		estabilizado.emit()
	return true
