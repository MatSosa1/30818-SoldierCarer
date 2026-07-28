extends Node3D
class_name MenuPausa
## Menu de pausa (RF-40): panel con estetica azul electrico. Al abrirse se
## posiciona UNA vez frente a la vista, a distancia de brazo
## (distancia_apertura), y queda anclado ahi - no sigue a la cabeza. Dos
## motivos: (a) un panel pegado a la camara se mueve con cada micro-giro y
## resulta incomodo/mareante en VR; (b) la seleccion es por proximidad de la
## mano derecha + gatillo (mismo patron que MapaMuneca/KitMedico), asi que
## el panel DEBE estar al alcance fisico del brazo (~0.45 m) - el jugador
## esta fijo (RF-03) y no puede caminar hacia el.
##
## Disposicion: mapa tactico a la izquierda (heridos + jugador al centro, con
## el mismo color semaforico que MapaMuneca) y debajo los dos botones de
## teletransporte E1/E2 (RF-08); a la derecha, de arriba a abajo, REANUDAR,
## fundido de teletransporte (RNF-05), volumen general/musica/SFX (RF-38) y
## SALIR - ver _iconos_seleccionables(). Cada fila es un boton con UNA sola
## etiqueta ("NOMBRE · VALOR"): antes eran dos Label3D por fila separadas
## 0.055 m, que se montaban sobre las filas vecinas.
##
## Seleccion (el icono resaltado se confirma con el gatillo/clic, arbitrado
## en jugador.gd):
## - VR: acercar la mano derecha al icono (proximidad, radio_seleccion).
## - Escritorio: el MOUSE. Antes solo se podia ciclar la seleccion con la
##   rueda/Tab y recien despues hacer clic; ahora se apunta directo. El
##   picking es por geometria proyectada a pantalla (_rect_pantalla), no por
##   Area3D: los Area3D de este panel viven pegados a la cabeza del jugador y
##   ya habian roto el raycast del mapa del puesto de mando (ver
##   mapa_despliegue.gd). Rueda y Tab siguen funcionando como respaldo.
##
## Se abre/cierra con el boton de menu de la mano izquierda
## (jugador.gd._al_presionar_boton_mano_izquierda) o con ESC en escritorio.
## Pausa la simulacion via GestorEscenarios.pausar_activo() en vez de
## SceneTree.paused, para no tener que lidiar con el process_mode de los
## XRController3D solo para que este menu siga recibiendo el gatillo mientras
## esta abierto.
##
## PLACEHOLDER: el "fondo desenfocado" del diseno original
## (UI_ART_Design.md SS5.4) se simplifica a un panel oscuro solido, sin blur
## real (PH-016).

@export var radio_seleccion: float = 0.045
@export var distancia_apertura: float = 0.45
@export var escala_hover: float = 1.15
# Margen extra alrededor de la silueta de cada icono al apuntar con el mouse,
# como fraccion de la altura del viewport (no en pixeles fijos: los botones
# ocupan una fraccion constante de la pantalla, asi que un margen absoluto se
# comeria filas enteras en ventanas chicas).
@export var margen_pick_relativo: float = 0.008

const HeridoScript := preload("res://scripts/Herido/herido.gd")
const COLOR_ESTABLE := Color(0.137, 0.545, 0.137)
const COLOR_CRITICO := Color(0.855, 0.647, 0.125)
const COLOR_AGONIZANTE := Color(0.8, 0.0, 0.0)
const COLOR_MUERTO := Color(0.25, 0.25, 0.25)
const ESCALA_MAPA := 0.0028
const RADIO_MAPA := 0.06
const DURACION_AVISO := 2.0
const ESCENARIO_POR_ICONO := {"IconoE1": "E1_Calle", "IconoE2": "E2_Edificio"}

@onready var mano_derecha: XRController3D = get_node_or_null("../ManoDerecha")
@onready var camara: XRCamera3D = get_node_or_null("../Camera3D")
@onready var jugador: Jugador = get_node_or_null("../..")
@onready var icono_reanudar: Node3D = $IconoReanudar
@onready var icono_opciones: Node3D = $IconoOpciones
@onready var icono_volumen_master: Node3D = $IconoVolumenMaster
@onready var icono_volumen_musica: Node3D = $IconoVolumenMusica
@onready var icono_volumen_sfx: Node3D = $IconoVolumenSFX
@onready var icono_salir: Node3D = $IconoSalir
@onready var mapa_tactico: Node3D = $MapaTactico
@onready var icono_e1: MeshInstance3D = $MapaTactico/IconoE1
@onready var icono_e2: MeshInstance3D = $MapaTactico/IconoE2
@onready var etiqueta_aviso: Label3D = $EtiquetaAviso

