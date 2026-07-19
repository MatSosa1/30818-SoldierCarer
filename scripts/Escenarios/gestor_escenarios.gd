extends Node3D
## Activa el escenario correspondiente (E1_Calle / E2_Edificio) y reposiciona
## al jugador al confirmar un teletransporte (RF-08/RF-09). Escucha
## EventBus.solicitar_teletransporte; flujo documentado en Arquitectura.md SS8.

@export var contenedor_e1_path: NodePath
@export var contenedor_e2_path: NodePath
# Vacio = arrancar sin escenario activo: el jugador aparece en el puesto de
# mando (fase DESPLIEGUE) y el primer escenario se activa recien al confirmar
# un punto en el mapa de despliegue. Un nombre concreto ("E1_Calle") conserva
# el arranque directo, util para probar un escenario desde el editor.
@export var escenario_inicial: String = ""

@onready var contenedor_e1: Node3D = get_node_or_null(contenedor_e1_path)
@onready var contenedor_e2: Node3D = get_node_or_null(contenedor_e2_path)
@onready var jugador: Jugador = get_tree().get_first_node_in_group("jugador")

var escenario_activo: String = ""

func _ready() -> void:
	add_to_group("gestor_escenarios") # para que menu_pausa.gd (RF-40) lo encuentre
	EventBus.solicitar_teletransporte.connect(_al_solicitar_teletransporte)
	# GestorJuego es autoload: sobrevive al cambio de escena, asi que cada
	# carga de Mision.tscn debe devolverlo a DESPLIEGUE con el reloj lleno
	# (antes, al rejugar, quedaba el estado de la partida anterior).
	GestorJuego.reiniciar()
	if escenario_inicial != "":
		activar_escenario(escenario_inicial)
	else:
		_desactivar_todos()

# Fase DESPLIEGUE: ambos escenarios quedan invisibles y congelados (los
# heridos no se desangran mientras el jugador elige destino en el mapa).
func _desactivar_todos() -> void:
	for contenedor: Node3D in [contenedor_e1, contenedor_e2]:
		if contenedor:
			contenedor.visible = false
			contenedor.process_mode = Node.PROCESS_MODE_DISABLED
	escenario_activo = ""

# RF-40: pausa/reanuda la simulacion del escenario activo (enemigos,
# heridos) sin usar SceneTree.paused, para no tener que lidiar con el
# process_mode de los XRController3D solo para que el menu de pausa siga
# recibiendo el gatillo mientras esta abierto.
func pausar_activo(pausado: bool) -> void:
	var contenedor: Node3D = {"E1_Calle": contenedor_e1, "E2_Edificio": contenedor_e2}.get(escenario_activo)
	if contenedor:
		contenedor.process_mode = Node.PROCESS_MODE_DISABLED if pausado else Node.PROCESS_MODE_INHERIT

func activar_escenario(nombre: String) -> void:
	var contenedores := {"E1_Calle": contenedor_e1, "E2_Edificio": contenedor_e2}
	for clave in contenedores:
		var contenedor: Node3D = contenedores[clave]
		if not contenedor:
			continue
		var activo: bool = clave == nombre
		contenedor.visible = activo
		contenedor.process_mode = Node.PROCESS_MODE_INHERIT if activo else Node.PROCESS_MODE_DISABLED
	escenario_activo = nombre
	EventBus.escenario_activado.emit(nombre)

func punto_despliegue(nombre: String) -> Vector3:
	var contenedor: Node3D = {"E1_Calle": contenedor_e1, "E2_Edificio": contenedor_e2}.get(nombre)
	if contenedor:
		var marcador := contenedor.get_node_or_null("PuntoDespliegue")
		if marcador:
			return marcador.global_position
	return Vector3.ZERO

# punto_destino == Vector3.ZERO es el centinela de "usa el punto de
# despliegue por defecto del escenario" (seleccion directa de un icono de
# escenario en el mapa, sin un herido puntual como destino).
func _al_solicitar_teletransporte(punto_destino: Vector3, escenario: String) -> void:
	var punto_final: Vector3 = punto_destino if punto_destino != Vector3.ZERO else punto_despliegue(escenario)
	# RF-42: el salto consume tiempo de mision segun la distancia real
	# recorrida en el mapa, calculada ANTES de mover al jugador.
	if jugador:
		GestorJuego.consumir_tiempo_por_distancia(jugador.global_position.distance_to(punto_final))
	activar_escenario(escenario)
	if not jugador:
		return
	jugador.global_position = punto_final
	jugador.fundido_teletransporte()
