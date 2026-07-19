extends Node3D
class_name Herido
## Paciente en un punto de rescate fijo (RF-11). Su salud decae por
## temporizador interno (RF-12): ESTABLE -> CRITICO -> AGONIZANTE -> MUERTO,
## comunicado por color semaforico en el foco de emergencia y en MapaMuneca
## (RF-13). En paralelo, el tratamiento real via kit medico (RF-17..RF-24,
## S3) puede estabilizarlo en cualquier momento antes de MUERTO; la
## secuencia de pasos vive en SecuenciaTratamiento (una instancia por
## herido), independiente del temporizador de salud.
##
## Los tiempos de decaimiento son @export para balanceo (RNF-12, S10/S11).

signal curado # se mantiene por compatibilidad; MapaMuneca lee curado_completo

enum EstadoSalud {ESTABLE, CRITICO, AGONIZANTE, MUERTO, ESTABILIZADO}

@export var duracion_estable: float = 40.0
@export var duracion_critico: float = 30.0
@export var duracion_agonizante: float = 20.0

# Nombre del escenario donde vive este herido (clave que usa GestorEscenarios,
# "E1_Calle"/"E2_Edificio"). MapaMuneca lo usa para saber a que escenario
# activar al teletransportar hacia este herido (S7: ya hay heridos en mas de
# un escenario).
@export var escenario: String = "E1_Calle"

const COLOR_ESTABLE := Color(0.137, 0.545, 0.137) # verde #228B22
const COLOR_CRITICO := Color(0.855, 0.647, 0.125) # amarillo #DAA520
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0) # rojo #CC0000
const COLOR_MUERTO := Color(0.2, 0.2, 0.2)

@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var malla: MeshInstance3D = $Malla
@onready var foco_luz: OmniLight3D = $Foco/Luz
@onready var foco_malla: MeshInstance3D = $Foco/Malla
@onready var sonido_gemido: AudioStreamPlayer3D = $SonidoGemido
@onready var sonido_rescate: AudioStreamPlayer3D = $SonidoRescate

var secuencia: SecuenciaTratamiento
var estado_salud: EstadoSalud = EstadoSalud.ESTABLE
var curado_completo: bool = false # true solo cuando estado_salud == ESTABILIZADO

var _tiempo_restante: float

func _ready() -> void:
	add_to_group("heridos")
	secuencia = SecuenciaTratamiento.new()
	add_child(secuencia)
	secuencia.estabilizado.connect(_al_estabilizar)
	_tiempo_restante = duracion_estable
	_actualizar_visual()

func _process(delta: float) -> void:
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return
	_tiempo_restante -= delta
	if _tiempo_restante <= 0.0:
		_avanzar_estado_salud()
	_actualizar_visual()

# Llamado por kit_medico.gd cuando un gesto de item se completa cerca de
# este herido. Devuelve exito/fallo para el feedback (RF-24). Un herido
# MUERTO o ya ESTABILIZADO no puede tratarse (RF-14).
func aplicar_tratamiento(tipo: int) -> bool:
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return false
	return secuencia.aplicar(tipo)

func _avanzar_estado_salud() -> void:
	match estado_salud:
		EstadoSalud.ESTABLE:
			estado_salud = EstadoSalud.CRITICO
			_tiempo_restante = duracion_critico
			if sonido_gemido:
				sonido_gemido.play()
		EstadoSalud.CRITICO:
			estado_salud = EstadoSalud.AGONIZANTE
			_tiempo_restante = duracion_agonizante
			if sonido_gemido:
				sonido_gemido.play()
		EstadoSalud.AGONIZANTE:
			_morir()

# RF-14: sin estabilizacion a tiempo, el herido muere, deja de poder
# rescatarse y su foco se apaga.
func _morir() -> void:
	estado_salud = EstadoSalud.MUERTO
	if foco_luz:
		foco_luz.visible = false
	if foco_malla:
		foco_malla.visible = false
	if malla:
		var material := malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = COLOR_MUERTO
	_actualizar_etiqueta()
	print("Herido murio sin ser estabilizado a tiempo.")

func _al_estabilizar() -> void:
	estado_salud = EstadoSalud.ESTABILIZADO
	curado_completo = true
	if malla:
		var material := malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = COLOR_ESTABLE
	if sonido_rescate:
		sonido_rescate.play()
	_actualizar_visual()
	print("Herido estabilizado.")
	curado.emit()
	EventBus.herido_estabilizado.emit(self)

func _actualizar_visual() -> void:
	if estado_salud == EstadoSalud.MUERTO:
		return
	var color := _color_actual()
	if foco_luz:
		foco_luz.light_color = color
		# RF-13: parpadeo cuando el herido esta agonizante.
		foco_luz.light_energy = (
			1.0 + sin(Time.get_ticks_msec() / 120.0) * 0.8
			if estado_salud == EstadoSalud.AGONIZANTE
			else 1.5
		)
	if foco_malla:
		var mat := foco_malla.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = color
			mat.emission = color
	_actualizar_etiqueta()

func _color_actual() -> Color:
	match estado_salud:
		EstadoSalud.CRITICO:
			return COLOR_CRITICO
		EstadoSalud.AGONIZANTE:
			return COLOR_AGONIZANTE
		EstadoSalud.ESTABLE, EstadoSalud.ESTABILIZADO:
			return COLOR_ESTABLE
		_:
			return COLOR_ESTABLE

func _actualizar_etiqueta() -> void:
	if not etiqueta_estado:
		return
	if estado_salud == EstadoSalud.MUERTO:
		etiqueta_estado.text = "MUERTO"
		return
	if estado_salud == EstadoSalud.ESTABILIZADO:
		etiqueta_estado.text = "ESTABILIZADO"
		return
	var nombres_salud := {
		EstadoSalud.ESTABLE: "ESTABLE",
		EstadoSalud.CRITICO: "CRITICO",
		EstadoSalud.AGONIZANTE: "AGONIZANTE",
	}
	var nombres_tratamiento := {
		SecuenciaTratamiento.Estado.SIN_ATENDER: "vendar",
		SecuenciaTratamiento.Estado.LIMPIANDO: "alcohol",
		SecuenciaTratamiento.Estado.SUTURANDO: "suturar",
	}
	etiqueta_estado.text = "%s (%ds) - %s" % [
		nombres_salud.get(estado_salud, "?"),
		int(_tiempo_restante),
		nombres_tratamiento.get(secuencia.estado, "?"),
	]