var _iconos_heridos_mapa: Dictionary = {} # herido -> MeshInstance3D
var _malla_icono_herido := SphereMesh.new()
var _icono_hover: Node3D = null
var _indice_hover_escritorio: int = 0
# El mouse manda mientras se lo mueva; rueda/Tab toman el control hasta el
# siguiente movimiento (asi el teclado no "pelea" con el puntero).
var _usar_mouse: bool = true
var _tiempo_aviso: float = 0.0

func _ready() -> void:
	visible = false
	_malla_icono_herido.radius = 0.004
	_malla_icono_herido.height = 0.008
	etiqueta_aviso.visible = false
	_actualizar_etiquetas_opciones()

func _process(delta: float) -> void:
	if not visible:
		return
	_actualizar_mapa_tactico()
	_actualizar_colores_escenarios()
	_actualizar_hover()
	if _tiempo_aviso > 0.0:
		_tiempo_aviso -= delta
		etiqueta_aviso.visible = _tiempo_aviso > 0.0

func alternar() -> void:
	visible = not visible
	if visible:
		_posicionar_frente_a_la_vista()
	else:
		etiqueta_aviso.visible = false
		_tiempo_aviso = 0.0
	# Escritorio: el menu se apunta con el mouse, asi que hay que liberarlo del
	# MOUSE_MODE_CAPTURED del mouse-look y recapturarlo al cerrar. Se hace aca y
	# no en jugador.gd porque el menu tambien se cierra solo (REANUDAR,
	# teletransporte) y por esa via el cursor quedaba suelto en pleno juego.
	if not get_viewport().use_xr:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	var gestor := get_tree().get_first_node_in_group("gestor_escenarios")
	if gestor:
		gestor.pausar_activo(visible)
	# El reloj de mision vive en GestorJuego (autoload, fuera del contenedor
	# del escenario): hay que congelarlo aparte o la pausa quema tiempo.
	GestorJuego.marcar_pausa(visible)

# Ancla el panel una vez al abrirse: frente a la camara (solo rumbo
# horizontal, sin heredar la inclinacion de la cabeza), a distancia de
# brazo, mirando al jugador.
func _posicionar_frente_a_la_vista() -> void:
	if not camara:
		return
	var adelante: Vector3 = -camara.global_transform.basis.z
	adelante.y = 0.0
	if adelante.length_squared() < 0.0001:
		adelante = Vector3.FORWARD
	adelante = adelante.normalized()
	global_position = camara.global_position + adelante * distancia_apertura
	look_at(camara.global_position, Vector3.UP)
	rotate_object_local(Vector3.UP, PI) # el QuadMesh mira hacia +Z; girarlo hacia el jugador

# Resalta el icono seleccionado (hover): asi el jugador sabe QUE va a
# confirmar antes de apretar el gatillo o el clic. Pulso haptico suave al
# entrar en rango de un icono nuevo.
func _actualizar_hover() -> void:
	var candidato := _icono_en_rango()
	if candidato == _icono_hover:
		return
	if is_instance_valid(_icono_hover):
		_icono_hover.scale = Vector3.ONE
	_icono_hover = candidato
	if _icono_hover:
		_icono_hover.scale = Vector3.ONE * escala_hover
		if mano_derecha:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.05, 0.0)

# Orden de recorrido con rueda/Tab: la columna derecha de arriba a abajo y
# despues los dos destinos del mapa.
func _iconos_seleccionables() -> Array[Node3D]:
	return [
		icono_reanudar,
		icono_opciones,
		icono_volumen_master,
		icono_volumen_musica,
		icono_volumen_sfx,
		icono_salir,
		icono_e1,
		icono_e2,
	]

