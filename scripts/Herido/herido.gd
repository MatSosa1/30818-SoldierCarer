extends Node3D
class_name Herido
## Paciente en un punto de rescate fijo (RF-11). Su salud decae por
## temporizador (RF-12): ESTABLE -> CRITICO -> AGONIZANTE -> MUERTO, con
## color semaforico en el foco y en los mapas (RF-13).
##
## Desde el sistema de heridas procedurales, cada herido tiene 2..3 heridas
## generadas al azar (GeneradorHeridas) sobre puntos anatomicos del cuerpo
## ($PuntosDeHerida): tratarlo no es repetir una secuencia fija, sino leer
## cada herida, aplicar SU secuencia de items sobre SU posicion, y manejar
## el dolor: por encima de umbral_dolor_bloqueo el herido se retuerce
## (temblor + gemidos) y no deja trabajar hasta administrar morfina o
## analgesicos. La gravedad total de las heridas acelera el decaimiento, y
## cada herida tratada lo frena. Todas tratadas = ESTABILIZADO.

signal curado # se mantiene por compatibilidad; MapaMuneca lee curado_completo

enum EstadoSalud {ESTABLE, CRITICO, AGONIZANTE, MUERTO, ESTABILIZADO}

@export var duracion_estable: float = 40.0
@export var duracion_critico: float = 30.0
@export var duracion_agonizante: float = 20.0
# Dolor (0..1) a partir del cual el herido se retuerce y bloquea los gestos
# de tratamiento (RF-19/RF-22: morfina y analgesicos dejan de ser opcionales).
@export var umbral_dolor_bloqueo: float = 0.65
# Cuanto alivio pierde por segundo (la morfina "se pasa" con el tiempo).
@export var decaimiento_alivio: float = 0.015
# RF-12/RF-31: ademas de FRENAR el decaimiento (_factor_decaimiento, via la
# gravedad de heridas sin tratar), cada avance real le devuelve tiempo al
# reloj de muerte del estado actual - un respiro concreto en vez de solo
# demorar lo inevitable. tiempo_bonus_por_alivio se escala por la cantidad
# de alivio aplicado (morfina 0.8 > analgesicos 0.4: la mas fuerte da mas
# tiempo, mismo criterio que ya usan para el dolor).
@export var tiempo_bonus_por_paso: float = 6.0
@export var tiempo_bonus_por_alivio: float = 10.0

# Nombre del escenario donde vive este herido (clave que usa GestorEscenarios,
# "E1_Calle"/"E2_Edificio"). MapaMuneca y DirectorDeOleadas lo usan.
@export var escenario: String = "E1_Calle"

const COLOR_ESTABLE := Color(0.137, 0.545, 0.137) # verde #228B22
const COLOR_CRITICO := Color(0.855, 0.647, 0.125) # amarillo #DAA520
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0) # rojo #CC0000
const COLOR_MUERTO := Color(0.2, 0.2, 0.2)

const PESO_SEVERIDAD := {
	Herida.Severidad.LEVE: 1.0,
	Herida.Severidad.MODERADA: 1.5,
	Herida.Severidad.GRAVE: 2.0,
}

@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var cuerpo: Node3D = $Cuerpo
@onready var puntos_de_herida: Node3D = $PuntosDeHerida
@onready var foco_luz: OmniLight3D = $Foco/Luz
@onready var foco_malla: MeshInstance3D = $Foco/Malla
@onready var sonido_gemido: AudioStreamPlayer3D = $SonidoGemido
@onready var sonido_rescate: AudioStreamPlayer3D = $SonidoRescate

var estado_salud: EstadoSalud = EstadoSalud.ESTABLE
var curado_completo: bool = false # true solo cuando estado_salud == ESTABILIZADO
var heridas: Array[Herida] = []

var _tiempo_restante: float
var _alivio: float = 0.0 # aportado por morfina/analgesicos, decae solo
var _tiempo_gemido: float = 3.0
var _posicion_base_cuerpo: Vector3

func _ready() -> void:
	add_to_group("heridos")
	heridas = GeneradorHeridas.generar_para(puntos_de_herida.get_children())
	for herida in heridas:
		herida.paso_completado.connect(_al_progresar_herida)
	# Los materiales del cuerpo son subrecursos compartidos entre instancias
	# de SoldadoHerido: sin duplicarlos, tenir un herido teniria a todos.
	for malla in cuerpo.get_children():
		if malla is MeshInstance3D and malla.get_surface_override_material(0):
			malla.set_surface_override_material(0, malla.get_surface_override_material(0).duplicate())
	_posicion_base_cuerpo = cuerpo.position
	_tiempo_restante = duracion_estable
	_actualizar_visual()
	print("Herido en %s: %d heridas -> %s" % [escenario, heridas.size(), _resumen_heridas()])

