extends Node3D
class_name KitMedico
## Apertura del kit (RF-17) y aplicacion de items sobre heridos cercanos
## (RF-18..RF-24). Se abre acercando la mano izquierda a la posicion de este
## nodo, que representa la mochila colgada a la altura de la cadera (ver
## Jugador.tscn; posicion distinta del gesto de "levantar mano" que abre
## MapaMuneca, para no disparar ambos a la vez).
##
## Seleccion de item y aplicacion de items de confirmacion manual
## (morfina/analgesicos) comparten el gatillo derecho con el mapa y el arma;
## jugador.gd arbitra el orden llamando a confirmar_seleccion().

@export var radio_apertura: float = 0.15
@export var radio_seleccion: float = 0.05
@export var rango_tratamiento: float = 1.5
@export var escala_hover: float = 1.2

# HUD del kit (RF-36: minimo y discreto). La leyenda ya no enumera los cinco
# items -eso lo dice la etiqueta de cada item, que ademas trae su numero de
# tecla- sino solo las teclas que no se ven en ningun lado. La vista queda
# fija apenas se equipa un item (jugador.gd, para no pelear con el gesto de
# vendas por el mismo mouse), asi que hay que mirar la herida ANTES de elegir
# la herramienta: por eso el estado, sin item en mano, dice que item pide la
# herida apuntada en vez de repetir el menu completo.
const LEYENDA_ESCRITORIO := "[1-5] tomar item · [Q] morfina · [E] cerrar"
const PISTA_SIN_OBJETIVO := "Mira una herida para ver que necesita"

const COLOR_ESTADO_NEUTRO := Color(0.88, 0.92, 1.0)
const COLOR_ESTADO_LISTO := Color(0.35, 0.9, 0.45)
const COLOR_ESTADO_BLOQUEO := Color(1.0, 0.72, 0.2)
const COLOR_ITEM_PEDIDO := Color(0.35, 0.9, 0.45)
const COLOR_ITEM_INACTIVO := Color(0.7, 0.73, 0.78, 0.5)
# Personajes.md SS4: la presencia enemiga bloquea la curacion — la zona debe
# estar razonablemente despejada. Enemigos vivos dentro de este radio (m)
# alrededor del medico impiden los gestos de secuencia (morfina/analgesicos
# se permiten: un pinchazo rapido bajo fuego es plausible y evita softlocks).
@export var radio_zona_hostil: float = 10.0

@onready var mano_izquierda: XRController3D = get_node_or_null("../ManoIzquierda")
@onready var mano_derecha: XRController3D = get_node_or_null("../ManoDerecha")
@onready var camara: Camera3D = get_node_or_null("../Camera3D")
@onready var etiqueta_equipado: Label3D = $EtiquetaEquipado
@onready var etiqueta_feedback: Label3D = $EtiquetaFeedback
@onready var sonido_feedback: AudioStreamPlayer3D = $SonidoFeedback

var item_equipado: ItemMedico = null
var _items: Array[ItemMedico] = []
var _item_hover: ItemMedico = null
var _posicion_original_equipado: Vector3
var _abierto_manual: bool = false
var _herida_activa: Herida = null
var _etiquetas_preparadas: bool = false

func _ready() -> void:
	visible = false
	etiqueta_feedback.visible = false
	for hijo in get_children():
		if hijo is ItemMedico:
			_items.append(hijo)

# Modo escritorio (sin headset): no hay mano que acercar a la mochila, asi
# que la tecla E (jugador.gd) alterna esta bandera en vez del gesto de
# proximidad.
func alternar_manual() -> void:
	_abierto_manual = not _abierto_manual