func _icono_en_rango() -> Node3D:
	if not get_viewport().use_xr:
		return _icono_escritorio()
	if not mano_derecha:
		return null
	var mas_cercano: Node3D = null
	var distancia_min := radio_seleccion
	for icono in _iconos_seleccionables():
		var d: float = mano_derecha.global_position.distance_to(icono.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = icono
	return mas_cercano

func _icono_escritorio() -> Node3D:
	if _usar_mouse:
		return _icono_bajo_mouse()
	var iconos := _iconos_seleccionables()
	_indice_hover_escritorio = clampi(_indice_hover_escritorio, 0, iconos.size() - 1)
	return iconos[_indice_hover_escritorio]

# Icono cuya silueta contiene al puntero. Si se superponen dos, gana el mas
# chico (el de adentro), que es el que el jugador cree estar apuntando.
func _icono_bajo_mouse() -> Node3D:
	if not camara:
		return null
	var puntero := get_viewport().get_mouse_position()
	var elegido: Node3D = null
	var area_minima := INF
	for icono in _iconos_seleccionables():
		var rect := _rect_pantalla(icono)
		if rect.size == Vector2.ZERO or not rect.has_point(puntero):
			continue
		var area := rect.size.x * rect.size.y
		if area < area_minima:
			area_minima = area
			elegido = icono
	return elegido

# Caja de la malla del icono proyectada a coordenadas de pantalla. Rect2()
# vacio = el icono esta detras de la camara o no tiene malla.
func _rect_pantalla(icono: Node3D) -> Rect2:
	var malla := icono as MeshInstance3D
	if not malla or not malla.mesh:
		return Rect2()
	var caja := malla.get_aabb()
	var transformacion := malla.global_transform
	var margen: float = get_viewport().get_visible_rect().size.y * margen_pick_relativo
	var rect := Rect2()
	for indice in 8:
		var punto: Vector3 = transformacion * caja.get_endpoint(indice)
		if camara.is_position_behind(punto):
			return Rect2()
		var proyectado := camara.unproject_position(punto)
		rect = Rect2(proyectado, Vector2.ZERO) if indice == 0 else rect.expand(proyectado)
	return rect.grow(margen)

# Modo escritorio: el mouse apunta directo (ver _icono_bajo_mouse); la rueda
# y Tab/Shift+Tab siguen disponibles como respaldo -util sin mouse fino- y
# toman el control del resaltado hasta que se vuelva a mover el puntero. El
# clic izquierdo confirma (jugador.gd -> confirmar_seleccion, sin cambios).
func _unhandled_input(event: InputEvent) -> void:
	if not visible or get_viewport().use_xr:
		return
	if event is InputEventMouseMotion:
		_usar_mouse = true
		return
	var total := _iconos_seleccionables().size()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_ciclar_hover(-1, total)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_ciclar_hover(1, total)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_ciclar_hover(-1 if event.shift_pressed else 1, total)

func _ciclar_hover(paso: int, total: int) -> void:
	# Al pasar del mouse al teclado se arranca desde lo que estaba resaltado,
	# no desde el indice viejo: si no, el primer giro de rueda "saltaba".
	if _usar_mouse:
		var actual := _iconos_seleccionables().find(_icono_hover)
		if actual >= 0:
			_indice_hover_escritorio = actual
		_usar_mouse = false
	_indice_hover_escritorio = wrapi(_indice_hover_escritorio + paso, 0, total)

# Llamado desde jugador.gd al presionar el gatillo derecho (o el clic
# izquierdo en escritorio) mientras el menu esta abierto.
func confirmar_seleccion() -> void:
	if not visible:
		return
	var icono := _icono_en_rango()
	if not icono:
		return
	if mano_derecha:
		mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
	if icono == icono_reanudar:
		alternar()
	elif icono == icono_opciones:
		# RF-38 Accesibilidad: intensidad del fundido de teletransporte
		# (RNF-05). Graficos/Controles siguen sin sistema que configurar
		# (ver Elementos_Faltantes).
		GestorOpciones.ciclar_intensidad_teletransporte()
		_actualizar_etiquetas_opciones()
	elif icono == icono_volumen_master:
		GestorOpciones.ciclar_volumen_master()
		_actualizar_etiquetas_opciones()
	elif icono == icono_volumen_musica:
		GestorOpciones.ciclar_volumen_musica()
		_actualizar_etiquetas_opciones()
	elif icono == icono_volumen_sfx:
		GestorOpciones.ciclar_volumen_sfx()
		_actualizar_etiquetas_opciones()
	elif icono == icono_e1 or icono == icono_e2:
		_teletransportar(ESCENARIO_POR_ICONO[String(icono.name)])
	elif icono == icono_salir:
		# RNF-03: fundido a negro antes de volver al menu (en vez de un
		# corte duro de escena).
		if jugador:
			jugador.fundido_salida("res://views/main_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://views/main_menu.tscn")

# RF-08/RF-09: el mini mapa del menu tambien despliega, sin tener que cerrar
# la pausa y levantar el mapa de muneca. Se cierra el menu ANTES de pedir el
# salto: gestor_escenarios.gd reactiva el contenedor del escenario destino, y
# con la pausa puesta ese contenedor volveria a quedar congelado igual.
func _teletransportar(escenario: String) -> void:
	if GestorJuego.fase != GestorJuego.Fase.MISION:
		_avisar("Despliegate primero desde el puesto de mando")
		return
	if escenario == _escenario_activo():
		_avisar("Ya estas en ese escenario")
		return
	alternar()
	EventBus.solicitar_teletransporte.emit(Vector3.ZERO, escenario)

func _escenario_activo() -> String:
	var gestor := get_tree().get_first_node_in_group("gestor_escenarios")
	return gestor.escenario_activo if gestor else ""

func _avisar(texto: String) -> void:
	etiqueta_aviso.text = texto
	etiqueta_aviso.visible = true
	_tiempo_aviso = DURACION_AVISO

# Una sola etiqueta por fila ("NOMBRE · VALOR"): la fila entera es el boton,
# asi que el valor no necesita su propio Label3D debajo.
func _actualizar_etiquetas_opciones() -> void:
	_fijar_texto(icono_opciones, "FUNDIDO · %s" % GestorOpciones.nombre_intensidad_actual())
	_fijar_texto(icono_volumen_master, "GENERAL · %s" % GestorOpciones.porcentaje_volumen_master())
	_fijar_texto(icono_volumen_musica, "MUSICA · %s" % GestorOpciones.porcentaje_volumen_musica())
	_fijar_texto(icono_volumen_sfx, "EFECTOS · %s" % GestorOpciones.porcentaje_volumen_sfx())

func _fijar_texto(icono: Node3D, texto: String) -> void:
	var etiqueta: Label3D = icono.get_node_or_null("Etiqueta")
	if etiqueta:
		etiqueta.text = texto

# Los dos destinos toman el color del peor herido pendiente de su escenario
# (mismo criterio que mapa_despliegue.gd): la decision de a donde saltar es
# informada. El escenario en el que ya esta el jugador queda apagado.
func _actualizar_colores_escenarios() -> void:
	var activo := _escenario_activo()
	for icono: MeshInstance3D in [icono_e1, icono_e2]:
		var material := icono.get_surface_override_material(0) as StandardMaterial3D
		if not material:
			continue
		var escenario: String = ESCENARIO_POR_ICONO[String(icono.name)]
		var color := _color_heridos_de(escenario)
		if escenario == activo:
			color = color.darkened(0.55)
		material.albedo_color = color

func _color_heridos_de(escenario: String) -> Color:
	var peor := -1
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido) or herido.escenario != escenario:
			continue
		if herido.curado_completo:
			continue
		peor = max(peor, herido.estado_salud)
	match peor:
		HeridoScript.EstadoSalud.CRITICO:
			return COLOR_CRITICO
		HeridoScript.EstadoSalud.AGONIZANTE:
			return COLOR_AGONIZANTE
		HeridoScript.EstadoSalud.MUERTO, -1: # sin heridos pendientes
			return COLOR_MUERTO
		_:
			return COLOR_ESTABLE

