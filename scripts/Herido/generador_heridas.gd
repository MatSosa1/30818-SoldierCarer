extends RefCounted
class_name GeneradorHeridas
## Genera el cuadro clinico procedural de un soldado herido (RF-18..RF-23):
## cantidad, tipo, severidad y dolor de cada herida son aleatorios, asi que
## no hay dos heridos iguales y el medico debe LEER al paciente antes de
## actuar, en vez de repetir una secuencia memorizada.
##
## Secuencias por tipo (con los 5 items existentes del kit):
## - LACERACION: alcohol (desinfectar) -> suturas (cerrar) -> vendas (cubrir)
## - HEMORRAGIA: vendas (compresion) -> suturas (cerrar) -> vendas (vendaje);
##   GRAVE agrega alcohol antes de suturar (herida contaminada)
## - QUEMADURA:  alcohol (limpiar) -> vendas (cubrir); nunca se sutura
## Morfina y analgesicos no forman parte de las secuencias: controlan el
## dolor, que por encima del umbral bloquea el tratamiento (herido.gd).

const DOLOR_BASE := {
	Herida.Severidad.LEVE: 0.3,
	Herida.Severidad.MODERADA: 0.55,
	Herida.Severidad.GRAVE: 0.8,
}

static func generar_para(cuerpo_puntos: Array[Node]) -> Array[Herida]:
	var heridas: Array[Herida] = []
	var puntos := cuerpo_puntos.duplicate()
	puntos.shuffle()
	# 1..3 heridas, sesgado hacia 2: un unico paso nunca estabiliza a nadie.
	var cantidad: int = clampi([1, 2, 2, 3].pick_random(), 1, puntos.size())
	for i in cantidad:
		var herida := _generar_una()
		# La herida se cuelga del punto anatomico (pecho, brazo, pierna...):
		# los gestos del kit se ejecutan sobre ESTA posicion del cuerpo.
		puntos[i].add_child(herida)
		heridas.append(herida)
	return heridas

static func _generar_una() -> Herida:
	var herida := Herida.new()
	herida.tipo = [
		Herida.Tipo.LACERACION,
		Herida.Tipo.HEMORRAGIA,
		Herida.Tipo.QUEMADURA,
	].pick_random()
	herida.severidad = [
		Herida.Severidad.LEVE,
		Herida.Severidad.MODERADA,
		Herida.Severidad.MODERADA,
		Herida.Severidad.GRAVE,
	].pick_random()
	herida.dolor = clampf(DOLOR_BASE[herida.severidad] + randf_range(-0.1, 0.1), 0.1, 1.0)
	herida.pasos = _secuencia(herida.tipo, herida.severidad)
	return herida

static func _secuencia(tipo: Herida.Tipo, severidad: Herida.Severidad) -> Array[ItemMedico.TipoItem]:
	match tipo:
		Herida.Tipo.HEMORRAGIA:
			if severidad == Herida.Severidad.GRAVE:
				return [
					ItemMedico.TipoItem.VENDAS,
					ItemMedico.TipoItem.ALCOHOL,
					ItemMedico.TipoItem.SUTURAS,
					ItemMedico.TipoItem.VENDAS,
				]
			return [
				ItemMedico.TipoItem.VENDAS,
				ItemMedico.TipoItem.SUTURAS,
				ItemMedico.TipoItem.VENDAS,
			]
		Herida.Tipo.QUEMADURA:
			return [
				ItemMedico.TipoItem.ALCOHOL,
				ItemMedico.TipoItem.VENDAS,
			]
		_: # LACERACION
			return [
				ItemMedico.TipoItem.ALCOHOL,
				ItemMedico.TipoItem.SUTURAS,
				ItemMedico.TipoItem.VENDAS,
			]
