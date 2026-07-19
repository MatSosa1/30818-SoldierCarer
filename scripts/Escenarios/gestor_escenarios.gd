extends Node3D
## Activa el escenario correspondiente (E1_Calle / E2_Edificio) y reposiciona
## al jugador al confirmar un teletransporte (RF-08/RF-09). Escucha
## EventBus.solicitar_teletransporte; flujo documentado en Arquitectura.md SS8.

@export var contenedor_e1_path: NodePath
@export var contenedor_e2_path: NodePath
@export var escenario_inicial: String = "E1_Calle"

@onready var contenedor_e1: Node3D = get_node_or_null(contenedor_e1_path)
@onready var contenedor_e2: Node3D = get_node_or_null(contenedor_e2_path)
@onready var jugador: Node3D = get_tree().get_first_node_in_group("jugador")

var escenario_activo: String = ""

func _ready() -> void:
	EventBus.solicitar_teletransporte.connect(_al_solicitar_teletransporte)
	activar_escenario(escenario_inicial)

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
	activar_escenario(escenario)
	if not jugador:
		return
	jugador.global_position = punto_destino if punto_destino != Vector3.ZERO else punto_despliegue(escenario)