# Mini mapa 2D (RF-40) proyectado sobre el plano del panel: X del mundo -> X
# local; -Z del mundo (adelante del jugador) -> Y local (arriba del panel).
func _actualizar_mapa_tactico() -> void:
	var nodo_jugador := get_tree().get_first_node_in_group("jugador")
	if not nodo_jugador:
		return
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido):
			continue
		var icono: MeshInstance3D = _iconos_heridos_mapa.get(herido)
		if not icono:
			icono = MeshInstance3D.new()
			icono.mesh = _malla_icono_herido
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			icono.material_override = material
			mapa_tactico.add_child(icono)
			_iconos_heridos_mapa[herido] = icono

		if herido.estado_salud == HeridoScript.EstadoSalud.MUERTO:
			icono.visible = false
			continue
		icono.visible = true
		var color := COLOR_ESTABLE
		if herido.estado_salud == HeridoScript.EstadoSalud.CRITICO:
			color = COLOR_CRITICO
		elif herido.estado_salud == HeridoScript.EstadoSalud.AGONIZANTE:
			color = COLOR_AGONIZANTE
		(icono.material_override as StandardMaterial3D).albedo_color = color

		var offset: Vector3 = herido.global_position - nodo_jugador.global_position
		var x: float = clamp(offset.x * ESCALA_MAPA, -RADIO_MAPA, RADIO_MAPA)
		var y: float = clamp(-offset.z * ESCALA_MAPA, -RADIO_MAPA, RADIO_MAPA)
		icono.position = Vector3(x, y, 0.002)