func _process(delta: float) -> void:
	if not mano_izquierda:
		return
	# El kit permanece abierto mientras haya un item equipado: cerrar la
	# mano izquierda de la mochila no debe interrumpir un tratamiento en
	# curso (los gestos del item se procesan aca).
	if GestorJuego.fase != GestorJuego.Fase.MISION or GestorJuego.en_pausa:
		visible = false # el kit no se abre en el puesto de mando, en pausa ni tras finalizar
		GestorJuego.marcar_tratando(false)
		_marcar_herida_activa(null)
		return
	var modo_escritorio := not get_viewport().use_xr
	if modo_escritorio:
		visible = _abierto_manual or item_equipado != null
	else:
		var cerca: bool = mano_izquierda.position.distance_to(position) <= radio_apertura
		visible = cerca or item_equipado != null
	GestorJuego.marcar_tratando(visible) # RF-42: el tiempo corre mas lento mientras el kit esta en uso
	if not visible:
		_marcar_herida_activa(null)
		return

	# Se calculan una sola vez por frame: los usan el resalte de morfina (VR),
	# la guia de "que item pide esta herida" y el gesto en curso.
	var herido_cercano := _herido_en_rango()
	var herida_objetivo := _herida_objetivo(herido_cercano, modo_escritorio)
	_marcar_herida_activa(herida_objetivo)
	_actualizar_etiquetas_items(herida_objetivo)
	if not modo_escritorio:
		_actualizar_resalte_morfina(herido_cercano)

	if not item_equipado:
		_mostrar_estado(_texto_sin_item(herida_objetivo, modo_escritorio), COLOR_ESTADO_NEUTRO)
		if not modo_escritorio:
			_actualizar_hover()
		return

	# El item equipado se ve EN la mano derecha (confirmacion visual de que
	# esta equipado), no desaparece.
	item_equipado.global_position = mano_derecha.global_position
	if item_equipado.requiere_confirmacion_manual():
		_mostrar_estado(
			"%s lista — confirma junto al herido" % item_equipado.nombre_item, COLOR_ESTADO_LISTO
		)
		return

	# Los gestos se ejecutan sobre una HERIDA concreta del cuerpo, no sobre
	# el herido generico: el medico tiene que trabajar donde esta la lesion.
	if not herido_cercano:
		_mostrar_estado("%s — acercate a un herido" % item_equipado.nombre_item, COLOR_ESTADO_NEUTRO)
		return
	if not herida_objetivo:
		_mostrar_estado("Sin heridas pendientes aqui", COLOR_ESTADO_NEUTRO)
		item_equipado.reiniciar()
		return
	if _hay_enemigos_cerca():
		# RF/diseno "zona despejada": no se puede trabajar bajo fuego; primero
		# defender (o alejarse), despues curar.
		_mostrar_estado("ZONA HOSTIL — neutraliza a los enemigos", COLOR_ESTADO_BLOQUEO)
		item_equipado.reiniciar()
		return
	if herido_cercano.dolor_bloqueante():
		# Con el paciente retorciendose no se puede trabajar: el gesto no
		# avanza hasta controlar el dolor (morfina/analgesicos).
		_mostrar_estado(
			"DOLOR ALTO — [Q] morfina" if modo_escritorio else "DOLOR ALTO — usa la morfina resaltada",
			COLOR_ESTADO_BLOQUEO,
		)
		item_equipado.reiniciar()
		return
	if item_equipado.tipo != herida_objetivo.item_esperado():
		# El nombre y la severidad de la herida ya los muestra su propia
		# etiqueta resaltada: aca solo hace falta que pide y con que tecla.
		_mostrar_estado(
			"Esta herida pide %s" % _descripcion_item_esperado(herida_objetivo), COLOR_ESTADO_BLOQUEO
		)
		item_equipado.reiniciar()
		return
	_mostrar_estado(
		"%s %d%%" % [item_equipado.nombre_item, int(item_equipado.progreso() * 100.0)],
		COLOR_ESTADO_LISTO,
	)
	herida_objetivo.mostrar_progreso_gesto(item_equipado.progreso())
	if item_equipado.procesar_gesto(delta, mano_derecha, herida_objetivo):
		_completar_aplicacion(
			herido_cercano.aplicar_tratamiento_en(herida_objetivo, item_equipado.tipo)
		)

# Herida sobre la que se trabaja: bajo la mira en escritorio, la mas cercana
# a la mano derecha en VR.
func _herida_objetivo(herido: Herido, modo_escritorio: bool) -> Herida:
	if not herido:
		return null
	if modo_escritorio and camara:
		return herido.herida_bajo_mira(camara)
	return herido.herida_mas_cercana(mano_derecha.global_position)

# Solo una herida a la vez muestra su ficha completa (ver herida.gd).
func _marcar_herida_activa(herida: Herida) -> void:
	if herida == _herida_activa:
		return
	if is_instance_valid(_herida_activa):
		_herida_activa.resaltar(false)
	_herida_activa = herida
	if herida:
		herida.resaltar(true)

# Sin item en mano, el estado guia el siguiente paso concreto en vez de
# listar el kit entero.
func _texto_sin_item(herida_objetivo: Herida, modo_escritorio: bool) -> String:
	if herida_objetivo:
		return "Esta herida pide %s" % _descripcion_item_esperado(herida_objetivo)
	if modo_escritorio:
		return "%s\n%s" % [PISTA_SIN_OBJETIVO, LEYENDA_ESCRITORIO]
	return PISTA_SIN_OBJETIVO

# "ALCOHOL [3]" en escritorio (la tecla que lo equipa), solo el nombre en VR.
func _descripcion_item_esperado(herida: Herida) -> String:
	var esperado: int = herida.item_esperado()
	for indice in _items.size():
		if _items[indice].tipo != esperado:
			continue
		if get_viewport().use_xr:
			return _items[indice].nombre_item.to_upper()
		return "%s [%d]" % [_items[indice].nombre_item.to_upper(), indice + 1]
	return herida.nombre_item_esperado().to_upper()

