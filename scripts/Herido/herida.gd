extends Node3D
class_name Herida
## Una herida individual sobre el cuerpo de un soldado (RF-18..RF-24).
## Sustituye a la secuencia fija unica: cada herido tiene 2..3 heridas
## procedurales (GeneradorHeridas) con tipo, severidad, dolor y SU PROPIA
## secuencia de pasos del kit medico, y el tratamiento se realiza sobre la
## herida concreta (los gestos se ejecutan en su posicion en el cuerpo).
##
## PLACEHOLDER: la marca visual es una primitiva emisiva coloreada por tipo
## (PH-021); el arte final seran decals/texturas de herida sobre el modelo.

signal paso_completado(herida: Herida)
signal completada(herida: Herida)

enum Tipo {LACERACION, HEMORRAGIA, QUEMADURA}
enum Severidad {LEVE, MODERADA, GRAVE}

const NOMBRES_TIPO := {
	Tipo.LACERACION: "LACERACION",
	Tipo.HEMORRAGIA: "HEMORRAGIA",
	Tipo.QUEMADURA: "QUEMADURA",
}
const NOMBRES_SEVERIDAD := {
	Severidad.LEVE: "LEVE",
	Severidad.MODERADA: "MODERADA",
	Severidad.GRAVE: "GRAVE",
}
const NOMBRES_ITEM := {
	ItemMedico.TipoItem.VENDAS: "vendas",
	ItemMedico.TipoItem.MORFINA: "morfina",
	ItemMedico.TipoItem.ALCOHOL: "alcohol",
	ItemMedico.TipoItem.SUTURAS: "suturas",
	ItemMedico.TipoItem.ANALGESICOS: "analgesicos",
}

const COLOR_LACERACION := Color(0.55, 0.08, 0.08)
const COLOR_HEMORRAGIA := Color(0.85, 0.05, 0.05)
const COLOR_QUEMADURA := Color(0.25, 0.12, 0.06)
const COLOR_TRATADA := Color(0.2, 0.45, 0.2)

var tipo: Tipo = Tipo.LACERACION
var severidad: Severidad = Severidad.LEVE
# Dolor que esta herida aporta al herido (0..1). Baja al tratarla.
var dolor: float = 0.3
# Secuencia de items del kit que ESTA herida requiere, en orden.
var pasos: Array[ItemMedico.TipoItem] = []
var paso_actual: int = 0
var tratada: bool = false

var _marca: MeshInstance3D
var _material: StandardMaterial3D
var _etiqueta: Label3D

# La marca y la etiqueta se construyen por codigo: la herida es procedural,
# no hay dos escenas iguales que justifiquen un .tscn propio.
func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	var color := _color_tipo()
	_material.albedo_color = color
	_material.emission = color

	var malla := SphereMesh.new()
	var radio := 0.045 + 0.02 * severidad # mas grave = marca mas grande
	malla.radius = radio
	malla.height = radio * 0.5
	_marca = MeshInstance3D.new()
	_marca.mesh = malla
	_marca.material_override = _material
	add_child(_marca)

	_etiqueta = Label3D.new()
	_etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiqueta.no_depth_test = true
	_etiqueta.pixel_size = 0.0025
	_etiqueta.font_size = 28
	_etiqueta.outline_size = 6
	_etiqueta.position = Vector3(0, 0.14, 0)
	add_child(_etiqueta)
	_actualizar_etiqueta()

func _process(_delta: float) -> void:
	# La hemorragia pulsa mientras no este tratada: urgencia legible de lejos.
	if tratada or tipo != Tipo.HEMORRAGIA:
		return
	_material.emission_energy_multiplier = 1.2 + sin(Time.get_ticks_msec() / 150.0) * 0.8

func item_esperado() -> int:
	if tratada:
		return -1
	return pasos[paso_actual]

func nombre_item_esperado() -> String:
	return NOMBRES_ITEM.get(item_esperado(), "?")

func nombre() -> String:
	return "%s %s" % [NOMBRES_TIPO[tipo], NOMBRES_SEVERIDAD[severidad]]

# Aplica un item sobre esta herida. Devuelve true si era el paso esperado.
func aplicar(tipo_item: ItemMedico.TipoItem) -> bool:
	if tratada or tipo_item != pasos[paso_actual]:
		return false
	paso_actual += 1
	# Completar ANTES de emitir paso_completado: el herido decide si quedo
	# estabilizado en su manejador, y necesita ver tratada=true en el ultimo paso.
	if paso_actual >= pasos.size():
		_completar()
	else:
		dolor = max(dolor - 0.1, 0.05) # cada paso bien hecho alivia un poco
	_actualizar_etiqueta()
	paso_completado.emit(self)
	return true

func fraccion_completada() -> float:
	if pasos.is_empty():
		return 1.0
	return float(paso_actual) / float(pasos.size())

# Llamado por kit_medico.gd para reflejar el avance del gesto en curso.
func mostrar_progreso_gesto(fraccion: float) -> void:
	if tratada:
		return
	_actualizar_etiqueta(fraccion)

func _completar() -> void:
	tratada = true
	dolor = 0.0
	_material.albedo_color = COLOR_TRATADA
	_material.emission = COLOR_TRATADA
	_material.emission_energy_multiplier = 0.6
	completada.emit(self)

func _color_tipo() -> Color:
	match tipo:
		Tipo.HEMORRAGIA:
			return COLOR_HEMORRAGIA
		Tipo.QUEMADURA:
			return COLOR_QUEMADURA
		_:
			return COLOR_LACERACION

func _actualizar_etiqueta(fraccion_gesto: float = -1.0) -> void:
	if not _etiqueta:
		return
	if tratada:
		_etiqueta.text = "%s\nTRATADA" % nombre()
		_etiqueta.modulate = Color(0.5, 0.9, 0.5)
		return
	var linea_paso := "> %s (%d/%d)" % [nombre_item_esperado(), paso_actual + 1, pasos.size()]
	if fraccion_gesto >= 0.0:
		linea_paso += " %d%%" % int(fraccion_gesto * 100.0)
	_etiqueta.text = "%s\n%s" % [nombre(), linea_paso]
	_etiqueta.modulate = Color.WHITE
