extends EnemigoBase
## Enemigo cuerpo a cuerpo. FSM reactiva: AVANCE -> ESQUIVA (al ser apuntado por el
## disparo del jugador) -> AVANCE -> EMBESTIDA -> NEUTRALIZADO.

enum Estado {AVANCE, ESQUIVA, EMBESTIDA, NEUTRALIZADO}
var estado: Estado = Estado.AVANCE

@export var velocidad_avance: float = 3.0
@export var rango_embestida: float = 1.5
@export var dano_embestida: float = 10.0
@export var cooldown_embestida: float = 1.0
@export var velocidad_esquiva: float = 5.0
@export var duracion_esquiva: float = 0.35

var _direccion_esquiva: Vector3 = Vector3.ZERO
var _tiempo_esquiva_restante: float = 0.0
var _cooldown_embestida_restante: float = 0.0

@onready var sonido_embestida: AudioStreamPlayer3D = $SonidoEmbestida

func _ready() -> void:
	super._ready()
	if jugador and jugador.has_signal("disparo_realizado"):
		jugador.disparo_realizado.connect(_al_recibir_disparo)

func _physics_process(delta: float) -> void:
	if not jugador or estado == Estado.NEUTRALIZADO:
		return
	_orientar_hacia(jugador.global_position)

	match estado:
		Estado.AVANCE:
			var dir := (jugador.global_position - global_position).normalized()
			velocity = dir * velocidad_avance
			move_and_slide()
			_reproducir_pasos()
			if global_position.distance_to(jugador.global_position) <= rango_embestida:
				_cambiar_estado(Estado.EMBESTIDA)
		Estado.ESQUIVA:
			velocity = _direccion_esquiva * velocidad_esquiva
			move_and_slide()
			_tiempo_esquiva_restante -= delta
			if _tiempo_esquiva_restante <= 0.0:
				_cambiar_estado(Estado.AVANCE)
		Estado.EMBESTIDA:
			velocity = Vector3.ZERO
			_detener_pasos()
			if global_position.distance_to(jugador.global_position) > rango_embestida * 1.5:
				_cambiar_estado(Estado.AVANCE)
				return
			_cooldown_embestida_restante -= delta
			if _cooldown_embestida_restante <= 0.0:
				_atacar_cuerpo_a_cuerpo()

# Transicion reactiva: se dispara en el instante en que un raycast del jugador
# confirma que impacto a ESTE enemigo especifico (no por temporizador ni azar).
func _al_recibir_disparo(rayo: RayCast3D) -> void:
	if estado == Estado.AVANCE and rayo.is_colliding() and rayo.get_collider() == self:
		_iniciar_esquiva()

func _iniciar_esquiva() -> void:
	var dir_actual := (jugador.global_position - global_position).normalized()
	var lateral := dir_actual.cross(Vector3.UP).normalized()
	_direccion_esquiva = lateral * (1.0 if randf() < 0.5 else -1.0)
	_tiempo_esquiva_restante = duracion_esquiva
	_cambiar_estado(Estado.ESQUIVA)

func _atacar_cuerpo_a_cuerpo() -> void:
	_cooldown_embestida_restante = cooldown_embestida
	print("%s embiste al jugador por %s de dano" % [name, dano_embestida])
	if sonido_embestida:
		sonido_embestida.play()
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano_embestida)

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