# La etiqueta de cada item lleva su numero de tecla SOLO en escritorio (en VR
# se agarra con la mano, el numero seria ruido). No se puede resolver en
# _ready(): Godot inicializa de abajo hacia arriba, asi que jugador.gd todavia
# no activo use_xr cuando este nodo esta listo — se prepara en el primer frame
# con el kit abierto.
func _preparar_etiquetas_items() -> void:
	if _etiquetas_preparadas:
		return
	_etiquetas_preparadas = true
	var escritorio := not get_viewport().use_xr
	for indice in _items.size():
		var etiqueta: Label3D = _items[indice].get_node_or_null("Etiqueta")
		if not etiqueta:
			continue
		var nombre: String = _items[indice].nombre_item.to_upper()
		etiqueta.text = "%d %s" % [indice + 1, nombre] if escritorio else nombre

func _mostrar_estado(texto: String, color: Color) -> void:
	etiqueta_equipado.text = texto
	etiqueta_equipado.modulate = color

# Guia visual dentro del kit: se resalta en verde el item que pide la herida
# apuntada y se apagan los demas; con un item ya en mano solo queda su
# etiqueta, para que la mochila no compita con la herida por la atencion.
func _actualizar_etiquetas_items(herida_objetivo: Herida) -> void:
	_preparar_etiquetas_items()
	var esperado: int = herida_objetivo.item_esperado() if herida_objetivo else -1
	for item in _items:
		var etiqueta: Label3D = item.get_node_or_null("Etiqueta")
		if not etiqueta:
			continue
		if item_equipado:
			etiqueta.visible = item == item_equipado
			etiqueta.modulate = COLOR_ESTADO_LISTO
			continue
		etiqueta.visible = true
		etiqueta.modulate = COLOR_ITEM_PEDIDO if item.tipo == esperado else COLOR_ITEM_INACTIVO

# Modo escritorio: las teclas 1-5 equipan el item de ese indice en _items
# (mismo orden que KitMedico.tscn: Vendas/Morfina/Alcohol/Suturas/
# Analgesicos, ver LEYENDA_ESCRITORIO) en vez de acercar la mano derecha al
# item y confirmar con el gatillo. Con un item ya equipado no hace nada:
# guardarlo sigue siendo el clic izquierdo (_al_presionar_boton_mano ->
# confirmar_seleccion -> _guardar_item), igual que en VR.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or get_viewport().use_xr or item_equipado:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var tecla := event as InputEventKey
	var indice := tecla.keycode - KEY_1
	if indice >= 0 and indice < _items.size():
		var item := _items[indice]
		_posicion_original_equipado = item.position
		item_equipado = item
		item.reiniciar()

# Resalta el item al alcance de la mano derecha (hover) antes de confirmar
# con el gatillo, con un pulso haptico suave al entrar en rango.
func _actualizar_hover() -> void:
	var candidato := _item_en_rango_seleccion()
	if candidato == _item_hover:
		return
	if is_instance_valid(_item_hover):
		_item_hover.scale = Vector3.ONE
	_item_hover = candidato
	if _item_hover:
		_item_hover.scale = Vector3.ONE * escala_hover
		if mano_derecha:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.05, 0.0)

func _item_en_rango_seleccion() -> ItemMedico:
	if not mano_derecha:
		return null
	var mas_cercano: ItemMedico = null
	var distancia_min := radio_seleccion
	for item in _items:
		var d: float = mano_derecha.global_position.distance_to(item.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = item
	return mas_cercano

func _item_de_tipo(tipo: ItemMedico.TipoItem) -> ItemMedico:
	for item in _items:
		if item.tipo == tipo:
			return item
	return null

# VR, "alivio rapido": si el herido cercano esta bloqueado por dolor, la
# morfina pulsa para que se la ubique de un vistazo en vez de tener que
# leer las 5 etiquetas del kit una por una. No pisa el resalte de hover
# (proximidad de la mano) cuando coinciden: el hover es la senial mas
# inmediata de "esto es lo que vas a agarrar si confirmas ahora".
func _actualizar_resalte_morfina(herido: Herido) -> void:
	var morfina := _item_de_tipo(ItemMedico.TipoItem.MORFINA)
	if not morfina or morfina == _item_hover:
		return
	if herido and herido.dolor_bloqueante():
		morfina.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() / 150.0) * 0.15)
	elif morfina.scale != Vector3.ONE:
		morfina.scale = Vector3.ONE

