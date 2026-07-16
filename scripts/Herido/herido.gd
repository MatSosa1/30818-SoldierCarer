extends Node3D
## Placeholder del herido a los pies del jugador. Curacion rudimentaria: solo
## para demostrar que la zona despejada (sin enemigos activos) es el momento
## para curar. El sistema de kit medico real esta fuera de alcance de esta
## demo (ver IA_SoldierCarer_Implementacion.md).

signal curado

@export var tiempo_curacion: float = 2.0
@export var director_oleadas_path: NodePath

@onready var director: Node = get_node_or_null(director_oleadas_path)
@onready var etiqueta_estado: Label3D = $EtiquetaEstado
@onready var malla: MeshInstance3D = $Malla

var _curando: bool = false
var _tiempo_restante: float = 0.0
var curado_completo: bool = false

func _ready() -> void:
	_actualizar_etiqueta()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_intentar_curar()

func _process(delta: float) -> void:
	if not _curando:
		return
	_tiempo_restante -= delta
	_actualizar_etiqueta()
	if _tiempo_restante <= 0.0:
		_completar_curacion()

func _intentar_curar() -> void:
	if curado_completo or _curando:
		return
	if director and director.has_method("hay_enemigos_activos") and director.hay_enemigos_activos():
		print("No se puede curar al herido: todavia hay enemigos activos en la zona.")
		return
	_curando = true
	_tiempo_restante = tiempo_curacion
	print("Curando al herido...")
	_actualizar_etiqueta()

func _completar_curacion() -> void:
	_curando = false
	curado_completo = true
	print("Herido curado y estabilizado.")
	if malla:
		var material := malla.get_surface_override_material(0)
		if material is StandardMaterial3D:
			material.albedo_color = Color(0.25, 0.8, 0.3)
	_actualizar_etiqueta()
	curado.emit()

func _actualizar_etiqueta() -> void:
	if not etiqueta_estado:
		return
	if curado_completo:
		etiqueta_estado.text = "CURADO"
	elif _curando:
		etiqueta_estado.text = "CURANDO... %.1f" % _tiempo_restante
	else:
		etiqueta_estado.text = "HERIDO (E para curar)"
