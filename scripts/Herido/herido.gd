extends Node3D
## Paciente en un punto de rescate. El tratamiento real via kit medico
## (RF-17..RF-24) vive en SecuenciaTratamiento; este script solo conecta esa
## FSM con la representacion visual y con curado_completo, el flag que
## consume MapaMuneca (S2) para el color del icono en el mapa.
##
## Reemplaza la curacion rudimentaria de la demo S0 (E/T + mirar + zona
## despejada): ahora se trata acercando el kit medico y repitiendo los
## gestos de cada item (kit_medico.gd). El decaimiento de salud por
## temporizador y los estados de urgencia (ESTABLE/CRITICO/AGONIZANTE) son
## responsabilidad de S4 (sistema de heridos); todavia no existen aqui.

signal curado

@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var malla: MeshInstance3D = $Malla

var secuencia: SecuenciaTratamiento
var curado_completo: bool = false

func _ready() -> void:
	add_to_group("heridos")
	secuencia = SecuenciaTratamiento.new()
	add_child(secuencia)
	secuencia.estabilizado.connect(_al_estabilizar)
	_actualizar_etiqueta()

# Llamado por kit_medico.gd cuando un gesto de item se completa cerca de
# este herido. Devuelve exito/fallo para el feedback (RF-24).
func aplicar_tratamiento(tipo: int) -> bool:
	if curado_completo:
		return false
	var exito: bool = secuencia.aplicar(tipo)
	_actualizar_etiqueta()
	return exito

func _al_estabilizar() -> void:
	curado_completo = true
	if malla:
		var material := malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = Color(0.25, 0.8, 0.3)
	_actualizar_etiqueta()
	print("Herido estabilizado.")
	curado.emit()

func _actualizar_etiqueta() -> void:
	if not etiqueta_estado:
		return
	if curado_completo:
		etiqueta_estado.text = "ESTABILIZADO"
		return
	var nombres := {
		SecuenciaTratamiento.Estado.SIN_ATENDER: "SIN ATENDER (vendar)",
		SecuenciaTratamiento.Estado.LIMPIANDO: "LIMPIAR (alcohol)",
		SecuenciaTratamiento.Estado.SUTURANDO: "SUTURAR",
	}
	etiqueta_estado.text = "HERIDO - %s" % nombres.get(secuencia.estado, "?")