# "Alivio rapido" de escritorio (tecla Q, jugador.gd): en vez de guardar el
# item actual, elegir morfina con "2" y volver a apuntar/confirmar con
# clic (varios pasos), inyecta la morfina directo en un solo gesto - lo
# que el aviso "DOLOR ALTO" le pide al jugador, sin la friccion normal.
# Si habia otro item equipado se guarda antes (su progreso ya se estaba
# reiniciando cada frame por el bloqueo de dolor, asi que no se pierde
# nada real al soltarlo).
func administrar_morfina_rapida() -> void:
	if GestorJuego.fase != GestorJuego.Fase.MISION or GestorJuego.en_pausa:
		return
	var herido := _herido_en_rango()
	if not herido:
		return
	if item_equipado:
		item_equipado.reiniciar()
		item_equipado.position = _posicion_original_equipado
		item_equipado = null
	_completar_aplicacion(herido.aplicar_tratamiento_en(null, ItemMedico.TipoItem.MORFINA))

# Llamado desde jugador.gd al presionar el gatillo derecho mientras el kit
# esta abierto: sin item equipado, intenta seleccionar uno por proximidad;
# con un item de confirmacion manual equipado, lo aplica si hay un herido
# en rango; con cualquier otro item equipado, LO DEVUELVE al kit. Sin esa
# salida, un item de secuencia quedaba pegado a la mano para siempre cuando
# su gesto no podia completarse (la herida pide otro item, dolor bloqueante,
# sin heridas pendientes) y el tratamiento entero se bloqueaba.
func confirmar_seleccion() -> void:
	if not visible or not mano_derecha:
		return
	if not item_equipado:
		var item := _item_en_rango_seleccion()
		if item:
			if _item_hover == item:
				item.scale = Vector3.ONE
				_item_hover = null
			_posicion_original_equipado = item.position
			item_equipado = item
			item.reiniciar()
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.4, 0.1, 0.0)
		return
	if item_equipado.requiere_confirmacion_manual():
		var herido := _herido_en_rango()
		if herido:
			# Morfina/analgesicos actuan sobre el paciente completo (herida null).
			_completar_aplicacion(herido.aplicar_tratamiento_en(null, item_equipado.tipo))
			return
	# Item de secuencia (o de confirmacion sin herido cerca): guardar.
	_guardar_item()

# Devuelve el item equipado a su lugar del kit sin aplicarlo. Los gestos de
# secuencia no usan el gatillo (circular/inclinacion/grip), asi que el
# gatillo queda libre como "guardar" sin conflicto.
func _guardar_item() -> void:
	if not item_equipado:
		return
	item_equipado.reiniciar()
	item_equipado.position = _posicion_original_equipado
	item_equipado = null
	etiqueta_equipado.text = ""
	if mano_derecha:
		mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.08, 0.0)

func _completar_aplicacion(resultado: Dictionary) -> void:
	var exito: bool = resultado["exito"]
	_dar_feedback(exito, resultado["mensaje"])
	if mano_derecha:
		# Pulso largo y suave en fallo, corto y firme en exito: distinguibles
		# sin mirar (RF-24 en su version haptica).
		if exito:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.6, 0.15, 0.0)
		else:
			mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.4, 0.0)
	if item_equipado:
		item_equipado.reiniciar()
		item_equipado.position = _posicion_original_equipado # vuelve a su lugar del kit
	item_equipado = null

# RF-24: feedback visual + sonoro por gesto, con el mensaje contextual del
# herido (que pide la herida, dolor bloqueante, etc.). El AudioStreamPlayer3D
# queda cableado sin stream (PLACEHOLDER de audio, ver Contexto.md SS6.2);
# .play() es un no-op seguro hasta que se asigne el clip final.
func _dar_feedback(exito: bool, mensaje: String) -> void:
	etiqueta_feedback.text = mensaje
	etiqueta_feedback.modulate = Color(0.2, 0.8, 0.3) if exito else Color(0.9, 0.2, 0.2)
	etiqueta_feedback.visible = true
	if sonido_feedback:
		sonido_feedback.play()
	get_tree().create_timer(1.6).timeout.connect(func(): etiqueta_feedback.visible = false)

# Enemigos activos a menos de radio_zona_hostil del medico. Los NEUTRALIZADO
# quedan invisibles hasta liberarse (enemigo_base.gd), por eso el filtro por
# visible; los enemigos de un escenario congelado quedan a +80 m y no cuentan.
func _hay_enemigos_cerca() -> bool:
	for enemigo: Node3D in get_tree().get_nodes_in_group("enemigos"):
		if not is_instance_valid(enemigo) or not enemigo.visible:
			continue
		if enemigo.global_position.distance_to(global_position) <= radio_zona_hostil:
			return true
	return false

func _herido_en_rango() -> Herido:
	var mas_cercano: Herido = null
	var distancia_min := rango_tratamiento
	for herido: Herido in get_tree().get_nodes_in_group("heridos"):
		if not is_instance_valid(herido):
			continue
		var d: float = mano_derecha.global_position.distance_to(herido.global_position)
		if d <= distancia_min:
			distancia_min = d
			mas_cercano = herido
	return mas_cercano
