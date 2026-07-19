extends CharacterBody3D
class_name Jugador
## Rig VR del jugador (OpenXR). Fijo en posicion (RF-03): la unica rotacion de
## "cabeza" viene del tracking real del headset via XRCamera3D, no de script.
## Conserva el contrato de la demo no-VR: senial disparo_realizado(rayo) y
## metodo recibir_dano(), de los que depende la IA de enemigos existente
## (ver Arquitectura.md SS5).

signal disparo_realizado(rayo: RayCast3D)

@export var salud_maxima: float = 100.0
@export var dano_disparo: float = 10.0
@export var umbral_salud_critica: float = 0.3 # RF-46: fraccion de salud_maxima que activa la musica "critico"

@export var trazador_disparo_path: NodePath

@export var mostrar_debug_salud: bool = true # etiqueta 2D solo visible en la ventana espejo de escritorio

@onready var mano_derecha: XRController3D = $XROrigin3D/ManoDerecha
@onready var mano_izquierda: XRController3D = $XROrigin3D/ManoIzquierda
@onready var pistola: Pistola = $XROrigin3D/ManoDerecha/Pistola
@onready var mapa_muneca: MapaMuneca = $XROrigin3D/ManoIzquierda/MapaMuneca
@onready var kit_medico: KitMedico = $XROrigin3D/KitMedico
@onready var menu_pausa: MenuPausa = $XROrigin3D/MenuPausa
@onready var resultados_mision: ResultadosMision = $XROrigin3D/ResultadosMision
# HUD diegetico en 3D (los CanvasLayer no se ven en el headset, ver pantalla_dano.gd)
@onready var pantalla_danio: PantallaDano = $XROrigin3D/Camera3D/VignetteDanio
@onready var desvanecido: MeshInstance3D = $XROrigin3D/Camera3D/Desvanecido3D
# Etiqueta 2D de debug: al vivir en CanvasLayer solo aparece en la ventana
# espejo de escritorio, nunca en el headset - util como consola del encargado.
@onready var etiqueta_salud: Label = $UI/EtiquetaSalud
@onready var trazador_disparo: MeshInstance3D = get_node_or_null(trazador_disparo_path)

var salud: float

func _ready() -> void:
	add_to_group("jugador")
	_inicializar_openxr()
	mano_derecha.button_pressed.connect(_al_presionar_boton_mano)
	mano_izquierda.button_pressed.connect(_al_presionar_boton_mano_izquierda)
	salud = salud_maxima
	etiqueta_salud.visible = mostrar_debug_salud
	_actualizar_etiqueta_salud()
	# En el puesto de mando (fase DESPLIEGUE) suena musica de menu; el combate
	# recien empieza al confirmar el despliegue en el mapa de la ciudad.
	GestorAudio.cambiar_estado(GestorAudio.EstadoMusica.MENU)
	EventBus.mision_desplegada.connect(
		func(_escenario: String): GestorAudio.cambiar_estado(GestorAudio.EstadoMusica.COMBATE)
	)

# RF-01: inicializa OpenXR y activa el viewport en modo XR si detecta headset
# y controladores. Si no hay runtime/headset disponible, el juego sigue
# funcionando sin XR activo (util para revisar la escena en el editor).
func _inicializar_openxr() -> void:
	var interfaz := XRServer.find_interface("OpenXR")
	if interfaz and interfaz.is_initialized():
		get_viewport().use_xr = true
		print("OpenXR inicializado: headset y controladores detectados.")
	else:
		print("OpenXR no disponible: ejecutando sin XR activo (revisa el runtime/headset).")

# El gatillo derecho dispara el arma por defecto. La pantalla de resultados
# (RF-44) tiene la maxima prioridad -si la mision termino, nada mas importa-,
# luego el menu de pausa (RF-40), luego el mapa de muneca (RF-08), luego el
# kit medico (RF-17..RF-24). El mapa y el kit se abren con gestos de la mano
# izquierda mutuamente excluyentes (altura vs. proximidad a la mochila), asi
# que no compiten entre si por el gatillo.
func _al_presionar_boton_mano(nombre_boton: String) -> void:
	if nombre_boton != "trigger_click":
		return
	if resultados_mision and resultados_mision.visible:
		resultados_mision.confirmar_seleccion()
	elif menu_pausa and menu_pausa.visible:
		menu_pausa.confirmar_seleccion()
	elif GestorJuego.fase == GestorJuego.Fase.DESPLIEGUE:
		# En el puesto de mando el gatillo solo confirma en el mapa de la
		# ciudad: no hay disparo ni kit hasta desplegarse.
		var mapa_despliegue: MapaDespliegue = get_tree().get_first_node_in_group("mapa_despliegue")
		if mapa_despliegue:
			mapa_despliegue.confirmar_seleccion()
	elif mapa_muneca and mapa_muneca.visible:
		mapa_muneca.confirmar_seleccion()
	elif kit_medico and kit_medico.visible:
		kit_medico.confirmar_seleccion()
	else:
		disparar()