func _process(delta: float) -> void:
	# Presion de triaje (Contexto.md pilar 4): el nodo usa PROCESS_MODE_ALWAYS
	# en SoldadoHerido.tscn para seguir procesando aunque su escenario este
	# desactivado — TODOS los heridos se desangran en paralelo, no solo el del
	# escenario visitado. A cambio, el propio herido respeta aqui las fases de
	# la partida: sin decaimiento antes del despliegue, en pausa ni al final.
	if GestorJuego.fase != GestorJuego.Fase.MISION or GestorJuego.en_pausa:
		return
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return
	_alivio = max(_alivio - decaimiento_alivio * delta, 0.0)
	# La gravedad de las heridas sin tratar acelera el decaimiento; tratar
	# heridas lo frena aunque aun no este estabilizado.
	_tiempo_restante -= delta * _factor_decaimiento()
	if _tiempo_restante <= 0.0:
		_avanzar_estado_salud()
	_actualizar_dolor_fisico(delta)
	_actualizar_visual()

# 1.0 sin heridas pendientes; +0.35 por cada punto de gravedad acumulada.
func _factor_decaimiento() -> float:
	var gravedad := 0.0
	for herida in heridas:
		if not herida.tratada:
			gravedad += PESO_SEVERIDAD[herida.severidad] * (1.0 - herida.fraccion_completada() * 0.5)
	return 1.0 + gravedad * 0.35

func dolor_actual() -> float:
	var dolor := 0.0
	for herida in heridas:
		if not herida.tratada:
			dolor = max(dolor, herida.dolor)
	return clampf(dolor - _alivio, 0.0, 1.0)

func dolor_bloqueante() -> bool:
	return dolor_actual() >= umbral_dolor_bloqueo

