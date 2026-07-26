extends EnemigoBase
## Enemigo a distancia. FSM: AVANCE -> DISPARO (a rango medio) -> NEUTRALIZADO.

enum Estado {AVANCE, DISPARO, NEUTRALIZADO}
var estado: Estado = Estado.AVANCE

func _init() -> void:
	salud_maxima = 25.0

@export var velocidad_avance: float = 2.5
@export var rango_disparo: float = 6.0
@export var dano_disparo: float = 5.0
@export var cadencia_disparo: float = 1.2

var _cooldown_disparo: float = 0.0

@onready var sonido_disparo: AudioStreamPlayer3D = $SonidoDisparo

func _physics_process(delta: float) -> void:
	if not jugador or estado == Estado.NEUTRALIZADO:
		return
	_orientar_hacia(jugador.global_position)

	var distancia := global_position.distance_to(jugador.global_position)
	match estado:
		Estado.AVANCE:
			var dir := (jugador.global_position - global_position).normalized()
			velocity = dir * velocidad_avance
			move_and_slide()
			_reproducir_pasos()
			# Solo abre fuego si ademas VE al jugador: sin linea de vision
			# (pared, vehiculo) sigue avanzando para flanquear la cobertura.
			if distancia <= rango_disparo and _tiene_linea_de_vision():
				_cambiar_estado(Estado.DISPARO)
		Estado.DISPARO:
			velocity = Vector3.ZERO
			_detener_pasos()
			if distancia > rango_disparo * 1.2 or not _tiene_linea_de_vision():
				_cambiar_estado(Estado.AVANCE)
				return
			_cooldown_disparo -= delta
			if _cooldown_disparo <= 0.0:
				_disparar_rafaga()

# Raycast fisico a la altura del pecho: el dano deja de atravesar paredes y
# props con colision (la cobertura funciona en ambos sentidos, igual que la
# pistola del jugador que ya usaba raycast). Otro cuerpo en el medio (aliado
# incluido) tambien bloquea la rafaga.
func _tiene_linea_de_vision() -> bool:
	var origen := global_position + Vector3.UP * 1.4
	var destino: Vector3 = jugador.global_position + Vector3.UP * 1.4
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino)
	consulta.exclude = [get_rid()]
	var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)
	return resultado.is_empty() or resultado.get("collider") == jugador

func _disparar_rafaga() -> void:
	_cooldown_disparo = cadencia_disparo
	print("%s dispara una rafaga al jugador" % name)
	if sonido_disparo:
		sonido_disparo.play()
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano_disparo)

func _esta_neutralizado() -> bool:
	return estado == Estado.NEUTRALIZADO

func _marcar_neutralizado() -> void:
	estado = Estado.NEUTRALIZADO
	_actualizar_etiqueta()

func _cambiar_estado(nuevo: Estado) -> void:
	estado = nuevo
	_actualizar_etiqueta()

func _actualizar_etiqueta() -> void:
	if etiqueta_estado:
		etiqueta_estado.text = Estado.keys()[estado]