# RF-40: el boton de menu de cualquiera de los dos controladores (aca solo
# se conecta en la mano izquierda; la derecha ya esta ocupada por el
# gatillo/pistola) abre o cierra el menu de pausa.
func _al_presionar_boton_mano_izquierda(nombre_boton: String) -> void:
	if nombre_boton == "menu_button" and menu_pausa:
		menu_pausa.alternar()

# RF-25/RF-26: solo dispara si la pistola esta desenfundada y con balas;
# pistola.gd decide eso y devuelve el RayCast3D usado, o null si no disparo
# (sin funda, sin balas). Sin tiro real no hay disparo_realizado: la esquiva
# reactiva del enemigo cuchillo solo debe reaccionar a balas de verdad.
func disparar() -> void:
	var rayo: RayCast3D = pistola.intentar_disparar()
	if not rayo:
		return
	disparo_realizado.emit(rayo)

	var origen := rayo.global_position
	var destino := origen
	if rayo.is_colliding():
		destino = rayo.get_collision_point()
	else:
		destino = rayo.global_transform * rayo.target_position
	_mostrar_trazador(origen, destino)

	if rayo.is_colliding():
		var objetivo := rayo.get_collider()
		if objetivo and objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano_disparo)

# Dibuja brevemente la trayectoria del disparo: el RayCast3D en si es invisible
# en juego, esta linea es solo para poder confirmar visualmente el impacto.
func _mostrar_trazador(origen: Vector3, destino: Vector3) -> void:
	if not trazador_disparo:
		return
	var malla := trazador_disparo.mesh as ImmediateMesh
	malla.clear_surfaces()
	malla.surface_begin(Mesh.PRIMITIVE_LINES)
	malla.surface_add_vertex(origen)
	malla.surface_add_vertex(destino)
	malla.surface_end()
	trazador_disparo.visible = true
	get_tree().create_timer(0.08).timeout.connect(func(): trazador_disparo.visible = false)

# RF-05: la comunicacion real de salud/critica es el tinte rojo de
# pantalla_dano.gd (sin barra numerica); etiqueta_salud es solo debug.
# El pulso haptico en ambas manos refuerza el impacto sin depender de mirar.
# RF-43: salud en 0 termina la mision (eliminado).
func recibir_dano(cantidad: float) -> void:
	salud = max(salud - cantidad, 0.0)
	_actualizar_etiqueta_salud()
	if pantalla_danio:
		pantalla_danio.mostrar_dano()
	mano_izquierda.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.2, 0.0)
	mano_derecha.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.2, 0.0)
	_actualizar_musica_por_salud()
	print("Jugador recibio %s de dano. Salud: %s" % [cantidad, salud])
	if salud <= 0.0:
		GestorJuego.terminar_mision("eliminado")

# RF-46: musica "critico" mientras la salud esta baja; vuelve a "combate" al
# recuperarse (todavia no hay curacion del jugador, pero deja el enganche
# listo para cuando exista).
func _actualizar_musica_por_salud() -> void:
	var critico := salud <= salud_maxima * umbral_salud_critica
	GestorAudio.cambiar_estado(
		GestorAudio.EstadoMusica.CRITICO if critico else GestorAudio.EstadoMusica.COMBATE
	)

func _actualizar_etiqueta_salud() -> void:
	if etiqueta_salud:
		etiqueta_salud.text = "Salud: %d" % salud

# RNF-05: fundido a negro que oculta el "salto" del teletransporte (RF-08);
# la duracion depende de GestorOpciones.intensidad_teletransporte (0 =
# instantaneo, sin fundido). Es un quad negro frente a la camara (visible en
# headset, a diferencia de un ColorRect 2D). Llamado por gestor_escenarios.gd
# luego de reposicionar al jugador.
func fundido_teletransporte() -> void:
	if not desvanecido:
		return
	var duracion := GestorOpciones.duracion_fundido()
	if duracion <= 0.0:
		return
	var material := desvanecido.material_override as StandardMaterial3D
	if not material:
		return
	material.albedo_color.a = 1.0
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, duracion)

# RNF-03: fundido a negro completo antes de salir de la mision (menu de
# pausa "SALIR", pantalla de resultados "VOLVER AL MENU"). A diferencia de
# fundido_teletransporte() (que se autodesvanece), este queda en negro
# hasta que la escena cambia, para no mostrar el "salto" de vuelta al menu.
func fundido_salida(escena_destino: String, duracion: float = 0.4) -> void:
	var material: StandardMaterial3D = desvanecido.material_override if desvanecido else null
	if not material:
		get_tree().change_scene_to_file(escena_destino)
		return
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 1.0, duracion)
	tween.tween_callback(func(): get_tree().change_scene_to_file(escena_destino))