# Herida sin tratar mas cercana a una posicion global (la mano derecha):
# define sobre CUAL herida se ejecuta el gesto del kit.
func herida_mas_cercana(pos_global: Vector3, radio_maximo: float = 1.5) -> Herida:
	var mas_cercana: Herida = null
	var distancia_min := radio_maximo
	for herida in heridas:
		if herida.tratada:
			continue
		var d := pos_global.distance_to(herida.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercana = herida
	return mas_cercana

# Modo escritorio: sin mano que acercar a una herida puntual, herida_mas_
# cercana() con un punto de mano fantasma fijo (ver kit_medico.gd) siempre
# elegia la geometricamente mas cercana a ESE punto, sin que el jugador
# pudiera elegir cual tratar cuando hay mas de una pendiente (desde que
# el minimo paso a ser 2 heridas por herido, esto era casi siempre). En
# su lugar, se elige la herida mas centrada bajo la mira de la camara
# (mismo punto de referencia que ya usa la pistola para apuntar). Si
# ninguna cae dentro del cono, cae a la mas cercana por distancia para no
# exigir punteria perfecta en heridas casi centradas.
func herida_bajo_mira(camara: Camera3D, angulo_maximo_grados: float = 35.0) -> Herida:
	var adelante: Vector3 = -camara.global_transform.basis.z
	var mejor: Herida = null
	var mejor_angulo := deg_to_rad(angulo_maximo_grados)
	for herida in heridas:
		if herida.tratada:
			continue
		var direccion := herida.global_position - camara.global_position
		if direccion.length_squared() < 0.0001:
			continue
		var angulo := adelante.angle_to(direccion.normalized())
		if angulo <= mejor_angulo:
			mejor_angulo = angulo
			mejor = herida
	if mejor:
		return mejor
	return herida_mas_cercana(camara.global_position)

# Aplica un item del kit. Para morfina/analgesicos la herida puede ser null
# (actuan sobre el paciente completo); el resto exige una herida concreta.
# Devuelve {"exito": bool, "mensaje": String} para el feedback (RF-24).
func aplicar_tratamiento_en(herida: Herida, tipo: int) -> Dictionary:
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return {"exito": false, "mensaje": "Este soldado ya no puede tratarse"}
	match tipo:
		ItemMedico.TipoItem.MORFINA:
			_aplicar_alivio(0.8)
			return {"exito": true, "mensaje": "Morfina administrada: dolor controlado"}
		ItemMedico.TipoItem.ANALGESICOS:
			_aplicar_alivio(0.4)
			return {"exito": true, "mensaje": "Analgesicos administrados"}
	if not herida:
		return {"exito": false, "mensaje": "Acerca la mano a una herida"}
	if dolor_bloqueante():
		return {"exito": false, "mensaje": "Se retuerce de dolor: administra morfina o analgesicos"}
	if not herida.aplicar(tipo):
		return {"exito": false, "mensaje": "La %s pide %s" % [herida.nombre(), herida.nombre_item_esperado()]}
	return {"exito": true, "mensaje": "Paso aplicado a %s" % herida.nombre()}

func _aplicar_alivio(cantidad: float) -> void:
	_alivio = clampf(_alivio + cantidad, 0.0, 1.0)
	_otorgar_tiempo(tiempo_bonus_por_alivio * cantidad)

func _al_progresar_herida(_herida: Herida) -> void:
	_otorgar_tiempo(tiempo_bonus_por_paso)
	# El director de oleadas escala con este avance (curar atrae enemigos).
	EventBus.tratamiento_progresado.emit(self, fraccion_tratamiento())
	if heridas.all(func(h: Herida) -> bool: return h.tratada):
		_al_estabilizar()

# Extiende _tiempo_restante sin pasarse de la duracion total del estado
# actual (no hace que el herido "aguante para siempre" a fuerza de pasos
# chicos, ni lo hace retroceder de CRITICO a ESTABLE - solo compra tiempo
# dentro del estado en el que ya esta).
func _otorgar_tiempo(cantidad: float) -> void:
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return
	_tiempo_restante = minf(_tiempo_restante + cantidad, _duracion_maxima_estado_actual())

func _duracion_maxima_estado_actual() -> float:
	match estado_salud:
		EstadoSalud.CRITICO:
			return duracion_critico
		EstadoSalud.AGONIZANTE:
			return duracion_agonizante
		_:
			return duracion_estable

func fraccion_tratamiento() -> float:
	var total := 0
	var hechos := 0
	for herida in heridas:
		total += herida.pasos.size()
		hechos += herida.paso_actual
	return float(hechos) / float(max(total, 1))

# Dolor fisico visible: temblor del cuerpo y gemidos mas frecuentes cuanto
# mas dolor; con el dolor controlado el cuerpo queda quieto.
func _actualizar_dolor_fisico(delta: float) -> void:
	var dolor := dolor_actual()
	if dolor >= umbral_dolor_bloqueo:
		var t := Time.get_ticks_msec() / 1000.0
		cuerpo.position = _posicion_base_cuerpo + Vector3(
			sin(t * 23.0) * 0.012,
			0.0,
			cos(t * 31.0) * 0.012
		) * dolor
	else:
		cuerpo.position = _posicion_base_cuerpo
	_tiempo_gemido -= delta
	if _tiempo_gemido <= 0.0 and dolor > 0.25:
		_tiempo_gemido = lerpf(7.0, 2.0, dolor)
		if sonido_gemido:
			sonido_gemido.play()

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
	_tenir_cuerpo(COLOR_MUERTO)
	cuerpo.position = _posicion_base_cuerpo
	_actualizar_etiqueta()
	print("Herido murio sin ser estabilizado a tiempo.")
	EventBus.herido_muerto.emit(self)

func _al_estabilizar() -> void:
	estado_salud = EstadoSalud.ESTABILIZADO
	curado_completo = true
	_tenir_cuerpo(COLOR_ESTABLE)
	cuerpo.position = _posicion_base_cuerpo
	if sonido_rescate:
		sonido_rescate.play()
	_actualizar_visual()
	print("Herido estabilizado: %d heridas tratadas." % heridas.size())
	curado.emit()
	EventBus.herido_estabilizado.emit(self)

func _tenir_cuerpo(color: Color) -> void:
	for hijo in cuerpo.get_children():
		if not hijo is MeshInstance3D:
			continue
		var malla := hijo as MeshInstance3D
		var material: Material = malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = material.albedo_color.lerp(color, 0.65)

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
	var pendientes := heridas.filter(func(h: Herida) -> bool: return not h.tratada).size()
	var texto := "%s (%ds) | %d herida%s" % [
		nombres_salud.get(estado_salud, "?"),
		int(_tiempo_restante),
		pendientes,
		"" if pendientes == 1 else "s",
	]
	if dolor_bloqueante():
		texto += " | DOLOR ALTO"
	etiqueta_estado.text = texto

func _resumen_heridas() -> String:
	var nombres: Array[String] = []
	for herida in heridas:
		nombres.append(herida.nombre())
	return ", ".join(nombres)
