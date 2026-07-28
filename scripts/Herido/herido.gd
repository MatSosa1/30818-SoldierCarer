extends Node3D
class_name Herido
## Paciente en un punto de rescate fijo (RF-11). Su salud decae como un
## MEDIDOR DE VITALIDAD 0..100 (RF-12): ESTABLE -> CRITICO -> AGONIZANTE ->
## MUERTO segun el porcentaje restante, con color semaforico en el foco, en
## la barra sobre el cuerpo y en los mapas (RF-13).
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

# Vitalidad como porcentaje (0..100) en vez de la vieja cadena de tres
# temporizadores en segundos (duracion_estable/critico/agonizante = 135 s
# totales, demasiado poco para tratar 2-3 heridas con el kit). Ahora cada
# punto de vitalidad cuesta segundos_por_punto segundos de juego: con los
# valores por defecto, un herido sin heridas graves tarda 100 * 3 = 300 s en
# morir, y la gravedad solo acelera esa caida (ver _factor_decaimiento).
@export var vitalidad_maxima: float = 100.0
@export var segundos_por_punto: float = 3.0
# Umbrales (en puntos de vitalidad) de los estados semaforicos (RF-13).
@export var umbral_critico: float = 66.0
@export var umbral_agonizante: float = 33.0
# Cuanto acelera el decaimiento cada punto de gravedad de las heridas sin
# tratar (ver _factor_decaimiento). 0 = la gravedad no influye.
@export var factor_gravedad: float = 0.15
# Dolor (0..1) a partir del cual el herido se retuerce y bloquea los gestos
# de tratamiento (RF-19/RF-22: morfina y analgesicos dejan de ser opcionales).
@export var umbral_dolor_bloqueo: float = 0.65
# Cuanto alivio pierde por segundo (la morfina "se pasa" con el tiempo).
@export var decaimiento_alivio: float = 0.015
# RF-12/RF-31: ademas de FRENAR el decaimiento (_factor_decaimiento, via la
# gravedad de heridas sin tratar), cada avance real le DEVUELVE puntos de
# vitalidad - un respiro concreto en vez de solo demorar lo inevitable, y
# visible al instante en la barra. bonus_vitalidad_por_alivio se escala por
# la cantidad de alivio aplicado (morfina 0.8 > analgesicos 0.4: la mas
# fuerte da mas margen, mismo criterio que ya usan para el dolor).
@export var bonus_vitalidad_por_paso: float = 5.0
@export var bonus_vitalidad_por_alivio: float = 8.0

# Nombre del escenario donde vive este herido (clave que usa GestorEscenarios,
# "E1_Calle"/"E2_Edificio"). MapaMuneca y DirectorDeOleadas lo usan.
@export var escenario: String = "E1_Calle"

const COLOR_ESTABLE := Color(0.137, 0.545, 0.137) # verde #228B22
const COLOR_CRITICO := Color(0.855, 0.647, 0.125) # amarillo #DAA520
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0) # rojo #CC0000
const COLOR_MUERTO := Color(0.2, 0.2, 0.2)

# Barra de vitalidad flotante sobre el cuerpo (medidor de RF-12/RF-13). Se
# construye por codigo, como las marcas de Herida: es puro HUD diegetico de
# primitivas, no hay asset que sustituir.
const ANCHO_BARRA := 0.4
const ALTO_BARRA := 0.05
const ALTURA_BARRA := 0.88

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
var vitalidad: float # 0..vitalidad_maxima; el medidor que reemplaza al reloj

var _alivio: float = 0.0 # aportado por morfina/analgesicos, decae solo
var _tiempo_gemido: float = 3.0
var _posicion_base_cuerpo: Vector3
var _barra_fondo: MeshInstance3D
var _barra_relleno: MeshInstance3D

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
	vitalidad = vitalidad_maxima
	_construir_barra_vitalidad()
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
	vitalidad = max(vitalidad - (delta / segundos_por_punto) * _factor_decaimiento(), 0.0)
	_actualizar_estado_por_vitalidad()
	if estado_salud == EstadoSalud.MUERTO:
		return
	_actualizar_dolor_fisico(delta)
	_actualizar_visual()

# 1.0 sin heridas pendientes; +factor_gravedad por cada punto de gravedad
# acumulada (una herida GRAVE sin tocar pesa 2.0, una LEVE 1.0).
func _factor_decaimiento() -> float:
	var gravedad := 0.0
	for herida in heridas:
		if not herida.tratada:
			gravedad += PESO_SEVERIDAD[herida.severidad] * (1.0 - herida.fraccion_completada() * 0.5)
	return 1.0 + gravedad * factor_gravedad

func fraccion_vitalidad() -> float:
	return clampf(vitalidad / max(vitalidad_maxima, 0.001), 0.0, 1.0)

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
	_otorgar_vitalidad(bonus_vitalidad_por_alivio * cantidad)

func _al_progresar_herida(_herida: Herida) -> void:
	_otorgar_vitalidad(bonus_vitalidad_por_paso)
	# El director de oleadas escala con este avance (curar atrae enemigos).
	EventBus.tratamiento_progresado.emit(self, fraccion_tratamiento())
	if heridas.all(func(h: Herida) -> bool: return h.tratada):
		_al_estabilizar()

# Devuelve puntos de vitalidad al medidor. A diferencia del viejo reloj por
# estado (que solo podia comprar tiempo DENTRO del estado actual), aca un
# tratamiento sostenido puede sacar al herido de AGONIZANTE y devolverlo a
# CRITICO: la mejora es visible en la barra y en el color semaforico, que es
# justamente la lectura que el medidor tiene que dar.
func _otorgar_vitalidad(cantidad: float) -> void:
	if estado_salud == EstadoSalud.MUERTO or estado_salud == EstadoSalud.ESTABILIZADO:
		return
	vitalidad = minf(vitalidad + cantidad, vitalidad_maxima)
	_actualizar_estado_por_vitalidad()
	_actualizar_visual()

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

# El estado semaforico es ahora una LECTURA del medidor, no una maquina de
# estados con reloj propio: se recalcula desde la vitalidad cada vez que
# cambia (decaimiento o tratamiento). Solo el empeoramiento suena, para que
# el gemido siga marcando "se te va" y no premie con ruido una mejora.
func _actualizar_estado_por_vitalidad() -> void:
	var nuevo := _estado_por_vitalidad()
	if nuevo == estado_salud:
		return
	var empeora := nuevo > estado_salud
	estado_salud = nuevo
	if nuevo == EstadoSalud.MUERTO:
		_morir()
		return
	if empeora and sonido_gemido:
		sonido_gemido.play()

func _estado_por_vitalidad() -> EstadoSalud:
	if vitalidad <= 0.0:
		return EstadoSalud.MUERTO
	if vitalidad <= umbral_agonizante:
		return EstadoSalud.AGONIZANTE
	if vitalidad <= umbral_critico:
		return EstadoSalud.CRITICO
	return EstadoSalud.ESTABLE

# RF-14: sin estabilizacion a tiempo, el herido muere, deja de poder
# rescatarse y su foco se apaga.
func _morir() -> void:
	estado_salud = EstadoSalud.MUERTO
	vitalidad = 0.0
	if foco_luz:
		foco_luz.visible = false
	if foco_malla:
		foco_malla.visible = false
	_mostrar_barra(false)
	_tenir_cuerpo(COLOR_MUERTO)
	cuerpo.position = _posicion_base_cuerpo
	_actualizar_etiqueta()
	print("Herido murio sin ser estabilizado a tiempo.")
	EventBus.herido_muerto.emit(self)

func _al_estabilizar() -> void:
	estado_salud = EstadoSalud.ESTABILIZADO
	curado_completo = true
	vitalidad = vitalidad_maxima # el medidor queda lleno: el paciente esta fuera de peligro
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
	_actualizar_barra(color)
	_actualizar_etiqueta()

# Medidor de vitalidad: dos quads billboard (fondo oscuro + relleno del color
# semaforico). El relleno no se ESCALA sino que se redimensiona la malla y se
# corre su center_offset: el offset de la malla si queda en el espacio ya
# rotado por el billboard, asi que la barra crece desde el borde izquierdo
# mirandola desde cualquier angulo (escalar el nodo la desplazaria de costado).
# Las dos usan render_priority negativa para quedar por DEBAJO de las Label3D
# (prioridad 0), que si no tapaban con la barra.
func _construir_barra_vitalidad() -> void:
	_barra_fondo = _nueva_barra(
		Vector2(ANCHO_BARRA + 0.02, ALTO_BARRA + 0.012), Color(0.04, 0.04, 0.05, 0.8), -2
	)
	_barra_relleno = _nueva_barra(Vector2(ANCHO_BARRA, ALTO_BARRA), COLOR_ESTABLE, -1)
	add_child(_barra_fondo)
	add_child(_barra_relleno)

func _nueva_barra(tamano: Vector2, color: Color, prioridad: int) -> MeshInstance3D:
	var malla := QuadMesh.new()
	malla.size = tamano
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.render_priority = prioridad
	material.albedo_color = color
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.material_override = material
	instancia.position = Vector3(0.0, ALTURA_BARRA, 0.0)
	return instancia

func _actualizar_barra(color: Color) -> void:
	if not _barra_relleno:
		return
	var fraccion := fraccion_vitalidad()
	var malla := _barra_relleno.mesh as QuadMesh
	malla.size = Vector2(maxf(ANCHO_BARRA * fraccion, 0.002), ALTO_BARRA)
	malla.center_offset = Vector3(-ANCHO_BARRA * 0.5 + malla.size.x * 0.5, 0.0, 0.0)
	(_barra_relleno.material_override as StandardMaterial3D).albedo_color = color

func _mostrar_barra(visible_barra: bool) -> void:
	for barra: MeshInstance3D in [_barra_fondo, _barra_relleno]:
		if barra:
			barra.visible = visible_barra

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
	# Dos lineas cortas en vez de una larga: estado + medidor arriba, carga de
	# trabajo pendiente abajo (la barra de vitalidad ya da la lectura rapida).
	var texto := "%s %d%%\n%d herida%s" % [
		nombres_salud.get(estado_salud, "?"),
		int(round(vitalidad)),
		pendientes,
		"" if pendientes == 1 else "s",
	]
	if dolor_bloqueante():
		texto += " · DOLOR ALTO"
	etiqueta_estado.text = texto

func _resumen_heridas() -> String:
	var nombres: Array[String] = []
	for herida in heridas:
		nombres.append(herida.nombre())
	return ", ".join(nombres)
